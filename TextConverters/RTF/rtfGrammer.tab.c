/* A Bison parser, made from rtfGrammer.y, by GNU bison 1.75.  */

/* Skeleton parser for Yacc-like parsing with Bison,
   Copyright (C) 1984, 1989, 1990, 2000, 2001, 2002 Free Software Foundation, Inc.

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

/* Written by Richard Stallman by simplifying the original so called
   ``semantic'' parser.  */

/* All symbols defined below should begin with yy or YY, to avoid
   infringing on user name space.  This should be done even for local
   variables, as they might otherwise be expanded by user macros.
   There are some unavoidable exceptions within include files to
   define necessary library symbols; they are noted "INFRINGES ON
   USER NAME SPACE" below.  */

/* Identify Bison output.  */
#define YYBISON	1

/* Pure parsers.  */
#define YYPURE	1

/* Using locations.  */
#define YYLSP_NEEDED 0

/* If NAME_PREFIX is specified substitute the variables and functions
   names.  */
#define yyparse GSRTFparse
#define yylex   GSRTFlex
#define yyerror GSRTFerror
#define yylval  GSRTFlval
#define yychar  GSRTFchar
#define yydebug GSRTFdebug
#define yynerrs GSRTFnerrs


/* Tokens.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
   /* Put the tokens into the symbol table, so that GDB and other debuggers
      know about them.  */
   enum yytokentype {
     RTFtext = 258,
     RTFstart = 259,
     RTFansi = 260,
     RTFmac = 261,
     RTFpc = 262,
     RTFpca = 263,
     RTFignore = 264,
     RTFinfo = 265,
     RTFstylesheet = 266,
     RTFfootnote = 267,
     RTFheader = 268,
     RTFfooter = 269,
     RTFpict = 270,
     RTFplain = 271,
     RTFparagraph = 272,
     RTFdefaultParagraph = 273,
     RTFrow = 274,
     RTFcell = 275,
     RTFtabulator = 276,
     RTFemdash = 277,
     RTFendash = 278,
     RTFemspace = 279,
     RTFenspace = 280,
     RTFbullet = 281,
     RTFlquote = 282,
     RTFrquote = 283,
     RTFldblquote = 284,
     RTFrdblquote = 285,
     RTFred = 286,
     RTFgreen = 287,
     RTFblue = 288,
     RTFcolorbg = 289,
     RTFcolorfg = 290,
     RTFcolortable = 291,
     RTFfont = 292,
     RTFfontSize = 293,
     RTFpaperWidth = 294,
     RTFpaperHeight = 295,
     RTFmarginLeft = 296,
     RTFmarginRight = 297,
     RTFmarginTop = 298,
     RTFmarginButtom = 299,
     RTFfirstLineIndent = 300,
     RTFleftIndent = 301,
     RTFrightIndent = 302,
     RTFalignCenter = 303,
     RTFalignJustified = 304,
     RTFalignLeft = 305,
     RTFalignRight = 306,
     RTFlineSpace = 307,
     RTFspaceAbove = 308,
     RTFstyle = 309,
     RTFbold = 310,
     RTFitalic = 311,
     RTFunderline = 312,
     RTFunderlineStop = 313,
     RTFunichar = 314,
     RTFsubscript = 315,
     RTFsuperscript = 316,
     RTFtabstop = 317,
     RTFfcharset = 318,
     RTFfprq = 319,
     RTFcpg = 320,
     RTFOtherStatement = 321,
     RTFfontListStart = 322,
     RTFfamilyNil = 323,
     RTFfamilyRoman = 324,
     RTFfamilySwiss = 325,
     RTFfamilyModern = 326,
     RTFfamilyScript = 327,
     RTFfamilyDecor = 328,
     RTFfamilyTech = 329
   };
#endif
#define RTFtext 258
#define RTFstart 259
#define RTFansi 260
#define RTFmac 261
#define RTFpc 262
#define RTFpca 263
#define RTFignore 264
#define RTFinfo 265
#define RTFstylesheet 266
#define RTFfootnote 267
#define RTFheader 268
#define RTFfooter 269
#define RTFpict 270
#define RTFplain 271
#define RTFparagraph 272
#define RTFdefaultParagraph 273
#define RTFrow 274
#define RTFcell 275
#define RTFtabulator 276
#define RTFemdash 277
#define RTFendash 278
#define RTFemspace 279
#define RTFenspace 280
#define RTFbullet 281
#define RTFlquote 282
#define RTFrquote 283
#define RTFldblquote 284
#define RTFrdblquote 285
#define RTFred 286
#define RTFgreen 287
#define RTFblue 288
#define RTFcolorbg 289
#define RTFcolorfg 290
#define RTFcolortable 291
#define RTFfont 292
#define RTFfontSize 293
#define RTFpaperWidth 294
#define RTFpaperHeight 295
#define RTFmarginLeft 296
#define RTFmarginRight 297
#define RTFmarginTop 298
#define RTFmarginButtom 299
#define RTFfirstLineIndent 300
#define RTFleftIndent 301
#define RTFrightIndent 302
#define RTFalignCenter 303
#define RTFalignJustified 304
#define RTFalignLeft 305
#define RTFalignRight 306
#define RTFlineSpace 307
#define RTFspaceAbove 308
#define RTFstyle 309
#define RTFbold 310
#define RTFitalic 311
#define RTFunderline 312
#define RTFunderlineStop 313
#define RTFunichar 314
#define RTFsubscript 315
#define RTFsuperscript 316
#define RTFtabstop 317
#define RTFfcharset 318
#define RTFfprq 319
#define RTFcpg 320
#define RTFOtherStatement 321
#define RTFfontListStart 322
#define RTFfamilyNil 323
#define RTFfamilyRoman 324
#define RTFfamilySwiss 325
#define RTFfamilyModern 326
#define RTFfamilyScript 327
#define RTFfamilyDecor 328
#define RTFfamilyTech 329




/* Copy the first part of user declarations.  */
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



/* Enabling traces.  */
#ifndef YYDEBUG
# define YYDEBUG 0
#endif

/* Enabling verbose error messages.  */
#ifdef YYERROR_VERBOSE
# undef YYERROR_VERBOSE
# define YYERROR_VERBOSE 1
#else
# define YYERROR_VERBOSE 0
#endif

#ifndef YYSTYPE
#line 77 "rtfGrammer.y"
typedef union {
	int		number;
	const char	*text;
	RTFcmd		cmd;
} yystype;
/* Line 193 of /usr/share/bison/yacc.c.  */
#line 278 "rtfGrammer.tab.c"
# define YYSTYPE yystype
# define YYSTYPE_IS_TRIVIAL 1
#endif

#ifndef YYLTYPE
typedef struct yyltype
{
  int first_line;
  int first_column;
  int last_line;
  int last_column;
} yyltype;
# define YYLTYPE yyltype
# define YYLTYPE_IS_TRIVIAL 1
#endif

