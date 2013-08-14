//
//  UIImageView+Additions.h
//  Bamboo
//
//  Created by Nick Lupinetti on 4/17/13.
//
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
  SGServerImageGuide = 0,
  SGServerImageGuide45x45,
  SGServerImageGuide64x64,
  SGServerImageGuide80x80,
  SGServerImageGuide185x135,
  SGServerImageGuide200x135,
  SGServerImageGuide212x288,
  SGServerImageGuide244x252,
  SGServerImageGuide280x195,
  SGServerImageGuide320x480,
  SGServerImageGuide320x160,
  SGServerImageGuide450x321,
  SGServerImageGuide472x418,
  SGServerImageGuide718x738,
  SGServerImageGuide1024x1024,
  SGServerImageProfile = 16,
  SGServerImageProfile25x25,
  SGServerImageProfile30x30,
  SGServerImageProfile40x40,/////////
  SGServerImageProfile45x45,
  SGServerImageProfile50x50,//////////
  SGServerImageProfile60x60,/////////
  SGServerImageProfile80x80,
  SGServerImageProfile87x87,
  SGServerImageTopic = 32,
  SGServerImageTopic64x64,
  SGServerImageTopic320x160,
  SGServerImageRequest = 64,
  SGServerImageRequest45x45,
  SGServerImageRequest50x50,
  SGServerImageRequest64x64,
  SGServerImageRequest80x80,
  SGServerImageRequest185x135,
  SGServerImageRequest320x160,
  SGServerImageRequest450x321,
  SGServerImageRequest630x390
} SGServerImageType;

@interface UIImageView (Additions)

+ (void)cancelAll;
- (void)cancelImageLoad;

//- (void)setCircleImageWithUUID:(NSString *)identifier type:(SGServerImageType)type;
//- (void)setImageWithUUID:(NSString *)identifier type:(SGServerImageType)type;
//- (void)setImageWithUUID:(NSString *)identifier type:(SGServerImageType)type cornerRadius:(CGFloat)cornerRadius;
//- (void)setImageWithUUID:(NSString *)identifier type:(SGServerImageType)type cornerRadius:(CGFloat)cornerRadius fadeDuration:(NSTimeInterval)fadeDuration;
//- (void)setImageWithUUID:(NSString *)identifier type:(SGServerImageType)type cornerRadius:(CGFloat)cornerRadius fadeDuration:(NSTimeInterval)fadeDuration completion:(void (^)(UIImage *))completion;
//- (void)setImageWithUUID:(NSString *)identifier type:(SGServerImageType)type cornerRadius:(CGFloat)cornerRadius corners:(UIRectCorner)corners fadeDuration:(NSTimeInterval)fadeDuration completion:(void (^)(UIImage *))completion;
//- (void)setImageWithUUID:(NSString *)identifier type:(SGServerImageType)type blurRadius:(CGFloat)blurRadius;
//- (void)setImageWithUUID:(NSString *)identifier type:(SGServerImageType)type blurRegion:(CGRect)blurRegion blurRadius:(CGFloat)blurRadius;
//- (void)setImageWithUUID:(NSString *)identifier type:(SGServerImageType)type blurRegion:(CGRect)blurRegion blurRadius:(CGFloat)blurRadius adjustBlurExposure:(CGFloat)exposure fadeDuration:(NSTimeInterval)fadeDuration;
//- (void)setImageWithUUID:(NSString *)identifier type:(SGServerImageType)type blurRegion:(CGRect)blurRegion blurRadius:(CGFloat)blurRadius adjustBlurExposure:(CGFloat)exposure cornerRadius:(CGFloat)cornerRadius corners:(UIRectCorner)corners fadeDuration:(NSTimeInterval)fadeDuration;

- (void)setImage:(UIImage *)image maskToPath:(UIBezierPath *)path;
- (void)setImage:(UIImage *)image maskToPath:(UIBezierPath *)path asynchronous:(BOOL)async fadeDuration:(NSTimeInterval)duration;

- (void)setImage:(UIImage *)image blurRadius:(CGFloat)blurRadius;
- (void)setImage:(UIImage *)image blurRegion:(CGRect)blurRegion blurRadius:(CGFloat)blurRadius;
- (void)setImage:(UIImage *)image blurRegion:(CGRect)blurRegion blurRadius:(CGFloat)blurRadius fadeDuration:(NSTimeInterval)fadeDuration;
- (void)setImage:(UIImage *)image blurRegion:(CGRect)blurRegion blurRadius:(CGFloat)blurRadius adjustBlurExposure:(CGFloat)exposure fadeDuration:(NSTimeInterval)fadeDuration;

- (void)setImage:(UIImage *)image blurRegion:(CGRect)blurRegion blurRadius:(CGFloat)blurRadius adjustBlurExposure:(CGFloat)exposure cornerRadius:(CGFloat)cornerRadius corners:(UIRectCorner)corners fadeDuration:(NSTimeInterval)fadeDuration;

@end
