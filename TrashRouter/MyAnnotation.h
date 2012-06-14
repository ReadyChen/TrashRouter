//
//  MyAnnotation.h
//  TrashRouter
//
//  Created by readyair on 12/5/29.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface MyAnnotation : NSObject <MKAnnotation> {

@public
    CLLocationCoordinate2D myCoordinate;
    NSString *myTitle;
    NSString *mySubTitle;
    NSInteger iPinColor;
}

@property(assign, nonatomic) CLLocationCoordinate2D myCoordinate;
@property(retain, nonatomic) NSString *myTitle;
@property(retain, nonatomic) NSString *mySubTitle;
@property(assign, nonatomic) NSInteger iPinColor;

- (CLLocationCoordinate2D)coordinate;
- (NSString *)title;
- (NSString *)subtitle;
- (void)setPinColor:(NSInteger)iNewPinColor;
- (NSInteger)getPinColor;


@end