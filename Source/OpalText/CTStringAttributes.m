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

#include <CoreText/CTStringAttributes.h>

/* Constants */

const CFStringRef kCTFontAttributeName = @"kCTFontAttributeName";
const CFStringRef kCTForegroundColorFromContextAttributeName = @"kCTForegroundColorFromContextAttributeName";
const CFStringRef kCTKernAttributeName = @"kCTKernAttributeName";
const CFStringRef kCTLigatureAttributeName = @"kCTLigatureAttributeName";
const CFStringRef kCTForegroundColorAttributeName = @"kCTForegroundColorAttributeName";
const CFStringRef kCTParagraphStyleAttributeName = @"kCTParagraphStyleAttributeName";
const CFStringRef kCTStrokeWidthAttributeName = @"kCTStrokeWidthAttributeName";
const CFStringRef kCTStrokeColorAttributeName = @"kCTStrokeColorAttributeName";
const CFStringRef kCTUnderlineStyleAttributeName = @"kCTUnderlineStyleAttributeName";
const CFStringRef kCTSuperscriptAttributeName = @"kCTSuperscriptAttributeName";
const CFStringRef kCTUnderlineColorAttributeName = @"kCTUnderlineColorAttributeName";
const CFStringRef kCTVerticalFormsAttributeName = @"kCTVerticalFormsAttributeName";
const CFStringRef kCTGlyphInfoAttributeName = @"kCTGlyphInfoAttributeName";
const CFStringRef kCTCharacterShapeAttributeName = @"kCTCharacterShapeAttributeName";

