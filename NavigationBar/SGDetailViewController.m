//
//  SGDetailViewController.m
//  NavigationBar
//
//  Created by Nick Lupinetti on 7/22/13.
//  Copyright (c) 2013 Heavy Bits, Inc. All rights reserved.
//

#import "SGDetailViewController.h"

@interface SGDetailViewController ()
- (void)configureView;
@end

@implementation SGDetailViewController

#pragma mark - Managing the detail item

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
}

- (void)setDetailItem:(id)newDetailItem
{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        
        // Update the view.
        [self configureView];
    }
}

- (void)configureView
{
    // Update the user interface for the detail item.
  self.view.backgroundColor = [UIColor grayColor];
  if (self.detailItem) {
      self.detailDescriptionLabel.text = [self.detailItem description];
  }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
  [self configureView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
