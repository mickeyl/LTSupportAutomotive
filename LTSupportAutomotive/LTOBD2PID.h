//
//  Copyright (c) Dr. Michael Lauer Information Technology. All rights reserved.
//

#import <LTSupportAutomotive/LTSupportAutomotive.h>

NS_ASSUME_NONNULL_BEGIN

@class LTOBD2DTC;
@class LTOBD2MonitorResult;
@class LTOBD2PerformanceTrackingResult;
@class LTOBD2Mode6TestResult;

typedef enum : NSUInteger {
    LTIgnitionTypeUnknown,
    LTIgnitionTypeSpark,
    LTIgnitionTypeCompression,
} LTIgnitionType;

#pragma mark -
#pragma mark PID Base class

@interface LTOBD2PID : LTOBD2Command

+(instancetype)pidForMode1; // mode 1
+(instancetype)pidForFreezeFrameDTC:(LTOBD2DTC*)freezeFrameDTC; // mode 2, freeze frame w/ ECU selection
+(instancetype)pid; // mode 3-n

@property(assign,nonatomic,readonly) NSInteger freezeFrame; // NSNotFound, if not applicable
@property(strong,nonatomic,readonly) NSString* selectedECU; // nil, if not applicable

@end

#pragma mark -
#pragma mark Helper class to check for individual PID support

@interface LTOBD2PID_TEST_SUPPORTED_COMMANDS : LTOBD2PID

+(instancetype)pid NS_UNAVAILABLE;
+(instancetype)pidForMode1 NS_UNAVAILABLE;
+(instancetype)pidForFreezeFrame:(NSUInteger)freezeFrame NS_UNAVAILABLE;
+(instancetype)pidForFreezeFrameDTC:(LTOBD2DTC *)freezeFrameDTC NS_UNAVAILABLE;

+(instancetype)pidForMode:(NSUInteger)mode part:(NSUInteger)part;
+(instancetype)pidForFreezeFrameDTC:(LTOBD2DTC *)freezeFrameDTC part:(NSUInteger)part;

-(NSArray<NSNumber*>*)supportBytes;

@end

@interface LTOBD2PIDDB : NSObject

+(instancetype)dbForMode:(NSUInteger)mode;
+(instancetype)dbForFreezeFrameDTC:(LTOBD2DTC*)freezeFrameDTC;

-(void)populateUsingAdapter:(LTOBD2Adapter*)adapter updateHandler:(void (^)(void))updateBlock completionHandler:(void (^)(void))completionBlock;
-(BOOL)supportsPID:(LTOBD2PID*)pid;

@end

#pragma mark -
#pragma mark Some abstract classes to simplify

/**
 Abstract subclass for PIDs which deocde to a single Integer payload value.
 */
@interface LTOBD2PIDInteger : LTOBD2PID
@end

/**
 Abstract subclass for PIDs which deocde to a single Double payload value.
 */
@interface LTOBD2PIDDouble : LTOBD2PID
@end

@interface LTOBD2PIDSingleByteTemperature : LTOBD2PIDDouble
@end

@interface LTOBD2PIDDoubleByteTemperature : LTOBD2PIDDouble
@end

@interface LTOBD2PIDSingleBytePercent : LTOBD2PIDDouble
@end

@interface LTOBD2PIDStoredDTC : LTOBD2PID

@property(nonatomic,readonly) NSArray<LTOBD2DTC*>* troubleCodes;

@end

@interface LTOBD2PIDComponentMonitoring : LTOBD2PID

@property(nonatomic,readonly) NSArray<LTOBD2MonitorResult*>* monitorResults;
@property(nonatomic,readonly) LTIgnitionType ignitionType;

@end

@interface LTOBD2PID_OXYGEN_SENSORS_INFO_1 : LTOBD2PID

+(instancetype)pid NS_UNAVAILABLE;
+(instancetype)pidForSensor:(NSUInteger)sensor mode:(NSUInteger)mode;
+(instancetype)pidForSensor:(NSUInteger)sensor inFreezeFrame:(NSUInteger)frame;

