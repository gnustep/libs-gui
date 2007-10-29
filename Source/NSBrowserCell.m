/** <title>NSBrowserCell</title>

   <abstract>Cell class for the NSBrowser</abstract>

   Copyright (C) 1996, 1997, 1999 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   Author: Nicola Pero <n.pero@mi.flashnet.it>
   Date: December 1999

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 3 of the License, or (at your option) any later version.

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

#include "config.h"

#include <Foundation/NSUserDefaults.h>

#include "AppKit/NSBrowserCell.h"
#include "AppKit/NSColor.h"
#include "AppKit/NSFont.h"
#include "AppKit/NSImage.h"
#include "AppKit/NSGraphics.h"
#include "AppKit/NSEvent.h"
#include "AppKit/NSWindow.h"

/*
 * Class variables
 */
static NSImage	*_branch_image;
static NSImage	*_highlight_image;

static Class	_colorClass;

// GNUstep user default to have NSBrowserCell in bold if non leaf
static BOOL _gsFontifyCells = NO;
static NSFont *_nonLeafFont;
static NSFont *_leafFont;

/**<p> TODO Description</p>
 */
@implementation NSBrowserCell

/*
 * Class methods
 */
+ (void) initialize
{
  if (self == [NSBrowserCell class])
    {
      [self setVersion: 1];
      ASSIGN(_branch_image, [NSImage imageNamed: @"common_3DArrowRight"]);
      ASSIGN(_highlight_image, [NSImage imageNamed: @"common_3DArrowRightH"]);

      /*
       * Cache classes to avoid overheads of poor compiler implementation.
       */
      _colorClass = [NSColor class];
      
      // A GNUstep experimental feature
      if ([[NSUserDefaults standardUserDefaults] 
	    boolForKey: @"GSBrowserCellFontify"])
	{
	  _gsFontifyCells = YES;
	  _nonLeafFont = RETAIN ([NSFont boldSystemFontOfSize: 0]);
	  _leafFont = RETAIN ([NSFont systemFontOfSize: 0]);
	}
    }
}

/**<p>Returns the default branch image. Currently, it's an arrow. </p>
 *<p>See Also: +highlightedBranchImage </p>
 */
+ (NSImage*) branchImage
{
  return _branch_image;
}

/**<p>Returns the default hightlited branch image</p>
 *<p>See Also: +branchImage</p>
 */
+ (NSImage*) highlightedBranchImage
{
  return _highlight_image;
}

/*
 * Instance methods
 */
- (id) initTextCell: (NSString *)aString
{
  [super initTextCell: aString];
  //_alternateImage = nil;
  //_browsercell_is_leaf = NO; 
  //_browsercell_is_loaded = NO;

  if (_gsFontifyCells)
    [self setFont: _nonLeafFont];

  return self;
}

- (id) initImageCell: (NSImage *)anImage
{
  [super initImageCell: anImage];
  //_alternateImage = nil;
  //_browsercell_is_leaf = NO; 
  //_browsercell_is_loaded = NO;

  if (_gsFontifyCells)
    [self setFont: _nonLeafFont];
  
  return self;
}


- (void) dealloc
{
  TEST_RELEASE (_alternateImage);

  [super dealloc];
}

- (id) copyWithZone: (NSZone*)zone
{
  NSBrowserCell	*c = [super copyWithZone: zone];

  TEST_RETAIN (_alternateImage);
  //c->_browsercell_is_leaf = _browsercell_is_leaf;
  //c->_browsercell_is_loaded = _browsercell_is_loaded;

  return c;
}

/**<p>Returns the alternate image in the NSBrowserCell
   (used when the cell is highlighted) </p>
   <p>See Also: -setAlternateImage:</p>
 */
- (NSImage*) alternateImage
{
  return _alternateImage;
}

/**<p>Sets the altenate image (used when the cell is highlighted)  to anImage 
 *</p><p>See Also: -alternateImage</p>
 */
- (void) setAlternateImage: (NSImage *)anImage
{
  ASSIGN(_alternateImage, anImage);
}

- (NSColor *)highlightColorInView: (NSView *)controlView
{
  return [_colorClass selectedControlColor];
}

/**<p>Returns whether the browserCell is a leaf. A leaf cell has usually no 
 * image. This method is used by NSBrowser in several methods, for example
 * to know if a column should be added; when the user selects a browser cell
 * (a branch or a leaf)</p>
 * <p>See Also: -setLeaf: </p>
 */
- (BOOL) isLeaf
{
  return _browsercell_is_leaf;
}

/**<p>Sets whether the cell is a leaf. This method is usally used in the 
 * NSBrowser's delegate methods</p>
 *<p>See Also: -isLeaf</p>
 */
