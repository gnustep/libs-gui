/*
   GSLayoutManager.m

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

#include <AppKit/GSLayoutManager_internal.h>

#include <Foundation/NSCharacterSet.h>
#include <Foundation/NSException.h>
#include <Foundation/NSValue.h>

#include <AppKit/GSTypesetter.h>
#include <AppKit/NSTextStorage.h>
#include <AppKit/NSTextContainer.h>

/* just for NSAttachmentCharacter */
#include <AppKit/NSTextAttachment.h>



/* TODO: is using rand() here ok? */
static int random_level(void)
{
  int i;
  for (i = 0; i < SKIP_LIST_DEPTH - 2; i++)
    if ((rand() % SKIP_LIST_LEVEL_PROBABILITY) != 0)
      break;
  return i;
}


/***** Glyph handling *****/

@implementation GSLayoutManager (glyphs_helpers)


-(void) _run_cache_attributes: (glyph_run_t *)r : (NSDictionary *)attributes
{
  /* set up attributes for this run */
  NSNumber *n;

  r->explicit_kern = !![attributes objectForKey: NSKernAttributeName];

  n = [attributes objectForKey: NSLigatureAttributeName];
  if (n)
    r->ligature = [n intValue];
  else
    r->ligature = 1;

  r->font = [typesetter fontForCharactersWithAttributes: attributes];
  /* TODO: it might be useful to change this slightly:
  Returning a nil font from -fontForCharactersWithAttributes: causes those
  characters to not be displayed (ie. no glyphs are generated).

  How would glyph<->char mapping be handled? Map the entire run to one
  NSNullGlyph?
  */
  if (!r->font)
    r->font = [NSFont userFontOfSize: 0];
  r->font = [self substituteFontForFont: r->font];
  r->font = [r->font retain];
}

-(void ) _run_free_attributes: (glyph_run_t *)r
{
  [r->font release];
}

-(void) _run_copy_attributes: (glyph_run_t *)dst : (const glyph_run_t *)src
{
  dst->font = [src->font retain];
  dst->ligature = src->ligature;
  dst->explicit_kern = src->explicit_kern;
}


-(void) _freeGlyphs
{
  glyph_run_t *cur, *next;
  glyph_run_head_t *h;

  if (!glyphs)
    return;

  h = glyphs;
  h += SKIP_LIST_DEPTH - 1;

  for (cur = (glyph_run_t *)h->next; cur; cur = next)
    {
      next = (glyph_run_t *)cur->head.next;
      if (cur->glyphs)
	free(cur->glyphs);
      [self _run_free_attributes: cur];
      h = &cur->head;
      h -= cur->level;
      free(h);
    }

  free(glyphs);
  glyphs = NULL;
}

-(void) _initGlyphs
{
  int i, size;
  glyph_run_head_t *h;

  size = sizeof(glyph_run_head_t) * (SKIP_LIST_DEPTH - 1) + sizeof(glyph_run_t);
  glyphs = malloc(size);
  memset(glyphs, 0, size);
  for (h = glyphs, i = SKIP_LIST_DEPTH; i; i--, h++)
    h->complete = 1;
}

-(void) _glyphDumpRuns
{
  printf("--- dumping runs\n");
  {
    glyph_run_t *h;
    h = (glyph_run_t *)(glyphs + SKIP_LIST_DEPTH - 1)->next;
    for (; h; h = (glyph_run_t *)h->head.next)
      {
	printf("%08x %i chars, %i glyphs, %i complete, prev %08x next %08x\n",
		(int)h, h->head.char_length, h->head.glyph_length, h->head.complete,
		(int)h->prev, (int)h->head.next);
	printf("         level %i, continued %i\n", h->level, h->continued);
/*	if (h->head.complete)
	  {
	    int i;
	    printf("glyphs:\n");
	    for (i = 0;i < h->head.glyph_length;i++)
	      printf("%5i %04x  ",h->glyphs[i].char_offset,h->glyphs[i].g);
	    printf("\n");
	  }*/
      }
  }
  printf("- structure\n");
  {
    glyph_run_head_t *h, *g;
    int i;

    printf("    head: ");
    for (i = 0, h = glyphs + SKIP_LIST_DEPTH - 1; i < SKIP_LIST_DEPTH; i++, h--)
      printf("%8x %i %3i %3i|", (int)h->next, h->complete, h->char_length, h->glyph_length);
    printf("\n");
    h = (glyphs + SKIP_LIST_DEPTH - 1)->next;
    for (; h; h = h->next)
      {
	printf("%8x: ", (int)h);
	for (g = h, i = ((glyph_run_t *)h)->level; i >= 0; i--, g--)
	  printf("%8x %i %3i %3i|", (int)g->next, g->complete, g->char_length, g->glyph_length);
	  printf("\n");
      }
  }
  printf("--- done\n");
  fflush(stdout);
}


/* NSLayoutManager uses this is, so it can't be static (and since it isn't,
it needs a reasonably unique name). */
glyph_run_t *GSLayoutManager_run_for_glyph_index(unsigned int glyphIndex,
	glyph_run_head_t *glyphs, unsigned int *glyph_pos,
	unsigned int *char_pos)
{
  int level;
  glyph_run_head_t *h;
  int pos, cpos;

  if (glyphs->glyph_length <= glyphIndex)
    return NULL;

  pos = cpos = 0;
  level = SKIP_LIST_DEPTH;
  h = glyphs;
  while (1)
    {
      if (!h->complete)
	{
	  h++;
	  level--;
	  if (!level)
	    return NULL;
	  continue;
	}
	if (glyphIndex >= pos + h->glyph_length)
	  {
	    pos += h->glyph_length;
	    cpos += h->char_length;
	    h = h->next;
	    if (!h)
	      return NULL;
	    continue;
	  }
	if (level > 1)
	  {
	    h++;
	    level--;
	    continue;
	  }

	*glyph_pos = pos;
	if (char_pos)
	  *char_pos = cpos;
	return (glyph_run_t *)h;
    }
}

static glyph_run_t *run_for_character_index(unsigned int charIndex,
	glyph_run_head_t *glyphs, unsigned int *glyph_pos,
	unsigned int *char_pos)
{
  int level;
  glyph_run_head_t *h;
  int pos, cpos;

  if (glyphs->char_length <= charIndex)
    return NULL;

//printf("run_for_character_index(%i)\n",charIndex);

  pos = cpos = 0;
  level = SKIP_LIST_DEPTH;
  h = glyphs;
  while (1)
    {
      if (!h->complete)
	{
	  h++;
	  level--;
	  if (!level)
	    return NULL;
	  continue;
	}
      if (charIndex >= cpos + h->char_length)
	{
	  pos += h->glyph_length;
	  cpos += h->char_length;
	  h = h->next;
	  if (!h)
	    return NULL;
	  continue;
	}
      if (level > 1)
	{
	  h++;
	  level--;
	  continue;
	}
      
      *glyph_pos = pos;
      if (char_pos)
	*char_pos = cpos;
//printf("got %p (at %i %i)\n",h,pos,cpos);
      return (glyph_run_t *)h;
    }
}


/* Recalculates char_length, glyph_length, and complete for a
glyph_run_head_t. All "children" of this head must have valid values. */
static void run_fix_head(glyph_run_head_t *h)
{
  glyph_run_head_t *h2, *next;
  next = h->next;
  if (next)
    next++;
  h2 = h + 1;
  h->complete = 1;
  h->glyph_length = 0;
  h->char_length = 0;
  while (h2 != next)
    {
      if (h->complete)
	h->glyph_length += h2->glyph_length;
      h->char_length += h2->char_length;
      if (!h2->complete)
	h->complete = 0;
      h2 = h2->next;
    }
}

