//
//  Copyright (c) Dr. Michael Lauer Information Technology. All rights reserved.
//

#import "LTOBD2O2Sensor.h"

#import "LTSupportAutomotive.h"

@implementation LTOBD2O2Sensor
{
    LTOBD2PID_OXYGEN_SENSORS_INFO_1* _info1;
    LTOBD2PID_OXYGEN_SENSORS_INFO_2* _info2;
    LTOBD2PID_OXYGEN_SENSORS_INFO_3* _info3;
    
    LTOBD2PID_OXYGEN_SENSORS_PRESENT_2_BANKS_13* _banks2;
    LTOBD2PID_OXYGEN_SENSORS_PRESENT_4_BANKS_1D* _banks4;
}

+(instancetype)sensorWithNumber:(NSUInteger)number
                          info1:(LTOBD2PID_OXYGEN_SENSORS_INFO_1*)info1
                          info2:(LTOBD2PID_OXYGEN_SENSORS_INFO_2*)info2
                          info3:(LTOBD2PID_OXYGEN_SENSORS_INFO_3*)info3
                  installBanks2:(LTOBD2PID_OXYGEN_SENSORS_PRESENT_2_BANKS_13*)banks2
                  installBanks4:(LTOBD2PID_OXYGEN_SENSORS_PRESENT_4_BANKS_1D*)banks4
{
    LTOBD2O2Sensor* obj = [[self alloc] init];
    
    NSAssert( number < 8, @"Sensor number out of range (0-7)" );
    
    obj->_number = number;
    obj->_info1 = info1;
    obj->_info2 = info2;
    obj->_info3 = info3;
    obj->_banks2 = banks2;
    obj->_banks4 = banks4;
    
    LOG( @"%@", obj );
    
    return obj;
}

-(BOOL)installed
{
    if ( _banks2.gotValidAnswer )
    {
        return [_banks2.sensors objectAtIndex:_number].boolValue;
    }
    
    if ( _banks4.gotValidAnswer )
    {
        return [_banks4.sensors objectAtIndex:_number].boolValue;
    }
    
    return NO;
}

-(NSString*)formattedLocation
{
    NSArray<NSNumber*>* banks = _banks2.gotValidAnswer  ? @[ @1, @1, @1, @1, @2, @2, @2, @2 ] : @[ @1, @1, @2, @2, @3, @3, @4, @4 ];
    NSArray<NSNumber*>* sensors = _banks2.gotValidAnswer ? @[ @1, @2, @3, @4, @1, @2, @3, @4 ] : @[ @1, @2, @1, @2, @1, @2, @1, @2 ];
    
    NSString* bankLabel = LTStringLookupWithPlaceholder( @"OBD2_BANK", @"Bank" );
    NSString* sensorLabel = LTStringLookupWithPlaceholder( @"OBD2_SENSOR", @"Sensor" );
    
    return [NSString stringWithFormat:@"%@ %@ %@ %@", bankLabel, banks[_number], sensorLabel, sensors[_number]];
}

-(NSString*)formattedType
{
    if ( _info1.gotValidAnswer )
    {
        return LTStringLookupWithPlaceholder( @"O2SENSOR_TYPE_CONVENTIONAL", @"Conventional" );
    }
    if ( _info2.gotValidAnswer || _info3.gotValidAnswer )
    {
        return LTStringLookupWithPlaceholder( @"O2SENSOR_TYPE_WIDERANGE", @"Widerange/Linear" );
    }
    else
    {
        return LTStringLookupWithPlaceholder( @"O2SENSOR_TYPE_UNKNOWN", @"Unknown Type" );
    }
}

