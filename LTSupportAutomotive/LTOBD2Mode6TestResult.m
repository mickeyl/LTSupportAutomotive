//
//  Copyright (c) Dr. Michael Lauer Information Technology. All rights reserved.
//

#import "LTOBD2Mode6TestResult.h"

#import "LTSupportAutomotive.h"

typedef enum : NSUInteger {
    MODE_6_TID_RICH_TO_LEAN_SENSOR_VOLTAGE = 0x01,
    MODE_6_TID_LEAN_TO_RICH_SENSOR_VOLTAGE = 0x02,
    MODE_6_TID_LOW_SENSOR_VOLTAGE_FOR_SWITCH_TIME = 0x03,
    MODE_6_TID_HIGH_SENSOR_VOLTAGE_FOR_SWITCH_TIME = 0x04,
    MODE_6_TID_RICH_TO_LEAN_SENSOR_SWITCH_TIME = 0x05,
    MODE_6_TID_LEAN_TO_RICH_SENSOR_SWITCH_TIME = 0x06,
    MODE_6_TID_MAX_SENSOR_VOLTAGE_FOR_TEST_CYCLE = 0x07,
    MODE_6_TID_MIN_SENSOR_VOLTAGE_FOR_TEST_CYCLE = 0x08,
    MODE_6_TID_TIME_BETWEEN_SENSOR_TRANSITIONS = 0x09,
    MODE_6_TID_SENSOR_PERIOD = 0x0A,
    MODE_6_TID_EWMA_MISFIRE_COUNTS_PREVIOUS_CYCLES = 0x0B,
    MODE_6_TID_MISFIRE_COUNTS_CURRENT_CYCLE = 0x0C,
    // 0x0D - 0x1F ISO/SAE reserved
    MODE_6_TID_MANUFACTURER_SPECIFIC_TIME_21 = 0x21,
    MODE_6_TID_MANUFACTURER_SPECIFIC_TIME_22 = 0x22,
    MODE_6_TID_MANUFACTURER_SPECIFIC_TIME_23 = 0x23,
    MODE_6_TID_MANUFACTURER_SPECIFIC_TIME_24 = 0x24,
    MODE_6_TID_MANUFACTURER_SPECIFIC_TIME_25 = 0x25,
    MODE_6_TID_MANUFACTURER_SPECIFIC_TIME_26 = 0x26,
    MODE_6_TID_MANUFACTURER_SPECIFIC_TIME_27 = 0x27,
    MODE_6_TID_MANUFACTURER_SPECIFIC_TIME_28 = 0x28,
    MODE_6_TID_MANUFACTURER_SPECIFIC_TIME_29 = 0x29,
    MODE_6_TID_MANUFACTURER_SPECIFIC_TIME_2A = 0x2A,
    MODE_6_TID_MANUFACTURER_SPECIFIC_TIME_2B = 0x2B,
    MODE_6_TID_MANUFACTURER_SPECIFIC_TIME_2C = 0x2C,
    MODE_6_TID_MANUFACTURER_SPECIFIC_TIME_2D = 0x2D,
    MODE_6_TID_MANUFACTURER_SPECIFIC_TIME_2E = 0x2E,
    MODE_6_TID_MANUFACTURER_SPECIFIC_TIME_2F = 0x2F,
    MODE_6_TID_MANUFACTURER_SPECIFIC_TIME_30 = 0x30,
    MODE_6_TID_MANUFACTURER_SPECIFIC_TIME_31 = 0x31,
    MODE_6_TID_MANUFACTURER_SPECIFIC_TIME_32 = 0x32,
    MODE_6_TID_MANUFACTURER_SPECIFIC_TIME_33 = 0x33,
    MODE_6_TID_MANUFACTURER_SPECIFIC_TIME_34 = 0x34,
    MODE_6_TID_MANUFACTURER_SPECIFIC_TIME_35 = 0x35,
    MODE_6_TID_MANUFACTURER_SPECIFIC_TIME_36 = 0x36,
    MODE_6_TID_MANUFACTURER_SPECIFIC_TIME_37 = 0x37,
    MODE_6_TID_MANUFACTURER_SPECIFIC_TIME_38 = 0x38,
    MODE_6_TID_MANUFACTURER_SPECIFIC_TIME_39 = 0x39,
    MODE_6_TID_MANUFACTURER_SPECIFIC_TIME_3A = 0x3A,
    MODE_6_TID_MANUFACTURER_SPECIFIC_TIME_3B = 0x3B,
    MODE_6_TID_MANUFACTURER_SPECIFIC_TIME_3C = 0x3C,
    MODE_6_TID_MANUFACTURER_SPECIFIC_TIME_3D = 0x3D,
    MODE_6_TID_MANUFACTURER_SPECIFIC_TIME_3E = 0x3E,
    MODE_6_TID_MANUFACTURER_SPECIFIC_TIME_3F = 0x3F,
    MODE_6_TID_MANUFACTURER_SPECIFIC_VOLTAGE_40 = 0x40,
    MODE_6_TID_MANUFACTURER_SPECIFIC_VOLTAGE_41 = 0x41,
    MODE_6_TID_MANUFACTURER_SPECIFIC_VOLTAGE_42 = 0x42,
    MODE_6_TID_MANUFACTURER_SPECIFIC_VOLTAGE_43 = 0x43,
    MODE_6_TID_MANUFACTURER_SPECIFIC_VOLTAGE_44 = 0x44,
    MODE_6_TID_MANUFACTURER_SPECIFIC_VOLTAGE_45 = 0x45,
    MODE_6_TID_MANUFACTURER_SPECIFIC_VOLTAGE_46 = 0x46,
    MODE_6_TID_MANUFACTURER_SPECIFIC_VOLTAGE_47 = 0x47,
    MODE_6_TID_MANUFACTURER_SPECIFIC_VOLTAGE_48 = 0x48,
    MODE_6_TID_MANUFACTURER_SPECIFIC_VOLTAGE_49 = 0x49,
    MODE_6_TID_MANUFACTURER_SPECIFIC_VOLTAGE_4A = 0x4A,
    MODE_6_TID_MANUFACTURER_SPECIFIC_VOLTAGE_4B = 0x4B,
    MODE_6_TID_MANUFACTURER_SPECIFIC_VOLTAGE_4C = 0x4C,
    MODE_6_TID_MANUFACTURER_SPECIFIC_VOLTAGE_4D = 0x4D,
    MODE_6_TID_MANUFACTURER_SPECIFIC_VOLTAGE_4E = 0x4E,
    MODE_6_TID_MANUFACTURER_SPECIFIC_VOLTAGE_4F = 0x4F,
    MODE_6_TID_MANUFACTURER_SPECIFIC_VOLTAGE_50 = 0x50,
    MODE_6_TID_MANUFACTURER_SPECIFIC_VOLTAGE_51 = 0x51,
    MODE_6_TID_MANUFACTURER_SPECIFIC_VOLTAGE_52 = 0x52,
    MODE_6_TID_MANUFACTURER_SPECIFIC_VOLTAGE_53 = 0x53,
    MODE_6_TID_MANUFACTURER_SPECIFIC_VOLTAGE_54 = 0x54,
    MODE_6_TID_MANUFACTURER_SPECIFIC_VOLTAGE_55 = 0x55,
    MODE_6_TID_MANUFACTURER_SPECIFIC_VOLTAGE_56 = 0x56,
    MODE_6_TID_MANUFACTURER_SPECIFIC_VOLTAGE_57 = 0x57,
    MODE_6_TID_MANUFACTURER_SPECIFIC_VOLTAGE_58 = 0x58,
    MODE_6_TID_MANUFACTURER_SPECIFIC_VOLTAGE_59 = 0x59,
    MODE_6_TID_MANUFACTURER_SPECIFIC_VOLTAGE_5A = 0x5A,
    MODE_6_TID_MANUFACTURER_SPECIFIC_VOLTAGE_5B = 0x5B,
    MODE_6_TID_MANUFACTURER_SPECIFIC_VOLTAGE_5C = 0x5C,
    MODE_6_TID_MANUFACTURER_SPECIFIC_VOLTAGE_5D = 0x5D,
    MODE_6_TID_MANUFACTURER_SPECIFIC_VOLTAGE_5E = 0x5E,
    MODE_6_TID_MANUFACTURER_SPECIFIC_VOLTAGE_5F = 0x5F,
    MODE_6_TID_MANUFACTURER_SPECIFIC_FREQUENCY_60 = 0x60,
    MODE_6_TID_MANUFACTURER_SPECIFIC_FREQUENCY_61 = 0x61,
    MODE_6_TID_MANUFACTURER_SPECIFIC_FREQUENCY_62 = 0x62,
    MODE_6_TID_MANUFACTURER_SPECIFIC_FREQUENCY_63 = 0x63,
    MODE_6_TID_MANUFACTURER_SPECIFIC_FREQUENCY_64 = 0x64,
    MODE_6_TID_MANUFACTURER_SPECIFIC_FREQUENCY_65 = 0x65,
    MODE_6_TID_MANUFACTURER_SPECIFIC_FREQUENCY_66 = 0x66,
    MODE_6_TID_MANUFACTURER_SPECIFIC_FREQUENCY_67 = 0x67,
    MODE_6_TID_MANUFACTURER_SPECIFIC_FREQUENCY_68 = 0x68,
    MODE_6_TID_MANUFACTURER_SPECIFIC_FREQUENCY_69 = 0x69,
    MODE_6_TID_MANUFACTURER_SPECIFIC_FREQUENCY_6A = 0x6A,
    MODE_6_TID_MANUFACTURER_SPECIFIC_FREQUENCY_6B = 0x6B,
    MODE_6_TID_MANUFACTURER_SPECIFIC_FREQUENCY_6C = 0x6C,
    MODE_6_TID_MANUFACTURER_SPECIFIC_FREQUENCY_6D = 0x6D,
    MODE_6_TID_MANUFACTURER_SPECIFIC_FREQUENCY_6E = 0x6E,
    MODE_6_TID_MANUFACTURER_SPECIFIC_FREQUENCY_6F = 0x6F,
    MODE_6_TID_MANUFACTURER_SPECIFIC_COUNTER_70 = 0x70,
    MODE_6_TID_MANUFACTURER_SPECIFIC_COUNTER_71 = 0x71,
    MODE_6_TID_MANUFACTURER_SPECIFIC_COUNTER_72 = 0x72,
    MODE_6_TID_MANUFACTURER_SPECIFIC_COUNTER_73 = 0x73,
    MODE_6_TID_MANUFACTURER_SPECIFIC_COUNTER_74 = 0x74,
    MODE_6_TID_MANUFACTURER_SPECIFIC_COUNTER_75 = 0x75,
    MODE_6_TID_MANUFACTURER_SPECIFIC_COUNTER_76 = 0x76,
    MODE_6_TID_MANUFACTURER_SPECIFIC_COUNTER_77 = 0x77,
    MODE_6_TID_MANUFACTURER_SPECIFIC_COUNTER_78 = 0x78,
    MODE_6_TID_MANUFACTURER_SPECIFIC_COUNTER_79 = 0x79,
    MODE_6_TID_MANUFACTURER_SPECIFIC_COUNTER_7A = 0x7A,
    MODE_6_TID_MANUFACTURER_SPECIFIC_COUNTER_7B = 0x7B,
    MODE_6_TID_MANUFACTURER_SPECIFIC_COUNTER_7C = 0x7C,
    MODE_6_TID_MANUFACTURER_SPECIFIC_COUNTER_7D = 0x7D,
    MODE_6_TID_MANUFACTURER_SPECIFIC_COUNTER_7E = 0x7E,
    MODE_6_TID_MANUFACTURER_SPECIFIC_COUNTER_7F = 0x7F,
    // 0x80-0xFE completely vendor specific, also with regards to the unit
    // 0xFF ISO/SAE reserved
} MODE_6_TID;

