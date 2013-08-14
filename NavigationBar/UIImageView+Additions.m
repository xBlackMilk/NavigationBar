//
//  UIImageView+Additions.m
//  Bamboo
//
//  Created by Nick Lupinetti on 4/17/13.
//
//

// Define this to log image requests
//#define LOG_IMAGE_REQUESTS

#import "UIImageView+Additions.h"

#import <objc/runtime.h>
//#import <SDWebImage/SDImageCache.h>
#import <QuartzCore/QuartzCore.h>

//#import "AppCtx.h"
//#import "SGDownloadManager.h"
//#import "SGDownloadImage.h"
#import "UIImage+ImageEffects.h"

static NSOperationQueue *_maskingQueue;
static NSOperationQueue *_blurringQueue;
static char downloadKey;
static char maskingKey;
static char blurringKey;

#pragma mark - Masking operation -

@interface SGMaskingOperation : NSOperation
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) UIColor *backgroundColor;
@property (nonatomic, strong) UIBezierPath *mask;
@property (nonatomic, copy) void (^postRenderMainThreadBlock)(UIImage *);
@property (nonatomic, readonly) BOOL isExecuting;
@property (nonatomic, readonly) BOOL isFinished;
@end

@implementation SGMaskingOperation

- (void)start {
  [self willChangeValueForKey:@"isExecuting"];
  _isExecuting = YES;
  [self didChangeValueForKey:@"isExecuting"];
  
  CGFloat scale = [[UIScreen mainScreen] scale];
  
  CGSize imageSize = self.image.size;
  imageSize.width *= scale;
  imageSize.height *= scale;
  CGRect drawRect = CGRectMake(0, 0, imageSize.width, imageSize.height);
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  CGContextRef context = CGBitmapContextCreate(NULL, imageSize.width, imageSize.height, 8, 0, colorSpace, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
  CGColorSpaceRelease(colorSpace);
  CGContextSetAllowsAntialiasing(context, true);
  CGContextSetShouldAntialias(context, true);
  CGContextSetFillColorWithColor(context, self.backgroundColor.CGColor);
  CGContextFillRect(context, drawRect);
  
  // translate UI coordinates into CG coordinates
  UIBezierPath *cgMask = [self.mask copy];
  [cgMask applyTransform:CGAffineTransformMakeScale(scale, -scale)];
  [cgMask applyTransform:CGAffineTransformMakeTranslation(0, imageSize.height)];
  CGContextAddPath(context, [cgMask CGPath]);
  CGContextClip(context);
  CGContextDrawImage(context, drawRect, [self.image CGImage]);
  
  if ([self isCancelled]) {
    CGContextRelease(context);
    [self prepareExit];
    return;
  }
  
  CGImageRef clippedImage = CGBitmapContextCreateImage(context);
  CGContextRelease(context);
  UIImage *maskedImage = [UIImage imageWithCGImage:clippedImage scale:scale orientation:UIImageOrientationUp];
  CGImageRelease(clippedImage);
  
  if ([self isCancelled]) {
    [self prepareExit];
    return;
  }
  
  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    if ([self isCancelled]) {
      [self prepareExit];
      return;
    }
    
    if (self.postRenderMainThreadBlock) {
      self.postRenderMainThreadBlock(maskedImage);
    }
  }];
  
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

#pragma mark - Blurring operation -

typedef enum {
  SGBlurMethodAccelerate,
  SGBlurMethodCoreImage
} SGBlurMethod;

@interface SGBlurringOperation : NSOperation
@property (nonatomic, strong) UIImage *inputImage;
@property (nonatomic, copy) void (^renderCompletion)(UIImage *blurredImage);
@property (nonatomic, readonly) BOOL isExecuting;
@property (nonatomic, readonly) BOOL isFinished;
@property (nonatomic) CGRect blurRegion;
@property (nonatomic) CGFloat blurRadius;
@property (nonatomic) CGFloat blurExposureAdjustment;
@property (nonatomic) SGBlurMethod blurMethod;
@end

