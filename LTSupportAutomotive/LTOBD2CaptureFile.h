//
//  Copyright (c) Dr. Michael Lauer Information Technology. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LTOBD2CaptureFile : NSObject <NSCoding>

@property(strong,nonatomic,readonly) NSString* manufacturer;
@property(strong,nonatomic,readonly) NSString* model;
@property(strong,nonatomic,readonly) NSString* variant;
@property(strong,nonatomic,readonly) NSString* modelYear;
@property(strong,nonatomic,readonly) NSString* creator;
@property(strong,nonatomic,readonly) NSString* notes;
@property(strong,nonatomic,readonly) NSDictionary<NSString*,NSArray<NSString*>*>* contents;
@property(strong,nonatomic,readonly) NSDate* timestamp;

+(nullable instancetype)captureFileFromJSON:(NSString*)path;

+(nullable instancetype)captureFileWithManufacturer:(NSString*)manufacturer
                                              model:(NSString*)model
                                            variant:(NSString*)variant
                                          modelYear:(NSString*)modelYear
                                            creator:(NSString*)creator
                                              notes:(NSString*)notes
                                           contents:(NSDictionary<NSString*,NSArray<NSString*>*>*)contents;

-(nullable instancetype)initWithManufacturer:(NSString*)manufacturer
                              model:(NSString*)model
                            variant:(NSString*)variant
                          modelYear:(NSString*)modelYear
                            creator:(NSString*)creator
                              notes:(NSString*)notes
                           contents:(NSDictionary<NSString*,NSArray<NSString*>*>*)contents;

-(nullable instancetype)init NS_UNAVAILABLE;

-(BOOL)writeAsJSON:(NSString*)path;

@property(nonatomic,readonly) NSString* formattedName;

@end

NS_ASSUME_NONNULL_END
