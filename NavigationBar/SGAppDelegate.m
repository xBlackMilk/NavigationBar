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
  UINavigationController *nav = [[SGNavigationController alloc] initWithNavigationBarClass:[SGNavigationBar class] toolbarClass:nil];
  UIColor *barColor = [UIColor orangeColor];
  CGFloat r,g,b;
  [barColor getRed:&r green:&g blue:&b alpha:NULL];
  r = r / 1.0;
  g = g / 1.0;
  b = b / 1.0;
  nav.navigationBar.barTintColor = [UIColor colorWithRed:r green:g blue:b alpha:1.0];
  nav.navigationBar.barTintColor = [UIColor colorWithRed:0.1 green:0.5 blue:.9 alpha:1.0];
    // opacity
//  UINavigationBar *bar = nav.navigationBar;
//  [bar setShadowImage:[UIImage imageNamed:@"orangepix"]];
//  [bar setBackgroundImage:[UIImage imageNamed:@"clearpix"] forBarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
  nav.navigationBar.tintColor = [UIColor whiteColor];
  [nav.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
  nav.viewControllers = @[[[SGMasterViewController alloc] init]];
  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  self.window.rootViewController = nav;
  [self.window makeKeyAndVisible];
  return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
  // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
  // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
  // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
  // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
  // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
  // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
  // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
