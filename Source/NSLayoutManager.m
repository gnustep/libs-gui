/** <title>NSLayoutManager</title>

   <abstract>The text layout manager class</abstract>

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author: Jonathan Gapen <jagapen@smithlab.chem.wisc.edu>
   Date: July 1999
   Author:  Michael Hanni <mhanni@sprintmail.com>
   Date: August 1999

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

#include <AppKit/NSWindow.h>
#include <Foundation/NSException.h>

#define	USE_GLYPHS	0



/*
 * Glyph attributes known to the layout manager.
 */
typedef enum {
  GSGlyphDrawsOutsideLineFragment,
  GSGlyphIsNotShown,
  GSGlyphGeneration,
  GSGlyphInscription,
} GSGlyphAttributes;

/*
 * A structure to hold information about a glyph in the glyph stream
 * NB. This structure should be no more than 32 bits, so it can fit
 * in as a GSIArray element.
 */
typedef	struct {
  unsigned offset:24;			// characters in from start of chunk
  unsigned drawsOutsideLineFragment:1;	// glyph bigger than fragment?
  unsigned isNotShown:1;		// glyph invisible (space, tab etc)
  unsigned inscription:3;		// NSGlyphInscription info
  unsigned generation:3;		// Other attributes
} GSGlyphAttrs;



/*
 * We need a fast array that can store -
 * pointers, objects, glyphs (long) and attributes.
 */
#define GSI_ARRAY_TYPES		GSUNION_PTR|GSUNION_OBJ|GSUNION_LONG
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
  if ((i0.ext).offset < (i1.ext).offset)
    return NSOrderedAscending;
  else if ((i0.ext).offset > (i1.ext).offset)
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
 * 3. The gap array contains glyph indices in numeric order and where no
 *    index exceeds the length of the glyph stream.
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
  GSIArray_t	glyphs;		// Array of glyphs.
  GSIArray_t	attrs;		// Array of attributes.
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
  GSIArrayInitWithZoneAndCapacity(&chunk->attrs, NSDefaultMallocZone(), 8);
  return chunk;
}

