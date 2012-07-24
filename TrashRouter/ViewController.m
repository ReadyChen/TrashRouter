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
#import "DDAnnotation.h"

#import "SKPSMTPMessage.h"
#import "NSData+Base64Additions.h"

#define FBOX(x) [NSNumber numberWithFloat:x]
#define ELTYPE(typeName) (NSOrderedSame == [elementName caseInsensitiveCompare:@#typeName])

//@interface ViewController ()
//@end

@implementation ViewController

@synthesize mapView;
@synthesize xmlParser,mySlider,lblSlider;
@synthesize _placemarks,_placemark;
@synthesize btnAdjust,btnAdjustBack,btnAdjustSubmit;
@synthesize toolbar;

MKAnnotationView * AnnotationViewToAdjust = nil;
DDAnnotation *annotationAdjust;
NSInteger iSliderValue = 0;
NSInteger iScreenStatus = 0;

-(IBAction)reportAdjust:(UIButton *)sender{
    NSLog(@" reportAdjust press");
    
	CLLocationCoordinate2D theCoordinate;
	theCoordinate.latitude = AnnotationViewToAdjust.annotation.coordinate.latitude;
    theCoordinate.longitude = AnnotationViewToAdjust.annotation.coordinate.longitude;
    
	annotationAdjust = [[[DDAnnotation alloc] initWithCoordinate:theCoordinate addressDictionary:nil] autorelease];
	annotationAdjust.title = AnnotationViewToAdjust.annotation.title;
	annotationAdjust.subtitle = AnnotationViewToAdjust.annotation.subtitle;
	
    // display PIN to Draggable for Adjust.
	[self.mapView addAnnotation:annotationAdjust];
    
    // remove all KMLPlacemark
    for(KMLPlacemark *placemark in _placemarks){
        MyAnnotation *TmpAnnotation = placemark.annotation;
        [mapView removeAnnotation:TmpAnnotation];
    }
    
    // renew UI.
    btnAdjust.hidden = YES;
    btnAdjustBack.hidden = NO;
    btnAdjustSubmit.hidden = NO;
    
    toolbar.hidden = YES;
    iScreenStatus = 1;
}

-(IBAction)reportAdjustBack:(UIButton *)sender{
    
    // remove Adjust Pin.
    if(annotationAdjust)
    {
        [mapView removeAnnotation:annotationAdjust];
        annotationAdjust = nil;
    }
    
    // display KMLPlacement.
    for(KMLPlacemark *placemark in _placemarks){
        
        //NSString *strTmpName = placemark.name;
        MyAnnotation *TmpAnnotation = placemark.annotation;
        NSInteger iTmpStartTime = placemark.iStartTime;
        NSInteger iTmpEndTime = placemark.iEndTime;
        //NSInteger iTmpStatus = placemark.iStatus;
        
        NSInteger iNewStatus = ePASS;
        if(iSliderValue >= iTmpStartTime && iSliderValue <= iTmpEndTime){
            iNewStatus = ePRESENT;
        }
        if(iSliderValue < iTmpStartTime && iSliderValue < iTmpEndTime){
            iNewStatus = eLATER;
        }
        
        //if(iNewStatus != iTmpStatus)
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
    
    // renew UI.
    btnAdjust.hidden = YES;
    btnAdjustBack.hidden = YES;
    btnAdjustSubmit.hidden = YES;
    
    toolbar.hidden = NO;
    iScreenStatus = 0;
    
}
-(IBAction)reportAdjustSubmit:(UIButton *)sender{
    
    // Send new coordated to auther.
    SKPSMTPMessage *testMsg = [[SKPSMTPMessage alloc] init];
    testMsg.fromEmail = @"ready.chen22@gmail.com";
    testMsg.toEmail = @"ready.chen@hotmail.com";
    testMsg.relayHost = @"smtp.gmail.com";
    testMsg.requiresAuth = YES;
    testMsg.login = @"ready.chen22@gmail.com";
    testMsg.pass = @"QCA5355Gd";
    testMsg.subject = @"test message";
    //testMsg.bccEmail = @"testbcc@test.com";
    testMsg.wantsSecure = YES; // smtp.gmail.com doesn't work without TLS!
    
    // Only do this for self-signed certs!
    // testMsg.validateSSLChain = NO;
    testMsg.delegate = self;
    
    NSString *newCoordinate = [NSString stringWithFormat:@"%f,%f",annotationAdjust.coordinate.latitude,annotationAdjust.coordinate.longitude];
    
    NSString *strMailBody = [[NSString alloc] initWithString:@"Mail Body"];
    strMailBody = [strMailBody stringByAppendingString:@"\r\n"];
    strMailBody = [strMailBody stringByAppendingString:annotationAdjust.title];
    strMailBody = [strMailBody stringByAppendingString:@"\r\n"];
    strMailBody = [strMailBody stringByAppendingString:annotationAdjust.subtitle];
    strMailBody = [strMailBody stringByAppendingString:@"\r\n"];
    strMailBody = [strMailBody stringByAppendingString:newCoordinate];
    
    //NSDictionary *plainPart = [NSDictionary dictionaryWithObjectsAndKeys:@"text/plain",kSKPSMTPPartContentTypeKey,
    //                           @"This is a tést messåge.",kSKPSMTPPartMessageKey,@"8bit",kSKPSMTPPartContentTransferEncodingKey,nil];
    NSDictionary *plainPart = [NSDictionary dictionaryWithObjectsAndKeys:@"text/plain",kSKPSMTPPartContentTypeKey,
                               strMailBody,kSKPSMTPPartMessageKey,@"8bit",kSKPSMTPPartContentTransferEncodingKey,nil];
    
    NSString *vcfPath = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"vcf"];
    NSData *vcfData = [NSData dataWithContentsOfFile:vcfPath];
    
    NSDictionary *vcfPart = [NSDictionary dictionaryWithObjectsAndKeys:@"text/directory;\r\n\tx-unix-mode=0644;\r\n\tname=\"test.vcf\"",kSKPSMTPPartContentTypeKey,
                             @"attachment;\r\n\tfilename=\"test.vcf\"",kSKPSMTPPartContentDispositionKey,[vcfData encodeBase64ForData],kSKPSMTPPartMessageKey,@"base64",kSKPSMTPPartContentTransferEncodingKey,nil];
    
    testMsg.parts = [NSArray arrayWithObjects:plainPart,vcfPart,nil];
    
    [testMsg send];
}

