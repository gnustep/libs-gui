/*
   GSLayoutManager_internal.h

   Copyright (C) 2002 Free Software Foundation, Inc.

   Author: Alexander Malmberg <alexander@malmberg.org>
   Date: 2002

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/

#ifndef _GNUstep_H_GSLayoutManager_internal
#define _GNUstep_H_GSLayoutManager_internal

#include <AppKit/GSLayoutManager.h>


/*
TODO:
Since temporary attributes are set for _character_ ranges and not _glyph_
ranges, a bunch of things could be simplified here (in particular, a
character can't be in several runs anymore, so there's no need to worry
about that or search over run boundaries).

(2002-11-27): All comments should be clarified now.
*/


/* Logarithmic time for lookups et al for up to 2^SKIP_LIST_DEPTH runs.
Only the head may actually have the maximum level. */
/* OPT: tweak */
#define SKIP_LIST_DEPTH 15

#define SKIP_LIST_LEVEL_PROBABILITY 2


typedef struct GSLayoutManager_glyph_run_head_s
{
  struct GSLayoutManager_glyph_run_head_s *next;

  /* char_length must always be accurate. glyph_length is the number of
  valid glyphs counting from the start. For a level 0 head, it's the number
  of glyphs in that run. */
  int glyph_length,char_length;

  /* Glyph generation is complete for all created runs. */
  unsigned int complete:1;
} glyph_run_head_t;


typedef struct
{
  NSGlyph g;

  /* This if the offset for the first character this glyph
  is mapped to; it is mapped to all characters between it and the next
  character explicitly mapped to a glyph.

  The char_offset must be strictly increasing for all glyphs; if reordering
  is necessary, the mapping will have to be range to range. (Eg. if you
  have characters 'ab' mapped to glyphs 'AB', reordered to 'BA', then the
  range 'ab' will be mapped to the range 'BA'. */
  int char_offset:21; /* This could be made a lot smaller, if necessary */

  unsigned int drawsOutsideLineFragment:1;
  unsigned int isNotShown:1;
  unsigned int inscription:3;
  /* 3 unused */
} glyph_t;


@class NSParagraphStyle;
@class NSColor;
@class NSTextAttachment;

typedef struct GSLayoutManager_glyph_run_s
{
  glyph_run_head_t head;
  glyph_run_head_t *prev;

  /* Zero-based, so it's really the number of heads in addition to the
  one included in glyph_run_t. */
  int level;

  /* All glyph-generation-affecting attributes are same as last run. This
  doesn't have to be set if a run is continued, but if it is set, it must
  be correct (it is (will, someday) be used to merge small runs created
  by repeated inserts in a small range; not merging when we can merge
  doesn't cost much, but merging when we shouldn't would mess up attributes
  for those runs).
  */
  unsigned int continued:1;

  /* Bidirectional-level, as per the unicode bidirectional algorithm
  (unicode standard annex #9). Only valid if glyphs have been generated
  (in particular, runs for which glyphs haven't been generated may not be
  all at the same level). */
  /* TODO2: these aren't filled in or used anywhere yet */
  unsigned int bidi_level:6;

  /* Font for this run. */
  NSFont *font;
  int ligature;

  /* YES if there's an explicit kern attribute. Currently, ligatures aren't
  used when explicit kerning is available (TODO). */
  BOOL explicit_kern;

  glyph_t *glyphs;
} glyph_run_t;


@interface GSLayoutManager (backend)
-(unsigned int) _findSafeBreakMovingBackwardFrom: (unsigned int)ch;
-(unsigned int) _findSafeBreakMovingForwardFrom: (unsigned int)ch;
-(void) _generateGlyphsForRun: (glyph_run_t *)run  at: (unsigned int)pos;
@end


/* All positions and lengths in glyphs */
typedef struct
{
  unsigned int pos,length;
  NSPoint p;
} linefrag_point_t;

typedef struct
{
  NSRect rect,used_rect;
  unsigned int pos,length;

  linefrag_point_t *points;
  int num_points;
} linefrag_t;

