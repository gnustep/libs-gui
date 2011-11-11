/** <title>NSFontconfigFontDescriptor</title>

   <abstract>C Interface to text layout library</abstract>

   Copyright <copy>(C) 2010 Free Software Foundation, Inc.</copy>

   Author: Eric Wasylishen
   Date: Aug 2010

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
   */

#include <fontconfig/fontconfig.h>

#include <CoreGraphics/CGAffineTransform.h>
#include <CoreText/CTFontDescriptor.h>

#import "../NSFontDescriptor.h"

@interface NSFontconfigFontDescriptor : NSFontDescriptor
{
  /**
   * This is a Fontconfig representation of the attributes this descriptor
   * was created with.
   */
  FcPattern *_pat;
  /**
   * This is the Fontconfig pattern for a physical font on the user's system
   * which most closely matches _pat
   */
  FcPattern *_matchedPat;
}
@end

@implementation NSFontconfigFontDescriptor

- (void)addURL: (NSURL*)url
{
  NSString *path = [url path];
  if ([url isFileURL] && path != nil)
  {
    FcPatternAddString(_pat, FC_FILE, (const FcChar8 *)[path UTF8String]);
  }
  else
  {
    NSLog(@"Warning, URL %@ is invalid", url);
  }
}

- (void)addName: (NSString*)name
{
  // FIXME: Fontconfig ignores PostScript names of fonts; we need
  // https://bugs.freedesktop.org/show_bug.cgi?id=18095 fixed.

  // This is a hack to guess the family name from a PostScript name
  // It will often fail because PostScript names are sometimes abbreviated

  // FIXME: write the hack
  /*
  NSMutableString *family = [NSMutableString stringWithCapacity: 50];

  const NSUInteger nameLength = [name length];
  for (NSUInteger i=0; i<nameLength; i++)
  {
    if ([
  }*/

  FcPatternAddString(_pat, FC_FAMILY, (const FcChar8 *)[name UTF8String]);
}

- (void)addDisplayName: (NSString*)name
{
  FcPatternAddString(_pat, FC_FULLNAME, (const FcChar8 *)[name UTF8String]);
}

- (void)addFamilyName: (NSString*)name
{
  FcPatternAddString(_pat, FC_FAMILY, (const FcChar8 *)[name UTF8String]);
}

- (void)addStyleName: (NSString*)style
{
  FcPatternAddString(_pat, FC_STYLE, (const FcChar8 *)[style UTF8String]);
}

