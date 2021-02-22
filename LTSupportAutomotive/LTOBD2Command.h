//
//  Copyright (c) Dr. Michael Lauer Information Technology. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LTOBD2Adapter.h"

NS_ASSUME_NONNULL_BEGIN

extern NSNumber* OBD2_NO_DATA_NUMBER;

@class LTOBD2ProtocolResult;

typedef enum : NSUInteger {
    LTString,
    LTInteger,
    LTDouble
} LTResponseDataType;

@interface LTOBD2Command : NSObject

+(instancetype)commandWithRawString:(NSString*)rawString;
+(instancetype)commandWithString:(NSString*)string;
+(instancetype)new NS_UNAVAILABLE;

-(instancetype)initWithRawString:(NSString*)rawString NS_DESIGNATED_INITIALIZER;
-(instancetype)initWithString:(NSString*)string NS_DESIGNATED_INITIALIZER;
-(instancetype)init NS_UNAVAILABLE;

@property(readonly,nonatomic) NSString* purpose;

@property(nonatomic,readonly) NSArray<NSString*>* rawResponse;
@property(nonatomic,readonly,getter=isRawCommand) BOOL rawCommand;
@property(nonatomic,readonly) NSTimeInterval completionTime;

@property(nonatomic,readonly) NSString* commandString;
@property(nonatomic,readonly) OBD2VehicleProtocol protocol;
/**
 Payload of bytes within the response message. The dictionary maps the response from each ECU that responded to the command.
 Each entry contains the list of response bytes represented as NSNumbers.
 */
@property(nonatomic,readonly) NSDictionary<NSString*,NSArray<NSNumber*>*>* responsePayload;
@property(nonatomic,readonly) NSDictionary<NSString*,NSNumber*>* failureResponse;
@property(nonatomic,readonly,getter=gotAnswer) BOOL answer;
@property(nonatomic,readonly,getter=gotValidAnswer) BOOL validAnswer;
@property(nonatomic,readonly,getter=isCAN) BOOL CAN;
@property(nonatomic,readonly) LTResponseDataType responseDataType;
@property(nonatomic,readonly) NSString* units;
@property(nonatomic,readonly) NSString* format;
@property(nonatomic,readonly) NSString* formattedResponse;

/**
 Decode the array of bytes in the responsePayload into an Object appropriate for application usage.
 Default implementation is to decode the array of bytes in the responsePayload as unsigned int values, and convert them to a String of comma separated unsigned int values.
 Other specialised implementations will convert to Integer, Double etc.
*/
-(NSObject*) decodeResponse;
-(void)didCompleteResponse:(NSArray<NSString*>*)lines completionTime:(NSTimeInterval)completionTime;
-(void)didUnpackResponsePayload:(NSDictionary<NSString*,LTOBD2ProtocolResult*>*)responseDictionary withProtocolType:(OBD2VehicleProtocol)protocol;
-(void)invalidateResponse;

@end

@interface LTOBD2DummyCommand : LTOBD2Command

-(instancetype)initWithRawString:(NSString*)rawString NS_UNAVAILABLE;
-(instancetype)initWithString:(NSString*)string NS_UNAVAILABLE;

+(instancetype)dummyCommand;

@end

NS_ASSUME_NONNULL_END

