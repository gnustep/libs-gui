/* A Bison parser, made by GNU Bison 1.875.  */

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
#define YYBISON 1

/* Skeleton name.  */
#define YYSKELETON_NAME "yacc.c"

/* Pure parsers.  */
#define YYPURE 1

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
     RTFsubscript = 314,
     RTFsuperscript = 315,
     RTFtabstop = 316,
     RTFfcharset = 317,
     RTFfprq = 318,
     RTFcpg = 319,
     RTFOtherStatement = 320,
     RTFfontListStart = 321,
     RTFfamilyNil = 322,
     RTFfamilyRoman = 323,
     RTFfamilySwiss = 324,
     RTFfamilyModern = 325,
     RTFfamilyScript = 326,
     RTFfamilyDecor = 327,
     RTFfamilyTech = 328
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
#define RTFsubscript 314
#define RTFsuperscript 315
#define RTFtabstop 316
#define RTFfcharset 317
#define RTFfprq 318
#define RTFcpg 319
#define RTFOtherStatement 320
#define RTFfontListStart 321
#define RTFfamilyNil 322
#define RTFfamilyRoman 323
#define RTFfamilySwiss 324
#define RTFfamilyModern 325
#define RTFfamilyScript 326
#define RTFfamilyDecor 327
#define RTFfamilyTech 328




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

#if ! defined (YYSTYPE) && ! defined (YYSTYPE_IS_DECLARED)
#line 77 "rtfGrammer.y"
typedef union YYSTYPE {
	int		number;
	const char	*text;
	RTFcmd		cmd;
} YYSTYPE;
/* Line 191 of yacc.c.  */
#line 278 "rtfGrammer.tab.c"
# define yystype YYSTYPE /* obsolescent; will be withdrawn */
# define YYSTYPE_IS_DECLARED 1
# define YYSTYPE_IS_TRIVIAL 1
#endif



/* Copy the second part of user declarations.  */


/* Line 214 of yacc.c.  */
#line 290 "rtfGrammer.tab.c"

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
	 || (YYSTYPE_IS_TRIVIAL)))

/* A type that is properly aligned for any stack member.  */
union yyalloc
{
  short yyss;
  YYSTYPE yyvs;
  };

/* The size of the maximum gap between one aligned stack and the next.  */
# define YYSTACK_GAP_MAXIMUM (sizeof (union yyalloc) - 1)

/* The size of an array large to enough to hold all stacks, each with
   N elements.  */
# define YYSTACK_BYTES(N) \
     ((N) * (sizeof (short) + sizeof (YYSTYPE))				\
      + YYSTACK_GAP_MAXIMUM)

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
	yynewbytes = yystacksize * sizeof (*Stack) + YYSTACK_GAP_MAXIMUM; \
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
/* YYLAST -- Last index in YYTABLE.  */
#define YYLAST   690

/* YYNTOKENS -- Number of terminals. */
#define YYNTOKENS  76
/* YYNNTS -- Number of nonterminals. */
#define YYNNTS  24
/* YYNRULES -- Number of rules. */
#define YYNRULES  88
/* YYNRULES -- Number of states. */
#define YYNSTATES  122

/* YYTRANSLATE(YYLEX) -- Bison symbol number corresponding to YYLEX.  */
#define YYUNDEFTOK  2
#define YYMAXUTOK   328

#define YYTRANSLATE(YYX) 						\
  ((unsigned int) (YYX) <= YYMAXUTOK ? yytranslate[YYX] : YYUNDEFTOK)

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
       2,     2,     2,     2,     2,     2,     1,     2,     3,     4,
       5,     6,     7,     8,     9,    10,    11,    12,    13,    14,
      15,    16,    17,    18,    19,    20,    21,    22,    23,    24,
      25,    26,    27,    28,    29,    30,    31,    32,    33,    34,
      35,    36,    37,    38,    39,    40,    41,    42,    43,    44,
      45,    46,    47,    48,    49,    50,    51,    52,    53,    54,
      55,    56,    57,    58,    59,    60,    61,    62,    63,    64,
      65,    66,    67,    68,    69,    70,    71,    72,    73
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
     153,   155,   157,   159,   161,   163,   165,   170,   171,   174,
     179,   186,   191,   192,   195,   198,   201,   204,   206,   208,
     210,   212,   214,   216,   218,   223,   224,   227,   232
};

/* YYRHS -- A `-1'-separated list of the rules' RHS. */
static const yysigned_char yyrhs[] =
{
      77,     0,    -1,    -1,    -1,    74,    78,     4,    80,    81,
      79,    75,    -1,     5,    -1,     6,    -1,     7,    -1,     8,
      -1,    65,    -1,    -1,    81,    92,    -1,    81,    97,    -1,
      81,    91,    -1,    81,     3,    -1,    81,    82,    -1,    81,
       1,    -1,    -1,    74,    83,    81,    75,    -1,    -1,    74,
      84,     9,    81,    75,    -1,    -1,    74,    85,    10,    81,
      75,    -1,    -1,    74,    86,    11,    81,    75,    -1,    -1,
      74,    87,    12,    81,    75,    -1,    -1,    74,    88,    13,
      81,    75,    -1,    -1,    74,    89,    14,    81,    75,    -1,
      -1,    74,    90,    15,    81,    75,    -1,    74,     1,    75,
      -1,    37,    -1,    38,    -1,    39,    -1,    40,    -1,    41,
      -1,    42,    -1,    43,    -1,    44,    -1,    45,    -1,    46,
      -1,    47,    -1,    61,    -1,    48,    -1,    49,    -1,    50,
      -1,    51,    -1,    53,    -1,    52,    -1,    18,    -1,    54,
      -1,    34,    -1,    35,    -1,    59,    -1,    60,    -1,    55,
      -1,    56,    -1,    57,    -1,    58,    -1,    16,    -1,    17,
      -1,    19,    -1,    65,    -1,    74,    66,    93,    75,    -1,
      -1,    93,    94,    -1,    93,    74,    94,    75,    -1,    93,
      74,    94,    82,     3,    75,    -1,    37,    96,    95,     3,
      -1,    -1,    95,    62,    -1,    95,    63,    -1,    95,    64,
      -1,    95,    82,    -1,    67,    -1,    68,    -1,    69,    -1,
      70,    -1,    71,    -1,    72,    -1,    73,    -1,    74,    36,
      98,    75,    -1,    -1,    98,    99,    -1,    31,    32,    33,
       3,    -1,     3,    -1
};

