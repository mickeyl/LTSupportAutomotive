//
//  Copyright (c) Dr. Michael Lauer Information Technology. All rights reserved.
//

#import "LTOBD2AdapterCaptureFile.h"

#import "LTOBD2CaptureFile.h"

typedef NSDictionary<NSString*,NSArray<NSString*>*> RequestResponseDictionary;

@implementation LTOBD2AdapterCaptureFile
{
    RequestResponseDictionary* _requestResponseDictionary;
    NSData* _logFile;
}

#pragma mark -
#pragma mark Lifecycle

+(nullable instancetype)adapterWithLogFile:(NSData*)logFile
{
    return [[self alloc] initWithLogFile:logFile];
}

-(nullable instancetype)initWithLogFile:(NSData*)logFile
{
    NSInputStream* dummyInputStream = nil;
    NSOutputStream* dummyOutputStream = nil;

    if ( ! ( self = [super initWithInputStream:dummyInputStream outputStream:dummyOutputStream] ) )
    {
        return nil;
    }
    
    _logFile = logFile;
    
    return self;
}

+(nullable instancetype)adapterWithCaptureFile:(LTOBD2CaptureFile*)captureFile
{
    return [[self alloc] initWithCaptureFile:captureFile];
}

-(nullable instancetype)initWithCaptureFile:(LTOBD2CaptureFile*)captureFile
{
    NSInputStream* dummyInputStream = nil;
    NSOutputStream* dummyOutputStream = nil;
    
    if ( ! ( self = [super initWithInputStream:dummyInputStream outputStream:dummyOutputStream] ) )
    {
        return nil;
    }
    
    _requestResponseDictionary = captureFile.contents;
    
    return self;
}

#pragma mark -
#pragma mark Helpers

-(void)populateRequestResponseDictionaryWithLogData:(NSData*)data
{
    NSString* str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    str = [str stringByReplacingOccurrencesOfString:@"\r\r" withString:@"\r\n"];
    //str = [@">" stringByAppendingString:str];
    
    NSArray* requestResponses = [str componentsSeparatedByString:@"\r\n>"];
    
    NSMutableDictionary* md = [NSMutableDictionary dictionary];
    
    for ( NSString* requestResponse in requestResponses )
    {
        NSArray<NSString*>* lines = [requestResponse componentsSeparatedByString:@"\r\n"];
        NSString* request = lines[0];
        if ( !request.length )
        {
            continue;
        }
        NSMutableArray<NSString*>* ma = [NSMutableArray array];
        for ( NSString* line in [lines subarrayWithRange:NSMakeRange( 1, lines.count - 1)] )
        {
            NSString* strippedLine = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if ( !strippedLine.length )
            {
                continue;
            }
            
            [ma addObject:strippedLine];
        }
        
        NSArray<NSString*>* response = [NSArray arrayWithArray:ma];
        [md setObject:response forKey:request];
    }
    
    _requestResponseDictionary = [NSDictionary dictionaryWithDictionary:md];
    
    [self advanceAdapterStateTo:OBD2AdapterStateConnected];
}

#pragma mark -
#pragma mark LTOBD2Adapter Overrides

-(void)connect
{
    [self advanceAdapterStateTo:OBD2AdapterStateDiscovering];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{

        if ( _logFile )
        {
            [self populateRequestResponseDictionaryWithLogData:_logFile];
        }
        [self advanceAdapterStateTo:OBD2AdapterStatePresent];

        });
}

-(BOOL)sendCommand:(LTOBD2Command*)command
{
    dispatch_async( dispatch_get_current_queue(), ^{

        if ( [command.commandString hasPrefix:@"AT"] )
        {
            [self processAtCommand:command];
        }
        else
        {
            [self processPidCommand:command];
        }

    });

    return YES;
}

-(NSString*)friendlyAdapterType
{
    return @"CaptureFile";
}

-(NSString*)friendlyAdapterVersion
{
    return [NSString stringWithFormat:@"ELM327 SIM 1.0"];
}

#pragma mark -
#pragma mark Helpers

-(NSArray<NSString*>*)readAnswerForQuestion:(NSString*)question
{
    if ( _simulatedLatency )
    {
        [NSThread sleepForTimeInterval:_simulatedLatency];
    }
    
    return [_requestResponseDictionary objectForKey:question];
}

-(void)processAtCommand:(LTOBD2Command*)command
{
    NSArray<NSString*>* answer;
    
    if ( [command.commandString isEqualToString:@"ATZ"] )
    {
        answer = @[ self.friendlyAdapterVersion ];
    }
    else
    {
        answer = [self readAnswerForQuestion:command.commandString] ?: @[ @"OK" ];
    }
    [self responseCompleted:answer];
}

-(void)processPidCommand:(LTOBD2Command*)command
{
    NSArray<NSString*>* answer = [self readAnswerForQuestion:command.commandString] ?: @[ @"NO DATA" ];
    [self responseCompleted:answer];
}

@end
