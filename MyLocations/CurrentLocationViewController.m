//
//  FirstViewController.m
//  MyLocations
//
//  Created by Shuyan Guo on 6/20/16.
//  Copyright © 2016 GG. All rights reserved.
//

#import "CurrentLocationViewController.h"
#import "LocationDetailsViewController.h"
#import "NSMutableString+AddText.h"
#import <AudioToolbox/AudioServices.h>

@interface CurrentLocationViewController () <UITabBarControllerDelegate>
{
    CLLocationManager *_locationManager;
    CLLocation *_currentLocation;
    BOOL _isUpdatingLocation;
    NSError *_locationError;
    
    CLGeocoder *_geocoder;
    CLPlacemark *_placemark;
    BOOL _isPerformingReverseGeocoding;
    NSError *_lastGeocodingError;
    
    BOOL _isShowingLogo;
    
    UIActivityIndicatorView *_spinner;
    SystemSoundID _soundID;
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

-(void)showLogo {
   
    _isShowingLogo = YES;
    _logoButton.hidden = NO;
    CABasicAnimation *logoMover = [CABasicAnimation animationWithKeyPath:@"position"];
    logoMover.removedOnCompletion = NO;
    logoMover.fillMode = kCAFillModeForwards;
    logoMover.duration = 0.5;
    logoMover.fromValue = [NSValue valueWithCGPoint:CGPointMake(-(self.view.center.x), _logoButton.center.y)];
    logoMover.toValue = [NSValue valueWithCGPoint:CGPointMake(self.view.center.x, _logoButton.center.y)];
    logoMover.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    [_logoButton.layer addAnimation:logoMover forKey:@"logoMover"];
    
    
    
    CABasicAnimation *logoRotator = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    logoRotator.removedOnCompletion = NO;
    logoRotator.fillMode = kCAFillModeForwards;
    logoRotator.duration = 0.5;
    logoRotator.fromValue = @0.0f;
    logoRotator.toValue = @(2.0f * M_PI);
    logoRotator.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    [_logoButton.layer addAnimation:logoRotator forKey:@"logoRotator"];
    
    

    CABasicAnimation *panelMover = [CABasicAnimation animationWithKeyPath:@"position"];
    panelMover.removedOnCompletion = NO;
    panelMover.fillMode = kCAFillModeForwards;
    panelMover.duration = 0.6;
    
    panelMover.fromValue = [NSValue valueWithCGPoint:self.containerView.center];
    panelMover.toValue = [NSValue valueWithCGPoint:CGPointMake(self.view.bounds.size.width * 2.0f, self.containerView.center.y)];
    panelMover.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    panelMover.delegate = self;
    [self.containerView.layer addAnimation:panelMover forKey:@"panelMover"];
    
    
}
-(void)hideLogo {
 
    if(!_containerView.hidden) return;
    _isShowingLogo = NO;
    
    _containerView.hidden = NO;
    CABasicAnimation *panelMover = [CABasicAnimation animationWithKeyPath:@"position"];
    panelMover.removedOnCompletion = NO;
    panelMover.fillMode = kCAFillModeForwards;
    panelMover.duration = 0.6;
    panelMover.fromValue = [NSValue valueWithCGPoint:CGPointMake(self.view.bounds.size.width * 2.0f,self.containerView.center.y)];
    panelMover.toValue = [NSValue valueWithCGPoint:self.containerView.center];
    panelMover.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    panelMover.delegate = self;
    [self.containerView.layer addAnimation:panelMover forKey:@"panelMover"];
    
    
    CABasicAnimation *logoMover = [CABasicAnimation animationWithKeyPath:@"position"];
    logoMover.removedOnCompletion = NO;
    logoMover.fillMode = kCAFillModeForwards;
    logoMover.duration = 0.5;
    logoMover.fromValue = [NSValue valueWithCGPoint:_logoButton.center];
    logoMover.toValue = [NSValue valueWithCGPoint:CGPointMake(-(self.view.center.x), _logoButton.center.y)];
    logoMover.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    [_logoButton.layer addAnimation:logoMover forKey:@"logoMover"];
    
    
    
    
    CABasicAnimation *logoRotator = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    logoRotator.removedOnCompletion = NO;
    logoRotator.fillMode = kCAFillModeForwards;
    logoRotator.duration = 0.5;
    logoRotator.fromValue = @0.0f;
    logoRotator.toValue = @(-2.0f * M_PI);
    logoRotator.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    [_logoButton.layer addAnimation:logoRotator forKey:@"logoRotator"];

}
-(void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    [_containerView.layer removeAllAnimations];
    [_logoButton.layer removeAllAnimations];
    
    if(_isShowingLogo){
        _containerView.hidden = YES;
    }else{
        _logoButton.hidden = YES;
    }
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tabBarController.delegate = self;
    self.tabBarController.tabBar.translucent = NO;
    [self loadSoundEffect];
}

-(void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    [self updateLabels];
    [self configureGetButton];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)getLocation:(UIButton *)sender {
    
    if (_isUpdatingLocation) {
        [self stopLocationManager];
        [self showLogo];
    } else {
        _currentLocation = nil;
        _locationError = nil;
        _placemark = nil;
        _lastGeocodingError = nil;
        [self startLocationManager];
        [self hideLogo];
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
        
        if(!_spinner){
            _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
            _spinner.center = CGPointMake(self.messageLabel.center.x, self.messageLabel.center.y+15+_spinner.bounds.size.height/2);
            
            [_spinner startAnimating];
            [self.containerView addSubview:_spinner];
        }

    }else {
        [_getButton setTitle:@"Get My Location" forState:UIControlStateNormal];
        
        [_spinner removeFromSuperview];
        _spinner = nil;
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
                    if(!_placemark){
                        [self playSoundEffect];
                    }
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
    
    NSMutableString *line1 = [NSMutableString string];
    [line1 addText:thePlacemark.subThoroughfare withSeparator:@""];
    [line1 addText:thePlacemark.thoroughfare withSeparator:@" "];
    
    NSMutableString *line2 = [NSMutableString string];
    [line2 addText:thePlacemark.locality withSeparator:@""];
    [line2 addText:thePlacemark.administrativeArea withSeparator:@" "];
    [line2 addText:thePlacemark.postalCode withSeparator:@" "];
    
    if(line1.length > 0) [line1 appendString:@"\n"];
    [line1 appendString:line2];
    return line1;

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
        _latTextLabel.hidden = NO;
        _longTextLabel.hidden = NO;
  
    } else {
        _latitudeLabel.text = @"";
        _longitudeLabel.text = @"";
        _addressLabel.text = @"";
        _tagButton.hidden = YES;
        _latTextLabel.hidden = YES;
        _longTextLabel.hidden = YES;
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
        statusMsg = @"";
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


#pragma mark - UITabBarControllerDelegate 

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    tabBarController.tabBar.translucent = (viewController != self);
    return YES;
}


#pragma mark - Sound Effect

- (void)loadSoundEffect
{
    NSString *path = [[NSBundle mainBundle]
                      pathForResource:@"Sound.caf" ofType:nil];
    NSURL *fileURL = [NSURL fileURLWithPath:path isDirectory:NO];
    if (fileURL == nil) {
        NSLog(@"NSURL is nil for path: %@", path);
        return;
    }
    OSStatus error = AudioServicesCreateSystemSoundID(
                                                      (__bridge CFURLRef)fileURL, &_soundID);
    if (error != kAudioServicesNoError) {
        NSLog(@"Error code %d loading sound at path: %@", (int)error, path);
        return;
    }
}
- (void)unloadSoundEffect
{
    AudioServicesDisposeSystemSoundID(_soundID);
    _soundID = 0;
}
- (void)playSoundEffect
{
    AudioServicesPlaySystemSound(_soundID);
}

@end
