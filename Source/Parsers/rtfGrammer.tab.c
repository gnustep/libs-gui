
/*  A Bison parser, made from Parsers/rtfGrammer.y
 by  GNU Bison version 1.25
  */

#define YYBISON 1  /* Identify Bison output.  */

#define yyparse GSRTFparse
#define yylex GSRTFlex
#define yyerror GSRTFerror
#define yylval GSRTFlval
#define yychar GSRTFchar
#define yydebug GSRTFdebug
#define yynerrs GSRTFnerrs
#define YYLSP_NEEDED

#define	RTFtext	258
#define	RTFstart	259
#define	RTFansi	260
#define	RTFmac	261
#define	RTFpc	262
#define	RTFpca	263
#define	RTFignore	264
#define	RTFinfo	265
#define	RTFstylesheet	266
#define	RTFfootnote	267
#define	RTFheader	268
#define	RTFfooter	269
#define	RTFpict	270
#define	RTFred	271
#define	RTFgreen	272
#define	RTFblue	273
#define	RTFcolorbg	274
#define	RTFcolorfg	275
#define	RTFcolortable	276
#define	RTFfont	277
#define	RTFfontSize	278
#define	RTFpaperWidth	279
#define	RTFpaperHeight	280
#define	RTFmarginLeft	281
#define	RTFmarginRight	282
#define	RTFmarginTop	283
#define	RTFmarginButtom	284
#define	RTFfirstLineIndent	285
#define	RTFleftIndent	286
#define	RTFrightIndent	287
#define	RTFalignCenter	288
#define	RTFalignLeft	289
#define	RTFalignRight	290
#define	RTFstyle	291
#define	RTFbold	292
#define	RTFitalic	293
#define	RTFunderline	294
#define	RTFunderlineStop	295
#define	RTFsubscript	296
#define	RTFsuperscript	297
#define	RTFtabulator	298
#define	RTFtabstop	299
#define	RTFparagraph	300
#define	RTFdefaultParagraph	301
#define	RTFfcharset	302
#define	RTFfprq	303
#define	RTFcpg	304
#define	RTFOtherStatement	305
#define	RTFfontListStart	306
#define	RTFfamilyNil	307
#define	RTFfamilyRoman	308
#define	RTFfamilySwiss	309
#define	RTFfamilyModern	310
#define	RTFfamilyScript	311
#define	RTFfamilyDecor	312
#define	RTFfamilyTech	313

#line 35 "Parsers/rtfGrammer.y"


/*
  The overall plan is to make this grammer universal in usage.
  Intrested buddies can implement plain C functions to consume what
  the grammer is producing. this way the rtf-grammer-tree can be
  converted to what is needed: GNUstep attributed strings, tex files,
  ...
  
  The plan is laid out by defining a set of C functions which cover
  all what is needed to mangle rtf information (it is NeXT centric
  however and may even lack some features).  Be aware that some
  functions are called at specific times when some information may or
  may not be available. The first argument of all functions is a
  context, which is asked to be maintained by the consumer at
  whichever purpose seems appropriate.  This context must be passed to
  the parser by issuing 'value = GSRTFparse(ctxt, lctxt);' in the
  first place.
*/

#include <stdlib.h>
#include <string.h>
#include "Parsers/rtfScanner.h"

/*	this context is passed to the interface functions	*/
typedef void	* GSRTFctxt;
#define YYPARSE_PARAM	ctxt, lctxt
#define YYLEX_PARAM		lctxt

#define	YYERROR_VERBOSE

#include "rtfConsumerFunctions.h"


#line 70 "Parsers/rtfGrammer.y"
typedef union {
	int			number;
	const char	*text;
	RTFcmd		cmd;
} YYSTYPE;

#ifndef YYLTYPE
typedef
  struct yyltype
    {
      int timestamp;
      int first_line;
      int first_column;
      int last_line;
      int last_column;
      char *text;
   }
  yyltype;

#define YYLTYPE yyltype
#endif

#include <stdio.h>

#ifndef __cplusplus
#ifndef __STDC__
#define const
#endif
#endif



#define	YYFINAL		110
#define	YYFLAG		-32768
#define	YYNTBASE	62

#define YYTRANSLATE(x) ((unsigned)(x) <= 313 ? yytranslate[x] : 85)

static const char yytranslate[] = {     0,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,    61,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,    59,     2,    60,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     1,     2,     3,     4,     5,
     6,     7,     8,     9,    10,    11,    12,    13,    14,    15,
    16,    17,    18,    19,    20,    21,    22,    23,    24,    25,
    26,    27,    28,    29,    30,    31,    32,    33,    34,    35,
    36,    37,    38,    39,    40,    41,    42,    43,    44,    45,
    46,    47,    48,    49,    50,    51,    52,    53,    54,    55,
    56,    57,    58
};

#if YYDEBUG != 0
static const short yyprhs[] = {     0,
     0,     1,     2,    10,    12,    14,    16,    18,    19,    22,
    25,    28,    31,    34,    35,    40,    41,    47,    48,    54,
    55,    61,    62,    68,    69,    75,    76,    82,    83,    89,
    92,    94,    96,    98,   100,   102,   104,   106,   108,   110,
   112,   114,   116,   118,   120,   122,   124,   126,   128,   130,
   132,   134,   136,   138,   140,   142,   144,   149,   150,   153,
   158,   163,   164,   167,   170,   173,   176,   178,   180,   182,
   184,   186,   188,   190,   195,   196,   199,   204,   206
};

static const short yyrhs[] = {    -1,
     0,    59,    63,     4,    65,    66,    64,    60,     0,     5,
     0,     6,     0,     7,     0,     8,     0,     0,    66,    77,
     0,    66,    82,     0,    66,    76,     0,    66,     3,     0,
    66,    67,     0,     0,    59,    68,    66,    60,     0,     0,
    59,    69,     9,    66,    60,     0,     0,    59,    70,    10,
    66,    60,     0,     0,    59,    71,    11,    66,    60,     0,
     0,    59,    72,    12,    66,    60,     0,     0,    59,    73,
    13,    66,    60,     0,     0,    59,    74,    14,    66,    60,
     0,     0,    59,    75,    15,    66,    60,     0,    59,    60,
     0,    22,     0,    23,     0,    24,     0,    25,     0,    26,
     0,    27,     0,    28,     0,    29,     0,    30,     0,    31,
     0,    32,     0,    44,     0,    33,     0,    34,     0,    35,
     0,    46,     0,    36,     0,    19,     0,    20,     0,    41,
     0,    42,     0,    37,     0,    38,     0,    39,     0,    40,
     0,    50,     0,    59,    51,    78,    60,     0,     0,    78,
    79,     0,    78,    59,    79,    60,     0,    22,    81,    80,
     3,     0,     0,    80,    47,     0,    80,    48,     0,    80,
    49,     0,    80,    67,     0,    52,     0,    53,     0,    54,
     0,    55,     0,    56,     0,    57,     0,    58,     0,    59,
    21,    83,    60,     0,     0,    83,    84,     0,    16,    17,
    18,     3,     0,     3,     0,    61,     0
};

