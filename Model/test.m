#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "IMLoading.h"

int main (int argc, char** argv, char** env)
{
  id pool;
  NSArray* arguments;
  NSProcessInfo* processInfo;

  pool = [NSAutoreleasePool new];
#if LIB_FOUNDATION_LIBRARY
  [NSProcessInfo initializeWithArguments:argv count:argc environment:env];
#endif

  processInfo = [NSProcessInfo processInfo];
  arguments = [processInfo arguments];
  if ([arguments count] != 2) {
    printf ("usage: %s gmodel-file\n", [[processInfo processName] cString]);
    exit (1);
  }

#ifndef NX_CURRENT_COMPILER_RELEASE
  initialize_gnustep_backend();
#endif

  if (![GMModel loadIMFile:[arguments objectAtIndex:1]
		 owner:[NSApplication sharedApplication]]) {
    printf ("Cannot load Interface Modeller file!\n");
    exit (1);
  }

  [[NSApplication sharedApplication] run];
  printf ("exiting...\n");

  [pool release];
  exit (0);
  return 0;
}

