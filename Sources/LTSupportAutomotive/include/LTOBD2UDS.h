//
//  Copyright (c) Dr. Lauer Information Technology. All rights reserved.
//
#import "LTOBD2Command.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(UInt8, UDSDiagnosticSessionType) {
    DefaultSession                  = 0x01,
    ProgrammingSession              = 0x02,
    ExtendedDiagnosticsSession      = 0x03,
    SafetySystemDiagnosticSession   = 0x04,
};

typedef NS_ENUM(UInt8, UDSEcuResetType) {
    HardReset                       = 0x01,
    KeyOffOnReset                   = 0x02,
    SoftReset                       = 0x03,
    EnableRapidPowerShutdown        = 0x04,
    DisableRapidPowerShutdown       = 0x05,
};

@interface LTOBD2UDSCommand : LTOBD2Command

+(instancetype)commandWithRawString:(NSString *)rawString NS_UNAVAILABLE;
+(instancetype)commandWithString:(NSString *)string NS_UNAVAILABLE;

@property(nonatomic,readonly) BOOL succeeded;
// for debugging
@property(nonatomic,readonly) NSString* hexResponse;
@property(nonatomic,readonly) NSString* stringResponse;

@end

@interface LTOBD2UDS_TESTER_PRESENT : LTOBD2UDSCommand

+(instancetype)command;

@end

@interface LTOBD2UDS_DIAGNOSTIC_SESSION_CONTROL : LTOBD2UDSCommand

+(instancetype)requestSession:(UDSDiagnosticSessionType)type;

@property(nonatomic,readonly) NSTimeInterval p2ServerMax;
@property(nonatomic,readonly) NSTimeInterval p2eServerMax;

@end

@interface LTOBD2UDS_ECU_RESET : LTOBD2UDSCommand

+(instancetype)resetWithType:(UDSEcuResetType)type;

@end

@interface LTOBD2UDS_READ_DATA_BY_IDENTIFIER : LTOBD2UDSCommand

+(instancetype)readIdentifier:(UInt16)identifier;

@end

@interface LTOBD2UDS_WRITE_DATA_BY_IDENTIFIER : LTOBD2UDSCommand

+(instancetype)writeIdentifier:(UInt16)identifier data:(NSArray<NSNumber*>*)data;

@end

@interface LTOBD2UDS_SECURITY_ACCESS : LTOBD2UDSCommand

+(instancetype)requestSeed:(UInt8)number;
+(instancetype)sendKey:(UInt8)number record:(NSArray<NSNumber*>*)record;

@end

@interface LTOBD2UDS_ROUTINE_CONTROL : LTOBD2UDSCommand

+(instancetype)startRoutine:(UInt16)identifier;
+(instancetype)stopRoutine:(UInt16)identifier;
+(instancetype)requestRoutineResults:(UInt16)identifier;

@end








NS_ASSUME_NONNULL_END
