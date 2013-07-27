//
//  SGMasterViewController.m
//  NavigationBar
//
//  Created by Nick Lupinetti on 7/22/13.
//  Copyright (c) 2013 Heavy Bits, Inc. All rights reserved.
//

#import "SGMasterViewController.h"

#import "SGDetailViewController.h"
#import "UIImage+ImageEffects.h"
#import "SGViewTableViewController.h"
#import "GPUImage.h"
#import "SGBlurView.h"

typedef enum {
  SGBlurMethodToolbar,
  SGBlurMethodGPUImage,
  SGBlurMethodAccelerate,
  SGBlurMethodEvil,
  SGBlurMethodCoreImage
} SGBlurMethod;

@interface SGTableViewCell : UITableViewCell
@property (nonatomic, readonly) UIImageView *photoView;
@property (nonatomic, readonly) UIImageView *blurPanel;
@property (nonatomic, readonly) UIImage *blurredImage;
@property (nonatomic, readonly) GPUImageView *gpuImageView;
@property (nonatomic, readonly) GPUImageFilter *gpuFilter;
@property (nonatomic, readonly) GPUImagePicture *gpuSource;
@property (nonatomic) SGBlurMethod blurMethod;
@end

@implementation SGTableViewCell
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
    _photoView = [[UIImageView alloc] initWithFrame:self.bounds];
    _photoView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _photoView.contentMode = UIViewContentModeBottom;
    [self.contentView addSubview:_photoView];
    
    [_photoView addObserver:self forKeyPath:@"image" options:NSKeyValueObservingOptionNew context:NULL];
    
    self.blurMethod = SGBlurMethodEvil;
    
    CGRect blurFrame = self.bounds;
    blurFrame.size.height /= 4;
    blurFrame.origin.y = self.bounds.size.height - blurFrame.size.height;
    UIViewAutoresizing blurAutoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    if (self.blurMethod == SGBlurMethodToolbar) {
      UIView *toolbar = [[UIToolbar alloc] initWithFrame:blurFrame];
      toolbar.autoresizingMask = blurAutoresizingMask;
      toolbar.tintColor = [UIColor colorWithWhite:.0 alpha:01];
      [self.contentView addSubview:toolbar];
    }
    else if (self.blurMethod == SGBlurMethodEvil) {
      SGBlurView *blurView = [[SGBlurView alloc] initWithFrame:blurFrame];
      blurView.autoresizingMask = blurAutoresizingMask;
      [self.contentView addSubview:blurView];
    }
    else {
      _blurPanel = [[UIImageView alloc] initWithFrame:blurFrame];
      _blurPanel.contentMode = UIViewContentModeBottom;
      _blurPanel.autoresizingMask = blurAutoresizingMask;
      _blurPanel.clipsToBounds = YES;
      [self.contentView addSubview:_blurPanel];
    }
    
    if (self.blurMethod == SGBlurMethodGPUImage) {
      _gpuImageView = [[GPUImageView alloc] initWithFrame:_photoView.frame];
      _gpuImageView.autoresizingMask = _photoView.autoresizingMask;
      [self.contentView addSubview:_gpuImageView];
      
      GPUImageFastBlurFilter *blur = [[GPUImageFastBlurFilter alloc] init];
      blur.blurPasses = 1;
      blur.blurSize = 1.5;
      _gpuFilter = blur;
    }
  }
  return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  [self blurImage:change[NSKeyValueChangeNewKey]];
}

- (void)blurImage:(UIImage *)image {
  UIImage *blurImage = image;
  switch (self.blurMethod) {
    case SGBlurMethodAccelerate:
      blurImage = [self blurImageAccelerate:image];
      break;
    case SGBlurMethodGPUImage:
      blurImage = [self blurImageGPU:image];
      break;
    case SGBlurMethodCoreImage:
      blurImage = [self blurImageGPU:image];
      break;
    case SGBlurMethodToolbar:
    case SGBlurMethodEvil:
      blurImage = nil;
      break;
  }
  self.blurPanel.image = blurImage;
}

- (UIImage *)blurImageAccelerate:(UIImage *)image {
  return [image applyBlurWithRadius:6 tintColor:[UIColor colorWithWhite:0.3 alpha:0.3] saturationDeltaFactor:1.3 maskImage:nil];
}

- (UIImage *)blurImageGPU:(UIImage *)image {
  return [self.gpuFilter imageByFilteringImage:image];
  return image;
}

- (UIImage *)blurImageCoreImage:(UIImage *)image {
  return image;
}

