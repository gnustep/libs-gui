/*
   NSLayoutManager.m

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

/*
TODO: document exact requirements on typesetting for this class

Roughly:

Line frag rects arranged in lines in which all line frag rects have same
y-origin and height. Lines don't overlap. Line frag rects go left->right,
as do points in the line frag rects.
*/

#include "AppKit/NSLayoutManager.h"
#include "AppKit/GSLayoutManager_internal.h"

#include <AppKit/NSTextContainer.h>
#include <AppKit/NSTextStorage.h>
#include <AppKit/DPSOperators.h>
#include <AppKit/NSColor.h>



@interface NSLayoutManager (layout_helpers)
-(void) _doLayoutToContainer: (int)cindex  point: (NSPoint)p;
@end

@implementation NSLayoutManager (layout_helpers)
-(void) _doLayoutToContainer: (int)cindex  point: (NSPoint)p
{
	[self _doLayout];
}
@end


@implementation NSLayoutManager (layout)

- (NSPoint) locationForGlyphAtIndex: (unsigned int)glyphIndex
{
	NSRange r;
	NSPoint p;
	NSFont *f;
	unsigned int i;

	r=[self rangeOfNominallySpacedGlyphsContainingIndex: glyphIndex
		startLocation: &p];

	i=r.location;
	f=[self effectiveFontForGlyphAtIndex: i
		range: &r];
	for (;i<glyphIndex;i++)
	{
		if (i==r.location+r.length)
		{
			f=[self effectiveFontForGlyphAtIndex: i
				range: &r];
		}
		p.x+=[f advancementForGlyph: [self glyphAtIndex: i]].width;
	}
	return p;
}


- (void) textContainerChangedTextView: (NSTextContainer *)aContainer
{
/* TODO: what do we do here? invalidate the displayed range for that
container? */
	int i;
	for (i=0;i<num_textcontainers;i++)
		[[textcontainers[i].textContainer textView] _updateMultipleTextViews];
}


- (NSRect *) rectArrayForGlyphRange: (NSRange)glyphRange
	withinSelectedGlyphRange: (NSRange)selGlyphRange
	inTextContainer: (NSTextContainer *)container
	rectCount: (unsigned int *)rectCount
{
	unsigned int last=glyphRange.location+glyphRange.length;
	int i;
	textcontainer_t *tc;
	linefrag_t *lf;
	int num_rects;
	float x0,x1;
	NSRect r;

	[self _doLayoutToGlyph: last-1];

	for (tc=textcontainers,i=0;i<num_textcontainers;i++,tc++)
		if (tc->textContainer==container)
			break;
	if (i==num_textcontainers ||
	    tc->pos+tc->length<last ||
	    tc->pos>glyphRange.location)
	{
		NSLog(@"%s: invalid text container",__PRETTY_FUNCTION__);
		*rectCount=0;
		return NULL;
	}

	if (!glyphRange.length)
	{
		*rectCount=0;
		return NULL;
	}

	num_rects=0;

	for (lf=tc->linefrags,i=0;i<tc->num_linefrags;i++,lf++)
		if (lf->pos+lf->length>glyphRange.location)
			break;

	while (1)
	{
		if (lf->pos<glyphRange.location)
		{
			int i,j;
			linefrag_point_t *lp;
			glyph_run_t *r;
			unsigned int gpos,cpos;

			for (j=0,lp=lf->points;j<lf->num_points;j++)
				if (lp->pos+lp->length>glyphRange.location)
					break;

			x0=lp->p.x+lf->rect.origin.x;
			r=run_for_glyph_index(lp->pos,glyphs,&gpos,&cpos);
			i=lp->pos-gpos;

			while (i+gpos<glyphRange.location)
			{
				if (!r->glyphs[i].isNotShown && r->glyphs[i].g &&
				    r->glyphs[i].g!=NSControlGlyph)
					x0+=[r->font advancementForGlyph: r->glyphs[i].g].width;
				GLYPH_STEP_FORWARD(r,i,gpos,cpos)
			}
		}
		else
			x0=NSMinX(lf->rect);

		if (lf->pos+lf->length>last)
		{
			int i,j;
			linefrag_point_t *lp;
			glyph_run_t *r;
			unsigned int gpos,cpos;

			/* At this point there is a glyph in our range that is in this
			line frag rect. If we're on the first line frag rect, it's
			trivially true. If not, the check before the lf++; ensures it. */
			for (j=0,lp=lf->points;j<lf->num_points;j++)
				if (lp->pos<last)
					break;

			x1=lp->p.x+lf->rect.origin.x;
			r=run_for_glyph_index(lp->pos,glyphs,&gpos,&cpos);
			i=lp->pos-gpos;

			while (i+gpos<last)
			{
				if (!r->glyphs[i].isNotShown && r->glyphs[i].g &&
				    r->glyphs[i].g!=NSControlGlyph)
					x1+=[r->font advancementForGlyph: r->glyphs[i].g].width;
				GLYPH_STEP_FORWARD(r,i,gpos,cpos)
			}
		}
		else
			x1=NSMaxX(lf->rect);

		r=NSMakeRect(x0,lf->rect.origin.y,x1-x0,lf->rect.size.height);
		if (num_rects &&
		    r.origin.x==rect_array[num_rects-1].origin.x &&
		    r.size.width==rect_array[num_rects-1].size.width &&
		    r.origin.y==NSMaxY(rect_array[num_rects-1]))
		{
			rect_array[num_rects-1].size.height+=r.size.height;
		}
		else
		{
			if (num_rects==rect_array_size)
			{
				rect_array_size+=4;
				rect_array=realloc(rect_array,sizeof(NSRect)*rect_array_size);
			}
			rect_array[num_rects++]=r;
		}

		if (lf->pos+lf->length>=last)
			break;
		lf++;
	}

	*rectCount=num_rects;
	return rect_array;
}

