/** <title>NSLayoutManager</title>

   <abstract>The text layout manager class</abstract>

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author: Jonathan Gapen <jagapen@smithlab.chem.wisc.edu>
   Date: July 1999
   Author:  Michael Hanni <mhanni@sprintmail.com>
   Date: August 1999
   Author: Richard Frith-Macdonald <rfm@gnu.org>
   Date: January 2001

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/
#include <AppKit/NSLayoutManager.h>
#include <AppKit/NSParagraphStyle.h>
#include "GSSimpleLayoutManager.h"

#include <AppKit/NSImage.h>
#include <AppKit/NSWindow.h>
#include <Foundation/NSException.h>

#define	USE_GLYPHS	0
#define	ALL_CHECKS	0

#define	BOTH	(NSTextStorageEditedCharacters | NSTextStorageEditedAttributes)

#if	ALL_CHECKS
static void missmatch(SEL s)
{
  NSLog(@"Missmatch in %@", NSStringFromSelector(s));
}
#endif

/*
 * Glyph attributes known to the layout manager.
 */
typedef enum {
  GSGlyphDrawsOutsideLineFragment,
  GSGlyphIsNotShown,
  GSGlyphGeneration,
  GSGlyphInscription,
} GSGlyphAttributes;

typedef	union {
  /*
   * A structure to hold information about a glyph in the glyph stream
   * NB. This structure should be no more than 64 bits, so it can fit
   * in as a GSIArray element of the same size as the NSRange structure
   * used to hold gap information.
   */
  struct {
    unsigned offset:24;			// characters in from start of chunk
    unsigned drawsOutsideLineFragment:1;	// glyph bigger than fragment?
    unsigned isNotShown:1;		// glyph invisible (space, tab etc)
    unsigned inscription:3;		// NSGlyphInscription info
    unsigned generation:3;		// Other attributes
    NSGlyph  glyph;			// The glyph itsself
  } g;
  NSRange	r;			// A range of invalidated glyphs (gap)
} GSGlyphAttrs;

#define	gRange(A)		((A).ext.r)
#define	gGlyph(A)		((A).ext.g.glyph)
#define	gOffset(A)		((A).ext.g.offset)
#define	gDrawsOutside(A)	((A).ext.g.drawsOutsideLineFragment)
#define	gIsNotShown(A)		((A).ext.g.isNotShown)
#define	gInscription(A)		((A).ext.g.inscription)
#define	gGeneration(A)		((A).ext.g.generation)



/*
 * We need a fast array that can store -
 * pointers, objects, glyphs (long) and attributes.
 */
#define GSI_ARRAY_TYPES		GSUNION_PTR|GSUNION_OBJ|GSUNION_INT|GSUNION_LONG
#define	GSI_ARRAY_TYPE		GSGlyphAttrs

/*
 * We handle retain/release explicitly, so we can use GSIArrays to hold
 * non-object values.
 */
#define GSI_ARRAY_NO_RELEASE	1
#define GSI_ARRAY_NO_RETAIN	1

#ifdef GSIArray
#undef GSIArray
#endif
#include <base/GSIArray.h>

/*
 * The glyph attributes within a chunk must be ordered by their offset fields,
 * so we can use a binary search to find the item for a particular offset.
 */
static NSComparisonResult
offsetSort(GSIArrayItem i0, GSIArrayItem i1)
{
  if (gOffset(i0) < gOffset(i1))
    return NSOrderedAscending;
  else if (gOffset(i0) > gOffset(i1))
    return NSOrderedDescending;
  else
    return NSOrderedSame;
}




/*
 * Glyph management implementation notes (January 2001)
 * Author - Richard Frith-Macdonald <rfm@gnu.org>
 *
 * An NSLayoutManager object maintains a 'glyph stream' which contains the
 * actual symbols to be displayed in text.  This glyph stream is conceptually
 * an array of glyphs and certain attributes.
 *
 * Each glyph has an associated index of the corresponding character in the
 * text storage object.  Since more than one character may map to a single
 * glyphs, the character index for a glyph is the index of the first
 * character corresponing to the glyph.  Since more than one glyph may map
 * on to the same character, adjacent glyphs in the glyph stream may have
 * the same character index.
 *
 * Other attributes of a glyph include flags to say whether the glyph is to
 * be drawn or not, and how it should be layed out with respect to the
 * preceeding glyph in the stream (allowing for overstrike etc).
 *
 * Since the state of the text storage object may change, glyphs may be
 * deleted from the stream from time to time, leaving a situation where
 * not all characters in the text storage have corresponding glyphs in
 * the glyph stream.  This state is called a 'gap'.  We maintain an array
 * of the locations of the gaps in the glyph stream.  When we attempt to
 * access a glyph, we must generate new glyphs from the text storage to
 * fill any gaps in the glyphs stream and insert them into the stream.
 *
 *
 * The glyph stream is actually implemented as an array of 'chunks' -
 * where a chunk contains an array of glyphs, and array of the glyph
 * attributes, and the glyph and character indices of the first glyph
 * in the chunk.  The remaining character/glyph indices are calculated
 * as offsets from the first glyph in the chunk.
 *
 * This implementation is used for speed of manipulation of very large
 * documents - modifications to a single chunk may have their effects
 * to some degree localised to that chunk.
 *
 * Invariants ...
 * 1. The glyph stream is a continuous array of glyphs ranging from 0 up.
 * 2. The character index of a glyph in the glyph stream is greater than
 *    or equal to that of the glyph that preceeds it.
 * 3. The gap array contains ranges of invalidated glyphs in numeric order
 *    and where no index exceeds the length of the glyph stream.
 * 4. The glyph stream consists of at least one chunk whose glyph index
 *    is zero.
 */


/*
 * Structure to handle the storage of the glyph stream.
 * This is done as an array of chunks.
 * Each chunk contains an array of glyphs and corresponding attributes.
 */
typedef struct {
  unsigned	charIndex;	// Index of character at start of chunk
  unsigned	glyphIndex;	// Index of glyph at start of chunk
  GSIArray_t	glyphs;		// Array of glyphs and their attributes.
} GSGlyphChunk;

/*
 * The glyph chunks must be ordered by their charIndex offset fields,
 * so we can use a binary search to find the item for a particular
 * character index.
 */
static NSComparisonResult
charIndexSort(GSIArrayItem i0, GSIArrayItem i1)
{
  if (((GSGlyphChunk*)(i0.ptr))->charIndex
    < (((GSGlyphChunk*)(i1.ptr))->charIndex))
    return NSOrderedAscending;
  else if (((GSGlyphChunk*)(i0.ptr))->charIndex
    > (((GSGlyphChunk*)(i1.ptr))->charIndex))
    return NSOrderedDescending;
  else
    return NSOrderedSame;
}

/*
 * The glyph chunks must be ordered by their glyphIndex offset fields,
 * so we can use a binary search to find the item for a particular
 * glyph index.
 */
static NSComparisonResult
glyphIndexSort(GSIArrayItem i0, GSIArrayItem i1)
{
  if (((GSGlyphChunk*)(i0.ptr))->glyphIndex
    < (((GSGlyphChunk*)(i1.ptr))->glyphIndex))
    return NSOrderedAscending;
  else if (((GSGlyphChunk*)(i0.ptr))->glyphIndex
    > (((GSGlyphChunk*)(i1.ptr))->glyphIndex))
    return NSOrderedDescending;
  else
    return NSOrderedSame;
}

/*
 * Glyph management functions.
 */
static GSGlyphChunk*
GSCreateGlyphChunk(unsigned glyphIndex, unsigned charIndex)
{
  GSGlyphChunk	*chunk;

  chunk = NSZoneMalloc(NSDefaultMallocZone(), sizeof(GSGlyphChunk));
  chunk->charIndex = charIndex;
  chunk->glyphIndex = glyphIndex;
  GSIArrayInitWithZoneAndCapacity(&chunk->glyphs, NSDefaultMallocZone(), 8);
  return chunk;
}

static void
GSDestroyGlyphChunk(GSGlyphChunk *chunk)
{
  GSIArrayClear(&chunk->glyphs);
  NSZoneFree(NSDefaultMallocZone(), chunk);
}

static unsigned
GSChunkForCharIndex(GSIArray chunks, unsigned charIndex)
{
  unsigned	pos;
  GSGlyphChunk	tmp;

  tmp.charIndex = charIndex;
  pos = GSIArrayInsertionPosition(chunks, (GSIArrayItem)(void*)&tmp,
    charIndexSort); 
  /*
   * pos is the index of the next chunk *after* the one we want,
   * unless we want something in the very first chunk.
   */
  if (pos > 0)
    {
      pos--;
    }
  return pos;
}

static unsigned
GSChunkForGlyphIndex(GSIArray chunks, unsigned glyphIndex)
{
  unsigned	pos;
  GSGlyphChunk	tmp;

  tmp.glyphIndex = glyphIndex;
  pos = GSIArrayInsertionPosition(chunks, (GSIArrayItem)(void*)&tmp,
    glyphIndexSort); 
  /*
   * pos is the index of the next chunk *after* the one we want,
   * unless we want something in the very first chunk.
   */
  NSCAssert(pos > 0, @"No glyph chunks present"); 
  if (pos > 0)
    {
      pos--;
    }
  return pos;
}



/*
 * Medium level functions for accessing and manipulating glyphs.
 */

typedef struct {
  @defs(NSLayoutManager)
} *lmDefs;

#define	glyphChunks	((GSIArray)_glyphData)

#define	_chunks		((GSIArray)(((lmDefs)lm)->_glyphData))
#define	_chunk		((GSGlyphChunk*)(((lmDefs)lm)->_currentGlyphs))
#define	_gindex		(((lmDefs)lm)->_glyphIndex)
#define	_cindex		(((lmDefs)lm)->_chunkIndex)
#define	_offset		(((lmDefs)lm)->_glyphOffset)
#define	_gaps		((GSIArray)(((lmDefs)lm)->_glyphGaps))


static BOOL		_Back(NSLayoutManager *lm);
static unsigned		_CharEnd(NSLayoutManager *lm);
static unsigned		_CharIndex(NSLayoutManager *lm);
static unsigned		_GlyphEnd(NSLayoutManager *lm);
static unsigned		_GlyphIndex(NSLayoutManager *lm);
static GSIArrayItem	*_Info(NSLayoutManager *lm);
static BOOL		_JumpToChar(NSLayoutManager *lm, unsigned charIndex);
static BOOL		_JumpToGlyph(NSLayoutManager *lm, unsigned glyphIndex);
static BOOL		_Step(NSLayoutManager *lm);


/*
 * Move 'current' glyph index back one place in glyph stream.
 * return NO on failure (start of stream).
 */
static inline BOOL
_Back(NSLayoutManager *lm)
{
  if (_offset > 0)
    {
      _offset--;
      _gindex--;
      return YES;
    }
  else if (_cindex > 0)
    {
      _cindex--;
      _chunk = (GSGlyphChunk*)GSIArrayItemAtIndex(_chunks, _cindex).ptr;
      _offset = GSIArrayCount(&_chunk->glyphs) - 1;
      _gindex--;
      return YES;
    }
  else
    {
      return NO;
    }
}

/*
 * Move 'current' glyph index forward one place in glyph stream.
 * return NO on failure (end of stream).
 */
