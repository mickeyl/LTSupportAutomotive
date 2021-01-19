//
//  Copyright (c) Dr. Michael Lauer Information Technology. All rights reserved.
//

#import "LTOBD2Protocol.h"

/* OBD2 Protocols P6, P7, P8, P9 */

NS_ASSUME_NONNULL_BEGIN

@interface LTOBD2ProtocolISO15765_4 : LTOBD2Protocol

+(instancetype)protocol NS_UNAVAILABLE;
+(instancetype)protocolVariantWith11BitHeaders;
+(instancetype)protocolVariantWith29BitHeaders;

-(instancetype)new NS_UNAVAILABLE;
-(instancetype)init NS_UNAVAILABLE;
-(instancetype)initWithNumberOfBitsInHeader:(NSUInteger)numberOfBitsInHeader NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
