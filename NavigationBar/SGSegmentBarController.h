//
//  SGSegmentBarController.h
//  NavigationBar
//
//  Created by Nick Lupinetti on 8/8/13.
//  Copyright (c) 2013 Heavy Bits, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SGSegmentBar.h"

@interface SGSegmentBarController : UIViewController

@property (nonatomic, readonly) SGSegmentBar *segmentBar;
@property (nonatomic, copy) NSArray *viewControllers;
@property (nonatomic) UIViewController *selectedViewController;
@property (nonatomic) NSUInteger selectedIndex;

@end
