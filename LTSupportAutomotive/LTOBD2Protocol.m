//
//  Copyright (c) Dr. Michael Lauer Information Technology. All rights reserved.
//

#import "LTOBD2Protocol.h"

@implementation LTOBD2Protocol

+(instancetype)protocol
{
    LTOBD2Protocol* obj = [[self alloc] init];
    return obj;
}

-(instancetype)init
{
    if ( ! ( self = [super init] ) )
    {
        return nil;
    }
    
    return self;
}

-(NSDictionary<NSString*,NSArray<NSNumber*>*>*)decode:(NSArray<NSString*>*)lines originatingCommand:(NSString*)command
{
    NSAssert( NO, @"please implement decode:originatingCommand: in your subclass" );
    return nil;
}

-(LTOBD2Command*)heartbeatCommand
{
    return nil;
}

-(BOOL)isMultiFrameWithPrefix:(NSString*)prefix lines:(NSArray<NSString*>*)lines
{
    __block NSUInteger n = 0;
    [lines enumerateObjectsUsingBlock:^(NSString * _Nonnull line, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if ( [line hasPrefix:prefix] )
        {
            n++;
        }
        if ( n > 1 )
        {
            *stop = YES;
        }
        
    }];
    
    return n > 1;
}

-(NSArray<NSNumber*>*)hexStringToArrayOfNumbers:(NSString*)string
{
    //TODO: Support strings without spaces as well?
    NSMutableArray<NSNumber*>* ma = [NSMutableArray array];
    NSArray<NSString*>* hexValues = [string componentsSeparatedByString:@" "];
    [hexValues enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSScanner* scanner = [NSScanner scannerWithString:obj];
        unsigned int value = 0;
        if ( [scanner scanHexInt:&value] )
        {
            [ma addObject:@(value)];
        }
    }];
    return [NSArray arrayWithArray:ma];
}

@end