@property(nonatomic,readonly) double voltage;
@property(nonatomic,readonly) double shortTermFuelTrim;

@end

@interface LTOBD2PID_OXYGEN_SENSORS_INFO_2 : LTOBD2PID

+(instancetype)pid NS_UNAVAILABLE;
+(instancetype)pidForSensor:(NSUInteger)sensor mode:(NSUInteger)mode;
+(instancetype)pidForSensor:(NSUInteger)sensor inFreezeFrame:(NSUInteger)frame;

@property(nonatomic,readonly) double fuelAirEquivalenceRatio;
@property(nonatomic,readonly) double voltage;

@end

@interface LTOBD2PID_OXYGEN_SENSORS_INFO_3 : LTOBD2PID

+(instancetype)pid NS_UNAVAILABLE;
+(instancetype)pidForSensor:(NSUInteger)sensor mode:(NSUInteger)mode;
+(instancetype)pidForSensor:(NSUInteger)sensor inFreezeFrame:(NSUInteger)frame;

@property(nonatomic,readonly) double fuelAirEquivalenceRatio;
@property(nonatomic,readonly) double current;

@end

@interface LTOBD2PIDPerformanceTracking : LTOBD2PID

+(instancetype)pidForMode1 NS_UNAVAILABLE;
+(instancetype)pidForFreezeFrameDTC:(LTOBD2DTC *)freezeFrameDTC NS_UNAVAILABLE;

@property(nonatomic,readonly) NSArray<LTOBD2PerformanceTrackingResult*>* counters;

@end

#pragma mark -
#pragma mark Mode 01 & Mode 02

@interface LTOBD2PID_SUPPORTED_COMMANDS1_00 : LTOBD2PID

@property(nonatomic,readonly) NSArray<NSString*>* connectedECUs;

@end

@interface LTOBD2PID_MONITOR_STATUS_THIS_DRIVE_CYCLE_41 : LTOBD2PIDComponentMonitoring
@end

@interface LTOBD2PID_MONITOR_STATUS_SINCE_DTC_CLEARED_01 : LTOBD2PIDComponentMonitoring

+(instancetype)pidForFreezeFrame:(NSUInteger)freezeFrame NS_UNAVAILABLE;
+(instancetype)pidForFreezeFrameDTC:(LTOBD2DTC *)freezeFrameDTC NS_UNAVAILABLE;

@property(nonatomic,readonly) BOOL motorIndicationLampOn;
@property(nonatomic,readonly) NSUInteger totalNumberOfStoredDTCs;
@property(nonatomic,readonly) NSDictionary<NSString*,NSNumber*>* numberOfStoredDTCsByECU;
@property(nonatomic,readonly) LTIgnitionType ignitionType;

@end

@interface LTOBD2PID_DTC_CAUSING_FREEZE_FRAME_02 : LTOBD2PID

+(instancetype)pid NS_UNAVAILABLE;
+(instancetype)pidForMode1 NS_UNAVAILABLE;
+(instancetype)pidForFreezeFrame:(NSUInteger)freezeFrame; // mode 2, no ECU selection

@property(nonatomic,readonly) NSArray<LTOBD2DTC*>* troubleCodes;

@end

@interface LTOBD2PID_FUEL_SYSTEM_STATUS_03 : LTOBD2PID

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_ENGINE_LOAD_04 : LTOBD2PIDSingleBytePercent

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_COOLANT_TEMP_05 : LTOBD2PIDSingleByteTemperature

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_SHORT_TERM_FUEL_TRIM_1_06 : LTOBD2PID

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_LONG_TERM_FUEL_TRIM_1_07 : LTOBD2PID

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_SHORT_TERM_FUEL_TRIM_2_08 : LTOBD2PID

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_LONG_TERM_FUEL_TRIM_2_09 : LTOBD2PID

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_FUEL_PRESSURE_0A : LTOBD2PID

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_INTAKE_MAP_0B : LTOBD2PID

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_ENGINE_RPM_0C : LTOBD2PIDDouble

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_VEHICLE_SPEED_0D : LTOBD2PID

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_TIMING_ADVANCE_0E : LTOBD2PID

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_INTAKE_TEMP_0F : LTOBD2PIDSingleByteTemperature

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_MAF_FLOW_10 : LTOBD2PID

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_THROTTLE_11 : LTOBD2PIDSingleBytePercent

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_SECONDARY_AIR_STATUS_12 : LTOBD2PID

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_OXYGEN_SENSORS_PRESENT_2_BANKS_13 : LTOBD2PID

