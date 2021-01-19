//
//  Copyright (c) Dr. Michael Lauer Information Technology. All rights reserved.
//
#import "helpers.h"

#define LTSUPPORTAUTOMOTIVE_STRINGS_PATH @"Frameworks/LTSupportAutomotive.framework/LTSupportAutomotive"

NSString* LTStringLookupOrNil( NSString* key )
{
    NSString* value = [[NSBundle bundleForClass:NSClassFromString(@"LTVIN")] localizedStringForKey:key value:nil table:nil];
    return [value isEqualToString:key] ? nil : value;
}

NSString* LTStringLookupWithPlaceholder( NSString* key, NSString* placeholder )
{
    NSString* value = [[NSBundle bundleForClass:NSClassFromString(@"LTVIN")] localizedStringForKey:key value:placeholder table:nil];
    return value;
}

void MyNSLog(const char *file, int lineNumber, const char *functionName, NSString *format, ...)
{
    va_list ap;
    va_start (ap, format);
    if ( ![format hasSuffix:@"\n"] )
    {
        format = [format stringByAppendingString:@"\n"];
    }
    NSString* body = [[NSString alloc] initWithFormat:format arguments:ap];
    va_end (ap);

    NSString* fileName = [[NSString stringWithUTF8String:file] lastPathComponent];
    fprintf( stderr, "%s (%s:%d) %s", functionName, [fileName UTF8String], lineNumber, body.UTF8String );
}

NSString* LTDataToString( NSData* d )
{
    NSString* s = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
    return [[s stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"] stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];
}