@interface OBD2Mode6UnitAndScalingObject : NSObject

@property(strong,nonatomic,readonly) NSString* name;
@property(strong,nonatomic,readonly) NSString* unit;
@property(assign,nonatomic,readonly) double multiplier;
@property(assign,nonatomic,readonly) NSInteger constant;
@property(assign,nonatomic,readonly) BOOL s;
@property(strong,nonatomic,readonly) NSString* formatString;

+(instancetype)unitAndScalingObjectWithName:(NSString*)name unit:(NSString*)unit multiplier:(double)multiplier constant:(NSInteger)constant s:(BOOL)s;

@end

@implementation OBD2Mode6UnitAndScalingObject

+(instancetype)unitAndScalingObjectWithName:(NSString*)name unit:(NSString*)unit multiplier:(double)multiplier constant:(NSInteger)constant s:(BOOL)s
{
    OBD2Mode6UnitAndScalingObject* obj = [[self alloc] init];
    obj->_name = name;
    obj->_unit = unit;
    obj->_multiplier = multiplier;
    obj->_constant = constant;
    obj->_s = s;
    if ( multiplier < 1.0 )
    {
        NSUInteger numberOfFractionDigits = [@(multiplier).stringValue componentsSeparatedByString:@"."].lastObject.length;
        obj->_formatString = [[@"%." stringByAppendingString:@(numberOfFractionDigits).stringValue] stringByAppendingString:@"f"];
    }
    else
    {
        obj->_formatString = @"%.0f";
    }
    return obj;
}