+(instancetype)pid NS_UNAVAILABLE;

@property(nonatomic,readonly) NSArray<NSNumber*>* sensors;

@end

@interface LTOBD2PID_OXYGEN_SENSOR_INFO_1_SENSOR_0_14 : LTOBD2PID_OXYGEN_SENSORS_INFO_1
@end

@interface LTOBD2PID_OXYGEN_SENSOR_INFO_1_SENSOR_1_15 : LTOBD2PID_OXYGEN_SENSORS_INFO_1
@end

@interface LTOBD2PID_OXYGEN_SENSOR_INFO_1_SENSOR_2_16 : LTOBD2PID_OXYGEN_SENSORS_INFO_1
@end

@interface LTOBD2PID_OXYGEN_SENSOR_INFO_1_SENSOR_3_17 : LTOBD2PID_OXYGEN_SENSORS_INFO_1
@end

@interface LTOBD2PID_OXYGEN_SENSOR_INFO_1_SENSOR_4_18 : LTOBD2PID_OXYGEN_SENSORS_INFO_1
@end

@interface LTOBD2PID_OXYGEN_SENSOR_INFO_1_SENSOR_5_19 : LTOBD2PID_OXYGEN_SENSORS_INFO_1
@end

@interface LTOBD2PID_SUPPORTED_COMMANDS2_20 : LTOBD2PID
@end

@interface LTOBD2PID_OXYGEN_SENSOR_INFO_1_SENSOR_6_1A : LTOBD2PID_OXYGEN_SENSORS_INFO_1
@end

@interface LTOBD2PID_OXYGEN_SENSOR_INFO_1_SENSOR_7_1B : LTOBD2PID_OXYGEN_SENSORS_INFO_1
@end

@interface LTOBD2PID_OBD_STANDARDS_1C : LTOBD2PID

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_OXYGEN_SENSORS_PRESENT_4_BANKS_1D : LTOBD2PID_OXYGEN_SENSORS_PRESENT_2_BANKS_13

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_AUX_INPUT_1E : LTOBD2PID

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_RUNTIME_1F : LTOBD2PID

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_DISTANCE_WITH_MIL_21 : LTOBD2PID

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_FUEL_RAIL_PRESSURE_22 : LTOBD2PID

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_FUEL_RAIL_GAUGE_PRESSURE_23 : LTOBD2PID

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_OXYGEN_SENSOR_INFO_2_SENSOR_0_24 : LTOBD2PID_OXYGEN_SENSORS_INFO_2
@end

@interface LTOBD2PID_OXYGEN_SENSOR_INFO_2_SENSOR_1_25 : LTOBD2PID_OXYGEN_SENSORS_INFO_2
@end

@interface LTOBD2PID_OXYGEN_SENSOR_INFO_2_SENSOR_2_26 : LTOBD2PID_OXYGEN_SENSORS_INFO_2
@end

@interface LTOBD2PID_OXYGEN_SENSOR_INFO_2_SENSOR_3_27 : LTOBD2PID_OXYGEN_SENSORS_INFO_2
@end

@interface LTOBD2PID_OXYGEN_SENSOR_INFO_2_SENSOR_4_28 : LTOBD2PID_OXYGEN_SENSORS_INFO_2
@end