static void
GSDestroyGlyphChunk(GSGlyphChunk *chunk)
{
  GSIArrayClear(&chunk->glyphs);
  GSIArrayClear(&chunk->attrs);
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
   * pos is the index of the next chunk *after* the one we want.
   */
  NSCAssert(pos > 0, @"No glyph chunks present"); 
  pos--;
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
   * pos is the index of the next chunk *after* the one we want.
   */
  NSCAssert(pos > 0, @"No glyph chunks present"); 
  pos--;
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
#define	_current	(((lmDefs)lm)->_currentGlyph)
#define	_index		(((lmDefs)lm)->_chunkIndex)
#define	_offset		(((lmDefs)lm)->_glyphIndex)
#define	_gaps		((GSIArray)(((lmDefs)lm)->_glyphGaps))


static GSGlyphAttrs	_Attrs(NSLayoutManager *lm);
static BOOL		_Back(NSLayoutManager *lm);
static unsigned		_CharIndex(NSLayoutManager *lm);
static NSGlyph		_Glyph(NSLayoutManager *lm);
static unsigned		_GlyphIndex(NSLayoutManager *lm);
static BOOL		_JumpToChar(NSLayoutManager *lm, unsigned charIndex);
static BOOL		_JumpToGlyph(NSLayoutManager *lm, unsigned glyphIndex);
static void		_SetAttrs(NSLayoutManager *lm, GSGlyphAttrs a);
static void		_SetGlyph(NSLayoutManager *lm, NSGlyph g);
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
      _current--;
      return YES;
    }
  else if (_index > 0)
    {
      _index--;
      _chunk = (GSGlyphChunk*)GSIArrayItemAtIndex(_chunks, _index).ptr;
      _offset = GSIArrayCount(&_chunk->glyphs) - 1;
      _current--;
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
      _current++;
      return YES;
    }
  else
    {
      if (_index < GSIArrayCount(_chunks) - 1)
	{
	  _index++;
	  _chunk = (GSGlyphChunk*)GSIArrayItemAtIndex(_chunks, _index).ptr;
	  _offset = 0;
	  _current++;
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
      unsigned		index = _index;
      unsigned		offset = _offset;

      /*
       * Adjust character offsets for all glyphs in this chunk.
       */
      if (offset > 0)
	{
	  while (offset < GSIArrayCount(&chunk->glyphs))
	    {
	      GSGlyphAttrs	a;

	      a = GSIArrayItemAtIndex(&chunk->attrs, offset).ext;
	      a.offset += lengthChange;
	      GSIArraySetItemAtIndex(&chunk->attrs, (GSIArrayItem)a, offset);
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

static inline GSGlyphAttrs
_Attrs(NSLayoutManager *lm)
{
  return GSIArrayItemAtIndex(&_chunk->attrs, _offset).ext;
}

static inline unsigned
_CharIndex(NSLayoutManager *lm)
{
  return _chunk->charIndex
    + (GSIArrayItemAtIndex(&_chunk->attrs, _offset).ext).offset;
}

static inline NSGlyph
_Glyph(NSLayoutManager *lm)
{
  return (NSGlyph)GSIArrayItemAtIndex(&_chunk->glyphs, _offset).ulng;
}

static inline unsigned
_GlyphIndex(NSLayoutManager *lm)
{
  return _chunk->glyphIndex + _offset;
}

static BOOL
_JumpToChar(NSLayoutManager *lm, unsigned charIndex)
{
  GSGlyphAttrs	tmp;
  GSGlyphChunk	*c;
  unsigned	i;
  unsigned	o;

  i = GSChunkForCharIndex(_chunks, charIndex);
  c = (GSGlyphChunk*)GSIArrayItemAtIndex(_chunks, i).ptr;
  tmp.offset = charIndex - c->charIndex;
  o = GSIArrayInsertionPosition(&c->attrs, (GSIArrayItem)tmp, offsetSort); 
  if (o == 0)
    {
      return NO;	// Insertion position not found.
    }
  o--;
  /*
   * Locate the *first* glyph for this character index.
   */
  while (o>0 && (GSIArrayItemAtIndex(&c->attrs, o-1).ext).offset >= tmp.offset)
    {
      o--;
    }
  if ((GSIArrayItemAtIndex(&c->attrs, o).ext).offset > tmp.offset)
    {
      return NO;
    }
  _chunk = c;
  _index = i;
  _offset = o;
  _current = c->glyphIndex + o;
  return YES;
}

static BOOL
_JumpToGlyph(NSLayoutManager *lm, unsigned glyphIndex)
{
  GSGlyphChunk	*c;
  unsigned	i;
  unsigned	o;

  /*
   * Attempt a little optimisation based on the current glyph index - 
   * avoid binary search through glyph chunks if a simpler operation
   * will suffice.
   */
  if (glyphIndex == _current)
    {
      return YES;
    }
  else if (glyphIndex == _current + 1)
    {
      return _Step(lm);
    }
  else if (glyphIndex == _current - 1)
    {
      return _Back(lm);
    }

  i = GSChunkForGlyphIndex(_chunks, glyphIndex);
  c = (GSGlyphChunk*)GSIArrayItemAtIndex(_chunks, i).ptr;
  o = glyphIndex - c->glyphIndex;
  if (o < GSIArrayCount(&c->glyphs))
    {
      _chunk = c;
      _index = i;
      _offset = o;
      _current = c->glyphIndex + o;
      return YES;
    }
  else
    {
      return NO;
    }
}

static inline void
_SetAttrs(NSLayoutManager *lm, GSGlyphAttrs a)
{
  GSIArraySetItemAtIndex(&_chunk->attrs, (GSIArrayItem)a, _offset);
}

static inline void
_SetGlyph(NSLayoutManager *lm, NSGlyph g)
{
  GSIArraySetItemAtIndex(&_chunk->glyphs, (GSIArrayItem)g, _offset);
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
	  GSGlyphAttrs	a;
	  unsigned	i;

	  for (i = 0; i < count; i++)
	    {
	      a = GSIArrayItemAtIndex(&chunk->attrs, i).ext;
	      NSCAssert(chunk->charIndex + a.offset >= lastChar,
		NSInternalInconsistencyException);
	      lastChar = chunk->charIndex + a.offset;
	    }
	  lastGlyph = chunk->glyphIndex + count - 1;
	}
    }
}
#else
static inline void
_Sane(NSLayoutManager *lm)
{
}
#endif



@interface NSLayoutManager (Private)

- (void) _doLayout;
- (int) _rebuildLayoutForTextContainer: (NSTextContainer*)aContainer
		  startingAtGlyphIndex: (int)glyphIndex;

@end


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

/* Designated Initializer. Sets up this instance. Finds the shared 
 * NSGlyphGenerator and the shared default NSTypesetter. 
 * The NSLayoutManager starts off without a NSTextStorage
 */
- (id) init
{
  if ([super init] != nil)
    {
      GSIArray	a;

      _backgroundLayout = YES;
      _delegate = nil;
      _textContainers = [[NSMutableArray alloc] initWithCapacity: 2];

      /*
       * Initialise glyph storage and ivars to contain 'current' glyph
       * location information.
       */
      _glyphData = NSZoneMalloc(NSDefaultMallocZone(), sizeof(GSIArray_t));
      GSIArrayInitWithZoneAndCapacity(glyphChunks, NSDefaultMallocZone(), 8);
      _currentGlyphs = GSCreateGlyphChunk(0, 0);
      GSIArrayInsertItem(glyphChunks, (GSIArrayItem)_currentGlyphs, 0);
      _chunkIndex = 0;
      _glyphIndex = 0;

      /*
       * Initialise storage of gaps in the glyph stream.
       * The initial glyph stream is one big gap starting at index 0!
       */
      a = NSZoneMalloc(NSDefaultMallocZone(), sizeof(GSIArray_t));
      GSIArrayInitWithZoneAndCapacity(a, NSDefaultMallocZone(), 8);
      GSIArrayInsertItem(a, (GSIArrayItem)(unsigned long)0, 0);
      _glyphGaps = a;
    }

  return self;
}

- (void) dealloc
{
  unsigned	i;

  /*
   * Release all glyph chunk information
   */
  i = GSIArrayCount(glyphChunks);
  while (i-- > 0)
    {
      GSGlyphChunk	*chunk;

      chunk = (GSGlyphChunk*)(GSIArrayItemAtIndex(glyphChunks, i).ptr);
      GSDestroyGlyphChunk(chunk);
    }
  GSIArrayEmpty(glyphChunks);
  NSZoneFree(NSDefaultMallocZone(), _glyphData);
  _glyphData = 0;

  GSIArrayEmpty((GSIArray)_glyphGaps);
  NSZoneFree(NSDefaultMallocZone(), _glyphGaps);

  RELEASE (_textContainers);

  [super dealloc];
}

//
// Setting the text storage
//

/* The set method generally should not be called directly, but you may
   want to override it.  Used to get and set the text storage.  The
   set method is called by the NSTextStorage's
   addTextStorageObserver/removeTextStorageObserver methods.  */
- (void) setTextStorage: (NSTextStorage*)aTextStorage
{
  unsigned length = [aTextStorage length];
  NSRange aRange = NSMakeRange (0, length);

  /* The text storage is owning us - we mustn't retain it - he is
     retaining us*/
  _textStorage = aTextStorage;
  // force complete re - layout
  [self textStorage: aTextStorage
	edited: NSTextStorageEditedCharacters | NSTextStorageEditedAttributes
	range: aRange
	changeInLength: length 
	invalidatedRange: aRange];
}

- (NSTextStorage*) textStorage
{
  return _textStorage;
}

/* This method should be used instead of the primitive
   -setTextStorage: if you need to replace a NSLayoutManager's
   NSTextStorage with a new one leaving the rest of the web intact.
   This method deals with all the work of making sure the
   NSLayoutManager doesn't get deallocated and transferring all the
   NSLayoutManager s on the old NSTextStorage to the new one.  */
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
      [_textStorage removeLayoutManager: object];
      [newTextStorage addLayoutManager: object];
    }
}

/*
 * Setting text containers
 */
- (NSArray*) textContainers
{
  return _textContainers;
}

/* Add a container to the end of the array.  Must invalidate layout of
 * all glyphs after the previous last container (ie glyphs that were
 * not previously laid out because they would not fit anywhere). */
