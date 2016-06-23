//
//  LocationDetailsViewController.m
//  MyLocations
//
//  Created by Shuyan Guo on 6/22/16.
//  Copyright © 2016 GG. All rights reserved.
//

#import "LocationDetailsViewController.h"
#import "CategoryPickerViewController.h"

@interface LocationDetailsViewController () <UITextViewDelegate, CategoryPickerDelegate>

@property (nonatomic, weak) IBOutlet UITextView *descriptionTextView;
@property (nonatomic, weak) IBOutlet UILabel *categoryLabel;
@property (nonatomic, weak) IBOutlet UILabel *latitudeLabel;
@property (nonatomic, weak) IBOutlet UILabel *longitudeLabel;
@property (nonatomic, weak) IBOutlet UILabel *addressLabel;
@property (nonatomic, weak) IBOutlet UILabel *dateLabel;

@end

@implementation LocationDetailsViewController {
    NSString *_description;
    NSString *_category;
    
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if(self){
        _description = @"";
        _category = @"No Category";
    }
    return self;
}


- (IBAction)done:(UIBarButtonItem *)sender {
    
    NSLog(@"*** description: %@",_description);
    [self closeScreen];
}

- (IBAction)cancel:(UIBarButtonItem *)sender {
    [self closeScreen];    
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if([segue.identifier isEqualToString:@"PickCategory"]) {
        CategoryPickerViewController *pickerVC = (CategoryPickerViewController *)segue.destinationViewController;
        pickerVC.selectedCategoryName = _category;
        pickerVC.delegate = self;
    }
}

-(void)closeScreen {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)editFinish {
    [_descriptionTextView resignFirstResponder];
}
- (void)viewDidLoad {
    [super viewDidLoad];

    //创建keyboard top toolBar工具条
    UIToolbar *topView = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 30)];
    [topView setBarStyle:UIBarStyleDefault];

    UIBarButtonItem *spaceBn = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];

    UIBarButtonItem *doneBn = [[UIBarButtonItem alloc]initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(editFinish)];
    [topView setItems:@[spaceBn,doneBn]];
    [_descriptionTextView setInputAccessoryView:topView];
    
    _descriptionTextView.text = _description;
    _categoryLabel.text = _category;
    
    _latitudeLabel.text = [NSString stringWithFormat:@"%.8f",_coordinate.latitude];
    _longitudeLabel.text = [NSString stringWithFormat:@"%.8f", _coordinate.longitude];
    
    if(_placemark){
        _addressLabel.text = [self stringFromPlaceMark];
    }else{
        _addressLabel.text = @"No Address Found";
    }
    _dateLabel.text = [self formatDate:[NSDate date]];

}

-(NSString *)stringFromPlaceMark {
    NSString *subThoroughfare = _placemark.subThoroughfare? _placemark.subThoroughfare:@"";
    NSString *thoroughfare = _placemark.thoroughfare? [NSString stringWithFormat:@"%@,", _placemark.thoroughfare] :@"";
    
    return [NSString stringWithFormat:@"%@ %@ %@, %@ %@,\n%@",subThoroughfare, thoroughfare, _placemark.locality, _placemark.administrativeArea, _placemark.postalCode, _placemark.country];
}

-(NSString *)formatDate: (NSDate *)date{
    
    NSDateFormatter *formatter = nil;
    if(!formatter) {
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateStyle:NSDateFormatterMediumStyle];
        [formatter setTimeStyle:NSDateFormatterShortStyle];
    }
    return [formatter stringFromDate:date];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0 && indexPath.row == 0) return 88;
    
    if(indexPath.section == 2 && indexPath.row == 2){
        CGRect frame = _addressLabel.frame;
        frame.size.height = 1000;
        _addressLabel.frame = frame;
        [_addressLabel sizeToFit];

        return _addressLabel.bounds.size.height + 24;
    }
    return 44;
}

# pragma mark - UITextViewDelegate

-(void)textViewDidEndEditing:(UITextView *)textView {
    _description = textView.text;
}

# pragma mark - CategoryPickerDelegate 

-(void)categoryPicker:(CategoryPickerViewController *)picker didFinishSelect:(NSString *)category {
    
    _category = category;
    self.categoryLabel.text = _category;
    
    [self.navigationController popViewControllerAnimated:YES];
}


@end
