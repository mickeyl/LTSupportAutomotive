//
//  Copyright (c) Dr. Michael Lauer Information Technology. All rights reserved.
//

#import "LTVIN.h"

#import "LTSupportAutomotive.h"

static NSString* const ISO3779_CHARACTERS = @"1234567890ABCDEFGHJKLMNPRSTUVWXYZ";

static NSUInteger const ISO3779_WMI_LOCATION = 0;
static NSUInteger const ISO3779_WMI_LENGTH = 3;
static NSUInteger const ISO3779_VDS_LOCATION = 3;
static NSUInteger const ISO3779_VDS_LENGTH = 5;
__unused static NSUInteger const ISO3779_CHECKSUM_LOCATION = 8;
static NSUInteger const ISO3779_CHECKSUM_LENGTH = 1;
static NSUInteger const ISO3779_VIS_LOCATION = 9;
static NSUInteger const ISO3779_VIS_LENGTH = 8;

static NSUInteger const ISO3779_LENGTH = ISO3779_WMI_LENGTH + ISO3779_VDS_LENGTH + ISO3779_CHECKSUM_LENGTH + ISO3779_VIS_LENGTH; // 17

static NSString* const UNASSIGNED = @"unassigned";
static NSString* const UNKNOWN = @"unknown";

static NSDictionary* _wmi_regions;
static NSDictionary* _wmi_countries;
static NSDictionary* _wmi_manufacturers;

@implementation LTVIN

#pragma mark -
#pragma mark Helpers

-(void)decode
{
    NSString* regionCode = [@"ISO3780_WMI_REGION_" stringByAppendingString:[_wmi substringWithRange:NSMakeRange(0, 1)]];
    _region = LTStringLookupWithPlaceholder( regionCode, UNASSIGNED );
    
    NSString* countryCode2Digits = [@"ISO3780_WMI_COUNTRY_" stringByAppendingString:[_wmi substringWithRange:NSMakeRange(0, 2)]];
    _country = LTStringLookupOrNil(countryCode2Digits);
    if ( !_country )
    {
        NSString* countryCode1Digit = [@"ISO3780_WMI_COUNTRY_" stringByAppendingString:[_wmi substringWithRange:NSMakeRange(0, 1)]];
        _country = LTStringLookupWithPlaceholder( countryCode1Digit, UNASSIGNED );
    }
    
    NSString* manufacturerCode3Digits = [@"ISO3780_WMI_MANUFACTURER_" stringByAppendingString:_wmi];
    _manufacturer = LTStringLookupOrNil( manufacturerCode3Digits );
    if ( !_manufacturer )
    {
        NSString* manufacturerCode2Digits = [@"ISO3780_WMI_MANUFACTURER_" stringByAppendingString:[_wmi substringWithRange:NSMakeRange(0, 2)]];
        _manufacturer = LTStringLookupWithPlaceholder( manufacturerCode2Digits, UNKNOWN );
    }
    
    static NSUInteger const MODEL_YEAR_RANGE_DISCRIMINATOR_LOCATION = 6;
    static NSUInteger const MODEL_YEAR_CODE_LOCATION = 9;
    
    if (isdigit([_vin characterAtIndex:MODEL_YEAR_RANGE_DISCRIMINATOR_LOCATION])) {
        // if the character at index 6 is a numeric digit then we select our model year from the 'old' 1980-2009 range
        NSString* modelYearCode = [@"VIN_MODEL_YEAR_OLD_" stringByAppendingString:[_vin substringWithRange:NSMakeRange(MODEL_YEAR_CODE_LOCATION, 1)]];
        _modelYear = LTStringLookupWithPlaceholder( modelYearCode, UNASSIGNED );
    } else {
        // if the character at index 6 is not a numeric digit then we select our model year from the 'new' 2010-2029 range
        NSString* modelYearCode = [@"VIN_MODEL_YEAR_NEW_" stringByAppendingString:[_vin substringWithRange:NSMakeRange(MODEL_YEAR_CODE_LOCATION, 1)]];
        _modelYear = LTStringLookupWithPlaceholder( modelYearCode, UNASSIGNED );
    }
    
    // these are unknown in the base class, subclasses can populate them
    _model = UNKNOWN;
    _productionPlant = UNKNOWN;
}

#pragma mark -
#pragma mark Debugging

-(NSString*)debugDescription
{
    return [NSString stringWithFormat:@"<VIN %@ = %@/%@/%@ %@ %@>", _vin, _region, _country, _manufacturer, _vds, _vis];
}


#pragma mark -
#pragma mark API

+(instancetype)VINWithString:(NSString*)string
{
    return [[self alloc] initWithString:string];
}

+(BOOL)isValidString:(NSString*)string
{
    if ( string.length != ISO3779_LENGTH )
    {
        return NO;
    }
    
    NSCharacterSet* allowedCharacters = [NSCharacterSet characterSetWithCharactersInString:ISO3779_CHARACTERS];
    for ( NSUInteger i = 0; i < string.length; ++i )
    {
        if ( ! [allowedCharacters characterIsMember:[string characterAtIndex:i]] )
        {
            return NO;
        }
    }
    
    return YES;
}

-(instancetype)initWithString:(NSString*)string
{
    if ( ! ( self = [super init] ) )
    {
        return nil;
    }
    
    if ( [string hasPrefix:@"WDX-SIM" ] )
    {
        _region = LTStringLookupOrNil( @"ISO3780_WMI_REGION_W" );
        _country = LTStringLookupOrNil( @"ISO3780_WMI_COUNTRY_W" );
        _manufacturer = @"DIAMEX OBD-II SIM";
        return self;
    }
    
    if ( ![[self class] isValidString:string] )
    {
        return nil;
    }
    
    _vin = string;
    _wmi = [string substringWithRange:NSMakeRange(ISO3779_WMI_LOCATION, ISO3779_WMI_LENGTH)];
    _vds = [string substringWithRange:NSMakeRange(ISO3779_VDS_LOCATION, ISO3779_VDS_LENGTH)];
    _vis = [string substringWithRange:NSMakeRange(ISO3779_VIS_LOCATION, ISO3779_VIS_LENGTH)];
    
    [self decode];
    
    return self;
}

@end
