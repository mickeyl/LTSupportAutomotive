//
//  Copyright (c) Dr. Michael Lauer Information Technology. All rights reserved.
//

#import "LTOBD2Adapter.h"

#import "LTOBD2Command.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTOBD2AdapterELM327 : LTOBD2Adapter

+(NSString*)identifyWithResponseToResetCommand:(NSString*)response;

@end

@interface LTOBD2CommandELM327_IDENTIFY : LTOBD2Command

+(instancetype)command;

@end

@interface LTOBD2CommandELM327_READ_VOLTAGE : LTOBD2Command

+(instancetype)command;

@end

@interface LTOBD2CommandELM327_IGNITION_STATUS : LTOBD2Command

+(instancetype)command;

@end

@interface LTOBD2CommandELM327_TRY_PROTOCOL : LTOBD2Command

+(instancetype)commandForAutoProtocol:(OBD2VehicleProtocol)protocol;
+(instancetype)commandForProtocol:(OBD2VehicleProtocol)protocol;

@end

@interface LTOBD2CommandELM327_SET_PROTOCOL : LTOBD2Command

+(instancetype)commandForAutoProtocol:(OBD2VehicleProtocol)protocol;
+(instancetype)commandForProtocol:(OBD2VehicleProtocol)protocol;

@end

@interface LTOBD2CommandELM327_DESCRIBE_PROTOCOL : LTOBD2Command

+(instancetype)command;

@end

@interface LTOBD2CommandELM327_DESCRIBE_PROTOCOL_NUMERIC : LTOBD2Command

+(instancetype)command;

@end

NS_ASSUME_NONNULL_END