static CIContext *kCoreImageContext = nil;

@implementation SGBlurringOperation

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
    //TODO: feed this method a maskImage based on blurRegion, or modify method to accept a CGRect
    outputImage = [self.inputImage applyBlurWithRadius:self.blurRadius tintColor:[UIColor colorWithWhite:0.1 alpha:0.15] saturationDeltaFactor:1.4 maskImage:nil];
  }
  else if (self.blurMethod == SGBlurMethodCoreImage) {
    if (!kCoreImageContext) {
      EAGLContext *glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
      kCoreImageContext = [CIContext contextWithEAGLContext:glContext options:@{kCIContextWorkingColorSpace: [NSNull null]}];
    }
    
    CIImage *original = [CIImage imageWithCGImage:self.inputImage.CGImage];
    
    CIFilter *edgeClamp = [CIFilter filterWithName:@"CIAffineClamp"];
    [edgeClamp setValue:original forKey:kCIInputImageKey];
    CIImage *clampOutput = [edgeClamp valueForKey:kCIOutputImageKey];
    
    CIFilter *blurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [blurFilter setValue:clampOutput forKey:kCIInputImageKey];
    [blurFilter setValue:@(self.blurRadius) forKey:kCIInputRadiusKey];
    CIImage *blurOutput = [blurFilter valueForKey:kCIOutputImageKey];
    
    CIImage *cropInput = blurOutput;
    CIImage *finalImageNode = blurOutput;
    
    if (self.blurExposureAdjustment != 0) {
      CIFilter *darkenFilter = [CIFilter filterWithName:@"CIExposureAdjust"];
      [darkenFilter setValue:blurOutput forKey:kCIInputImageKey];
      [darkenFilter setValue:@(self.blurExposureAdjustment) forKey:kCIInputEVKey];
      cropInput = [darkenFilter valueForKey:kCIOutputImageKey];
    }
    
    if (!CGSizeEqualToSize(self.inputImage.size, self.blurRegion.size) || !CGPointEqualToPoint(CGPointZero, self.blurRegion.origin)) {
      // Translate UIKit coordinates to Core Image coordinates
      CGFloat scale = self.inputImage.scale;
      CGRect cropRect = self.blurRegion;
      cropRect.origin.y = (self.inputImage.size.height - cropRect.origin.y - cropRect.size.height) * scale;
      cropRect.origin.x *= scale;
      cropRect.size.width *= scale;
      cropRect.size.height *= scale;
      
      CIFilter *cropFilter = [CIFilter filterWithName:@"CICrop"];
      [cropFilter setValue:cropInput forKey:kCIInputImageKey];;
      [cropFilter setValue:[CIVector vectorWithCGRect:cropRect] forKey:@"inputRectangle"];
      CIImage *cropOutput = [cropFilter valueForKey:kCIOutputImageKey];
      
      CIFilter *compositor = [CIFilter filterWithName:@"CISourceOverCompositing"];
      [compositor setValue:cropOutput forKey:kCIInputImageKey];
      [compositor setValue:original forKey:kCIInputBackgroundImageKey];
      finalImageNode = [compositor valueForKey:kCIOutputImageKey];
    }
    
    CGImageRef outputCGImage = [kCoreImageContext createCGImage:finalImageNode fromRect:[original extent]];
    
    outputImage = [UIImage imageWithCGImage:outputCGImage scale:self.inputImage.scale orientation:self.inputImage.imageOrientation];
    CGImageRelease(outputCGImage);
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

#pragma mark - UIImageView category -

@interface UIImageView (AssociatedObjects)
@property (nonatomic, strong) SGMaskingOperation *maskingOperation;
@property (nonatomic, strong) SGBlurringOperation *blurringOperation;
//@property (nonatomic, strong) SGDownloadImage *imageDownload;
@end

@implementation UIImageView (Additions)

+ (NSOperationQueue *)blurringQueue {
  if (!_blurringQueue) {
    _blurringQueue = [[NSOperationQueue alloc] init];
    [_blurringQueue setName:@"com.snapguide.uiimageview.blurring"];
    _blurringQueue.maxConcurrentOperationCount = 1;
  }
  return _blurringQueue;
}

+ (NSOperationQueue *)maskingQueue {
  if (!_maskingQueue) {
    _maskingQueue = [[NSOperationQueue alloc] init];
    [_maskingQueue setName:@"com.snapguide.uiimageview.masking"];
    _maskingQueue.maxConcurrentOperationCount = 1;
  }
  return _maskingQueue;
}

+ (void)cancelAll {
//  [[[AppCtx shared] downloadManager] cancelAll];
  [[[self class] maskingQueue] cancelAllOperations];
  [[[self class] blurringQueue] cancelAllOperations];
}

- (void)cancelImageLoad {
//  [self cancelDownload];
  [self cancelMasking];
  [self cancelBlurring];
}

//- (void)cancelDownload {
//  SGDownloadImage *download = self.imageDownload;
//  if (download) {
//    [download cancel];
//    self.imageDownload = nil;
//  }
//}

- (void)cancelMasking {
  SGMaskingOperation *maskingOperation = self.maskingOperation;
  if (maskingOperation) {
    [maskingOperation cancel];
    self.maskingOperation = nil;
  }
}

- (void)cancelBlurring {
  SGBlurringOperation *blurringOperation = self.blurringOperation;
  if (blurringOperation) {
    [blurringOperation cancel];
    self.blurringOperation = nil;
  }
}

- (SGMaskingOperation *)maskingOperation {
  return objc_getAssociatedObject(self, &maskingKey);
}

- (void)setMaskingOperation:(SGMaskingOperation *)maskingOperation {
  objc_setAssociatedObject(self, &maskingKey, maskingOperation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (SGBlurringOperation *)blurringOperation {
  return objc_getAssociatedObject(self, &blurringKey);
}

- (void)setBlurringOperation:(SGBlurringOperation *)blurringOperation {
  objc_setAssociatedObject(self, &blurringKey, blurringOperation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

//- (SGDownloadImage *)imageDownload {
//  return objc_getAssociatedObject(self, &downloadKey);
//}
//
//- (void)setImageDownload:(SGDownloadImage *)imageDownload {
//  objc_setAssociatedObject(self, &downloadKey, imageDownload, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
//}

#pragma mark Masking

- (void)setImage:(UIImage *)image maskToPath:(UIBezierPath *)path {
  [self setImage:image maskToPath:path asynchronous:YES fadeDuration:0.1];
}

- (void)setImage:(UIImage *)image maskToPath:(UIBezierPath *)path asynchronous:(BOOL)async fadeDuration:(NSTimeInterval)duration {
  [self setImage:image maskToPath:path asynchronous:async fadeDuration:duration completion:nil];
}

- (void)setImage:(UIImage *)image maskToPath:(UIBezierPath *)path asynchronous:(BOOL)async fadeDuration:(NSTimeInterval)duration completion:(void (^)(UIImage *))completion {
  [self cancelMasking];
  
  if (!image || !path) {
    [self setImage:image fadeDuration:duration completion:completion];
    return;
  }
  
  SGMaskingOperation *maskingOperation = [[SGMaskingOperation alloc] init];
  self.maskingOperation = maskingOperation;
  maskingOperation.mask = path;
  maskingOperation.image = image;
  maskingOperation.backgroundColor = [UIColor clearColor];
  __weak UIImageView *weakSelf = self;
  maskingOperation.postRenderMainThreadBlock = ^(UIImage *maskedImage) {
    UIImageView *strongSelf = weakSelf;
    if (!strongSelf) return;
    [strongSelf setImage:maskedImage fadeDuration:duration completion:completion];
    strongSelf.maskingOperation = nil;
  };
  
  NSOperationQueue *queue = async ? [[self class] maskingQueue] : [NSOperationQueue mainQueue];
  [queue addOperation:maskingOperation];
}

#pragma mark Blur

- (void)setImage:(UIImage *)image blurRadius:(CGFloat)blurRadius {
  [self setImage:image blurRegion:CGRectMake(0, 0, image.size.width, image.size.height) blurRadius:blurRadius];
}

- (void)setImage:(UIImage *)image blurRegion:(CGRect)blurRegion blurRadius:(CGFloat)blurRadius {
  [self setImage:image blurRegion:blurRegion blurRadius:blurRadius fadeDuration:0.1];
}

- (void)setImage:(UIImage *)image blurRegion:(CGRect)blurRegion blurRadius:(CGFloat)blurRadius fadeDuration:(NSTimeInterval)fadeDuration {
  [self setImage:image blurRegion:blurRegion blurRadius:blurRadius adjustBlurExposure:0.0 fadeDuration:fadeDuration];
}

- (void)setImage:(UIImage *)image blurRegion:(CGRect)blurRegion blurRadius:(CGFloat)blurRadius adjustBlurExposure:(CGFloat)exposure fadeDuration:(NSTimeInterval)fadeDuration {
  [self setImage:image blurRegion:blurRegion blurRadius:blurRadius adjustBlurExposure:exposure cornerRadius:0.0 corners:0 fadeDuration:fadeDuration];
}

- (void)setImage:(UIImage *)image blurRegion:(CGRect)blurRegion blurRadius:(CGFloat)blurRadius adjustBlurExposure:(CGFloat)exposure cornerRadius:(CGFloat)cornerRadius corners:(UIRectCorner)corners fadeDuration:(NSTimeInterval)fadeDuration {
  [self setImage:image blurRegion:blurRegion blurRadius:blurRadius adjustBlurExposure:exposure cornerRadius:cornerRadius corners:corners fadeDuration:fadeDuration completion:nil];
}

- (UIBezierPath *)maskPathForSize:(CGSize)size corners:(UIRectCorner)corners cornerRadius:(CGFloat)cornerRadius {
  CGRect pathRect = {CGPointZero, size};
  CGSize cornerSize = CGSizeMake(cornerRadius, cornerRadius);
  return [UIBezierPath bezierPathWithRoundedRect:pathRect byRoundingCorners:corners cornerRadii:cornerSize];
}

- (void)setImage:(UIImage *)image roundingCorners:(UIRectCorner)corners cornerRadius:(CGFloat)cornerRadius fadeDuration:(NSTimeInterval)fadeDuration completion:(void (^)(UIImage *))completion {
  if (cornerRadius <= 0 || corners == 0) {
    [self setImage:image fadeDuration:fadeDuration completion:completion];
    return;
  }
  
  UIBezierPath *maskPath = [self maskPathForSize:image.size corners:corners cornerRadius:cornerRadius];
  [self setImage:image maskToPath:maskPath asynchronous:YES fadeDuration:fadeDuration completion:completion];
}

- (void)setImage:(UIImage *)image blurRegion:(CGRect)blurRegion blurRadius:(CGFloat)blurRadius adjustBlurExposure:(CGFloat)exposure cornerRadius:(CGFloat)cornerRadius corners:(UIRectCorner)corners fadeDuration:(NSTimeInterval)fadeDuration completion:(void (^)(UIImage *))completion {
  [self cancelBlurring];
  [self cancelMasking];
  
  
  if (!image || blurRegion.size.height <= 0 || blurRegion.size.width <= 0 || blurRadius <= 0) {
    [self setImage:image roundingCorners:corners cornerRadius:cornerRadius fadeDuration:fadeDuration completion:completion];
    return;
  }
  
  SGBlurringOperation *operation = [[SGBlurringOperation alloc] init];
  self.blurringOperation = operation;
  operation.inputImage = image;
  operation.blurRadius = blurRadius;
  operation.blurRegion = blurRegion;
  operation.blurExposureAdjustment = exposure;
  operation.blurMethod = SGBlurMethodCoreImage;
  __weak UIImageView *weakSelf = self;
  operation.renderCompletion = ^(UIImage *blurredImage) {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
      UIImageView *strongSelf = weakSelf;
      if (!strongSelf) return;
      [strongSelf setImage:blurredImage roundingCorners:corners cornerRadius:cornerRadius fadeDuration:fadeDuration completion:completion];
      strongSelf.blurringOperation = nil;
    }];
  };
  
  [[[self class] blurringQueue] addOperation:operation];
}

#pragma mark Loading with UUID

//- (void)setImageWithUUID:(NSString *)identifier type:(SGServerImageType)type {
//  [self setImageWithUUID:identifier type:type cornerRadius:0];
//}
//
//- (void)setCircleImageWithUUID:(NSString *)identifier type:(SGServerImageType)type {
//  CGSize imageSize = [self sizeForImageType:type];
//  ZAssert(imageSize.width == imageSize.height, @"Must have equal dimensions to ensure a circle image");
//  CGFloat cornerRadius = imageSize.width / 2.0;
//  [self setImageWithUUID:identifier type:type cornerRadius:cornerRadius];
//}
//
//- (void)setImageWithUUID:(NSString *)identifier type:(SGServerImageType)type cornerRadius:(CGFloat)cornerRadius {
//  [self setImageWithUUID:identifier type:type cornerRadius:cornerRadius fadeDuration:0];
//}
//
//- (void)setImageWithUUID:(NSString *)identifier type:(SGServerImageType)type cornerRadius:(CGFloat)cornerRadius fadeDuration:(NSTimeInterval)fadeDuration {
//  [self setImageWithUUID:identifier type:type cornerRadius:cornerRadius fadeDuration:fadeDuration completion:nil];
//}
//
//- (void)setImageWithUUID:(NSString *)identifier type:(SGServerImageType)type cornerRadius:(CGFloat)cornerRadius fadeDuration:(NSTimeInterval)fadeDuration completion:(void (^)(UIImage *))completion {
//  [self setImageWithUUID:identifier type:type cornerRadius:cornerRadius corners:UIRectCornerAllCorners fadeDuration:fadeDuration completion:completion];
//}
//
//- (void)setImageWithUUID:(NSString *)identifier type:(SGServerImageType)type cornerRadius:(CGFloat)cornerRadius corners:(UIRectCorner)corners fadeDuration:(NSTimeInterval)fadeDuration completion:(void (^)(UIImage *))completion {
//  [self setImageWithUUID:identifier type:type blurRegion:CGRectZero blurRadius:0.0 adjustBlurExposure:0.0 cornerRadius:cornerRadius corners:corners fadeDuration:fadeDuration];
//}
//
//- (void)setImageWithUUID:(NSString *)identifier type:(SGServerImageType)type blurRadius:(CGFloat)blurRadius {
//  CGRect region = {CGPointZero, [self sizeForImageType:type]};
//  [self setImageWithUUID:identifier type:type blurRegion:region blurRadius:blurRadius];
//}
//
//- (void)setImageWithUUID:(NSString *)identifier type:(SGServerImageType)type blurRegion:(CGRect)blurRegion blurRadius:(CGFloat)blurRadius {
//  [self setImageWithUUID:identifier type:type blurRegion:blurRegion blurRadius:blurRadius adjustBlurExposure:0.0 fadeDuration:0.1];
//}
//
//- (void)setImageWithUUID:(NSString *)identifier type:(SGServerImageType)type blurRegion:(CGRect)blurRegion blurRadius:(CGFloat)blurRadius adjustBlurExposure:(CGFloat)exposure fadeDuration:(NSTimeInterval)fadeDuration {
//  [self setImageWithUUID:identifier type:type blurRegion:blurRegion blurRadius:blurRadius adjustBlurExposure:exposure cornerRadius:0.0 corners:0 fadeDuration:fadeDuration];
//}
//
//- (void)setImageWithUUID:(NSString *)identifier type:(SGServerImageType)type blurRegion:(CGRect)blurRegion blurRadius:(CGFloat)blurRadius adjustBlurExposure:(CGFloat)exposure cornerRadius:(CGFloat)cornerRadius corners:(UIRectCorner)corners fadeDuration:(NSTimeInterval)fadeDuration {
//  [self cancelImageLoad];
//  
//  if (!identifier) {
//    return;
//  }
//  
//  NSURL *url = [NSURL URLWithString:[self pathForImageWithUUID:identifier type:type]];
//#ifdef LOG_IMAGE_REQUESTS
//  NSLog(@"Requesting image: %@",[url absoluteString]);
//#endif
//  NSString *cacheKey = [self cacheKeyForImageNamed:[url path] cornerRadius:cornerRadius corners:corners blur:blurRadius region:blurRegion exposure:exposure];
//  UIImage *cachedImage = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:cacheKey];
//  if (cachedImage) {
//    self.image = cachedImage;
//    return;
//  }
//  
//  SGDownloadImage *download = self.imageDownload;
//  
//  if (!download) {
//    download = [[SGDownloadImage alloc] init];
//    self.imageDownload = download;
//  }
//  
//  __weak UIImageView *weakSelf = self;
//  
//  [download getUrl:url placeholder:nil completion:^(UIImage *image) {
//    UIImageView *strongSelf = weakSelf;
//    if (!strongSelf) return;
//
//    [strongSelf setImage:image blurRegion:blurRegion blurRadius:blurRadius adjustBlurExposure:exposure cornerRadius:cornerRadius corners:corners fadeDuration:fadeDuration completion:^(UIImage *processedImage) {
//      BOOL noRounding = corners == 0 || cornerRadius <= 0;
//      [[SDImageCache sharedImageCache] storeImage:processedImage forKey:cacheKey toDisk:noRounding];
//    }];
//    
//  } progress:nil];
//}
//
- (void)setImage:(UIImage *)image fadeDuration:(NSTimeInterval)duration completion:(void (^)(UIImage *image))completion {
  if (duration > 0) {
    [UIView transitionWithView:self duration:duration options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
      self.image = image;
    } completion:^(BOOL finished) {
      if (completion) {
        completion(image);
      }
    }];
  }
  else {
    self.image = image;
    if (completion) {
      completion(image);
    }
  }
}

#pragma mark - String building

- (NSString *)pathForImageWithUUID:(NSString *)identifier type:(SGServerImageType)type {
  NSString *typePath = [self typeStringForImageType:type];
  CGSize imageSize = [self sizeForImageType:type];
  NSString *fileName = @"";
  
  if (CGSizeEqualToSize(imageSize, CGSizeZero)) {
    fileName = @"original";
  }
  else {
    NSString *options = [self optionsForImageType:type];
    fileName = [NSString stringWithFormat:@"%ix%i%@", (int)imageSize.width, (int)imageSize.height, options];
  }
  
  return [NSString stringWithFormat:@"/images/%@/%@/%@.jpg", typePath, identifier, fileName];
}

- (NSString *)optionsForImageType:(SGServerImageType)type {
  if (type == SGServerImageGuide1024x1024) {
    return @"_acns";
  }
  if (type == SGServerImageGuide320x480) {
    return @"";
  }
  return @"_ac";
}

- (NSString *)typeStringForImageType:(SGServerImageType)type {
  if (type & SGServerImageProfile) {
    return @"profile";
  }
  if (type & SGServerImageTopic) {
    return @"topic";
  }
  if (type & SGServerImageRequest) {
    return @"request";
  }
  return @"guide";
}

- (CGSize)sizeForImageType:(SGServerImageType)type {
  CGSize rawSize = CGSizeZero;
  
  switch (type) {
    case SGServerImageGuide45x45:
      rawSize = CGSizeMake(45.0, 45.0);
      break;
    case SGServerImageGuide64x64:
      rawSize = CGSizeMake(64.0, 64.0);
      break;
    case SGServerImageGuide80x80:
      rawSize = CGSizeMake(80.0, 80.0);
      break;
    case SGServerImageGuide185x135:
      rawSize = CGSizeMake(185.0, 135.0);
      break;
    case SGServerImageGuide200x135:
      rawSize = CGSizeMake(200.0, 135.0);
      break;
    case SGServerImageGuide212x288:
      rawSize = CGSizeMake(212.0, 288.0);
      break;
    case SGServerImageGuide244x252:
      rawSize = CGSizeMake(244.0, 288.0);
      break;
    case SGServerImageGuide280x195:
      rawSize = CGSizeMake(280.0, 195.0);
      break;
    case SGServerImageGuide320x160:
      rawSize = CGSizeMake(320.0, 160.0);
      break;
    case SGServerImageGuide320x480:
      rawSize = CGSizeMake(320.0, 480.0);
      break;
    case SGServerImageGuide450x321:
      rawSize = CGSizeMake(450.0, 321.0);
      break;
    case SGServerImageGuide472x418:
      rawSize = CGSizeMake(472.0, 418.0);
      break;
    case SGServerImageGuide718x738:
      rawSize = CGSizeMake(718.0, 738.0);
      break;
    case SGServerImageGuide1024x1024:
      rawSize = CGSizeMake(1024.0, 1024.0);
      break;
    case SGServerImageProfile25x25:
      rawSize = CGSizeMake(25.0, 25.0);
      break;
    case SGServerImageProfile30x30:
      rawSize = CGSizeMake(30.0, 30.0);
      break;
    case SGServerImageProfile40x40:
      rawSize = CGSizeMake(40.0, 40.0);
      break;
    case SGServerImageProfile45x45:
      rawSize = CGSizeMake(45.0, 45.0);
      break;
    case SGServerImageProfile50x50:
      rawSize = CGSizeMake(50.0, 50.0);
      break;
    case SGServerImageProfile60x60:
      rawSize = CGSizeMake(60.0, 60.0);
      break;
    case SGServerImageProfile80x80:
      rawSize = CGSizeMake(80.0, 80.0);
      break;
    case SGServerImageProfile87x87:
      rawSize = CGSizeMake(87.0, 87.0);
      break;
    case SGServerImageTopic64x64:
      rawSize = CGSizeMake(64.0, 64.0);
      break;
    case SGServerImageTopic320x160:
      rawSize = CGSizeMake(320.0, 160.0);
      break;
    case SGServerImageRequest45x45:
      rawSize = CGSizeMake(45.0, 45.0);
      break;
    case SGServerImageRequest50x50:
      rawSize = CGSizeMake(50.0, 50.0);
      break;
    case SGServerImageRequest64x64:
      rawSize = CGSizeMake(64.0, 64.0);
      break;
    case SGServerImageRequest80x80:
      rawSize = CGSizeMake(80.0, 80.0);
      break;
    case SGServerImageRequest185x135:
      rawSize = CGSizeMake(185.0, 135.0);
      break;
    case SGServerImageRequest320x160:
      rawSize = CGSizeMake(320.0, 160.0);
      break;
    case SGServerImageRequest450x321:
      rawSize = CGSizeMake(450.0, 321.0);
      break;
    case SGServerImageRequest630x390:
      rawSize = CGSizeMake(630.0, 390.0);
      break;
    default:
      break;
  }
  
  CGFloat scale = [[UIScreen mainScreen] scale];
  return CGSizeMake(scale * rawSize.width, scale * rawSize.height);
}

- (NSString *)cacheKeyForImageNamed:(NSString *)nameOrPath cornerRadius:(CGFloat)cornerRadius corners:(UIRectCorner)corners blur:(CGFloat)blurRadius region:(CGRect)region exposure:(CGFloat)exposure {
  return [NSString stringWithFormat:@"%@-corner%.01f:%d-blur%.01f:%@-exp-%.01f", nameOrPath, cornerRadius, corners, blurRadius, NSStringFromCGRect(region), exposure];
}

@end
