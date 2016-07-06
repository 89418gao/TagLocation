//
//  MapViewController.m
//  MyLocations
//
//  Created by Shuyan Guo on 7/4/16.
//  Copyright © 2016 GG. All rights reserved.
//

#import "MapViewController.h"
#import <MapKit/MapKit.h>
#import <CoreData/CoreData.h>
#import "Location.h"
#import "LocationDetailsViewController.h"

@interface MapViewController () <MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@end

@implementation MapViewController {
    NSMutableArray *_locations;
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    if(self = [super initWithCoder:aDecoder]){
        _locations = [NSMutableArray array];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contextDidChange:) name:NSManagedObjectContextObjectsDidChangeNotification object:self.managedObjectContext];
    }
    
    return self;
}

-(void)contextDidChange: (NSNotification *)notification {
    if(![self isViewLoaded]) return;
    
    
    NSSet *deleteLocations = notification.userInfo[NSDeletedObjectsKey];
    for(id location in deleteLocations) {
        [self.mapView removeAnnotation:location];
        [_locations removeObject:location];
    }
    
      
    NSSet *insertLocations = notification.userInfo[NSInsertedObjectsKey];
    for(id location in insertLocations) {
        [self.mapView addAnnotation:location];
        [_locations addObject:location];
    }
    
    
    NSSet *updateLocations = notification.userInfo[NSUpdatedObjectsKey];
    for(id location in updateLocations) {
        [self.mapView removeAnnotation:location];
        [self.mapView addAnnotation:location];
        [_locations removeObject:location];
        [_locations addObject:location];
    }
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self updateLocations];
    
    if(_locations.count > 0){
        NSLog(@"********** showLocations");

        [self showLocations];
    }
}

-(void)updateLocations {
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Location" inManagedObjectContext:self.managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:entity];
    
    NSError *error;
    NSArray *foundObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if(!foundObjects){
        NSLog(@"*** found nothing with error: %@", error);
        return;
    }
 
    if(_locations) [self.mapView removeAnnotations:_locations];
    [_locations removeAllObjects];
    [_locations addObjectsFromArray:foundObjects];
    [self.mapView addAnnotations:_locations];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];

}
- (IBAction)showUser{
    
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(self.mapView.userLocation.coordinate, 1000, 1000);
    [self.mapView setRegion:[self.mapView regionThatFits:region] animated:YES];
}

- (IBAction)showLocations {

    MKCoordinateRegion region = [self regionForAnnotations:_locations];
    [self.mapView setRegion:region animated:YES];
    
}
-(MKCoordinateRegion)regionForAnnotations:(NSArray *)annotations {
    if(annotations.count == 0) {
        return MKCoordinateRegionMakeWithDistance(self.mapView.userLocation.coordinate, 1000, 1000);
    }
    
    if(annotations.count ==1){
        id <MKAnnotation> annotaion = [annotations lastObject];
        return MKCoordinateRegionMakeWithDistance(annotaion.coordinate, 1000, 1000);
    }
    
    CLLocationCoordinate2D topLeft, bottomRight;
    topLeft.latitude = -90;
    topLeft.longitude = 180;
    bottomRight.latitude = 90;
    bottomRight.longitude = -180;
    
    for(id <MKAnnotation> annotation in annotations) {
        topLeft.latitude = fmax(annotation.coordinate.latitude , topLeft.latitude);
        topLeft.longitude = fmin(annotation.coordinate.longitude , topLeft.longitude);
        bottomRight.latitude = fmin(annotation.coordinate.latitude , bottomRight.latitude);
        bottomRight.longitude = fmax(annotation.coordinate.longitude , bottomRight.longitude);
        
    }
    
    const double extraSpace=1.1;
    MKCoordinateRegion region;
    
    region.center.latitude = topLeft.latitude - (topLeft.latitude - bottomRight.latitude)/2;
    region.center.longitude = topLeft.longitude - (topLeft.longitude - bottomRight.longitude)/2;
    
    region.span.latitudeDelta = fabs(bottomRight.latitude - topLeft.latitude)*extraSpace;
    region.span.longitudeDelta = fabs(topLeft.longitude - bottomRight.longitude)*extraSpace;
    
    return [self.mapView regionThatFits:region];
}


#pragma mark - MKMapViewDelegate

-(MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    
    if(![annotation isKindOfClass:[Location class]]) return nil;
    
    NSString *identifier = @"Location";
    
    MKPinAnnotationView *annotationView = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
    
    if(!annotationView){
        annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
        
        annotationView.enabled = YES;
        annotationView.canShowCallout = YES;
        annotationView.animatesDrop = NO;
        annotationView.pinTintColor = [MKPinAnnotationView greenPinColor];
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        [button addTarget:self action:@selector(showLocationDetails:) forControlEvents:UIControlEventTouchUpInside];
        annotationView.rightCalloutAccessoryView = button;
        
    }else{
        annotationView.annotation = annotation;
    }
    UIButton *button = (UIButton *)[annotationView rightCalloutAccessoryView];
    button.tag = [_locations indexOfObject:(Location *)annotation];
    
    return annotationView;
}

-(void)showLocationDetails:(UIButton *)button {
    [self performSegueWithIdentifier:@"EditLocation" sender:button];
}
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"EditLocation"]) {
        
        UINavigationController *navi = segue.destinationViewController;
        LocationDetailsViewController *locationDetailVC = navi.viewControllers[0];
        
        UIButton *btn = (UIButton *)sender;
        locationDetailVC.locationToEdit = _locations[btn.tag];
        locationDetailVC.managedObjectContext = self.managedObjectContext;
    }
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