/* Copy the second part of user declarations.  */


/* Line 213 of /usr/share/bison/yacc.c.  */
#line 299 "rtfGrammer.tab.c"

#if ! defined (yyoverflow) || YYERROR_VERBOSE

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
#endif /* ! defined (yyoverflow) || YYERROR_VERBOSE */


#if (! defined (yyoverflow) \
     && (! defined (__cplusplus) \
	 || (YYLTYPE_IS_TRIVIAL && YYSTYPE_IS_TRIVIAL)))

/* A type that is properly aligned for any stack member.  */
union yyalloc
{
  short yyss;
  YYSTYPE yyvs;
  };

/* The size of the maximum gap between one aligned stack and the next.  */
# define YYSTACK_GAP_MAX (sizeof (union yyalloc) - 1)

/* The size of an array large to enough to hold all stacks, each with
   N elements.  */
# define YYSTACK_BYTES(N) \
     ((N) * (sizeof (short) + sizeof (YYSTYPE))				\
      + YYSTACK_GAP_MAX)

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
	    (To)[yyi] = (From)[yyi];	\
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

#if defined (__STDC__) || defined (__cplusplus)
   typedef signed char yysigned_char;
#else
   typedef short yysigned_char;
#endif

/* YYFINAL -- State number of the termination state. */
#define YYFINAL  4
#define YYLAST   701

/* YYNTOKENS -- Number of terminals. */
#define YYNTOKENS  77
/* YYNNTS -- Number of nonterminals. */
#define YYNNTS  24
/* YYNRULES -- Number of rules. */
#define YYNRULES  89
/* YYNRULES -- Number of states. */
#define YYNSTATES  123

/* YYTRANSLATE(YYLEX) -- Bison symbol number corresponding to YYLEX.  */
#define YYUNDEFTOK  2
#define YYMAXUTOK   329

#define YYTRANSLATE(X) \
  ((unsigned)(X) <= YYMAXUTOK ? yytranslate[X] : YYUNDEFTOK)

/* YYTRANSLATE[YYLEX] -- Bison symbol number corresponding to YYLEX.  */
static const unsigned char yytranslate[] =
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
       2,     2,     2,    75,     2,    76,     2,     2,     2,     2,
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
       2,     2,     2,     2,     2,     2,     1,     2,     3,     4,
       5,     6,     7,     8,     9,    10,    11,    12,    13,    14,
      15,    16,    17,    18,    19,    20,    21,    22,    23,    24,
      25,    26,    27,    28,    29,    30,    31,    32,    33,    34,
      35,    36,    37,    38,    39,    40,    41,    42,    43,    44,
      45,    46,    47,    48,    49,    50,    51,    52,    53,    54,
      55,    56,    57,    58,    59,    60,    61,    62,    63,    64,
      65,    66,    67,    68,    69,    70,    71,    72,    73,    74
};

#if YYDEBUG
/* YYPRHS[YYN] -- Index of the first RHS symbol of rule number YYN in
   YYRHS.  */
static const unsigned char yyprhs[] =
{
       0,     0,     3,     4,     5,    13,    15,    17,    19,    21,
      23,    24,    27,    30,    33,    36,    39,    42,    43,    48,
      49,    55,    56,    62,    63,    69,    70,    76,    77,    83,
      84,    90,    91,    97,   101,   103,   105,   107,   109,   111,
     113,   115,   117,   119,   121,   123,   125,   127,   129,   131,
     133,   135,   137,   139,   141,   143,   145,   147,   149,   151,
     153,   155,   157,   159,   161,   163,   165,   167,   172,   173,
     176,   181,   188,   193,   194,   197,   200,   203,   206,   208,
     210,   212,   214,   216,   218,   220,   225,   226,   229,   234
};

/* YYRHS -- A `-1'-separated list of the rules' RHS. */
static const yysigned_char yyrhs[] =
{
      78,     0,    -1,    -1,    -1,    75,    79,     4,    81,    82,
      80,    76,    -1,     5,    -1,     6,    -1,     7,    -1,     8,
      -1,    66,    -1,    -1,    82,    93,    -1,    82,    98,    -1,
      82,    92,    -1,    82,     3,    -1,    82,    83,    -1,    82,
       1,    -1,    -1,    75,    84,    82,    76,    -1,    -1,    75,
      85,     9,    82,    76,    -1,    -1,    75,    86,    10,    82,
      76,    -1,    -1,    75,    87,    11,    82,    76,    -1,    -1,
      75,    88,    12,    82,    76,    -1,    -1,    75,    89,    13,
      82,    76,    -1,    -1,    75,    90,    14,    82,    76,    -1,
      -1,    75,    91,    15,    82,    76,    -1,    75,     1,    76,
      -1,    37,    -1,    38,    -1,    39,    -1,    40,    -1,    41,
      -1,    42,    -1,    43,    -1,    44,    -1,    45,    -1,    46,
      -1,    47,    -1,    62,    -1,    48,    -1,    49,    -1,    50,
      -1,    51,    -1,    53,    -1,    52,    -1,    18,    -1,    54,
      -1,    34,    -1,    35,    -1,    60,    -1,    61,    -1,    55,
      -1,    56,    -1,    57,    -1,    58,    -1,    59,    -1,    16,
      -1,    17,    -1,    19,    -1,    66,    -1,    75,    67,    94,
      76,    -1,    -1,    94,    95,    -1,    94,    75,    95,    76,
      -1,    94,    75,    95,    83,     3,    76,    -1,    37,    97,
      96,     3,    -1,    -1,    96,    63,    -1,    96,    64,    -1,
      96,    65,    -1,    96,    83,    -1,    68,    -1,    69,    -1,
      70,    -1,    71,    -1,    72,    -1,    73,    -1,    74,    -1,
      75,    36,    99,    76,    -1,    -1,    99,   100,    -1,    31,
      32,    33,     3,    -1,     3,    -1
};

/* YYRLINE[YYN] -- source line where rule number YYN was defined.  */
static const unsigned short yyrline[] =
{
       0,   167,   167,   167,   167,   170,   171,   172,   173,   175,
     178,   179,   180,   181,   182,   183,   184,   187,   187,   188,
     188,   189,   189,   190,   190,   191,   191,   192,   192,   193,
     193,   194,   194,   195,   203,   210,   217,   224,   231,   238,
     245,   252,   259,   266,   273,   280,   287,   288,   289,   290,
     291,   298,   299,   300,   301,   308,   315,   322,   329,   336,
     343,   350,   351,   352,   353,   354,   355,   362,   365,   366,
     367,   368,   374,   378,   379,   380,   381,   382,   386,   388,
     389,   390,   391,   392,   393,   401,   404,   405,   409,   414
};
#endif

