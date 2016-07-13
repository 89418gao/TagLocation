//
//  LocationDetailsViewController.m
//  MyLocations
//
//  Created by Shuyan Guo on 6/22/16.
//  Copyright © 2016 GG. All rights reserved.
//

#import "LocationDetailsViewController.h"
#import "CategoryPickerViewController.h"
#import "HudView.h"
#import "Location.h"

@interface LocationDetailsViewController () <UITextViewDelegate, CategoryPickerDelegate,UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, weak) IBOutlet UITextView *descriptionTextView;
@property (nonatomic, weak) IBOutlet UILabel *categoryLabel;
@property (nonatomic, weak) IBOutlet UILabel *latitudeLabel;
@property (nonatomic, weak) IBOutlet UILabel *longitudeLabel;
@property (nonatomic, weak) IBOutlet UILabel *addressLabel;
@property (nonatomic, weak) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *photoLabel;



@end

@implementation LocationDetailsViewController {
    NSString *_description;
    NSString *_category;
    NSDate *_date;
    UIImage *_image;
    
    UIAlertController *_alertController;
    UIImagePickerController *_imagePicker;
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if(self){
        _description = @"";
        _category = @"No Category";
        _date = [NSDate date];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    return self;
}

-(void)applicationDidEnterBackground {
    if(_imagePicker){
        _imagePicker = nil;
    }
    
    if(_alertController) {
        [self dismissViewControllerAnimated:NO completion:^{
            _alertController = nil;
        }];
    }
    [self.descriptionTextView resignFirstResponder];
}

- (IBAction)done:(UIBarButtonItem *)sender {
    
    HudView *hudView = [HudView hudInView:self.navigationController.view animated:YES];
    
    
    Location *location = nil;
    if(_locationToEdit) {
        hudView.text = @"Updated";
        location = _locationToEdit;
    }else{
        hudView.text = @"Tagged";
        location = [NSEntityDescription insertNewObjectForEntityForName:@"Location" inManagedObjectContext:self.managedObjectContext];
        location.photoId = @-1;
    }

    location.locationDescription = _description;
    location.category = _category;
    location.latitude = @(self.coordinate.latitude);
    location.longitude = @(self.coordinate.longitude);
    location.date = _date;
    location.placemark = self.placemark;
    
    if(_image){
        if(![location hasPhoto]){
            location.photoId = @([Location nextPhotoId]);
        }
        
        NSData *data = UIImageJPEGRepresentation(_image, 0.5);
        NSError *error;
        if(![data writeToFile:[location photoPath] options:NSDataWritingAtomic error:&error]){
            NSLog(@"Save image with error: %@",error);
        }
    }
    
    NSError *error;
    if(![self.managedObjectContext save:&error]){
        NSLog(@"Error when save : %@", error);
        abort();
    }
    [self performSelector:@selector(closeScreen) withObject:nil afterDelay:0.6];
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

-(IBAction)dismissKeyBoard {
    [_descriptionTextView resignFirstResponder];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.backgroundColor = [UIColor blackColor];
    self.tableView.separatorColor = [UIColor colorWithWhite:1.0f alpha:0.2f];
    self.descriptionTextView.textColor = [UIColor whiteColor];
    self.descriptionTextView.backgroundColor = [UIColor blackColor];
    self.photoLabel.textColor = [UIColor whiteColor];
    self.photoLabel.highlightedTextColor = self.photoLabel.textColor;
    self.addressLabel.textColor = [UIColor colorWithWhite:1.0f alpha:0.4f];
    self.addressLabel.highlightedTextColor = self.addressLabel.textColor;
    
    if(_locationToEdit) {
        self.title = @"Edit Location";
        if([_locationToEdit hasPhoto] && _locationToEdit.photoImage){
            [self showImage:_locationToEdit.photoImage];
            [self.tableView reloadData];
        }
    }
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyBoard)];
    tapRecognizer.cancelsTouchesInView = NO;
    [self.tableView addGestureRecognizer:tapRecognizer];
    

    //创建keyboard top toolBar工具条
    UIToolbar *topBar = (UIToolbar *)[[[NSBundle mainBundle] loadNibNamed:@"KeyboardToolBar" owner:self options:nil] objectAtIndex:0];
    [_descriptionTextView setInputAccessoryView:topBar];
    
    _descriptionTextView.text = _description;
    _categoryLabel.text = _category;
    _dateLabel.text = [self formatDate:_date];
    
    _latitudeLabel.text = [NSString stringWithFormat:@"%.8f",_coordinate.latitude];
    _longitudeLabel.text = [NSString stringWithFormat:@"%.8f", _coordinate.longitude];
    
    if(_placemark){
        _addressLabel.text = [self stringFromPlaceMark];
    }else{
        _addressLabel.text = @"No Address Found";
    }
    _dateLabel.text = [self formatDate:[NSDate date]];

}

