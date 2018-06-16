//
//  Copyright (c) Dr. Michael Lauer Information Technology. All rights reserved.
//

#import "LTOBD2PID.h"

#import "LTSupportAutomotive.h"

#define OBD2_NO_DATA LTStringLookupWithPlaceholder(@"OBD2_NO_DATA", @"N/A")
#define OBD2_UNKNOWN LTStringLookupWithPlaceholder(@"OBD2_UNKNOWN", @"???")

@implementation LTOBD2PID

#pragma mark -
#pragma mark Lifecycle

+(instancetype)pid
{
    NSString* className = NSStringFromClass(self.class);
    NSArray<NSString*>* stringComponents = [className componentsSeparatedByString:@"_"];
    NSString* suffix = stringComponents.lastObject;

    LTOBD2PID* obj = [[self alloc] initWithString:suffix];
    obj->_freezeFrame = NSNotFound;
    return obj;
}

+(instancetype)pidForMode1
{
    NSString* className = NSStringFromClass(self.class);
    NSArray<NSString*>* stringComponents = [className componentsSeparatedByString:@"_"];
    NSString* suffix = stringComponents.lastObject;
    NSString* string = [@"01" stringByAppendingString:suffix];

    LTOBD2PID* obj = [[self alloc] initWithString:string];
    obj->_freezeFrame = NSNotFound;
    return obj;
}

+(instancetype)pidForFreezeFrameDTC:(LTOBD2DTC*)freezeFrameDTC
{
    NSAssert( freezeFrameDTC.associatedFreezeFrame != NSNotFound, @"This initializer needs a DTC w/ an associated freeze frame" );
    NSAssert( freezeFrameDTC.associatedFreezeFrame != NSNotFound, @"This initializer needs a DTC w/ an associated ECU source" );

    NSString* className = NSStringFromClass(self.class);
    NSArray<NSString*>* stringComponents = [className componentsSeparatedByString:@"_"];
    NSString* suffix = stringComponents.lastObject;
    NSString* string = [NSString stringWithFormat:@"02%@%02X", suffix, (int)freezeFrameDTC.associatedFreezeFrame];
    
    LTOBD2PID* obj = [[self alloc] initWithString:string];
    obj->_freezeFrame = freezeFrameDTC.associatedFreezeFrame;
    obj->_selectedECU = freezeFrameDTC.ecu;
    return obj;
}

-(instancetype)initWithString:(NSString *)string
{
    return [self initWithString:string freezeFrame:NSNotFound];
}

-(instancetype)initWithString:(NSString*)string freezeFrame:(NSUInteger)freezeFrame
{
    if ( ! ( self = [super initWithString:string] ) )
    {
        return nil;
    }
    
    _freezeFrame = freezeFrame;
    
    return self;
}

-(instancetype)initWithString:(NSString*)string inFreezeFrameDTC:(LTOBD2DTC*)freezeFrameDTC
{
    NSAssert( freezeFrameDTC.associatedFreezeFrame != NSNotFound, @"This initializer needs a DTC w/ an associated freeze frame" );
    NSAssert( freezeFrameDTC.associatedFreezeFrame != NSNotFound, @"This initializer needs a DTC w/ an associated ECU source" );
    
    NSString* composedString = [NSString stringWithFormat:@"%@%02X", string, (uint)freezeFrameDTC.associatedFreezeFrame];
    if ( ! ( self = [super initWithString:composedString] ) )
    {
        return nil;
    }
    
    _freezeFrame = freezeFrameDTC.associatedFreezeFrame;
    _selectedECU = freezeFrameDTC.ecu;
    
    return self;
}

#pragma mark -
#pragma mark API for subclasses

-(NSString*)formatSingleByteDoubleValueWithString:(NSString*)formatString offset:(double)offset factor:(double)factor
{
    NSArray<NSNumber*>* responseFromAnyECU = [self anyResponseWithMinimumLength:1];
    if ( !responseFromAnyECU )
    {
        return OBD2_NO_DATA;
    }
    uint A = responseFromAnyECU[0].unsignedIntValue;
    
    double original = (double)A;
    double adapted = offset + original * factor;
    return [NSString stringWithFormat:formatString, adapted];
}

-(NSString*)formatTwoByteDoubleValueWithString:(NSString*)formatString offset:(double)offset factor:(double)factor
{
    NSArray<NSNumber*>* responseFromAnyECU = [self anyResponseWithMinimumLength:2];
    if ( !responseFromAnyECU )
    {
        return OBD2_NO_DATA;
    }
    uint A = responseFromAnyECU[0].unsignedIntValue;
    uint B = responseFromAnyECU[1].unsignedIntValue;
    
    double original = (double) ( A * 256 + B );
    double adapted = offset + original * factor;
    return [NSString stringWithFormat:formatString, adapted];
}

-(NSString*)formatSingleByteTextMappingWithString:(NSString*)formatString
{
    NSArray<NSNumber*>* responseFromAnyECU = [self anyResponseWithMinimumLength:1];
    if ( !responseFromAnyECU )
    {
        return OBD2_NO_DATA;
    }
    uint value = responseFromAnyECU[0].unsignedIntValue;
    NSString* key = [NSString stringWithFormat:formatString, value];
    NSString* placeholder = [NSString stringWithFormat:@"%@ (%02X)", OBD2_UNKNOWN, value];
    return LTStringLookupWithPlaceholder( key, placeholder );
}

-(NSString*)dtcCodeForA:(uint)A B:(uint)B
{
    NSMutableString* ms = [NSMutableString string];
    
    /*
     00	P - Powertrain
     01	C - Chassis
     10	B - Body
     11	U - Network
     */
    switch ( ( A & 0b11000000 ) >> 6 )
    {
        case 0b00:
            [ms appendString:@"P"];
            break;
            
        case 0b01:
            [ms appendString:@"C"];
            break;
            
        case 0b10:
            [ms appendString:@"B"];
            break;
            
        case 0b11:
            [ms appendString:@"U"];
            break;
    }
	
	uint aUpperNibble = ( A & 0b00110000 ) >> 4;
	uint aLowerNibble = ( A & 0b00001111 );
	uint bUpperNibble = ( B & 0b11110000 ) >> 4;
	uint bLowerNibble = ( B & 0b00001111 );
	
    [ms appendFormat:@"%c", (aUpperNibble < 10 ? 0x30 : 0x37) + aUpperNibble];
    [ms appendFormat:@"%c", (aLowerNibble < 10 ? 0x30 : 0x37) + aLowerNibble];
    [ms appendFormat:@"%c", (bUpperNibble < 10 ? 0x30 : 0x37) + bUpperNibble];
    [ms appendFormat:@"%c", (bLowerNibble < 10 ? 0x30 : 0x37) + bLowerNibble];
    
    return [NSString stringWithString:ms];
}

#pragma mark -
#pragma mark Helpers

-(NSDictionary<NSString*,NSString*>*)stringResponses
{
    if ( self.cookedResponse.count < 1 )
    {
        return nil;
    }
    
    NSMutableDictionary<NSString*,NSString*>* md = [NSMutableDictionary dictionary];
    [self.cookedResponse enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSArray<NSNumber *> * _Nonnull bytes, BOOL * _Nonnull stop) {
    
        NSMutableString* ms = [NSMutableString string];
        // if the first byte is a non-printable byte, then it indicates the number of following responses.
        // we only support one here.
        uint firstValue = bytes.firstObject.unsignedIntValue;
        NSArray<NSNumber*>* actualBytes = ( firstValue < 0x1f ) ? [bytes subarrayWithRange:NSMakeRange(1, bytes.count - 1)] : bytes;
        for ( NSNumber* asciiNumber in actualBytes )
        {
            uint c = asciiNumber.unsignedIntValue;
            if ( c > 0x1f && c < 0x7e )
            {
                [ms appendFormat:@"%c", asciiNumber.unsignedIntValue];
            }
        }
        md[key] = [NSString stringWithString:ms];
    }];
    
    return md;
}

-(NSString*)anyFormattedStringResponse
{
    NSDictionary<NSString*,NSString*>* stringResponses = [self stringResponses];
    return stringResponses.count ? [stringResponses objectForKey:stringResponses.allKeys.firstObject] : OBD2_NO_DATA;
}

-(NSString*)allFormattedStringResponses
{
    NSMutableArray<NSString*>* ma = [NSMutableArray array];
    NSDictionary<NSString*,NSString*>* stringResponses = [self stringResponses];
    
    for ( NSString* ecu in [stringResponses.allKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] )
    {
        [ma addObject:[stringResponses objectForKey:ecu]];
    }
    
    return [ma componentsJoinedByString:@", "];
}

