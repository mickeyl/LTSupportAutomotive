//
//  Copyright (c) Dr. Michael Lauer Information Technology. All rights reserved.
//

#import "LTOBD2ProtocolSAEJ1850.h"

/*
 0100 single line response (PWM)
 41 6B 10 41 00 B8 7B 30 10 9E
 41 6B 17 41 00 80 00 80 03 C9

 0100 single line response (VPWM)
 48 6B 10 41 00 B8 7B 30 10 F4
 48 6B 17 41 00 80 00 80 03 A3

 0902 multi line response (PWM & VPWM)
 48 6B 10 49 02 01 00 00 00 57 B3  - 
 48 6B 10 49 02 02 44 58 2D 53 99  - 
 48 6B 10 49 02 03 49 4D 30 30 11  - 
 48 6B 10 49 02 04 31 39 32 31 B6  - 
 48 6B 10 49 02 05 32 33 34 35 A8
*/

@implementation LTOBD2ProtocolSAEJ1850

-(NSDictionary<NSString*,NSArray<NSNumber*>*>*)decode:(NSArray<NSString*>*)lines originatingCommand:(NSString*)command
{
    NSMutableDictionary<NSString*,NSMutableArray<NSNumber*>*>* md = [NSMutableDictionary dictionary];
    
    NSUInteger numberOfBytesInCommand = command.length / 2;
    
    for ( NSString* line in lines )
    {
        NSArray<NSNumber*>* bytesInLine = [self hexStringToArrayOfNumbers:line];
        
        NSUInteger headerLength = 3; // format, target, source
        uint format = bytesInLine[0].unsignedIntValue;
        uint target = bytesInLine[1].unsignedIntValue;
        uint source = bytesInLine[2].unsignedIntValue;
        
        NSString* headerPrefix = [NSString stringWithFormat:@"%02X %02X %02X", format, target, source];
        BOOL isMultiFrame = [self isMultiFrameWithPrefix:headerPrefix lines:lines]; // slow, should be cached?
        NSUInteger multiFrameCorrective = isMultiFrame ? 1 : 0;
        
        NSUInteger payloadIndex = headerLength + numberOfBytesInCommand + multiFrameCorrective;
        NSUInteger payloadLength = bytesInLine.count - payloadIndex - 1; // last byte is checksum
        NSRange payloadRange = NSMakeRange(payloadIndex, payloadLength);
        NSArray<NSNumber*>* payload = [bytesInLine subarrayWithRange:payloadRange];
        
        NSString* sourceString = [NSString stringWithFormat:@"%02X", source];
        NSMutableArray<NSNumber*>* existingBytesForSource = [md objectForKey:sourceString] ?: [NSMutableArray array];
        [existingBytesForSource addObjectsFromArray:payload];
        [md setObject:existingBytesForSource forKey:sourceString];
    }
    
    return [NSDictionary dictionaryWithDictionary:md];
}

@end