- (void) addTextContainer: (NSTextContainer*)obj
{
  if ([_textContainers indexOfObjectIdenticalTo: obj] == NSNotFound)
    {
      int i;
      
      [_textContainers addObject: obj];
      [obj setLayoutManager: self];
      // TODO: Invalidate layout
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

/* Insert a container into the array before the container at index.
 * Must invalidate layout of all glyphs in the containers from the one
 * previously at index to the last container. */
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
  // TODO: Invalidate layout
}

// Removes the container at index from the array.  Must invalidate
// layout of all glyphs in the container being removed and any
// containers which come after it.
- (void) removeTextContainerAtIndex: (unsigned)index
{
  int i;

  [_textContainers removeObjectAtIndex: index];
  _textContainersCount--;
  _firstTextView = [(NSTextContainer *)[_textContainers objectAtIndex: 0] 
				       textView];  
  for (i = 0; i < _textContainersCount; i++)
    {
      NSTextView *tv = [[_textContainers objectAtIndex: i] textView]; 
      
      [tv _updateMultipleTextViews];
    }
}

//
// Invalidating glyphs and layout
//

// This removes all glyphs for the old character range, adjusts the
// character indices of all the subsequent glyphs by the change in
// length, and invalidates the new character range.  If
// actualCharRange is non-NULL it will be set to the actual range
// invalidated after any necessary expansion.
- (void) invalidateGlyphsForCharacterRange: (NSRange)aRange
			    changeInLength: (int)lengthChange
		      actualCharacterRange: (NSRange*)actualRange
{
  NSRange	cRange;
  NSRange	gRange;

  if (aRange.length == 0)
    {
      return;
    }

  gRange = [self glyphRangeForCharacterRange: aRange
			actualCharacterRange: &cRange];
  if (actualRange != 0)
    {
      *actualRange = cRange;
    }

  [self deleteGlyphsInRange: gRange];

  /*
   * Now adjust character locations for glyphs if necessary.
   */
  _Adjust(self, gRange.location, lengthChange);

  /*
   * Unless the 'lengthChange' accounts for the entire character range
   * that we deleted glyphs for, we must note the presence of a gap.
   */
  if (cRange.length + lengthChange > 0)
    {
      unsigned	pos;

      for (pos = 0; pos < GSIArrayCount((GSIArray)_glyphGaps); pos++)
	{
	  unsigned	val;

	  val = (unsigned)GSIArrayItemAtIndex((GSIArray)_glyphGaps, pos).ulng;
	  if (val == gRange.location)
	    {
	      break;	// Gap already marked here.
	    }
	  if (val > gRange.location)
	    {
	      GSIArrayInsertItem((GSIArray)_glyphGaps,
		(GSIArrayItem)gRange.location, pos);
	      break;
	    }
	}
    }

// FIXME - should invalidate the character range ... but what does that mean?
_Sane(self);
}

// This invalidates the layout information (glyph location and
// rotation) for the given range of characters.  If flag is YES then
// this range is marked as a hard layout invalidation.  If NO, then
// the invalidation is soft.  A hard invalid layout range indicates
// that layout information must be completely recalculated no matter
// what.  A soft invalid layout range means that there is already old
// layout info for the range in question, and if the NSLayoutManager
// is smart enough to figure out how to avoid doing the complete
// relayout, it may perform any optimization available.  If
// actualCharRange is non-NULL it will be set to the actual range
// invalidated after any necessary expansion.
- (void) invalidateLayoutForCharacterRange: (NSRange)aRange
				    isSoft: (BOOL)flag
		      actualCharacterRange: (NSRange*)actualRange
{
  [self _doLayout];
}

// Invalidates display for the glyph or character range given.  For
// the glyph range variant any part of the range that does not yet
// have glyphs generated is ignored.  For the character range variant,
// unlaid parts of the range are remembered and will definitely be
// redisplayed at some point later when the layout is available.
// Neither method actually causes layout.
- (void) invalidateDisplayForCharacterRange: (NSRange)aRange
{
}

- (void) invalidateDisplayForGlyphRange: (NSRange)aRange
{
}

// Invalidates layout of all glyphs in container and all subsequent
// containers.
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

/* Called by NSTextContainer whenever its textView changes.  Used to
   keep notifications in synch. */
- (void) textContainerChangedTextView: (NSTextContainer*)aContainer
{
  /* It only makes sense if we have more than one text container */
  if (_textContainersCount > 1)
    {
      unsigned index;
      
      index = [_textContainers indexOfObjectIdenticalTo: aContainer];
      
      if (index != NSNotFound)
	{
	  if (index == 0)
	    {
	      /* It's the first text view.  Need to update everything. */
	      int i;
	      
	      _firstTextView = [aContainer textView];
	      
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

// Sent from processEditing in NSTextStorage. newCharRange is the
// range in the final string which was explicitly
// edited. invalidatedRange includes stuff which was changed as a
// result of attribute fixing. invalidatedRange is either equal to
// newCharRange or larger. Layout managers should not change the
// contents of the text storage during the execution of this message.
- (void) textStorage: (NSTextStorage*)aTextStorage
	      edited: (unsigned)mask
	       range: (NSRange)range
      changeInLength: (int)lengthChange
    invalidatedRange: (NSRange)invalidatedRange
{
/*
  NSLog(@"NSLayoutManager was just notified that a change in the text
storage occured.");
  NSLog(@"range: (%d, %d) changeInLength: %d invalidatedRange (%d, %d)",
range.location, range.length, lengthChange, invalidatedRange.location,
invalidatedRange.length);
*/
  int delta = 0;
  unsigned last = NSMaxRange (invalidatedRange);

  if (mask & NSTextStorageEditedCharacters)
    {
      delta = lengthChange;
    }

  // hard invalidation occures here.
  [self invalidateGlyphsForCharacterRange: range 
	changeInLength: delta
	actualCharacterRange: NULL];
  [self invalidateLayoutForCharacterRange: invalidatedRange 
	isSoft: NO
	actualCharacterRange: NULL];

  // the following range is soft invalidated
  [self invalidateLayoutForCharacterRange: 
	    NSMakeRange (last, [_textStorage length] - last)
	isSoft: YES
	actualCharacterRange: NULL];
}

//
// Turning on/off background layout
//

// These methods allow you to set/query whether text gets laid out in
// the background when there's nothing else to do.
- (void) setBackgroundLayoutEnabled: (BOOL)flag
{
  _backgroundLayout = flag;
}

- (BOOL) backgroundLayoutEnabled
{
  return _backgroundLayout;
}

//
// Accessing glyphs
//
// These methods are primitive.  They do not cause the bookkeeping of
// filling holes to happen.  They do not cause invalidation of other
// stuff.

/*
 * Inserts a single glyph into the glyph stream at glyphIndex.
 * The character index which this glyph corresponds to is given
 * by charIndex.
 * Invariants ...
 * a)  Glyph chunks are ordered sequentially from zero by character index.
 * b)  Glyph chunks are ordered sequentially from zero by glyph index.
 * c)  Adjacent glyphs may share a character index.
 */
- (void) insertGlyph: (NSGlyph)aGlyph
	atGlyphIndex: (unsigned)glyphIndex
      characterIndex: (unsigned)charIndex
{
  unsigned		chunkCount = GSIArrayCount(glyphChunks);
  GSGlyphAttrs		attrs = { 0 };
  GSGlyphChunk		*chunk;
  unsigned		pos;

  if (glyphIndex == 0 && chunkCount == 0)
    {
      /*
       * Special case - if there are no chunks, this is the
       * very first glyph and can simply be added to a new chunk.
       */
      chunk = GSCreateGlyphChunk(glyphIndex, charIndex);
      GSIArrayAddItem(&chunk->glyphs, (GSIArrayItem)aGlyph);
      GSIArrayAddItem(&chunk->attrs, (GSIArrayItem)attrs);
      GSIArrayAddItem(glyphChunks, (GSIArrayItem)(void*)chunk);
    }
  else
    {
      unsigned		glyphCount;
      unsigned		glyphOffset;
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
      glyphCount = GSIArrayCount(&chunk->glyphs);
      glyphOffset = glyphIndex - chunk->glyphIndex;
      if (glyphOffset > glyphCount)
	{
	  [NSException raise: NSRangeException
		      format: @"insertGlyph:glyphIndex:characterIndex: "
			@"glyph index out of range"];
	}
      
      if (glyphOffset == 0)			// Before first glyph in chunk
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
	      c = GSIArrayCount(&previous->attrs);
	      c = previous->charIndex
		+ (GSIArrayItemAtIndex(&previous->attrs, c).ext).offset;
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
		  glyphCount = GSIArrayCount(&chunk->glyphs);
		  glyphOffset = glyphIndex - chunk->glyphIndex;
		}
	    }
	}
      else if (glyphOffset == glyphCount)	// After last glyph in chunk
	{
	  unsigned	c;

	  c = chunk->charIndex
	    + (GSIArrayItemAtIndex(&chunk->attrs, glyphOffset-1).ext).offset;
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
		  glyphCount = GSIArrayCount(&chunk->glyphs);
		  glyphOffset = glyphIndex - chunk->glyphIndex;
		}
	    }
	}
      else		// In middle of chunk somewhere.
	{
	  unsigned	n; 
	  unsigned	p; 

	  p = chunk->charIndex
	    + (GSIArrayItemAtIndex(&chunk->attrs, glyphOffset-1).ext).offset;
	  if (p > charIndex)
	    {
	      [NSException raise: NSRangeException
			  format: @"insertGlyph:glyphIndex:characterIndex: "
		@"character index less than that of previous glyph"];
	    }
	  n = chunk->charIndex
	    + (GSIArrayItemAtIndex(&chunk->attrs, glyphOffset).ext).offset;
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
      if (glyphCount > 100 && glyphCount == GSIArrayCapacity(&chunk->glyphs))
	{
	  GSGlyphChunk	*newChunk = 0;
	  unsigned	pos;
	  unsigned	splitAt = glyphCount/2;
	  unsigned	splitChar;

	  splitChar = (GSIArrayItemAtIndex(&chunk->attrs, splitAt).ext).offset;
	  while (splitAt > 0 && splitChar
	    == (GSIArrayItemAtIndex(&chunk->attrs, splitAt-1).ext).offset)
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
	  if (splitAt <= glyphCount/4)
	    {
	      [NSException raise: NSInternalInconsistencyException
			  format: @"unable to split glyph chunk"];
	    }
	  /*
	   * Ok - split the chunk into two (roughly) equal parts.
	   */
	  splitChar
	    = (GSIArrayItemAtIndex(&chunk->attrs, splitAt).ext).offset;
	  newChunk = GSCreateGlyphChunk(chunk->glyphIndex + splitAt,
	    chunk->charIndex + splitChar);
	  GSIArrayInsertItem(glyphChunks, (GSIArrayItem)(void*)newChunk,
	    chunkIndex+1);
	  pos = 0;
	  while (GSIArrayCount(&chunk->glyphs) > splitAt)
	    {
	      GSGlyphAttrs	attrs;
	      NSGlyph		glyph;

	      /*
	       * Remove attributes from old chunk and add to new.
	       * Adjust offset for character index of new chunk.
	       */
	      attrs = GSIArrayItemAtIndex(&chunk->attrs, splitAt).ext;
	      GSIArrayRemoveItemAtIndex(&chunk->attrs, splitAt);
	      attrs.offset -= splitChar;
	      GSIArrayInsertItem(&newChunk->attrs,
		(GSIArrayItem)attrs, pos);

	      /*
	       * Remove glyph from old chunk and add to new.
	       */
	      glyph = GSIArrayItemAtIndex(&chunk->glyphs, splitAt).ulng;
	      GSIArrayRemoveItemAtIndex(&chunk->glyphs, splitAt);
	      GSIArrayInsertItem(&newChunk->glyphs,
		(GSIArrayItem)glyph, pos);

	      pos++;
	    }
	  /*
	   * And set up so we point at the correct half of the split chunk.
	   */
	  if (glyphIndex >= newChunk->glyphIndex)
	    {
	      chunkIndex++;
	      chunk = newChunk;
	      glyphCount = GSIArrayCount(&chunk->glyphs);
	      glyphOffset = glyphIndex - chunk->glyphIndex;
	    }
	}

      /*
       * Special handling for insertion at the start of a chunk - we
       * need to update the index values for the chunk, and (possibly)
       * the character offsets of every glyph in the chunk.
       */
      if (glyphOffset == 0)
	{
	  chunk->glyphIndex = glyphIndex;
	  if (chunk->charIndex != charIndex)
	    {
	      int	diff = chunk->charIndex - charIndex;

	      /*
	       * Changing character index of entire chunk.
	       */
	      for (pos = 0; pos < glyphCount; pos++)
		{
		  GSGlyphAttrs	tmp;

		  tmp = GSIArrayItemAtIndex(&chunk->attrs, pos).ext;
		  tmp.offset += diff;
		  GSIArraySetItemAtIndex(&chunk->attrs, (GSIArrayItem)tmp, pos);
		}
	    }
	}

      /*
       * At last we insert the glyph and its attributes into the chunk.
       */
      attrs.offset = charIndex - chunk->charIndex;
      GSIArrayInsertItem(&chunk->glyphs, (GSIArrayItem)aGlyph, glyphOffset);
      GSIArrayInsertItem(&chunk->attrs, (GSIArrayItem)attrs, glyphOffset);

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

  _numberOfGlyphs++;

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
_Sane(self);
}

// If there are any holes in the glyph stream this will cause glyph
// generation for all holes sequentially encountered until the desired
// index is available.  The first variant raises a NSRangeError if the
// requested index is out of bounds, the second does not, but instead
// optionally returns a flag indicating whether the requested index
// exists.
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

- (NSGlyph) glyphAtIndex: (unsigned)index
	    isValidIndex: (BOOL*)flag
{
#if USE_GLYPHS
  if (GSIArrayCount((GSIArray)_glyphGaps) > 0
    && (GSIArrayItemAtIndex((GSIArray)_glyphGaps, 0).ulng) <= index)
    {
      NSString		*string;
      unsigned long	gap;
      unsigned		textLength;

      string = [_textStorage string];
      textLength = [string length];

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
	       * a character one beyond the one that generated the glyph.
	       * This guarantees that we won't try to re-generate the
	       * preceeding glyph.
	       */
	      _JumpToGlyph(self, gap - 1);
	      startChar = _CharIndex(self) + 1;
	    }
	  if (gap == _numberOfGlyphs)
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
	  GSIArrayRemoveItemAtIndex((GSIArray)_glyphGaps, 0);	// Remove gap.
	  while (startChar < endChar)
	    {
	      unichar	c = [string characterAtIndex: startChar];

	      [self insertGlyph: (NSGlyph)c
		   atGlyphIndex: gap++
		 characterIndex: startChar++];
	    }
	}
    }
_Sane(self);
  if (_JumpToGlyph(self, index) == YES)
    {
      *flag = YES;
      return _Glyph(self);
    }
  else
    {
      *flag = NO;
      return NSNullGlyph;
    }
#else
  return (NSGlyph)[[_textStorage string] characterAtIndex: index];
#endif
}

