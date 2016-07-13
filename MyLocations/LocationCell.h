//
//  LocationCell.h
//  MyLocations
//
//  Created by Shuyan Guo on 7/2/16.
//  Copyright © 2016 GG. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LocationCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *descLabel;
@property (nonatomic, weak) IBOutlet UILabel *addressLabel;
@property (nonatomic, weak) IBOutlet UIImageView *photoImageView;

@end
