//
//  Copyright (c) Dr. Michael Lauer Information Technology. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class LTOBD2ECU;

typedef enum : NSUInteger {
    OBD2AdapterStateUnknown = 0,
    OBD2AdapterStateNotFound,
    OBD2AdapterStateError,
    OBD2AdapterStateDiscovering,
    OBD2AdapterStatePresent,                /* Adapter found */
    OBD2AdapterStateInitializing,           /* Adapter initializing... */
    OBD2AdapterStateReady,                  /* Adapter ready to communicate, not necessarily connected to the vehicle though */
    OBD2AdapterStateIgnitionOff,            /* Adapter ready, but ignition is not present */
    OBD2AdapterStateConnected,              /* Adapter connected to ECU(s), received at least one valid result to a PID query */
    OBD2AdapterStateUnsupportedProtocol,    /* Adapter could not negotiate a vehicle protocol that we support */
    OBD2AdapterStateGone,                   /* Adapter disconnected, no longer possible to communicate */
} OBD2AdapterState;

typedef enum : NSUInteger {
    OBD2VehicleProtocolUnknown       = 0xff,
    OBD2VehicleProtocolAUTO          = 0,
    OBD2VehicleProtocolJ_1850PWM     = 1,   /* Not supported by some adapters */
    OBD2VehicleProtocolJ_1850VPWM    = 2,   /* Not supported by some adapters */
    OBD2VehicleProtocolISO_9141_2    = 3,
    OBD2VehicleProtocolKWP2000_5KBPS = 4,
    OBD2VehicleProtocolKWP2000_FAST  = 5,
    OBD2VehicleProtocolCAN_11B_500K  = 6,
    OBD2VehicleProtocolCAN_29B_500K  = 7,
    OBD2VehicleProtocolCAN_11B_250K  = 8,
    OBD2VehicleProtocolCAN_29B_250K  = 9,
    OBD2VehicleProtocolMAX           = 10,
} OBD2VehicleProtocol;

@class LTOBD2Command;

typedef void(^LTOBD2MultipleCommandsResponseHandler)(NSArray<LTOBD2Command*>* commands);
typedef void(^LTOBD2CommandResponseHandler)(LTOBD2Command* command);
typedef void(^LTOBD2RawResponseHandler)(NSArray<NSString*>* _Nullable response);

extern NSString* const LTOBD2AdapterDidUpdateState;
extern NSString* const LTOBD2AdapterDidSend;
extern NSString* const LTOBD2AdapterDidReceive;

@interface LTOBD2Adapter : NSObject <NSStreamDelegate>

@property(assign,nonatomic,readonly) OBD2AdapterState adapterState;
@property(nonatomic,readonly) NSString* friendlyAdapterState;
@property(assign,nonatomic,readonly) OBD2VehicleProtocol vehicleProtocol;
@property(nonatomic,readonly) NSString* friendlyVehicleProtocol;

@property(nonatomic,readonly) NSString* friendlyAdapterType;
@property(nonatomic,readonly) NSString* friendlyAdapterVersion;

@property(strong,nonatomic,readonly) NSArray<LTOBD2ECU*>* visibleECUs;

// configuration
@property(assign,nonatomic,readwrite) NSTimeInterval nextCommandDelay;

// lifecycle
+(nullable instancetype)adapterWithInputStream:(NSInputStream*)inputStream outputStream:(NSOutputStream*)outputStream;
-(nullable instancetype)initWithInputStream:(NSInputStream*)inputStream outputStream:(NSOutputStream*)outputStream NS_DESIGNATED_INITIALIZER;
-(nullable instancetype)init NS_UNAVAILABLE;
+(nullable instancetype)new NS_UNAVAILABLE;

// connection handling
-(void)connect;
-(void)disconnect;

// command handling
-(void)transmitRawString:(NSString*)command responseHandler:(nullable LTOBD2RawResponseHandler)handler;
-(void)transmitCommand:(LTOBD2Command*)command responseHandler:(nullable LTOBD2CommandResponseHandler)handler;
// response handler getting called for every response
-(void)transmitMultipleCommands:(NSArray<LTOBD2Command*>*)commands responseHandler:(nullable LTOBD2CommandResponseHandler)handler;
// completion handler getting called for the last response
-(void)transmitMultipleCommands:(NSArray<LTOBD2Command*>*)commands completionHandler:(nullable LTOBD2MultipleCommandsResponseHandler)handler;
-(void)cancelPendingCommands;

// for subclasses
-(void)advanceAdapterStateTo:(OBD2AdapterState)nextCommand;
-(void)receivedData:(NSData*)data receiveBuffer:(NSMutableData*)receiveBuffer;
-(BOOL)sendCommand:(LTOBD2Command*)command;
-(void)responseCompleted:(NSArray<NSString*>*)lines;
-(void)didRecognizeProtocol:(OBD2VehicleProtocol)protocol;

// for debugging
-(void)startLoggingCommunicationTo:(NSString*)path;
-(void)registerDebugOverrideForCommand:(NSString*)command result:(NSArray<NSString*>*)lines;

// auxillary
+(BOOL)isValidPidResponse:(NSArray<NSString*>*)lines;

@end

NS_ASSUME_NONNULL_END
