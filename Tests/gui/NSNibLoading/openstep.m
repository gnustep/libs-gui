#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "GNUstepGUI/GSModelLoaderFactory.h"
#import "GSOpenStepNibReader.h"

/* Also usable as a standalone test against an installed GUI library: link
 * the new reader and GSNibLoader.m compiled with
 * -DGSNibLoader=GSOpenStepTestNibLoader, then this test registers that loader. */
static unsigned failures, checks;
static void Check(BOOL condition, NSString *message)
{
  checks++;
  if (!condition) { failures++; NSLog(@"FAIL: %@", message); }
}

@interface OpenStepTestObject : NSObject
{
@public
  unsigned awakeCount;
}
@end
@implementation OpenStepTestObject
- (void) awakeFromNib { awakeCount++; }
@end

@interface OpenStepTestOwner : NSObject
{
@public
  OpenStepTestObject *object;
  NSWindow *window;
  NSButton *button;
  NSButton *alias;
  unsigned awakeCount;
  unsigned actions;
  BOOL connectedWhenAwoken;
}
@end
@implementation OpenStepTestOwner
- (void) awakeFromNib
{
  awakeCount++;
  connectedWhenAwoken = object != nil && (window == nil || button == alias);
}
- (void) run: (id)sender { actions++; }
@end

static NSData *Fixture(NSString *directory, NSString *name)
{
  NSData *data = [NSData dataWithContentsOfFile:
    [directory stringByAppendingPathComponent: name]];
  Check(data != nil, [@"fixture exists: " stringByAppendingString: name]);
  return data;
}

static void Instantiate(NSData *data, BOOL gui)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];
  OpenStepTestOwner *owner = [OpenStepTestOwner new];
  NSNib *nib = [[NSNib alloc] initWithNibData: data bundle: nil];
  NSArray *top = nil;
  BOOL result = [nib instantiateWithOwner: owner topLevelObjects: &top];
  Check(result, @"NSNib instantiates a typed stream");
  Check([owner->object isKindOfClass: [OpenStepTestObject class]], @"owner outlet connected");
  Check(owner->object != nil && owner->object->awakeCount == 1 && owner->awakeCount == 1,
        @"objects and owner awake exactly once");
  Check(owner->connectedWhenAwoken, @"connections precede awakening");
  Check([top count] == (gui ? 2 : 1), @"top-level ownership uses nib parent map");
  if (gui && result)
    {
      Check(owner->window != nil && owner->button == owner->alias, @"window template and shared outlet identity");
      Check([[owner->window title] isEqual: @"OPENSTEP fixture"], @"window title");
      Check(NSEqualRects([owner->button frame], NSMakeRect(12.5, 18.25, 90, 24)),
            @"fractional frame preserved");
      Check([owner->button superview] == [owner->window contentView], @"view hierarchy restored");
      Check([[owner->button title] isEqual: @"Run"], @"button cell title");
      {
        float delay, interval;
        [[owner->button cell] getPeriodicDelay: &delay interval: &interval];
        Check(fabs(delay - 0.2) < 0.0001 && fabs(interval - 0.025) < 0.0001,
              @"periodic timing preserves historical milliseconds");
      }
      Check([owner->button target] == owner, @"action target is real owner");
      Check([owner->button action] == @selector(run:), @"action selector restored");
      [owner->button sendAction: [owner->button action] to: [owner->button target]];
      Check(owner->actions == 1, @"action reaches owner");
      [owner->window close];
    }
  /* Nib instantiation transfers an extra retain for each top-level object. */
  for (id o in top) [o release];
  [nib release]; [owner release]; [pool drain];
}