static inline BOOL
_Step(NSLayoutManager *lm)
{
  if (_offset < GSIArrayCount(&_chunk->glyphs) - 1)
    {
      _offset++;
      _gindex++;
      return YES;
    }
  else
    {
      if (_cindex < GSIArrayCount(_chunks) - 1)
	{
	  _cindex++;
	  _chunk = (GSGlyphChunk*)GSIArrayItemAtIndex(_chunks, _cindex).ptr;
	  _offset = 0;
	  _gindex++;
	  return YES;
	}
      else
	{
	  return NO;
	}
    }
}

/*
 * Adjust the character indices for all the glyphs from the specified
 * location onwards. Leave the current glyphs set to the 'from' location.
 */
static void
_Adjust(NSLayoutManager *lm, unsigned from, int lengthChange)
{
  if (_JumpToGlyph(lm, from) == YES)
    {
      GSGlyphChunk	*chunk = _chunk;
      unsigned		index = _cindex;
      unsigned		offset = _offset;

      /*
       * Adjust character offsets for all glyphs in this chunk.
       */
      if (offset > 0)
	{
	  while (offset < GSIArrayCount(&chunk->glyphs))
	    {
	      gOffset(GSIArrayItems(&chunk->glyphs)[offset]) += lengthChange;
	      offset--;
	    }
	  index++;
	}
      
      /*
       * Now adjust character offsets for remaining chunks.
       */
      while (index < GSIArrayCount(_chunks))
	{
	  chunk = (GSGlyphChunk*)GSIArrayItemAtIndex(_chunks, index).ptr;
	  index++;
	  chunk->charIndex += lengthChange;
	}
    }
}

/*
 * Return the index of the character immediately beyond the last
 * generated glyph.
 */
static inline unsigned
_CharEnd(NSLayoutManager *lm)
{
  unsigned	i;

  i =  GSIArrayCount(_chunks);
  while (i-- > 0)
    {
      GSGlyphChunk	*c;
      unsigned		j;

      c = (GSGlyphChunk*)GSIArrayItemAtIndex(_chunks, i).ptr;
      j = GSIArrayCount(&c->glyphs);
      if (j-- > 0)
	{
          return c->charIndex + gOffset(GSIArrayItemAtIndex(&c->glyphs, j)) + 1;
	}
    }
  return 0;
}

/*
 * Return the glyph index immediately beyond the last generated glyph.
 */
static inline unsigned
_GlyphEnd(NSLayoutManager *lm)
{
  unsigned	i;

  i =  GSIArrayCount(_chunks);
  while (i-- > 0)
    {
      GSGlyphChunk	*c;
      unsigned		j;

      c = (GSGlyphChunk*)GSIArrayItemAtIndex(_chunks, i).ptr;
      j = GSIArrayCount(&c->glyphs);
      if (j > 0)
	{
          return c->glyphIndex + j;
	}
    }
  return 0;
}

/*
 * return the character index of the current glyph.
 */
static inline unsigned
_CharIndex(NSLayoutManager *lm)
{
  return _chunk->charIndex
    + gOffset(GSIArrayItemAtIndex(&_chunk->glyphs, _offset));
}

/*
 * return the index of the current glyph.
 */
static inline unsigned
_GlyphIndex(NSLayoutManager *lm)
{
  return _chunk->glyphIndex + _offset;
}

/*
 * Return the current glyph and attributes
 */
static GSIArrayItem *
_Info(NSLayoutManager *lm)
{
  return GSIArrayItems(&_chunk->glyphs) + _offset;
}

/*
 * Locate the first glyph corresponding to the specified character index
 * and make it the current glyph.
 */
static BOOL
_JumpToChar(NSLayoutManager *lm, unsigned charIndex)
{
  GSIArrayItem	tmp;
  GSGlyphChunk	*c;
  unsigned	i;
  unsigned	o;
  unsigned	co;

  i = GSChunkForCharIndex(_chunks, charIndex);
  c = (GSGlyphChunk*)GSIArrayItemAtIndex(_chunks, i).ptr;
  gOffset(tmp) = charIndex - c->charIndex;
  o = GSIArrayInsertionPosition(&c->glyphs, tmp, offsetSort); 
  if (o == 0)
    {
      return NO;	// Insertion position not found.
    }
  o--;

  /*
   * Check the character index of this glyph to see if it matches the
   * character index we were asked for.  If it doesn't we have probably
   * failed to find a glyph matching the character.
   */
  co = gOffset(GSIArrayItemAtIndex(&c->glyphs, o));
  if (co + c->charIndex != charIndex)
    {
      if ([((lmDefs)lm)->_textStorage length] > charIndex)
	{
	  NSRange	r;

	  r = [[((lmDefs)lm)->_textStorage string]
	    rangeOfComposedCharacterSequenceAtIndex: charIndex];
	  if (r.length > 0 && r.location == co + c->charIndex)
	    {
	      /*
	       * The requested character is part of a composed character
	       * sequence whose first character maps on to the glyph we found.
	       */
	      _chunk = c;
	      _cindex = i;
	      _offset = o;
	      _gindex = c->glyphIndex + o;
	      return YES;
	    }
	}
      return NO;
    }

  /*
   * Locate the *first* glyph for this character index...
   */
  while (o > 0 && gOffset(GSIArrayItemAtIndex(&c->glyphs, o-1)) == co)
    {
      o--;
    }
  _chunk = c;
  _cindex = i;
  _offset = o;
  _gindex = c->glyphIndex + o;
  return YES;
}

/*
 * Make the specified glyph index the current glyph
 */
static BOOL
_JumpToGlyph(NSLayoutManager *lm, unsigned glyphIndex)
{
  GSGlyphChunk	*c;
  unsigned	i;
  unsigned	o;

  /*
   * Optimise for glyph index zero ... easy to find.
   */
  if (glyphIndex == 0)
    {
      c = (GSGlyphChunk*)GSIArrayItemAtIndex(_chunks, 0).ptr;
      if (GSIArrayCount(&c->glyphs) > 0)
	{
	  _chunk = c;
	  _cindex = 0;
	  _offset = 0;
	  _gindex = 0;
	  return YES;
	}
      return NO;
    }

  i = GSChunkForGlyphIndex(_chunks, glyphIndex);
  c = (GSGlyphChunk*)GSIArrayItemAtIndex(_chunks, i).ptr;
  o = glyphIndex - c->glyphIndex;
  if (o < GSIArrayCount(&c->glyphs))
    {
      _chunk = c;
      _cindex = i;
      _offset = o;
      _gindex = glyphIndex;
      return YES;
    }
  else
    {
      return NO;
    }
}

#if	USE_GLYPHS
static void
_Sane(NSLayoutManager *lm)
{
  unsigned	lastGlyph = 0;
  unsigned	lastChar = 0;
  unsigned	pos;

  /*
   * Check gaps.
   */
  for (pos = 0; pos < GSIArrayCount(_gaps); pos++)
    {
      unsigned val = GSIArrayItemAtIndex(_gaps, pos).ulng;

      NSCAssert(val > lastGlyph || (val == 0 && pos == 0),
	NSInternalInconsistencyException);
      lastGlyph = val;
    }
  
  NSCAssert(GSIArrayCount(_chunks) > 0, NSInternalInconsistencyException);
  lastGlyph = 0;
  for (pos = 0; pos < GSIArrayCount(_chunks); pos++)
    {
      GSGlyphChunk	*chunk;
      unsigned		count;

      chunk = (GSGlyphChunk*)GSIArrayItemAtIndex(_chunks, pos).ptr;
      NSCAssert(chunk->glyphIndex == (pos == 0 ? 0 : lastGlyph+1),
	NSInternalInconsistencyException);
      NSCAssert(chunk->charIndex >= lastChar, NSInternalInconsistencyException);
      count = GSIArrayCount(&chunk->glyphs);
      if (count > 0)
	{
	  GSIArrayItem	a;
	  unsigned	i;

	  for (i = 0; i < count; i++)
	    {
	      a = GSIArrayItemAtIndex(&chunk->glyphs, i);
	      NSCAssert(chunk->charIndex + gOffset(a) >= lastChar,
		NSInternalInconsistencyException);
	      lastChar = chunk->charIndex + gOffset(a);
	    }
	  lastGlyph = chunk->glyphIndex + count - 1;
	}
    }
}
static void
_GLog(NSLayoutManager *lm, SEL _cmd)
{
#if	ALL_CHECKS
  unsigned	pos;

  /*
   * Check gaps.
   */
  fprintf(stderr, "%s, %x\ngaps (%u) - ",
    _cmd ? sel_get_name(_cmd) : "", (unsigned)lm, GSIArrayCount(_gaps));
  for (pos = 0; pos < GSIArrayCount(_gaps); pos++)
    {
      unsigned val = GSIArrayItemAtIndex(_gaps, pos).ulng;

      fprintf(stderr, " %u", val);
    }
  fprintf(stderr, "\n");
  
  fprintf(stderr, "chunks (%u) -\n", GSIArrayCount(_chunks));
  for (pos = 0; pos < GSIArrayCount(_chunks); pos++)
    {
      GSGlyphChunk	*chunk;
      unsigned		count;

      chunk = (GSGlyphChunk*)GSIArrayItemAtIndex(_chunks, pos).ptr;
      count = GSIArrayCount(&chunk->glyphs);
      fprintf(stderr, "  glyphs (%u) - gi %d, ci %d\n",
        count, chunk->glyphIndex, chunk->charIndex);
      if (count > 0)
	{
	  GSIArrayItem	a;
	  unsigned	i;

	  for (i = 0; i < count; i++)
	    {
	      a = GSIArrayItemAtIndex(&chunk->glyphs, i);
	      fprintf(stderr, "     %4d %4d %c",
		chunk->glyphIndex + i,
	     	chunk->charIndex + gOffset(a),
		(char)GSIArrayItemAtIndex(&chunk->glyphs, i).ulng);
	    }
	  fprintf(stderr, "\n");
	}
    }
#endif
}
#else
static inline void
_Sane(NSLayoutManager *lm)
{
}
static inline void
_GLog(NSLayoutManager *lm, SEL _cmd)
{
}
#endif



@interface NSLayoutManager (Private)

- (void) _doLayout;
- (int) _rebuildLayoutForTextContainer: (NSTextContainer*)aContainer
		  startingAtGlyphIndex: (int)glyphIndex;

@end


/**
 * <p>
 * A layout manager handles layout and glyph management for a text
 * storage.  A glyph is a symbol draewn to a display, and while
 * there is usually a one to one correspondence between glyphs
 * and characters in the text storage, that is no always the case.</p>
 * <p>
 * Sometimes a group of characters (a unicode composed character sequence)
 * can represent a single glyph, sometimes a single unicode character is
 * represented by multiple glyphs.</p>
 * <p>
 * eg. The text storage may contain the unichar o-umlaut and
 * the glyph stream could contain the two glyphs "o" and umlaut.
 * In this case, we would have two glyphs, with different glyph indexes,
 * both corresponding to a single character index.</p>
 */
@implementation NSLayoutManager

+ (id) allocWithZone: (NSZone*)z
{
  // Return a simple layout manager as this is the only working subclass
  if (self == [NSLayoutManager class])
    {
      return [GSSimpleLayoutManager allocWithZone: z];
    }
  else
    {
      return NSAllocateObject (self, 0, z);
    }
}

/** <init />
 * Sets up this instance. We should in future find a glyph generator and a
 * typesetter to use with glyphs management, but for now we just set up
 * the glyph storage.
 */
