//
//  SGNavigationController.m
//  NavigationBar
//
//  Created by Nick Lupinetti on 7/26/13.
//  Copyright (c) 2013 Heavy Bits, Inc. All rights reserved.
//

#import "SGNavigationController.h"

@interface SGNavigationController ()

@end

@implementation SGNavigationController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc {
  [self teardownKVO];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setNeedsStatusBarAppearanceUpdate];
	// Do any additional setup after loading the view.
//  barFrame.size.height = 0.0;
//  _accessoryBar = [[UIToolbar alloc] init];
//  _accessoryBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
//  [self.view addSubview:_accessoryBar];
//  [self positionAccessoryBar];
//  [self tintAccessoryBar];
//  [self setupKVO];
}

- (void)setupKVO {
  [self.navigationBar addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:NULL];
  [self.navigationBar addObserver:self forKeyPath:@"barTintColor" options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)teardownKVO {
  [self.navigationBar removeObserver:self forKeyPath:@"frame"];
  [self.navigationBar removeObserver:self forKeyPath:@"barTintColor"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  if ([keyPath isEqualToString:@"frame"]) {
    [self positionAccessoryBar];
  }
  else if ([keyPath isEqualToString:@"barTintColor"]) {
    [self tintAccessoryBar];
  }
}

- (void)tintAccessoryBar {
  self.accessoryBar.barTintColor = self.navigationBar.barTintColor;
}

- (void)positionAccessoryBar {
  CGRect barFrame = self.navigationBar.frame;
  barFrame.origin.y = CGRectGetMaxY(barFrame);
  barFrame.origin.y = 64.0;
  self.accessoryBar.frame = barFrame;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end