// Replaces the glyph currently at glyphIndex with newGlyph.  The
// character index of the glyph is assumed to remain the same
// (although it can, of course, be set explicitly if needed).
- (void) replaceGlyphAtIndex: (unsigned)index
		   withGlyph: (NSGlyph)newGlyph
{
  if (_JumpToGlyph(self, index) == NO)
    {
      [NSException raise: NSRangeException
		  format: @"glyph index out of range"];
    }
  _SetGlyph(self, newGlyph);
}

// This causes glyph generation similarly to asking for a single
// glyph.  It formats a sequence of NSGlyphs (unsigned long ints).  It
// does not include glyphs that aren't shown in the result but does
// zero-terminate the array.  The memory passed in to the function
// should be large enough for at least glyphRange.length+1 elements.
// The actual number of glyphs stuck into the array is returned (not
// counting the null-termination).  RM!!! check out the private method
// "_packedGlyphs:range:length:" if you need to send glyphs to the
// window server.  It returns a (conceptually) autoreleased array of
// big-endian packeg glyphs.  Don't use this method to do that.
- (unsigned) getGlyphs: (NSGlyph*)glyphArray
		 range: (NSRange)glyphRange
{
  unsigned	packed = 0;
  unsigned	toFetch = glyphRange.length;

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
	  if (_Attrs(self).isNotShown == 0)
	    {
	      glyphArray[packed++] = _Glyph(self);
	    }
	  _Step(self);	// Move to next glyph.
	}
    }
  glyphArray[packed] = 0;
  return packed;
}

