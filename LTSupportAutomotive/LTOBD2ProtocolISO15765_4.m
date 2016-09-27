//
//  Copyright (c) Dr. Michael Lauer Information Technology. All rights reserved.
//

#import "LTOBD2ProtocolISO15765_4.h"

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

-(NSDictionary<NSString*,NSArray<NSNumber*>*>*)decode:(NSArray<NSString*>*)lines originatingCommand:(NSString*)command
{
    NSMutableDictionary<NSString*,NSMutableArray<NSNumber*>*>* md = [NSMutableDictionary dictionary];
    
    NSUInteger numberOfBytesInCommand = command.length / 2;
    NSUInteger addressParts = ( _numberOfBitsInHeader == 11 ) ? 1 : 4;
    NSUInteger addressIndex = addressParts - 1;
    NSUInteger headerLength = addressParts + 1;
    
    for ( NSString* line in lines )
    {
        NSArray<NSNumber*>* bytesInLine = [self hexStringToArrayOfNumbers:line];
        uint address = bytesInLine[addressIndex].unsignedIntValue;
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
        
        NSString* sourceString = [NSString stringWithFormat:@"%X", address];
        NSMutableArray<NSNumber*>* existingBytesForSource = [md objectForKey:sourceString] ?: [NSMutableArray array];
        [existingBytesForSource addObjectsFromArray:payload];
        [md setObject:existingBytesForSource forKey:sourceString];
    }
    
    return [NSDictionary dictionaryWithDictionary:md];
}

@end