/* YYRLINE[YYN] -- source line where rule number YYN was defined.  */
static const unsigned short yyrline[] =
{
       0,   166,   166,   166,   166,   169,   170,   171,   172,   174,
     177,   178,   179,   180,   181,   182,   183,   186,   186,   187,
     187,   188,   188,   189,   189,   190,   190,   191,   191,   192,
     192,   193,   193,   194,   202,   209,   216,   223,   230,   237,
     244,   251,   258,   265,   272,   279,   286,   287,   288,   289,
     290,   297,   298,   299,   300,   307,   314,   321,   328,   335,
     342,   349,   350,   351,   352,   353,   360,   363,   364,   365,
     366,   372,   376,   377,   378,   379,   380,   385,   386,   387,
     388,   389,   390,   391,   399,   402,   403,   407,   412
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
  "RTFitalic", "RTFunderline", "RTFunderlineStop", "RTFsubscript", 
  "RTFsuperscript", "RTFtabstop", "RTFfcharset", "RTFfprq", "RTFcpg", 
  "RTFOtherStatement", "RTFfontListStart", "RTFfamilyNil", 
  "RTFfamilyRoman", "RTFfamilySwiss", "RTFfamilyModern", 
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
     325,   326,   327,   328,   123,   125
};
# endif

/* YYR1[YYN] -- Symbol number of symbol that rule YYN derives.  */
static const unsigned char yyr1[] =
{
       0,    76,    78,    79,    77,    80,    80,    80,    80,    80,
      81,    81,    81,    81,    81,    81,    81,    83,    82,    84,
      82,    85,    82,    86,    82,    87,    82,    88,    82,    89,
      82,    90,    82,    82,    91,    91,    91,    91,    91,    91,
      91,    91,    91,    91,    91,    91,    91,    91,    91,    91,
      91,    91,    91,    91,    91,    91,    91,    91,    91,    91,
      91,    91,    91,    91,    91,    91,    92,    93,    93,    93,
      93,    94,    95,    95,    95,    95,    95,    96,    96,    96,
      96,    96,    96,    96,    97,    98,    98,    99,    99
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
       1,     1,     1,     1,     1,     1,     4,     0,     2,     4,
       6,     4,     0,     2,     2,     2,     2,     1,     1,     1,
       1,     1,     1,     1,     4,     0,     2,     4,     1
};

/* YYDEFACT[STATE-NAME] -- Default rule to reduce with in state
   STATE-NUM when YYTABLE doesn't specify something else to do.  Zero
   means the default is an error.  */
static const unsigned char yydefact[] =
{
       0,     2,     0,     0,     1,     0,     5,     6,     7,     8,
       9,    10,     0,    16,    14,    62,    63,    52,    64,    54,
      55,    34,    35,    36,    37,    38,    39,    40,    41,    42,
      43,    44,    46,    47,    48,    49,    51,    50,    53,    58,
      59,    60,    61,    56,    57,    45,    65,     0,     0,    15,
      13,    11,    12,     0,    85,    67,    10,     0,     0,     0,
       0,     0,     0,     0,     4,    33,     0,     0,     0,    10,
      10,    10,    10,    10,    10,    10,    88,     0,    84,    86,
       0,     0,    66,    68,    18,     0,     0,     0,     0,     0,
       0,     0,     0,    77,    78,    79,    80,    81,    82,    83,
      72,     0,    20,    22,    24,    26,    28,    30,    32,     0,
       0,     0,    69,     0,    87,    71,    73,    74,    75,    76,
       0,    70
};

/* YYDEFGOTO[NTERM-NUM]. */
static const yysigned_char yydefgoto[] =
{
      -1,     2,     3,    48,    11,    12,    49,    56,    57,    58,
      59,    60,    61,    62,    63,    50,    51,    67,    83,   110,
     100,    52,    66,    79
};

/* YYPACT[STATE-NUM] -- Index in YYTABLE of the portion describing
   STATE-NUM.  */
#define YYPACT_NINF -83
static const short yypact[] =
{
     -73,   -83,    31,    28,   -83,    -2,   -83,   -83,   -83,   -83,
     -83,   -83,   127,   -83,   -83,   -83,   -83,   -83,   -83,   -83,
     -83,   -83,   -83,   -83,   -83,   -83,   -83,   -83,   -83,   -83,
     -83,   -83,   -83,   -83,   -83,   -83,   -83,   -83,   -83,   -83,
     -83,   -83,   -83,   -83,   -83,   -83,   -83,    -1,   -13,   -83,
     -83,   -83,   -83,    -9,   -83,   -83,   -83,    59,    61,    88,
      90,    57,   115,   117,   -83,   -83,    58,    60,   188,   -83,
     -83,   -83,   -83,   -83,   -83,   -83,   -83,    40,   -83,   -83,
      23,    99,   -83,   -83,   -83,   249,   310,   371,   432,   493,
     554,   615,   104,   -83,   -83,   -83,   -83,   -83,   -83,   -83,
     -83,   -45,   -83,   -83,   -83,   -83,   -83,   -83,   -83,   135,
      24,    66,   -83,   136,   -83,   -83,   -83,   -83,   -83,   -83,
      67,   -83
};

