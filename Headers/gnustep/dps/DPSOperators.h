/* 
   DPSOperators.h

   Display Postscript operators and functions

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: September, 1995
   
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   If you are interested in a warranty or support for this source code,
   contact Scott Christley <scottc@net-community.com> for more information.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/ 

#ifndef _GNUstep_H_DPSOperators
#define _GNUstep_H_DPSOperators

#include <Foundation/NSObject.h>
#include <DPSClient/TypesandConstants.h>
#include <Foundation/NSGeometry.h>

@class NSColor;

//////////////////////////////////////////////////////////////////////////
//
// Drawing operators
//
// path an arc in counterclockwise direction
void
PSarc(float x, float y, float radius, float angle1, float angle2);

// path an arc in clockwise direction
void
PSarcn(float x, float y, float radius, float angle1, float angle2);

// path a Bezier curve
void
PScurveto(float x1, float y1, float x2, float y2, float x3, float y3);

// path a line
void
PSlineto(float x, float y);

// set current point
void
PSmoveto(float x, float y);

// path a Bezier curve relative to current point
void
PSrcurveto(float x1, float y1, float x2, float y2, float x3, float y3);

// path a line relative to current point
void
PSrlineto(float x, float y);

// set current point relative to current point
void
PSrmoveto(float x, float y);

// path a text string
void
PSshow(char *string);

//
// Path operators
//
// close the path
void
PSclosepath();

// start new path
void
PSnewpath();

// fill the path
void
PSfill();

// stroke the path
void
PSstroke();

//
// Graphic state operators
//
// get current line width
float
PScurrentlinewidth();

// set current line width
void
PSsetlinewidth(float width);

// get current point in path
NSPoint
PScurrentpoint();

// flush graphic operations
void
PSflushgraphics();

// set the color
void
PSsetcolor(NSColor *c);

//
// Convenience operations
//
// path a rectangle
void
PSrectstroke(float x, float y, float width, float height);

// path and fill a rectangle
void
PSrectfill(float x, float y, float width, float height);

#endif /* _GNUstep_H_DPSOperators */
