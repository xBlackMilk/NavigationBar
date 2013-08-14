//
//  SGSegmentBarControllerTransitionAnimator.m
//  NavigationBar
//
//  Created by Nick Lupinetti on 8/14/13.
//  Copyright (c) 2013 Heavy Bits, Inc. All rights reserved.
//

#import "SGSegmentBarControllerTransitionAnimator.h"

@implementation SGSegmentBarControllerTransitionAnimator

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    CGRect endFrame = [transitionContext initialFrameForViewController:fromVC];
    CGRect startFrame = endFrame;
    startFrame.origin.x += startFrame.size.width * (self.leftToRight ? -1 : 1);
    
    fromVC.view.frame = endFrame;
    toVC.view.frame = startFrame;
    [transitionContext.containerView addSubview:fromVC.view];
    [transitionContext.containerView addSubview:toVC.view];
    
    [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        toVC.view.frame = endFrame;
    } completion:^(BOOL finished) {
        [transitionContext completeTransition:YES];
    }];
}

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return 1.0;
}

@end