/* YYPGOTO[NTERM-NUM].  */
static const yysigned_char yypgoto[] =
{
     -83,   -83,   -83,   -83,   -83,   -49,   -82,   -83,   -83,   -83,
     -83,   -83,   -83,   -83,   -83,   -83,   -83,   -83,    68,   -83,
     -83,   -83,   -83,   -83
};

/* YYTABLE[YYPACT[STATE-NUM]].  What to do in state STATE-NUM.  If
   positive, shift that token.  If negative, reduce the rule which
   number is the opposite.  If zero, do what YYDEFACT says.
   If YYTABLE_NINF, syntax error.  */
#define YYTABLE_NINF -32
static const yysigned_char yytable[] =
{
      53,     1,   -17,     6,     7,     8,     9,    68,   -19,   -21,
     -23,   -25,   -27,   -29,   -31,   -17,   -17,   -17,   -17,   113,
      85,    86,    87,    88,    89,    90,    91,   115,   119,   111,
     112,     4,     5,   -17,   -17,    54,   -17,   -17,   -17,   -17,
     -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,
     -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,
     -17,    76,    64,    10,   -17,    55,    65,    53,    69,   -17,
      73,    70,    92,   -17,   -17,   -19,   -21,   -23,   -25,   -27,
     -29,   -31,   -17,   -17,   -17,   -17,   116,   117,   118,    77,
      93,    94,    95,    96,    97,    98,    99,    80,   111,    71,
     -17,   -17,    72,   -17,   -17,   -17,   -17,   -17,   -17,   -17,
     -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,
     -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,    13,    74,
      14,   -17,    75,    78,    81,    82,    80,   109,   114,   120,
     -17,   -17,   121,    15,    16,    17,    18,     0,     0,   101,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,    19,    20,     0,    21,    22,    23,    24,    25,    26,
      27,    28,    29,    30,    31,    32,    33,    34,    35,    36,
      37,    38,    39,    40,    41,    42,    43,    44,    45,    13,
       0,    14,    46,     0,     0,     0,     0,     0,     0,     0,
       0,    47,    -3,     0,    15,    16,    17,    18,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,    19,    20,     0,    21,    22,    23,    24,    25,
      26,    27,    28,    29,    30,    31,    32,    33,    34,    35,
      36,    37,    38,    39,    40,    41,    42,    43,    44,    45,
      13,     0,    14,    46,     0,     0,     0,     0,     0,     0,
       0,     0,    47,    84,     0,    15,    16,    17,    18,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,    19,    20,     0,    21,    22,    23,    24,
      25,    26,    27,    28,    29,    30,    31,    32,    33,    34,
      35,    36,    37,    38,    39,    40,    41,    42,    43,    44,
      45,    13,     0,    14,    46,     0,     0,     0,     0,     0,
       0,     0,     0,    47,   102,     0,    15,    16,    17,    18,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,    19,    20,     0,    21,    22,    23,
      24,    25,    26,    27,    28,    29,    30,    31,    32,    33,
      34,    35,    36,    37,    38,    39,    40,    41,    42,    43,
      44,    45,    13,     0,    14,    46,     0,     0,     0,     0,
       0,     0,     0,     0,    47,   103,     0,    15,    16,    17,
      18,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,    19,    20,     0,    21,    22,
      23,    24,    25,    26,    27,    28,    29,    30,    31,    32,
      33,    34,    35,    36,    37,    38,    39,    40,    41,    42,
      43,    44,    45,    13,     0,    14,    46,     0,     0,     0,
       0,     0,     0,     0,     0,    47,   104,     0,    15,    16,
      17,    18,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,    19,    20,     0,    21,
      22,    23,    24,    25,    26,    27,    28,    29,    30,    31,
      32,    33,    34,    35,    36,    37,    38,    39,    40,    41,
      42,    43,    44,    45,    13,     0,    14,    46,     0,     0,
       0,     0,     0,     0,     0,     0,    47,   105,     0,    15,
      16,    17,    18,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,    19,    20,     0,
      21,    22,    23,    24,    25,    26,    27,    28,    29,    30,
      31,    32,    33,    34,    35,    36,    37,    38,    39,    40,
      41,    42,    43,    44,    45,    13,     0,    14,    46,     0,
       0,     0,     0,     0,     0,     0,     0,    47,   106,     0,
      15,    16,    17,    18,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,    19,    20,
       0,    21,    22,    23,    24,    25,    26,    27,    28,    29,
      30,    31,    32,    33,    34,    35,    36,    37,    38,    39,
      40,    41,    42,    43,    44,    45,    13,     0,    14,    46,
       0,     0,     0,     0,     0,     0,     0,     0,    47,   107,
       0,    15,    16,    17,    18,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,    19,
      20,     0,    21,    22,    23,    24,    25,    26,    27,    28,
      29,    30,    31,    32,    33,    34,    35,    36,    37,    38,
      39,    40,    41,    42,    43,    44,    45,     0,     0,     0,
      46,     0,     0,     0,     0,     0,     0,     0,     0,    47,
     108
};