static glyph_run_t *run_insert(glyph_run_head_t **context)
{
  glyph_run_head_t *h;
  glyph_run_t *r;
  int level;
  int i;

  level = random_level();
  h = malloc(sizeof(glyph_run_head_t) * level + sizeof(glyph_run_t));
  memset(h, 0, sizeof(glyph_run_head_t) * level + sizeof(glyph_run_t));

  for (i = level; i >= 0; i--)
    {
      h->next = context[i]->next;
      context[i]->next = h;
      h++;
    }
  h--;

  r = (glyph_run_t *)h;
  r->level = level;
  r->prev = context[0];
  return r;
}


-(void) _generateRunsToCharacter: (unsigned int)last
{
  glyph_run_head_t *context[SKIP_LIST_DEPTH];
  int positions[SKIP_LIST_DEPTH];
  glyph_run_head_t *h;
  int pos;

  int length;

  int level;


  length = [_textStorage length];
  if (last >= length)
    last = length - 1;

  h = glyphs;
  pos = 0;
  if (h->char_length > last)
    return;

  /* We haven't created any run for that character. Find the last run. */
  for (level = SKIP_LIST_DEPTH; level; level--)
    {
      while (h->next) pos += h->char_length, h = h->next;
      context[level - 1] = h;
      positions[level - 1] = pos;
      h++;
    }
  h--;
  pos += h->char_length;

  /* Create runs and add them to the skip list until we're past our
     target. */
  while (pos <= last)
    {
      NSRange maxRange = NSMakeRange(pos, length - pos);
      NSRange curRange;
      NSDictionary *attributes;

      glyph_run_head_t *new_head;
      glyph_run_t *new;
      int new_level;

      int i;

      attributes = [_textStorage attributesAtIndex: pos
			       longestEffectiveRange: &curRange
			       inRange: maxRange];

      if (curRange.location < pos)
	{
	  curRange.length -= pos - curRange.location;
	  curRange.location = pos;
	}

      new_level = random_level();

      /* Since we'll be creating these in order, we can be smart about
	 picking new levels. */
      {
	int i;
	glyph_num_end_runs++;
	for (i=0; i < SKIP_LIST_DEPTH - 2; i++)
	  if (glyph_num_end_runs & (1 << i))
	    break;
	new_level = i;
      }

      new_head = malloc(sizeof(glyph_run_t) + sizeof(glyph_run_head_t) * new_level);
      memset(new_head, 0, sizeof(glyph_run_t) + sizeof(glyph_run_head_t) * new_level);
      new = (glyph_run_t *)(new_head + new_level);

      new->level = new_level;
      new->head.char_length = curRange.length;
      new->prev = context[0];

      [self _run_cache_attributes: new : attributes];

//		printf("created new run for %i + %i\n", pos, new->head.char_length);

      h = &new->head;
      for (i = 0; i <= new_level; i++, h--)
	{
	  h->char_length = new->head.char_length;
	  context[i]->next = h;
	  context[i] = h;
	}
      for (; i < SKIP_LIST_DEPTH; i++)
	{
	  context[i]->char_length += new->head.char_length;
	  context[i]->complete = 0;
	}

      pos += new->head.char_length;
    }

//	[self _glyphDumpRuns];
}


/* returns number of new glyphs generated */
-(unsigned int) _generateGlyphs_char_r: (unsigned int)last : (unsigned int)pos
	: (int)level
	: (glyph_run_head_t *)h : (glyph_run_head_t *)stop
	: (BOOL *)all_complete
{
  int total_new = 0, new;
  BOOL c, seen_incomplete;

//	printf("generate_r: %i %i %i %p %p\n",last,pos,level,h,stop);
  *all_complete = YES;
  seen_incomplete = NO;
  while (h != stop && (pos <= last || *all_complete))
    {
      if (h->complete)
	{
	  if (seen_incomplete)
	    total_new += h->glyph_length;
	  pos += h->char_length;
	  h = h->next;
	  continue;
	}

      if (pos > last)
	break;

      seen_incomplete = YES;
      if (level)
	{
	  if (h->next)
	    new = [self _generateGlyphs_char_r: last : pos : level - 1: h + 1: h->next + 1: &c];
	  else
	    new = [self _generateGlyphs_char_r: last : pos : level - 1: h + 1: NULL : &c];
	  if (!c)
	    *all_complete = NO;
	  else
	    h->complete = 1;
	  h->glyph_length += new;
	  total_new += new;
	}
      else
	{
	  [self _generateGlyphsForRun: (glyph_run_t *)h at: pos];
	  h->complete = 1;
	  total_new += h->glyph_length;
	}
      pos += h->char_length;
      h = h->next;
    }
  if (h != stop)
    *all_complete = NO;
//	printf("total_new=%i done %i\n",total_new,*all_complete);
  return total_new;
}

-(void) _generateGlyphsUpToCharacter: (unsigned int)last
{
  int length;
  BOOL dummy;

//	printf("generate to %i\n",last);
  if (!_textStorage)
    return;
  length = [_textStorage length];
  if (!length)
    return;
  if (last >= length)
    last = length - 1;

  if (glyphs->char_length <= last)
    [self _generateRunsToCharacter: last];

//	[self _glyphDumpRuns];
  if ([self _generateGlyphs_char_r: last : 0 : SKIP_LIST_DEPTH - 1: glyphs : NULL : &dummy])
    /*[self _glyphDumpRuns]*/;
}

-(void) _generateGlyphsUpToGlyph: (unsigned int)last
{
  int length;

  if (!_textStorage)
    return;
  length = [_textStorage length];

  /* OPT: this can be done __much__ more efficiently */
  while (glyphs->glyph_length <= last && (glyphs->char_length < length || !glyphs->complete))
    {
/*		printf("want to glyph %i, got %i, length=%i char_length=%i\n",
			last,glyphs->glyph_length,length,glyphs->char_length);*/
      [self _generateGlyphsUpToCharacter: glyphs->char_length];
    }
}


-(glyph_run_t *) _glyphForCharacter: (unsigned int)target
	index: (unsigned int *)rindex
	positions: (unsigned int *)rpos : (unsigned int *)rcpos
{
  glyph_run_t *r;
  int pos, cpos;
  int i;

  r = run_for_character_index(target, glyphs, &pos, &cpos);
  if (!r)
    return NULL;

  i = 0;
  if (r->glyphs[i].char_offset + cpos > target)
    {
      GLYPH_SCAN_BACKWARD(r, i, pos, cpos, r->glyphs[i].char_offset + cpos > target)
    }
  else
    {
      GLYPH_SCAN_FORWARD(r, i, pos, cpos, r->glyphs[i].char_offset + cpos < target)
      if (i == r->head.glyph_length)
	GLYPH_STEP_BACKWARD(r, i, pos, cpos)
      else
	GLYPH_SCAN_BACKWARD(r, i, pos, cpos, r->glyphs[i].char_offset + cpos > target)
    }
  target = r->glyphs[i].char_offset + cpos;
  GLYPH_SCAN_BACKWARD(r, i, pos, cpos, r->glyphs[i].char_offset + cpos == target)
  GLYPH_STEP_FORWARD(r, i, pos, cpos)

  *rindex = i;
  *rpos = pos;
  *rcpos = cpos;
  return r;
}

@end


@implementation GSLayoutManager (glyphs)

- (unsigned int) numberOfGlyphs
{
  [self _generateGlyphsUpToCharacter: -1];
  return glyphs->glyph_length;
}


- (NSGlyph) glyphAtIndex: (unsigned int)glyphIndex
{
  BOOL valid;
  NSGlyph g;
  g = [self glyphAtIndex: glyphIndex isValidIndex: &valid];
  if (valid)
    return g;
  [NSException raise: NSRangeException
	       format: @"%s glyph index out of range", __PRETTY_FUNCTION__];
  return 0;
}


