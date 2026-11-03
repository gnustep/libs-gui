/* A xib font element that carries neither a name nor a metaFont, which is what
 * Interface Builder writes for a control left on the standard appearance font,
 * has to give the system font at the system font size. AppKit gives such a
 * cell the same font as one written metaFont="system", while a cell with no
 * font element at all keeps NSCell's own default instead.
 *
 * The system font size is moved off its default here so that the size the
 * element resolves to is distinguishable.
 */
#import "ObjectTesting.h"

#import <Foundation/NSData.h>
#import <Foundation/NSUserDefaults.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSCell.h>
#import <AppKit/NSFont.h>
#import <AppKit/NSTextField.h>
#import <Additions/GNUstepGUI/GSXibKeyedUnarchiver.h>

static NSCell *
cellTitled(NSArray *objects, NSString *title)
{
  NSEnumerator *enumerator = [objects objectEnumerator];
  id element;

  while ((element = [enumerator nextObject]) != nil)
    {
      if ([element isKindOfClass: [NSTextField class]]
          && [[[element cell] title] isEqualToString: title])
        {
          return [element cell];
        }
    }
  return nil;
}

int main()
{
  START_SET("GSXib5KeyedUnarchiver appearance font tests")

  NS_DURING
    {
      [NSApplication sharedApplication];
    }
  NS_HANDLER
    {
      if ([[localException name]
	isEqualToString: NSInternalInconsistencyException ])
	{
	  SKIP("It looks like GNUstep backend is not yet installed")
	}
    }
  NS_ENDHANDLER

  NSData	*data;
  id		unarchiver;
  NSArray	*rootObjects;
  NSCell	*appearance;
  NSCell	*metaSystem;
  NSCell	*noFont;
  NSFont	*systemFont;

  [[NSUserDefaults standardUserDefaults] setObject: @"16"
					   forKey: @"NSFontSize"];
  PASS([NSFont systemFontSize] == 16.0,
    "the system font size is moved off its default for the test")

  data = [NSData dataWithContentsOfFile: @"AppearanceFont.xib"];
  unarchiver = [GSXibKeyedUnarchiver unarchiverForReadingWithData: data];
  rootObjects = [unarchiver decodeObjectForKey: @"IBDocument.RootObjects"];

  appearance = cellTitled(rootObjects, @"APPEARANCE");
  metaSystem = cellTitled(rootObjects, @"METASYSTEM");
  noFont = cellTitled(rootObjects, @"NOFONT");

  PASS(appearance != nil && metaSystem != nil && noFont != nil,
    "the three text field cells were decoded")

  systemFont = [NSFont systemFontOfSize: [NSFont systemFontSize]];

  /* The element resolves to a font at all. */
  PASS([appearance font] != nil, "the appearance font element gives a font")

  /* And it is the system font, at the system font size. */
  PASS_EQUAL([[appearance font] fontName], [systemFont fontName],
    "the appearance font element gives the system font")
  PASS([[appearance font] pointSize] == [NSFont systemFontSize],
    "the appearance font element gives the system font size")

  /* Which is what metaFont=\"system\" gives, as on AppKit. */
  PASS_EQUAL([[appearance font] fontName], [[metaSystem font] fontName],
    "the appearance font matches a metaFont system font")
  PASS([[appearance font] pointSize] == [[metaSystem font] pointSize],
    "the appearance font size matches a metaFont system font")

  /* A cell with no font element is a different case and keeps its own
     default, so the two must not be collapsed. */
  PASS([noFont font] != nil, "a cell with no font element still has a font")

  [[NSUserDefaults standardUserDefaults] removeObjectForKey: @"NSFontSize"];

  END_SET("GSXib5KeyedUnarchiver appearance font tests")

  return 0;
}
