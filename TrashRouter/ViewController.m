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

@implementation ViewController

@synthesize mapView;
@synthesize xmlParser,mySlider,lblSlider;
@synthesize _placemarks,_placemark;
@synthesize btnAdjust,btnAdjustBack,btnAdjustCurr,btnAdjustSubmit,btnAbout;
@synthesize toolbar;
@synthesize AlphaActivityIndicatorView,AlphaImageView,lblAlphaStatus;
@synthesize internetReach;
@synthesize adBannerView = _adBannerView;
@synthesize adBannerViewIsVisible = _adBannerViewIsVisible;

CLLocationCoordinate2D taipeiCenterCoordinate; // define Taipei Center Coordinate.
CLLocationManager *locationManager; // use for user current Location.
MKAnnotationView * AnnotationViewToAdjust = nil; // remember user selected annotation in main screen.
DDAnnotation *annotationAdjust; // only use in Adjust screen, display annotation for drag and drog.
NSInteger iSliderValue = 0; // remember SlderValue for user back from Adjust to main screen.
NSInteger iScreenStatus = 0; // remember user screen status. 0=main,1=Adjust,2=unuse.
NSTimer *AlphaTimer; // timer ticker for close "alpha imageview layer".
NSTimer *HHMMTimer; // for display user time 1 sec. when out of slider range min~max(HH*60+MM).


//=============================
//
//
//      UI Area
//
//
//=============================

-(IBAction)clickbyAbout:(UIButton *)sender{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://sites.google.com/site/taipeitrashpoints/"]];
}

-(IBAction)clickAdjust:(UIButton *)sender{
    
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
    btnAdjustCurr.hidden = ![locationManager locationServicesEnabled];
    btnAdjustSubmit.hidden = NO;
    btnAbout.hidden = NO;
    lblSlider.hidden = YES;
    
    toolbar.hidden = YES;
    iScreenStatus = 1;
}

-(IBAction)clickAdjustBack:(UIButton *)sender{
    
    // remove Adjust Pin. user back to main screen.
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
    btnAdjustCurr.hidden = YES;
    btnAdjustSubmit.hidden = YES;
    btnAbout.hidden = YES;
    lblSlider.hidden = NO;
    
    toolbar.hidden = NO;
    iScreenStatus = 0;
}

-(IBAction)clickAdjustCurr:(UIButton *)sender{
    // check if location service ternned off.
    if(![locationManager locationServicesEnabled])
        return;
    
    // set Curr Coordi to annotationAdjust.
    annotationAdjust.coordinate = locationManager.location.coordinate;
    
    // renew annotationAdjust title.
    NSString *strTmp = annotationAdjust.title;
    strTmp = [strTmp substringToIndex:11];
    annotationAdjust.title = [NSString stringWithFormat:@"%@ %f,%f", strTmp, annotationAdjust.coordinate.latitude, annotationAdjust.coordinate.longitude];
    
    // renew UI
    [mapView setCenterCoordinate:locationManager.location.coordinate animated:YES];
}

-(IBAction)clickAdjustSubmit:(UIButton *)sender{
    
    NSInteger iLength = [annotationAdjust.title length];
    if(iLength < 12)
    {
        // renew UI. reject Submit.
        lblAlphaStatus.text = @"請拖曳綠色大頭針";
        lblAlphaStatus.hidden = NO;
        AlphaImageView.hidden = NO;
        
        btnAdjustBack.enabled = NO;
        btnAdjustCurr.enabled = NO;
        btnAdjustSubmit.enabled = NO;
        btnAbout.enabled = NO;
        
        // trigger Submited UI timer.
        AlphaTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(AlphaTimerFunc) userInfo:nil repeats:YES];
        
        return;
    }

    // Send new coordated to auther.
    SKPSMTPMessage *testMsg = [[SKPSMTPMessage alloc] init];
    testMsg.fromEmail = @"ready.chen33@gmail.com";
    testMsg.toEmail = @"ready.chen22@gmail.com";
    testMsg.relayHost = @"smtp.gmail.com";
    testMsg.requiresAuth = YES;
    testMsg.login = @"ready.chen33@gmail.com";
    testMsg.pass = @"hedoni88";
    testMsg.subject = @"User Adjust";
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
    
    // if you want to attach any file. open this function.
    if(0)
    {
        NSString *vcfPath = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"vcf"];
        NSData *vcfData = [NSData dataWithContentsOfFile:vcfPath];
    
        NSDictionary *vcfPart = [NSDictionary dictionaryWithObjectsAndKeys:@"text/directory;\r\n\tx-unix-mode=0644;\r\n\tname=\"test.vcf\"",kSKPSMTPPartContentTypeKey,
                             @"attachment;\r\n\tfilename=\"test.vcf\"",kSKPSMTPPartContentDispositionKey,[vcfData encodeBase64ForData],kSKPSMTPPartMessageKey,@"base64",kSKPSMTPPartContentTransferEncodingKey,nil];
        
        testMsg.parts = [NSArray arrayWithObjects:plainPart,vcfPart,nil];
    }
    
    testMsg.parts = [NSArray arrayWithObjects:plainPart,nil];
    
    [testMsg send];
    
    // renew UI.
    lblAlphaStatus.text = @"發送中...";
    [AlphaActivityIndicatorView startAnimating];
    
    AlphaActivityIndicatorView.hidden= NO;
    lblAlphaStatus.hidden = NO;
    AlphaImageView.hidden = NO;
    
    btnAdjustBack.enabled = NO;
    btnAdjustCurr.enabled = NO;
    btnAdjustSubmit.enabled = NO;
    btnAbout.enabled = NO;
}

