//
//  Copyright (c) Dr. Michael Lauer Information Technology. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LTOBD2Command;

static const NSUInteger OBD2FailureCode = 0x7F;

typedef enum : NSUInteger {
    OBD2FailureTypeInternalOK = 0x00, /* not defined by the standard */
    OBD2FailureTypeInternalUnknown = 0x01, /* not defined by the standard */
    
    OBD2FailureTypeGeneralReject = 0x10,
    OBD2FailureTypeServiceNotSupported = 0x11,
    OBD2FailureTypeSubfunctionNotSupportedOrInvalidFormat = 0x12,
    OBD2FailureTypeBusyRepeatRequest = 0x21,
    OBD2FailureTypeConditionsNotCorrectOrRequestSequenceError = 0x22,
    OBD2FailureTypeRoutineNotCompleteOrServiceInProgress = 0x23,
    OBD2FailureTypeRequestOutOfRange = 0x31,
    OBD2FailureTypeSecurityAccessDenied = 0x33,
    OBD2FailureTypeInvalidKey = 0x35,
    OBD2FailureTypeExceedNumberOfAttempts = 0x36,
    OBD2FailureTypeRequiredTimeDelayNotExpired = 0x37,
    OBD2FailureTypeDownloadNotAccepted = 0x40,
    OBD2FailureTypeImproperDownloadType = 0x41,
    OBD2FailureTypeCanNotDownloadToSpecifiedAddress = 0x42,
    OBD2FailureTypeCanNotDownloadNumberOfBytesRequested = 0x43,
    OBD2FailureTypeUploadNotAccepted = 0x50,
    OBD2FailureTypeImproperUploadType = 0x51,
    OBD2FailureTypeCanNotUploadFromSpecifiedAddress = 0x52,
    OBD2FailureTypeCanNotUploadNumberOfBytesRequested = 0x53,
    OBD2FailureTypeTransferSuspended = 0x71,
    OBD2FailureTypeTransferAborted = 0x72,
    OBD2FailureTypeIllegalAddressInBlockTransfer = 0x74,
    OBD2FailureTypeIllegalByteCountInBlockTransfer = 0x75,
    OBD2FailureTypeIllegalBlockTransferType = 0x76,
    OBD2FailureTypeBlockTransferDataChecksumError = 0x77,
    OBD2FailureTypeRequestCorrectlyReceivedResponsePending = 0x78,
    OBD2FailureTypeIncorrectByteCountDuringBlockTransfer = 0x79,
    OBD2FailureTypeServiceNotSupportedInActiveDiagnosticMode = 0x80,
    OBD2FailureTypeStartComms = 0xC1,
    OBD2FailureTypeStopComms = 0xC2,
    OBD2FailureTypeAccessTimingParams = 0xC3,
} OBD2FailureType;

NS_ASSUME_NONNULL_BEGIN


@interface LTOBD2ProtocolResult : NSObject

+(instancetype)protocolResultFailureType:(OBD2FailureType)failureType;
-(void)appendPayloadBytes:(NSArray<NSNumber*>*)bytes;

@property(nonatomic,readonly) NSArray<NSNumber*>* payload;
@property(nonatomic,readonly) OBD2FailureType failureType;

@end


@interface LTOBD2Protocol : NSObject

+(instancetype)protocol;

@property(nonatomic,readonly) LTOBD2Command* heartbeatCommand;

// API for subclasses
-(BOOL)isMultiFrameWithPrefix:(NSString*)prefix lines:(NSArray<NSString*>*)lines;
-(NSArray<NSNumber*>*)hexStringToArrayOfNumbers:(NSString*)string;
-(LTOBD2ProtocolResult*)createProtocolResultForBytes:(NSArray<NSNumber*>*)bytes sidIndex:(NSUInteger)sidIndex;

// API to override in subclasses
-(NSDictionary<NSString*,LTOBD2ProtocolResult*>*)decode:(NSArray<NSString*>*)lines originatingCommand:(NSString*)command;

@end

NS_ASSUME_NONNULL_END
