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

#include "config.h"
#include "AppKit/NSDataLinkPanel.h"
#include "AppKit/NSNibLoading.h"
#include "GSGuiPrivate.h"

static NSDataLinkPanel *__sharedDataLinkPanel;

@interface GSDataLinkPanelController : NSObject
{
  id panel;
}
- (id) panel;
@end

@implementation GSDataLinkPanelController
- (id) init
{
  NSString *panelPath;
  NSDictionary *table;

  self = [super init];
  panelPath = [GSGuiBundle() pathForResource: @"GSDataLinkPanel" 
			  ofType: @"gorm"
			  inDirectory: nil];
  NSLog(@"Panel path=%@",panelPath);
  table = [NSDictionary dictionaryWithObject: self forKey: @"NSOwner"];
  if ([NSBundle loadNibFile: panelPath 
	  externalNameTable: table
		withZone: [self zone]] == NO)
    {
      NSRunAlertPanel(@"Error", @"Could not load data link panel resource", 
		      @"OK", NULL, NULL);
      return nil;
    }

  return self;
}

- (id) panel
{
  return panel;
}
@end

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
  if(__sharedDataLinkPanel == nil)
    {
      id controller = [[GSDataLinkPanelController alloc] init];
      __sharedDataLinkPanel = [controller panel];
    }
  NSLog(@"%@",__sharedDataLinkPanel);
  return __sharedDataLinkPanel;
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
{
  NSLog(@"Break all links...");
}

- (void)pickedBreakLink:(id)sender
{
  NSLog(@"Break link...");
}

- (void)pickedOpenSource:(id)sender
{
  NSLog(@"Open Source...");
}

- (void)pickedUpdateDestination:(id)sender
{
  NSLog(@"Update destination...");
}

- (void)pickedUpdateMode:(id)sender
{
  NSLog(@"Update mode..");
}

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