typedef struct GSLayoutManager_textcontainer_s
{
  NSTextContainer *textContainer;

  BOOL started,complete;
  unsigned int pos,length;

  linefrag_t *linefrags;
  int num_linefrags;
} textcontainer_t;



@interface GSLayoutManager (glyphs_helpers)

-(void) _run_cache_attributes: (glyph_run_t *)r : (NSDictionary *)attributes;
-(void) _run_copy_attributes: (glyph_run_t *)dst : (const glyph_run_t *)src;
-(void) _run_free_attributes: (glyph_run_t *)r;

-(void) _initGlyphs;
-(void) _freeGlyphs;

-(void) _glyphDumpRuns;

-(void) _generateGlyphsUpToCharacter: (unsigned int)last;
-(void) _generateGlyphsUpToGlyph: (unsigned int)last;

-(glyph_run_t *) _glyphForCharacter: (unsigned int)target
	index: (unsigned int *)rindex
	positions: (unsigned int *)rpos : (unsigned int *)rcpos;
@end



@interface GSLayoutManager (layout_helpers)
-(void) _freeLayout;
-(void) _invalidateLayoutFromContainer: (int)idx;

-(void) _doLayout; /* TODO: this is just a hack until proper incremental layout is done */
-(void) _doLayoutToGlyph: (unsigned int)glyphIndex;
-(void) _doLayoutToContainer: (int)cindex;
@end


/* Some helper macros */

/* r is a run, pos and cpos are the glyph and character positions of the
run, i is the glyph index in the run. */

/* Steps forward to the next glyph. If there is no next glyph, r will be
the last run and i==r->head.glyph_length. */
#define GLYPH_STEP_FORWARD(r,i,pos,cpos) \
  { \
    i++; \
    while (i==r->head.glyph_length) \
      { \
	if (!r->head.next || !r->head.next->complete) \
	  { \
	    if (cpos+r->head.char_length==[_textStorage length]) \
	      break; \
	    [self _generateGlyphsUpToCharacter: cpos+r->head.char_length]; \
	  } \
	pos+=r->head.glyph_length; \
	cpos+=r->head.char_length; \
	r=(glyph_run_t *)r->head.next; \
	i=0; \
      } \
  }

/* Steps backward to the previous glyph. If there is no previous glyph, r
will be the first glyph and i==-1. */
#define GLYPH_STEP_BACKWARD(r,i,pos,cpos) \
  { \
    i--; \
    while (i<0 && r->prev) \
      { \
	r=(glyph_run_t *)r->prev; \
	pos-=r->head.glyph_length; \
	cpos-=r->head.char_length; \
	i=r->head.glyph_length-1; \
      } \
  }

/* OPT: can do better than linear scan? */

/* Scans forward from glyph i in run r (with positions pos and cpos) while
condition holds. r, i, pos, and cpos must be simple variables. When done, r,
i, pos, and cpos will be set for the first glyph for which the condition
doesn't hold. If there is no such glyph, r is the last run and
i==r->head.glyph_length. */
#define GLYPH_SCAN_FORWARD(r,i,pos,cpos,condition) \
  { \
    while (condition) \
      { \
	GLYPH_STEP_FORWARD(r,i,pos,cpos) \
	if (i==r->head.glyph_length) \
	  break; \
      } \
  }

/* Scan backward. r, i, pos, and cpos will be set to the first glyph for
which condition doesn't hold. If there is no such glyph, r is the first run
and i==-1. */
#define GLYPH_SCAN_BACKWARD(r,i,pos,cpos,condition) \
  { \
    while (condition) \
      { \
	GLYPH_STEP_BACKWARD(r,i,pos,cpos) \
	if (i==-1) \
	  break; \
      } \
  }

glyph_run_t *GSLayoutManager_run_for_glyph_index(unsigned int glyphIndex,
	glyph_run_head_t *glyphs,unsigned int *glyph_pos,unsigned int *char_pos);
#define run_for_glyph_index GSLayoutManager_run_for_glyph_index

#endif

