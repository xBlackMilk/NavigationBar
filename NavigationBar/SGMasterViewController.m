//
//  SGMasterViewController.m
//  NavigationBar
//
//  Created by Nick Lupinetti on 7/22/13.
//  Copyright (c) 2013 Heavy Bits, Inc. All rights reserved.
//
// Blur Options:
// - Don't blur (design tradeoff)
// - Toolbar blur (design tradeoff)
// - Accelerate on some devices (memory)
// - GPU on all(?) devices (memory!)
// - CoreImage on devices (not working?)
// - Blur image on backend, truncate title
// - Blur image on backend, download two images
// -
//
//
// Nav bar Options:
// - Facebook-style hiding bar
// - Safari-style shrkinking bar
// - Reimplement Nav bar, should make translucency doable
//

#import "SGMasterViewController.h"

#import "SGDetailViewController.h"
#import "UIImage+ImageEffects.h"
#import "SGViewTableViewController.h"

typedef enum {
    SGBlurMethodToolbar,
    SGBlurMethodGPUImage,
    SGBlurMethodAccelerate,
    SGBlurMethodCoreImage
} SGBlurMethod;

@interface SGImageBlurOperation : NSOperation
@property (nonatomic, strong) UIImage *inputImage;
@property (nonatomic, copy) void (^renderCompletion)(UIImage *);
@property (nonatomic, readonly) BOOL isExecuting;
@property (nonatomic, readonly) BOOL isFinished;
@property (nonatomic) CGRect blurRegion;
@property (nonatomic) SGBlurMethod blurMethod;
@property (nonatomic) CGFloat blurRadius;
@end

static CIContext *kCoreImageContext = nil;

@implementation SGImageBlurOperation

- (id)init {
    self = [super init];
    if (self) {
        self.blurRadius = 5.0;
    }
    return self;
}

