//
//  SGBlurView.m
//  NavigationBar
//
//  Created by Nick Lupinetti on 7/26/13.
//  Copyright (c) 2013 Heavy Bits, Inc. All rights reserved.
//

#import "SGBlurView.h"

static CALayer *kPrototypeBlurLayer = nil;

@implementation SGBlurView

static UIToolbar * kPrototypeToolbar;

//- (id)initWithFrame:(CGRect)frame {
//    self = [super initWithFrame:frame];
//    if (self) {
//      [self addSubview:kPrototypeToolbar];
//    }
//    return self;
//}

+ (Class)layerClass {
  return [kPrototypeBlurLayer class];
}

+ (void)prepareBlurViewsWithNavigationBar:(UINavigationBar *)navigationBar {
  kPrototypeBlurLayer = [self findTranslucentLayerInView:navigationBar];
}

+ (void)prepareBlurViewsWithToolbar:(UIToolbar *)toolbar {
  kPrototypeBlurLayer = [self findTranslucentLayerInView:toolbar];
}

+ (CALayer *)findTranslucentLayerInView:(UIView *)view {
  if ([view.layer isKindOfClass:NSClassFromString(@"CABackdropLayer")]) {
    return view.layer;
  }
  for (UIView *subview in view.subviews) {
    CALayer *layer = [self findTranslucentLayerInView:subview];
    if (layer) {
      return layer;
    }
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
