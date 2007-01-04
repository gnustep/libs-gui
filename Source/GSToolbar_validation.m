/* 
   <title>GSToolbar_validation.m</title>

   <abstract>Toolbar validation mechanism</abstract>
   
   Copyright (C) 2004 Free Software Foundation, Inc.

   Author:  Quentin Mathe <qmathe@club-internet.fr>
   Date: February 2004
   
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
*/ 

#import "AppKit/AppKit.h"
#import "GSToolbar_validation.h"
#import "NSArray_filtering.h"

// internal
static NSNotificationCenter *nc = nil;
static GSValidationCenter *vc;

// Validation stuff
static const unsigned int ValidationInterval = 4;


// Validation mechanism

@interface NSWindow (GNUstepPrivate)
- (NSView *) _windowView;
@end

@implementation GSValidationObject

- (id) initWithWindow: (NSWindow *)window
{
  if ((self = [super init]) != nil)
    {
      _observers = [[NSMutableArray alloc] init];
      
      [nc addObserver: self selector: @selector(windowDidUpdate:) 
                 name: NSWindowDidUpdateNotification 
	       object: window];
      [nc addObserver: vc 
      	     selector: @selector(windowWillClose:) 
                 name: NSWindowWillCloseNotification 
	       object: window];
						
       _trackingRectView = [window _windowView];
       _trackingRect 
	 = [_trackingRectView addTrackingRect: [_trackingRectView bounds]
			                owner: self 
			             userData: nil 
			         assumeInside: NO];  
       _window = window;
    }
  return self;
}

- (void) dealloc
{
  // NSLog(@"vobj dealloc");
 
  // [_trackingRectView removeTrackingRect: _trackingRect]; 
  // Not here because the tracking rect retains us, then when the tracking rect
  // would be deallocated that would create a loop and a segmentation fault.
  // See next method.
  
  RELEASE(_observers);
  
  [super dealloc];
}

- (void) clean
{ 
  if ([_validationTimer isValid])
    {
      [_validationTimer invalidate];
      _validationTimer = nil;
    }
  
  [nc removeObserver: vc
                name: NSWindowWillCloseNotification 
              object: _window];
  [nc removeObserver: self 
                name: NSWindowDidUpdateNotification  
              object: _window];
  
  [self setWindow: nil];              
  // Needed because the validation timer can retain us and by this way retain also the toolbar which is
  // currently observing.
  
  [self setObservers: nil]; // To release observers 
	      
  [_trackingRectView removeTrackingRect: _trackingRect];
  // We can safely remove the tracking rect here, because it will never call
  // this method unlike dealloc.   
}

/*
 * FIXME: Replace the deprecated method which follows by this one when -base 
 * NSObject will implement it.
 *
- (id) valueForUndefinedKey: (NSString *)key
{
  if ([key isEqualToString: @"window"] || [key isEqualToString: @"_window"])
    return nil;
  
  return [super valueForUndefinedKey: key];
}
 */
 
- (id) handleQueryWithUnboundKey: (NSString *)key
{
  if ([key isEqualToString: @"window"] || [key isEqualToString: @"_window"])
    return [NSNull null];
  
  return [super handleQueryWithUnboundKey: key];
}

- (NSMutableArray *) observers
{
  return _observers;
}

- (void) setObservers: (NSMutableArray *)observers
{
  ASSIGN(_observers, observers);
}

- (NSWindow *) window
{
  return _window;
}

- (void) setWindow: (NSWindow *)window
{
  _window = window;
}

- (void) validate
{ 
  _validating = YES;
  
  // NSLog(@"vobj validate");
  
  [_observers makeObjectsPerformSelector: @selector(_validate:) 
                              withObject: _window];
  
  _validating = NO;
}

- (void) mouseEntered: (NSEvent *)event
{ 
  _inside = YES;
  [self scheduledValidate];
}

- (void) mouseExited: (NSEvent *)event
{ 
  _inside = NO;
  if ([_validationTimer isValid])
    {
      [_validationTimer invalidate];
      _validationTimer = nil;
    }
}

