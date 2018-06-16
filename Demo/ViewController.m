//
//  CarCommunicationViewController.m
//  LTSupportDemo
//
//  Created by Dr. Michael Lauer on 14.06.16.
//  Copyright © 2016 Vanille Media. All rights reserved.
//

#import "ViewController.h"

#import <LTSupportAutomotive/LTSupportAutomotive.h>

#import <CoreBluetooth/CoreBluetooth.h>

typedef enum : NSUInteger {
    PageCurrentData,
    PageComponentMonitors,
    PageDTC,
} Page;

static const CGFloat animationDuration = 0.15;

@implementation ViewController
{
    LTBTLESerialTransporter* _transporter;
    LTOBD2Adapter* _obd2Adapter;
    
    NSArray<LTOBD2PID*>* _pids;
    NSArray<LTOBD2MonitorResult*>* _monitors;
    NSArray<LTOBD2DTC*>* _dtcs;
    
    NSTimer* _timer;
    
    Page _selectedPage;
    
    LTOBD2PID_MONITOR_STATUS_SINCE_DTC_CLEARED_01* _statusPID;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    NSMutableArray* serviceUUIDs = [NSMutableArray array];
    [@[ @"FFF0", @"FFE0", @"BEEF" , @"E7810A71-73AE-499D-8C15-FAA9AEF0C3F2"] enumerateObjectsUsingBlock:^(NSString* _Nonnull uuid, NSUInteger idx, BOOL * _Nonnull stop) {
        [serviceUUIDs addObject:[CBUUID UUIDWithString:uuid]];
    }];
    
    _transporter = [LTBTLESerialTransporter transporterWithIdentifier:nil serviceUUIDs:serviceUUIDs];
    [_transporter connectWithBlock:^(NSInputStream * _Nullable inputStream, NSOutputStream * _Nullable outputStream) {
        
        if ( !inputStream )
        {
            LOG( @"Could not connect to OBD2 adapter" );
            return;
        }
        
        self->_obd2Adapter = [LTOBD2AdapterELM327 adapterWithInputStream:inputStream outputStream:outputStream];
        [self->_obd2Adapter connect];
    }];
    
    [_transporter startUpdatingSignalStrengthWithInterval:1.0];
    
    UISegmentedControl* sc = [[UISegmentedControl alloc] initWithItems:@[ @"Current", @"Monitors", @"DTC" ]];
    sc.selectedSegmentIndex = _selectedPage = 0;
    [sc addTarget:self action:@selector(onSegmentedControlValueChanged:) forControlEvents:UIControlEventValueChanged];
    self.navigationItem.titleView = sc;

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(onRefreshClicked:)];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAdapterChangedState:) name:LTOBD2AdapterDidUpdateState object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onTransporterDidUpdateSignalStrength:) name:LTBTLESerialTransporterDidUpdateSignalStrength object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAdapterDidSendBytes:) name:LTOBD2AdapterDidSend object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAdapterDidReceiveBytes:) name:LTOBD2AdapterDidReceive object:nil];
    
    NSMutableArray<LTOBD2PID*>* ma = @[
                                                 
                                                 [LTOBD2CommandELM327_IDENTIFY command],
                                                 [LTOBD2CommandELM327_IGNITION_STATUS command],
                                                 [LTOBD2CommandELM327_READ_VOLTAGE command],
                                                 [LTOBD2CommandELM327_DESCRIBE_PROTOCOL command],
                                                 
                                                 [LTOBD2PID_VIN_CODE_0902 pid],
                                                 [LTOBD2PID_FUEL_SYSTEM_STATUS_03 pidForMode1],
                                                 [LTOBD2PID_OBD_STANDARDS_1C pidForMode1],
                                                 [LTOBD2PID_FUEL_TYPE_51 pidForMode1],
                                                 
                                                 [LTOBD2PID_ENGINE_LOAD_04 pidForMode1],
                                                 [LTOBD2PID_COOLANT_TEMP_05 pidForMode1],
                                                 [LTOBD2PID_SHORT_TERM_FUEL_TRIM_1_06 pidForMode1],
                                                 [LTOBD2PID_LONG_TERM_FUEL_TRIM_1_07 pidForMode1],
                                                 [LTOBD2PID_SHORT_TERM_FUEL_TRIM_2_08 pidForMode1],
                                                 [LTOBD2PID_LONG_TERM_FUEL_TRIM_2_09 pidForMode1],
                                                 [LTOBD2PID_FUEL_PRESSURE_0A pidForMode1],
                                                 [LTOBD2PID_INTAKE_MAP_0B pidForMode1],
                                                 
                                                 [LTOBD2PID_ENGINE_RPM_0C pidForMode1],
                                                 [LTOBD2PID_VEHICLE_SPEED_0D pidForMode1],
                                                 [LTOBD2PID_TIMING_ADVANCE_0E pidForMode1],
                                                 [LTOBD2PID_INTAKE_TEMP_0F pidForMode1],
                                                 [LTOBD2PID_MAF_FLOW_10 pidForMode1],
                                                 [LTOBD2PID_THROTTLE_11 pidForMode1],
                                                 
                                                 [LTOBD2PID_SECONDARY_AIR_STATUS_12 pidForMode1],
                                                 [LTOBD2PID_OXYGEN_SENSORS_PRESENT_2_BANKS_13 pidForMode1],
                                                 
                                                 ].mutableCopy;
    for ( NSUInteger i = 0; i < 8; ++i )
    {
        [ma addObject:[LTOBD2PID_OXYGEN_SENSORS_INFO_1 pidForSensor:i mode:1]];
    }
    
    [ma addObjectsFromArray:@[
                              [LTOBD2PID_OXYGEN_SENSORS_PRESENT_4_BANKS_1D pidForMode1],
                              [LTOBD2PID_AUX_INPUT_1E pidForMode1],
                              [LTOBD2PID_RUNTIME_1F pidForMode1],
                              [LTOBD2PID_DISTANCE_WITH_MIL_21 pidForMode1],
                              [LTOBD2PID_FUEL_RAIL_PRESSURE_22 pidForMode1],
                              [LTOBD2PID_FUEL_RAIL_GAUGE_PRESSURE_23 pidForMode1],
                              ]];

    for ( NSUInteger i = 0; i < 8; ++i )
    {
        [ma addObject:[LTOBD2PID_OXYGEN_SENSORS_INFO_2 pidForSensor:i mode:1]];
    }

    [ma addObjectsFromArray:@[
                              [LTOBD2PID_COMMANDED_EGR_2C pidForMode1],
                              [LTOBD2PID_EGR_ERROR_2D pidForMode1],
                              [LTOBD2PID_COMMANDED_EVAPORATIVE_PURGE_2E pidForMode1],
                              [LTOBD2PID_FUEL_TANK_LEVEL_2F pidForMode1],
                              [LTOBD2PID_WARMUPS_SINCE_DTC_CLEARED_30 pidForMode1],
                              [LTOBD2PID_DISTANCE_SINCE_DTC_CLEARED_31 pidForMode1],
                              [LTOBD2PID_EVAP_SYS_VAPOR_PRESSURE_32 pidForMode1],
                              [LTOBD2PID_ABSOLUTE_BAROMETRIC_PRESSURE_33 pidForMode1],
                              ]];
    
     for ( NSUInteger i = 0; i < 8; ++i )
     {
         [ma addObject:[LTOBD2PID_OXYGEN_SENSORS_INFO_3 pidForSensor:i mode:1]];
     }
     
     [ma addObjectsFromArray:@[
                               [LTOBD2PID_CATALYST_TEMP_B1S1_3C pidForMode1],
                               [LTOBD2PID_CATALYST_TEMP_B2S1_3D pidForMode1],
                               [LTOBD2PID_CATALYST_TEMP_B1S2_3E pidForMode1],
                               [LTOBD2PID_CATALYST_TEMP_B2S2_3F pidForMode1],
                               [LTOBD2PID_CONTROL_MODULE_VOLTAGE_42 pidForMode1],
                               [LTOBD2PID_ABSOLUTE_ENGINE_LOAD_43 pidForMode1],
                               [LTOBD2PID_AIR_FUEL_EQUIV_RATIO_44 pidForMode1],
                               [LTOBD2PID_RELATIVE_THROTTLE_POS_45 pidForMode1],
                               [LTOBD2PID_AMBIENT_TEMP_46 pidForMode1],
                               [LTOBD2PID_ABSOLUTE_THROTTLE_POS_B_47 pidForMode1],
                               [LTOBD2PID_ABSOLUTE_THROTTLE_POS_C_48 pidForMode1],
                               [LTOBD2PID_ACC_PEDAL_POS_D_49 pidForMode1],
                               [LTOBD2PID_ACC_PEDAL_POS_E_4A pidForMode1],
                               [LTOBD2PID_ACC_PEDAL_POS_F_4B pidForMode1],
                               [LTOBD2PID_COMMANDED_THROTTLE_ACTUATOR_4C pidForMode1],
                               [LTOBD2PID_TIME_WITH_MIL_4D pidForMode1],
                               [LTOBD2PID_TIME_SINCE_DTC_CLEARED_4E pidForMode1],
                               [LTOBD2PID_MAX_VALUE_FUEL_AIR_EQUIVALENCE_RATIO_4F pidForMode1],
                               [LTOBD2PID_MAX_VALUE_OXYGEN_SENSOR_VOLTAGE_4F pidForMode1],
                               [LTOBD2PID_MAX_VALUE_OXYGEN_SENSOR_CURRENT_4F pidForMode1],
                               [LTOBD2PID_MAX_VALUE_INTAKE_MAP_4F pidForMode1],
                               [LTOBD2PID_MAX_VALUE_MAF_AIR_FLOW_RATE_50 pidForMode1],
                               ]];

    _pids = [NSArray arrayWithArray:ma];
    
    _adapterStatusLabel.text = @"Looking for adapter...";
    _rpmLabel.text = _speedLabel.text = _tempLabel.text = @"";
    _rssiLabel.text = @"";
    _incomingBytesNotification.alpha = 0.3;
    _outgoingBytesNotification.alpha = 0.3;
    
}