- (NSGlyph) glyphAtIndex: (unsigned int)glyphIndex
	isValidIndex: (BOOL *)isValidIndex
{
  glyph_run_t *r;
  int pos;

  *isValidIndex = NO;

  /* glyph '-1' is returned in other places as an "invalid" marker; this
  way, we can say that it isn't valid without building all glyphs */
  /* TODO: check if this is really safe or smart. if it isn't, some other
  methods will need to be changed so they can return "no glyph index" in
  some other way. */
  if (glyphIndex == (unsigned int)-1)
    return 0;

  if (glyphs->glyph_length <= glyphIndex)
    {
      [self _generateGlyphsUpToGlyph: glyphIndex];
      if (glyphs->glyph_length <= glyphIndex)
	return 0;
    }

  r = run_for_glyph_index(glyphIndex, glyphs, &pos, NULL);
  if (!r) /* shouldn't happen */
    return 0;

  glyphIndex -= pos;
  *isValidIndex = YES;
  return r->glyphs[glyphIndex].g;
}


- (unsigned int) getGlyphs: (NSGlyph *)glyphArray
	range: (NSRange)glyphRange
{
  int pos = glyphRange.location + glyphRange.length - 1;
  glyph_run_t *r;
  NSGlyph *g;
  int num;
  int i, j, k;

  if (glyphs->glyph_length <= pos)
    {
      [self _generateGlyphsUpToGlyph: pos];
      if (glyphs->glyph_length <= pos)
	{
	  [NSException raise: NSRangeException
		       format: @"%s glyph range out of range", __PRETTY_FUNCTION__];
	  return 0;
	}
    }

  r = run_for_glyph_index(glyphRange.location, glyphs, &pos, NULL);
  if (!r)
    { /* shouldn't happen */
      [NSException raise: NSRangeException
		   format: @"%s glyph range out of range", __PRETTY_FUNCTION__];
      return 0;
    }

  g = glyphArray;
  num = 0;

  while (1)
    {
      if (pos < glyphRange.location)
	j = glyphRange.location - pos;
      else
	j = 0;

      k = glyphRange.location + glyphRange.length - pos;
      if (k > r->head.glyph_length)
	k = r->head.glyph_length;
      if (k <= j)
	break;

      /* TODO? only "displayed" glyphs */
      for (i = j; i < k; i++)
	{
	  *g++=r->glyphs[i].g;
	  num++;
	}

      pos += r->head.glyph_length;
      r = (glyph_run_t *)r->head.next;
      if (!r)
	break;
    }

  return num;
}

- (unsigned int) characterIndexForGlyphAtIndex: (unsigned int)glyphIndex
{
  glyph_run_t *r;
  int pos, cpos;

  if (glyphs->glyph_length <= glyphIndex)
    {
      [self _generateGlyphsUpToGlyph: glyphIndex];
      if (glyphs->glyph_length <= glyphIndex)
	{
	  [NSException raise: NSRangeException
		       format: @"%s glyph index out of range", __PRETTY_FUNCTION__];
	  return 0;
	}
    }

  r = run_for_glyph_index(glyphIndex, glyphs, &pos, &cpos);
  if (!r)
    {
      [NSException raise: NSRangeException
		   format: @"%s glyph index out of range", __PRETTY_FUNCTION__];
      return 0;
    }

  return cpos + r->glyphs[glyphIndex - pos].char_offset;
}


- (NSRange) characterRangeForGlyphRange: (NSRange)glyphRange
	actualGlyphRange: (NSRange *)actualGlyphRange
{
  int cpos, pos = glyphRange.location + glyphRange.length - 1;
  glyph_run_t *r;
  NSRange real_range, char_range;
  int i, j;

  if (glyphs->glyph_length <= pos)
    {
      [self _generateGlyphsUpToGlyph: pos];
      if (glyphs->glyph_length <= pos)
	{
	  [NSException raise: NSRangeException
		       format: @"%s glyph range out of range", __PRETTY_FUNCTION__];
	  return NSMakeRange(0, 0);
	}
    }

  r = run_for_glyph_index(glyphRange.location, glyphs, &pos, &cpos);
  if (!r)
    {
      [NSException raise: NSRangeException
		   format: @"%s glyph range out of range", __PRETTY_FUNCTION__];
      return NSMakeRange(0, 0);
    }

  j = cpos + r->glyphs[glyphRange.location - pos].char_offset;
  char_range.location = j;

  /* scan backwards to find the real first glyph */
  {
    glyph_run_t *r2;
    unsigned int adj, cadj;

    i = glyphRange.location - pos;
    r2 = r;
    adj = pos;
    cadj = cpos;
//		printf("scan backwards from %p %i\n", r2, i);
    while (r2->glyphs[i].char_offset + cadj == j)
      {
	i--;
//			printf("  got %i\n", i);
	while (i < 0)
	  {
	    if (!r2->prev)
	      break;
	    r2 = (glyph_run_t *)r2->prev;
	    i = r2->head.glyph_length - 1;
	    adj -= r2->head.glyph_length;
	    cadj -= r2->head.char_length;
//				printf("  adjust to %p %i\n", r2, i);
	  }
	if (i < 0)
	  break;
      }
//		printf("got %i+1+%i\n", i, adj);
    real_range.location = i + 1 + adj;
  }

  /* the range is likely short, so we can do better then a completely new
     search */
  r = run_for_glyph_index(glyphRange.location + glyphRange.length - 1,
			glyphs, &pos, &cpos);
//	printf("run for glyph index got %p %i\n", r, cpos);
  if (!r)
    {
      [NSException raise: NSRangeException
		   format: @"%s glyph range out of range", __PRETTY_FUNCTION__];
      return NSMakeRange(0, 0);
    }

  j = cpos + r->glyphs[glyphRange.location + glyphRange.length - 1 - pos].char_offset;

  /* scan forwards to find the real last glyph */
  {
    glyph_run_t *r2;
    unsigned int adj, cadj;
    unsigned int last = 0;

    i = glyphRange.location + glyphRange.length - 1 - pos;
    r2 = r;
    adj = pos;
    cadj = cpos;
//		printf("scan forwards from %p %i, char pos %i\n", r2, i, cadj);
    while (r2->glyphs[i].char_offset + cadj == j)
      {
	i++;
//			printf("got %i\n", i);
	while (i == r2->head.glyph_length)
	  {
	    if (!r2->head.next || !r2->head.next->complete)
	      {
//					printf("no next, at %i, length %i\n", cadj+r2->head.char_length, [_textStorage length]);
		if (cadj + r2->head.char_length == [_textStorage length])
		  {
		    last = cadj + r2->head.char_length;
		    goto found;
		  }
		[self _generateGlyphsUpToCharacter: cadj + r2->head.char_length];
	      }
	    adj += r2->head.glyph_length;
	    cadj += r2->head.char_length;
	    r2 = (glyph_run_t *)r2->head.next;
	    i = 0;
//				printf("adjust to %p %i\n", r2, i);
	  }
      }
    last = r2->glyphs[i].char_offset + cadj;
  found:
    real_range.length = i + adj - real_range.location;
    char_range.length = last - char_range.location;
  }

  if (actualGlyphRange)
    *actualGlyphRange = real_range;
  return char_range;
}


