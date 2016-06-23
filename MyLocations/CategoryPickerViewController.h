//
//  CategoryPickerViewController.h
//  MyLocations
//
//  Created by Shuyan Guo on 6/22/16.
//  Copyright © 2016 GG. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CategoryPickerDelegate;
@class CategoryPickerViewController;

@protocol CategoryPickerDelegate <NSObject>

-(void)categoryPicker:(CategoryPickerViewController *)picker didFinishSelect:(NSString *)category;

@end



@interface CategoryPickerViewController : UITableViewController

@property (nonatomic, strong) NSString *selectedCategoryName;
@property (nonatomic, weak) id <CategoryPickerDelegate> delegate;

@end