-(NSArray<NSNumber*>*)anyResponseWithMinimumLength:(NSUInteger)minimumLength
{
    NSArray<NSString*>* sortedECUs = [self.cookedResponse.allKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    for ( NSString* ecu in sortedECUs )
    {
        NSArray<NSNumber*>* bytes = [self.cookedResponse objectForKey:ecu];
        
        if ( bytes.count >= minimumLength )
        {
            if ( _freezeFrame != NSNotFound && _selectedECU && ! [_selectedECU isEqualToString:ecu] )
            {
                continue;
            }
            return bytes;
        }
    }
    return nil;
}

@end

#pragma mark -
#pragma mark Some helper classes

@implementation LTOBD2PID_TEST_SUPPORTED_COMMANDS

+(instancetype)pidForMode:(NSUInteger)mode part:(NSUInteger)part
{
    NSAssert( part < 8, @"Part only makes sense when < 8" );
    
    NSString* string = [NSString stringWithFormat:@"%02X%02X", (uint)mode, (uint)0x20 * (uint)part];
    LTOBD2PID_TEST_SUPPORTED_COMMANDS* obj = [[self alloc] initWithString:string];
    return obj;
}

+(instancetype)pidForFreezeFrameDTC:(LTOBD2DTC *)freezeFrameDTC part:(NSUInteger)part;
{
    NSAssert( part < 8, @"Part only makes sense when < 8" );
    NSString* string = [NSString stringWithFormat:@"%02X%02X", 0x02, (uint)0x20 * (uint)part];
    LTOBD2PID_TEST_SUPPORTED_COMMANDS* obj = [[self alloc] initWithString:string inFreezeFrameDTC:freezeFrameDTC];
    return obj;
}

-(NSArray<NSNumber*>*)supportBytes
{
    NSArray<NSNumber*>* bytes = [self anyResponseWithMinimumLength:4];
    if ( !bytes.count )
    {
        return @[
                 @0,
                 @0,
                 @0,
                 @0
                 ];
    }
    // NOTE: PIDs 0900, 0920, and the like seem to have an additional 'numberOfMessages' byte before the 4 data byte.
    // NOTE: We account for that by only using the last 4 bytes.
    return @[
             [bytes objectAtIndex:bytes.count - 4],
             [bytes objectAtIndex:bytes.count - 3],
             [bytes objectAtIndex:bytes.count - 2],
             [bytes objectAtIndex:bytes.count - 1],
             ];
}

@end

@implementation LTOBD2PIDDB
{
    LTOBD2DTC* _freezeFrameDTC;
    NSUInteger _mode;
    
    NSDictionary<NSNumber*,NSNumber*>* _supported;
}

+(instancetype)dbForMode:(NSUInteger)mode
{
    LTOBD2PIDDB* obj = [[self alloc] init];
    obj->_mode = mode;
    return obj;
}

+(instancetype)dbForFreezeFrameDTC:(LTOBD2DTC*)freezeFrameDTC
{
    LTOBD2PIDDB* obj = [[self alloc] init];
    obj->_mode = 0x02;
    obj->_freezeFrameDTC = freezeFrameDTC;
    return obj;
}

-(void)populateUsingAdapter:(LTOBD2Adapter*)adapter updateHandler:(void (^)(void))updateBlock completionHandler:(void (^)(void))completionBlock
{
    NSMutableArray<LTOBD2PID_TEST_SUPPORTED_COMMANDS*>* commands = [NSMutableArray array];
    NSUInteger bytesPerResult = 4;
    NSUInteger offsetPerPart = bytesPerResult * 8;
    NSUInteger numberOfParts = 256 / offsetPerPart;
    
    for ( NSUInteger part = 0; part < numberOfParts; ++part )
    {
        LTOBD2PID_TEST_SUPPORTED_COMMANDS* command = _freezeFrameDTC ? [LTOBD2PID_TEST_SUPPORTED_COMMANDS pidForFreezeFrameDTC:_freezeFrameDTC part:part] : [LTOBD2PID_TEST_SUPPORTED_COMMANDS pidForMode:_mode part:part];
        [commands addObject:command];
    }
    
    [adapter transmitMultipleCommands:commands responseHandler:^(LTOBD2Command * _Nonnull command) {
        
        if ( command != commands.lastObject )
        {
            if ( updateBlock )
            {
                updateBlock();
                return;
            }
        }
        
        NSMutableDictionary<NSNumber*,NSNumber*>* md = [NSMutableDictionary dictionary];
        md[@00] = @YES; // we treat the xx 00 as supported
        
        for ( NSUInteger part = 0; part < numberOfParts; ++part )
        {
            LTOBD2PID_TEST_SUPPORTED_COMMANDS* command = [commands objectAtIndex:part];
            for ( NSUInteger number = 0; number < 8 * command.supportBytes.count; ++number )
            {
                uint byte = command.supportBytes[number / 8].unsignedIntValue;
                BOOL supported = byte & ( 1 << ( 7 - ( number % 8 ) ) );
                
                if ( supported )
                {
                    NSUInteger bitnumber = part * offsetPerPart + number;
                    md[@(1 + bitnumber)] = @(supported);
                    LOG( @"Adapter supports command %02X%02X", self->_mode, 1 + bitnumber );
                }
            }
        }
        self->_supported = [NSDictionary dictionaryWithDictionary:md];
        if ( completionBlock )
        {
            completionBlock();
        }
    }];
}

-(BOOL)supportsPID:(LTOBD2PID*)pid
{
    NSAssert( pid.commandString.length >= 4, @"This method only supports testing strings with a minimum length of 4" );
    
    NSString* stringByte1 = [pid.commandString substringWithRange:NSMakeRange(0, 2)];
    NSString* stringByte2 = [pid.commandString substringWithRange:NSMakeRange(2, 2)];
    uint b1 = 0;
    uint b2 = 0;
    [[NSScanner scannerWithString:stringByte1] scanHexInt:&b1];
    [[NSScanner scannerWithString:stringByte2] scanHexInt:&b2];
    
    BOOL supported = _supported[@(b2)].boolValue;
    return supported;
}

@end

#pragma mark -
#pragma mark Some abstract classes for simplification

@implementation LTOBD2PIDSingleByteTemperature

-(NSString*)formattedResponse
{
    return [self formatSingleByteDoubleValueWithString:@"%.0f" UTF8_NARROW_NOBREAK_SPACE @"°C" offset:-40 factor:1];
}

@end

@implementation LTOBD2PIDDoubleByteTemperature

-(NSString*)formattedResponse
{
    return [self formatTwoByteDoubleValueWithString:@"%.1f" UTF8_NARROW_NOBREAK_SPACE @"°C" offset:-40 factor:0.1];
}

@end

@implementation LTOBD2PIDSingleBytePercent

-(NSString*)formattedResponse
{
    return [self formatSingleByteDoubleValueWithString:@"%.1f" UTF8_NARROW_NOBREAK_SPACE @"%%" offset:0 factor:100 / 255.0];
}

@end

@implementation LTOBD2PIDStoredDTC

-(NSArray<LTOBD2DTC*>*)troubleCodes
{
    if ( ! [self anyResponseWithMinimumLength:1] )
    {
        return nil;
    }
    
    NSMutableArray<LTOBD2DTC*>* ma = [NSMutableArray array];
    
    [self.cookedResponse enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull ecu, NSArray<NSNumber *> * _Nonnull bytes, BOOL * _Nonnull stop) {
        
        NSRange codeRange = NSMakeRange(1, bytes.count-1);
        NSArray<NSNumber*>* codeBytes = [bytes subarrayWithRange:codeRange];
        
        for ( NSUInteger n = 0; n < codeBytes.count / 2; ++n )
        {
            uint A = codeBytes[2*n+0].unsignedIntValue;
            uint B = codeBytes[2*n+1].unsignedIntValue;
            
            if ( !(A + B) )
            {
                continue;
            }
            
            NSString* code = [self dtcCodeForA:A B:B];
            LTOBD2DTC* dtc = [LTOBD2DTC dtcWithCode:code ecu:ecu];
            if ( dtc )
            {
                [ma addObject:dtc];
            }
        }
    }];

    return [NSArray arrayWithArray:ma];
}

-(NSString*)formattedResponse
{
    return self.troubleCodes.description ?: OBD2_NO_DATA;
}

@end

@implementation LTOBD2PIDComponentMonitoring