- (void)messageSent:(SKPSMTPMessage *)message
{
    [message release];
    
    //NSLog(@"delegate - message sent");
    
    // renew UI.
    lblAlphaStatus.text = @"已完成,謝謝";
    [AlphaActivityIndicatorView stopAnimating];
    
    // trigger Submited UI timer.
    AlphaTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(AlphaTimerFunc) userInfo:nil repeats:YES];
}

- (void)messageFailed:(SKPSMTPMessage *)message error:(NSError *)error
{
    [message release];
    
    //NSLog(@"delegate - error(%d): %@", [error code], [error localizedDescription]);
    
    // renew UI.
    lblAlphaStatus.text = @"伺服器錯誤";
    [AlphaActivityIndicatorView stopAnimating];
    
    // trigger Submited UI timer.
    AlphaTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(AlphaTimerFunc) userInfo:nil repeats:YES];
}

NSInteger iTimerCountDown = 3;
-(void) AlphaTimerFunc{
    
    // Display iTimerCounDown time pass with append to char @"."
    lblAlphaStatus.text = [NSString stringWithFormat:@"%@%@",lblAlphaStatus.text, @"."];
    
    if(iTimerCountDown==0)
    {
        // renew UI.
        AlphaActivityIndicatorView.hidden= YES;
        lblAlphaStatus.hidden = YES;
        AlphaImageView.hidden = YES;
        
        btnAdjustBack.enabled = YES;
        btnAdjustCurr.enabled = YES;
        btnAdjustSubmit.enabled = YES;
        btnAbout.enabled = YES;
        
        // reset timer
        [AlphaTimer invalidate];
        AlphaTimer = nil;
        iTimerCountDown = 3;
    }
    else {
        // Count Down.
        iTimerCountDown--;
    }
}

- (IBAction) sliderValueChanged:(UISlider *)sender{
    
    // remember Slider value.
    iSliderValue = [sender value];
    
    // renew HHMM.
    [self UpdateHHMM:iSliderValue];
    
    // renew KMLPlacement.
    [self UpdatePlacemark];
}