- (void)addTraits: (NSDictionary*)traits
{
  if ([traits objectForKey: kCTFontSymbolicTrait])
  {
    CTFontSymbolicTraits symTraits = [[traits objectForKey: kCTFontSymbolicTrait] intValue];

    if (symTraits & kCTFontItalicTrait)
    {
      // NOTE: May be overridden by kCTFontSlantTrait
      FcPatternAddInteger(_pat, FC_SLANT, FC_SLANT_ITALIC);
    }
    if (symTraits & kCTFontBoldTrait)
    {
      // NOTE: May be overridden by kCTFontWeightTrait
      FcPatternAddInteger(_pat, FC_WEIGHT, FC_WEIGHT_BOLD);
    }
    if (symTraits & kCTFontExpandedTrait)
    {
      // NOTE: May be overridden by kCTFontWidthTrait
      FcPatternAddInteger(_pat, FC_WIDTH, FC_WIDTH_EXPANDED);
    }
    if (symTraits & kCTFontCondensedTrait)
    {
      // NOTE: May be overridden by kCTFontWidthTrait
      FcPatternAddInteger(_pat, FC_WIDTH, FC_WIDTH_CONDENSED);
    }
    if (symTraits & kCTFontMonoSpaceTrait)
    {
      // If you run "fc-match :spacing=100", you get "DejaVu Sans" even though you would
      // expect to get "DejaVu Sans Mono". So, we also add "monospace" as a weak family
      // name to fix the problem.
      FcPatternAddInteger(_pat, FC_SPACING, FC_MONO);

			FcValue value;
      value.type = FcTypeString;
      value.u.s = (FcChar8*)"monospace";
      FcPatternAddWeak(_pat, FC_FAMILY, value, FcTrue);
    }
    if (symTraits & kCTFontVerticalTrait)
    {
      // FIXME: What is this supposed to mean?
    }
    if (symTraits & kCTFontUIOptimizedTrait)
    {
			// NOTE: Fontconfig can't express this
    }

    CTFontStylisticClass class = symTraits & kCTFontClassMaskTrait;
    char *addWeakFamilyName = NULL;
    switch (class)
    {
      default:
      case kCTFontUnknownClass:
      case kCTFontOrnamentalsClass:
      case kCTFontScriptsClass:
      case kCTFontSymbolicClass:
        // FIXME: Is there some way to convey these to Fontconfig?
        break;
      case kCTFontOldStyleSerifsClass:
      case kCTFontTransitionalSerifsClass:
      case kCTFontModernSerifsClass:
      case kCTFontClarendonSerifsClass:
      case kCTFontSlabSerifsClass:
      case kCTFontFreeformSerifsClass:
		  	addWeakFamilyName = "serif";
        break;
      case kCTFontSansSerifClass:
        addWeakFamilyName = "sans";
        break;
    }
    if (addWeakFamilyName)
    {
      FcValue value;
      value.type = FcTypeString;
      value.u.s = (const FcChar8 *)addWeakFamilyName;
      FcPatternAddWeak(_pat, FC_FAMILY, value, FcTrue);
    }
  }

  if ([traits objectForKey: kCTFontWeightTrait])
  {
    /**
     * Scale: -1 is thinnest, 0 is normal, 1 is heaviest
     */
    double weight = [[traits objectForKey: kCTFontWeightTrait] doubleValue];
    weight = MAX(-1, MIN(1, weight));
    int fcWeight;
    if (weight <= 0)
    {
			fcWeight = FC_WEIGHT_THIN + ((weight + 1.0) * (FC_WEIGHT_NORMAL - FC_WEIGHT_THIN));
    }
    else
    {
 			fcWeight = FC_WEIGHT_NORMAL + (weight * (FC_WEIGHT_ULTRABLACK - FC_WEIGHT_NORMAL));
    }
    FcPatternAddInteger(_pat, FC_WEIGHT, fcWeight);
  }

  if ([traits objectForKey: kCTFontWidthTrait])
  {
    /**
     * Scale: -1 is most condensed, 0 is normal, 1 is most spread apart
     */
    double width = [[traits objectForKey: kCTFontWidthTrait] doubleValue];
    width = MAX(-1, MIN(1, width));
    int fcWidth;
    if (width <= 0)
    {
			fcWidth = FC_WIDTH_ULTRACONDENSED + ((width + 1.0) * (FC_WIDTH_NORMAL - FC_WIDTH_ULTRACONDENSED));
    }
    else
    {
 			fcWidth = FC_WIDTH_NORMAL + (width * (FC_WIDTH_ULTRAEXPANDED - FC_WIDTH_NORMAL));
    }
    FcPatternAddInteger(_pat, FC_WIDTH, fcWidth);
  }

  if ([traits objectForKey: kCTFontSlantTrait])
  {
    /**
     * Scale: -1 is 30 degree counterclockwise slant, 0 is no slant, 1
     * is 30 degree clockwise slant
     */
    double slant = [[traits objectForKey: kCTFontSlantTrait] doubleValue];

    // NOTE: Fontconfig can't express this as a scale
    if (slant > 0)
    {
      FcPatternAddInteger(_pat, FC_SLANT, FC_SLANT_ITALIC);
    }
    else
    {
      FcPatternAddInteger(_pat, FC_SLANT, FC_SLANT_ROMAN);
    }
  }
}