-(LTOBD2MonitorResult*)monitorResultForName:(NSString*)name availableByte:(int)availableByte availableBit:(int)availableBit incompleteByte:(int)incompleteByte incompleteBit:(int)incompleteBit
{
    OBD2MonitorTestResult testResult = OBD2MonitorTestNotAvailable;
    if ( availableByte & 1 << availableBit )
    {
        testResult = (incompleteByte & 1 << incompleteBit) ? OBD2MonitorTestFailed : OBD2MonitorTestPassed;
    }
    return [LTOBD2MonitorResult resultWithTestName:name result:testResult];
}

-(NSArray<LTOBD2MonitorResult*>*)monitorResults
{
    NSArray<NSNumber*>* response = [self anyResponseWithMinimumLength:4];
    
    if ( !response )
    {
        return nil;
    }
    
    NSMutableArray<LTOBD2MonitorResult*>* ma = [NSMutableArray array];
    
    uint B = response[1].unsignedIntValue;
    uint C = response[2].unsignedIntValue;
    uint D = response[3].unsignedIntValue;
    
    [ma addObject:[self monitorResultForName:@"OBD2_MONITOR_GENERIC_B0"     availableByte:B availableBit:0 incompleteByte:B incompleteBit:4]];
    [ma addObject:[self monitorResultForName:@"OBD2_MONITOR_GENERIC_B1"     availableByte:B availableBit:1 incompleteByte:B incompleteBit:5]];
    [ma addObject:[self monitorResultForName:@"OBD2_MONITOR_GENERIC_B2"     availableByte:B availableBit:2 incompleteByte:B incompleteBit:6]];
    
    BOOL sparkIgnition = ! ( B & 1 << 3 );
    
    if ( sparkIgnition )
    {
        [ma addObject:[self monitorResultForName:@"OBD2_MONITOR_SPARK_C0"   availableByte:C availableBit:0 incompleteByte:D incompleteBit:0]];
        [ma addObject:[self monitorResultForName:@"OBD2_MONITOR_SPARK_C1"   availableByte:C availableBit:1 incompleteByte:D incompleteBit:1]];
        [ma addObject:[self monitorResultForName:@"OBD2_MONITOR_SPARK_C2"   availableByte:C availableBit:2 incompleteByte:D incompleteBit:2]];
        [ma addObject:[self monitorResultForName:@"OBD2_MONITOR_SPARK_C3"   availableByte:C availableBit:3 incompleteByte:D incompleteBit:3]];
        [ma addObject:[self monitorResultForName:@"OBD2_MONITOR_SPARK_C4"   availableByte:C availableBit:4 incompleteByte:D incompleteBit:4]];
        [ma addObject:[self monitorResultForName:@"OBD2_MONITOR_SPARK_C5"   availableByte:C availableBit:5 incompleteByte:D incompleteBit:5]];
        [ma addObject:[self monitorResultForName:@"OBD2_MONITOR_SPARK_C6"   availableByte:C availableBit:6 incompleteByte:D incompleteBit:6]];
        [ma addObject:[self monitorResultForName:@"OBD2_MONITOR_SPARK_C7"   availableByte:C availableBit:7 incompleteByte:D incompleteBit:7]];
    }
    else
    {
        [ma addObject:[self monitorResultForName:@"OBD2_MONITOR_COMPRESSION_C0"   availableByte:C availableBit:0 incompleteByte:D incompleteBit:0]];
        [ma addObject:[self monitorResultForName:@"OBD2_MONITOR_COMPRESSION_C1"   availableByte:C availableBit:1 incompleteByte:D incompleteBit:1]];
        [ma addObject:[LTOBD2MonitorResult resultWithTestName:@"OBD2_NO_DATA" result:OBD2MonitorTestNotAvailable]];
        [ma addObject:[self monitorResultForName:@"OBD2_MONITOR_COMPRESSION_C3"   availableByte:C availableBit:3 incompleteByte:D incompleteBit:3]];
        [ma addObject:[LTOBD2MonitorResult resultWithTestName:@"OBD2_NO_DATA" result:OBD2MonitorTestNotAvailable]];
        [ma addObject:[self monitorResultForName:@"OBD2_MONITOR_COMPRESSION_C5"   availableByte:C availableBit:5 incompleteByte:D incompleteBit:5]];
        [ma addObject:[self monitorResultForName:@"OBD2_MONITOR_COMPRESSION_C6"   availableByte:C availableBit:6 incompleteByte:D incompleteBit:6]];
        [ma addObject:[self monitorResultForName:@"OBD2_MONITOR_COMPRESSION_C7"   availableByte:C availableBit:7 incompleteByte:D incompleteBit:7]];
    }
    
    return [NSArray arrayWithArray:ma];
}

-(LTIgnitionType)ignitionType
{
    NSArray<NSNumber*>* response = [self anyResponseWithMinimumLength:4];
    
    if ( !response )
    {
        return LTIgnitionTypeUnknown;
    }
    
    uint B = response[1].unsignedIntValue;
    BOOL sparkIgnition = ! ( B & 1 << 3 );
    
    return sparkIgnition ? LTIgnitionTypeSpark : LTIgnitionTypeCompression;
}

@end


@implementation LTOBD2PID_OXYGEN_SENSORS_INFO_1
{
    NSUInteger _sensor;
}

+(instancetype)pidForSensor:(NSUInteger)sensor mode:(NSUInteger)mode
{
    NSAssert( sensor < 8, @"Sensor number out of range (0-7)" );
    NSString* cmd = [NSString stringWithFormat:@"%02X%02X", (uint)mode, (uint)(0x14 + sensor)];
    LTOBD2PID_OXYGEN_SENSORS_INFO_1* obj = [self commandWithString:cmd];
    obj->_sensor = sensor;
    return obj;
}

+(instancetype)pidForSensor:(NSUInteger)sensor inFreezeFrame:(NSUInteger)frame
{
    NSAssert( sensor < 8, @"Sensor number out of range (0-7)" );
    NSString* cmd = [NSString stringWithFormat:@"02%02X%02X", (uint)(0x14 + sensor), (uint)frame];
    LTOBD2PID_OXYGEN_SENSORS_INFO_1* obj = [self commandWithString:cmd];
    obj->_sensor = sensor;
    return obj;
}

-(NSString*)purpose
{
    return [super.purpose stringByAppendingFormat:@" %u", (uint)(1 + _sensor)];
}

-(double)voltage
{
    NSArray<NSNumber*>* bytes = [self anyResponseWithMinimumLength:2];
    if ( !bytes )
    {
        return 0.0;
    }
    uint A = bytes[0].unsignedIntValue;
    return A / 200.0;
}

-(double)shortTermFuelTrim
{
    NSArray<NSNumber*>* bytes = [self anyResponseWithMinimumLength:2];
    if ( !bytes )
    {
        return 0.0;
    }
    uint B = bytes[1].unsignedIntValue;
    return ( 100.0 / 128.0 * B ) - 100.0;
}

-(NSString*)formattedResponse
{
    if ( ![self anyResponseWithMinimumLength:2] )
    {
        return OBD2_NO_DATA;
    }
    return [NSString stringWithFormat:@"%.3f%@V, %.3f%@%%", self.voltage, UTF8_NARROW_NOBREAK_SPACE, self.shortTermFuelTrim, UTF8_NARROW_NOBREAK_SPACE];
}

@end


@implementation LTOBD2PID_OXYGEN_SENSORS_INFO_2
{
    NSUInteger _sensor;
}

+(instancetype)pidForSensor:(NSUInteger)sensor mode:(NSUInteger)mode
{
    NSAssert( sensor < 8, @"Sensor number out of range (0-7)" );
    NSString* cmd = [NSString stringWithFormat:@"%02X%02X", (uint)mode, (uint)(0x24 + sensor)];
    LTOBD2PID_OXYGEN_SENSORS_INFO_2* obj = [self commandWithString:cmd];
    obj->_sensor = sensor;
    return obj;
}

+(instancetype)pidForSensor:(NSUInteger)sensor inFreezeFrame:(NSUInteger)frame
{
    NSAssert( sensor < 8, @"Sensor number out of range (0-7)" );
    NSString* cmd = [NSString stringWithFormat:@"02%02X%02X", (uint)(0x24 + sensor), (uint)frame];
    LTOBD2PID_OXYGEN_SENSORS_INFO_2* obj = [self commandWithString:cmd];
    obj->_sensor = sensor;
    return obj;
}

-(NSString*)purpose
{
    return [super.purpose stringByAppendingFormat:@" %u", (uint)(1 + _sensor)];
}

-(double)fuelAirEquivalenceRatio
{
    NSArray<NSNumber*>* bytes = [self anyResponseWithMinimumLength:4];
    if ( !bytes )
    {
        return 0.0;
    }
    uint A = bytes[0].unsignedIntValue;
    uint B = bytes[1].unsignedIntValue;
    
    return 2.0 / 65536.0 * ( 256 * A + B );
}