- (IBAction)clickSetCurr:(id)sender{
    
    // get System YMD W HMS
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDate *now;
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    NSInteger unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSWeekdayCalendarUnit | \
    NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
    
    now=[NSDate date];
    comps = [calendar components:unitFlags fromDate:now];
    
    NSInteger year=[comps year];
    NSInteger week = [comps weekday];   
    NSInteger month = [comps month];
    NSInteger day = [comps day];
    NSInteger hour = [comps hour];
    NSInteger min = [comps minute];
    NSInteger sec = [comps second];
    
    //NSLog(@"%4d/%02d/%02d (%d) %02d:%02d:%02d", year,month,day,week,hour,min,sec);
    
    NSInteger iTmpValue = hour*60+min;
    
    // renew Slider & HHMM
    if ( iTmpValue < mySlider.minimumValue ) {
        [self UpdateHHMM:iTmpValue];
        lblSlider.textColor = [UIColor blackColor];
        HHMMTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(HHMMTimerFunc) userInfo:nil repeats:NO];
        mySlider.value = mySlider.minimumValue;
        iSliderValue = mySlider.value;
    } else if ( iTmpValue > mySlider.maximumValue ) {
        [self UpdateHHMM:iTmpValue];
        lblSlider.textColor = [UIColor blackColor];
        HHMMTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(HHMMTimerFunc) userInfo:nil repeats:NO];
        mySlider.value = mySlider.maximumValue;
        iSliderValue = mySlider.value;
    } else {
        mySlider.value = iTmpValue;
        iSliderValue = mySlider.value;
        [self UpdateHHMM:iSliderValue];
    }
    
    // renew KMLPlacement.
    [self UpdatePlacemark];
    
    // renew mapview setCenterCoordinate
    if( [locationManager locationServicesEnabled] ){
        [mapView setCenterCoordinate:locationManager.location.coordinate animated:YES];
    }
    else {
        // if can't get System Current Location. Do not set any new coordi.
    }
}

-(void)HHMMTimerFunc{
    // renew HHMM.
    [self UpdateHHMM:iSliderValue];
    lblSlider.textColor = [UIColor redColor];
    
    // reset timer
    [HHMMTimer invalidate];
    HHMMTimer = nil;
}

-(void)UpdateHHMM:(NSInteger)iValue
{
    NSString *strTmp = [NSString stringWithFormat:@"%i:%02i", (iValue/60), iValue%60 ];
    lblSlider.text = strTmp;
}