- (NSRect *) rectArrayForCharacterRange: (NSRange)charRange
	withinSelectedCharacterRange: (NSRange)selCharRange
	inTextContainer: (NSTextContainer *)container
	rectCount: (unsigned int *)rectCount
{
	NSRange r1,r2;

	r1=[self glyphRangeForCharacterRange: charRange
		actualCharacterRange: NULL];
	r2=[self glyphRangeForCharacterRange: selCharRange
		actualCharacterRange: NULL];

	return [self rectArrayForGlyphRange: r1
		withinSelectedGlyphRange: r2
		inTextContainer: container
		rectCount: rectCount];
}

- (NSRect) boundingRectForGlyphRange: (NSRange)glyphRange 
	inTextContainer: (NSTextContainer *)aTextContainer
{
	NSRect *r;
	NSRect result;
	int i,c;

/* TODO: This isn't correct. Need to handle glyphs that extend outside the
line frag rect. */
//	printf("get bounding rect for (%u+%u)\n",glyphRange.location,glyphRange.length);
	r=[self rectArrayForGlyphRange: glyphRange
		withinSelectedGlyphRange: NSMakeRange(NSNotFound,0)
		inTextContainer: aTextContainer
		rectCount: &c];

	if (!c)
		return NSZeroRect;

	result=r[0];
	for (r++,i=1;i<c;i++,r++)
		result=NSUnionRect(result,*r);

/*	NSLog(@"%@ %s  for glyphs (%u+%u)  (%g %g)+(%g %g) in %@\n",self,__PRETTY_FUNCTION__,
		glyphRange.location,glyphRange.length,
		result.origin.x,result.origin.y,
		result.size.width,result.size.height,
		aTextContainer);*/

	return result;
}


- (NSRange) glyphRangeForBoundingRect: (NSRect)bounds 
	inTextContainer: (NSTextContainer *)container
{
	NSLog(@"%@ %s  (%g %g)+(%g %g) in %@\n",self,__PRETTY_FUNCTION__,
		bounds.origin.x,bounds.origin.y,
		bounds.size.width,bounds.size.height,
		container);
	return NSMakeRange(0,[self numberOfGlyphs]);
}

- (NSRange) glyphRangeForBoundingRectWithoutAdditionalLayout: (NSRect)bounds
	inTextContainer: (NSTextContainer *)container
{
	/* OPT: handle faster? how? */
	return [self glyphRangeForBoundingRect: bounds
		inTextContainer: container];
}