- (NSRange) glyphRangeForCharacterRange: (NSRange)charRange 
	actualCharacterRange: (NSRange *)actualCharRange
{
  NSRange char_range, glyph_range;
  glyph_run_t *r;
  int cpos, pos = charRange.location + charRange.length - 1;
  int i, target;

  /* TODO: should this really be valid?

  This is causing all kinds of problems when border glyph ranges are passed
  to other functions. Better to keep the layout manager clean of all this and
  let NSTextView deal with it.
  */
#if 1
  if (charRange.length == 0 && charRange.location == [[_textStorage string] length])
    {
      if (actualCharRange)
	*actualCharRange = NSMakeRange([[_textStorage string] length], 0);
      return NSMakeRange([self numberOfGlyphs], 0);
    }
#endif
  /* TODO: this case is also dubious, but it makes sense to return like this,
  so it's mostly the caller's fault */
  if (charRange.length == 0)
    {
      NSLog(@"Warning: %s called with zero-length range", __PRETTY_FUNCTION__);
      if (actualCharRange)
	*actualCharRange = NSMakeRange(0, 0);
      return NSMakeRange(0, 0);
    }

  [self _generateGlyphsUpToCharacter: pos];
  if (glyphs->char_length <= pos)
    {
      [NSException raise: NSRangeException
	format: @"%s character range out of range", __PRETTY_FUNCTION__];
      return NSMakeRange(0, 0);
    }

  target = charRange.location;
  r = [self _glyphForCharacter: target
	  index: &i
	  positions: &pos : &cpos];
  glyph_range.location = i + pos;
  char_range.location = r->glyphs[i].char_offset + cpos;

  target = charRange.location + charRange.length - 1;
  r = [self _glyphForCharacter: target
	  index: &i
	  positions: &pos : &cpos];

  GLYPH_SCAN_FORWARD(r, i, pos, cpos, r->glyphs[i].char_offset + cpos <= target)

    glyph_range.length = i + pos - glyph_range.location;
  if (i == r->head.glyph_length)
    char_range.length = glyphs->char_length - char_range.location;
  else
    char_range.length = r->glyphs[i].char_offset + cpos - char_range.location;

  if (actualCharRange)
    *actualCharRange = char_range;
  return glyph_range;
}


/*
TODO? this might currently lead to continued runs not being marked as
continued runs. this will only happen at safe break spots, though, so
it should still be safe. might lose opportunities to merge runs, though.
*/

/* This is hairy. */
- (void) invalidateGlyphsForCharacterRange: (NSRange)range
	changeInLength: (int)lengthChange
	actualCharacterRange: (NSRange *)actualRange
{
  BOOL trailing;

  int cpos;
  int ts_length;
  int gap;

  int position[SKIP_LIST_DEPTH];
  glyph_run_head_t *context[SKIP_LIST_DEPTH];
  glyph_run_head_t *h;
  glyph_run_t *r;
  int level;

  int ch;

  NSRange rng;


/*	[self _glyphDumpRuns];
	printf("range=(%i+%i) lengthChange=%i\n", range.location, range.length, lengthChange);*/
  range.length -= lengthChange;
//	printf("invalidate %i+%i=%i\n", range.location, range.length, range.location+range.length);

  ts_length = [_textStorage length];

  ch = range.location;
  if (ch > 0)
    {
      ch = [self _findSafeBreakMovingBackwardFrom: ch];
      range.length += range.location - ch;
      range.location = ch;
    }

  ch = ch + range.length + lengthChange;
  if (ch < ts_length)
    {
      ch = [self _findSafeBreakMovingForwardFrom: ch];

      ch -= lengthChange;
      range.length = ch - range.location;
    }

//	printf("adjusted to %i+%i\n", range.location, range.length);

  ch = range.location;

  h = glyphs;
  cpos = 0;
  for (level = SKIP_LIST_DEPTH - 1; level >= 0; level--)
    {
      while (cpos + h->char_length <= ch)
	{
	  cpos += h->char_length;
	  h = h->next;
	  if (!h) /* no runs created yet */
	    {
//				printf("no runs created yet\n");
	      return;
	    }
	}
      context[level] = h;
      position[level] = cpos;
      h++;
    }
  h--;
  r = (glyph_run_t *)h;

  /* assumes that first glyph for a character is in the same run as
     the character. should be valid, but need to make sure temporary attributes
     and glyph generation maintain it.

     Not an issue since temporary attributes are character based, and the glyph
     run issues have been resolved. (2002-11-18)
  */

//	printf("split if %i+%i > %i+%i\n", cpos, r->head.char_length, ch, range.length);
  if (cpos + r->head.char_length > ch + range.length && range.length)
    {
      glyph_run_t *new;
      glyph_run_head_t *hn;
      int i;

      new = run_insert(context);
      new->head.char_length = cpos + r->head.char_length - (ch + range.length);
      [self _run_copy_attributes: new : r];
      /* OPT!!! keep valid glyphs */
      hn = &new->head;
      hn--;
      for (i = 1; i <= new->level; i++, hn--)
	run_fix_head(hn);

      r->head.char_length -= new->head.char_length;
    }

  if (ch == cpos)
    {
      glyph_run_head_t *h2;

      h2 = h - r->level;
      h = context[r->level + 1];
      cpos = position[r->level + 1];
      h++;
      for (level = r->level; level >= 0; level--)
	{
	  while (h->next != h2)
	    {
	      cpos += h->char_length;
	      h = h->next;
	    }
	  position[level] = cpos;
	  context[level] = h;
	  h++;
	  h2++;
	}
      h--;
      r = (glyph_run_t *)h;
      gap = 0;
    }
  else
    {
      gap = r->head.char_length + cpos - ch;
      r->head.char_length = ch - cpos;
      /* OPT!!! keep valid glyphs */
      if (r->head.complete)
	{
	  r->head.glyph_length = 0;
	  r->head.complete = 0;
	  free(r->glyphs);
	  r->glyphs = NULL;
	}
    }

  /* r is the last run we should keep, context and positions are set up
     for it, gap is the number of characters already deleted */

  {
    glyph_run_t *next;
    unsigned int max = range.location + range.length;
    int i;

    /* delete all runs completely invalidated */
    cpos += gap + r->head.char_length;
    while (1)
      {
	next = (glyph_run_t *)r->head.next;

	/* we reached the end of all created runs */
	if (!next)
	  break;

	/* clean cut, just stop */
	if (max == cpos)
	  break;

	if (max < cpos + next->head.char_length)
	  {
	    glyph_run_head_t *hn;
	    /* adjust final run */
	    /* OPT!!! keep valid glyphs */
	    if (next->head.complete)
	      {
		next->head.complete = 0;
		next->head.glyph_length = 0;
		free(next->glyphs);
		next->glyphs = NULL;
	      }
	    next->head.char_length -= max - cpos;

	    hn = &next->head;
	    hn--;
	    for (i = 1; i <= next->level; i++, hn--)
	      run_fix_head(hn);

	    break;
	  }

	cpos += next->head.char_length;

	/* remove the run, will update heads later */
	if (next->head.next)
	  ((glyph_run_t *)next->head.next)->prev = &r->head;

	for (i = 0; i <= next->level; i++)
	  context[i]->next = context[i]->next->next;
	h = &next->head;
	if (h->complete)
	  free(next->glyphs);
	[self _run_free_attributes: next];
	h -= next->level;
	free(h);
	h = NULL;
      }
    trailing = !next;
  }

/*	printf("deleted\n");
	[self _glyphDumpRuns];*/

  /* r is the last run we want to keep, and the next run is the next
     uninvalidated run. need to insert new runs for range */
  range.length += lengthChange;
//	printf("create runs for %i+%i\n", range.location, range.length);
  /* OPT: this is creating more runs than it needs to */
  {
    NSDictionary *attributes;
    glyph_run_t *new;
    unsigned int max = range.location + range.length;
    int i;

    ch = range.location;
    while (ch < max)
      {
	attributes = [_textStorage attributesAtIndex: ch
				 longestEffectiveRange: &rng
				 inRange: NSMakeRange(0, [_textStorage length])];

/*			printf("at %i, max=%i, effective range (%i+%i)\n",
				ch, max, rng.location, rng.length); */

	new = run_insert(context);
	if (rng.location < ch)
	  {
	    new->continued = 1;
	    rng.length -= ch - rng.location;
	    rng.location = ch;
	  }
	if (ch + rng.length > max)
	  {
	    if (new->head.next)
	      ((glyph_run_t *)new->head.next)->continued = 1;
	    rng.length = max - ch;
	  }
//			printf("adjusted length: %i\n", rng.length);
	new->head.char_length = rng.length;

	[self _run_cache_attributes: new : attributes];

	h = &new->head;
	for (i = 0; i <= new->level; i++, h--)
	  {
	    if (i)
	      run_fix_head(context[i]);
	    context[i] = h;
	  }
	ch += new->head.char_length;
      }

    if (context[0]->next)
      ((glyph_run_t *)context[0]->next)->prev = context[0];
  }

  /* fix all heads */
  {
    int i;
    for (i = 1; i < SKIP_LIST_DEPTH; i++)
      {
	run_fix_head(context[i]);
      }
  }

  if (actualRange)
    *actualRange = range;

//	[self _glyphDumpRuns];
}


