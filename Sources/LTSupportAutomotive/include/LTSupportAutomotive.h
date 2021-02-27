//
//  Copyright (c) Dr. Michael Lauer Information Technology. All rights reserved.
//
#import <Foundation/Foundation.h>

FOUNDATION_EXPORT double LTSupportAutomotiveVersionNumber;

FOUNDATION_EXPORT const unsigned char LTSupportAutomotiveVersionString[];

// automotive
#import "LTVIN.h"
#import "LTOBD2Adapter.h"
#import "LTOBD2AdapterELM327.h"
#import "LTOBD2AdapterCaptureFile.h"
#import "LTOBD2Command.h"
#import "LTOBD2Protocol.h"
#import "LTOBD2ProtocolISO15765_4.h"
#import "LTOBD2ProtocolISO14230_4.h"
#import "LTOBD2ProtocolSAEJ1850.h"
#import "LTOBD2ProtocolISO9141_2.h"
#import "LTOBD2PID.h"
#import "LTOBD2DTC.h"
#import "LTOBD2O2Sensor.h"
#import "LTOBD2MonitorResult.h"
#import "LTOBD2PerformanceTrackingResult.h"
#import "LTOBD2Mode6TestResult.h"
#import "LTOBD2CaptureFile.h"
#import "LTOBD2UDS.h"

// aux (should go into a seperate library)
#import "LTBTLESerialTransporter.h"
#import "LTBTLEReadCharacteristicStream.h"
#import "LTBTLEWriteCharacteristicStream.h"