@end

static NSDictionary<NSNumber*,OBD2Mode6UnitAndScalingObject*>* MODE_6_UNIT_AND_SCALING_DEFINITION;

@implementation LTOBD2Mode6TestResult

#pragma mark -
#pragma mark Lifecycle

+(void)initialize
{
    if ( self != LTOBD2Mode6TestResult.class )
    {
        return;
    }
    
    MODE_6_UNIT_AND_SCALING_DEFINITION =
    @{
      @(0x01): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Raw Value"         unit:@"–"       multiplier:1            constant:0          s:NO],
      @(0x02): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Raw Value"         unit:@"–"       multiplier:0.1          constant:0          s:NO],
      @(0x03): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Raw Value"         unit:@"–"       multiplier:0.01         constant:0          s:NO],
      @(0x04): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Raw Value"         unit:@"–"       multiplier:0.001        constant:0          s:NO],
      @(0x05): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Raw Value"         unit:@"–"       multiplier:0.0000305    constant:0          s:NO],
      @(0x06): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Raw Value"         unit:@"–"       multiplier:0.000305     constant:0          s:NO],
      @(0x07): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Rotational Freq."  unit:@"RPM"     multiplier:0.25         constant:0          s:NO],
      @(0x08): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Speed"             unit:@"km/h"    multiplier:0.01         constant:0          s:NO],
      @(0x09): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Speed"             unit:@"km/h"    multiplier:1            constant:0          s:NO],
      @(0x0A): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Voltage"           unit:@"mV"      multiplier:0.122        constant:0          s:NO],
      @(0x0B): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Voltage"           unit:@"V"       multiplier:0.001        constant:0          s:NO],
      @(0x0C): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Voltage"           unit:@"V"       multiplier:0.01         constant:0          s:NO],
      @(0x0D): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Current"           unit:@"mA"      multiplier:0.003960625  constant:0          s:NO],
      @(0x0E): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Current"           unit:@"A"       multiplier:0.001        constant:0          s:NO],
      @(0x0F): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Current"           unit:@"A"       multiplier:0.01         constant:0          s:NO],
      @(0x10): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Time"              unit:@"ms"      multiplier:1            constant:0          s:NO],
      @(0x11): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Time"              unit:@"s"       multiplier:0.1          constant:0          s:NO],
      @(0x12): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Time"              unit:@"s"       multiplier:1            constant:0          s:NO],
      @(0x13): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Resistance"        unit:@"mOhm"    multiplier:1            constant:0          s:NO],
      @(0x14): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Resistance"        unit:@"Ohm"     multiplier:1            constant:0          s:NO],
      @(0x15): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Resistance"        unit:@"kOhm"    multiplier:1            constant:0          s:NO],
      @(0x16): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Temperature"       unit:@"°C"      multiplier:0.1          constant:-40        s:NO],
      @(0x17): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Pressure (Gauge)"  unit:@"kPA"     multiplier:0.01         constant:0          s:NO],
      @(0x18): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Air Pressure"      unit:@"kPA"     multiplier:0.0117       constant:0          s:NO],
      @(0x19): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Fuel Pressure"     unit:@"kPA"     multiplier:0.079        constant:0          s:NO],
      @(0x1A): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Pressure (Gauge)"  unit:@"kPA"     multiplier:1            constant:0          s:NO],
      @(0x1B): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Diesel Pressure"   unit:@"kPA"     multiplier:10           constant:0          s:NO],
      @(0x1C): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Angle"             unit:@"°"       multiplier:0.01         constant:0          s:NO],
      @(0x1D): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Angle"             unit:@"°"       multiplier:0.5          constant:0          s:NO],
      @(0x1E): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Equivalence Ratio" unit:@"–"       multiplier:0.0000305    constant:0          s:NO],
      @(0x1F): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Air/Fuel Ratio"    unit:@"–"       multiplier:0.05         constant:0          s:NO],
      @(0x20): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Ratio"             unit:@"–"       multiplier:0.00390625   constant:0          s:NO],
      @(0x21): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Frequency"         unit:@"mHz"     multiplier:1            constant:0          s:NO],
      @(0x22): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Frequency"         unit:@"Hz"      multiplier:1            constant:0          s:NO],
      @(0x23): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Frequency"         unit:@"kHz"     multiplier:1            constant:0          s:NO],
      @(0x24): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Counts"            unit:@"#"       multiplier:1            constant:0          s:NO],
      @(0x25): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Distance"          unit:@"km"      multiplier:1            constant:0          s:NO],
      @(0x26): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Voltage per time"  unit:@"V/ms"    multiplier:0.1          constant:0          s:NO],
      @(0x27): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Mass per time"     unit:@"g/s"     multiplier:0.01         constant:0          s:NO],
      @(0x28): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Mass per time"     unit:@"g/s"     multiplier:1            constant:0          s:NO],
      @(0x29): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Pressure per time" unit:@"Pa/s"    multiplier:0.25         constant:0          s:NO],
      @(0x2A): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Mass per time"     unit:@"kg/h"    multiplier:0.001        constant:0          s:NO],
      @(0x2B): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Switches"          unit:@"#"       multiplier:1            constant:0          s:NO],
      @(0x2C): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Mass per cylinder" unit:@"g/cyl"   multiplier:0.01         constant:0          s:NO],
      @(0x2D): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Mass per stroke" unit:@"mg/stroke" multiplier:0.01         constant:0          s:NO],
      //TODO @(0x2E): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Pressure per time" unit:@"Pa/s"    multiplier:0.25         constant:0          s:NO],
      @(0x2F): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Percent"           unit:@"%"       multiplier:0.01         constant:0          s:NO],
      @(0x30): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Percent"           unit:@"%"       multiplier:0.001526     constant:0          s:NO],
      @(0x31): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Volume"            unit:@"L"       multiplier:0.001        constant:0          s:NO],
      @(0x32): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Length"            unit:@"mm"      multiplier:0.0007747    constant:0          s:NO],
      @(0x33): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Equivalence Ratio" unit:@"lambda"  multiplier:0.00024414   constant:0          s:NO],
      @(0x34): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Time"              unit:@"min"     multiplier:1            constant:0          s:NO],
      @(0x35): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Time"              unit:@"s"       multiplier:0.01         constant:0          s:NO],
      @(0x36): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Weight"            unit:@"g"       multiplier:0.01         constant:0          s:NO],
      @(0x37): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Weight"            unit:@"g"       multiplier:0.1          constant:0          s:NO],
      @(0x38): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Weight"            unit:@"g"       multiplier:1            constant:0          s:NO],
      @(0x39): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Percent"           unit:@"%"       multiplier:0.01         constant:-327.68    s:NO],
      @(0x3A): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Weight"            unit:@"g"       multiplier:0.001        constant:0          s:NO],
      @(0x3B): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Weight"            unit:@"g"       multiplier:0.0001       constant:0          s:NO],
      @(0x3C): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Time"              unit:@"µs"      multiplier:0.1          constant:0          s:NO],
      @(0x3D): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Current"           unit:@"mA"      multiplier:0.01         constant:0          s:NO],
      @(0x3E): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Area"              unit:@"mm²"  multiplier:0.00006103516   constant:0          s:NO],
      @(0x3F): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Volume"            unit:@"L"       multiplier:0.01         constant:0          s:NO],
      @(0x40): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Part per million"  unit:@"ppm"     multiplier:1            constant:0          s:NO],
      @(0x41): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Current"           unit:@"µA"      multiplier:0.01         constant:0          s:NO],
      @(0x42): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Energy"            unit:@"kJ"      multiplier:0.1          constant:0          s:NO],
      @(0x43): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Mass per kWh"      unit:@"g/kWh"   multiplier:0.00024414   constant:0          s:NO],
      // 0x44 - 0x80 not specified by SAE
      @(0x81): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Raw Value"         unit:@"–"       multiplier:1            constant:0          s:YES],
      @(0x82): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Raw Value"         unit:@"–"       multiplier:0.1          constant:0          s:YES],
      @(0x83): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Raw Value"         unit:@"–"       multiplier:0.01         constant:0          s:YES],
      @(0x84): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Raw Value"         unit:@"–"       multiplier:0.001        constant:0          s:YES],
      @(0x85): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Raw Value"         unit:@"–"       multiplier:0.0000305    constant:0          s:YES],
      @(0x86): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Raw Value"         unit:@"–"       multiplier:0.000305     constant:0          s:YES],
      @(0x87): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Part per million"  unit:@"ppm"     multiplier:1            constant:0          s:YES],
      @(0x8A): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Voltage"           unit:@"mV"      multiplier:0.122        constant:0          s:YES],
      @(0x8B): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Voltage"           unit:@"V"       multiplier:0.001        constant:0          s:YES],
      @(0x8C): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Voltage"           unit:@"V"       multiplier:0.01         constant:0          s:YES],
      @(0x8D): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Current"           unit:@"mA"      multiplier:0.00390625   constant:0          s:YES],
      @(0x8E): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Current"           unit:@"A"       multiplier:0.001        constant:0          s:YES],
      @(0x8F): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Time"              unit:@"µs"      multiplier:1            constant:0          s:YES],
      @(0x90): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Time"              unit:@"ms"      multiplier:1            constant:0          s:YES],
      @(0x91): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Time"              unit:@"s"       multiplier:0.1          constant:0          s:YES],
      @(0x92): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Torque"            unit:@"Nm"      multiplier:0.1          constant:0          s:YES],
      // 0x93 - 0x95 not specified by SAE
      @(0x96): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Temperature"       unit:@"°C"      multiplier:0.1          constant:0          s:YES],
      @(0x97): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Temp. per time"    unit:@"°C/s"    multiplier:0.01         constant:0          s:YES],
      @(0x98): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Mass per stroke" unit:@"mg/stroke" multiplier:1            constant:0          s:YES],
      @(0x99): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Pressure"          unit:@"°kPa"    multiplier:0.1          constant:0          s:YES],
      // 0x9A - 0x9B not specified by SAE
      @(0x9C): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Angle"             unit:@"°"       multiplier:0.01         constant:0          s:YES],
      @(0x9D): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Angle"             unit:@"°"       multiplier:0.5          constant:0          s:YES],
      // 0x9E - 0xA7 not specified by SAE
      @(0xA8): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Mass per time"     unit:@"g/s"     multiplier:1            constant:0          s:YES],
      @(0xA9): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Pressure per time" unit:@"PA/s"    multiplier:0.25         constant:0          s:YES],
      // 0xAA - 0xAC not specified by SAE
      @(0xAD): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Mass per stroke" unit:@"mg/stroke" multiplier:0.01         constant:0          s:YES],
      @(0xAE): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Mass per stroke" unit:@"mg/stroke" multiplier:0.1          constant:0          s:YES],
      @(0xAF): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Percent"           unit:@"%"       multiplier:0.01         constant:0          s:YES],

      @(0xB0): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Percent"           unit:@"%"       multiplier:0.003052     constant:0          s:YES],
      @(0xB1): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Voltage per time"  unit:@"mV/s"    multiplier:2            constant:0          s:YES],
      @(0xFB): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Pressure"          unit:@"kPa"     multiplier:10           constant:0          s:YES],
      @(0xFC): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Pressure"          unit:@"kPa"     multiplier:0.01         constant:0          s:YES],
      @(0xFD): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Pressure"          unit:@"kPa"     multiplier:0.001        constant:0          s:YES],
      @(0xFE): [OBD2Mode6UnitAndScalingObject unitAndScalingObjectWithName:@"Pressure"          unit:@"Pa"      multiplier:0.25         constant:0          s:YES],
    };
}

