/* Coverage for NSPathControlItem: init defaults, the presence of the
   URL/title/attributedTitle/image setters, and their round-trip behaviour.
   Every assertion was checked against Apple AppKit (macOS 26) and only the
   behaviours that match are asserted here.  NSPathControlItem is a plain model
   object and needs no backend. */
#import "Testing.h"
#import <Foundation/NSString.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSAttributedString.h>
#import <AppKit/NSPathControlItem.h>

int main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  NSPathControlItem *it = [[NSPathControlItem alloc] init];
  PASS(it != nil, "NSPathControlItem -init returns an instance");

  /* Defaults that match AppKit. */
  PASS([it URL] == nil, "default URL is nil");
  PASS([it image] == nil, "default image is nil");

  /* AppKit exposes all four setters. */
  PASS([it respondsToSelector: @selector(setURL:)], "responds to -setURL:");
  PASS([it respondsToSelector: @selector(setTitle:)], "responds to -setTitle:");
  PASS([it respondsToSelector: @selector(setAttributedTitle:)],
       "responds to -setAttributedTitle:");
  PASS([it respondsToSelector: @selector(setImage:)], "responds to -setImage:");

  /* setURL: round-trips. */
  NSURL *url = [NSURL fileURLWithPath: @"/tmp/foo"];
  [it setURL: url];
  PASS([[it URL] isEqual: url], "-setURL: round-trips");

  /* setTitle: sets the title and backs the attributed title. */
  [it setTitle: @"hello"];
  PASS([[it title] isEqualToString: @"hello"], "-setTitle: sets -title");
  PASS([[[it attributedTitle] string] isEqualToString: @"hello"],
       "-setTitle: backs -attributedTitle");

  /* setAttributedTitle: sets the attributed title and drives -title. */
  NSAttributedString *a =
      [[NSAttributedString alloc] initWithString: @"world"];
  [it setAttributedTitle: a];
  PASS([[[it attributedTitle] string] isEqualToString: @"world"],
       "-setAttributedTitle: sets -attributedTitle");
  PASS([[it title] isEqualToString: @"world"],
       "-title reflects -attributedTitle");
  RELEASE(a);

  RELEASE(it);
  DESTROY(arp);
  return 0;
}
