//
//  SGDetailViewController.h
//  NavigationBar
//
//  Created by Nick Lupinetti on 7/22/13.
//  Copyright (c) 2013 Heavy Bits, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SGDetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;

@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@end
