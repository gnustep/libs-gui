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
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the 
   Free Software Foundation, 51 Franklin Street, Fifth Floor, 
   Boston, MA 02110-1301, USA.
*/ 

#include <Foundation/NSObject.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSEnumerator.h>
#include <Foundation/NSException.h>
#include "AppKit/NSToolbarItem.h"
#include "AppKit/NSView.h"
#include "AppKit/NSWindow.h"
#include "AppKit/NSWindow+Toolbar.h"
#include "GNUstepGUI/GSToolbarView.h"
#include "GNUstepGUI/GSToolbar.h"
#include "AppKit/NSToolbar.h"

// internal
static const int current_version = 1;

@interface GSToolbar (GNUstepPrivate)
+ (NSArray *) _toolbarsWithIdentifier: (NSString *)identifier;
@end

@interface NSToolbar (GNUstepPrivate)

// Private methods with broadcast support
- (void) _setDisplayMode: (NSToolbarDisplayMode)displayMode 
               broadcast: (BOOL)broadcast;
- (void) _setSizeMode: (NSToolbarSizeMode)sizeMode 
            broadcast: (BOOL)broadcast;
- (void) _setVisible: (BOOL)shown broadcast: (BOOL)broadcast;

// Few other private methods
- (GSToolbar *) _toolbarModel;

@end

@interface GSToolbarView (GNUstepPrivate)
- (void) _reload;

// Accessors
- (void) _setSizeMode: (NSToolbarSizeMode)sizeMode;
- (NSToolbarSizeMode) _sizeMode;
@end

@interface NSWindow (ToolbarPrivate)
- (void) _adjustToolbarView;
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
    }
}

// Instance methods

- (id) initWithIdentifier: (NSString *)identifier 
{
  NSToolbar *toolbarModel = nil;

  if ((self = [super initWithIdentifier: identifier]) == nil)
    {
      return nil;
    }

  toolbarModel = (NSToolbar *)[self _toolbarModel];
    
  if (toolbarModel != nil)
    {
      _visible = [toolbarModel isVisible];
    }
  else
    {
      _visible = YES;
    }

  return self;
}

// Accessors

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
 * The methods below handle the toolbar edition and broacast each associated
 * event to the other toolbars with identical identifiers. 
 *
 */

#define TRANSMIT(signature) \
  NSEnumerator *e = [[GSToolbar _toolbarsWithIdentifier: _identifier] objectEnumerator]; \
  NSToolbar *toolbar; \
  \
  while ((toolbar = [e nextObject]) != nil) \
    { \
      if (toolbar != self && [self isMemberOfClass: [self class]]) \
        [toolbar signature]; \
    } \

- (void) _setDisplayMode: (NSToolbarDisplayMode)displayMode 
               broadcast: (BOOL)broadcast
{
  if (_displayMode != displayMode)
    {
      _displayMode = displayMode;
   
      [_toolbarView _reload];
      [[_toolbarView window] _adjustToolbarView];
      
      if (broadcast) 
        {
          TRANSMIT(_setDisplayMode: _displayMode broadcast: NO);
        }
    }
}

- (void) _setSizeMode: (NSToolbarSizeMode)sizeMode 
            broadcast: (BOOL)broadcast
{
  if (_sizeMode != sizeMode)
    {
      _sizeMode = sizeMode;

      [_toolbarView _setSizeMode: _sizeMode];
      
      [_toolbarView _reload];
      [[_toolbarView window] _adjustToolbarView];
  
      if (broadcast) 
        {
          TRANSMIT(_setSizeMode: _sizeMode broadcast: NO);
        }
    }
}

// This method wont make a toolbar visible or invisible by itself.
// Use [NSWindow toggleToolbarShown:]
- (void) _setVisible: (BOOL)shown broadcast: (BOOL)broadcast
{
  if (_visible != shown)
    {  
       _visible = shown; 
    
       if (broadcast) 
         {
           TRANSMIT(_setVisible: _visible broadcast: NO);
         }
    }
}

@end
