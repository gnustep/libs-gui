#include <AppKit/NSAttributedString.h>

//@implementation NSAttributedString (AppKit)

/*
 * This is where the fun begins with RTF/RTFD/HTML
 */

//@end

@implementation NSMutableAttributedString (AppKit)
- (void)superscriptRange:(NSRange)range
{
  id value;
  int sValue;

  value = [self attribute:NSSuperscriptAttributeName
		atIndex:range.location effectiveRange:&range];

  sValue = [value intValue];

  sValue++;

  [self addAttribute:NSSuperscriptAttributeName value:[[NSNumber alloc]
	initWithInt:sValue] range:range];
}

- (void)subscriptRange:(NSRange)range
{
  id value;
  int sValue;

  value = [self attribute:NSSuperscriptAttributeName
		atIndex:range.location effectiveRange:&range];

  sValue = [value intValue];

  sValue--;

  [self addAttribute:NSSuperscriptAttributeName value:[[NSNumber alloc]
	initWithInt:sValue] range:range];
}

- (void)unscriptRange:(NSRange)range
{
  [self addAttribute:NSSuperscriptAttributeName value:[[NSNumber alloc]
        initWithInt:0] range:range];
}

- (void)applyFontTraits:(NSFontTraitMask)traitMask range:(NSRange)range
{
/* We don't use font traits yet, oops. */
/*
  id value;

  value = [self attribute:NSFontAttributeName
		atIndex:range.location effectiveRange:range];

  [value setFontTraits:traitMask];

  [self addAttribute:NSFontAttributeName value:value range:range];
*/
}

- (void)setAlignment:(NSTextAlignment)alignment range:(NSRange)range
{
  id value;

  value = [self attribute:NSParagraphStyleAttributeName
		atIndex:range.location effectiveRange:&range];

  [value setAlignment:alignment];

  [self addAttribute:NSParagraphStyleAttributeName value:value range:range];
}

- (void)fixAttributesInRange:(NSRange)range
{
  [self fixFontAttributeInRange:range];
  [self fixParagraphStyleAttributeInRange:range];
  [self fixAttachmentAttributeInRange:range];
}

- (void)fixFontAttributeInRange:(NSRange)range
{
}

- (void)fixParagraphStyleAttributeInRange:(NSRange)range
{
}

- (void)fixAttachmentAttributeInRange:(NSRange)range
{
}
@end
