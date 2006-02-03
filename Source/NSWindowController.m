/** <title>NSWindowController</title>

   Copyright (C) 2000 Free Software Foundation, Inc.

   Author: Fred Kiefer <FredKiefer@gmx.de>
   Date: Aug 2003
   Author: Carl Lindberg <Carl.Lindberg@hbo.com>
   Date: 1999

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
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
*/

#include "AppKit/NSWindowController.h"
#include "AppKit/NSPanel.h"
#include "AppKit/NSNibLoading.h"
#include "AppKit/NSDocumentFrameworkPrivate.h"

@implementation NSWindowController

- (id) initWithWindowNibName: (NSString *)windowNibName
{
  return [self initWithWindowNibName: windowNibName  owner: self];
}

- (id) initWithWindowNibName: (NSString *)windowNibName  owner: (id)owner
{
  if (windowNibName == nil)
    {
      [NSException raise: NSInvalidArgumentException
		   format: @"attempt to init NSWindowController with nil windowNibName"];
    }

  if (owner == nil)
    {
      [NSException raise: NSInvalidArgumentException
		   format: @"attempt to init NSWindowController with nil owner"];
    }

  self = [self initWithWindow: nil];
  ASSIGN(_windowNibName, windowNibName);
  _owner = owner;
  return self;
}

- (id) initWithWindowNibPath: (NSString *)windowNibPath
		       owner: (id)owner
{
  if (windowNibPath == nil)
    {
      [NSException raise: NSInvalidArgumentException
		   format: @"attempt to init NSWindowController with nil windowNibPath"];
    }

  if (owner == nil)
    {
      [NSException raise: NSInvalidArgumentException
		   format: @"attempt to init NSWindowController with nil owner"];
    }

  self = [self initWithWindow: nil];
  ASSIGN(_windowNibPath, windowNibPath);
  _owner = owner;
  return self;
}

- (id) initWithWindow: (NSWindow *)window
{
  self = [super init];

  _windowFrameAutosaveName = @"";
  _wcFlags.shouldCascade = YES;
  _wcFlags.shouldCloseDocument = NO;

  [self setWindow: window];
  if (_window != nil)
    {
      [self _windowDidLoad];
    }

  [self setDocument: nil];
  return self;
}

- (id) init
{
  return [self initWithWindow: nil];
}

- (void) dealloc
{
  [self setWindow: nil];
  RELEASE (_windowNibName);
  RELEASE (_windowNibPath);
  RELEASE (_windowFrameAutosaveName);
  RELEASE (_topLevelObjects);
  [super dealloc];
}

- (NSString *) windowNibName
{
  if ((_windowNibName == nil) && (_windowNibPath != nil))
  {
    return [[_windowNibPath lastPathComponent] 
	       stringByDeletingPathExtension];
  }

  return _windowNibName;
}

- (NSString *)windowNibPath
{
  if ((_windowNibName != nil) && (_windowNibPath == nil))
  {
    NSString *path;

    path = [[NSBundle bundleForClass: [_owner class]] 
	       pathForNibResource: _windowNibName];
    if (path == nil)
      path = [[NSBundle mainBundle] 
		 pathForNibResource: _windowNibName];

    return path;
  }

  return _windowNibPath;
}

- (id) owner
{
  return _owner;
}

/** Sets the document associated with this controller. A document
    automatically calls this method when adding a window controller to
    its list of window controllers. You should not call this method
    directly when using NSWindowController with an NSDocument
    or subclass. */
- (void) setDocument: (NSDocument *)document
{
  // As the document retains us, we only keep a week reference.
  _document = document;
  [self synchronizeWindowTitleWithDocumentName];

  if (_document == nil)
    {
      /* If you want the window to be deallocated when closed, you
	 need to observe the NSWindowWillCloseNotification (or
	 implement the window's delegate windowWillClose: method) and
	 autorelease the window controller in that method.  That will
	 then release the window when the window controller is
	 released. */
      [_window setReleasedWhenClosed: NO];
    }
  else
    {
      /* When a window owned by a document is closed, it is released
	 and the window controller is removed from the documents
	 list of controllers.
       */
      [_window setReleasedWhenClosed: YES];
    }
}

- (id) document
{
  return _document;
}

- (void) setDocumentEdited: (BOOL)flag
{
  [_window setDocumentEdited: flag];
}

- (void) setWindowFrameAutosaveName:(NSString *)name
{
  ASSIGN(_windowFrameAutosaveName, name);
  
  if ([self isWindowLoaded])
    {
      [[self window] setFrameAutosaveName: name ? name : @""];
    }
}

- (NSString *) windowFrameAutosaveName
{
  return _windowFrameAutosaveName;
}

- (void) setShouldCloseDocument: (BOOL)flag
{
  _wcFlags.shouldCloseDocument = flag;
}

- (BOOL) shouldCloseDocument
{
  return _wcFlags.shouldCloseDocument;
}

- (void) setShouldCascadeWindows: (BOOL)flag
{
  _wcFlags.shouldCascade = flag;
}

- (BOOL) shouldCascadeWindows
{
  return _wcFlags.shouldCascade;
}

- (void) close
{
  [_window close];
}