- (void)addSize: (NSNumber*)size
{
  FcPatternAddDouble(_pat, FC_SIZE, [size doubleValue]);
}

- (void)addCharacterSet: (NSCharacterSet*)characterSet
{
  // FIXME: Keep a cache of NSCharacterSet->FcCharSet pairs, because
  // this is really slow.

  FcCharSet *fcSet = FcCharSetCreate();

  for (uint32_t plane=0; plane<=16; plane++)
  {
    if ([characterSet hasMemberInPlane: plane])
    {
       for (uint32_t codePoint = plane<<16; codePoint <= 0xffff + (plane<<16); codePoint++)
       {
          if ([characterSet longCharacterIsMember: codePoint])
          {
            FcCharSetAddChar(fcSet, codePoint);
          }
       }
    }
  }

  FcPatternAddCharSet(_pat, FC_CHARSET, fcSet);
  FcCharSetDestroy(fcSet);
}

- (void)addLanguages: (NSArray*)languages
{
  FcLangSet *fcLangSet = FcLangSetCreate();

  NSUInteger languagesCount = [languages count];
  for (NSUInteger i=0; i<languagesCount; i++)
  {
    FcLangSetAdd(fcLangSet, (const FcChar8 *)[[languages objectAtIndex: i] UTF8String]);
  }

  FcPatternAddLangSet(_pat, FC_LANG, fcLangSet);
  FcLangSetDestroy(fcLangSet);
}

- (void)addOrientation: (NSNumber*)orientation
{
  CTFontOrientation orient = [orientation intValue];
  switch (orient)
  {
    default:
    case kCTFontDefaultOrientation:
    case kCTFontHorizontalOrientation:
      break;
    case kCTFontVerticalOrientation:
      FcPatternAddBool(_pat, FC_VERTICAL_LAYOUT, FcTrue);
      break;
  }
}

- (void)addFormat: (NSNumber*)format
{
  CTFontFormat fmt = [format intValue];
  switch (fmt)
  {
    default:
    case kCTFontFormatUnrecognized:
    case kCTFontFormatOpenTypePostScript:
    case kCTFontFormatOpenTypeTrueType:
    case kCTFontFormatTrueType:
    case kCTFontFormatPostScript:
      break;
    case kCTFontFormatBitmap:
      FcPatternAddBool(_pat, FC_OUTLINE, FcFalse);
      break;
  }
}

//-------------


- (NSString*)readFontconfigString: (const char *)key fromPattern: (FcPattern*)pat
{
  unsigned char *string = NULL;
  if (FcResultMatch == FcPatternGetString(pat, key, 0, &string))
  {
    if (string)
    {
      return [NSString stringWithUTF8String: (const char *)string];
    }
  }
  return nil;
}

- (NSString*)readFontconfigLocalizedStringWithKey: (const char *)key
                                      languageKey: (const char *)langKey
                                         language: (NSString*)language
                                      fromPattern: (FcPattern*)pat
{
  const char *desiredLang = [language UTF8String];

  unsigned char *string = NULL;
  unsigned char *langString = NULL;

  int index = 0;
  while ((FcResultMatch == FcPatternGetString(pat, key, index, &string))
          && (FcResultMatch == FcPatternGetString(pat, langKey, index, &langString)))
	{
	  if (0 == strcmp((const char *)langString, desiredLang))
	  {
	    return [NSString stringWithUTF8String: (const char *)string];
	  }
    else
    {
      index++;
    }
	}

  return nil;
}

- (NSNumber*)readFontconfigInteger: (const char *)key fromPattern: (FcPattern*)pat
{
  int value;
  if (FcResultMatch == FcPatternGetInteger(pat, key, 0, &value))
  {
    return [NSNumber numberWithInt: value];
  }
  return nil;
}

