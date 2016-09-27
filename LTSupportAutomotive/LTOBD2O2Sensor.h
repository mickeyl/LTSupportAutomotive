//
//  Copyright (c) Dr. Michael Lauer Information Technology. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class LTOBD2PID_OXYGEN_SENSORS_PRESENT_2_BANKS_13;
@class LTOBD2PID_OXYGEN_SENSORS_PRESENT_4_BANKS_1D;

@class LTOBD2PID_OXYGEN_SENSORS_INFO_1;
@class LTOBD2PID_OXYGEN_SENSORS_INFO_2;
@class LTOBD2PID_OXYGEN_SENSORS_INFO_3;

@interface LTOBD2O2Sensor : NSObject

+(instancetype)sensorWithNumber:(NSUInteger)number
                          info1:(LTOBD2PID_OXYGEN_SENSORS_INFO_1*)info1
                          info2:(LTOBD2PID_OXYGEN_SENSORS_INFO_2*)info2
                          info3:(LTOBD2PID_OXYGEN_SENSORS_INFO_3*)info3
                  installBanks2:(LTOBD2PID_OXYGEN_SENSORS_PRESENT_2_BANKS_13*)banks2
                  installBanks4:(LTOBD2PID_OXYGEN_SENSORS_PRESENT_4_BANKS_1D*)banks4;

@property(nonatomic,readonly) BOOL installed;

@property(nonatomic,readonly) NSUInteger number;

@property(nonatomic,readonly) NSString* formattedLocation;
@property(nonatomic,readonly) NSString* formattedType;

@property(nonatomic,readonly) NSString* formattedKey1;
@property(nonatomic,readonly) NSString* formattedKey2;
@property(nonatomic,readonly) NSString* formattedKey3;
@property(nonatomic,readonly) NSString* formattedKey4;

@property(nonatomic,readonly) NSString* formattedValue1;
@property(nonatomic,readonly) NSString* formattedValue2;
@property(nonatomic,readonly) NSString* formattedValue3;
@property(nonatomic,readonly) NSString* formattedValue4;

@end

NS_ASSUME_NONNULL_END
