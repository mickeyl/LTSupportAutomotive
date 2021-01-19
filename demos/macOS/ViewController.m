//
//  ViewController.m
//  macOS_Demo
//
//  Created by Dr. Michael Lauer on 13.08.18.
//  Copyright © 2018 Dr. Lauer Information Technology. All rights reserved.
//

#import "ViewController.h"

#import <LTSupportAutomotive/LTSupportAutomotive.h>

NSString* const TTY = @"/dev/cu.usbserial-113010893810";

@implementation ViewController
{
    LTOBD2AdapterELM327* _adapter;
}

-(void)viewDidLoad
{
    [super viewDidLoad];

    NSLog( @"Hello!\n" );

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAdapterDidOpenStream:) name:LTOBD2AdapterDidOpenStream object:nil];

    NSInputStream* is = [NSInputStream inputStreamWithFileAtPath:TTY];
    NSOutputStream* os = [NSOutputStream outputStreamToFileAtPath:TTY append:NO];
    _adapter = [LTOBD2AdapterELM327 adapterWithInputStream:is outputStream:os];
    [_adapter connect];
}

-(void)setRepresentedObject:(id)representedObject
{
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

#pragma mark -
#pragma mark Notifications

-(void)onAdapterDidOpenStream:(NSNotification*)notification
{
    NSStream* stream = (NSStream*)notification.object;
    if ( [stream isKindOfClass:NSInputStream.class] )
    {
        NSString* command = [NSString stringWithFormat:@"stty -f %@ speed 115200baud", TTY];
        system( command.UTF8String );
    }
}

@end
