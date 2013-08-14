//
//  SGAppDelegate.m
//  NavigationBar
//
//  Created by Nick Lupinetti on 7/22/13.
//  Copyright (c) 2013 Heavy Bits, Inc. All rights reserved.
//

#import "SGAppDelegate.h"
//#import "SGMasterViewController.h"
#import "SGNavigationBar.h"
#import "SGNavigationController.h"
#import "SGSegmentBarController.h"
#import "SGTableViewController.h"

@implementation SGAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    srand(time(NULL));
    
    UINavigationController *nav = [[SGNavigationController alloc] initWithNavigationBarClass:[SGNavigationBar class] toolbarClass:nil];
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
    bar.tintColor = [UIColor whiteColor];
    bar.barTintColor = [UIColor colorWithRed:218.0/255.0 green:80.0/255.0 blue:15.0/255.0 alpha:1.0];
    bar.translucent = NO;
//    [bar setBackgroundImage:[UIImage imageNamed:@"orangepix"] forBarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
//    [bar setBackgroundImage:[UIImage imageNamed:@"orange_pixel"] forBarMetrics:UIBarMetricsDefault]; // iOS 6 friendly
    
    [bar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    
    SGTableViewController *tvc1 = [[SGTableViewController alloc] init];
    SGTableViewController *tvc2 = [[SGTableViewController alloc] init];
    SGTableViewController *tvc3 = [[SGTableViewController alloc] init];
    SGSegmentBarController *sbc = [[SGSegmentBarController alloc] init];
    sbc.segmentBar.tintColor = [UIColor colorWithRed:246.0/255.0 green:241.0/255.0 blue:234.0/255.0 alpha:1.0];
    sbc.segmentBar.segmentedControl.backgroundColor = [UIColor colorWithRed:193.0/255.0 green:64.0/255.0 blue:0.0 alpha:1.0];
    sbc.segmentBar.backgroundColor = bar.barTintColor;
    sbc.title = @"Explore";
    tvc1.title = @"Popular";
    tvc2.title = @"Featured";
    tvc3.title = @"Recent";
    sbc.viewControllers = @[tvc1, tvc2, tvc3];
    nav.viewControllers = @[sbc];
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = nav;
    [self.window makeKeyAndVisible];
    self.rootViewController = nav;
    
    return YES;
}

@end
