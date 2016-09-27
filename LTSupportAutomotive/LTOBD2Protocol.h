//
//  Copyright (c) Dr. Michael Lauer Information Technology. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LTOBD2Command;

NS_ASSUME_NONNULL_BEGIN

@interface LTOBD2Protocol : NSObject

+(instancetype)protocol;

@property(nonatomic,readonly) LTOBD2Command* heartbeatCommand;

// API for subclasses
-(BOOL)isMultiFrameWithPrefix:(NSString*)prefix lines:(NSArray<NSString*>*)lines;
-(NSArray<NSNumber*>*)hexStringToArrayOfNumbers:(NSString*)string;

// API to override in subclasses
-(NSDictionary<NSString*,NSArray<NSNumber*>*>*)decode:(NSArray<NSString*>*)lines originatingCommand:(NSString*)command;

@end

NS_ASSUME_NONNULL_END
