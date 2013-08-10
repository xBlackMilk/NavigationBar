//
//  SGCrossfadingLabelView.h
//  NavigationBar
//
//  Created by Nick Lupinetti on 8/8/13.
//  Copyright (c) 2013 Heavy Bits, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SGCrossfadingLabelView : UIView

@property (nonatomic, readonly) UILabel *titleLabel;
@property (nonatomic, readonly) UILabel *detailLabel;
@property (nonatomic) CGFloat crossFade;

@end