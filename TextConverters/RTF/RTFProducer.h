/*
 RTFProducer.h

 Writes out a NSAttributedString as RTF

 Copyright (C) 2000 Free Software Foundation, Inc.

 Author: Fred Kiefer <FredKiefer@gmx.de>
 Date: June 2000
 Modifications: Axel Katerbau <axel@objectpark.org>
 Date: April 2003

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

#ifndef _GNUstep_H_RTFDProducer
#define _GNUstep_H_RTFDProducer

#include <AppKit/GSTextConverter.h>
//#include "GSTextConverter.h"

@class NSAttributedString;
@class NSMutableDictionary;
@class NSColor;
@class NSFont;
@class NSMutableParagraphStyle;

@interface RTFDProducer: NSObject <GSTextProducer>
{
  @public
  NSAttributedString *text;
  NSMutableDictionary *fontDict;
  NSMutableDictionary *colorDict;
  NSMutableDictionary *docDict;
  NSMutableArray *attachments;

  NSColor *fgColor;
  NSColor *bgColor;

  NSDictionary *_attributesOfLastRun; /*" holds the attributes of the last run
    to build the delta "*/

  BOOL _inlineGraphics; /*" Indicates if graphics should be inlined. "*/
}

+ (NSData *)produceDataFrom: (NSAttributedString *)aText
         documentAttributes: (NSDictionary *)dict;

+ (NSFileWrapper *)produceFileFrom: (NSAttributedString *)aText
                documentAttributes: (NSDictionary *)dict;

@end

@interface RTFProducer: RTFDProducer
// Subclass with no special interface
@end

#endif
