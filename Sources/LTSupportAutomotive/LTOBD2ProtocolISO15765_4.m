//
//  Copyright (c) Dr. Michael Lauer Information Technology. All rights reserved.
//
#import "LTOBD2ProtocolISO15765_4.h"

#import "helpers.h"

/*** PROTOCOL EXAMPLES

 07 (single frame)
 7E8 06 47 02 01 10 01 48

 0902 (multiframe)
 7E8 10 14 49 02 01 57 44 58
 7E8 21 2D 53 49 4D 30 30 31

 04 (successful)
 7E8 01 44

 0601 (multiframe)
 7E8 10 37 46 01 01 0A 0E 66
 7E8 21 0E 66 0E 66 01 02 0A
 7E8 22 0E 66 0E 66 0E 66 01
 7E8 23 07 0A 00 00 00 00 0C
 7E8 24 D8 01 08 0A 1D 70 13
 7E8 25 18 22 90 01 09 10 00
 7E8 26 78 00 78 05 F0 01 0A
 7E8 27 10 00 00 00 00 00 00

***/

@implementation LTOBD2ProtocolISO15765_4
{
    NSUInteger _numberOfBitsInHeader;
}

#pragma mark -
#pragma mark Lifecycle

+(instancetype)protocolVariantWith11BitHeaders
{
    return [[self alloc] initWithNumberOfBitsInHeader:11];
}

+(instancetype)protocolVariantWith29BitHeaders
{
    return [[self alloc] initWithNumberOfBitsInHeader:29];
}

-(instancetype)initWithNumberOfBitsInHeader:(NSUInteger)numberOfBitsInHeader
{
    if ( ! ( self = [super init] ) )
    {
        return nil;
    }

    NSAssert( numberOfBitsInHeader == 11 || numberOfBitsInHeader == 29, @"Unsupported number of bits in header. I can only manage 11 or 29" );

    _numberOfBitsInHeader = numberOfBitsInHeader;

    return self;
}

#pragma mark -
#pragma mark API

-(NSDictionary<NSString*,LTOBD2ProtocolResult*>*)decode:(NSArray<NSString*>*)lines originatingCommand:(NSString*)command
{
    NSMutableDictionary<NSString*,LTOBD2ProtocolResult*>* md = [NSMutableDictionary dictionary];

    NSUInteger numberOfBytesInCommand = command.length / 2;
    NSUInteger addressParts = ( _numberOfBitsInHeader == 11 ) ? 1 : 4;
    NSUInteger addressIndex = addressParts - 1;
    NSUInteger headerLength = addressParts + 1;

    for ( NSString* line in lines )
    {
        NSArray<NSNumber*>* bytesInLine = [self hexStringToArrayOfNumbers:line];
        if ( bytesInLine.count < 3 )
        {
            WARN( @" Invalid or short line '%@' found", line );
            continue;
        }
        uint address = bytesInLine[addressIndex].unsignedIntValue;

        NSString* sourceKey = [NSString stringWithFormat:@"%X", address];
        LTOBD2ProtocolResult* resultForSource = md[sourceKey];
        if ( !resultForSource )
        {
            md[sourceKey] = resultForSource = [self createProtocolResultForBytes:bytesInLine sidIndex:addressIndex + 2];
        }
        if ( resultForSource.failureType == OBD2FailureTypeRequestCorrectlyReceivedResponsePending )
        {
            // Note: As per ISO 14229-1, a negative response with type RequestCorrectlyReceivedResponsePending is just an
            // intermediate response which is to be expected whenever the ECU will perform an operation
            // that could take "a bit longer". For OBD2 this should never happen – for UDS, it seems to be quite common.
            // In this case, we assume that another – positive – response is forthcoming, and just swallow the "negative" response.
            md[sourceKey] = resultForSource = [self createProtocolResultForBytes:bytesInLine sidIndex:addressIndex + 2];
        }
        if ( resultForSource.failureType != OBD2FailureTypeInternalOK )
        {
            continue;
        }

        uint pci = bytesInLine[addressIndex + 1].unsignedIntValue;
        uint frametype = ( pci & 0b11110000 ) >> 4;
        __unused uint length = ( pci & 0b00001111 );

        // <Clunky workaround for mode 06 behavior START>
        if ( bytesInLine.count > headerLength + 1 )
        {
            uint sid = bytesInLine[headerLength+1].unsignedIntValue & ~0x40;
            if ( sid == 0x06 && bytesInLine.count > headerLength + 2 )
            {
                uint pid = bytesInLine[headerLength+2].unsignedIntValue;
                if ( pid > 0x00 && pid % 0x20 )
                {
                    numberOfBytesInCommand--;
                }
            }
        }
        // <Clunky workaround for mode 06 behavior STOP>

        BOOL isSingleFrame = ( frametype == 0x00 );
        BOOL isFirstFrameOfMultiple = ( frametype == 0x01 );
        __unused BOOL isConsecutiveFrame = ( frametype == 0x02 );
        NSUInteger multiFrameCorrective = isFirstFrameOfMultiple ? 1 : 0;
        // Note: The original code has been written with OBD2 in mind which has commands that are either one or two bytes.
        // For UDS though, commands (and answers) can be of (almost) arbitrary length, hence we need a corrective of maximal 2 bytes.
        NSUInteger originalCommandCorrective = ( isSingleFrame || isFirstFrameOfMultiple ) ? MIN(2, numberOfBytesInCommand) : 0;

        NSUInteger payloadIndex = headerLength + originalCommandCorrective + multiFrameCorrective;
        NSUInteger payloadLength = bytesInLine.count - payloadIndex;
        NSRange payloadRange = NSMakeRange(payloadIndex, payloadLength);
        NSArray<NSNumber*>* payload = [bytesInLine subarrayWithRange:payloadRange];
        [resultForSource appendPayloadBytes:payload];
    }

    return [NSDictionary dictionaryWithDictionary:md];
}

@end