-(void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}
    

#pragma mark -
#pragma mark Actions

-(void)onSegmentedControlValueChanged:(UISegmentedControl*)sender
{
    _selectedPage = sender.selectedSegmentIndex;
    
    if ( _obd2Adapter.adapterState != OBD2AdapterStateConnected )
    {
        return;
    }
    
    switch ( _selectedPage )
    {
        case PageCurrentData:
            [_tableView reloadData];
            break;
            
        case PageComponentMonitors:
        {
            for ( NSUInteger i = 0; i < 10; ++i )
            {
                LTOBD2PID_DTC_CAUSING_FREEZE_FRAME_02* ffDTCPid = [LTOBD2PID_DTC_CAUSING_FREEZE_FRAME_02 pidForFreezeFrame:i];
                [_obd2Adapter transmitCommand:ffDTCPid responseHandler:^(LTOBD2Command * _Nonnull command) {
                    
                    LOG( @"FREEZE FRAME %u DTC %@", i, ffDTCPid.formattedResponse );
                    
                }];
            }
            
            
            LTOBD2PID_MONITOR_STATUS_SINCE_DTC_CLEARED_01* pid = [LTOBD2PID_MONITOR_STATUS_SINCE_DTC_CLEARED_01 pidForMode1];
            [_obd2Adapter transmitCommand:pid responseHandler:^(LTOBD2Command * _Nonnull command) {
                
                self->_monitors = pid.monitorResults;
                
                dispatch_async( dispatch_get_main_queue(), ^{
                    [self->_tableView reloadData];
                } );
                
            }];
        }
            
        case PageDTC:
        {
            LTOBD2PID_PERMANENT_DTC_0A* pid0A = [LTOBD2PID_PERMANENT_DTC_0A pid];
            [_obd2Adapter transmitCommand:pid0A responseHandler:^(LTOBD2Command * _Nonnull command) {
                
                LOG( @"PERMANENT DTC = %@", pid0A.formattedResponse );
            }];
            
            LTOBD2PID_PENDING_DTC_07* pid07 = [LTOBD2PID_PENDING_DTC_07 pid];
            [_obd2Adapter transmitCommand:pid07 responseHandler:^(LTOBD2Command * _Nonnull command) {
                
                LOG( @"PENDING DTC = %@", pid07.formattedResponse );
            }];
            
            LTOBD2PID_STORED_DTC_03* dtcPid = [LTOBD2PID_STORED_DTC_03 pid];
            [_obd2Adapter transmitCommand:dtcPid responseHandler:^(LTOBD2Command * _Nonnull command) {
                
                LOG( @"DTC = %@", dtcPid.formattedResponse );
                self->_dtcs = dtcPid.troubleCodes;
                
                dispatch_async( dispatch_get_main_queue(), ^{
                    [self->_tableView reloadData];
                } );
            }];
        }
        break;
    }
}

