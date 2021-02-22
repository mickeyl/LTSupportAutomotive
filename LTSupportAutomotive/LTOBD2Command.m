//
//  Copyright (c) Dr. Michael Lauer Information Technology. All rights reserved.
//

#import "LTOBD2Command.h"

#import "LTSupportAutomotive.h"

NSNumber* OBD2_NO_DATA_NUMBER;

__attribute__((constructor))
static void initGlobalConstants() {
    OBD2_NO_DATA_NUMBER = [NSNumber numberWithInteger:-999999];
}
@implementation LTOBD2Command
{
    NSString* _rawString;
    NSString* _cookedString;

    NSDate* _startDate;
    NSTimeInterval _completionTime;
}

#pragma mark -
#pragma mark Lifecycle

+(instancetype)commandWithRawString:(NSString*)rawString
{
    return [[self alloc] initWithRawString:rawString];
}

+(instancetype)commandWithString:(NSString*)string
{
    return [[self alloc] initWithString:string];
}

-(instancetype)initWithRawString:(NSString*)rawString
{
    if ( ! ( self = [super init] ) )
    {
        return nil;
    }
    
    _rawString = rawString;
    return self;
}

-(instancetype)initWithString:(NSString*)string
{
    if ( ! ( self = [super init] ) )
    {
        return nil;
    }
    
    _cookedString = string;
    return self;
}

#pragma mark -
#pragma mark Accessors

-(NSString*)purpose
{
    NSArray<NSString*>* classNameComponents = [NSStringFromClass(self.class) componentsSeparatedByString:@"_"];
    NSRange purposeRange = NSMakeRange(1, classNameComponents.count - 2);
    NSMutableArray<NSString*>* purposeComponents = [classNameComponents subarrayWithRange:purposeRange].mutableCopy;
    [purposeComponents enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ( obj.length <= 3 )
        {
            [purposeComponents replaceObjectAtIndex:idx withObject:obj.uppercaseString];
        }
        else
        {
            [purposeComponents replaceObjectAtIndex:idx withObject:obj.capitalizedString];
        }
    }];
    NSString* purposePlaceholder = [purposeComponents componentsJoinedByString:@" "];
    NSString* purposeKey = [purposeComponents componentsJoinedByString:@"_"].uppercaseString;
    
    return LTStringLookupWithPlaceholder( purposeKey, purposePlaceholder );
}

-(void)prepareForSending
{
    _startDate = [NSDate date];
}

#pragma mark -
#pragma mark API

-(NSString*)commandString
{
    return _rawString ?: _cookedString;
}

-(BOOL)isRawCommand
{
    return _rawString.length > 0;
}

-(BOOL)gotAnswer
{
    return _rawResponse.count > 0;
}

-(BOOL)gotValidAnswer
{
    return _responsePayload.count > 0;
}

-(BOOL)isCAN
{
    switch ( _protocol )
    {
        case OBD2VehicleProtocolCAN_11B_250K:
        case OBD2VehicleProtocolCAN_11B_500K:
        case OBD2VehicleProtocolCAN_29B_250K:
        case OBD2VehicleProtocolCAN_29B_500K:
            return YES;
            
        default:
            return NO;
    }
}

/**
 Default decodeResponse implementation decodes the array of bytes in the responsePayload
 as unsigned int values, and converts them to a String of comma separated unsigned int values.
*/
-(NSObject*)decodeResponse
{
    if ( !self.responsePayload )
    {
        return LTStringLookupWithPlaceholder(@"OBD2_NO_DATA", @"N/A");
    }
    
    NSMutableArray<NSString*>* ma = [NSMutableArray array];

    for ( NSString* ecu in [self.responsePayload.allKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] )
    {
        NSMutableString* ms = [NSMutableString string];
        NSArray<NSNumber*>* bytes = [self.responsePayload objectForKey:ecu];
        [bytes enumerateObjectsUsingBlock:^(NSNumber * _Nonnull byte, NSUInteger idx, BOOL * _Nonnull stop) {
            [ms appendFormat:@"%02X", byte.unsignedIntValue];
        }];
        [ma addObject:ms];
    }
    
    // default implementation returns a single NSString
    return [ma componentsJoinedByString:@", "];
}