// Removes all glyphs in the given range from the storage.
- (void) deleteGlyphsInRange: (NSRange)aRange
{
  unsigned	chunkStart;
  unsigned	chunkEnd;
  unsigned	offset;
  unsigned	from;
  unsigned	pos;
  GSGlyphChunk	*chunk;

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
   * Get start chunk and remove any glyphs in specificed range.
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
	  GSIArrayRemoveItemsFromIndex(&chunk->attrs, offset);
	}
    }

  chunk = (GSGlyphChunk*)GSIArrayItemAtIndex(glyphChunks, chunkEnd).ptr;
  offset = NSMaxRange(aRange)-1 - chunk->glyphIndex;
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
      GSIArrayRemoveItemAtIndex(&chunk->attrs, from);
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
	  pos++;
	}
      else if (val < aRange.length)
	{
	  GSIArrayRemoveItemAtIndex((GSIArray)_glyphGaps, pos);
	}
      else
	{
	  val -= aRange.length;
	  GSIArraySetItemAtIndex((GSIArray)_glyphGaps, (GSIArrayItem)val, pos);
	  pos++;
	}
    }

  _numberOfGlyphs -= aRange.length;
_Sane(self);
}

// If there are any holes in the glyph stream, this will cause all
// invalid character ranges to have glyphs generated for them.
- (unsigned) numberOfGlyphs
{
#if	USE_GLYPHS
  if (GSIArrayCount((GSIArray)_glyphGaps) > 0)
    {
      BOOL	valid;

      /*
       * Force generation of all glyphs.
       */
      [self glyphAtIndex: 0x7fffffff isValidIndex: &valid];
    }
  return _numberOfGlyphs;
#else
  return [_textStorage length];
#endif
}

//
// Mapping characters to glyphs
//
// Sets the index of the corresponding character for the glyph at the
// given glyphIndex.
- (void) setCharacterIndex: (unsigned)charIndex
	   forGlyphAtIndex: (unsigned)glyphIndex
{
  GSGlyphAttrs	attrs;
  int		diff;

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
  if (_glyphIndex == 0)
    {
      GSGlyphChunk	*chunk = (GSGlyphChunk*)_currentGlyphs;

      diff = charIndex - _CharIndex(self);
      chunk->charIndex += diff;
      while (_Step(self) == YES && (GSGlyphChunk*)_currentGlyphs == chunk)
	{
	  attrs = _Attrs(self);
	  attrs.offset += diff;
	  _SetAttrs(self, attrs);
	}
    }
  else
    {
      attrs = _Attrs(self);
      attrs.offset += diff;
      _SetAttrs(self, attrs);
    }
_Sane(self);
}