#endif

#if YYDEBUG != 0
static const short yyrline[] = { 0,
   144,   144,   145,   147,   148,   149,   150,   153,   154,   155,
   156,   157,   158,   161,   161,   162,   162,   163,   163,   164,
   164,   165,   165,   166,   166,   167,   167,   168,   168,   169,
   177,   184,   191,   198,   205,   212,   219,   226,   233,   240,
   247,   254,   261,   262,   263,   264,   265,   266,   273,   280,
   287,   294,   301,   308,   315,   316,   323,   326,   327,   328,
   334,   338,   339,   340,   341,   342,   346,   348,   349,   350,
   351,   352,   353,   361,   364,   365,   369,   374,   384
};
#endif


#if YYDEBUG != 0 || defined (YYERROR_VERBOSE)

static const char * const yytname[] = {   "$","error","$undefined.","RTFtext",
"RTFstart","RTFansi","RTFmac","RTFpc","RTFpca","RTFignore","RTFinfo","RTFstylesheet",
"RTFfootnote","RTFheader","RTFfooter","RTFpict","RTFred","RTFgreen","RTFblue",
"RTFcolorbg","RTFcolorfg","RTFcolortable","RTFfont","RTFfontSize","RTFpaperWidth",
"RTFpaperHeight","RTFmarginLeft","RTFmarginRight","RTFmarginTop","RTFmarginButtom",
"RTFfirstLineIndent","RTFleftIndent","RTFrightIndent","RTFalignCenter","RTFalignLeft",
"RTFalignRight","RTFstyle","RTFbold","RTFitalic","RTFunderline","RTFunderlineStop",
"RTFsubscript","RTFsuperscript","RTFtabulator","RTFtabstop","RTFparagraph","RTFdefaultParagraph",
"RTFfcharset","RTFfprq","RTFcpg","RTFOtherStatement","RTFfontListStart","RTFfamilyNil",
"RTFfamilyRoman","RTFfamilySwiss","RTFfamilyModern","RTFfamilyScript","RTFfamilyDecor",
"RTFfamilyTech","'{'","'}'","'\\'","rtfFile","@1","@2","rtfCharset","rtfIngredients",
"rtfBlock","@3","@4","@5","@6","@7","@8","@9","@10","rtfStatement","rtfFontList",
"rtfFonts","rtfFontStatement","rtfFontAttrs","rtfFontFamily","rtfColorDef","rtfColors",
"rtfColorStatement", NULL
};
#endif

static const short yyr1[] = {     0,
    63,    64,    62,    65,    65,    65,    65,    66,    66,    66,
    66,    66,    66,    68,    67,    69,    67,    70,    67,    71,
    67,    72,    67,    73,    67,    74,    67,    75,    67,    67,
    76,    76,    76,    76,    76,    76,    76,    76,    76,    76,
    76,    76,    76,    76,    76,    76,    76,    76,    76,    76,
    76,    76,    76,    76,    76,    76,    77,    78,    78,    78,
    79,    80,    80,    80,    80,    80,    81,    81,    81,    81,
    81,    81,    81,    82,    83,    83,    84,    84,    -1
};

static const short yyr2[] = {     0,
     0,     0,     7,     1,     1,     1,     1,     0,     2,     2,
     2,     2,     2,     0,     4,     0,     5,     0,     5,     0,
     5,     0,     5,     0,     5,     0,     5,     0,     5,     2,
     1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
     1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
     1,     1,     1,     1,     1,     1,     4,     0,     2,     4,
     4,     0,     2,     2,     2,     2,     1,     1,     1,     1,
     1,     1,     1,     4,     0,     2,     4,     1,     1
};

static const short yydefact[] = {     0,
     1,     0,     0,     4,     5,     6,     7,     8,     2,    12,
    48,    49,    31,    32,    33,    34,    35,    36,    37,    38,
    39,    40,    41,    43,    44,    45,    47,    52,    53,    54,
    55,    50,    51,    42,    46,    56,    14,     0,    13,    11,
     9,    10,    75,    58,    30,     8,     0,     0,     0,     0,
     0,     0,     0,     3,     0,     0,     0,     8,     8,     8,
     8,     8,     8,     8,    78,     0,    74,    76,     0,     0,
    57,    59,    15,     0,     0,     0,     0,     0,     0,     0,
     0,    67,    68,    69,    70,    71,    72,    73,    62,     0,
    17,    19,    21,    23,    25,    27,    29,     0,     0,    60,
    77,    61,    63,    64,    65,    14,    66,     0,     0,     0
};

static const short yydefgoto[] = {   108,
     2,    38,     8,     9,    39,    46,    47,    48,    49,    50,
    51,    52,    53,    40,    41,    56,    72,    99,    89,    42,
    55,    68
};

static const short yypact[] = {   -58,
-32768,    -2,    85,-32768,-32768,-32768,-32768,-32768,   333,-32768,
-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,
-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,
-32768,-32768,-32768,-32768,-32768,-32768,   375,   -57,-32768,-32768,
-32768,-32768,-32768,-32768,-32768,-32768,    -4,     5,    -5,     6,
    33,    38,    36,-32768,    37,   -15,    -3,-32768,-32768,-32768,
-32768,-32768,-32768,-32768,-32768,    65,-32768,-32768,   -44,    32,
-32768,-32768,-32768,    39,    81,   123,   165,   207,   249,   291,
    68,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,    27,
-32768,-32768,-32768,-32768,-32768,-32768,-32768,    52,     1,-32768,
-32768,-32768,-32768,-32768,-32768,   334,-32768,    88,    94,-32768
};

static const short yypgoto[] = {-32768,
-32768,-32768,-32768,   345,     3,-32768,-32768,-32768,-32768,-32768,
-32768,-32768,-32768,-32768,-32768,-32768,    25,-32768,-32768,-32768,
-32768,-32768
};


#define	YYLAST		435


