/** <title>GSXib5KeyedUnarchiver.m</title>
 
 <abstract>The XIB 5 keyed unarchiver</abstract>
 
 Copyright (C) 1996-2017 Free Software Foundation, Inc.
 
 Author:  Marcian Lytwyn <gnustep@advcsi.com>
 Date: 12/28/16
 
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

#import "GSXib5KeyedUnarchiver.h"
#import "GNUstepGUI/GSNibLoading.h"
#import "GNUstepGUI/GSXibLoading.h"
#import "GNUstepGUI/GSXibElement.h"

#import "AppKit/NSApplication.h"
#import "AppKit/NSBox.h"
#import "AppKit/NSBrowser.h"
#import "AppKit/NSBrowserCell.h"
#import "AppKit/NSButtonCell.h"
#import "AppKit/NSCell.h"
#import "AppKit/NSClipView.h"
#import "AppKit/NSFormCell.h"
#import "AppKit/NSImage.h"
#import "AppKit/NSMatrix.h"
#import "AppKit/NSMenu.h"
#import "AppKit/NSMenuItem.h"
#import "AppKit/NSNib.h"
#import "AppKit/NSParagraphStyle.h"
#import "AppKit/NSPopUpButton.h"
#import "AppKit/NSPopUpButtonCell.h"
#import "AppKit/NSScroller.h"
#import "AppKit/NSScrollView.h"
#import "AppKit/NSSliderCell.h"
#import "AppKit/NSSplitView.h"
#import "AppKit/NSTableColumn.h"
#import "AppKit/NSTableView.h"
#import "AppKit/NSTabView.h"
#import "AppKit/NSView.h"


//#define DEBUG_XIB5

@interface NSString (GSXib5KeyedUnarchiver)

#pragma mark - NSString method(s)...
- (NSString*) stringByDeletingPrefix: (NSString*) prefix;
@end

@implementation NSString (GSXib5KeyedUnarchiver)

- (NSString*) stringByDeletingPrefix: (NSString*) prefix
{
  if ([self length] > [prefix length])
    {
      if ([[self substringWithRange:NSMakeRange(0, [prefix length])] isEqualToString:prefix])
        {
          NSString *key = [self substringWithRange:NSMakeRange([prefix length], [self length]-[prefix length])];
          return key;
        }
    }
  
  return nil;
}

@end

#pragma mark - Extended XIB 5 NSCustomObject...
@interface NSCustomObject5 : NSCustomObject
{
  NSString *_userLabel;
}

- (NSString*) userLabel;
@end

@implementation NSCustomObject5

static NSString *ApplicationClass = nil;

- (id) initWithCoder: (NSCoder *)coder
{
  self = [super initWithCoder: coder];
  
  if (self)
    {
      _userLabel = [coder decodeObjectForKey:@"userLabel"];
      
      if (_className)
        {
          // If we've not set the general application class yet...
          if (([NSClassFromString(_className) isKindOfClass: [NSApplication class]]) &&
              (ApplicationClass == nil))
            {
              @synchronized([self class])
                {
                  ASSIGNCOPY(ApplicationClass, _className);
                }
            }
        }
      
      // Override thie one type...
      if (_userLabel)
        {
          if ([@"Application" isEqualToString:_userLabel])
            {
              if (ApplicationClass == nil)
                ASSIGN(_className, @"NSApplication");
              else
                ASSIGN(_className, ApplicationClass);
            }
        }
    }
  
  return self;
}

- (NSString *)userLabel
{
  return _userLabel;
}

@end

#pragma mark - Extended XIB 5 NSWindowTemplate...
@interface NSWindowTemplate5 : NSWindowTemplate
{
  BOOL _visibleAtLaunch;
}
@end

@implementation NSWindowTemplate5

- (id) initWithCoder: (NSCoder *)coder
{
  self = [super initWithCoder: coder];
  if (self)
    {
      _visibleAtLaunch = YES;
      
      if ([coder containsValueForKey: @"visibleAtLaunch"])
        _visibleAtLaunch = [coder decodeBoolForKey: @"visibleAtLaunch"];
    }
  
  return self;
}

- (id) nibInstantiate
{
  if (_realObject == nil)
    {
      // Instantiate the real object...
      [super nibInstantiate];
      
      // >= XIB 5 - startup visible windows...
      if (_visibleAtLaunch)
        {
          // bring visible windows to front...
          [(NSWindow *)_realObject orderFront: self];
        }
    }
  
  return _realObject;
}

@end

#pragma mark - Extended XIB 5 IBActionConnection...
@interface IBActionConnection5 : IBActionConnection
{
  NSString *trigger;
}
@end

@implementation IBActionConnection5

- (instancetype)initWithCoder:(NSCoder *)coder
{
  self = [super initWithCoder: coder];
  if (self)
  {
    trigger = nil;
    
    if ([coder allowsKeyedCoding])
      {
        // label and source string tags have changed for XIB5...
        ASSIGN(label, [coder decodeObjectForKey: @"selector"]);
        ASSIGN(source, [coder decodeObjectForKey: @"target"]);
        // destination string tag is still the same (so far) and loaded
        // by base class...
        //ASSIGN(destination, [coder decodeObjectForKey: @"destination"]);
        
        // Looks like the 'trigger' attribute should be used to override the
        // target/action setup method...
        if ([coder containsValueForKey: @"trigger"])
          ASSIGN(trigger, [coder decodeObjectForKey: @"trigger"]);
      }
    else
    {
      [NSException raise: NSInvalidArgumentException
                  format: @"Can't decode %@ with %@.",NSStringFromClass([self class]),
       NSStringFromClass([coder class])];
    }
  }
  return self;
}

- (NSString*) trigger
{
  return trigger;
}

- (void) establishConnection
{
  if (trigger && [trigger length])
    {
      SEL       sel     = NSSelectorFromString(label);
      NSString *selName = [NSString stringWithFormat: @"set%@%@:",
                           [[trigger substringToIndex: 1] uppercaseString],
                           [trigger substringFromIndex: 1]];
      SEL       trigsel = NSSelectorFromString(selName);
      
      if (sel && trigsel && [destination respondsToSelector: trigsel])
        {
          NSWarnMLog(@"setting trigger %@ to selector %@", selName, label);
          //[destination setTarget: source]; // Not needed???
          [destination performSelector: trigsel withObject: sel];
        }
      else if ((SEL)nil == sel)
        {
          NSWarnMLog(@"label %@ does not correspond to any selector", label);
        }
      else if ((SEL)nil == trigsel)
        {
          NSWarnMLog(@"trigger %@ does not correspond to any selector", trigger);
        }
      else
        {
          NSWarnMLog(@"destination class (%@) does not respond to trigger selector %@",
                     NSStringFromClass([destination class]), selName);
        }
      
      // PREMATURE RETURN...
      return;
    }
  
  // Otherwise invoke the super class' method...
  [super establishConnection];
}

@end

#pragma mark - Extended XIB 5 IBBindingConnection...
@interface NSNibBindingConnector5 : NSNibBindingConnector
@end

@implementation NSNibBindingConnector5

- (id) initWithCoder: (NSCoder*)coder
{
  if (self = [super initWithCoder: coder]) // Avoid super class init...
    {
      if ([coder allowsKeyedCoding])
        {
          // label and source string tags have changed for XIB5...
          ASSIGN(_binding, [coder decodeObjectForKey: @"name"]);
          ASSIGN(_keyPath, [coder decodeObjectForKey: @"keyPath"]);
          // No options in XIB 5
          //ASSIGN(_options, [aDecoder decodeObjectForKey: @"NSOptions"]);
        }
    }
  else
    {
      [NSException raise: NSInvalidArgumentException
                  format: @"Can't decode %@ with %@.",NSStringFromClass([self class]),
       NSStringFromClass([coder class])];
    }

  return self;
}

@end

#pragma mark - Extended XIB 5 IBBindingConnection...
@interface IBBindingConnection5 : IBBindingConnection
@end

@implementation IBBindingConnection5

- (instancetype)initWithCoder:(NSCoder *)coder
{
  self = [super initWithCoder: coder];
  if (self)
  {
    if ([coder allowsKeyedCoding])
    {
      connector = [[NSNibBindingConnector5 alloc] initWithCoder: coder];
      
      // label and source string tags have changed for XIB5...
      ASSIGN(label, [coder decodeObjectForKey: @"name"]);
      //ASSIGN(source, [coder decodeObjectForKey: @"target"]);
      // destination string tag is still the same (so far) and loaded
      // by base class...
      //ASSIGN(destination, [coder decodeObjectForKey: @"destination"]);
    }
    else
    {
      [NSException raise: NSInvalidArgumentException
                  format: @"Can't decode %@ with %@.",NSStringFromClass([self class]),
       NSStringFromClass([coder class])];
    }
  }
  return self;
}

@end

#pragma mark - Extended XIB 5 IBOutletConnection...
@interface IBOutletConnection5 : IBOutletConnection
@end

@implementation IBOutletConnection5

- (instancetype)initWithCoder:(NSCoder *)coder
{
  self = [super initWithCoder: coder];
  if (self)
    {
      if ([coder allowsKeyedCoding])
        {
          // label and source string tags have changed for XIB5...
          ASSIGN(label, [coder decodeObjectForKey: @"property"]);
          ASSIGN(source, [coder decodeObjectForKey: @"target"]);
          // destination string tag is still the same (so far) and loaded
          // by base class...
          //ASSIGN(destination, [coder decodeObjectForKey: @"destination"]);
        }
      else
        {
          [NSException raise: NSInvalidArgumentException
                      format: @"Can't decode %@ with %@.",NSStringFromClass([self class]),
           NSStringFromClass([coder class])];
        }
    }
  return self;
}

#if 0
- (void) establishConnection
{
  [super establishConnection];
  // For some reason I needed this originally - but not now...
  RETAIN(destination);
}
#endif

@end

#pragma mark - Extended XIB 5 IBUserDefinedRuntimeAttribute...
@interface IBUserDefinedRuntimeAttribute5 : IBUserDefinedRuntimeAttribute
@end


@implementation IBUserDefinedRuntimeAttribute5

- (id) initWithCoder: (NSCoder *)coder
{
  self = [super initWithCoder: coder];
  
  if (self)
    {
      if([coder allowsKeyedCoding])
        {
          [self setTypeIdentifier: [coder decodeObjectForKey: @"type"]];
          
          // Decode value properly...
          if ([@"boolean" isEqualToString: typeIdentifier])
            [self setValue: [NSNumber numberWithBool: ([@"YES" isEqualToString: value] ? YES : NO)]];
          else if ([@"image" isEqualToString: typeIdentifier])
            [self setValue: [NSImage imageNamed: value]];
          else if ([@"number" isEqualToString: typeIdentifier])
            [self setValue: [coder decodeObjectForKey: @"value"]];
          else if ([@"point" isEqualToString: typeIdentifier])
            [self setValue: [coder decodeObjectForKey: @"value"]];
          else if ([@"size" isEqualToString: typeIdentifier])
            [self setValue: [coder decodeObjectForKey: @"size"]];
          else if ([@"rect" isEqualToString: typeIdentifier])
            [self setValue: [coder decodeObjectForKey: @"value"]];
          else if ([@"nil" isEqualToString: typeIdentifier])
            [self setValue: nil];
          NSWarnMLog(@"type: %@ value: %@ (%@)", typeIdentifier, value, [value class]);
        }
    }
  
  return self;
}

@end


#pragma mark - XIB 5 GSXib5KeyedUnarchiver Implementation...
@implementation GSXib5KeyedUnarchiver

static NSDictionary *XmltagToObjectClassCrossReference = nil;
static NSArray      *XmltagsNotStacked = nil;
static NSArray      *XmltagsToSkip = nil;
static NSArray      *ClassNamePrefixes = nil;
static NSDictionary *XmlKeyMapTable = nil;
static NSDictionary *XmlTagToDecoderSelectorMap = nil;
static NSDictionary *XmlKeyToDecoderSelectorMap = nil;
static NSArray      *XmlKeysDefined  = nil;
static NSArray      *XmlReferenceAttributes  = nil;
static NSArray      *XmlConnectionRecordTags  = nil;

#pragma mark -
+ (void) initialize
{
  if (self == [GSXib5KeyedUnarchiver class])
    {
      @synchronized(self)
      {
        // Only check one since we're going to load all once...
        if (XmltagToObjectClassCrossReference == nil)
          {
            // These define XML tags (i.e. <objects ...) that should be allocated as the
            // associated class...
            XmltagToObjectClassCrossReference = @{ @"objects"                       : @"NSMutableArray",
                                                   @"items"                         : @"NSMutableArray",
                                                   @"tabViewItems"                  : @"NSMutableArray",
                                                   @"connections"                   : @"NSMutableArray",
                                                   @"subviews"                      : @"NSMutableArray",
                                                   @"tableColumns"                  : @"NSMutableArray",
                                                   @"cells"                         : @"NSMutableArray",
                                                   @"column"                        : @"NSMutableArray",
                                                   @"tabStops"                      : @"NSMutableArray",
                                                   @"userDefinedRuntimeAttributes"  : @"NSMutableArray",
                                                   @"resources"                     : @"NSMutableArray",
                                                   @"segments"                      : @"NSMutableArray",
                                                   @"objectValues"                  : @"NSMutableArray",
                                                   @"prototypeCellViews"            : @"NSMutableArray",
                                                   @"segment"                       : @"NSSegmentItem",
                                                   @"customCell"                    : @"NSCell", // May have to add a NSCustomCell class
                                                   @"customObject"                  : @"NSCustomObject5",
                                                   @"userDefinedRuntimeAttribute"   : @"IBUserDefinedRuntimeAttribute5",
                                                   //@"action"                        : @"IBActionConnection5",
                                                   //@"binding"                       : @"IBABindingConnection5",
                                                   //@"outlet"                        : @"IBOutletConnection5",
                                                   @"window"                        : @"NSWindowTemplate5",
                                                   @"tableCellView"                 : @"NSView" };
            RETAIN(XmltagToObjectClassCrossReference);

            XmltagsNotStacked = @[ @"document" ];
            RETAIN(XmltagsNotStacked);

            XmltagsToSkip = @[ @"dependencies" ];
            RETAIN(XmltagsToSkip);

            ClassNamePrefixes = @[ @"NS", @"IB" ];
            RETAIN(ClassNamePrefixes);

            XmlReferenceAttributes = @[ @"headerView", @"initialItem" ];
            RETAIN(XmlReferenceAttributes);
            
            XmlConnectionRecordTags = @[ @"action", @"binding", @"outlet" ];
            RETAIN(XmlConnectionRecordTags);

            // These cross-reference from the OLD key to the NEW key that can be referenced and it's value
            // or object returned verbatum.  IF an OLD XIB key does not exist and contains the 'NS' prefix
            // the key processing will strip the 'NS' prefix, make the first letter lowercase then check
            // whether that key exists and use it's presence during 'containsValueForKey:' processing, and
            // use it's value for 'decodeXxxForKey:' processing.  So, the keys here should ONLY be those
            // that cannot be generated autoamatically by this processing.
            // (i.e. NSIsSeparator->isSeparatorItem, NSWindowStyleMask->styleMask, etc)
            // Note, that unless the associated cross referenced key contains an aattribute that matches the
            // original OLD key type you will need to potentially add a decoding method, and if so, the
            // 'XmlKeyToDecoderSelectorMap' variable below should contain the key to it's associated decoding
            // method for cross referencing...
            XmlKeyMapTable = @{ @"NSIsSeparator"                    : @"isSeparatorItem",
                                //@"NSName"                           : @"systemMenu",
                                @"NSClassName"                      : @"customClass",
                                @"NSCatalogName"                    : @"catalog",
                                @"NSColorName"                      : @"name",
                                @"NSSelectedIndex"                  : @"selectedItem",
                                @"NSNoAutoenable"                   : @"autoenablesItems",
                                @"NSPullDown"                       : @"pullsDown",
                                @"NSProtoCell"                      : @"prototype",
                                @"IBIsSystemFont"                   : @"metaFont",
                                //@"NSHeaderClipView"                 : @"headerView",
                                @"NSMinColumnWidth"                 : @"minColumnWidth",
                                //@"NSNumberOfVisibleColumns"         : @"maxVisibleColumns",
                                @"NSPreferedColumnWidth"            : @"defaultColumnWidth",
                                //@"NSPreferedColumnWidth"            : @"preferredColumnWidth",
                                @"NSBorderColor2"                   : @"borderColor",
                                @"NSFillColor2"                     : @"fillColor",
                                @"NSHScroller"                      : @"horizontalScroller",
                                @"NSVScroller"                      : @"verticalScroller",
                                @"NSKeyEquiv"                       : @"keyEquivalent",
                                @"NSKeyEquivModMask"                : @"keyEquivalentModifierMask",
                                @"NSOffsets"                        : @"contentViewMargins",
                                @"NSWindowStyleMask"                : @"styleMask",
                                @"NSWindowView"                     : @"contentView",
                                @"NSWindowClass"                    : @"customClass",
                                @"NSWindowTitle"                    : @"title",
                                @"windowPositionMask"               : @"initialPositionMask",
                                @"NSWindowRect"                     : @"contentRect",
                                @"NSInsertionColor"                 : @"insertionPointColor",
                                @"NSIsVertical"                     : @"vertical",
                                @"NSSelectedTabViewItem"            : @"initialItem",
                                @"NSControlAllowsExpansionToolTips" : @"allowsExpansionToolTips",
                                @"NSSegmentImages"                  : @"segments",
                                @"NSSegmentItemLabel"               : @"label",
                                @"NSSegmentItemImage"               : @"image",
                                @"NSIsEditable"                     : @"editable",
                                @"NSPopUpListData"                  : @"objectValues",
                                @"NSMaxNumberOfGridRows"            : @"maxNumberOfRows",
                                @"NSMaxNumberOfGridColumns"         : @"maxNumberOfColumns",
                                @"NSKey"                            : @"sortKey" };
            RETAIN(XmlKeyMapTable);
            
            // These define keys that are always "CONTAINED" since they typically are a combination of key values
            // stored as separate and/or multiple attributed values that may be combined as in the case of flags
            // and masks.  There are some that have NO direct cross reference (i.e. NSSupport, NSBGColor, etc)
            // Each of the ones listed here will MOST PROBABLY have an entry in the 'XmlKeyToDecoderSelectorMap'
            // below that provides a cross referenced to an asociated decoding method...
            // If there is an easy way to check whether an existing OLD XIB key is contained within the XIB 5
            // version the 'containsValueForKey:' method in this file should be modified and the key omitted from this
            // list (i.e. NSContents, NSAlternateContents, NSIntercellSpacingWidth, NSIntercellSpacingHeight, etc)...
            XmlKeysDefined = @[ @"NSWindowBacking", @"NSWTFlags",
                                @"NSvFlags", @"NSBGColor",
                                @"NSSize", //@"IBIsSystemFont",
                                //@"NSHeaderClipView",
                                @"NSHScroller", @"NSVScroller", @"NSsFlags", @"NSsFlags2",
                                @"NSColumnAutoresizingStyle", @"NSTvFlags", @"NScvFlags",
                                @"NSSupport", @"NSName",
                                @"NSMenuItem",
                                @"NSDocView",
                                @"NSSliderType",
                                @"NSCellPrototype", @"NSBrFlags", @"NSNumberOfVisibleColumns",
                                @"NSWhite", @"NSRGB", @"NSCYMK",
                                //@"NSContents", @"NSAlternateContents",
                                @"NSCellFlags", @"NSCellFlags2",
                                @"NSButtonFlags", @"NSButtonFlags2",
                                @"NSSelectedIndex", @"NSAltersState", @"NSUsesItemFromMenu",
                                @"NSNormalImage", @"NSAlternateImage",
                                @"NSBorderType", @"NSBoxType", @"NSTitlePosition",
                                @"NSTitleCell", @"NSOffsets",
                                @"NSMatrixFlags", @"NSNumCols", @"NSNumRows",
                                @"NSSharedData", @"NSFlags", @"NSTVFlags", @"NSDefaultParagraphStyle",
                                @"NSpiFlags" ];
            RETAIN(XmlKeysDefined);
            
            // These define XML tags (i.e. '<autoresizingMask ...') to an associated decode method...
            XmlTagToDecoderSelectorMap = @{ @"tableColumnResizingMask"  : @"decodeTableColumnResizingMaskForElement:",
                                            @"autoresizingMask"         : @"decodeAutoresizingMaskForElement:",
                                            @"windowStyleMask"          : @"decodeWindowStyleMaskForElement:",
                                            @"windowPositionMask"       : @"decodeWindowPositionMaskForElement:",
                                            //@"modifierMask"             : @"decodeModifierMaskForElement:",
                                            @"tableViewGridLines"       : @"decodeTableViewGridLinesForElement:" };
            RETAIN(XmlTagToDecoderSelectorMap);
            
            // These define XML attribute keys (i.e. '<object key="name" key="name" ...') to an associated decode method...
            // The associated decode method may process MULTIPLE keyed attributes as in such cases as
            // decoding the integer flag masks...
            XmlKeyToDecoderSelectorMap = @{ @"NSIntercellSpacingHeight"   : @"decodeIntercellSpacingHeightForElement:",
                                            @"NSIntercellSpacingWidth"    : @"decodeIntercellSpacingWidthForElement:",
                                            @"NSColumnAutoresizingStyle"  : @"decodeColumnAutoresizingStyleForElement:",
                                            @"NSName"                     : @"decodeNameForElement:",
                                            @"NSSliderType"               : @"decodeSliderCellTypeForElement:",
                                            @"NSColumnResizingType"       : @"decodeColumnResizingTypeForElement:",
                                            @"NSNumberOfVisibleColumns"   : @"decodeNumberOfVisibleColumnsForElement:",
                                            @"NSTickMarkPosition"         : @"decodeSliderCellTickMarkPositionForElement:",
                                            @"NSCells"                    : @"decodeCellsForElement:",
                                            @"NSNumCols"                  : @"decodeNumberOfColumnsInMatrixForElement:",
                                            @"NSNumRows"                  : @"decodeNumberOfRowsInMatrixForElement:",
                                            @"pullsDown"                  : @"decodePullsDownForElement:",
                                            @"autoenablesItems"           : @"decodeAutoenablesItemsForElement:",
                                            @"NSAltersState"              : @"decodeAltersStateForElement:",
                                            @"NSMenuItem"                 : @"decodeMenuItemForElement:",
                                            @"NSUsesItemFromMenu"         : @"decodeUsesItemFromMenuForElement:",
                                            @"selectedItem"               : @"decodeSelectedIndexForElement:",
                                            @"NSPreferredEdge"            : @"decodePreferredEdgeForElement:",
                                            @"NSArrowPosition"            : @"decodeArrowPositionForElement:",
                                            @"NSCellPrototype"            : @"decodeCellPrototypeForElement:",
                                            //@"NSMinColumnWidth"           : @"decodeMinimumColumnWidthForElement:",
                                            @"NSTitleCell"                : @"decodeTitleCellForElement:",
                                            @"NSBorderType"               : @"decodeBorderTypeForElement:",
                                            @"NSBoxType"                  : @"decodeBoxTypeForElement:",
                                            @"NSTitlePosition"            : @"decodeTitlePositionForElement:",
                                            //@"NSSearchButtonCell"         : @"decodeSearchButtonForElement:",
                                            //@"NSCancelButtonCell"         : @"decodeSearchButtonForElement:",
                                            @"keyEquivalentModifierMask"  : @"decodeModifierMaskForElement:",
                                            @"NSState"                    : @"decodeButtonStateForElement:",
                                            @"NSCell"                     : @"decodeCellForElement:",
                                            @"NSSize"                     : @"decodeFontSizeForElement:",
                                            //@"IBIsSystemFont"             : @"decodeFontTypeForElement:",
                                            @"NSpiFlags"                  : @"decodeProgressIndicatorFlagsForElement:",
                                            @"NSFlags"                    : @"decodeTextViewSharedDataFlagsForElement:",
                                            @"NSSharedData"               : @"decodeSharedDataForElement:",
                                            @"NSDefaultParagraphStyle"    : @"decodeDefaultParagraphStyleForElement:",
                                            @"NSTVFlags"                  : @"decodeTextViewFlagsForElement:",
                                            @"NSMatrixFlags"              : @"decodeMatrixFlagsForElement:",
                                            @"NSsFlags"                   : @"decodeScrollClassFlagsForElement:",
                                            @"NSsFlags2"                  : @"decodeScrollerFlags2ForElement:",
                                            @"NSHeaderClipView"           : @"decodeScrollViewHeaderClipViewForElement:",
                                            @"NSBGColor"                  : @"decodeBackgroundColorForElement:",
                                            @"NSBrFlags"                  : @"decodeBrowserFlagsForElement:",
                                            @"NScvFlags"                  : @"decodeClipViewFlagsForElement:",
                                            @"NSTvFlags"                  : @"decodeTViewFlagsForElement:",
                                            @"NSvFlags"                   : @"decodeViewFlagsForElement:",
                                            @"NSContents"                 : @"decodeCellContentsForElement:",
                                            @"NSAlternateContents"        : @"decodeCellAlternateContentsForElement:",
                                            @"NSCellFlags"                : @"decodeCellFlags1ForElement:",
                                            @"NSCellFlags2"               : @"decodeCellFlags2ForElement:",
                                            @"NSButtonFlags"              : @"decodeButtonFlags1ForElement:",
                                            @"NSButtonFlags2"             : @"decodeButtonFlags2ForElement:",
                                            @"NSNormalImage"              : @"decodeCellNormalImageForElement:",
                                            @"NSAlternateImage"           : @"decodeCellAlternateImageForElement:",
                                            @"NSWTFlags"                  : @"decodeWindowTemplateFlagsForElement:",
                                            @"NSWindowBacking"            : @"decodeWindowBackingStoreForElement:",
                                            @"NSDocView"                  : @"decodeClipViewDocumentViewForElement:",
                                            @"NSWhite"                    : @"decodeColorWhiteForElement:",
                                            @"NSRGB"                      : @"decodeColorRGBForElement:",
                                            @"NSColorSpace"               : @"decodeColorSpaceForElement:",
                                            @"NSCYMK"                     : @"decodeColorCYMKForElement:",
                                            @"NSSegmentItemImage"         : @"decodeSegmentItemImageForElement:",
                                            @"NSBackgroundColors"         : @"decodeBackgroundColorsForElement:",
                                            @"NSDividerStyle"             : @"decodeDividerStyleForElement:" };
            RETAIN(XmlKeyToDecoderSelectorMap);
        }
    }
  }
}

#pragma mark - Class level support method(s)...
+ (NSInteger) coderVersion
{
  return 5;
}

+ (NSString*) classNameForXibTag: (NSString*)xibTag
{
  NSString *className = [XmltagToObjectClassCrossReference objectForKey:xibTag];

  if (nil == className)
  {
    NSEnumerator *iter       = [ClassNamePrefixes objectEnumerator];
    NSString     *prefix     = nil;
    NSString     *baseString = [[xibTag substringToIndex:1] capitalizedString];
    baseString               = [baseString stringByAppendingString:[xibTag substringFromIndex:1]];
    
    // Try to generate a default name from tag...
    while ((prefix = [iter nextObject]))
    {
      NSString *theClassName = [NSString stringWithFormat:@"%@%@",prefix,baseString];

      if (NSClassFromString(theClassName))
      {
        className = theClassName;
        break;
      }
    }
  }
  
  return className;
}

+ (Class) classForXibTag: (NSString*)xibTag
{
  return NSClassFromString([self classNameForXibTag:xibTag]);
}

#pragma mark - Instance level decoding support method(s)...
- (GSXib5Element*) connectionRecordForElement: (GSXib5Element*)element
{
  // Mimic the old IBConnectionRecord instance...
  if ([XmlConnectionRecordTags containsObject: [element type]])
    {
      NSDictionary  *attributes       = @{ @"class"      : @"IBConnectionRecord",
                                           @"id"         : [[NSUUID UUID] UUIDString] };
      GSXib5Element *connectionRecord = [[GSXib5Element alloc] initWithType: @"object"
                                                              andAttributes: attributes];
      //[element setAttribute: @"connection" forKey: @"key"];
      [connectionRecord setElement: element forKey: @"connection"];
      return AUTORELEASE(connectionRecord);
    }
  
  return nil;
}

- (GSXib5Element*) orderedObjectForElement: (GSXib5Element*)element
{
  // Mimic the old IBObjectRecord instance...
  NSDictionary  *attributes   = @{ @"class" : @"IBObjectRecord",
                                   @"id"    : [[NSUUID UUID] UUIDString] };
  GSXib5Element *objectRecord = [[GSXib5Element alloc] initWithType: @"object"
                                                      andAttributes: attributes];
  GSXib5Element *parent       = [[GSXib5Element alloc] initWithType: @"nil"
                                                      andAttributes: @{ @"key" : @"parent" }];
  GSXib5Element *children     = [[GSXib5Element alloc] initWithType: @"nil"
                                                      andAttributes: @{ @"key" : @"children" }];
  GSXib5Element *reference    = [[GSXib5Element alloc] initWithType: @"reference"
                                                      andAttributes: @{ @"key" : @"object", @"ref" : [element attributeForKey: @"id"] }];

  //[element setAttribute: @"connection" forKey: @"key"];
  [objectRecord setElement: element forKey: @"object"];
  [objectRecord setElement: parent forKey: @"parent"];
  [objectRecord setElement: children forKey: @"children"];
  [objectRecord setElement: reference forKey: @"reference"];
  
  RELEASE(parent);
  RELEASE(children);
  RELEASE(reference);
  return AUTORELEASE(objectRecord);
}

- (void) addRuntimeAttributesForElement: (GSXib5Element*)element forID: (NSString*)idString
{
  NSString      *refID        = [NSString stringWithFormat:@"%@.IBAttributePlaceholdersKey",idString];
  GSXib5Element *objectRecord = (GSXib5Element*)[_flattenedProperties elementForKey: refID];
  
  // Mimic the old IBAttributePlaceholders instance...
  if (objectRecord == nil)
    {
      objectRecord                  = [[GSXib5Element alloc] initWithType: @"dictionary"
                                                            andAttributes: @{ @"class" : @"NSMutableDictionary",
                                                                              @"id"    : refID } ];
      GSXib5Element *stringRecord   = [[GSXib5Element alloc] initWithType: @"string"
                                                            andAttributes: @{ @"key" : @"NS.key.0" }];
      GSXib5Element *placeholderRec = [[GSXib5Element alloc] initWithType: @"object"
                                                            andAttributes: @{ @"class" : @"IBUserDefinedRuntimeAttributesPlaceholder",
                                                                              @"key"   : @"IBUserDefinedRuntimeAttributesPlaceholderName" }];
      GSXib5Element *placeStringRec = [[GSXib5Element alloc] initWithType: @"string"
                                                            andAttributes: @{ @"key" : @"name" }];
      GSXib5Element *referenceRec   = [[GSXib5Element alloc] initWithType: @"reference"
                                                            andAttributes: @{ @"key" : @"object",
                                                                              @"ref" : [element attributeForKey: @"id"] }];
      
      // Setup placeholder record...
      [placeStringRec setValue: @"IBUserDefinedRuntimeAttributesPlaceholderName"];
      [placeholderRec setElement: placeStringRec forKey: @"name"];
      [placeholderRec setElement: referenceRec forKey: @"object"];
      [placeholderRec setElement: element forKey: @"userDefinedRuntimeAttributes"];
      
      // Attach placeholder and string records to the object record...
      [objectRecord setElement: stringRecord forKey: @"NS.key.0"];
      [objectRecord setElement: placeholderRec forKey: @"IBUserDefinedRuntimeAttributesPlaceholderName"];
      
      // Add to flattened properties...
      [_flattenedProperties setElement: objectRecord forKey: refID];
      
      // Cleanup...
      RELEASE(stringRecord);
      RELEASE(placeholderRec);
      RELEASE(placeStringRec);
      RELEASE(referenceRec);
      RELEASE(objectRecord);
    }
}

#pragma mark - Instance initialization method(s)...
- (id) initForReadingWithData: (NSData*)data
{
#if     GNUSTEP_BASE_HAVE_LIBXML
  NSXMLParser *theParser  = nil;
  NSData      *theData    = data;
  
  // Check data...
  if (theData == nil)
    {
      return nil;
    }
  else
    {
      // Ensure we have a XIB 5 version...first see if we can parse the XML...
      NSXMLDocument *document = [[[NSXMLDocument alloc] initWithData:data
                                                            options:0
                                                              error:NULL] autorelease];
      if (document == nil)
        {
          NSLog(@"%s:DOCUMENT IS NIL: %@\n", __PRETTY_FUNCTION__, document);
        }
      else
        {
          // Test to see if this is an Xcode 5 XIB...
          NSArray *documentNodes = [document nodesForXPath:@"/document" error:NULL];
        
          // Need at LEAST ONE document node...we should find something a bit more
          // specific to check here...
          if ([documentNodes count] == 0)
            {
              NSWarnMLog(@"XIB is NOT a version 5 level");
              DESTROY(self);
            }
          else
            {
              // Initialize...
              [self _initCommon];
              
              // Createe the parser and parse the data...
              theParser = [[NSXMLParser alloc] initWithData: theData];
              [theParser setDelegate: self];
              
              NS_DURING
                {
                  // Parse the XML data
                  [theParser parse];
                }
              NS_HANDLER
                {
                  NSLog(@"Exception occurred while parsing Xib: %@", [localException reason]);
                  DESTROY(self);
                }
              NS_ENDHANDLER
              
              DESTROY(theParser);
            }
        }
    }
#endif
  
  return self;
}

- (void) _initCommon
{
  [super _initCommon];
  
  _orderedObjectsDict = RETAIN([NSMutableDictionary dictionary]);
  
  // Create our object(s)...
  _connectionRecords    = [[GSXib5Element alloc] initWithType: @"array"
                                                andAttributes: @{ @"key" : @"connectionRecords" }];
  _objectRecords        = [[GSXib5Element alloc] initWithType: @"object"
                                                andAttributes: @{ @"class" : @"IBMutableOrderedSet",
                                                                  @"key"   : @"objectRecords" }];
  _orderedObjects       = [[GSXib5Element alloc] initWithType: @"array"
                                                andAttributes: @{ @"key" : @"orderedObjects" }];
  _flattenedProperties  = [[GSXib5Element alloc] initWithType: @"dictionary"
                                                andAttributes: @{ @"class" : @"NSMutableDictionary",
                                                                  @"key"   : @"flattenedProperties" }];
  _runtimeAttributes    = [[GSXib5Element alloc] initWithType: @"dictionary"
                                                andAttributes: @{ @"class" : @"NSMutableDictionary",
                                                                  @"key"   : @"connectionRecords" }];
  
  // We will imitate the old XIB loading using an IBObjectContainer
  // stored with key "IBDocument.Objects"...
  _IBObjectContainer = [[GSXib5Element alloc] initWithType: @"object"
                                             andAttributes: @{ @"class" : @"IBObjectContainer",
                                                               @"key"   : @"IBDocument.Objects" }];
  
  // Create the linked set of XIB elements...
  [_IBObjectContainer setElement: _connectionRecords forKey: @"connectionRecords"];
  [_IBObjectContainer setElement: _objectRecords forKey: @"objectRecords"];
  [_IBObjectContainer setElement: _flattenedProperties forKey: @"flattenedProperties"];
  
  // objectRecords...
  [_objectRecords setElement: _orderedObjects forKey: @"orderedObjects"];
  
   // flattenedProperties...
//  NSString *runtimeAttributesKey = [NSString stringWithFormat: @"%@.IBAttributePlaceholdersKey", [[NSUUID UUID] UUIDString]];
//  [_flattenedProperties setElement: _runtimeAttributes forKey: runtimeAttributesKey];
}

- (void)dealloc
{
  RELEASE(_IBObjectContainer);
  RELEASE(_connectionRecords);
  RELEASE(_objectRecords);
  RELEASE(_flattenedProperties);
  RELEASE(_runtimeAttributes);
  RELEASE(_orderedObjects);
  RELEASE(_orderedObjectsDict);
  [super dealloc];
}

#pragma mark - XML decoding method(s)...
- (void) parser: (NSXMLParser*)parser
didStartElement: (NSString*)elementName
   namespaceURI: (NSString*)namespaceURI
  qualifiedName: (NSString*)qualifiedName
     attributes: (NSDictionary*)attributeDict
{
  NSMutableDictionary *attributes  = AUTORELEASE([attributeDict mutableCopy]);
  NSString            *className   = nil;
  NSString            *elementType = elementName;

  // Skip certain element names - for now...
  if ([XmltagsToSkip containsObject:elementName] == NO)
    {
      if (([@"window" isEqualToString: elementName] == NO) &&
          ([@"customView" isEqualToString: elementName] == NO) &&
          ([@"customObject" isEqualToString: elementName] == NO))
        className = [attributes objectForKey: @"customClass"];
      if (nil == className)
        className = [[self class] classNameForXibTag:elementName];
      
      if (nil != className)
        {
          if ([NSClassFromString(className) isSubclassOfClass:[NSArray class]])
            elementType = @"array";
          else if ([@"string" isEqualToString: elementName] == NO)
            elementType = @"object";
        }
      
      // Add the necessary attribute(s)...
      if (className)
        [attributes setObject: className forKey: @"class"];
      
      if ([attributes objectForKey:@"key"] == nil)
        {
          // Special cases to allow current initWithCoder methods to obtain objects..._IBObjectContainer
          if ([@"objects" isEqualToString: elementName])
            {
              [attributes setObject: @"IBDocument.RootObjects" forKey: @"key"];
            }
          else if (([@"items" isEqualToString: elementName]) &&
                   ([[currentElement attributeForKey: @"class"] isEqualToString:@"NSMenu"]))
            {
              [attributes setObject: @"NSMenuItems" forKey: @"key"];
            }
          else
            {
              [attributes setObject: elementName forKey: @"key"];
            }
        }
      
      if (([attributes objectForKey: @"customClass"] == nil) ||
          ([NSClassFromString([attributes objectForKey: @"customClass"]) isSubclassOfClass: [NSApplication class]] == NO))
        if ([[attributes objectForKey: @"userLabel"] isEqualToString: @"Application"])
          [attributes setObject:@"NSApplication" forKey:@"customClass"];
      
      // If there is no ID assigned to this element we're going to arbritrarily
      // add one since we need to cross-reference objects...
      if ([attributes objectForKey: @"id"] == nil)
        [attributes setObject: [[NSUUID UUID] UUIDString] forKey: @"id"];
      
      // FOR DEBUG...CAN BE REMOVED...
      [attributes setObject: elementName forKey: @"key5"];

      // Generate the XIB element object...
      GSXib5Element *element = [[GSXib5Element alloc] initWithType: elementType
                                                     andAttributes: attributes];
      NSString      *key     = [attributes objectForKey: @"key"];
      NSString      *ref     = [attributes objectForKey: @"id"];
      
      if ([@"array" isEqualToString: [currentElement type]])
        {
          // For arrays...
          [currentElement addElement: element];

          // Need to store element for making the connections...
          if ([XmlConnectionRecordTags containsObject: elementName])
            {
              // Get the parent of the parent object...
              // The current object at this point is the 'connections' array element.
              // The parent of connections array element IS the object ID we need...
              GSXib5Element *parent = [stack objectAtIndex: [stack count]-1];
              NSString      *objKey = (([@"action" isEqualToString: elementName]) ?
                                       @"destination" : @"target");
              
              // Store the ID reference of the parent object...
              [element setAttribute: [parent attributeForKey: @"id"] forKey: objKey];

              // Add a connection record element that includes this element...
              [_connectionRecords addElement: [self connectionRecordForElement: element]];
            }
        }
      else
        {
          // For elements...
          [currentElement setElement: element forKey: key];
          
          // If top level document add our generated connection records...
          if ([@"document" isEqualToString: elementName])
            {
              [element setElement: _IBObjectContainer forKey: @"IBDocument.Objects"];
            }
        }

      // Reference(s)...
      if (ref != nil)
        {
          [objects setObject: element forKey: ref];
        }
      
      if ([XmltagsNotStacked containsObject: elementName] == NO)
        {
          // Push element onto stack...
          [stack addObject: currentElement];
        }

      // Set as current element being processed...
      currentElement = element;
      
      AUTORELEASE(element);
    }
}

- (void) parser: (NSXMLParser*)parser
  didEndElement: (NSString*)elementName
   namespaceURI: (NSString*)namespaceURI
  qualifiedName: (NSString*)qName
{
  // Skip certain element names - for now...
  if ([XmltagsToSkip containsObject: elementName] == NO)
    {
      if ([XmltagsNotStacked containsObject: elementName] == NO)
        {
          // Pop element...
          currentElement = [stack lastObject];
          [stack removeLastObject];
        }
    }
}

#pragma mark - Decoding method(s)...
// All this code should eventually move into their respective initWithCoder class
// methods - however note - there are a couple that may be duplicated...

#pragma mark - NSView...
- (id) decodeAutoresizingMaskForElement: (GSXib5Element*)element
{
  NSDictionary *attributes = [element attributes];

  if (attributes)
  {
    NSUInteger mask = NSViewNotSizable;
    
    if ([[attributes objectForKey: @"flexibleMinX"] boolValue])
      mask |= NSViewMinXMargin;
    if ([[attributes objectForKey: @"widthSizable"] boolValue])
      mask |= NSViewWidthSizable;
    if ([[attributes objectForKey: @"flexibleMaxX"] boolValue])
      mask |= NSViewMaxXMargin;
    if ([[attributes objectForKey: @"flexibleMinY"] boolValue])
      mask |= NSViewMinYMargin;
    if ([[attributes objectForKey: @"heightSizable"] boolValue])
      mask |= NSViewHeightSizable;
    if ([[attributes objectForKey: @"flexibleMaxY"] boolValue])
      mask |= NSViewMaxYMargin;
    
    return [NSNumber numberWithUnsignedInt: mask];
  }
  
  return nil;
}

- (id) decodeViewFlagsForElement: (GSXib5Element*)element
{
  Class class   = NSClassFromString([element attributeForKey: @"class"]);
  id    object  = nil;
  
  if ([class isSubclassOfClass: [NSView class]] == NO)
    {
      NSWarnMLog(@"called for a class that is NOT a sub-class of NSView - class: %@", NSStringFromClass(class));
    }
  else
    {
      typedef union _GSvFlagsUnion
      {
        GSvFlags flags;
        uint32_t value;
      } GSvFlagsUnion;
      
      GSvFlagsUnion  mask             = { { 0 } };
      NSDictionary  *attributes       = [element attributes];
      GSXib5Element *autoresizingMask = (GSXib5Element*)[element elementForKey: @"autoresizingMask"];
      
      mask.flags.autoresizingMask    = [[self decodeAutoresizingMaskForElement: autoresizingMask] unsignedIntegerValue];
      mask.flags.isHidden            = [[attributes objectForKey: @"hidden"] boolValue];
      mask.flags.autoresizesSubviews = YES;
      
      if ([attributes objectForKey: @"autoresizesSubviews"])
        mask.flags.autoresizesSubviews = [[attributes objectForKey: @"autoresizesSubviews"] boolValue];
      
      // Return value...
      object = [NSNumber numberWithUnsignedInt: mask.value];
    }
  
  return object;
}

#pragma mark - NSClipView...
- (id) decodeClipViewDocumentViewForElement: (GSXib5Element*)element
{
  NSArray *subviews = [self decodeObjectForKey: @"subviews"];
  
  if ([subviews count])
    return [subviews objectAtIndex: 0];
  
  NSWarnMLog(@"no clipview document view for element: %@", element);
  return nil;
}

#pragma mark - NSWindow...
- (id) decodeWindowTemplateFlagsForElement: (GSXib5Element*)element
{
  NSDictionary *attributes = [element attributes];
  
  if (attributes)
  {
    typedef union _GSWindowTemplateFlagsUnion
    {
      GSWindowTemplateFlags  flags;
      uint32_t               value;
    } GSWindowTemplateFlagsUnion;
    
    GSWindowTemplateFlagsUnion   mask = { { 0 } };
    GSXib5Element               *winPosMaskEleme  = (GSXib5Element*)[currentElement elementForKey: @"initialPositionMask"];
    NSUInteger                   winPosMask       = [[self decodeWindowPositionMaskForElement:winPosMaskEleme] unsignedIntegerValue];
    NSString                    *autorecalculatesKeyViewLoop = [element attributeForKey: @"autorecalculatesKeyViewLoop"];
    
    mask.flags.isHiddenOnDeactivate =  [[attributes objectForKey: @"hidesOnDeactivate"] boolValue];
    mask.flags.isNotReleasedOnClose = !([attributes objectForKey: @"releasedWhenClosed"] ?
                                        [[attributes objectForKey: @"releasedWhenClosed"] boolValue] : YES);
    mask.flags.isDeferred           =  ([attributes objectForKey: @"deferred"] ?
                                        [[attributes objectForKey: @"deferred"] boolValue] : YES);
    mask.flags.isOneShot            =  ([attributes objectForKey: @"oneShot"] ?
                                        [[attributes objectForKey: @"oneShot"] boolValue] : YES);
    
    mask.flags.isVisible            =  ([attributes objectForKey: @"visibleAtLaunch"] ?
                                        [[attributes objectForKey: @"visibleAtLaunch"] boolValue] : YES);
    mask.flags.wantsToBeColor       =  0; // ???;
    mask.flags.dynamicDepthLimit    =  0; // ???;
    mask.flags.autoPositionMask     =  winPosMask;
    mask.flags.savePosition         =  [attributes objectForKey: @"frameAutosaveName"] != nil;
    mask.flags.style                =  0; // ???
    mask.flags.isNotShadowed        = !([attributes objectForKey: @"hasShadow"] ?
                                        [[attributes objectForKey: @"hasShadow"] boolValue] : YES);
    mask.flags.autorecalculatesKeyViewLoop = (autorecalculatesKeyViewLoop ? [autorecalculatesKeyViewLoop boolValue] : YES);
    
    // File GSNibLoading.m: 422. In -[NSWindowTemplate initWithCoder:] _flags: 0xf0781400 style: 147 backing: 2
    // File GSNibLoading.m: 422. In -[NSWindowTemplate initWithCoder:] _flags: 0xf0001000 style: 147 backing: 2

#if 0 // FIXME:
    mask.flags.allowsToolTipsWhenApplicationIsInactive = ([attributes objectForKey: @"allowsToolTipsWhenApplicationIsInactive"] ?
                                                          [[attributes objectForKey: @"allowsToolTipsWhenApplicationIsInactive"] boolValue] :
                                                          YES);
#endif
    
    return [NSNumber numberWithUnsignedInteger: mask.value];
  }
  
  return nil;
}

- (id) decodeWindowBackingStoreForElement: (GSXib5Element*)element
{
  NSUInteger   value       = NSBackingStoreBuffered; // Default for Cocoa...
  NSString    *backingType = [element attributeForKey: @"backingType"];
  
  if (backingType)
    {
      if ([@"retained" isEqualToString: backingType])
        value = NSBackingStoreRetained;
      else if ([@"nonretained" isEqualToString: backingType])
        value = NSBackingStoreNonretained;
      else
        NSWarnMLog(@"unknown backing store type: %@", backingType);
    }
  
  return [NSNumber numberWithUnsignedInteger: value];
}

- (id) decodeWindowPositionMaskForElement: (GSXib5Element*)element
{
  NSDictionary *attributes = [element attributes];
  
  if (attributes)
  {
    NSUInteger mask = 0;
    
    return [NSNumber numberWithUnsignedInteger: mask];
  }
  
  return nil;
}

- (id) decodeWindowStyleMaskForElement: (GSXib5Element*)element
{
  NSDictionary *attributes = [element attributes];
  
  if (attributes)
    {
      NSUInteger mask = 0;
      
      if ([[attributes objectForKey: @"titled"] boolValue])
        mask |= NSTitledWindowMask;
      if ([[attributes objectForKey: @"closable"] boolValue])
        mask |= NSClosableWindowMask;
      if ([[attributes objectForKey: @"miniaturizable"] boolValue])
        mask |= NSMiniaturizableWindowMask;
      if ([[attributes objectForKey: @"resizable"] boolValue])
        mask |= NSResizableWindowMask;
      if ([[attributes objectForKey: @"texturedBackground"] boolValue])
        mask |= NSTexturedBackgroundWindowMask;
      if ([[attributes objectForKey: @"unifiedTitleAndToolbar"] boolValue])
        mask |= NSUnifiedTitleAndToolbarWindowMask;
      if ([[attributes objectForKey: @"fullSizeContentView"] boolValue])
        mask |= NSWindowStyleMaskFullSizeContentView;
      if ([[attributes objectForKey: @"utility"] boolValue])
        mask |= NSWindowStyleMaskUtilityWindow;
      if ([[attributes objectForKey: @"nonactivatingPanel"] boolValue])
        mask |= NSWindowStyleMaskNonactivatingPanel;
      
      return [NSNumber numberWithUnsignedInteger: mask];
    }
  
  return nil;
}

#pragma mark - NSForm/NSMatrix...
- (id)decodeMatrixFlagsForElement: (GSXib5Element*)element
{
  NSString           *mode                 = [element attributeForKey: @"mode"];
  NSString           *allowsEmptySelection = [element attributeForKey: @"allowsEmptySelection"];
  NSString           *autosizesCells       = [element attributeForKey: @"autosizesCells"];
  NSString           *drawsBackground      = [element attributeForKey: @"drawsBackground"];
  NSString           *selectionByRect      = [element attributeForKey: @"selectionByRect"];
  GSMatrixFlagsUnion  mask                 = { { 0 } };

  // mode...
  if ([@"list" isEqualToString: mode])
    {
      mask.flags.isList = 1;
    }
  else if ([@"highlight" isEqualToString: mode])
    {
      mask.flags.isHighlight = 1;
    }
  else if ([@"radio" isEqualToString: mode])
    {
      mask.flags.isRadio = 1;
    }
  else if ([@"track" isEqualToString: mode])
    {
      // What do we do with this type???
    }
  else if (mode)
    {
      NSWarnMLog(@"unknown matrix mode: %@", mode);
    }
  
  // allows empty selection...
  if (allowsEmptySelection == nil)
    mask.flags.allowsEmptySelection = 1;
  else
    mask.flags.allowsEmptySelection = [allowsEmptySelection boolValue];
  
  // autosizes cells...
  if (autosizesCells == nil)
    mask.flags.autosizesCells = 1;
  else
    mask.flags.autosizesCells = [autosizesCells boolValue];
  
  // draw background/cell background...
  if (drawsBackground)
    mask.flags.drawBackground = [drawsBackground boolValue];
  mask.flags.drawCellBackground = mask.flags.drawBackground;
  
  // selection by rectangle...
  if (selectionByRect == nil)
    mask.flags.selectionByRect = 1;
  else
    mask.flags.selectionByRect = [selectionByRect boolValue];
  
  return [NSNumber numberWithUnsignedInt: mask.value];
}

- (id)decodeNumberOfColumnsInMatrixForElement: (GSXib5Element*)element
{
  id    object  = nil;
  Class class   = NSClassFromString([element attributeForKey: @"class"]);
  
  if ([class isSubclassOfClass: [NSMatrix class]])
    {
      NSArray *cells = [self decodeObjectForKey: @"cells"];
      object         = [NSNumber numberWithUnsignedInteger: [cells count]];
    }
  
  return object;
}

- (id)decodeNumberOfRowsInMatrixForElement: (GSXib5Element*)element
{
  id    object  = nil;
  Class class   = NSClassFromString([element attributeForKey: @"class"]);
  
  if ([class isSubclassOfClass: [NSMatrix class]])
    {
      NSArray *cells  = [self decodeObjectForKey: @"cells"];
      NSArray *column = [cells objectAtIndex: 0];
      object          = [NSNumber numberWithUnsignedInteger: [column count]];
    }
  
  return object;
}

- (id)decodeFormCellsForElement: (GSXib5Element*)element
{
  id         object  = [NSMutableArray array];
  NSArray   *columns = [self decodeObjectForKey: @"cells"];
  NSInteger  numCols = [columns count];
  NSInteger  numRows = [[columns objectAtIndex: 0] count];
  NSInteger  row     = 0;
  NSInteger  col     = 0;
  
  // NSForm's cells now encoded as two dimensional array but we need
  // the cells in a single array by column/row...
  for (row = 0; row < numRows; ++row)
    {
      for (col = 0; col < numCols; ++col)
        {
          // Add the row/column object...
          [object addObject: [[columns objectAtIndex: col] objectAtIndex: row]];
        }
    }
  
  return object;
}

- (id)decodeNameForElement: (GSXib5Element*)element
{
  id    object = nil;
  Class class  = NSClassFromString([element attributeForKey: @"class"]);
  
  if ([class isSubclassOfClass: [NSMenu class]])
    {
      object = [element attributeForKey: @"systemMenu"];
      
      if ([@"main" isEqualToString: object])
        object = @"_NSMainMenu";
      else if ([@"apple" isEqualToString: object])
        object = @"_NSAppleMenu";
      else if ([@"window" isEqualToString: object])
        object = @"_NSWindowsMenu";
      else if ([@"services" isEqualToString: object])
        object = @"_NSServicesMenu";
      else if ([@"recentDocuments" isEqualToString: object])
        object = @"_NSRecentDocumentsMenu";
      else if ([@"font" isEqualToString: object])
        object = @"_NSFontMenu";
    }
  else if ([element attributeForKey: @"name"])
    {
      object = [self decodeObjectForKey: @"name"];
    }
  else if ([class isSubclassOfClass: [NSFont class]] == NO)
    {
      NSWarnMLog(@"no name object for class: %@", [element attributeForKey: @"class"]);
    }
  
  return object;
}

#pragma mark - NSSlider...
- (id)decodeSliderCellTickMarkPositionForElement: (GSXib5Element*)element
{
  NSUInteger  value            = NSTickMarkBelow; // Default...
  NSString   *tickMarkPosition = [element attributeForKey: @"tickMarkPosition"];

  if ([@"below" isEqualToString: tickMarkPosition])
    value = NSTickMarkBelow;
  else if ([@"above" isEqualToString: tickMarkPosition])
    value = NSTickMarkAbove;
  else if ([@"leading" isEqualToString: tickMarkPosition])
    value = NSTickMarkLeft;
  else if ([@"trailing" isEqualToString: tickMarkPosition])
    value = NSTickMarkRight;
  else if (tickMarkPosition)
    NSWarnMLog(@"unknown slider cell tick mark position: %@", tickMarkPosition);
  
  return [NSNumber numberWithUnsignedInteger: value];
}

- (id)decodeSliderCellTypeForElement: (GSXib5Element*)element
{
  NSUInteger  value      = NSCircularSlider; // Default...
  NSString   *sliderType = [element attributeForKey: @"sliderType"];
  
  if ([@"linear" isEqualToString: sliderType])
    value = NSLinearSlider;
  else if ([@"circular" isEqualToString: sliderType])
    value = NSCircularSlider;
  else if (sliderType)
    NSWarnMLog(@"unknown slider cell type: %@", sliderType);
  
  return [NSNumber numberWithUnsignedInteger: value];
}

- (id)decodeCellsForElement: (GSXib5Element*)element
{
  id    object = nil;
  Class class  = NSClassFromString([element attributeForKey: @"class"]);
  
  if ([class isSubclassOfClass: [NSMatrix class]])
    object = [self decodeFormCellsForElement: element];
  else
    object = [self decodeObjectForKey: @"cells"];
  
  return object;
}

#pragma mark - NSMenu/NSMenuItem...
- (id)decodePullsDownForElement: (GSXib5Element*)element
{
  NSString  *pullsDown = [element attributeForKey: @"pullsDown"];
  BOOL       value     = YES; // Default if not present...
  
  if (pullsDown)
    value = [pullsDown boolValue];
  
  return [NSNumber numberWithBool: value];
}

- (id)decodeAutoenablesItemsForElement: (GSXib5Element*)element
{
  NSString  *autoenablesItems = [element attributeForKey: @"autoenablesItems"];
  BOOL       value            = YES; // Default if not present...
  
  if (autoenablesItems)
    value = [autoenablesItems boolValue];
  
  return [NSNumber numberWithBool: value];
}

- (id)decodeAltersStateForElement: (GSXib5Element*)element
{
  NSString  *altersState = [element attributeForKey: @"altersStateOfSelectedItem"];
  BOOL       value       = YES; // Default if not present...
  
  if (altersState)
    value = [altersState boolValue];

  return [NSNumber numberWithBool: value];
}

- (id)decodeMenuItemForElement: (GSXib5Element*)element
{
  NSString      *itemID   = [element attributeForKey: @"selectedItem"];
  GSXib5Element *itemElem = [objects objectForKey: itemID];
  id             object   = [self objectForXib: itemElem];
  
  return object;
}

- (id)decodeTitleCellForElement: (GSXib5Element*)element
{
  id        object  = nil;
  NSString *title   = [element attributeForKey: @"title"];
  
  if (title)
    {
      NSFont *font = [self decodeObjectForKey: @"titleFont"];
      
      // IF no font...
      if (font == nil) // default to system-11...
        font = [NSFont systemFontOfSize: 11];
      
      object = [[NSCell alloc] initTextCell: title];
      [object setAlignment: NSCenterTextAlignment];
      [object setBordered: NO];
      [object setEditable: NO];
      [object setFont: font];
    }
  
  return AUTORELEASE(object);
}

- (id)decodeBorderTypeForElement: (GSXib5Element*)element
{
  NSString      *borderType = [element attributeForKey: @"borderType"];
  NSBorderType   value      = NSGrooveBorder; // Cocoa default...

  if (borderType)
    {
      if ([@"bezel" isEqualToString: borderType])
        value = NSBezelBorder;
      else if ([@"line" isEqualToString: borderType])
        value = NSLineBorder;
      else if ([@"none" isEqualToString: borderType])
        value = NSNoBorder;
      else
        NSWarnMLog(@"unknown border type: %@", borderType);
    }
  
  return [NSNumber numberWithUnsignedInteger: value];
}

- (id) decodeModifierMaskForElement: (GSXib5Element*)element
{
  id            object     = nil;
  NSDictionary *attributes = [[element elementForKey: @"keyEquivalentModifierMask"] attributes];

  // ??? SKIP modifier mask processing if BASE64-UTF8 string being used ???
  if (attributes == nil)
    {
      if (([element elementForKey: @"keyEquivalent"]) &&
          ([[element elementForKey: @"keyEquivalent"] attributeForKey: @"base64-UTF8"]))
      {
        object = [NSNumber numberWithUnsignedInt: 0];
      }
    else
      {
        // Seems that Apple decided to omit this attribute IF certain default keys alone
        // are applied.  If this key is present WITH NO setting then the following is
        // used for the modifier mask...
        object = [NSNumber numberWithUnsignedInt: NSCommandKeyMask];
      }
    }
  else
    {
      // If the modifier mask element is present then no modifier attributes
      // equates to no key modifiers applied...
      NSUInteger mask = 0;
      
      if ([[attributes objectForKey:@"option"] boolValue])
        {
          mask |= NSAlternateKeyMask;
        }
      if ([[attributes objectForKey:@"alternate"] boolValue])
        {
          mask |= NSAlternateKeyMask;
        }
      if ([[attributes objectForKey:@"command"] boolValue])
        {
          mask |= NSCommandKeyMask;
        }
      if ([[attributes objectForKey:@"control"] boolValue])
        {
          mask |= NSControlKeyMask;
        }
      if ([[attributes objectForKey:@"shift"] boolValue])
        {
          mask |= NSShiftKeyMask;
        }
      if ([[attributes objectForKey:@"numeric"] boolValue])
        {
          mask |= NSNumericPadKeyMask;
        }
      if ([[attributes objectForKey:@"help"] boolValue])
        {
          mask |= NSHelpKeyMask;
        }
      if ([[attributes objectForKey:@"function"] boolValue])
        {
          mask |= NSFunctionKeyMask;
        }
      
      object = [NSNumber numberWithUnsignedInt: mask];
    }
  
  return object;
}

#pragma mark - NSBox...
- (id)decodeBoxTypeForElement: (GSXib5Element*)element
{
  NSString  *boxType = [element attributeForKey: @"boxType"];
  NSBoxType  value   = NSBoxPrimary; // Cocoa default...

  if (boxType)
  {
    if ([@"secondary" isEqualToString: boxType])
      value = NSBoxSecondary;
    else if ([@"separator" isEqualToString: boxType])
      value = NSBoxSeparator;
    else if ([@"oldStyle" isEqualToString: boxType])
      value = NSBoxOldStyle;
    else if ([@"custom" isEqualToString: boxType])
      value = NSBoxCustom;
    else if ([@"primary" isEqualToString: boxType])
      value = NSBoxPrimary;
    else
      NSWarnMLog(@"unknown box type: %@", boxType);
  }
  
  return [NSNumber numberWithUnsignedInteger: value];
}

- (id)decodeTitlePositionForElement: (GSXib5Element*)element
{
  NSString        *titlePosition = [element attributeForKey: @"titlePosition"];
  NSTitlePosition  value         = NSAtTop; // Default if not present...

  if (titlePosition)
    {
      if ([@"noTitle" isEqualToString: titlePosition])
        value = NSNoTitle;
      else if ([@"aboveTop" isEqualToString: titlePosition])
        value = NSAboveTop;
      else if ([@"belowTop" isEqualToString: titlePosition])
        value = NSBelowTop;
      else if ([@"aboveBottom" isEqualToString: titlePosition])
        value = NSAboveTop;
      else if ([@"atBottom" isEqualToString: titlePosition])
        value = NSAtBottom;
      else if ([@"belowBottom" isEqualToString: titlePosition])
        value = NSBelowBottom;
      else if ([@"atTop" isEqualToString: titlePosition])
        value = NSAtTop;
      else
        NSWarnMLog(@"unknown title position: %@", titlePosition);
    }
  
  return [NSNumber numberWithUnsignedInteger: value];
}

#pragma mark - NSFont...
- (id)decodeFontSizeForElement: (GSXib5Element*)element
{
  NSDictionary *attributes = [element attributes];
  CGFloat       size       = [[attributes objectForKey: @"size"] floatValue];
  
  if (size == 0)
    {
      NSString *metaFont = [[attributes objectForKey: @"metaFont"] lowercaseString];
      
      // Default the value per Cocoa...
      size = 13;
      
      if ([metaFont containsString: @"mini"])
        size = 9;
      else if ([metaFont containsString: @"small"])
        size = 11;
      else if ([metaFont containsString: @"medium"])
        size = 12;
      else if ([metaFont containsString: @"menu"])
        size = 13;
      else if ([metaFont containsString: @"system"])
        size = 13;
      else if (metaFont)
        NSWarnMLog(@"unknown meta font value: %@", metaFont);
    }
  
  return [NSNumber numberWithFloat: size];
}

- (id)decodeFontTypeForElement: (GSXib5Element*)element
{
  static NSArray *MetaFontSystemNames = nil;
  if (MetaFontSystemNames == nil)
    {
      MetaFontSystemNames = @[ @"system", @"message" ];
      RETAIN(MetaFontSystemNames);
    }
  
  NSDictionary *attributes = [element attributes];
  NSString     *metaFont   = [[attributes objectForKey: @"metaFont"] lowercaseString];
  BOOL          isSystem   = [MetaFontSystemNames containsObject: metaFont];
  return [NSNumber numberWithBool: isSystem];
}

#pragma mark - NSSplitView...
- (id) decodeDividerStyleForElement: (GSXib5Element*)element
{
  NSString                *dividerStyle = [element attributeForKey: @"dividerStyle"];
  NSSplitViewDividerStyle  style        = NSSplitViewDividerStyleThick; // Default...
  
  if (dividerStyle)
    {
      if ([@"thin" isEqualToString: dividerStyle])
        style = NSSplitViewDividerStyleThin;
      else if ([@"paneSplitter" isEqualToString: dividerStyle])
        style = NSSplitViewDividerStylePaneSplitter;
#if 0 // DEFAULT - see above...
      else if ([@"thick" isEqualToString: dividerStyle])
        style = NSSplitViewDividerStyleThick;
#endif
      else
        NSWarnMLog(@"unknown divider style: %@", dividerStyle);
    }
  
  return [NSNumber numberWithInteger: style];
}

- (id) decodeBackgroundColorsForElement: (GSXib5Element*)element
{
  NSMutableArray *backgroundColors = [NSMutableArray array];
  NSColor        *primaryColor     = [self decodeObjectForKey: @"primaryBackgroundColor"];
  NSColor        *secondaryColor   = [self decodeObjectForKey: @"secondaryBackgroundColor"];
  
  // If primary only - just one background color...
  if (primaryColor)
    [backgroundColors addObject: primaryColor];

  // If secondary included - indicates alternating background color scheme...
  if (secondaryColor)
    [backgroundColors addObject: secondaryColor];
  
  return backgroundColors;
}

#pragma mark - NSProgressIndicator...
- (id) decodeProgressIndicatorFlagsForElement: (GSXib5Element*)element
{
  unsigned int  flags                 = 0;
#if 0
  NSString     *bezeled               = [element attributeForKey: @"bezeled"];
#endif
  NSString     *style                 = [element attributeForKey: @"style"];
  NSString     *controlSize           = [element attributeForKey: @"controlSize"];
  NSString     *indeterminate         = [element attributeForKey: @"indeterminate"];
  NSString     *displayedWhenStopped  = [element attributeForKey: @"displayedWhenStopped"];
  
  if ([indeterminate boolValue])
    flags |= 0x0002;
  if ([@"small" isEqualToString: controlSize])
    flags |= 0x0100;
  if ([@"spinning" isEqualToString: style])
    flags |= 0x1000;
  if ((displayedWhenStopped == nil) || ([displayedWhenStopped boolValue]))
    flags |= 0x2000;
  
  return [NSNumber numberWithInt: flags];
}

#pragma mark - NSTextView...
- (id) decodeTextViewSharedDataFlagsForElement: (GSXib5Element*)element
{
  unsigned int  flags              = 0;
  NSString     *allowsUndo         = [element attributeForKey: @"allowsUndo"];
  NSString     *importsGraphics    = [element attributeForKey: @"importsGraphics"];
  NSString     *editable           = [element attributeForKey: @"editable"];
  NSString     *selectable         = [element attributeForKey: @"selectable"];
  NSString     *fieldEditor        = [element attributeForKey: @"fieldEditor"];
  NSString     *findStyle          = [element attributeForKey: @"findStyle"];
  NSString     *richText           = [element attributeForKey: @"richText"];
  NSString     *smartInsertDelete  = [element attributeForKey: @"smartInsertDelete"];
  NSString     *usesFontPanel      = [element attributeForKey: @"usesFontPanel"];
  NSString     *usesRuler          = [element attributeForKey: @"usesRuler"];
  NSString     *drawsBackground    = [element attributeForKey: @"drawsBackground"];
  NSString     *continuousSpellChecking = [element attributeForKey: @"continuousSpellChecking"];
  
#if 0
  // FIXME: if and when these are added to NSTextView...
  NSString     *allowsNonContiguousLayout           = [element attributeForKey: @"allowsNonContiguousLayout"];
  NSString     *spellingCorrection                  = [element attributeForKey: @"spellingCorrection"];
  NSString     *allowsImageEditing                  = [element attributeForKey: @"allowsImageEditing"];
  NSString     *allowsDocumentBackgroundColorChange = [element attributeForKey: @"allowsDocumentBackgroundColorChange"];
#endif
  
  if ((selectable == nil) || ([selectable boolValue]))
    flags |= 0x01;
  if ((editable == nil) || ([editable boolValue]))
    flags |= 0x02;
  if ((richText == nil) || ([richText boolValue]))
    flags |= 0x04;
  if ([importsGraphics boolValue])
    flags |= 0x08;
  if ([fieldEditor boolValue])
    flags |= 0x10;
  if ([usesFontPanel boolValue])
    flags |= 0x20;
  if ([usesRuler boolValue])
    flags |= 0x40;
  if ([continuousSpellChecking boolValue])
    flags |= 0x80;
  if ([usesRuler boolValue])
    flags |= 0x100;
  if ([smartInsertDelete boolValue])
    flags |= 0x200;
  if ([allowsUndo boolValue])
    flags |= 0x400;
  if ((drawsBackground == nil) || ([drawsBackground boolValue]))
    flags |= 0x800;
  if (findStyle) //([@"panel" isEqualToString: findStyle])
    flags |= 0x2000;
  
#if 0
  // FIXME: when added to NSTextView...
  if ([allowsImageEditing boolValue])
    flags |= 0x00;
  if ([allowsDocumentBackgroundColorChange boolValue])
    flags |= 0x00;
#endif
  
  return [NSNumber numberWithUnsignedInt: flags];
}

- (id) decodeSharedDataForElement: (GSXib5Element*)element
{
  id object = [[NSClassFromString(@"NSTextViewSharedData") alloc] initWithCoder: self];
  
  return AUTORELEASE(object);
}

- (id) decodeTextViewFlagsForElement: (GSXib5Element*)element
{
  unsigned int flags = 0;
  
  // horizontallyResizable...
  if ([[element attributeForKey: @"horizontallyResizable"] boolValue])
    flags |= 0x01;
  
  // verticallyResizable...
  if ([element attributeForKey: @"verticallyResizable"] == nil)
    flags |= 0x02;
  else if ([[element attributeForKey: @"verticallyResizable"] boolValue])
    flags |= 0x02;
  
  return [NSNumber numberWithUnsignedInt: flags];
}

- (id) decodeDefaultParagraphStyleForElement: (GSXib5Element*)element
{
  NSMutableParagraphStyle *paragraphStyle        = AUTORELEASE([NSMutableParagraphStyle new]);
  NSString                *baseWritingDirection  = [element attributeForKey: @"baseWritingDirection"];
  NSString                *selectionGranularity  = [element attributeForKey: @"selectionGranularity"];
  
  if (baseWritingDirection == nil)
    [paragraphStyle setBaseWritingDirection: NSWritingDirectionNaturalDirection];
  else if ([@"leftToRight" isEqualToString: baseWritingDirection])
    [paragraphStyle setBaseWritingDirection: NSWritingDirectionLeftToRight];
  else if ([@"rightToLeft" isEqualToString: baseWritingDirection])
    [paragraphStyle setBaseWritingDirection: NSWritingDirectionRightToLeft];
  else
    NSWarnMLog(@"unknown base writing direction: %@", baseWritingDirection);
  
  // Line break mode...
  [paragraphStyle setLineBreakMode: [self decodeLineBreakModeForAttributes: [element attributes]]];
  
  if (selectionGranularity == nil)
    ; // NSSelectByCharacter
  else if ([@"word" isEqualToString: selectionGranularity])
    ; // NSSelectByWord
  else if ([@"paragraph" isEqualToString: selectionGranularity])
    ; // NSSelectByParagraph
  
  return paragraphStyle;
}

#pragma mark - NSColor...
- (id) decodeColorSpaceForElement: (GSXib5Element*)element
{
  // <color key="textColor" name="labelColor" catalog="System" colorSpace="catalog"/>
  // <color key="backgroundColor" white="1" alpha="1" colorSpace="calibratedWhite"/>
  // <color key="textColor" red="0.0" green="0.0" blue="1" alpha="1" colorSpace="calibratedRGB"/>
  // <color key="insertionPointColor" name="controlTextColor" catalog="System" colorSpace="catalog"/>
  // <color key="backgroundColor" cyan="0.61524784482758621" magenta="0.17766702586206898" yellow="0.48752693965517241" black="0.60991379310344829"
  //  alpha="1" colorSpace="custom" customColorSpace="genericCMYKColorSpace"/>
  // <color key=“textColor” red=“0.72941176470000002" green=“0.53333333329999999” blue=“0.1333333333" alpha=“1”
  //  colorSpace=“custom” customColorSpace=“sRGB”/>
  NSDictionary *attributes = [element attributes];
  NSString     *colorSpace = [attributes objectForKey: @"colorSpace"];
  
  if (colorSpace)
    {
      NSUInteger value = 0;
      
      // Put most common first???
      if ([@"catalog" isEqualToString: colorSpace])
        {
          value = 6;
        }
      else if ([@"calibratedRGB" isEqualToString: colorSpace])
        {
          value = 1;
        }
      else if ([@"deviceRGB" isEqualToString: colorSpace])
        {
          value = 2;
        }
      else if ([@"calibratedWhite" isEqualToString: colorSpace])
        {
          value = 3;
        }
      else if ([@"deviceWhite" isEqualToString: colorSpace])
        {
          value = 4;
        }
      else if ([@"custom" isEqualToString: colorSpace])
      {
        NSString *customSpace = [attributes objectForKey: @"customColorSpace"];
        
        if ([@"genericCMYKColorSpace" isEqualToString: customSpace])
          {
            value = 5;
          }
        else if ([@"sRGB" isEqualToString: customSpace])
          {
            value = 2;
          }
        else if (customSpace)
          {
            NSLog(@"%s:unknown custom color space: %@", __PRETTY_FUNCTION__, customSpace);
          }
      }
      else
        {
          NSLog(@"%s:unknown color space: %@", __PRETTY_FUNCTION__, colorSpace);
        }

      return [NSNumber numberWithUnsignedInteger: value];
    }
  
  return nil;
}

- (id) decodeColorCYMKForElement: (GSXib5Element*)element
{
  // <color key="backgroundColor" cyan="0.61524784482758621" magenta="0.17766702586206898"
  //  yellow="0.48752693965517241" black="0.60991379310344829"
  //  alpha="1" colorSpace="custom" customColorSpace="genericCMYKColorSpace"/>
  double     cyan    = [self decodeDoubleForKey: @"cyan"];
  double     yellow  = [self decodeDoubleForKey: @"yellow"];
  double     magenta = [self decodeDoubleForKey: @"magenta"];
  double     black   = [self decodeDoubleForKey: @"black"];
  double     alpha   = [self decodeDoubleForKey: @"alpha"];
  NSString  *string  = [NSString stringWithFormat: @"%f %f %f %f %f", cyan, yellow, magenta, black, alpha];
  
  return [string dataUsingEncoding: NSUTF8StringEncoding];
}

- (id) decodeColorRGBForElement: (GSXib5Element*)element
{
  // <color key="textColor" red="0.0" green="0.0" blue="1" alpha="1" colorSpace="calibratedRGB"/>
  double     red    = [self decodeDoubleForKey: @"red"];
  double     green  = [self decodeDoubleForKey: @"green"];
  double     blue   = [self decodeDoubleForKey: @"blue"];
  double     alpha  = [self decodeDoubleForKey: @"alpha"];
  NSString  *string = [NSString stringWithFormat: @"%f %f %f %f", red, green, blue, alpha];
  
  return [string dataUsingEncoding: NSUTF8StringEncoding];
}

- (id) decodeColorWhiteForElement: (GSXib5Element*)element
{
  // <color key="backgroundColor" white="1" alpha="1" colorSpace="calibratedWhite"/>
  double     white  = [self decodeDoubleForKey: @"white"];
  double     alpha  = [self decodeDoubleForKey: @"alpha"];
  NSString  *string = [NSString stringWithFormat: @"%f %f", white, alpha];

  return [string dataUsingEncoding: NSUTF8StringEncoding];
}

- (id) decodeBackgroundColorForElement: (GSXib5Element*)element
{
  id object = [self decodeObjectForKey: @"backgroundColor"];
  
  // Return a default color if none available...
  if (object == nil)
    object = [NSColor whiteColor];
  
  return object;
}

#pragma mark - NSScrollView/NSScroller...
- (id) decodeScrollerFlagsForElement: (GSXib5Element*)element
{
  NSUInteger     mask           = (NSAllScrollerParts << 27); // Default...
  NSDictionary  *attributes     = [element attributes];
  NSString      *arrowsPosition = [attributes objectForKey: @"arrowsPosition"];
  NSString      *controlTint    = [attributes objectForKey: @"controlTint"];

  // Decode arrows position...
  if (arrowsPosition == nil)
    mask |= (NSScrollerArrowsDefaultSetting << 29);
  else if ([@"none" isEqualToString: arrowsPosition])
    mask |= (NSScrollerArrowsNone << 29);
  else if ([@"default" isEqualToString: arrowsPosition])
    mask |= (NSScrollerArrowsDefaultSetting << 29);
  else
    NSWarnMLog(@"unknown scroller arrows position: %@", arrowsPosition);
  
  // Decode control tint...
  if (controlTint == nil)
    mask |= NSDefaultControlTint << 16;
  else if ([@"blue" isEqualToString: controlTint])
    mask |= NSBlueControlTint << 16;
  else if ([@"graphite" isEqualToString: controlTint])
    mask |= NSGraphiteControlTint << 16;
  else if ([@"clear" isEqualToString: controlTint])
    mask |= NSClearControlTint << 16;
  else
    NSWarnMLog(@"unknown control tint: %@", controlTint);
  
  // Return value...
  return [NSNumber numberWithUnsignedInt: mask];
}

- (id) decodeScrollerFlags2ForElement: (GSXib5Element*)element
{
  NSUInteger     mask         = 0;
  NSDictionary  *attributes   = [element attributes];
  NSString      *controlSize  = [attributes objectForKey: @"controlSize"];
  
  if (controlSize == nil)
    mask |= NSControlSizeRegular << 26;
  else if ([@"small" isEqualToString: controlSize])
    mask |= NSControlSizeSmall << 26;
  else if ([@"mini" isEqualToString: controlSize])
    mask |= NSControlSizeMini << 26;
  else if ([@"regular" isEqualToString: controlSize])
    mask |= NSControlSizeRegular << 26;
  else
    NSWarnMLog(@"unknown scroller control size: %@", controlSize);

  return [NSNumber numberWithUnsignedInteger: mask];
}

- (id) decodeScrollViewFlagsForElement: (GSXib5Element*)element
{
  NSUInteger    mask       = NSBezelBorder; // Default...
  NSDictionary *attributes = [element attributes];
  NSString     *borderType = [attributes objectForKey: @"borderType"];
  
  // borderType
  if (borderType == nil)
    {
      mask = NSBezelBorder;
    }
  else if ([@"none" isEqualToString: borderType])
    {
      mask = NSNoBorder;
    }
  else if ([@"line" isEqualToString: borderType])
    {
      mask = NSLineBorder;
    }
  else if ([@"groove" isEqualToString: borderType])
    {
      mask = NSGrooveBorder;
    }
  else
    {
      NSWarnMLog(@"unknown border type: %@", borderType);
    }
  
  // hasVerticalScroller
  if ([attributes objectForKey: @"hasVerticalScroller"] == nil)
    mask |= (1 << 4);
  else
    mask |= ([[attributes objectForKey: @"hasVerticalScroller"] boolValue] ? (1 << 4) : 0);
  
  // hasHorizontalScroller
  if ([attributes objectForKey: @"hasHorizontalScroller"] == nil)
    mask |= (1 << 5);
  else
    mask |= ([[attributes objectForKey: @"hasHorizontalScroller"] boolValue] ? (1 << 5) : 0);
  
  // autohidesScrollers - if not present then disable...
  if ([attributes objectForKey: @"autohidesScrollers"])
    mask |= ([[attributes objectForKey: @"autohidesScrollers"] boolValue] ? (1 << 9) : 0);

  // Return value...
  return [NSNumber numberWithUnsignedInt: mask];
}

- (id) decodeScrollViewHeaderClipViewForElement: (GSXib5Element*)element
{
  NSTableHeaderView *headerView = [self decodeObjectForKey: @"headerView"];
  id                 object     = [[NSClipView alloc] initWithFrame: [headerView frame]];
  
#if 0
  [object setAutoresizesSubviews: YES];
  [object setAutoresizingMask: NSViewWidthSizable | NSViewMaxYMargin];
#endif
  [object setNextKeyView: (NSView*)headerView];
  [object setDocumentView: (NSView*)headerView];
  
  return AUTORELEASE(object);
}

- (id) decodeScrollClassFlagsForElement: (GSXib5Element*)element
{
  Class class   = NSClassFromString([element attributeForKey: @"class"]);
  id    object  = nil;
  
  if ([class isSubclassOfClass: [NSScrollView class]])
    {
      object = [self decodeScrollViewFlagsForElement: element];
    }
  else if ([class isSubclassOfClass: [NSScroller class]])
    {
      object = [self decodeScrollerFlagsForElement: element];
    }
  else
    {
      NSWarnMLog(@"called for a class that is NOT a sub-class of NSScrollView/NSScroller - class: %@", NSStringFromClass(class));
    }
  
  return object;
}

#pragma mark - NSTableView...
- (id) decodeTableViewFlagsForElement: (GSXib5Element*)element
{
  typedef union _GSTableViewFlagsUnion
  {
    GSTableViewFlags flags;
    uint32_t         value;
  } GSTableViewFlagsUnion;
  
  GSTableViewFlagsUnion  mask          = { { 0 } };
  NSDictionary          *attributes    = [element attributes];
  NSDictionary          *gridStyleMask = [[element elementForKey: @"gridStyleMask"] attributes];
  
  // These are the defaults...
  mask.flags.columnOrdering                 = YES; // check if present - see below...
  mask.flags.columnResizing                 = YES; // check if present - see below...
  mask.flags.drawsGrid                      = (gridStyleMask != nil);
  mask.flags.emptySelection                 = YES; // check if present - see below...
  mask.flags.multipleSelection              = YES;
  mask.flags.columnSelection                = [[attributes objectForKey: @"columnSelection"] boolValue];
  mask.flags.columnAutosave                 = YES;
  mask.flags.alternatingRowBackgroundColors = [[attributes objectForKey: @"alternatingRowBackgroundColors"] boolValue];
  
  // Overide the defaults with any attributes present...
  if ([attributes objectForKey: @"columnReordering"])
    mask.flags.columnOrdering = [[attributes objectForKey: @"columnReordering"] boolValue];
  if ([attributes objectForKey: @"columnResizing"])
    mask.flags.columnResizing = [[attributes objectForKey: @"columnResizing"] boolValue];
  if ([attributes objectForKey: @"emptySelection"])
    mask.flags.emptySelection = [[attributes objectForKey: @"emptySelection"] boolValue];
  if ([attributes objectForKey: @"multipleSelection"])
    mask.flags.multipleSelection = [[attributes objectForKey: @"multipleSelection"] boolValue];
  if ([attributes objectForKey: @"autosaveColumns"])
    mask.flags.columnAutosave = [[attributes objectForKey: @"autosaveColumns"] boolValue];

  // Unknown: typeSelect,
  
  return [NSNumber numberWithUnsignedInteger: mask.value];
}

- (id) decodeTableViewGridLinesForElement: (GSXib5Element*)element
{
  NSUInteger    mask       = NSTableViewGridNone;
  NSDictionary *attributes = [element attributes];
  
  if ([[attributes objectForKey: @"dashed"] boolValue])
    mask |= NSTableViewDashedHorizontalGridLineMask;
  else if ([[attributes objectForKey: @"horizontal"] boolValue])
    mask |= NSTableViewSolidHorizontalGridLineMask;
  
  if ([[attributes objectForKey: @"vertical"] boolValue])
    mask |= NSTableViewSolidHorizontalGridLineMask;
  
  return [NSNumber numberWithUnsignedInteger: mask];
}

- (id) decodeIntercellSpacingHeightForElement: (GSXib5Element*)element
{
  element = (GSXib5Element*)[element elementForKey: @"intercellSpacing"];
  return [element attributeForKey: @"height"];
}

- (id) decodeIntercellSpacingWidthForElement: (GSXib5Element*)element
{
  element = (GSXib5Element*)[element elementForKey: @"intercellSpacing"];
  return [element attributeForKey: @"width"];
}

- (id) decodeColumnAutoresizingStyleForElement: (GSXib5Element*)element
{
  NSString    *style = [element attributeForKey: @"columnAutoresizingStyle"];
  NSUInteger   value = NSTableViewUniformColumnAutoresizingStyle;
  
  if ([@"none" isEqualToString: style])
    value = NSTableViewNoColumnAutoresizing;
  else if ([@"firstColumnOnly" isEqualToString: style])
    value = NSTableViewFirstColumnOnlyAutoresizingStyle;
  else if ([@"lastColumnOnly" isEqualToString: style])
    value = NSTableViewLastColumnOnlyAutoresizingStyle;
  else if ([@"sequential" isEqualToString: style])
    value = NSTableViewSequentialColumnAutoresizingStyle;
  else if ([@"reverseSequential" isEqualToString: style])
    value = NSTableViewReverseSequentialColumnAutoresizingStyle;
  
  return [NSString stringWithFormat: @"%"PRIuPTR,value];
}

- (id) decodeTableColumnResizingMaskForElement: (GSXib5Element*)element
{
  NSDictionary *attributes = [element attributes];
  
  if (attributes)
    {
      NSUInteger mask = NSTableColumnNoResizing;
      
      if ([[attributes objectForKey: @"resizeWithTable"] boolValue])
        mask |= NSTableColumnAutoresizingMask;
      if ([[attributes objectForKey: @"userResizable"] boolValue])
        mask |= NSTableColumnUserResizingMask;

      return [NSNumber numberWithUnsignedInteger: mask];
    }
  
  return nil;
}

#pragma mark - NSTabView...
- (id) decodeTabViewFlagsForElement: (GSXib5Element*)element
{
  GSTabViewTypeFlagsUnion  mask         = { { 0 } };
  NSDictionary            *attributes   = [element attributes];
  NSString                *type         = [attributes objectForKey: @"type"];
  NSString                *controlSize  = [attributes objectForKey: @"controlSize"];
  NSString                *controlTint  = [attributes objectForKey: @"controlTint"];
  
  // Set defaults...
  mask.flags.controlTint        = NSDefaultControlTint;
  mask.flags.controlSize        = NSControlSizeRegular;
  mask.flags.tabViewBorderType  = NSTopTabsBezelBorder;

  // Decode type...
  if ([@"leftTabsBezelBorder" isEqualToString: type])
    mask.flags.tabViewBorderType = NSLeftTabsBezelBorder;
  else if ([@"bottomTabsBezelBorder" isEqualToString: type])
    mask.flags.tabViewBorderType = NSBottomTabsBezelBorder;
  else if ([@"rightTabsBezelBorder" isEqualToString: type])
    mask.flags.tabViewBorderType = NSRightTabsBezelBorder;
  else if ([@"noTabsBezelBorder" isEqualToString: type])
    mask.flags.tabViewBorderType = NSNoTabsBezelBorder;
  else if ([@"noTabsLineBorder" isEqualToString: type])
    mask.flags.tabViewBorderType = NSNoTabsLineBorder;
  else if ([@"noTabsNoBorder" isEqualToString: type])
    mask.flags.tabViewBorderType = NSNoTabsNoBorder;
  else if (type)
    NSWarnMLog(@"unknown tabview type: %@", type);
  
  // Decode control size...
  if ([@"small" isEqualToString: controlSize])
    mask.flags.controlSize = NSControlSizeSmall;
  else if ([@"mini" isEqualToString: controlSize])
    mask.flags.controlSize = NSControlSizeMini;
  else if ([@"regular" isEqualToString: controlSize])
    mask.flags.controlSize = NSControlSizeRegular;
  else if (controlSize)
    NSWarnMLog(@"unknown control size: %@", controlSize);
  
  // Decode control tint...
  if ([@"blue" isEqualToString: controlTint])
    mask.flags.controlTint = NSBlueControlTint;
  else if ([@"graphite" isEqualToString: controlTint])
    mask.flags.controlTint = NSGraphiteControlTint;
  else if ([@"clear" isEqualToString: controlTint])
    mask.flags.controlTint = NSClearControlTint;
  else if (controlTint)
    NSWarnMLog(@"unknown control tint: %@", controlTint);

  return [NSNumber numberWithUnsignedInteger: mask.value];
}

#pragma mark - NSTableView/NSTabView...
- (id) decodeTViewFlagsForElement: (GSXib5Element*)element
{
  NSString *classname = [element attributeForKey: @"class"];
  id        object    = nil;
  
  // Invoke decoding based on class type...
  if ([NSClassFromString(classname) isSubclassOfClass: [NSTableView class]])
    object = [self decodeTableViewFlagsForElement: element];
  else
    object = [self decodeTabViewFlagsForElement: element];
  
  return object;
}

#pragma mark - NSBrowser...
- (id) decodeBrowserFlagsForElement: (GSXib5Element*)element
{
  NSUInteger    mask                         = 0;
  NSDictionary *attributes                   = [element attributes];
  id            takesTitleFromPreviousColumn = [attributes objectForKey: @"takesTitleFromPreviousColumn"];
  id            allowsEmptySelection         = [attributes objectForKey: @"allowsEmptySelection"];
  id            acceptsArrowKeys             = [attributes objectForKey: @"acceptsArrowKeys"];
  
  // Set the flags...
  if ([[attributes objectForKey: @"hasHorizontalScroller"] boolValue])
    mask |= 0x10000;
  if ((allowsEmptySelection == nil) || ([allowsEmptySelection boolValue] == NO))
    mask |= 0x20000;
  if ([[attributes objectForKey: @"sendsActionOnArrowKeys"] boolValue])
    mask |= 0x40000;
  if ((acceptsArrowKeys == nil) || [acceptsArrowKeys boolValue])
    mask |= 0x100000;
  if ([[attributes objectForKey: @"separatesColumns"] boolValue])
    mask |= 0x4000000;
  if ((takesTitleFromPreviousColumn == nil) || [takesTitleFromPreviousColumn boolValue])
    mask |= 0x8000000; // Cocoa default is YES if Omitted...
  if ([[attributes objectForKey: @"titled"] boolValue])
    mask |= 0x10000000;
  if ([[attributes objectForKey: @"reusesColumns"] boolValue])
    mask |= 0x20000000;
  if ([[attributes objectForKey: @"allowsBranchSelection"] boolValue])
    mask |= 0x40000000;
  if ([[attributes objectForKey: @"allowsMultipleSelection"] boolValue])
    mask |= 0x80000000;
  if ([[attributes objectForKey: @"prefersAllColumnUserResizing"] boolValue])
    mask |= 0; // FIXME: do we handle this yet???

  return [NSNumber numberWithUnsignedInt: mask];
}

- (id)decodeCellPrototypeForElement: (GSXib5Element*)element
{
  id object = [[NSBrowserCell alloc] initTextCell: @"BrowserItem"];
  
  [object setType: NSPushInCell];
  [object setWraps: NO];
  [object sendActionOn: NSLeftMouseUpMask];
  [object setEnabled: YES];
  
  return AUTORELEASE(object);
}

- (id)decodeMinimumColumnWidthForElement: (GSXib5Element*)element
{
  return [NSNumber numberWithInteger: [[element attributeForKey: @"minColumnWidth"] integerValue]];
}

- (id)decodeColumnResizingTypeForElement: (GSXib5Element*)element
{
  NSUInteger  value              = NSBrowserNoColumnResizing; // Default...
  NSString   *columnResizingType = [element attributeForKey: @"columnResizingType"];
  
  if ([@"user" isEqualToString: columnResizingType])
    value = NSBrowserUserColumnResizing;
  else if ([@"auto" isEqualToString: columnResizingType])
    value = NSBrowserAutoColumnResizing;
  else if (columnResizingType)
    NSWarnMLog(@"unknown column resizing  type: %@", columnResizingType);
  
  return [NSNumber numberWithUnsignedInteger: value];
}

- (id)decodeNumberOfVisibleColumnsForElement: (GSXib5Element*)element
{
  NSInteger value = 0; // Cocoa default...
  
  if ([element attributeForKey: @"maxVisibleColumns"])
    value = [[element attributeForKey: @"maxVisibleColumns"] integerValue];
  
  return [NSNumber numberWithInteger: value];
}

#pragma mark - NSCell...
- (id) decodeClipViewFlagsForElement: (GSXib5Element*)element
{
  Class class   = NSClassFromString([element attributeForKey: @"class"]);
  id    object  = nil;
  
  if ([class isSubclassOfClass: [NSClipView class]] == NO)
    {
      NSWarnMLog(@"called for a class that is NOT a sub-class of NSClipView - class: %@", NSStringFromClass(class));
    }
  else
    {
      NSUInteger    mask = 0;
      NSDictionary *attributes = [element attributes];
      
      // copiesOnScroll - defaults to ON...
      if ([attributes objectForKey: @"copiesOnScroll"] == nil)
        mask |= (1 << 1);
      else
        mask |= ([[attributes objectForKey: @"copiesOnScroll"] boolValue] ? (1 << 1) : 0);
      
      // drawsBackground - defaults to ON...
      if ([attributes objectForKey: @"drawsBackground"] == nil)
        mask |= (1 << 2);
      else
        mask |= ([[attributes objectForKey: @"drawsBackground"] boolValue] ? (1 << 2) : 0);
      
      
      // Return value...
      object = [NSNumber numberWithUnsignedInt: mask];
    }
  
  return object;
}

- (id) decodeCellContentsForElement: (GSXib5Element*)element
{
  Class class   = NSClassFromString([element attributeForKey: @"class"]);
  id    object  = @"";
  
  if ([class isSubclassOfClass: [NSCell class]] == NO)
    {
      NSWarnMLog(@"called for a class that is NOT a sub-class of NSCell - class: %@", NSStringFromClass(class));
    }
  else if ([class isSubclassOfClass: [NSFormCell class]])
    {
      object = [element attributeForKey: @"stringValue"];
    }
  else
    {
      // Try the title attribute first as it's the common encoding...
      if ([element attributeForKey: @"title"])
        {
          object = [element attributeForKey: @"title"];
        }
      else if ([element elementForKey: @"title"])
        {
          // If the attribute does not exist check for a title element encoded
          // the old way via <string>TITLE</string>...
          object = [self decodeObjectForKey: @"title"];
        }
      else if ([element attributeForKey: @"image"])
        {
          object = [NSImage imageNamed: [element attributeForKey: @"image"]];
        }
      
#if 0
      // If a font is encoded then change the title to an attributed
      // string and set the font on it...
      if ([object isKindOfClass: [NSString class]] && [element elementForKey: @"font"])
        {
          NSFont       *font        = [self decodeObjectForKey: @"font"];
          NSDictionary *attributes  = [NSDictionary dictionaryWithObject: font forKey: NSFontAttributeName];
          object                    = [[NSAttributedString alloc] initWithString: object attributes: attributes];
          AUTORELEASE(object);
        }
#endif
    }
  
  return object;
}

- (id) decodeCellAlternateContentsForElement: (GSXib5Element*)element
{
  Class class   = NSClassFromString([element attributeForKey: @"class"]);
  id    object  = @"";
  
  if ([class isSubclassOfClass: [NSCell class]])
    {
      if ([element attributeForKey: @"alternateTitle"])
        {
          object = [element attributeForKey: @"alternateTitle"];
        }
      else if ([element attributeForKey: @"alternateImage"])
        {
          object = [NSImage imageNamed: [element attributeForKey: @"alternateImage"]];
        }
    }
  
  return object;
}

- (unsigned int) decodeLineBreakModeForAttributes: (NSDictionary*)attributes
{
  unsigned int  value = 0;
  NSString     *lineBreakMode = [attributes objectForKey: @"lineBreakMode"];
  
  value = NSLineBreakByWordWrapping;
  if ([@"clipping" isEqualToString: lineBreakMode])
    value = NSLineBreakByClipping;
  else if ([@"charWrapping" isEqualToString: lineBreakMode])
    value = NSLineBreakByCharWrapping;
  else if ([@"wordWrapping" isEqualToString: lineBreakMode])
    value = NSLineBreakByWordWrapping;
  else if ([@"truncatingHead" isEqualToString: lineBreakMode])
    value = NSLineBreakByTruncatingHead;
  else if ([@"truncatingMiddle" isEqualToString: lineBreakMode])
    value = NSLineBreakByTruncatingMiddle;
  else if ([@"truncatingTail" isEqualToString: lineBreakMode])
    value = NSLineBreakByTruncatingTail;
#if 0
  else
    NSWarnMLog(@"unknown line break mode: %@", lineBreakMode);
#endif
  
  return value;
}

- (id) decodeCellFlags1ForElement: (GSXib5Element*)element
{
  NSNumber *value = nil;
  Class     class = NSClassFromString([element attributeForKey: @"class"]);
  
  if ([class isSubclassOfClass: [NSCell class]])
    {
      GSCellFlagsUnion   mask          = { { 0 } };
      NSDictionary      *attributes    = [element attributes];
#if 0
      NSString          *title         = [attributes objectForKey: @"title"];
      NSString          *lineBreakMode = [attributes objectForKey: @"lineBreakMode"];
      NSString          *bezelStyle    = [attributes objectForKey: @"bezelStyle"];
#endif
      NSString          *imageName     = [attributes objectForKey: @"image"];
      NSString          *focusRingType = [attributes objectForKey: @"focusRingType"];
      NSString          *borderStyle   = [attributes objectForKey: @"borderStyle"];
      
      mask.flags.state                    = [[attributes objectForKey:@"state"] isEqualToString: @"on"];
      mask.flags.highlighted              = [[attributes objectForKey: @"highlighted"] boolValue];
      mask.flags.disabled                 = ([attributes objectForKey: @"enabled"] ?
                                             [[attributes objectForKey: @"enabled"] boolValue] == NO : NO);
      mask.flags.editable                 = [[attributes objectForKey: @"editable"] boolValue];
      mask.flags.vCentered                = [[attributes objectForKey: @"alignment"] isEqualToString: @"center"];
      mask.flags.hCentered                = [[attributes objectForKey: @"alignment"] isEqualToString: @"center"];
      mask.flags.bordered                 = [[borderStyle lowercaseString] containsString: @"border"];
      //mask.flags.bezeled                  = ((bezelStyle != nil) && ([@"regularSquare" isEqualToString: bezelStyle] == NO));
      mask.flags.bezeled                  = [[borderStyle lowercaseString] containsString: @"bezel"];
      mask.flags.selectable               = [[attributes objectForKey: @"selectable"] boolValue];
      mask.flags.scrollable               = [[attributes objectForKey: @"scrollable"] boolValue];
      mask.flags.lineBreakMode            = [self decodeLineBreakModeForAttributes: attributes];
      mask.flags.truncateLastLine         = [[attributes objectForKey: @"truncatesLastVisibleLine"] boolValue];
      mask.flags.singleLineMode           = [[attributes objectForKey: @"usesSingleLineMode"] boolValue];
      mask.flags.continuous               = [[attributes objectForKey: @"continuous"] boolValue];
      mask.flags.actOnMouseDown           = (mask.flags.continuous ? YES : NO);
      mask.flags.actOnMouseDragged        = (mask.flags.continuous ? YES : NO);

      // FIXME: these are unknowns for now...
      mask.flags.isLeaf                   = NO;
      mask.flags.invalidObjectValue       = NO;
      mask.flags.invalidFont              = NO;
      mask.flags.weakTargetHelperFlag     = NO;
      mask.flags.allowsAppearanceEffects  = NO;
      mask.flags.isLoaded                 = NO;
      mask.flags.dontActOnMouseUp         = NO;
      mask.flags.isWhite                  = NO;
      mask.flags.useUserKeyEquivalent     = NO;
      mask.flags.showsFirstResponder      = NO;
      
#if 0
      if ((title == nil) && (imageName == nil))
        mask.flags.type = NSNullCellType;
      else if (title == nil)
        mask.flags.type = NSImageCellType;
      else
        mask.flags.type = NSTextCellType;
#else
      if (imageName)
        mask.flags.type = NSImageCellType;
      else
        mask.flags.type = NSTextCellType;
#endif
      
      mask.flags.focusRingType = NSFocusRingTypeDefault;
      if ([@"exterior" isEqualToString: focusRingType])
        mask.flags.focusRingType = NSFocusRingTypeExterior;
      else if ([@"none" isEqualToString: focusRingType])
        mask.flags.focusRingType = NSFocusRingTypeNone;
      
      // Return mask...
      value = [NSNumber numberWithUnsignedInteger: mask.value];
    }
  
  return value;
}

- (id) decodeCellFlags2ForElement: (GSXib5Element*)element
{
  NSNumber *value = nil;
  Class     class = NSClassFromString([element attributeForKey: @"class"]);

  if ([class isSubclassOfClass: [NSCell class]])
    {
      GSCellFlags2Union  mask         = { { 0 } };
      NSDictionary      *attributes   = [element attributes];
#if 0
      NSString          *type         = [attributes objectForKey: @"type"];
#endif
      NSString          *alignment    = [attributes objectForKey: @"alignment"];
      NSString          *controlSize  = [attributes objectForKey: @"controlSize"];
      
      mask.flags.allowsEditingTextAttributes  = [[attributes objectForKey: @"allowsEditingTextAttributes"] boolValue];
      mask.flags.importsGraphics              = 0;
      mask.flags.lineBreakMode                = [self decodeLineBreakModeForAttributes: attributes];
      mask.flags.refusesFirstResponder        = [[attributes objectForKey: @"refusesFirstResponder"] boolValue];
      mask.flags.allowsMixedState             = [[attributes objectForKey: @"allowsMixedState"] boolValue];
      mask.flags.sendsActionOnEndEditing      = [[attributes objectForKey: @"sendsActionOnEndEditing"] boolValue];
      mask.flags.controlSize                  = NSRegularControlSize;
      mask.flags.doesNotAllowUndo             = 0;
      mask.flags.controlTint                  = NSDefaultControlTint;

      // Alignment
      mask.flags.alignment = NSNaturalTextAlignment;
      if ([@"left" isEqualToString: alignment])
        mask.flags.alignment = NSLeftTextAlignment;
      else if ([@"center" isEqualToString: alignment])
        mask.flags.alignment = NSCenterTextAlignment;
      else if ([@"right" isEqualToString: alignment])
        mask.flags.alignment = NSRightTextAlignment;
      else if ([@"justified" isEqualToString: alignment])
        mask.flags.alignment = NSJustifiedTextAlignment;
      else if (alignment)
        NSWarnMLog(@"unknown text alignment: %@", alignment);
      
      // Control size...
      if ([@"small" isEqualToString: controlSize])
        mask.flags.controlSize = NSSmallControlSize;
      else if ([@"mini" isEqualToString: controlSize])
        mask.flags.controlSize = NSMiniControlSize;
      else if ([@"regular" isEqualToString: controlSize])
        mask.flags.controlSize = NSRegularControlSize;
      else if (controlSize)
        NSWarnMLog(@"unknown control size: %@", controlSize);
      
      value = [NSNumber numberWithUnsignedInteger: mask.value];
    }
  
  return value;
}

- (id) decodeCellNormalImageForElement: (GSXib5Element*)element
{
  Class class   = NSClassFromString([element attributeForKey: @"class"]);
  id    object  = nil;
  
  if ([class isSubclassOfClass: [NSCell class]])
    {
      if ([element attributeForKey: @"image"])
        {
          object = [NSImage imageNamed: [element attributeForKey: @"image"]];
        }
      else
        {
          NSString *type = [element attributeForKey: @"type"];
          
          if ([@"radio" isEqualToString: type])
            {
              object = [NSImage imageNamed: @"NSRadioButton"];
            }
          else if ([@"check" isEqualToString: type])
            {
              object = [NSImage imageNamed: @"NSSwitch"];
            }
          else if ([@"disclosure" isEqualToString: type])
            {
              object = [NSImage imageNamed: @"NSDropDownIndicatorTemplate"];
            }
        }
    }
  
  return object;
}

- (id) decodeCellAlternateImageForElement: (GSXib5Element*)element
{
  Class class   = NSClassFromString([element attributeForKey: @"class"]);
  id    object  = nil;
  
  if ([class isSubclassOfClass: [NSCell class]])
    {
      if ([element attributeForKey: @"alternateImage"])
        {
          object = [NSImage imageNamed: [element attributeForKey: @"alternateImage"]];
        }
      else
        {
          NSString *type = [element attributeForKey: @"type"];
          
          if ([@"radio" isEqualToString: type])
            {
              object = [NSImage imageNamed: @"NSRadioButton"];
            }
          else if ([@"check" isEqualToString: type])
            {
              object = [NSImage imageNamed: @"NSSwitch"];
            }
          else if ([@"disclosure" isEqualToString: type])
            {
              object = [NSImage imageNamed: @"NSDropDownIndicatorTemplate-reversed"];
            }
        }
    }
  
  return object;
}

#pragma mark - NSegmentedControl/NSSegmentedCell...
- (id) decodeSegmentItemImageForElement: (GSXib5Element*)element
{
  id object = nil;
  
  if ([element attributeForKey: @"image"])
    {
      object = [NSImage imageNamed: [element attributeForKey: @"image"]];
    }
  
  return object;
}

#pragma mark - NSButton...
- (id) decodeButtonFlags1ForElement: (GSXib5Element*)element
{
  NSNumber *value = nil;
  Class     class = NSClassFromString([element attributeForKey: @"class"]);

  if ([class isSubclassOfClass: [NSButtonCell class]] == NO)
    {
      NSWarnMLog(@"attempt to access button flags 2 for NON-NSButtonCell based class");
    }
  else
    {
      GSButtonCellFlagsUnion   mask       = { { 0 } };
      NSDictionary            *behavior   = [[element elementForKey: @"behavior"] attributes];
      NSDictionary            *attributes = [element attributes];
      NSString                *imagePos   = [attributes objectForKey: @"imagePosition"];
      
      mask.flags.isPushin               = [[behavior objectForKey: @"pushIn"]  boolValue];
      mask.flags.changeContents         = [[behavior objectForKey: @"changeContents"]  boolValue];
      mask.flags.changeBackground       = [[behavior objectForKey: @"changeBackground"]  boolValue];
      mask.flags.changeGray             = [[behavior objectForKey: @"changeGray"]  boolValue];
      
      mask.flags.highlightByContents    = [[behavior objectForKey: @"lightByContents"]  boolValue];
      mask.flags.highlightByBackground  = [[behavior objectForKey: @"lightByBackground"]  boolValue];
      mask.flags.highlightByGray        = [[behavior objectForKey: @"lightByGray"]  boolValue];
      mask.flags.drawing                = [[behavior objectForKey: @"drawing"]  boolValue];
      
      mask.flags.isBordered             = [attributes objectForKey: @"borderStyle"] != nil;
      mask.flags.imageDoesOverlap       = [@"only" isEqualToString: imagePos];
      mask.flags.imageDoesOverlap      |= [@"overlaps" isEqualToString: imagePos];
      mask.flags.isHorizontal           = [@"left" isEqualToString: imagePos];
      mask.flags.isHorizontal          |= [@"right" isEqualToString: imagePos];
      mask.flags.isBottomOrLeft         = [@"left" isEqualToString: imagePos];
      mask.flags.isBottomOrLeft        |= [@"bottom" isEqualToString: imagePos];
      
      mask.flags.isImageAndText         = [@"only" isEqualToString: [attributes objectForKey: @"imagePosition"]] == NO;
      mask.flags.isImageSizeDiff        = 1; // FIXME...
      //mask.flags.hasKeyEquiv            = [[behavior objectForKey: @"hasKeyEquiv"]  boolValue];
      //mask.flags.lastState              = [[behavior objectForKey: @"lastState"]  boolValue];

      mask.flags.isTransparent          = [[behavior objectForKey: @"transparent"]  boolValue];
      mask.flags.inset                  = [[attributes objectForKey: @"inset"] intValue];
      mask.flags.doesNotDimImage        = [[behavior objectForKey: @"doesNotDimImage"] boolValue];
      mask.flags.useButtonImageSource   = 0; //[attributes objectForKey: @"imagePosition"] != nil;
      //mask.flags.unused2                = [[behavior objectForKey: @"XXXXX"]  boolValue]; // alt mnem loc???
      
      // Return the value...
      value = [NSNumber numberWithUnsignedInteger: mask.value];
    }
  
  return value;
}

- (id) decodeButtonFlags2ForElement: (GSXib5Element*)element
{
  NSNumber *value = nil;
  Class     class = NSClassFromString([element attributeForKey: @"class"]);
  
  if ([class isSubclassOfClass: [NSButtonCell class]] == NO)
    {
      NSWarnMLog(@"attempt to access button flags 2 for NON-NSButtonCell based class");
    }
  else
    {
      GSButtonCellFlags2Union  mask         = { { 0 } };
      NSDictionary            *attributes   = [element attributes];
      NSString                *bezelStyle   = [attributes objectForKey:@"bezelStyle"];
      NSString                *imageScaling = [attributes objectForKey:@"imageScaling"];
      
      if (bezelStyle)
        {
          uint32_t flag = NSRegularSquareBezelStyle; // Default if not specified...
          
          if ([@"rounded" isEqualToString: bezelStyle])
            flag = NSRoundedBezelStyle;
          else if ([@"regularSquare" isEqualToString: bezelStyle])
            flag = NSRegularSquareBezelStyle;
          else if ([@"disclosure" isEqualToString: bezelStyle])
            flag = NSDisclosureBezelStyle;
          else if ([@"shadowlessSquare" isEqualToString: bezelStyle])
            flag = NSShadowlessSquareBezelStyle;
          else if ([@"circular" isEqualToString: bezelStyle])
            flag = NSCircularBezelStyle;
          else if ([@"texturedSquare" isEqualToString: bezelStyle])
            flag = NSTexturedSquareBezelStyle;
          else if ([@"helpButton" isEqualToString: bezelStyle])
            flag = NSHelpButtonBezelStyle;
          else if ([@"smallSquare" isEqualToString: bezelStyle])
            flag = NSSmallSquareBezelStyle;
          else if ([@"texturedRounded" isEqualToString: bezelStyle])
            flag = NSTexturedRoundedBezelStyle;
          else if ([@"roundedRectangle" isEqualToString: bezelStyle])
            flag = NSRoundRectBezelStyle;
          else if ([@"roundedRect" isEqualToString: bezelStyle])
            flag = NSRoundRectBezelStyle;
          else if ([@"recessed" isEqualToString: bezelStyle])
            flag = NSRecessedBezelStyle;
          else if ([@"roundedDisclosure" isEqualToString: bezelStyle])
            flag = NSRoundedDisclosureBezelStyle;
  #if 0
          else if ([@"inline" isEqualToString: bezelStyle])
            flag = NSInlineBezelStyle; // New value added in Cocoa version???
  #endif
          else
            NSWarnMLog(@"unknown bezelStyle: %@", bezelStyle);
          
          mask.flags.bezelStyle  = (flag & 7);
          mask.flags.bezelStyle2 = (flag & 8) >> 3;
          if (flag == 0)
            NSWarnMLog(@"_bezel_style: %ld", (long)mask.value);
        }
      
      // Image scaling...
      if ([@"axesIndependently" isEqualToString: imageScaling])
        {
          mask.flags.imageScaling = 3;
        }
      else if ([@"proportionallyDown" isEqualToString: imageScaling])
        {
          mask.flags.imageScaling = 2;
        }
      else if ([@"proportionallyUpOrDown" isEqualToString: imageScaling])
        {
          mask.flags.imageScaling = 1;
        }
      else
        {
          // Warn about unknown image scaling to add later...
          if (imageScaling && [imageScaling length])
            NSWarnMLog(@"unknown image scaling: %@", imageScaling);
          mask.flags.imageScaling = 0;
        }
      
      // keyEquivalentModifierMask...
      mask.value |= [[self decodeModifierMaskForElement: element] unsignedIntValue];
      
      // Return value...
      value = [NSNumber numberWithUnsignedInteger: mask.value];
    }
  
  return value;
}

- (id) decodeButtonStateForElement: (GSXib5Element*)element
{
  id          object = nil;
  NSUInteger  state  = NSOffState;

  // If the current cell definition has no custom class defined...
  if ([element attributeForKey: @"state"])
    {
      // Check encompassing class for cellClass diversion...
      NSString *refstate = [element attributeForKey: @"state"];
      
      if ([@"on" isEqualToString: refstate])
        {
          state = NSOnState;
        }
      else if ([@"mized" isEqualToString: refstate])
        {
          state = NSMixedState;
        }
      else if (state)
        {
          NSWarnMLog(@"unknown cell state: %@", refstate);
        }
      
      // Generate the object normally...
      object = [NSNumber numberWithUnsignedInteger: state];
    }

  return object;
}

- (id) decodeCellForElement: (GSXib5Element*)topElement
{
  // Unfortunately cell classes can be overridden by their encompassing class so
  // we need to check for these manually...
  GSXib5Element *element = (GSXib5Element*)[topElement elementForKey: @"cell"];
  id             object  = nil;

  if (element != nil)
    {
      // If the current cell definition has no custom class defined...
      if ([element attributeForKey: @"customClass"] == nil)
        {
          // Check encompassing class for cellClass diversion...
          Class class = NSClassFromString([topElement attributeForKey: @"class"]);
          
          // If the encompassing class supports cellClass type...
          if ([class respondsToSelector: @selector(cellClass)])
            [element setAttribute: NSStringFromClass([class cellClass]) forKey: @"class"];
        }
      
      // Generate the object normally...
      object = [self objectForXib: element];
    }
  
  return object;
}

#pragma mark - NSPopUpButton/NSPopUpButtonCell...
- (id)decodeSelectedIndexForElement: (GSXib5Element*)element
{
  // We need to get the index into the menuitems for menu...
  NSMenu      *menu     = [self decodeObjectForKey: @"menu"];
  NSMenuItem  *item     = [self decodeMenuItemForElement: element];
  NSArray     *items    = [menu itemArray];
  NSUInteger   index    = [items indexOfObjectIdenticalTo: item];
  
  return [NSNumber numberWithUnsignedInteger: index];
}

- (id)decodePreferredEdgeForElement: (GSXib5Element*)element
{
  NSUInteger  value         = NSMinXEdge;
  NSString   *preferredEdge = [element attributeForKey: @"preferredEdge"];
  
  if (preferredEdge)
    {
      if ([@"minX" isEqualToString: preferredEdge])
        value = NSMinXEdge;
      else if ([@"maxX" isEqualToString: preferredEdge])
        value = NSMaxXEdge;
      else if ([@"minY" isEqualToString: preferredEdge])
        value = NSMinYEdge;
      else if ([@"maxY" isEqualToString: preferredEdge])
        value = NSMaxYEdge;
      else
        NSWarnMLog(@"unknown preferred edge value: %@", preferredEdge);
    }
  
  return [NSNumber numberWithUnsignedInteger: value];
}

- (id)decodeArrowPositionForElement: (GSXib5Element*)element
{
  NSUInteger  value         = NSPopUpArrowAtBottom; // If omitted Cocoa default...
  NSString   *arrowPosition = [element attributeForKey: @"arrowPosition"];
  
  if (arrowPosition)
  {
    if ([@"noArrow" isEqualToString: arrowPosition])
      value = NSPopUpNoArrow;
    else if ([@"arrowAtCenter" isEqualToString: arrowPosition])
      value = NSPopUpArrowAtCenter;
    else
      NSWarnMLog(@"unknown arrow position value: %@", arrowPosition);
  }
  
  return [NSNumber numberWithUnsignedInteger: value];
}

- (id)decodeUsesItemFromMenuForElement: (GSXib5Element*)element
{
  BOOL      value            = YES; // If omitted Cocoa default...
  NSString *usesItemFromMenu = [element attributeForKey: @"usesItemFromMenu"];
  
  if (usesItemFromMenu)
    value = [usesItemFromMenu boolValue];
  
  return [NSNumber numberWithBool: value];
}

#pragma mark - Overridden decoding methods from base class...
- (id) objectForXib: (GSXibElement*)element
{
  id object = [super objectForXib: element];
  
  // If no object check other possibilities related to XIB 5...
  if (object == nil)
    {
      NSString *elementName = [element type];

      if (([@"action" isEqualToString: elementName]) ||
          ([@"binding" isEqualToString: elementName]) ||
          ([@"outlet" isEqualToString: elementName]))
        {
          NSString      *classname        = nil;
          NSString      *targID           = [element attributeForKey: @"target"];
          NSString      *destID           = [element attributeForKey: @"destination"];
          GSXib5Element *targElem         = [objects objectForKey: targID];
          GSXib5Element *destElem         = [objects objectForKey: destID];
          id             targObj          = [self objectForXib: targElem];
          id             destObj          = [self objectForXib: destElem];
          
          [(GSXib5Element*)element setAttribute: targObj forKey: @"target"];
          [(GSXib5Element*)element setAttribute: destObj forKey: @"destination"];
          
          // For XIB 5 bindings - this is to fool the existing initWithCoder in NSNibBindingConnector...
          [(GSXib5Element*)element setAttribute: @"2" forKey: @"nibBindingConnectorVersion"];
          // Also for XB 5 bindings - but we're on;y setting this if it doesn't exist...
          if (nil == [element attributeForKey: @"source"])
            [(GSXib5Element*)element setAttribute: targObj forKey: @"source"];

          if ([@"outlet" isEqualToString: elementName])
            classname = @"IBOutletConnection5";
          else if ([@"binding" isEqualToString: elementName])
            classname = @"IBBindingConnection5";
          else
            classname = @"IBActionConnection5";
          
          // Decode the object...
          object = [self decodeObjectForXib: element forClassName: classname withID: [element attributeForKey: @"id"]];
        }
      else if ([@"range" isEqualToString: elementName])
        {
          NSRange range = [self decodeRangeForKey: [element attributeForKey: @"key"]];
          object        = [NSValue valueWithRange: range];
          
          if ([element attributeForKey: @"id"])
            [decoded setObject: object forKey: [element attributeForKey: @"id"]];
        }
      else if ([XmlTagToDecoderSelectorMap objectForKey: elementName])
        {
          SEL selector = NSSelectorFromString([XmlTagToDecoderSelectorMap objectForKey: elementName]);
          object       = [self performSelector: selector withObject: element];
          
          if ([element attributeForKey: @"id"])
            [decoded setObject: object forKey: [element attributeForKey: @"id"]];
        }
    }
  else // Check for required fixes for XIB 5 processing changes to old element types...
    {
      NSString *elementName = [element type];

      if ([@"string" isEqualToString: elementName])
        {
          // <string> now has base64-UTF8 as a bool attribute...
          if ([[element attributeForKey: @"base64-UTF8"] boolValue])
            {
              NSData *data = [[NSData alloc] initWithBase64EncodedString: object
                                                                 options: NSDataBase64DecodingIgnoreUnknownCharacters];
              object       = AUTORELEASE([[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding]);
              RELEASE(data);
              
              // Replace previous object...
              if ([element attributeForKey: @"id"])
                [decoded setObject: object forKey: [element attributeForKey: @"id"]];
            }
        }
    }
  
  return object;
}

- (id) decodeObjectForXib: (GSXibElement*)element
             forClassName: (NSString*)classname
                   withID: (NSString*)objID
{
  // Try decoding the object using super first...
  id object = [super decodeObjectForXib: element forClassName: classname withID: objID];

  // Create an ordered object for this element...
  // This probably needs to be qualified but I have yet to determine
  // what that should be right now...
  // OK - I think we need at least this qualifier here to avoid excess and
  // objects and memory leaks...
  if ([element attributeForKey: @"id"] && [_orderedObjectsDict objectForKey: [element attributeForKey: @"id"]] == nil)
    {
      id orderedObject = [self orderedObjectForElement: (GSXib5Element*)element];
      [_orderedObjectsDict setObject: orderedObject forKey: [element attributeForKey: @"id"]];
      [_orderedObjects addElement: orderedObject];
    }
  
  // Process tooltips...
  if ([element attributeForKey: @"toolTip"])
    {
      if ([object respondsToSelector: @selector(setToolTip:)])
        [object setToolTip: [element attributeForKey: @"toolTip"]];
      else if ([object respondsToSelector: @selector(setHeaderToolTip:)])
        [object setHeaderToolTip: [element attributeForKey: @"toolTip"]];
    }

  // Process IB runtime attributes for element...
  if ([element elementForKey: @"userDefinedRuntimeAttributes"] && // Ensure we don't process the placeholders...
      ([[element attributeForKey: @"class"] isEqualToString: @"IBUserDefinedRuntimeAttributesPlaceholder"] == NO))
    {
      // Create the flattened property data for the runtime attributes in the OLD XIB format...
      id runtimeAttributes = [element elementForKey: @"userDefinedRuntimeAttributes"];
      id orderedObject     = [_orderedObjectsDict objectForKey: [element attributeForKey: @"id"]];
      [self addRuntimeAttributesForElement: runtimeAttributes forID: [orderedObject attributeForKey: @"id"]];
    }
  
  return object;
}

- (id)decodeObjectForKey:(NSString *)key
{
  id object = [super decodeObjectForKey:key];
  
  // If not object try some other cases before defaulting to remove 'NS' prefix if present...
  if (object == nil)
    {
      // Try to reinterpret the request...
      if ([XmlKeyMapTable objectForKey: key])
        {
          object = [self decodeObjectForKey: [XmlKeyMapTable objectForKey: key]];
        }
      else if ([XmlKeyToDecoderSelectorMap objectForKey: key])
        {
          SEL selector = NSSelectorFromString([XmlKeyToDecoderSelectorMap objectForKey: key]);
          object       = [self performSelector: selector withObject: currentElement];
        }
      else if (([@"NSSearchButtonCell" isEqualToString: key]) ||
               ([@"NSCancelButtonCell" isEqualToString: key]))
        {
          // Search field encoding is real basic now...does not include these by default...
          // So we're going to generate them here for now...again should be moved into
          // class initWithCoder method eventually...
          object = AUTORELEASE([NSButtonCell new]);

          unsigned int      bFlags = 0x8444000;
          GSButtonCellFlags buttonCellFlags;
          
          memcpy((void *)&buttonCellFlags,(void *)&bFlags,sizeof(struct _GSButtonCellFlags));
          
          if ([@"NSSearchButtonCell" isEqualToString: key])
            [object setTitle: @"search"];
          else
            [object setTitle: @"clear"];
          
          [object setTransparent: buttonCellFlags.isTransparent];
          [object setBordered: buttonCellFlags.isBordered];
          
          [object setCellAttribute: NSPushInCell to: buttonCellFlags.isPushin];
          [object setCellAttribute: NSCellLightsByBackground to: buttonCellFlags.highlightByBackground];
          [object setCellAttribute: NSCellLightsByContents to: buttonCellFlags.highlightByContents];
          [object setCellAttribute: NSCellLightsByGray to: buttonCellFlags.highlightByGray];
          [object setCellAttribute: NSChangeBackgroundCell to: buttonCellFlags.changeBackground];
          [object setCellAttribute: NSCellChangesContents to: buttonCellFlags.changeContents];
          [object setCellAttribute: NSChangeGrayCell to: buttonCellFlags.changeGray];
          
          if (buttonCellFlags.imageDoesOverlap)
            {
              if (buttonCellFlags.isImageAndText)
                [object setImagePosition: NSImageOverlaps];
              else
                [object setImagePosition: NSImageOnly];
            }
          else if (buttonCellFlags.isImageAndText)
            {
              if (buttonCellFlags.isHorizontal)
                {
                  if (buttonCellFlags.isBottomOrLeft)
                    [object setImagePosition: NSImageLeft];
                  else
                    [object setImagePosition: NSImageRight];
                }
              else
                {
                  if (buttonCellFlags.isBottomOrLeft)
                    [object setImagePosition: NSImageBelow];
                  else
                    [object setImagePosition: NSImageAbove];
                }
            }
          else
            {
              [object setImagePosition: NSNoImage];
            }
#if 0
          [object setBordered: NO];
          [object setCellAttribute: NSPushInCell to: NO];
          [object setCellAttribute: NSChangeBackgroundCell to: NO];
          [object setCellAttribute: NSCellChangesContents to: NO];
          [object setCellAttribute: NSChangeGrayCell to: NO];
          [object setCellAttribute: NSCellLightsByContents to: YES];
          [object setCellAttribute: NSCellLightsByBackground to: NO];
          [object setCellAttribute: NSCellLightsByGray to: NO];
          [object setImagePosition: NSImageOnly];
          [object setImageScaling: NSImageScaleNone];
          [object setBezelStyle: NSRoundedBezelStyle];
#endif
        }
      else if ([@"NSSupport" isEqualToString: key])
        {
          // This is the key Cocoa uses for fonts...
          // OR images - depending on what's encoded
          if ([self containsValueForKey: @"font"])
            object = [self decodeObjectForKey: @"font"];
          else if ([self containsValueForKey: @"image"])
            object = [self decodeObjectForKey: @"image"];
        }
      else if (([@"NSName" isEqualToString: key]) && ([@"font" isEqualToString: [currentElement attributeForKey: @"key"]]))
        {
          // We have to be careful with NSName as it is used by Cocoa in at least three places...
          object = [currentElement attributeForKey: @"name"];
        }
      else if ([@"NSFirstColumnTitle" isEqualToString: key])
        {
          object = @"Browser";
        }
      else if ([@"NSPathSeparator" isEqualToString: key])
        {
          // This would allow to do system dependent path separator decoding...
          object = @"/";
        }
      else if ([key hasPrefix:@"NS"])
        {
          // Try a key minus a (potential) NS prefix...
          NSString *newKey = [key stringByDeletingPrefix: @"NS"];
          newKey           = [[[newKey substringToIndex:1] lowercaseString] stringByAppendingString:[newKey substringFromIndex:1]];
          object           = [self decodeObjectForKey:newKey];
        }
      else if ([XmlReferenceAttributes containsObject: key])
        {
          // Elements not stored INSIDE current element potentially need to be cross
          // referenced via attribute references...
          NSString      *idString = [currentElement attributeForKey: key];
          GSXib5Element *element  = [objects objectForKey:idString];
          object                  = [self objectForXib: element];
        }
      else if ([currentElement attributeForKey: key])
        {
          // New xib stores values as attributes...
          object = [currentElement attributeForKey: key];
        }
#if 0 //defined(DEBUG)
      else // DEBUG ONLY...
        {
          NSWarnMLog(@"no element/attribute for key: %@", key);
        }
#endif
    }
  
  return object;
}

- (BOOL)decodeBoolForKey:(NSString *)key
{
  BOOL flag = NO;
  
  if ([super containsValueForKey:key])
    {
      flag = [super decodeBoolForKey:key];
    }
  else if ([@"NSIsBordered" isEqualToString: key])
    {
      flag = ([currentElement attributeForKey: @"bordered"] ?
              [[currentElement attributeForKey: @"bordered"] boolValue] : YES);
    }
  else if ([XmlKeyMapTable objectForKey: key])
    {
      flag = [self decodeBoolForKey: [XmlKeyMapTable objectForKey: key]];
    }
  else if ([XmlKeyToDecoderSelectorMap objectForKey: key])
    {
      SEL selector = NSSelectorFromString([XmlKeyToDecoderSelectorMap objectForKey: key]);
      flag         = [[self performSelector: selector withObject: currentElement] boolValue];
    }
  else if ([currentElement attributeForKey: key])
    {
      flag = [[currentElement attributeForKey: key] boolValue];
    }
  else if ([key hasPrefix:@"NS"])
    {
      NSString *newKey = [key stringByDeletingPrefix:@"NS"];
      newKey = [[[newKey substringToIndex:1] lowercaseString] stringByAppendingString:[newKey substringFromIndex:1]];
      flag = [self decodeBoolForKey:newKey];
    }
#if 0
  else
    {
      NSWarnMLog(@"no BOOL for key: %@", key);
    }
#endif
  
  return flag;
}

- (double)decodeDoubleForKey:(NSString *)key
{
  double value = 0;
  
  if ([self containsValueForKey:key])
    {
      value = [super decodeDoubleForKey:key];
    }
  else if ([XmlKeyMapTable objectForKey: key])
    {
      value = [self decodeDoubleForKey: [XmlKeyMapTable objectForKey: key]];
    }
  else if ([XmlKeyToDecoderSelectorMap objectForKey: key])
    {
      SEL selector = NSSelectorFromString([XmlKeyToDecoderSelectorMap objectForKey: key]);
      value        = [[self performSelector: selector withObject: currentElement] doubleValue];
    }
  else if ([currentElement attributeForKey: key])
    {
      value = [[currentElement attributeForKey: key] doubleValue];
    }
  else if ([key hasPrefix:@"NS"])
    {
      NSString *newKey = [key stringByDeletingPrefix:@"NS"];
      newKey = [[[newKey substringToIndex:1] lowercaseString] stringByAppendingString:[newKey substringFromIndex:1]];
      value = [self decodeDoubleForKey:newKey];
    }
  else
    {
      NSWarnMLog(@"no DOUBLE for key: %@", key);
    }
  
  return value;
}

- (float)decodeFloatForKey:(NSString *)key
{
  return (float)[self decodeDoubleForKey: key];
}

- (int)decodeIntForKey:(NSString *)key
{
  int value = 0;
  
  if ([XmlKeyToDecoderSelectorMap objectForKey: key])
    {
      SEL selector = NSSelectorFromString([XmlKeyToDecoderSelectorMap objectForKey: key]);
      value        = [[self performSelector: selector withObject: currentElement] intValue];
    }
  else if ([self containsValueForKey:key])
    {
      value = [super decodeIntForKey:key];
    }
  else if ([XmlKeyMapTable objectForKey: key])
    {
      value = [self decodeIntForKey: [XmlKeyMapTable objectForKey: key]];
    }
  else if ([currentElement attributeForKey: key])
    {
      value = [[currentElement attributeForKey: key] integerValue];
    }
  else if ([key hasPrefix:@"NS"])
    {
      NSString *newKey = [key stringByDeletingPrefix:@"NS"];
      newKey = [[[newKey substringToIndex:1] lowercaseString] stringByAppendingString:[newKey substringFromIndex:1]];
      value = [self decodeIntegerForKey:newKey];
    }
  else
    {
      NSWarnMLog(@"no INT for key: %@", key);
    }
  
  return value;
}

- (NSInteger)decodeIntegerForKey:(NSString *)key
{
  NSInteger value = 0;
  
  if ([super containsValueForKey:key])
    {
      value = [super decodeIntegerForKey:key];
    }
  else if ([XmlKeyToDecoderSelectorMap objectForKey: key])
    {
      SEL selector = NSSelectorFromString([XmlKeyToDecoderSelectorMap objectForKey: key]);
      value        = [[self performSelector: selector withObject: currentElement] integerValue];
    }
  else if ([currentElement attributeForKey: key])
    {
      value = [[currentElement attributeForKey: key] integerValue];
    }
  else if ([key hasPrefix:@"NS"])
    {
      NSString *newKey = [key stringByDeletingPrefix:@"NS"];
      newKey = [[[newKey substringToIndex:1] lowercaseString] stringByAppendingString:[newKey substringFromIndex:1]];
      value = [self decodeIntegerForKey:newKey];
    }
  else
    {
      NSWarnMLog(@"no INTEGER for key: %@", key);
    }
  
  return value;
}

- (NSPoint) decodePointForKey:(NSString *)key
{
  NSPoint point = NSZeroPoint;
  
  // If the request element exists...
  if ([currentElement elementForKey: key])
    {
      GSXib5Element *element = (GSXib5Element*)[currentElement elementForKey: key];
      NSDictionary  *object  = [element attributes];
      
      point.x = [[object objectForKey:@"x"] doubleValue];
      point.y = [[object objectForKey:@"y"] doubleValue];
    }
  else if ([XmlKeyMapTable objectForKey: key])
    {
      point = [self decodePointForKey: [XmlKeyMapTable objectForKey: key]];
    }
  else if ([key hasPrefix:@"NS"])
    {
      NSString *newKey = [key stringByDeletingPrefix: @"NS"];
      newKey = [[[newKey substringToIndex:1] lowercaseString] stringByAppendingString: [newKey substringFromIndex:1]];
      point = [self decodePointForKey: newKey];
    }
  else
    {
      NSWarnMLog(@"no POINT for key: %@", key);
    }
  
  return point;

}

- (NSSize) decodeSizeForKey: (NSString*)key
{
  NSSize size = NSZeroSize;
  
  // If the request element exists...
  if ([currentElement elementForKey: key])
    {
      GSXib5Element *element = (GSXib5Element*)[currentElement elementForKey: key];
      NSDictionary  *object  = [element attributes];
      
      size.width  = [[object objectForKey:@"width"] doubleValue];
      size.height = [[object objectForKey:@"height"] doubleValue];
    }
  else if ([XmlKeyMapTable objectForKey: key])
    {
      size = [self decodeSizeForKey: [XmlKeyMapTable objectForKey: key]];
    }
  else if ([key hasPrefix:@"NS"])
    {
      NSString *newKey = [key stringByDeletingPrefix: @"NS"];
      NSString *prefix = [[newKey substringToIndex:1] lowercaseString];
      newKey           = [prefix stringByAppendingString: [newKey substringFromIndex:1]];
      size             = [self decodeSizeForKey: newKey];
    }
  else
    {
      NSWarnMLog(@"no SIZE for key: %@", key);
    }
  
  return size;
}

- (NSRect) decodeRectForKey: (NSString*)key
{
  NSRect frame = NSZeroRect;
  
  // If the request element exists...
  if ([currentElement elementForKey: key])
    {
      frame.origin  = [self decodePointForKey: key];
      frame.size    = [self decodeSizeForKey: key];
    }
  else if ([XmlKeyMapTable objectForKey: key])
    {
      frame = [self decodeRectForKey: [XmlKeyMapTable objectForKey: key]];
    }
  else if ([key hasPrefix:@"NS"])
    {
      NSString *newKey = [key stringByDeletingPrefix: @"NS"];
      newKey = [[[newKey substringToIndex:1] lowercaseString] stringByAppendingString: [newKey substringFromIndex:1]];
      frame = [self decodeRectForKey: newKey];
    }
  else
    {
      NSWarnMLog(@"no RECT for key: %@", key);
    }
  
  return frame;
}

- (NSRange) decodeRangeForKey: (NSString*)key
{
  NSRange        range   = NSMakeRange(0, 0);
  GSXib5Element *element = (GSXib5Element*)[currentElement elementForKey: key];

  // If the request element exists...
  if (element)
    {
      range.location  = [[element attributeForKey: @"location"] integerValue];
      range.length    = [[element attributeForKey: @"length"] integerValue];
    }
  else
    {
      NSWarnMLog(@"no RANGE for key: %@", key);
    }
  
  return range;
}

- (BOOL)containsValueForKey:(NSString *)key
{
  BOOL hasValue = [super containsValueForKey:key];
  
  // Check attributes (for XIB 5 and above) for additional values...
  if (hasValue == NO)
    {
      hasValue = [currentElement attributeForKey: key] != nil;
    }
  
  // If that didn't work...
  if (hasValue == NO)
    {
      // Try reinterpreting the request...
      if ([XmlKeyMapTable objectForKey: key])
        {
          hasValue = [self containsValueForKey: [XmlKeyMapTable objectForKey: key]];
        }
      else if (([@"NSIntercellSpacingHeight" isEqualToString: key]) ||
               ([@"NSIntercellSpacingWidth" isEqualToString: key]))
        {
          hasValue = [currentElement elementForKey: @"intercellSpacing"] != nil;
        }
      else if ([@"NSContents" isEqualToString: key])
        {
          hasValue  = [currentElement attributeForKey: @"title"] != nil;
          hasValue |= [currentElement attributeForKey: @"image"] != nil;
        }
      else if ([@"NSAlternateContents" isEqualToString: key])
        {
          hasValue = [currentElement attributeForKey: @"alternateTitle"] != nil;
        }
      else if ([@"NSHeaderClipView" isEqualToString: key])
        {
          hasValue = [currentElement elementForKey: @"headerView"] != nil;
        }
      else if ([XmlKeysDefined containsObject: key])
        {
          // These are arbitrarily defined through hard-coding...
          hasValue = YES;
        }
      else if ([key hasPrefix:@"NS"])
        {
          // Try a key minus a (potential) NS prefix...
          NSString *newKey = [key stringByDeletingPrefix:@"NS"];
          newKey = [[[newKey substringToIndex:1] lowercaseString] stringByAppendingString:[newKey substringFromIndex:1]];
          hasValue = [self containsValueForKey:newKey];
        }
      else
        {
          // Check special cases...
          if (([@"action" isEqualToString: key]) || ([@"target" isEqualToString: key]))
            {
              // Target is stored in the action XIB element - if present - which is
              // stored under the connections array element...
              NSArray     *connections = [self objectForXib: [currentElement elementForKey: @"connections"]];
              NSPredicate *predicate   = [NSPredicate predicateWithFormat:@"className == 'IBActionConnection'"];
              NSArray     *actions     = [connections filteredArrayUsingPredicate: predicate];
              hasValue = ([actions count] != 0);
            }
        }
    }
  
  return hasValue;
}

@end

#if 0
#pragma mark - NSObject (NSKeyedUnarchiverDelegate) Protocol...
@implementation NSObject (NSKeyedUnarchiverDelegate)
/** <override-dummy />
 */
- (Class) unarchiver: (NSKeyedUnarchiver*)anUnarchiver
cannotDecodeObjectOfClassName: (NSString*)aName
     originalClasses: (NSArray*)classNames
{
  return nil;
}
/** <override-dummy />
 */
- (id) unarchiver: (NSKeyedUnarchiver*)anUnarchiver
  didDecodeObject: (id)anObject
{
  return anObject;
}
/** <override-dummy />
 */
- (void) unarchiverDidFinish: (NSKeyedUnarchiver*)anUnarchiver
{
}
/** <override-dummy />
 */
- (void) unarchiverWillFinish: (NSKeyedUnarchiver*)anUnarchiver
{
}
/** <override-dummy />
 */
- (void) unarchiver: (NSKeyedUnarchiver*)anUnarchiver
  willReplaceObject: (id)anObject
         withObject: (id)newObject
{
}
@end

@implementation NSObject (NSKeyedUnarchiverObjectSubstitution)
+ (Class) classForKeyedUnarchiver
{
  return self;
}
@end
#endif