// If there are any holes in the glyph stream this will cause glyph
// generation for all holes sequentially encountered until the desired
// index is available.
- (unsigned) characterIndexForGlyphAtIndex: (unsigned)glyphIndex
{
#if	USE_GLYPHS
  if (_JumpToGlyph(self, glyphIndex) == NO)
    {
      BOOL	exists;

      [self glyphAtIndex: glyphIndex isValidIndex: &exists];
      if (exists == NO)
	{
	  /*
	   * As a special case, the glyph index just beyond the end of
	   * the glyph stream is known to map to the character index just
	   * beyond the end of the text.
	   */
	  if (glyphIndex == _numberOfGlyphs)
	    {
	      return [_textStorage length];
	    }
	  [NSException raise: NSRangeException
		      format: @"glyph index out of range"];
	}
      _JumpToGlyph(self, glyphIndex);
    }
  return _CharIndex(self);  
#else
  return glyphIndex;
#endif
}

// These two methods can cause glyph generation.  Returns the range of
// characters that generated the glyphs in the given glyphRange.
// actualGlyphRange, if not NULL, will be set to the full range of
// glyphs that the character range returned generated.  This range may
// be identical or slightly larger than the requested glyphRange.  For
// instance, if the text storage contains the unichar (o-umlaut) and
// the glyph store contains the two atomic glyphs "o" and (umlaut),
// and if the glyphRange given encloses only the first or second
// glyph, the actualGlyphRange will be set to enclose both glyphs.
- (NSRange) characterRangeForGlyphRange: (NSRange)glyphRange
		       actualGlyphRange: (NSRange*)actualGlyphRange
{
#if	USE_GLYPHS
  NSRange	cRange;
  NSRange	gRange = glyphRange;
  unsigned	cEnd;
  BOOL		exists;

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
      if (NSMaxRange(glyphRange) > _numberOfGlyphs)
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

  if (actualGlyphRange != 0)
    {
      *actualGlyphRange = gRange;
    }
  return cRange;
#else
  // Currently gyphIndex is the same as character index
  if (actualGlyphRange != NULL)
    *actualGlyphRange = glyphRange;
  return glyphRange;
#endif
}

// Returns the range of glyphs that are generated from the unichars in
// the given charRange.  actualCharRange, if not NULL, will be set to
// the actual range of characters that fully define the glyph range
// returned.  This range may be identical or slightly larger than the
// requested characterRange.  For instance, if the text storage
// contains the unichars "o" and (umlaut) and the glyph store contains
// the single precomposed glyph (o-umlaut), and if the charcterRange
// given encloses only the first or second unichar, the
// actualCharRange will be set to enclose both unichars.
- (NSRange) glyphRangeForCharacterRange: (NSRange)charRange
		   actualCharacterRange: (NSRange*)actualCharRange
{
#if	USE_GLYPHS
  unsigned	pos;
  NSRange	cRange = charRange;
  NSRange	gRange;
  unsigned	numGlyphs;

  numGlyphs = [self numberOfGlyphs];	// Force generation of glyphs.

  /*
   * Locate the first glyph corresponding to the start character.
   */
  _JumpToChar(self, charRange.location);
  gRange.location = _GlyphIndex(self);

  /*
   * Adjust start character if necessary.
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
  if (actualCharRange != 0)
    {
      *actualCharRange = cRange;
    }
  return gRange;
#else
  // Currently gyphIndex is the same as character index
  if (actualCharRange != NULL)
    *actualCharRange = charRange;
  return charRange;
#endif
}

//
// Setting glyph attributes 
//

// Each NSGlyph has an attribute field, yes?  This method is
// primitive.  It does not cause any invalidation of other stuff.
// This method also will not cause glyph generation.  The glyph being
// set must already be there.  This method is used by the
// NSGlyphGenerator to set attributes.  It is not usually necessary
// for anyone but the glyph generator (and perhaps the typesetter) to
// call it.  It is provided as a public method so subclassers can
// extend it to accept other glyph attributes.  To add new glyph
// attributes to the text system you basically need to do two things.
// You need to write a rulebook which will generate the attributes (in
// rulebooks attributes are identified by integer tags).  Then you
// need to subclass NSLayoutManager to provide someplace to store the
// new attribute and to override this method and
// -attribute:forGlyphAtIndex: to understand the integer tag which
// your new rulebook is generating.  NSLayoutManager's implementation
// understands the glyph attributes which it is prepared to remember.
// Your override should pass any glyph attributes it does not
// understand up to the superclass's implementation.
- (void) setIntAttribute: (int)attribute
		   value: (int)anInt
	 forGlyphAtIndex: (unsigned)glyphIndex
{
  GSGlyphAttrs	attrs;

  if (_JumpToGlyph(self, glyphIndex) == NO)
    {
      [NSException raise: NSRangeException
		  format: @"glyph index out of range"];
    }
  attrs = _Attrs(self);
  if (attribute == GSGlyphDrawsOutsideLineFragment)
    {
      if (anInt == 0)
	{
	  attrs.drawsOutsideLineFragment = 0;
	}
      else
	{
	  attrs.drawsOutsideLineFragment = 1;
	}
    }
  else if (attribute == GSGlyphIsNotShown)
    {
      if (anInt == 0)
	{
	  attrs.isNotShown = 0;
	}
      else
	{
	  attrs.isNotShown = 1;
	}
    }
  else if (attribute == GSGlyphGeneration)
    {
      attrs.generation = anInt;
    }
  else if (attribute == GSGlyphInscription)
    {
      attrs.inscription = anInt;
    }
  _SetAttrs(self, attrs);
}

// This returns the value for the given glyph attribute at the glyph
// index specified.  Most apps will not have much use for this info
// but the typesetter and glyph generator might need to know about
// certain attributes.  You can override this method to know how to
// return any custom glyph attributes you want to support.
- (int) intAttribute: (int)attribute
     forGlyphAtIndex: (unsigned)glyphIndex
{
  GSGlyphAttrs	attrs;

  if (_JumpToGlyph(self, glyphIndex) == NO)
    {
      [NSException raise: NSRangeException
		  format: @"glyph index out of range"];
    }
  attrs = _Attrs(self);

  if (attribute == GSGlyphDrawsOutsideLineFragment)
    {
      if (attrs.drawsOutsideLineFragment == 0)
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
      if (attrs.isNotShown == 0)
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
      return attrs.generation;
    }
  else if (attribute == GSGlyphInscription)
    {
      return attrs.inscription;
    }

  return 0;
}

//
// Handling layout for text containers 
//
// These methods are fairly primitive.  They do not cause any kind of
// invalidation to happen.  The glyphs being set must already exist.
// This is not a hardship since the NSTypesetter will have had to ask
// for the actual glyphs already by the time it goes to set this, and
// asking for the glyphs causes the glyph to be generated if
// necessary.  Associates the given container with the given range of
// glyphs.  This method should be called by the typesetter first (ie
// before setting line fragment rect or any of the layout bits) for
// each range of glyphs it lays out.  This method will set several key
// layout atttributes (like not shown and draws outside line fragment)
// to their default values.
- (void) setTextContainer: (NSTextContainer*)aTextContainer
	    forGlyphRange: (NSRange)glyphRange
{
  /* TODO */
}

