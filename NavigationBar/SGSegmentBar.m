//
//  SGSegmentBar.m
//  NavigationBar
//
//  Created by Nick Lupinetti on 8/8/13.
//  Copyright (c) 2013 Heavy Bits, Inc. All rights reserved.
//

#import "SGSegmentBar.h"

@interface SGSegmentBar()
@property (nonatomic, getter = isAdjustingShrinkage) BOOL adjustingShrinkage;
@property (nonatomic) CGRect fullFrame;
@end

@implementation SGSegmentBar

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _segmentedControl = [[UISegmentedControl alloc] initWithItems:@[]];
        [self addSubview:self.segmentedControl];
        [self updateSegmentedControlFrame];
        self.clipsToBounds = YES;
        self.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (void)setShrinkage:(CGFloat)shrinkage animated:(BOOL)animated {
    self.adjustingShrinkage = YES;
    NSTimeInterval duration = animated ? 0.3 : 0.0;
    [UIView animateWithDuration:duration delay:0.0 usingSpringWithDamping:1 initialSpringVelocity:0.0 options:0 animations:^{
        self.shrinkage = shrinkage;
    } completion:^(BOOL finished) {
        self.adjustingShrinkage = NO;
    }];
}

- (void)setFrame:(CGRect)frame {
    BOOL sizeChange = !CGSizeEqualToSize(frame.size, self.frame.size);
    [super setFrame:frame];
    
    if (sizeChange && !self.adjustingShrinkage) {
        self.fullFrame = frame;
        [self updateSegmentedControlFrame];
    }
}

- (void)updateSegmentedControlFrame {
    CGFloat horizontalInsets = 10.0;
    CGFloat verticalInsets = (self.bounds.size.height - self.segmentedControl.frame.size.height) / 2;
    CGRect frame = CGRectInset(self.bounds, horizontalInsets, verticalInsets);
    frame.size.height = self.segmentedControl.frame.size.height;
    self.segmentedControl.frame = frame;
}

- (CGFloat)maxShrinkage {
    return self.fullFrame.size.height;
}

- (CGFloat)maxShrinkFactor {
    return 0.5;
}

- (void)setShrinkage:(CGFloat)shrinkage {
    shrinkage = fmaxf(0, fminf([self maxShrinkage], shrinkage));
    if (shrinkage == _shrinkage) return;
    _shrinkage = shrinkage;
    [self updateShrinkage];
}

- (void)updateShrinkage {
    self.adjustingShrinkage = YES;
    
    CGRect frame = self.fullFrame;
    frame.size.height -= self.shrinkage;
    self.frame = frame;
    
    CGFloat alpha = self.shrinkage / [self maxShrinkage];
    self.segmentedControl.alpha = 1 - alpha;
    
    CGFloat shrinkFactor = 1 - (self.shrinkage / [self maxShrinkage] * (1 - [self maxShrinkFactor]));
    self.segmentedControl.transform = CGAffineTransformMakeScale(shrinkFactor, shrinkFactor);
    self.segmentedControl.center = CGPointMake(self.bounds.size.width / 2.0, self.bounds.size.height / 2.0);
    
    self.segmentedControl.userInteractionEnabled = self.shrinkage == 0;
    
    self.adjustingShrinkage = NO;
}

@end