- (NSNumber*)readFontconfigDouble: (const char *)key fromPattern: (FcPattern*)pat
{
  double value;
  if (FcResultMatch == FcPatternGetDouble(pat, key, 0, &value))
  {
    return [NSNumber numberWithDouble: value];
  }
  return nil;
}

//-----------------------

- (NSURL*)readURLFromPattern: (FcPattern*)pat
{
  return [NSURL fileURLWithPath: [self readFontconfigString: FC_FILE fromPattern: pat]];
}
- (NSString*)readNameFromPattern: (FcPattern*)pat
{
  // FIXME: try to get the localized one
  return [self readFontconfigString: FC_FAMILY fromPattern: pat];
}
- (NSString*)readDisplayNameFromPattern: (FcPattern*)pat
{
  // FIXME: try to get the localized one
  return [self readFontconfigString: FC_FULLNAME fromPattern: pat];
}
- (NSString*)readFamilyNameFromPattern: (FcPattern*)pat
{
  // FIXME: try to get the localized one
  return [self readFontconfigString: FC_FAMILY fromPattern: pat];
}
- (NSString*)readStyleNameFromPattern: (FcPattern*)pat
{
  // FIXME: try to get the localized one
  return [self readFontconfigString: FC_STYLE fromPattern: pat];
}
- (NSDictionary*)readTraitsFromPattern: (FcPattern*)pat
{
  NSMutableDictionary *traits = [NSMutableDictionary dictionary];

  CTFontSymbolicTraits symTraits = 0;

  int value;
  if (FcResultMatch == FcPatternGetInteger(pat, FC_SLANT, 0, &value))
  {
    if (value == FC_SLANT_ITALIC)
    {
      symTraits |= kCTFontItalicTrait;
    }
  }
  if (FcResultMatch == FcPatternGetInteger(pat, FC_WEIGHT, 0, &value))
  {
    if (value >= FC_WEIGHT_BOLD)
    {
      symTraits |= kCTFontBoldTrait;
    }

	  double weight;
	  if (value <= FC_WEIGHT_NORMAL)
	  {
      weight = ((value - FC_WEIGHT_THIN) / (double)(FC_WEIGHT_NORMAL - FC_WEIGHT_THIN)) - 1.0;
	  }
	  else
	  {
      weight = (value - FC_WEIGHT_NORMAL) / (double)(FC_WEIGHT_ULTRABLACK - FC_WEIGHT_NORMAL);
	  }

    [traits setObject: [NSNumber numberWithDouble: weight]
               forKey: kCTFontWeightTrait];
  }
  if (FcResultMatch == FcPatternGetInteger(pat, FC_WIDTH, 0, &value))
  {
    if (value >= FC_WIDTH_EXPANDED)
    {
      symTraits |= kCTFontExpandedTrait;
    }
    if (value <= FC_WIDTH_CONDENSED)
    {
      symTraits |= kCTFontCondensedTrait;
    }

	  double width;
	  if (value <= FC_WIDTH_NORMAL)
	  {
      width = ((value - FC_WIDTH_ULTRACONDENSED) / (double)(FC_WIDTH_NORMAL - FC_WIDTH_ULTRACONDENSED)) - 1.0;
	  }
	  else
	  {
      width = (value - FC_WIDTH_NORMAL) / (double)(FC_WIDTH_ULTRAEXPANDED - FC_WIDTH_NORMAL);
	  }

    [traits setObject: [NSNumber numberWithDouble: width]
               forKey: kCTFontWidthTrait];
  }
  if (FcResultMatch == FcPatternGetInteger(pat, FC_SPACING, 0, &value))
  {
    if (value == FC_MONO)
    {
      symTraits |= kCTFontMonoSpaceTrait;
    }
  }

  if (symTraits != 0)
  {
    [traits setObject: [NSNumber numberWithUnsignedInt: symTraits]
               forKey: kCTFontSymbolicTrait];
  }

  return traits;
}

- (NSNumber*)readSizeFromPattern: (FcPattern*)pat
{
  return [self readFontconfigDouble: FC_SIZE fromPattern: pat];
}