@interface LTOBD2PID_OXYGEN_SENSOR_INFO_2_SENSOR_5_29 : LTOBD2PID_OXYGEN_SENSORS_INFO_2
@end

@interface LTOBD2PID_OXYGEN_SENSOR_INFO_2_SENSOR_6_2A : LTOBD2PID_OXYGEN_SENSORS_INFO_2
@end

@interface LTOBD2PID_OXYGEN_SENSOR_INFO_2_SENSOR_7_2B : LTOBD2PID_OXYGEN_SENSORS_INFO_2
@end

@interface LTOBD2PID_COMMANDED_EGR_2C : LTOBD2PIDSingleBytePercent

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_EGR_ERROR_2D : LTOBD2PID

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_COMMANDED_EVAPORATIVE_PURGE_2E : LTOBD2PIDSingleBytePercent

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_FUEL_TANK_LEVEL_2F : LTOBD2PIDSingleBytePercent

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_WARMUPS_SINCE_DTC_CLEARED_30 : LTOBD2PID

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_DISTANCE_SINCE_DTC_CLEARED_31 : LTOBD2PID

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_EVAP_SYS_VAPOR_PRESSURE_32 : LTOBD2PID

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_ABSOLUTE_BAROMETRIC_PRESSURE_33 : LTOBD2PID
@end

@interface LTOBD2PID_OXYGEN_SENSOR_INFO_3_SENSOR_0_34 : LTOBD2PID_OXYGEN_SENSORS_INFO_3
@end

@interface LTOBD2PID_OXYGEN_SENSOR_INFO_3_SENSOR_1_35 : LTOBD2PID_OXYGEN_SENSORS_INFO_3
@end

@interface LTOBD2PID_OXYGEN_SENSOR_INFO_3_SENSOR_2_36 : LTOBD2PID_OXYGEN_SENSORS_INFO_3
@end

@interface LTOBD2PID_OXYGEN_SENSOR_INFO_3_SENSOR_3_37 : LTOBD2PID_OXYGEN_SENSORS_INFO_3
@end

@interface LTOBD2PID_OXYGEN_SENSOR_INFO_3_SENSOR_4_38 : LTOBD2PID_OXYGEN_SENSORS_INFO_3
@end

@interface LTOBD2PID_OXYGEN_SENSOR_INFO_3_SENSOR_5_39 : LTOBD2PID_OXYGEN_SENSORS_INFO_3
@end

@interface LTOBD2PID_OXYGEN_SENSOR_INFO_3_SENSOR_6_3A : LTOBD2PID_OXYGEN_SENSORS_INFO_3
@end

@interface LTOBD2PID_OXYGEN_SENSOR_INFO_3_SENSOR_7_3B : LTOBD2PID_OXYGEN_SENSORS_INFO_3
@end

@interface LTOBD2PID_CATALYST_TEMP_B1S1_3C : LTOBD2PIDDoubleByteTemperature

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_CATALYST_TEMP_B2S1_3D : LTOBD2PIDDoubleByteTemperature

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_CATALYST_TEMP_B1S2_3E : LTOBD2PIDDoubleByteTemperature

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_CATALYST_TEMP_B2S2_3F : LTOBD2PIDDoubleByteTemperature

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_SUPPORTED_COMMANDS3_40 : LTOBD2PID
@end