// All of these methods can cause glyph generation AND layout.
// Returns the range of characters which have been laid into the given
// container.  This is a less efficient method than the similar
// -textContainerForGlyphAtIndex:effectiveRange:.
- (NSRange) glyphRangeForTextContainer: (NSTextContainer*)aTextContainer
{
  /* TODO */
  return NSMakeRange(NSNotFound, 0);
}

// Returns the container in which the given glyph is laid and
// (optionally) by reference the whole range of glyphs that are in
// that container.  This will cause glyph generation AND layout as
// needed.
- (NSTextContainer*) textContainerForGlyphAtIndex: (unsigned)glyphIndex
                                   effectiveRange: (NSRange*)effectiveRange
{
  /* TODO */
  return [_textContainers objectAtIndex: 0];
}

//
// Handling line fragment rectangles 
//
// Associates the given line fragment bounds with the given range of
// glyphs.
- (void) setLineFragmentRect: (NSRect)fragmentRect
	       forGlyphRange: (NSRange)glyphRange
		    usedRect: (NSRect)usedRect
{
  /* TODO */
}

// Returns the rect for the line fragment in which the given glyph is
// laid and (optionally) by reference the whole range of glyphs that
// are in that fragment.  This will cause glyph generation AND layout
// as needed.
- (NSRect) lineFragmentRectForGlyphAtIndex: (unsigned)glyphIndex
			    effectiveRange: (NSRange*)lineFragmentRange
{
  /* TODO */
  return NSZeroRect;
}

// Returns the usage rect for the line fragment in which the given
// glyph is laid and (optionally) by reference the whole range of
// glyphs that are in that fragment.  This will cause glyph generation
// AND layout as needed.
- (NSRect) lineFragmentUsedRectForGlyphAtIndex: (unsigned)glyphIndex
				effectiveRange: (NSRange*)lineFragmentRange
{
  /* TODO */
  return NSZeroRect;
}

// Sets the bounds and container for the extra line fragment.  The
// extra line fragment is used when the text backing ends with a hard
// line break or when the text backing is totally empty to define the
// extra line which needs to be displayed.  If the text backing does
// not end with a hard line break this should be set to NSZeroRect and
// nil.
- (void) setExtraLineFragmentRect: (NSRect)aRect
			 usedRect: (NSRect)usedRect
		    textContainer: (NSTextContainer*)aTextContainer
{
  /* TODO */
}

// Return info about the extra line fragment.
- (NSRect) extraLineFragmentRect 
{
  /* TODO */
  return NSZeroRect;
}

- (NSRect) extraLineFragmentUsedRect 
{
  /* TODO */
  return NSZeroRect;
}

- (NSTextContainer*) extraLineFragmentTextContainer 
{
  /* TODO */
  return nil;
}

// Returns the container's currently used area.  This is the size that
// the view would need to be in order to display all the stuff that is
// currently laid into the container.  This causes no generation.
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

// Used to indicate that a particular glyph for some reason marks
// outside its line fragment bounding rect.  This can commonly happen
// if a fixed line height is used (consider a 12 point line height and
// a 24 point glyph).
- (void) setDrawsOutsideLineFragment: (BOOL)flag
		     forGlyphAtIndex: (unsigned)glyphIndex
{
  [self setIntAttribute: GSGlyphDrawsOutsideLineFragment
	value: 1
	forGlyphAtIndex: glyphIndex];
}

// Returns whether the glyph will make marks outside its line
// fragment's bounds.
- (BOOL) drawsOutsideLineFragmentForGlyphAtIndex: (unsigned)glyphIndex
{
  if ([self intAttribute: GSGlyphDrawsOutsideLineFragment
	    forGlyphAtIndex: glyphIndex] == 1)
    {
      return YES;
    }
  return NO;
}

//
// Layout of glyphs 
//

// Sets the location to draw the first glyph of the given range at.
// Setting the location for a glyph range implies that its first glyph
// is NOT nominally spaced with respect to the previous glyph.  When
// all is said and done all glyphs in the layoutManager should have
// been included in a range passed to this method.  But only glyphs
// which start a new nominal rtange should be at the start of such
// ranges.  Glyph locations are given relative the their line fragment
// bounding rect's origin.
- (void) setLocation: (NSPoint)aPoint
forStartOfGlyphRange: (NSRange)glyphRange
{
  /* TODO */
}

// Returns the location that the given glyph will draw at.  If this
// glyph doesn't have an explicit location set for it (ie it is part
// of (but not first in) a sequence of nominally spaced characters),
// the location is calculated from the location of the last glyph with
// a location set.  Glyph locations are relative the their line
// fragment bounding rect's origin (see
// -lineFragmentForGlyphAtIndex:effectiveRange: below for finding line
// fragment bounding rects).  This will cause glyph generation AND
// layout as needed.
- (NSPoint) locationForGlyphAtIndex: (unsigned)glyphIndex
{
  /* TODO */
  return NSZeroPoint;
}

// Returns the range including the first glyph from glyphIndex on back
// that has a location set and up to, but not including the next glyph
// that has a location set.  This is a range of glyphs that can be
// shown with a single postscript show operation.
- (NSRange) rangeOfNominallySpacedGlyphsContainingIndex: (unsigned)glyphIndex
{
  /* TODO */
  return NSMakeRange(NSNotFound, 0);
}

// Returns an array of NSRects and the number of rects by reference
// which define the region in container that encloses the given range.
// If a selected range is given in the second argument, the rectangles
// returned will be correct for drawing the selection.  Selection
// rectangles are generally more complicated than enclosing rectangles
// and supplying a selected range is the clue these methods use to
// determine whether to go to the trouble of doing this special work.
// If the caller is interested in this more from an enclosing point of
// view rather than a selection point of view pass {NSNotFound, 0} as
// the selected range.  This method works hard to do the minimum
// amount of work required to answer the question.  The resulting
// array is owned by the layoutManager and will be reused when either
// of these two methods OR -boundingRectForGlyphRange:inTextContainer:
// is called.  Note that one of these methods may be called
// indirectly.  The upshot is that if you aren't going to use the
// rects right away, you should copy them to another location.
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

