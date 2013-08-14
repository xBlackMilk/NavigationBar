//
//  SGSegmentBarController.h
//  Bamboo
//
//  Created by Nick Lupinetti on 8/8/13.
//  Copyright (c) 2013 Heavy Bits, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SGSegmentBar.h"

/** To enable segment bar autohiding, you must forward `scrollViewDidEndDecelerating:`
 `scrollViewDidEndDragging:willDecelerate:` and `scrollViewShouldScrollToTop:` to SGSegmentBarController
 */

@interface SGSegmentBarController : UIViewController <UIScrollViewDelegate>
@property (nonatomic, readonly) SGSegmentBar *segmentBar;
@property (nonatomic, copy) NSArray *viewControllers;
@property (nonatomic) UIViewController *selectedViewController;
@property (nonatomic) NSUInteger selectedIndex;
@end


@interface SGSegmentBarItem : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) UIImage *image;
@end


@interface UIViewController (SGSegmentBarControllerItem)
@property (nonatomic, readonly) SGSegmentBarController *segmentBarController;
@property (nonatomic, strong) SGSegmentBarItem *segmentBarItem;
@end
