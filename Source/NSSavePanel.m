/* 
   NSSavePanel.m

   Standard save panel for saving files

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   Author:  Daniel Bðhringer <boehring@biomed.ruhr-uni-bochum.de>
   Date: August 1998
   Source by Daniel Bðhringer integrated into Scott Christley's preliminary
   implementation by Felipe A. Rodriguez <far@ix.netcom.com> 
 
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
#include <string.h>

#include <Foundation/NSArray.h>
#include <Foundation/NSString.h>
#include <Foundation/NSCoder.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSSavePanel.h>
#include <AppKit/NSOpenPanel.h>
#include <AppKit/NSBrowserCell.h>

// toDo:	
// - interactive directory creation in SavePanel
// - accessory view support
// - parse ".hidden" files; array of suffixes of directories treated as single 
//   files



//
// Class variables
//
static NSSavePanel *gnustep_gui_save_panel = nil;

@implementation NSSavePanel

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSSavePanel class])
      [self setVersion:1];									// Initial version
}

//
// Creating an NSSavePanel 
//
+ (NSSavePanel *)savePanel
{	
	if(!gnustep_gui_save_panel)	
    	{
//      PanelLoader *pl = [PanelLoader panelLoader];
//      gnustep_gui_save_panel = (NSSavePanel *)[pl loadPanel: @"NSSavePanel"];
		gnustep_gui_save_panel = [[NSSavePanel alloc] init];
		}

	return gnustep_gui_save_panel;
}

//
// Instance methods
//
//
// Initialization
//
- (void)setDefaults
{
	directory = @"\\";
	file_name = @"";
	_accessoryView = nil;
	panel_title = @"Save File";
	panel_prompt = @"";
	required_type = nil;
	treatsFilePackagesAsDirectories = YES;
}

- init
{
	[super init];
	
	[self setDefaults];
	return self;
}

//
// Customizing the NSSavePanel 
//
- (void)setAccessoryView:(NSView *)aView
{
	_accessoryView = aView;
}

- (NSView *)accessoryView
{
	return _accessoryView;
}

-(void) validateVisibleColumns
{
}

- (void)setTitle:(NSString *)title
{	
	[titleField setStringValue:title];
}

- (NSString *)title
{	
	return [titleField stringValue];
}

- (void)setPrompt:(NSString *)prompt
{	// does currently not work since i went with NSTextField instead of NSForm
	[[form cell] setTitle:prompt];
}

- (NSString *)prompt
{	
	return [[form cell] title];
}

//
// Setting Directory and File Type 
//
- (NSString *)requiredFileType
{	
	if(!requiredTypes || ![requiredTypes count])
		return nil;
	
	return [requiredTypes objectAtIndex:0];
}

- (void)setDirectory:(NSString *)path
{	
NSString *standardizedPath=[path stringByStandardizingPath];
	
	if(standardizedPath)
		{	
		[browser setPath:standardizedPath];
		if(lastValidPath)
			[lastValidPath autorelease];
		lastValidPath=[path retain];
		}
}
- (void)setRequiredFileType:(NSString *)type
{	
	if(requiredTypes) 
		[requiredTypes autorelease];
	requiredTypes=[[NSArray arrayWithObject:type] retain];
}

- (void)setTreatsFilePackagesAsDirectories:(BOOL)flag
{	
	treatsFilePackagesAsDirectories=flag;
}

- (BOOL)treatsFilePackagesAsDirectories
{	
	return treatsFilePackagesAsDirectories;
}

//
// Running the NSSavePanel 
//
- (int)runModalForDirectory:(NSString *)path file:(NSString *)name
{	
int	ret;

	[browser loadColumnZero];
	[self setDirectory:path];
	[browser setPath:[NSString stringWithFormat:@"%@/%@",
						[self directory], name]];
	[form setStringValue:name];
	[self selectText:self];							// or should it be browser?
	if([self class] == [NSOpenPanel class]) 
		[okButton setEnabled:
					([browser selectedCell] && [self canChooseDirectories]) ||  
					[[browser selectedCell] isLeaf]];
	[self makeKeyAndOrderFront:self];
	ret = [[NSApplication sharedApplication] runModalForWindow:self];
													// replace warning
	if([self class] == [NSSavePanel class] && 
			[[browser selectedCell] isLeaf] && ret == NSOKButton)
		{	
		if(NSRunAlertPanel(@"Save",@"The file %@ in %@ exists. Replace it?", 
							@"Replace",@"Cancel",nil,[form stringValue], 
							[self directory]) == NSAlertAlternateReturn)
			return NSCancelButton;
		}

	return ret;
}

- (int)runModal
{	
	return [self runModalForDirectory:[self directory] file:@""];
}

//
// Reading Save Information 
//
- (NSString *)directory
{	
NSString *path;
	
	if([[browser selectedCell] isLeaf])		// remove file component of path
		path=[[browser path] stringByDeletingLastPathComponent];	
	else
		path=[browser path];

	if(![path length]) 
		return lastValidPath;
	else 
		return path;
}

- (NSString *)filename
{	
NSString *ret = [NSString stringWithFormat:@"%@/%@",[self directory],
													[form stringValue]];
									// if path does not exist ask the user to 
									// create each missing directory
	if([[self requiredFileType] length] && ![ret hasSuffix:[NSString 
				stringWithFormat:@".%@",[self requiredFileType]]])
		ret = [NSString stringWithFormat:@"%@.%@",ret,[self requiredFileType]];

	return [ret stringByExpandingTildeInPath];
}

//
// Target and Action Methods 
//
- (void)ok:(id)sender
{						// iterate through selection if a multiple selection
	if(![self panel:self isValidFilename:[self filename]]) 
		return;

	[[NSApplication sharedApplication] stopModalWithCode:NSOKButton];
	[self orderOut:self];
}

- (void)cancel:(id)sender
{	
	[[NSApplication sharedApplication] stopModalWithCode:NSCancelButton];
	[self orderOut:self];
}

//
// Responding to User Input 
//
- (void)selectText:(id)sender
{	
	[form selectText:sender];
}

//
// Methods Implemented by the Delegate 
//
- (NSComparisonResult)panel:(id)sender
	    	compareFilename:(NSString *)filename1
			with:(NSString *)filename2
	    	caseSensitive:(BOOL)caseSensitive
{
	if ([delegate respondsToSelector:
		  		@selector(panel:compareFilename:with:caseSensitive:)])
    	return [delegate panel:sender 
						compareFilename:filename1
		     			with:filename2 
						caseSensitive:caseSensitive];

	return NSOrderedSame;
}

- (BOOL)panel:(id)sender
shouldShowFilename:(NSString *)filename
{
  if ([delegate respondsToSelector:@selector(panel:shouldShowFilename:)])
    return [delegate panel:sender shouldShowFilename:filename];
  return NO;
}

- (BOOL)panel:(id)sender isValidFilename:(NSString*)filename
{	
	if([self delegate] && [[self delegate] 
						 respondsToSelector:@selector(panel:isValidFilename:)])
		return [[self delegate] panel:sender isValidFilename:filename];

	return YES;
}

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder
{
  [aCoder encodeObject: _accessoryView];
  [aCoder encodeObject: panel_title];
  [aCoder encodeObject: panel_prompt];
  [aCoder encodeObject: directory];
  [aCoder encodeObject: file_name];
  [aCoder encodeObject: required_type];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at:&required_type];
#if 0
  [aCoder encodeObjectReference: delegate withName: @"Delegate"];
#else
  [aCoder encodeConditionalObject:delegate];
#endif
}

- initWithCoder:aDecoder
{
  _accessoryView = [aDecoder decodeObject];
  panel_title = [aDecoder decodeObject];
  panel_prompt = [aDecoder decodeObject];
  directory = [aDecoder decodeObject];
  file_name = [aDecoder decodeObject];
  required_type = [aDecoder decodeObject];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at:&required_type];
#if 0
  [aDecoder decodeObjectAt: &delegate withName: NULL];
#else
  delegate = [aDecoder decodeObject];
#endif

  return self;
}

@end