-(NSString*)formattedKey1
{
    if ( _info1.gotValidAnswer )
    {
        return LTStringLookupWithPlaceholder( @"O2SENSOR_UNIT_VOLTAGE", @"Unit Voltage" );
    }
    
    if ( _info2.gotValidAnswer )
    {
        return LTStringLookupWithPlaceholder( @"AIR_FUEL_EQUIV_RATIO", @"Fuel/Air Equivalence Ratio" );
    }
    
    if ( _info3.gotValidAnswer )
    {
        return LTStringLookupWithPlaceholder( @"AIR_FUEL_EQUIV_RATIO", @"Fuel/Air Equivalence Ratio" );
    }
    
    return nil;
}

-(NSString*)formattedKey2
{
    if ( _info1.gotValidAnswer )
    {
        return LTStringLookupWithPlaceholder( @"O2SENSOR_UNIT_STFT", @"Short Term Fuel Trim" );
    }
    
    if ( _info2.gotValidAnswer )
    {
        return LTStringLookupWithPlaceholder( @"O2SENSOR_UNIT_VOLTAGE", @"Unit Voltage" );
    }
    
    if ( _info3.gotValidAnswer )
    {
        return LTStringLookupWithPlaceholder( @"O2SENSOR_UNIT_CURRENT", @"Unit Current" );
    }
    
    return nil;
}

-(NSString*)formattedKey3
{
    if ( _info2.gotValidAnswer && _info3.gotValidAnswer )
    {
        return LTStringLookupWithPlaceholder( @"AIR_FUEL_EQUIV_RATIO", @"Fuel/Air Equivalence Ratio" );
    }
    
    return nil;
}

-(NSString*)formattedKey4
{
    if ( _info2.gotValidAnswer && _info3.gotValidAnswer )
    {
        return LTStringLookupWithPlaceholder( @"O2SENSOR_UNIT_CURRENT", @"Unit Current" );
    }
    
    return nil;
}


-(NSString*)formattedValue1
{
    if ( _info1.gotValidAnswer )
    {
        return [NSString stringWithFormat:@"%.3f" UTF8_NARROW_NOBREAK_SPACE "V", _info1.voltage];
    }
    
    if ( _info2.gotValidAnswer )
    {
        return [NSString stringWithFormat:@"%.3f", _info2.fuelAirEquivalenceRatio];
    }
    
    if ( _info3.gotValidAnswer )
    {
        return [NSString stringWithFormat:@"%.3f", _info3.fuelAirEquivalenceRatio];
    }
    
    return nil;
}

-(NSString*)formattedValue2
{
    if ( _info1.gotValidAnswer )
    {
        return [NSString stringWithFormat:@"%.1f" UTF8_NARROW_NOBREAK_SPACE "%%", _info1.shortTermFuelTrim];
    }
    
    if ( _info2.gotValidAnswer )
    {
        return [NSString stringWithFormat:@"%.3f" UTF8_NARROW_NOBREAK_SPACE "V", _info2.voltage];
    }
    
    if ( _info3.gotValidAnswer )
    {
        return [NSString stringWithFormat:@"%.3f" UTF8_NARROW_NOBREAK_SPACE "mA", _info3.current];
    }
    
    return nil;
}

-(NSString*)formattedValue3
{
    if ( _info2.gotValidAnswer && _info3.gotValidAnswer )
    {
        return [NSString stringWithFormat:@"%.3f", _info3.fuelAirEquivalenceRatio];
    }
    
    return nil;
}

-(NSString*)formattedValue4
{
    if ( _info2.gotValidAnswer && _info3.gotValidAnswer )
    {
        return [NSString stringWithFormat:@"%.3f" UTF8_NARROW_NOBREAK_SPACE "mA", _info3.current];
    }
    
    return nil;
}

-(NSString*)description
{
    return [NSString stringWithFormat:@"<LTOBD2O2Sensor %u i1:%@ i2:%@ i3:%@>", (uint)_number, _info1.gotValidAnswer ? @"YES" : @"NO", _info2.gotValidAnswer ? @"YES" : @"NO", _info3.gotValidAnswer ? @"YES" : @"NO"];
}


@end
