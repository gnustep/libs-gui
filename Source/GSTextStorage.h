/* 
   GSTextStorage.h

   Implementation of concrete subclass of a string class with attributes

   Copyright (C) 1999 Free Software Foundation, Inc.

   Based on code by: ANOQ of the sun <anoq@vip.cybercity.dk>
   Written by: Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date: July 1999
   
   This file is part of GNUStep-gui

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
#include <AppKit/NSTextStorage.h>

@class NSMutableString;
@class NSMutableArray;

@interface GSTextStorage : NSTextStorage
{
  NSMutableString       *_textChars;
  NSMutableArray        *_infoArray;
  NSString		*_textProxy;
}
@end

