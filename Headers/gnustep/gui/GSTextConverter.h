/*                                                    -*-objc-*-
   GSTextConverter.h

   Define two protocols for text converter that will either read an external
   format from a file or data object into an attributed string or write out
   an attributed string in a format into a file or data object.

   Copyright (C) 2001 Free Software Foundation, Inc.

   Author: Fred Kiefer <FredKiefer@gmx.de>
   Date: August 2001

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

#ifndef _GNUstep_H_GSTextConverter
#define _GNUstep_H_GSTextConverter

#include <Foundation/NSAttributedString.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSData.h>

@class NSFileWrapper;

@protocol GSTextProducer
+ (NSData*) produceDataFrom: (NSAttributedString*) aText
	 documentAttributes: (NSDictionary*)dict;
+ (NSFileWrapper*) produceFileFrom: (NSAttributedString*) aText
		documentAttributes: (NSDictionary*)dict;
@end

@protocol GSTextConsumer
+ (NSAttributedString*) parseData: (NSData *)aData 
	       documentAttributes: (NSDictionary **)dict;
+ (NSAttributedString*) parseFile: (NSFileWrapper *)aFile 
	       documentAttributes: (NSDictionary **)dict;
@end

#endif // _GNUstep_H_GSTextConverter