#define GET_GLYPH \
	glyph_run_t *r; \
	int pos, cpos; \
\
	if (glyphs->glyph_length <= idx) \
	{ \
		[self _generateGlyphsUpToGlyph: idx]; \
		if (glyphs->glyph_length <= idx) \
		{ \
			[NSException raise: NSRangeException \
				format: @"%s glyph range out of range", __PRETTY_FUNCTION__]; \
		} \
	} \
 \
	r = run_for_glyph_index(idx, glyphs, &pos, &cpos); \
	if (!r) \
	{ \
		[NSException raise: NSRangeException \
			format: @"%s glyph range out of range", __PRETTY_FUNCTION__]; \
	} \
	idx -= pos;

- (void) setDrawsOutsideLineFragment: (BOOL)flag 
	forGlyphAtIndex: (unsigned int)idx
{
  GET_GLYPH
  r->glyphs[idx].drawsOutsideLineFragment = !!flag;
}
- (BOOL) drawsOutsideLineFragmentForGlyphAtIndex: (unsigned int)idx
{
  GET_GLYPH
  return r->glyphs[idx].drawsOutsideLineFragment;
}

- (void) setNotShownAttribute: (BOOL)flag 
	forGlyphAtIndex: (unsigned int)idx
{
  GET_GLYPH
  r->glyphs[idx].isNotShown = !!flag;
}
- (BOOL) notShownAttributeForGlyphAtIndex: (unsigned int)idx
{
  GET_GLYPH
  return r->glyphs[idx].isNotShown;
}


- (NSFont *) effectiveFontForGlyphAtIndex: (unsigned int)idx
	range: (NSRange *)range
{
  GET_GLYPH
  if (range)
    *range = NSMakeRange(pos, r->head.glyph_length);
  return r->font;
}


- (void) insertGlyph: (NSGlyph)aGlyph
	atGlyphIndex: (unsigned int)glyphIndex
      characterIndex: (unsigned int)charIndex
{
  NSLog(@"Internal method %s called", __PRETTY_FUNCTION__);
}
- (void) replaceGlyphAtIndex: (unsigned int)glyphIndex
	withGlyph: (NSGlyph)newGlyph
{
  NSLog(@"Internal method %s called", __PRETTY_FUNCTION__);
}
- (void) deleteGlyphsInRange: (NSRange)aRange
{
  NSLog(@"Internal method %s called", __PRETTY_FUNCTION__);
}
- (void) setCharacterIndex: (unsigned int)charIndex
	   forGlyphAtIndex: (unsigned int)glyphIndex
{
  NSLog(@"Internal method %s called", __PRETTY_FUNCTION__);
}


- (void) setIntAttribute: (int)attributeTag 
		   value: (int)anInt
	 forGlyphAtIndex: (unsigned int)glyphIndex
{
  [self subclassResponsibility: _cmd];
}
- (int) intAttribute: (int)attributeTag
     forGlyphAtIndex: (unsigned int)glyphIndex
{
  [self subclassResponsibility: _cmd];
  return 0;
}

@end



/***** Layout handling *****/

@implementation GSLayoutManager (layout_helpers)

-(void) _invalidateLayoutFromContainer: (int)idx
{
  int i, j;
  textcontainer_t *tc;
  linefrag_t *lf;

//	printf("invalidate from %i\n", idx);
  extra_textcontainer = nil;

  for (i = idx, tc = textcontainers + idx; i < num_textcontainers; i++, tc++)
    {
      tc->started = tc->complete = NO;
      if (tc->linefrags)
	{
	  for (j = 0, lf = tc->linefrags; j < tc->num_linefrags; j++, lf++)
	    {
	      if (lf->points)
		free(lf->points);
	      if (lf->attachments)
		free(lf->attachments);
	    }

	  free(tc->linefrags);
	}
      tc->linefrags = NULL;
      tc->num_linefrags = 0;
      tc->pos = tc->length = 0;
    }
  for (i = idx - 1, tc = textcontainers + idx - 1; i >= 0; i--, tc--)
    {
      if (tc->started)
	{
	  layout_glyph = tc->pos + tc->length;
	  if (layout_glyph == glyphs->glyph_length)
	    layout_char = glyphs->char_length;
	  else
	    layout_char = [self characterIndexForGlyphAtIndex: layout_glyph]; /* TODO? */
	  return;
	}
    }
  layout_glyph = layout_char = 0;
}

-(void) _freeLayout
{
  [self _invalidateLayoutFromContainer: 0];
}


-(void) _doLayout
{
  int i, j;
  textcontainer_t *tc;
  unsigned int next;
  NSRect prev;

//	printf("_doLayout\n");
  for (i = 0, tc = textcontainers; i < num_textcontainers; i++, tc++)
    {
/*		printf("_doLayout in %i  (size (%g %g))\n",
			i, [tc->textContainer containerSize].width, [tc->textContainer containerSize].height);*/
      if (tc->complete)
	{
//			printf("  already done\n");
	  continue;
	}

      while (1)
	{
	  if (tc->num_linefrags)
	    prev = tc->linefrags[tc->num_linefrags - 1].rect;
	  else
	    prev = NSZeroRect;
	  j = [typesetter layoutGlyphsInLayoutManager: self
			inTextContainer: tc->textContainer
			startingAtGlyphIndex: tc->pos + tc->length
			previousLineFragmentRect: prev
			nextGlyphIndex: &next
			numberOfLineFragments: 0];
//			printf("  got j = %i\n", j);
	  if (j)
	    break;
	}
      tc->complete = YES;
      if (j == 2)
	break;
    }
}


-(void) _doLayoutToGlyph: (unsigned int)glyphIndex
{
  [self _doLayout];
}

-(void) _doLayoutToContainer: (int)cindex
{
  [self _doLayout];
}

@end


@implementation GSLayoutManager (layout)


- (void) invalidateLayoutForCharacterRange: (NSRange)aRange 
				    isSoft: (BOOL)flag
		      actualCharacterRange: (NSRange *)actualRange
{
  [self _invalidateLayoutFromContainer: 0];
#if 0
  unsigned int from_glyph = glyphs->glyph_length;
  int i, j;
  textcontainer_t *tc;
  linefrag_t *lf;

  if (from_glyph)
    {
      unsigned int chi = [self characterIndexForGlyphAtIndex: from_glyph - 1];
      if (chi > aRange.location)
	{
	  from_glyph = [self glyphRangeForCharacterRange: NSMakeRange(aRange.location, 1)
			   actualCharacterRange: actualRange].location;
	}
      else
	{
	  if (actualRange)
	    actualRange->location = chi;
	}
    }
  else
    {
      if (actualRange)
	actualRange->location = 0;
    }
  if (actualRange)
    actualRange->length = [_textStorage length] - actualRange->location;

  if (layout_glyph <= from_glyph)
    return;

  for (i = 0, tc = textcontainers; i < num_textcontainers; i++, tc++)
    if (tc->pos + tc->length > from_glyph)
      break;
  if (i == num_textcontainers)
    {
      NSLog(@"%s: can't find text container for glyph (internal error)", __PRETTY_FUNCTION__);
      return;
    }
  j = i;

  for (i = 0, lf = tc->linefrags; i < tc->num_linefrags; i++, lf++)
    if (lf->pos + lf->length > from_glyph)
      break;
  if (i == tc->num_linefrags)
    {
      NSLog(@"%s: can't find line frag rect for glyph (internal error)", __PRETTY_FUNCTION__);
      return;
    }

  if (i)
    {
      int idx = i;
      for (; i < tc->num_linefrags; i++, lf++)
	{
	  if (lf->points)
	    free(lf->points);
	  if (lf->attachments)
	    free(lf->attachments);
	}
      tc->num_linefrags = idx;
      tc->length = tc->linefrags[idx - 1].pos + tc->linefrags[idx - 1].length - tc->pos;
      tc->complete = NO;
      [self _invalidateLayoutFromContainer: j + 1];
    }
  else
    {
      [self _invalidateLayoutFromContainer: j];
    }
#endif
}


