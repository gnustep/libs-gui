#include <Foundation/NSRunLoop.h>
#include <Foundation/NSData.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>
#include <AppKit/NSPasteboard.h>

BOOL
initialize_gnustep_backend(void)
{
  /* Dummy replacement for the xdps function */
  return YES;
}
void NSHighlightRect(NSRect aRect)       						// dummy define
{}
void NSRectFill(NSRect aRect)       							// dummy define
{}
void NSBeep(void)												// dummy define
{}

@interface	GMModel: NSObject
{
}
@end

@implementation	GMModel
@end

@interface	pbOwner : NSObject
{
}
- (void) pasteboard: (NSPasteboard*)pb provideDataForType: (NSString*)type;
@end

@implementation	pbOwner
- (void) pasteboard: (NSPasteboard*)pb provideDataForType: (NSString*)type
{
    if ([type isEqual: NSFileContentsPboardType]) {
        NSString*	s = [pb stringForType: NSStringPboardType];

	if (s) {
	    const char*	ptr;
	    int		len;
	    NSData*		d;

	    ptr = [s cString];
	    len = strlen(ptr);
	    d = [NSData dataWithBytes: ptr length: len];
    	    [pb setData: d forType: type];
	}
    }
}
@end

int
main(int argc, char** argv)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];
  pbOwner	*owner = [pbOwner new];
  NSPasteboard	*pb;
  NSArray	*types;
  NSData	*d;

  [NSObject enableDoubleReleaseCheck: YES];

  types = [NSArray arrayWithObjects:
	NSStringPboardType, NSFileContentsPboardType, nil];
  pb = [NSPasteboard generalPasteboard];
  [pb declareTypes: types owner: owner];
  [pb setString: @"This is a test" forType: NSStringPboardType];
  d = [pb dataForType: NSFileContentsPboardType];
  printf("%.*s\n", [d length], [d bytes]);

  pb = [NSPasteboard pasteboardWithUniqueName];
  types = [NSArray arrayWithObjects:
	NSStringPboardType, nil];
  [pb declareTypes: types owner: owner];
  [pb setString: @"a lowercase test string" forType: NSStringPboardType];
  if (NSPerformService(@"To upper", pb) == NO)
    {
      printf("Failed to perform 'To upper' service\n");
    }
  else
    {
      NSString	*result = [pb stringForType: NSStringPboardType];

      printf("To upper - result - '%s'\n", [result cString]);
    }
  [pool release];
  exit(0);
}


