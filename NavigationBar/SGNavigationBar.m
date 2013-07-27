//
//  SGNavigationBar.m
//  NavigationBar
//
//  Created by Nick Lupinetti on 7/24/13.
//  Copyright (c) 2013 Heavy Bits, Inc. All rights reserved.
//

#import "SGNavigationBar.h"

@implementation SGNavigationBar

- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self hideShadowImage];
  }
  return self;
}

- (void)hideShadowImage {
  UIImageView *shadow = [self findShadowView];
  shadow.hidden = YES;
}

- (UIImageView *)findShadowView {
  return [self findShadowViewInView:self];
}

- (UIImageView *)findShadowViewInView:(UIView *)view {
  if ([view isMemberOfClass:[UIImageView class]] && view.frame.size.height == 0.5) {
    return (UIImageView *)view;
  }
  for (UIView *subview in [view subviews]) {
    return [self findShadowViewInView:subview];
  }
  return nil;
}

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect
 {
 // Drawing code
 }
 */

@end