-(double)voltage
{
    NSArray<NSNumber*>* bytes = [self anyResponseWithMinimumLength:4];
    if ( !bytes )
    {
        return 0.0;
    }
    uint C = bytes[2].unsignedIntValue;
    uint D = bytes[3].unsignedIntValue;
    
    return 8.0 / 65536.0 * ( 256 * C + D );
}

-(NSString*)formattedResponse
{
    if ( ![self anyResponseWithMinimumLength:4] )
    {
        return OBD2_NO_DATA;
    }
    return [NSString stringWithFormat:@"%.3f, %.3f" UTF8_NARROW_NOBREAK_SPACE @"V", self.fuelAirEquivalenceRatio, self.voltage];
}

@end


@implementation LTOBD2PID_OXYGEN_SENSORS_INFO_3
{
    NSUInteger _sensor;
}

+(instancetype)pidForSensor:(NSUInteger)sensor mode:(NSUInteger)mode
{
    NSAssert( sensor < 8, @"Sensor number out of range (0-7)" );
    NSString* cmd = [NSString stringWithFormat:@"%02X%02X", (uint)mode, (uint)(0x34 + sensor)];
    LTOBD2PID_OXYGEN_SENSORS_INFO_3* obj = [self commandWithString:cmd];
    obj->_sensor = sensor;
    return obj;
}

+(instancetype)pidForSensor:(NSUInteger)sensor inFreezeFrame:(NSUInteger)frame
{
    NSAssert( sensor < 8, @"Sensor number out of range (0-7)" );
    NSString* cmd = [NSString stringWithFormat:@"02%02X%02X", (uint)(0x34 + sensor), (uint)frame];
    LTOBD2PID_OXYGEN_SENSORS_INFO_3* obj = [self commandWithString:cmd];
    obj->_sensor = sensor;
    return obj;
}

-(NSString*)purpose
{
    return [super.purpose stringByAppendingFormat:@" %u", (uint)(1 + _sensor)];
}

-(double)fuelAirEquivalenceRatio
{
    NSArray<NSNumber*>* bytes = [self anyResponseWithMinimumLength:4];
    if ( !bytes )
    {
        return 0.0;
    }
    uint A = bytes[0].unsignedIntValue;
    uint B = bytes[1].unsignedIntValue;
    
    return 2.0 / 65536.0 * ( 256 * A + B );
}

-(double)current
{
    NSArray<NSNumber*>* bytes = [self anyResponseWithMinimumLength:4];
    if ( !bytes )
    {
        return 0.0;
    }
    uint C = bytes[2].unsignedIntValue;
    uint D = bytes[3].unsignedIntValue;
    
    return ( ( 256.0 * C + D ) / 256.0 ) - 128.0;
}

-(NSString*)formattedResponse
{
    if ( ![self anyResponseWithMinimumLength:4] )
    {
        return OBD2_NO_DATA;
    }
    return [NSString stringWithFormat:@"%.3f, %.3f" UTF8_NARROW_NOBREAK_SPACE @"mA", self.fuelAirEquivalenceRatio, self.current];
}

@end

@implementation LTOBD2PIDPerformanceTracking

-(NSArray<LTOBD2PerformanceTrackingResult*>*)countersForMnemonics:(NSArray<NSString*>*)mnemonics
{
    NSMutableArray<LTOBD2PerformanceTrackingResult*>* ma = [NSMutableArray array];
    
    if ( self.isCAN )
    {
        NSArray<NSNumber*>* bytes = [self anyResponseWithMinimumLength:1];
        if ( !bytes.count )
        {
            return nil;
        }
        
        NSUInteger numberOfValues = MIN( bytes[0].unsignedIntegerValue, mnemonics.count );
        for ( NSUInteger i = 0; i < numberOfValues; ++i )
        {
            if ( 1 + 2 * i + 1 > bytes.count )
            {
                break;
            }
            
            NSString* mnemonic = mnemonics[i];
            
            uint A = bytes[1 + 2 * i + 0].unsignedIntValue;
            uint B = bytes[1 + 2 * i + 1].unsignedIntValue;
            uint value = A * 256 + B;
            
            LTOBD2PerformanceTrackingResult* result = [LTOBD2PerformanceTrackingResult resultWithMnemonic:mnemonic count:value];
            if ( result )
            {
                [ma addObject:result];
            }
        }
    }
    else
    {
        NSUInteger resultPairLength = 4;
        
        NSArray<NSNumber*>* bytes = [self anyResponseWithMinimumLength:resultPairLength];
        if ( !bytes.count )
        {
            return nil;
        }
        
        NSUInteger numberOfPairs = MIN( bytes.count / resultPairLength, mnemonics.count );
        for ( NSUInteger i = 0; i < numberOfPairs; ++i )
        {
            NSString* mnemonic = mnemonics[i * 2 + 0];
            uint A = bytes[4 * i + 0].unsignedIntValue;
            uint B = bytes[4 * i + 1].unsignedIntValue;
            uint value = A * 256 + B;
            LTOBD2PerformanceTrackingResult* result = [LTOBD2PerformanceTrackingResult resultWithMnemonic:mnemonic count:value];
            if ( result )
            {
                [ma addObject:result];
            }
            mnemonic = mnemonics[i * 2 + 1];
            A = bytes[4 * i + 2].unsignedIntValue;
            B = bytes[4 * i + 3].unsignedIntValue;
            value = A * 256 + B;
            result = [LTOBD2PerformanceTrackingResult resultWithMnemonic:mnemonic count:value];
            if ( result )
            {
                [ma addObject:result];
            }
        }
    }
    
    return [NSArray arrayWithArray:ma];
}

@end


#pragma mark -
#pragma mark Mode 01 & Mode 02

@implementation LTOBD2PID_SUPPORTED_COMMANDS1_00

-(NSArray<NSString*>*)connectedECUs
{
    if ( !self.cookedResponse.count )
    {
        return nil;
    }
    
    NSMutableArray<NSString*>* ma = [NSMutableArray array];
    
    [self.cookedResponse enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSArray<NSNumber *> * _Nonnull obj, BOOL * _Nonnull stop) {
        [ma addObject:key];
    }];
    
    return [[NSArray arrayWithArray:ma] sortedArrayUsingSelector:@selector(compare:)];
}

@end

@implementation LTOBD2PID_MONITOR_STATUS_SINCE_DTC_CLEARED_01

-(NSString*)formattedResponse
{
    if ( !self.cookedResponse.count )
    {
        return OBD2_NO_DATA;
    }
    
    NSString* on = LTStringLookupWithPlaceholder( @"OBD2_ON", @"ON" );
    NSString* off = LTStringLookupWithPlaceholder( @"OBD2_OFF", @"OFF" );
    NSString* dtc = LTStringLookupWithPlaceholder( @"OBD2_DTC", @"DTC" );
    
    return [NSString stringWithFormat:@"%@, %u %@", self.motorIndicationLampOn ? on : off, (uint)self.totalNumberOfStoredDTCs, dtc];
}

-(BOOL)motorIndicationLampOn
{
    __block BOOL on = NO;
    
    [self.cookedResponse enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSArray<NSNumber *> * _Nonnull responseFromECU, BOOL * _Nonnull stop) {
        
        uint A = responseFromECU[0].unsignedIntValue;
        if ( A & 0x80 )
        {
            on = YES;
            *stop = YES;
        }

    }];
    
    return on;
}

-(NSUInteger)totalNumberOfStoredDTCs
{
    __block NSUInteger n = 0;

    [self.cookedResponse enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSArray<NSNumber *> * _Nonnull responseFromECU, BOOL * _Nonnull stop) {
        
        uint A = responseFromECU[0].unsignedIntValue;
        n += ( A & 0x7F );
        
    }];
    
    return n;
}

-(NSDictionary<NSString*,NSNumber*>*)numberOfStoredDTCsByECU
{
    NSMutableDictionary<NSString*,NSNumber*>* md = [NSMutableDictionary dictionary];
    
    [self.cookedResponse enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSArray<NSNumber *> * _Nonnull responseFromECU, BOOL * _Nonnull stop) {
        
        uint A = responseFromECU[0].unsignedIntValue;
        uint n = ( A & 0x7F );

        [md setObject:@(n) forKey:key];
        
    }];
    
    return [NSDictionary dictionaryWithDictionary:md];
}

-(LTIgnitionType)ignitionType
{
    NSArray<NSNumber*>* bytes = [self anyResponseWithMinimumLength:4];
    if ( !bytes )
    {
        return LTIgnitionTypeUnknown;
    }
    
    uint B = bytes[1].unsignedIntValue;
    BOOL sparkIgnition = ! ( B & 1 << 3 );
    
    return sparkIgnition ? LTIgnitionTypeSpark : LTIgnitionTypeCompression;
}

