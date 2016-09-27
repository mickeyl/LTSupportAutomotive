//
//  Copyright (c) Dr. Michael Lauer Information Technology. All rights reserved.
//

#import "LTOBD2ProtocolISO14230_4.h"

/*
 
 0100
 single line answer, 10 and 17 are the ECU addresses 86 for single line, last byte is checksum, no payload length indicator
 
 86 F1 10 41 00 B8 7B 30 10 3B  -
 86 F1 17 41 00 80 00 80 03 D2

 0902
 multiline answer
 
 87 F1 10 49 02 01 00 00 00 57 2B  -
 87 F1 10 49 02 02 44 58 2D 53 F1  -
 87 F1 10 49 02 03 49 4D 30 30 CC  -
 87 F1 10 49 02 04 31 39 32 31 A4  -
 87 F1 10 49 02 05 32 33 34 35 A6

 ECU not responding answer?
 83 F1 10 7F 01 12 16
 83 F1 17 7F 01 12 1D

 NOTE2: 0x1A is supposed to gather ECU identification, might be interesting to try that.
 
 */

@implementation LTOBD2ProtocolISO14230_4

-(LTOBD2Command*)heartbeatCommand
{
    // KWP 2000 has a timeout mechanism, we are supposed to send command 0x3E (Tester present) regularly in order to avoid this.
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
        uint format = bytesInLine[0].unsignedIntValue;
        uint target = bytesInLine[1].unsignedIntValue;
        uint source = bytesInLine[2].unsignedIntValue;
        
        uint length = ( format & 0b00111111 );
        BOOL haveLengthInHeader = ( length > 0 );
        if ( !haveLengthInHeader )
        {
            length = bytesInLine[3].unsignedIntValue;
            headerLength++;
        }
        uint sid = bytesInLine[headerLength].unsignedIntValue;
        if ( sid == 0x7F ) // pidmode & 0x40 is positive, 0x7F is negative response
        {
            continue;
        }

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