#if YYDEBUG || YYERROR_VERBOSE
/* YYTNME[SYMBOL-NUM] -- String name of the symbol SYMBOL-NUM.
   First, the terminals, then, starting at YYNTOKENS, nonterminals. */
static const char *const yytname[] =
{
  "$end", "error", "$undefined", "RTFtext", "RTFstart", "RTFansi", "RTFmac", 
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
  "RTFitalic", "RTFunderline", "RTFunderlineStop", "RTFunichar", 
  "RTFsubscript", "RTFsuperscript", "RTFtabstop", "RTFfcharset", 
  "RTFfprq", "RTFcpg", "RTFOtherStatement", "RTFfontListStart", 
  "RTFfamilyNil", "RTFfamilyRoman", "RTFfamilySwiss", "RTFfamilyModern", 
  "RTFfamilyScript", "RTFfamilyDecor", "RTFfamilyTech", "'{'", "'}'", 
  "$accept", "rtfFile", "@1", "@2", "rtfCharset", "rtfIngredients", 
  "rtfBlock", "@3", "@4", "@5", "@6", "@7", "@8", "@9", "@10", 
  "rtfStatement", "rtfFontList", "rtfFonts", "rtfFontStatement", 
  "rtfFontAttrs", "rtfFontFamily", "rtfColorDef", "rtfColors", 
  "rtfColorStatement", 0
};
#endif

# ifdef YYPRINT
/* YYTOKNUM[YYLEX-NUM] -- Internal token number corresponding to
   token YYLEX-NUM.  */
static const unsigned short yytoknum[] =
{
       0,   256,   257,   258,   259,   260,   261,   262,   263,   264,
     265,   266,   267,   268,   269,   270,   271,   272,   273,   274,
     275,   276,   277,   278,   279,   280,   281,   282,   283,   284,
     285,   286,   287,   288,   289,   290,   291,   292,   293,   294,
     295,   296,   297,   298,   299,   300,   301,   302,   303,   304,
     305,   306,   307,   308,   309,   310,   311,   312,   313,   314,
     315,   316,   317,   318,   319,   320,   321,   322,   323,   324,
     325,   326,   327,   328,   329,   123,   125
};
# endif

/* YYR1[YYN] -- Symbol number of symbol that rule YYN derives.  */
static const unsigned char yyr1[] =
{
       0,    77,    79,    80,    78,    81,    81,    81,    81,    81,
      82,    82,    82,    82,    82,    82,    82,    84,    83,    85,
      83,    86,    83,    87,    83,    88,    83,    89,    83,    90,
      83,    91,    83,    83,    92,    92,    92,    92,    92,    92,
      92,    92,    92,    92,    92,    92,    92,    92,    92,    92,
      92,    92,    92,    92,    92,    92,    92,    92,    92,    92,
      92,    92,    92,    92,    92,    92,    92,    93,    94,    94,
      94,    94,    95,    96,    96,    96,    96,    96,    97,    97,
      97,    97,    97,    97,    97,    98,    99,    99,   100,   100
};

/* YYR2[YYN] -- Number of symbols composing right hand side of rule YYN.  */
static const unsigned char yyr2[] =
{
       0,     2,     0,     0,     7,     1,     1,     1,     1,     1,
       0,     2,     2,     2,     2,     2,     2,     0,     4,     0,
       5,     0,     5,     0,     5,     0,     5,     0,     5,     0,
       5,     0,     5,     3,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     4,     0,     2,
       4,     6,     4,     0,     2,     2,     2,     2,     1,     1,
       1,     1,     1,     1,     1,     4,     0,     2,     4,     1
};

/* YYDEFACT[STATE-NAME] -- Default rule to reduce with in state
   STATE-NUM when YYTABLE doesn't specify something else to do.  Zero
   means the default is an error.  */
static const unsigned char yydefact[] =
{
       0,     2,     0,     0,     1,     0,     5,     6,     7,     8,
       9,    10,     0,    16,    14,    63,    64,    52,    65,    54,
      55,    34,    35,    36,    37,    38,    39,    40,    41,    42,
      43,    44,    46,    47,    48,    49,    51,    50,    53,    58,
      59,    60,    61,    62,    56,    57,    45,    66,     0,     0,
      15,    13,    11,    12,     0,    86,    68,    10,     0,     0,
       0,     0,     0,     0,     0,     4,    33,     0,     0,     0,
      10,    10,    10,    10,    10,    10,    10,    89,     0,    85,
      87,     0,     0,    67,    69,    18,     0,     0,     0,     0,
       0,     0,     0,     0,    78,    79,    80,    81,    82,    83,
      84,    73,     0,    20,    22,    24,    26,    28,    30,    32,
       0,     0,     0,    70,     0,    88,    72,    74,    75,    76,
      77,     0,    71
};

/* YYDEFGOTO[NTERM-NUM]. */
static const yysigned_char yydefgoto[] =
{
      -1,     2,     3,    49,    11,    12,    50,    57,    58,    59,
      60,    61,    62,    63,    64,    51,    52,    68,    84,   111,
     101,    53,    67,    80
};

/* YYPACT[STATE-NUM] -- Index in YYTABLE of the portion describing
   STATE-NUM.  */
#define YYPACT_NINF -84
static const short yypact[] =
{
     -74,   -84,    31,    28,   -84,    -2,   -84,   -84,   -84,   -84,
     -84,   -84,   129,   -84,   -84,   -84,   -84,   -84,   -84,   -84,
     -84,   -84,   -84,   -84,   -84,   -84,   -84,   -84,   -84,   -84,
     -84,   -84,   -84,   -84,   -84,   -84,   -84,   -84,   -84,   -84,
     -84,   -84,   -84,   -84,   -84,   -84,   -84,   -84,    -1,   -13,
     -84,   -84,   -84,   -84,    -9,   -84,   -84,   -84,    60,    62,
      89,    91,    58,   117,   119,   -84,   -84,    59,    61,   191,
     -84,   -84,   -84,   -84,   -84,   -84,   -84,   -84,    41,   -84,
     -84,    23,   101,   -84,   -84,   -84,   253,   315,   377,   439,
     501,   563,   625,   106,   -84,   -84,   -84,   -84,   -84,   -84,
     -84,   -84,   -46,   -84,   -84,   -84,   -84,   -84,   -84,   -84,
     137,    24,    67,   -84,   138,   -84,   -84,   -84,   -84,   -84,
     -84,    68,   -84
};

/* YYPGOTO[NTERM-NUM].  */
static const yysigned_char yypgoto[] =
{
     -84,   -84,   -84,   -84,   -84,   -50,   -83,   -84,   -84,   -84,
     -84,   -84,   -84,   -84,   -84,   -84,   -84,   -84,    69,   -84,
     -84,   -84,   -84,   -84
};

/* YYTABLE[YYPACT[STATE-NUM]].  What to do in state STATE-NUM.  If
   positive, shift that token.  If negative, reduce the rule which
   number is the opposite.  If zero, do what YYDEFACT says.
   If YYTABLE_NINF, parse error.  */