@end

@implementation LTOBD2PID_DTC_CAUSING_FREEZE_FRAME_02

+(instancetype)pidForFreezeFrame:(NSUInteger)freezeFrame
{
    NSAssert( freezeFrame != NSNotFound, @"This initializer needs a valid freeze frame number" );

    NSString* className = NSStringFromClass(self.class);
    NSArray<NSString*>* stringComponents = [className componentsSeparatedByString:@"_"];
    NSString* suffix = stringComponents.lastObject;
    NSString* string = [NSString stringWithFormat:@"02%@%02X", suffix, (int)freezeFrame];
    return [[self alloc] initWithString:string freezeFrame:freezeFrame];
}

-(NSArray<LTOBD2DTC*>*)troubleCodes
{
    if ( ! [self anyResponseWithMinimumLength:2] )
    {
        return nil;
    }
    
    NSMutableArray<LTOBD2DTC*>* ma = [NSMutableArray array];
    
    [self.cookedResponse enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull ecu, NSArray<NSNumber *> * _Nonnull bytes, BOOL * _Nonnull stop) {
        
        uint A = bytes[0].unsignedIntValue;
        uint B = bytes[1].unsignedIntValue;
        
        if ( (A + B) )
        {
            
            NSString* code = [self dtcCodeForA:A B:B];
            LTOBD2DTC* dtc = [LTOBD2DTC dtcWithCode:code ecu:ecu freezeFrame:self.freezeFrame];
            if ( dtc )
            {
                [ma addObject:dtc];
            }
        }
    }];
    
    return [NSArray arrayWithArray:ma];
}

-(NSString*)formattedResponse
{
    return self.troubleCodes.description ?: OBD2_NO_DATA;
}

@end

@implementation LTOBD2PID_FUEL_SYSTEM_STATUS_03

-(NSString*)formattedResponse
{
    NSArray<NSNumber*>* bytes = [self anyResponseWithMinimumLength:2];
    if ( !bytes )
    {
        return OBD2_NO_DATA;
    }
    
    uint system1 = bytes[0].unsignedIntValue;
    NSString* key = [NSString stringWithFormat:@"OBD2_FUEL_SYSTEM_STATUS_%02X", system1];
    return LTStringLookupWithPlaceholder(key, key);
}

@end

@implementation LTOBD2PID_ENGINE_LOAD_04
@end

@implementation LTOBD2PID_COOLANT_TEMP_05
@end

@implementation LTOBD2PID_SHORT_TERM_FUEL_TRIM_1_06

-(NSString*)formattedResponse
{
    return [self formatSingleByteDoubleValueWithString:@"%.0f" UTF8_NARROW_NOBREAK_SPACE @"%%" offset:-100 factor:100 / 128.0];
}

@end

@implementation LTOBD2PID_LONG_TERM_FUEL_TRIM_1_07

-(NSString*)formattedResponse
{
    return [self formatSingleByteDoubleValueWithString:@"%.0f" UTF8_NARROW_NOBREAK_SPACE @"%%" offset:-100 factor:100 / 128.0];
}

@end

@implementation LTOBD2PID_SHORT_TERM_FUEL_TRIM_2_08

-(NSString*)formattedResponse
{
    return [self formatSingleByteDoubleValueWithString:@"%.0f" UTF8_NARROW_NOBREAK_SPACE @"%%" offset:-100 factor:100 / 128.0];
}

@end

@implementation LTOBD2PID_LONG_TERM_FUEL_TRIM_2_09

-(NSString*)formattedResponse
{
    return [self formatSingleByteDoubleValueWithString:@"%.0f" UTF8_NARROW_NOBREAK_SPACE @"%%" offset:-100 factor:100 / 128.0];
}

@end

@implementation LTOBD2PID_FUEL_PRESSURE_0A

-(NSString*)formattedResponse
{
    return [self formatSingleByteDoubleValueWithString:@"%.0f" UTF8_NARROW_NOBREAK_SPACE @"kPa" offset:0 factor:3.0];
}

@end

@implementation LTOBD2PID_INTAKE_MAP_0B

-(NSString*)formattedResponse
{
    return [self formatSingleByteDoubleValueWithString:@"%.0f" UTF8_NARROW_NOBREAK_SPACE @"kPa" offset:0 factor:1.0];
}

@end

@implementation LTOBD2PID_ENGINE_RPM_0C

-(NSString*)formattedResponse
{
    NSString* string = [self formatTwoByteDoubleValueWithString:@"%.0f" UTF8_NARROW_NOBREAK_SPACE @"rpm" offset:0 factor:1 / 4.0];
    return string;
}

@end

@implementation LTOBD2PID_VEHICLE_SPEED_0D

-(NSString*)formattedResponse
{
    NSString* string = [self formatSingleByteDoubleValueWithString:@"%.0f" UTF8_NARROW_NOBREAK_SPACE @"kph" offset:0 factor:1];
    return string;
}

@end

@implementation LTOBD2PID_TIMING_ADVANCE_0E

-(NSString*)formattedResponse
{
    NSString* string = [self formatSingleByteDoubleValueWithString:@"%.0f" UTF8_NARROW_NOBREAK_SPACE @"°bf/TDC" offset:-64 factor:1 / 2.0];
    return string;
}

@end

@implementation LTOBD2PID_INTAKE_TEMP_0F
@end

@implementation LTOBD2PID_MAF_FLOW_10

-(NSString*)formattedResponse
{
    NSString* string = [self formatTwoByteDoubleValueWithString:@"%.0f" UTF8_NARROW_NOBREAK_SPACE @"g/s" offset:0 factor:1 / 100.0];
    return string;
}

@end

@implementation LTOBD2PID_THROTTLE_11
@end

@implementation LTOBD2PID_SECONDARY_AIR_STATUS_12

-(NSString*)formattedResponse
{
    return [self formatSingleByteTextMappingWithString:@"OBD2_SECONDARY_AIR_STATUS_%02X"];
}

@end

@implementation LTOBD2PID_OXYGEN_SENSORS_PRESENT_2_BANKS_13

-(NSArray<NSNumber*>*)sensors
{
    NSArray<NSNumber*>* bytes = [self anyResponseWithMinimumLength:1];
    if ( !bytes )
    {
        return nil;
    }
    NSMutableArray<NSNumber*>* ma = [NSMutableArray array];
    uint A = bytes.firstObject.unsignedIntValue;
    for ( NSUInteger i = 0; i < 8; ++i )
    {
        BOOL sensorPresent = ( A & ( 1 << i ) );
        [ma addObject:@(sensorPresent)];
    }
    return [NSArray arrayWithArray:ma];
}

-(NSString*)formattedResponse
{
    NSArray<NSNumber*>* sensorArray = self.sensors;
    if ( !sensorArray )
    {
        return OBD2_NO_DATA;
    }
    NSMutableArray<NSString*>* ma = [NSMutableArray array];
    [sensorArray enumerateObjectsUsingBlock:^(NSNumber * _Nonnull sensorIsPresent, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if ( sensorIsPresent.boolValue )
        {
            if ( idx < 4 )
            {
                [ma addObject:[NSString stringWithFormat:@"B1S%u", 1 + (uint)idx]];
            }
            else
            {
                [ma addObject:[NSString stringWithFormat:@"B2S%u", 1 + (uint)idx - 4]];
            }
        }
        
    }];
    return [ma componentsJoinedByString:@", "];
}

@end

@implementation LTOBD2PID_OXYGEN_SENSOR_INFO_1_SENSOR_0_14
@end

@implementation LTOBD2PID_OXYGEN_SENSOR_INFO_1_SENSOR_1_15
@end

@implementation LTOBD2PID_OXYGEN_SENSOR_INFO_1_SENSOR_2_16
@end

@implementation LTOBD2PID_OXYGEN_SENSOR_INFO_1_SENSOR_3_17
@end

@implementation LTOBD2PID_OXYGEN_SENSOR_INFO_1_SENSOR_4_18
@end

@implementation LTOBD2PID_OXYGEN_SENSOR_INFO_1_SENSOR_5_19
@end

@implementation LTOBD2PID_OXYGEN_SENSOR_INFO_1_SENSOR_6_1A
@end

@implementation LTOBD2PID_OXYGEN_SENSOR_INFO_1_SENSOR_7_1B
@end

@implementation LTOBD2PID_OBD_STANDARDS_1C

-(NSString*)formattedResponse
{
    return [self formatSingleByteTextMappingWithString:@"OBD2_OBD_STANDARD_%02X"];
}

@end

