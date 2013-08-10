//
//  SGCrossfadingLabelView.m
//  NavigationBar
//
//  Created by Nick Lupinetti on 8/8/13.
//  Copyright (c) 2013 Heavy Bits, Inc. All rights reserved.
//

#import "SGCrossfadingLabelView.h"

@implementation SGCrossfadingLabelView
- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _titleLabel = [[UILabel alloc] initWithFrame:frame];
        _detailLabel = [[UILabel alloc] initWithFrame:frame];
        UIViewAutoresizing autoresize = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _titleLabel.autoresizingMask = autoresize;
        _detailLabel.autoresizingMask = autoresize;
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _detailLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_titleLabel];
        [self addSubview:_detailLabel];
        [self updateAlphas];
    }
    return self;
}

- (CGSize)sizeThatFits:(CGSize)size {
    CGSize titleSize = [self.titleLabel sizeThatFits:size];
    CGSize detailSize = [self.detailLabel sizeThatFits:size];
    CGFloat maxWidth = fmaxf(titleSize.width, detailSize.width);
    CGFloat maxHeight = fmaxf(titleSize.height, detailSize.height);
    return CGSizeMake(maxWidth, maxHeight);
}

- (void)setCrossFade:(CGFloat)crossFade animated:(BOOL)animated {
    NSTimeInterval duration = animated ? 0.3 : 0.0;
    [UIView animateWithDuration:duration animations:^{
        self.crossFade = crossFade;
    }];
}

- (void)setCrossFade:(CGFloat)crossFade {
    crossFade = fminf(1.0, fmaxf(0.0, crossFade));
    if (crossFade == _crossFade) return;
    _crossFade = crossFade;
    
    [self updateAlphas];
}

- (void)updateAlphas {
    self.titleLabel.alpha = 1.0 - self.crossFade;
    self.detailLabel.alpha = self.crossFade;
}

@end