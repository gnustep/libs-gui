/* A Bison parser, made from rtfGrammer.y
   by GNU bison 1.35.  */

#define YYBISON 1  /* Identify Bison output.  */

#define yyparse GSRTFparse
#define yylex GSRTFlex
#define yyerror GSRTFerror
#define yylval GSRTFlval
#define yychar GSRTFchar
#define yydebug GSRTFdebug
#define yynerrs GSRTFnerrs
# define	RTFtext	257
# define	RTFstart	258
# define	RTFansi	259
# define	RTFmac	260
# define	RTFpc	261
# define	RTFpca	262
# define	RTFignore	263
# define	RTFinfo	264
# define	RTFstylesheet	265
# define	RTFfootnote	266
# define	RTFheader	267
# define	RTFfooter	268
# define	RTFpict	269
# define	RTFplain	270
# define	RTFparagraph	271
# define	RTFdefaultParagraph	272
# define	RTFrow	273
# define	RTFcell	274
# define	RTFtabulator	275
# define	RTFemdash	276
# define	RTFendash	277
# define	RTFemspace	278
# define	RTFenspace	279
# define	RTFbullet	280
# define	RTFlquote	281
# define	RTFrquote	282
# define	RTFldblquote	283
# define	RTFrdblquote	284
# define	RTFred	285
# define	RTFgreen	286
# define	RTFblue	287
# define	RTFcolorbg	288
# define	RTFcolorfg	289
# define	RTFcolortable	290
# define	RTFfont	291
# define	RTFfontSize	292
# define	RTFpaperWidth	293
# define	RTFpaperHeight	294
# define	RTFmarginLeft	295
# define	RTFmarginRight	296
# define	RTFmarginTop	297
# define	RTFmarginButtom	298
# define	RTFfirstLineIndent	299
# define	RTFleftIndent	300
# define	RTFrightIndent	301
# define	RTFalignCenter	302
# define	RTFalignJustified	303
# define	RTFalignLeft	304
# define	RTFalignRight	305
# define	RTFlineSpace	306
# define	RTFspaceAbove	307
# define	RTFstyle	308
# define	RTFbold	309
# define	RTFitalic	310
# define	RTFunderline	311
# define	RTFunderlineStop	312
# define	RTFsubscript	313
# define	RTFsuperscript	314
# define	RTFtabstop	315
# define	RTFfcharset	316
# define	RTFfprq	317
# define	RTFcpg	318
# define	RTFOtherStatement	319
# define	RTFfontListStart	320
# define	RTFfamilyNil	321
# define	RTFfamilyRoman	322
# define	RTFfamilySwiss	323
# define	RTFfamilyModern	324
# define	RTFfamilyScript	325
# define	RTFfamilyDecor	326
# define	RTFfamilyTech	327

#line 35 "rtfGrammer.y"


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
#include "rtfScanner.h"

/*	this context is passed to the interface functions	*/
typedef void	*GSRTFctxt;
// Two parameters are not supported by some bison versions. The declaration of 
// yyparse in the .c file must be corrected to be able to compile it.
#define YYPARSE_PARAM	ctxt, void *lctxt
#define YYLEX_PARAM		lctxt
#define YYLSP_NEEDED 0
#define CTXT            ctxt

#define	YYERROR_VERBOSE
#define YYDEBUG 0

#include "RTFConsumerFunctions.h"
/*int GSRTFlex (YYSTYPE *lvalp, RTFscannerCtxt *lctxt); */
int GSRTFlex(void *lvalp, void *lctxt);


#line 77 "rtfGrammer.y"
#ifndef YYSTYPE
typedef union {
	int		number;
	const char	*text;
	RTFcmd		cmd;
} yystype;
# define YYSTYPE yystype
# define YYSTYPE_IS_TRIVIAL 1
#endif
#ifndef YYDEBUG
# define YYDEBUG 0
#endif



#define	YYFINAL		118
#define	YYFLAG		-32768
#define	YYNTBASE	76

/* YYTRANSLATE(YYLEX) -- Bison token number corresponding to YYLEX. */
#define YYTRANSLATE(x) ((unsigned)(x) <= 327 ? yytranslate[x] : 99)

/* YYTRANSLATE[YYLEX] -- Bison token number corresponding to YYLEX. */
static const char yytranslate[] =
{
       0,     2,     2,     2,     2,     2,     2,     2,     2,     2,
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
       2,     2,     2,    74,     2,    75,     2,     2,     2,     2,
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
       2,     2,     2,     2,     2,     2,     1,     3,     4,     5,
       6,     7,     8,     9,    10,    11,    12,    13,    14,    15,
      16,    17,    18,    19,    20,    21,    22,    23,    24,    25,
      26,    27,    28,    29,    30,    31,    32,    33,    34,    35,
      36,    37,    38,    39,    40,    41,    42,    43,    44,    45,
      46,    47,    48,    49,    50,    51,    52,    53,    54,    55,
      56,    57,    58,    59,    60,    61,    62,    63,    64,    65,
      66,    67,    68,    69,    70,    71,    72,    73
};

#if YYDEBUG
static const short yyprhs[] =
{
       0,     0,     1,     2,    10,    12,    14,    16,    18,    19,
      22,    25,    28,    31,    34,    35,    40,    41,    47,    48,
      54,    55,    61,    62,    68,    69,    75,    76,    82,    83,
      89,    91,    93,    95,    97,    99,   101,   103,   105,   107,
     109,   111,   113,   115,   117,   119,   121,   123,   125,   127,
     129,   131,   133,   135,   137,   139,   141,   143,   145,   147,
     149,   151,   153,   158,   159,   162,   167,   174,   179,   180,
     183,   186,   189,   192,   194,   196,   198,   200,   202,   204,
     206,   211,   212,   215,   220
};
static const short yyrhs[] =
{
      -1,     0,    74,    77,     4,    79,    80,    78,    75,     0,
       5,     0,     6,     0,     7,     0,     8,     0,     0,    80,
      91,     0,    80,    96,     0,    80,    90,     0,    80,     3,
       0,    80,    81,     0,     0,    74,    82,    80,    75,     0,
       0,    74,    83,     9,    80,    75,     0,     0,    74,    84,
      10,    80,    75,     0,     0,    74,    85,    11,    80,    75,
       0,     0,    74,    86,    12,    80,    75,     0,     0,    74,
      87,    13,    80,    75,     0,     0,    74,    88,    14,    80,
      75,     0,     0,    74,    89,    15,    80,    75,     0,    37,
       0,    38,     0,    39,     0,    40,     0,    41,     0,    42,
       0,    43,     0,    44,     0,    45,     0,    46,     0,    47,
       0,    61,     0,    48,     0,    49,     0,    50,     0,    51,
       0,    53,     0,    52,     0,    18,     0,    54,     0,    34,
       0,    35,     0,    59,     0,    60,     0,    55,     0,    56,
       0,    57,     0,    58,     0,    16,     0,    17,     0,    19,
       0,    65,     0,    74,    66,    92,    75,     0,     0,    92,
      93,     0,    92,    74,    93,    75,     0,    92,    74,    93,
      81,     3,    75,     0,    37,    95,    94,     3,     0,     0,
      94,    62,     0,    94,    63,     0,    94,    64,     0,    94,
      81,     0,    67,     0,    68,     0,    69,     0,    70,     0,
      71,     0,    72,     0,    73,     0,    74,    36,    97,    75,
       0,     0,    97,    98,     0,    31,    32,    33,     3,     0,
       3,     0
};

#endif