-(void)UpdatePlacemark
{
    for(KMLPlacemark *placemark in _placemarks){
        
        NSString *strTmpName = placemark.name;
        MyAnnotation *TmpAnnotation = placemark.annotation;
        NSInteger iTmpStartTime = placemark.iStartTime;
        NSInteger iTmpEndTime = placemark.iEndTime;
        NSInteger iTmpStatus = placemark.iStatus;
        
        NSInteger iNewStatus = ePASS;
        if(iSliderValue >= iTmpStartTime && iSliderValue <= iTmpEndTime){
            iNewStatus = ePRESENT;
        }
        if(iSliderValue < iTmpStartTime && iSliderValue < iTmpEndTime){
            iNewStatus = eLATER;
        }
        
        if(0)
        {
            //NSLog(@"<Placemark>");
            //NSLog(@"   <Name>%@</Name>", strTmpName);
            //NSLog(@"   <Coordinates>%f,%f</Coordinates>", TmpAnnotation->myCoordinate.longitude, TmpAnnotation->myCoordinate.latitude);
            //NSLog(@"   <StayTime>%i,%i</StayTime>", iTmpStartTime, iTmpEndTime);
            //NSLog(@"</Placemark>");
            //NSLog(@" ");
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


//=============================
//
//
//      banner Area
//
//
//=============================

- (int)getBannerHeight {
    CGFloat adbannerHeight = [_adBannerView frame].size.height;
    //NSLog(@" adbannerHeight %f", adbannerHeight);
    return (int)adbannerHeight;
}

- (void)createAdBannerView {
    //NSLog(@" createAdBannerView");
    Class classAdBannerView = NSClassFromString(@"ADBannerView");
    if (classAdBannerView != nil) {
        //self.adBannerView = [[[classAdBannerView alloc] initWithFrame:CGRectZero] autorelease];
        //self.adBannerView = [[[classAdBannerView alloc] initWithFrame:CGRectMake(0, 400+[self getBannerHeight], 0, 0)] autorelease];
        self.adBannerView = [[[classAdBannerView alloc] initWithFrame:CGRectMake(0, 480, 0, 0)] autorelease];
        [_adBannerView setRequiredContentSizeIdentifiers:[NSSet setWithObjects: ADBannerContentSizeIdentifierPortrait, ADBannerContentSizeIdentifierLandscape, nil]];
        if (UIInterfaceOrientationIsLandscape([UIDevice currentDevice].orientation)) {
            [_adBannerView setCurrentContentSizeIdentifier:ADBannerContentSizeIdentifierLandscape];
        } else {
            [_adBannerView setCurrentContentSizeIdentifier:ADBannerContentSizeIdentifierPortrait];
        }
        //[_adBannerView setFrame:CGRectOffset([_adBannerView frame], 0, 400+[self getBannerHeight])];
        [_adBannerView setFrame:CGRectOffset([_adBannerView frame], 0, 480)];
        [_adBannerView setDelegate:self];
        
        [self.view addSubview:_adBannerView];
    }
}

- (void)fixupAdView:(UIInterfaceOrientation)toInterfaceOrientation {
    //NSLog(@" fixupAdView %d", toInterfaceOrientation);
    if (_adBannerView != nil) {
        if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
            [_adBannerView setCurrentContentSizeIdentifier:ADBannerContentSizeIdentifierLandscape];
        } else {
            [_adBannerView setCurrentContentSizeIdentifier:ADBannerContentSizeIdentifierPortrait];
        }
        [UIView beginAnimations:@"fixupViews" context:nil];
        if (_adBannerViewIsVisible) {
            // 彈出來
            CGRect adBannerViewFrame = [_adBannerView frame];
            adBannerViewFrame.origin.x = 0;
            adBannerViewFrame.origin.y = [self getScreenHeight:toInterfaceOrientation]-64-[self getBannerHeight];
            [_adBannerView setFrame:adBannerViewFrame];
        } else {
            // 縮起來
            CGRect adBannerViewFrame = [_adBannerView frame];
            adBannerViewFrame.origin.x = 0;
            adBannerViewFrame.origin.y = [self getScreenHeight:toInterfaceOrientation];
            [_adBannerView setFrame:adBannerViewFrame];
        }
        [UIView commitAnimations];
    }
}

-(CGFloat)getScreenHeight:(UIInterfaceOrientation)toInterfaceOrientation {
    
    CGRect screenBound = [[UIScreen mainScreen] bounds];
    CGSize screenSize = screenBound.size;
    
    //CGFloat toolbarHeight = [toolbar frame].size.height;
    //CGFloat adbannerHeight = [_adBannerView frame].size.height;
    //NSLog(@" %f, %f, %f, %f", screenSize.width, screenSize.height, toolbarHeight, adbannerHeight);
    
    if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
        return screenSize.width;
    }
    else
    {
        return screenSize.height;
    }
}

#pragma mark ADBannerViewDelegate

- (void)bannerViewDidLoadAd:(ADBannerView *)banner {
    //NSLog(@" bannerViewDidLoadAd");
    
    if (!_adBannerViewIsVisible) {
        _adBannerViewIsVisible = YES;
        //NSLog(@" _adBannerViewIsVisible = YES");
        [self fixupAdView:[UIDevice currentDevice].orientation];
    }
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    //NSLog(@"ad didFailToReceiveAdWithError  Error:%@", error);
    if (_adBannerViewIsVisible)
    {
        _adBannerViewIsVisible = NO;
        //NSLog(@" _adBannerViewIsVisible = NO");
        [self fixupAdView:[UIDevice currentDevice].orientation];
    }
}

- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)abanner willLeaveApplication:(BOOL)willLeave {
    //NSLog(@"ad should begin");
    return YES;
}

- (void)bannerViewActionDidFinish:(ADBannerView *)abanner {
    //NSLog(@"ad did finish");
}


//=============================
//
//
//      reachability Area
//
//
//=============================
- (void) updateInterfaceWithReachability: (Reachability*) curReach
{
    NetworkStatus netStatus = [curReach currentReachabilityStatus];
    NSString* statusString= @"";
    switch (netStatus)
    {
        case NotReachable:
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"網路不存在"
                                                            message:@"需要網路連線的存在，功能才能完整"
                                                           delegate:self
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"明白了", nil];
            alert.cancelButtonIndex = -1;
            [alert show];
            [alert release];
            
            statusString = @"Access Not Available";
            break;
        }
            
        case ReachableViaWWAN:
        {
            statusString = @"Reachable WWAN";
            break;
        }
        case ReachableViaWiFi:
        {
            statusString= @"Reachable WiFi";
            break;
        }
    }
    //NSLog(@" internet status = [%@]", statusString);
}

//Called by Reachability whenever status changes.
- (void) reachabilityChanged: (NSNotification* )note
{
	Reachability* curReach = [note object];
	NSParameterAssert([curReach isKindOfClass: [Reachability class]]);
	[self updateInterfaceWithReachability: curReach];
}



//=============================
//
//
//      xml Area
//
//
//=============================

- (void) InitXmlParser{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"TPE4133" ofType:@"xml"];
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
    //    //NSLog(@"attribute %@", [attributeDict objectForKey:key]);
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