- (id) init
{
  self = [super init];

  if (self != nil)
    {
      GSIArray	a;

      _backgroundLayout = YES;
      _delegate = nil;
      _textContainers = [[NSMutableArray alloc] initWithCapacity: 2];

      /*
       * Initialise glyph storage and ivars to contain 'current' glyph
       * location information.
       */
      a = NSZoneMalloc(NSDefaultMallocZone(), sizeof(GSIArray_t));
      GSIArrayInitWithZoneAndCapacity(a, NSDefaultMallocZone(), 8);
      _glyphData = a;
      _currentGlyphs = GSCreateGlyphChunk(0, 0);
      GSIArrayInsertItem(glyphChunks, (GSIArrayItem)_currentGlyphs, 0);
      _chunkIndex = 0;
      _glyphOffset = 0;
      
      /*
       * Initialise storage of gaps in the glyph stream.
       * Initially there are no gaps in the stream.
       */
      a = NSZoneMalloc(NSDefaultMallocZone(), sizeof(GSIArray_t));
      GSIArrayInitWithZoneAndCapacity(a, NSDefaultMallocZone(), 8);
      _glyphGaps = a;
    }

  return self;
}

- (void) dealloc
{
  unsigned	i;

  /* We check that the _glyphData and _glyphGaps are not NULL so that
   * we can dealloc an object which has not been -init (some
   * regression tests need it).
   */

  /*
   * Release all glyph chunk information.
   */
  if (_glyphData != NULL)
    {
      i = GSIArrayCount(glyphChunks);
      while (i-- > 0)
	{
	  GSGlyphChunk	*chunk;
	  
	  chunk = (GSGlyphChunk*)(GSIArrayItemAtIndex(glyphChunks, i).ptr);
	  GSDestroyGlyphChunk(chunk);
	}
      GSIArrayEmpty(glyphChunks);
      NSZoneFree(NSDefaultMallocZone(), _glyphData);
    }

  if (_glyphGaps != NULL)
    {
      GSIArrayEmpty((GSIArray)_glyphGaps);
      NSZoneFree(NSDefaultMallocZone(), _glyphGaps);
    }
  
  RELEASE (_textContainers);

  [super dealloc];
}

/**
 * Sets the text storage for the layout manager.
 * Use -replaceTextStorage: instead as a rule. - this method is really
 * more for internal use by the text system.
 * Invalidates the entire layout (should it??)
 */
- (void) setTextStorage: (NSTextStorage*)aTextStorage
{
  unsigned int	length;
  NSRange	aRange;

  /*
   * Mark the entire existing text storage as invalid.
   */
  length = [_textStorage length];
  aRange = NSMakeRange(0, length);
  [self textStorage: _textStorage
	     edited: BOTH
	      range: aRange
     changeInLength: -length 
   invalidatedRange: aRange];

  /*
   * Make a note of the new text storage object, but don't retain it.
   * The text storage is owning us - it retains us.
   */
  _textStorage = aTextStorage;

  length = [aTextStorage length];
  aRange = NSMakeRange (0, length);
  // force complete re - layout
  [self textStorage: aTextStorage
	     edited: BOTH
	      range: aRange
     changeInLength: length 
   invalidatedRange: aRange];
}

/**
 * Returns the text storage for this layout manager.
 */
- (NSTextStorage*) textStorage
{
  return _textStorage;
}

/**
 * Replaces the test storage with a new one.<br />
 * Takes care (since layout managers are owned by text storages)
 * not to get self deallocated.
 */
- (void) replaceTextStorage: (NSTextStorage*)newTextStorage
{
  NSArray		*layoutManagers = [_textStorage layoutManagers];
  NSEnumerator		*enumerator = [layoutManagers objectEnumerator];
  NSLayoutManager	*object;

  /* Remove layout managers from old NSTextStorage object and add them to the
     new one.  NSTextStorage's addLayoutManager invokes NSLayoutManager's
     setTextStorage method automatically, and that includes self.  */

  while ((object = (NSLayoutManager*)[enumerator nextObject]) != nil)
    {
      RETAIN(object);
      [_textStorage removeLayoutManager: object];
      [newTextStorage addLayoutManager: object];
      RELEASE(object);
    }
}

/**
 * Return the text containers
 */
- (NSArray*) textContainers
{
  return _textContainers;
}

/**
 * Adds a container to the layout manager.
 */
- (void) addTextContainer: (NSTextContainer*)obj
{
  if ([_textContainers indexOfObjectIdenticalTo: obj] == NSNotFound)
    {
      int i;
      
      [_textContainers addObject: obj];
      [obj setLayoutManager: self];
      // FIXME: Invalidate layout beyond previous last container
      _textContainersCount++;
      /* NB: We do not retain this here !  It's already retained in the
	 array. */
      _firstTextView = [(NSTextContainer *)[_textContainers objectAtIndex: 0] 
					   textView];
      for (i = 0; i < _textContainersCount; i++)
	{
	  NSTextView *tv = [[_textContainers objectAtIndex: i] textView]; 
	  
	  [tv _updateMultipleTextViews];
	}
    }
}

/**
 * Inserts a new text container at index.
 */
- (void) insertTextContainer: (NSTextContainer*)aTextContainer
		     atIndex: (unsigned)index
{
  int i;

  [_textContainers insertObject: aTextContainer  atIndex: index];
  _textContainersCount++;
  _firstTextView = [(NSTextContainer *)[_textContainers objectAtIndex: 0] 
				       textView];
  for (i = 0; i < _textContainersCount; i++)
    {
      NSTextView *tv = [[_textContainers objectAtIndex: i] textView]; 
	
      [tv _updateMultipleTextViews];
    }
  // FIXME: Invalidate layout from thsi container onwards
}

/**
 * Removes the text container at index.
 */
- (void) removeTextContainerAtIndex: (unsigned)index
{
  int i;

  // FIXME  invalidate from thsi point onwards.
  [_textContainers removeObjectAtIndex: index];
  _textContainersCount--;
  if (_textContainersCount > 0)
    {
      _firstTextView = [(NSTextContainer *)[_textContainers objectAtIndex: 0] 
					   textView];  
    }
  else
    {
      _firstTextView = nil;
    }

  for (i = 0; i < _textContainersCount; i++)
    {
      NSTextView *tv = [[_textContainers objectAtIndex: i] textView]; 
      
      [tv _updateMultipleTextViews];
    }
}

/**
 * This determines the glyph range corresponding to aRange and
 * marks the glyphs as invalid.  It adjusts the character locations
 * of all glyphs beyond this by lengthChange.  It returns the
 * actual character range corresponding to the invalidated glyphs
 * if actualRange is non-nul.
 */
- (void) invalidateGlyphsForCharacterRange: (NSRange)aRange
			    changeInLength: (int)lengthChange
		      actualCharacterRange: (NSRange*)actualRange
{
  GSIArrayItem	item;
  NSRange	cRange;
  NSRange	gRange;
  unsigned	count;

_GLog(self,_cmd);
  if (actualRange != 0)
    {
      *actualRange = cRange;
    }
  if (aRange.length == 0)
    {
      return;	// Empty ... nothing to do.
    }
  if (aRange.location >= _CharEnd(self))
    {
      return;	// No glyphs generated for that character index.
    }

  gRange = [self glyphRangeForCharacterRange: aRange
			actualCharacterRange: &cRange];
  if (actualRange != 0)
    {
      *actualRange = cRange;
    }
  if (gRange.length == 0)
    {
      return;		// Nothing to do.
    }

  /*
   * Now adjust character locations for glyphs if necessary.
   */
  _Adjust(self, gRange.location, lengthChange);

  /*
   * Now adjust invalidated gaps in the glyph stream.
   */
  count = GSIArrayCount((GSIArray)_glyphGaps);
  if (count == 0)
    {
      gRange(item) = gRange;
      GSIArrayInsertItem((GSIArray)_glyphGaps, item, 0);
    }
  else
    {
      unsigned	pos;

      for (pos = 0; pos < count; pos++)
	{
	  NSRange	val;
	  NSRange	tmp;

	  val = gRange(GSIArrayItemAtIndex((GSIArray)_glyphGaps, pos));

	  /*
	   * If there is no overlap, we must either insert the new gap
	   * before the found one, or continue to look at the next gap.
	   */
	  tmp = NSIntersectionRange(gRange, val);
	  if (tmp.length == 0)
	    {
	      if (gRange.location < val.location)
		{
		  gRange(item) = gRange;
		  GSIArrayInsertItem((GSIArray)_glyphGaps, item, pos);
		  break;
		}
	      continue;
	    }

	  /*
	   * If the new gap is entirely within an existing one, we
	   * don't need to do anything.
	   */
	  if (val.location <= gRange.location
	    && NSMaxRange(val) >= NSMaxRange(gRange))
	    {
	      break;
	    }

	  /*
	   * Update the existing gap to be a union with our new gap.
	   */
	  gRange = NSUnionRange(gRange, val);
	  gRange(item) = gRange;
	  GSIArraySetItemAtIndex((GSIArray)_glyphGaps, item, pos);

	  while (pos + 1 < count)
	    {
	      val = gRange(GSIArrayItemAtIndex((GSIArray)_glyphGaps, pos + 1));

	      /*
	       * If there is no overlap with the next gap, we have
	       * nothing more to do.
	       */
	      tmp = NSIntersectionRange(gRange, val);
	      if (tmp.length == 0)
		{
		  break;
		}

	      /*
	       * If the next gap extends beyond our gap, we can remove
	       * the current one and replace the next one with a union.
	       */
	      if (val.location <= gRange.location
		&& NSMaxRange(val) >= NSMaxRange(gRange))
		{
		  GSIArrayRemoveItemsFromIndex((GSIArray)_glyphGaps, pos);
		  count--;
		  gRange(item) = NSUnionRange(gRange, val);
		  GSIArraySetItemAtIndex((GSIArray)_glyphGaps, item, pos);
		  break;
		}

	      /*
	       * The next gap is contained within our gap, so we can
	       * simply remove it. Then loop to examine the one beyond
	       */
	      GSIArrayRemoveItemsFromIndex((GSIArray)_glyphGaps, pos + 1);
	      count--;
	    }
	}
    }

// FIXME - should invalidate the character range ... but what does that mean?
_GLog(self,_cmd);
_Sane(self);
}

/**
 * This invalidates glyph positions for all glyphs corresponding
 * to the specified character range.<br />
 * If flag is YES then the layout information needs to be redone from
 * scratch, but if it's NO, the layout manager may try to optimise
 * layout from the old information.<br />
 * If actualRange is non-nul, returns the actual range invalidated.
 */
- (void) invalidateLayoutForCharacterRange: (NSRange)aRange
				    isSoft: (BOOL)flag
		      actualCharacterRange: (NSRange*)actualRange
{
  [self _doLayout];
}

/**
 * Causes redisplay of aRange, but does not lose the alyout information.
 */
- (void) invalidateDisplayForCharacterRange: (NSRange)aRange
{
/* FIXME */
}

/**
 * Causes redisplay of aRange, but does not lose the alyout information.
 */
- (void) invalidateDisplayForGlyphRange: (NSRange)aRange
{
/* FIXME */
}

/**
 * Invalidates the layout of all glyphs in aContainer and all containers
 * following it.
 */
- (void) textContainerChangedGeometry: (NSTextContainer*)aContainer
{
  // find the first character in that text container
  NSRange aRange = [self glyphRangeForTextContainer: aContainer];
  unsigned first = aRange.location;

  // invalidate the layout from here on
  [self invalidateLayoutForCharacterRange: 
	  NSMakeRange(first, [_textStorage length] - first)
	isSoft: NO
	actualCharacterRange: NULL];
}