#if YYDEBUG
/* YYRLINE[YYN] -- source line where rule number YYN was defined. */
static const short yyrline[] =
{
       0,   166,   166,   166,   169,   170,   171,   172,   175,   176,
     177,   178,   179,   180,   183,   183,   184,   184,   185,   185,
     186,   186,   187,   187,   188,   188,   189,   189,   190,   190,
     198,   205,   212,   219,   226,   233,   240,   247,   254,   261,
     268,   275,   282,   283,   284,   285,   286,   293,   294,   295,
     296,   303,   310,   317,   324,   331,   338,   345,   346,   347,
     348,   349,   356,   359,   360,   361,   362,   368,   372,   373,
     374,   375,   376,   380,   382,   383,   384,   385,   386,   387,
     395,   398,   399,   403,   408
};
#endif


#if (YYDEBUG) || defined YYERROR_VERBOSE

/* YYTNAME[TOKEN_NUM] -- String name of the token TOKEN_NUM. */
static const char *const yytname[] =
{
  "$", "error", "$undefined.", "RTFtext", "RTFstart", "RTFansi", "RTFmac", 
  "RTFpc", "RTFpca", "RTFignore", "RTFinfo", "RTFstylesheet", 
  "RTFfootnote", "RTFheader", "RTFfooter", "RTFpict", "RTFplain", 
  "RTFparagraph", "RTFdefaultParagraph", "RTFrow", "RTFcell", 
  "RTFtabulator", "RTFemdash", "RTFendash", "RTFemspace", "RTFenspace", 
  "RTFbullet", "RTFlquote", "RTFrquote", "RTFldblquote", "RTFrdblquote", 
  "RTFred", "RTFgreen", "RTFblue", "RTFcolorbg", "RTFcolorfg", 
  "RTFcolortable", "RTFfont", "RTFfontSize", "RTFpaperWidth", 
  "RTFpaperHeight", "RTFmarginLeft", "RTFmarginRight", "RTFmarginTop", 
  "RTFmarginButtom", "RTFfirstLineIndent", "RTFleftIndent", 
  "RTFrightIndent", "RTFalignCenter", "RTFalignJustified", "RTFalignLeft", 
  "RTFalignRight", "RTFlineSpace", "RTFspaceAbove", "RTFstyle", "RTFbold", 
  "RTFitalic", "RTFunderline", "RTFunderlineStop", "RTFsubscript", 
  "RTFsuperscript", "RTFtabstop", "RTFfcharset", "RTFfprq", "RTFcpg", 
  "RTFOtherStatement", "RTFfontListStart", "RTFfamilyNil", 
  "RTFfamilyRoman", "RTFfamilySwiss", "RTFfamilyModern", 
  "RTFfamilyScript", "RTFfamilyDecor", "RTFfamilyTech", "'{'", "'}'", 
  "rtfFile", "@1", "@2", "rtfCharset", "rtfIngredients", "rtfBlock", "@3", 
  "@4", "@5", "@6", "@7", "@8", "@9", "@10", "rtfStatement", 
  "rtfFontList", "rtfFonts", "rtfFontStatement", "rtfFontAttrs", 
  "rtfFontFamily", "rtfColorDef", "rtfColors", "rtfColorStatement", 0
};
#endif

/* YYR1[YYN] -- Symbol number of symbol that rule YYN derives. */
static const short yyr1[] =
{
       0,    77,    78,    76,    79,    79,    79,    79,    80,    80,
      80,    80,    80,    80,    82,    81,    83,    81,    84,    81,
      85,    81,    86,    81,    87,    81,    88,    81,    89,    81,
      90,    90,    90,    90,    90,    90,    90,    90,    90,    90,
      90,    90,    90,    90,    90,    90,    90,    90,    90,    90,
      90,    90,    90,    90,    90,    90,    90,    90,    90,    90,
      90,    90,    91,    92,    92,    92,    92,    93,    94,    94,
      94,    94,    94,    95,    95,    95,    95,    95,    95,    95,
      96,    97,    97,    98,    98
};

/* YYR2[YYN] -- Number of symbols composing right hand side of rule YYN. */
static const short yyr2[] =
{
       0,     0,     0,     7,     1,     1,     1,     1,     0,     2,
       2,     2,     2,     2,     0,     4,     0,     5,     0,     5,
       0,     5,     0,     5,     0,     5,     0,     5,     0,     5,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     4,     0,     2,     4,     6,     4,     0,     2,
       2,     2,     2,     1,     1,     1,     1,     1,     1,     1,
       4,     0,     2,     4,     1
};

/* YYDEFACT[S] -- default rule to reduce with in state S when YYTABLE
   doesn't specify something else to do.  Zero means the default is an
   error. */
static const short yydefact[] =
{
       0,     1,     0,     0,     4,     5,     6,     7,     8,     2,
      12,    58,    59,    48,    60,    50,    51,    30,    31,    32,
      33,    34,    35,    36,    37,    38,    39,    40,    42,    43,
      44,    45,    47,    46,    49,    54,    55,    56,    57,    52,
      53,    41,    61,    14,     0,    13,    11,     9,    10,    81,
      63,     8,     0,     0,     0,     0,     0,     0,     0,     3,
       0,     0,     0,     8,     8,     8,     8,     8,     8,     8,
      84,     0,    80,    82,     0,     0,    62,    64,    15,     0,
       0,     0,     0,     0,     0,     0,     0,    73,    74,    75,
      76,    77,    78,    79,    68,     0,    17,    19,    21,    23,
      25,    27,    29,     0,     0,    14,    65,     0,    83,    67,
      69,    70,    71,    72,     0,    66,     0,     0,     0
};

static const short yydefgoto[] =
{
     116,     2,    44,     8,     9,    45,    51,    52,    53,    54,
      55,    56,    57,    58,    46,    47,    61,    77,   104,    94,
      48,    60,    73
};

static const short yypact[] =
{
     -70,-32768,     5,    22,-32768,-32768,-32768,-32768,-32768,   477,
  -32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,
  -32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,
  -32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,
  -32768,-32768,-32768,   474,   -67,-32768,-32768,-32768,-32768,-32768,
  -32768,-32768,     3,     1,     6,    13,    46,    47,    50,-32768,
       2,   -11,    -3,-32768,-32768,-32768,-32768,-32768,-32768,-32768,
  -32768,    37,-32768,-32768,    12,    33,-32768,-32768,-32768,    57,
     117,   177,   237,   297,   357,   417,    53,-32768,-32768,-32768,
  -32768,-32768,-32768,-32768,-32768,   -72,-32768,-32768,-32768,-32768,
  -32768,-32768,-32768,    84,     4,   114,-32768,    85,-32768,-32768,
  -32768,-32768,-32768,-32768,    14,-32768,    90,    93,-32768
};

static const short yypgoto[] =
{
  -32768,-32768,-32768,-32768,   -45,   -94,-32768,-32768,-32768,-32768,
  -32768,-32768,-32768,-32768,-32768,-32768,-32768,    44,-32768,-32768,
  -32768,-32768,-32768
};


#define	YYLAST		551


