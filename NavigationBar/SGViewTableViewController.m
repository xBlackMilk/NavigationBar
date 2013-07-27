//
//  SGViewTableViewController.m
//  NavigationBar
//
//  Created by Nick Lupinetti on 7/24/13.
//  Copyright (c) 2013 Heavy Bits, Inc. All rights reserved.
//

#import "SGViewTableViewController.h"

@interface SGViewModel : NSObject
@property (nonatomic, strong) UIView *view;
@property (nonatomic, copy) NSString *name;
@property (nonatomic) NSInteger level;
@end

@implementation SGViewModel
@end

static NSString * const kCellIdentifier = @"Cell";

@interface SGViewTableViewController ()
@property (nonatomic, strong) NSMutableArray *barViews;
@property (nonatomic, strong) UIColor *hiddenViewTextColor;
@property (nonatomic, strong) UIColor *visibleViewTextColor;
@property (nonatomic) NSInteger index;
@end

@implementation SGViewTableViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
      self.barViews = [NSMutableArray array];
      self.visibleViewTextColor = [UIColor colorWithRed:0.1 green:0.5 blue:.9 alpha:1.0];
      self.hiddenViewTextColor = [UIColor lightGrayColor];
      self.index = 1;
      self.rootView = self.navigationController.navigationBar;
    }
    return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStylePlain target:self action:@selector(nextButtonTapped:)];
  self.navigationItem.title = [NSString stringWithFormat:@"%d",self.index];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [self collectViewsFromView:self.rootView];
  [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kCellIdentifier];
  [self.tableView reloadData];
}

- (void)nextButtonTapped:(id)sender {
  SGViewTableViewController *nextController = [[SGViewTableViewController alloc] initWithStyle:UITableViewStylePlain];
  nextController.index = self.index + 1;
  [self.navigationController pushViewController:nextController animated:YES];
}

#pragma mark - Data

- (void)collectViewsFromView:(UIView *)view level:(NSInteger)level {
  [self.barViews addObject:[self viewModelForView:view level:level]];
  
  for (UIView *subview in [view subviews]) {
    [self collectViewsFromView:subview level:level + 1];
  }
}

- (void)collectViewsFromView:(UIView *)view {
  [self collectViewsFromView:view level:0];
}

- (SGViewModel *)viewModelForView:(UIView *)view level:(NSInteger)level {
  SGViewModel *model = [[SGViewModel alloc] init];
  model.view = view;
  model.level = level;
  model.name = NSStringFromClass([view class]);
  return model;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.barViews count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier forIndexPath:indexPath];
  SGViewModel *model = self.barViews[indexPath.row];
  cell.indentationWidth = 20.0;
  cell.textLabel.text = model.name;
  cell.textLabel.textColor = model.view.hidden ? self.hiddenViewTextColor : self.visibleViewTextColor;
  
  CGFloat leftInset = (1 + model.level) * cell.indentationWidth;
  cell.separatorInset = UIEdgeInsetsMake(0, leftInset, 0, 0);
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  SGViewModel *model = self.barViews[indexPath.row];
  UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
  BOOL hide = !model.view.hidden;
  
  model.view.hidden = hide;
  cell.textLabel.textColor = hide ? self.hiddenViewTextColor : self.visibleViewTextColor;
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  NSLog(@"%@",model.view);
}

@end
