/** <title>CTGlyphInfo</title>

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

#include <CoreText/CTGlyphInfo.h>

/* Classes */

/**
 * Specifies a custom mapping from a sequence of Unicode characters to a 
 * single glyph.
 */
@interface CTGlyphInfo : NSObject
{
  /**
   * The sequence of Unicode characters to map from
   */
  NSString *_baseString;
  /**
   * The glpyh name to map to
   */
  NSString *_glpyhName;
  /**
   * Alternative representation of the glpyh to map to
   */
  CTCharacterCollection _characterCollection;  
  CGFontIndex _characterIdentifier;
}

- (CTGlyphInfoRef) initWithGlyphName: (NSString*)glyphName
                                font: (CTFontRef)font
                          baseString: (NSString*)baseString;
- (CTGlyphInfoRef) initWithGlyph: (CGGlyph)glyph
                            font: (CTFontRef)font
                      baseString: (NSString*)baseString;
- (CTGlyphInfoRef) initWithCharacterIdentifier: (CGFontIndex)cid
                           characterCollection: (CTCharacterCollection)collection
                                    baseString: (NSString*)baseString;
- (CFStringRef) glyphName;
- (CGFontIndex) characterIdentifier;
- (CTCharacterCollection) characterCollection;

@end

@implementation CTGlyphInfo

- (CTGlyphInfoRef) initWithGlyphName: (NSString*)glyphName
                                font: (CTFontRef)font
                          baseString: (NSString*)baseString
{
  self = [super init];
  if (nil == self)
  {
    return nil;
  }
  _characterCollection = kCTIdentityMappingCharacterCollection;
  _characterIdentifier = CTFontGetGlyphWithName(font, glyphName);
  _glpyhName = [glyphName retain];
  _baseString = [baseString retain];

  return self;
}

- (CTGlyphInfoRef) initWithGlyph: (CGGlyph)glyph
                            font: (CTFontRef)font
                      baseString: (NSString*)baseString
{
  self = [super init];
  if (nil == self)
  {
    return nil;
  }
  CGFontRef graphicsFont = CTFontCopyGraphicsFont(font, NULL);
  _glpyhName = CGFontCopyGlyphNameForGlyph(graphicsFont, glyph);
  [graphicsFont release];

  _characterCollection = kCTIdentityMappingCharacterCollection;
  _characterIdentifier = glyph;
  _baseString = [baseString retain];

  return self;
}

- (CTGlyphInfoRef) initWithCharacterIdentifier: (CGFontIndex)cid
                           characterCollection: (CTCharacterCollection)collection
                                    baseString: (NSString*)baseString
{
  self = [super init];
  if (nil == self)
  {
    return nil;
  }
  _characterCollection = kCTIdentityMappingCharacterCollection;
  _characterIdentifier = cid;
  // FIXME: need to look up in the character collections's database
  _glpyhName = @"";
  _baseString = [baseString retain];

  return self;
}
- (void)dealloc
{
  [_baseString release];
  [_glpyhName release];
  [super dealloc];
}
- (CFStringRef) baseString
{
  return _baseString;
}
- (CFStringRef) glyphName
{
  return _glpyhName;
}
- (CGFontIndex) characterIdentifier
{
  return _characterIdentifier;
}
- (CTCharacterCollection) characterCollection
{
  return _characterCollection;
}

@end


/* Functions */

CTGlyphInfoRef CTGlyphInfoCreateWithGlyphName(
	CFStringRef glyphName,
	CTFontRef font,
	CFStringRef baseString)
{
  return [[CTGlyphInfo alloc] initWithGlyphName: glyphName
                                           font: font
                                     baseString: baseString];
}

CTGlyphInfoRef CTGlyphInfoCreateWithGlyph(
	CGGlyph glyph,
	CTFontRef font,
	CFStringRef baseString)
{
  return [[CTGlyphInfo alloc] initWithGlyph: glyph
                                       font: font
                                 baseString: baseString];
}

CTGlyphInfoRef CTGlyphInfoCreateWithCharacterIdentifier(
	CGFontIndex cid,
	CTCharacterCollection collection,
	CFStringRef baseString)
{
  return [[CTGlyphInfo alloc] initWithCharacterIdentifier: cid
                                      characterCollection: collection
                                               baseString: baseString];
}

CFStringRef CTGlyphInfoGetGlyphName(CTGlyphInfoRef glyphInfo)
{
  return [glyphInfo glyphName];
}

CGFontIndex CTGlyphInfoGetCharacterIdentifier(CTGlyphInfoRef glyphInfo)
{
  return [glyphInfo characterIdentifier];
}

CTCharacterCollection CTGlyphInfoGetCharacterCollection(CTGlyphInfoRef glyphInfo)
{
  return [glyphInfo characterCollection];
}

CFTypeID CTGlyphInfoGetTypeID()
{
  return (CFTypeID)[CTGlyphInfo class];
}