/**
 * Notifies the layout manager that one of its text containers has
 * changed its view and an update of the display is needed.
 */
- (void) textContainerChangedTextView: (NSTextContainer*)aContainer
{
  unsigned index;
  
  index = [_textContainers indexOfObjectIdenticalTo: aContainer];
  
  if (index != NSNotFound)
    {
      if (index == 0)
	{
	  _firstTextView = [aContainer textView];
	  
	  /* It only makes sense to update the other text views if we
             have more than one text container */
	  if (_textContainersCount > 1)
	    {
	      /* It's the first text view.  Need to update everything. */
	      int i;

	      for (i = 0; i < _textContainersCount; i++)
		{
		  NSTextView *tv;
		  
		  tv = [[_textContainers objectAtIndex: i] textView]; 
		  [tv _updateMultipleTextViews];
		}
	    }
	}
    }
}

/**
 * This method is used to handle an editing change to aTextStorage.
 * The mask value indicates whether characters or attribuytes or both
 * have changed.<br />
 * If characters have not changed, the lengthChange argument is ignored.<br/>
 * The newCharRange is the effected range currently in the storage, while
 * invalidatedRange is the original range effected.
 */
- (void) textStorage: (NSTextStorage*)aTextStorage
	      edited: (unsigned)mask
	       range: (NSRange)newCharRange
      changeInLength: (int)lengthChange
    invalidatedRange: (NSRange)invalidatedRange
{
/*
  NSLog(@"NSLayoutManager was just notified that a change in the text
storage occured.");
  NSLog(@"range: (%d, %d) changeInLength: %d invalidatedRange (%d, %d)",
newCharRange.location, newCharRange.length, lengthChange, invalidatedRange.location,
invalidatedRange.length);
*/
  int		delta = 0;
  unsigned int	last;

_GLog(self,_cmd);
  if (mask & NSTextStorageEditedCharacters)
    {
      delta = lengthChange;
    }
  else if (mask == 0)
    {
      return;		// No changes to make.
    }
  last = NSMaxRange (invalidatedRange);

  // hard invalidation occures here.
  [self invalidateGlyphsForCharacterRange: newCharRange 
			   changeInLength: delta
		     actualCharacterRange: NULL];
  [self invalidateLayoutForCharacterRange: invalidatedRange 
				   isSoft: NO
		     actualCharacterRange: NULL];

  // the following range is soft invalidated
  newCharRange = NSMakeRange (last, [_textStorage length] - last);
  [self invalidateLayoutForCharacterRange: newCharRange
				   isSoft: YES
		     actualCharacterRange: NULL];
_GLog(self,_cmd);
}

/**
 * Sets flag to say if text should get laid out in
 * the background when the run lopp is idle.
 */
- (void) setBackgroundLayoutEnabled: (BOOL)flag
{
  _backgroundLayout = flag;
}

/**
 * Returns flag to say if text should get laid out in
 * the background when the run lopp is idle.
 */
- (BOOL) backgroundLayoutEnabled
{
  return _backgroundLayout;
}

/**
 * Used by the internal glyph generation system to insert aGlyph into
 * the glyph stream athe the specified glyphIndex and charIndex.<br />
 * Invariants ...<br />
 * a)  Glyph chunks are ordered sequentially from zero by character index.<br />
 * b)  Glyph chunks are ordered sequentially from zero by glyph index.<br />
 * c)  Adjacent glyphs may share a character index.<br />
 */
- (void) insertGlyph: (NSGlyph)aGlyph
	atGlyphIndex: (unsigned)glyphIndex
      characterIndex: (unsigned)charIndex
{
  unsigned		chunkCount = GSIArrayCount(glyphChunks);
  GSIArrayItem		info = { 0 };
  GSGlyphChunk		*chunk;
  unsigned		pos;

_GLog(self,_cmd);
  if (glyphIndex == 0 && chunkCount == 0)
    {
      /*
       * Special case - if there are no chunks, this is the
       * very first glyph and can simply be added to a new chunk.
       */
      chunk = GSCreateGlyphChunk(glyphIndex, charIndex);
      gGlyph(info) = aGlyph;
      GSIArrayAddItem(&chunk->glyphs, info);
      GSIArrayAddItem(glyphChunks, (GSIArrayItem)(void*)chunk);
    }
  else
    {
      unsigned		gCount;
      unsigned		gOffset;
      unsigned		chunkIndex;

      /*
       * Locate the chunk that we should insert into - the last one with
       * a glyphIndex less than or equal to the index we were given.
       */
      chunkIndex = GSChunkForGlyphIndex(glyphChunks, glyphIndex);
      chunk = (GSGlyphChunk*)GSIArrayItemAtIndex(glyphChunks, chunkIndex).ptr;

      /*
       * Check for the case where we have been given an index that's
       * beyond the end of the last chunk.
       */
      gCount = GSIArrayCount(&chunk->glyphs);
      gOffset = glyphIndex - chunk->glyphIndex;
      if (gOffset > gCount)
	{
	  [NSException raise: NSRangeException
		      format: @"insertGlyph:glyphIndex:characterIndex: "
			@"glyph index out of range"];
	}
      
      if (gOffset == 0)			// Before first glyph in chunk
	{
	  if (chunk->charIndex < charIndex)
	    {
	      [NSException raise: NSRangeException
			  format: @"insertGlyph:glyphIndex:characterIndex: "
		@"character index greater than that of next glyph"];
	    }
	  if (chunkIndex > 0)
	    {
	      GSGlyphChunk	*previous;
	      unsigned		c;

	      previous = (GSGlyphChunk*)GSIArrayItemAtIndex(glyphChunks,
		chunkIndex-1).ptr;
	      c = GSIArrayCount(&previous->glyphs);
	      c = previous->charIndex
		+ gOffset(GSIArrayItemAtIndex(&previous->glyphs, c));
	      if (c > charIndex)
		{
		  [NSException raise: NSRangeException
			      format: @"insertGlyph:glyphIndex:characterIndex: "
		    @"character index less than that of previous glyph"];
		}
	      else if (c == charIndex)
		{
		  /*
		   * Inserting with the same character index as the last glyph
		   * in the previous chunk - so we should append to that chunk
		   * rather than prepending to this one.
		   */ 
		  chunkIndex--;
		  chunk = previous;
		  gCount = GSIArrayCount(&chunk->glyphs);
		  gOffset = glyphIndex - chunk->glyphIndex;
		}
	    }
	}
      else if (gOffset == gCount)	// After last glyph in chunk
	{
	  unsigned	c = chunk->charIndex;

	  if (gOffset > 0)
	    {
	      c += gOffset(GSIArrayItemAtIndex(&chunk->glyphs, gOffset-1));
	    }
	  if (charIndex < c)
	    {
	      [NSException raise: NSRangeException
			  format: @"insertGlyph:glyphIndex:characterIndex: "
		@"character index less than that of previous glyph"];
	    }
	  if (chunkIndex < chunkCount - 1)
	    {
	      GSGlyphChunk	*next;

	      next = (GSGlyphChunk*)GSIArrayItemAtIndex(glyphChunks,
		chunkIndex+1).ptr;
	      if (next->charIndex < charIndex)
		{
		  [NSException raise: NSRangeException
			      format: @"insertGlyph:glyphIndex:characterIndex: "
		    @"character index greater than that of next glyph"];
		}
	      else if (next->charIndex == charIndex)
		{
		  /*
		   * Inserting with the same character index as the first glyph
		   * in the next chunk - so we should insert in that chunk
		   * rather than appending to this one.
		   */ 
		  chunkIndex++;
		  chunk = next;
		  gCount = GSIArrayCount(&chunk->glyphs);
		  gOffset = glyphIndex - chunk->glyphIndex;
		}
	    }
	}
      else		// In middle of chunk somewhere.
	{
	  unsigned	n; 
	  unsigned	p; 

	  p = chunk->charIndex
	    + gOffset(GSIArrayItemAtIndex(&chunk->glyphs, gOffset-1));
	  if (p > charIndex)
	    {
	      [NSException raise: NSRangeException
			  format: @"insertGlyph:glyphIndex:characterIndex: "
		@"character index less than that of previous glyph"];
	    }
	  n = chunk->charIndex
	    + gOffset(GSIArrayItemAtIndex(&chunk->glyphs, gOffset));
	  if (n < charIndex)
	    {
	      [NSException raise: NSRangeException
			  format: @"insertGlyph:glyphIndex:characterIndex: "
		@"character index greater than that of next glyph"];
	    }
	}

      /*
       * Shall we add to the chunk or is it big enough already?
       */
      if (gCount > 4 && gCount == GSIArrayCapacity(&chunk->glyphs))
	{
	  GSGlyphChunk	*newChunk = 0;
	  unsigned	from;
	  unsigned	pos;
	  unsigned	splitAt = gCount/2;
	  unsigned	splitChar;

	  splitChar = gOffset(GSIArrayItemAtIndex(&chunk->glyphs, splitAt));
	  while (splitAt > 0 && splitChar
	    == gOffset(GSIArrayItemAtIndex(&chunk->glyphs, splitAt-1)))
	    {
	      splitAt--;
	    }
	  /*
	   * Arbitrary check that we could make a sane splitup of the
	   * chunk.  Conceivably we could have every glyph in the
	   * chunk set to the same character - which would force us to
	   * break our invariant that all glyphs for a particular
	   * character lie in the same chunk.
	   */
	  if (splitAt <= gCount/4)
	    {
	      [NSException raise: NSInternalInconsistencyException
			  format: @"unable to split glyph chunk"];
	    }
	  /*
	   * Ok - split the chunk into two (roughly) equal parts.
	   */
	  splitChar
	    = gOffset(GSIArrayItemAtIndex(&chunk->glyphs, splitAt));
	  newChunk = GSCreateGlyphChunk(chunk->glyphIndex + splitAt,
	    chunk->charIndex + splitChar);
	  GSIArrayInsertItem(glyphChunks, (GSIArrayItem)(void*)newChunk,
	    chunkIndex+1);
	  pos = 0;
	  from = splitAt;
	  while (from < GSIArrayCount(&chunk->glyphs))
	    {
	      GSIArrayItem	info;

	      /*
	       * Remove attributes from old chunk and add to new.
	       * Adjust offset for character index of new chunk.
	       */
	      info = GSIArrayItemAtIndex(&chunk->glyphs, from);
	      gOffset(info) -= splitChar;
	      GSIArrayInsertItem(&newChunk->glyphs, info, pos);

	      from++;
	      pos++;
	    }
	  GSIArrayRemoveItemsFromIndex(&chunk->glyphs, splitAt);
	  /*
	   * And set up so we point at the correct half of the split chunk.
	   */
	  if (glyphIndex >= newChunk->glyphIndex)
	    {
	      chunkIndex++;
	      chunk = newChunk;
	      gOffset = glyphIndex - chunk->glyphIndex;
	    }
	  gCount = GSIArrayCount(&chunk->glyphs);
	}

      /*
       * Special handling for insertion at the start of a chunk - we
       * need to update the index values for the chunk, and (possibly)
       * the character offsets of every glyph in the chunk.
       */
      if (gOffset == 0)
	{
	  chunk->glyphIndex = glyphIndex;
	  if (chunk->charIndex != charIndex)
	    {
	      int	diff = charIndex - chunk->charIndex;

	      /*
	       * Changing character index of entire chunk.
	       */
	      for (pos = 0; pos < gCount; pos++)
		{
		  gOffset(GSIArrayItems(&chunk->glyphs)[pos]) += diff;
		}
	      chunk->charIndex = charIndex;
	    }
	}

      /*
       * At last we insert the glyph and its attributes into the chunk.
       */
      gOffset(info) = charIndex - chunk->charIndex;
      gGlyph(info) = aGlyph;
      GSIArrayInsertItem(&chunk->glyphs, info, gOffset);

      /*
       * Now adjust the glyph index for all following chunks so we will
       * still know the index of the first glyph in each chunk.
       */
      for (pos = chunkIndex+1; pos < chunkCount; pos++)
	{
	  chunk = (GSGlyphChunk*)GSIArrayItemAtIndex(glyphChunks, pos).ptr;
	  chunk->glyphIndex++;
	}
    }

  /*
   * Now adjust gaps to handle glyph insertion.
   */
  pos = 0;
  while (pos < GSIArrayCount((GSIArray)_glyphGaps))
    {
      unsigned long val;

      val = GSIArrayItemAtIndex((GSIArray)_glyphGaps, pos).ulng;
      if (val >= glyphIndex)
	{
	  GSIArraySetItemAtIndex((GSIArray)_glyphGaps, (GSIArrayItem)(val+1),
	    pos);
	}
      pos++;
    }
_GLog(self,_cmd);
_Sane(self);
}