- (void)start {
    if ([self isCancelled]) {
        [self prepareExit];
        return;
    }
    
    [self willChangeValueForKey:@"isExecuting"];
    _isExecuting = YES;
    [self didChangeValueForKey:@"isExecuting"];
    
    UIImage *outputImage = nil;
    
    if (self.blurMethod == SGBlurMethodAccelerate) {
        outputImage = [self.inputImage applyBlurWithRadius:5 tintColor:[UIColor colorWithWhite:0.1 alpha:0.15] saturationDeltaFactor:1.4 maskImage:nil];
    }
    else if (self.blurMethod == SGBlurMethodCoreImage) {
        if (!kCoreImageContext) {
            EAGLContext *glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
            kCoreImageContext = [CIContext contextWithEAGLContext:glContext options:@{kCIContextWorkingColorSpace: [NSNull null]}];
        }
        
        CGFloat scale = self.inputImage.scale;
        // Core Image coordinate (0, 0) is the bottom left of the image instead of top left
        CGRect cropRect = self.blurRegion;
        cropRect.origin.y = (self.inputImage.size.height - cropRect.origin.y - cropRect.size.height) * scale;
        cropRect.origin.x *= scale;
        cropRect.size.width *= scale;
        cropRect.size.height *= scale;
        
        CIImage *original = [CIImage imageWithCGImage:self.inputImage.CGImage];
        
        CIFilter *edgeClamp = [CIFilter filterWithName:@"CIAffineClamp"];
        [edgeClamp setValue:original forKey:kCIInputImageKey];
        CIImage *clampOutput = [edgeClamp valueForKey:kCIOutputImageKey];
        
        CIFilter *blurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
        [blurFilter setValue:clampOutput forKey:kCIInputImageKey];
        [blurFilter setValue:@(self.blurRadius) forKey:kCIInputRadiusKey];
        CIImage *blurOutput = [blurFilter valueForKey:kCIOutputImageKey];

        CIFilter *darkenFilter = [CIFilter filterWithName:@"CIExposureAdjust"];
        [darkenFilter setValue:blurOutput forKey:kCIInputImageKey];
        [darkenFilter setValue:@-.3 forKey:kCIInputEVKey];
        CIImage *darkenOutput = [darkenFilter valueForKey:kCIOutputImageKey];
        
        CIFilter *cropFilter = [CIFilter filterWithName:@"CICrop"];
        [cropFilter setValue:darkenOutput forKey:kCIInputImageKey];
        [cropFilter setValue:[CIVector vectorWithCGRect:cropRect] forKey:@"inputRectangle"];
        CIImage *cropOutput = [cropFilter valueForKey:kCIOutputImageKey];
        
        CIFilter *compositor = [CIFilter filterWithName:@"CISourceOverCompositing"];
        [compositor setValue:cropOutput forKey:kCIInputImageKey];
        [compositor setValue:original forKey:kCIInputBackgroundImageKey];
        CIImage *composite = [compositor valueForKey:kCIOutputImageKey];
      
        
        CGImageRef cgImage = [kCoreImageContext createCGImage:composite fromRect:[original extent]];
        
        outputImage = [UIImage imageWithCGImage:cgImage scale:self.inputImage.scale orientation:self.inputImage.imageOrientation];
        CGImageRelease(cgImage);
    }
    else {
//        GPUImagePicture *gpuImage = [[GPUImagePicture alloc] initWithImage:self.inputImage];
//        // broken
//        GPUImageCropFilter *cropper = [[GPUImageCropFilter alloc] initWithCropRegion:self.blurRegion];
//        GPUImageFastBlurFilter *blur = [[GPUImageFastBlurFilter alloc] init];
//        blur.blurPasses = 2;
//        blur.blurSize = 1.5;
//        
//        [gpuImage addTarget:cropper];
//        [cropper addTarget:blur];
//        [gpuImage processImage];
//        
//        if ([self isCancelled]) {
//            [self prepareExit];
//            return;
//        }
//        
//        CGImageRef cgImage = [blur newCGImageFromCurrentlyProcessedOutput];
//        outputImage = [UIImage imageWithCGImage:cgImage scale:self.inputImage.scale orientation:self.inputImage.imageOrientation];
//        CGImageRelease(cgImage);
    }
    
    if ([self isCancelled]) {
        [self prepareExit];
        return;
    }
    
    self.renderCompletion(outputImage);
    [self prepareExit];
}

- (void)prepareExit {
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    _isExecuting = NO;
    _isFinished = YES;
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

@end

static NSOperationQueue *kBlurringOperationQueue;

@interface SGTableViewCell : UITableViewCell
@property (nonatomic, readonly) UIImageView *photoView;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, readonly) UIImage *blurredImage;
//@property (nonatomic, readonly) GPUImageView *gpuImageView;
//@property (nonatomic, readonly) GPUImageFilter *gpuFilter;
//@property (nonatomic, readonly) GPUImagePicture *gpuSource;
@property (nonatomic) SGBlurMethod blurMethod;
@property (nonatomic, strong) SGImageBlurOperation *blurOperation;
@end

@implementation SGTableViewCell
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        _photoView = [[UIImageView alloc] initWithFrame:self.bounds];
        _photoView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        _photoView.contentMode = UIViewContentModeBottom;
        [self.contentView addSubview:_photoView];
        
        //        [_photoView addObserver:self forKeyPath:@"image" options:NSKeyValueObservingOptionNew context:NULL];
        
        self.blurMethod = SGBlurMethodCoreImage;
        
        CGRect blurFrame = self.bounds;
        blurFrame.size.height /= 4;
        blurFrame.origin.y = self.bounds.size.height - blurFrame.size.height;
        UIViewAutoresizing blurAutoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        if (self.blurMethod == SGBlurMethodToolbar) {
            UINavigationBar *toolbar = [[UINavigationBar alloc] initWithFrame:blurFrame];
            toolbar.autoresizingMask = blurAutoresizingMask;
            toolbar.barTintColor = [UIColor colorWithWhite:0.9 alpha:1.0];
            [self.contentView addSubview:toolbar];
        }
        else {
            //            _blurPanel = [[UIImageView alloc] initWithFrame:blurFrame];
            //            _blurPanel.contentMode = UIViewContentModeBottom;
            //            _blurPanel.autoresizingMask = blurAutoresizingMask;
            //            _blurPanel.clipsToBounds = YES;
            //            [self.contentView addSubview:_blurPanel];
            
            kBlurringOperationQueue = [[NSOperationQueue alloc] init];
            kBlurringOperationQueue.maxConcurrentOperationCount = 1;
            [kBlurringOperationQueue setName:@"com.snapguide.blur"];
        }
        