-(void)onRefreshClicked:(UIBarButtonItem*)sender
{
    [_tableView reloadData];
}

#pragma mark -
#pragma mark NSTimer
    
-(void)updateSensorData
{
    LTOBD2PID_ENGINE_RPM_0C* rpm = [LTOBD2PID_ENGINE_RPM_0C pidForMode1];
    LTOBD2PID_VEHICLE_SPEED_0D* speed = [LTOBD2PID_VEHICLE_SPEED_0D pidForMode1];
    LTOBD2PID_COOLANT_TEMP_05* temp = [LTOBD2PID_COOLANT_TEMP_05 pidForMode1];
    
    [_obd2Adapter transmitMultipleCommands:@[ rpm, speed, temp ] completionHandler:^(NSArray<LTOBD2Command *> * _Nonnull commands) {
    
        dispatch_async( dispatch_get_main_queue(), ^{

            self->_rpmLabel.text = rpm.formattedResponse;
            self->_speedLabel.text = speed.formattedResponse;
            self->_tempLabel.text = temp.formattedResponse;

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self updateSensorData];
            });

        } );
        
    }];
}

#pragma mark -
#pragma mark NSNotificationCenter

-(void)onAdapterChangedState:(NSNotification*)notification
{
    dispatch_async( dispatch_get_main_queue(), ^{

        self->_adapterStatusLabel.text = self->_obd2Adapter.friendlyAdapterState;
        
        if ( self->_obd2Adapter.adapterState == OBD2AdapterStateConnected )
        {
            self->_tableView.dataSource = self;
            self->_tableView.delegate = self;
            [self->_tableView reloadData];
            
            [self updateSensorData];
        }
        
        if ( self->_obd2Adapter.adapterState == OBD2AdapterStateUnsupportedProtocol )
        {
            dispatch_async( dispatch_get_main_queue(), ^{

                NSString* message = [NSString stringWithFormat:@"Adapter ready, but vehicle uses an unsupported protocol – %@", self->_obd2Adapter.friendlyVehicleProtocol];
                self->_adapterStatusLabel.text = message;
                
            } );
        }
    } );
}
    
