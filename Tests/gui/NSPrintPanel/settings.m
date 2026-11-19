/* Exercise the real print-panel controls without running a modal session or
   submitting a job. Printer capabilities are fixed for reproducible choices. */
#import "Testing.h"
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface NSPrintPanel (SettingsTest)

- (void) _updateFromPrintInfo: (NSPrintInfo *)info;
- (void) _finalWritePrintInfo: (NSPrintInfo *)info;

@end

@interface SettingsPanel : NSPrintPanel

- (id) optionControl: (NSInteger)tag;

@end

@implementation SettingsPanel

+ (id) allocWithZone: (NSZone *)zone
{
  return NSAllocateObject(self, 0, zone);
}

- (id) optionControl: (NSInteger)tag
{
  return [[_optionPanel contentView] viewWithTag: tag];
}

@end

@interface SettingsInfo : NSObject
{
  NSMutableDictionary *attributes;
}

- (NSMutableDictionary *) dictionary;
- (id) printer;
- (NSString *) name;
- (NSString *) note;
- (NSString *) stringForKey: (NSString *)key inTable: (NSString *)table;
- (NSArray *) stringListForKey: (NSString *)key inTable: (NSString *)table;
- (void) setJobDisposition: (NSString *)value;

@end

@implementation SettingsInfo

- (id) init
{
  self = [super init];
  if (self != nil)
    attributes = [[NSMutableDictionary alloc] init];
  return self;
}

- (void) dealloc
{
  RELEASE(attributes);
  DEALLOC;
}

- (NSMutableDictionary *) dictionary
{
  return attributes;
}

- (id) printer
{
  return self;
}

- (NSString *) name
{
  return @"Test printer";
}

- (NSString *) note
{
  return @"Test capabilities";
}

- (NSString *) stringForKey: (NSString *)key inTable: (NSString *)table
{
  if ([key isEqual: @"DefaultResolution"])
    return @"300dpi";
  if ([key isEqual: @"DefaultInputSlot"])
    return @"Upper";
  if ([key isEqual: @"DefaultManualFeed"])
    return @"False";
  return nil;
}

- (NSArray *) stringListForKey: (NSString *)key inTable: (NSString *)table
{
  if ([key isEqual: @"Resolution"])
    return [NSArray arrayWithObjects: @"300dpi", @"600dpi", nil];
  if ([key isEqual: @"InputSlot"])
    return [NSArray arrayWithObjects: @"Upper", @"Lower", nil];
  return nil;
}

- (void) setJobDisposition: (NSString *)value
{
  [attributes setObject: value forKey: NSPrintJobDisposition];
}

@end

int
main(void)
{
  START_SET("Print panel settings")
  SettingsPanel *panel;
  SettingsInfo *settings;
  NSPrintInfo *info;
  NSMutableDictionary *dict;
  NSDictionary *features;
  id copies;
  id feed;
  id resolution;

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqual: NSInternalInconsistencyException])
      SKIP("A GUI backend and display are required");
    [localException raise];
  NS_ENDHANDLER

  panel = [[SettingsPanel alloc] init];
  settings = [[SettingsInfo alloc] init];
  info = (NSPrintInfo *)settings;
  dict = [settings dictionary];
  copies = [[panel contentView] viewWithTag: NSPPCopiesField];
  feed = [panel optionControl: NSPPPaperFeedButton];
  resolution = [panel optionControl: NSPPResolutionButton];
  PASS(copies != nil && feed != nil && resolution != nil,
       "print-panel controls are loaded");

  [dict setObject: [NSNumber numberWithInt: 5] forKey: NSPrintCopies];
  [panel _updateFromPrintInfo: info];
  PASS([copies intValue] == 5, "panel displays the saved copy count");
  [copies setIntValue: 1];
  [panel _finalWritePrintInfo: info];
  PASS([[dict objectForKey: NSPrintCopies] intValue] == 1,
       "changing copies to one replaces the previous count");
  [copies setIntValue: 0];
  [panel _finalWritePrintInfo: info];
  PASS([[dict objectForKey: NSPrintCopies] intValue] == 1
       && [copies intValue] == 1, "zero copies normalize to one");
  [copies setIntValue: -2];
  [panel _finalWritePrintInfo: info];
  PASS([[dict objectForKey: NSPrintCopies] intValue] == 1,
       "negative copies normalize to one");

  [dict removeObjectForKey: NSPrintJobFeatures];
  [feed selectItemAtIndex: 0];
  [panel _finalWritePrintInfo: info];
  features = [dict objectForKey: NSPrintJobFeatures];
  PASS([[features objectForKey: @"ManualFeed"] isEqual: @"ManualFeed/True"],
       "manual feed creates a job-feature dictionary when needed");
  [panel _updateFromPrintInfo: info];
  PASS([feed indexOfSelectedItem] == 0, "manual feed survives panel reload");

  [feed selectItemAtIndex: 2];
  [resolution selectItemAtIndex: 1];
  [panel _finalWritePrintInfo: info];
  features = [dict objectForKey: NSPrintJobFeatures];
  PASS([[features objectForKey: @"InputSlot"] isEqual: @"InputSlot/Lower"],
       "selected paper tray is saved");
  PASS([[features objectForKey: @"ManualFeed"] isEqual: @"ManualFeed/False"]
       && [dict objectForKey: NSPrintManualFeed] == nil,
       "switching to a tray disables manual feed");
  PASS([[features objectForKey: @"Resolution"] isEqual: @"Resolution/600dpi"],
       "selected resolution is saved");
  [panel _updateFromPrintInfo: info];
  PASS([feed indexOfSelectedItem] == 2 && [resolution indexOfSelectedItem] == 1,
       "paper tray and resolution survive panel reload");

  /* Job features may come from an immutable application dictionary. */
  [dict setObject: [NSDictionary dictionaryWithDictionary: features]
           forKey: NSPrintJobFeatures];
  [feed selectItemAtIndex: 0];
  PASS_RUNS([panel _finalWritePrintInfo: info];,
            "immutable job features can be updated by the panel");
  features = [dict objectForKey: NSPrintJobFeatures];
  PASS([features objectForKey: @"InputSlot"] == nil,
       "switching to manual feed removes the stale tray choice");

  RELEASE(panel);
  RELEASE(settings);
  END_SET("Print panel settings")
  return 0;
}