#define SETUP_STUFF \
	unsigned int max = glyphRange.location + glyphRange.length; \
	\
	[self _generateGlyphsUpToGlyph: max - 1]; \
	if (glyphs->glyph_length < max) \
	{ \
		[NSException raise: NSRangeException \
			format: @"%s glyph range out of range", __PRETTY_FUNCTION__]; \
		return; \
	}

- (void) setTextContainer: (NSTextContainer *)aTextContainer 
	forGlyphRange: (NSRange)glyphRange
{
  textcontainer_t *tc;
  int i;
  SETUP_STUFF

  for (i = 0, tc = textcontainers; i < num_textcontainers; i++, tc++)
    if (tc->textContainer == aTextContainer)
      break;
  if (i == num_textcontainers)
    {
      NSLog(@"%s: doesn't own text container", __PRETTY_FUNCTION__);
      return;
    }

  if (tc->started)
    {
      if (glyphRange.location != tc->pos + tc->length)
	{
	  NSLog(@"%s: invalid range", __PRETTY_FUNCTION__);
	  return;
	}
      tc->length += glyphRange.length;
    }
  else if (!i)
    {
      if (glyphRange.location)
	{
	  NSLog(@"%s: invalid range", __PRETTY_FUNCTION__);
	  return;
	}
      tc->pos = 0;
      tc->length = glyphRange.length;
      tc->started = YES;
    }
  else
    {
      if (tc[-1].pos + tc[-1].length != glyphRange.location)
	{
	  NSLog(@"%s: invalid range", __PRETTY_FUNCTION__);
	  return;
	}
      tc->pos = glyphRange.location;
      tc->length = glyphRange.length;
      tc->started = YES;
    }

  {
    unsigned int gpos;
    unsigned int g;
    glyph_t *glyph;
    glyph_run_t *run = run_for_glyph_index(glyphRange.location, glyphs, &gpos, NULL);

    g = glyphRange.location;
    glyph = &run->glyphs[g - gpos];
    while (g < glyphRange.location + glyphRange.length)
      {
	if (g == gpos + run->head.glyph_length)
	  {
	    gpos += run->head.glyph_length;
	    run = (glyph_run_t *)run->head.next;
	    glyph = run->glyphs;
	  }

	glyph->isNotShown = NO;
	glyph->drawsOutsideLineFragment = NO;
	g++;
	glyph++;
      }
  }
}

- (void) setLineFragmentRect: (NSRect)fragmentRect 
	       forGlyphRange: (NSRange)glyphRange
		    usedRect: (NSRect)usedRect
{
  textcontainer_t *tc;
  int i;
  linefrag_t *lf;

  SETUP_STUFF

  for (i = 0, tc = textcontainers; i < num_textcontainers; i++, tc++)
    {
      if (tc->pos <= glyphRange.location &&
	  tc->pos + tc->length >= glyphRange.location + glyphRange.length)
	break;
    }
  if (i == num_textcontainers)
    {
      NSLog(@"%s: text container not set for range", __PRETTY_FUNCTION__);
      return;
    }

  if (!tc->num_linefrags)
    {
      if (glyphRange.location != tc->pos)
	{
	  NSLog(@"%s: invalid range", __PRETTY_FUNCTION__);
	  return;
	}
      tc->linefrags = malloc(sizeof(linefrag_t));
      tc->num_linefrags = 1;
      lf = tc->linefrags;
    }
  else
    {
      lf = &tc->linefrags[tc->num_linefrags - 1];
      if (lf->pos + lf->length != glyphRange.location)
	{
	  NSLog(@"%s: invalid range", __PRETTY_FUNCTION__);
	  return;
	}
      tc->num_linefrags++;
      tc->linefrags = realloc(tc->linefrags, sizeof(linefrag_t) * tc->num_linefrags);
      lf = &tc->linefrags[tc->num_linefrags - 1];
    }
  memset(lf, 0, sizeof(linefrag_t));
  lf->rect = fragmentRect;
  lf->used_rect = usedRect;
  lf->pos = glyphRange.location;
  lf->length = glyphRange.length;
}

- (void) setLocation: (NSPoint)location 
forStartOfGlyphRange: (NSRange)glyphRange
{
  textcontainer_t *tc;
  int i;
  linefrag_t *lf;
  linefrag_point_t *lp;

  SETUP_STUFF

  for (i = 0, tc = textcontainers; i < num_textcontainers; i++, tc++)
    {
      if (tc->pos <= glyphRange.location &&
	  tc->pos + tc->length >= glyphRange.location + glyphRange.length)
	break;
    }
  if (i == num_textcontainers)
    {
      NSLog(@"%s: text container not set for range", __PRETTY_FUNCTION__);
      return;
    }

  for (i = 0, lf = tc->linefrags; i < tc->num_linefrags; i++, lf++)
    {
      if (lf->pos <= glyphRange.location &&
	  lf->pos + lf->length >= glyphRange.location + glyphRange.length)
	break;
    }
  if (i == tc->num_linefrags)
    {
      NSLog(@"%s: line fragment rect not set for range", __PRETTY_FUNCTION__);
      return;
    }

  if (!lf->num_points)
    {
      if (glyphRange.location != lf->pos)
	{
	  NSLog(@"%s: line fragment rect not set for range", __PRETTY_FUNCTION__);
	  return;
	}
      lp = lf->points = malloc(sizeof(linefrag_point_t));
      lf->num_points++;
    }
  else
    {
      lp = &lf->points[lf->num_points - 1];
      if (lp->pos + lp->length != glyphRange.location)
	{
	  NSLog(@"%s: line fragment rect not set for range", __PRETTY_FUNCTION__);
	  return;
	}
      lf->num_points++;
      lf->points = realloc(lf->points, sizeof(linefrag_point_t) * lf->num_points);
      lp = &lf->points[lf->num_points - 1];
    }
  memset(lp, 0, sizeof(linefrag_point_t));
  lp->pos = glyphRange.location;
  lp->length = glyphRange.length;
  lp->p = location;

  layout_glyph = lp->pos + lp->length;
  if (layout_glyph == glyphs->glyph_length)
    layout_char = glyphs->char_length;
  else
    layout_char = [self characterIndexForGlyphAtIndex: layout_glyph];
}


-(void) setAttachmentSize: (NSSize)size
	    forGlyphRange: (NSRange)glyphRange
{
  textcontainer_t *tc;
  int i;
  linefrag_t *lf;
  linefrag_attachment_t *la;

  SETUP_STUFF

  for (i = 0, tc = textcontainers; i < num_textcontainers; i++, tc++)
    {
      if (tc->pos <= glyphRange.location &&
	  tc->pos + tc->length >= glyphRange.location + glyphRange.length)
	break;
    }
  if (i == num_textcontainers)
    {
      NSLog(@"%s: text container not set for range", __PRETTY_FUNCTION__);
      return;
    }

  for (i = 0, lf = tc->linefrags; i < tc->num_linefrags; i++, lf++)
    {
      if (lf->pos <= glyphRange.location &&
	  lf->pos + lf->length >= glyphRange.location + glyphRange.length)
	break;
    }
  if (i == tc->num_linefrags)
    {
      NSLog(@"%s: line fragment rect not set for range", __PRETTY_FUNCTION__);
      return;
    }

  /* TODO: we do no sanity checking of attachment size ranges. might want
  to consider doing it */
  lf->attachments = realloc(lf->attachments,
		      sizeof(linefrag_attachment_t) * (lf->num_attachments + 1));
  la = &lf->attachments[lf->num_attachments++];

  memset(la, 0, sizeof(linefrag_attachment_t));
  la->pos = glyphRange.location;
  la->length = glyphRange.length;
  la->size = size;
}

