#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>

int main (int argc, char** argv, char** env)
{
  id pool = [NSAutoreleasePool new];
  NSArray* arguments;
  NSProcessInfo* processInfo;
  NSString *model;

#ifdef LIB_FOUNDATION_LIBRARY
  [NSProcessInfo initializeWithArguments:argv count:argc environment:env];
#endif

  processInfo = [NSProcessInfo processInfo];
  arguments = [processInfo arguments];
  [NSApplication sharedApplication];
  if ([arguments count] < 2)
    {
      model = @"test.gmodel";
      if (![NSBundle loadNibNamed: model owner: NSApp]) 
	{
	  printf ("Cannot load Interface Modeller file!\n");
	  exit (1);
	}
    }
  else
    {
      NSDictionary *table;
      table = [NSDictionary dictionaryWithObject: NSApp forKey: @"NSOwner"];
      model = [arguments objectAtIndex: 1];
      if (![NSBundle loadNibFile: model
	       externalNameTable: table
		        withZone: [NSApp zone]])
	{
	  printf ("Cannot load Interface Modeller file!\n");
	  exit (1);
	}

    }

  [[NSApplication sharedApplication] run];
  printf ("exiting...\n");

  [pool release];
  exit (0);
  return 0;
}