- (NSCharacterSet*)readCharacterSetFromPattern: (FcPattern*)pat
{
  // FIXME: Implement
  return nil;
}

- (NSArray*)readLanguagesFromPattern: (FcPattern*)pat
{
  NSMutableArray *langs = [NSMutableArray array];

  FcLangSet *fcLangSet;
  if (FcResultMatch == FcPatternGetLangSet(pat, FC_LANG, 0, &fcLangSet))
  {
    // FIXME: Not totally clear wheter we have to destroy this
    FcStrSet *stringSet = FcLangSetGetLangs(fcLangSet);
    FcStrList *setIterator = FcStrListCreate(stringSet);
    FcChar8 *str;
    while (NULL != (str = FcStrListNext(setIterator)))
    {
      [langs addObject: [NSString stringWithUTF8String: (const char *)str]];
    }
    FcStrListDone(setIterator);
  }

  return langs;
}

- (NSNumber*)readOrientationFromPattern: (FcPattern*)pat
{
  int value;
  if (FcResultMatch == FcPatternGetBool(pat, FC_VERTICAL_LAYOUT, 0, &value))
  {
    if (value == FcTrue)
    {
      return [NSNumber numberWithInt: kCTFontVerticalOrientation];
    }
    else
    {
      return [NSNumber numberWithInt: kCTFontHorizontalOrientation];
    }
  }
  return nil;
}

- (NSNumber*)readFormatFromPattern: (FcPattern*)pat
{
  int value;
  if (FcResultMatch == FcPatternGetBool(pat, FC_OUTLINE, 0, &value))
  {
    if (value == FcFalse)
    {
      return [NSNumber numberWithInt: kCTFontFormatBitmap];
    }
  }
  return nil;
}




//-------------
// Private
- (void)handleKey: (NSString*)key selector: (SEL)selector valueClass: (Class)valueClass
{
  id value = [[self fontAttributes] objectForKey: key];
  if (value)
  {
    if ([value isKindOfClass: valueClass])
    {
      if ([self respondsToSelector: selector])
      {
        [self performSelector: selector withObject: value];
      }
    }
    else
    {
      NSLog(@"NSFontDescriptor: Ignoring invalid value %@ for attribute %@", value, key);
    }
  }
}

/**
 * Call in subclasses -initWithFontAttributes method to have custom handlers invoked
 * for each attribute key
 */
- (void)handleAddValues
{
  [self handleKey: kCTFontURLAttribute selector: @selector(addURL:) valueClass: [NSURL class]];
  [self handleKey: kCTFontNameAttribute selector: @selector(addName:) valueClass: [NSString class]];
  [self handleKey: kCTFontDisplayNameAttribute selector: @selector(addDisplayName:) valueClass: [NSString class]];
  [self handleKey: kCTFontFamilyNameAttribute selector: @selector(addFamilyName:) valueClass: [NSString class]];
  [self handleKey: kCTFontStyleNameAttribute selector: @selector(addStyleName:) valueClass: [NSString class]];
  [self handleKey: kCTFontTraitsAttribute selector: @selector(addTraits:) valueClass: [NSDictionary class]];
  [self handleKey: kCTFontSizeAttribute selector: @selector(addSize:) valueClass: [NSNumber class]];
  [self handleKey: kCTFontCharacterSetAttribute selector: @selector(addCharacterSet:) valueClass: [NSCharacterSet class]];
  [self handleKey: kCTFontLanguagesAttribute selector: @selector(addLanguages:) valueClass: [NSArray class]];
  [self handleKey: kCTFontOrientationAttribute selector: @selector(addOrientation:) valueClass: [NSNumber class]];
  [self handleKey: kCTFontFormatAttribute selector: @selector(addFormat:) valueClass: [NSNumber class]];
}