- (unsigned int) glyphIndexForPoint: (NSPoint)aPoint
	inTextContainer: (NSTextContainer *)aTextContainer
{
	return [self glyphIndexForPoint: aPoint
		inTextContainer: aTextContainer
		fractionOfDistanceThroughGlyph: NULL];
}

/* LR */
- (unsigned int) glyphIndexForPoint: (NSPoint)point
	inTextContainer: (NSTextContainer *)container
	fractionOfDistanceThroughGlyph: (float *)partialFraction
{
	int i;
	textcontainer_t *tc;
	linefrag_t *lf;
	linefrag_point_t *lp;
	float dummy;

	if (!partialFraction)
		partialFraction=&dummy;

	for (tc=textcontainers,i=0;i<num_textcontainers;i++,tc++)
		if (tc->textContainer==container)
			break;
	if (i==num_textcontainers)
	{
		NSLog(@"%s: invalid text container",__PRETTY_FUNCTION__);
		return -1;
	}

	[self _doLayoutToContainer: i  point: point];

	for (i=0,lf=tc->linefrags;i<tc->num_linefrags;i++,lf++)
		if (NSPointInRect(point,lf->rect))
			break;
	if (i==tc->num_linefrags)
		return -1;

	/* only interested in x from here on */
	point.x-=lf->rect.origin.x;

	/* scan to the first point beyond the target */
	for (i=0,lp=lf->points;i<lf->num_points;i++,lp++)
		if (lp->p.x>point.x)
			break;

	/* Before the first glyph on the line. */
	if (!i)
	{
		/* TODO: what if it isn't shown? */
		*partialFraction=0;
		return lp->pos;
	}
	else
	{
		float cur,prev,next;
		glyph_run_t *r;
		unsigned int glyph_pos,char_pos,last_visible;

		if (i<lf->num_points)
			next=lp->p.x;
		else
			next=NSMinX(lf->rect); /* TODO? */

		lp--;
		r=run_for_glyph_index(lp->pos,glyphs,&glyph_pos,&char_pos);

		prev=lp->p.x;

		last_visible=(unsigned int)-1;
		for (i=lp->pos-glyph_pos;i+glyph_pos<lp->pos+lp->length;)
		{
			if (r->glyphs[i].isNotShown || r->glyphs[i].g==NSControlGlyph ||
			    !r->glyphs[i].g)
			{
				GLYPH_STEP_FORWARD(r,i,glyph_pos,char_pos)
				continue;
			}
			last_visible=i+glyph_pos;

			cur=prev+[r->font advancementForGlyph: r->glyphs[i].g].width;
			if (i+glyph_pos+1==lp->pos+lp->length && next>cur)
				cur=next;

			if (cur>=point.x)
			{
				*partialFraction=(point.x-prev)/(cur-prev);
				if (*partialFraction<0)
					*partialFraction=0;
				return i+glyph_pos;
			}
			prev=cur;
			GLYPH_STEP_FORWARD(r,i,glyph_pos,char_pos)
		}
		*partialFraction=1;
		return last_visible;
	}
}

@end




@implementation NSLayoutManager (drawing)


/** Drawing **/

/* TODO: reconsider silently clamping ranges in these methods; might
want to make sure we don't do it if part of the range is in a second
container */

