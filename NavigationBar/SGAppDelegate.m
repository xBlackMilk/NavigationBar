//
//  SGAppDelegate.m
//  NavigationBar
//
//  Created by Nick Lupinetti on 7/22/13.
//  Copyright (c) 2013 Heavy Bits, Inc. All rights reserved.
//

#import "SGAppDelegate.h"
#import "SGMasterViewController.h"
#import "SGNavigationBar.h"
#import "SGNavigationController.h"

@implementation SGAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  UINavigationController *nav = [[UINavigationController alloc] initWithNavigationBarClass:[SGNavigationBar class] toolbarClass:nil];
  UIColor *barColor = [UIColor orangeColor];
  CGFloat r,g,b;
  [barColor getRed:&r green:&g blue:&b alpha:NULL];
  r = r / 1.0;
  g = g / 1.0;
  b = b / 1.0;
//  nav.navigationBar.barTintColor = [UIColor colorWithRed:r green:g blue:b alpha:1.0];
//  nav.navigationBar.barTintColor = [UIColor colorWithRed:0.1 green:0.5 blue:.9 alpha:1.0];
    // opacity
  UINavigationBar *bar = nav.navigationBar;
  [bar setShadowImage:[UIImage imageNamed:@"clearpix"]];
  [bar setBackgroundImage:[UIImage imageNamed:@"orangepix"] forBarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
  nav.navigationBar.tintColor = [UIColor whiteColor];
  [nav.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
  nav.viewControllers = @[[[SGMasterViewController alloc] init]];
  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  self.window.rootViewController = nav;
  [self.window makeKeyAndVisible];
  return YES;
}

@end
