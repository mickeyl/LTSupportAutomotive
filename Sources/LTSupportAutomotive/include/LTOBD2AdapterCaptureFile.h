//
//  Copyright (c) Dr. Michael Lauer Information Technology. All rights reserved.
//

#import "LTOBD2AdapterELM327.h"

@class LTOBD2CaptureFile;

NS_ASSUME_NONNULL_BEGIN

@interface LTOBD2AdapterCaptureFile : LTOBD2AdapterELM327

+(nullable instancetype)adapterWithInputStream:(NSInputStream*)inputStream outputStream:(NSOutputStream*)outputStream NS_UNAVAILABLE;
-(nullable instancetype)initWithInputStream:(NSInputStream*)inputStream outputStream:(NSOutputStream*)outputStream NS_UNAVAILABLE;

+(nullable instancetype)adapterWithLogFile:(NSData*)logFile;
-(nullable instancetype)initWithLogFile:(NSData*)logFile;

+(nullable instancetype)adapterWithCaptureFile:(LTOBD2CaptureFile*)captureFile;
-(nullable instancetype)initWithCaptureFile:(LTOBD2CaptureFile*)captureFile;

@property(assign,nonatomic,readwrite) NSTimeInterval simulatedLatency;

@end

NS_ASSUME_NONNULL_END
