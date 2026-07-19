/** <title>NSTokenFieldCell</title>

   <abstract>Cell class for the token field entry control</abstract>

   Copyright (C) 2008 Free Software Foundation, Inc.

   Author: Gregory Casamento <greg.casamento@gmail.com>
   Date: July 2008
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

#include "config.h"
#import <Foundation/NSNotification.h>
#import <Foundation/NSCharacterSet.h>
#import "AppKit/NSControl.h"
#import "AppKit/NSEvent.h"
#import "AppKit/NSTokenField.h"
#import "AppKit/NSTokenFieldCell.h"


@implementation NSTokenFieldCell
+ (void) initialize
{
  if (self == [NSTokenFieldCell class])
    {
      [self setVersion: 2];
    }
}

- (id) initTextCell: (NSString*)aString
{
  self = [super initTextCell: aString];
  if (self != nil)
    {
      ASSIGN(tokenizingCharacterSet,
        [[self class] defaultTokenizingCharacterSet]);
      completionDelay = [[self class] defaultCompletionDelay];
    }
  return self;
}

- (void) dealloc
{
  RELEASE(tokenizingCharacterSet);
  [super dealloc];
}

//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];

  if ([aCoder allowsKeyedCoding])
    {
      [aCoder encodeInt: tokenStyle forKey: @"NSTokenStyle"];
      [aCoder encodeDouble: completionDelay forKey: @"NSCompletionDelay"];
      [aCoder encodeObject: tokenizingCharacterSet
                    forKey: @"NSTokenizingCharacterSet"];
    }
  else
    {
      [aCoder encodeValueOfObjCType: @encode(NSTokenStyle) at: &tokenStyle];
      [aCoder encodeValueOfObjCType: @encode(NSTimeInterval)
                                 at: &completionDelay];
      [aCoder encodeObject: tokenizingCharacterSet];
    }
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  self = [super initWithCoder: aDecoder];
  if (self == nil)
    {
      return nil;
    }

  if ([aDecoder allowsKeyedCoding])
    {
      if ([aDecoder containsValueForKey: @"NSTokenStyle"])
        {
          tokenStyle = [aDecoder decodeIntForKey: @"NSTokenStyle"];
        }
      if ([aDecoder containsValueForKey: @"NSCompletionDelay"])
        {
          completionDelay = [aDecoder decodeDoubleForKey: @"NSCompletionDelay"];
        }
      if ([aDecoder containsValueForKey: @"NSTokenizingCharacterSet"])
        {
          ASSIGN(tokenizingCharacterSet,
            [aDecoder decodeObjectForKey: @"NSTokenizingCharacterSet"]);
        }
    }
  else if ([aDecoder versionForClassName: @"NSTokenFieldCell"] >= 2)
    {
      [aDecoder decodeValueOfObjCType: @encode(NSTokenStyle) at: &tokenStyle];
      [aDecoder decodeValueOfObjCType: @encode(NSTimeInterval)
                                   at: &completionDelay];
      ASSIGN(tokenizingCharacterSet, [aDecoder decodeObject]);
    }

  return self;
}
// Style...
- (NSTokenStyle)tokenStyle
{
  return tokenStyle;
}

- (void)setTokenStyle:(NSTokenStyle)style
{
  tokenStyle = style;
}

// Completion delay...
+ (NSTimeInterval)defaultCompletionDelay
{
  return 0;
}

- (NSTimeInterval)completionDelay
{
  return completionDelay;
}

- (void)setCompletionDelay:(NSTimeInterval)delay
{
  completionDelay = delay;
}

// Character set...
+ (NSCharacterSet *)defaultTokenizingCharacterSet
{
  return [NSCharacterSet characterSetWithCharactersInString: @","];
}

- (void)setTokenizingCharacterSet:(NSCharacterSet *)characterSet
{
  ASSIGN(tokenizingCharacterSet, characterSet);
}

- (NSCharacterSet *)tokenizingCharacterSet
{
  return tokenizingCharacterSet;
}
@end