static const short yytable[] = {    10,
     1,     3,    54,   102,    58,    60,    69,    82,    83,    84,
    85,    86,    87,    88,    59,    11,    12,    61,    13,    14,
    15,    16,    17,    18,    19,    20,    21,    22,    23,    24,
    25,    26,    27,    28,    29,    30,    31,    32,    33,    65,
    34,    10,    35,    70,    71,    62,    36,   103,   104,   105,
    64,    63,    66,    69,   101,    37,    73,    11,    12,   106,
    13,    14,    15,    16,    17,    18,    19,    20,    21,    22,
    23,    24,    25,    26,    27,    28,    29,    30,    31,    32,
    33,    81,    34,    10,    35,    98,   100,   109,    36,     4,
     5,     6,     7,   110,    90,     0,    67,    37,    91,    11,
    12,   107,    13,    14,    15,    16,    17,    18,    19,    20,
    21,    22,    23,    24,    25,    26,    27,    28,    29,    30,
    31,    32,    33,     0,    34,    10,    35,     0,     0,     0,
    36,     0,     0,     0,     0,     0,     0,     0,     0,    37,
    92,    11,    12,     0,    13,    14,    15,    16,    17,    18,
    19,    20,    21,    22,    23,    24,    25,    26,    27,    28,
    29,    30,    31,    32,    33,     0,    34,    10,    35,     0,
     0,     0,    36,     0,     0,     0,     0,     0,     0,     0,
     0,    37,    93,    11,    12,     0,    13,    14,    15,    16,
    17,    18,    19,    20,    21,    22,    23,    24,    25,    26,
    27,    28,    29,    30,    31,    32,    33,     0,    34,    10,
    35,     0,     0,     0,    36,     0,     0,     0,     0,     0,
     0,     0,     0,    37,    94,    11,    12,     0,    13,    14,
    15,    16,    17,    18,    19,    20,    21,    22,    23,    24,
    25,    26,    27,    28,    29,    30,    31,    32,    33,     0,
    34,    10,    35,     0,     0,     0,    36,     0,     0,     0,
     0,     0,     0,     0,     0,    37,    95,    11,    12,     0,
    13,    14,    15,    16,    17,    18,    19,    20,    21,    22,
    23,    24,    25,    26,    27,    28,    29,    30,    31,    32,
    33,     0,    34,    10,    35,     0,     0,     0,    36,     0,
     0,     0,     0,     0,     0,     0,     0,    37,    96,    11,
    12,     0,    13,    14,    15,    16,    17,    18,    19,    20,
    21,    22,    23,    24,    25,    26,    27,    28,    29,    30,
    31,    32,    33,     0,    34,    10,    35,     0,     0,     0,
    36,     0,   -16,   -18,   -20,   -22,   -24,   -26,   -28,    37,
    97,    11,    12,     0,    13,    14,    15,    16,    17,    18,
    19,    20,    21,    22,    23,    24,    25,    26,    27,    28,
    29,    30,    31,    32,    33,     0,    34,     0,    35,     0,
     0,     0,    36,   -16,   -18,   -20,   -22,   -24,   -26,   -28,
    57,    37,     0,    45,     0,    43,     0,     0,     0,     0,
     0,     0,    74,    75,    76,    77,    78,    79,    80,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,    44,     0,     0,     0,     0,
     0,     0,     0,     0,    45
};

static const short yycheck[] = {     3,
    59,     4,    60,     3,     9,    11,    22,    52,    53,    54,
    55,    56,    57,    58,    10,    19,    20,    12,    22,    23,
    24,    25,    26,    27,    28,    29,    30,    31,    32,    33,
    34,    35,    36,    37,    38,    39,    40,    41,    42,     3,
    44,     3,    46,    59,    60,    13,    50,    47,    48,    49,
    15,    14,    16,    22,     3,    59,    60,    19,    20,    59,
    22,    23,    24,    25,    26,    27,    28,    29,    30,    31,
    32,    33,    34,    35,    36,    37,    38,    39,    40,    41,
    42,    17,    44,     3,    46,    18,    60,     0,    50,     5,
     6,     7,     8,     0,    70,    -1,    60,    59,    60,    19,
    20,    99,    22,    23,    24,    25,    26,    27,    28,    29,
    30,    31,    32,    33,    34,    35,    36,    37,    38,    39,
    40,    41,    42,    -1,    44,     3,    46,    -1,    -1,    -1,
    50,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    59,
    60,    19,    20,    -1,    22,    23,    24,    25,    26,    27,
    28,    29,    30,    31,    32,    33,    34,    35,    36,    37,
    38,    39,    40,    41,    42,    -1,    44,     3,    46,    -1,
    -1,    -1,    50,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
    -1,    59,    60,    19,    20,    -1,    22,    23,    24,    25,
    26,    27,    28,    29,    30,    31,    32,    33,    34,    35,
    36,    37,    38,    39,    40,    41,    42,    -1,    44,     3,
    46,    -1,    -1,    -1,    50,    -1,    -1,    -1,    -1,    -1,
    -1,    -1,    -1,    59,    60,    19,    20,    -1,    22,    23,
    24,    25,    26,    27,    28,    29,    30,    31,    32,    33,
    34,    35,    36,    37,    38,    39,    40,    41,    42,    -1,
    44,     3,    46,    -1,    -1,    -1,    50,    -1,    -1,    -1,
    -1,    -1,    -1,    -1,    -1,    59,    60,    19,    20,    -1,
    22,    23,    24,    25,    26,    27,    28,    29,    30,    31,
    32,    33,    34,    35,    36,    37,    38,    39,    40,    41,
    42,    -1,    44,     3,    46,    -1,    -1,    -1,    50,    -1,
    -1,    -1,    -1,    -1,    -1,    -1,    -1,    59,    60,    19,
    20,    -1,    22,    23,    24,    25,    26,    27,    28,    29,
    30,    31,    32,    33,    34,    35,    36,    37,    38,    39,
    40,    41,    42,    -1,    44,     3,    46,    -1,    -1,    -1,
    50,    -1,     9,    10,    11,    12,    13,    14,    15,    59,
    60,    19,    20,    -1,    22,    23,    24,    25,    26,    27,
    28,    29,    30,    31,    32,    33,    34,    35,    36,    37,
    38,    39,    40,    41,    42,    -1,    44,    -1,    46,    -1,
    -1,    -1,    50,     9,    10,    11,    12,    13,    14,    15,
    46,    59,    -1,    60,    -1,    21,    -1,    -1,    -1,    -1,
    -1,    -1,    58,    59,    60,    61,    62,    63,    64,    -1,
    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
    -1,    -1,    -1,    -1,    -1,    51,    -1,    -1,    -1,    -1,
    -1,    -1,    -1,    -1,    60
};
#define YYPURE 1