// Returns the smallest bounding rect (in container coordinates) which
// completely encloses the glyphs in the given glyphRange that are in
// the given container.  If no container is given, then the container
// of the first glyph is assumed.  Basically, the range is intersected
// with the container's range before computing the bounding rect.
// This method can be used to translate glyph ranges into display
// rectangles for invalidation.
- (NSRect) boundingRectForGlyphRange: (NSRange)glyphRange
		     inTextContainer: (NSTextContainer*)aTextContainer
{
  /* TODO */
  return NSZeroRect;
}

// Returns the minimum contiguous glyph range that would need to be
// displayed in order to draw all glyphs that fall (even partially)
// within the bounding rect given.  This range might include glyphs
// which do not fall into the rect at all.  At most this will return
// the glyph range for the whole container.  The "WithoutFillingHoles"
// variant will not generate glyphs or perform layout in attempting to
// answer, and, thus, will potentially not be totally correct.
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

// Returns the index of the glyph which under the given point which is
// expressed in the given container's coordinate system.  If no glyph
// is under the point the "nearest" glyph is returned where "nearest"
// is defined in such a way that selection works like it should.  See
// the implementation for details.  partialFraction, if provided, is
// set to the fraction of the distance between the location of the
// glyph returned and the location of the next glyph that the point is
// at.
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

//
// Display of special glyphs 
//
// Some glyphs are not shown.  The typesetter decides which ones and
// sets this attribute in layoutManager where the view can find it.
- (void) setNotShownAttribute: (BOOL)flag
	      forGlyphAtIndex: (unsigned)glyphIndex
{
  [self setIntAttribute: GSGlyphIsNotShown
	          value: 1
	forGlyphAtIndex: glyphIndex];
}

// Some glyphs are not shown.  This will cause glyph generation and
// layout as needed..
- (BOOL) notShownAttributeForGlyphAtIndex: (unsigned)glyphIndex
{
  if ([self intAttribute: GSGlyphIsNotShown forGlyphAtIndex: glyphIndex] == 1)
    {
      return YES;
    }
  return NO;
}

// If YES, and the rulebooks and fonts in use support it, whitespace
// and other "invisible" unicodes will be shown with special glyphs
// (ie "." for space, the little CR icon for new lines, etc...)
- (void) setShowsInvisibleCharacters: (BOOL)flag
{
  _showsInvisibleChars = flag;
}

- (BOOL) showsInvisibleCharacters 
{
  return _showsInvisibleChars;
}

// If YES, and the rulebooks and fonts in use support it, control
// characters will be rendered visibly (usually like "^M", but
// possibly with special glyphs if the the font and rulebook supports
// it).
- (void) setShowsControlCharacters: (BOOL)flag
{
  _showsControlChars = flag;
}

- (BOOL) showsControlCharacters
{
  return _showsControlChars;
}

//
// Controlling hyphenation 
//
- (void) setHyphenationFactor: (float)factor
{
  _hyphenationFactor = factor;
}

- (float) hyphenationFactor
{
  return _hyphenationFactor;
}

//
// Finding unlaid characters/glyphs 
//
// Returns (by reference) the character index or glyph index or both
// of the first unlaid character/glyph in the layout manager at this
// time.
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

//
// Using screen fonts 
//
// Sets whether this layoutManager will use screen fonts when it is
// possible to do so.
- (void) setUsesScreenFonts: (BOOL)flag
{
  _usesScreenFonts = flag;
}

- (BOOL) usesScreenFonts 
{
  return _usesScreenFonts;
}

// Returns a font to use in place of originalFont.  This method is
// used to substitute screen fonts for regular fonts.  If screen fonts
// are allowed AND no NSTextView managed by this layoutManager is
// scaled or rotated AND a screen font is available for originalFont,
// it is returned, otherwise originalFont is returned.  MF:??? This
// method will eventually need to know or be told whether use of
// screen fonts is appropriate in a given situation (ie screen font
// used might be enabled or disabled, we might be printing, etc...).
// This method causes no generation.
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

//
// Handling rulers 
//
// These return, respectively, an array of text ruler objects for the
// current selection and the accessory view that the text system uses
// for ruler.  If you have turned off automatic ruler updating through
// the use of setUsesRulers: so that you can do more complex things,
// but you still want to display the appropriate text ruler objects
// and/or accessory view, you can use these methods.
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
  return [[_textContainers objectAtIndex: 0] textView];
  /* WARNING: Uncommenting the following makes initialization 
     with the other text objects more difficult. */
  //  return _firstTextView;
}

// This method is special in that it won't cause layout if the
// beginning of the selected range is not yet laid out.  Other than
// that this method could be done through other API.
- (NSTextView*) textViewForBeginningOfSelection
{
  return NULL;
}

//
// Drawing 
//
- (void) drawBackgroundForGlyphRange: (NSRange)glyphRange
			     atPoint: (NSPoint)containerOrigin
{
}

// These methods are called by NSTextView to do drawing.  You can
// override these if you think you can draw the stuff any better
// (but not to change layout).  You can call them if you want, but
// focus must already be locked on the destination view or MF:???image?.
// -drawBackgroundGorGlyphRange:atPoint: should draw the background
// color and selection and marked range aspects of the text display. 
// -drawGlyphsForGlyphRange:atPoint: should draw the actual glyphs. 
// The point in either method is the container origin in the currently
// focused view's coordinates for the container the glyphs lie in.
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

// The first of these methods actually draws an appropriate underline
// for the glyph range given.  The second method potentailly breaks
// the range it is given up into subranges and calls drawUnderline...
// for ranges that should actually have the underline drawn.  As
// examples of why there are two methods, consider two situations.
// First, in all cases you don't want to underline the leading and
// trailing whitespace on a line.  The -underlineGlyphRange... method
// is passed glyph ranges that have underlining turned on, but it will
// then look for this leading and trailing white space and only pass
// the ranges that should actually be underlined to -drawUnderline...
// Second, if the underlineType: indicates that only words, (ie no
// whitespace), should be underlined, then -underlineGlyphRange...
// will carve the range it is passed up into words and only pass word
// ranges to -drawUnderline.
- (void) underlineGlyphRange: (NSRange)glyphRange
	       underlineType: (int)underlineType
	    lineFragmentRect: (NSRect)lineRect
      lineFragmentGlyphRange: (NSRange)lineGlyphRange
	     containerOrigin: (NSPoint)containerOrigin
{
  /* TODO */
}

//
// Setting the delegate 
//
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

  for (i=0; i < [lineStarts count]; i++)
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