#define YYTABLE_NINF -32
static const yysigned_char yytable[] =
{
      54,     1,   -17,     6,     7,     8,     9,    69,   -19,   -21,
     -23,   -25,   -27,   -29,   -31,   -17,   -17,   -17,   -17,   114,
      86,    87,    88,    89,    90,    91,    92,   116,   120,   112,
     113,     4,     5,   -17,   -17,    55,   -17,   -17,   -17,   -17,
     -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,
     -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,
     -17,   -17,    77,    65,    10,   -17,    56,    66,    54,    70,
     -17,    74,    71,    93,   -17,   -17,   -19,   -21,   -23,   -25,
     -27,   -29,   -31,   -17,   -17,   -17,   -17,   117,   118,   119,
      78,    94,    95,    96,    97,    98,    99,   100,    81,   112,
      72,   -17,   -17,    73,   -17,   -17,   -17,   -17,   -17,   -17,
     -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,
     -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,
      13,    75,    14,   -17,    76,    79,    82,    83,    81,   110,
     115,   121,   -17,   -17,   122,    15,    16,    17,    18,     0,
       0,   102,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,    19,    20,     0,    21,    22,    23,    24,
      25,    26,    27,    28,    29,    30,    31,    32,    33,    34,
      35,    36,    37,    38,    39,    40,    41,    42,    43,    44,
      45,    46,    13,     0,    14,    47,     0,     0,     0,     0,
       0,     0,     0,     0,    48,    -3,     0,    15,    16,    17,
      18,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,    19,    20,     0,    21,    22,
      23,    24,    25,    26,    27,    28,    29,    30,    31,    32,
      33,    34,    35,    36,    37,    38,    39,    40,    41,    42,
      43,    44,    45,    46,    13,     0,    14,    47,     0,     0,
       0,     0,     0,     0,     0,     0,    48,    85,     0,    15,
      16,    17,    18,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,    19,    20,     0,
      21,    22,    23,    24,    25,    26,    27,    28,    29,    30,
      31,    32,    33,    34,    35,    36,    37,    38,    39,    40,
      41,    42,    43,    44,    45,    46,    13,     0,    14,    47,
       0,     0,     0,     0,     0,     0,     0,     0,    48,   103,
       0,    15,    16,    17,    18,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,    19,
      20,     0,    21,    22,    23,    24,    25,    26,    27,    28,
      29,    30,    31,    32,    33,    34,    35,    36,    37,    38,
      39,    40,    41,    42,    43,    44,    45,    46,    13,     0,
      14,    47,     0,     0,     0,     0,     0,     0,     0,     0,
      48,   104,     0,    15,    16,    17,    18,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,    19,    20,     0,    21,    22,    23,    24,    25,    26,
      27,    28,    29,    30,    31,    32,    33,    34,    35,    36,
      37,    38,    39,    40,    41,    42,    43,    44,    45,    46,
      13,     0,    14,    47,     0,     0,     0,     0,     0,     0,
       0,     0,    48,   105,     0,    15,    16,    17,    18,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,    19,    20,     0,    21,    22,    23,    24,
      25,    26,    27,    28,    29,    30,    31,    32,    33,    34,
      35,    36,    37,    38,    39,    40,    41,    42,    43,    44,
      45,    46,    13,     0,    14,    47,     0,     0,     0,     0,
       0,     0,     0,     0,    48,   106,     0,    15,    16,    17,
      18,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,    19,    20,     0,    21,    22,
      23,    24,    25,    26,    27,    28,    29,    30,    31,    32,
      33,    34,    35,    36,    37,    38,    39,    40,    41,    42,
      43,    44,    45,    46,    13,     0,    14,    47,     0,     0,
       0,     0,     0,     0,     0,     0,    48,   107,     0,    15,
      16,    17,    18,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,    19,    20,     0,
      21,    22,    23,    24,    25,    26,    27,    28,    29,    30,
      31,    32,    33,    34,    35,    36,    37,    38,    39,    40,
      41,    42,    43,    44,    45,    46,    13,     0,    14,    47,
       0,     0,     0,     0,     0,     0,     0,     0,    48,   108,
       0,    15,    16,    17,    18,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,    19,
      20,     0,    21,    22,    23,    24,    25,    26,    27,    28,
      29,    30,    31,    32,    33,    34,    35,    36,    37,    38,
      39,    40,    41,    42,    43,    44,    45,    46,     0,     0,
       0,    47,     0,     0,     0,     0,     0,     0,     0,     0,
      48,   109
};

static const yysigned_char yycheck[] =
{
       1,    75,     3,     5,     6,     7,     8,    57,     9,    10,
      11,    12,    13,    14,    15,    16,    17,    18,    19,   102,
      70,    71,    72,    73,    74,    75,    76,     3,   111,    75,
      76,     0,     4,    34,    35,    36,    37,    38,    39,    40,
      41,    42,    43,    44,    45,    46,    47,    48,    49,    50,
      51,    52,    53,    54,    55,    56,    57,    58,    59,    60,
      61,    62,     3,    76,    66,    66,    67,    76,     1,     9,
       3,    13,    10,    32,    75,    76,     9,    10,    11,    12,
      13,    14,    15,    16,    17,    18,    19,    63,    64,    65,
      31,    68,    69,    70,    71,    72,    73,    74,    37,    75,
      11,    34,    35,    12,    37,    38,    39,    40,    41,    42,
      43,    44,    45,    46,    47,    48,    49,    50,    51,    52,
      53,    54,    55,    56,    57,    58,    59,    60,    61,    62,
       1,    14,     3,    66,    15,    76,    75,    76,    37,    33,
       3,     3,    75,    76,    76,    16,    17,    18,    19,    -1,
      -1,    82,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    34,    35,    -1,    37,    38,    39,    40,
      41,    42,    43,    44,    45,    46,    47,    48,    49,    50,
      51,    52,    53,    54,    55,    56,    57,    58,    59,    60,
      61,    62,     1,    -1,     3,    66,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    75,    76,    -1,    16,    17,    18,
      19,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    34,    35,    -1,    37,    38,
      39,    40,    41,    42,    43,    44,    45,    46,    47,    48,
      49,    50,    51,    52,    53,    54,    55,    56,    57,    58,
      59,    60,    61,    62,     1,    -1,     3,    66,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    75,    76,    -1,    16,
      17,    18,    19,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    34,    35,    -1,
      37,    38,    39,    40,    41,    42,    43,    44,    45,    46,
      47,    48,    49,    50,    51,    52,    53,    54,    55,    56,
      57,    58,    59,    60,    61,    62,     1,    -1,     3,    66,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    75,    76,
      -1,    16,    17,    18,    19,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    34,
      35,    -1,    37,    38,    39,    40,    41,    42,    43,    44,
      45,    46,    47,    48,    49,    50,    51,    52,    53,    54,
      55,    56,    57,    58,    59,    60,    61,    62,     1,    -1,
       3,    66,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      75,    76,    -1,    16,    17,    18,    19,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    34,    35,    -1,    37,    38,    39,    40,    41,    42,
      43,    44,    45,    46,    47,    48,    49,    50,    51,    52,
      53,    54,    55,    56,    57,    58,    59,    60,    61,    62,
       1,    -1,     3,    66,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    75,    76,    -1,    16,    17,    18,    19,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    34,    35,    -1,    37,    38,    39,    40,
      41,    42,    43,    44,    45,    46,    47,    48,    49,    50,
      51,    52,    53,    54,    55,    56,    57,    58,    59,    60,
      61,    62,     1,    -1,     3,    66,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    75,    76,    -1,    16,    17,    18,
      19,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    34,    35,    -1,    37,    38,
      39,    40,    41,    42,    43,    44,    45,    46,    47,    48,
      49,    50,    51,    52,    53,    54,    55,    56,    57,    58,
      59,    60,    61,    62,     1,    -1,     3,    66,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    75,    76,    -1,    16,
      17,    18,    19,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    34,    35,    -1,
      37,    38,    39,    40,    41,    42,    43,    44,    45,    46,
      47,    48,    49,    50,    51,    52,    53,    54,    55,    56,
      57,    58,    59,    60,    61,    62,     1,    -1,     3,    66,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    75,    76,
      -1,    16,    17,    18,    19,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    34,
      35,    -1,    37,    38,    39,    40,    41,    42,    43,    44,
      45,    46,    47,    48,    49,    50,    51,    52,    53,    54,
      55,    56,    57,    58,    59,    60,    61,    62,    -1,    -1,
      -1,    66,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      75,    76
};

