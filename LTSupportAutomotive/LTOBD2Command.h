//
//  Copyright (c) Dr. Michael Lauer Information Technology. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

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
@property(nonatomic,readonly) NSDictionary<NSString*,NSArray<NSNumber*>*>* cookedResponse;
@property(nonatomic,readonly,getter=gotAnswer) BOOL answer;
@property(nonatomic,readonly,getter=gotValidAnswer) BOOL validAnswer;
@property(nonatomic,readonly) NSString* formattedResponse;

-(void)didCompleteResponse:(NSArray<NSString*>*)lines completionTime:(NSTimeInterval)completionTime;
-(void)didCookResponse:(NSDictionary<NSString*,NSArray<NSNumber*>*>*)cookedResponse;
-(void)invalidateResponse;

@end

@interface LTOBD2DummyCommand : LTOBD2Command

-(instancetype)initWithRawString:(NSString*)rawString NS_UNAVAILABLE;
-(instancetype)initWithString:(NSString*)string NS_UNAVAILABLE;

+(instancetype)dummyCommand;

@end

NS_ASSUME_NONNULL_END
