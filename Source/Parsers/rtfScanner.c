/* rtcScanner

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:  Stefan Bðhringer (stefan.boehringer@uni-bochum.de)
   Date: Dec 1999

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

#include "stdio.h"
#include "stdlib.h"
#include "ctype.h"
#include "Parsers/rtfScanner.h"
#include "Parsers/rtfGrammer.tab.h"

//	<§> scanner types and helpers

#define	CArraySize(a)	(sizeof(a)/sizeof((a)[0])-1)

typedef struct {
  char	*bf;
  int	length, position, chunkSize;
} DynamicString;
typedef struct {
  const char	*string;
  int		token;
} LexKeyword;

GSLexError	initDynamicString(DynamicString *string)
{
  string->length = 0, string->position = 0, string->chunkSize = 128;
  string->bf = calloc(1, string->length = string->chunkSize);
  if (!string->bf) 
    return LEXoutOfMemory;
  return NoError;
}

GSLexError	appendChar(DynamicString *string, int c)
{
  if (string->position == string->length)
    {
      if (!(string->bf = realloc(string->bf, 
				 string->length += string->chunkSize))) 
	return LEXoutOfMemory;
      else 
	string->chunkSize <<= 1;
    }
  
  string->bf[string->position++] = c;
  return NoError;
}

void	lexInitContext(RTFscannerCtxt *lctxt, void *customContext, 
		       int (*getcharFunction)(void *))
{
  lctxt->streamLineNumber = 1;
  lctxt->streamPosition = lctxt->pushbackCount = 0;
  lctxt->lgetchar = getcharFunction;
  lctxt->customContext = customContext;
}
int	lexGetchar(RTFscannerCtxt *lctxt)
{
  int	c;
  if (lctxt->pushbackCount)
    {
      lctxt->pushbackCount--;
      return lctxt->pushbackBuffer[lctxt->pushbackCount];
    }
  lctxt->streamPosition++;
  c = lctxt->lgetchar(lctxt->customContext);
  if (c == '\n') 
    lctxt->streamLineNumber++;
  return c;
}

void	lexUngetchar(RTFscannerCtxt *lctxt, int c)
{
  if (c == '\n') 
    lctxt->streamLineNumber--;
  lctxt->pushbackBuffer[lctxt->pushbackCount++] = c;	//<!> no checking here
}

int	lexStreamPosition(RTFscannerCtxt *lctxt)
{
  return lctxt->streamPosition - lctxt->pushbackCount;
}

char	*my_strdup(const char *str)
{
  char   *copy = str? malloc(strlen(str) + 1): 0;
  return !copy? 0: strcpy(copy, str);
}

int	findStringFromKeywordArray(const char *string, const LexKeyword *array,
				   int arrayCount)
{
  int	min, max, mid, cmp;
  const LexKeyword *currentKeyword;

  for (min=0, max=arrayCount; min<=max; )
    {
      mid = (min+max)>>1;
      currentKeyword = array + mid;
      if (!(cmp = strcmp(string, currentKeyword->string)))
	{
	  return currentKeyword->token;
	} 
      else if (cmp>0) 
	min=mid+1;
      else 
	max=mid-1;
    }
  return 0;		// couldn't find
}

//	end <§> scanner types and helpers

//	<§> core scanner functions

#define	token(a)	(a)

//	<!> must be sorted
LexKeyword	RTFcommands[]={
	"b",		token(RTFbold),
	"f", 		token(RTFfont),
	"fdecor",	token(RTFfamilyDecor),
	"fmodern",	token(RTFfamilyModern),
	"fnil",		token(RTFfamilyNil),
	"fonttbl",	token(RTFfontListStart),
	"froman",	token(RTFfamilyRoman),
	"fs",		token(RTFfontSize),
	"fscript",	token(RTFfamilyScript),
	"fswiss",	token(RTFfamilySwiss),
	"ftech",	token(RTFfamilyTech),
	"i",		token(RTFitalic),
	"margl",	token(RTFmarginLeft),
	"margr",	token(RTFmarginRight),
	"paperh",	token(RTFpaperHeight),
	"paperw",	token(RTFpaperWidth),
	"rtf",		token(RTFstart),
	"ul",		token(RTFunderline),
	"ulnone",	token(RTFunderlineStop)
};

BOOL	probeCommand(RTFscannerCtxt *lctxt)
{
  int	c = lexGetchar(lctxt);
  lexUngetchar(lctxt, c);
  return isalpha(c);
}

//	<N> According to spec a cmdLength of 32 is respected
#define	RTFMaxCmdLength			32
#define RTFMaxArgumentLength	64
GSLexError	readCommand(RTFscannerCtxt *lctxt, YYSTYPE *lvalp, int *token)	// the '\\' is already read
{
  char	cmdNameBf[RTFMaxCmdLength+1], *cmdName = cmdNameBf;
  char	argumentBf[RTFMaxArgumentLength+1], *argument = argumentBf;
  int	c, foundToken;

  lvalp->cmd.name = 0;	// initialize
  while (isalpha( c = lexGetchar(lctxt) ))
    {
      *cmdName++ = c;
      if (cmdName >= cmdNameBf + RTFMaxCmdLength) 
	return LEXsyntaxError;
    }
  *cmdName = 0;
  if (!(foundToken = findStringFromKeywordArray(cmdNameBf, RTFcommands, 
						CArraySize(RTFcommands))))
    {
      if (!(lvalp->cmd.name = my_strdup(cmdNameBf))) 
	return LEXoutOfMemory;
      *token = RTFOtherStatement;
    } 
  else 
    {
      *token = foundToken;
    }
  if (c == ' ')				// this is an empty argument
    {	
      lvalp->cmd.isEmpty = YES;
    } 
  else if (isdigit(c) || c == '-')	// we've found a numerical argument
    {
      do 
	{
	  *argument++ = c;
	  if (argument >= argumentBf + RTFMaxArgumentLength) 
	    return LEXsyntaxError;
	} while (isdigit(c = lexGetchar(lctxt)));
      *argument = 0;
      if (c != ' ') 
	lexUngetchar(lctxt, c); 	// <N> ungetc non-digit
      // the consumption of the space seems necessary on NeXT but
      // is not according to spec
      lvalp->cmd.isEmpty = NO, lvalp->cmd.parameter = atoi(argumentBf);
    } 
  else 
    {
      lvalp->cmd.isEmpty = YES;
      lexUngetchar(lctxt, c); 		// ungetc non-whitespace delimiter
    }
  return NoError;
}

GSLexError	readText(RTFscannerCtxt *lctxt, YYSTYPE *lvalp)
{
  int	c;
  DynamicString	text;
  GSLexError	error;
  
  if ((error = initDynamicString(&text))) 
    return error;
  for (;;)
    {
      c = lexGetchar(lctxt);
      
      if (c == EOF || c == '{' || c == '}')
	{
	  lexUngetchar(lctxt, c);
	  break;
	}
      if (c == '\\')	// see <p>
	{
	  if (probeCommand(lctxt))
	    {
	      lexUngetchar(lctxt, c);
	      break;
	    }
	  appendChar(&text, lexGetchar(lctxt));
	} 
      else 
	{
	  if (c != '\n' && c != '\r')	// <N> newline and cr are ignored if not quoted
	    appendChar(&text, c);
	}
    }
  appendChar(&text, 0);
  lvalp->text = text.bf;	// release is up to the consumer
  return NoError;
}

int	GSRTFlex(YYSTYPE *lvalp, YYLTYPE *llocp, RTFscannerCtxt *lctxt)	/* provide value and position in the params */ 
{
  int	c;
  int	token = 0;
  
  do	
    c = lexGetchar(lctxt);
  while ( c == '\n' || c == '\r' );	// <A> the listed characters are to be ignored
  
  switch (c)
    {
    case EOF:	token = 0;
      break;
    case '{':	token = '{';
      break;
    case '}':	token = '}';
      break;
    case '\\':
      if (probeCommand(lctxt))
	{
	  readCommand(lctxt, lvalp, &token);
	  break;
	}
      // else fall through to default: read text <A>
      // no break <A>
    default:
      lexUngetchar(lctxt, c);
      readText(lctxt, lvalp);
      token = RTFtext;
      break;
    }
  
  //*llocp = lctxt->position();
  return token;
}