+(instancetype)resultWithMid:(NSUInteger)mid bytes:(NSArray<NSNumber*>*)bytes can:(BOOL)can
{
    return [[self alloc] initWithMid:mid bytes:bytes can:can];
}

-(instancetype)initWithMid:(NSUInteger)mid bytes:(NSArray<NSNumber*>*)bytes can:(BOOL)can;
{
    if ( ! ( self = [super init] ) )
    {
        return nil;
    }
    
    _mid = mid;
    _can = can;
    
    [self parseBytes:bytes];
    
    return self;
}

#pragma mark -
#pragma mark Helpers

-(void)parseBytes:(NSArray<NSNumber*>*)bytes
{
    //               0    1    2     3       4    5       6       7      8
    // not CAN: TLTCID TVHI    TVLO  TLHI TLLO
    // CAN:        MID S/MDTID UASID TVHI TVLO MINTLHI MINTLLO MAXTLHI MAXTLLO

    if ( _can )
    {
        if ( bytes[0].unsignedIntValue != _mid )
        {
            WARN( @" inconsistent values for mid %lu != %lu", _mid, bytes[0].unsignedIntValue );
        }
        
        _tid = bytes[1].unsignedIntValue;
        _uasid = bytes[2].unsignedIntValue;

        uint tvhi = bytes[3].unsignedIntValue;
        uint tvlo = bytes[4].unsignedIntValue;
        _current = tvlo + tvhi * 0x100;

        uint mintlhi = bytes[5].unsignedIntValue;
        uint mintllo = bytes[6].unsignedIntValue;
        _minimum = mintllo + mintlhi * 0x100;
        
        uint maxtlhi = bytes[7].unsignedIntValue;
        uint maxtllo = bytes[8].unsignedIntValue;
        _maximum = maxtllo + maxtlhi * 0x100;
    }
    else
    {
        uint tltcid = bytes[0].unsignedIntValue;
        _tid = tltcid & 0x7F;
        _limitIsMinimum = ( tltcid & 0x80 ) == 0x80;
    
        uint tvhi = bytes[1].unsignedIntValue;
        uint tvlo = bytes[2].unsignedIntValue;
        _current = tvlo + tvhi * 0x100;
        
        uint tlhi = bytes[3].unsignedIntValue;
        uint tllo = bytes[4].unsignedIntValue;
        if ( _limitIsMinimum )
        {
            _minimum = tllo + tlhi * 0x100;
        }
        else
        {
            _maximum = tllo + tlhi * 0x100;
        }
    }
}