@implementation LTOBD2PID_OXYGEN_SENSORS_PRESENT_4_BANKS_1D

-(NSString*)formattedResponse
{
    NSArray<NSNumber*>* sensorArray = self.sensors;
    if ( !sensorArray )
    {
        return OBD2_NO_DATA;
    }
    NSArray<NSString*>* sensorInBanks = @[
                                          @"B1S1",
                                          @"B1S2",
                                          @"B2S1",
                                          @"B2S2",
                                          @"B3S1",
                                          @"B3S2",
                                          @"B4S1",
                                          @"B4S2",
                                          ];
    NSMutableArray<NSString*>* ma = [NSMutableArray array];
    [sensorArray enumerateObjectsUsingBlock:^(NSNumber * _Nonnull sensorIsPresent, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if ( sensorIsPresent.boolValue )
        {
            [ma addObject:[sensorInBanks objectAtIndex:idx]];
        }
        
    }];
    return [ma componentsJoinedByString:@", "];
}

@end

@implementation LTOBD2PID_AUX_INPUT_1E

-(NSString*)formattedResponse
{
    NSArray<NSNumber*>* bytes = [self anyResponseWithMinimumLength:1];
    if ( !bytes )
    {
        return OBD2_NO_DATA;
    }
    
    uint A = bytes[0].unsignedIntValue;
    BOOL pto = ( A & 0x01 );
    return pto ? @"PTO active" : @"PTO inactive";
}

@end

@implementation LTOBD2PID_RUNTIME_1F

-(NSString*)formattedResponse
{
    NSArray<NSNumber*>* bytes = [self anyResponseWithMinimumLength:2];
    if ( !bytes )
    {
        return OBD2_NO_DATA;
    }
    
    uint A = bytes[0].unsignedIntValue;
    uint B = bytes[1].unsignedIntValue;
    
    uint totalSeconds = 256 * A + B;
    uint seconds = totalSeconds % 60;
    uint minutes = (totalSeconds / 60) % 60;
    uint hours = totalSeconds / 3600;
    
    return [NSString stringWithFormat:@"%02u:%02u:%02u", hours, minutes, seconds];
}

@end

@implementation LTOBD2PID_DISTANCE_WITH_MIL_21

-(NSString*)formattedResponse
{
    return [self formatTwoByteDoubleValueWithString:@"%.0f" UTF8_NARROW_NOBREAK_SPACE @"km" offset:0 factor:1];
}

@end

@implementation LTOBD2PID_FUEL_RAIL_PRESSURE_22

-(NSString*)formattedResponse
{
    return [self formatTwoByteDoubleValueWithString:@"%.3f" UTF8_NARROW_NOBREAK_SPACE @"kPa" offset:0 factor:0.079];
}

@end

@implementation LTOBD2PID_FUEL_RAIL_GAUGE_PRESSURE_23

-(NSString*)formattedResponse
{
    return [self formatTwoByteDoubleValueWithString:@"%.0f" UTF8_NARROW_NOBREAK_SPACE @"kPa" offset:0 factor:10];
}

@end

@implementation LTOBD2PID_OXYGEN_SENSOR_INFO_2_SENSOR_0_24
@end

@implementation LTOBD2PID_OXYGEN_SENSOR_INFO_2_SENSOR_1_25
@end

@implementation LTOBD2PID_OXYGEN_SENSOR_INFO_2_SENSOR_2_26
@end

@implementation LTOBD2PID_OXYGEN_SENSOR_INFO_2_SENSOR_3_27
@end

@implementation LTOBD2PID_OXYGEN_SENSOR_INFO_2_SENSOR_4_28
@end

@implementation LTOBD2PID_OXYGEN_SENSOR_INFO_2_SENSOR_5_29
@end

@implementation LTOBD2PID_OXYGEN_SENSOR_INFO_2_SENSOR_6_2A
@end

@implementation LTOBD2PID_OXYGEN_SENSOR_INFO_2_SENSOR_7_2B
@end

@implementation LTOBD2PID_COMMANDED_EGR_2C
@end

@implementation LTOBD2PID_EGR_ERROR_2D

-(NSString*)formattedResponse
{
    return [self formatSingleByteDoubleValueWithString:@"%.1f" UTF8_NARROW_NOBREAK_SPACE @"%%" offset:-100 factor:100.0 / 128.0];
}

@end

@implementation LTOBD2PID_COMMANDED_EVAPORATIVE_PURGE_2E
@end

@implementation LTOBD2PID_FUEL_TANK_LEVEL_2F
@end

@implementation LTOBD2PID_WARMUPS_SINCE_DTC_CLEARED_30

-(NSString*)formattedResponse
{
    return [self formatSingleByteDoubleValueWithString:@"%.0f" offset:0 factor:1];
}

@end

@implementation LTOBD2PID_DISTANCE_SINCE_DTC_CLEARED_31

-(NSString*)formattedResponse
{
    return [self formatSingleByteDoubleValueWithString:@"%.1f" UTF8_NARROW_NOBREAK_SPACE @"km" offset:0 factor:100.0 / 255.0];
}

@end

@implementation LTOBD2PID_EVAP_SYS_VAPOR_PRESSURE_32

-(NSString*)formattedResponse
{
    NSArray<NSNumber*>* bytes = [self anyResponseWithMinimumLength:2];
    if ( !bytes )
    {
        return OBD2_NO_DATA;
    }
    
    signed char A = bytes[0].charValue;
    signed char B = bytes[0].charValue;
    int value = (1 / 4.0) * A * 256 + B;
    
    return [NSString stringWithFormat:@"%d" UTF8_NARROW_NOBREAK_SPACE @"Pa", value];
}

@end

@implementation LTOBD2PID_ABSOLUTE_BAROMETRIC_PRESSURE_33

-(NSString*)formattedResponse
{
    return [self formatSingleByteDoubleValueWithString:@"%.0f" UTF8_NARROW_NOBREAK_SPACE @"kPA" offset:0 factor:1];
}

@end

@implementation LTOBD2PID_OXYGEN_SENSOR_INFO_3_SENSOR_0_34
@end

@implementation LTOBD2PID_OXYGEN_SENSOR_INFO_3_SENSOR_1_35
@end

@implementation LTOBD2PID_OXYGEN_SENSOR_INFO_3_SENSOR_2_36
@end

@implementation LTOBD2PID_OXYGEN_SENSOR_INFO_3_SENSOR_3_37
@end

@implementation LTOBD2PID_OXYGEN_SENSOR_INFO_3_SENSOR_4_38
@end

@implementation LTOBD2PID_OXYGEN_SENSOR_INFO_3_SENSOR_5_39
@end

@implementation LTOBD2PID_OXYGEN_SENSOR_INFO_3_SENSOR_6_3A
@end

@implementation LTOBD2PID_OXYGEN_SENSOR_INFO_3_SENSOR_7_3B
@end

@implementation LTOBD2PID_CATALYST_TEMP_B1S1_3C

-(NSString*)formattedResponse
{
    return [self formatTwoByteDoubleValueWithString:@"%.2f" UTF8_NARROW_NOBREAK_SPACE @"°C" offset:-40 factor:1 / 10.0];
}

@end

@implementation LTOBD2PID_CATALYST_TEMP_B2S1_3D

-(NSString*)formattedResponse
{
    return [self formatTwoByteDoubleValueWithString:@"%.2f" UTF8_NARROW_NOBREAK_SPACE @"°C" offset:-40 factor:1 / 10.0];
}

@end

@implementation LTOBD2PID_CATALYST_TEMP_B1S2_3E

-(NSString*)formattedResponse
{
    return [self formatTwoByteDoubleValueWithString:@"%.2f" UTF8_NARROW_NOBREAK_SPACE @"°C" offset:-40 factor:1 / 10.0];
}

@end

@implementation LTOBD2PID_CATALYST_TEMP_B2S2_3F

-(NSString*)formattedResponse
{
    return [self formatTwoByteDoubleValueWithString:@"%.2f" UTF8_NARROW_NOBREAK_SPACE @"°C" offset:-40 factor:1 / 10.0];
}

@end

@implementation LTOBD2PID_MONITOR_STATUS_THIS_DRIVE_CYCLE_41
@end

@implementation LTOBD2PID_CONTROL_MODULE_VOLTAGE_42

-(NSString*)formattedResponse
{
    return [self formatTwoByteDoubleValueWithString:@"%.3f" UTF8_NARROW_NOBREAK_SPACE @"V" offset:0 factor:1 / 1000.0];
}

@end

@implementation LTOBD2PID_ABSOLUTE_ENGINE_LOAD_43
@end

@implementation LTOBD2PID_AIR_FUEL_EQUIV_RATIO_44

