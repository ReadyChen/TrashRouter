//
//  TrashPoints.m
//  TrashRouter
//
//  Created by readyair on 12/5/31.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "TrashPoint.h"

@implementation KMLElement

@synthesize identifier;

- (id)initWithIdentifier:(NSString *)ident
{
    if (self = [super init]) {
        identifier = [ident retain];
    }
    return self;
}

- (void)dealloc
{
    [identifier release];
    [accum release];
    [super dealloc];
}

- (BOOL)canAddString
{
    return NO;
}

- (void)addString:(NSString *)str
{
    if ([self canAddString]) {
        if (!accum)
            accum = [[NSMutableString alloc] init];
        //[accum appendString:str];
        accum = [str copy];
    }
}

- (void)clearString
{
    [accum release];
    accum = nil;
}

@end


@implementation KMLPlacemark

@synthesize name, iStartTime, iEndTime, annotation, iStatus;//strCoordinates, strStayTime,

- (id)init  
{  
    self = [super init];  
    if (self)  
    {  
        name = nil;  
        iStartTime = 0;
        iEndTime = 0;
        annotation = nil;
        iStatus = 0;
    }  
    
    return self;  
}

- (void)dealloc
{
    [name release];
    [annotation release];
    [super dealloc];
}

- (BOOL)canAddString
{
    return flags.inPlacemark || flags.inName  || flags.inCoordi  || flags.inAddress ;
}

- (void)addString:(NSString *)str
{
    [super addString:str];
}

- (void)beginPlacemark
{
    flags.inPlacemark = YES;
}
- (void)endPlacemark
{
    flags.inPlacemark = NO;
    if(annotation == nil)
    {
        annotation = [[MyAnnotation alloc] init];
    }
    //annotation.myCoordinate = coordi;
    annotation.myTitle = name;
}

- (void)beginName
{
    flags.inName = YES;
}
- (void)endName
{
    flags.inName = NO;
    [name release];
    name = [accum copy];
    strNameToStayTime(name, &iStartTime, &iEndTime);
    [self clearString];
}

- (void)beginCoordi
{
    flags.inCoordi = YES;
}
- (void)endCoordi
{
    flags.inCoordi = NO;
    CLLocationCoordinate2D _coordi;
    strToCoords(accum, &_coordi);
    annotation.myCoordinate = _coordi;
    [self clearString];
}

- (void)beginAddress
{
    flags.inAddress = YES;
}
- (void)endAddress
{
    flags.inAddress = NO;
    if(annotation == nil)
    {
        annotation = [[MyAnnotation alloc] init];
    }
    annotation.mySubTitle = accum;
    [self clearString];
}

/*
-(NSString *)getName{
    return name;
}
-(CLLocationCoordinate2D *)getCoordinate{
    return &coordinate;
}
-(NSInteger)getiStartTime{
    return iStartTime;
}
-(NSInteger)getiEndTime{
    return iEndTime;
}
- (MyAnnotation *)getAnnotation{
    return annotation;
}

- (void)setStatus:(NSInteger)iNewStatus{
    iStatus = iNewStatus;
}
- (NSInteger)getStatus{
    return iStatus;
}
*/

// Convert a KML coordinate list string to a C array of CLLocationCoordinate2Ds.
// KML coordinate lists are longitude,latitude[,altitude] tuples specified by whitespace.
static void strToCoords(NSString *str, CLLocationCoordinate2D *coordsOut)
{
    //改成 只能支援一組 log,lat 的解析
    NSArray *tuples = [str componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    for (NSString *tuple in tuples) {        
        double lat, lon;
        NSScanner *scanner = [[NSScanner alloc] initWithString:tuple];
        [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@","]];
        BOOL success = [scanner scanDouble:&lat];
        if (success) 
            success = [scanner scanDouble:&lon];
        if (success) {
            CLLocationCoordinate2D c = CLLocationCoordinate2DMake(lat, lon);
            if (CLLocationCoordinate2DIsValid(c))
                *coordsOut = CLLocationCoordinate2DMake(lat, lon);
        }
        [scanner release];
    }
}

static void strNameToStayTime(NSString *str, NSInteger *_iStartTime, NSInteger *_iEndTime)
{
    NSArray *tuples = [str componentsSeparatedByString:@"~"];
    
    NSInteger iHHs = 0;
    NSInteger iMMs = 0;
    NSInteger iHHe = 0;
    NSInteger iMMe = 0;
    
    NSInteger iRound = 0;
    for (NSString *tuple in tuples) {
        BOOL success = NO;
        NSScanner *scanner = [[NSScanner alloc] initWithString:tuple];
        [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@":"]];
        if(iRound == 0){
            success = [scanner scanInteger:&iHHs];
            if (success) {
                success = [scanner scanInteger:&iMMs];
            }
            iRound++;
        }else{
            success = [scanner scanInteger:&iHHe];
            if (success) {
                success = [scanner scanInteger:&iMMe];
            }
        }
        [scanner release];
    }
    *_iStartTime = (iHHs)*60+iMMs;
    *_iEndTime = (iHHe)*60+iMMe;
    
    if(iHHe<6){
        // when ~00:MM to ~05:MM
        *_iEndTime = (iHHe+24)*60+iMMe;
    }
}

@end
