#ifndef _GNUstep_H_NSRulerMarker
#define _GNUstep_H_NSRulerMarker

#include <Foundation/NSObject.h>

@class NSRulerView;
@class NSImage;

@interface NSRulerMarker : NSObject <NSObject,NSCopying>
- (id)initWithRulerView:(NSRulerView *)aRulerView
         markerLocation:(float)location
		  image:(NSImage *)anImage
	    imageOrigin:(NSPoint)imageOrigin; 

- (NSRulerView *)ruler; 

- (void)setImage:(NSImage *)anImage; 
- (NSImage *)image;

- (void)setImageOrigin:(NSPoint)aPoint; 
- (NSPoint)imageOrigin; 
- (NSRect)imageRectInRuler; 
- (float)thicknessRequiredInRuler; 

- (void)setMovable:(BOOL)flag;
- (BOOL)isMovable; 
- (void)setRemovable:(BOOL)flag; 
- (BOOL)isRemovable; 

- (void)setMarkerLocation:(float)location; 
- (float)makerLocation; 

- (void)setRepresentedObject:(id <NSCopying>)anObject; 
- (id <NSCopying>)representedObject;

- (void)drawRect:(NSRect)aRect;
- (BOOL)isDragging; 
- (BOOL)trackMouse:(NSEvent *)theEvent adding:(BOOL)flag; 

// NSCopying
- (id) copyWithZone: (NSZone*)zone;
@end

#endif /* _GNUstep_H_NSRulerMarker */