//        if (self.blurMethod == SGBlurMethodGPUImage) {
//            GPUImageFastBlurFilter *blur = [[GPUImageFastBlurFilter alloc] init];
//            blur.blurPasses = 2;
//            blur.blurSize = 1.5;
//            _gpuFilter = blur;
//            
//            UIView *overlay = [[UIView alloc] initWithFrame:blurFrame];
//            overlay.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.15];
//            overlay.autoresizingMask = blurAutoresizingMask;
//            [self.contentView addSubview:overlay];
//        }
    }
    return self;
}

- (void)setImage:(UIImage *)image {
    if (image == _image) return;
    self.photoView.image = nil;
    [self blurImage:image];
    
}

//- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
//    [self blurImage:change[NSKeyValueChangeNewKey]];
//}

- (void)blurImage:(UIImage *)image {
    switch (self.blurMethod) {
        case SGBlurMethodAccelerate:
        case SGBlurMethodCoreImage:
        case SGBlurMethodGPUImage:
            [self blurImageInBackground:image];
            break;
        case SGBlurMethodToolbar:
            break;
    }
}

- (UIImage *)blurImageAccelerate:(UIImage *)image {
    return [image applyBlurWithRadius:5 tintColor:[UIColor colorWithWhite:0.1 alpha:0.15] saturationDeltaFactor:1.4 maskImage:nil];
}

- (UIImage *)blurImageInBackground:(UIImage *)image {
    [self.blurOperation cancel];
    
    __weak SGTableViewCell *weakSelf = self;
    self.blurOperation = [[SGImageBlurOperation alloc] init];
    self.blurOperation.blurMethod = self.blurMethod;
    self.blurOperation.inputImage = image;
    self.blurOperation.blurRegion = CGRectMake(0, image.size.height * 0.75, image.size.width, image.size.height * 0.25);
    self.blurOperation.renderCompletion = ^(UIImage *outputImage) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            weakSelf.photoView.image = outputImage;
        }];
    };
    [kBlurringOperationQueue addOperation:self.blurOperation];
    return nil;

    return image;
}

- (UIImage *)blurImageCoreImage:(UIImage *)image {
    return image;
}

@end


@interface SGCrossfadingLabelView : UIView
@property (nonatomic, readonly) UILabel *titleLabel;
@property (nonatomic, readonly) UILabel *detailLabel;
@property (nonatomic) CGFloat crossFade;
@end

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

@interface SGShrinkingSegmentedControlPanel : UIView
@property (nonatomic, readonly) UISegmentedControl *segmentedControl;
@property (nonatomic, readonly) CGFloat maxShrinkage;
@property (nonatomic) CGFloat shrinkage;
- (void)setShrinkage:(CGFloat)shrinkage animated:(BOOL)animated;
@end

@interface SGShrinkingSegmentedControlPanel ()
@property (nonatomic, getter = isAdjustingShrinkage) BOOL adjustingShrinkage;
@property (nonatomic) CGRect fullFrame;
@end

@implementation SGShrinkingSegmentedControlPanel

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _segmentedControl = [[UISegmentedControl alloc] initWithItems:@[]];
        [self addSubview:self.segmentedControl];
        [self updateSegmentedControlFrame];
        self.clipsToBounds = YES;
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
    self.segmentedControl.userInteractionEnabled = shrinkage == 0;
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
    
    self.adjustingShrinkage = NO;
}

