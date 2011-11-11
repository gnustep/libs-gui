/** <title>CTStringAttribute</title>

   <abstract>C Interface to text layout library</abstract>

   Copyright <copy>(C) 2010 Free Software Foundation, Inc.</copy>

   Author: Eric Wasylishen
   Date: Aug 2010

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
   Lesser General Public License for more details.
   
   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
   */

#ifndef OPAL_CTStringAttributes_h
#define OPAL_CTStringAttributes_h

#include <CoreGraphics/CGBase.h>

/* Constants */

extern const CFStringRef kCTFontAttributeName;
extern const CFStringRef kCTForegroundColorFromContextAttributeName;
extern const CFStringRef kCTKernAttributeName;
extern const CFStringRef kCTLigatureAttributeName;
extern const CFStringRef kCTForegroundColorAttributeName;
extern const CFStringRef kCTParagraphStyleAttributeName;
extern const CFStringRef kCTStrokeWidthAttributeName;
extern const CFStringRef kCTStrokeColorAttributeName;
extern const CFStringRef kCTUnderlineStyleAttributeName;
extern const CFStringRef kCTSuperscriptAttributeName;
extern const CFStringRef kCTUnderlineColorAttributeName;
extern const CFStringRef kCTVerticalFormsAttributeName;
extern const CFStringRef kCTGlyphInfoAttributeName;
extern const CFStringRef kCTCharacterShapeAttributeName;

typedef enum {
  kCTUnderlineStyleNone = 0,
  kCTUnderlineStyleSingle = 1,
  kCTUnderlineStyleThick = 2,
  kCTUnderlineStyleDouble = 9
} CTUnderlineStyle;

typedef enum {
  kCTUnderlinePatternSolid = 0x0000,
  kCTUnderlinePatternDot = 0x0100,
  kCTUnderlinePatternDash = 0x0200,
  kCTUnderlinePatternDashDot = 0x0300,
  kCTUnderlinePatternDashDotDot = 0x0400
} CTUnderlineStyleModifiers;

#endif
