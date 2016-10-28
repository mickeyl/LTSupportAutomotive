//
//  Copyright (c) Dr. Michael Lauer Information Technology. All rights reserved.
//

#import "LTOBD2ProtocolISO15765_4.h"

#import "LTSupportAutomotive.h"

/** Protocol examples
 
 07:
 7E8 06 47 02 01 10 01 48
 
 0902:
 7E8 10 14 49 02 01 57 44 58
 7E8 21 2D 53 49 4D 30 30 31
 
 04: (successful)
 7E8 01 44
 
 04: (unsuccessful)
 
 
**/

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
            LOG( @"Warning: Invalid or short line '%@' found", line );
            continue;
        }
        uint address = bytesInLine[addressIndex].unsignedIntValue;

        NSString* sourceKey = [NSString stringWithFormat:@"%X", address];
        LTOBD2ProtocolResult* resultForSource = md[sourceKey];
        if ( !resultForSource )
        {
            md[sourceKey] = resultForSource = [self createProtocolResultForBytes:bytesInLine sidIndex:addressIndex + 2];
        }
        if ( resultForSource.failureType != OBD2FailureTypeInternalOK )
        {
            continue;
        }
        
        uint pci = bytesInLine[addressIndex + 1].unsignedIntValue;
        uint frametype = ( pci & 0b11110000 ) >> 4;
        __unused uint length = ( pci & 0b00001111 );

        BOOL isSingleFrame = ( frametype == 0x00 );
        BOOL isFirstFrameOfMultiple = ( frametype == 0x01 );
        __unused BOOL isConsecutiveFrame = ( frametype == 0x02 );
        NSUInteger multiFrameCorrective = isFirstFrameOfMultiple ? 1 : 0;
        NSUInteger originalCommandCorrective = ( isSingleFrame || isFirstFrameOfMultiple ) ? numberOfBytesInCommand : 0;

        NSUInteger payloadIndex = headerLength + originalCommandCorrective + multiFrameCorrective;
        NSUInteger payloadLength = bytesInLine.count - payloadIndex;
        NSRange payloadRange = NSMakeRange(payloadIndex, payloadLength);
        NSArray<NSNumber*>* payload = [bytesInLine subarrayWithRange:payloadRange];
        [resultForSource appendPayloadBytes:payload];
    }
    
    return [NSDictionary dictionaryWithDictionary:md];
}

@end