-(NSString*)formattedResponse
{
    return [self formatTwoByteDoubleValueWithString:@"%.3f" offset:0 factor:2 / 65536.0];
}

@end

@implementation LTOBD2PID_RELATIVE_THROTTLE_POS_45
@end

@implementation LTOBD2PID_AMBIENT_TEMP_46
@end

@implementation LTOBD2PID_ABSOLUTE_THROTTLE_POS_B_47
@end

@implementation LTOBD2PID_ABSOLUTE_THROTTLE_POS_C_48
@end

@implementation LTOBD2PID_ACC_PEDAL_POS_D_49
@end

@implementation LTOBD2PID_ACC_PEDAL_POS_E_4A
@end

@implementation LTOBD2PID_ACC_PEDAL_POS_F_4B
@end

@implementation LTOBD2PID_COMMANDED_THROTTLE_ACTUATOR_4C
@end

@implementation LTOBD2PID_TIME_WITH_MIL_4D

-(NSString*)formattedResponse
{
    NSArray<NSNumber*>* bytes = [self anyResponseWithMinimumLength:2];
    if ( !bytes )
    {
        return OBD2_NO_DATA;
    }
    
    uint A = bytes[0].unsignedIntValue;
    uint B = bytes[1].unsignedIntValue;
    uint totalMinutes = 256 * A + B;
    
    uint minutes = totalMinutes % 60;
    uint hours = (totalMinutes / 60) % 60;
    uint days = totalMinutes / 3600;
    
    return [NSString stringWithFormat:@"%02ud" UTF8_NARROW_NOBREAK_SPACE @"%02u:%02u", days, hours, minutes];
}

@end

@implementation LTOBD2PID_TIME_SINCE_DTC_CLEARED_4E

-(NSString*)formattedResponse
{
    NSArray<NSNumber*>* bytes = [self anyResponseWithMinimumLength:2];
    if ( !bytes )
    {
        return OBD2_NO_DATA;
    }
    
    uint A = bytes[0].unsignedIntValue;
    uint B = bytes[1].unsignedIntValue;
    uint totalMinutes = 256 * A + B;
    
    uint minutes = totalMinutes % 60;
    uint hours = (totalMinutes / 60) % 60;
    uint days = totalMinutes / 3600;
    
    return [NSString stringWithFormat:@"%02ud" UTF8_NARROW_NOBREAK_SPACE @"%02u:%02u", days, hours, minutes];
}

@end

@implementation LTOBD2PID_MAX_VALUE_FUEL_AIR_EQUIVALENCE_RATIO_4F

-(NSString*)formattedResponse
{
    NSArray<NSNumber*>* bytes = [self anyResponseWithMinimumLength:4];
    
    uint A = bytes[0].unsignedIntValue;
    return [NSString stringWithFormat:@"%d", A];
}

@end

@implementation LTOBD2PID_MAX_VALUE_OXYGEN_SENSOR_VOLTAGE_4F

-(NSString*)formattedResponse
{
    NSArray<NSNumber*>* bytes = [self anyResponseWithMinimumLength:4];
    
    uint B = bytes[1].unsignedIntValue;
    return [NSString stringWithFormat:@"%d" UTF8_NARROW_NOBREAK_SPACE @"V", B];
}

@end

@implementation LTOBD2PID_MAX_VALUE_OXYGEN_SENSOR_CURRENT_4F

-(NSString*)formattedResponse
{
    NSArray<NSNumber*>* bytes = [self anyResponseWithMinimumLength:4];
    
    uint C = bytes[2].unsignedIntValue;
    return [NSString stringWithFormat:@"%d" UTF8_NARROW_NOBREAK_SPACE @"mA", C];
}

@end

@implementation LTOBD2PID_MAX_VALUE_INTAKE_MAP_4F

-(NSString*)formattedResponse
{
    NSArray<NSNumber*>* bytes = [self anyResponseWithMinimumLength:4];
    
    uint D = bytes[3].unsignedIntValue;
    return [NSString stringWithFormat:@"%d" UTF8_NARROW_NOBREAK_SPACE @"kPa", 10 * D];
}

@end

@implementation LTOBD2PID_MAX_VALUE_MAF_AIR_FLOW_RATE_50

-(NSString*)formattedResponse
{
    NSArray<NSNumber*>* bytes = [self anyResponseWithMinimumLength:4];
    
    uint A = bytes[0].unsignedIntValue;
    return [NSString stringWithFormat:@"%d" UTF8_NARROW_NOBREAK_SPACE @"g/s", 10 * A];
}

@end

@implementation LTOBD2PID_FUEL_TYPE_51

-(NSString*)formattedResponse
{
    return [self formatSingleByteTextMappingWithString:@"OBD2_FUEL_TYPE_%02X"];
}

@end

@implementation LTOBD2PID_ETHANOL_FUEL_52
@end

@implementation LTOBD2PID_ABSOLUTE_EVAP_SYSTEM_VAPOR_PRESSURE_53

-(NSString*)formattedResponse
{
    return [self formatTwoByteDoubleValueWithString:@"%.2f" UTF8_NARROW_NOBREAK_SPACE @"kPA" offset:0 factor:1 / 200.0];
}

@end

@implementation LTOBD2PID_EVAP_SYSTEM_VAPOR_PRESSURE_54

-(NSString*)formattedResponse
{
    return [self formatTwoByteDoubleValueWithString:@"%.0f" UTF8_NARROW_NOBREAK_SPACE @"PA" offset:-32767 factor:1];
}

@end

@implementation LTOBD2PID_FUEL_RAIL_ABSOLUTE_PRESSURE_59

-(NSString*)formattedResponse
{
    return [self formatTwoByteDoubleValueWithString:@"%.0f" UTF8_NARROW_NOBREAK_SPACE @"kPA" offset:0 factor:10];
}

@end

@implementation LTOBD2PID_RELATIVE_ACCELERATOR_PEDAL_POSITION_5A
@end

@implementation LTOBD2PID_HYBRID_BATTERY_PERCENTAGE_5B
@end

@implementation LTOBD2PID_ENGINE_OIL_TEMP_5C
@end

@implementation LTOBD2PID_FUEL_INJECTION_TIMING_5D

-(NSString*)formattedResponse
{
    return [self formatTwoByteDoubleValueWithString:@"%.3f" UTF8_NARROW_NOBREAK_SPACE @"°" offset:-210 factor:1 / 128.0];
}

@end

@implementation LTOBD2PID_ENGINE_FUEL_RATE_5E

-(NSString*)formattedResponse
{
    return [self formatTwoByteDoubleValueWithString:@"%.3f" UTF8_NARROW_NOBREAK_SPACE @"L/h" offset:0 factor:1 / 20.0];
}

@end

@implementation LTOBD2PID_SUPPORTED_EMISSION_REQUIREMENTS_5F

-(NSString*)formattedResponse
{
    return [self formatSingleByteTextMappingWithString:@"OBD2_EMISSION_REQUIREMENTS_%02X"];
}

@end

@implementation LTOBD2PID_ENGINE_TORQUE_DEMANDED_61

-(NSString*)formattedResponse
{
    return [self formatSingleByteDoubleValueWithString:@"%.0f" UTF8_NARROW_NOBREAK_SPACE @"%%" offset:-125 factor:1];
}

@end

@implementation LTOBD2PID_ENGINE_TORQUE_PERCENTAGE_62

-(NSString*)formattedResponse
{
    return [self formatSingleByteDoubleValueWithString:@"%.0f" UTF8_NARROW_NOBREAK_SPACE @"%%" offset:-125 factor:1];
}

@end

@implementation LTOBD2PID_ENGINE_REF_TORQUE_63

-(NSString*)formattedResponse
{
    return [self formatTwoByteDoubleValueWithString:@"%.0f" UTF8_NARROW_NOBREAK_SPACE @"Nm" offset:0 factor:1];
}

@end

#pragma mark -
#pragma mark Mode 03 – Show stored Diagnostic Trouble Codes

@implementation LTOBD2PID_STORED_DTC_03
@end

#pragma mark -
#pragma mark Mode 04 – Clear Diagnostic Trouble Codes and stored values

@implementation LTOBD2PID_CLEAR_STORED_DTC_04
@end

#pragma mark -
#pragma mark Mode 05 – Oxygen Sensor Component Monitoring (not for CAN)

@implementation LTOBD2PID_SUPPORTED_PIDS_MODE_5_0500
@end

#pragma mark -
#pragma mark Mode 06 – Test Results Component Monitoring

@implementation LTOBD2PID_MODE_6_TEST_RESULTS_06
{
    NSUInteger _mid;
}

