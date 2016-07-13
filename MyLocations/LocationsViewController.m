//
//  LocationsViewController.m
//  MyLocations
//
//  Created by Shuyan Guo on 7/2/16.
//  Copyright © 2016 GG. All rights reserved.
//

#import "LocationsViewController.h"
#import <CoreData/CoreData.h>
#import "Location.h"
#import "LocationCell.h"
#import "LocationDetailsViewController.h"
#import "NSMutableString+AddText.h"



@interface LocationsViewController () <NSFetchedResultsControllerDelegate>

@end

@implementation LocationsViewController{
    
    NSFetchedResultsController *_fetchResultsController;
    
}

-(NSFetchedResultsController *)fetchResultsController {
    
    if(!_fetchResultsController){
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Location" inManagedObjectContext:self.managedObjectContext];
        
        [fetchRequest setEntity:entity];
        
        NSSortDescriptor *sortCategory = [NSSortDescriptor sortDescriptorWithKey:@"category" ascending:YES];
        NSSortDescriptor *sortDate = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES];
        
        [fetchRequest setSortDescriptors:@[sortCategory, sortDate]];
        
        
        [fetchRequest setFetchBatchSize:20];
        
        _fetchResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:@"category" cacheName:@"Locations"];
        
        _fetchResultsController.delegate = self;
    }
    return _fetchResultsController;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self performFetch];
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.tableView.backgroundColor = [UIColor blackColor];
    self.tableView.separatorColor = [UIColor colorWithWhite:1.0f alpha:0.2];
    
}

-(void)performFetch {

    NSError *error;
    if(![self.fetchResultsController performFetch:&error]){
        NSLog(@"fetchResultsController failed with Error: %@",error);
    }

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    return [[self fetchResultsController] sections].count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self fetchResultsController] sections][section];
    return [sectionInfo numberOfObjects];
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    id<NSFetchedResultsSectionInfo> sectionInfo = [self fetchResultsController].sections[section];
    return [[sectionInfo name] uppercaseString];
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Location" forIndexPath:indexPath];
    
    [self configureCell:cell atIndexPath:indexPath];

    return cell;
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if(editingStyle == UITableViewCellEditingStyleDelete) {
        Location *location = [[self fetchResultsController] objectAtIndexPath:indexPath];
        [location removePhotoFile];
        [self.managedObjectContext deleteObject:location];
        
        NSError *error;
        if(![self.managedObjectContext save:&error]){
            NSLog(@"*** UITableViewCellEditingStyleDelete error: %@", error);
            return;
        }
    }
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(15, tableView.sectionHeaderHeight - 14.0f, tableView.bounds.size.width-20, 14.0f)];
    label.text = [tableView.dataSource tableView:tableView titleForHeaderInSection:section];
    label.font = [UIFont boldSystemFontOfSize:11.0f];
    label.textColor = [UIColor colorWithWhite:1.0f alpha:0.4f];
    label.backgroundColor = [UIColor clearColor];
    
    UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(15, tableView.sectionHeaderHeight-0.5, tableView.bounds.size.width - 15, 0.5)];
    separator.backgroundColor = tableView.separatorColor;
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, tableView.sectionHeaderHeight)];
    view.backgroundColor = [UIColor clearColor];
    [view addSubview:separator];
    [view addSubview:label];
    
    return view;
    
}

-(void)configureCell:(UITableViewCell *)tableCell atIndexPath:(NSIndexPath *)indexPath {
    
    LocationCell *cell = (LocationCell *)tableCell;
    Location *location = [[self fetchResultsController] objectAtIndexPath:indexPath];
    
    if(location.locationDescription.length > 0) {
        cell.descLabel.text = location.locationDescription;
    }else {
        cell.descLabel.text = @"No Description";
    }
    
    if(location.placemark){
        NSMutableString *string = [NSMutableString string];
        [string addText:location.placemark.subThoroughfare withSeparator:@""];
        [string addText:location.placemark.thoroughfare withSeparator:@" "];
        [string addText:location.placemark.locality withSeparator:@", "];
        
        cell.addressLabel.text = string;
    }else {
        cell.addressLabel.text = [NSString stringWithFormat:@"Lat: %.8f, Long: %.8f", [location.latitude doubleValue], [location.longitude doubleValue]];
    }

    UIImage *image = [UIImage imageNamed:@"No Photo"];
    if([location hasPhoto] && [location photoImage]){
        image = [location photoImage];
    }
    
    UIView *selectionView = [[UIView alloc] initWithFrame:CGRectZero];
    selectionView.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.2f];
    cell.selectedBackgroundView = selectionView;
    
    
    cell.photoImageView.layer.cornerRadius = cell.photoImageView.bounds.size.width / 2.0f;
    cell.photoImageView.layer.masksToBounds = YES;
    cell.photoImageView.clipsToBounds = YES;
    cell.photoImageView.image = image;
    cell.separatorInset = UIEdgeInsetsMake(0, 82, 0, 0);

}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if([segue.identifier isEqualToString:@"EditLocation"]) {
        UINavigationController *navigation = segue.destinationViewController;
        LocationDetailsViewController *locationDetailsVC = (LocationDetailsViewController *)navigation.viewControllers[0];
        
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        locationDetailsVC.locationToEdit = [[self fetchResultsController] objectAtIndexPath:indexPath];
        
        locationDetailsVC.managedObjectContext = self.managedObjectContext;
    }
}



#pragma mark - NSFetchResultsDelegate

-(void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    
    NSLog(@"*** Controller will change content");
    [self.tableView beginUpdates];
}

-(void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    
    switch (type) {
        case NSFetchedResultsChangeInsert:
            NSLog(@"*** NSFetchedResultsChangeInsert (object)");
            [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            NSLog(@"*** NSFetchedResultsChangeDelete (object)");
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            NSLog(@"*** NSFetchedResultsChangeUpdate (object)");
           [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeMove:
            NSLog(@"*** NSFetchedResultsChangeMove (object)");
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        default:
            break;
    }
}

-(void)controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        default:
            break;
    }
}

-(void) controllerDidChangeContent:(NSFetchedResultsController *)controller {
    NSLog(@"*** Controller did change content");
    [self.tableView endUpdates];
}


-(void)dealloc {
    _fetchResultsController.delegate = nil;
}

@end
