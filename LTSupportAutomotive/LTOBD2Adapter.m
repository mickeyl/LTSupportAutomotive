//
//  LTOBD2Adapter.m
//  LTSupport
//
//  Created by Dr. Michael Lauer on 23.06.16.
//  Copyright © 2016 Dr. Lauer Information Technology. All rights reserved.
//

#import "LTOBD2Adapter.h"

#import "LTSupportAutomotive.h"

//#define DEBUG_THIS_FILE

#ifdef DEBUG_THIS_FILE
#define XLOG LOG
#else
#define XLOG(...)
#endif

static NSString* const RESPONSE_FINAL_NODATA = @"NO DATA";
static NSString* const COMMAND_TERMINATION_SEQUENCE = @"\r"; // CR (0x0D)

#pragma mark -
#pragma mark InternalCommand Helper class

@interface LTOBD2AdapterInternalCommand : NSObject
{
    NSDate* _startDate;
}

+(instancetype)commandWithOBD2Command:(LTOBD2Command*)command responseHandler:(LTOBD2CommandResponseHandler)responseHandler;

@property(strong,nonatomic,readonly) LTOBD2Command* command;
@property(strong,nonatomic,readonly) LTOBD2CommandResponseHandler responseHandler;

@end

@implementation LTOBD2AdapterInternalCommand

+(instancetype)commandWithOBD2Command:(LTOBD2Command *)command responseHandler:(LTOBD2CommandResponseHandler)responseHandler
{
    LTOBD2AdapterInternalCommand* obj = [[self alloc] init];
    obj->_command = command;
    obj->_responseHandler = responseHandler;
    return obj;
}

-(void)commandSent
{
    _startDate = [NSDate date];
}

-(void)didCompleteResponse:(NSArray<NSString*>*)lines protocol:(LTOBD2Protocol*)protocol protocolType:(OBD2VehicleProtocol)protocolType
{
    NSTimeInterval completionTime = -[_startDate timeIntervalSinceNow];
    [_command didCompleteResponse:lines completionTime:completionTime];
    LOG( @"%@ complete [%.0f ms] => '%@'", _command, 1000*_command.completionTime, [lines componentsJoinedByString:@" - "] );
    
    if ( protocol && ! [_command isRawCommand] )
    {
        if ( ! [lines.firstObject isEqualToString:RESPONSE_FINAL_NODATA] )
        {
            [_command didCookResponse:[protocol decode:lines originatingCommand:_command.commandString] withProtocolType:protocolType];
        }
    }
    
    if ( _responseHandler )
    {
        _responseHandler( _command );
    }
}

-(NSString*)description
{
    return [NSString stringWithFormat:@"<InternalCommand: %p (%@)>", self, _command];
}

@end

#pragma mark -
#pragma mark LTOBD2Adapter

NSString* const LTOBD2AdapterDidUpdateState = @"LTOBD2AdapterDidUpdateState";
NSString* const LTOBD2AdapterDidSend = @"LTOBD2AdapterDidSend";
NSString* const LTOBD2AdapterDidReceive = @"LTOBD2AdapterDidReceive";

@implementation LTOBD2Adapter
{
    NSInputStream* _inputStream;
    NSOutputStream* _outputStream;
    
    NSMutableArray* _commandQueue;
    dispatch_queue_t _dispatchQueue;
    
    NSMutableData* _receiveBuffer;
    BOOL _hasPendingAnswer;
    
    LTOBD2Protocol* _adapterProtocol;
    NSTimer* _heartbeatTimer;
    
    // debugging
    NSFileHandle* _logFile;
    NSMutableDictionary<NSString*,NSArray<NSString*>*>* _debugOverrides;
}

#pragma mark -
#pragma mark Lifecycle

+(nullable instancetype)adapterWithInputStream:(NSInputStream*)inputStream outputStream:(NSOutputStream*)outputStream
{
    return [[self alloc] initWithInputStream:inputStream outputStream:outputStream];
}