@end

typedef enum : NSInteger {
    SGHeaderStyleHide,
    SGHeaderStyleShrink
} SGHeaderStyle;

@interface SGMasterViewController () <UITableViewDataSource, UITableViewDelegate>// UINavigationControllerDelegate, UIViewControllerAnimatedTransitioning>
@property (nonatomic, strong) NSMutableArray *objects;
@property (nonatomic, strong) UIView *header;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic) BOOL hasAppeared;
@property (nonatomic) UINavigationControllerOperation navigationOperation;
@property (nonatomic, strong) SGViewTableViewController *viewTable;
@property (nonatomic) BOOL manageBarHeight;
@property (nonatomic, strong) SGCrossfadingLabelView *titleView;
@property (nonatomic) CGPoint lastTableContentOffset;
@property (nonatomic) SGHeaderStyle headerStyle;
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
    self.navigationItem.title = @"Explore";
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Views" style:UIBarButtonItemStylePlain target:self action:@selector(toggleViewTable)];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = 320.0;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.tableView registerClass:[SGTableViewCell class] forCellReuseIdentifier:@"Cell"];
    [self.view addSubview:self.tableView];
    
    [self loadImages];
    
    if (0) { // Capture, blur, and display manually
        self.header = [[UIImageView alloc] init];
    }
    else if (1) { // Toolbar
        self.headerStyle = SGHeaderStyleShrink;
        
        if (self.headerStyle == SGHeaderStyleHide) {
            self.titleView = [[SGCrossfadingLabelView alloc] init];
            self.titleView.titleLabel.text = @"Explore";
            self.titleView.detailLabel.text = @"Popular";
            self.titleView.titleLabel.textColor = self.titleView.detailLabel.textColor = [UIColor whiteColor];
            [self.titleView sizeToFit];
            self.navigationItem.titleView = self.titleView;
            
            UINavigationBar *header = [[UINavigationBar alloc] init];
            //          [header setBackgroundImage:[UIImage imageNamed:@"orangepix"] forBarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
            [header setBackgroundImage:[UIImage imageNamed:@"orangepix"] forBarMetrics:UIBarMetricsDefault]; // iOS 6 friendly
                                                                                                             //          [header setShadowImage:[UIImage imageNamed:@"clearpix"]];
            UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"Topics",@"Popular",@"Recent"]];
            segmentedControl.backgroundColor = [UIColor colorWithRed:210.0/255.0 green:75.0/255.0 blue:10.0/255.0 alpha:1.0];
            segmentedControl.tintColor = [UIColor colorWithRed:246.0/255.0 green:241.0/255.0 blue:234.0/255.0];//[UIColor colorWithRed:199.0/255.0 green:66.0/255.0 blue:25.0/255.0 alpha:1.0];
            segmentedControl.selectedSegmentIndex = 1;
            [segmentedControl addTarget:self action:@selector(segmentSelected:) forControlEvents:UIControlEventValueChanged];
            CGRect frame = segmentedControl.frame;
            frame.size.width = self.view.bounds.size.width - 20.0;
            segmentedControl.frame = frame;
            header.items = @[[[UINavigationItem alloc] init]];
            [header.items[0] setTitleView:segmentedControl];
            [header addSubview:segmentedControl];
            self.header = header;
        }
        else if (self.headerStyle == SGHeaderStyleShrink) {
            SGShrinkingSegmentedControlPanel *header = [[SGShrinkingSegmentedControlPanel alloc] init];
            header.backgroundColor = self.navigationController.navigationBar.barTintColor;
            [header.segmentedControl insertSegmentWithTitle:@"Topics" atIndex:0 animated:NO];
            [header.segmentedControl insertSegmentWithTitle:@"Popular" atIndex:1 animated:NO];
            [header.segmentedControl insertSegmentWithTitle:@"Recent" atIndex:2 animated:NO];
            header.segmentedControl.backgroundColor = [UIColor colorWithRed:181.0/255.0 green:60.0/255.0 blue:0 alpha:1];
            header.segmentedControl.selectedSegmentIndex = 1;
            [header.segmentedControl addTarget:self action:@selector(segmentSelected:) forControlEvents:UIControlEventValueChanged];
            header.tintColor = [UIColor colorWithRed:246.0/255.0 green:241.0/255.0 blue:234.0/255.0 alpha:1];
            self.header = header;
            
            self.titleView = [[SGCrossfadingLabelView alloc] init];
            self.titleView.titleLabel.text = self.navigationItem.title;
            self.titleView.detailLabel.text = [header.segmentedControl titleForSegmentAtIndex:header.segmentedControl.selectedSegmentIndex];
            self.titleView.titleLabel.textColor = self.titleView.detailLabel.textColor = [UIColor whiteColor];
            [self.titleView sizeToFit];
            self.navigationItem.titleView = self.titleView;
            
            [self.titleView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showHeader)]];
        }
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