-(double)scaleValue:(NSInteger)value usingUnitAndScaling:(OBD2Mode6UnitAndScalingObject*)unitAndScaling
{
    if ( unitAndScaling.s && ( value & 0x8000 ) )
    {
        value = -( (value ^ 0xffff) + 1);
    }
    return unitAndScaling.constant + unitAndScaling.multiplier * (double)value;
}

-(NSString*)formatCanValue:(NSInteger)value unit:(out NSString**)unit
{
    double amount = value;
    NSString* format = @"%.0f";
    NSString* u = [NSString stringWithFormat:@"%02X", (uint)_uasid];
    
    OBD2Mode6UnitAndScalingObject* unitAndScaling = [MODE_6_UNIT_AND_SCALING_DEFINITION objectForKey:@(_uasid)];
    if ( unitAndScaling )
    {
        amount = [self scaleValue:value usingUnitAndScaling:unitAndScaling];
        format = unitAndScaling.formatString;
        u = unitAndScaling.unit;
    }
    
    if ( unit )
    {
        *unit = u;
    }
    return [NSString stringWithFormat:format, amount];
}

-(NSString*)formatNonCanValue:(NSInteger)value unit:(out NSString**)unit
{
    double amount;
    NSString* format;
    NSString* u;
    
    switch ( _mid )
    {
        case MODE_6_TID_RICH_TO_LEAN_SENSOR_VOLTAGE:
        case MODE_6_TID_LEAN_TO_RICH_SENSOR_VOLTAGE:
        case MODE_6_TID_LOW_SENSOR_VOLTAGE_FOR_SWITCH_TIME:
        case MODE_6_TID_HIGH_SENSOR_VOLTAGE_FOR_SWITCH_TIME:
        case MODE_6_TID_MAX_SENSOR_VOLTAGE_FOR_TEST_CYCLE:
        case MODE_6_TID_MIN_SENSOR_VOLTAGE_FOR_TEST_CYCLE:
            amount = (double)value * 0.005;
            format = @"%.3f";
            u = @"V";
            break;

        case MODE_6_TID_RICH_TO_LEAN_SENSOR_SWITCH_TIME:
        case MODE_6_TID_LEAN_TO_RICH_SENSOR_SWITCH_TIME:
            amount = (double)value * 0.004;
            format = @"%.3f";
            u = @"s";
            break;
            
        case MODE_6_TID_TIME_BETWEEN_SENSOR_TRANSITIONS:
        case MODE_6_TID_SENSOR_PERIOD:
            amount = (double)value * 0.04;
            format = @"%.2f";
            u = @"s";
            break;
            
        case MODE_6_TID_EWMA_MISFIRE_COUNTS_PREVIOUS_CYCLES:
        case MODE_6_TID_MISFIRE_COUNTS_CURRENT_CYCLE:
            amount = (double)value;
            format = @"%.0f";
            u = @"#";
            break;

        default:
            amount = (double)value;
            format = @"%ud";
            u = @"?";
            break;
    }
    
    if ( unit )
    {
        *unit = u;
    }
    return [NSString stringWithFormat:format, amount];
}

