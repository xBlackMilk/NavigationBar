//
//  SGSegmentBar.h
//  NavigationBar
//
//  Created by Nick Lupinetti on 8/8/13.
//  Copyright (c) 2013 Heavy Bits, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SGSegmentBar : UIView

@property (nonatomic, readonly) UISegmentedControl *segmentedControl;
@property (nonatomic, readonly) CGFloat maxShrinkage;
@property (nonatomic) CGFloat shrinkage;

- (void)setShrinkage:(CGFloat)shrinkage animated:(BOOL)animated;

@end