/**
 * Returns the glyph at the specified index.<br />
 * Causes any gaps (areas where glyphs have been invalidated) before this
 * index to be re-filled.<br />
 * Raises an exception if the index is out of range.
 */
- (NSGlyph) glyphAtIndex: (unsigned)index
{
  BOOL		flag;
  NSGlyph	glyph;

  glyph = [self glyphAtIndex: index isValidIndex: &flag];
  if (flag == NO)
    {
      [NSException raise: NSRangeException
		  format: @"glyph index out of range"];
    }
  return glyph;
}

/**
 * Returns the glyph at the specified index.<br />
 * Causes any gaps (areas where glyphs have been invalidated) before this
 * index to be re-filled.<br />
 * Sets the flag to indicate whether the index was found ... if it wasn't
 * the returned glyph is meaningless.
 */
- (NSGlyph) glyphAtIndex: (unsigned)index
	    isValidIndex: (BOOL*)flag
{
#if USE_GLYPHS
  NSGlyph	glyph;
  NSString	*string = nil;
  unsigned	textLength = [_textStorage length];

_GLog(self,_cmd);
  if (GSIArrayCount((GSIArray)_glyphGaps) > 0
    && (GSIArrayItemAtIndex((GSIArray)_glyphGaps, 0).ulng) <= index)
    {
      unsigned long	gap;

      string = [_textStorage string];

      while (GSIArrayCount((GSIArray)_glyphGaps) > 0
	&& (gap = GSIArrayItemAtIndex((GSIArray)_glyphGaps, 0).ulng) <= index)
	{
	  unsigned	endChar;
	  unsigned	startChar;

	  if (gap == 0)
	    {
	      startChar = 0;
	    }
	  else
	    {
	      /*
	       * Locate the glyph that preceeds the gap, and start with the
	       * a character one beyond the one that generated that glyph.
	       * This guarantees that we won't try to re-generate the
	       * preceeding glyph.
	       * FIXME ... probably too simplistic an algorithm if we have
	       * decomposed unicode characters to deal with 0 we should
	       * probably skip forward to the next character sequence.
	       */
	      _JumpToGlyph(self, gap - 1);
	      startChar = _CharIndex(self) + 1;
	    }
	  if (gap == _GlyphEnd(self))
	    {
	      endChar = textLength;
	    }
	  else
	    {
	      _JumpToGlyph(self, gap);
	      endChar = _CharIndex(self);
	    }

	  /*
	   * FIXME
	   * Here we put some simple-minded code to generate glyphs from
	   * characters assuming that a glyph is the same as a character.
	   */
	  while (startChar < endChar)
	    {
	      unichar	c = [string characterAtIndex: startChar];

	      [self insertGlyph: (NSGlyph)c
		   atGlyphIndex: gap++
		 characterIndex: startChar++];
	    }
          /*
	   * We have generated glyphs upto or beyond the gap, so we
	   * can remove this gap and any others we have gone past.
	   */
	  while (GSIArrayCount((GSIArray)_glyphGaps) > 0
	    && GSIArrayItemAtIndex((GSIArray)_glyphGaps, 0).ulng < gap)
	    {
	      GSIArrayRemoveItemAtIndex((GSIArray)_glyphGaps, 0);
	    }
	}
    }

  if (index >= _GlyphEnd(self) && _CharEnd(self) < textLength)
    {
      unsigned	endChar = textLength;
      unsigned	startChar = _CharEnd(self);
      unsigned	glyphIndex = _GlyphEnd(self);

      if (string == nil)
	{
	  string = [_textStorage string];
	}
      /* FIXME ... should generate glyphs properly here */
      while (startChar < endChar && glyphIndex <= index)
	{
	  unichar	c = [string characterAtIndex: startChar];

	  [self insertGlyph: (NSGlyph)c
	       atGlyphIndex: glyphIndex++
	     characterIndex: startChar++];
	}
    }

_GLog(self,_cmd);
_Sane(self);
  if (_JumpToGlyph(self, index) == YES)
    {
      *flag = YES;
      glyph = gGlyph(*_Info(self));
    }
  else
    {
      *flag = NO;
      glyph = NSNullGlyph;
    }
#if	ALL_CHECKS
  if (index >= [_textStorage length])
    {
      if (glyph != NSNullGlyph)
	{
	  missmatch(_cmd);
	  *flag = NO;
	  glyph = NSNullGlyph;
	}
    }
  else if (glyph != (NSGlyph)[[_textStorage string] characterAtIndex: index])
    {
      missmatch(_cmd);
      *flag = YES;
      glyph = (NSGlyph)[[_textStorage string] characterAtIndex: index];
    }
#endif
  return glyph;
#else
  return (NSGlyph)[[_textStorage string] characterAtIndex: index];
#endif
}

/**
 * Replaces the glyph at index with newGlyph without changing
 * character index or other attributes.
 */
- (void) replaceGlyphAtIndex: (unsigned)index
		   withGlyph: (NSGlyph)newGlyph
{
_GLog(self,_cmd);
  if (_JumpToGlyph(self, index) == NO)
    {
      [NSException raise: NSRangeException
		  format: @"glyph index out of range"];
    }
  gGlyph(*_Info(self)) = newGlyph;
_GLog(self,_cmd);
}

/**
 * This returns a nul terminated array of glyphs ... so glyphArray
 * should contain space for glyphRange.length+1 glyphs.
 */
- (unsigned) getGlyphs: (NSGlyph*)glyphArray
		 range: (NSRange)glyphRange
{
  unsigned	packed = 0;
  unsigned	toFetch = glyphRange.length;

_GLog(self,_cmd);
  if (toFetch > 0)
    {
      /*
       * Force generation of glyphs to fill range.
       */
      [self glyphAtIndex: NSMaxRange(glyphRange)-1];

      _JumpToGlyph(self, glyphRange.location);

      /*
       * Now return glyphs, excluding those 'not shown'
       */
      while (toFetch-- > 0)
	{
	  GSIArrayItem	info = *_Info(self);

	  if (gIsNotShown(info) == 0)
	    {
	      glyphArray[packed++] = gGlyph(info);
	    }
	  _Step(self);	// Move to next glyph.
	}
    }
  glyphArray[packed] = 0;
_GLog(self,_cmd);
  return packed;
}

/**
 * Removes all the glyphs in aRange from the glyph stream, causing all
 * subsequent glyphs to have their index decreased by aRange.length
 */
- (void) deleteGlyphsInRange: (NSRange)aRange
{
  unsigned	chunkStart;
  unsigned	chunkEnd;
  unsigned	offset;
  unsigned	from;
  unsigned	pos;
  GSGlyphChunk	*chunk;

_GLog(self,_cmd);
  if (aRange.length == 0)
    {
      return;					// Nothing to delete.
    }
  pos = GSIArrayCount(glyphChunks) - 1;
  chunk = (GSGlyphChunk*)GSIArrayItemAtIndex(glyphChunks, pos).ptr;
  pos = chunk->glyphIndex + GSIArrayCount(&chunk->glyphs);
  if (aRange.location >= pos)
    {
      return;					// Range is beyond glyphs.
    }
  if (NSMaxRange(aRange) > pos)
    {
      aRange.length = pos - aRange.location;	// Truncate range to glyphs.
    }

  chunkStart = GSChunkForGlyphIndex(glyphChunks, aRange.location);
  chunkEnd = GSChunkForGlyphIndex(glyphChunks, NSMaxRange(aRange)-1);

  /*
   * Remove all chunks wholy contained in the range.
   */
  while (chunkEnd - chunkStart > 1)
    {
      chunkEnd--;
      chunk = (GSGlyphChunk*)GSIArrayItemAtIndex(glyphChunks, chunkEnd).ptr;
      GSIArrayRemoveItemAtIndex(glyphChunks, chunkEnd);
      GSDestroyGlyphChunk(chunk);
    }

  /*
   * Get start chunk and remove any glyphs in specified range.
   */
  chunk = (GSGlyphChunk*)GSIArrayItemAtIndex(glyphChunks, chunkStart).ptr;
  if (chunkStart == chunkEnd)
    {
      pos = chunk->glyphIndex;
    }
  else
    {
      offset = aRange.location - chunk->glyphIndex;
      if (offset == 0)
	{
	  /*
	   * Start chunk is fully enclosed in range - remove it.
	   */
	  pos = chunk->glyphIndex;
	  GSIArrayRemoveItemAtIndex(glyphChunks, chunkStart);
	  GSDestroyGlyphChunk(chunk);
	  chunkEnd--;
	}
      else
	{
	  pos = chunk->glyphIndex + offset;
	  GSIArrayRemoveItemsFromIndex(&chunk->glyphs, offset);
	}
      chunk = (GSGlyphChunk*)GSIArrayItemAtIndex(glyphChunks, chunkEnd).ptr;
    }

  offset = NSMaxRange(aRange) - chunk->glyphIndex;
  if (chunk->glyphIndex < aRange.location)
    {
      from = aRange.location - chunk->glyphIndex;
    }
  else
    {
      from = 0;
    }
  chunk->glyphIndex = pos;
  while (offset-- > from)
    {
      GSIArrayRemoveItemAtIndex(&chunk->glyphs, from);
    }
  while (++chunkEnd < GSIArrayCount(glyphChunks))
    {
      chunk = (GSGlyphChunk*)GSIArrayItemAtIndex(glyphChunks, chunkEnd).ptr;
      chunk->glyphIndex -= aRange.length;
    }

  /*
   * Remove any gaps that were in the deleted range and adjust the
   * indices of any remaining gaps to allow for the deletion.
   */
  pos = 0;
  while (pos < GSIArrayCount((GSIArray)_glyphGaps))
    {
      unsigned	val = GSIArrayItemAtIndex((GSIArray)_glyphGaps, pos).ulng;

      if (val < aRange.location)
	{
	  pos++;	// Not modified by deletion
	}
      else if (val <= NSMaxRange(aRange))
	{
	  /*
	   * Gap is within (or immediately after) the deleted area ...
	   * we set it to the end of the deleted area, or remove it if
	   * there is already a gap at that location.
	   */
	  if (pos > 0
	    && GSIArrayItemAtIndex((GSIArray)_glyphGaps, pos-1).ulng
	    == aRange.location)
	    {
	      GSIArrayRemoveItemAtIndex((GSIArray)_glyphGaps, pos);
	    }
	  else
	    {
	      GSIArraySetItemAtIndex((GSIArray)_glyphGaps,
		(GSIArrayItem)aRange.location, pos);
	      pos++;
	    }
	}
      else
	{
	  /*
	   * Gap is beyond deleted area ... simply adjust downwards.
	   */
	  val -= aRange.length;
	  GSIArraySetItemAtIndex((GSIArray)_glyphGaps,
	    (GSIArrayItem)val, pos);
	  pos++;
	}
    }

_GLog(self,_cmd);
_Sane(self);
}

