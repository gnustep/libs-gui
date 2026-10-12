#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSSet.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSAttributedString.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSFontDescriptor.h>
#include <AppKit/NSFontManager.h>

int main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSFont *font = nil;
  NSArray *names;
  unichar candidates[] = { 0x2318, 0x21E7, 0x2325, 0x2713 };
  unichar missing = 0;
  NSUInteger i;

  START_SET("NSAttributedString font substitution")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  /* A font that lacks a character an installed font has. */
  names = [[NSFontManager sharedFontManager] availableFonts];
  for (i = 0; i < sizeof(candidates) / sizeof(candidates[0]) && missing == 0; i++)
    {
      NSString *chars = [NSString stringWithCharacters: &candidates[i] length: 1];
      NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString: chars];
      NSFontDescriptor *fd = [NSFontDescriptor fontDescriptorWithFontAttributes:
        [NSDictionary dictionaryWithObject: set forKey: NSFontCharacterSetAttribute]];
      NSFontDescriptor *match = [fd matchingFontDescriptorWithMandatoryKeys:
        [NSSet setWithObject: NSFontCharacterSetAttribute]];

      NSUInteger j;

      if (![[match objectForKey: NSFontCharacterSetAttribute] characterIsMember: candidates[i]])
        continue;
      for (j = 0; j < [names count] && j < 200 && missing == 0; j++)
        {
          NSFont *f = [NSFont fontWithName: [names objectAtIndex: j] size: 12];

          if (f != nil && [f coveredCharacterSet] != nil
            && ![[f coveredCharacterSet] characterIsMember: candidates[i]])
            {
              font = f;
              missing = candidates[i];
            }
        }
    }
  if (missing == 0)
    SKIP("No installed font lacks a character another one has")

  {
    NSString *text = [@"A" stringByAppendingString: [NSString stringWithCharacters: &missing length: 1]];
    NSMutableAttributedString *s;
    NSFont *substituted;

    s = AUTORELEASE([[NSMutableAttributedString alloc] initWithString: text
      attributes: [NSDictionary dictionaryWithObject: font forKey: NSFontAttributeName]]);
    [s fixFontAttributeInRange: NSMakeRange(0, [s length])];
    substituted = [s attribute: NSFontAttributeName atIndex: 1 effectiveRange: NULL];
    PASS([[substituted coveredCharacterSet] characterIsMember: missing],
      "a character the font lacks is given a font that has it");
    PASS_EQUAL([s attribute: NSFontAttributeName atIndex: 0 effectiveRange: NULL], font,
      "a character the font has keeps it");
  }

  END_SET("NSAttributedString font substitution")

  DESTROY(arp);
  return 0;
}
