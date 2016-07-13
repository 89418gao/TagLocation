//
//  NSMutableString+AddText.m
//  MyLocations
//
//  Created by Shuyan Guo on 7/6/16.
//  Copyright © 2016 GG. All rights reserved.
//

#import "NSMutableString+AddText.h"

@implementation NSMutableString (AddText)

-(void)addText:(NSString *)text withSeparator:(NSString *)separator {

    if(text){
        if(self.length > 0){
            [self appendString:separator];
        }
        [self appendString:text];
    }
}

@end
