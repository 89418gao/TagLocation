//
//  FirstViewController.m
//  MyLocations
//
//  Created by Shuyan Guo on 6/20/16.
//  Copyright © 2016 GG. All rights reserved.
//

#import "CurrentLocationViewController.h"

@interface CurrentLocationViewController () {
    CLLocationManager *_locationManager;
    CLLocation *_currentLocation;
    
    BOOL _isUpdatingLocation;
    NSError *_locationError;
}

@end

@implementation CurrentLocationViewController

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if(self){
        _locationManager = [[CLLocationManager alloc] init];
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
        [self startLocationManager];
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

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    CLLocation *newLocation = [locations lastObject];
    NSLog(@"didUpdateLocations %@", _currentLocation);
    
    if([newLocation.timestamp timeIntervalSinceNow] < -5.0) return;
    if(newLocation.horizontalAccuracy < 0) return;
    
    if(_currentLocation==nil || _currentLocation.horizontalAccuracy >= newLocation.horizontalAccuracy){
        _locationError = nil;
        _currentLocation = newLocation;
        [self updateLabels];
        
        if(_currentLocation.horizontalAccuracy <= _locationManager.desiredAccuracy) {
            NSLog(@"Searching is done.");
            [self stopLocationManager];
        }
    }
    
    
}

-(void)updateLabels {
    
    [self configureGetButton];
    
    if(_currentLocation){
        _latitudeLabel.text = [NSString stringWithFormat:@"%.8f",_currentLocation.coordinate.latitude];
        _longitudeLabel.text = [NSString stringWithFormat:@"%.8f",_currentLocation.coordinate.longitude];
        _tagButton.hidden = NO;
  
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
    [self updateLabels];
}
-(void)stopLocationManager {
    if(_isUpdatingLocation){
        [_locationManager stopUpdatingLocation];
        _locationManager.delegate = nil;
        _isUpdatingLocation = NO;
    }
    [self updateLabels];
}




@end