- (void)messageSent:(SKPSMTPMessage *)message
{
    [message release];
    
    NSLog(@"delegate - message sent");
}

- (void)messageFailed:(SKPSMTPMessage *)message error:(NSError *)error
{
    [message release];
    
    NSLog(@"delegate - error(%d): %@", [error code], [error localizedDescription]);
}

- (IBAction) sliderValueChanged:(UISlider *)sender{
    
    // remove Adjust Pin.
    if(annotationAdjust)
    {
        [mapView removeAnnotation:annotationAdjust];
        annotationAdjust = nil;
    }
    
    // renew UI.
    btnAdjust.hidden = YES;
    btnAdjustBack.hidden = YES;
    btnAdjustSubmit.hidden = YES;
    
    mySlider.enabled = YES;
    
    // display KMLPlacement.
    NSInteger iValue = [sender value];
    iSliderValue = iValue;
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
    
    btnAdjust.hidden = YES;
    btnAdjustBack.hidden = YES;
    btnAdjustSubmit.hidden = YES;

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

- (void)mapView:(MKMapView *)mapview didAddAnnotationViews:(NSArray *)views{
    for (id<MKAnnotation> currentAnnotation in mapview.annotations) {       
        if ([currentAnnotation isEqual: annotationAdjust]) {
            [mapview selectAnnotation:currentAnnotation animated:YES];
        }
    }
}

-(void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    AnnotationViewToAdjust = view;
    if(iScreenStatus==0)// == 1 don't change btnAdjust hidden to NO.
    {
        btnAdjust.hidden = FALSE;
    }
}
-(void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view
{
    btnAdjust.hidden = TRUE;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)annotationView didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState {
	
	if (oldState == MKAnnotationViewDragStateDragging) {
		DDAnnotation *annotation = (DDAnnotation *)annotationView.annotation;
		annotation.subtitle = [NSString	stringWithFormat:@"%f %f", annotation.coordinate.latitude, annotation.coordinate.longitude];
        
        btnAdjust.hidden = YES;
        btnAdjustBack.hidden = NO;
        btnAdjustSubmit.hidden = NO;
	}
}

- (MKAnnotationView *)mapView:(MKMapView *)theMapView viewForAnnotation:(id <MKAnnotation>)annotation{
    if ([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
    
    if ([annotation isKindOfClass:[MyAnnotation class]]){
        static NSString *MyAnnotationIdentifier = @"PinIdentifier";
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
            
            //UIImage *imageIcon = [UIImage imageNamed:@"scooterIcon.png"];
            //myPinView.image = imageIcon;

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
    
    static NSString * const kPinAnnotationIdentifier = @"PinIdentifier";
    MKPinAnnotationView *annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:kPinAnnotationIdentifier];
    annotationView.draggable = YES;
    annotationView.canShowCallout = YES;
    annotationView.pinColor = MKPinAnnotationColorGreen;
    return [annotationView autorelease];

}

@end
