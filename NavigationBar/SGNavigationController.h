//
//  SGNavigationController.h
//  NavigationBar
//
//  Created by Nick Lupinetti on 7/26/13.
//  Copyright (c) 2013 Heavy Bits, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SGNavigationController : UINavigationController
@property (nonatomic, readonly) UIToolbar *accessoryBar;
@end

@interface UIViewController (SGNavigationController)
@property (nonatomic) BOOL showsAccessoryBar;
@end