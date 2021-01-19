//
//  Copyright (c) Dr. Michael Lauer Information Technology. All rights reserved.
//
#import "LTOBD2DTC.h"

#import "helpers.h"

static NSDictionary<NSString*,NSString*>* LTOBD2DTCEcuDictionary;

@implementation LTOBD2DTC

#pragma mark -
#pragma mark Lifecycle

+(void)initialize
{
    if ( self != LTOBD2DTC.class )
    {
        return;
    }

    LTOBD2DTCEcuDictionary = @{
                                         @"10": @"ECU #1",
                                         @"17": @"ECU #2",
                                         @"1E": @"ECU #3",
                                         @"7E8": @"ECU #1",
                                         @"7E9": @"ECU #2",
                                         @"7EA": @"ECU #3",
                                         };
}

+(instancetype)dtcWithCode:(NSString*)code ecu:(NSString*)ecu
{
    return [self dtcWithCode:code ecu:ecu freezeFrame:NSNotFound];
}

+(instancetype)dtcWithCode:(NSString*)code ecu:(NSString*)ecu freezeFrame:(NSUInteger)framenumber
{
    LTOBD2DTC* obj = [[self alloc] init];
    obj->_code = code;
    obj->_ecu = ecu;
    obj->_associatedFreezeFrame = framenumber;
    return obj;
}

#pragma mark -
#pragma mark API

-(NSString*)formattedCode
{
    NSMutableArray<NSString*>* ma = [NSMutableArray array];
    for ( NSUInteger i = 0; i < 3; ++i )
    {
        NSString* character = [_code substringWithRange:NSMakeRange(i, 1)];
        NSString* key = [NSString stringWithFormat:@"OBD2_DTC_%u_%@", (uint)i, character];
        [ma addObject:LTStringLookupWithPlaceholder( key, key )];
    }
    return [ma componentsJoinedByString:@" › "];
}

-(NSString*)formattedEcu
{
    return [LTOBD2DTCEcuDictionary objectForKey:_ecu] ?: [NSString stringWithFormat:@"ECU @ 0x%@", _ecu];
}

-(NSString*)explanation
{
    NSString* key = [NSString stringWithFormat:@"OBD2_DTC_%@", _code];
    return LTStringLookupOrNil( key ) ?: LTStringLookupWithPlaceholder( @"OBD2_DTC_UNKNOWN", @"OBD2_DTC_UNKNOWN" );
}

-(void)associateWithFreezeFrame:(NSUInteger)framenumber
{
    _associatedFreezeFrame = framenumber;
}

#pragma mark -
#pragma mark Debug

-(NSString*)description
{
    return [NSString stringWithFormat:@"<OBD2DTC: %p %@=%@>", self, self.code, self.formattedCode];
}

@end
