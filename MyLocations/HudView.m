//
//  HudView.m
//  MyLocations
//
//  Created by Shuyan Guo on 6/23/16.
//  Copyright © 2016 GG. All rights reserved.
//

#import "HudView.h"

@implementation HudView

+(instancetype)hudInView:(UIView *)view animated:(BOOL)animated {
    
    HudView *hudview = [[HudView alloc] initWithFrame:view.frame];
    hudview.opaque = NO;
    
    [view addSubview:hudview];
    view.userInteractionEnabled = NO;
    
    [hudview showAnimated:animated];
    return hudview;
}

-(void)drawRect:(CGRect)rect {
    const CGFloat boxSize = 96.0f;
    
    CGRect box = CGRectMake(roundf(self.bounds.size.width - boxSize)/2.0f,
                            roundf(self.bounds.size.height - boxSize)/2.0f,
                            boxSize, boxSize);
    
    UIBezierPath *roundRect = [UIBezierPath bezierPathWithRoundedRect:box cornerRadius:10.0f];
    [[UIColor colorWithWhite:0.3f alpha:0.8f] setFill];
    [roundRect fill];
    
    UIImage *image = [UIImage imageNamed:@"Checkmark"];
    CGPoint point = CGPointMake(roundf(self.bounds.size.width - image.size.width)/2.0f,
                                roundf(self.bounds.size.height - image.size.height)/2.0f - boxSize/8.0f
                                );
    [image drawAtPoint:point];
    
    NSDictionary *attributes = @{
                                 NSFontAttributeName : [UIFont systemFontOfSize:16.0f],
                                 NSForegroundColorAttributeName : [UIColor whiteColor],
                                 };
    CGSize textSize = [_text sizeWithAttributes:attributes];
    CGPoint textPoint = CGPointMake(roundf(self.bounds.size.width - textSize.width)/2.0f,
                                roundf(self.bounds.size.height - textSize.height)/2.0f + boxSize/4.0f
                                );
    [_text drawAtPoint:textPoint withAttributes:attributes];
}

-(void)showAnimated:(BOOL)animated {
    if(animated) {
        self.alpha = 0;
        self.transform = CGAffineTransformMakeScale(1.3f, 1.3f);
        
        [UIView animateWithDuration:0.3 animations:^{
            self.alpha = 1.0f;
            self.transform = CGAffineTransformIdentity;
        }];
    }
}

@end