-(NSString*)formatValue:(NSInteger)value unit:(out NSString**)unit
{
    if ( _can )
    {
        return [self formatCanValue:value unit:unit];
    }
    else
    {
        return [self formatNonCanValue:value unit:unit];
    }
}

#pragma mark -
#pragma mark API

-(BOOL)hasPassed
{
    if ( _can )
    {
        OBD2Mode6UnitAndScalingObject* unitAndScaling = [MODE_6_UNIT_AND_SCALING_DEFINITION objectForKey:@(_uasid)];
        if ( !unitAndScaling )
        {
            return YES;
        }
        double current = [self scaleValue:_current usingUnitAndScaling:unitAndScaling];
        double minimum = [self scaleValue:_minimum usingUnitAndScaling:unitAndScaling];
        double maximum = [self scaleValue:_maximum usingUnitAndScaling:unitAndScaling];
        
        return current >= minimum && current <= maximum;
    }
    else
    {
        return _limitIsMinimum ? _current >= _minimum : _current <= _maximum;
    }
}

-(NSString*)formattedTid
{
    if ( _can )
    {
        NSString* key = [NSString stringWithFormat:@"OBD2_TID_TYPE_%02X", (uint)_tid];
        NSString* placeholder = [NSString stringWithFormat:LTStringLookupWithPlaceholder(@"OBD2_TID_TYPE_VENDOR", @"Vendor specific 0x%02X"), (uint)_tid];
        NSString* localizedString = LTStringLookupWithPlaceholder(key, placeholder);
        return localizedString;
    }
    else
    {
        NSString* string = [NSString stringWithFormat:@"%@ #%u", LTStringLookupWithPlaceholder(@"OBD2_ASSEMBLY", @"Assembly"), (uint)_tid];
        return string;
    }
}

-(NSString*)formattedUnit
{
    NSString* unit;
    [self formatValue:0 unit:&unit];
    return unit;
}

-(NSString*)formattedMinimum
{
    return [self formatValue:_minimum unit:nil];
}

-(NSString*)formattedCurrent
{
    return [self formatValue:_current unit:nil];
}

-(NSString*)formattedMaximum
{
    return [self formatValue:_maximum unit:nil];
}

@end