/* YYSTOS[STATE-NUM] -- The (internal number of the) accessing
   symbol of state STATE-NUM.  */
static const unsigned char yystos[] =
{
       0,    75,    78,    79,     0,     4,     5,     6,     7,     8,
      66,    81,    82,     1,     3,    16,    17,    18,    19,    34,
      35,    37,    38,    39,    40,    41,    42,    43,    44,    45,
      46,    47,    48,    49,    50,    51,    52,    53,    54,    55,
      56,    57,    58,    59,    60,    61,    62,    66,    75,    80,
      83,    92,    93,    98,     1,    36,    67,    84,    85,    86,
      87,    88,    89,    90,    91,    76,    76,    99,    94,    82,
       9,    10,    11,    12,    13,    14,    15,     3,    31,    76,
     100,    37,    75,    76,    95,    76,    82,    82,    82,    82,
      82,    82,    82,    32,    68,    69,    70,    71,    72,    73,
      74,    97,    95,    76,    76,    76,    76,    76,    76,    76,
      33,    96,    75,    76,    83,     3,     3,    63,    64,    65,
      83,     3,    76
};

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
#define YYABORT		goto yyabortlab
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
   are run).  */

#ifndef YYLLOC_DEFAULT
# define YYLLOC_DEFAULT(Current, Rhs, N)           \
  Current.first_line   = Rhs[1].first_line;      \
  Current.first_column = Rhs[1].first_column;    \
  Current.last_line    = Rhs[N].last_line;       \
  Current.last_column  = Rhs[N].last_column;
#endif

/* YYLEX -- calling `yylex' with the right arguments.  */

#ifdef YYLEX_PARAM
# define YYLEX	yylex (&yylval, YYLEX_PARAM)
#else
# define YYLEX	yylex (&yylval)
#endif

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
# define YYDSYMPRINT(Args)			\
do {						\
  if (yydebug)					\
    yysymprint Args;				\
} while (0)
/* Nonzero means print parse trace.  It is left uninitialized so that
   multiple parsers can coexist.  */
int yydebug;
#else /* !YYDEBUG */
# define YYDPRINTF(Args)
# define YYDSYMPRINT(Args)
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



#if YYERROR_VERBOSE

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

#endif /* !YYERROR_VERBOSE */



#if YYDEBUG
/*-----------------------------.
| Print this symbol on YYOUT.  |
`-----------------------------*/

static void
#if defined (__STDC__) || defined (__cplusplus)
yysymprint (FILE* yyout, int yytype, YYSTYPE yyvalue)
#else
yysymprint (yyout, yytype, yyvalue)
    FILE* yyout;
    int yytype;
    YYSTYPE yyvalue;
#endif
{
  /* Pacify ``unused variable'' warnings.  */
  (void) yyvalue;

  if (yytype < YYNTOKENS)
    {
      YYFPRINTF (yyout, "token %s (", yytname[yytype]);
# ifdef YYPRINT
      YYPRINT (yyout, yytoknum[yytype], yyvalue);
# endif
    }
  else
    YYFPRINTF (yyout, "nterm %s (", yytname[yytype]);

  switch (yytype)
    {
      default:
        break;
    }
  YYFPRINTF (yyout, ")");
}
#endif /* YYDEBUG. */


/*-----------------------------------------------.
| Release the memory associated to this symbol.  |
`-----------------------------------------------*/

static void
#if defined (__STDC__) || defined (__cplusplus)
yydestruct (int yytype, YYSTYPE yyvalue)
#else
yydestruct (yytype, yyvalue)
    int yytype;
    YYSTYPE yyvalue;
#endif
{
  /* Pacify ``unused variable'' warnings.  */
  (void) yyvalue;

  switch (yytype)
    {
      default:
        break;
    }
}



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
int yyparse (void *YYPARSE_PARAM);
# else
int yyparse (void);
# endif
#endif




int
yyparse (YYPARSE_PARAM_ARG)
     YYPARSE_PARAM_DECL
{
  /* The lookahead symbol.  */
int yychar;

/* The semantic value of the lookahead symbol.  */
YYSTYPE yylval;

/* Number of parse errors so far.  */
int yynerrs;

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

  /* The state stack.  */
  short	yyssa[YYINITDEPTH];
  short *yyss = yyssa;
  register short *yyssp;

  /* The semantic value stack.  */
  YYSTYPE yyvsa[YYINITDEPTH];
  YYSTYPE *yyvs = yyvsa;
  register YYSTYPE *yyvsp;



#define YYPOPSTACK   (yyvsp--, yyssp--)

  YYSIZE_T yystacksize = YYINITDEPTH;

  /* The variables used to return semantic value and location from the
     action routines.  */
  YYSTYPE yyval;


  /* When reducing, the number of symbols on the RHS of the reduced
     rule.  */
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
	   data in use in that stack, in bytes.  This used to be a
	   conditional around just the two extra args, but that might
	   be undefined if yyoverflow is a macro.  */
	yyoverflow ("parser stack overflow",
		    &yyss1, yysize * sizeof (*yyssp),
		    &yyvs1, yysize * sizeof (*yyvsp),

		    &yystacksize);

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

#  undef YYSTACK_RELOCATE
	if (yyss1 != yyssa)
	  YYSTACK_FREE (yyss1);
      }
