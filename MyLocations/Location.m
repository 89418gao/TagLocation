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

-(BOOL)hasPhoto {
    return (self.photoId) && ([self.photoId integerValue] != -1);
}

-(NSString *)documentDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = [paths lastObject];
    return documentDirectory;
}
-(NSString *)photoPath {
    NSString *fileName = [NSString stringWithFormat:@"Photo-%ld.jpg", [self.photoId integerValue]];
    return [[self documentDirectory] stringByAppendingPathComponent:fileName];
    
}

-(UIImage *)photoImage {
    NSAssert(self.photoId, @"No photo ID");
    NSAssert([self.photoId integerValue] != -1, @" Photo ID = -1");
    return [UIImage imageWithContentsOfFile:[self photoPath]];
    
}

+(NSInteger)nextPhotoId {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger photoId = [defaults integerForKey:@"PhotoId"];
    [defaults setInteger:photoId+1 forKey:@"PhotoId"];
    [defaults synchronize];
    return photoId;
}

-(void)removePhotoFile {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *path = [self photoPath];
    
    if([fileManager fileExistsAtPath:path]){
        
        NSError *error;
        if(![fileManager removeItemAtPath:path error:&error]){
            NSLog(@"delete photo file with error: %@", error);
        }
    }
}

@end