static const short yytable[] =
{
      10,   107,   105,   106,     1,    70,    62,   109,    59,     3,
     113,    64,    63,    11,    12,    13,    14,    65,    79,    80,
      81,    82,    83,    84,    85,    66,    74,     4,     5,     6,
       7,    15,    16,    71,    17,    18,    19,    20,    21,    22,
      23,    24,    25,    26,    27,    28,    29,    30,    31,    32,
      33,    34,    35,    36,    37,    38,    39,    40,    41,    67,
      10,    68,    42,    75,    76,    69,   110,   111,   112,    86,
      74,    43,    78,    11,    12,    13,    14,    72,   105,    87,
      88,    89,    90,    91,    92,    93,   103,   108,   114,   115,
     117,    15,    16,   118,    17,    18,    19,    20,    21,    22,
      23,    24,    25,    26,    27,    28,    29,    30,    31,    32,
      33,    34,    35,    36,    37,    38,    39,    40,    41,    95,
      10,     0,    42,   -16,   -18,   -20,   -22,   -24,   -26,   -28,
       0,    43,    96,    11,    12,    13,    14,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,    15,    16,     0,    17,    18,    19,    20,    21,    22,
      23,    24,    25,    26,    27,    28,    29,    30,    31,    32,
      33,    34,    35,    36,    37,    38,    39,    40,    41,     0,
      10,     0,    42,     0,     0,     0,     0,     0,     0,     0,
       0,    43,    97,    11,    12,    13,    14,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,    15,    16,     0,    17,    18,    19,    20,    21,    22,
      23,    24,    25,    26,    27,    28,    29,    30,    31,    32,
      33,    34,    35,    36,    37,    38,    39,    40,    41,     0,
      10,     0,    42,     0,     0,     0,     0,     0,     0,     0,
       0,    43,    98,    11,    12,    13,    14,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,    15,    16,     0,    17,    18,    19,    20,    21,    22,
      23,    24,    25,    26,    27,    28,    29,    30,    31,    32,
      33,    34,    35,    36,    37,    38,    39,    40,    41,     0,
      10,     0,    42,     0,     0,     0,     0,     0,     0,     0,
       0,    43,    99,    11,    12,    13,    14,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,    15,    16,     0,    17,    18,    19,    20,    21,    22,
      23,    24,    25,    26,    27,    28,    29,    30,    31,    32,
      33,    34,    35,    36,    37,    38,    39,    40,    41,     0,
      10,     0,    42,     0,     0,     0,     0,     0,     0,     0,
       0,    43,   100,    11,    12,    13,    14,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,    15,    16,     0,    17,    18,    19,    20,    21,    22,
      23,    24,    25,    26,    27,    28,    29,    30,    31,    32,
      33,    34,    35,    36,    37,    38,    39,    40,    41,     0,
      10,     0,    42,     0,     0,     0,     0,     0,     0,     0,
       0,    43,   101,    11,    12,    13,    14,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,    15,    16,     0,    17,    18,    19,    20,    21,    22,
      23,    24,    25,    26,    27,    28,    29,    30,    31,    32,
      33,    34,    35,    36,    37,    38,    39,    40,    41,     0,
      10,     0,    42,   -16,   -18,   -20,   -22,   -24,   -26,   -28,
       0,    43,   102,    11,    12,    13,    14,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
      49,    15,    16,     0,    17,    18,    19,    20,    21,    22,
      23,    24,    25,    26,    27,    28,    29,    30,    31,    32,
      33,    34,    35,    36,    37,    38,    39,    40,    41,     0,
      50,     0,    42,     0,     0,     0,     0,     0,     0,     0,
       0,    43
};

static const short yycheck[] =
{
       3,    95,    74,    75,    74,     3,    51,     3,    75,     4,
     104,    10,     9,    16,    17,    18,    19,    11,    63,    64,
      65,    66,    67,    68,    69,    12,    37,     5,     6,     7,
       8,    34,    35,    31,    37,    38,    39,    40,    41,    42,
      43,    44,    45,    46,    47,    48,    49,    50,    51,    52,
      53,    54,    55,    56,    57,    58,    59,    60,    61,    13,
       3,    14,    65,    74,    75,    15,    62,    63,    64,    32,
      37,    74,    75,    16,    17,    18,    19,    75,    74,    67,
      68,    69,    70,    71,    72,    73,    33,     3,     3,    75,
       0,    34,    35,     0,    37,    38,    39,    40,    41,    42,
      43,    44,    45,    46,    47,    48,    49,    50,    51,    52,
      53,    54,    55,    56,    57,    58,    59,    60,    61,    75,
       3,    -1,    65,     9,    10,    11,    12,    13,    14,    15,
      -1,    74,    75,    16,    17,    18,    19,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    34,    35,    -1,    37,    38,    39,    40,    41,    42,
      43,    44,    45,    46,    47,    48,    49,    50,    51,    52,
      53,    54,    55,    56,    57,    58,    59,    60,    61,    -1,
       3,    -1,    65,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    74,    75,    16,    17,    18,    19,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    34,    35,    -1,    37,    38,    39,    40,    41,    42,
      43,    44,    45,    46,    47,    48,    49,    50,    51,    52,
      53,    54,    55,    56,    57,    58,    59,    60,    61,    -1,
       3,    -1,    65,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    74,    75,    16,    17,    18,    19,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    34,    35,    -1,    37,    38,    39,    40,    41,    42,
      43,    44,    45,    46,    47,    48,    49,    50,    51,    52,
      53,    54,    55,    56,    57,    58,    59,    60,    61,    -1,
       3,    -1,    65,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    74,    75,    16,    17,    18,    19,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    34,    35,    -1,    37,    38,    39,    40,    41,    42,
      43,    44,    45,    46,    47,    48,    49,    50,    51,    52,
      53,    54,    55,    56,    57,    58,    59,    60,    61,    -1,
       3,    -1,    65,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    74,    75,    16,    17,    18,    19,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    34,    35,    -1,    37,    38,    39,    40,    41,    42,
      43,    44,    45,    46,    47,    48,    49,    50,    51,    52,
      53,    54,    55,    56,    57,    58,    59,    60,    61,    -1,
       3,    -1,    65,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    74,    75,    16,    17,    18,    19,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    34,    35,    -1,    37,    38,    39,    40,    41,    42,
      43,    44,    45,    46,    47,    48,    49,    50,    51,    52,
      53,    54,    55,    56,    57,    58,    59,    60,    61,    -1,
       3,    -1,    65,     9,    10,    11,    12,    13,    14,    15,
      -1,    74,    75,    16,    17,    18,    19,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      36,    34,    35,    -1,    37,    38,    39,    40,    41,    42,
      43,    44,    45,    46,    47,    48,    49,    50,    51,    52,
      53,    54,    55,    56,    57,    58,    59,    60,    61,    -1,
      66,    -1,    65,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    74
};
#define YYPURE 1

/* -*-C-*-  Note some compilers choke on comments on `#line' lines.  */
#line 3 "/usr/share/bison/bison.simple"

/* Skeleton output parser for bison,

   Copyright (C) 1984, 1989, 1990, 2000, 2001, 2002 Free Software
   Foundation, Inc.

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
   Foundation, Inc., 59 Temple Place - Suite 330,
   Boston, MA 02111-1307, USA.  */

/* As a special exception, when this file is copied by Bison into a
   Bison output file, you may use that output file without restriction.
   This special exception was added by the Free Software Foundation
   in version 1.24 of Bison.  */

/* This is the parser code that is written into each bison parser when
   the %semantic_parser declaration is not specified in the grammar.
   It was written by Richard Stallman by simplifying the hairy parser
   used when %semantic_parser is specified.  */

/* All symbols defined below should begin with yy or YY, to avoid
   infringing on user name space.  This should be done even for local
   variables, as they might otherwise be expanded by user macros.
   There are some unavoidable exceptions within include files to
   define necessary library symbols; they are noted "INFRINGES ON
   USER NAME SPACE" below.  */

#ifndef YYPARSE_RETURN_TYPE
#define YYPARSE_RETURN_TYPE int
#endif

#if ! defined (yyoverflow) || defined (YYERROR_VERBOSE)

