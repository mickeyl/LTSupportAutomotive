//
//  Copyright (c) Dr. Michael Lauer Information Technology. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LTVIN : NSObject

+(BOOL)isValidString:(NSString*)string;
+(nullable instancetype)VINWithString:(NSString*)string;
+(nonnull instancetype)new NS_UNAVAILABLE;
-(nullable instancetype)initWithString:(NSString*)string NS_DESIGNATED_INITIALIZER;
-(nonnull instancetype)init NS_UNAVAILABLE;

// ISO 3779
@property(strong,nonatomic,readonly) NSString* vin;
@property(strong,nonatomic,readonly) NSString* wmi;
@property(strong,nonatomic,readonly) NSString* vds;
@property(strong,nonatomic,readonly) NSString* vis;

// formatted base information
@property(strong,nonatomic,readonly) NSString* region;
@property(strong,nonatomic,readonly) NSString* country;
@property(strong,nonatomic,readonly) NSString* manufacturer;

// for class cluster subclasses
@property(strong,nonatomic,readonly) NSString* modelYear;
@property(strong,nonatomic,readonly) NSString* model;
@property(strong,nonatomic,readonly) NSString* productionPlant;

@end

NS_ASSUME_NONNULL_END