- (void) windowDidUpdate: (NSNotification *)notification
{
  // NSLog(@"Window update %d", [[NSApp currentEvent] type]);
  
  if (!_inside || _validating || [[NSApp currentEvent] type] == NSMouseMoved)
    return;
  // _validating permits in the case the UI/window is refreshed by a validation to 
  // avoid have windowDidUpdate called, which would cause a loop like that :
  // validate -> view update -> windowDidUpdate -> validate etc.
    
  [self validate];
}

- (void) scheduledValidate
{  
  if (!_inside)
    return;
  
  [self validate];
  
  _validationTimer = 
    [NSTimer timerWithTimeInterval: ValidationInterval 
                            target: self 
			  selector: @selector(scheduledValidate) 
			  userInfo: nil
			   repeats: NO];
  [[NSRunLoop currentRunLoop] addTimer: _validationTimer 
                               forMode: NSDefaultRunLoopMode];	  
}

@end


@implementation GSValidationCenter

+ (void) initialize
{
  if (self == [GSValidationCenter class])
  {
    nc = [NSNotificationCenter defaultCenter];
  }
}

+ (GSValidationCenter *) sharedValidationCenter
{
  if (vc == nil)
    {
      if ((vc = [[GSValidationCenter alloc] init]) != nil)
        {
           // Nothing special
        }
    }
    
  return vc;
}

- (id) init
{
  if ((self = [super init]) != nil)
    {
      _vobjs = [[NSMutableArray alloc] init];
    }
    
  return self;
}

- (void) dealloc
{
  [nc removeObserver: self];
  
  RELEASE(_vobjs);
  
  [super dealloc];
}

- (NSArray *) observersWindow: (NSWindow *)window
{
  int i;
  NSArray *observersArray;
  NSMutableArray *result;
  
  if (window == nil)
    {
      result = [NSMutableArray array];
      observersArray = [_vobjs valueForKey: @"_observers"];
      for (i = 0; i < [observersArray count]; i++)
        {
	  [result addObjectsFromArray: [observersArray objectAtIndex: i]];
	}
      return result;
    }
  else
    {
      result = [[[_vobjs objectsWithValue: window forKey: @"_window"] 
        objectAtIndex: 0] observers];
      return result;
    }
}

- (void) addObserver: (id)observer window: (NSWindow *)window
{
  GSValidationObject *vobj = 
    [[_vobjs objectsWithValue: window forKey: @"_window"] objectAtIndex: 0];
  NSMutableArray *observersWindow = nil;
  
  if (window == nil)
    return;
  
  if (vobj != nil)
    {
      observersWindow = [vobj observers];
    }
  else
    {
      vobj = [[GSValidationObject alloc] initWithWindow: window];
      [_vobjs addObject: vobj];
      RELEASE(vobj);

      observersWindow = [NSMutableArray array];
      [vobj setObservers: observersWindow]; 
    }
  
  [observersWindow addObject: observer];
}

- (void) removeObserver: (id)observer window: (NSWindow *)window
{
  GSValidationObject *vobj;
  NSMutableArray *observersWindow;
  NSMutableArray *windows;
  NSEnumerator *e;
  NSWindow *w;

  if (window == nil)
    {
      windows = [_vobjs valueForKey: @"_window"];
    }
  else
    {
      windows = [NSArray arrayWithObject: window];
    }
  
  e = [windows objectEnumerator];
  
  while ((w = [e nextObject]) != nil)
    { 
      vobj = [[_vobjs objectsWithValue: w forKey: @"_window"] objectAtIndex: 0];
      observersWindow = [vobj observers];
  
      if (observersWindow != nil && [observersWindow containsObject: observer])
        {
          [observersWindow removeObject: observer];
	  if ([observersWindow count] == 0)
	    {  
              [vobj clean];
	      [_vobjs removeObjectIdenticalTo: vobj];
	    }
	}
    }
 
}

- (void) windowWillClose: (NSNotification *)notification
{
  GSValidationObject *vobj;
 
  // NSLog(@"Window will close");
 
  vobj = [[_vobjs objectsWithValue: [notification object] forKey: @"_window"] 
    objectAtIndex: 0];
  if (vobj != nil)
    {
      [vobj clean];
      [_vobjs removeObjectIdenticalTo: vobj];
    }
}

@end