/**
 * Returns the number of glyphs in the glyph stream ... causing generation
 * of new glyphs to fill gaps and to extend the stream until all characters
 * in the text storage have had glyphs generated.
 */
- (unsigned) numberOfGlyphs
{
  unsigned	result;
#if	USE_GLYPHS
  BOOL	valid;

  /*
   * Force generation of all glyphs.
   */
  [self glyphAtIndex: 0x7fffffff isValidIndex: &valid];
  result = _GlyphEnd(self);
#if	ALL_CHECKS
  if (result != [_textStorage length])
    {
      missmatch(_cmd);
      result = [_textStorage length];
    }
#endif
#else
  result = [_textStorage length];
#endif
  return result;
}

/**
 * Sets the glyph at glyphIndex to correspond to the character at charIndex.
 */
- (void) setCharacterIndex: (unsigned)charIndex
	   forGlyphAtIndex: (unsigned)glyphIndex
{
  int		diff;

_GLog(self,_cmd);
  if (_JumpToGlyph(self, glyphIndex) == NO)
    {
      [self glyphAtIndex: glyphIndex];
      _JumpToGlyph(self, glyphIndex);
    }
  diff = charIndex - _CharIndex(self);
  if (diff == 0)
    {
      return;		// Already set - nothing to do.
    }

  if (_Back(self) == NO)
    {
      if (charIndex != 0)
	{
	  [NSException raise: NSRangeException
		      format: @"set non-zero index for initial glyph"];
	}
      return;
    }
  if (_CharIndex(self) > charIndex)
    {
      [NSException raise: NSRangeException
		  format: @"set index lower than preceeding glyph"];
    }
  _Step(self);
  if (_Step(self) == YES && charIndex > _CharIndex(self))
    {
      [NSException raise: NSRangeException
		  format: @"set index higher than following glyph"];
    }
  
  _Back(self);
  /*
   * If this is the start of a chunk, we adjust the character position
   * for the chunk as a whole, then fix each glyph in turn.  Otherwise
   * we simply adjust the glyph concerned.
   */
  if (_glyphOffset == 0)
    {
      GSGlyphChunk	*chunk = (GSGlyphChunk*)_currentGlyphs;

      diff = charIndex - _CharIndex(self);
      chunk->charIndex += diff;
      while (_Step(self) == YES && (GSGlyphChunk*)_currentGlyphs == chunk)
	{
	  gOffset(*_Info(self)) += diff;
	}
    }
  else
    {
      gOffset(*_Info(self)) += diff;
    }
_GLog(self,_cmd);
_Sane(self);
}

/**
 * Returns the character index for the specified glyphIndex.<br />
 * If there are invalidated ranges (gaps) in the glyph stream before
 * glyphIndex, this will cause glyph generation to fill them.
 */
- (unsigned) characterIndexForGlyphAtIndex: (unsigned)glyphIndex
{
  unsigned	result;

#if	USE_GLYPHS
_GLog(self,_cmd);
  if (_JumpToGlyph(self, glyphIndex) == NO)
    {
      BOOL	exists;

      [self glyphAtIndex: glyphIndex isValidIndex: &exists];
      if (exists == YES)
	{
	  _JumpToGlyph(self, glyphIndex);
	  result = _CharIndex(self);  
	}
      else
	{
	  /*
	   * As a special case, the glyph index just beyond the end of
	   * the glyph stream is known to map to the character index just
	   * beyond the end of the text.
	   */
	  if (glyphIndex == _GlyphEnd(self))
	    {
	      result = [_textStorage length];
	    }
	  else
	    {
	      [NSException raise: NSRangeException
			  format: @"glyph index out of range"];
	    }
	}
    }
  else
    {
      result = _CharIndex(self);  
    }
#if	ALL_CHECKS
  if (result != glyphIndex)
    {
      missmatch(_cmd);
      result = glyphIndex;
    }
#endif
_GLog(self,_cmd);
#else
  result = glyphIndex;
#endif
  return result;
}

/**
 * Returns the range of characters that generated the glyphs in glyphRange.
 * Sets actualGlyphRange (if non-nul) to the range of glyphs generated by
 * those characters.
 */
- (NSRange) characterRangeForGlyphRange: (NSRange)glyphRange
		       actualGlyphRange: (NSRange*)actualGlyphRange
{
  NSRange	cRange;
  NSRange	gRange = glyphRange;
#if	USE_GLYPHS
  unsigned	cEnd;
  BOOL		exists;

_GLog(self,_cmd);
  /*
   * Force generation of glyphs to fill gaps.
   */
  [self glyphAtIndex: NSMaxRange(glyphRange)
	isValidIndex: &exists];

  /*
   * Locate character index of location immediately beyond last glyph in range.
   */
  if (exists == NO)
    {
      if (NSMaxRange(glyphRange) > _GlyphEnd(self))
	{
	  [NSException raise: NSRangeException
		      format: @"glyph range too large"];
	}
      cEnd = [_textStorage length];
    }
  else
    {
      _JumpToGlyph(self, NSMaxRange(glyphRange));
      cEnd = _CharIndex(self);
    }

  /*
   * Locate the first glyph and step backwards to the earliest glyph with
   * the same character index.
   */
  _JumpToGlyph(self, glyphRange.location);
  cRange.location = _CharIndex(self);
  cRange.length = cEnd - cRange.location;
  while (_Back(self) == YES && _CharIndex(self) == cRange.location)
    {
      gRange.location--;
      gRange.length++;
    }

#if	ALL_CHECKS
  if (NSEqualRanges(cRange, glyphRange) == NO)
    {
      missmatch(_cmd);
      cRange = glyphRange;
    }
  if (NSEqualRanges(gRange, glyphRange) == NO)
    {
      missmatch(_cmd);
      gRange = glyphRange;
    }
#endif
#else
  // Currently gyphIndex is the same as character index
  gRange = glyphRange;
  cRange = glyphRange;
#endif
  if (actualGlyphRange != 0)
    {
      *actualGlyphRange = gRange;
    }
  return cRange;
}

/**
 * Returns the range of glyphs that are generated from the characters in
 * charRange.
 * Sets actualCharRange (if non-nul) to the full range of characters which
 * generated those glyphs.
 */
- (NSRange) glyphRangeForCharacterRange: (NSRange)charRange
		   actualCharacterRange: (NSRange*)actualCharRange
{
  NSRange	gRange;
#if	USE_GLYPHS
  unsigned	pos;
  NSRange	cRange = charRange;
  unsigned	numGlyphs;
  BOOL		valid;

  /*
   * If the range we have been given begins or ends with a composed
   * character sequence, we must extend it to encompass the entire
   * sequence.  We store the actual range in cRange.
   */
  if (charRange.length > 0)
    {
      NSString	*s = [_textStorage string];
      NSRange	r;

      r = [s rangeOfComposedCharacterSequenceAtIndex: cRange.location];
      if (r.length > 0)
	{
	  cRange.length += (cRange.location - r.location);
	  cRange.location = r.location;
	}
      if (NSMaxRange(charRange) > NSMaxRange(r))
	{
	  pos = NSMaxRange(charRange) - 1;
	  r = [s rangeOfComposedCharacterSequenceAtIndex: pos];
	  if (r.length > 0)
	    {
	      cRange.length += r.length - 1;
	    }
	}
    }

_GLog(self,_cmd);
  // Force generation of glyphs.
  [self glyphAtIndex: NSMaxRange(cRange) - 1 isValidIndex: &valid];

  /*
   * Locate the first glyph corresponding to the start character.
   * If it doesn't exist, we either have a zero length range at the end.
   * or we must return a not found marker.
   */
  if (_JumpToChar(self, charRange.location) == NO)
    {
      if (charRange.location == _CharEnd(self))
	{
	  cRange = NSMakeRange(charRange.location, 0);
	  gRange = NSMakeRange(numGlyphs, 0);
	}
      else
	{
	  cRange = NSMakeRange(NSNotFound, 0);
	  gRange = NSMakeRange(NSNotFound, 0);
	}
    }
  else
    {
      gRange.location = _GlyphIndex(self);

      /*
       * Adjust start character if necessary.  The glyph may have a lower
       * index if the start char is part of a composed character sequence.
       */
      pos = _CharIndex(self);
      if (pos < cRange.location)
	{
	  cRange.length += (cRange.location - pos);
	  cRange.location = pos;
	}

      if (charRange.length == 0)
	{
	  /*
	   * For a zero length range, we don't need to locate an end character.
	   */
	  cRange.length = 0;	// May have been lengthened above.
	  gRange.length = 0;
	}
      else if (NSMaxRange(charRange) == [_textStorage length])
	{
	  /*
	   * Special case - range extends to end of text storage.
	   */
	  gRange.length = numGlyphs - gRange.location;
	}
      else
	{
	  /*
	   * Locate the glyph immediately beyond the range,
	   * and calculate the length of the range from that.
	   */
	  _JumpToChar(self, NSMaxRange(charRange));
	  pos = _GlyphIndex(self);
	  gRange.length = pos - gRange.location;
	  pos = _CharIndex(self);
	  cRange.length = pos - cRange.location;
	}
    }
#if	ALL_CHECKS
  if (NSEqualRanges(gRange, charRange) == NO)
    {
      missmatch(_cmd);
      gRange = charRange;
    }
  if (NSEqualRanges(cRange, charRange) == NO)
    {
      missmatch(_cmd);
      cRange = charRange;
    }
#endif
  if (actualCharRange != 0)
    {
      *actualCharRange = cRange;
    }
_GLog(self,_cmd);
#else
  // Currently gyphIndex is the same as character index
  if (actualCharRange != NULL)
    {
      *actualCharRange = charRange;
    }
  gRange = charRange;
#endif
  return gRange;
}

/**
 * This method modifies the attributes of an existing glyph at glyphIndex.
 * It only deals with the existing attribute types ... if you subclass and
 * add new attributed, you must replace this method with one which can
 * store your new attributes.
 */
- (void) setIntAttribute: (int)attribute
		   value: (int)anInt
	 forGlyphAtIndex: (unsigned)glyphIndex
{
  GSIArrayItem	info;

_GLog(self,_cmd);
  if (_JumpToGlyph(self, glyphIndex) == NO)
    {
      [NSException raise: NSRangeException
		  format: @"glyph index out of range"];
    }
  info = *_Info(self);
  if (attribute == GSGlyphDrawsOutsideLineFragment)
    {
      if (anInt == 0)
	{
	  gDrawsOutside(info) = 0;
	}
      else
	{
	  gDrawsOutside(info) = 1;
	}
    }
  else if (attribute == GSGlyphIsNotShown)
    {
      if (anInt == 0)
	{
	  gIsNotShown(info) = 0;
	}
      else
	{
	  gIsNotShown(info) = 1;
	}
    }
  else if (attribute == GSGlyphGeneration)
    {
      gGeneration(info) = anInt;
    }
  else if (attribute == GSGlyphInscription)
    {
      gInscription(info) = anInt;
    }
  *_Info(self) = info;
_GLog(self,_cmd);
}