//=============================
//
//
//      view Area
//
//
//=============================

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    
    // 初始化ADBannerView
    [self createAdBannerView];
    
    // Observe the kNetworkReachabilityChangedNotification. When that notification is posted, the
    // method "reachabilityChanged" will be called.
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(reachabilityChanged:) name: kReachabilityChangedNotification object: nil];
    
    internetReach = [[Reachability reachabilityForInternetConnection] retain];
    [internetReach startNotifier];
    [self updateInterfaceWithReachability: internetReach];

    
    // Init Data.
    taipeiCenterCoordinate.latitude = 25.048533;
    taipeiCenterCoordinate.longitude = 121.541343;
    
    // Init Xml Parser
    [self InitXmlParser];
    
    mapView.delegate = self;
    mapView.showsUserLocation = YES;

    // get System Current Location
    locationManager = [[CLLocationManager alloc] init];
    locationManager.distanceFilter = kCLDistanceFilterNone; // whenever we move
    locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters; // 100 m
    [locationManager startUpdatingLocation];

    // Display Map Region
    MKCoordinateRegion userCurrentRegion;
    //if( [locationManager locationServicesEnabled] )
    userCurrentRegion.center.latitude = locationManager.location.coordinate.latitude;
    userCurrentRegion.center.longitude = locationManager.location.coordinate.longitude;
    userCurrentRegion.span.latitudeDelta = 0.005;
    userCurrentRegion.span.longitudeDelta = 0.005;
    if(userCurrentRegion.center.latitude==0||userCurrentRegion.center.longitude==0)
    {
        // if can't get System Current Location. display Defined Taipei Center.
        userCurrentRegion.center.latitude = taipeiCenterCoordinate.latitude;
        userCurrentRegion.center.longitude = taipeiCenterCoordinate.longitude;
    }
    [mapView setRegion:userCurrentRegion animated:YES];
    
    // renew UI.
    btnAdjust.hidden = YES;
    btnAdjustBack.hidden = YES;
    btnAdjustCurr.hidden = YES;
    btnAdjustSubmit.hidden = YES;
    btnAbout.hidden = YES;
    
    AlphaActivityIndicatorView.hidden= YES;
    [AlphaActivityIndicatorView stopAnimating];
    lblAlphaStatus.hidden = YES;
    AlphaImageView.hidden = YES;
    
    [self clickSetCurr:(id)nil];
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
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    //NSLog(@"ad rotate to %d", toInterfaceOrientation);
    [self fixupAdView:toInterfaceOrientation];
}

- (void)dealloc {
    //self.adBannerView = nil;
    [super dealloc];
}




//=============================
//
//
//      Map View Area
//
//
//=============================


- (void)mapView:(MKMapView *)mapview didAddAnnotationViews:(NSArray *)views{
    for (id<MKAnnotation> currentAnnotation in mapview.annotations) {
        if ([currentAnnotation isEqual: annotationAdjust]) {
            [mapview selectAnnotation:currentAnnotation animated:YES];
        }
    }
}

//annotation Select event.
-(void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    // Remenber annotation been select to AnnotationViewToAdjust.
    AnnotationViewToAdjust = view;
    
    // iScreenStatus == 0 mean user in Main Screen. Display Adjust btn when Pin select.
    // iScreenStatus == 1 mean user in Adjust Screen. Display
    if(iScreenStatus==0)// == 1 don't change btnAdjust hidden to NO.
    {
        btnAdjust.hidden = NO;
    }
    
    // Don't display btnAdjust when user select THE pin "Current Location".
    //if([view.annotation.title isEqualToString:@"Current Location"])
    if ([view.annotation isKindOfClass:[MKUserLocation class]]) 
    {
        btnAdjust.hidden = YES;
    }
}

//annotation Deselect event.
-(void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view
{
    btnAdjust.hidden = YES;
}

//annotation Drag event.
- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)annotationView didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState {
	
	if (oldState == MKAnnotationViewDragStateDragging) {
		DDAnnotation *annotation = (DDAnnotation *)annotationView.annotation;
        NSString *strTmp = annotation.title;
        strTmp = [strTmp substringToIndex:11];
        annotation.title = [NSString stringWithFormat:@"%@ %f,%f", strTmp, annotation.coordinate.latitude, annotation.coordinate.longitude];
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
