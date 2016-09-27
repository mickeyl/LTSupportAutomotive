//
//  Copyright (c) Dr. Michael Lauer Information Technology. All rights reserved.
//

#import "LTOBD2ProtocolISO9141_2.h"

#import "LTOBD2Command.h"

/*
 0100 single frame answer
 
 48 6B 10 41 00 B8 7B 30 10 77
 48 6B 17 41 00 80 00 80 03 0E

 0902 multi frame answer
 48 6B 10 49 02 01 00 00 00 57 66  -
 48 6B 10 49 02 02 44 58 2D 53 2C  - 
 48 6B 10 49 02 03 49 4D 30 30 07  - 
 48 6B 10 49 02 04 31 39 32 31 DF  - 
 48 6B 10 49 02 05 32 33 34 35 E1

 */

@implementation LTOBD2ProtocolISO9141_2

-(LTOBD2Command*)heartbeatCommand
{
    // ISO-9141 has a timeout mechanism, we are supposed to send command 0x3E (Tester present) regularly in order to avoid this.
    return [LTOBD2Command commandWithString:@"3E"];
}

-(NSDictionary<NSString*,NSArray<NSNumber*>*>*)decode:(NSArray<NSString*>*)lines originatingCommand:(NSString*)command
{
    NSMutableDictionary<NSString*,NSMutableArray<NSNumber*>*>* md = [NSMutableDictionary dictionary];
    
    NSUInteger numberOfBytesInCommand = command.length / 2;
    
    for ( NSString* line in lines )
    {
        NSArray<NSNumber*>* bytesInLine = [self hexStringToArrayOfNumbers:line];
        
        NSUInteger headerLength = 3; // format, target, source
        __unused uint format = bytesInLine[0].unsignedIntValue;
        __unused uint target = bytesInLine[1].unsignedIntValue;
        uint source = bytesInLine[2].unsignedIntValue;
        
        //FIXME: I'm not sure whether the sid negative response has only been introduced in the successor to ISO9141-2 (14230-4 / KWP2000)
        uint sid = bytesInLine[headerLength].unsignedIntValue;
        if ( sid == 0x7F ) // pidmode & 0x40 is positive, 0x7F is negative response
        {
            continue;
        }
        
        BOOL isMultiFrame = ( bytesInLine.count > 10 ); //FIXME: This can't be right all the time!
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