@end

@interface SGMasterViewController () <UITableViewDataSource, UITableViewDelegate, UINavigationControllerDelegate, UIViewControllerAnimatedTransitioning>
@property (nonatomic, strong) NSMutableArray *objects;
@property (nonatomic, strong) UIView *header;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic) BOOL hasAppeared;
@property (nonatomic) UINavigationControllerOperation navigationOperation;
@property (nonatomic, strong) SGViewTableViewController *viewTable;
@property (nonatomic) BOOL manageBarHeight;
@end

@implementation SGMasterViewController

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  if (animated && self.manageBarHeight) {
    UINavigationBar *bar = self.navigationController.navigationBar;
    CGRect frame = bar.frame;
    frame.size.height += 44.0;
    
    [[self transitionCoordinator] animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
      bar.frame = frame;
      self.tableView.contentInset = UIEdgeInsetsMake(104, 0, 0, 0);
    } completion:nil];
  }
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  
  if (!self.hasAppeared && self.manageBarHeight) {
    self.hasAppeared = YES;
    UINavigationBar *bar = self.navigationController.navigationBar;
    CGRect frame = bar.frame;
    frame.size.height += 44;
    bar.frame = frame;
    
    NSArray *buttons = [self buttonsInNavBar:bar];
    for (UIView *button in buttons) {
      CGRect frame = button.frame;
      frame.origin.y -= 44;
      button.frame = frame;
    }
  }
  else if (!self.hasAppeared) {
    self.hasAppeared = YES;
    [SGBlurView prepareBlurViewsWithNavigationBar:self.navigationController.navigationBar];
  }
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  
  if (self.manageBarHeight && animated) {
    UINavigationBar *bar = self.navigationController.navigationBar;
    CGRect frame = bar.frame;
    frame.size.height -= 44.0;
    
    [[self transitionCoordinator] animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
      bar.frame = frame;
      self.tableView.contentInset = UIEdgeInsetsMake(44, 0, 0, 0);
    } completion:nil];
  }
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
  self.navigationItem.title = @"Photos";
  
  self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Views" style:UIBarButtonItemStylePlain target:self action:@selector(toggleViewTable)];
  
  self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
  self.tableView.delegate = self;
  self.tableView.dataSource = self;
  self.tableView.rowHeight = 320.0;
  self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  [self.tableView registerClass:[SGTableViewCell class] forCellReuseIdentifier:@"Cell"];
  [self.view addSubview:self.tableView];
  
  if (0) { // Capture, blur, and display manually
    self.header = [[UIImageView alloc] init];
  }
  else if (0) { // Toolbar
    UIToolbar *header = [[UIToolbar alloc] init];
    header.barTintColor = self.navigationController.navigationBar.barTintColor;
    self.header = header;
  }
  else if (0) { // Use personal nav bar
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    UINavigationBar *bar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 104)];
    bar.barTintColor = [UIColor orangeColor];
    bar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [bar pushNavigationItem:self.navigationItem animated:NO];
    [self.view addSubview:bar];
    
    self.tableView.contentInset = UIEdgeInsetsMake(104, 0, 0, 0);
  }
  else if (0) { // Resize nav controller's nav bar
    self.manageBarHeight = YES;
  }
  
  self.header.frame = CGRectMake(0, 64, self.view.bounds.size.width, 44);
  self.header.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
  [self.view addSubview:self.header];
  
  if (self.header) {
    self.tableView.contentInset = UIEdgeInsetsMake(self.header.frame.size.height, 0, 0, 0);
  }
  self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
  
//  self.navigationController.delegate = self;
  
  srand(time(NULL));
}

- (NSArray *)buttonsInNavBar:(UINavigationBar *)bar {
  NSMutableArray *buttons = [NSMutableArray array];
  for (UIView *subview in [bar subviews]) {
    if ([subview isKindOfClass:NSClassFromString(@"UINavigationButton")]) {
      [buttons addObject:subview];
    }
  }
  return buttons;
}