- (id) initWithFontAttributes: (NSDictionary *)attributes
{
  self = [super initWithFontAttributes: attributes];
  if (nil == self)
  {
    return nil;
  }

  _pat = FcPatternCreate();

  // Call the corresponding add...: method for each element in the attributes dictionary
  [self handleAddValues];

  //NSLog(@"NSFontconfigFontDescriptor: Input attributes %@", attributes);
  //NSLog(@"NSFontconfigFontDescriptor: Output pattern:");
  //FcPatternPrint(_pat);

  return self;
}

/**
 * Private initializer. The provided pattern must have been matched, and must not
 * be subsequently modified.
 */
- (id) initWithImmutableMatchedPattern: (FcPattern*)pat
{
  self = [super initWithFontAttributes: nil];
  if (nil == self)
  {
    return nil;
  }

  FcPatternReference(pat);
  _pat = pat;

  FcPatternReference(pat);
  _matchedPat = pat;

  return self;
}

- (void)dealloc
{
  if (_pat)
  {
    FcPatternDestroy(_pat);
  }
  if (_matchedPat)
  {
    FcPatternDestroy(_matchedPat);
  }
  [super dealloc];
}

- (NSString*)description
{
  return [NSString stringWithFormat: @"<NSFontconfigFontDescriptor name: %@ URL: %@>",
    [self objectForKey: kCTFontNameAttribute],
    [self objectForKey: kCTFontURLAttribute]];
}

- (void)matchPattern
{
  if (!_matchedPat)
  {
    FcPattern *patCopy = FcPatternDuplicate(_pat);

    //NSLog(@"1. before substituting: ");
    //FcPatternPrint(patCopy);

    FcConfigSubstitute(NULL, patCopy, FcMatchPattern);

    //NSLog(@"2. after configSubstitute: ");
    //FcPatternPrint(patCopy);

    FcDefaultSubstitute(patCopy);

    //NSLog(@"3. after DefaultSubstitute : ");
    //FcPatternPrint(patCopy);

    // FIXME: FcFontMatch doesn't write in the result variable if the match was successful, this is a strange policy
    FcResult result = FcResultMatch;
    _matchedPat = FcFontMatch(NULL, patCopy, &result);
    if (result != FcResultMatch)
    {
      NSLog(@"Warning, FcFontMatch failed with code: %d", result);
    }
    else
    {
      FcPatternReference(_matchedPat);
      //NSLog(@"FcFontMatch succeeded, attributes: ");
      //FcPatternPrint(_matchedPat);
    }
		FcPatternDestroy(patCopy);
  }
}

/**
 * Overridden methods:
 */

- (NSArray *) matchingFontDescriptorsWithMandatoryKeys: (NSSet *)mandatoryKeys
{
  NSMutableArray *matching = [NSMutableArray array];

  [self matchPattern];

  FcResult result = FcResultMatch;
  FcFontSet *fontSet = FcFontSort(NULL, _matchedPat, FcFalse, NULL, &result);
  if (result == FcResultMatch)
  {
    for (int i=0; i<fontSet->nfont; i++)
    {
      FcPattern *pat = FcPatternDuplicate(fontSet->fonts[i]);

      NSFontDescriptor *candidate = [[NSFontconfigFontDescriptor alloc] initWithImmutableMatchedPattern: pat];
      BOOL acceptable = YES;
      if (mandatoryKeys)
      {
   			NSEnumerator *enumerator = [mandatoryKeys objectEnumerator];
   	    NSString *mandatoryKey;
        while (nil != (mandatoryKey = [enumerator nextObject]))
        {
          id selfValue = [self objectForKey: mandatoryKey];
          id candidateValue = [candidate objectForKey: mandatoryKey];

          if ((selfValue != nil || candidateValue != nil)
              && ![selfValue isEqual: candidateValue])
          {
            // Hack: only requre kCTFontTraitsAttribute to have the same kCTFontSymbolicTrait
            if ([mandatoryKey isEqualToString: kCTFontTraitsAttribute])
            {
              if ([[selfValue objectForKey: kCTFontSymbolicTrait] intValue]
                  == [[candidateValue objectForKey: kCTFontSymbolicTrait] intValue])
              {
                continue; // Good enough match
              }
            }
            // Otherwise, reject.
            acceptable = NO;
            break;
          }
        }
      }
      if (acceptable)
      {
        [matching addObject: candidate];
      }
      [candidate release];

      FcPatternDestroy(pat);
    }
  }
  else
  {
    NSLog(@"ERROR! FcFontSort failed");
  }

  FcFontSetDestroy(fontSet);

  return matching;
}

