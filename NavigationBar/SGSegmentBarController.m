//
//  SGSegmentBarController.m
//  NavigationBar
//
//  Created by Nick Lupinetti on 8/8/13.
//  Copyright (c) 2013 Heavy Bits, Inc. All rights reserved.
//

#import "SGSegmentBarController.h"

@interface SGSegmentBarController ()

@end

@implementation SGSegmentBarController

@synthesize segmentBar = _segmentBar;

#pragma mark - Memory Management

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self addSegmentBar];
    
    [self loadViewController:self.selectedViewController];
}

- (void)addSegmentBar {
    CGRect frame = CGRectMake(0, 0, self.view.bounds.size.width, 44.0);
    
    if (YES) {
        frame.origin.y = 64.0;
    }
    
    self.segmentBar.frame = frame;
    [self.view addSubview:self.segmentBar];
}

#pragma mark - Lazy loading properties

- (SGSegmentBar *)segmentBar {
    if (!_segmentBar) {
        _segmentBar = [[SGSegmentBar alloc] init];
    }
    return _segmentBar;
}

#pragma mark - Child view controller management

- (void)loadViewController:(UIViewController *)viewController {
    if (self.isViewLoaded) {
        [viewController willMoveToParentViewController:self];
        [self.view addSubview:viewController.view];
        [self addChildViewController:viewController];
        [viewController didMoveToParentViewController:self];
    }
}

- (void)unloadViewController:(UIViewController *)viewController {
    [viewController willMoveToParentViewController:nil];
    [viewController.view removeFromSuperview];
    [viewController removeFromParentViewController];
    [viewController didMoveToParentViewController:nil];
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
}

- (void)setViewControllers:(NSArray *)viewControllers {
    if (_viewControllers == viewControllers) {
        return;
    }
    
    [self unloadViewController:self.selectedViewController];
    
    _viewControllers = viewControllers;
    
    if ([viewControllers count] > 0) {
        self.selectedIndex = 0;
    }
}

#pragma mark - KVO

- (void)setupKVOForViewController:(UIViewController *)controller {
    if ([controller.view isKindOfClass:[UIScrollView class]]) {
        [controller.view addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:NULL];
    }
}

- (void)tearDownKVOForViewController:(UIViewController *)controller {
    if ([controller.view isKindOfClass:[UIScrollView class]]) {
        [controller.view removeObserver:self forKeyPath:@"contentOffset"];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
}

@end