@interface LTOBD2PID_CONTROL_MODULE_VOLTAGE_42 : LTOBD2PID

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_ABSOLUTE_ENGINE_LOAD_43 : LTOBD2PIDSingleBytePercent

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_AIR_FUEL_EQUIV_RATIO_44 : LTOBD2PID

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_RELATIVE_THROTTLE_POS_45 : LTOBD2PIDSingleBytePercent

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_AMBIENT_TEMP_46 : LTOBD2PIDSingleByteTemperature

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_ABSOLUTE_THROTTLE_POS_B_47 : LTOBD2PIDSingleBytePercent

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_ABSOLUTE_THROTTLE_POS_C_48 : LTOBD2PIDSingleBytePercent

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_ACC_PEDAL_POS_D_49 : LTOBD2PIDSingleBytePercent

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_ACC_PEDAL_POS_E_4A : LTOBD2PIDSingleBytePercent

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_ACC_PEDAL_POS_F_4B : LTOBD2PIDSingleBytePercent

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_COMMANDED_THROTTLE_ACTUATOR_4C : LTOBD2PIDSingleBytePercent

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_TIME_WITH_MIL_4D : LTOBD2PID

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_TIME_SINCE_DTC_CLEARED_4E : LTOBD2PID

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_MAX_VALUE_FUEL_AIR_EQUIVALENCE_RATIO_4F : LTOBD2PID

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_MAX_VALUE_OXYGEN_SENSOR_VOLTAGE_4F : LTOBD2PID

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_MAX_VALUE_OXYGEN_SENSOR_CURRENT_4F : LTOBD2PID

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_MAX_VALUE_INTAKE_MAP_4F : LTOBD2PID

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_MAX_VALUE_MAF_AIR_FLOW_RATE_50 : LTOBD2PID

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_FUEL_TYPE_51 : LTOBD2PID

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_ETHANOL_FUEL_52 : LTOBD2PIDSingleBytePercent

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_ABSOLUTE_EVAP_SYSTEM_VAPOR_PRESSURE_53 : LTOBD2PID

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_EVAP_SYSTEM_VAPOR_PRESSURE_54 : LTOBD2PID

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_FUEL_RAIL_ABSOLUTE_PRESSURE_59 : LTOBD2PID

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_RELATIVE_ACCELERATOR_PEDAL_POSITION_5A : LTOBD2PIDSingleBytePercent

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_HYBRID_BATTERY_PERCENTAGE_5B : LTOBD2PIDSingleBytePercent

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_ENGINE_OIL_TEMP_5C : LTOBD2PIDSingleByteTemperature

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_FUEL_INJECTION_TIMING_5D : LTOBD2PID

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_ENGINE_FUEL_RATE_5E : LTOBD2PID

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_SUPPORTED_EMISSION_REQUIREMENTS_5F : LTOBD2PID

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_SUPPORTED_COMMANDS4_60 : LTOBD2PID
@end

@interface LTOBD2PID_ENGINE_TORQUE_DEMANDED_61 : LTOBD2PID

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_ENGINE_TORQUE_PERCENTAGE_62 : LTOBD2PID

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_ENGINE_REF_TORQUE_63 : LTOBD2PID

+(instancetype)pid NS_UNAVAILABLE;

@end

@interface LTOBD2PID_SUPPORTED_COMMANDS5_80 : LTOBD2PID
@end

@interface LTOBD2PID_SUPPORTED_COMMANDS6_A0 : LTOBD2PID
@end

@interface LTOBD2PID_ODOMETER_A6 : LTOBD2PID
@end

#pragma mark -
#pragma mark Mode 03 – Show stored Diagnostic Trouble Codes

@interface LTOBD2PID_STORED_DTC_03 : LTOBD2PIDStoredDTC

+(instancetype)pidForMode1 NS_UNAVAILABLE;
+(instancetype)pidForFreezeFrameDTC:(LTOBD2DTC *)freezeFrameDTC NS_UNAVAILABLE;

@end

#pragma mark -
#pragma mark Mode 04 – Clear Diagnostic Trouble Codes and stored values

@interface LTOBD2PID_CLEAR_STORED_DTC_04 : LTOBD2PID

+(instancetype)pidForMode1 NS_UNAVAILABLE;
+(instancetype)pidForFreezeFrameDTC:(LTOBD2DTC *)freezeFrameDTC NS_UNAVAILABLE;

@end

#pragma mark -
#pragma mark Mode 05 – Oxygen Sensor Component Monitoring (not for CAN)

@interface LTOBD2PID_SUPPORTED_PIDS_MODE_5_0500 : LTOBD2PID