static NSDictionary *ReadSelectors;

- (NSValue*)selValue: (SEL)selector
{
  return [NSValue valueWithBytes: &selector objCType: @encode(SEL)];
}

- (id) objectFromPlatformFontPatternForKey: (NSString *)attribute
{
  if (!ReadSelectors)
  {
    ReadSelectors = [[NSDictionary alloc] initWithObjectsAndKeys:
      [self selValue: @selector(readURLFromPattern:)], kCTFontURLAttribute,
      [self selValue: @selector(readNameFromPattern:)], kCTFontNameAttribute,
      [self selValue: @selector(readDisplayNameFromPattern:)], kCTFontDisplayNameAttribute,
      [self selValue: @selector(readFamilyNameFromPattern:)], kCTFontFamilyNameAttribute,
      [self selValue: @selector(readStyleNameFromPattern:)], kCTFontStyleNameAttribute,
      [self selValue: @selector(readTraitsFromPattern:)], kCTFontTraitsAttribute,
      [self selValue: @selector(readSizeFromPattern:)], kCTFontSizeAttribute,
      [self selValue: @selector(readCharacterSetFromPattern:)], kCTFontCharacterSetAttribute,
      [self selValue: @selector(readLanguagesFromPattern:)], kCTFontLanguagesAttribute,
      [self selValue: @selector(readOrientationFromPattern:)], kCTFontOrientationAttribute,
      [self selValue: @selector(readFormatFromPattern:)], kCTFontFormatAttribute,
      nil];
  }

  [self matchPattern];

  id selValue = [ReadSelectors objectForKey: attribute];
  if (selValue)
  {
    SEL sel;
    [selValue getValue: &sel];

    id result = [self performSelector: sel withObject: (id)_matchedPat];
    return result;
  }
  return nil;
}

- (id) localizedObjectFromPlatformFontPatternForKey: (NSString*)key language: (NSString*)language
{
  // Only FC_FAMILY, FC_STYLE, FC_FULLNAME are localized.

  [self matchPattern];

  // FIXME: kCTFontNameAttribute hack
  if ([key isEqualToString: kCTFontNameAttribute]
      || [key isEqualToString: kCTFontFamilyNameAttribute])
  {
    return [self readFontconfigLocalizedStringWithKey: FC_FAMILY
                                          languageKey: FC_FAMILYLANG
                                             language: language
                                          fromPattern: _matchedPat];
  }
  else if ([key isEqualToString: kCTFontStyleNameAttribute])
  {
    return [self readFontconfigLocalizedStringWithKey: FC_STYLE
                                          languageKey: FC_STYLELANG
                                             language: language
                                          fromPattern: _matchedPat];
  }
  else if ([key isEqualToString: kCTFontDisplayNameAttribute])
  {
    return [self readFontconfigLocalizedStringWithKey: FC_FULLNAME
                                          languageKey: FC_FULLNAMELANG
                                             language: language
                                          fromPattern: _matchedPat];
  }
  return nil;
}

- (NSString*)_fontPath
{
  return [self readFontconfigString: FC_FILE
                       fromPattern: _matchedPat];
}

- (NSInteger)_fontfaceIndex
{
  return [[self readFontconfigInteger: FC_INDEX
                          fromPattern: _matchedPat] integerValue];
}

@end
