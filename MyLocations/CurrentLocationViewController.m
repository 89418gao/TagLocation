//
//  FirstViewController.m
//  MyLocations
//
//  Created by Shuyan Guo on 6/20/16.
//  Copyright © 2016 GG. All rights reserved.
//

#import "CurrentLocationViewController.h"
#import "LocationDetailsViewController.h"

@interface CurrentLocationViewController () {
    CLLocationManager *_locationManager;
    CLLocation *_currentLocation;
    BOOL _isUpdatingLocation;
    NSError *_locationError;
    
    CLGeocoder *_geocoder;
    CLPlacemark *_placemark;
    BOOL _isPerformingReverseGeocoding;
    NSError *_lastGeocodingError;
}

@end

@implementation CurrentLocationViewController

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if(self){
        _locationManager = [[CLLocationManager alloc] init];
        _geocoder = [[CLGeocoder alloc] init];
    }
    return self;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self updateLabels];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)getLocation:(UIButton *)sender {
    
    if(_isUpdatingLocation){
        [self stopLocationManager];
    }else{
        _locationError = nil;
        _currentLocation = nil;
        _placemark = nil;
        _lastGeocodingError = nil;
        
        [self startLocationManager];
    }

}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"TagLocation"]) {
        UINavigationController *navigationController = segue.destinationViewController;
        LocationDetailsViewController *locationDetailsVC = (LocationDetailsViewController *)navigationController.topViewController;
        
        locationDetailsVC.placemark = _placemark;
        locationDetailsVC.coordinate = _currentLocation.coordinate;
        locationDetailsVC.managedObjectContext = self.managedObjectContext;
    }
}

-(void)configureGetButton{
    if(_isUpdatingLocation) {
        [_getButton setTitle:@"Stop" forState:UIControlStateNormal];
    }else {
        [_getButton setTitle:@"Get My Location" forState:UIControlStateNormal];
    }
}


#pragma mark - CLLocationManagerDelegate

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"did fail with error: %@",error);
    if(error.code == kCLErrorLocationUnknown) return;
    
    _locationError = error;
    [self stopLocationManager];
    
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    CLLocation *newLocation = [locations lastObject];
    
    if([newLocation.timestamp timeIntervalSinceNow] < -5.0) return;
    if(newLocation.horizontalAccuracy < 0) return;
    
    CLLocationDistance distance = _currentLocation? [newLocation distanceFromLocation:_currentLocation]:MAXFLOAT;
   
    
    if(!_currentLocation || _currentLocation.horizontalAccuracy >= newLocation.horizontalAccuracy){
        _locationError = nil;
        _currentLocation = newLocation;
        [self updateLabels];
        
        if(_currentLocation.horizontalAccuracy <= _locationManager.desiredAccuracy) {
            NSLog(@"Searching is done.");
            [self stopLocationManager];
            
            if(distance > 0) _isPerformingReverseGeocoding = NO;
        }
        
        if(!_isPerformingReverseGeocoding){
            NSLog(@"***Going to geocode");
            _isPerformingReverseGeocoding = YES;
            
            [_geocoder reverseGeocodeLocation:_currentLocation completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
                _lastGeocodingError = error;
                    
                if(!error && placemarks.count > 0){
                    _placemark = [placemarks lastObject];
                }else{
                    _placemark = nil;
                }
                _isPerformingReverseGeocoding = NO;
                [self updateLabels];
            }];
        }
            
    }else if(distance < 1.0) {
        NSTimeInterval timeInterval = [newLocation.timestamp timeIntervalSinceDate:_currentLocation.timestamp];
        if(timeInterval >= 10){
            NSLog(@"***Force Done!");
            [self stopLocationManager];
        }
    }
}


- (NSString *)stringFromPlacemark:(CLPlacemark *)thePlacemark {
    
    NSString *subThoroughfare = thePlacemark.subThoroughfare? thePlacemark.subThoroughfare:@"";
    NSString *thoroughfare = thePlacemark.thoroughfare? thePlacemark.thoroughfare:@"";
    
    return [NSString stringWithFormat:@"%@ %@\n%@ %@ %@",subThoroughfare, thoroughfare, thePlacemark.locality, thePlacemark.administrativeArea, thePlacemark.postalCode];
}

-(void)updateLabels {
    
    [self configureGetButton];
    
    if(_currentLocation){
        _latitudeLabel.text = [NSString stringWithFormat:@"%.8f",_currentLocation.coordinate.latitude];
        _longitudeLabel.text = [NSString stringWithFormat:@"%.8f",_currentLocation.coordinate.longitude];
        _tagButton.hidden = NO;
        
        if (_placemark) {
            self.addressLabel.text = [self stringFromPlacemark:_placemark];
        } else if (_isPerformingReverseGeocoding) {
            self.addressLabel.text = @"Searching for Address...";
        } else if (_lastGeocodingError) {
            self.addressLabel.text = @"Error Finding Address";
        } else {
            self.addressLabel.text = @"No Address Found";
        }
  
    } else {
        _latitudeLabel.text = @"";
        _longitudeLabel.text = @"";
        _tagButton.hidden = YES;
    }
   
    
    NSString *statusMsg;
    if(_locationError){
        if([_locationError.domain isEqualToString:kCLErrorDomain] && _locationError.code== kCLErrorDenied){
            statusMsg = @"Location Services Disabled";
        }else{
            statusMsg = @"Error Getting Location";
        }
    }else if(![CLLocationManager locationServicesEnabled]){
        statusMsg = @"Location Services Disabled";
    }else if(_isUpdatingLocation){
        statusMsg = @"Searching...";
    }else{
        statusMsg = @"Press Button to Start";
    }
    _messageLabel.text = statusMsg;
    
}
-(void)startLocationManager {
    
    if( [CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined){
        [_locationManager requestAlwaysAuthorization];
        [_locationManager requestWhenInUseAuthorization];
    }
    
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied){
        NSLog(@"error code: %d",[CLLocationManager authorizationStatus]);
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Oops" message:@"Location service is not enabled for app. You can enable it in Setting -> Privacy -> Location Services." preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"Got it" style:UIAlertActionStyleDefault handler:nil];
        [alert addAction:action];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    if (![CLLocationManager locationServicesEnabled]){
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Oops" message:@"Location service is not enabled. You can enable it in Setting -> Privacy -> Location Services." preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"Got it" style:UIAlertActionStyleDefault handler:nil];
        [alert addAction:action];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    _locationManager.delegate = self;
    _locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    
    [_locationManager startUpdatingLocation];
    _isUpdatingLocation = YES;

    //    after 60 seconds stop locating automatically
    [self performSelector:@selector(didTimeOut:) withObject:nil afterDelay:60];
    
    [self updateLabels];
}

-(void)stopLocationManager {
    if(_isUpdatingLocation){
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(didTimeOut:) object:nil];
        [_locationManager stopUpdatingLocation];
        _locationManager.delegate = nil;
        _isUpdatingLocation = NO;
    }
    [self updateLabels];
}
-(void)didTimeOut:(id)obj {
    NSLog(@"*** Time out!");
    
    if(!_currentLocation){
        [self stopLocationManager];
        
        _locationError = [NSError errorWithDomain:@"MyLocationsErrorDomain" code:1 userInfo:nil];
    }
}




@end