-(void) drawBackgroundForGlyphRange: (NSRange)range
	atPoint: (NSPoint)containerOrigin
{
	NSTextContainer *textContainer;
	glyph_run_t *glyph_run;
	unsigned int glyph_pos,char_pos;
	int i,j;
	NSRect *rects;
	int count;
	NSColor *color,*last_color;

	NSGraphicsContext *ctxt=GSCurrentContext();


	if (!range.length)
		return;
	[self _doLayoutToGlyph: range.location+range.length-1];

	{
		int i;
		textcontainer_t *tc;

		for (i=0,tc=textcontainers;i<num_textcontainers;i++,tc++)
			if (tc->pos+tc->length>range.location)
				break;
		if (i==num_textcontainers)
		{
			NSLog(@"%s: can't find text container for glyph (internal error)",__PRETTY_FUNCTION__);
			return;
		}

		/* We might not be able to lay out all the requested glyphs (out of
		space in the container), so we need to clamp here. */
		if (range.location+range.length>tc->pos+tc->length)
			range.length=tc->pos+tc->length-range.location;

		textContainer=tc->textContainer;
	}

	glyph_run=run_for_glyph_index(range.location,glyphs,&glyph_pos,&char_pos);
	i=range.location-glyph_pos;
	last_color=nil;
	while (1)
	{
		rects=[self rectArrayForGlyphRange:
				NSMakeRange(glyph_pos+i,glyph_run->head.glyph_length-i)
			withinSelectedGlyphRange: NSMakeRange(NSNotFound,0)
			inTextContainer: textContainer
			rectCount: &count];

		if (count)
		{
			color=[_textStorage attribute: NSBackgroundColorAttributeName
				atIndex: char_pos
				effectiveRange: NULL];
			if (color)
			{
				if (last_color!=color)
				{
					[color set];
					last_color=color;
				}
				for (j=0;j<count;j++,rects++)
				{
					DPSrectfill(ctxt,
						rects->origin.x+containerOrigin.x,
						rects->origin.y+containerOrigin.y,
						rects->size.width,rects->size.height);
				}
			}
		}
		glyph_pos+=glyph_run->head.glyph_length;
		char_pos+=glyph_run->head.char_length;
		i=0;
		glyph_run=(glyph_run_t *)glyph_run->head.next;
		if (i+glyph_pos>=range.location+range.length)
			break;
	}
}


