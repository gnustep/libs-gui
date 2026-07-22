/* Coverage for NSTextAlternatives: the primary string and the alternative
 * strings passed to the initialiser, the value of the selected-alternative
 * notification name, and what noteSelectedAlternativeString: posts.  These are
 * plain model objects and need no backend.
 */
#include "Testing.h"
#include <Foundation/Foundation.h>
#include <AppKit/NSTextAlternatives.h>

@interface Observer : NSObject
{
  unsigned	count;
  id		object;
  NSDictionary	*info;
}
- (void) selected: (NSNotification *)aNotification;
- (unsigned) count;
- (id) object;
- (NSDictionary *) info;
@end

@implementation Observer
- (void) selected: (NSNotification *)aNotification
{
  count++;
  object = [aNotification object];
  ASSIGN(info, [aNotification userInfo]);
}
- (unsigned) count
{
  return count;
}
- (id) object
{
  return object;
}
- (NSDictionary *) info
{
  return info;
}
- (void) dealloc
{
  RELEASE(info);
  [super dealloc];
}
@end

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("a new object")
    NSArray		*alternatives;
    NSTextAlternatives	*alt;

    alternatives = [NSArray arrayWithObjects: @"color", @"colours", nil];
    alt = AUTORELEASE([[NSTextAlternatives alloc]
      initWithPrimaryString: @"colour"
         alternativeStrings: alternatives]);

    PASS(alt != nil, "a text alternatives object is created");
    PASS([[alt primaryString] isEqualToString: @"colour"],
      "the primary string reads back");
    PASS([[alt alternativeStrings] isEqualToArray: alternatives],
      "the alternative strings read back");
    PASS([[alt alternativeStrings] count] == 2,
      "the alternative strings keep their count");
  END_SET("a new object")

  START_SET("the notification name")
    PASS([NSTextAlternativesSelectedAlternativeStringNotification
      isEqualToString: @"NSTextAlternativesSelectedAlternativeStringNotification"],
      "the selected alternative notification name is the documented one");
  END_SET("the notification name")

  START_SET("noteSelectedAlternativeString:")
    NSArray		*alternatives;
    NSTextAlternatives	*alt;
    Observer		*observer;
    NSDictionary	*info;

    alternatives = [NSArray arrayWithObject: @"color"];
    alt = AUTORELEASE([[NSTextAlternatives alloc]
      initWithPrimaryString: @"colour"
         alternativeStrings: alternatives]);
    observer = AUTORELEASE([[Observer alloc] init]);

    [[NSNotificationCenter defaultCenter]
      addObserver: observer
         selector: @selector(selected:)
             name: NSTextAlternativesSelectedAlternativeStringNotification
           object: nil];
    [alt noteSelectedAlternativeString: @"color"];
    [[NSNotificationCenter defaultCenter] removeObserver: observer];

    info = [observer info];
    PASS([observer count] == 1,
      "noteSelectedAlternativeString: posts the notification once");
    PASS([observer object] == alt,
      "the notification is posted by the text alternatives object");
    PASS([[info allKeys] count] == 1,
      "the notification carries a single user info entry");
    PASS([[info objectForKey: @"NSAlternativeString"]
      isEqualToString: @"color"],
      "the user info carries the selected alternative string");
  END_SET("noteSelectedAlternativeString:")

  DESTROY(arp);
  return 0;
}
