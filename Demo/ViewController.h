//
//  CarCommunicationViewController.h
//  LTSupportDemo
//
//  Created by Dr. Michael Lauer on 14.06.16.
//  Copyright © 2016 Vanille Media. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *adapterStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel *rpmLabel;
@property (weak, nonatomic) IBOutlet UILabel *speedLabel;
@property (weak, nonatomic) IBOutlet UILabel *tempLabel;

@property (weak, nonatomic) IBOutlet UILabel *rssiLabel;
@property (weak, nonatomic) IBOutlet UILabel *outgoingBytesNotification;
@property (weak, nonatomic) IBOutlet UILabel *incomingBytesNotification;

@end
