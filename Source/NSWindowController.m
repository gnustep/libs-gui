/*
   NSWindowController.m

   Copyright (C) 2000 Free Software Foundation, Inc.

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
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#import <AppKit/NSWindowController.h>
#import <AppKit/NSPanel.h>
#import <AppKit/NSNibLoading.h>
#import <AppKit/NSDocumentFrameworkPrivate.h>

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

  ASSIGN (_window, window);
  _windowFrameAutosaveName = @"";
  _wcFlags.shouldCascade = YES;
  _wcFlags.shouldCloseDocument = NO;

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
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  RELEASE(_windowNibName);
  RELEASE(_windowNibPath);
  RELEASE(_windowFrameAutosaveName);
  RELEASE(_topLevelObjects);
  AUTORELEASE (_window); /* FIXME - should be RELEASE I think */
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

    // This is not fully correct as nib resources are searched different.
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

- (void) setDocument: (NSDocument *)document
{
  // FIXME - this is RETAINed and never RELEASEd ...
  ASSIGN (_document, document);
  [self synchronizeWindowTitleWithDocumentName];

  if (_document != nil)
    {
      [_window setReleasedWhenClosed: YES];
    }
  else
    {
      /* If you want the window to be deallocated when closed, you
	 need to observe the NSWindowWillCloseNotification (or
	 implement the window's delegate windowWillClose: method) and
	 autorelease the window controller in that method.  That will
	 then release the window when the window controller is
	 released. */
      [_window setReleasedWhenClosed: NO];
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

- (NSString *) windowFrameAutosaveName;
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
	   * itself, so nil out our reference so we don't release it again
	   * 
	   * Apple's implementation doesn't seem to deal with this case, and
	   * crashes if isReleaseWhenClosed is set.
	   */
	  _window = nil;

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

- (void) setWindow: (NSWindow *)aWindow
{
  ASSIGN (_window, aWindow);
  if (_document != nil)
    {
      [_window setReleasedWhenClosed: YES];
    }
  else
    {
      [_window setReleasedWhenClosed: NO];
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
  if (_document != nil)
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

  [_window setWindowController: self];

  [self synchronizeWindowTitleWithDocumentName];
  
  [[NSNotificationCenter defaultCenter]
                addObserver: self
                selector: @selector(_windowWillClose:)
                name: NSWindowWillCloseNotification
                object: _window];

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
  if ([self isWindowLoaded]) 
    {
      return;
    }

  if ((_windowNibName == nil) && (_windowNibPath != nil))
    {
      NSDictionary *table;

      table = [NSDictionary dictionaryWithObject: _owner forKey: @"NSOwner"];
	
      if ([NSBundle loadNibFile: _windowNibPath
		    externalNameTable: table
		    withZone: [_owner zone]])
        {
	  _wcFlags.nibIsLoaded = YES;
	  
	  if (_window == nil  &&  _document != nil  &&  _owner == _document)
	    {
	      [self setWindow: [_document _transferWindowOwnership]];
	    }
	  return;
	}
    }

  if ([NSBundle loadNibNamed: _windowNibName  owner: _owner])
    {
      _wcFlags.nibIsLoaded = YES;

      if (_window == nil  &&  _document != nil  &&  _owner == _document)
	{
	  [self setWindow: [_document _transferWindowOwnership]];
	}
    }
  else
    {
      // FIXME: We should still try the main bundle
      NSLog (@"%@: could not load nib named %@.nib", 
	     [self class], _windowNibName);
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
