/*
   GSHorizontalTypesetter.m

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

#include "AppKit/GSHorizontalTypesetter.h"

#include "AppKit/GSLayoutManager.h"

#include <Foundation/NSLock.h>
#include <Foundation/NSValue.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSTextStorage.h>
#include <AppKit/NSParagraphStyle.h>
#include <AppKit/NSTextContainer.h>



@implementation GSHorizontalTypesetter

- init
{
  if (!(self = [super init])) return nil;
  lock = [[NSLock alloc] init];
  return self;
}

-(void) dealloc
{
  if (cache)
    {
      free(cache);
      cache = NULL;
    }
  [super dealloc];
}

+(GSHorizontalTypesetter *) sharedInstance
{
static GSHorizontalTypesetter *shared;
  if (!shared)
    shared = [[self alloc] init];
  return shared;
}


typedef struct GSHorizontalTypesetter_glyph_cache_s
{
  NSGlyph g;
  int char_index;

  NSFont *font;
  struct
    {
      BOOL explicit_kern;
      float kern;
      float baseline_offset;
      int superscript;
    } attributes;

  BOOL nominal;
  NSPoint pos; /* relative to the baseline */
  float width;
  BOOL dont_show, outside_line_frag;
} glyph_cache_t;


/* TODO: if we could know whether the layout manager had been modified since
the last time or not, we wouldn't need to clear the cache every time */
-(void) _cacheClear
{
  cache_length=0;
}

-(void) _cacheAttributes
{
  NSNumber *n;

  n=[curAttributes objectForKey: NSKernAttributeName];
  if (!n)
    attributes.explicit_kern=NO;
  else
    {
      attributes.explicit_kern=YES;
      attributes.kern=[n floatValue];
    }

  n=[curAttributes objectForKey: NSBaselineOffsetAttributeName];
  if (n)
    attributes.baseline_offset=[n floatValue];
  else
    attributes.baseline_offset=0.0;

  n=[curAttributes objectForKey: NSSuperscriptAttributeName];
  if (n)
    attributes.superscript=[n intValue];
  else
    attributes.superscript=0;
}

-(void) _cacheMoveTo: (unsigned int)glyph
{
	BOOL valid;

	if (cache_base<=glyph && cache_base+cache_length>glyph)
	{
		int delta=glyph-cache_base;
		cache_length-=delta;
		memmove(cache,&cache[delta],sizeof(glyph_cache_t)*cache_length);
		cache_base=glyph;
		return;
	}

	cache_base=glyph;
	cache_length=0;

	[curLayoutManager glyphAtIndex: glyph
		isValidIndex: &valid];

	if (valid)
	{
		unsigned int i;

		at_end=NO;
		i=[curLayoutManager characterIndexForGlyphAtIndex: glyph];
		curAttributes=[curTextStorage attributesAtIndex: i
			effectiveRange: &attributeRange];
		[self _cacheAttributes];

		paragraphRange=NSMakeRange(i,[curTextStorage length]-i);
		curParagraphStyle=[curTextStorage attribute: NSParagraphStyleAttributeName
			atIndex: i
			longestEffectiveRange: &paragraphRange
			inRange: paragraphRange];

		curFont=[curLayoutManager effectiveFontForGlyphAtIndex: glyph
			range: &fontRange];
	}
	else
		at_end=YES;
}

