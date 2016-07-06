//
//  Location.m
//  MyLocations
//
//  Created by Shuyan Guo on 6/30/16.
//  Copyright © 2016 GG. All rights reserved.
//

#import "Location.h"

@implementation Location

-(CLLocationCoordinate2D)coordinate {
    return CLLocationCoordinate2DMake([self.latitude doubleValue], [self.longitude doubleValue]);
}

-(NSString *)title{
    if(self.locationDescription.length > 0){
        return self.locationDescription;
    }
    return @"No Description";
}

- (NSString *)subtitle {
    return self.category;
}

@end
