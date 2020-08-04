/* Implementation of class NSTextFinder
   Copyright (C) 2020 Free Software Foundation, Inc.
   
   By: Gregory John Casamento
   Date: 02-08-2020

   This file is part of the GNUstep Library.
   
   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.
   
   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110 USA.
*/

#import <Foundation/NSArray.h>
#import <Foundation/NSArchiver.h>

#import "AppKit/NSTextFinder.h"
#import "AppKit/NSTextView.h"

#import "GSTextFinder.h"

@implementation NSTextFinder

// Validating and performing
- (void) performAction: (NSTextFinderAction)op
{
  switch (op)
    {
    case NSTextFinderActionShowFindInterface:
      break;        
    case NSTextFinderActionNextMatch:
      break;        
    case NSTextFinderActionPreviousMatch:
      break;        
    case NSTextFinderActionReplaceAll:
      break;        
    case NSTextFinderActionReplace:
      break;        
    case NSTextFinderActionReplaceAndFind:
      break;        
    case NSTextFinderActionSetSearchString:
      break;        
    case NSTextFinderActionReplaceAllInSelection:
      break;        
    case NSTextFinderActionSelectAll:
      break;        
    case NSTextFinderActionSelectAllInSelection:
      break;        
    case NSTextFinderActionHideFindInterface:
      break;        
    case NSTextFinderActionShowReplaceInterface:
      break;        
    case NSTextFinderActionHideReplaceInterface:
      break;        
    default:
      break;
    }
}

- (BOOL) validateAction: (NSTextFinderAction)op
{
  return NO;
}

- (void)cancelFindIndicator;
{
}

// Properties
- (id<NSTextFinderClient>) client
{
  return _client;
}

- (void) setClient: (id<NSTextFinderClient>) client
{
  _client = client;
}

- (id<NSTextFinderBarContainer>) findBarContainer
{
  return _findBarContainer;
}

- (void) setFindBarContainer: (id<NSTextFinderBarContainer>) findBarContainer
{
  _findBarContainer = findBarContainer;
}

- (BOOL) findIndicatorNeedsUpdate
{
  return _findIndicatorNeedsUpdate;
}

- (void) setFindIndicatorNeedsUpdate: (BOOL)flag
{
  _findIndicatorNeedsUpdate = flag;
}

- (BOOL) isIncrementalSearchingEnabled
{
  return _incrementalSearchingEnabled;
}

- (void) setIncrementalSearchingEnabled: (BOOL)flag
{
  _incrementalSearchingEnabled = flag;
}

- (BOOL) incrementalSearchingShouldDimContentView
{
  return _incrementalSearchingShouldDimContentView;
}

- (void) setIncrementalSearchingShouldDimContentView: (BOOL)flag
{
  _incrementalSearchingShouldDimContentView = flag;
}

- (NSArray *) incrementalMatchRanges
{
  return _incrementalMatchRanges;
}

+ (void) drawIncrementalMatchHighlightInRect: (NSRect)rect
{
}

- (void) noteClientStringWillChange
{
  // nothing...
}

// NSCoding...
- (instancetype) initWithCoder: (NSCoder *)coder
{
  self = [super init];
  if (self != nil)
    {
      if ([coder allowsKeyedCoding])
        {
          if ([coder containsValueForKey: @"NSFindIndicatorNeedsUpdate"])
            {
              _findIndicatorNeedsUpdate = [coder decodeBoolForKey: @"NSFindIndicatorNeedsUpdate"];
            }
          if ([coder containsValueForKey: @"NSIncrementalSearchingEnabled"])
            {
              _incrementalSearchingEnabled = [coder decodeBoolForKey: @"NSIncrementalSearchingEnabled"];
            }
          if ([coder containsValueForKey: @"NSIncrementalSearchingShouldDimContentView"])
            {
              _incrementalSearchingShouldDimContentView = [coder decodeBoolForKey: @"NSIncrementalSearchingShouldDimContentView"];
            }
          if ([coder containsValueForKey: @"NSIncrementalMatchRanges"])
            {
              ASSIGN(_incrementalMatchRanges, [coder decodeObjectForKey: @"NSIncrementalMatchRanges"]);
            }
        }
      else
        {
          [coder decodeValueOfObjCType: @encode(BOOL)
                                    at: &_findIndicatorNeedsUpdate];
          [coder decodeValueOfObjCType: @encode(BOOL)
                                    at: &_incrementalSearchingEnabled];
          [coder decodeValueOfObjCType: @encode(BOOL)
                                    at: &_incrementalSearchingShouldDimContentView];
          ASSIGN(_incrementalMatchRanges, [coder decodeObject]);
        }
    }
  return self;
}

- (void) encodeWithCoder: (NSCoder *)coder
{
  if ([coder allowsKeyedCoding])
    {
      [coder encodeBool: _findIndicatorNeedsUpdate
                 forKey: @"NSFindIndicatorNeedsUpdate"];
      [coder encodeBool: _incrementalSearchingEnabled
                 forKey: @"NSIncrementalSearchingEnabled"];
      [coder encodeBool: _incrementalSearchingShouldDimContentView
                 forKey: @"NSIncrementalSearchingShouldDimContentView"];
      [coder encodeObject: _incrementalMatchRanges
                   forKey: @"NSIncrementalMatchRanges"];
    }
  else
    {
      [coder encodeValueOfObjCType: @encode(BOOL)
                                at: &_findIndicatorNeedsUpdate];
      [coder encodeValueOfObjCType: @encode(BOOL)
                                at: &_incrementalSearchingEnabled];
      [coder encodeValueOfObjCType: @encode(BOOL)
                                at: &_incrementalSearchingShouldDimContentView];
      [coder encodeObject: _incrementalMatchRanges];
    }
}

@end
