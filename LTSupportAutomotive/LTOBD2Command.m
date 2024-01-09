//
//  Copyright (c) Dr. Michael Lauer Information Technology. All rights reserved.
//

#import "LTOBD2Command.h"

#import "LTSupportAutomotive.h"

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
    return _cookedResponse.count > 0;
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

-(NSString*)formattedResponse
{
    if ( !self.cookedResponse )
    {
        return LTStringLookupWithPlaceholder(@"OBD2_NO_DATA", @"N/A");
    }
    
    NSMutableArray<NSString*>* ma = [NSMutableArray array];
    
    for ( NSString* ecu in [self.cookedResponse.allKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] )
    {
        NSMutableString* ms = [NSMutableString string];
        NSArray<NSNumber*>* bytes = [self.cookedResponse objectForKey:ecu];
        [bytes enumerateObjectsUsingBlock:^(NSNumber * _Nonnull byte, NSUInteger idx, BOOL * _Nonnull stop) {
            [ms appendFormat:@"%02X", byte.unsignedIntValue];
        }];
        [ma addObject:ms];
    }
    
    return [ma componentsJoinedByString:@", "];
}

-(void)didCompleteResponse:(NSArray<NSString*>*)lines completionTime:(NSTimeInterval)completionTime
{
    _rawResponse = lines;
    _completionTime = completionTime;
}

-(void)didCookResponse:(NSDictionary<NSString*,LTOBD2ProtocolResult*>*)responseDictionary withProtocolType:(OBD2VehicleProtocol)protocol
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
    
    _cookedResponse = positiveResponses;
    _failureResponse = negativeResponses;
}

-(void)invalidateResponse
{
    _cookedResponse = nil;
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
    return [[self alloc] initWithRawString:@""];
}

@end
