//
//  Copyright (c) Dr. Michael Lauer Information Technology. All rights reserved.
//
#import "LTOBD2ProtocolSAEJ1850.h"

#import "helpers.h"

/*** PROTOCOL EXAMPLES

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

***/

@implementation LTOBD2ProtocolSAEJ1850

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
