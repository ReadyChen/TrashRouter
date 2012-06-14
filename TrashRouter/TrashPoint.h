//
//  TrashPoints.h


#import "MyAnnotation.h"
@class MyAnnotation;

@interface KMLElement : NSObject {
    NSString *identifier;
    NSMutableString *accum;
}

- (id)initWithIdentifier:(NSString *)ident;

@property (retain) NSString *identifier;

// Returns YES if we're currently parsing an element that has character
// data contents that we are interested in saving.
- (BOOL)canAddString;
// Add character data parsed from the xml
- (void)addString:(NSString *)str;
// Once the character data for an element has been parsed, use clearString to
// reset the character buffer to get ready to parse another element.
- (void)clearString;

@end





@interface KMLPlacemark : KMLElement {
    
@private
    NSString *name;// static format "HH:MM~HH:MM", Log Pin title & parser out StayTime iStartTime,iEndTime.
    CLLocationCoordinate2D coordi;
    NSInteger iStartTime;
    NSInteger iEndTime;
    MyAnnotation *annotation;
    NSInteger iStatus;// Log for ePASS|ePRESENT|eLATER
    
    struct {
        NSInteger inPlacemark:1;
        NSInteger inName:1;
        NSInteger inCoordi:1;
        NSInteger inAddress:1;
    } flags;
}
- (void)beginPlacemark;
- (void)endPlacemark;

- (void)beginName;
- (void)endName;

- (void)beginCoordi;
- (void)endCoordi;

- (void)beginAddress;
- (void)endAddress;

/*
 - (MyAnnotation *)getAnnotation;
 - (void)setStatus:(NSInteger)iNewStatus;
 - (NSInteger)getStatus;
 */

// Corresponds to the title property on MKAnnotation
@property (retain) NSString *name;
@property (nonatomic) NSInteger iStartTime;
@property (nonatomic) NSInteger iEndTime;
@property (retain) MyAnnotation *annotation;
@property (nonatomic) NSInteger iStatus;

@end


typedef enum{
    ePASS,
    ePRESENT,
    eLATER
} iStatusFlag;