#undef SETUP_STUFF


- (NSTextContainer *) textContainerForGlyphAtIndex: (unsigned int)glyphIndex
				    effectiveRange: (NSRange *)effectiveRange
{
  textcontainer_t *tc;
  int i;

  [self _doLayoutToGlyph: glyphIndex];
  for (i = 0, tc = textcontainers; i < num_textcontainers; i++, tc++)
    if (tc->pos + tc->length > glyphIndex)
      break;
  if (i == num_textcontainers)
    {
      NSLog(@"%s: can't find text container for glyph (internal error)", __PRETTY_FUNCTION__);
      return nil;
    }

  if (effectiveRange)
    {
      [self _doLayoutToContainer: i];
      *effectiveRange = NSMakeRange(tc->pos, tc->length);
    }
  return tc->textContainer;
}

- (NSRect) lineFragmentRectForGlyphAtIndex: (unsigned int)glyphIndex
			    effectiveRange: (NSRange *)effectiveGlyphRange
{
  int i;
  textcontainer_t *tc;
  linefrag_t *lf;

  [self _doLayoutToGlyph: glyphIndex];
  for (i = 0, tc = textcontainers; i < num_textcontainers; i++, tc++)
    if (tc->pos + tc->length > glyphIndex)
      break;
  if (i == num_textcontainers)
    {
      NSLog(@"%s: can't find text container for glyph (internal error)", __PRETTY_FUNCTION__);
      return NSZeroRect;
    }

  for (i = 0, lf = tc->linefrags; i < tc->num_linefrags; i++, lf++)
    if (lf->pos + lf->length > glyphIndex)
      break;
  if (i == tc->num_linefrags)
    {
      NSLog(@"%s: can't find line frag rect for glyph (internal error)", __PRETTY_FUNCTION__);
      return NSZeroRect;
    }

  if (effectiveGlyphRange)
    {
      *effectiveGlyphRange = NSMakeRange(lf->pos, lf->length);
    }
  return lf->rect;
}

- (NSRect) lineFragmentUsedRectForGlyphAtIndex: (unsigned int)glyphIndex
				effectiveRange: (NSRange *)effectiveGlyphRange
{
  int i;
  textcontainer_t *tc;
  linefrag_t *lf;

  [self _doLayoutToGlyph: glyphIndex];
  for (i = 0, tc = textcontainers; i < num_textcontainers; i++, tc++)
    if (tc->pos + tc->length > glyphIndex)
      break;
  if (i == num_textcontainers)
    {
      NSLog(@"%s: can't find text container for glyph (internal error)", __PRETTY_FUNCTION__);
      return NSMakeRect(0, 0, 0, 0);
    }

  for (i = 0, lf = tc->linefrags; i < tc->num_linefrags; i++, lf++)
    if (lf->pos + lf->length > glyphIndex)
      break;
  if (i == tc->num_linefrags)
    {
      NSLog(@"%s: can't find line frag rect for glyph (internal error)", __PRETTY_FUNCTION__);
      return NSMakeRect(0, 0, 0, 0);
    }

  if (effectiveGlyphRange)
    {
      *effectiveGlyphRange = NSMakeRange(lf->pos, lf->length);
    }
  return lf->used_rect;
}

- (NSRange) rangeOfNominallySpacedGlyphsContainingIndex:(unsigned int)glyphIndex
					  startLocation: (NSPoint *)p
{
  int i;
  textcontainer_t *tc;
  linefrag_t *lf;
  linefrag_point_t *lp;

  [self _doLayoutToGlyph: glyphIndex];
  for (i = 0, tc = textcontainers; i < num_textcontainers; i++, tc++)
    if (tc->pos + tc->length > glyphIndex)
      break;
  if (i == num_textcontainers)
    {
      NSLog(@"%s: can't find text container for glyph (internal error)", __PRETTY_FUNCTION__);
      return NSMakeRange(NSNotFound, 0);
    }

  for (i = 0, lf = tc->linefrags; i < tc->num_linefrags; i++, lf++)
    if (lf->pos + lf->length > glyphIndex)
      break;
  if (i == tc->num_linefrags)
    {
      NSLog(@"%s: can't find line frag rect for glyph (internal error)", __PRETTY_FUNCTION__);
      return NSMakeRange(NSNotFound, 0);
    }

  for (i = 0, lp = lf->points; i < lf->num_points; i++, lp++)
    if (lp->pos + lp->length > glyphIndex)
      break;
  if (i == lf->num_points)
    {
      NSLog(@"%s: can't find location for glyph (internal error)", __PRETTY_FUNCTION__);
      return NSMakeRange(NSNotFound, 0);
    }

  if (p)
    *p = lp->p;
  return NSMakeRange(lp->pos, lp->length);
}


- (NSRange) rangeOfNominallySpacedGlyphsContainingIndex:(unsigned int)glyphIndex
{
  return [self rangeOfNominallySpacedGlyphsContainingIndex: glyphIndex
	       startLocation: NULL];
}


/* The union of all line frag rects' used rects. */
- (NSRect) usedRectForTextContainer: (NSTextContainer *)container
{
  textcontainer_t *tc;
  linefrag_t *lf;
  int i;
  NSRect used;

  for (i = 0, tc = textcontainers; i < num_textcontainers; i++, tc++)
    if (tc->textContainer == container)
      break;
  if (i == num_textcontainers)
    {
      NSLog(@"%s: doesn't own text container", __PRETTY_FUNCTION__);
      return NSMakeRect(0, 0, 0, 0);
    }

  [self _doLayoutToContainer: i];
  used = NSZeroRect;
  for (i = 0, lf = tc->linefrags; i < tc->num_linefrags; i++, lf++)
    used = NSUnionRect(used, lf->used_rect);
  return used;
}

- (NSRange) glyphRangeForTextContainer: (NSTextContainer *)container
{
  textcontainer_t *tc;
  int i;

  for (i = 0, tc = textcontainers; i < num_textcontainers; i++, tc++)
    if (tc->textContainer == container)
      break;
  if (i == num_textcontainers)
    {
      NSLog(@"%s: doesn't own text container", __PRETTY_FUNCTION__);
      return NSMakeRange(NSNotFound, 0);
    }

  [self _doLayoutToContainer: i];
  return NSMakeRange(tc->pos, tc->length);
}



/* TODO: make more efficient */
- (NSArray *) textContainers
{
  NSMutableArray *ma;
  int i;

  ma = [[NSMutableArray alloc] initWithCapacity: num_textcontainers];
  for (i = 0; i < num_textcontainers; i++)
    [ma addObject: textcontainers[i].textContainer];
  return [ma autorelease];
}

- (void) addTextContainer: (NSTextContainer *)container
{
  [self insertTextContainer: container
	atIndex: num_textcontainers];
}

- (void) insertTextContainer: (NSTextContainer *)aTextContainer
		     atIndex: (unsigned int)index
{
  int i;

  if (index < num_textcontainers)
    [self _invalidateLayoutFromContainer: index];

  num_textcontainers++;
  textcontainers = realloc(textcontainers,
			 sizeof(textcontainer_t) * num_textcontainers);

  for (i = num_textcontainers - 1; i > index; i--)
    textcontainers[i] = textcontainers[i - 1];

  memset(&textcontainers[i], 0, sizeof(textcontainer_t));
  textcontainers[i].textContainer = [aTextContainer retain];

  [aTextContainer setLayoutManager: self];
}

- (void) removeTextContainerAtIndex: (unsigned int)index
{
  int i;
  textcontainer_t *tc = &textcontainers[index];

  [self _invalidateLayoutFromContainer: index];
  [tc->textContainer setLayoutManager: nil];
  [tc->textContainer release];

  num_textcontainers--;
  for (i = index; i < num_textcontainers; i++)
    textcontainers[i] = textcontainers[i + 1];

  if (num_textcontainers)
    textcontainers = realloc(textcontainers,
			   sizeof(textcontainer_t) * num_textcontainers);
  else
    {
      free(textcontainers);
      textcontainers = NULL;
    }
}

