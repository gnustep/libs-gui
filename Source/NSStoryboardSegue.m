/* Implementation of class NSStoryboardSegue
   Copyright (C) 2020 Free Software Foundation, Inc.

   By: Gregory Casamento
   Date: Mon Jan 20 15:57:31 EST 2020

   This file is part of the GNUstep Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110 USA.
*/

#import <Foundation/NSString.h>
#import <Foundation/NSGeometry.h>
#import <Foundation/NSNotification.h>

#import "AppKit/NSStoryboardSegue.h"
#import "AppKit/NSWindowController.h"
#import "AppKit/NSViewController.h"
#import "AppKit/NSSplitViewController.h"
#import "AppKit/NSSplitViewItem.h"
#import "AppKit/NSSplitView.h"
#import "AppKit/NSTabViewController.h"
#import "AppKit/NSTabViewItem.h"
#import "AppKit/NSTabView.h"
#import "AppKit/NSWindow.h"
#import "AppKit/NSApplication.h"
#import "AppKit/NSView.h"
#import "AppKit/NSPopover.h"
#import "GSStoryboardArchive.h"

/* A presentation outlives the temporary segue and may outlive its source
 * controller.  The close notification balances this object's initial retain;
 * neither the controller nor its window needs to retain itself. */
@interface GSStoryboardWindowPresentation : NSObject
{
  id _controller;
  id _presentation;
}
- (id) initWithController: (id)controller presentation: (id)presentation
       closeNotification: (NSString *)notification;
- (void) presentationDidClose: (NSNotification *)notification;
@end

@implementation GSStoryboardWindowPresentation

- (id) initWithController: (id)controller presentation: (id)presentation
       closeNotification: (NSString *)notification
{
  if ((self = [super init]) != nil)
    {
      if (presentation == nil)
        {
          RELEASE(self);
          return nil;
        }
      _controller = RETAIN(controller);
      _presentation = RETAIN(presentation);
      [[NSNotificationCenter defaultCenter] addObserver: self
        selector: @selector(presentationDidClose:) name: notification
        object: presentation];
    }
  return self;
}

- (void) presentationDidClose: (NSNotification *)notification
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  AUTORELEASE(self); // Keep the controller alive until close dispatch finishes.
}

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  RELEASE(_controller);
  RELEASE(_presentation);
  [super dealloc];
}
@end

@implementation NSStoryboardSegue

- (id) sourceController
{
  return _sourceController;
}

- (id) destinationController
{
  return _destinationController;
}

- (NSStoryboardSegueIdentifier)identifier
{
  return _identifier;
}

- (void) _setHandler: (GSStoryboardSeguePerformHandler)handler
{
  ASSIGN(_handler, handler);
}

- (void) _setDestinationController: (id)controller
{
  ASSIGN(_destinationController, controller);
}

- (void) _setSourceController: (id)controller
{
  ASSIGN(_sourceController, controller);
}

+ (instancetype) segueWithIdentifier: (NSStoryboardSegueIdentifier)identifier
			      source: (id)sourceController
			 destination: (id)destinationController
		      performHandler: (GSStoryboardSeguePerformHandler)performHandler
{
  NSStoryboardSegue *segue = [[NSStoryboardSegue alloc] initWithIdentifier: identifier
								    source: sourceController
							       destination: destinationController];
  AUTORELEASE(segue);
  [segue _setHandler: performHandler];

  return segue;
}

- (instancetype) initWithIdentifier: (NSStoryboardSegueIdentifier)identifier
			     source: (id)sourceController
			destination: (id)destinationController
{
  self = [super init];
  if (self != nil)
    {
      ASSIGN(_sourceController, sourceController);
      ASSIGN(_destinationController, destinationController);
      ASSIGN(_identifier, identifier);
    }
  return self;
}

- (void) dealloc
{
  RELEASE(_sourceController);
  RELEASE(_destinationController);
  RELEASE(_identifier);
  RELEASE(_kind);
  RELEASE(_relationship);
  RELEASE(_handler);
  RELEASE(_popoverAnchorView);
  [super dealloc];
}