- (void) _windowWillClose: (NSNotification *)notification
{
  if ([notification object] == _window)
    {
      /* We only need to do something if the window is set to be
	 released when closed (which should only happen if _document
	 != nil).  In this case, we release everything; otherwise,
	 well the window is closed but nothing is released so there's
	 nothing to do here. */
      if ([_window isReleasedWhenClosed])
	{
	  if ([_window delegate] == self) 
	    {
	      [_window setDelegate: nil];
	    }
	  if ([_window windowController] == self) 
	    {
	      [_window setWindowController: nil];
	    }
	  
	  /*
	   * If the window is set to isReleasedWhenClosed, it will release
	   * itself, so we have to retain it once more.
	   * 
	   * Apple's implementation doesn't seem to deal with this case, and
	   * crashes if isReleaseWhenClosed is set.
	   */
	  RETAIN(_window);
	  [self setWindow: nil];

	  [_document _removeWindowController: self];
	}
    }
}

- (NSWindow *) window
{
  if (_window == nil && ![self isWindowLoaded])
    {
      // Do all the notifications.  Yes, the docs say this should
      // be implemented here instead of in -loadWindow itself.
      [self windowWillLoad];
      if ([_document respondsToSelector:
		       @selector(windowControllerWillLoadNib:)])
	{
	  [_document windowControllerWillLoadNib:self];
	}

      [self loadWindow];

      [self _windowDidLoad];
      if ([_document respondsToSelector:
		       @selector(windowControllerDidLoadNib:)])
	{
	  [_document windowControllerDidLoadNib:self];
	}
    }

  return _window;
}

/** Sets the window that this controller managers to aWindow. The old
   window is released. */
- (void) setWindow: (NSWindow *)aWindow
{
  NSNotificationCenter *nc;

  if (_window == aWindow)
    {
      return;
    }

  nc = [NSNotificationCenter defaultCenter];

  if (_window != nil)
    {
      [nc removeObserver: self
	  name: NSWindowWillCloseNotification
	  object: _window];
      [_window setWindowController: nil];
    }

  ASSIGN (_window, aWindow);

  if (_window != nil)
    {
      [_window setWindowController: self];
      [nc addObserver: self
	  selector: @selector(_windowWillClose:)
	  name: NSWindowWillCloseNotification
	  object: _window];

      /* For information on the following, see the description in 
	 -setDocument: */
      if (_document == nil)
	{
	  [_window setReleasedWhenClosed: NO];
	}
      else
	{
	  [_window setReleasedWhenClosed: YES];
	}

    }
}

- (IBAction) showWindow: (id)sender
{
  NSWindow *window = [self window];

  if ([window isKindOfClass: [NSPanel class]] 
      && [(NSPanel*)window becomesKeyOnlyIfNeeded])
    {
      [window orderFront: sender];
    }
  else
    {
      [window makeKeyAndOrderFront: sender];
    }
}

- (NSString *) windowTitleForDocumentDisplayName: (NSString *)displayName
{
  return displayName;
}

- (void) synchronizeWindowTitleWithDocumentName
{
  if ((_document != nil) && [self isWindowLoaded])
    {
      NSString *filename = [_document fileName];
      NSString *displayName = [_document displayName];
      NSString *title = [self windowTitleForDocumentDisplayName: displayName];

      /* If they just want to display the filename, use the fancy method */
      if (filename != nil && [title isEqualToString: filename])
        {
          [_window setTitleWithRepresentedFilename: filename];
        }
      else
        {
          if (filename) 
	    [_window setRepresentedFilename: filename];
	  [_window setTitle: title];
        }
    }
}

- (BOOL) isWindowLoaded
{
  return _wcFlags.nibIsLoaded;
}

- (void) windowDidLoad
{
}

- (void) windowWillLoad
{
}

- (void) _windowDidLoad
{
  _wcFlags.nibIsLoaded = YES;

  [self synchronizeWindowTitleWithDocumentName];
  
  /* Make sure window sizes itself right */
  if ([_windowFrameAutosaveName length] > 0)
    {
      [_window setFrameUsingName: _windowFrameAutosaveName];
      [_window setFrameAutosaveName: _windowFrameAutosaveName];
    }

  if ([self shouldCascadeWindows])
    {
      static NSPoint nextWindowLocation  = { 0.0, 0.0 };
      static BOOL firstWindow = YES;

      if (firstWindow)
        {
          NSRect windowFrame = [_window frame];

          /* Start with the frame as set */
          nextWindowLocation = NSMakePoint (NSMinX (windowFrame), 
					    NSMaxY (windowFrame));
          firstWindow = NO;
        }
      else
        {
          /*
           * cascadeTopLeftFromPoint will "wrap" the point back to the
           * top left if the normal cascading will cause the window to go
           * off the screen. In Apple's implementation, this wraps to the
           * extreme top of the screen, and offset only a small amount
           * from the left.
           */
           nextWindowLocation 
	     = [_window cascadeTopLeftFromPoint: nextWindowLocation];
        }
    }

  [self windowDidLoad];
}

- (void) loadWindow
{
  NSDictionary *table;

  if ([self isWindowLoaded]) 
    {
      return;
    }

  table = [NSDictionary dictionaryWithObject: _owner forKey: @"NSOwner"];
  
  if ([NSBundle loadNibFile: [self windowNibPath]
		externalNameTable: table
		withZone: [_owner zone]])
    {
      _wcFlags.nibIsLoaded = YES;
	  
      if (_window == nil  &&  _document != nil  &&  _owner == _document)
        {
	  [self setWindow: [_document _transferWindowOwnership]];
	}
    }
  else
    {
      if (_windowNibName != nil)
        {
	  NSLog (@"%@: could not load nib named %@.nib", 
		 [self class], _windowNibName);
	}
    }
}

- (id) initWithCoder: (NSCoder *)coder
{
  return [self init];
}

- (void) encodeWithCoder: (NSCoder *)coder
{
  // What are we supposed to encode?  Window nib name?  Or should these
  // be empty, just to conform to NSCoding, so we do an -init on
  // unarchival.  ?
}

@end