/**
 * Returns the value for the attribute at the glyphIndex.
 */
- (int) intAttribute: (int)attribute
     forGlyphAtIndex: (unsigned)glyphIndex
{
  GSIArrayItem	info;

_GLog(self,_cmd);
  if (_JumpToGlyph(self, glyphIndex) == NO)
    {
      [NSException raise: NSRangeException
		  format: @"glyph index out of range"];
    }
  info = *_Info(self);

  if (attribute == GSGlyphDrawsOutsideLineFragment)
    {
      if (gDrawsOutside(info) == 0)
	{
	  return 0;
	}
      else
	{
	  return 1;
	}
    }
  else if (attribute == GSGlyphIsNotShown)
    {
      if (gIsNotShown(info) == 0)
	{
	  return 0;
	}
      else
	{
	  return 1;
	}
    }
  else if (attribute == GSGlyphGeneration)
    {
      return gGeneration(info);
    }
  else if (attribute == GSGlyphInscription)
    {
      return gInscription(info);
    }

  return 0;
}

- (void) setTextContainer: (NSTextContainer*)aTextContainer
	    forGlyphRange: (NSRange)glyphRange
{
  /* TODO */
}

- (NSRange) glyphRangeForTextContainer: (NSTextContainer*)aTextContainer
{
  /* TODO */
  return NSMakeRange(NSNotFound, 0);
}

/**
 * Returns the text container in which the glyph at glyphIndex is laid.
 * If effectiveRange is non-nul, returns the range of all glyphs in the
 * container.
 */
- (NSTextContainer*) textContainerForGlyphAtIndex: (unsigned)glyphIndex
                                   effectiveRange: (NSRange*)effectiveRange
{
/* FIXME ... needs to be properly implemented */
  if (effectiveRange != 0)
    {
      *effectiveRange = NSMakeRange(0, [self numberOfGlyphs]);
    }
  if ([_textContainers count] == 0)
    {
      return nil;
    }
  else
    {
      return  [_textContainers objectAtIndex: 0];
    }
}

- (void) setLineFragmentRect: (NSRect)fragmentRect
	       forGlyphRange: (NSRange)glyphRange
		    usedRect: (NSRect)usedRect
{
  /* TODO */
}

- (NSRect) lineFragmentRectForGlyphAtIndex: (unsigned)glyphIndex
			    effectiveRange: (NSRange*)lineFragmentRange
{
  /* TODO */
  return NSZeroRect;
}

- (NSRect) lineFragmentUsedRectForGlyphAtIndex: (unsigned)glyphIndex
				effectiveRange: (NSRange*)lineFragmentRange
{
  /* TODO */
  return NSZeroRect;
}

- (void) setExtraLineFragmentRect: (NSRect)aRect
			 usedRect: (NSRect)usedRect
		    textContainer: (NSTextContainer*)aTextContainer
{
  _extraLineFragmentRect = aRect;
  _extraLineFragmentUsedRect = usedRect;
  _extraLineFragmentContainer = aTextContainer;
}

- (NSRect) extraLineFragmentRect 
{
  return _extraLineFragmentRect;
}

- (NSRect) extraLineFragmentUsedRect 
{
  return _extraLineFragmentUsedRect;
}

- (NSTextContainer*) extraLineFragmentTextContainer 
{
  return _extraLineFragmentContainer;
}

- (NSRect)usedRectForTextContainer:(NSTextContainer *)container
{
  /* TODO */
  return NSZeroRect;
}

- (void)setAttachmentSize:(NSSize)attachmentSize 
	    forGlyphRange:(NSRange)glyphRange
{
  /* TODO */
}

- (void) setDrawsOutsideLineFragment: (BOOL)flag
		     forGlyphAtIndex: (unsigned)glyphIndex
{
  [self setIntAttribute: GSGlyphDrawsOutsideLineFragment
	value: 1
	forGlyphAtIndex: glyphIndex];
}

- (BOOL) drawsOutsideLineFragmentForGlyphAtIndex: (unsigned)glyphIndex
{
  if ([self intAttribute: GSGlyphDrawsOutsideLineFragment
	    forGlyphAtIndex: glyphIndex] == 1)
    {
      return YES;
    }
  return NO;
}

- (void) setLocation: (NSPoint)aPoint
forStartOfGlyphRange: (NSRange)glyphRange
{
  /* TODO */
}

- (NSPoint) locationForGlyphAtIndex: (unsigned)glyphIndex
{
  /* TODO */
  return NSZeroPoint;
}

- (NSRange) rangeOfNominallySpacedGlyphsContainingIndex: (unsigned)glyphIndex
{
  /* TODO */
  return NSMakeRange(NSNotFound, 0);
}

- (NSRect*) rectArrayForCharacterRange: (NSRange)charRange
          withinSelectedCharacterRange: (NSRange)selChareRange
                       inTextContainer: (NSTextContainer*)aTextContainer
                             rectCount: (unsigned*)rectCount
{
  /* TODO */
  return NULL;
}

- (NSRect*) rectArrayForGlyphRange: (NSRange)glyphRange
          withinSelectedGlyphRange: (NSRange)selectedGlyphRange
                   inTextContainer: (NSTextContainer*)aTextContainer
                         rectCount: (unsigned*)rectCount
{
  /* TODO */
  return _cachedRectArray;
}

- (NSRect) boundingRectForGlyphRange: (NSRange)glyphRange
		     inTextContainer: (NSTextContainer*)aTextContainer
{
  /* TODO */
  return NSZeroRect;
}

- (NSRange) glyphRangeForBoundingRect: (NSRect)aRect
		      inTextContainer: (NSTextContainer*)aTextContainer
{
  /* TODO */
  return NSMakeRange(0, 0);
}

- (NSRange) glyphRangeForBoundingRectWithoutAdditionalLayout: (NSRect)bounds
                           inTextContainer: (NSTextContainer*)aTextContainer
{
  /* TODO */
  return NSMakeRange(0, 0);
}

- (unsigned) glyphIndexForPoint: (NSPoint)aPoint
		inTextContainer: (NSTextContainer*)aTextContainer
 fractionOfDistanceThroughGlyph: (float*)partialFraction
{
  /* TODO */
  return 0;
}

- (unsigned) glyphIndexForPoint: (NSPoint)aPoint 
		inTextContainer: (NSTextContainer *)aTextContainer
{
  /* TODO */
  return [self glyphIndexForPoint: aPoint
	       inTextContainer: aTextContainer
	       fractionOfDistanceThroughGlyph: NULL];
}

- (void) setNotShownAttribute: (BOOL)flag
	      forGlyphAtIndex: (unsigned)glyphIndex
{
  [self setIntAttribute: GSGlyphIsNotShown
	          value: 1
	forGlyphAtIndex: glyphIndex];
}

- (BOOL) notShownAttributeForGlyphAtIndex: (unsigned)glyphIndex
{
  if ([self intAttribute: GSGlyphIsNotShown forGlyphAtIndex: glyphIndex] == 1)
    {
      return YES;
    }
  return NO;
}

- (void) setShowsInvisibleCharacters: (BOOL)flag
{
  _showsInvisibleChars = flag;
}

- (BOOL) showsInvisibleCharacters 
{
  return _showsInvisibleChars;
}

- (void) setShowsControlCharacters: (BOOL)flag
{
  _showsControlChars = flag;
}

- (BOOL) showsControlCharacters
{
  return _showsControlChars;
}

- (void) setHyphenationFactor: (float)factor
{
  _hyphenationFactor = factor;
}

- (float) hyphenationFactor
{
  return _hyphenationFactor;
}

- (void) getFirstUnlaidCharacterIndex: (unsigned*)charIndex
			   glyphIndex: (unsigned*)glyphIndex
{
  if (charIndex)
    {
      *charIndex = [self firstUnlaidCharacterIndex];
    }
  
  if (glyphIndex)
    {
      *glyphIndex = [self firstUnlaidGlyphIndex];
    }
}

- (unsigned int) firstUnlaidCharacterIndex
{
  return _firstUnlaidCharIndex;
}

- (unsigned int) firstUnlaidGlyphIndex
{
  return _firstUnlaidGlyphIndex;
}

- (void) setUsesScreenFonts: (BOOL)flag
{
  _usesScreenFonts = flag;
}

- (BOOL) usesScreenFonts 
{
  return _usesScreenFonts;
}

- (NSFont*) substituteFontForFont: (NSFont*)originalFont
{
  NSFont *replaceFont;

  if (! _usesScreenFonts)
    {
      return originalFont;
    }

  // FIXME: Should check if any NSTextView is scaled or rotated
  replaceFont = [originalFont screenFont];
  
  if (replaceFont != nil)
    {
      return replaceFont;
    }
  else
    {
      return originalFont;    
    }
}

- (NSView*) rulerAccessoryViewForTextView: (NSTextView*)aTextView
                           paragraphStyle: (NSParagraphStyle*)paragraphStyle
                                    ruler: (NSRulerView*)aRulerView
                                  enabled: (BOOL)flag
{
  /* TODO */
  return NULL;
}

- (NSArray*) rulerMarkersForTextView: (NSTextView*)aTextView
                      paragraphStyle: (NSParagraphStyle*)paragraphStyle
                               ruler: (NSRulerView*)aRulerView
{
  NSRulerMarker *marker;
  NSTextTab *tab;
  NSImage *image;
  NSArray *tabs = [paragraphStyle tabStops];
  NSEnumerator *enumerator = [tabs objectEnumerator];
  NSMutableArray *markers = [NSMutableArray arrayWithCapacity: [tabs count]];

  while ((tab = [enumerator nextObject]) != nil)
    {
      switch ([tab tabStopType])
        {
	  case NSLeftTabStopType:
	    image = [NSImage imageNamed: @"common_LeftTabStop"];
	    break;
	  case NSRightTabStopType:
	    image = [NSImage imageNamed: @"common_RightTabStop"];
	    break;
	  case NSCenterTabStopType:
	    image = [NSImage imageNamed: @"common_CenterTabStop"];
	    break;
	  case NSDecimalTabStopType:
	    image = [NSImage imageNamed: @"common_DecimalTabStop"];
	    break;
	  default:
	    image = nil;
	    break;
	}
      marker = [[NSRulerMarker alloc] 
		   initWithRulerView: aRulerView
		   markerLocation: [tab location]
		   image: image
		   imageOrigin: NSMakePoint(0, 0)];
      [marker setRepresentedObject: tab];
      [markers addObject: marker];
    }

  return markers;
}

/*
 * Managing the responder chain 
 */
- (BOOL) layoutManagerOwnsFirstResponderInWindow: (NSWindow*)aWindow
{
  id firstResponder = [aWindow firstResponder];

  if (_textContainersCount == 1)
    {
      if (_firstTextView == firstResponder)
	{
	  return YES;
	}
    }
  else
    {
      int i;

      for (i = 0; i < _textContainersCount; i++)
	{
	  id tv = [[_textContainers objectAtIndex: i] textView]; 
	  
	  if (tv == firstResponder)
	    {
	      return YES;
	    }
	}
    }

  return NO;
}

- (NSTextView*) firstTextView 
{
  return _firstTextView;
}

- (NSTextView*) textViewForBeginningOfSelection
{
  return nil;
}

