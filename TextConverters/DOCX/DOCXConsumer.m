/* attributedStringConsumer.m

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:  Stefan Böhringer (stefan.boehringer@uni-bochum.de)
   Date: Dec 1999
   Author: Fred Kiefer <FredKiefer@gmx.de>
   Date: June 2000

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

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

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <GNUstepGUI/GSHelpAttachment.h>

#import "DOCXConsumer.h"
// #import "DOCXConsumerFunctions.h"
#import "DOCXProducer.h"

@implementation DOCXConsumer

/* RTFConsumer is the principal class and thus implements this */
+ (Class) classForFormat: (NSString *)format producer: (BOOL)flag
{
  Class cClass = Nil;

  return cClass;
}

+ (NSAttributedString*) parseFile: (NSFileWrapper *)wrapper
                          options: (NSDictionary *)options
	       documentAttributes: (NSDictionary **)dict
                            error: (NSError **)error
			    class: (Class)class
{
  NSAttributedString *text = nil;

  return text;
}

+ (NSAttributedString*) parseData: (NSData *)rtfData 
                          options: (NSDictionary *)options
	       documentAttributes: (NSDictionary **)dict
                            error: (NSError **)error
			    class: (Class)class
{
  // DOCXConsumer *consumer = [DOCXConsumer new];
  NSAttributedString *text = nil;

  return text;
}

- (id) init
{
  ignore = 0;  
  result = nil;
  encoding = NSISOLatin1StringEncoding;
  documentAttributes = nil;
  fonts = nil;
  attrs = nil;
  colours = nil;
  _class = Nil;

  return self;
}

- (void) dealloc
{
  RELEASE(fonts);
  RELEASE(attrs);
  RELEASE(colours);
  RELEASE(result);
  RELEASE(documentAttributes);
  [super dealloc];
}

@end
