//
//  Copyright (c) Dr. Michael Lauer Information Technology. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>

NS_ASSUME_NONNULL_BEGIN

@interface LTBTLEReadCharacteristicStream : NSInputStream <NSStreamDelegate>

-(nullable instancetype)initWithCharacteristic:(CBCharacteristic*)characteristic;
-(void)characteristicDidUpdateValue;
-(void)dealloc;

@end

NS_ASSUME_NONNULL_END
