//
//  Copyright (c) Dr. Michael Lauer Information Technology. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>

NS_ASSUME_NONNULL_BEGIN

@interface LTBTLEWriteCharacteristicStream : NSOutputStream <NSStreamDelegate>

-(nullable instancetype)initToCharacteristic:(CBCharacteristic*)characteristic;
-(void)characteristicDidWriteValue;

@end

NS_ASSUME_NONNULL_END
