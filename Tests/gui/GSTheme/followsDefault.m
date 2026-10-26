/* An application must follow the GSTheme default for the whole of its run, not
 * only once it has already changed theme by itself.  GSTheme registers its
 * observer of NSUserDefaultsDidChangeNotification from +setTheme:, in the
 * branch that is taken only when the theme really changes, so an application
 * that starts with the default theme - the common case - was never watching
 * the default and kept the theme it started with until it was restarted.
 *
 * The GSTheme default is pinned to GNUstep in the argument domain before
 * GSTheme is first used, so that the application under test starts on the
 * default theme whatever the machine running the test has configured.  It is
 * then switched to a bundle the test lays down itself, which carries no code:
 * +loadThemeNamed: builds a plain GSTheme for it, which is enough to tell
 * whether the default was followed.  Nothing on disk is written and nothing
 * waits for the defaults to be re-read: the domain is volatile and the
 * notification is posted here.
 */
#include "Testing.h"
#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include <GNUstepGUI/GSTheme.h>

static NSString *themeName = @"GSThemeFollowsDefaultTest";

static NSString *
themeBundlePath(void)
{
  NSArray	*dirs;

  dirs = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
    NSUserDomainMask, YES);
  if ([dirs count] == 0)
    {
      return nil;
    }
  return [[[dirs objectAtIndex: 0] stringByAppendingPathComponent: @"Themes"]
    stringByAppendingPathComponent:
      [themeName stringByAppendingPathExtension: @"theme"]];
}

static BOOL
makeThemeBundle(NSString *path)
{
  NSFileManager	*mgr = [NSFileManager defaultManager];
  NSDictionary	*info;

  if (NO == [mgr createDirectoryAtPath:
    [path stringByAppendingPathComponent: @"Resources"]
    withIntermediateDirectories: YES attributes: nil error: NULL])
    {
      return NO;
    }
  info = [NSDictionary dictionaryWithObjectsAndKeys:
    themeName, @"GSThemeName", nil];
  return [info writeToFile: [path stringByAppendingPathComponent:
    @"Resources/Info-gnustep.plist"] atomically: YES];
}

static void
setThemeDefault(NSString *name)
{
  NSUserDefaults	*defs = [NSUserDefaults standardUserDefaults];
  NSMutableDictionary	*args;

  args = [[[defs volatileDomainForName: NSArgumentDomain] mutableCopy]
    autorelease];
  if (args == nil)
    {
      args = [NSMutableDictionary dictionary];
    }
  [args setObject: name forKey: @"GSTheme"];
  [defs removeVolatileDomainForName: NSArgumentDomain];
  [defs setVolatileDomain: args forName: NSArgumentDomain];
  [[NSNotificationCenter defaultCenter]
    postNotificationName: NSUserDefaultsDidChangeNotification object: defs];
}

int
main(int argc, char **argv)
{
  NSAutoreleasePool	*pool = [NSAutoreleasePool new];

  START_SET("an application follows the GSTheme default it did not start with")
    NSString	*path = themeBundlePath();
    NSString	*started;

    if (path == nil || NO == makeThemeBundle(path))
      {
        SKIP("no writable library directory to put a theme bundle in")
      }

    /* Before GSTheme is first used, and so before it reads the default. */
    setThemeDefault(@"GNUstep");

    started = [[GSTheme theme] name];
    PASS([started isEqualToString: @"GNUstep"],
      "an application starts with the default theme (got %@)", started);

    setThemeDefault(themeName);
    PASS([[[GSTheme theme] name] isEqualToString: themeName],
      "the theme changes with the default (got %@)", [[GSTheme theme] name]);

    setThemeDefault(@"GNUstep");
    PASS([[[GSTheme theme] name] isEqualToString: @"GNUstep"],
      "and changes back when the default does (got %@)",
      [[GSTheme theme] name]);

    [[NSFileManager defaultManager] removeItemAtPath: path error: NULL];
  END_SET("an application follows the GSTheme default it did not start with")

  [pool release];
  return 0;
}
