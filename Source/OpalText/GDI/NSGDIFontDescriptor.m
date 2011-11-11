/** <title>NSGDIFontDescriptor</title>

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

#include <windows.h>

@interface NSGDIFontDescriptor : NSFontDescriptor
{
  LOGFONTW _logfont;
}

- (void)addName: (NSString*)name
{
}

- (void)addDisplayName: (NSString*)name
{
}

- (void)addFamilyName: (NSString*)name
{
  size_t length = MIN(LF_FACESIZE-1, [name length]);
  [name getCharacters: &_logfont.lfFaceName
                range: NSMakeRange(0, length)];
  _logfont.lfFaceName[length] = 0;
}

- (void)addStyleName: (NSString*)style
{
}

- (void)addTraits: (NSDictionary*)traits
{
  if ([traits objectForKey: kCTFontSymbolicTrait])
  {
    CTFontSymbolicTraits symTraits = [traits objectForKey: kCTFontSymbolicTrait];

    if (symTraits & kCTFontItalicTrait)
    {
			_logfont.lfItalic = TRUE;
    }
    if (symTraits & kCTFontBoldTrait)
    {
      // NOTE: May be overridden by kCTFontWeightTrait
      _logfont.lfWeight = FW_BOLD;
    }
    if (symTraits & kCTFontExpandedTrait)
    {
    }
    if (symTraits & kCTFontCondensedTrait)
    {
    }
    if (symTraits & kCTFontMonoSpaceTrait)
    {
      _logfont.lfPitchAndFamily |= FIXED_PITCH | FF_MODERN;
    }
    if (symTraits & kCTFontVerticalTrait)
    {
    }
    if (symTraits & kCTFontUIOptimizedTrait)
    {
    }

    CTFontStylisticClass class = symbolicTraits & kCTFontClassMaskTrait;

    switch (class)
    {
      default:
      case kCTFontUnknownClass:
      case kCTFontSymbolicClass:
        _logfont.lfPitchAndFamily |= FF_DONTCARE;
        break;
      case kCTFontOrnamentalsClass:
				_logfont.lfPitchAndFamily |= FF_DECORATIVE;
 				break;
      case kCTFontScriptsClass:
				_logfont.lfPitchAndFamily |= FF_SCRIPT;
				break;
      case kCTFontOldStyleSerifsClass:
      case kCTFontTransitionalSerifsClass:
      case kCTFontModernSerifsClass:
      case kCTFontClarendonSerifsClass:
      case kCTFontSlabSerifsClass:
      case kCTFontFreeformSerifsClass:
        _logfont.lfPitchAndFamily |= FF_ROMAN;
        break;
      case kCTFontSansSerifClass:
        _logfont.lfPitchAndFamily |= FF_SWISS;
        break;
    }
  }

  if ([traits objectForKey: kCTFontWeightTrait])
  {
    /**
     * Scale: -1 is thinnest, 0 is normal, 1 is heaviest
     */
    double weight = [[traits objectForKey: kCTFontWeightTrait] doubleValue];
    weight = MAX(-1, MIN(1, weight));
    if (weight <= 0)
    {
			_logfont.lfWeight = FW_THIN + ((weight + 1.0) * (FW_REGULAR - FW_THIN));
    }
    else
    {
 			_logfont.lfWeight = FW_NORMAL + (weight * (FW_BLACK - FW_NORMAL));
    }
  }

  if ([traits objectForKey: kCTFontWidthTrait])
  {
  }

  if ([traits objectForKey: kCTFontSlantTrait])
  {
    /**
     * Scale: -1 is 30 degree counterclockwise slant, 0 is no slant, 1
     * is 30 degree clockwise slant
     */
    double slant = [[traits objectForKey: kCTFontSlantTrait] doubleValue];

    if (slant > 0)
    {
			_logfont.lfItalic = TRUE;
    }
    else
    {
			_logfont.lfItalic = FALSE;
		}
  }
}

- (void)addVariation: (NSDictionary*)variationDict
{
  // NOTE: Fontconfig doesn't support variation axes
}

- (void)addSize: (NSNumber*)size
{
  _logFont.lfHeight = -MulDiv(PointSize, GetDeviceCaps(hDC, LOGPIXELSY), 72);
}

- (void)addMatrix: (NSData*)matrixData
{
}

- (void)addCascadeList: (NSArray*)cascadeList
{
  // NOTE: Don't think we can support this
}

- (void)addCharacterSet: (NSCharacterSet*)characterSet
{
  // FIXME: we should support this
}

- (void)addLanguages: (NSArray*)languages
{
}

- (void)addBaselineAdjust: (NSNumber*)baselineAdjust
{
  // NOTE: Don't think we can support this
}

- (void)addMacintoshEncodings: (NSNumber *)macintoshEncodings
{
  // NOTE: Don't think we can support this
}

- (void)addFeatures: (NSArray*)fontFeatures
{
  // NOTE: Don't think we can support this
}

- (void)addFeatureSettings: (NSArray*)fontFeatureSettings
{
  // NOTE: Don't think we can support this
}

- (void)addFixedAdvance: (NSNumber*)fixedAdvance
{
  // NOTE: Don't think we can support this
}

- (void)addOrientation: (NSNumber*)orientation
{
}

- (void)addFormat: (NSNumber*)format
{
  CTFontFormat fmt = [format intValue];
  switch (fmt)
  {
    default:
    case kCTFontFormatUnrecognized:
			break;
    case kCTFontFormatOpenTypePostScript:
    case kCTFontFormatOpenTypeTrueType:
    case kCTFontFormatTrueType:
      _logfont.lfOutPrecision = OUT_OUTLINE_PRECIS;		
			break;
    case kCTFontFormatPostScript:
      _logfont.lfOutPrecision = OUT_PS_ONLY_PRECIS;
      break;
    case kCTFontFormatBitmap:
      _logfont.lfOutPrecision = OUT_RASTER_PRECIS;
      break;
  }
}

- (void)addRegistrationScope: (NSNumber*)registrationScope
{
  // NOTE: Don't think we can support this
}

- (void)addPriority: (NSNumber*)priority
{
  // NOTE: Don't think we can support this
}

- (void)addEnabled: (NSNumber*)enabled
{
  // NOTE: Don't think we can support this
}

@end