/* -*-C-*-  Note some compilers choke on comments on `#line' lines.  */
#line 3 "/usr/local/share/bison.simple"

/* Skeleton output parser for bison,
   Copyright (C) 1984, 1989, 1990 Free Software Foundation, Inc.

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2, or (at your option)
   any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.  */

/* As a special exception, when this file is copied by Bison into a
   Bison output file, you may use that output file without restriction.
   This special exception was added by the Free Software Foundation
   in version 1.24 of Bison.  */

#ifndef alloca
#ifdef __GNUC__
#define alloca __builtin_alloca
#else /* not GNU C.  */
#if (!defined (__STDC__) && defined (sparc)) || defined (__sparc__) || defined (__sparc) || defined (__sgi)
#include <alloca.h>
#else /* not sparc */
#if defined (MSDOS) && !defined (__TURBOC__)
#include <malloc.h>
#else /* not MSDOS, or __TURBOC__ */
#if defined(_AIX)
#include <malloc.h>
 #pragma alloca
#else /* not MSDOS, __TURBOC__, or _AIX */
#ifdef __hpux
#ifdef __cplusplus
extern "C" {
void *alloca (unsigned int);
};
#else /* not __cplusplus */
void *alloca ();
#endif /* not __cplusplus */
#endif /* __hpux */
#endif /* not _AIX */
#endif /* not MSDOS, or __TURBOC__ */
#endif /* not sparc.  */
#endif /* not GNU C.  */
#endif /* alloca not defined.  */

/* This is the parser code that is written into each bison parser
  when the %semantic_parser declaration is not specified in the grammar.
  It was written by Richard Stallman by simplifying the hairy parser
  used when %semantic_parser is specified.  */

/* Note: there must be only one dollar sign in this file.
   It is replaced by the list of actions, each action
   as one case of the switch.  */

#define yyerrok		(yyerrstatus = 0)
#define yyclearin	(yychar = YYEMPTY)
#define YYEMPTY		-2
#define YYEOF		0
#define YYACCEPT	return(0)
#define YYABORT 	return(1)
#define YYERROR		goto yyerrlab1
/* Like YYERROR except do call yyerror.
   This remains here temporarily to ease the
   transition to the new meaning of YYERROR, for GCC.
   Once GCC version 2 has supplanted version 1, this can go.  */
#define YYFAIL		goto yyerrlab
#define YYRECOVERING()  (!!yyerrstatus)
#define YYBACKUP() \
do								\
  if (yychar == YYEMPTY && yylen == 1)				\
    { yychar = (token), yylval = (value);			\
      yychar1 = YYTRANSLATE (yychar);				\
      YYPOPSTACK;						\
      goto yybackup;						\
    }								\
  else								\
    { yyerror ("syntax error: cannot back up"); YYERROR; }	\
while (0)

#define YYTERROR	1
#define YYERRCODE	256

#ifndef YYPURE
#define YYLEX		yylex()
#endif

#ifdef YYPURE
#ifdef YYLSP_NEEDED
#ifdef YYLEX_PARAM
#define YYLEX		yylex(&yylval, &yylloc, YYLEX_PARAM)
#else
#define YYLEX		yylex(&yylval, &yylloc)
#endif
#else /* not YYLSP_NEEDED */
#ifdef YYLEX_PARAM
#define YYLEX		yylex(&yylval, YYLEX_PARAM)
#else
#define YYLEX		yylex(&yylval)
#endif
#endif /* not YYLSP_NEEDED */
#endif

/* If nonreentrant, generate the variables here */

#ifndef YYPURE

int	yychar;			/*  the lookahead symbol		*/
YYSTYPE	yylval;			/*  the semantic value of the		*/
				/*  lookahead symbol			*/

#ifdef YYLSP_NEEDED
YYLTYPE yylloc;			/*  location data for the lookahead	*/
				/*  symbol				*/
#endif

int yynerrs;			/*  number of parse errors so far       */
#endif  /* not YYPURE */

#if YYDEBUG != 0
int yydebug;			/*  nonzero means print parse trace	*/
/* Since this is uninitialized, it does not stop multiple parsers
   from coexisting.  */
#endif

/*  YYINITDEPTH indicates the initial size of the parser's stacks	*/

#ifndef	YYINITDEPTH
#define YYINITDEPTH 200
#endif

/*  YYMAXDEPTH is the maximum size the stacks can grow to
    (effective only if the built-in stack extension method is used).  */

#if YYMAXDEPTH == 0
#undef YYMAXDEPTH
#endif

#ifndef YYMAXDEPTH
#define YYMAXDEPTH 10000
#endif

/* Prevent warning if -Wstrict-prototypes.  */
#ifdef __GNUC__
/*int yyparse ();*/
#endif

#if __GNUC__ > 1		/* GNU C and GNU C++ define this.  */
#define __yy_memcpy(TO,FROM,COUNT)	__builtin_memcpy(TO,FROM,COUNT)
#else				/* not GNU C or C++ */
#ifndef __cplusplus

/* This is the most reliable way to avoid incompatibilities
   in available built-in functions on various systems.  */
static void
__yy_memcpy (to, from, count)
     char *to;
     char *from;
     int count;
{
  register char *f = from;
  register char *t = to;
  register int i = count;

  while (i-- > 0)
    *t++ = *f++;
}

#else /* __cplusplus */

/* This is the most reliable way to avoid incompatibilities
   in available built-in functions on various systems.  */
static void
__yy_memcpy (char *to, char *from, int count)
{
  register char *f = from;
  register char *t = to;
  register int i = count;

  while (i-- > 0)
    *t++ = *f++;
}

#endif
#endif

#line 196 "/usr/local/share/bison.simple"

/* The user can define YYPARSE_PARAM as the name of an argument to be passed
   into yyparse.  The argument should have type void *.
   It should actually point to an object.
   Grammar actions can access the variable by casting it
   to the proper pointer type.  */

typedef void	*VOIDP;
#ifdef YYPARSE_PARAM
#ifdef __cplusplus
#define YYPARSE_PARAM_ARG void *YYPARSE_PARAM
#define YYPARSE_PARAM_DECL
#else /* not __cplusplus */
#define YYPARSE_PARAM_ARG YYPARSE_PARAM
#define YYPARSE_PARAM_DECL VOIDP	YYPARSE_PARAM;
#endif /* not __cplusplus */
#else /* not YYPARSE_PARAM */
#define YYPARSE_PARAM_ARG
#define YYPARSE_PARAM_DECL
#endif /* not YYPARSE_PARAM */

