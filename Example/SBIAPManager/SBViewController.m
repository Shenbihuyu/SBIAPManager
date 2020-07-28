//
//  SBViewController.m
//  SBIAPManager
//
//  Created by waing on 07/28/2020.
//  Copyright (c) 2020 waing. All rights reserved.
//

#import "SBViewController.h"
#import <IAPManager.h>

@interface SBViewController() <IAPManagerObserver>
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activetyView;

@end

@implementation SBViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)buyAction:(id)sender {
    
}
- (IBAction)restoreAction:(id)sender {
    [IAPManager.shareInstance restoreBuy];
}


@end