/* The parser invokes alloca or malloc; define the necessary symbols.  */

# if YYSTACK_USE_ALLOCA
#  define YYSTACK_ALLOC alloca
# else
#  ifndef YYSTACK_USE_ALLOCA
#   if defined (alloca) || defined (_ALLOCA_H)
#    define YYSTACK_ALLOC alloca
#   else
#    ifdef __GNUC__
#     define YYSTACK_ALLOC __builtin_alloca
#    endif
#   endif
#  endif
# endif

# ifdef YYSTACK_ALLOC
   /* Pacify GCC's `empty if-body' warning. */
#  define YYSTACK_FREE(Ptr) do { /* empty */; } while (0)
# else
#  if defined (__STDC__) || defined (__cplusplus)
#   include <stdlib.h> /* INFRINGES ON USER NAME SPACE */
#   define YYSIZE_T size_t
#  endif
#  define YYSTACK_ALLOC malloc
#  define YYSTACK_FREE free
# endif
#endif /* ! defined (yyoverflow) || defined (YYERROR_VERBOSE) */


#if (! defined (yyoverflow) \
     && (! defined (__cplusplus) \
	 || ((YYLTYPE_IS_TRIVIAL || ! YYLSP_NEEDED) && YYSTYPE_IS_TRIVIAL)))

/* A type that is properly aligned for any stack member.  */
union yyalloc
{
  short yyss;
  YYSTYPE yyvs;
# if YYLSP_NEEDED
  YYLTYPE yyls;
# endif
};

/* The size of the maximum gap between one aligned stack and the next.  */
# define YYSTACK_GAP_MAX (sizeof (union yyalloc) - 1)

/* The size of an array large to enough to hold all stacks, each with
   N elements.  */
# if YYLSP_NEEDED
#  define YYSTACK_BYTES(N) \
     ((N) * (sizeof (short) + sizeof (YYSTYPE) + sizeof (YYLTYPE))	\
      + 2 * YYSTACK_GAP_MAX)
# else
#  define YYSTACK_BYTES(N) \
     ((N) * (sizeof (short) + sizeof (YYSTYPE))				\
      + YYSTACK_GAP_MAX)
# endif

/* Copy COUNT objects from FROM to TO.  The source and destination do
   not overlap.  */
# ifndef YYCOPY
#  if 1 < __GNUC__
#   define YYCOPY(To, From, Count) \
      __builtin_memcpy (To, From, (Count) * sizeof (*(From)))
#  else
#   define YYCOPY(To, From, Count)		\
      do					\
	{					\
	  register YYSIZE_T yyi;		\
	  for (yyi = 0; yyi < (Count); yyi++)	\
	    (To)[yyi] = (From)[yyi];		\
	}					\
      while (0)
#  endif
# endif

/* Relocate STACK from its old location to the new one.  The
   local variables YYSIZE and YYSTACKSIZE give the old and new number of
   elements in the stack, and YYPTR gives the new location of the
   stack.  Advance YYPTR to a properly aligned location for the next
   stack.  */
# define YYSTACK_RELOCATE(Stack)					\
    do									\
      {									\
	YYSIZE_T yynewbytes;						\
	YYCOPY (&yyptr->Stack, Stack, yysize);				\
	Stack = &yyptr->Stack;						\
	yynewbytes = yystacksize * sizeof (*Stack) + YYSTACK_GAP_MAX;	\
	yyptr += yynewbytes / sizeof (*yyptr);				\
      }									\
    while (0)

#endif


#if ! defined (YYSIZE_T) && defined (__SIZE_TYPE__)
# define YYSIZE_T __SIZE_TYPE__
#endif
#if ! defined (YYSIZE_T) && defined (size_t)
# define YYSIZE_T size_t
#endif
#if ! defined (YYSIZE_T)
# if defined (__STDC__) || defined (__cplusplus)
#  include <stddef.h> /* INFRINGES ON USER NAME SPACE */
#  define YYSIZE_T size_t
# endif
#endif
#if ! defined (YYSIZE_T)
# define YYSIZE_T unsigned int
#endif

#define yyerrok		(yyerrstatus = 0)
#define yyclearin	(yychar = YYEMPTY)
#define YYEMPTY		-2
#define YYEOF		0
#define YYACCEPT	goto yyacceptlab
#define YYABORT 	goto yyabortlab
#define YYERROR		goto yyerrlab1
/* Like YYERROR except do call yyerror.  This remains here temporarily
   to ease the transition to the new meaning of YYERROR, for GCC.
   Once GCC version 2 has supplanted version 1, this can go.  */
#define YYFAIL		goto yyerrlab
#define YYRECOVERING()  (!!yyerrstatus)
#define YYBACKUP(Token, Value)					\
do								\
  if (yychar == YYEMPTY && yylen == 1)				\
    {								\
      yychar = (Token);						\
      yylval = (Value);						\
      yychar1 = YYTRANSLATE (yychar);				\
      YYPOPSTACK;						\
      goto yybackup;						\
    }								\
  else								\
    { 								\
      yyerror ("syntax error: cannot back up");			\
      YYERROR;							\
    }								\
while (0)

#define YYTERROR	1
#define YYERRCODE	256


/* YYLLOC_DEFAULT -- Compute the default location (before the actions
   are run).

   When YYLLOC_DEFAULT is run, CURRENT is set the location of the
   first token.  By default, to implement support for ranges, extend
   its range to the last symbol.  */

#ifndef YYLLOC_DEFAULT
# define YYLLOC_DEFAULT(Current, Rhs, N)       	\
   Current.last_line   = Rhs[N].last_line;	\
   Current.last_column = Rhs[N].last_column;
#endif


/* YYLEX -- calling `yylex' with the right arguments.  */

#if YYPURE
# if YYLSP_NEEDED
#  ifdef YYLEX_PARAM
#   define YYLEX		yylex (&yylval, &yylloc, YYLEX_PARAM)
#  else
#   define YYLEX		yylex (&yylval, &yylloc)
#  endif
# else /* !YYLSP_NEEDED */
#  ifdef YYLEX_PARAM
#   define YYLEX		yylex (&yylval, YYLEX_PARAM)
#  else
#   define YYLEX		yylex (&yylval)
#  endif
# endif /* !YYLSP_NEEDED */
#else /* !YYPURE */
# define YYLEX			yylex ()
#endif /* !YYPURE */


/* Enable debugging if requested.  */
#if YYDEBUG

# ifndef YYFPRINTF
#  include <stdio.h> /* INFRINGES ON USER NAME SPACE */
#  define YYFPRINTF fprintf
# endif

# define YYDPRINTF(Args)			\
do {						\
  if (yydebug)					\
    YYFPRINTF Args;				\
} while (0)
/* Nonzero means print parse trace.  It is left uninitialized so that
   multiple parsers can coexist.  */
int yydebug;
#else /* !YYDEBUG */
# define YYDPRINTF(Args)
#endif /* !YYDEBUG */

/* YYINITDEPTH -- initial size of the parser's stacks.  */
#ifndef	YYINITDEPTH
# define YYINITDEPTH 200
#endif

/* YYMAXDEPTH -- maximum size the stacks can grow to (effective only
   if the built-in stack extension method is used).

   Do not make this value too large; the results are undefined if
   SIZE_MAX < YYSTACK_BYTES (YYMAXDEPTH)
   evaluated with infinite-precision integer arithmetic.  */

#if YYMAXDEPTH == 0
# undef YYMAXDEPTH
#endif

#ifndef YYMAXDEPTH
# define YYMAXDEPTH 10000
#endif

#ifdef YYERROR_VERBOSE

