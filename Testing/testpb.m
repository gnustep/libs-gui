#include <Foundation/NSRunLoop.h>
#include <Foundation/NSData.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSAutoreleasePool.h>
#include <AppKit/NSPasteboard.h>

BOOL
initialize_gnustep_backend(void)
{
  /* Dummy replacement for the xdps function */
  return YES;
}

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
    pbOwner		*owner = [pbOwner new];
    NSPasteboard	*pb;
    NSArray		*types;
    NSData		*d;

    [NSObject enableDoubleReleaseCheck: YES];

    types = [NSArray arrayWithObjects:
	NSStringPboardType, NSFileContentsPboardType, nil];
    pb = [NSPasteboard generalPasteboard];
    [pb declareTypes: types owner: owner];
    [pb setString: @"This is a test" forType: NSStringPboardType];
    d = [pb dataForType: NSFileContentsPboardType];
    printf("%.*s\n", [d length], [d bytes]);
    exit(0);
}


