/* 
   <title>NSToolbar.m</title>

   <abstract>The toolbar class.</abstract>
   
   Copyright (C) 2002 Free Software Foundation, Inc.

   Author:  Gregory John Casamento <greg_casamento@yahoo.com>,
            Fabien Vallon <fabien.vallon@fr.alcove.com>,
	    Quentin Mathe <qmathe@club-internet.fr>
   Date: May 2002
   
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
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/ 

#include <Foundation/NSObject.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSException.h>
#include <Foundation/NSNotification.h>
#include "AppKit/NSToolbarItem.h"
#include "AppKit/NSView.h"
#include "AppKit/NSWindow.h"
#include "GNUstepGUI/GSToolbarView.h"
#include "GNUstepGUI/GSToolbar.h"
#include "AppKit/NSToolbar.h"

// internal
static NSNotificationCenter *nc = nil;
static const int current_version = 1;


@interface NSToolbar (GNUstepPrivate)

+ (NSMutableArray *) _toolbars;

// Private methods with broadcast support
- (void) _setDisplayMode: (NSToolbarDisplayMode)displayMode 
               broadcast: (BOOL)broadcast;
- (void) _setSizeMode: (NSToolbarSizeMode)sizeMode 
            broadcast: (BOOL)broadcast;
- (void) _setVisible: (BOOL)shown broadcast: (BOOL)broadcast;
- (void) _setDelegate: (id)delegate broadcast: (BOOL)broadcast;

// Few other private methods
- (void) _loadConfig;
- (GSToolbar *) _toolbarModel;

// Accessors
- (void) _setWindow: (NSWindow *)window;
- (NSWindow *) _window;
@end

@interface NSToolbarItem (GNUstepPrivate)
- (void) _setToolbar: (GSToolbar *)toolbar;
@end

@interface GSToolbarView (GNUstepPrivate)
- (void) _reload;
- (NSArray *) _visibleBackViews;
- (BOOL) _willBeVisible;
- (void) _setWillBeVisible: (BOOL)willBeVisible;
@end

// ---

@implementation NSToolbar

// Class methods

// Initialize the class when it is loaded
+ (void) initialize
{
  if (self == [NSToolbar class])
    {
      [self setVersion: current_version];
      nc = [NSNotificationCenter defaultCenter];
    }
}

// Instance methods

- (id) initWithIdentifier: (NSString *)identifier 
              displayMode:(NSToolbarDisplayMode)displayMode 
                 sizeMode: (NSToolbarSizeMode)sizeMode
{
  NSToolbar *toolbarModel = nil;

  if ((self = [super initWithIdentifier: identifier 
                            displayMode: displayMode 
                               sizeMode: sizeMode]) == nil)
    {
      return nil;
    }

  toolbarModel = (NSToolbar *)[self _toolbarModel];
    
  if (toolbarModel != nil)
    {
      _displayMode = [toolbarModel displayMode];
      _sizeMode = [toolbarModel sizeMode]; 
      _visible = [toolbarModel isVisible];
    }
  else
    {
      _displayMode = displayMode; 
      _sizeMode = sizeMode;
      _visible = YES;
    }

  return self;
}

- (void) dealloc
{

  [super dealloc];
}

// Accessors

- (NSToolbarDisplayMode) displayMode
{
  return _displayMode;
}

- (NSToolbarSizeMode) sizeMode
{
  return _sizeMode;
}

- (BOOL) isVisible
{
  return _visible;
}


/**
 * Sets the receivers delegate ... this is the object which will receive
 * -toolbar:itemForItemIdentifier:willBeInsertedIntoToolbar:
 * -toolbarAllowedItemIdentifiers: and -toolbarDefaultItemIdentifiers:
 * messages.
 */
 
- (void) setDisplayMode: (NSToolbarDisplayMode)displayMode
{
  [self _setDisplayMode: displayMode broadcast: YES];
}

- (void) setSizeMode: (NSToolbarSizeMode)sizeMode
{
  [self _setSizeMode: sizeMode broadcast: YES];
}

- (void) setVisible: (BOOL)shown
{
  [self _setVisible: shown broadcast: NO];
}

// Private methods

/*
 *
 * The methods below handles the toolbar edition and broacasts each associated
 * event to the other toolbars with identical identifiers. 
 *
 */

#define TRANSMIT(signature) \
  NSEnumerator *e = [[[GSToolbar _toolbars] objectsWithValue: _identifier forKey: @"_identifier"] objectEnumerator]; \
  NSToolbar *toolbar; \
  \
  while ((toolbar = [e nextObject]) != nil) \
    { \
      if (toolbar != self && [self isMemberOfClass: [self class]]) \
        [toolbar signature]; \
    }

- (void) _setDisplayMode: (NSToolbarDisplayMode)displayMode 
               broadcast: (BOOL)broadcast
{
   _displayMode = displayMode;
   
   // do more
     
   if (broadcast) 
     {
       TRANSMIT(_setDisplayMode: _displayMode broadcast: NO);
     }
}

- (void) setSizeMode: (NSToolbarSizeMode)sizeMode 
           broadcast: (BOOL)broadcast
{
   _sizeMode = sizeMode;
   
   // do more
     
   if (broadcast) 
     {
       TRANSMIT(_setSizeMode: _sizeMode broadcast: NO);
     }
}

- (void) _setVisible: (BOOL)shown broadcast: (BOOL)broadcast
{
  if (_visible != shown)
    {  
      if (_window) 
        {
          if (shown)
	    [_toolbarView _setWillBeVisible: YES];
	  
	  [_window toggleToolbarShown: self];
	  
	  [_toolbarView _setWillBeVisible: NO];
        }
	
       _visible = shown; 
       // Important to set _visible after the toolbar has been toggled because
       // NSWindow method contentViewWithoutToolbar uses [NSToolbar visible]
       // when we toggle the toolbar
       // example : the toolbar needs to be still known visible in order to hide
       // it.
    }
    
    if (broadcast) 
      {
        TRANSMIT(_setVisible: _visible broadcast: NO);
      }
}

// Private Accessors

- (void)_setWindow: (NSWindow *)window 
{
  ASSIGN(_window, window); 
  // call [NSWindow(Toolbar) setToolbar:] to set the toolbar window 
}

- (NSWindow *) _window
{
  return _window;
}

@end