# endif
#endif /* no yyoverflow */

      yyssp = yyss + yysize - 1;
      yyvsp = yyvs + yysize - 1;


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
  if (yyn == YYPACT_NINF)
    goto yydefault;

  /* Not known => get a lookahead token if don't already have one.  */

  /* yychar is either YYEMPTY or YYEOF
     or a valid token in external form.  */

  if (yychar == YYEMPTY)
    {
      YYDPRINTF ((stderr, "Reading a token: "));
      yychar = YYLEX;
    }

  /* Convert token to internal form (in yychar1) for indexing tables with.  */

  if (yychar <= 0)		/* This means end of input.  */
    {
      yychar1 = 0;
      yychar = YYEOF;		/* Don't call YYLEX any more.  */

      YYDPRINTF ((stderr, "Now at end of input.\n"));
    }
  else
    {
      yychar1 = YYTRANSLATE (yychar);

      /* We have to keep this `#if YYDEBUG', since we use variables
	 which are defined only if `YYDEBUG' is set.  */
      YYDPRINTF ((stderr, "Next token is "));
      YYDSYMPRINT ((stderr, yychar1, yylval));
      YYDPRINTF ((stderr, "\n"));
    }

  /* If the proper action on seeing token YYCHAR1 is to reduce or to
     detect an error, take that action.  */
  yyn += yychar1;
  if (yyn < 0 || YYLAST < yyn || yycheck[yyn] != yychar1)
    goto yydefault;
  yyn = yytable[yyn];
  if (yyn <= 0)
    {
      if (yyn == 0 || yyn == YYTABLE_NINF)
	goto yyerrlab;
      yyn = -yyn;
      goto yyreduce;
    }

  if (yyn == YYFINAL)
    YYACCEPT;

  /* Shift the lookahead token.  */
  YYDPRINTF ((stderr, "Shifting token %d (%s), ",
	      yychar, yytname[yychar1]));

  /* Discard the token being shifted unless it is eof.  */
  if (yychar != YYEOF)
    yychar = YYEMPTY;

  *++yyvsp = yylval;


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

     Otherwise, the following line sets YYVAL to garbage.
     This behavior is undocumented and Bison
     users should not rely upon it.  Assigning to YYVAL
     unconditionally makes the parser a bit smaller, and it avoids a
     GCC warning that YYVAL may be used uninitialized.  */
  yyval = yyvsp[1-yylen];



#if YYDEBUG
  /* We have to keep this `#if YYDEBUG', since we use variables which
     are defined only if `YYDEBUG' is set.  */
  if (yydebug)
    {
      int yyi;

      YYFPRINTF (stderr, "Reducing via rule %d (line %d), ",
		 yyn - 1, yyrline[yyn]);

      /* Print the symbols being reduced, and their result.  */
      for (yyi = yyprhs[yyn]; yyrhs[yyi] >= 0; yyi++)
	YYFPRINTF (stderr, "%s ", yytname[yyrhs[yyi]]);
      YYFPRINTF (stderr, " -> %s\n", yytname[yyr1[yyn]]);
    }
