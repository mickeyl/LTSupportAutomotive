//
//  Copyright (c) Dr. Michael Lauer Information Technology. All rights reserved.
//

#import "LTBTLEReadCharacteristicStream.h"

@implementation LTBTLEReadCharacteristicStream
{
    __unsafe_unretained id<NSStreamDelegate> _delegate;

    __weak CBPeripheral* _peripheral;
    CBCharacteristic* _characteristic;
    
    NSStreamStatus _status;
    NSMutableData* _buffer;
}

#pragma mark -
#pragma mark Lifecycle

-(instancetype)initWithCharacteristic:(CBCharacteristic*)characteristic
{
    if ( ! ( self = [super init] ) )
    {
        return nil;
    }
    
    _characteristic = characteristic;
    _peripheral = _characteristic.service.peripheral;
    _delegate = self;
    _status = NSStreamStatusNotOpen;
    
    return self;
}

#pragma mark -
#pragma mark API

-(void)characteristicDidUpdateValue
{
    NSData* value = _characteristic.value;
    [_buffer appendData:value];
    [self.delegate stream:self handleEvent:NSStreamEventHasBytesAvailable];
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
    _buffer = [NSMutableData data];
    _status = NSStreamStatusOpen;
    [self.delegate stream:self handleEvent:NSStreamEventOpenCompleted];
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
#pragma mark NSInputStream Overrides

-(NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)len
{
    if ( _status != NSStreamStatusOpen )
    {
        return -1;
    }
    
    NSUInteger maxBytesToRead = MIN( len, _buffer.length );
    memcpy( buffer, _buffer.bytes, maxBytesToRead );
    
    if ( len < _buffer.length )
    {
        NSData* remainingBuffer = [NSData dataWithBytes:_buffer.bytes + maxBytesToRead length:_buffer.length - maxBytesToRead];
        [_buffer setData:remainingBuffer];
    }
    else
    {
        _buffer = [NSMutableData data];
    }
    
    return maxBytesToRead;
}

-(BOOL)getBuffer:(uint8_t * _Nullable * _Nonnull)buffer length:(NSUInteger *)len
{
    return NO;
}

-(BOOL)hasBytesAvailable
{
    if ( _status != NSStreamStatusOpen )
    {
        return NO;
    }
    
    return _buffer.length > 0;
}

-(void)dealloc {
    _delegate = nil;
}

@end
