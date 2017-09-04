//
//  Copyright (c) Dr. Michael Lauer Information Technology. All rights reserved.
//

#import "LTOBD2ProtocolISO14230_4.h"

#import "LTOBD2PID.h"

/*** PROTOCOL EXAMPLES
 
 0100
 single line answer, 10 and 17 are the ECU addresses 86 for single line, last byte is checksum, no payload length indicator
 86 F1 10 41 00 B8 7B 30 10 3B  -
 86 F1 17 41 00 80 00 80 03 D2

 0606 - multiline answer without frame index indicator
 "87 F1 10 46 06 03 00 5A 9C 40 0D ",
 "87 F1 10 46 06 85 00 5A 00 00 B3 ",
 "87 F1 10 46 06 09 09 60 88 B8 86 ",
 "87 F1 10 46 06 8A 09 60 00 00 C7"

 
 0902 - multiline answer
 87 F1 10 49 02 01 00 00 00 57 2B  -
 87 F1 10 49 02 02 44 58 2D 53 F1  -
 87 F1 10 49 02 03 49 4D 30 30 CC  -
 87 F1 10 49 02 04 31 39 32 31 A4  -
 87 F1 10 49 02 05 32 33 34 35 A6

 Negative response, multiple ECUs
 83 F1 10 7F 01 12 16
 83 F1 17 7F 01 12 1D
 
***/

@implementation LTOBD2ProtocolISO14230_4

-(LTOBD2Command*)heartbeatCommand
{
    // ISO14230 (KWP2000) has a timeout mechanism, we are supposed to send command 0x3E (Tester present) regularly in order to avoid this.
    return [LTOBD2PID_TESTER_PRESENT_3E pid];
}

-(NSDictionary<NSString*,LTOBD2ProtocolResult*>*)decode:(NSArray<NSString*>*)lines originatingCommand:(NSString*)command
{
    NSMutableDictionary<NSString*,LTOBD2ProtocolResult*>* md = [NSMutableDictionary dictionary];
    
    NSUInteger numberOfBytesInCommand = command.length / 2;
    
    for ( NSString* line in lines )
    {
        NSArray<NSNumber*>* bytesInLine = [self hexStringToArrayOfNumbers:line];
        if ( bytesInLine.count < 3 )
        {
            WARN( @" Invalid or short line '%@' found", line );
            continue;
        }
        
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
        
        NSString* sourceKey = [NSString stringWithFormat:@"%02X", source];
        LTOBD2ProtocolResult* resultForSource = md[sourceKey];
        if ( !resultForSource )
        {
            md[sourceKey] = resultForSource = [self createProtocolResultForBytes:bytesInLine sidIndex:headerLength];
        }
        if ( resultForSource.failureType != OBD2FailureTypeInternalOK )
        {
            continue;
        }

        NSString* headerPrefix = [NSString stringWithFormat:@"%02X %02X %02X", format, target, source];
        BOOL isMultiFrame = [self isMultiFrameWithPrefix:headerPrefix lines:lines]; // slow, should be cached?
        NSUInteger multiFrameCorrective = isMultiFrame ? 1 : 0;

        // <Horrible Hack for Mode 6 which is sending multiline answers without multiline header indication>
        if ( bytesInLine.count > headerLength )
        {
            uint sid = bytesInLine[headerLength].unsignedIntValue & ~0x40;
            if ( sid == 0x06 && bytesInLine.count > headerLength + 1 )
            {
                uint pid = bytesInLine[headerLength+1].unsignedIntValue;
                if ( pid > 0x00 && pid % 0x20 )
                {
                    multiFrameCorrective = 0;
                }
            }
        }
        // </Horrible Hack for Mode 6 which is sending multiline answers without multiline header indication>

        NSUInteger payloadIndex = headerLength + numberOfBytesInCommand + multiFrameCorrective;
        NSUInteger payloadLength = bytesInLine.count - payloadIndex - 1; // last byte is checksum
        NSRange payloadRange = NSMakeRange(payloadIndex, payloadLength);
        NSArray<NSNumber*>* payload = [bytesInLine subarrayWithRange:payloadRange];
        [resultForSource appendPayloadBytes:payload];
    }
    
    return [NSDictionary dictionaryWithDictionary:md];
}

@end