# ifndef yystrlen
#  if defined (__GLIBC__) && defined (_STRING_H)
#   define yystrlen strlen
#  else
/* Return the length of YYSTR.  */
static YYSIZE_T
#   if defined (__STDC__) || defined (__cplusplus)
yystrlen (const char *yystr)
#   else
yystrlen (yystr)
     const char *yystr;
#   endif
{
  register const char *yys = yystr;

  while (*yys++ != '\0')
    continue;

  return yys - yystr - 1;
}
#  endif
# endif

# ifndef yystpcpy
#  if defined (__GLIBC__) && defined (_STRING_H) && defined (_GNU_SOURCE)
#   define yystpcpy stpcpy
#  else
/* Copy YYSRC to YYDEST, returning the address of the terminating '\0' in
   YYDEST.  */
static char *
#   if defined (__STDC__) || defined (__cplusplus)
yystpcpy (char *yydest, const char *yysrc)
#   else
yystpcpy (yydest, yysrc)
     char *yydest;
     const char *yysrc;
#   endif
{
  register char *yyd = yydest;
  register const char *yys = yysrc;

  while ((*yyd++ = *yys++) != '\0')
    continue;

  return yyd - 1;
}
#  endif
# endif
#endif

#line 319 "/usr/share/bison/bison.simple"


/* The user can define YYPARSE_PARAM as the name of an argument to be passed
   into yyparse.  The argument should have type void *.
   It should actually point to an object.
   Grammar actions can access the variable by casting it
   to the proper pointer type.  */

#ifdef YYPARSE_PARAM
# if defined (__STDC__) || defined (__cplusplus)
#  define YYPARSE_PARAM_ARG void *YYPARSE_PARAM
#  define YYPARSE_PARAM_DECL
# else
#  define YYPARSE_PARAM_ARG YYPARSE_PARAM
#  define YYPARSE_PARAM_DECL void *YYPARSE_PARAM;
# endif
#else /* !YYPARSE_PARAM */
# define YYPARSE_PARAM_ARG
# define YYPARSE_PARAM_DECL
#endif /* !YYPARSE_PARAM */

/* Prevent warning if -Wstrict-prototypes.  */
#ifdef __GNUC__
# ifdef YYPARSE_PARAM
YYPARSE_RETURN_TYPE yyparse (void *YYPARSE_PARAM);
# else
YYPARSE_RETURN_TYPE yyparse (void);
# endif
#endif

/* YY_DECL_VARIABLES -- depending whether we use a pure parser,
   variables are global, or local to YYPARSE.  */

#define YY_DECL_NON_LSP_VARIABLES			\
/* The lookahead symbol.  */				\
int yychar;						\
							\
/* The semantic value of the lookahead symbol. */	\
YYSTYPE yylval;						\
							\
/* Number of parse errors so far.  */			\
int yynerrs;

#if YYLSP_NEEDED
# define YY_DECL_VARIABLES			\
YY_DECL_NON_LSP_VARIABLES			\
						\
/* Location data for the lookahead symbol.  */	\
YYLTYPE yylloc;
#else
# define YY_DECL_VARIABLES			\
YY_DECL_NON_LSP_VARIABLES
#endif


/* If nonreentrant, generate the variables here. */

#if !YYPURE
YY_DECL_VARIABLES
#endif  /* !YYPURE */