static const yysigned_char yycheck[] =
{
       1,    74,     3,     5,     6,     7,     8,    56,     9,    10,
      11,    12,    13,    14,    15,    16,    17,    18,    19,   101,
      69,    70,    71,    72,    73,    74,    75,     3,   110,    74,
      75,     0,     4,    34,    35,    36,    37,    38,    39,    40,
      41,    42,    43,    44,    45,    46,    47,    48,    49,    50,
      51,    52,    53,    54,    55,    56,    57,    58,    59,    60,
      61,     3,    75,    65,    65,    66,    75,     1,     9,     3,
      13,    10,    32,    74,    75,     9,    10,    11,    12,    13,
      14,    15,    16,    17,    18,    19,    62,    63,    64,    31,
      67,    68,    69,    70,    71,    72,    73,    37,    74,    11,
      34,    35,    12,    37,    38,    39,    40,    41,    42,    43,
      44,    45,    46,    47,    48,    49,    50,    51,    52,    53,
      54,    55,    56,    57,    58,    59,    60,    61,     1,    14,
       3,    65,    15,    75,    74,    75,    37,    33,     3,     3,
      74,    75,    75,    16,    17,    18,    19,    -1,    -1,    81,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    34,    35,    -1,    37,    38,    39,    40,    41,    42,
      43,    44,    45,    46,    47,    48,    49,    50,    51,    52,
      53,    54,    55,    56,    57,    58,    59,    60,    61,     1,
      -1,     3,    65,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    74,    75,    -1,    16,    17,    18,    19,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    34,    35,    -1,    37,    38,    39,    40,    41,
      42,    43,    44,    45,    46,    47,    48,    49,    50,    51,
      52,    53,    54,    55,    56,    57,    58,    59,    60,    61,
       1,    -1,     3,    65,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    74,    75,    -1,    16,    17,    18,    19,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    34,    35,    -1,    37,    38,    39,    40,
      41,    42,    43,    44,    45,    46,    47,    48,    49,    50,
      51,    52,    53,    54,    55,    56,    57,    58,    59,    60,
      61,     1,    -1,     3,    65,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    74,    75,    -1,    16,    17,    18,    19,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    34,    35,    -1,    37,    38,    39,
      40,    41,    42,    43,    44,    45,    46,    47,    48,    49,
      50,    51,    52,    53,    54,    55,    56,    57,    58,    59,
      60,    61,     1,    -1,     3,    65,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    74,    75,    -1,    16,    17,    18,
      19,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    34,    35,    -1,    37,    38,
      39,    40,    41,    42,    43,    44,    45,    46,    47,    48,
      49,    50,    51,    52,    53,    54,    55,    56,    57,    58,
      59,    60,    61,     1,    -1,     3,    65,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    74,    75,    -1,    16,    17,
      18,    19,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    34,    35,    -1,    37,
      38,    39,    40,    41,    42,    43,    44,    45,    46,    47,
      48,    49,    50,    51,    52,    53,    54,    55,    56,    57,
      58,    59,    60,    61,     1,    -1,     3,    65,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    74,    75,    -1,    16,
      17,    18,    19,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    34,    35,    -1,
      37,    38,    39,    40,    41,    42,    43,    44,    45,    46,
      47,    48,    49,    50,    51,    52,    53,    54,    55,    56,
      57,    58,    59,    60,    61,     1,    -1,     3,    65,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    74,    75,    -1,
      16,    17,    18,    19,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    34,    35,
      -1,    37,    38,    39,    40,    41,    42,    43,    44,    45,
      46,    47,    48,    49,    50,    51,    52,    53,    54,    55,
      56,    57,    58,    59,    60,    61,     1,    -1,     3,    65,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    74,    75,
      -1,    16,    17,    18,    19,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    34,
      35,    -1,    37,    38,    39,    40,    41,    42,    43,    44,
      45,    46,    47,    48,    49,    50,    51,    52,    53,    54,
      55,    56,    57,    58,    59,    60,    61,    -1,    -1,    -1,
      65,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    74,
      75
};

/* YYSTOS[STATE-NUM] -- The (internal number of the) accessing
   symbol of state STATE-NUM.  */
static const unsigned char yystos[] =
{
       0,    74,    77,    78,     0,     4,     5,     6,     7,     8,
      65,    80,    81,     1,     3,    16,    17,    18,    19,    34,
      35,    37,    38,    39,    40,    41,    42,    43,    44,    45,
      46,    47,    48,    49,    50,    51,    52,    53,    54,    55,
      56,    57,    58,    59,    60,    61,    65,    74,    79,    82,
      91,    92,    97,     1,    36,    66,    83,    84,    85,    86,
      87,    88,    89,    90,    75,    75,    98,    93,    81,     9,
      10,    11,    12,    13,    14,    15,     3,    31,    75,    99,
      37,    74,    75,    94,    75,    81,    81,    81,    81,    81,
      81,    81,    32,    67,    68,    69,    70,    71,    72,    73,
      96,    94,    75,    75,    75,    75,    75,    75,    75,    33,
      95,    74,    75,    82,     3,     3,    62,    63,    64,    82,
       3,    75
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
#define YYEMPTY		(-2)
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
      yytoken = YYTRANSLATE (yychar);				\
      YYPOPSTACK;						\
      goto yybackup;						\
    }								\
  else								\
    { 								\
      yyerror ("syntax error: cannot back up");\
      YYERROR;							\
    }								\
while (0)

