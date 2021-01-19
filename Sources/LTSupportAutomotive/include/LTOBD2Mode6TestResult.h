//
//  Copyright (c) Dr. Michael Lauer Information Technology. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LTOBD2Mode6TestResult : NSObject

@property(assign,nonatomic,readonly) NSUInteger mid;
@property(assign,nonatomic,readonly) NSUInteger tid;
@property(assign,nonatomic,readonly) NSUInteger uasid;

@property(assign,nonatomic,readonly) NSInteger minimum;
@property(assign,nonatomic,readonly) NSInteger current;
@property(assign,nonatomic,readonly) NSInteger maximum;

@property(nonatomic,readonly,getter=isCan) BOOL can;
@property(nonatomic,readonly,getter=hasPassed) BOOL passed;
@property(nonatomic,readonly) BOOL limitIsMinimum;

@property(nonatomic,readonly) NSString* formattedTid;
@property(nonatomic,readonly) NSString* formattedUnit;
@property(nonatomic,readonly) NSString* formattedMinimum;
@property(nonatomic,readonly) NSString* formattedCurrent;
@property(nonatomic,readonly) NSString* formattedMaximum;

+(instancetype)resultWithMid:(NSUInteger)mid bytes:(NSArray<NSNumber*>*)bytes can:(BOOL)can;

@end

NS_ASSUME_NONNULL_END