/**
 Units string used when building the formattedResponse
 Default units is empty string.
 Subclasses can override to define their own units.
*/
-(NSString*)units
{
    return @"";
}

/**
 Format string used when building the formattedResponse
 Default format is simple string concatentation
 Subclasses can override to define their own formatting for integer and double value types.
*/
-(NSString*)format
{
    return @"%@";
}

/**
 Declares the type of the decodedResponse object.
   - String
   - Integer
   - Double
 Default responseDataType is a String.
 Subclasses can override to configure their own responseDataType.
*/
-(LTResponseDataType)responseDataType
{
    return LTString;
}

/**
 Default formattedResponse implementation
 Uses the format string to format the decodeResponse object and then appends the units string.
 Subclasses can override to customise their own formattedResponse string.
 However, most commands do not need to customise this function, and can just configure format and units strings and provide an impl of decodeResponse.
*/
-(NSString*)formattedResponse
{
    if ( !self.responsePayload )
    {
        return LTStringLookupWithPlaceholder(@"OBD2_NO_DATA", @"N/A");
    }
    
    NSObject* decodedResponse = self.decodeResponse;
    
    LOG( @"decodedResponse: '%@'", decodedResponse );
    
    NSString* responseString;
    
    if (self.responseDataType == LTString) {
        responseString = [NSString stringWithFormat:self.format, decodedResponse];
    } else if (self.responseDataType == LTInteger) {
        int decodedIntValue = ((NSNumber*) decodedResponse).intValue;
        responseString = [NSString stringWithFormat:self.format, decodedIntValue ];
    } else if (self.responseDataType == LTDouble) {
        double decodedDoubleValue = ((NSNumber*) decodedResponse).doubleValue;
        responseString = [NSString stringWithFormat:self.format, decodedDoubleValue ];
    } else {
        LOG( @"ERROR - UNHANDLED ResponseDataType: '%@'", self.responseDataType );
    }
    
    LOG( @"responseString after format: '%@': '%@'", self.format, responseString );

    if (self.units) {
        responseString = [NSString stringWithFormat: @"%@" UTF8_NARROW_NOBREAK_SPACE @"%@", responseString, self.units];
        LOG( @"responseString with units: '%@'", responseString );
    }
    
    return responseString;
}

-(void)didCompleteResponse:(NSArray<NSString*>*)lines completionTime:(NSTimeInterval)completionTime
{
    _rawResponse = lines;
    _completionTime = completionTime;
}

-(void)didUnpackResponsePayload:(NSDictionary<NSString*,LTOBD2ProtocolResult*>*)responseDictionary withProtocolType:(OBD2VehicleProtocol)protocol
{
    _protocol = protocol;
    
    NSMutableDictionary<NSString*,NSArray<NSNumber*>*>* positiveResponses = [NSMutableDictionary dictionary];
    NSMutableDictionary<NSString*,NSNumber*>* negativeResponses = [NSMutableDictionary dictionary];
    
    [responseDictionary enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull source, LTOBD2ProtocolResult * _Nonnull result, BOOL * _Nonnull stop) {
        
        OBD2FailureType failureTypeForResult = result.failureType;
        if ( failureTypeForResult == OBD2FailureTypeInternalOK )
        {
            positiveResponses[source] = result.payload;
        }
        else
        {
            negativeResponses[source] = @(failureTypeForResult);
        }
        
    }];
    
    _responsePayload = positiveResponses;
    _failureResponse = negativeResponses;
}

-(void)invalidateResponse
{
    _responsePayload = nil;
    _failureResponse = nil;
}

#pragma mark -
#pragma mark Debug

-(NSString*)description
{
    return [NSString stringWithFormat:@"<%@:%p = '%@'>", NSStringFromClass(self.class), self, self.commandString];
}

@end

@implementation LTOBD2DummyCommand

+(instancetype)dummyCommand
{
    return [[self alloc] init];
}

@end
