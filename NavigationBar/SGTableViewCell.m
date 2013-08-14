//
//  SGTableViewCell.m
//  NavigationBar
//
//  Created by Nick Lupinetti on 8/12/13.
//  Copyright (c) 2013 Heavy Bits, Inc. All rights reserved.
//

#import "SGTableViewCell.h"

@implementation SGTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        _photoView = [[UIImageView alloc] initWithFrame:self.bounds];
        _photoView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        _photoView.contentMode = UIViewContentModeCenter;
        [self.contentView addSubview:_photoView];
    }
    return self;
}

@end
