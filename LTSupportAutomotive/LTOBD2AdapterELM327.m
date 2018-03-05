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

    if ( response.length < 2 )
    {
        return nil;
    }
    unichar lastCharacter = [response characterAtIndex:response.length - 1];
    unichar crlfCharacter = [response characterAtIndex:response.length - 2];
    if ( lastCharacter != '>' )
    {
        return nil;
    }
    if ( crlfCharacter != '\r' && crlfCharacter != '\n' )
    {
        return nil;
    }

    identification = @""; // indicates that we got a valid response terminator, even if there was not valid identification string (e.g. '?')
    NSString* stringWithoutResponseTerminator = [response substringToIndex:response.length - 1];
    [stringWithoutResponseTerminator enumerateLinesUsingBlock:^(NSString * _Nonnull line, BOOL * _Nonnull stop) {
        if ( line.length > 5 )
        {
            identification = line;
        }
    }];
    identification = [identification stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
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
    NSMutableArray<NSString*>* init0 = [NSMutableArray array];
    [init0 addObjectsFromArray:@[
                                 @"ATD",       // set defaults
                                 @"ATZ",       // reset all settings
                                 @"ATE0",      // echo off
                                 @"ATL0",      // line feeds off
                                 @"ATS1",      // spaces on (only during init)
                                 ]];
    if ( self.nextCommandDelay )
    {
        [init0 addObject:@"ATSTFF"];           // set answer timing to maximum (in order to work with slower cars)
    }
    [init0 addObjectsFromArray:@[
                                 @"ATRV",      // read voltage
                                 @"ATSP0",     // start negotiating with automatic protocol
                                 @"ATH1",      // CAN headers on
                                 @"ATI",       // identify yourself
                                 @"ATS0",      // spaces off
                                 ]];
    // send initialization sequence, make sure the last command will return 'OK'

    [init0 enumerateObjectsUsingBlock:^(NSString * _Nonnull string, NSUInteger idx, BOOL * _Nonnull stop) {
        
        [self transmitRawString:string responseHandler:^(NSArray<NSString*>* _Nullable response) {
            
            if ( [string isEqualToString:@"ATI"] )
            {
                _version = response.lastObject;
                if ( [_version isEqualToString:@"NO DATA"] || ![_version containsString:@" "] )
                {
                    WARN( @"Did not find expected ELM327 identification response. Got %@ instead", _version );
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
                            if ( [self isValidPidResponse:response] )
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
    XLOG( @"Received data: %@", LTDataToString( data ) );

    NSMutableData* md = [NSMutableData data];
    // A note about "clone wars" here...: Some cheap ELM327-clones inject invalid characters into the answer,
    // hence we need to filter the data before appending to the receive buffer.
    uint8_t* bytes = (uint8_t*)[data bytes];
    for ( NSUInteger i = 0; i < data.length; ++i )
    {
        uint8_t byte = bytes[i];
        if ( byte > 0x09 && byte < 0x80 )
        {
            [md appendBytes:&byte length:1];
        }
        else
        {
            XLOG( @"Warning: Skipping invalid character 0x%02X in response...", byte );
        }
    }
    NSData* filteredData = [NSData dataWithData:md];
    [receiveBuffer appendData:filteredData];

    NSString* receivedString = [[NSString alloc] initWithData:receiveBuffer encoding:NSUTF8StringEncoding];

    // A note about our parsing strategy here:
    // ----------------------------------------
    // 0. We check whether the last two characters are a valid ELM327-like prompt, such as <someCRLFcharacter> and '>'
    // 1. We strip the terminator away before iterating through "lines"
    // 2. Empty lines are thrown away
    // 3. We always let the last line (which is supposed to contain either a valid PID or a terminal response, such as OK, NO DATA, STOPPED, etc.) pass
    // 4. Lines (except the last one) that are not valid PID lines (allowed are all hex characters and spaces) are thrown away

    if ( receivedString.length < 2 )
    {
        return;
    }

    unichar lastCharacter = [receivedString characterAtIndex:receivedString.length - 1];
    unichar crlfCharacter = [receivedString characterAtIndex:receivedString.length - 2];
    if ( lastCharacter != '>' )
    {
        return;
    }
    if ( crlfCharacter != '\r' && crlfCharacter != '\n' )
    {
        return;
    }

    NSMutableCharacterSet* whitespaceNewlineAndPrompt = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
    [whitespaceNewlineAndPrompt addCharactersInString:@">"];
    NSString* receivedStringWithoutTermination = [receivedString stringByTrimmingCharactersInSet:whitespaceNewlineAndPrompt];

    NSMutableArray<NSString*>* ma = [NSMutableArray array];
    __block NSInteger idx = -1;
    [receivedStringWithoutTermination enumerateLinesUsingBlock:^(NSString * _Nonnull line, BOOL * _Nonnull stop) {

        idx++;
        if ( line.length < 1 )
        {
            return;
        }
        if ( idx < ma.count && ! [self isValidPidLine:line] )
        {
            return;
        }
        [ma addObject:line];

    }];

    [self responseCompleted:ma];
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
            if ( [self isValidPidResponse:test0100.rawResponse] )
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
    // Most adapters return a string like "12.2V" here, but some are omitting the 'V',
    // hence we better grab the value, do a sanity check, and then format the string.
    double voltage = [self.rawResponse.firstObject doubleValue];
    if ( voltage < 1 || voltage > 100 )
    {
        return OBD2_NO_DATA;
    }
    NSString* response = [NSString stringWithFormat:@"%.1f" UTF8_NARROW_NOBREAK_SPACE "V", voltage];
    return response;
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