-(void) _cacheGlyphs: (unsigned int)new_length
{
	glyph_cache_t *g;
	BOOL valid;

	if (cache_size<new_length)
	{
		cache_size=new_length;
		cache=realloc(cache,sizeof(glyph_cache_t)*cache_size);
	}

	for (g=&cache[cache_length];cache_length<new_length;cache_length++,g++)
	{
		g->g=[curLayoutManager glyphAtIndex: cache_base+cache_length
			isValidIndex: &valid];
		if (!valid)
		{
			at_end=YES;
			break;
		}
		g->char_index=[curLayoutManager characterIndexForGlyphAtIndex: cache_base+cache_length];
//		printf("cache glyph %i, char %i\n",cache_base+cache_length,g->char_index);
		if (g->char_index>=paragraphRange.location+paragraphRange.length)
		{
			at_end=YES;
			break;
		}

		/* cache attributes */
		if (g->char_index>=attributeRange.location+attributeRange.length)
		{
			curAttributes=[curTextStorage attributesAtIndex: g->char_index
				effectiveRange: &attributeRange];
			[self _cacheAttributes];
		}

		g->attributes.explicit_kern=attributes.explicit_kern;
		g->attributes.kern=attributes.kern;
		g->attributes.baseline_offset=attributes.baseline_offset;
		g->attributes.superscript=attributes.superscript;

		if (cache_base+cache_length>=fontRange.location+fontRange.length)
		{
			curFont=[curLayoutManager effectiveFontForGlyphAtIndex: cache_base+cache_length
				range: &fontRange];
		}
		g->font=curFont;

		g->dont_show=NO;
		g->outside_line_frag=NO;
	}
}


/*
Should return the first glyph on the next line, which must be <=gi and
>=cache_base (TODO: not enough). Glyphs up to and including gi will have
been cached.
*/
-(unsigned int) breakLineByWordWrappingBefore: (unsigned int)gi
{
	glyph_cache_t *g;
	unichar ch;
	NSString *str=[curTextStorage string];

	gi-=cache_base;
	g=cache+gi;

	while (gi>0)
	{
		if (g->g==NSControlGlyph)
			return gi;
		ch=[str characterAtIndex: g->char_index];
		if (ch==0x20 || ch==0x0a || ch==0x0d /* TODO: paragraph/line separator */ )
		{
			g->dont_show=YES;
			if (gi>0)
			{
				g->pos=g[-1].pos;
				g->pos.x+=g[-1].width;
			}
			else
				g->pos=NSMakePoint(0,0);
			g->width=0;
			return gi+1+cache_base;
		}
		gi--;
		g--;
	}
	return gi+cache_base;
}


typedef struct
{
	NSRect rect;
	float last_used;
	unsigned int last_glyph; /* last_glyph+1, actually */
} line_frag_t;


-(void) fullJustifyLine: (line_frag_t *)lf : (int)num_line_frags
{
	unsigned int i,start;
	float extra_space,delta;
	unsigned int num_spaces;
	NSString *str=[curTextStorage string];
	glyph_cache_t *g;
	unichar ch;

	for (start=0;num_line_frags;num_line_frags--,lf++)
	{
		num_spaces=0;
		for (i=start,g=cache+i;i<lf->last_glyph;i++,g++)
		{
			if (g->dont_show)
				continue;
			ch=[str characterAtIndex: g->char_index];
			if (ch==0x20)
				num_spaces++;
		}
		if (!num_spaces)
			continue;

		extra_space=lf->rect.size.width-lf->last_used;
		extra_space/=num_spaces;
		delta=0;
		for (i=start,g=cache+i;i<lf->last_glyph;i++,g++)
		{
			g->pos.x+=delta;
			if (!g->dont_show && [str characterAtIndex: g->char_index]==0x20)
			{
				if (i<lf->last_glyph)
					g[1].nominal=NO;
				delta+=extra_space;
			}
		}
		start=lf->last_glyph;
	}
}


-(void) rightAlignLine: (line_frag_t *)lf : (int)num_line_frags
{
	unsigned int i;
	float delta;
	glyph_cache_t *g;

	for (i=0,g=cache;num_line_frags;num_line_frags--,lf++)
	{
		delta=lf->rect.size.width-lf->last_used;
		for (;i<lf->last_glyph;i++,g++)
			g->pos.x+=delta;
	}
}