-(nullable instancetype)initWithInputStream:(NSInputStream*)inputStream outputStream:(NSOutputStream*)outputStream
{
    if ( ! ( self = [super init] ) )
    {
        return nil;
    }
    
    _inputStream = inputStream;
    _inputStream.delegate = self;
    _outputStream = outputStream;
    _outputStream.delegate = self;
    _commandQueue = [NSMutableArray array];
    _dispatchQueue = dispatch_queue_create( [self.description cStringUsingEncoding:NSUTF8StringEncoding], DISPATCH_QUEUE_SERIAL );
    
    _adapterState = OBD2AdapterStateUnknown;
    
    return self;
}

-(void)dealloc
{
    [self disconnect];
}

#pragma mark -
#pragma mark API

-(NSString*)friendlyAdapterState
{
    static NSString* const states[] = {
        @"OBD2AdapterStateUnknown",
        @"OBD2AdapterStateNotFound",
        @"OBD2AdapterStateError",
        @"OBD2AdapterStateDiscovering",
        @"OBD2AdapterStatePresent",
        @"OBD2AdapterStateInitializing",
        @"OBD2AdapterStateReady",
        @"OBD2AdapterStateIgnitionOff",
        @"OBD2AdapterStateConnected",
        @"OBD2AdapterStateUnsupportedProtocol",
        @"OBD2AdapterStateGone",
    };
    
    return states[_adapterState];
}

-(NSString*)friendlyVehicleProtocol
{
    NSDictionary* const protocols = @{
                                      @(OBD2VehicleProtocolUnknown):        @"UNKNOWN",
                                      @(OBD2VehicleProtocolAUTO):           @"AUTO",
                                      @(OBD2VehicleProtocolJ_1850PWM):      @"J-1850 PWM",
                                      @(OBD2VehicleProtocolJ_1850VPWM):     @"J-1850 VPWM",
                                      @(OBD2VehicleProtocolISO_9141_2):     @"ISO_9141_2",
                                      @(OBD2VehicleProtocolKWP2000_5KBPS):  @"KWP2000_5KBPS",
                                      @(OBD2VehicleProtocolKWP2000_FAST):   @"KWP2000_FAST",
                                      @(OBD2VehicleProtocolCAN_11B_500K):   @"CAN_11B_500K",
                                      @(OBD2VehicleProtocolCAN_29B_500K):   @"CAN_29B_500K",
                                      @(OBD2VehicleProtocolCAN_11B_250K):   @"CAN_11B_250K",
                                      @(OBD2VehicleProtocolCAN_29B_250K):   @"CAN_29B_250K",
                                      };
    
    return [protocols objectForKey:@(_vehicleProtocol)] ?: @"UNKNOWN";
}

-(NSString*)friendlyAdapterType
{
    NSAssert( NO, @"Abstract base class implementation called." );
    return nil;
}

-(NSString*)friendlyAdapterVersion
{
    NSAssert( NO, @"Abstract base class implementation called." );
    return nil;
}

#pragma mark -
#pragma mark Connection Handling

