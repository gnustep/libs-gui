#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

int main (int argc, char** argv, char** env)
{
  id pool = [NSAutoreleasePool new];
  NSArray* arguments;
  NSProcessInfo* processInfo;
  NSString *model;

#ifdef LIB_FOUNDATION_LIBRARY
  [NSProcessInfo initializeWithArguments:argv count:argc environment:env];
#endif

#if 1
  processInfo = [NSProcessInfo processInfo];
  arguments = [processInfo arguments];
  if ([arguments count] < 2)
    model = @"test.gmodel";
  else
    model = [arguments objectAtIndex: 1];
#endif

#if 1
  if (![NSBundle loadNibNamed: model
		 owner:[NSApplication sharedApplication]]) {
    printf ("Cannot load Interface Modeller file!\n");
    exit (1);
  }
#endif

  [[NSGraphicsContext currentContext] wait];
  [[NSApplication sharedApplication] run];
  printf ("exiting...\n");

  [pool release];
  exit (0);
  return 0;
}