-(void)onAdapterDidSendBytes:(NSNotification*)notification
{
    dispatch_async( dispatch_get_main_queue(), ^{
        if ( self->_outgoingBytesNotification.layer.animationKeys.count )
        {
            LOG( @"OUT Ani in progress..." );
            return;
        }
        
        
        [UIView animateWithDuration:animationDuration delay:0.0 options:0 animations:^{
            self->_outgoingBytesNotification.alpha = 0.75;
        } completion:^(BOOL finished) {
            self->_outgoingBytesNotification.alpha = 0.3;
        }];
    } );
}
    
-(void)onAdapterDidReceiveBytes:(NSNotification*)notification
{
    dispatch_async( dispatch_get_main_queue(), ^{
        if ( self->_incomingBytesNotification.layer.animationKeys.count )
        {
            LOG( @"IN Ani in progress..." );
            return;
        }
        
        [UIView animateWithDuration:animationDuration delay:0.0 options:0 animations:^{
            self->_incomingBytesNotification.alpha = 0.75;
        } completion:^(BOOL finished) {
            self->_incomingBytesNotification.alpha = 0.3;
        }];
    } );
}
    
-(void)onTransporterDidUpdateSignalStrength:(NSNotification*)notification
{
    dispatch_async( dispatch_get_main_queue(), ^{
        self->_rssiLabel.text = [NSString stringWithFormat:@"-%.0f dbM", self->_transporter.signalStrength.floatValue];
    } );
}

#pragma mark -
#pragma mark <UITableViewDataSource>

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    switch ( _selectedPage )
    {
        case PageCurrentData:
            return 1;
            
        case PageComponentMonitors:
            return 1;
            
        case PageDTC:
            return _dtcs.count;
    }
    
    return 0;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch ( _selectedPage )
    {
        case PageCurrentData:
            return _pids.count;
            
        case PageComponentMonitors:
            return _monitors.count;
            
        case PageDTC:
        {
            return _dtcs.count;
        }
    }
    
    return 0;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell;
    
    switch ( _selectedPage )
    {
        case PageCurrentData:
        {
            cell = [tableView dequeueReusableCellWithIdentifier:@"OBD2_PID" forIndexPath:indexPath];
            cell.textLabel.text = @"loading...";
            cell.detailTextLabel.text = @"...";
            
            LTOBD2PID* modelObject = [_pids objectAtIndex:indexPath.row];
            //if ( !modelObject.cookedResponse )
            {
                [_obd2Adapter transmitCommand:modelObject responseHandler:^(LTOBD2Command * _Nonnull command) {
                    
                    dispatch_async( dispatch_get_main_queue(), ^{
                        
                        cell.textLabel.text = modelObject.purpose;
                        cell.detailTextLabel.text = modelObject.formattedResponse;
                        
                    } );
                    
                }];
            }
        }
        break;
            
        case PageComponentMonitors:
        {
            cell = [tableView dequeueReusableCellWithIdentifier:@"OBD2_MON" forIndexPath:indexPath];
            
            LTOBD2MonitorResult* modelObject = [_monitors objectAtIndex:indexPath.row];
            cell.textLabel.text = [@"TEST " stringByAppendingString:modelObject.formattedName];
            cell.detailTextLabel.text = modelObject.formattedResult;
        }
        break;
            
        case PageDTC:
        {
            cell = [tableView dequeueReusableCellWithIdentifier:@"OBD2_DTC" forIndexPath:indexPath];
            LTOBD2DTC* modelObject = [_dtcs objectAtIndex:indexPath.row];
            cell.textLabel.text = modelObject.code;
            cell.detailTextLabel.text = modelObject.formattedEcu;
        }
            
    }
    
    return cell;
}

#pragma mark -
#pragma mark <UITableViewDelegate>

-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return nil;
}

@end
