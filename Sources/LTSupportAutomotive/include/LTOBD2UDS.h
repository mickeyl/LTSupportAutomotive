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

typedef NS_ENUM(UInt8, UDSNegativeResponseCode) {
    GeneralReject                               = 0x10,
    ServiceNotSupported                         = 0x11,
    SubFunctionNotSupported                     = 0x12,
    IncorrectMessageLengthOrInvalidFormat       = 0x13,
    ResponseTooLong                             = 0x14,

    BusyRepeatReques                            = 0x21,
    ConditionsNotCorrect                        = 0x22,
    RequestSequenceError                        = 0x24,

    RequestOutOfRange                           = 0x31,
    SecurityAccessDenied                        = 0x33,
    InvalidKey                                  = 0x35,
    ExceedNumberOfAttempts                      = 0x36,
    RequiredTimeDelayNotExpired                 = 0x37,

    UploadDownloadNotAccepted                   = 0x70,
    TransferDataSuspended                       = 0x71,
    GeneralProgrammingFailure                   = 0x72,
    WrongBlockSequenceCounter                   = 0x73,
    RequestCorrectlyReceivedResponsePending     = 0x78, // NOT an error, but an intermediate response
    SubFunctionNotSupportedInActiveSession      = 0x7E,
    ServiceNotSupportedInActiveSession          = 0x7F,

    RpmTooHigh                                  = 0x81,
    RpmTooLow                                   = 0x82,
    EngineIsRunning                             = 0x83,
    EngineIsNotRunning                          = 0x84,
    EngineRunTimeTooLow                         = 0x85,
    TemperatureTooHigh                          = 0x86,
    TemperatureTooLow                           = 0x87,
    VehicleSpeedTooHigh                         = 0x88,
    VehicleSpeedTooLow                          = 0x89,
    ThrottleTooHigh                             = 0x8A,
    ThrottleTooLow                              = 0x8B,
    TransmissionRangeNotInNeutral               = 0x8C,
    TransmissionRangeNotInGear                  = 0x8D,
    BrakeSwitchNotClosed                        = 0x8F,

    ShifterLeverNotInPark                       = 0x90,
    TorqueConverterClutchLocked                 = 0x91,
    VoltageTooHigh                              = 0x92,
    VoltageTooLow                               = 0x93,
};

@interface LTOBD2UDSCommand : LTOBD2Command

+(instancetype)commandWithRawString:(NSString *)rawString NS_UNAVAILABLE;
+(instancetype)commandWithString:(NSString *)string NS_UNAVAILABLE;

@property(nonatomic,readonly) BOOL succeeded;
// for debugging
@property(nonatomic,readonly) NSString* hexPayload;
@property(nonatomic,readonly) NSString* stringPayload;

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
