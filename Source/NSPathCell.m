/* Implementation of class NSPathCell
   Copyright (C) 2020 Free Software Foundation, Inc.
   
   By: Gregory John Casamento
   Date: Wed Apr 22 18:19:07 EDT 2020

   This file is part of the GNUstep Library.
   
   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.
   
   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110 USA.
*/

#import "AppKit/NSPathCell.h"
#import "AppKit/NSWorkspace.h"
#import "AppKit/NSImage.h"
#import "AppKit/NSPathComponentCell.h"

@interface NSPathCell (Private)
+ (NSArray *) _generateCellsForURL: (NSURL *)url;
@end

@interface NSPathComponentCell (Private)
- (void) _setLastComponent: (BOOL)f;
@end

@implementation NSPathCell

- (void)mouseEntered:(NSEvent *)event 
           withFrame:(NSRect)frame 
              inView:(NSView *)view
{
}

- (void)mouseExited:(NSEvent *)event 
          withFrame:(NSRect)frame 
             inView:(NSView *)view
{
}

- (void) setAllowedTypes: (NSArray *)types
{
  ASSIGNCOPY(_allowedTypes, types);
}

- (NSArray *) allowedTypes
{
  return _allowedTypes;
}

- (NSPathStyle) pathStyle
{
  return _pathStyle;
}

- (void) setPathStyle: (NSPathStyle)pathStyle
{
  _pathStyle = pathStyle;
}

- (void) setControlSize: (NSControlSize)size
{
  _controlSize = size;
}

- (void) setObjectValue: (id)obj
{
  ASSIGN(_objectValue, obj);
}

- (NSAttributedString *) placeholderAttributedString
{
  return _placeholderAttributedString; 
}

- (void) setPlaceholderAttributedString: (NSAttributedString *)string
{
  ASSIGNCOPY(_placeholderAttributedString, string);
}

- (NSString *) placeholderString
{
  return _placeholderString;
}

- (void) setPlaceholderString: (NSString *)string
{
  ASSIGNCOPY(_placeholderString, string);
}

- (NSColor *) backgroundColor
{
  return _backgroundColor;
}

- (void) setBackgroundColor: (NSColor *)color
{
  ASSIGNCOPY(_backgroundColor, color);
}

+ (Class) pathComponentCellClass
{
  return pathComponentCellClass;
}

+ (void) setPathComponentCellClass: (Class)clz
{
  pathComponentCellClass = clz;
}

- (NSRect)rectOfPathComponentCell:(NSPathComponentCell *)cell 
                        withFrame:(NSRect)frame 
                           inView:(NSView *)view
{
  return NSZeroRect;
}

- (NSPathComponentCell *)pathComponentCellAtPoint:(NSPoint)point 
                                        withFrame:(NSRect)frame 
                                           inView:(NSView *)view
{
  return nil;
}

- (NSPathComponentCell *) clickedPathComponentCell
{
  return nil;
}

- (NSArray *) pathComponentCells
{
  return _pathComponentCells;
}

- (void) setPathComponentCells: (NSArray *)cells
{
  ASSIGNCOPY(_pathComponentCells, cells);
}

- (SEL) doubleAction
{
  return _doubleAction;
}

- (void) setDoubleAction: (SEL)action
{
  _doubleAction = action;
}

- (NSURL *) URL
{
  return _url;
}

- (void) setURL: (NSURL *)url
{
  ASSIGNCOPY(_url, url);
  [self setPathComponentCells: [NSPathCell _generateCellsForURL: url]];
}

- (id<NSPathCellDelegate>) delegate
{
  return _delegate;
}

- (void) setDelegate: (id<NSPathCellDelegate>)delegate
{
  _delegate = delegate;
}

- (void) drawInteriorWithFrame: (NSRect)frame inView: (NSView *)controlView
{
  NSUInteger count = [_pathComponentCells count];

  [super drawInteriorWithFrame: frame
                        inView: controlView];
  if (count > 0)
    {
      NSEnumerator *en = [_pathComponentCells objectEnumerator];
      NSPathComponentCell *cell = nil;
      CGFloat cell_width = (frame.size.width / (CGFloat)[_pathComponentCells count]);
      CGFloat current_x = 0.0;
      
      while((cell = (NSPathComponentCell *)[en nextObject]) != nil)
        {
          NSRect f = NSMakeRect(current_x, 0.0, cell_width, frame.size.height);
          [cell drawInteriorWithFrame: f
                               inView: controlView];
          current_x += cell_width;
        }
    }
}

- (id) initWithCoder: (NSCoder *)coder
{
  if ([coder allowsKeyedCoding])
    {
      [self setPathStyle: NSPathStyleStandard];
      
      // if ([coder containsValueForKey: @"NSPathStyle"]) // can't seem to find it in the contains method,
      // but it does when I decode it... not sure why.
        {
          [self setPathStyle: [coder decodeIntegerForKey: @"NSPathStyle"]];
        }
      
      if ([coder containsValueForKey: @"NSPathComponentCells"])
        {
          [self setPathComponentCells: [coder decodeObjectForKey: @"NSPathComponentCells"]];
        }
    }
  else
    {
      [coder decodeValueObjCType: @encode(NSUInteger)
                              at: &_pathStyle];
      [self setPathComponentCells: [coder decodeObject]];
    }

  return self;
}

- (void) encodeWithCoder: (NSCoder *)coder
{
  if ([coder allowsKeyedCoding])
    {
      [coder encodeInteger: [self pathStyle]
                    forKey: @"NSPathStyle"];
      [coder encodeObject: [self pathComponentCells]
                   forKey: @"NSPathComponentCells"]
    }
  else
    {
      [coder encodeValueObjCType: @encode(NSUInteger)
                              at: &_pathStyle];
      [coder encodeObject: [self pathComponentCells]];
    }
}

@end

@implementation NSPathCell (Private)

// Private...
+ (NSArray *) _generateCellsForURL: (NSURL *)url
{
  NSMutableArray *array = [NSMutableArray arrayWithCapacity: 10];
    
  // Create cells
  if (url != nil)
    {
      NSString *string = nil;
      BOOL isDir = NO;
      BOOL at_root = NO;
      NSFileManager *fm = [NSFileManager defaultManager];
            
      // Decompose string...
      do
        {
          NSPathComponentCell *cell = [[NSPathComponentCell alloc] init];
          NSImage *image = nil;

          AUTORELEASE(cell);
          [cell setURL: url];
          [fm fileExistsAtPath: [url path]
               isDirectory: &isDir];

          if ([[url path] isEqualToString: @"/"])
            {
              at_root = YES;
            }

          if (isDir && at_root == NO)
            {
              image = [NSImage imageNamed: @"NSFolder"];
            }
          else
            {
              image = [[NSWorkspace sharedWorkspace] iconForFile: [[url path] lastPathComponent]];
            }

          [cell setImage: image];
          string = [string stringByDeletingLastPathComponent];

          if ([array count] == 0) // the element we are adding is the last component that will show
            {
              [cell _setLastComponent: YES];
            }
          else
            {
              [cell _setLastComponent: NO];
            }
          
          [array insertObject: cell
                      atIndex: 0];
          url = [NSURL URLWithString: string
                       relativeToURL: nil];
          if (url == nil && at_root == NO)
            {
              // Because when we remove the last path component
              // all that is left is a blank... so we add the "/" so that
              // it is shown.
              url = [NSURL URLWithString: @"/"];
            }
        }
      while (at_root == NO);
    }
  
  return [array copy];
}

@end

@implementation NSPathComponentCell (Private)

- (void) _setLastComponent: (BOOL)f
{
  _lastComponent = f;
}

@end
