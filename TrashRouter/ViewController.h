//
//  ViewController.h
//  TrashRouter
//
//  Created by readyair on 12/5/29.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

@class KMLPlacemark;

@interface ViewController : UIViewController <NSXMLParserDelegate,MKMapViewDelegate,CLLocationManagerDelegate> {
    IBOutlet MKMapView *mapView;
    NSXMLParser *xmlParser;
    IBOutlet UISlider *mySlider;
    IBOutlet UILabel *lblSlider;
    NSMutableArray *_placemarks;
    KMLPlacemark *_placemark;
}

@property(assign, nonatomic) IBOutlet MKMapView *mapView;
@property(assign, nonatomic) NSXMLParser *xmlParser;
@property (nonatomic, retain) IBOutlet UISlider *mySlider;
@property (nonatomic, retain) IBOutlet UILabel *lblSlider;
@property (nonatomic, retain) NSMutableArray *_placemarks;
@property (nonatomic, retain) KMLPlacemark *_placemark;

- (IBAction) sliderValueChanged:(id)sender;
- (void) MyFunc:(NSString *)strTmp;

@end
