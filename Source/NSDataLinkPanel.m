/** <title>NSDataLinkPanel</title>

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: Scott Christley <scottc@net-community.com>
   Date: 1996
   
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

#include <gnustep/gui/config.h>
#include <AppKit/NSDataLinkPanel.h>


@implementation NSApplication (NSDataLinkPanel)

- (void) orderFrontDataLinkPanel: sender
{
  NSDataLinkPanel *dataLinkPanel = [NSDataLinkPanel sharedDataLinkPanel];

  if (dataLinkPanel)
    [dataLinkPanel orderFront: nil];
  else
    NSBeep();
}

@end

@implementation NSDataLinkPanel

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSDataLinkPanel class])
    {
      // Initial version
      [self setVersion:1];
    }
}

//
// Initializing
//
+ (NSDataLinkPanel *)sharedDataLinkPanel
{
  NSRunAlertPanel (NULL, @"Data Link Panel not implemented yet",
		   @"OK", NULL, NULL);
  return nil;
}

//
// Keeping the Panel Up to Date
//
+ (void)getLink:(NSDataLink **)link
	manager:(NSDataLinkManager **)linkManager
isMultiple:(BOOL *)flag
{}

+ (void)setLink:(NSDataLink *)link
	manager:(NSDataLinkManager *)linkManager
isMultiple:(BOOL)flag
{}

//
// Instance methods
//

//
// Keeping the Panel Up to Date
//
- (void)getLink:(NSDataLink **)link
	manager:(NSDataLinkManager **)linkManager
isMultiple:(BOOL *)flag
{}

- (void)setLink:(NSDataLink *)link
	manager:(NSDataLinkManager *)linkManager
isMultiple:(BOOL)flag
{}

//
// Customizing the Panel
//
- (NSView *)accessoryView
{
  return nil;
}

- (void)setAccessoryView:(NSView *)aView
{}

//
// Responding to User Input
//
- (void)pickedBreakAllLinks:(id)sender
{}

- (void)pickedBreakLink:(id)sender
{}

- (void)pickedOpenSource:(id)sender
{}

- (void)pickedUpdateDestination:(id)sender
{}

- (void)pickedUpdateMode:(id)sender
{}

//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  [super initWithCoder: aDecoder];

  return self;
}

@end