- (void) perform
{
  // Perform segue based on it's kind...
  if ([_kind isEqualToString: @"relationship"])
    {
      if ([_relationship isEqualToString: @"window.shadowedContentViewController"])
	{
	  NSWindow *w = [_sourceController window];
	  NSView *v = [_destinationController view];
	  [w setContentView: v];
	  [w setTitle: [_destinationController title]];
	  [_sourceController showWindow: self];
	}
      else if ([_relationship isEqualToString: @"splitItems"])
	{
          NSSplitViewController *svc = (NSSplitViewController *)_sourceController;
          NSSplitViewItem *item = [NSSplitViewItem
            splitViewItemWithViewController: _destinationController];
          [svc addSplitViewItem: item];
	}
      else if ([_relationship isEqualToString: @"tabItems"])
	{
	  NSTabViewController *tvc = (NSTabViewController *)_sourceController;
	  NSTabViewItem *item = [NSTabViewItem tabViewItemWithViewController: _destinationController];
	  [tvc addTabViewItem: item];
	}
    }
  else if ([_kind isEqualToString: @"modal"])
    {
      NSWindow *w = nil;
      if ([_destinationController isKindOfClass: [NSWindowController class]])
	{
	  w = [_destinationController window];
	}
      else
	{
	  w = [NSWindow windowWithContentViewController: _destinationController];
	  [w setTitle: [_destinationController title]];
	}
      RETAIN(w);
      [w center];
      [NSApp runModalForWindow: w];
    }
  else if ([_kind isEqualToString: @"show"])
    {
      if ([_destinationController isKindOfClass: [NSWindowController class]])
	{
          [[GSStoryboardWindowPresentation alloc]
            initWithController: _destinationController
            presentation: [_destinationController window]
            closeNotification: NSWindowWillCloseNotification];
	  [_destinationController showWindow: _sourceController];
	}
      else
	{
	  NSWindow *w = [NSWindow windowWithContentViewController: _destinationController];
	  [w setTitle: [_destinationController title]];
	  [w center];
          // The presentation owns this autoreleased window until close.
          // Closing must not consume that ownership a second time.
          [w setReleasedWhenClosed: NO];
          [[GSStoryboardWindowPresentation alloc]
            initWithController: _destinationController presentation: w
            closeNotification: NSWindowWillCloseNotification];
	  [w orderFrontRegardless];
	}
    }
  else if ([_kind isEqualToString: @"popover"])
    {
      if (_popover == nil)
	{
	  NSPopover *po = [[NSPopover alloc] init];
	  NSRect rect = [_popoverAnchorView frame];

	  _popover = po; // weak... since we manually release...
	  [po setBehavior: _popoverBehavior];
	  [po setContentViewController: _destinationController];
	  [po showRelativeToRect: rect
			  ofView: _popoverAnchorView
		   preferredEdge: _preferredEdge];
	}
      else
	{
	  if ([_popover behavior] == NSPopoverBehaviorTransient)
	    {
	      [_destinationController dismissController: nil];
	      [_popover close];
	      RELEASE(_popover);
	      _popover = nil;
	    }
	}
    }
  else if ([_kind isEqualToString: @"sheet"])
    {
    }
  else if ([_kind isEqualToString: @"custom"])
    {
    }

  if (_handler != nil)
    {
      CALL_BLOCK_NO_ARGS(_handler);
    }
}

@end

@implementation NSStoryboardSegue (GSStoryboardPrivate)

- (void) _setKind: (NSString *)k
{
  ASSIGN(_kind, k);
}

- (NSString *) _kind
{
  return _kind;
}

- (void) _setRelationship: (NSString *)r
{
  ASSIGN(_relationship, r);
}

- (NSString *) _relationship
{
  return _relationship;
}

- (void) _setPopoverAnchorView: (id)view
{
  ASSIGN(_popoverAnchorView, view);
}

- (id) _popoverAnchorView
{
  return _popoverAnchorView;
}

- (void) _setPopoverBehavior: (NSPopoverBehavior)behavior
{
  _popoverBehavior = behavior;
}

- (NSPopoverBehavior) _popoverBehavior
{
  return _popoverBehavior;
}

- (void) _setPreferredEdge: (NSRectEdge)edge
{
  _preferredEdge = edge;
}

- (NSRectEdge) _preferredEdge
{
  return _preferredEdge;
}
@end
