//
//  Copyright (c) Dr. Lauer Information Technology. All rights reserved.
//
#import "LTOBD2UDS.h"

typedef NS_ENUM(UInt8, UDSRequestSID) {
    DiagnosticSessionControl                    = 0x10,
    ECUReset                                    = 0x11,
    ClearDiagnosticInformation                  = 0x14,
    ReadDTCInformation                          = 0x19,

    ReadDataByIdentifier                        = 0x22,
    ReadMemoryByAddress                         = 0x23,
    ReadScalingDataByIdentifier                 = 0x24,
    SecurityAccess                              = 0x27,
    CommunicationControl                        = 0x28,
    Authentication                              = 0x29,
    ReadDataByPeriodicIdentifier                = 0x2A,
    DynamicallyDefineDataIdentifier             = 0x2C,
    WriteDataByIdentifier                       = 0x2E,
    InputOutputControlByIdentifier              = 0x2F,

    RoutineControl                              = 0x31,
    RequestDownload                             = 0x34,
    RequestUpload                               = 0x35,
    TransferData                                = 0x36,
    RequestTransferExit                         = 0x37,
    RequestFileTransfer                         = 0x38,
    WriteMemoryByAddress                        = 0x3D,
    TesterPresent                               = 0x3E,

    SecuredDataTransmission                     = 0x84,
    ControlDTCSetting                           = 0x85,
    ResponseOnEvent                             = 0x86,
    LinkControl                                 = 0x87,
};

typedef NS_ENUM(UInt8, UDSRoutineControlType) {
    StartRoutine                                = 0x01,
    StopRoutine                                 = 0x02,
    RequestRoutineResults                       = 0x03,
};

@implementation LTOBD2UDSCommand

+(instancetype)commandWithBytes:(NSArray<NSNumber*>*)bytes
{
    NSMutableString* string = [NSMutableString string];
    [bytes enumerateObjectsUsingBlock:^(NSNumber * _Nonnull number, NSUInteger idx, BOOL * _Nonnull stop) {
        UInt8 byte = number.unsignedShortValue;
        [string appendFormat:@"%02X", byte];
    }];
    return [super commandWithString:[NSString stringWithString:string]];
}

@end



@implementation LTOBD2UDS_DIAGNOSTIC_SESSION_CONTROL : LTOBD2UDSCommand

+(instancetype)requestSession:(UDSDiagnosticSessionType)type
{
    NSArray<NSNumber*>* bytes = @[
        @(DiagnosticSessionControl),
        @(type),
    ];
    return [self commandWithBytes:bytes];
}

@end



@implementation LTOBD2UDS_READ_DATA_BY_IDENTIFIER : LTOBD2UDSCommand

+(instancetype)readIdentifier:(UInt16)identifier
{
    NSArray<NSNumber*>* bytes = @[
        @(ReadDataByIdentifier),
        @(identifier >> 8 & 0xff),
        @(identifier & 0xff),
    ];
    return [self commandWithBytes:bytes];
}

@end



@implementation LTOBD2UDS_WRITE_DATA_BY_IDENTIFIER : LTOBD2UDSCommand

+(instancetype)writeIdentifier:(UInt16)identifier data:(NSArray<NSNumber*>*)data
{
    NSMutableArray<NSNumber*>* bytes = @[
        @(WriteDataByIdentifier),
        @(identifier >> 8 & 0xff),
        @(identifier & 0xff),
    ].mutableCopy;
    [bytes addObjectsFromArray:data];
    return [self commandWithBytes:bytes];
}

@end



@implementation LTOBD2UDS_SECURITY_ACCESS : LTOBD2UDSCommand

+(instancetype)requestSeed:(UInt8)number
{
    NSArray<NSNumber*>* bytes = @[
        @(SecurityAccess),
        @(number),
    ];
    return [self commandWithBytes:bytes];
}

+(instancetype)sendKey:(UInt8)number record:(NSArray<NSNumber *> *)record
{
    NSMutableArray* bytes = @[
        @(SecurityAccess),
        @(number),
    ].mutableCopy;
    [bytes addObjectsFromArray:record];
    return [self commandWithBytes:bytes];
}

@end



@implementation LTOBD2UDS_ROUTINE_CONTROL : LTOBD2UDSCommand

+(instancetype)startRoutine:(UInt16)identifier
{
    NSArray<NSNumber*>* bytes = @[
        @(RoutineControl),
        @(StartRoutine),
        @(identifier >> 8 & 0xff),
        @(identifier & 0xff),
    ];
    return [self commandWithBytes:bytes];
}

+(instancetype)stopRoutine:(UInt16)identifier
{
    NSArray<NSNumber*>* bytes = @[
        @(RoutineControl),
        @(StopRoutine),
        @(identifier >> 8 & 0xff),
        @(identifier & 0xff),
    ];
    return [self commandWithBytes:bytes];
}

+(instancetype)requestRoutineResults:(UInt16)identifier
{
    NSArray<NSNumber*>* bytes = @[
        @(RoutineControl),
        @(RequestRoutineResults),
        @(identifier >> 8 & 0xff),
        @(identifier & 0xff),
    ];
    return [self commandWithBytes:bytes];
}

@end
