//
//  Copyright (c) Dr. Michael Lauer Information Technology. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LTOBD2PerformanceTrackingResult : NSObject

+(instancetype)resultWithMnemonic:(NSString*)mnemonic count:(NSUInteger)count;

@property(nonatomic,readonly) NSString* mnemonic;
@property(nonatomic,readonly) NSString* formattedMnemonic;
@property(nonatomic,readonly) NSUInteger count;

@end

NS_ASSUME_NONNULL_END

