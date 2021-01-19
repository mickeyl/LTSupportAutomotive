//
//  Copyright (c) Dr. Michael Lauer Information Technology. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LTOBD2DTC : NSObject

@property(nonatomic,readonly) NSString* code;
@property(nonatomic,readonly) NSString* ecu;

@property(nonatomic,readonly) NSString* formattedEcu;
@property(nonatomic,readonly) NSString* formattedCode;
@property(nonatomic,readonly) NSString* explanation;
@property(nonatomic,readonly) NSInteger associatedFreezeFrame;

+(instancetype)dtcWithCode:(NSString*)code ecu:(NSString*)ecu;
+(instancetype)dtcWithCode:(NSString*)code ecu:(NSString*)ecu freezeFrame:(NSUInteger)framenumber;

@end

NS_ASSUME_NONNULL_END
