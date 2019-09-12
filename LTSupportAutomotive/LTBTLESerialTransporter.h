//
//  Copyright (c) Dr. Michael Lauer Information Technology. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CoreBluetooth/CoreBluetooth.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString* const LTBTLESerialTransporterDidUpdateSignalStrength;
extern NSString* const LTBTLESerialTransporterDidDiscoverDevice;

typedef void(^LTBTLESerialTransporterConnectionBlock)(NSInputStream* _Nullable inputStream, NSOutputStream* _Nullable outputStream);
typedef void(^LTBTLEDeviceDiscoveredBlock)(CBPeripheral* peripheral);

@interface LTBTLESerialTransporter : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>

@property(strong,nonatomic,readonly) NSNumber* signalStrength;
@property(strong,nonatomic,readonly) CBPeripheral* adapter;

+(instancetype)transporterWithIdentifier:(nullable NSUUID*)identifier serviceUUIDs:(NSArray<CBUUID*>*)serviceUUIDs;
-(void)connectWithIdentifier:(NSUUID*)identfier block:(LTBTLESerialTransporterConnectionBlock)block;
-(void)disconnect;
-(void)startDiscoveryWithBlock:(LTBTLEDeviceDiscoveredBlock)block;
-(void)stopDiscovery;
-(void)startUpdatingSignalStrengthWithInterval:(NSTimeInterval)interval;
-(void)stopUpdatingSignalStrength;

@end

NS_ASSUME_NONNULL_END

