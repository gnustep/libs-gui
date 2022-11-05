#import <AppKit/AppKit.h>

@interface GSAutoLayoutVFLParser : NSObject
{
 NSDictionary *_views;
 NSLayoutFormatOptions _options;
 NSDictionary *_metrics;
 NSScanner *_scanner;
 NSMutableArray *_constraints;
 NSMutableArray *_layoutFormatConstraints;  
 NSView *_view;
 BOOL _createLeadingConstraintToSuperview;
 BOOL _isVerticalOrientation;
}


-(instancetype)initWithFormat: (NSString*)format options: (NSLayoutFormatOptions)options metrics: (NSDictionary*)metrics views: (NSDictionary*)views;

-(NSArray*)parse;

@end