static const NSUInteger LTOBD2PID_MODE_6_PAYLOAD_LENGTH_NON_CAN = 5;
static const NSUInteger LTOBD2PID_MODE_6_PAYLOAD_LENGTH_CAN     = 9;

+(instancetype)pidForMid:(NSUInteger)mid
{
    NSAssert( mid < 0xFF, @"Mid only makes sense when < 0xFF" );
    NSString* string = [NSString stringWithFormat:@"06%02X", (uint)mid];
    
    LTOBD2PID_MODE_6_TEST_RESULTS_06* obj = [[self alloc] initWithString:string];
    obj->_mid = mid;
    return obj;
}

-(NSArray<LTOBD2Mode6TestResult*>*)testResults
{
    NSUInteger resultResponseLength = self.isCAN ? LTOBD2PID_MODE_6_PAYLOAD_LENGTH_CAN : LTOBD2PID_MODE_6_PAYLOAD_LENGTH_NON_CAN;
    NSArray<NSNumber*>* bytes = [self anyResponseWithMinimumLength:resultResponseLength]; // at least one must be present
    
    if ( !bytes.count )
    {
        return nil;
    }

    NSMutableArray<LTOBD2Mode6TestResult*>* ma = [NSMutableArray array];

    NSUInteger remaining = bytes.count;
    NSUInteger i = 0;
    
    while ( i < bytes.count )
    {
        NSRange range = NSMakeRange( i, MIN( resultResponseLength, remaining ) );
        NSArray<NSNumber*>* subarray = [bytes subarrayWithRange:range];
        
        if ( subarray.count != resultResponseLength )
        {
            LOG( @"Ignoring short answer (or filler bytes)" );
            break;
        }

        LTOBD2Mode6TestResult* testResult = [LTOBD2Mode6TestResult resultWithMid:_mid bytes:subarray can:self.isCAN];
        [ma addObject:testResult];
        
        remaining -= range.length;
        i += range.length;
    }

    return [NSArray arrayWithArray:ma];
}

-(NSString*)purpose
{
    NSString* localizedString = @"N/A";
    
    if ( self.isCAN )
    {
        NSString* key = [NSString stringWithFormat:@"OBD2_MID_TYPE_%02X", (uint)_mid];
        localizedString = LTStringLookupWithPlaceholder(key, key);
    }
    else
    {
        NSString* formatstring = LTStringLookupWithPlaceholder(@"OBD2_TID_TYPE_VENDOR", @"Vendor Specific %02X");
        NSString* placeholder = [NSString stringWithFormat:formatstring, _mid];
    
        NSString* key = [NSString stringWithFormat:@"OBD2_TID_TYPE_%02X", (uint)_mid];
        localizedString = LTStringLookupWithPlaceholder(key, placeholder);
    }
    return localizedString;
}

@end

#pragma mark -
#pragma mark Mode 07 – Pending Diagnostic Trouble Codes

@implementation LTOBD2PID_PENDING_DTC_07
@end

#pragma mark -
#pragma mark Mode 08 – Interactive Tests

#pragma mark -
#pragma mark Mode 09 – Vehicle Information

@implementation LTOBD2PID_VIN_CODE_0902

-(NSString*)formattedResponse
{
    return [self anyFormattedStringResponse];
}

@end

@implementation LTOBD2PID_CALIBRATION_ID_0904

-(NSString*)formattedResponse
{
    return [self allFormattedStringResponses];
}

@end

@implementation LTOBD2PID_CALIBRATION_VERIFICATION_0906
@end

@implementation LTOBD2PID_ECU_NAME_090A

-(NSDictionary<NSString*,NSString*>*)recognizedECUs
{
    if ( !self.cookedResponse.count )
    {
        return nil;
    }
    
    return self.stringResponses;
}

@end

@implementation LTOBD2PID_SPARK_IGNITION_PERFORMANCE_TRACKING_0908

-(NSArray<LTOBD2PerformanceTrackingResult*>*)counters
{
    NSArray<NSString*>* mnemonics = @[
                                      @"OBDCOND",
                                      @"IGNCNTR",
                                      @"CATCOMP1",
                                      @"CATCOND1",
                                      @"CATCOMP2",
                                      @"CATCOND2",
                                      @"O2SCOMP1",
                                      @"O2SCOND1",
                                      @"O2SCOMP2",
                                      @"O2SCOND2",
                                      @"EGRCOMP",
                                      @"EGRCOND",
                                      @"AIRCOMP",
                                      @"AIRCOND",
                                      @"EVAPCOMP",
                                      @"EVAPCOND",
                                      @"SO2SCOMP1",
                                      @"SO2SCOND1",
                                      @"SO2SCOMP2",
                                      @"SO2SCOND2",
                                      ];
    
    return [self countersForMnemonics:mnemonics];
}

@end

@implementation LTOBD2PID_COMPRESSION_IGNITION_PERFORMANCE_TRACKING_090B

-(NSArray<LTOBD2PerformanceTrackingResult*>*)counters
{
    NSArray<NSString*>* mnemonics = @[
                                      @"OBDCOND",
                                      @"IGNCNTR",
                                      @"HCCATCOMP",
                                      @"HCCATCOND",
                                      @"NCATCOMP",
                                      @"NCATCOND",
                                      @"NADSCOMP",
                                      @"NADSCOND",
                                      @"PMCOMP",
                                      @"PMCOND",
                                      @"EGSCOMP",
                                      @"EGSCOND",
                                      @"EGRCOMP",
                                      @"EGRCOND",
                                      @"BPCOMP",
                                      @"BPCOND",
                                      @"FUELCOMP",
                                      @"FUELCOND",
                                      ];

    return [self countersForMnemonics:mnemonics];
}

@end

#pragma mark -
#pragma mark Mode A – Permanent DTC

@implementation LTOBD2PID_PERMANENT_DTC_0A
@end

#pragma mark -
#pragma mark Mode 10 – Start Diagnostic Session

#pragma mark -
#pragma mark Mode 11 – ECU Reset

#pragma mark -
#pragma mark Mode 12 – Read Freeze Frame Data

#pragma mark -
#pragma mark Mode 13 – Read Diagnostic Trouble Codes

#pragma mark -
#pragma mark Mode 14 – Clear Diagnostic Information

#pragma mark -
#pragma mark Mode 17 – Read Status Of Diagnostic Trouble Codes

#pragma mark -
#pragma mark Mode 18 – Read Diagnostic Trouble Codes By Status

#pragma mark -
#pragma mark Mode 1A – Read ECU Id

#pragma mark -
#pragma mark Mode 20 – Stop Diagnostic Session

#pragma mark -
#pragma mark Mode 21 – Read Data By Local Id

#pragma mark -
#pragma mark Mode 22 – Read Data By Common Id

#pragma mark -
#pragma mark Mode 23 – Read Memory By Address

#pragma mark -
#pragma mark Mode 25 – Stop Repeated Data Transmission

#pragma mark -
#pragma mark Mode 26 – Set Data Rates

#pragma mark -
#pragma mark Mode 27 – Security Access

#pragma mark -
#pragma mark Mode 2C – Dynamically Define Local Id

#pragma mark -
#pragma mark Mode 2E – Write Data By Common Id

#pragma mark -
#pragma mark Mode 2F – Input Output Control By Common Id

#pragma mark -
#pragma mark Mode 30 – Input Output Control By Local Id

#pragma mark -
#pragma mark Mode 31 – Start Routine By Local ID

#pragma mark -
#pragma mark Mode 32 – Stop Routine By Local ID

#pragma mark -
#pragma mark Mode 33 – Request Routine Results By Local Id

#pragma mark -
#pragma mark Mode 34 – Request Download

#pragma mark -
#pragma mark Mode 35 – Request Upload

#pragma mark -
#pragma mark Mode 36 – Transfer data

#pragma mark -
#pragma mark Mode 37 – Request transfer exit

#pragma mark -
#pragma mark Mode 38 – Start Routine By Address

#pragma mark -
#pragma mark Mode 39 – Stop Routine By Address

#pragma mark -
#pragma mark Mode 3A – Request Routine Results By Address

#pragma mark -
#pragma mark Mode 3B – Write Data By Local Id

#pragma mark -
#pragma mark Mode 3D – Write Memory By Address

#pragma mark -
#pragma mark Mode 3E – Tester Present

@implementation LTOBD2PID_TESTER_PRESENT_3E

@end

#pragma mark -
#pragma mark Mode 81 – Start Communication

#pragma mark -
#pragma mark Mode 82 – Stop Communication

#pragma mark -
#pragma mark Mode 83 – Access Timing Parameters

#pragma mark -
#pragma mark Mode 85 – Start Programming

