//
//  SGSegmentBarController.m
//  Bamboo
//
//  Created by Nick Lupinetti on 8/8/13.
//  Copyright (c) 2013 Heavy Bits, Inc. All rights reserved.
//

#import "SGSegmentBarController.h"

#import "SGCrossfadingLabelView.h"
//#import "SGSegmentBarControllerTransitionAnimator.h"
#import <objc/objc-runtime.h>


static const char kSGSegmentItemKey;
static const char kSGSegmentControllerKey;
static const CGFloat kSGSegmentBarControllerBarHeight = 44.0;


@implementation SGSegmentBarItem
@end


@implementation UIViewController (SGSegmentBarControllerItem)

- (void)setSegmentBarController:(SGSegmentBarController *)segmentBarController {
    objc_setAssociatedObject(self, &kSGSegmentControllerKey, segmentBarController, OBJC_ASSOCIATION_ASSIGN);
}

- (SGSegmentBarController *)segmentBarController {
    return objc_getAssociatedObject(self, &kSGSegmentControllerKey);
}

- (void)setSegmentBarItem:(SGSegmentBarItem *)segmentBarItem {
    [self willChangeValueForKey:@"segmentBarItem"];
    objc_setAssociatedObject(self, &kSGSegmentItemKey, segmentBarItem, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self didChangeValueForKey:@"segmentBarItem"];
}

- (SGSegmentBarItem *)segmentBarItem {
    SGSegmentBarItem *item = objc_getAssociatedObject(self, &kSGSegmentItemKey);
    if (!item) {
        item = [[SGSegmentBarItem alloc] init];
        self.segmentBarItem = item;
    }
    return item;
}

@end


@interface UIViewController (SGSegmentBarItemChecking)
- (BOOL)hasSegmentBarItem;
@end

@implementation UIViewController (SGSegmentBarItemChecking)
- (BOOL)hasSegmentBarItem {
    return objc_getAssociatedObject(self, &kSGSegmentItemKey) != nil;
}
@end



@interface SGSegmentBarController ()// <UIViewControllerTransitioningDelegate>
@property (nonatomic, strong) SGCrossfadingLabelView *titleView;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) NSMutableArray *viewLoadedMap;
@end

@implementation SGSegmentBarController

@synthesize segmentBar = _segmentBar;

#pragma mark - Memory Management

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _selectedIndex = NSNotFound;
    }
    return self;
}

- (void)dealloc {
    for (UIViewController *controller in self.viewControllers) {
        controller.segmentBarController = nil;
    }
    [self unloadViewController:self.selectedViewController];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self addSegmentBar];
    
    if (!self.selectedViewController && [self.viewControllers count]) {
        self.selectedIndex = 0;
    }
    
    [self loadViewController:self.selectedViewController];
    [self setUpTitleView];
    [self loadViewControllerTitles];
}

- (void)setUpTitleView {
    self.titleView = [[SGCrossfadingLabelView alloc] init];
    
    NSString *title = self.navigationItem.title;
    if (!title) {
        title = self.title;
    }
    
    self.titleView.titleLabel.text = title;
    self.titleView.detailLabel.text = [self titleForViewControllerAtIndex:self.selectedIndex];
    self.titleView.titleLabel.textColor = [[self.navigationController.navigationBar titleTextAttributes] valueForKey:NSForegroundColorAttributeName];
    self.titleView.detailLabel.textColor = [[self.navigationController.navigationBar titleTextAttributes] valueForKey:NSForegroundColorAttributeName];
    [self.titleView sizeToFit];
    self.navigationItem.titleView = self.titleView;
    
    [self.titleView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showSegmentBar)]];
}

#pragma mark - Segment bar management

- (SGSegmentBar *)segmentBar {
    if (!_segmentBar) {
        _segmentBar = [[SGSegmentBar alloc] init];
    }
    return _segmentBar;
}

