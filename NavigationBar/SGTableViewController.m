//
//  SGTableViewController.m
//  NavigationBar
//
//  Created by Nick Lupinetti on 8/12/13.
//  Copyright (c) 2013 Heavy Bits, Inc. All rights reserved.
//

#import "SGTableViewController.h"

#import "SGDetailViewController.h"
#import "SGSegmentBarController.h"
#import "SGTableViewCell.h"
#import "UIImageView+Additions.h"

@interface SGTableViewController ()

@end

@implementation SGTableViewController

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.rowHeight = self.view.bounds.size.width;
    [self.tableView registerClass:[SGTableViewCell class] forCellReuseIdentifier:@"Cell"];
    [self loadImages];
}

#pragma mark - Data

- (NSInteger)assetCount {
    return 16;
}

- (UIImage *)assetWithIndex:(NSInteger)index {
    NSString *assetName = [NSString stringWithFormat:@"%02d", index];
    return [UIImage imageNamed:assetName];
}

- (void)loadImages {
    NSMutableArray *objects = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < 30; i++) {
        NSInteger assetIndex = rand() % [self assetCount] + 1;
        [objects addObject:[self assetWithIndex:assetIndex]];
    }
    
    _objects = objects;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _objects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SGTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    UIImage *image = self.objects[indexPath.row];
    CGRect bottomQuarter = CGRectMake(0, image.size.height * 3 / 4, image.size.width, image.size.height / 4);
    cell.photoView.image = nil;
    [cell.photoView setImage:image blurRegion:bottomQuarter blurRadius:5.0 adjustBlurExposure:-.25 cornerRadius:10 corners:UIRectCornerAllCorners fadeDuration:0.2];
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    SGDetailViewController *detailController = [[SGDetailViewController alloc] init];
    detailController.detailItem = self.objects[indexPath.row];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    [self.navigationController pushViewController:detailController animated:YES];
}

#pragma mark - Scroll view delegate

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [self.segmentBarController scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self.segmentBarController scrollViewDidEndDecelerating:scrollView];
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
    return [self.segmentBarController scrollViewShouldScrollToTop:scrollView];
}

@end