int
yyparse(YYPARSE_PARAM_ARG)
     YYPARSE_PARAM_DECL
{
  register int yystate;
  register int yyn;
  register short *yyssp;
  register YYSTYPE *yyvsp;
  int yyerrstatus;	/*  number of tokens to shift before error messages enabled */
  int yychar1 = 0;		/*  lookahead token as an internal (translated) token number */

  short	yyssa[YYINITDEPTH];	/*  the state stack			*/
  YYSTYPE yyvsa[YYINITDEPTH];	/*  the semantic value stack		*/

  short *yyss = yyssa;		/*  refer to the stacks thru separate pointers */
  YYSTYPE *yyvs = yyvsa;	/*  to allow yyoverflow to reallocate them elsewhere */

#ifdef YYLSP_NEEDED
  YYLTYPE yylsa[YYINITDEPTH];	/*  the location stack			*/
  YYLTYPE *yyls = yylsa;
  YYLTYPE *yylsp;

#define YYPOPSTACK   (yyvsp--, yyssp--, yylsp--)
#else
#define YYPOPSTACK   (yyvsp--, yyssp--)
#endif

  int yystacksize = YYINITDEPTH;

#ifdef YYPURE
  int yychar;
  YYSTYPE yylval;
  int yynerrs;
#ifdef YYLSP_NEEDED
  YYLTYPE yylloc;
#endif
#endif

  YYSTYPE yyval;		/*  the variable used to return		*/
				/*  semantic values from the action	*/
				/*  routines				*/

  int yylen;

#if YYDEBUG != 0
  if (yydebug)
    fprintf(stderr, "Starting parse\n");
#endif

  yystate = 0;
  yyerrstatus = 0;
  yynerrs = 0;
  yychar = YYEMPTY;		/* Cause a token to be read.  */

  /* Initialize stack pointers.
     Waste one element of value and location stack
     so that they stay on the same level as the state stack.
     The wasted elements are never initialized.  */

  yyssp = yyss - 1;
  yyvsp = yyvs;
#ifdef YYLSP_NEEDED
  yylsp = yyls;
#endif

/* Push a new state, which is found in  yystate  .  */
/* In all cases, when you get here, the value and location stacks
   have just been pushed. so pushing a state here evens the stacks.  */
yynewstate:

  *++yyssp = yystate;

  if (yyssp >= yyss + yystacksize - 1)
    {
      /* Give user a chance to reallocate the stack */
      /* Use copies of these so that the &'s don't force the real ones into memory. */
      YYSTYPE *yyvs1 = yyvs;
      short *yyss1 = yyss;
#ifdef YYLSP_NEEDED
      YYLTYPE *yyls1 = yyls;
#endif

      /* Get the current used size of the three stacks, in elements.  */
      int size = yyssp - yyss + 1;

#ifdef yyoverflow
      /* Each stack pointer address is followed by the size of
	 the data in use in that stack, in bytes.  */
#ifdef YYLSP_NEEDED
      /* This used to be a conditional around just the two extra args,
	 but that might be undefined if yyoverflow is a macro.  */
      yyoverflow("parser stack overflow",
		 &yyss1, size * sizeof (*yyssp),
		 &yyvs1, size * sizeof (*yyvsp),
		 &yyls1, size * sizeof (*yylsp),
		 &yystacksize);
#else
      yyoverflow("parser stack overflow",
		 &yyss1, size * sizeof (*yyssp),
		 &yyvs1, size * sizeof (*yyvsp),
		 &yystacksize);
#endif

      yyss = yyss1; yyvs = yyvs1;
#ifdef YYLSP_NEEDED
      yyls = yyls1;
#endif
#else /* no yyoverflow */
      /* Extend the stack our own way.  */
      if (yystacksize >= YYMAXDEPTH)
	{
	  yyerror("parser stack overflow");
	  return 2;
	}
      yystacksize *= 2;
      if (yystacksize > YYMAXDEPTH)
	yystacksize = YYMAXDEPTH;
      yyss = (short *) alloca (yystacksize * sizeof (*yyssp));
      __yy_memcpy ((char *)yyss, (char *)yyss1, size * sizeof (*yyssp));
      yyvs = (YYSTYPE *) alloca (yystacksize * sizeof (*yyvsp));
      __yy_memcpy ((char *)yyvs, (char *)yyvs1, size * sizeof (*yyvsp));
#ifdef YYLSP_NEEDED
      yyls = (YYLTYPE *) alloca (yystacksize * sizeof (*yylsp));
      __yy_memcpy ((char *)yyls, (char *)yyls1, size * sizeof (*yylsp));
#endif
#endif /* no yyoverflow */

      yyssp = yyss + size - 1;
      yyvsp = yyvs + size - 1;
#ifdef YYLSP_NEEDED
      yylsp = yyls + size - 1;
#endif

#if YYDEBUG != 0
      if (yydebug)
	fprintf(stderr, "Stack size increased to %d\n", yystacksize);
#endif

      if (yyssp >= yyss + yystacksize - 1)
	YYABORT;
    }

#if YYDEBUG != 0
  if (yydebug)
    fprintf(stderr, "Entering state %d\n", yystate);
#endif

  goto yybackup;
 yybackup:

/* Do appropriate processing given the current state.  */
/* Read a lookahead token if we need one and don't already have one.  */
/* yyresume: */

  /* First try to decide what to do without reference to lookahead token.  */

  yyn = yypact[yystate];
  if (yyn == YYFLAG)
    goto yydefault;

  /* Not known => get a lookahead token if don't already have one.  */

  /* yychar is either YYEMPTY or YYEOF
     or a valid token in external form.  */

  if (yychar == YYEMPTY)
    {
#if YYDEBUG != 0
      if (yydebug)
	fprintf(stderr, "Reading a token: ");
#endif
      yychar = YYLEX;
    }

  /* Convert token to internal form (in yychar1) for indexing tables with */

  if (yychar <= 0)		/* This means end of input. */
    {
      yychar1 = 0;
      yychar = YYEOF;		/* Don't call YYLEX any more */

#if YYDEBUG != 0
      if (yydebug)
	fprintf(stderr, "Now at end of input.\n");
#endif
    }
  else
    {
      yychar1 = YYTRANSLATE(yychar);

#if YYDEBUG != 0
      if (yydebug)
	{
	  fprintf (stderr, "Next token is %d (%s", yychar, yytname[yychar1]);
	  /* Give the individual parser a way to print the precise meaning
	     of a token, for further debugging info.  */
#ifdef YYPRINT
	  YYPRINT (stderr, yychar, yylval);
#endif
	  fprintf (stderr, ")\n");
	}
#endif
    }

  yyn += yychar1;
  if (yyn < 0 || yyn > YYLAST || yycheck[yyn] != yychar1)
    goto yydefault;

  yyn = yytable[yyn];

  /* yyn is what to do for this token type in this state.
     Negative => reduce, -yyn is rule number.
     Positive => shift, yyn is new state.
       New state is final state => don't bother to shift,
       just return success.
     0, or most negative number => error.  */

  if (yyn < 0)
    {
      if (yyn == YYFLAG)
	goto yyerrlab;
      yyn = -yyn;
      goto yyreduce;
    }
  else if (yyn == 0)
    goto yyerrlab;

  if (yyn == YYFINAL)
    YYACCEPT;

  /* Shift the lookahead token.  */

#if YYDEBUG != 0
  if (yydebug)
    fprintf(stderr, "Shifting token %d (%s), ", yychar, yytname[yychar1]);
#endif

  /* Discard the token being shifted unless it is eof.  */
  if (yychar != YYEOF)
    yychar = YYEMPTY;

  *++yyvsp = yylval;
#ifdef YYLSP_NEEDED
  *++yylsp = yylloc;
#endif

  /* count tokens shifted since error; after three, turn off error status.  */
  if (yyerrstatus) yyerrstatus--;

  yystate = yyn;
  goto yynewstate;

/* Do the default action for the current state.  */
yydefault:

  yyn = yydefact[yystate];
  if (yyn == 0)
    goto yyerrlab;

/* Do a reduction.  yyn is the number of a rule to reduce with.  */
yyreduce:
  yylen = yyr2[yyn];
  if (yylen > 0)
    yyval = yyvsp[1-yylen]; /* implement default value of the action */

#if YYDEBUG != 0
  if (yydebug)
    {
      int i;

      fprintf (stderr, "Reducing via rule %d (line %d), ",
	       yyn, yyrline[yyn]);

      /* Print the symbols being reduced, and their result.  */
      for (i = yyprhs[yyn]; yyrhs[i] > 0; i++)
	fprintf (stderr, "%s ", yytname[yyrhs[i]]);
      fprintf (stderr, " -> %s\n", yytname[yyr1[yyn]]);
    }
#endif


  switch (yyn) {

case 1:
#line 144 "Parsers/rtfGrammer.y"
{ GSRTFstart(ctxt); ;
    break;}
case 2:
#line 144 "Parsers/rtfGrammer.y"
{ GSRTFstop(ctxt); ;
    break;}
case 4:
#line 147 "Parsers/rtfGrammer.y"
{ yyval.number = 1; ;
    break;}
case 5:
#line 148 "Parsers/rtfGrammer.y"
{ yyval.number = 2; ;
    break;}
case 6:
#line 149 "Parsers/rtfGrammer.y"
{ yyval.number = 3; ;
    break;}
case 7:
#line 150 "Parsers/rtfGrammer.y"
{ yyval.number = 4; ;
    break;}
case 12:
#line 157 "Parsers/rtfGrammer.y"
{ GSRTFmangleText(ctxt, yyvsp[0].text); free((void *)yyvsp[0].text); ;
    break;}
case 14:
#line 161 "Parsers/rtfGrammer.y"
{ GSRTFopenBlock(ctxt, NO); ;
    break;}
case 15:
#line 161 "Parsers/rtfGrammer.y"
{ GSRTFcloseBlock(ctxt, NO); ;
    break;}
case 16:
#line 162 "Parsers/rtfGrammer.y"
{ GSRTFopenBlock(ctxt, YES); ;
    break;}
case 17:
#line 162 "Parsers/rtfGrammer.y"
{ GSRTFcloseBlock(ctxt, YES); ;
    break;}
case 18:
#line 163 "Parsers/rtfGrammer.y"
{ GSRTFopenBlock(ctxt, YES); ;
    break;}
case 19:
#line 163 "Parsers/rtfGrammer.y"
{ GSRTFcloseBlock(ctxt, YES); ;
    break;}
case 20:
#line 164 "Parsers/rtfGrammer.y"
{ GSRTFopenBlock(ctxt, YES); ;
    break;}
case 21:
#line 164 "Parsers/rtfGrammer.y"
{ GSRTFcloseBlock(ctxt, YES); ;
    break;}
case 22:
#line 165 "Parsers/rtfGrammer.y"
{ GSRTFopenBlock(ctxt, YES); ;
    break;}
case 23:
#line 165 "Parsers/rtfGrammer.y"
{ GSRTFcloseBlock(ctxt, YES); ;
    break;}
case 24:
#line 166 "Parsers/rtfGrammer.y"
{ GSRTFopenBlock(ctxt, YES); ;
    break;}
case 25:
#line 166 "Parsers/rtfGrammer.y"
{ GSRTFcloseBlock(ctxt, YES); ;
    break;}
case 26:
#line 167 "Parsers/rtfGrammer.y"
{ GSRTFopenBlock(ctxt, YES); ;
    break;}
case 27:
#line 167 "Parsers/rtfGrammer.y"
{ GSRTFcloseBlock(ctxt, YES); ;
    break;}
case 28:
#line 168 "Parsers/rtfGrammer.y"
{ GSRTFopenBlock(ctxt, YES); ;
    break;}
case 29:
#line 168 "Parsers/rtfGrammer.y"
{ GSRTFcloseBlock(ctxt, YES); ;
    break;}
case 31:
#line 177 "Parsers/rtfGrammer.y"
{ int font;
		    
						  if (yyvsp[0].cmd.isEmpty)
						      font = 0;
						  else
						      font = yyvsp[0].cmd.parameter;
						  GSRTFfontNumber(ctxt, font); ;
    break;}
case 32:
#line 184 "Parsers/rtfGrammer.y"
{ int size;

						  if (yyvsp[0].cmd.isEmpty)
						      size = 24;
						  else
						      size = yyvsp[0].cmd.parameter;
						  GSRTFfontSize(ctxt, size); ;
    break;}
case 33:
#line 191 "Parsers/rtfGrammer.y"
{ int width; 
		
		                                  if (yyvsp[0].cmd.isEmpty)
						      width = 12240;
						  else
						      width = yyvsp[0].cmd.parameter;
						  GSRTFpaperWidth(ctxt, width);;
    break;}
case 34:
#line 198 "Parsers/rtfGrammer.y"
{ int height; 
		
		                                  if (yyvsp[0].cmd.isEmpty)
						      height = 15840;
						  else
						      height = yyvsp[0].cmd.parameter;
						  GSRTFpaperHeight(ctxt, height);;
    break;}
case 35:
#line 205 "Parsers/rtfGrammer.y"
{ int margin; 
		
		                                  if (yyvsp[0].cmd.isEmpty)
						      margin = 1800;
						  else
						      margin = yyvsp[0].cmd.parameter;
						  GSRTFmarginLeft(ctxt, margin);;
    break;}
case 36:
#line 212 "Parsers/rtfGrammer.y"
{ int margin; 
		
		                                  if (yyvsp[0].cmd.isEmpty)
						      margin = 1800;
						  else
						      margin = yyvsp[0].cmd.parameter;
						  GSRTFmarginRight(ctxt, margin); ;
    break;}
case 37:
#line 219 "Parsers/rtfGrammer.y"
{ int margin; 
		
		                                  if (yyvsp[0].cmd.isEmpty)
						      margin = 1440;
						  else
						      margin = yyvsp[0].cmd.parameter;
						  GSRTFmarginTop(ctxt, margin); ;
    break;}
case 38:
#line 226 "Parsers/rtfGrammer.y"
{ int margin; 
		
		                                  if (yyvsp[0].cmd.isEmpty)
						      margin = 1440;
						  else
						      margin = yyvsp[0].cmd.parameter;
						  GSRTFmarginButtom(ctxt, margin); ;
    break;}
case 39:
#line 233 "Parsers/rtfGrammer.y"
{ int indent; 
		
		                                  if (yyvsp[0].cmd.isEmpty)
						      indent = 0;
						  else
						      indent = yyvsp[0].cmd.parameter;
						  GSRTFfirstLineIndent(ctxt, indent); ;
    break;}
case 40:
#line 240 "Parsers/rtfGrammer.y"
{ int indent; 
		
		                                  if (yyvsp[0].cmd.isEmpty)
						      indent = 0;
						  else
						      indent = yyvsp[0].cmd.parameter;
						  GSRTFleftIndent(ctxt, indent);;
    break;}
case 41:
#line 247 "Parsers/rtfGrammer.y"
{ int indent; 
		
		                                  if (yyvsp[0].cmd.isEmpty)
						      indent = 0;
						  else
						      indent = yyvsp[0].cmd.parameter;
						  GSRTFrightIndent(ctxt, indent);;
    break;}
case 42:
#line 254 "Parsers/rtfGrammer.y"
{ int location; 
		
		                                  if (yyvsp[0].cmd.isEmpty)
						      location = 0;
						  else
						      location = yyvsp[0].cmd.parameter;
						  GSRTFtabstop(ctxt, location);;
    break;}
case 43:
#line 261 "Parsers/rtfGrammer.y"
{ GSRTFalignCenter(ctxt); ;
    break;}
case 44:
#line 262 "Parsers/rtfGrammer.y"
{ GSRTFalignLeft(ctxt); ;
    break;}
case 45:
#line 263 "Parsers/rtfGrammer.y"
{ GSRTFalignRight(ctxt); ;
    break;}
case 46:
#line 264 "Parsers/rtfGrammer.y"
{ GSRTFdefaultParagraph(ctxt); ;
    break;}
case 47:
#line 265 "Parsers/rtfGrammer.y"
{ GSRTFstyle(ctxt, yyvsp[0].cmd.parameter); ;
    break;}
case 48:
#line 266 "Parsers/rtfGrammer.y"
{ int color; 
		
		                                  if (yyvsp[0].cmd.isEmpty)
						      color = 0;
						  else
						      color = yyvsp[0].cmd.parameter;
						  GSRTFcolorbg(ctxt, color); ;
    break;}
case 49:
#line 273 "Parsers/rtfGrammer.y"
{ int color; 
		
		                                  if (yyvsp[0].cmd.isEmpty)
						      color = 0;
						  else
						      color = yyvsp[0].cmd.parameter;
						  GSRTFcolorfg(ctxt, color); ;
    break;}
case 50:
#line 280 "Parsers/rtfGrammer.y"
{ int script;
		
		                                  if (yyvsp[0].cmd.isEmpty)
						      script = 6;
						  else
						      script = yyvsp[0].cmd.parameter;
						  GSRTFsubscript(ctxt, script); ;
    break;}
case 51:
#line 287 "Parsers/rtfGrammer.y"
{ int script;
		
		                                  if (yyvsp[0].cmd.isEmpty)
						      script = 6;
						  else
						      script = yyvsp[0].cmd.parameter;
						  GSRTFsuperscript(ctxt, script); ;
    break;}
case 52:
#line 294 "Parsers/rtfGrammer.y"
{ BOOL on;

		                                  if (yyvsp[0].cmd.isEmpty || yyvsp[0].cmd.parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFbold(ctxt, on); ;
    break;}
case 53:
#line 301 "Parsers/rtfGrammer.y"
{ BOOL on;

		                                  if (yyvsp[0].cmd.isEmpty || yyvsp[0].cmd.parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFitalic(ctxt, on); ;
    break;}
case 54:
#line 308 "Parsers/rtfGrammer.y"
{ BOOL on;

		                                  if (yyvsp[0].cmd.isEmpty || yyvsp[0].cmd.parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFunderline(ctxt, on); ;
    break;}
case 55:
#line 315 "Parsers/rtfGrammer.y"
{ GSRTFunderline(ctxt, NO); ;
    break;}
case 56:
#line 316 "Parsers/rtfGrammer.y"
{ GSRTFgenericRTFcommand(ctxt, yyvsp[0].cmd); ;
    break;}
case 61:
#line 334 "Parsers/rtfGrammer.y"
{ GSRTFregisterFont(ctxt, yyvsp[0].text, yyvsp[-2].number, yyvsp[-3].cmd.parameter);
                                                          free((void *)yyvsp[0].text); ;
    break;}
case 67:
#line 347 "Parsers/rtfGrammer.y"
{ yyval.number = RTFfamilyNil - RTFfamilyNil; ;
    break;}
case 68:
#line 348 "Parsers/rtfGrammer.y"
{ yyval.number = RTFfamilyRoman - RTFfamilyNil; ;
    break;}
case 69:
#line 349 "Parsers/rtfGrammer.y"
{ yyval.number = RTFfamilySwiss - RTFfamilyNil; ;
    break;}
case 70:
#line 350 "Parsers/rtfGrammer.y"
{ yyval.number = RTFfamilyModern - RTFfamilyNil; ;
    break;}
case 71:
#line 351 "Parsers/rtfGrammer.y"
{ yyval.number = RTFfamilyScript - RTFfamilyNil; ;
    break;}
case 72:
#line 352 "Parsers/rtfGrammer.y"
{ yyval.number = RTFfamilyDecor - RTFfamilyNil; ;
    break;}
case 73:
#line 353 "Parsers/rtfGrammer.y"
{ yyval.number = RTFfamilyTech - RTFfamilyNil; ;
    break;}
case 77:
#line 370 "Parsers/rtfGrammer.y"
{ 
		       GSRTFaddColor(ctxt, yyvsp[-3].cmd.parameter, yyvsp[-2].cmd.parameter, yyvsp[-1].cmd.parameter);
		       free((void *)yyvsp[0].text);
		     ;
    break;}
case 78:
#line 375 "Parsers/rtfGrammer.y"
{ 
		       GSRTFaddDefaultColor(ctxt);
		       free((void *)yyvsp[0].text);
		     ;
    break;}
case 79:
#line 384 "Parsers/rtfGrammer.y"
{ yylsp[0].first_line; ;
    break;}
}
   /* the action file gets copied in in place of this dollarsign */
#line 498 "/usr/local/share/bison.simple"

  yyvsp -= yylen;
  yyssp -= yylen;
#ifdef YYLSP_NEEDED
  yylsp -= yylen;
#endif

#if YYDEBUG != 0
  if (yydebug)
    {
      short *ssp1 = yyss - 1;
      fprintf (stderr, "state stack now");
      while (ssp1 != yyssp)
	fprintf (stderr, " %d", *++ssp1);
      fprintf (stderr, "\n");
    }
#endif

  *++yyvsp = yyval;

#ifdef YYLSP_NEEDED
  yylsp++;
  if (yylen == 0)
    {
      yylsp->first_line = yylloc.first_line;
      yylsp->first_column = yylloc.first_column;
      yylsp->last_line = (yylsp-1)->last_line;
      yylsp->last_column = (yylsp-1)->last_column;
      yylsp->text = 0;
    }
  else
    {
      yylsp->last_line = (yylsp+yylen-1)->last_line;
      yylsp->last_column = (yylsp+yylen-1)->last_column;
    }
#endif

  /* Now "shift" the result of the reduction.
     Determine what state that goes to,
     based on the state we popped back to
     and the rule number reduced by.  */

  yyn = yyr1[yyn];

  yystate = yypgoto[yyn - YYNTBASE] + *yyssp;
  if (yystate >= 0 && yystate <= YYLAST && yycheck[yystate] == *yyssp)
    yystate = yytable[yystate];
  else
    yystate = yydefgoto[yyn - YYNTBASE];

  goto yynewstate;

yyerrlab:   /* here on detecting error */

  if (! yyerrstatus)
    /* If not already recovering from an error, report this error.  */
    {
      ++yynerrs;

#ifdef YYERROR_VERBOSE
      yyn = yypact[yystate];

      if (yyn > YYFLAG && yyn < YYLAST)
	{
	  int size = 0;
	  char *msg;
	  int x, count;

	  count = 0;
	  /* Start X at -yyn if nec to avoid negative indexes in yycheck.  */
	  for (x = (yyn < 0 ? -yyn : 0);
	       x < (sizeof(yytname) / sizeof(char *)); x++)
	    if (yycheck[x + yyn] == x)
	      size += strlen(yytname[x]) + 15, count++;
	  msg = (char *) malloc(size + 15);
	  if (msg != 0)
	    {
	      strcpy(msg, "parse error");

	      if (count < 5)
		{
		  count = 0;
		  for (x = (yyn < 0 ? -yyn : 0);
		       x < (sizeof(yytname) / sizeof(char *)); x++)
		    if (yycheck[x + yyn] == x)
		      {
			strcat(msg, count == 0 ? ", expecting `" : " or `");
			strcat(msg, yytname[x]);
			strcat(msg, "'");
			count++;
		      }
		}
	      yyerror(msg);
	      free(msg);
	    }
	  else
	    yyerror ("parse error; also virtual memory exceeded");
	}
      else
#endif /* YYERROR_VERBOSE */
	yyerror("parse error");
    }

  goto yyerrlab1;
yyerrlab1:   /* here on error raised explicitly by an action */

  if (yyerrstatus == 3)
    {
      /* if just tried and failed to reuse lookahead token after an error, discard it.  */

      /* return failure if at end of input */
      if (yychar == YYEOF)
	YYABORT;

#if YYDEBUG != 0
      if (yydebug)
	fprintf(stderr, "Discarding token %d (%s).\n", yychar, yytname[yychar1]);
#endif

      yychar = YYEMPTY;
    }

  /* Else will try to reuse lookahead token
     after shifting the error token.  */

  yyerrstatus = 3;		/* Each real token shifted decrements this */

  goto yyerrhandle;

yyerrdefault:  /* current state does not do anything special for the error token. */

#if 0
  /* This is wrong; only states that explicitly want error tokens
     should shift them.  */
  yyn = yydefact[yystate];  /* If its default is to accept any token, ok.  Otherwise pop it.*/
  if (yyn) goto yydefault;
#endif

yyerrpop:   /* pop the current state because it cannot handle the error token */

  if (yyssp == yyss) YYABORT;
  yyvsp--;
  yystate = *--yyssp;
#ifdef YYLSP_NEEDED
  yylsp--;
#endif

#if YYDEBUG != 0
  if (yydebug)
    {
      short *ssp1 = yyss - 1;
      fprintf (stderr, "Error: state stack now");
      while (ssp1 != yyssp)
	fprintf (stderr, " %d", *++ssp1);
      fprintf (stderr, "\n");
    }
#endif

yyerrhandle:

  yyn = yypact[yystate];
  if (yyn == YYFLAG)
    goto yyerrdefault;

  yyn += YYTERROR;
  if (yyn < 0 || yyn > YYLAST || yycheck[yyn] != YYTERROR)
    goto yyerrdefault;

  yyn = yytable[yyn];
  if (yyn < 0)
    {
      if (yyn == YYFLAG)
	goto yyerrpop;
      yyn = -yyn;
      goto yyreduce;
    }
  else if (yyn == 0)
    goto yyerrpop;

  if (yyn == YYFINAL)
    YYACCEPT;

#if YYDEBUG != 0
  if (yydebug)
    fprintf(stderr, "Shifting error token, ");
#endif

  *++yyvsp = yylval;
#ifdef YYLSP_NEEDED
  *++yylsp = yylloc;
#endif

  yystate = yyn;
  goto yynewstate;
}
#line 387 "Parsers/rtfGrammer.y"


/*	some C code here	*/

