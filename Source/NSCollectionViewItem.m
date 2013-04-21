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

#import <Foundation/NSArray.h>
#import <Foundation/NSKeyedArchiver.h>

#import "AppKit/NSCollectionView.h"
#import "AppKit/NSCollectionViewItem.h"
#import "AppKit/NSImageView.h"
#import "AppKit/NSTextField.h"

@implementation NSCollectionViewItem

- (void) awakeFromNib
{
}

- (BOOL) isSelected
{
  return _isSelected;
}

- (void) dealloc
{
  DESTROY(textField);
  DESTROY(imageView);
  [super dealloc];
}

- (NSCollectionView *) collectionView
{
  return (NSCollectionView *)[[self view] superview];
}

- (NSArray *) draggingImageComponents
{
  // FIXME: We don't have NSDraggingImageComponent
  return [NSArray array];
}

- (void) setSelected: (BOOL)flag
{
  if (_isSelected != flag)
    {
      _isSelected = flag;
    }
}

- (id) representedObject
{
  return [super representedObject];
}

- (void) setRepresentedObject: (id)anObject
{
  [super setRepresentedObject:anObject];
  //[textField setStringValue:[self representedObject]];
}

- (NSTextField *) textField
{
  return textField;
}

- (void) setTextField: (NSTextField *)aTextField
{
  if (textField != aTextField)
    {
      textField = aTextField;
    }
}

- (NSImageView *) imageView
{
  return imageView;
}

- (void) setImageView: (NSImageView *)anImageView
{
  if (imageView != anImageView)
    {
      imageView = anImageView;
    }
}

- (id) initWithCoder: (NSCoder *)aCoder
{
  self = [super initWithCoder: aCoder];
  if (nil != self)
    {
      if (YES == [aCoder allowsKeyedCoding])
	{
	  textField = [aCoder decodeObjectForKey: @"textField"];
	  imageView = [aCoder decodeObjectForKey: @"imageView"];
	}
      else
	{
	  textField = [aCoder decodeObject];
	  imageView = [aCoder decodeObject];
	}
    }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [super encodeWithCoder: aCoder];
  if (YES == [aCoder allowsKeyedCoding])
    {
      [aCoder encodeObject: textField forKey: @"textField"];
      [aCoder encodeObject: imageView forKey: @"imageView"];
    }
  else
    {
      [aCoder encodeObject: textField];
      [aCoder encodeObject: imageView];
    }
}

- (id) copyWithZone: (NSZone *)zone 
{
  NSData *itemAsData = [NSKeyedArchiver archivedDataWithRootObject: self];
  NSCollectionViewItem *newItem = 
    [NSKeyedUnarchiver unarchiveObjectWithData: itemAsData];
  return newItem;
}

@end