-(void) centerAlignLine: (line_frag_t *)lf : (int)num_line_frags
{
	unsigned int i;
	float delta;
	glyph_cache_t *g;

	for (i=0,g=cache;num_line_frags;num_line_frags--,lf++)
	{
		delta=(lf->rect.size.width-lf->last_used)/2.0;
		for (;i<lf->last_glyph;i++,g++)
			g->pos.x+=delta;
	}
}


-(int) layoutLineNewParagraph: (BOOL)newParagraph
{
	NSRect rect,remain;
	float line_height,max_line_height,baseline;

	line_frag_t *line_frags=NULL;
	int num_line_frags=0;


	[self _cacheMoveTo: curGlyph];
	if (!cache_length)
		[self _cacheGlyphs: 16];
	if (!cache_length && at_end)
		return 2;

	{
		float min=[curParagraphStyle minimumLineHeight];
		max_line_height=[curParagraphStyle maximumLineHeight];

		/* sanity */
		if (max_line_height<min)
			max_line_height=min;

		line_height=[cache->font defaultLineHeightForFont];
		baseline=line_height+[cache->font descender];
		if (line_height<min)
			line_height=min;

		if (max_line_height>0 && line_height>max_line_height)
			line_height=max_line_height;
	}

	/* If we find out that we need to increase the line height, we have to
	start over. The increased line height might give _completely_ different
	line frag rects, so we can't reuse much of the layout information. */
restart:
//	printf("start: at (%g %g)  line_height=%g, baseline=%g\n",curPoint.x,curPoint.y,line_height,baseline);
	{
		float hindent,tindent=[curParagraphStyle tailIndent];

		if (newParagraph)
			hindent=[curParagraphStyle firstLineHeadIndent];
		else
			hindent=[curParagraphStyle headIndent];

		if (tindent<=0.0)
			tindent=[curTextContainer containerSize].width+tindent;

		remain=NSMakeRect(hindent,
			curPoint.y,
			tindent-hindent,
			line_height+[curParagraphStyle lineSpacing]);
	}

	num_line_frags=0;
	if (line_frags)
	{
		free(line_frags);
		line_frags=NULL;
	}
	while (1)
	{
		rect=[curTextContainer lineFragmentRectForProposedRect: remain
			sweepDirection: NSLineSweepRight
			movementDirection: num_line_frags?NSLineDoesntMove:NSLineMoveDown
			remainingRect: &remain];
		if (NSEqualRects(rect,NSZeroRect))
			break;

		num_line_frags++;
		line_frags=realloc(line_frags,sizeof(line_frag_t)*num_line_frags);
		line_frags[num_line_frags-1].rect=rect;
/*		printf("rect %i: (%g %g)+(%g %g)\n",
			num_line_frags-1,
			rect.origin.x,rect.origin.y,rect.size.width,rect.size.height);*/
	}
//	printf("got %i line frag rects\n",num_line_frags);
	if (!num_line_frags)
		return 1;

	{
		unsigned int i=0;
		NSFont *f=cache->font;
		glyph_cache_t *g;
		NSGlyph last_glyph=NSNullGlyph;
		NSPoint last_p,p;

		unsigned int first_glyph;
		line_frag_t *lf=line_frags;
		int lfi=0;


		last_p=p=NSMakePoint(0,0);

		g=cache;
		first_glyph=0;
		while (1)
		{
		relayout:
//			printf("do glyph %i\n",i);
			if (i>=cache_length)
			{
				if (at_end)
					break;
				[self _cacheGlyphs: cache_length+16];
				if (i==cache_length)
					break;
				g=cache+i;
			}
//			printf("cached\n");
			if (g->font!=f)
			{
				float new_height;
				f=g->font;
				last_glyph=NSNullGlyph;
				new_height=[f defaultLineHeightForFont];
				if (max_line_height>0 && new_height>max_line_height)
					new_height=max_line_height;
				if (new_height>line_height)
				{
					line_height=new_height;
					baseline=line_height+[f descender];
					goto restart;
				}
			}

			if (g->g==NSControlGlyph)
			{
				unichar ch=[[curTextStorage string] characterAtIndex: g->char_index];

				g->pos=p;
				g->width=0;
				g->dont_show=YES;
				g->nominal=YES;
				i++;
				g++;
				last_glyph=NSNullGlyph;

				if (ch==0xa)
					break;

				continue;
			}

			g->nominal=YES;
			if (g->attributes.explicit_kern)
				p.x+=g->attributes.kern;
			/* TODO: this is a major bottleneck */
/*			else if (last_glyph)
			{
				p=[f positionOfGlyph: g->g
					precededByGlyph: last_glyph
					isNominal: &g->nominal];
				p.x+=last_p.x;
				p.y+=last_p.y;
			}*/

/*			printf("place %04x %04x %2i (%2i) at (%5g %5g) (%@)\n",g->g,[[curTextStorage string] characterAtIndex: g->char_index],
				i,cache_base,p.x,p.y,f);*/

			last_p=g->pos=p;
			g->width=[f advancementForGlyph: g->g].width;
			p.x+=g->width;
			if (p.x>lf->rect.size.width)
			{
//				printf("  too much! (%g %g)\n",p.x,p.y);
				switch ([curParagraphStyle lineBreakMode])
				{
				default:
				case NSLineBreakByCharWrapping:
				char_wrapping:
					lf->last_glyph=i;
					break;

				case NSLineBreakByWordWrapping:
					lf->last_glyph=[self breakLineByWordWrappingBefore: cache_base+i]-cache_base;
					if (lf->last_glyph<=first_glyph)
						goto char_wrapping;
					break;
				}

				/* We force at least one glyph into each line frag rect. This
				ensures that typesetting will never get stuck (ie. if the text
				container is to narrow to fit even a single glyph). */
				if (lf->last_glyph<=first_glyph)
					lf->last_glyph=i+1;

				last_p=p=NSMakePoint(0,0);
				i=lf->last_glyph;
				g=cache+i;
				/* The -1 is always valid since there's at least one glyph in the
				line frag rect (see above). */
				lf->last_used=g[-1].pos.x+g[-1].width;
				last_glyph=NSNullGlyph;

				lf++;
				lfi++;
				if (lfi==num_line_frags)
					break;
				first_glyph=i;
				goto relayout;
			}

			last_glyph=g->g;
			i++;
			g++;
		}

		if (lfi!=num_line_frags)
		{
			lf->last_glyph=i;
			lf->last_used=p.x;

			/* TODO: incorrect if there is more than one line frag */
			if ([curParagraphStyle alignment]==NSRightTextAlignment)
				[self rightAlignLine: line_frags : num_line_frags];
			else if ([curParagraphStyle alignment]==NSCenterTextAlignment)
				[self centerAlignLine: line_frags : num_line_frags];

			newParagraph=YES;
		}
		else
		{
			if ([curParagraphStyle lineBreakMode]==NSLineBreakByWordWrapping &&
			    [curParagraphStyle alignment]==NSJustifiedTextAlignment)
				[self fullJustifyLine: line_frags : num_line_frags];
			else if ([curParagraphStyle alignment]==NSRightTextAlignment)
				[self rightAlignLine: line_frags : num_line_frags];
			else if ([curParagraphStyle alignment]==NSCenterTextAlignment)
				[self centerAlignLine: line_frags : num_line_frags];

			lfi--;
			newParagraph=NO;
		}
//		printf("done with line, i=%i\n",i);

//		printf("set text container for %i+%i\n",cache_base,i);
		[curLayoutManager setTextContainer: curTextContainer
			forGlyphRange: NSMakeRange(cache_base,i)];
		curGlyph=i+cache_base;
		{
			line_frag_t *lf;
			NSPoint p;
			unsigned int i,j;
			glyph_cache_t *g;

			for (lf=line_frags,i=0,g=cache;lfi>=0;lfi--,lf++)
			{
//				printf("set line frag for %i+%i\n",cache_base+i,lf->last_glyph-i);
				[curLayoutManager setLineFragmentRect: lf->rect
					forGlyphRange: NSMakeRange(cache_base+i,lf->last_glyph-i)
					usedRect: lf->rect /* TODO */ ];
				p=g->pos;
				[curLayoutManager setDrawsOutsideLineFragment: g->outside_line_frag
					forGlyphAtIndex: cache_base+i];
				[curLayoutManager setNotShownAttribute: g->dont_show
					forGlyphAtIndex: cache_base+i];
				p.y+=baseline;
				j=i;
				while (i<lf->last_glyph)
				{
					if (!g->nominal && i!=j)
					{
						[curLayoutManager setLocation: p
							forStartOfGlyphRange: NSMakeRange(cache_base+j,i-j)];
						p=g->pos;
						p.y+=baseline;
						j=i;
					}
					i++;
					g++;
				}
				if (i!=j)
				{
					[curLayoutManager setLocation: p
						forStartOfGlyphRange: NSMakeRange(cache_base+j,i-j)];
				}
			}
		}
	}
//	printf("done\n");

	curPoint=NSMakePoint(0,NSMaxY(line_frags->rect));

	if (line_frags)
	{
		free(line_frags);
		line_frags=NULL;
	}

	/* if we're really at the end, we should probably set the extra line frag
	stuff here */
	if (newParagraph)
		return 3;
	else
		return 0;
}