#define YYTERROR	1
#define YYERRCODE	256

/* YYLLOC_DEFAULT -- Compute the default location (before the actions
   are run).  */

#ifndef YYLLOC_DEFAULT
# define YYLLOC_DEFAULT(Current, Rhs, N)         \
  Current.first_line   = Rhs[1].first_line;      \
  Current.first_column = Rhs[1].first_column;    \
  Current.last_line    = Rhs[N].last_line;       \
  Current.last_column  = Rhs[N].last_column;
#endif

/* YYLEX -- calling `yylex' with the right arguments.  */

#ifdef YYLEX_PARAM
# define YYLEX yylex (&yylval, YYLEX_PARAM)
#else
# define YYLEX yylex (&yylval)
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

# define YYDSYMPRINTF(Title, Token, Value, Location)		\
do {								\
  if (yydebug)							\
    {								\
      YYFPRINTF (stderr, "%s ", Title);				\
      yysymprint (stderr, 					\
                  Token, Value);	\
      YYFPRINTF (stderr, "\n");					\
    }								\
} while (0)

/*------------------------------------------------------------------.
| yy_stack_print -- Print the state stack from its BOTTOM up to its |
| TOP (cinluded).                                                   |
`------------------------------------------------------------------*/

#if defined (__STDC__) || defined (__cplusplus)
static void
yy_stack_print (short *bottom, short *top)
#else
static void
yy_stack_print (bottom, top)
    short *bottom;
    short *top;
#endif
{
  YYFPRINTF (stderr, "Stack now");
  for (/* Nothing. */; bottom <= top; ++bottom)
    YYFPRINTF (stderr, " %d", *bottom);
  YYFPRINTF (stderr, "\n");
}

# define YY_STACK_PRINT(Bottom, Top)				\
do {								\
  if (yydebug)							\
    yy_stack_print ((Bottom), (Top));				\
} while (0)


/*------------------------------------------------.
| Report that the YYRULE is going to be reduced.  |
`------------------------------------------------*/

#if defined (__STDC__) || defined (__cplusplus)
static void
yy_reduce_print (int yyrule)
#else
static void
yy_reduce_print (yyrule)
    int yyrule;
#endif
{
  int yyi;
  unsigned int yylineno = yyrline[yyrule];
  YYFPRINTF (stderr, "Reducing stack by rule %d (line %u), ",
             yyrule - 1, yylineno);
  /* Print the symbols being reduced, and their result.  */
  for (yyi = yyprhs[yyrule]; 0 <= yyrhs[yyi]; yyi++)
    YYFPRINTF (stderr, "%s ", yytname [yyrhs[yyi]]);
  YYFPRINTF (stderr, "-> %s\n", yytname [yyr1[yyrule]]);
}

# define YY_REDUCE_PRINT(Rule)		\
do {					\
  if (yydebug)				\
    yy_reduce_print (Rule);		\
} while (0)

/* Nonzero means print parse trace.  It is left uninitialized so that
   multiple parsers can coexist.  */
int yydebug;
#else /* !YYDEBUG */
# define YYDPRINTF(Args)
# define YYDSYMPRINT(Args)
# define YYDSYMPRINTF(Title, Token, Value, Location)
# define YY_STACK_PRINT(Bottom, Top)
# define YY_REDUCE_PRINT(Rule)
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
/*--------------------------------.
| Print this symbol on YYOUTPUT.  |
`--------------------------------*/

#if defined (__STDC__) || defined (__cplusplus)
static void
yysymprint (FILE *yyoutput, int yytype, YYSTYPE *yyvaluep)
#else
static void
yysymprint (yyoutput, yytype, yyvaluep)
    FILE *yyoutput;
    int yytype;
    YYSTYPE *yyvaluep;
#endif
{
  /* Pacify ``unused variable'' warnings.  */
  (void) yyvaluep;

  if (yytype < YYNTOKENS)
    {
      YYFPRINTF (yyoutput, "token %s (", yytname[yytype]);
# ifdef YYPRINT
      YYPRINT (yyoutput, yytoknum[yytype], *yyvaluep);
# endif
    }
  else
    YYFPRINTF (yyoutput, "nterm %s (", yytname[yytype]);

  switch (yytype)
    {
      default:
        break;
    }
  YYFPRINTF (yyoutput, ")");
}

#endif /* ! YYDEBUG */
/*-----------------------------------------------.
| Release the memory associated to this symbol.  |
`-----------------------------------------------*/

#if defined (__STDC__) || defined (__cplusplus)
static void
yydestruct (int yytype, YYSTYPE *yyvaluep)
#else
static void
yydestruct (yytype, yyvaluep)
    int yytype;
    YYSTYPE *yyvaluep;
#endif
{
  /* Pacify ``unused variable'' warnings.  */
  (void) yyvaluep;

  switch (yytype)
    {

      default:
        break;
    }
}


/* Prevent warnings from -Wmissing-prototypes.  */

#ifdef YYPARSE_PARAM
# if defined (__STDC__) || defined (__cplusplus)
int yyparse (void *YYPARSE_PARAM);
# else
int yyparse ();
# endif
#else /* ! YYPARSE_PARAM */
#if defined (__STDC__) || defined (__cplusplus)
int yyparse (void);
#else
int yyparse ();
#endif
#endif /* ! YYPARSE_PARAM */






/*----------.
| yyparse.  |
`----------*/

#ifdef YYPARSE_PARAM
# if defined (__STDC__) || defined (__cplusplus)
int yyparse (void *YYPARSE_PARAM)
# else
int yyparse (YYPARSE_PARAM)
  void *YYPARSE_PARAM;
