//
//  Copyright (c) Dr. Michael Lauer Information Technology. All rights reserved.
//

#import "LTOBD2AdapterELM327.h"

#import "LTSupportAutomotive.h"

//#define DEBUG_THIS_FILE

#ifdef DEBUG_THIS_FILE
    #define XLOG LOG
#else
    #define XLOG(...)
#endif

#define OBD2_NO_DATA LTStringLookupWithPlaceholder(@"OBD2_NO_DATA", @"N/A")

static NSString* RESPONSE_CHIP_IDENTIFICATION = @"ELM327";
static NSString* RESPONSE_TERMINATION_RN = @"\r\n>";
static NSString* RESPONSE_TERMINATION_RR = @"\r\r>";

//TODO: We have dedicated command classes for most of the commands, should better use them instead of transmitting raw commands

@implementation LTOBD2AdapterELM327
{
    NSString* _version;
}

#pragma mark -
#pragma mark Identification

+(NSString*)identifyWithResponseToResetCommand:(NSString*)response
{
    __block NSString* identification;

    NSArray<NSString*>* potentialResponseTerminators = @[ RESPONSE_TERMINATION_RR, RESPONSE_TERMINATION_RN ];
    [potentialResponseTerminators enumerateObjectsUsingBlock:^(NSString * _Nonnull responseTerminator, NSUInteger idx, BOOL * _Nonnull stop) {

        if ( [response hasSuffix:responseTerminator] )
        {
            *stop = YES;
            NSString* lineTerminator = [responseTerminator substringWithRange:NSMakeRange(0, responseTerminator.length - 1)];
            NSString* stringWithoutResponseTerminator = [response stringByReplacingOccurrencesOfString:responseTerminator withString:@""];
            NSMutableArray<NSString*>* ma = [NSMutableArray array];
            [[stringWithoutResponseTerminator componentsSeparatedByString:lineTerminator] enumerateObjectsUsingBlock:^(NSString * _Nonnull line, NSUInteger idx, BOOL * _Nonnull stop) {
                if ( line.length >= 4 )
                {
                    [ma addObject:line];
                }
            }];
            identification = [ma.lastObject stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        }
    }];

    return identification;
}

#pragma mark -
#pragma mark LTOBD2Adapter Overrides

-(NSString*)friendlyAdapterType
{
    return @"ELM327";
}

-(NSString*)friendlyAdapterVersion
{
    return _version;
}

-(void)sendInitializationSequence
{
    // send initialization sequence, make sure the last command is one that is supposed to return 'OK'
    NSArray<NSString*>* init0 = @[
                                  @"ATD",       // set defaults
                                  @"ATZ",       // reset all settings
                                  self.nextCommandDelay ? @"ATSTFF" : @"ATE0", // set answer timing to maximum (in order to work with slower cars)
                                  @"ATRV",      // read voltage
                                  @"ATSP0",     // start negotiating with automatic protocol
                                  @"ATE0",      // echo off
                                  @"ATL1",      // linefeed on
                                  @"ATH1",      // CAN headers on
                                  @"ATI",       // identify yourself
                                  @"ATS1",      // spaces on
                                  ];
    
    [init0 enumerateObjectsUsingBlock:^(NSString * _Nonnull string, NSUInteger idx, BOOL * _Nonnull stop) {
        
        [self transmitRawString:string responseHandler:^(NSArray<NSString*>* _Nullable response) {
            
            if ( [string isEqualToString:@"ATI"] )
            {
                _version = response.lastObject;
                if ( ! [_version hasPrefix:RESPONSE_CHIP_IDENTIFICATION] )
                {
                    LOG( @"Did not find expected ELM327 identification response. Got %@ instead", _version );
                    [self advanceAdapterStateTo:OBD2AdapterStateError];
                    return;
                }
            }
            
            if ( string == init0.lastObject )
            {
                if ( [response.lastObject isEqualToString:@"OK"] )
                {
                    [self advanceAdapterStateTo:OBD2AdapterStateReady];
                    
                    [self transmitRawString:@"ATIGN" responseHandler:^(NSArray<NSString *> * _Nullable response) {
                        
                        NSString* answer = response.lastObject;
                        if ( [answer isEqualToString:@"OFF"] )
                        {
                            [self advanceAdapterStateTo:OBD2AdapterStateIgnitionOff];
                            return;
                        }
                        
                        [self transmitRawString:@"0100" responseHandler:^(NSArray<NSString *> * _Nullable response) {
                            if ( [self.class isValidPidResponse:response] )
                            {
                                [self initDoneIdentifyProtocol];
                            }
                            else
                            {
                                LOG( @"Did not get a valid response, trying slow initialization path..." );
                                [self trySlowInitializationWithProtocol:OBD2VehicleProtocolJ_1850PWM];
                            }

                        }];
                        
                     }];
                }
                else
                {
                    LOG( @"Adapter did not answer 'OK' to '%@' => Error", init0.lastObject );
                    [self advanceAdapterStateTo:OBD2AdapterStateError];
                }
            }
        }];
    }];
}

-(void)receivedData:(NSData*)data receiveBuffer:(NSMutableData*)receiveBuffer
{
    [super receivedData:data receiveBuffer:receiveBuffer];

    [receiveBuffer appendData:data];

    XLOG( @"Received data: %@, buffer now %@", LTDataToString( data ), LTDataToString( receiveBuffer ) );
    NSString* receivedString = [[NSString alloc] initWithData:receiveBuffer encoding:NSUTF8StringEncoding];
    // A note about "clone wars" here...: Some cheap ELM327-clones inject invalid characters into the answer.
    // If they're non-UTF8, then we need to iterate through the bytes manually and ignore the offenders.
    if ( !receivedString )
    {
        XLOG( @"Non-UTF8 characters in string. Inspecting and skipping..." );
        NSMutableString* ms = [NSMutableString stringWithCapacity:receiveBuffer.length];
        uint8_t* bytes = (uint8_t*)[data bytes];
        for ( NSUInteger i = 0; i < receiveBuffer.length; ++i )
        {
            uint8_t byte = bytes[i];
            if ( byte > 11 && byte < 128 )
            {
                [ms appendFormat:@"%c", byte];
            }
        }
        receivedString = ms;
    }

    // A note about our parsing strategy here:
    // ----------------------------------------
    // 1. We strip the terminator away before iterating through "lines"
    // 2. Empty lines are thrown away
    // 3. We always let the last line (which is supposed to contain either a valid PID or a terminal response, such as OK, NO DATA, STOPPED, etc.) pass
    // 4. Lines (except the last one) that are not valid PID lines (allowed are all hex characters and spaces) are thrown away

    if ( [receivedString hasSuffix:RESPONSE_TERMINATION_RR] || [receivedString hasSuffix:RESPONSE_TERMINATION_RN] )
    {
        NSString* receivedStringWithoutTermination = [receivedString substringToIndex:receivedString.length - RESPONSE_TERMINATION_RR.length];

        NSMutableArray<NSString*>* ma = [NSMutableArray array];
        __block NSInteger idx = -1;
        [receivedStringWithoutTermination enumerateLinesUsingBlock:^(NSString * _Nonnull line, BOOL * _Nonnull stop) {

            idx++;
            if ( line.length < 1 )
            {
                return;
            }
            if ( idx < ma.count && ! [LTOBD2Adapter isValidPidLine:line] )
            {
                return;
            }
            [ma addObject:line];

        }];

        [self responseCompleted:ma];
    }
}

#pragma mark -
#pragma mark Helpers

-(void)initDoneIdentifyProtocol
{
    [self transmitRawString:@"ATDPN" responseHandler:^(NSArray<NSString *> * _Nullable response) {

        OBD2VehicleProtocol protocol = OBD2VehicleProtocolUnknown;
        NSString* answer = response.lastObject;

        if ( answer.length == 1 )
        {
            NSUInteger value = answer.intValue;
            if ( value > OBD2VehicleProtocolAUTO && value < OBD2VehicleProtocolMAX )
            {
                protocol = value;
            }
        }
        else if ( answer.length == 2 )
        {
            NSUInteger value = [answer substringFromIndex:1].intValue;
            if ( value > OBD2VehicleProtocolAUTO && value < OBD2VehicleProtocolMAX )
            {
                protocol = value;
            }
        }
        [self didRecognizeProtocol:protocol];
    }];
}

-(void)trySlowInitializationWithProtocol:(OBD2VehicleProtocol)protocol
{
    if ( protocol == OBD2VehicleProtocolMAX )
    {
        [self advanceAdapterStateTo:OBD2AdapterStateError];
        return;
    }

    LTOBD2CommandELM327_TRY_PROTOCOL* tryProtocol = [LTOBD2CommandELM327_TRY_PROTOCOL commandForProtocol:protocol];
    LTOBD2Command* test0100 = [LTOBD2Command commandWithRawString:@"0100"];
    [self transmitMultipleCommands:@[ tryProtocol, test0100 ] responseHandler:^(LTOBD2Command * _Nonnull command) {

        if ( command == test0100 )
        {
            if ( [self.class isValidPidResponse:test0100.rawResponse] )
            {
                [self initDoneIdentifyProtocol];
            }
            else
            {
                [self trySlowInitializationWithProtocol:protocol + 1];
            }
        }

    }];
}

@end



#pragma mark -
#pragma mark Non-initialization ELM327 AT commands

@implementation LTOBD2CommandELM327_IDENTIFY

+(instancetype)command
{
    return [self commandWithRawString:@"ATI"];
}

-(NSString*)purpose
{
    return LTStringLookupWithPlaceholder( @"ADAPTER_IDENTIFICATION", @"Adapter Identification" );
}

-(NSString*)formattedResponse
{
    return self.rawResponse.firstObject;
}

@end



@implementation LTOBD2CommandELM327_READ_VOLTAGE

+(instancetype)command
{
    return [self commandWithRawString:@"ATRV"];
}

-(NSString*)purpose
{
    return LTStringLookupWithPlaceholder( @"BATTERY_VOLTAGE", @"Battery Voltage" );
}

-(NSString*)formattedResponse
{
    if ( ! [self.rawResponse.firstObject hasSuffix:@"V"] )
    {
        return OBD2_NO_DATA;
    }
    
    return [self.rawResponse.firstObject stringByReplacingOccurrencesOfString:@"V" withString:UTF8_NARROW_NOBREAK_SPACE @"V"];
}

@end



@implementation LTOBD2CommandELM327_IGNITION_STATUS

+(instancetype)command
{
    return [self commandWithRawString:@"ATIGN"];
}

-(NSString*)purpose
{
    return LTStringLookupWithPlaceholder( @"IGNITION_STATUS", @"Ignition Status");
}

-(NSString*)formattedResponse
{
    if ( [self.rawResponse.firstObject isEqualToString:@"ON"] )
    {
        return LTStringLookupWithPlaceholder(@"OBD2_ON", @"ON");
    }

    if ( [self.rawResponse.firstObject isEqualToString:@"OFF"] )
    {
        return LTStringLookupWithPlaceholder(@"OBD2_OFF", @"OFF");
    }
    
    return OBD2_NO_DATA;
}

@end



@implementation LTOBD2CommandELM327_TRY_PROTOCOL

+(instancetype)commandForProtocol:(OBD2VehicleProtocol)protocol
{
    NSString* string = [NSString stringWithFormat:@"ATTP%u", (uint)protocol];
    return [self commandWithRawString:string];
}

+(instancetype)commandForAutoProtocol:(OBD2VehicleProtocol)protocol
{
    NSString* string = [NSString stringWithFormat:@"ATTPA%u", (uint)protocol];
    return [self commandWithRawString:string];
}

@end



@implementation LTOBD2CommandELM327_SET_PROTOCOL

+(instancetype)commandForProtocol:(OBD2VehicleProtocol)protocol
{
    NSString* string = [NSString stringWithFormat:@"ATSP%u", (uint)protocol];
    return [self commandWithRawString:string];
}

+(instancetype)commandForAutoProtocol:(OBD2VehicleProtocol)protocol
{
    NSString* string = [NSString stringWithFormat:@"ATSPA%u", (uint)protocol];
    return [self commandWithRawString:string];
}

@end



@implementation LTOBD2CommandELM327_DESCRIBE_PROTOCOL

+(instancetype)command
{
    return [self commandWithRawString:@"ATDP"];
}

-(NSString*)purpose
{
    return LTStringLookupWithPlaceholder( @"VEHICLE_PROTOCOL", @"Vehicle Protocol");
}

-(NSString*)formattedResponse
{
    NSString* line = self.rawResponse.firstObject;
    
    if ( !line.length )
    {
        return OBD2_NO_DATA;
    }

    NSArray* components = [line componentsSeparatedByString:@","];
    NSString* result = components.count < 2 ? components.firstObject : [components objectAtIndex:1];
    return [result stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@end



@implementation LTOBD2CommandELM327_DESCRIBE_PROTOCOL_NUMERIC

+(instancetype)command
{
    return [self commandWithRawString:@"ATDPN"];
}

-(NSString*)purpose
{
    return LTStringLookupWithPlaceholder( @"VEHICLE_PROTOCOL_NUMERIC", @"Vehicle Protocol (Numeric)");
}

-(NSString*)formattedResponse
{
    NSString* line = self.rawResponse.firstObject;
    
    if ( !line.length )
    {
        return OBD2_NO_DATA;
    }
    
    return line;
}

@end
