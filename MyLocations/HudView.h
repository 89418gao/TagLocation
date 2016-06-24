//
//  HudView.h
//  MyLocations
//
//  Created by Shuyan Guo on 6/23/16.
//  Copyright © 2016 GG. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HudView : UIView

+(instancetype)hudInView:(UIView *)view animated:(BOOL)animated;

@property (nonatomic,strong) NSString *text;

@end