# endif
#else /* ! YYPARSE_PARAM */
#if defined (__STDC__) || defined (__cplusplus)
int
yyparse (void)
#else
int
yyparse ()

#endif
#endif
{
  /* The lookahead symbol.  */
int yychar;

/* The semantic value of the lookahead symbol.  */
YYSTYPE yylval;

/* Number of syntax errors so far.  */
int yynerrs;

  register int yystate;
  register int yyn;
  int yyresult;
  /* Number of tokens to shift before error messages enabled.  */
  int yyerrstatus;
  /* Lookahead token as an internal (translated) token number.  */
  int yytoken = 0;

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

  if (yyss + yystacksize - 1 <= yyssp)
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
      if (YYMAXDEPTH <= yystacksize)
	goto yyoverflowlab;
      yystacksize *= 2;
      if (YYMAXDEPTH < yystacksize)
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

      if (yyss + yystacksize - 1 <= yyssp)
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

  /* YYCHAR is either YYEMPTY or YYEOF or a valid lookahead symbol.  */
  if (yychar == YYEMPTY)
    {
      YYDPRINTF ((stderr, "Reading a token: "));
      yychar = YYLEX;
    }

  if (yychar <= YYEOF)
    {
      yychar = yytoken = YYEOF;
      YYDPRINTF ((stderr, "Now at end of input.\n"));
    }
  else
    {
      yytoken = YYTRANSLATE (yychar);
      YYDSYMPRINTF ("Next token is", yytoken, &yylval, &yylloc);
    }

  /* If the proper action on seeing token YYTOKEN is to reduce or to
     detect an error, take that action.  */
  yyn += yytoken;
  if (yyn < 0 || YYLAST < yyn || yycheck[yyn] != yytoken)
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
  YYDPRINTF ((stderr, "Shifting token %s, ", yytname[yytoken]));

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


  YY_REDUCE_PRINT (yyn);
  switch (yyn)
    {
        case 2:
#line 166 "rtfGrammer.y"
    { GSRTFstart(CTXT); ;}
    break;

  case 3:
#line 166 "rtfGrammer.y"
    { GSRTFstop(CTXT); ;}
    break;

  case 5:
#line 169 "rtfGrammer.y"
    { yyval.number = 1; ;}
    break;

  case 6:
#line 170 "rtfGrammer.y"
    { yyval.number = 2; ;}
    break;

  case 7:
#line 171 "rtfGrammer.y"
    { yyval.number = 3; ;}
    break;

  case 8:
#line 172 "rtfGrammer.y"
    { yyval.number = 4; ;}
    break;

  case 9:
#line 174 "rtfGrammer.y"
    { yyval.number = 1; ;}
    break;

  case 14:
#line 181 "rtfGrammer.y"
    { GSRTFmangleText(CTXT, yyvsp[0].text); free((void *)yyvsp[0].text); ;}
    break;

  case 17:
#line 186 "rtfGrammer.y"
    { GSRTFopenBlock(CTXT, NO); ;}
    break;

  case 18:
#line 186 "rtfGrammer.y"
    { GSRTFcloseBlock(CTXT, NO); ;}
    break;

  case 19:
#line 187 "rtfGrammer.y"
    { GSRTFopenBlock(CTXT, YES); ;}
    break;

  case 20:
#line 187 "rtfGrammer.y"
    { GSRTFcloseBlock(CTXT, YES); ;}
    break;

  case 21:
#line 188 "rtfGrammer.y"
    { GSRTFopenBlock(CTXT, YES); ;}
    break;

  case 22:
#line 188 "rtfGrammer.y"
    { GSRTFcloseBlock(CTXT, YES); ;}
    break;

  case 23:
#line 189 "rtfGrammer.y"
    { GSRTFopenBlock(CTXT, YES); ;}
    break;

  case 24:
#line 189 "rtfGrammer.y"
    { GSRTFcloseBlock(CTXT, YES); ;}
    break;

  case 25:
#line 190 "rtfGrammer.y"
    { GSRTFopenBlock(CTXT, YES); ;}
    break;

  case 26:
#line 190 "rtfGrammer.y"
    { GSRTFcloseBlock(CTXT, YES); ;}
    break;

  case 27:
#line 191 "rtfGrammer.y"
    { GSRTFopenBlock(CTXT, YES); ;}
    break;

  case 28:
#line 191 "rtfGrammer.y"
    { GSRTFcloseBlock(CTXT, YES); ;}
    break;

  case 29:
#line 192 "rtfGrammer.y"
    { GSRTFopenBlock(CTXT, YES); ;}
    break;

  case 30:
#line 192 "rtfGrammer.y"
    { GSRTFcloseBlock(CTXT, YES); ;}
    break;

  case 31:
#line 193 "rtfGrammer.y"
    { GSRTFopenBlock(CTXT, YES); ;}
    break;

  case 32:
#line 193 "rtfGrammer.y"
    { GSRTFcloseBlock(CTXT, YES); ;}
    break;

  case 34:
#line 202 "rtfGrammer.y"
    { int font;
		    
						  if (yyvsp[0].cmd.isEmpty)
						      font = 0;
						  else
						      font = yyvsp[0].cmd.parameter;
						  GSRTFfontNumber(CTXT, font); ;}
    break;

  case 35:
#line 209 "rtfGrammer.y"
    { int size;

						  if (yyvsp[0].cmd.isEmpty)
						      size = 24;
						  else
						      size = yyvsp[0].cmd.parameter;
						  GSRTFfontSize(CTXT, size); ;}
    break;

  case 36:
#line 216 "rtfGrammer.y"
    { int width; 
		
		                                  if (yyvsp[0].cmd.isEmpty)
						      width = 12240;
						  else
						      width = yyvsp[0].cmd.parameter;
						  GSRTFpaperWidth(CTXT, width);;}
    break;

  case 37:
#line 223 "rtfGrammer.y"
    { int height; 
		
		                                  if (yyvsp[0].cmd.isEmpty)
						      height = 15840;
						  else
						      height = yyvsp[0].cmd.parameter;
						  GSRTFpaperHeight(CTXT, height);;}
    break;

  case 38:
#line 230 "rtfGrammer.y"
    { int margin; 
		
		                                  if (yyvsp[0].cmd.isEmpty)
						      margin = 1800;
						  else
						      margin = yyvsp[0].cmd.parameter;
						  GSRTFmarginLeft(CTXT, margin);;}
    break;

  case 39:
#line 237 "rtfGrammer.y"
    { int margin; 
		
		                                  if (yyvsp[0].cmd.isEmpty)
						      margin = 1800;
						  else
						      margin = yyvsp[0].cmd.parameter;
						  GSRTFmarginRight(CTXT, margin); ;}
    break;

  case 40:
#line 244 "rtfGrammer.y"
    { int margin; 
		
		                                  if (yyvsp[0].cmd.isEmpty)
						      margin = 1440;
						  else
						      margin = yyvsp[0].cmd.parameter;
						  GSRTFmarginTop(CTXT, margin); ;}
    break;

  case 41:
#line 251 "rtfGrammer.y"
    { int margin; 
		
		                                  if (yyvsp[0].cmd.isEmpty)
						      margin = 1440;
						  else
						      margin = yyvsp[0].cmd.parameter;
						  GSRTFmarginButtom(CTXT, margin); ;}
    break;

  case 42:
#line 258 "rtfGrammer.y"
    { int indent; 
		
		                                  if (yyvsp[0].cmd.isEmpty)
						      indent = 0;
						  else
						      indent = yyvsp[0].cmd.parameter;
						  GSRTFfirstLineIndent(CTXT, indent); ;}
    break;

  case 43:
#line 265 "rtfGrammer.y"
    { int indent; 
		
		                                  if (yyvsp[0].cmd.isEmpty)
						      indent = 0;
						  else
						      indent = yyvsp[0].cmd.parameter;
						  GSRTFleftIndent(CTXT, indent);;}
    break;

  case 44:
#line 272 "rtfGrammer.y"
    { int indent; 
		
		                                  if (yyvsp[0].cmd.isEmpty)
						      indent = 0;
						  else
						      indent = yyvsp[0].cmd.parameter;
						  GSRTFrightIndent(CTXT, indent);;}
    break;

  case 45:
#line 279 "rtfGrammer.y"
    { int location; 
		
		                                  if (yyvsp[0].cmd.isEmpty)
						      location = 0;
						  else
						      location = yyvsp[0].cmd.parameter;
						  GSRTFtabstop(CTXT, location);;}
    break;

  case 46:
#line 286 "rtfGrammer.y"
    { GSRTFalignCenter(CTXT); ;}
    break;

  case 47:
#line 287 "rtfGrammer.y"
    { GSRTFalignJustified(CTXT); ;}
    break;

  case 48:
#line 288 "rtfGrammer.y"
    { GSRTFalignLeft(CTXT); ;}
    break;

  case 49:
#line 289 "rtfGrammer.y"
    { GSRTFalignRight(CTXT); ;}
    break;

  case 50:
#line 290 "rtfGrammer.y"
    { int space; 
		
		                                  if (yyvsp[0].cmd.isEmpty)
						      space = 0;
						  else
						      space = yyvsp[0].cmd.parameter;
						  GSRTFspaceAbove(CTXT, space); ;}
    break;

  case 51:
#line 297 "rtfGrammer.y"
    { GSRTFlineSpace(CTXT, yyvsp[0].cmd.parameter); ;}
    break;

  case 52:
#line 298 "rtfGrammer.y"
    { GSRTFdefaultParagraph(CTXT); ;}
    break;

  case 53:
#line 299 "rtfGrammer.y"
    { GSRTFstyle(CTXT, yyvsp[0].cmd.parameter); ;}
    break;

  case 54:
#line 300 "rtfGrammer.y"
    { int color; 
		
		                                  if (yyvsp[0].cmd.isEmpty)
						      color = 0;
						  else
						      color = yyvsp[0].cmd.parameter;
						  GSRTFcolorbg(CTXT, color); ;}
    break;

  case 55:
#line 307 "rtfGrammer.y"
    { int color; 
		
		                                  if (yyvsp[0].cmd.isEmpty)
						      color = 0;
						  else
						      color = yyvsp[0].cmd.parameter;
						  GSRTFcolorfg(CTXT, color); ;}
    break;

  case 56:
#line 314 "rtfGrammer.y"
    { int script;
		
		                                  if (yyvsp[0].cmd.isEmpty)
						      script = 6;
						  else
						      script = yyvsp[0].cmd.parameter;
						  GSRTFsubscript(CTXT, script); ;}
    break;

  case 57:
#line 321 "rtfGrammer.y"
    { int script;
		
		                                  if (yyvsp[0].cmd.isEmpty)
						      script = 6;
						  else
						      script = yyvsp[0].cmd.parameter;
						  GSRTFsuperscript(CTXT, script); ;}
    break;

  case 58:
#line 328 "rtfGrammer.y"
    { BOOL on;

		                                  if (yyvsp[0].cmd.isEmpty || yyvsp[0].cmd.parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFbold(CTXT, on); ;}
    break;

  case 59:
#line 335 "rtfGrammer.y"
    { BOOL on;

		                                  if (yyvsp[0].cmd.isEmpty || yyvsp[0].cmd.parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFitalic(CTXT, on); ;}
    break;

  case 60:
#line 342 "rtfGrammer.y"
    { BOOL on;

		                                  if (yyvsp[0].cmd.isEmpty || yyvsp[0].cmd.parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFunderline(CTXT, on); ;}
    break;

  case 61:
#line 349 "rtfGrammer.y"
    { GSRTFunderline(CTXT, NO); ;}
    break;

  case 62:
#line 350 "rtfGrammer.y"
    { GSRTFdefaultCharacterStyle(CTXT); ;}
    break;

  case 63:
#line 351 "rtfGrammer.y"
    { GSRTFparagraph(CTXT); ;}
    break;

  case 64:
#line 352 "rtfGrammer.y"
    { GSRTFparagraph(CTXT); ;}
    break;

  case 65:
#line 353 "rtfGrammer.y"
    { GSRTFgenericRTFcommand(CTXT, yyvsp[0].cmd); ;}
    break;

  case 70:
#line 367 "rtfGrammer.y"
    { free((void *)yyvsp[-1].text);;}
    break;

  case 71:
#line 372 "rtfGrammer.y"
    { GSRTFregisterFont(CTXT, yyvsp[0].text, yyvsp[-2].number, yyvsp[-3].cmd.parameter);
                                                          free((void *)yyvsp[0].text); ;}
    break;

  case 77:
#line 385 "rtfGrammer.y"
    { yyval.number = RTFfamilyNil - RTFfamilyNil; ;}
    break;

  case 78:
#line 386 "rtfGrammer.y"
    { yyval.number = RTFfamilyRoman - RTFfamilyNil; ;}
    break;

  case 79:
#line 387 "rtfGrammer.y"
    { yyval.number = RTFfamilySwiss - RTFfamilyNil; ;}
    break;

  case 80:
#line 388 "rtfGrammer.y"
    { yyval.number = RTFfamilyModern - RTFfamilyNil; ;}
    break;

  case 81:
#line 389 "rtfGrammer.y"
    { yyval.number = RTFfamilyScript - RTFfamilyNil; ;}
    break;

  case 82:
#line 390 "rtfGrammer.y"
    { yyval.number = RTFfamilyDecor - RTFfamilyNil; ;}
    break;

  case 83:
#line 391 "rtfGrammer.y"
    { yyval.number = RTFfamilyTech - RTFfamilyNil; ;}
    break;

  case 87:
#line 408 "rtfGrammer.y"
    { 
		       GSRTFaddColor(CTXT, yyvsp[-3].cmd.parameter, yyvsp[-2].cmd.parameter, yyvsp[-1].cmd.parameter);
		       free((void *)yyvsp[0].text);
		     ;}
    break;

  case 88:
#line 413 "rtfGrammer.y"
    { 
		       GSRTFaddDefaultColor(CTXT);
		       free((void *)yyvsp[0].text);
		     ;}
    break;


    }

/* Line 991 of yacc.c.  */
#line 1879 "rtfGrammer.tab.c"

  yyvsp -= yylen;
  yyssp -= yylen;


  YY_STACK_PRINT (yyss, yyssp);

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
	  yysize += yystrlen ("syntax error, unexpected ") + 1;
	  yysize += yystrlen (yytname[yytype]);
	  yymsg = (char *) YYSTACK_ALLOC (yysize);
	  if (yymsg != 0)
	    {
	      char *yyp = yystpcpy (yymsg, "syntax error, unexpected ");
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
	    yyerror ("syntax error; also virtual memory exhausted");
	}
      else
#endif /* YYERROR_VERBOSE */
	yyerror ("syntax error");
    }



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
	  while (yyss < yyssp)
	    {
	      YYDSYMPRINTF ("Error: popping", yystos[*yyssp], yyvsp, yylsp);
	      yydestruct (yystos[*yyssp], yyvsp);
	      YYPOPSTACK;
	    }
	  YYABORT;
        }

      YYDSYMPRINTF ("Error: discarding", yytoken, &yylval, &yylloc);
      yydestruct (yytoken, &yylval);
      yychar = YYEMPTY;

    }

  /* Else will try to reuse lookahead token after shifting the error
     token.  */
  goto yyerrlab2;


/*----------------------------------------------------.
| yyerrlab1 -- error raised explicitly by an action.  |
`----------------------------------------------------*/
yyerrlab1:

  /* Suppress GCC warning that yyerrlab1 is unused when no action
     invokes YYERROR.  */
#if defined (__GNUC_MINOR__) && 2093 <= (__GNUC__ * 1000 + __GNUC_MINOR__)
  __attribute__ ((__unused__))
#endif


  goto yyerrlab2;


/*---------------------------------------------------------------.
| yyerrlab2 -- pop states until the error token can be shifted.  |
`---------------------------------------------------------------*/
yyerrlab2:
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

      YYDSYMPRINTF ("Error: popping", yystos[*yyssp], yyvsp, yylsp);
      yydestruct (yystos[yystate], yyvsp);
      yyvsp--;
      yystate = *--yyssp;

      YY_STACK_PRINT (yyss, yyssp);
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


#line 425 "rtfGrammer.y"


/*	some C code here	*/


