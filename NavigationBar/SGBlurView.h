//
//  SGBlurView.h
//  NavigationBar
//
//  Created by Nick Lupinetti on 7/26/13.
//  Copyright (c) 2013 Heavy Bits, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SGBlurView : UIView

+ (void)prepareBlurViewsWithNavigationBar:(UINavigationBar *)navigationBar;
+ (void)prepareBlurViewsWithToolbar:(UIToolbar *)toolbar;

@end