- (void) setLeaf: (BOOL)flag
{
  if (_browsercell_is_leaf == flag)
    return;

  _browsercell_is_leaf = flag;
  
  if (_gsFontifyCells)
    {
      if (_browsercell_is_leaf)
	{
	  [self setFont: _leafFont];
	}
      else 
	{
	  [self setFont: _nonLeafFont];
	}
    }
}

/**<p>Returns whether the NSBrowseCell state is set and is ready for 
   display</p> <p>See Also: -setLoaded:</p>
 */
- (BOOL) isLoaded
{
  return _browsercell_is_loaded;
}


/**<p>Sets whether the NSBrowseCell state is set and is ready for display</p>
 * <p>See Also: -isLoaded </p>
 */
- (void) setLoaded: (BOOL)flag
{
  _browsercell_is_loaded = flag;
}

/**
 *<p>Unhighlights the cell and sets the cell's state to NO</p>
 *<p>See Also: -set</p>
 */
- (void) reset
{
  _cell.is_highlighted = NO;
  _cell.state = NO;
}

/**<p>Highlights the cell and sets the cell's state to YES</p>
 *<p>See Also: -reset</p>
 */
- (void) set
{
  _cell.is_highlighted = YES;
  _cell.state = YES;
}

- (void) setType: (NSCellType)aType
{
  /* We do nothing here (we match the Mac OS X behavior) because with
   * NSBrowserCell GNUstep implementation the cell may contain an image 
   * and text at the same time. 
   */
}

/*
 * Displaying
 */
- (void) drawInteriorWithFrame: (NSRect)cellFrame inView: (NSView *)controlView
{
  NSRect	title_rect = cellFrame;
  NSImage	*branch_image = nil;
  NSImage	*cell_image = nil;
  NSColor	*backColor;
  NSWindow      *cvWin = [controlView window];

  if (_cell.is_highlighted || _cell.state)
    {
      backColor = [self highlightColorInView: controlView];
      [backColor set];
      if (!_browsercell_is_leaf)
	branch_image = [isa highlightedBranchImage];
      cell_image = [self alternateImage];
    }
  else
    {
      backColor = [cvWin backgroundColor];
      [backColor set];
      if (!_browsercell_is_leaf)
	branch_image = [isa branchImage];
      cell_image = [self image];
    }
  
  // Clear the background
  NSRectFill(cellFrame);	

  // Draw the branch image if there is one
  if (branch_image) 
    {
      NSSize size;
      NSPoint position;

      size = [branch_image size];
      position.x = MAX(NSMaxX(title_rect) - size.width - 4.0, 0.);
      position.y = MAX(NSMidY(title_rect) - (size.height/2.), 0.);
      /*
       * Images are always drawn with their bottom-left corner at the origin
       * so we must adjust the position to take account of a flipped view.
       */
      if ([controlView isFlipped])
	position.y += size.height;
      [branch_image compositeToPoint: position operation: NSCompositeSourceOver];

      title_rect.size.width -= size.width + 8;
    }

  // Skip 2 points from the left border
  title_rect.origin.x += 2;
  title_rect.size.width -= 2;
  
  // Draw the cell image if there is one
  if (cell_image) 
    {
      NSSize size;
      NSPoint position;
      
      size = [cell_image size];
      position.x = NSMinX(title_rect);
      position.y = MAX(NSMidY(title_rect) - (size.height/2.),0.);
      if ([controlView isFlipped])
	position.y += size.height;
      [cell_image compositeToPoint: position operation: NSCompositeSourceOver];

      title_rect.origin.x += size.width + 4;
      title_rect.size.width -= size.width + 4;
   }

  // Draw the body of the cell
  [self _drawAttributedText: [self attributedStringValue]
	inFrame: title_rect];
}

- (BOOL) isOpaque
{
  return YES;
}

/*
 * NSCoding protocol
 */
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];
  if ([aCoder allowsKeyedCoding])
    {
      // simply encodes prescence...
    }
  else
    {
      BOOL tmp;
      tmp = _browsercell_is_leaf;
      [aCoder encodeValueOfObjCType: @encode(BOOL) at: &tmp];
      tmp = _browsercell_is_loaded;
      [aCoder encodeValueOfObjCType: @encode(BOOL) at: &tmp];
      [aCoder encodeObject: _alternateImage];
    }
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  [super initWithCoder: aDecoder];

  if ([aDecoder allowsKeyedCoding])
    {
      // Nothing to decode...
    }
  else
    {
      BOOL tmp;

      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &tmp];
      [self setLeaf: tmp];
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &tmp];
      [self setLoaded: tmp];
      [aDecoder decodeValueOfObjCType: @encode(id) at: &_alternateImage];
    }
  
  return self;
}

@end