#endif
  switch (yyn)
    {
        case 2:
#line 167 "rtfGrammer.y"
    { GSRTFstart(CTXT); }
    break;

  case 3:
#line 167 "rtfGrammer.y"
    { GSRTFstop(CTXT); }
    break;

  case 5:
#line 170 "rtfGrammer.y"
    { yyval.number = 1; }
    break;

  case 6:
#line 171 "rtfGrammer.y"
    { yyval.number = 2; }
    break;

  case 7:
#line 172 "rtfGrammer.y"
    { yyval.number = 3; }
    break;

  case 8:
#line 173 "rtfGrammer.y"
    { yyval.number = 4; }
    break;

  case 9:
#line 175 "rtfGrammer.y"
    { yyval.number = 1; }
    break;

  case 14:
#line 182 "rtfGrammer.y"
    { GSRTFmangleText(CTXT, yyvsp[0].text); free((void *)yyvsp[0].text); }
    break;

  case 17:
#line 187 "rtfGrammer.y"
    { GSRTFopenBlock(CTXT, NO); }
    break;

  case 18:
#line 187 "rtfGrammer.y"
    { GSRTFcloseBlock(CTXT, NO); }
    break;

  case 19:
#line 188 "rtfGrammer.y"
    { GSRTFopenBlock(CTXT, YES); }
    break;

  case 20:
#line 188 "rtfGrammer.y"
    { GSRTFcloseBlock(CTXT, YES); }
    break;

  case 21:
#line 189 "rtfGrammer.y"
    { GSRTFopenBlock(CTXT, YES); }
    break;

  case 22:
#line 189 "rtfGrammer.y"
    { GSRTFcloseBlock(CTXT, YES); }
    break;

  case 23:
#line 190 "rtfGrammer.y"
    { GSRTFopenBlock(CTXT, YES); }
    break;

  case 24:
#line 190 "rtfGrammer.y"
    { GSRTFcloseBlock(CTXT, YES); }
    break;

  case 25:
#line 191 "rtfGrammer.y"
    { GSRTFopenBlock(CTXT, YES); }
    break;

  case 26:
#line 191 "rtfGrammer.y"
    { GSRTFcloseBlock(CTXT, YES); }
    break;

  case 27:
#line 192 "rtfGrammer.y"
    { GSRTFopenBlock(CTXT, YES); }
    break;

  case 28:
#line 192 "rtfGrammer.y"
    { GSRTFcloseBlock(CTXT, YES); }
    break;

  case 29:
#line 193 "rtfGrammer.y"
    { GSRTFopenBlock(CTXT, YES); }
    break;

  case 30:
#line 193 "rtfGrammer.y"
    { GSRTFcloseBlock(CTXT, YES); }
    break;

  case 31:
#line 194 "rtfGrammer.y"
    { GSRTFopenBlock(CTXT, YES); }
    break;

  case 32:
#line 194 "rtfGrammer.y"
    { GSRTFcloseBlock(CTXT, YES); }
    break;

  case 34:
#line 203 "rtfGrammer.y"
    { int font;
		    
						  if (yyvsp[0].cmd.isEmpty)
						      font = 0;
						  else
						      font = yyvsp[0].cmd.parameter;
						  GSRTFfontNumber(CTXT, font); }
    break;

  case 35:
#line 210 "rtfGrammer.y"
    { int size;

						  if (yyvsp[0].cmd.isEmpty)
						      size = 24;
						  else
						      size = yyvsp[0].cmd.parameter;
						  GSRTFfontSize(CTXT, size); }
    break;

  case 36:
#line 217 "rtfGrammer.y"
    { int width; 
		
		                                  if (yyvsp[0].cmd.isEmpty)
						      width = 12240;
						  else
						      width = yyvsp[0].cmd.parameter;
						  GSRTFpaperWidth(CTXT, width);}
    break;

  case 37:
#line 224 "rtfGrammer.y"
    { int height; 
		
		                                  if (yyvsp[0].cmd.isEmpty)
						      height = 15840;
						  else
						      height = yyvsp[0].cmd.parameter;
						  GSRTFpaperHeight(CTXT, height);}
    break;

  case 38:
#line 231 "rtfGrammer.y"
    { int margin; 
		
		                                  if (yyvsp[0].cmd.isEmpty)
						      margin = 1800;
						  else
						      margin = yyvsp[0].cmd.parameter;
						  GSRTFmarginLeft(CTXT, margin);}
    break;

  case 39:
#line 238 "rtfGrammer.y"
    { int margin; 
		
		                                  if (yyvsp[0].cmd.isEmpty)
						      margin = 1800;
						  else
						      margin = yyvsp[0].cmd.parameter;
						  GSRTFmarginRight(CTXT, margin); }
    break;

  case 40:
#line 245 "rtfGrammer.y"
    { int margin; 
		
		                                  if (yyvsp[0].cmd.isEmpty)
						      margin = 1440;
						  else
						      margin = yyvsp[0].cmd.parameter;
						  GSRTFmarginTop(CTXT, margin); }
    break;

  case 41:
#line 252 "rtfGrammer.y"
    { int margin; 
		
		                                  if (yyvsp[0].cmd.isEmpty)
						      margin = 1440;
						  else
						      margin = yyvsp[0].cmd.parameter;
						  GSRTFmarginButtom(CTXT, margin); }
    break;

  case 42:
#line 259 "rtfGrammer.y"
    { int indent; 
		
		                                  if (yyvsp[0].cmd.isEmpty)
						      indent = 0;
						  else
						      indent = yyvsp[0].cmd.parameter;
						  GSRTFfirstLineIndent(CTXT, indent); }
    break;

  case 43:
#line 266 "rtfGrammer.y"
    { int indent; 
		
		                                  if (yyvsp[0].cmd.isEmpty)
						      indent = 0;
						  else
						      indent = yyvsp[0].cmd.parameter;
						  GSRTFleftIndent(CTXT, indent);}
    break;

  case 44:
#line 273 "rtfGrammer.y"
    { int indent; 
		
		                                  if (yyvsp[0].cmd.isEmpty)
						      indent = 0;
						  else
						      indent = yyvsp[0].cmd.parameter;
						  GSRTFrightIndent(CTXT, indent);}
    break;

  case 45:
#line 280 "rtfGrammer.y"
    { int location; 
		
		                                  if (yyvsp[0].cmd.isEmpty)
						      location = 0;
						  else
						      location = yyvsp[0].cmd.parameter;
						  GSRTFtabstop(CTXT, location);}
    break;

  case 46:
#line 287 "rtfGrammer.y"
    { GSRTFalignCenter(CTXT); }
    break;

  case 47:
#line 288 "rtfGrammer.y"
    { GSRTFalignJustified(CTXT); }
    break;

  case 48:
#line 289 "rtfGrammer.y"
    { GSRTFalignLeft(CTXT); }
    break;

  case 49:
#line 290 "rtfGrammer.y"
    { GSRTFalignRight(CTXT); }
    break;

  case 50:
#line 291 "rtfGrammer.y"
    { int space; 
		
		                                  if (yyvsp[0].cmd.isEmpty)
						      space = 0;
						  else
						      space = yyvsp[0].cmd.parameter;
						  GSRTFspaceAbove(CTXT, space); }
    break;

  case 51:
#line 298 "rtfGrammer.y"
    { GSRTFlineSpace(CTXT, yyvsp[0].cmd.parameter); }
    break;

  case 52:
#line 299 "rtfGrammer.y"
    { GSRTFdefaultParagraph(CTXT); }
    break;

  case 53:
#line 300 "rtfGrammer.y"
    { GSRTFstyle(CTXT, yyvsp[0].cmd.parameter); }
    break;

  case 54:
#line 301 "rtfGrammer.y"
    { int color; 
		
		                                  if (yyvsp[0].cmd.isEmpty)
						      color = 0;
						  else
						      color = yyvsp[0].cmd.parameter;
						  GSRTFcolorbg(CTXT, color); }
    break;

  case 55:
#line 308 "rtfGrammer.y"
    { int color; 
		
		                                  if (yyvsp[0].cmd.isEmpty)
						      color = 0;
						  else
						      color = yyvsp[0].cmd.parameter;
						  GSRTFcolorfg(CTXT, color); }
    break;

  case 56:
#line 315 "rtfGrammer.y"
    { int script;
		
		                                  if (yyvsp[0].cmd.isEmpty)
						      script = 6;
						  else
						      script = yyvsp[0].cmd.parameter;
						  GSRTFsubscript(CTXT, script); }
    break;

  case 57:
#line 322 "rtfGrammer.y"
    { int script;
		
		                                  if (yyvsp[0].cmd.isEmpty)
						      script = 6;
						  else
						      script = yyvsp[0].cmd.parameter;
						  GSRTFsuperscript(CTXT, script); }
    break;

  case 58:
#line 329 "rtfGrammer.y"
    { BOOL on;

		                                  if (yyvsp[0].cmd.isEmpty || yyvsp[0].cmd.parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFbold(CTXT, on); }
    break;

  case 59:
#line 336 "rtfGrammer.y"
    { BOOL on;

		                                  if (yyvsp[0].cmd.isEmpty || yyvsp[0].cmd.parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFitalic(CTXT, on); }
    break;

  case 60:
#line 343 "rtfGrammer.y"
    { BOOL on;

		                                  if (yyvsp[0].cmd.isEmpty || yyvsp[0].cmd.parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFunderline(CTXT, on); }
    break;

  case 61:
#line 350 "rtfGrammer.y"
    { GSRTFunderline(CTXT, NO); }
    break;

  case 62:
#line 351 "rtfGrammer.y"
    { GSRTFunicode(CTXT, yyvsp[0].cmd.parameter); }
    break;

  case 63:
#line 352 "rtfGrammer.y"
    { GSRTFdefaultCharacterStyle(CTXT); }
    break;

  case 64:
#line 353 "rtfGrammer.y"
    { GSRTFparagraph(CTXT); }
    break;

  case 65:
#line 354 "rtfGrammer.y"
    { GSRTFparagraph(CTXT); }
    break;

  case 66:
#line 355 "rtfGrammer.y"
    { GSRTFgenericRTFcommand(CTXT, yyvsp[0].cmd); }
    break;

  case 71:
#line 369 "rtfGrammer.y"
    { free((void *)yyvsp[-1].text);}
    break;

  case 72:
#line 374 "rtfGrammer.y"
    { GSRTFregisterFont(CTXT, yyvsp[0].text, yyvsp[-2].number, yyvsp[-3].cmd.parameter);
                                                          free((void *)yyvsp[0].text); }
    break;

  case 78:
#line 387 "rtfGrammer.y"
    { yyval.number = RTFfamilyNil - RTFfamilyNil; }
    break;

  case 79:
#line 388 "rtfGrammer.y"
    { yyval.number = RTFfamilyRoman - RTFfamilyNil; }
    break;

  case 80:
#line 389 "rtfGrammer.y"
    { yyval.number = RTFfamilySwiss - RTFfamilyNil; }
    break;

  case 81:
#line 390 "rtfGrammer.y"
    { yyval.number = RTFfamilyModern - RTFfamilyNil; }
    break;

  case 82:
#line 391 "rtfGrammer.y"
    { yyval.number = RTFfamilyScript - RTFfamilyNil; }
    break;

  case 83:
#line 392 "rtfGrammer.y"
    { yyval.number = RTFfamilyDecor - RTFfamilyNil; }
    break;

  case 84:
#line 393 "rtfGrammer.y"
    { yyval.number = RTFfamilyTech - RTFfamilyNil; }
    break;

  case 88:
#line 410 "rtfGrammer.y"
    { 
		       GSRTFaddColor(CTXT, yyvsp[-3].cmd.parameter, yyvsp[-2].cmd.parameter, yyvsp[-1].cmd.parameter);
		       free((void *)yyvsp[0].text);
		     }
    break;

  case 89:
#line 415 "rtfGrammer.y"
    { 
		       GSRTFaddDefaultColor(CTXT);
		       free((void *)yyvsp[0].text);
		     }
    break;


    }

/* Line 1016 of /usr/share/bison/yacc.c.  */
#line 1839 "rtfGrammer.tab.c"

  yyvsp -= yylen;
  yyssp -= yylen;


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


  /* Now `shift' the result of the reduction.  Determine what state
     that goes to, based on the state we popped back to and the rule
     number reduced by.  */

  yyn = yyr1[yyn];

  yystate = yypgoto[yyn - YYNTOKENS] + *yyssp;
  if (0 <= yystate && yystate <= YYLAST && yycheck[yystate] == *yyssp)
    yystate = yytable[yystate];
  else
    yystate = yydefgoto[yyn - YYNTOKENS];

  goto yynewstate;


/*------------------------------------.
| yyerrlab -- here on detecting error |
`------------------------------------*/
yyerrlab:
  /* If not already recovering from an error, report this error.  */
  if (!yyerrstatus)
    {
      ++yynerrs;
#if YYERROR_VERBOSE
      yyn = yypact[yystate];

      if (YYPACT_NINF < yyn && yyn < YYLAST)
	{
	  YYSIZE_T yysize = 0;
	  int yytype = YYTRANSLATE (yychar);
	  char *yymsg;
	  int yyx, yycount;

	  yycount = 0;
	  /* Start YYX at -YYN if negative to avoid negative indexes in
	     YYCHECK.  */
	  for (yyx = yyn < 0 ? -yyn : 0;
	       yyx < (int) (sizeof (yytname) / sizeof (char *)); yyx++)
	    if (yycheck[yyx + yyn] == yyx && yyx != YYTERROR)
	      yysize += yystrlen (yytname[yyx]) + 15, yycount++;
	  yysize += yystrlen ("parse error, unexpected ") + 1;
	  yysize += yystrlen (yytname[yytype]);
	  yymsg = (char *) YYSTACK_ALLOC (yysize);
	  if (yymsg != 0)
	    {
	      char *yyp = yystpcpy (yymsg, "parse error, unexpected ");
	      yyp = yystpcpy (yyp, yytname[yytype]);

	      if (yycount < 5)
		{
		  yycount = 0;
		  for (yyx = yyn < 0 ? -yyn : 0;
		       yyx < (int) (sizeof (yytname) / sizeof (char *));
		       yyx++)
		    if (yycheck[yyx + yyn] == yyx && yyx != YYTERROR)
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
#endif /* YYERROR_VERBOSE */
	yyerror ("parse error");
    }
  goto yyerrlab1;


/*----------------------------------------------------.
| yyerrlab1 -- error raised explicitly by an action.  |
`----------------------------------------------------*/
yyerrlab1:
  if (yyerrstatus == 3)
    {
      /* If just tried and failed to reuse lookahead token after an
	 error, discard it.  */

      /* Return failure if at end of input.  */
      if (yychar == YYEOF)
        {
	  /* Pop the error token.  */
          YYPOPSTACK;
	  /* Pop the rest of the stack.  */
	  while (yyssp > yyss)
	    {
	      YYDPRINTF ((stderr, "Error: popping "));
	      YYDSYMPRINT ((stderr,
			    yystos[*yyssp],
			    *yyvsp));
	      YYDPRINTF ((stderr, "\n"));
	      yydestruct (yystos[*yyssp], *yyvsp);
	      YYPOPSTACK;
	    }
	  YYABORT;
        }

      YYDPRINTF ((stderr, "Discarding token %d (%s).\n",
		  yychar, yytname[yychar1]));
      yydestruct (yychar1, yylval);
      yychar = YYEMPTY;
    }

  /* Else will try to reuse lookahead token after shifting the error
     token.  */

  yyerrstatus = 3;	/* Each real token shifted decrements this.  */

  for (;;)
    {
      yyn = yypact[yystate];
      if (yyn != YYPACT_NINF)
	{
	  yyn += YYTERROR;
	  if (0 <= yyn && yyn <= YYLAST && yycheck[yyn] == YYTERROR)
	    {
	      yyn = yytable[yyn];
	      if (0 < yyn)
		break;
	    }
	}

      /* Pop the current state because it cannot handle the error token.  */
      if (yyssp == yyss)
	YYABORT;

      YYDPRINTF ((stderr, "Error: popping "));
      YYDSYMPRINT ((stderr,
		    yystos[*yyssp], *yyvsp));
      YYDPRINTF ((stderr, "\n"));

      yydestruct (yystos[yystate], *yyvsp);
      yyvsp--;
      yystate = *--yyssp;


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
    }

  if (yyn == YYFINAL)
    YYACCEPT;

  YYDPRINTF ((stderr, "Shifting error token, "));

  *++yyvsp = yylval;


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

#ifndef yyoverflow
/*----------------------------------------------.
| yyoverflowlab -- parser overflow comes here.  |
`----------------------------------------------*/
yyoverflowlab:
  yyerror ("parser stack overflow");
  yyresult = 2;
  /* Fall through.  */
#endif

yyreturn:
#ifndef yyoverflow
  if (yyss != yyssa)
    YYSTACK_FREE (yyss);
#endif
  return yyresult;
}


#line 427 "rtfGrammer.y"


/*	some C code here	*/


