//
//  Copyright (c) Dr. Michael Lauer Information Technology. All rights reserved.
//
#import <Foundation/Foundation.h>

FOUNDATION_EXPORT double LTSupportAutomotiveVersionNumber;

FOUNDATION_EXPORT const unsigned char LTSupportAutomotiveVersionString[];

// automotive
#import <LTSupportAutomotive/LTVIN.h>
#import <LTSupportAutomotive/LTOBD2Adapter.h>
#import <LTSupportAutomotive/LTOBD2AdapterELM327.h>
#import <LTSupportAutomotive/LTOBD2AdapterCaptureFile.h>
#import <LTSupportAutomotive/LTOBD2Command.h>
#import <LTSupportAutomotive/LTOBD2Protocol.h>
#import <LTSupportAutomotive/LTOBD2ProtocolISO15765_4.h>
#import <LTSupportAutomotive/LTOBD2ProtocolISO14230_4.h>
#import <LTSupportAutomotive/LTOBD2ProtocolSAEJ1850.h>
#import <LTSupportAutomotive/LTOBD2ProtocolISO9141_2.h>
#import <LTSupportAutomotive/LTOBD2PID.h>
#import <LTSupportAutomotive/LTOBD2DTC.h>
#import <LTSupportAutomotive/LTOBD2O2Sensor.h>
#import <LTSupportAutomotive/LTOBD2MonitorResult.h>
#import <LTSupportAutomotive/LTOBD2PerformanceTrackingResult.h>
#import <LTSupportAutomotive/LTOBD2Mode6TestResult.h>
#import <LTSupportAutomotive/LTOBD2CaptureFile.h>

// aux (should go into a seperate library)
#import <LTSupportAutomotive/LTBTLESerialTransporter.h>
#import <LTSupportAutomotive/LTBTLEReadCharacteristicStream.h>
#import <LTSupportAutomotive/LTBTLEWriteCharacteristicStream.h>

NS_ASSUME_NONNULL_BEGIN

// global helpers
NSString* _Nullable LTStringLookupOrNil( NSString* key );
NSString* LTStringLookupWithPlaceholder( NSString* key, NSString* placeholder );
void MyNSLog(const char *file, int lineNumber, const char *functionName, NSString *format, ...);
NSString* LTDataToString( NSData* d );

NS_ASSUME_NONNULL_END

// global macros
#ifndef LOG
    #define LOG(args...) MyNSLog(__FILE__,__LINE__,__PRETTY_FUNCTION__,args);
#endif

#ifndef UTF8_NARROW_NOBREAK_SPACE
    #define UTF8_NARROW_NOBREAK_SPACE @"\u202F"
#endif