-(void) drawGlyphsForGlyphRange: (NSRange)range
	atPoint: (NSPoint)containerOrigin
{
	int i,j;
	textcontainer_t *tc;
	linefrag_t *lf;
	linefrag_point_t *lp;

	NSPoint p;
	unsigned int g;

	NSDictionary *attributes;
	NSFont *f;
	NSColor *color,*new_color;

	glyph_run_t *glyph_run;
	unsigned int glyph_pos,char_pos;
	glyph_t *glyph;

	NSGraphicsContext *ctxt=GSCurrentContext();

#define GBUF_SIZE 16
	NSGlyph gbuf[GBUF_SIZE];
	int gbuf_len;
	NSPoint gbuf_point;


//printf("draw glyphs %i+%i at (%g %g)\n",range.location,range.length,containerOrigin.x,containerOrigin.y);
/*[self _glyphDumpRuns];*/
	if (!range.length)
		return;
	[self _doLayoutToGlyph: range.location+range.length-1];

	for (i=0,tc=textcontainers;i<num_textcontainers;i++,tc++)
		if (tc->pos+tc->length>range.location)
			break;
	if (i==num_textcontainers)
	{
		NSLog(@"%s: can't find text container for glyph (internal error)",__PRETTY_FUNCTION__);
		return;
	}

	/* We might not be able to lay out all the requested glyphs (out of
	space in the container), so we need to clamp here. */
	if (range.location+range.length>tc->pos+tc->length)
		range.length=tc->pos+tc->length-range.location;

	for (i=0,lf=tc->linefrags;i<tc->num_linefrags;i++,lf++)
		if (lf->pos+lf->length>range.location)
			break;
	if (i==tc->num_linefrags)
	{
		NSLog(@"%s: can't find line frag rect for glyph (internal error)",__PRETTY_FUNCTION__);
		return;
	}

	j=0;
	lp=lf->points;
	while (lp->pos+lp->length<range.location)
		lp++,j++;

//printf("linefrag %i, point %i\n",i,j);

	glyph_run=run_for_glyph_index(lp->pos,glyphs,&glyph_pos,&char_pos);
	glyph=glyph_run->glyphs+lp->pos-glyph_pos;
	attributes=[_textStorage attributesAtIndex: char_pos
		effectiveRange: NULL];
	color=[attributes valueForKey: NSForegroundColorAttributeName];
	if (color)
		[color set];
	else
	{
		DPSsetgray(ctxt,0.0);
		DPSsetalpha(ctxt,1.0);
	}
	f=glyph_run->font;
	[f set];
//printf("set font %@\n",f);

	p=lp->p;
	p.x+=lf->rect.origin.x+containerOrigin.x;
	p.y+=lf->rect.origin.y+containerOrigin.y;
//printf("start at %i\n",lp->pos);
	gbuf_len=0;
	for (g=lp->pos;g<range.location+range.length;g++,glyph++)
	{
//printf("glyph %i\n",g);
		if (g==lp->pos+lp->length)
		{
			if (gbuf_len)
			{
//printf("%i at (%g %g) 1\n",gbuf_len,gbuf_point.x,gbuf_point.y);
				DPSmoveto(ctxt,gbuf_point.x,gbuf_point.y);
				GSShowGlyphs(ctxt,gbuf,gbuf_len);
				DPSnewpath(ctxt);
				gbuf_len=0;
			}
//printf("  advance point\n");
			j++;
			lp++;
			if (j==lf->num_points)
			{
				i++;
				lf++;
				j=0;
				lp=lf->points;
			}
			p=lp->p;
			p.x+=lf->rect.origin.x+containerOrigin.x;
			p.y+=lf->rect.origin.y+containerOrigin.y;
		}
		if (g==glyph_pos+glyph_run->head.glyph_length)
		{
//printf("  advance run\n");
			glyph_pos+=glyph_run->head.glyph_length;
			char_pos+=glyph_run->head.char_length;
			glyph_run=(glyph_run_t *)glyph_run->head.next;
			attributes=[_textStorage attributesAtIndex: char_pos
				effectiveRange: NULL];
			new_color=[attributes valueForKey: NSForegroundColorAttributeName];
			glyph=glyph_run->glyphs;
			if (glyph_run->font!=f || new_color!=color)
			{
				if (gbuf_len)
				{
//printf("%i at (%g %g) 2\n",gbuf_len,gbuf_point.x,gbuf_point.y);
					DPSmoveto(ctxt,gbuf_point.x,gbuf_point.y);
					GSShowGlyphs(ctxt,gbuf,gbuf_len);
					DPSnewpath(ctxt);
					gbuf_len=0;
				}
				color=new_color;
				if (color)
					[color set];
				else
				{
					DPSsetgray(ctxt,0.0);
					DPSsetalpha(ctxt,1.0);
				}
				f=glyph_run->font;
				[f set];
//printf("set font %@\n",f);
			}
		}
//printf("  (%04x %i) (%g %g)\n",glyph->g,glyph->isNotShown,p.x,p.y);
		if (!glyph->isNotShown && glyph->g && glyph->g!=NSControlGlyph)
		{
//printf("%i %i\n",g,range.location);
			if (g>=range.location)
			{
				if (!gbuf_len)
				{
					gbuf[0]=glyph->g;
					gbuf_point=p;
					gbuf_len=1;
				}
				else
				{
					if (gbuf_len==GBUF_SIZE)
					{
//printf("%i at (%g %g) 3\n",gbuf_len,gbuf_point.x,gbuf_point.y);
						DPSmoveto(ctxt,gbuf_point.x,gbuf_point.y);
						GSShowGlyphs(ctxt,gbuf,GBUF_SIZE);
						DPSnewpath(ctxt);
						gbuf_len=0;
						gbuf_point=p;
					}
					gbuf[gbuf_len++]=glyph->g;
				}
			}
			p.x+=[f advancementForGlyph: glyph->g].width;
		}
	}
	if (gbuf_len)
	{
/*int i;
printf("%i at (%g %g) 4\n",gbuf_len,gbuf_point.x,gbuf_point.y);
for (i=0;i<gbuf_len;i++) printf("   %3i : %04x\n",i,gbuf[i]);*/
		DPSmoveto(ctxt,gbuf_point.x,gbuf_point.y);
		GSShowGlyphs(ctxt,gbuf,gbuf_len);
		DPSnewpath(ctxt);
	}
#undef GBUF_SIZE
//	printf("   done\n");
}

@end


@implementation NSLayoutManager

- (void) insertTextContainer: (NSTextContainer *)aTextContainer
		     atIndex: (unsigned int)index
{
  int i;

  [super insertTextContainer: aTextContainer
  	atIndex: index];

  for (i = 0; i < num_textcontainers; i++)
    [[textcontainers[i].textContainer textView] _updateMultipleTextViews];
}

- (void) removeTextContainerAtIndex: (unsigned int)index
{
  int i;

  [super removeTextContainerAtIndex: index];

  for (i = 0; i < num_textcontainers; i++)
    [[textcontainers[i].textContainer textView] _updateMultipleTextViews];
}

@end

