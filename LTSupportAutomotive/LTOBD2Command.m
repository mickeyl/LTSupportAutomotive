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

-(void)didCookResponse:(NSDictionary<NSString *,NSArray<NSNumber *> *> *)cookedResponse
{
    _cookedResponse = cookedResponse;
}

-(void)invalidateResponse
{
    _cookedResponse = nil;
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