-(void)connect
{
    [self advanceAdapterStateTo:OBD2AdapterStateDiscovering];
    
    [_inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [_outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    [_inputStream open];
    [_outputStream open];
}

-(void)disconnect
{
    [_heartbeatTimer invalidate];
    _heartbeatTimer = nil;
    
    [_inputStream close];
    _inputStream = nil;
    [_outputStream close];
    _outputStream = nil;
    
    [_logFile closeFile];
    _logFile = nil;
}

#pragma mark -
#pragma mark Command Handling

-(void)transmitRawString:(NSString*)rawString responseHandler:(nullable LTOBD2RawResponseHandler)handler
{
    LTOBD2Command* command = [LTOBD2Command commandWithRawString:rawString];
    [self transmitCommand:command responseHandler:^(LTOBD2Command * _Nonnull command) {
        
        handler( command.rawResponse );
        
    }];
}

-(void)transmitCommand:(LTOBD2Command*)command responseHandler:(nullable LTOBD2CommandResponseHandler)handler
{
    LTOBD2AdapterInternalCommand* internalCommand = [LTOBD2AdapterInternalCommand commandWithOBD2Command:command responseHandler:handler];
    dispatch_async( _dispatchQueue, ^{
        [self asyncEnqueueInternalCommand:internalCommand];
    });
}

-(void)transmitMultipleCommands:(NSArray<LTOBD2Command*>*)commands responseHandler:(nullable LTOBD2CommandResponseHandler)handler
{
    if ( !commands.count )
    {
        return;
    }
    
    [commands enumerateObjectsUsingBlock:^(LTOBD2Command * _Nonnull command, NSUInteger idx, BOOL * _Nonnull stop) {
        [self transmitCommand:command responseHandler:handler];
    }];
}

-(void)transmitMultipleCommands:(NSArray<LTOBD2Command*>*)commands completionHandler:(nullable LTOBD2MultipleCommandsResponseHandler)handler
{
    if ( !commands.count )
    {
        return;
    }
    
    [commands enumerateObjectsUsingBlock:^(LTOBD2Command * _Nonnull command, NSUInteger idx, BOOL * _Nonnull stop) {
        LTOBD2CommandResponseHandler commandHandler = ( idx < commands.count - 1 ) ? nil : ^(LTOBD2Command* command ){
            handler( commands );
        };
        [self transmitCommand:command responseHandler:commandHandler];
    }];
}

-(void)cancelPendingCommands
{
    // This cancels all but the first command in order to prevent sending a new command while
    // the response to an active command is still pending. OBD2 adapters usually can't cope with
    // that and emit a 'STOPPED' response in that case.
    if ( _hasPendingAnswer )
    {
        NSRange allButTheFirst = NSMakeRange( 1, _commandQueue.count - 1 );
        [_commandQueue removeObjectsInRange:allButTheFirst];
    }
    else
    {
        [_commandQueue removeAllObjects];
    }
}

#pragma mark -
#pragma mark API for subclasses

-(NSString*)commandTerminationSequence
{
    return COMMAND_TERMINATION_SEQUENCE;
}


-(void)advanceAdapterStateTo:(OBD2AdapterState)nextState
{
    if ( _adapterState == nextState )
    {
        return;
    }
#ifdef DEBUG_THIS_FILE
    NSString* oldState = [self friendlyAdapterState];
#endif
    _adapterState = nextState;
#ifdef DEBUG_THIS_FILE
    NSString* newState = [self friendlyAdapterState];
#endif
    
    XLOG( @"Adapter state '%@' => '%@'", oldState, newState );
    
    [[NSNotificationCenter defaultCenter] postNotificationName:LTOBD2AdapterDidUpdateState object:self];
    
    if ( _adapterState == OBD2AdapterStatePresent )
    {
        [self advanceAdapterStateTo:OBD2AdapterStateInitializing];
        [self sendInitializationSequence];
    }
    
    if ( _adapterState == OBD2AdapterStateGone )
    {
        [self disconnect];
    }
}

-(void)sendInitializationSequence
{
    // default implementation does nothing
}

-(void)receivedData:(NSData*)data receiveBuffer:(NSMutableData*)receiveBuffer
{
    // default implementation does nothing
}

-(BOOL)sendCommand:(LTOBD2Command*)command
{
    if ( !_outputStream.hasSpaceAvailable )
    {
        LOG( @"Failed to send %@ (no space on %@)", command, _outputStream );
        return NO;
    }
    
    NSString* string = command.commandString;
    
    //// DEBUGGING
    NSArray<NSString*>* debugOverride = [_debugOverrides objectForKey:string];
    if ( debugOverride )
    {
        [self responseCompleted:debugOverride];
        return YES;
    }
    //// <DEBUGGING>
    
    if ( ! [string hasSuffix:self.commandTerminationSequence] )
    {
        string = [string stringByAppendingString:self.commandTerminationSequence];
    }
    NSData* data = [string dataUsingEncoding:NSUTF8StringEncoding];
    NSInteger numWritten = [_outputStream write:data.bytes maxLength:data.length];
    [_logFile writeData:data];
    if ( numWritten != data.length )
    {
        XLOG( @"Warning: Couldn't completely send %@ (partial write %u/%u on %@)", command, (uint)numWritten, (uint)data.length, _outputStream );
        return NO;
    }
    
    XLOG( @"Command %@ sent successfully to %@", command, _outputStream );
    return YES;
}

-(void)inputReadBytes:(NSData*)data
{
    if ( _hasPendingAnswer )
    {
        [self receivedData:data receiveBuffer:_receiveBuffer];
        [_logFile writeData:data];
    }
    else
    {
        WARN( @"Ignoring unsolicited data: %@", data );
    }
}

-(void)responseCompleted:(NSArray<NSString*>*)lines
{
    [[NSNotificationCenter defaultCenter] postNotificationName:LTOBD2AdapterDidReceive object:self];
    
    if ( !_hasPendingAnswer )
    {
        WARN( @" Received command without pending answer (perhaps in reaction to a cancelPendingCommands?)!" );
        return;
    }
    
    LTOBD2AdapterInternalCommand* internalCommand = _commandQueue.firstObject;
    [_commandQueue removeObjectAtIndex:0];
    [internalCommand didCompleteResponse:lines protocol:_adapterProtocol protocolType:_vehicleProtocol];
    _hasPendingAnswer = NO;

    if ( _nextCommandDelay )
    {
        [NSThread sleepForTimeInterval:_nextCommandDelay];
    }
    [self processCommandQueue];
}

-(void)didRecognizeProtocol:(OBD2VehicleProtocol)protocol
{
    _vehicleProtocol = protocol;
    
    LTOBD2Protocol* implementation;
    
    switch ( protocol )
    {
        /* CAN w/ 11 byte headers, no checksum */
        case OBD2VehicleProtocolCAN_11B_500K: /* P6 */
        case OBD2VehicleProtocolCAN_11B_250K: /* P8 */
            implementation = [LTOBD2ProtocolISO15765_4 protocolVariantWith11BitHeaders];
            break;

        /* CAN w/ 29 bit headers, no checksum */
        case OBD2VehicleProtocolCAN_29B_500K: /* P7 */
        case OBD2VehicleProtocolCAN_29B_250K: /* P9 */
            implementation = [LTOBD2ProtocolISO15765_4 protocolVariantWith29BitHeaders];
            break;
            
        /* ISO 14230-4, no payload indicators, simple multiframing, checksum */
        case OBD2VehicleProtocolKWP2000_FAST: /* P5 */
        case OBD2VehicleProtocolKWP2000_5KBPS: /* P4 */
            implementation = [LTOBD2ProtocolISO14230_4 protocol];
            break;
            
        /* SAE J1850 (V)PWM */
        case OBD2VehicleProtocolJ_1850PWM:  /* P1 */
        case OBD2VehicleProtocolJ_1850VPWM: /* P2 */
            implementation = [LTOBD2ProtocolSAEJ1850 protocol];
            break;
            
        /* ISO 9141-2 K-LINE*/
        case OBD2VehicleProtocolISO_9141_2: /* P3 */
            implementation = [LTOBD2ProtocolISO9141_2 protocol];
            break;

        default:
            LOG( @"Unknown or not yet implemented protocol value %u", protocol );
            break;
    }
    
    if ( implementation )
    {
        _adapterProtocol = implementation;
        [self advanceAdapterStateTo:OBD2AdapterStateConnected];
        [self launchHeartbeatIfNecessary];
    }
    else
    {
        [self advanceAdapterStateTo:OBD2AdapterStateUnsupportedProtocol];
    }
}

#pragma mark -
#pragma mark Aux

+(BOOL)isValidPidLine:(NSString*)line
{
    NSCharacterSet* invalidCharactersSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789ABCDEF "].invertedSet;
    NSRange range = [line rangeOfCharacterFromSet:invalidCharactersSet];
    return range.location == NSNotFound;
}

+(BOOL)isValidPidResponse:(NSArray<NSString*>*)lines
{
    return [self isValidPidLine:lines.lastObject];
}

#pragma mark -
#pragma mark Debugging

-(void)startLoggingCommunicationTo:(NSString*)path
{
    if ( _logFile )
    {
        return;
    }
    
    [[NSFileManager defaultManager] createFileAtPath:path contents:[NSData new] attributes:nil];
    _logFile = [NSFileHandle fileHandleForWritingAtPath:path];
}

-(void)registerDebugOverrideForCommand:(NSString*)command result:(NSArray<NSString*>*)lines
{
    if ( !_debugOverrides )
    {
        _debugOverrides = [NSMutableDictionary dictionary];
    }
    [_debugOverrides setObject:lines forKey:command];
}

#pragma mark -
#pragma mark Timer

-(void)onTimerFired:(NSTimer*)timer
{
    XLOG( @"COMMAND TIMEOUT: %@", _commandQueue.firstObject );
    //FIXME: What now?
}

#pragma mark -
#pragma mark <NSStreamDelegate>

-(void)stream:(NSStream*)stream handleEvent:(NSStreamEvent)eventCode
{
    XLOG( @"stream %@ handleEvent: %u", stream, (uint)eventCode );
    
    if ( stream == _inputStream )
    {
        switch ( eventCode )
        {
            case NSStreamEventHasBytesAvailable:
            {
                uint8_t buffer[1024];
                NSInteger numRead = [_inputStream read:(uint8_t*)&buffer maxLength:sizeof(buffer)];
                if ( numRead > 0 )
                {
                    NSData* data = [NSData dataWithBytes:&buffer length:numRead];
                    [self inputReadBytes:data];
                }
                // NOTE: Reading 0 bytes from an NSInputStream will automatically trigger an NSStreamEventEndEncountered
                break;
            }
                
            case NSStreamEventEndEncountered:
            {
                [self advanceAdapterStateTo:OBD2AdapterStateGone];
                break;
            }
                
            case NSStreamEventErrorOccurred:
            {
                [self advanceAdapterStateTo:OBD2AdapterStateError];
                break;
            }
                
            default:
                break;
        }
    }
    else if ( stream == _outputStream )
    {
        switch ( eventCode )
        {
            case NSStreamEventHasSpaceAvailable:
            {
                if ( _adapterState == OBD2AdapterStateDiscovering )
                {
                    [self advanceAdapterStateTo:OBD2AdapterStatePresent];
                }
                break;
            }
                
            case NSStreamEventErrorOccurred:
            {
                [self advanceAdapterStateTo:OBD2AdapterStateError];
                break;
            }
                
            default:
                break;
        }
    }
    
}

#pragma mark -
#pragma mark NSTimer

-(void)sendHeartbeatCommand:(NSTimer*)timer
{
    if ( _adapterState != OBD2AdapterStateConnected )
    {
        XLOG( @"Can't send heartbeat command since we're not connected" );
        return;
    }
    
    [self transmitCommand:_adapterProtocol.heartbeatCommand responseHandler:nil];
}

#pragma mark -
#pragma mark Helpers

-(void)launchHeartbeatIfNecessary
{
    if ( _adapterProtocol.heartbeatCommand )
    {
        dispatch_async( dispatch_get_main_queue(), ^{
            _heartbeatTimer = [NSTimer scheduledTimerWithTimeInterval:4.5 target:self selector:@selector(sendHeartbeatCommand:) userInfo:nil repeats:YES];
        } );
    }
}

-(void)processCommandQueue
{
    dispatch_async( _dispatchQueue, ^{
        [self asyncProcessCommandQueue];
    });
}

-(void)asyncProcessCommandQueue
{
    if ( _hasPendingAnswer )
    {
        return;
    }
    
    XLOG( @"Q status: %@", _commandQueue );
    
    LTOBD2AdapterInternalCommand* internalCommand = _commandQueue.firstObject;
    if ( !internalCommand )
    {
        XLOG( @"No more commands in Q" );
        return;
    }
    
    if ( internalCommand.command.class == LTOBD2DummyCommand.class )
    {
        [_commandQueue removeObject:internalCommand];
        internalCommand.responseHandler( internalCommand.command );
        return;
    }
    
    _receiveBuffer = [NSMutableData data];
    _hasPendingAnswer = YES;
    if ( [self sendCommand:internalCommand.command] )
    {
        [internalCommand commandSent];
        [[NSNotificationCenter defaultCenter] postNotificationName:LTOBD2AdapterDidSend object:self];
    }
}

-(void)asyncEnqueueInternalCommand:(LTOBD2AdapterInternalCommand*)internalCommand
{
    [_commandQueue addObject:internalCommand];
    [self asyncProcessCommandQueue];
}

@end

