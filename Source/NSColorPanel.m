/* 
   NSColorPanel.m

   System generic color panel

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   
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

#include <gnustep/gui/config.h>
#include <Foundation/NSBundle.h>
#include <Foundation/NSEnumerator.h>
#include <Foundation/NSFileManager.h>
#include <Foundation/NSLock.h>
#include <Foundation/NSPathUtilities.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSColorPanel.h>
#include <AppKit/NSColorPicker.h>
#include <AppKit/NSColorPicking.h>
#include <AppKit/NSColorWell.h>
#include <AppKit/NSPasteboard.h>
#include <AppKit/NSWindow.h>
#include <AppKit/IMLoading.h>

static NSLock *_gs_gui_color_panel_lock = nil;
static NSColorPanel *_gs_gui_color_panel = nil;
static int _gs_gui_color_picker_mask = NSColorPanelAllModesMask;
static int _gs_gui_color_picker_mode = NSRGBModeColorPanel;

@interface GSAppKitPanelController : NSObject
{
@public
  id panel;
}
@end

@implementation GSAppKitPanelController
@end

@interface NSColorPanel (PrivateMethods)
- (void) _loadPickers;
- (void) _loadPickerAtPath: (NSString *)path;
- (void) _fixupMatrix;
- (void) _setupPickers;
- (void) _showNewPicker: (id)sender;
@end

@implementation NSColorPanel (PrivateMethods)

- (void) _loadPickers
{
  NSArray *paths;
  NSString *path;
  NSEnumerator *pathEnumerator;
  NSArray *bundles;
  NSEnumerator *bundleEnumerator;
  NSString *bundleName;

  _pickers = [NSMutableArray new];

  paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
                                              NSAllDomainsMask, YES);

  pathEnumerator = [paths objectEnumerator];
  while ((path = [pathEnumerator nextObject]))
    {
      path = [path stringByAppendingPathComponent: @"ColorPickers"];
      bundles = [[NSFileManager defaultManager] directoryContentsAtPath: path];

      bundleEnumerator = [bundles objectEnumerator];
      while ((bundleName = [bundleEnumerator nextObject]))
        [self _loadPickerAtPath:
            [path stringByAppendingPathComponent: bundleName]];
    }

  paths = [[NSBundle mainBundle] pathsForResourcesOfType: @"bundle"
                                             inDirectory: @"ColorPickers"];

  pathEnumerator = [paths objectEnumerator];
  while ((path = [pathEnumerator nextObject]))
    [self _loadPickerAtPath: path];
}

- (void) _loadPickerAtPath: (NSString *)path
{
  NSBundle *bundle;
  Class pickerClass;
  NSColorPicker *picker;

  bundle = [NSBundle bundleWithPath: path];
  if (bundle && (pickerClass = [bundle principalClass]))
    {
      picker = [[pickerClass alloc] initWithPickerMask:_gs_gui_color_picker_mask
                                            colorPanel:_gs_gui_color_panel];
      if (picker && [picker conformsToProtocol:@protocol(NSColorPickingCustom)])
        {
          [picker provideNewView: YES];
          [_pickers addObject: picker];
        }
      else
        NSLog(@"%@ does not contain a valid color picker.");
    }
}

// FIXME - this is a HACK to get around problems in the gmodel code
- (void) _fixupMatrix
{
  [_pickerMatrix setFrame: NSMakeRect(4, 190, 192, 36)];
}

- (void) _setupPickers
{
  NSColorPicker *picker;
  NSButtonCell *cell;
  NSMutableArray *cells = [NSMutableArray new];
  int i, count;
  NSSize size = [_pickerMatrix frame].size;

  count = [_pickers count];
  for (i = 0; i < count; i++)
    {
      cell = [[_pickerMatrix prototype] copy];
      [cell setTag: i];
      picker = [_pickers objectAtIndex: i];
      [picker insertNewButtonImage: [picker provideNewButtonImage] in: cell];
      [cells addObject: cell];
    }

  [_pickerMatrix addRowWithCells: cells];
  [_pickerMatrix setCellSize: NSMakeSize(size.width / count, size.height)];
  [_pickerMatrix setTarget: self];
  [_pickerMatrix setAction: @selector(_showNewPicker:)];

  // use the space occupied by the matrix of color picker buttons if the
  // button matrix is useless, i.e. it contains only one button
  if (count < 2)
    {
      [_pickerBox setFrame: NSUnionRect([_pickerBox frame],
                                        [_pickerMatrix frame])];
      [_pickerBox setNeedsDisplay: YES];
    }
}

- (void) _showNewPicker: (id)sender
{
  _currentPicker = [_pickers objectAtIndex: [sender selectedColumn]];
  [_pickerBox setContentView: [_currentPicker provideNewView: NO]];
}
@end

@implementation NSColorPanel

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSColorPanel class])
    {
      // Initial version
      [self setVersion:1];
      _gs_gui_color_panel_lock = [NSLock new];
    }
}

//
// Creating the NSColorPanel 
//
+ (NSColorPanel *)sharedColorPanel
{
  if (_gs_gui_color_panel == nil)
    {
      [_gs_gui_color_panel_lock lock];
      if (!_gs_gui_color_panel)
        {
          GSAppKitPanelController *panelCtrl = [GSAppKitPanelController new];

          if ([GMModel loadIMFile:@"ColorPanel" owner:panelCtrl])
            {
              _gs_gui_color_panel = panelCtrl->panel;
              [_gs_gui_color_panel _fixupMatrix];
              [_gs_gui_color_panel _loadPickers];
              [_gs_gui_color_panel _setupPickers];
            }
        }
      [_gs_gui_color_panel_lock unlock];
    }

  //[_gs_gui_color_panel setMode: _gs_gui_color_picker_mode];
  [_gs_gui_color_panel setMode: NSColorListModeColorPanel];
  return _gs_gui_color_panel;
}

+ (BOOL)sharedColorPanelExists
{
  return (_gs_gui_color_panel == nil) ? NO : YES;
}

//
// Setting the NSColorPanel 
//
+ (void)setPickerMask:(int)mask
{
  _gs_gui_color_picker_mask = mask;
}

+ (void)setPickerMode:(int)mode
{
  _gs_gui_color_picker_mode = mode;
}

//
// Setting Color
//
+ (BOOL)dragColor:(NSColor *)aColor
        withEvent:(NSEvent *)anEvent
         fromView:(NSView *)sourceView
{
  NSPasteboard *pb = [NSPasteboard pasteboardWithName: NSDragPboard];
  NSImage *image = [NSImage imageNamed: @"colorwell_DragImage"];

  [pb declareTypes: [NSArray arrayWithObjects: NSColorPboardType, nil]
             owner: aColor];
  [aColor writeToPasteboard: pb];
  [image setBackgroundColor: aColor];

  [sourceView dragImage: image
                     at: [sourceView frame].origin
                 offset: NSMakeSize(0,0)
                  event: anEvent
             pasteboard: pb
                 source: sourceView
              slideBack: NO];

  return YES;
}

//
// Instance methods
//

//
// Setting the NSColorPanel 
//
- (NSView *)accessoryView
{
  return [_accessoryBox contentView];
}

- (BOOL)isContinuous
{
  return _isContinuous;
}

- (int)mode
{
  if (_currentPicker != nil)
    return [_currentPicker currentMode];
  else
    return 0;
}

- (void)setAccessoryView:(NSView *)aView
{
  [_accessoryBox setContentView: aView];
  // [_accessoryBox sizeToFit];
}

- (void)setAction:(SEL)aSelector
{
  _action = aSelector;
}

- (void)setContinuous:(BOOL)flag
{
  _isContinuous = flag;
}

- (void)setMode:(int)mode
{
  int i, count;

  if (mode == [self mode])
    return;

  count = [_pickers count];
  for (i = 0; i < count; i++)
    {
      if ([[_pickers objectAtIndex: i] supportsMode: mode])
        break;
    }

  // if i == count, no picker was found
  if (i != count)
    {
      [_pickerMatrix selectCellWithTag: i];
      [self _showNewPicker: _pickerMatrix];
    }
}

// This code is very simple-minded.  Instead of removing the alpha slider,
// why not just cover it up?

- (void)setShowsAlpha:(BOOL)flag
{
  if (flag && ![self showsAlpha])
    {
      NSRect newFrame = [_pickerBox frame];
      float offset = [_alphaSlider frame].size.height + 4;

      newFrame.origin.y += offset;
      newFrame.size.height -= offset;
      [_pickerBox setFrame: newFrame];
    }
  else
    {
      [_pickerBox setFrame: NSUnionRect([_pickerBox frame],
                                        [_alphaSlider frame])];
    }

  [_pickers makeObjectsPerformSelector: @selector(alphaControlAddedOrRemoved:)
                            withObject: self];

  [_topView setNeedsDisplay: YES];
}

- (void)setTarget:(id)anObject
{
  ASSIGN(_target, anObject);
}

- (BOOL)showsAlpha
{
  if (NSIntersectsRect([_pickerBox frame], [_alphaSlider frame]))
    return NO;
  else
    return YES;
}

//
// Attaching a Color List
//
- (void)attachColorList:(NSColorList *)aColorList
{
  NSEnumerator *enumerator;
  id picker;

  if ((_pickers != nil) && ([_pickers count] > 0))
    {
      enumerator = [_pickers objectEnumerator];
      while ((picker = [enumerator nextObject]))
        [picker attachColorList: aColorList];
    }
}

- (void)detachColorList:(NSColorList *)aColorList
{
  NSEnumerator *enumerator;
  id picker;

  if ((_pickers != nil) && ([_pickers count] > 0))
    {
      enumerator = [_pickers objectEnumerator];
      while ((picker = [enumerator nextObject]))
        [picker detachColorList: aColorList];
    }
}

//
// Setting Color
//
- (float)alpha
{
  if ([self showsAlpha])
    return [_alphaSlider floatValue];
  else
    return 1.0;
}

- (NSColor *)color
{
  return [_colorWell color];
}

- (void)setColor:(NSColor *)aColor
{
  [_colorWell setColor: aColor];
  [[NSNotificationCenter defaultCenter]
      postNotificationName: NSColorPanelColorChangedNotification
                    object: (id)self];
}

//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  [super initWithCoder: aDecoder];

  return self;
}

@end