-(void)showImage:(UIImage *)image {
    
    [self.photoLabel setHidden:YES];
    [self.imageView setImage:image];
    [self.imageView setHidden:NO];
}

-(NSString *)stringFromPlaceMark {
    NSString *subThoroughfare = _placemark.subThoroughfare? _placemark.subThoroughfare:@"";
    NSString *thoroughfare = _placemark.thoroughfare? [NSString stringWithFormat:@"%@,", _placemark.thoroughfare] :@"";
    
    NSString *string = [NSString stringWithFormat:@"%@ %@ %@, %@ %@,\n%@",subThoroughfare, thoroughfare, _placemark.locality, _placemark.administrativeArea, _placemark.postalCode, _placemark.country];
    return string;
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

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = [UIColor blackColor];
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.textLabel.highlightedTextColor = cell.textLabel.textColor;
    cell.detailTextLabel.textColor = [UIColor colorWithWhite:1.0f alpha:0.4f];
    cell.detailTextLabel.highlightedTextColor = cell.detailTextLabel.textColor;
    UIView *selectionView = [[UIView alloc] initWithFrame:CGRectZero];
    selectionView.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.2f];
    cell.selectedBackgroundView = selectionView;
    
    if (indexPath.row == 2) {
        UILabel *addressLabel = (UILabel *)[cell viewWithTag:100];
        addressLabel.textColor = [UIColor whiteColor];
        addressLabel.highlightedTextColor = addressLabel.textColor;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row == 0) return 88;
    
    if(indexPath.section == 1 && indexPath.row == 0 && !self.imageView.hidden) {
        CGFloat ratio = self.imageView.image.size.height / self.imageView.image.size.width;
        return (self.tableView.bounds.size.width - 33) * ratio + 20;
    }
    
    if(indexPath.section == 2 && indexPath.row == 2){
        CGRect frame = _addressLabel.frame;
        frame.size.height = 100;
        _addressLabel.frame = frame;
        [_addressLabel sizeToFit];

        return _addressLabel.bounds.size.height + 24;
    }
    return 44;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0 || indexPath.section == 1) return indexPath;
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if(indexPath.row == 0 && indexPath.section == 0){
        [_descriptionTextView becomeFirstResponder];
        return;
    }
    if(indexPath.section ==1 && indexPath.row== 0){
        [self showPhotoMenu];
    }
}

-(void)showPhotoMenu {
    
    _alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [_alertController addAction:[UIAlertAction actionWithTitle:@"Take Photo" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self takePhoto];
        _alertController = nil;
    }]];
    [_alertController addAction:[UIAlertAction actionWithTitle:@"Choose From Library" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self choosePhotoFromLibrary];
        _alertController = nil;
    }]];
    [_alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        _alertController = nil;
    }]];
    
    [self presentViewController:_alertController animated:YES completion:nil];
    
}

-(void)choosePhotoFromLibrary {
    
    _imagePicker = [[UIImagePickerController alloc] init];
    _imagePicker.delegate = self;
    _imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    _imagePicker.allowsEditing = YES;
    _imagePicker.view.tintColor = self.view.tintColor;
    [self presentViewController:_imagePicker animated:YES completion:nil];
    
}

-(void)takePhoto {
    
    _imagePicker = [[UIImagePickerController alloc] init];
    _imagePicker.delegate = self;
    _imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    _imagePicker.view.tintColor = self.view.tintColor;
    [self presentViewController:_imagePicker animated:YES completion:nil];
    
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

-(void)setLocationToEdit:(Location *)newLocation {
    
    if(_locationToEdit != newLocation) {
        
        _locationToEdit = newLocation;
        _description = _locationToEdit.locationDescription;
        _category = _locationToEdit.category;
        _date = _locationToEdit.date;
        
        _placemark = _locationToEdit.placemark;
        _coordinate = CLLocationCoordinate2DMake([_locationToEdit.latitude doubleValue], [_locationToEdit.longitude doubleValue]);
        
    }
}

#pragma mark - UIImagePickerControllerDelegate

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    
    _image = info[UIImagePickerControllerOriginalImage];
    [self showImage:_image];

    [self.tableView reloadData];
    [self dismissViewControllerAnimated:YES completion:^{
        _imagePicker = nil;
    }];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:^{
        _imagePicker = nil;
    }];
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