-(int) layoutGlyphsInLayoutManager: (GSLayoutManager *)layoutManager
	inTextContainer: (NSTextContainer *)textContainer
	startingAtGlyphIndex: (unsigned int)glyphIndex
	previousLineFragmentRect: (NSRect)previousLineFragRect
	nextGlyphIndex: (unsigned int *)nextGlyphIndex
	numberOfLineFragments: (unsigned int)howMany
{
	int ret=0;
	BOOL newParagraph;

#if BENCHMARK
{
	int ng=[layoutManager numberOfGlyphs];
	NSRange r=NSMakeRange(glyphIndex,ng-glyphIndex);
	[layoutManager setTextContainer: textContainer
		forGlyphRange: r];
	[layoutManager setLineFragmentRect: NSMakeRect(0,0,100,100)
		forGlyphRange: r
		usedRect: NSMakeRect(0,0,100,100)];
	[layoutManager setLocation: NSMakePoint(0,20)
		forStartOfGlyphRange: r];
	*nextGlyphIndex=ng;
	return 2;
}
#endif

	[lock lock];

NS_DURING
	curLayoutManager=layoutManager;
	curTextContainer=textContainer;
	curTextStorage=[layoutManager textStorage];

/*	printf("*** layout some stuff |%@|\n",curTextStorage);
	[curLayoutManager _glyphDumpRuns];*/

	curGlyph=glyphIndex;

	[self _cacheClear];

	newParagraph=NO;
	if (!curGlyph)
		newParagraph=YES;

	ret=0;
	curPoint=NSMakePoint(0,NSMaxY(previousLineFragRect));
	while (1)
	{
//		printf("layout a line, start at glyph %i\n",curGlyph);
		ret=[self layoutLineNewParagraph: newParagraph];
//		printf("  got %i\n",ret);
		if (ret==3)
		{
			newParagraph=YES;
			ret=0;
		}
		else
			newParagraph=NO;
		if (ret)
			break;

		if (howMany)
			if (!--howMany)
				break;
	}

	*nextGlyphIndex=curGlyph;
NS_HANDLER
	[lock unlock];
	printf("got exception %@\n",localException);
	[localException raise];
NS_ENDHANDLER
	[lock unlock];
//	printf("return %i\n",ret);
	return ret;
}


-(float) baselineOffsetInLayoutManager: (GSLayoutManager *)layoutManager
	glyphIndex: (unsigned int)glyphIndex
{
  return 0.0;
}

@end