- (void)insertNewObject:(id)sender {
  if (!_objects) {
    _objects = [[NSMutableArray alloc] init];
  }
  
  NSInteger assetCount = 16;
  NSInteger index = [self.objects count];
  NSInteger assetIndex = rand()%assetCount + 1;
  NSString *assetName = [NSString stringWithFormat:@"%02d", assetIndex];
  [self.objects addObject:[UIImage imageNamed:assetName]];
  NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
  [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)toggleViewTable {
  self.navigationItem.leftBarButtonItem.enabled = NO;
  
  if (!self.viewTable) {
    self.viewTable = [[SGViewTableViewController alloc] init];
    self.viewTable.rootView = self.navigationController.view;
    
    [self.viewTable willMoveToParentViewController:self];
    [self addChildViewController:self.viewTable];
    [self.view addSubview:self.viewTable.view];
    CGRect frame = CGRectInset(self.view.bounds, 40.0, 100);
    frame.origin.y = self.view.bounds.size.height;
    self.viewTable.view.frame = frame;
    CGFloat extraMargin = 50.0;
    frame.origin.y -= frame.size.height - extraMargin;
    self.viewTable.tableView.contentInset = UIEdgeInsetsMake(0, 0, extraMargin, 0);
    self.viewTable.tableView.scrollIndicatorInsets = self.viewTable.tableView.contentInset;
    
    [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:0 animations:^{
      self.viewTable.view.frame = frame;
    } completion:^(BOOL finished) {
      [self.viewTable didMoveToParentViewController:self];
      self.navigationItem.leftBarButtonItem.enabled = YES;
    }];
  }
  else {
    [self.viewTable willMoveToParentViewController:nil];
    CGRect frame = self.viewTable.view.frame;
    frame.origin.y += frame.size.height;
    [UIView animateWithDuration:0.2 delay:0.0 usingSpringWithDamping:1.5 initialSpringVelocity:-20 options:0 animations:^{
      self.viewTable.view.frame = frame;
    } completion:^(BOOL finished) {
      [self.viewTable removeFromParentViewController];
      [self.viewTable.view removeFromSuperview];
      self.viewTable = nil;
      self.navigationItem.leftBarButtonItem.enabled = YES;
    }];
  }
}

#pragma mark - Navigation controller delegate

//- (id <UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC {
//  self.navigationOperation = operation;
//  return self;
//}

#pragma mark - UIViewController animated transitioning

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
  return 0.4;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
  UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
  UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
  CGFloat delta = toVC == self ? 44.0 : fromVC == self ? -44.0 : 0;
  
  CGRect frame = self.navigationController.navigationBar.frame;
  frame.size.height += delta;
  
  [[transitionContext containerView] addSubview:fromVC.view];
  [[transitionContext containerView] addSubview:toVC.view];
  
  CGRect fromStartFrame = [transitionContext initialFrameForViewController:fromVC];
  CGRect toStartFrame = fromStartFrame;
  toStartFrame.origin.x = toStartFrame.size.width;
  if (self.navigationOperation == UINavigationControllerOperationPop) toStartFrame.origin.x *= -1;
  
  CGRect toEndFrame = fromStartFrame;
  CGRect fromEndFrame = toStartFrame;
  fromEndFrame.origin.x *= -1;
  
  fromVC.view.frame = fromStartFrame;
  toVC.view.frame = toStartFrame;
  
  [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
    self.navigationController.navigationBar.frame = frame;
    
    fromVC.view.frame = fromEndFrame;
    toVC.view.frame = toEndFrame;
    
  } completion:^(BOOL finished) {
    [transitionContext completeTransition:YES];
  }];
}

#pragma mark - Table View

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return _objects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  SGTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
  cell.photoView.image = self.objects[indexPath.row];
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  SGDetailViewController *detailController = [[SGDetailViewController alloc] init];
  detailController.detailItem = self.objects[indexPath.row];
  [self.navigationController setNavigationBarHidden:NO animated:NO];
  [self.navigationController pushViewController:detailController animated:YES];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  if (![self.header respondsToSelector:@selector(setImage:)]) return;
  UIGraphicsBeginImageContextWithOptions(self.header.frame.size, NO, [[UIScreen mainScreen] scale]);
  CGRect drawRect = self.header.frame;// [self.view convertRect:self.header.frame toView:self.tableView];
  drawRect.size = self.tableView.frame.size;
  drawRect.origin.x *= -1;
  drawRect.origin.y *= -1;
  [self.tableView drawViewHierarchyInRect:drawRect];
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  UIColor *barColor = self.navigationController.navigationBar.barTintColor;
  CGFloat r,g,b;
  [barColor getRed:&r green:&g blue:&b alpha:NULL];
  UIColor *tintColor = [UIColor colorWithRed:r green:g blue:b alpha:0.6];
  image = [image applyBlurWithRadius:30 tintColor:tintColor saturationDeltaFactor:1.8 maskImage:nil];
  ((UIImageView*)self.header).image = image;
}

@end
