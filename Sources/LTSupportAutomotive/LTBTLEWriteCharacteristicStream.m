//
//  Copyright (c) Dr. Michael Lauer Information Technology. All rights reserved.
//
#import "LTBTLEWriteCharacteristicStream.h"

@implementation LTBTLEWriteCharacteristicStream
{
    __weak id<NSStreamDelegate> _delegate;
    CBCharacteristic* _characteristic;

    NSStreamStatus _status;
}

#pragma mark -
#pragma mark Lifecycle

-(instancetype)initToCharacteristic:(CBCharacteristic*)characteristic
{
    NSAssert( characteristic.properties & CBCharacteristicPropertyWrite, @"Characteristic has to offer the write property" );

    if ( ! ( self = [super init] ) )
    {
        return self;
    }

    _characteristic = characteristic;
    _delegate = self;
    _status = NSStreamStatusNotOpen;

    return self;
}

#pragma mark -
#pragma mark API

-(void)characteristicDidWriteValue
{
    [self.delegate stream:self handleEvent:NSStreamEventHasSpaceAvailable];
}

#pragma mark -
#pragma mark NSStream Overrides

-(void)setDelegate:(id<NSStreamDelegate>)delegate
{
    if ( _delegate == delegate )
    {
        return;
    }

    _delegate = delegate ?: self;
}

-(id<NSStreamDelegate>)delegate
{
    return _delegate;
}

-(void)open
{
    _status = NSStreamStatusOpening;
    _status = NSStreamStatusOpen;
    [self.delegate stream:self handleEvent:NSStreamEventOpenCompleted];
    [self.delegate stream:self handleEvent:NSStreamEventHasSpaceAvailable];
}

-(void)close
{
    _status = NSStreamStatusClosed;
    [self.delegate stream:self handleEvent:NSStreamEventEndEncountered];
}

-(void)scheduleInRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString*)mode
{
    // nothing to do here
}

-(void)removeFromRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString*)mode
{
    // nothing to do here
}

-(id)propertyForKey:(NSString *)key
{
    return nil;
}

-(BOOL)setProperty:(id)property forKey:(NSString *)key
{
    // nothing to do here
    return NO;
}

#pragma mark -
#pragma mark NSOutputStream Overrides

-(NSInteger)write:(const uint8_t *)buffer maxLength:(NSUInteger)len
{
    if ( _status != NSStreamStatusOpen )
    {
        return -1;
    }

    NSUInteger maxWriteForCharacteristic = [_characteristic.service.peripheral maximumWriteValueLengthForType:CBCharacteristicWriteWithResponse];
    NSUInteger lengthToWrite = MIN( len, maxWriteForCharacteristic );
    NSData* value = [NSData dataWithBytes:buffer length:lengthToWrite];
    [_characteristic.service.peripheral writeValue:value forCharacteristic:_characteristic type:CBCharacteristicWriteWithResponse];
    return lengthToWrite;
}

-(BOOL)hasSpaceAvailable
{
    if ( _status != NSStreamStatusOpen )
    {
        return NO;
    }
    return YES;
}

@end
