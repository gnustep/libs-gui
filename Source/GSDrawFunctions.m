/** <title>GSDrawFunctions</title>

   <abstract>Useful/configurable drawing functions</abstract>

   Copyright (C) 2004 Free Software Foundation, Inc.

   Author: Adam Fedor <fedor@gnu.org>
   Date: Jan 2004
   
   This file is part of the GNU Objective C User interface library.

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

#include "GNUstepGUI/GSDrawFunctions.h"
#include "AppKit/NSColor.h"
#include "AppKit/NSView.h"
#include "AppKit/NSGraphics.h"
#include "AppKit/PSOperators.h"


/**
  <unit>
  <heading>Class Description</heading>
  <p>
  This is a simple class used for encapsulating common drawing behaviors.
  These methods standardize drawing of buttons, borders and other common
  GUI elements. The drawing functions are encapsulated in a class to
  allow overriding of the methods so that these elements can be drawn
  in different ways (e.g. with themes).
  </p>
  <p>
  The default implementation uses the standard configurable colors defined in 
  NSColor, such as <code>controlLightHighlightColor</code>,
  <code>controlShadowColor</code> and  <code>controlDarkShadowColor</code>.
  </p>
  </unit>
*/ 
@implementation GSDrawFunctions

/** Draw a button border */
+ (void) drawButton: (NSRect)border : (NSRect)clip
{
  NSRectEdge up_sides[] = {NSMaxXEdge, NSMinYEdge, 
			   NSMinXEdge, NSMaxYEdge, 
			   NSMaxXEdge, NSMinYEdge};
  NSRectEdge dn_sides[] = {NSMaxXEdge, NSMaxYEdge, 
			     NSMinXEdge, NSMinYEdge, 
			     NSMaxXEdge, NSMaxYEdge};
  NSColor *colors[] = {[NSColor controlDarkShadowColor],
		       [NSColor controlDarkShadowColor],
		       [NSColor controlLightHighlightColor],
		       [NSColor controlLightHighlightColor],
		       [NSColor controlShadowColor],
		       [NSColor controlShadowColor]};
  if ([[NSView focusView] isFlipped] == YES)
    {
      NSDrawColorTiledRects(border, clip, dn_sides, colors, 8);
    }
  else
    {
      NSDrawColorTiledRects(border, clip, up_sides, colors, 8);
    }
}

/** Draw a dark bezel border */
+ (void) drawDarkBezel: (NSRect)border : (NSRect)clip
{
  NSRectEdge up_sides[] = {NSMaxXEdge, NSMinYEdge, NSMinXEdge, NSMaxYEdge,
			   NSMinXEdge, NSMaxYEdge, NSMaxXEdge, NSMinYEdge};
  NSRectEdge dn_sides[] = {NSMaxXEdge, NSMaxYEdge, NSMinXEdge, NSMinYEdge,
			   NSMinXEdge, NSMinYEdge, NSMaxXEdge, NSMaxYEdge};
  NSColor *colors[] = {[NSColor controlLightHighlightColor],
		       [NSColor controlLightHighlightColor],
		       [NSColor controlShadowColor],
		       [NSColor controlShadowColor],
		       [NSColor controlDarkShadowColor],
		       [NSColor controlDarkShadowColor],
		       [NSColor controlColor],
		       [NSColor controlColor]};
  
  if ([[NSView focusView] isFlipped] == YES)
    {
      NSDrawColorTiledRects(border, clip, dn_sides, colors, 8);
  
      [[NSColor controlShadowColor] set];
      PSrectfill(NSMinX(border) + 1., NSMinY(border) - 2., 1., 1.);
      PSrectfill(NSMaxX(border) - 2., NSMaxY(border) + 1., 1., 1.);
    }
  else
    {
      NSDrawColorTiledRects(border, clip, up_sides, colors, 8);
  
      [[NSColor controlShadowColor] set];
      PSrectfill(NSMinX(border) + 1., NSMinY(border) + 1., 1., 1.);
      PSrectfill(NSMaxX(border) - 2., NSMaxY(border) - 2., 1., 1.);
    }
}

/** Draw a light bezel border */
+ (void) drawLightBezel: (NSRect) border : (NSRect)clip
{
  NSRectEdge up_sides[] = {NSMaxXEdge, NSMinYEdge, NSMinXEdge, NSMaxYEdge, 
  			   NSMaxXEdge, NSMinYEdge, NSMinXEdge, NSMaxYEdge};
  NSRectEdge dn_sides[] = {NSMaxXEdge, NSMaxYEdge, NSMinXEdge, NSMinYEdge, 
			   NSMaxXEdge, NSMaxYEdge, NSMinXEdge, NSMinYEdge};
  NSColor *colors[] = {[NSColor controlLightHighlightColor],
		       [NSColor controlLightHighlightColor],
		       [NSColor controlShadowColor],
		       [NSColor controlShadowColor],
		       [NSColor controlColor],
		       [NSColor controlColor],
		       [NSColor controlShadowColor],
		       [NSColor controlShadowColor]};

  if ([[NSView focusView] isFlipped] == YES)
    {
      NSDrawColorTiledRects(border, clip, dn_sides, colors, 8);
    }
  else
    {
      NSDrawColorTiledRects(border, clip, up_sides, colors, 8);
    }
}

/** Draw a groove border */
+ (void) drawGroove: (NSRect)border : (NSRect)clip
{
  // go clockwise from the top twice -- makes the groove come out right
  NSRectEdge up_sides[] = {NSMaxYEdge, NSMaxXEdge, NSMinYEdge, NSMinXEdge,
			   NSMaxYEdge, NSMaxXEdge, NSMinYEdge, NSMinXEdge};
  NSRectEdge dn_sides[] = {NSMinYEdge, NSMaxXEdge, NSMaxYEdge, NSMinXEdge,
			   NSMinYEdge, NSMaxXEdge, NSMaxYEdge, NSMinXEdge};
  NSColor *colors[] = {[NSColor controlShadowColor],
		       [NSColor controlLightHighlightColor],
		       [NSColor controlLightHighlightColor],
		       [NSColor controlShadowColor],
		       [NSColor controlLightHighlightColor],
		       [NSColor controlShadowColor],
		       [NSColor controlShadowColor],
		       [NSColor controlLightHighlightColor]};

  if ([[NSView focusView] isFlipped] == YES)
    {
      NSDrawColorTiledRects(border, clip, dn_sides, colors, 8);
    }
  else
    {
      NSDrawColorTiledRects(border, clip, up_sides, colors, 8);
    }
}

/** Draw a frame photo border.  Used in NSImageView.   */
+ (void) drawFramePhoto: (NSRect) border : (NSRect)clip
{
  NSRectEdge up_sides[] = {NSMaxXEdge, NSMinYEdge, 
			   NSMinXEdge, NSMaxYEdge, 
			   NSMaxXEdge, NSMinYEdge};
  NSRectEdge dn_sides[] = {NSMaxXEdge, NSMaxYEdge, 
			   NSMinXEdge, NSMinYEdge, 
			   NSMaxXEdge, NSMaxYEdge};
  NSColor *colors[] = {[NSColor controlShadowColor],
		       [NSColor controlShadowColor],
		       [NSColor controlShadowColor],
		       [NSColor controlShadowColor],
		       [NSColor controlDarkShadowColor],
		       [NSColor controlDarkShadowColor]};

  if ([[NSView focusView] isFlipped] == YES)
    {
      NSDrawColorTiledRects(border, clip, dn_sides, colors, 8);
    }
  else
    {
      NSDrawColorTiledRects(border, clip, up_sides, colors, 8);
    }
}

@end
