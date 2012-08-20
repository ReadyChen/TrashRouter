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
#import <CFNetwork/CFNetwork.h>
#import <iAd/iAd.h>

#import "SKPSMTPMessage.h"
#import "Reachability.h"

@class KMLPlacemark;
@class Reachability;

@interface ViewController : UIViewController <NSXMLParserDelegate,MKMapViewDelegate,CLLocationManagerDelegate,SKPSMTPMessageDelegate> {
    IBOutlet MKMapView *mapView;
    NSXMLParser *xmlParser;
    IBOutlet UISlider *mySlider;
    IBOutlet UILabel *lblSlider;
    NSMutableArray *_placemarks;
    KMLPlacemark *_placemark;
    IBOutlet UIButton *btnAdjust;
    IBOutlet UIButton *btnAdjustBack;
    IBOutlet UIButton *btnAdjustCurr;
    IBOutlet UIButton *btnAdjustSubmit;
    IBOutlet UIToolbar *toolbar;
    IBOutlet UIActivityIndicatorView *AlphaActivityIndicatorView;
    IBOutlet UIImageView *AlphaImageView;
    IBOutlet UILabel *lblAlphaStatus;
    IBOutlet UIButton *btnAbout;
    ADBannerView *adView;
    Reachability* internetReach;
}

@property(assign, nonatomic) IBOutlet MKMapView *mapView;
@property(assign, nonatomic) NSXMLParser *xmlParser;
@property (nonatomic, retain) IBOutlet UISlider *mySlider;
@property (nonatomic, retain) IBOutlet UILabel *lblSlider;
@property (nonatomic, retain) NSMutableArray *_placemarks;
@property (nonatomic, retain) KMLPlacemark *_placemark;
@property (nonatomic, retain) IBOutlet UIButton *btnAdjust;
@property (nonatomic, retain) IBOutlet UIButton *btnAdjustBack;
@property (nonatomic, retain) IBOutlet UIButton *btnAdjustCurr;
@property (nonatomic, retain) IBOutlet UIButton *btnAdjustSubmit;
@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *AlphaActivityIndicatorView;
@property (nonatomic, retain) IBOutlet UIImageView *AlphaImageView;
@property (nonatomic, retain) IBOutlet UILabel *lblAlphaStatus;
@property (nonatomic, retain) IBOutlet UIButton *btnAbout;
@property (nonatomic, assign)BOOL adViewIsVisible;
@property (nonatomic, retain)IBOutlet ADBannerView *adView;
@property (nonatomic, retain)Reachability* internetReach;


@end