YYPARSE_RETURN_TYPE
yyparse (YYPARSE_PARAM_ARG)
     YYPARSE_PARAM_DECL
{
  /* If reentrant, generate the variables here. */
#if YYPURE
  YY_DECL_VARIABLES
#endif  /* !YYPURE */

  register int yystate;
  register int yyn;
  int yyresult;
  /* Number of tokens to shift before error messages enabled.  */
  int yyerrstatus;
  /* Lookahead token as an internal (translated) token number.  */
  int yychar1 = 0;

  /* Three stacks and their tools:
     `yyss': related to states,
     `yyvs': related to semantic values,
     `yyls': related to locations.

     Refer to the stacks thru separate pointers, to allow yyoverflow
     to reallocate them elsewhere.  */

  /* The state stack. */
  short	yyssa[YYINITDEPTH];
  short *yyss = yyssa;
  register short *yyssp;

  /* The semantic value stack.  */
  YYSTYPE yyvsa[YYINITDEPTH];
  YYSTYPE *yyvs = yyvsa;
  register YYSTYPE *yyvsp;

#if YYLSP_NEEDED
  /* The location stack.  */
  YYLTYPE yylsa[YYINITDEPTH];
  YYLTYPE *yyls = yylsa;
  YYLTYPE *yylsp;
#endif

#if YYLSP_NEEDED
# define YYPOPSTACK   (yyvsp--, yyssp--, yylsp--)
#else
# define YYPOPSTACK   (yyvsp--, yyssp--)
#endif

  YYSIZE_T yystacksize = YYINITDEPTH;


  /* The variables used to return semantic value and location from the
     action routines.  */
  YYSTYPE yyval;
#if YYLSP_NEEDED
  YYLTYPE yyloc;
#endif

  /* When reducing, the number of symbols on the RHS of the reduced
     rule. */
  int yylen;

  YYDPRINTF ((stderr, "Starting parse\n"));

  yystate = 0;
  yyerrstatus = 0;
  yynerrs = 0;
  yychar = YYEMPTY;		/* Cause a token to be read.  */

  /* Initialize stack pointers.
     Waste one element of value and location stack
     so that they stay on the same level as the state stack.
     The wasted elements are never initialized.  */

  yyssp = yyss;
  yyvsp = yyvs;
#if YYLSP_NEEDED
  yylsp = yyls;
#endif
  goto yysetstate;

/*------------------------------------------------------------.
| yynewstate -- Push a new state, which is found in yystate.  |
`------------------------------------------------------------*/
 yynewstate:
  /* In all cases, when you get here, the value and location stacks
     have just been pushed. so pushing a state here evens the stacks.
     */
  yyssp++;

 yysetstate:
  *yyssp = yystate;

  if (yyssp >= yyss + yystacksize - 1)
    {
      /* Get the current used size of the three stacks, in elements.  */
      YYSIZE_T yysize = yyssp - yyss + 1;

#ifdef yyoverflow
      {
	/* Give user a chance to reallocate the stack. Use copies of
	   these so that the &'s don't force the real ones into
	   memory.  */
	YYSTYPE *yyvs1 = yyvs;
	short *yyss1 = yyss;

	/* Each stack pointer address is followed by the size of the
	   data in use in that stack, in bytes.  */
# if YYLSP_NEEDED
	YYLTYPE *yyls1 = yyls;
	/* This used to be a conditional around just the two extra args,
	   but that might be undefined if yyoverflow is a macro.  */
	yyoverflow ("parser stack overflow",
		    &yyss1, yysize * sizeof (*yyssp),
		    &yyvs1, yysize * sizeof (*yyvsp),
		    &yyls1, yysize * sizeof (*yylsp),
		    &yystacksize);
	yyls = yyls1;
# else
	yyoverflow ("parser stack overflow",
		    &yyss1, yysize * sizeof (*yyssp),
		    &yyvs1, yysize * sizeof (*yyvsp),
		    &yystacksize);
# endif
	yyss = yyss1;
	yyvs = yyvs1;
      }
#else /* no yyoverflow */
# ifndef YYSTACK_RELOCATE
      goto yyoverflowlab;
# else
      /* Extend the stack our own way.  */
      if (yystacksize >= YYMAXDEPTH)
	goto yyoverflowlab;
      yystacksize *= 2;
      if (yystacksize > YYMAXDEPTH)
	yystacksize = YYMAXDEPTH;

      {
	short *yyss1 = yyss;
	union yyalloc *yyptr =
	  (union yyalloc *) YYSTACK_ALLOC (YYSTACK_BYTES (yystacksize));
	if (! yyptr)
	  goto yyoverflowlab;
	YYSTACK_RELOCATE (yyss);
	YYSTACK_RELOCATE (yyvs);
# if YYLSP_NEEDED
	YYSTACK_RELOCATE (yyls);
# endif
# undef YYSTACK_RELOCATE
	if (yyss1 != yyssa)
	  YYSTACK_FREE (yyss1);
      }
# endif
#endif /* no yyoverflow */

      yyssp = yyss + yysize - 1;
      yyvsp = yyvs + yysize - 1;
#if YYLSP_NEEDED
      yylsp = yyls + yysize - 1;
#endif

      YYDPRINTF ((stderr, "Stack size increased to %lu\n",
		  (unsigned long int) yystacksize));

      if (yyssp >= yyss + yystacksize - 1)
	YYABORT;
    }

  YYDPRINTF ((stderr, "Entering state %d\n", yystate));

  goto yybackup;


/*-----------.
| yybackup.  |
`-----------*/
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
      YYDPRINTF ((stderr, "Reading a token: "));
      yychar = YYLEX;
    }

  /* Convert token to internal form (in yychar1) for indexing tables with */

  if (yychar <= 0)		/* This means end of input. */
    {
      yychar1 = 0;
      yychar = YYEOF;		/* Don't call YYLEX any more */

      YYDPRINTF ((stderr, "Now at end of input.\n"));
    }
  else
    {
      yychar1 = YYTRANSLATE (yychar);

#if YYDEBUG
     /* We have to keep this `#if YYDEBUG', since we use variables
	which are defined only if `YYDEBUG' is set.  */
      if (yydebug)
	{
	  YYFPRINTF (stderr, "Next token is %d (%s",
		     yychar, yytname[yychar1]);
	  /* Give the individual parser a way to print the precise
	     meaning of a token, for further debugging info.  */
# ifdef YYPRINT
	  YYPRINT (stderr, yychar, yylval);
# endif
	  YYFPRINTF (stderr, ")\n");
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
  YYDPRINTF ((stderr, "Shifting token %d (%s), ",
	      yychar, yytname[yychar1]));

  /* Discard the token being shifted unless it is eof.  */
  if (yychar != YYEOF)
    yychar = YYEMPTY;

  *++yyvsp = yylval;
#if YYLSP_NEEDED
  *++yylsp = yylloc;
#endif

  /* Count tokens shifted since error; after three, turn off error
     status.  */
  if (yyerrstatus)
    yyerrstatus--;

  yystate = yyn;
  goto yynewstate;


/*-----------------------------------------------------------.
| yydefault -- do the default action for the current state.  |
`-----------------------------------------------------------*/
yydefault:
  yyn = yydefact[yystate];
  if (yyn == 0)
    goto yyerrlab;
  goto yyreduce;


/*-----------------------------.
| yyreduce -- Do a reduction.  |
`-----------------------------*/
yyreduce:
  /* yyn is the number of a rule to reduce with.  */
  yylen = yyr2[yyn];

  /* If YYLEN is nonzero, implement the default value of the action:
     `$$ = $1'.

     Otherwise, the following line sets YYVAL to the semantic value of
     the lookahead token.  This behavior is undocumented and Bison
     users should not rely upon it.  Assigning to YYVAL
     unconditionally makes the parser a bit smaller, and it avoids a
     GCC warning that YYVAL may be used uninitialized.  */
  yyval = yyvsp[1-yylen];

#if YYLSP_NEEDED
  /* Similarly for the default location.  Let the user run additional
     commands if for instance locations are ranges.  */
  yyloc = yylsp[1-yylen];
  YYLLOC_DEFAULT (yyloc, (yylsp - yylen), yylen);
#endif

#if YYDEBUG
  /* We have to keep this `#if YYDEBUG', since we use variables which
     are defined only if `YYDEBUG' is set.  */
  if (yydebug)
    {
      int yyi;

      YYFPRINTF (stderr, "Reducing via rule %d (line %d), ",
		 yyn, yyrline[yyn]);

      /* Print the symbols being reduced, and their result.  */
      for (yyi = yyprhs[yyn]; yyrhs[yyi] > 0; yyi++)
	YYFPRINTF (stderr, "%s ", yytname[yyrhs[yyi]]);
      YYFPRINTF (stderr, " -> %s\n", yytname[yyr1[yyn]]);
    }
#endif

  switch (yyn) {

case 1:
#line 166 "rtfGrammer.y"
{ GSRTFstart(CTXT); ;
    break;}
case 2:
#line 166 "rtfGrammer.y"
{ GSRTFstop(CTXT); ;
    break;}
case 4:
#line 169 "rtfGrammer.y"
{ yyval.number = 1; ;
    break;}
case 5:
#line 170 "rtfGrammer.y"
{ yyval.number = 2; ;
    break;}
case 6:
#line 171 "rtfGrammer.y"
{ yyval.number = 3; ;
    break;}
case 7:
#line 172 "rtfGrammer.y"
{ yyval.number = 4; ;
    break;}
case 12:
#line 179 "rtfGrammer.y"
{ GSRTFmangleText(CTXT, yyvsp[0].text); free((void *)yyvsp[0].text); ;
    break;}
case 14:
#line 183 "rtfGrammer.y"
{ GSRTFopenBlock(CTXT, NO); ;
    break;}
case 15:
#line 183 "rtfGrammer.y"
{ GSRTFcloseBlock(CTXT, NO); ;
    break;}
case 16:
#line 184 "rtfGrammer.y"
{ GSRTFopenBlock(CTXT, YES); ;
    break;}
case 17:
#line 184 "rtfGrammer.y"
{ GSRTFcloseBlock(CTXT, YES); ;
    break;}
case 18:
#line 185 "rtfGrammer.y"
{ GSRTFopenBlock(CTXT, YES); ;
    break;}
case 19:
#line 185 "rtfGrammer.y"
{ GSRTFcloseBlock(CTXT, YES); ;
    break;}
case 20:
#line 186 "rtfGrammer.y"
{ GSRTFopenBlock(CTXT, YES); ;
    break;}
case 21:
#line 186 "rtfGrammer.y"
{ GSRTFcloseBlock(CTXT, YES); ;
    break;}
case 22:
#line 187 "rtfGrammer.y"
{ GSRTFopenBlock(CTXT, YES); ;
    break;}
case 23:
#line 187 "rtfGrammer.y"
{ GSRTFcloseBlock(CTXT, YES); ;
    break;}
case 24:
#line 188 "rtfGrammer.y"
{ GSRTFopenBlock(CTXT, YES); ;
    break;}
case 25:
#line 188 "rtfGrammer.y"
{ GSRTFcloseBlock(CTXT, YES); ;
    break;}
case 26:
#line 189 "rtfGrammer.y"
{ GSRTFopenBlock(CTXT, YES); ;
    break;}
case 27:
#line 189 "rtfGrammer.y"
{ GSRTFcloseBlock(CTXT, YES); ;
    break;}
case 28:
#line 190 "rtfGrammer.y"
{ GSRTFopenBlock(CTXT, YES); ;
    break;}
case 29:
#line 190 "rtfGrammer.y"
{ GSRTFcloseBlock(CTXT, YES); ;
    break;}
case 30:
#line 198 "rtfGrammer.y"
{ int font;
		    
						  if (yyvsp[0].cmd.isEmpty)
						      font = 0;
						  else
						      font = yyvsp[0].cmd.parameter;
						  GSRTFfontNumber(CTXT, font); ;
    break;}
case 31:
#line 205 "rtfGrammer.y"
{ int size;

						  if (yyvsp[0].cmd.isEmpty)
						      size = 24;
						  else
						      size = yyvsp[0].cmd.parameter;
						  GSRTFfontSize(CTXT, size); ;
    break;}
case 32:
#line 212 "rtfGrammer.y"
{ int width; 
		
		                                  if (yyvsp[0].cmd.isEmpty)
						      width = 12240;
						  else
						      width = yyvsp[0].cmd.parameter;
						  GSRTFpaperWidth(CTXT, width);;
    break;}
case 33:
#line 219 "rtfGrammer.y"
{ int height; 
		
		                                  if (yyvsp[0].cmd.isEmpty)
						      height = 15840;
						  else
						      height = yyvsp[0].cmd.parameter;
						  GSRTFpaperHeight(CTXT, height);;
    break;}
case 34:
#line 226 "rtfGrammer.y"
{ int margin; 
		
		                                  if (yyvsp[0].cmd.isEmpty)
						      margin = 1800;
						  else
						      margin = yyvsp[0].cmd.parameter;
						  GSRTFmarginLeft(CTXT, margin);;
    break;}
case 35:
#line 233 "rtfGrammer.y"
{ int margin; 
		
		                                  if (yyvsp[0].cmd.isEmpty)
						      margin = 1800;
						  else
						      margin = yyvsp[0].cmd.parameter;
						  GSRTFmarginRight(CTXT, margin); ;
    break;}
case 36:
#line 240 "rtfGrammer.y"
{ int margin; 
		
		                                  if (yyvsp[0].cmd.isEmpty)
						      margin = 1440;
						  else
						      margin = yyvsp[0].cmd.parameter;
						  GSRTFmarginTop(CTXT, margin); ;
    break;}
case 37:
#line 247 "rtfGrammer.y"
{ int margin; 
		
		                                  if (yyvsp[0].cmd.isEmpty)
						      margin = 1440;
						  else
						      margin = yyvsp[0].cmd.parameter;
						  GSRTFmarginButtom(CTXT, margin); ;
    break;}
case 38:
#line 254 "rtfGrammer.y"
{ int indent; 
		
		                                  if (yyvsp[0].cmd.isEmpty)
						      indent = 0;
						  else
						      indent = yyvsp[0].cmd.parameter;
						  GSRTFfirstLineIndent(CTXT, indent); ;
    break;}
case 39:
#line 261 "rtfGrammer.y"
{ int indent; 
		
		                                  if (yyvsp[0].cmd.isEmpty)
						      indent = 0;
						  else
						      indent = yyvsp[0].cmd.parameter;
						  GSRTFleftIndent(CTXT, indent);;
    break;}
case 40:
#line 268 "rtfGrammer.y"
{ int indent; 
		
		                                  if (yyvsp[0].cmd.isEmpty)
						      indent = 0;
						  else
						      indent = yyvsp[0].cmd.parameter;
						  GSRTFrightIndent(CTXT, indent);;
    break;}
case 41:
#line 275 "rtfGrammer.y"
{ int location; 
		
		                                  if (yyvsp[0].cmd.isEmpty)
						      location = 0;
						  else
						      location = yyvsp[0].cmd.parameter;
						  GSRTFtabstop(CTXT, location);;
    break;}
case 42:
#line 282 "rtfGrammer.y"
{ GSRTFalignCenter(CTXT); ;
    break;}
case 43:
#line 283 "rtfGrammer.y"
{ GSRTFalignJustified(CTXT); ;
    break;}
case 44:
#line 284 "rtfGrammer.y"
{ GSRTFalignLeft(CTXT); ;
    break;}
case 45:
#line 285 "rtfGrammer.y"
{ GSRTFalignRight(CTXT); ;
    break;}
case 46:
#line 286 "rtfGrammer.y"
{ int space; 
		
		                                  if (yyvsp[0].cmd.isEmpty)
						      space = 0;
						  else
						      space = yyvsp[0].cmd.parameter;
						  GSRTFspaceAbove(CTXT, space); ;
    break;}
case 47:
#line 293 "rtfGrammer.y"
{ GSRTFlineSpace(CTXT, yyvsp[0].cmd.parameter); ;
    break;}
case 48:
#line 294 "rtfGrammer.y"
{ GSRTFdefaultParagraph(CTXT); ;
    break;}
case 49:
#line 295 "rtfGrammer.y"
{ GSRTFstyle(CTXT, yyvsp[0].cmd.parameter); ;
    break;}
case 50:
#line 296 "rtfGrammer.y"
{ int color; 
		
		                                  if (yyvsp[0].cmd.isEmpty)
						      color = 0;
						  else
						      color = yyvsp[0].cmd.parameter;
						  GSRTFcolorbg(CTXT, color); ;
    break;}
case 51:
#line 303 "rtfGrammer.y"
{ int color; 
		
		                                  if (yyvsp[0].cmd.isEmpty)
						      color = 0;
						  else
						      color = yyvsp[0].cmd.parameter;
						  GSRTFcolorfg(CTXT, color); ;
    break;}
case 52:
#line 310 "rtfGrammer.y"
{ int script;
		
		                                  if (yyvsp[0].cmd.isEmpty)
						      script = 6;
						  else
						      script = yyvsp[0].cmd.parameter;
						  GSRTFsubscript(CTXT, script); ;
    break;}
case 53:
#line 317 "rtfGrammer.y"
{ int script;
		
		                                  if (yyvsp[0].cmd.isEmpty)
						      script = 6;
						  else
						      script = yyvsp[0].cmd.parameter;
						  GSRTFsuperscript(CTXT, script); ;
    break;}
case 54:
#line 324 "rtfGrammer.y"
{ BOOL on;

		                                  if (yyvsp[0].cmd.isEmpty || yyvsp[0].cmd.parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFbold(CTXT, on); ;
    break;}
case 55:
#line 331 "rtfGrammer.y"
{ BOOL on;

		                                  if (yyvsp[0].cmd.isEmpty || yyvsp[0].cmd.parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFitalic(CTXT, on); ;
    break;}
case 56:
#line 338 "rtfGrammer.y"
{ BOOL on;

		                                  if (yyvsp[0].cmd.isEmpty || yyvsp[0].cmd.parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFunderline(CTXT, on); ;
    break;}
case 57:
#line 345 "rtfGrammer.y"
{ GSRTFunderline(CTXT, NO); ;
    break;}
case 58:
#line 346 "rtfGrammer.y"
{ GSRTFdefaultCharacterStyle(CTXT); ;
    break;}
case 59:
#line 347 "rtfGrammer.y"
{ GSRTFparagraph(CTXT); ;
    break;}
case 60:
#line 348 "rtfGrammer.y"
{ GSRTFparagraph(CTXT); ;
    break;}
case 61:
#line 349 "rtfGrammer.y"
{ GSRTFgenericRTFcommand(CTXT, yyvsp[0].cmd); ;
    break;}
case 66:
#line 363 "rtfGrammer.y"
{ free((void *)yyvsp[-1].text);;
    break;}
case 67:
#line 368 "rtfGrammer.y"
{ GSRTFregisterFont(CTXT, yyvsp[0].text, yyvsp[-2].number, yyvsp[-3].cmd.parameter);
                                                          free((void *)yyvsp[0].text); ;
    break;}
case 73:
#line 381 "rtfGrammer.y"
{ yyval.number = RTFfamilyNil - RTFfamilyNil; ;
    break;}
case 74:
#line 382 "rtfGrammer.y"
{ yyval.number = RTFfamilyRoman - RTFfamilyNil; ;
    break;}
case 75:
#line 383 "rtfGrammer.y"
{ yyval.number = RTFfamilySwiss - RTFfamilyNil; ;
    break;}
case 76:
#line 384 "rtfGrammer.y"
{ yyval.number = RTFfamilyModern - RTFfamilyNil; ;
    break;}
case 77:
#line 385 "rtfGrammer.y"
{ yyval.number = RTFfamilyScript - RTFfamilyNil; ;
    break;}
case 78:
#line 386 "rtfGrammer.y"
{ yyval.number = RTFfamilyDecor - RTFfamilyNil; ;
    break;}
case 79:
#line 387 "rtfGrammer.y"
{ yyval.number = RTFfamilyTech - RTFfamilyNil; ;
    break;}
case 83:
#line 404 "rtfGrammer.y"
{ 
		       GSRTFaddColor(CTXT, yyvsp[-3].cmd.parameter, yyvsp[-2].cmd.parameter, yyvsp[-1].cmd.parameter);
		       free((void *)yyvsp[0].text);
		     ;
    break;}
case 84:
#line 409 "rtfGrammer.y"
{ 
		       GSRTFaddDefaultColor(CTXT);
		       free((void *)yyvsp[0].text);
		     ;
    break;}
}

#line 709 "/usr/share/bison/bison.simple"


  yyvsp -= yylen;
  yyssp -= yylen;
#if YYLSP_NEEDED
  yylsp -= yylen;
#endif

#if YYDEBUG
  if (yydebug)
    {
      short *yyssp1 = yyss - 1;
      YYFPRINTF (stderr, "state stack now");
      while (yyssp1 != yyssp)
	YYFPRINTF (stderr, " %d", *++yyssp1);
      YYFPRINTF (stderr, "\n");
    }
#endif

  *++yyvsp = yyval;
#if YYLSP_NEEDED
  *++yylsp = yyloc;
#endif

  /* Now `shift' the result of the reduction.  Determine what state
     that goes to, based on the state we popped back to and the rule
     number reduced by.  */

  yyn = yyr1[yyn];

  yystate = yypgoto[yyn - YYNTBASE] + *yyssp;
  if (yystate >= 0 && yystate <= YYLAST && yycheck[yystate] == *yyssp)
    yystate = yytable[yystate];
  else
    yystate = yydefgoto[yyn - YYNTBASE];

  goto yynewstate;


/*------------------------------------.
| yyerrlab -- here on detecting error |
`------------------------------------*/
yyerrlab:
  /* If not already recovering from an error, report this error.  */
  if (!yyerrstatus)
    {
      ++yynerrs;

#ifdef YYERROR_VERBOSE
      yyn = yypact[yystate];

      if (yyn > YYFLAG && yyn < YYLAST)
	{
	  YYSIZE_T yysize = 0;
	  char *yymsg;
	  int yyx, yycount;

	  yycount = 0;
	  /* Start YYX at -YYN if negative to avoid negative indexes in
	     YYCHECK.  */
	  for (yyx = yyn < 0 ? -yyn : 0;
	       yyx < (int) (sizeof (yytname) / sizeof (char *)); yyx++)
	    if (yycheck[yyx + yyn] == yyx)
	      yysize += yystrlen (yytname[yyx]) + 15, yycount++;
	  yysize += yystrlen ("parse error, unexpected ") + 1;
	  yysize += yystrlen (yytname[YYTRANSLATE (yychar)]);
	  yymsg = (char *) YYSTACK_ALLOC (yysize);
	  if (yymsg != 0)
	    {
	      char *yyp = yystpcpy (yymsg, "parse error, unexpected ");
	      yyp = yystpcpy (yyp, yytname[YYTRANSLATE (yychar)]);

	      if (yycount < 5)
		{
		  yycount = 0;
		  for (yyx = yyn < 0 ? -yyn : 0;
		       yyx < (int) (sizeof (yytname) / sizeof (char *));
		       yyx++)
		    if (yycheck[yyx + yyn] == yyx)
		      {
			const char *yyq = ! yycount ? ", expecting " : " or ";
			yyp = yystpcpy (yyp, yyq);
			yyp = yystpcpy (yyp, yytname[yyx]);
			yycount++;
		      }
		}
	      yyerror (yymsg);
	      YYSTACK_FREE (yymsg);
	    }
	  else
	    yyerror ("parse error; also virtual memory exhausted");
	}
      else
#endif /* defined (YYERROR_VERBOSE) */
	yyerror ("parse error");
    }
  goto yyerrlab1;


/*--------------------------------------------------.
| yyerrlab1 -- error raised explicitly by an action |
`--------------------------------------------------*/
yyerrlab1:
  if (yyerrstatus == 3)
    {
      /* If just tried and failed to reuse lookahead token after an
	 error, discard it.  */

      /* return failure if at end of input */
      if (yychar == YYEOF)
	YYABORT;
      YYDPRINTF ((stderr, "Discarding token %d (%s).\n",
		  yychar, yytname[yychar1]));
      yychar = YYEMPTY;
    }

  /* Else will try to reuse lookahead token after shifting the error
     token.  */

  yyerrstatus = 3;		/* Each real token shifted decrements this */

  goto yyerrhandle;


/*-------------------------------------------------------------------.
| yyerrdefault -- current state does not do anything special for the |
| error token.                                                       |
`-------------------------------------------------------------------*/
yyerrdefault:
#if 0
  /* This is wrong; only states that explicitly want error tokens
     should shift them.  */

  /* If its default is to accept any token, ok.  Otherwise pop it.  */
  yyn = yydefact[yystate];
  if (yyn)
    goto yydefault;
#endif


/*---------------------------------------------------------------.
| yyerrpop -- pop the current state because it cannot handle the |
| error token                                                    |
`---------------------------------------------------------------*/
yyerrpop:
  if (yyssp == yyss)
    YYABORT;
  yyvsp--;
  yystate = *--yyssp;
#if YYLSP_NEEDED
  yylsp--;
#endif

#if YYDEBUG
  if (yydebug)
    {
      short *yyssp1 = yyss - 1;
      YYFPRINTF (stderr, "Error: state stack now");
      while (yyssp1 != yyssp)
	YYFPRINTF (stderr, " %d", *++yyssp1);
      YYFPRINTF (stderr, "\n");
    }
#endif

/*--------------.
| yyerrhandle.  |
`--------------*/
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

  YYDPRINTF ((stderr, "Shifting error token, "));

  *++yyvsp = yylval;
#if YYLSP_NEEDED
  *++yylsp = yylloc;
#endif

  yystate = yyn;
  goto yynewstate;


/*-------------------------------------.
| yyacceptlab -- YYACCEPT comes here.  |
`-------------------------------------*/
yyacceptlab:
  yyresult = 0;
  goto yyreturn;

/*-----------------------------------.
| yyabortlab -- YYABORT comes here.  |
`-----------------------------------*/
yyabortlab:
  yyresult = 1;
  goto yyreturn;

/*---------------------------------------------.
| yyoverflowab -- parser overflow comes here.  |
`---------------------------------------------*/
yyoverflowlab:
  yyerror ("parser stack overflow");
  yyresult = 2;
  /* Fall through.  */

yyreturn:
#ifndef yyoverflow
  if (yyss != yyssa)
    YYSTACK_FREE (yyss);
#endif
  return yyresult;
}
#line 421 "rtfGrammer.y"


/*	some C code here	*/

