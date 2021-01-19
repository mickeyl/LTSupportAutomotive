//
//  Copyright (c) Dr. Michael Lauer Information Technology. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    OBD2MonitorTestNotAvailable,
    OBD2MonitorTestPassed,
    OBD2MonitorTestFailed,
} OBD2MonitorTestResult;

NS_ASSUME_NONNULL_BEGIN

@interface LTOBD2MonitorResult : NSObject

@property(nonatomic,readonly) OBD2MonitorTestResult result;
@property(nonatomic,readonly) NSString* formattedName;
@property(nonatomic,readonly) NSString* formattedResult;

+(instancetype)resultWithTestName:(NSString*)name result:(OBD2MonitorTestResult)result;

@end

NS_ASSUME_NONNULL_END
