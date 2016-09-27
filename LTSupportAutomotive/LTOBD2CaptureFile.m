//
//  Copyright (c) Dr. Michael Lauer Information Technology. All rights reserved.
//

#import "LTOBD2CaptureFile.h"

#import "LTSupportAutomotive.h"

static NSDateFormatter* dateFormatter;

@implementation LTOBD2CaptureFile

#pragma mark -
#pragma mark Overrides

+(void)initialize
{
    if ( self != LTOBD2CaptureFile.class )
    {
        return;
    }
    
    dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZZZZZ";
}

#pragma mark -
#pragma mark API

+(instancetype)captureFileFromJSON:(NSString*)path
{
    NSError* e;
    NSData* data = [NSData dataWithContentsOfFile:path options:0 error:&e];
    if ( e )
    {
        LOG( @"Can't read from %@: %@", path, e );
        return nil;
    }
    
    NSDictionary* dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&e];
    if ( e )
    {
        LOG( @"Can't parse JSON: %@", e );
        return nil;
    }
    
    return [[self alloc] initWithDictionary:dict];
}

+(instancetype)captureFileWithManufacturer:(NSString*)manufacturer
                                     model:(NSString*)model
                                   variant:(NSString*)variant
                                 modelYear:(NSString*)modelYear
                                   creator:(NSString*)creator
                                     notes:(NSString*)notes
                                  contents:(NSDictionary<NSString*,NSArray<NSString*>*>*)contents
{
    return [[self alloc] initWithManufacturer:manufacturer model:model variant:variant modelYear:modelYear creator:creator notes:notes contents:contents];
}

-(instancetype)initWithManufacturer:(NSString*)manufacturer
                              model:(NSString*)model
                            variant:(NSString*)variant
                          modelYear:(NSString*)modelYear
                            creator:(NSString*)creator
                              notes:(NSString*)notes
                           contents:(NSDictionary<NSString*,NSArray<NSString*>*>*)contents
{
    if ( ! ( self = [super init] ) )
    {
        return nil;
    }
    
    _manufacturer = manufacturer;
    _model = model;
    _variant = variant;
    _modelYear = modelYear;
    _creator = creator;
    _notes = notes;
    _contents = contents;
    _timestamp = [NSDate date];

    return self;
}

-(instancetype)initWithDictionary:(NSDictionary*)dict
{
    if ( ! ( self = [super init] ) )
    {
        return nil;
    }
    
    _manufacturer = dict[@"manufacturer"];
    _model = dict[@"model"];
    _variant = dict[@"variant"];
    _modelYear = dict[@"modelYear"];
    _creator = dict[@"creator"];
    _notes = dict[@"notes"];
    _contents = dict[@"contents"];
    _timestamp = [dateFormatter dateFromString:dict[@"timestamp"]];
    
    return self;
}

-(BOOL)writeAsJSON:(NSString*)path
{
    NSString* timestamp = _timestamp ? [dateFormatter stringFromDate:_timestamp] : [dateFormatter stringFromDate:[NSDate date]];
    
    NSDictionary* dict = @{
                           @"manufacturer": _manufacturer ?: @"",
                           @"model": _model ?: @"",
                           @"variant": _variant ?: @"",
                           @"modelYear": _modelYear ?: @"",
                           @"creator": _creator ?: @"",
                           @"notes": _notes ?: @"",
                           @"contents": _contents ?: @{},
                           @"timestamp": timestamp,
                           };
    
    NSError* e;
    NSData* data = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&e];
    if ( e )
    {
        LOG( @"Can't serialize %@: %@", self, e );
        return NO;
    }
    
    [data writeToFile:path atomically:YES];
    
    return YES;
}

-(NSString*)formattedName
{
    NSString* str = [NSString stringWithFormat:@"%@ %@ %@",
                     _manufacturer.length ? _manufacturer : @"",
                     _model.length ? _model : @"",
                     _variant.length ? _variant : @""
                     ];
    return str;
}

#pragma mark -
#pragma mark Helpers

+(NSArray<NSString*>*)serializableProperties
{
    return @[
             @"manufacturer",
             @"model",
             @"variant",
             @"modelYear",
             @"creator",
             @"notes",
             @"contents",
             @"timestamp",
             ];
}

#pragma mark -
#pragma mark <NSCoding>

-(void)encodeWithCoder:(NSCoder*)aCoder
{
    for ( NSString* property in [[self class] serializableProperties] )
    {
        [aCoder encodeObject:[self valueForKey:property] forKey:property];
    }
}

-(instancetype)initWithCoder:(NSCoder*)aDecoder
{
    if ( ! ( self = [super init] ) )
    {
        return nil;
    }
    for ( NSString* property in [[self class] serializableProperties] )
    {
        if ( ! [aDecoder containsValueForKey:property ] )
        {
            LOG( @"WARNING: Property %@ not found in serialized archive for class %@", property, NSStringFromClass(self.class) );
        }
        else
        {
            [self setValue:[aDecoder decodeObjectForKey:property] forKey:property];
        }
    }
    
    return self;
}

#pragma mark -
#pragma mark Equality Overrides

-(BOOL)isEqual:(id)object
{
    if ( self == object )
    {
        return YES;
    }
    if ( ! [object isKindOfClass:LTOBD2CaptureFile.class] )
    {
        return NO;
    }
    return [self isEqualToCaptureFile:(LTOBD2CaptureFile*)object];
}

-(BOOL)isEqualToCaptureFile:(LTOBD2CaptureFile*)object
{
    for ( NSString* property in self.class.serializableProperties )
    {
        id thisValue = [self valueForKey:property];
        id otherValue = [object valueForKey:property];
        if ( ! [thisValue isEqual:otherValue] )
        {
            return NO;
        }
    }
    return YES;
}

-(NSUInteger)hash
{
    NSUInteger hash = 0;
    for ( NSString* property in self.class.serializableProperties )
    {
        id<NSObject> value = [self valueForKey:property];
        hash += [value hash];
    }
    return hash;
}

@end