int main(int argc, char **argv, char **envp)
{
  GSInitializeProcess(argc, argv, envp);
  NSAutoreleasePool *pool = [NSAutoreleasePool new];
  NSString *dir = argc > 1 ? [NSString stringWithUTF8String: argv[1]] : @"OpenStepFixtures";
  Class standalone = NSClassFromString(@"GSOpenStepTestNibLoader");
  Class loader;
  NSData *sample;
  NSUInteger i;
  BOOL gui = argc > 2 && !strcmp(argv[2], "--gui");
  if (argc == 1 && ![[NSFileManager defaultManager] fileExistsAtPath: dir])
    dir = [@".." stringByAppendingPathComponent: dir];
  if (standalone)
    for (NSString *name in [NSArray arrayWithObjects: @"GSOpenStepTestNibLoader",
        @"GSOpenStepTestXibLoader", @"GSOpenStepTestGormLoader", @"GSOpenStepTestGModelLoader", nil])
      [GSModelLoaderFactory registerModelLoaderClass: NSClassFromString(name)];
  loader = [[GSModelLoaderFactory modelLoaderForFileType: @"nib"] class];
  sample = Fixture(dir, @"objects-v4-le.nib");
  for (i = 0; i < 13; i++)
    {
      NSData *shortData = [sample subdataWithRange: NSMakeRange(0, i)];
      Check(!GSOpenStepNibIsTypedStream(shortData), @"short signature rejected");
      Check(![loader canReadData: shortData], @"short loader probe does not throw");
      Check([GSModelLoaderFactory modelLoaderForData: shortData] == nil,
            @"all factory probes tolerate short input");
    }
  for (NSString *name in [NSArray arrayWithObjects: @"objects-v3-le.nib", @"objects-v3-be.nib",
      @"objects-v4-le.nib", @"objects-v4-be.nib", nil])
    {
      NSData *data = Fixture(dir, name);
      Check([loader canReadData: data], @"binary typedstream recognized");
      Instantiate(data, NO);
    }
  for (NSString *name in [NSArray arrayWithObjects: @"window-v3-le.nib", @"window-v3-be.nib",
      @"window-v4-le.nib", @"window-v4-be.nib", nil])
    Check(GSOpenStepNibKeyedData(Fixture(dir, name)) != nil,
          @"window/control graph translates without a backend");
  /* Conversion validates a complete graph before running any initializers. */
  for (i = 13; i < [sample length]; i++)
    {
      BOOL rejected = NO;
      @try { GSOpenStepNibKeyedData([sample subdataWithRange: NSMakeRange(0, i)]); }
      @catch (NSException *e) { rejected = YES; }
      Check(rejected, @"every truncated archive rejected");
    }
  {
    BOOL rejected = NO;
    @try { GSOpenStepNibKeyedData(Fixture(dir, @"unsupported-version.nib")); }
    @catch (NSException *e)
      { rejected = [[e reason] rangeOfString: @"version 999"].location != NSNotFound; }
    Check(rejected, @"unsupported class version has a useful diagnostic");
  }
  {
    NSData *keyed = GSOpenStepNibKeyedData(sample);
    id plist = [NSPropertyListSerialization propertyListWithData: keyed options: 0 format: NULL error: NULL];
    NSData *xml = [NSPropertyListSerialization dataWithPropertyList: plist
      format: NSPropertyListXMLFormat_v1_0 options: 0 error: NULL];
    Check([loader canReadData: keyed] && [loader canReadData: xml], @"existing binary and XML keyed formats recognized");
    Check(![loader canReadData: [@"<nib streamer=\"4\"/>" dataUsingEncoding: NSUTF8StringEncoding]],
          @"NIBMAKER XML is not accepted");
    Instantiate(keyed, NO);
    /* Some installed base libraries have a broken GSXMLPListParser.  Report
     * that separately from binary OPENSTEP support, which does not use it. */
    @try
      {
        id parsed = [NSPropertyListSerialization propertyListWithData: xml
          options: 0 format: NULL error: NULL];
        if (parsed) Instantiate(xml, NO);
        else NSLog(@"SKIP XML instantiation: installed base cannot parse XML plists");
      }
    @catch (NSException *e) { NSLog(@"SKIP XML instantiation: %@", [e reason]); }
  }
  {
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:
      [[NSProcessInfo processInfo] globallyUniqueString]];
    NSFileManager *fm = [NSFileManager defaultManager];
    GSModelLoader *reader = [GSModelLoaderFactory modelLoaderForFileType: @"nib"];
    [fm createDirectoryAtPath: path withIntermediateDirectories: YES attributes: nil error: NULL];
    [sample writeToFile: [path stringByAppendingPathComponent: @"data.nib"] atomically: YES];
    Check([[reader dataForFile: path] isEqual: sample], @"legacy data.nib payload found");
    [sample writeToFile: [path stringByAppendingPathComponent: @"objects.nib"] atomically: YES];
    Check([[reader dataForFile: path] isEqual: sample], @"objects.nib payload found");
    [[NSData data] writeToFile: [path stringByAppendingPathComponent: @"keyedobjects.nib"] atomically: YES];
    Check([[reader dataForFile: path] length] == 0, @"broken preferred payload does not fall back");
    [fm removeItemAtPath: path error: NULL];
  }
  if (gui)
    {
      [NSApplication sharedApplication];
      for (NSString *name in [NSArray arrayWithObjects: @"window-v3-le.nib", @"window-v3-be.nib",
          @"window-v4-le.nib", @"window-v4-be.nib", nil])
        Instantiate(Fixture(dir, name), YES);
    }
  NSLog(@"OPENSTEP nib: %u checks, %u failures%@", checks, failures,
        gui ? @" (including GUI)" : @" (use --gui for window/control checks)");
  [pool drain];
  return failures ? 1 : 0;
}
