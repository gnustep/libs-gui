#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "AppKit/IMLoading.h"

@interface MyView : NSView
@end

@implementation MyView
- (void)drawRect:(NSRect)rect
{
  [[NSColor greenColor] set];
  NSRectFill (rect);
}
@end

int main (int argc, char** argv, char** env)
{
id pool = [NSAutoreleasePool new];
NSArray* arguments;
NSProcessInfo* processInfo;

#ifdef LIB_FOUNDATION_LIBRARY
  [NSProcessInfo initializeWithArguments:argv count:argc environment:env];
#endif
#ifndef NX_CURRENT_COMPILER_RELEASE
  initialize_gnustep_backend();
#endif

#if 0
  processInfo = [NSProcessInfo processInfo];
  arguments = [processInfo arguments];
  if ([arguments count] != 2) {
    printf ("usage: %s gmodel-file\n", [[processInfo processName] cString]);
    exit (1);
  }
#endif

#if 0
  if (![GMModel loadIMFile:[arguments objectAtIndex:1]
		 owner:[NSApplication sharedApplication]]) {
    printf ("Cannot load Interface Modeller file!\n");
    exit (1);
  }
#endif

  [[NSGraphicContext currentContext] wait];
  [[NSApplication sharedApplication] run];
  printf ("exiting...\n");

  [pool release];
  exit (0);
  return 0;
}

