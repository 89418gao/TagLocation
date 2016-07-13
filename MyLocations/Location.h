//
//  Location.h
//  MyLocations
//
//  Created by Shuyan Guo on 6/30/16.
//  Copyright © 2016 GG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <MapKit/MapKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface Location : NSManagedObject <MKAnnotation>

+(NSInteger)nextPhotoId;

-(BOOL)hasPhoto;
-(NSString *)photoPath;
-(UIImage *)photoImage;
-(void)removePhotoFile;

@end

NS_ASSUME_NONNULL_END

#import "Location+CoreDataProperties.h"