- (void) textContainerChangedGeometry: (NSTextContainer *)aContainer
{
  int i;
  for (i = 0; i < num_textcontainers; i++)
    if (textcontainers[i].textContainer == aContainer)
      break;
  if (i == num_textcontainers)
    {
      NSLog(@"%s: does not own text container", __PRETTY_FUNCTION__);
      return;
    }
  [self _invalidateLayoutFromContainer: i];
}


- (unsigned int) firstUnlaidCharacterIndex
{
  return layout_char;
}
- (unsigned int) firstUnlaidGlyphIndex
{
  return layout_glyph;
}
-(void) getFirstUnlaidCharacterIndex: (unsigned int *)cindex
			  glyphIndex: (unsigned int *)gindex
{
  if (cindex)
    *cindex = [self firstUnlaidCharacterIndex];
  if (gindex)
    *gindex = [self firstUnlaidGlyphIndex];
}

@end


/***** The rest *****/

@implementation GSLayoutManager

- init
{
  if (!(self = [super init]))
    return nil;

  [self _initGlyphs];

  typesetter = [[GSTypesetter sharedSystemTypesetter] retain];

  usesScreenFonts = YES;

  return self;
}


-(void) dealloc
{
  int i;
  textcontainer_t *tc;

  free(rect_array);
  rect_array_size = 0;
  rect_array = NULL;

  [self _freeLayout];
  for (i = 0, tc = textcontainers; i < num_textcontainers; i++, tc++)
    {
      [tc->textContainer release];
    }
  free(textcontainers);
  textcontainers = NULL;

  [self _freeGlyphs];

  DESTROY(typesetter);

  [super dealloc];
}


-(void) _invalidateEverything
{
  [self _freeLayout];

  [self _freeGlyphs];
  [self _initGlyphs];
}


/**
 * Sets the text storage for the layout manager.
 * Use -replaceTextStorage: instead as a rule. - this method is really
 * more for internal use by the text system.
 * Invalidates the entire layout (should it??)
 */
/*
See [NSTextView -setTextContainer:] for more information about these calls.
*/
- (void) setTextStorage: (NSTextStorage *)aTextStorage
{
  int i;
  textcontainer_t *tc;

  [self _invalidateEverything];

  /*
   * Make a note of the new text storage object, but don't retain it.
   * The text storage is owning us - it retains us.
   */
  _textStorage = aTextStorage;

  /*
  We send this message to all text containers so they can respond to the
  change (most importantly to let them tell their text views).
  */
  for (i = 0, tc = textcontainers; i < num_textcontainers; i++, tc++)
    {
      [tc->textContainer setLayoutManager: self];
    }
}

/**
 * Returns the text storage for this layout manager.
 */
- (NSTextStorage *) textStorage
{
  return _textStorage;
}

/**
 * Replaces the text storage with a new one.<br />
 * Takes care (since layout managers are owned by text storages)
 * not to get self deallocated.
 */
- (void) replaceTextStorage: (NSTextStorage *)newTextStorage
{
  NSArray		*layoutManagers = [_textStorage layoutManagers];
  NSEnumerator		*enumerator = [layoutManagers objectEnumerator];
  GSLayoutManager	*object;

  /* Remove layout managers from old NSTextStorage object and add them to the
     new one.  NSTextStorage's addLayoutManager invokes GSLayoutManager's
     setTextStorage method automatically, and that includes self.  */

  while ((object = (GSLayoutManager*)[enumerator nextObject]) != nil)
    {
      RETAIN(object);
      [_textStorage removeLayoutManager: object];
      [newTextStorage addLayoutManager: object];
      RELEASE(object);
    }
}


- (id) delegate
{
  return _delegate;
}
- (void) setDelegate: (id)aDelegate
{
  _delegate = aDelegate;
}


- (BOOL) usesScreenFonts
{
  return usesScreenFonts;
}
- (void) setUsesScreenFonts: (BOOL)flag
{
  flag = !!flag;
  if (flag == usesScreenFonts)
    return;
  usesScreenFonts = flag;
  [self _invalidateEverything];
}

- (NSFont *) substituteFontForFont: (NSFont *)originalFont
{
  NSFont *f;
  if (usesScreenFonts)
    {
      f = [originalFont screenFont];
      if (f)
	return f;
    }
  return originalFont;
}


- (void) setBackgroundLayoutEnabled: (BOOL)flag
{
  flag = !!flag;
  if (flag == backgroundLayoutEnabled)
    return;
  backgroundLayoutEnabled = flag;
  /* TODO */
}
- (BOOL) backgroundLayoutEnabled
{
  return backgroundLayoutEnabled;
}

- (void) setShowsInvisibleCharacters: (BOOL)flag
{
  flag = !!flag;
  if (flag == showsInvisibleCharacters)
    return;

  showsInvisibleCharacters = flag;
  [self _invalidateEverything];
}
- (BOOL) showsInvisibleCharacters
{
  return showsInvisibleCharacters;
}

- (void) setShowsControlCharacters: (BOOL)flag
{
  flag = !!flag;
  if (flag == showsControlCharacters)
    return;
  showsControlCharacters = flag;
  [self _invalidateEverything];
}
- (BOOL) showsControlCharacters
{
  return showsControlCharacters;
}


- (void) textStorage: (NSTextStorage *)aTextStorage
	      edited: (unsigned int)mask
	       range: (NSRange)range
      changeInLength: (int)lengthChange
    invalidatedRange: (NSRange)invalidatedRange
{
  NSRange r;

  if (!(mask & NSTextStorageEditedCharacters))
    lengthChange = 0;

/*	printf("edited: range=(%i+%i) invalidatedRange=(%i+%i) delta=%i\n",
		range.location, range.length,
		invalidatedRange.location, invalidatedRange.length,
		lengthChange);*/

  [self invalidateGlyphsForCharacterRange: invalidatedRange
	changeInLength: lengthChange
	actualCharacterRange: &r];

  [self invalidateLayoutForCharacterRange: r
	isSoft: NO
	actualCharacterRange: &r];
  r.location += r.length;
  r.length = [_textStorage length] - r.location;
  [self invalidateLayoutForCharacterRange: r
	isSoft: YES
	actualCharacterRange: NULL];
}


/* These must be in the main implementation so backends can override them
in a category safely. */

/* These three methods should be implemented in the backend, but there's
a dummy here. It maps each character to a glyph with the glyph id==unicode
index, except control characters, which are mapped to NSControlGlyph. */

-(unsigned int) _findSafeBreakMovingBackwardFrom: (unsigned int)ch
{
  return ch;
}

-(unsigned int) _findSafeBreakMovingForwardFrom: (unsigned int)ch
{
  return ch;
}


/* TODO2: put good control code handling here in a way that makes it easy
for the backends to use it */
-(void) _generateGlyphsForRun: (glyph_run_t *)run  at: (unsigned int)pos
{
  int i, c = run->head.char_length;
  unsigned int ch;
  unichar buf[c];

  glyph_t *g;

  NSCharacterSet *cs = [NSCharacterSet controlCharacterSet];
  IMP characterIsMember = [cs methodForSelector: @selector(characterIsMember:)];

  run->head.glyph_length = c;
  run->glyphs = malloc(sizeof(glyph_t) * c);
  memset(run->glyphs, 0, sizeof(glyph_t) * c);

  [[_textStorage string] getCharacters: buf
			 range: NSMakeRange(pos, c)];

  g = run->glyphs;
  for (i = 0; i < c; i++)
    {
      ch = buf[i];
      g->char_offset = i;
      if (characterIsMember(cs, @selector(characterIsMember:), ch))
	g->g = NSControlGlyph;
      else if (ch == NSAttachmentCharacter)
	g->g = GSAttachmentGlyph;
      else
	g->g = ch;
      g++;
    }
}

@end