- (void)segmentSelected:(UISegmentedControl *)sender {
    NSString *newTitle = [sender titleForSegmentAtIndex:sender.selectedSegmentIndex];
    self.titleView.detailLabel.text = newTitle;
    [self.titleView sizeToFit];
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

- (NSInteger)assetCount {
    return 16;
}

- (UIImage *)assetWithIndex:(NSInteger)index {
    NSString *assetName = [NSString stringWithFormat:@"%02d", index];
    return [UIImage imageNamed:assetName];
}

- (void)loadImages {
    _objects = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < 30; i++) {
        NSInteger assetIndex = fmodf(i, [self assetCount]) + 1;
        [self.objects addObject:[self assetWithIndex:assetIndex]];
    }
}

- (void)insertNewObject:(id)sender {
    if (!_objects) {
        _objects = [[NSMutableArray alloc] init];
    }
    
    NSInteger assetIndex = rand() % [self assetCount] + 1;
    [self.objects addObject:[self assetWithIndex:assetIndex]];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self.objects count] - 1 inSection:0];
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
    cell.image = self.objects[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    SGDetailViewController *detailController = [[SGDetailViewController alloc] init];
    detailController.detailItem = self.objects[indexPath.row];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    [self.navigationController pushViewController:detailController animated:YES];
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
    if (self.headerStyle == SGHeaderStyleHide) {
        CGRect frame = self.header.frame;
        frame.origin.y = CGRectGetMaxY(self.navigationController.navigationBar.frame);
        self.header.frame = frame;
    }
    else if (self.headerStyle == SGHeaderStyleShrink) {
        SGShrinkingSegmentedControlPanel *header = (SGShrinkingSegmentedControlPanel *)self.header;
        [header setShrinkage:0 animated:YES];
    }
    return YES;
}

- (void)showHeader {
    if (self.tableView.isDecelerating && !self.tableView.isTracking) {
        self.tableView.contentOffset = self.tableView.contentOffset;
        SGShrinkingSegmentedControlPanel *header = (SGShrinkingSegmentedControlPanel *)self.header;
        [header setShrinkage:0.0 animated:YES];
        [self.titleView setCrossFade:0.0 animated:YES];
    }
}

