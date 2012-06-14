//
//  ViewController.m
//  TrashRouter
//
//  Created by readyair on 12/5/29.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"
#import "TrashPoint.h"
#import "MyAnnotation.h"

#define FBOX(x) [NSNumber numberWithFloat:x]
#define ELTYPE(typeName) (NSOrderedSame == [elementName caseInsensitiveCompare:@#typeName])

//@interface ViewController ()
//@end

@implementation ViewController

@synthesize mapView;
@synthesize xmlParser,mySlider,lblSlider;
@synthesize _placemarks,_placemark;

- (IBAction) sliderValueChanged:(UISlider *)sender{
    NSInteger iValue = [sender value];
    NSString *strTmp = [NSString stringWithFormat:@"%i:%02i", (iValue/60), iValue%60 ];
    lblSlider.text = strTmp;

    for(KMLPlacemark *placemark in _placemarks){
        
        NSString *strTmpName = placemark.name;
        MyAnnotation *TmpAnnotation = placemark.annotation;
        NSInteger iTmpStartTime = placemark.iStartTime;
        NSInteger iTmpEndTime = placemark.iEndTime;
        NSInteger iTmpStatus = placemark.iStatus;
        
        NSInteger iNewStatus = ePASS;
        if(iValue >= iTmpStartTime && iValue <= iTmpEndTime){
            iNewStatus = ePRESENT;
        }
        if(iValue < iTmpStartTime && iValue < iTmpEndTime){
            iNewStatus = eLATER;
        }
        
        if(0)
        {
            NSLog(@"<Placemark>");
            NSLog(@"   <Name>%@</Name>", strTmpName);
            NSLog(@"   <Coordinates>%f,%f</Coordinates>", TmpAnnotation->myCoordinate.longitude, TmpAnnotation->myCoordinate.latitude);
            NSLog(@"   <StayTime>%i,%i</StayTime>", iTmpStartTime, iTmpEndTime);
            NSLog(@"</Placemark>");
            NSLog(@" ");
        }
         
        if(iNewStatus != iTmpStatus)
        {
            switch(iNewStatus){
                case ePASS:
                    [mapView removeAnnotation:TmpAnnotation];
                    placemark.iStatus = ePASS;
                    break;
                case ePRESENT:
                    [mapView removeAnnotation:TmpAnnotation];
                    TmpAnnotation.iPinColor = MKPinAnnotationColorRed;
                    [mapView addAnnotation:TmpAnnotation];
                    placemark.iStatus = ePRESENT;
                    break;
                case eLATER:
                    [mapView removeAnnotation:TmpAnnotation];
                    TmpAnnotation.iPinColor = MKPinAnnotationColorPurple;
                    [mapView addAnnotation:TmpAnnotation];
                    placemark.iStatus = eLATER;
                    break;
            }
        }
    }
}

- (IBAction)btn1:(id)sender{
    NSLog(@"btn");

}

- (void) MyFunc:(NSString *)strTmp{
    NSLog(@"Teijsd = %@",strTmp);
}

- (void) InitXmlParser{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"NK113" ofType:@"xml"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    xmlParser = [[NSXMLParser alloc] initWithData:data];
    _placemarks = [[NSMutableArray alloc] init];
    
    [xmlParser setDelegate:self];
    [xmlParser parse];
    [xmlParser release];
}

-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    //for(id key in attributeDict)
    //{
    //    NSLog(@"attribute %@", [attributeDict objectForKey:key]);
    //}
    
    NSString *ident = [attributeDict objectForKey:@"id"];
    if (ELTYPE(Placemark)) {
        _placemark = [[KMLPlacemark alloc] initWithIdentifier:ident];
        [_placemark beginPlacemark];
    } else if (ELTYPE(Name)) {
        [_placemark beginName];
    } else if (ELTYPE(Coordinates)) {
        [_placemark beginCoordi];
    } else if (ELTYPE(Address)) {
        [_placemark beginAddress];
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    [_placemark addString:string];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if (ELTYPE(Placemark)) {
        if (_placemark) {
            [_placemarks addObject:_placemark];
            [_placemark endPlacemark];
            [_placemark release];
            _placemark = nil;
        }
    } else if (ELTYPE(Name)) {
        [_placemark endName];
    } else if (ELTYPE(Coordinates)) {
        [_placemark endCoordi];
    } else if (ELTYPE(Address)) {
        [_placemark endAddress];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // Init Xml Parser
    [self InitXmlParser];
    
    mapView.delegate = self;
    mapView.showsUserLocation = YES;

    // get Current Location
    CLLocationManager *locationManager;
    locationManager = [[CLLocationManager alloc] init];
    locationManager.distanceFilter = kCLDistanceFilterNone; // whenever we move
    locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters; // 100 m
    [locationManager startUpdatingLocation];

    // Display Map Region  
    MKCoordinateRegion userCurrentRegion;
    userCurrentRegion.center.latitude = locationManager.location.coordinate.latitude;
    userCurrentRegion.center.longitude = locationManager.location.coordinate.longitude;
    userCurrentRegion.span.latitudeDelta = 0.05;
    userCurrentRegion.span.longitudeDelta = 0.05;
    [mapView setRegion:userCurrentRegion animated:YES];

}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (MKAnnotationView *)mapView:(MKMapView *)theMapView viewForAnnotation:(id <MKAnnotation>)annotation{
    if ([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
    
    if ([annotation isKindOfClass:[MyAnnotation class]]){
        static NSString *MyAnnotationIdentifier = @"myAnnotation";
        MKPinAnnotationView *pinView = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:MyAnnotationIdentifier];

        NSInteger iPinColor = [annotation getPinColor];
        if (!pinView){
            MKPinAnnotationView* myPinView = [[[MKPinAnnotationView alloc]initWithAnnotation:annotation reuseIdentifier:MyAnnotationIdentifier] autorelease];

            if(0)
            {
                BOOL bAnimatesDrop = NO;
                if(iPinColor==MKPinAnnotationColorRed)
                {
                    bAnimatesDrop = YES;
                }
                myPinView.animatesDrop = bAnimatesDrop;
            }
            NSLog(@"Pass here");
            myPinView.pinColor = iPinColor;
            myPinView.canShowCallout = YES;
            myPinView.draggable = YES;
            return myPinView;
        }else{
            if(0)
            {
                BOOL bAnimatesDrop = NO;
                if(iPinColor==MKPinAnnotationColorRed)
                {
                    bAnimatesDrop = YES;
                }
                pinView.animatesDrop = bAnimatesDrop;
            }
            pinView.pinColor = iPinColor;
            pinView.canShowCallout = YES;
            pinView.draggable = YES;
            return pinView;
        }
    }
    
    return nil;
}

@end