- (void)addSegmentBar {
    CGFloat height = [self respondsToSelector:@selector(topLayoutGuide)] ? [[self topLayoutGuide] length] : 0.0;
    CGRect frame = CGRectMake(0.0, height, self.view.bounds.size.width, kSGSegmentBarControllerBarHeight);
    
    self.segmentBar.frame = frame;
    [self.segmentBar.segmentedControl addTarget:self action:@selector(segmentControllerChanged:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.segmentBar];
}

- (void)segmentControllerChanged:(UISegmentedControl *)segmentedControl {
    self.selectedIndex = self.segmentBar.segmentedControl.selectedSegmentIndex;
//    NSUInteger selectedIndex = self.segmentBar.segmentedControl.selectedSegmentIndex;
//    
//    UIViewController *presentedController = self.viewControllers[selectedIndex];
//    presentedController.transitioningDelegate = self;
//    presentedController.modalPresentationStyle = UIModalPresentationCustom;
//    [self.selectedViewController presentViewController:presentedController animated:YES completion:^{_selectedIndex = selectedIndex;}];
}

- (void)showSegmentBar {
    [self.segmentBar setShrinkage:0.0 animated:YES];
    [self.titleView setCrossFade:0.0 animated:YES];
}

- (void)hideSegmentBar {
    [self.segmentBar setShrinkage:[self.segmentBar maxShrinkage] animated:YES];
    [self.titleView setCrossFade:1.0 animated:YES];
}

#pragma mark - Child view controller management

- (BOOL)hasLoadedViewController:(UIViewController *)viewController {
    NSUInteger index = [self.viewControllers indexOfObject:viewController];
    return [self.viewLoadedMap[index] boolValue];
}

- (void)setHasLoadedViewController:(UIViewController *)viewController {
    NSUInteger index = [self.viewControllers indexOfObject:viewController];
    self.viewLoadedMap[index] = @YES;
}

- (void)loadViewController:(UIViewController *)viewController {
    if ([viewController parentViewController] == self || !self.isViewLoaded || !viewController) {
        return;
    }
    
    [viewController willMoveToParentViewController:self];
    [self.view addSubview:viewController.view];
    [self addChildViewController:viewController];
    [viewController didMoveToParentViewController:self];
    
    viewController.view.frame = self.view.bounds;
    viewController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    if ([viewController.view isKindOfClass:[UIScrollView class]]) {
        self.scrollView = (UIScrollView *)viewController.view;
        [self setUpKVOForScrollView:self.scrollView];
        
        if (![self hasLoadedViewController:viewController]) {
            UIEdgeInsets insets = self.scrollView.contentInset;
            insets.top += kSGSegmentBarControllerBarHeight;
            self.scrollView.contentInset = insets;
            self.scrollView.scrollIndicatorInsets = insets;
            self.scrollView.contentOffset = CGPointMake(0, -insets.top);
            [self setHasLoadedViewController:viewController];
        }
    }
    
    [self.view bringSubviewToFront:self.segmentBar];
}

- (void)unloadViewController:(UIViewController *)viewController {
    [viewController willMoveToParentViewController:nil];
    [viewController.view removeFromSuperview];
    [viewController removeFromParentViewController];
    [viewController didMoveToParentViewController:nil];
    
    if (self.scrollView == viewController.view) {
        [self tearDownKVOForScrollView:self.scrollView];
        self.scrollView = nil;
    }
}

//- (void)transitionFromViewController:(UIViewController *)fromViewController toViewController:(UIViewController *)toViewController {
//    [self transitionFromViewController:fromViewController toViewController:toViewController duration:0.3 options:UIViewAnimationOptionCurveEaseOut animations:^{
//        
//    } completion:^(BOOL finished) {
//        
//    }];
//}

- (void)loadViewControllerTitles {
    [self.segmentBar.segmentedControl removeAllSegments];
    
    for (int i = 0; i < [self.viewControllers count]; i++) {
        NSString *title = [self titleForViewControllerAtIndex:i];
        [self.segmentBar.segmentedControl insertSegmentWithTitle:title atIndex:i animated:NO];
    }
    
    self.segmentBar.segmentedControl.selectedSegmentIndex = self.selectedIndex;
}

- (NSString *)titleForViewControllerAtIndex:(NSUInteger)index {
    UIViewController *viewController = self.viewControllers[index];
    NSString *title = nil;
    if ([viewController hasSegmentBarItem]){
        title = viewController.segmentBarItem.title;
    }
    if (!title) {
        title = viewController.title;
    }
    return title;
}

- (void)setSelectedViewController:(UIViewController *)selectedViewController {
    if (_selectedViewController == selectedViewController) {
        return;
    }
    
    NSUInteger selectedIndex = [self.viewControllers indexOfObject:selectedViewController];
    if (selectedIndex == NSNotFound) {
        [NSException raise:NSInvalidArgumentException format:@"Argument to %@ must be in viewControllers array",NSStringFromSelector(_cmd)];
    }
    
    UIViewController *oldViewController = _selectedViewController;
    _selectedViewController = selectedViewController;
    self.selectedIndex = selectedIndex;
    
    [self unloadViewController:oldViewController];
    [self loadViewController:selectedViewController];
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex {
    if (_selectedIndex == selectedIndex) {
        return;
    }
    
    if (selectedIndex >= [self.viewControllers count]) {
        [NSException raise:NSInvalidArgumentException format:@"Argument to %@ out of bounds of [%@ viewControllers]",NSStringFromSelector(_cmd),NSStringFromClass([self class])];
    }
    
    _selectedIndex = selectedIndex;
    [self setSelectedViewController:self.viewControllers[selectedIndex]];
    self.segmentBar.segmentedControl.selectedSegmentIndex = selectedIndex;
    self.titleView.detailLabel.text = [self titleForViewControllerAtIndex:selectedIndex];
    [self.titleView sizeToFit];
}

- (void)setViewControllers:(NSArray *)viewControllers {
    if (_viewControllers == viewControllers) {
        return;
    }
    
    for (UIViewController *controller in self.viewControllers) {
        controller.segmentBarController = nil;
    }
    
    [self unloadViewController:self.selectedViewController];
    self.viewLoadedMap = [NSMutableArray arrayWithCapacity:[viewControllers count]];
    _viewControllers = viewControllers;
    
    for (UIViewController *controller in viewControllers) {
        controller.segmentBarController = self;
        [self.viewLoadedMap addObject:@NO];
    }
    
    if (self.isViewLoaded) {
        [self loadViewControllerTitles];
    }
}

#pragma mark - Scroll handling

- (void)scrollView:(UIScrollView *)scrollView scrolledFromOffset:(CGFloat)oldOffset toOffset:(CGFloat)newOffset {
    CGFloat normalizedOffset = newOffset + scrollView.contentInset.top;
    
    BOOL offsetInBounds = normalizedOffset > 0 && normalizedOffset < scrollView.contentSize.height - scrollView.bounds.size.height;
    BOOL offsetNearTop = normalizedOffset < kSGSegmentBarControllerBarHeight;
    BOOL decelerating = scrollView.isDecelerating && !scrollView.isTracking;
    BOOL touching = scrollView.isTracking;
    
    CGFloat scrollDelta = newOffset - oldOffset;
    BOOL wantsToGrow = scrollDelta < 0;
    
    if (offsetInBounds || (normalizedOffset < 0 && wantsToGrow)) {
        if ((decelerating) || (touching && offsetInBounds && self.segmentBar.shrinkage < [self.segmentBar maxShrinkage]) || (offsetNearTop && offsetInBounds)) {
            self.segmentBar.shrinkage += scrollDelta;
        }
    }
    
    CGFloat fade = self.segmentBar.shrinkage / [self.segmentBar maxShrinkage];
    self.titleView.crossFade = fade;
}

- (void)hideOrShowSegmentBar {
    CGFloat normalizedOffset = self.scrollView.contentOffset.y + self.scrollView.contentInset.top;
    CGFloat hideThreshold = floorf([self.segmentBar maxShrinkage] / 2.0);
    
    if (self.segmentBar.shrinkage < hideThreshold || normalizedOffset < [self.segmentBar maxShrinkage]) {
        [self showSegmentBar];
    }
    else {
        [self hideSegmentBar];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self hideOrShowSegmentBar];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self hideOrShowSegmentBar];
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
    [self showSegmentBar];
    return YES;
}

#pragma mark - KVO

- (void)setUpKVOForScrollView:(UIScrollView *)scrollView {
    [scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:NULL];
}

- (void)tearDownKVOForScrollView:(UIScrollView *)scrollView {
    [scrollView removeObserver:self forKeyPath:@"contentOffset"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isKindOfClass:[UIScrollView class]]) {
        UIScrollView *scrollView = (UIScrollView *)object;
        
        if ([keyPath isEqualToString:@"contentOffset"]) {
            CGFloat oldOffset = [change[NSKeyValueChangeOldKey] CGPointValue].y;
            CGFloat newOffset = [change[NSKeyValueChangeNewKey] CGPointValue].y;
            [self scrollView:scrollView scrolledFromOffset:oldOffset toOffset:newOffset];
        }
    }
}

//#pragma mark - Controller transitions
//
//- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
//    NSUInteger presentedIndex = [self.viewControllers indexOfObject:presented];
//    if (presentedIndex == NSNotFound) {
//        return nil;
//    }
//    SGSegmentBarControllerTransitionAnimator *animator = [[SGSegmentBarControllerTransitionAnimator alloc] init];
//    animator.leftToRight = presentedIndex < self.selectedIndex;
//    return animator;
//}

@end