+(instancetype)pidForMode1 NS_UNAVAILABLE;
+(instancetype)pidForFreezeFrameDTC:(LTOBD2DTC *)freezeFrameDTC NS_UNAVAILABLE;

@end

#pragma mark -
#pragma mark Mode 06 – Test Results Component Monitoring

@interface LTOBD2PID_MODE_6_TEST_RESULTS_06 : LTOBD2PID

+(instancetype)pidForMode1 NS_UNAVAILABLE;
+(instancetype)pidForFreezeFrameDTC:(LTOBD2DTC *)freezeFrameDTC NS_UNAVAILABLE;
+(instancetype)pid NS_UNAVAILABLE;

+(instancetype)pidForMid:(NSUInteger)mid;

@property(nonatomic,readonly) NSArray<LTOBD2Mode6TestResult*>* testResults;

@end

#pragma mark -
#pragma mark Mode 07 – Pending Diagnostic Trouble Codes

@interface LTOBD2PID_PENDING_DTC_07 : LTOBD2PIDStoredDTC

+(instancetype)pidForMode1 NS_UNAVAILABLE;
+(instancetype)pidForFreezeFrameDTC:(LTOBD2DTC *)freezeFrameDTC NS_UNAVAILABLE;

@end

#pragma mark -
#pragma mark Mode 08 – Interactive Test

#pragma mark -
#pragma mark Mode 09 – Vehicle Information

@interface LTOBD2PID_VIN_CODE_0902 : LTOBD2PID

+(instancetype)pidForMode1 NS_UNAVAILABLE;
+(instancetype)pidForFreezeFrameDTC:(LTOBD2DTC *)freezeFrameDTC NS_UNAVAILABLE;

@end

@interface LTOBD2PID_CALIBRATION_ID_0904 : LTOBD2PID

+(instancetype)pidForMode1 NS_UNAVAILABLE;
+(instancetype)pidForFreezeFrameDTC:(LTOBD2DTC *)freezeFrameDTC NS_UNAVAILABLE;

@end

@interface LTOBD2PID_CALIBRATION_VERIFICATION_0906 : LTOBD2PID

+(instancetype)pidForMode1 NS_UNAVAILABLE;
+(instancetype)pidForFreezeFrameDTC:(LTOBD2DTC *)freezeFrameDTC NS_UNAVAILABLE;

@end

@interface LTOBD2PID_SPARK_IGNITION_PERFORMANCE_TRACKING_0908 : LTOBD2PIDPerformanceTracking
@end

@interface LTOBD2PID_ECU_NAME_090A : LTOBD2PID

+(instancetype)pidForMode1 NS_UNAVAILABLE;
+(instancetype)pidForFreezeFrameDTC:(LTOBD2DTC *)freezeFrameDTC NS_UNAVAILABLE;

-(NSDictionary<NSString*,NSString*>*)recognizedECUs;

@end

@interface LTOBD2PID_COMPRESSION_IGNITION_PERFORMANCE_TRACKING_090B : LTOBD2PIDPerformanceTracking
@end

#pragma mark -
#pragma mark Mode 0A – Permanent DTC

@interface LTOBD2PID_PERMANENT_DTC_0A : LTOBD2PIDStoredDTC

+(instancetype)pidForMode1 NS_UNAVAILABLE;
+(instancetype)pidForFreezeFrameDTC:(LTOBD2DTC *)freezeFrameDTC NS_UNAVAILABLE;

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

@interface LTOBD2PID_TESTER_PRESENT_3E : LTOBD2PID

+(instancetype)pidForMode1 NS_UNAVAILABLE;
+(instancetype)pidForFreezeFrameDTC:(LTOBD2DTC*)freezeFrameDTC NS_UNAVAILABLE;

@end

#pragma mark -
#pragma mark Mode 81 – Start Communication

#pragma mark -
#pragma mark Mode 82 – Stop Communication

#pragma mark -
#pragma mark Mode 83 – Access Timing Parameters

#pragma mark -
#pragma mark Mode 85 – Start Programming


NS_ASSUME_NONNULL_END
