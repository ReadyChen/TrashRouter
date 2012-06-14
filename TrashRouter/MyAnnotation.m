//
//  MyAnnotation.m
//  TrashRouter
//
//  Created by readyair on 12/5/29.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "MyAnnotation.h"

@implementation MyAnnotation

@synthesize myCoordinate, myTitle, mySubTitle, iPinColor;

- (CLLocationCoordinate2D)coordinate{
    return self.myCoordinate;
}

- (NSString *)title{
    return self.myTitle;
}

- (NSString *)subtitle{
    return self.mySubTitle;
}

-(void)setPinColor:(NSInteger)iNewPinColor{
    self.iPinColor = iNewPinColor;
}
-(NSInteger)getPinColor{
    return self.iPinColor;
}

@end