- (void)hideOrShowHeader {
    SGShrinkingSegmentedControlPanel *header = (SGShrinkingSegmentedControlPanel *)self.header;
    CGFloat normalizedOffset = self.tableView.contentOffset.y + self.tableView.contentInset.top;
    CGFloat hideThreshold = floorf([header maxShrinkage] / 2.0);
    
    if (header.shrinkage < hideThreshold || normalizedOffset < [header maxShrinkage]) {
        [header setShrinkage:0 animated:YES];
        [self.titleView setCrossFade:0.0 animated:YES];
    }
    else {
        [header setShrinkage:[header maxShrinkage] animated:YES];
        [self.titleView setCrossFade:1.0 animated:YES];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate && self.headerStyle == SGHeaderStyleShrink) {
        [self hideOrShowHeader];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (self.headerStyle == SGHeaderStyleShrink) {
        [self hideOrShowHeader];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.headerStyle == SGHeaderStyleHide) {
        CGFloat normalizedOffset = scrollView.contentOffset.y + scrollView.contentInset.top;
        CGFloat fade = normalizedOffset / self.header.frame.size.height;
        self.titleView.crossFade = fade;
        
        if (scrollView.isDragging || scrollView.isDecelerating) {
            CGFloat visibleHeight = CGRectGetMaxY(self.navigationController.navigationBar.frame);
            CGFloat hiddenHeight = visibleHeight - self.header.frame.size.height;
            BOOL headerVisible = self.header.frame.origin.y > hiddenHeight;
            BOOL offsetInBounds = normalizedOffset > 0 && normalizedOffset < scrollView.contentSize.height - scrollView.bounds.size.height;
            BOOL offsetNearTop = normalizedOffset < self.header.frame.size.height;
            BOOL decelerating = scrollView.isDecelerating && !scrollView.isTracking;
            
            if (offsetNearTop || (offsetInBounds && (headerVisible || decelerating))) {
                CGRect frame = self.header.frame;
                CGFloat newHeaderY = frame.origin.y;
                
                if (offsetNearTop) {
                    newHeaderY = fmaxf(visibleHeight - normalizedOffset, newHeaderY);
                }
                else {
                    CGFloat distance = self.lastTableContentOffset.y - scrollView.contentOffset.y;
                    newHeaderY = frame.origin.y + distance;
                }
                
                newHeaderY = fmaxf(hiddenHeight, fminf(visibleHeight, newHeaderY));
                frame.origin.y = newHeaderY;
                self.header.frame = frame;
                self.titleView.crossFade = (visibleHeight - newHeaderY) / (visibleHeight - hiddenHeight);
            }
        }
    }
    else if (self.headerStyle == SGHeaderStyleShrink) {
        SGShrinkingSegmentedControlPanel *header = (SGShrinkingSegmentedControlPanel *)self.header;
        CGFloat normalizedOffset = scrollView.contentOffset.y + scrollView.contentInset.top;
        
        BOOL offsetInBounds = normalizedOffset > 0 && normalizedOffset < scrollView.contentSize.height - scrollView.bounds.size.height;
        BOOL offsetNearTop = normalizedOffset < 44.0;
        BOOL decelerating = scrollView.isDecelerating && !scrollView.isTracking;
        BOOL touching = scrollView.isTracking;
        
        CGFloat scrollDelta = scrollView.contentOffset.y - self.lastTableContentOffset.y;
        BOOL wantsToGrow = scrollDelta < 0;
        
        if (offsetInBounds || (normalizedOffset < 0 && wantsToGrow)) {
            if ((decelerating) || (touching && offsetInBounds && header.shrinkage < [header maxShrinkage]) || (offsetNearTop && offsetInBounds)) {
                header.shrinkage += scrollDelta;
            }
        }
        
        CGFloat fade = header.shrinkage / [header maxShrinkage];
        self.titleView.crossFade = fade;
    }
    
    self.lastTableContentOffset = scrollView.contentOffset;
    
    if (![self.header respondsToSelector:@selector(setImage:)]) return;
    
    UIGraphicsBeginImageContextWithOptions(self.header.frame.size, NO, [[UIScreen mainScreen] scale]);
    CGRect drawRect = self.header.frame;// [self.view convertRect:self.header.frame toView:self.tableView];
    drawRect.size = self.tableView.frame.size;
    drawRect.origin.x *= -1;
    drawRect.origin.y *= -1;
    [self.tableView drawViewHierarchyInRect:drawRect afterScreenUpdates:NO];
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
