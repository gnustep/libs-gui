/** <title>NSCollectionViewItem</title>
 
   Copyright (C) 2013 Free Software Foundation, Inc.
 
   Author: Doug Simons (doug.simons@testplant.com)
           Frank LeGrand (frank.legrand@testplant.com)
   Date: February 2013
 
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

#import "AppKit/NSCollectionViewItem.h"

#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSDebug.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSException.h>
#import <Foundation/NSFormatter.h>
#import <Foundation/NSIndexSet.h>
#import <Foundation/NSKeyValueCoding.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSUserDefaults.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSKeyedArchiver.h>

#import "AppKit/NSTableView.h"
#import "AppKit/NSApplication.h"
#import "AppKit/NSCell.h"
#import "AppKit/NSClipView.h"
#import "AppKit/NSColor.h"
#import "AppKit/NSEvent.h"
#import "AppKit/NSImage.h"
#import "AppKit/NSGraphics.h"
#import "AppKit/NSKeyValueBinding.h"
#import "AppKit/NSScroller.h"
#import "AppKit/NSScrollView.h"
#import "AppKit/NSTableColumn.h"
#import "AppKit/NSTableHeaderView.h"
#import "AppKit/NSText.h"
#import "AppKit/NSTextFieldCell.h"
#import "AppKit/NSWindow.h"
#import "AppKit/PSOperators.h"
#import "AppKit/NSCachedImageRep.h"
#import "AppKit/NSPasteboard.h"
#import "AppKit/NSDragging.h"
#import "AppKit/NSCustomImageRep.h"
#import "AppKit/NSAttributedString.h"
#import "AppKit/NSStringDrawing.h"
#import "GNUstepGUI/GSTheme.h"
#import "GSBindingHelpers.h"

#include <math.h>

@implementation NSCollectionViewItem

- (void)awakeFromNib
{
}

- (BOOL)isSelected
{
  return _isSelected;
}

- (void)dealloc
{
  DESTROY (textField);
  DESTROY (imageView);
  [super dealloc];
}

- (NSCollectionView *)collectionView
{
  return (NSCollectionView *)[[self view] superview];
}

- (void)setSelected:(BOOL)flag
{
  if (_isSelected != flag)
    {
      _isSelected = flag;
	}
}

- (id)representedObject
{
  return [super representedObject];
}

- (void)setRepresentedObject:(id)anObject
{
  [super setRepresentedObject:anObject];
  //[textField setStringValue:[self representedObject]];
}

- (NSTextField *)textField
{
  return textField;
}

- (void)setTextField:(NSTextField *)aTextField
{
  if (textField != aTextField)
    {
	  textField = aTextField;
	}
}

- (NSImageView *)imageView
{
  return imageView;
}

- (void)setImageView:(NSImageView *)anImageView
{
  if (imageView != anImageView)
    {
	  imageView = anImageView;
	}
}

- (id)initWithCoder:(NSCoder *)aCoder
{
  self = [super initWithCoder:aCoder];
    
  if (self)
    {
      textField = [aCoder decodeObjectForKey:@"textField"];
      imageView = [aCoder decodeObjectForKey:@"imageView"];
    }
    
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeObject:textField forKey:@"textField"];
  [aCoder encodeObject:imageView forKey:@"imageView"];
}

- (id) copyWithZone:(NSZone *)zone 
{
  NSData *itemAsData = [NSKeyedArchiver archivedDataWithRootObject:self];
  NSCollectionViewItem *newItem = [NSKeyedUnarchiver unarchiveObjectWithData:itemAsData];
  return newItem;
}

@end
