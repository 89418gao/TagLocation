//
//  Location+CoreDataProperties.h
//  MyLocations
//
//  Created by Shuyan Guo on 7/6/16.
//  Copyright © 2016 GG. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Location.h"

NS_ASSUME_NONNULL_BEGIN

@interface Location (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *category;
@property (nullable, nonatomic, retain) NSDate *date;
@property (nullable, nonatomic, retain) NSNumber *latitude;
@property (nullable, nonatomic, retain) NSString *locationDescription;
@property (nullable, nonatomic, retain) NSNumber *longitude;
@property (nullable, nonatomic, retain) CLPlacemark *placemark;
@property (nullable, nonatomic, retain) NSNumber *photoId;

@end

NS_ASSUME_NONNULL_END
