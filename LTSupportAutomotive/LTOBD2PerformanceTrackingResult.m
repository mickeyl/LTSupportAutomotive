//
//  Copyright (c) Dr. Michael Lauer Information Technology. All rights reserved.
//

#import "LTOBD2PerformanceTrackingResult.h"

#import "LTSupportAutomotive.h"

@implementation LTOBD2PerformanceTrackingResult

+(instancetype)resultWithMnemonic:(NSString*)mnemonic count:(NSUInteger)count
{
    LTOBD2PerformanceTrackingResult* obj = [[self alloc] init];
    obj->_mnemonic = mnemonic;
    obj->_count = count;
    return obj;
}

-(NSString*)formattedMnemonic
{
    NSString* key = [NSString stringWithFormat:@"OBD2_PERFORMANCE_TRACKING_%@", _mnemonic];
    return LTStringLookupWithPlaceholder( key, _mnemonic );
}

@end