- (void) drawBackgroundForGlyphRange: (NSRange)glyphRange
			     atPoint: (NSPoint)containerOrigin
{
  NSTextContainer *aTextContainer;
  NSRect rect;

  aTextContainer = [self textContainerForGlyphAtIndex: glyphRange.location
			 effectiveRange: NULL];
  
  [[[aTextContainer textView] backgroundColor] set];
  
  rect = [self boundingRectForGlyphRange: glyphRange 
	       inTextContainer: aTextContainer];
  rect.origin.x += containerOrigin.x;
  rect.origin.x += containerOrigin.y;
  NSRectFill (rect);
}

- (void) drawGlyphsForGlyphRange: (NSRange)glyphRange
			 atPoint: (NSPoint)containerOrigin
{
  /* TODO */
}

- (void) drawUnderlineForGlyphRange: (NSRange)glyphRange
		      underlineType: (int)underlineType
		     baselineOffset: (float)baselineOffset
		   lineFragmentRect: (NSRect)lineRect
	     lineFragmentGlyphRange: (NSRange)lineGlyphRange
		    containerOrigin: (NSPoint)containerOrigin
{
  /* TODO */
}

- (void) underlineGlyphRange: (NSRange)glyphRange
	       underlineType: (int)underlineType
	    lineFragmentRect: (NSRect)lineRect
      lineFragmentGlyphRange: (NSRange)lineGlyphRange
	     containerOrigin: (NSPoint)containerOrigin
{
  /* TODO */
}

- (void) setDelegate: (id)aDelegate
{
  _delegate = aDelegate;
}

- (id) delegate
{
  return _delegate;
}

- (unsigned) _charIndexForInsertionPointMovingFromY: (float)position
					      bestX: (float)wanted
						 up: (BOOL)upFlag
				      textContainer: (NSTextContainer *)tc
{
  [self subclassResponsibility: _cmd];
  return 0;
}


@end /* NSLayoutManager */

/* The methods laid out here are not correct, however the code they
contain for the most part is. Therefore, my country and a handsome
gift of Ghiradelli chocolate to he who puts all the pieces together :) */

/*
 * A little utility function to determine the range of characters in a
 * scanner that are present in a specified character set.  */
static inline NSRange
scanRange (NSScanner *scanner, NSCharacterSet* aSet)
{
  unsigned	start = [scanner scanLocation];
  unsigned	end = start;

  if ([scanner scanCharactersFromSet: aSet  intoString: 0] == YES)
    {
      end = [scanner scanLocation];
    }
  return NSMakeRange (start, end - start);
}

@implementation NSLayoutManager (Private)
- (int) _rebuildLayoutForTextContainer: (NSTextContainer*)aContainer
		  startingAtGlyphIndex: (int)glyphIndex
{
  NSSize cSize = [aContainer containerSize];
  float i = 0.0;
  NSMutableArray *lineStarts = [NSMutableArray new];
  NSMutableArray *lineEnds = [NSMutableArray new];
  int indexToAdd;
  NSScanner		*lineScanner;
  NSScanner		*paragraphScanner;
  BOOL lastLineForContainerReached = NO;
  int previousScanLocation;
  int previousParagraphLocation;
  int endScanLocation;
  int startIndex;
  NSRect firstProposedRect;
  NSRect secondProposedRect;
  NSCharacterSet *selectionParagraphGranularitySet = [NSCharacterSet characterSetWithCharactersInString: @"\n"];
  NSCharacterSet *selectionWordGranularitySet = [NSCharacterSet characterSetWithCharactersInString: @" "];
  NSCharacterSet *invSelectionWordGranularitySet = [selectionWordGranularitySet invertedSet];
  NSCharacterSet *invSelectionParagraphGranularitySet = [selectionParagraphGranularitySet invertedSet];
  NSRange paragraphRange;
  NSRange leadingSpacesRange;
  NSRange currentStringRange;
  NSRange trailingSpacesRange;
  NSRange leadingNlRange;
  NSRange trailingNlRange;
  NSSize lSize;
  float lineWidth = 0.0;
  float ourLines = 0.0;
  int beginLineIndex = 0;

  NSLog(@"rebuilding Layout at index: %d.\n", glyphIndex);

  // 1.) figure out how many glyphs we can fit in our container by
  // breaking up glyphs from the first unlaid out glyph and breaking it
  // into lines.
  //
  // 2.) 
  //     a.) set the range for the container
  //     b.) for each line in step 1 we need to set a lineFragmentRect and
  //         an origin point.


  // Here we go at part 1.

  startIndex = glyphIndex;

  paragraphScanner = [NSScanner scannerWithString: [_textStorage string]];
  [paragraphScanner setCharactersToBeSkipped: nil];

  [paragraphScanner setScanLocation: startIndex];

  NSLog(@"length of textStorage: %d", [[_textStorage string] length]);

//  NSLog(@"buffer: %@", [_textStorage string]);

  /*
   * This scanner eats one word at a time, we should have it imbeded in
   * another scanner that snacks on paragraphs (i.e. lines that end with
   * \n). Look in NSText.
   */
  while (![paragraphScanner isAtEnd])
    {
      previousParagraphLocation = [paragraphScanner scanLocation];
      beginLineIndex = previousParagraphLocation;
      lineWidth = 0.0;

      leadingNlRange
	= scanRange(paragraphScanner, selectionParagraphGranularitySet);
      paragraphRange
	= scanRange(paragraphScanner, invSelectionParagraphGranularitySet);
      trailingNlRange
	= scanRange(paragraphScanner, selectionParagraphGranularitySet);

//      NSLog(@"leadingNlRange: (%d, %d)", leadingNlRange.location, leadingNlRange.length);

//      if (leadingNlRange.length)
//	paragraphRange = NSUnionRange (leadingNlRange,paragraphRange);
//      if (trailingNlRange.length)
//	paragraphRange = NSUnionRange (trailingNlRange,paragraphRange);

      NSLog(@"paragraphRange: (%d, %d)", paragraphRange.location, paragraphRange.length);

      lineScanner = [NSScanner scannerWithString:
	[[_textStorage string] substringWithRange: paragraphRange]];
      [lineScanner setCharactersToBeSkipped: nil];

      while (![lineScanner isAtEnd])
        {
          previousScanLocation = [lineScanner scanLocation];

           // snack next word
          leadingSpacesRange
	    = scanRange(lineScanner, selectionWordGranularitySet);
          currentStringRange
	    = scanRange(lineScanner, invSelectionWordGranularitySet);
          trailingSpacesRange
	    = scanRange(lineScanner, selectionWordGranularitySet);

          if (leadingSpacesRange.length)
	    currentStringRange = NSUnionRange(leadingSpacesRange,currentStringRange);
          if (trailingSpacesRange.length)
	    currentStringRange = NSUnionRange(trailingSpacesRange,currentStringRange);

	  lSize = [_textStorage sizeRange: currentStringRange];

//	  lSize = [_textStorage sizeRange: 
//NSMakeRange(currentStringRange.location+paragraphRange.location+startIndex,
//currentStringRange.length)];

	  if ((lineWidth + lSize.width) < cSize.width)
	    {
	      if ([lineScanner isAtEnd])
                {
		  NSLog(@"we are at end before finishing a line: %d.\n",  [lineScanner scanLocation]);
		NSLog(@"scanLocation = %d, previousParagraphLocation = %d, beginLineIndex = %d",
		      [lineScanner scanLocation],
		      previousParagraphLocation,
		      beginLineIndex);
		[lineStarts addObject: [NSNumber
					 numberWithInt: beginLineIndex]];
		[lineEnds addObject: [NSNumber
				       numberWithInt: (int)[lineScanner scanLocation] + previousParagraphLocation - (beginLineIndex)]];
		lineWidth = 0.0;
                }
	      
	      lineWidth += lSize.width;
	      //NSLog(@"lineWidth: %f", lineWidth);
	    }
	  else
	    {
	      if (ourLines > cSize.height)
                {
                   lastLineForContainerReached = YES;
                   break;
                 }
	      
	      [lineScanner setScanLocation: previousScanLocation];
	      indexToAdd = previousScanLocation + previousParagraphLocation 
		- (beginLineIndex);
	      
	      NSLog(@"previousScanLocation = %d, previousParagraphLocation = %d, beginLineIndex = %d indexToAdd = %d",
		    previousScanLocation,
		    previousParagraphLocation,
		    beginLineIndex,
		    indexToAdd);
	      
	      ourLines += 20.0;  // 14
	      lineWidth = 0.0;
	      
	      [lineStarts addObject: [NSNumber
				       numberWithInt: beginLineIndex]];
	      [lineEnds addObject: [NSNumber numberWithInt: indexToAdd]];
	      beginLineIndex = previousScanLocation + previousParagraphLocation;
	    }
	}

      if (lastLineForContainerReached)
        break;
    }

  endScanLocation = [paragraphScanner scanLocation];

  NSLog(@"endScanLocation: %d", endScanLocation);

  // set this container for that glyphrange

  [self setTextContainer: aContainer
    forGlyphRange: NSMakeRange(startIndex, endScanLocation - startIndex)];

  NSLog(@"ok, move on to step 2.");

  // step 2. break the lines up and assign rects to them.

  for (i = 0; i < [lineStarts count]; i++)
    {
      NSRect aRect, bRect;
      float padding = [aContainer lineFragmentPadding];
      NSRange ourRange;

//      NSLog(@"\t\t===> %d", [[lines objectAtIndex: i] intValue]);

      ourRange = NSMakeRange ([[lineStarts objectAtIndex: i] intValue],
			      [[lineEnds objectAtIndex: i] intValue]);

/*
      if (i == 0)
        {
          ourRange = NSMakeRange (startIndex, 
			[[lines objectAtIndex: i] intValue] - startIndex);
        }
      else
        {
          ourRange = NSMakeRange ([[lines objectAtIndex: i-1] intValue],
[[lines objectAtIndex: i] intValue] - [[lines objectAtIndex: i-1]
intValue]);
        }
*/
      NSLog(@"line: %@|", [[_textStorage string]
substringWithRange: ourRange]);

      firstProposedRect = NSMakeRect (0, i * 14, cSize.width, 14);

      // ask our textContainer to fix our lineFragment.

      secondProposedRect = [aContainer
	lineFragmentRectForProposedRect: firstProposedRect
                            sweepDirection: NSLineSweepLeft
                         movementDirection: NSLineMoveLeft
			     remainingRect: &bRect];

      // set the line fragmentRect for this range.

      [self setLineFragmentRect: secondProposedRect
		  forGlyphRange: ourRange
		       usedRect: aRect];

      // set the location for this string to be 'show'ed.

      [self setLocation: NSMakePoint(secondProposedRect.origin.x + padding,
				    secondProposedRect.origin.y + padding) 
	    forStartOfGlyphRange: ourRange];
    }

// bloody hack.
//      if (moreText)
//      	[delegate layoutManager: self
//	  didCompleteLayoutForTextContainer: [textContainers objectAtIndex: i]
//          atEnd: NO];
//      else
//      	[delegate layoutManager: self
//	  didCompleteLayoutForTextContainer: [textContainers objectAtIndex: i]
//          atEnd: YES];

  [lineStarts release];
  [lineEnds release];

  return endScanLocation;
}

- (void) _doLayout
{
  NSEnumerator		*enumerator;
  NSTextContainer	*container;
  int			gIndex = 0;

  NSLog(@"doLayout called.\n");

  enumerator = [_textContainers objectEnumerator];
  while ((container = [enumerator nextObject]) != nil)
    {
      gIndex = [self _rebuildLayoutForTextContainer: container
			       startingAtGlyphIndex: gIndex];
    }
}

@end
