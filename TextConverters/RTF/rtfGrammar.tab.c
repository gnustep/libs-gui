/* A Bison parser, made by GNU Bison 2.3.  */

/* Skeleton implementation for Bison's Yacc-like parsers in C

   Copyright (C) 1984, 1989, 1990, 2000, 2001, 2002, 2003, 2004, 2005, 2006
   Free Software Foundation, Inc.

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
   Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

/* C LALR(1) parser skeleton written by Richard Stallman, by
   simplifying the original so-called "semantic" parser.  */

/* All symbols defined below should begin with yy or YY, to avoid
   infringing on user name space.  This should be done even for local
   variables, as they might otherwise be expanded by user macros.
   There are some unavoidable exceptions within include files to
   define necessary library symbols; they are noted "INFRINGES ON
   USER NAME SPACE" below.  */

/* Identify Bison output.  */
#define YYBISON 1

/* Bison version.  */
#define YYBISON_VERSION "2.3"

/* Skeleton name.  */
#define YYSKELETON_NAME "yacc.c"

/* Pure parsers.  */
#define YYPURE 1

/* Using locations.  */
#define YYLSP_NEEDED 0

/* Substitute the variable and function names.  */
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
     RTFNeXTGraphic = 294,
     RTFNeXTGraphicWidth = 295,
     RTFNeXTGraphicHeight = 296,
     RTFNeXTHelpLink = 297,
     RTFNeXTHelpMarker = 298,
     RTFNeXTfilename = 299,
     RTFNeXTmarkername = 300,
     RTFNeXTlinkFilename = 301,
     RTFNeXTlinkMarkername = 302,
     RTFpaperWidth = 303,
     RTFpaperHeight = 304,
     RTFmarginLeft = 305,
     RTFmarginRight = 306,
     RTFmarginTop = 307,
     RTFmarginButtom = 308,
     RTFfirstLineIndent = 309,
     RTFleftIndent = 310,
     RTFrightIndent = 311,
     RTFalignCenter = 312,
     RTFalignJustified = 313,
     RTFalignLeft = 314,
     RTFalignRight = 315,
     RTFlineSpace = 316,
     RTFspaceAbove = 317,
     RTFstyle = 318,
     RTFbold = 319,
     RTFitalic = 320,
     RTFunderline = 321,
     RTFunderlineStop = 322,
     RTFunichar = 323,
     RTFsubscript = 324,
     RTFsuperscript = 325,
     RTFtabstop = 326,
     RTFfcharset = 327,
     RTFfprq = 328,
     RTFcpg = 329,
     RTFOtherStatement = 330,
     RTFfontListStart = 331,
     RTFfamilyNil = 332,
     RTFfamilyRoman = 333,
     RTFfamilySwiss = 334,
     RTFfamilyModern = 335,
     RTFfamilyScript = 336,
     RTFfamilyDecor = 337,
     RTFfamilyTech = 338
   };
#endif
/* Tokens.  */
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
#define RTFNeXTGraphic 294
#define RTFNeXTGraphicWidth 295
#define RTFNeXTGraphicHeight 296
#define RTFNeXTHelpLink 297
#define RTFNeXTHelpMarker 298
#define RTFNeXTfilename 299
#define RTFNeXTmarkername 300
#define RTFNeXTlinkFilename 301
#define RTFNeXTlinkMarkername 302
#define RTFpaperWidth 303
#define RTFpaperHeight 304
#define RTFmarginLeft 305
#define RTFmarginRight 306
#define RTFmarginTop 307
#define RTFmarginButtom 308
#define RTFfirstLineIndent 309
#define RTFleftIndent 310
#define RTFrightIndent 311
#define RTFalignCenter 312
#define RTFalignJustified 313
#define RTFalignLeft 314
#define RTFalignRight 315
#define RTFlineSpace 316
#define RTFspaceAbove 317
#define RTFstyle 318
#define RTFbold 319
#define RTFitalic 320
#define RTFunderline 321
#define RTFunderlineStop 322
#define RTFunichar 323
#define RTFsubscript 324
#define RTFsuperscript 325
#define RTFtabstop 326
#define RTFfcharset 327
#define RTFfprq 328
#define RTFcpg 329
#define RTFOtherStatement 330
#define RTFfontListStart 331
#define RTFfamilyNil 332
#define RTFfamilyRoman 333
#define RTFfamilySwiss 334
#define RTFfamilyModern 335
#define RTFfamilyScript 336
#define RTFfamilyDecor 337
#define RTFfamilyTech 338




/* Copy the first part of user declarations.  */
#line 36 "rtfGrammar.y"


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
/*#define YYPARSE_PARAM	ctxt, void *lctxt*/
#define YYLEX_PARAM		lctxt
/*#undef YYLSP_NEEDED*/
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

/* Enabling the token table.  */
#ifndef YYTOKEN_TABLE
# define YYTOKEN_TABLE 0
#endif

#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
typedef union YYSTYPE
#line 81 "rtfGrammar.y"
{
	int		number;
	const char	*text;
	RTFcmd		cmd;
}
/* Line 193 of yacc.c.  */
#line 318 "rtfGrammar.tab.c"
	YYSTYPE;
# define yystype YYSTYPE /* obsolescent; will be withdrawn */
# define YYSTYPE_IS_DECLARED 1
# define YYSTYPE_IS_TRIVIAL 1
#endif



/* Copy the second part of user declarations.  */


/* Line 216 of yacc.c.  */
#line 331 "rtfGrammar.tab.c"

#ifdef short
# undef short
#endif

#ifdef YYTYPE_UINT8
typedef YYTYPE_UINT8 yytype_uint8;
#else
typedef unsigned char yytype_uint8;
#endif

#ifdef YYTYPE_INT8
typedef YYTYPE_INT8 yytype_int8;
#elif (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
typedef signed char yytype_int8;
#else
typedef short int yytype_int8;
#endif

#ifdef YYTYPE_UINT16
typedef YYTYPE_UINT16 yytype_uint16;
#else
typedef unsigned short int yytype_uint16;
#endif

#ifdef YYTYPE_INT16
typedef YYTYPE_INT16 yytype_int16;
#else
typedef short int yytype_int16;
#endif

#ifndef YYSIZE_T
# ifdef __SIZE_TYPE__
#  define YYSIZE_T __SIZE_TYPE__
# elif defined size_t
#  define YYSIZE_T size_t
# elif ! defined YYSIZE_T && (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
#  include <stddef.h> /* INFRINGES ON USER NAME SPACE */
#  define YYSIZE_T size_t
# else
#  define YYSIZE_T unsigned int
# endif
#endif

#define YYSIZE_MAXIMUM ((YYSIZE_T) -1)

#ifndef YY_
# if defined YYENABLE_NLS && YYENABLE_NLS
#  if ENABLE_NLS
#   include <libintl.h> /* INFRINGES ON USER NAME SPACE */
#   define YY_(msgid) dgettext ("bison-runtime", msgid)
#  endif
# endif
# ifndef YY_
#  define YY_(msgid) msgid
# endif
#endif

/* Suppress unused-variable warnings by "using" E.  */
#if ! defined lint || defined __GNUC__
# define YYUSE(e) ((void) (e))
#else
# define YYUSE(e) /* empty */
#endif

/* Identity function, used to suppress warnings about constant conditions.  */
#ifndef lint
# define YYID(n) (n)
#else
#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
static int
YYID (int i)
#else
static int
YYID (i)
    int i;
#endif
{
  return i;
}
#endif

#if ! defined yyoverflow || YYERROR_VERBOSE

/* The parser invokes alloca or malloc; define the necessary symbols.  */

# ifdef YYSTACK_USE_ALLOCA
#  if YYSTACK_USE_ALLOCA
#   ifdef __GNUC__
#    define YYSTACK_ALLOC __builtin_alloca
#   elif defined __BUILTIN_VA_ARG_INCR
#    include <alloca.h> /* INFRINGES ON USER NAME SPACE */
#   elif defined _AIX
#    define YYSTACK_ALLOC __alloca
#   elif defined _MSC_VER
#    include <malloc.h> /* INFRINGES ON USER NAME SPACE */
#    define alloca _alloca
#   else
#    define YYSTACK_ALLOC alloca
#    if ! defined _ALLOCA_H && ! defined _STDLIB_H && (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
#     include <stdlib.h> /* INFRINGES ON USER NAME SPACE */
#     ifndef _STDLIB_H
#      define _STDLIB_H 1
#     endif
#    endif
#   endif
#  endif
# endif

# ifdef YYSTACK_ALLOC
   /* Pacify GCC's `empty if-body' warning.  */
#  define YYSTACK_FREE(Ptr) do { /* empty */; } while (YYID (0))
#  ifndef YYSTACK_ALLOC_MAXIMUM
    /* The OS might guarantee only one guard page at the bottom of the stack,
       and a page size can be as small as 4096 bytes.  So we cannot safely
       invoke alloca (N) if N exceeds 4096.  Use a slightly smaller number
       to allow for a few compiler-allocated temporary stack slots.  */
#   define YYSTACK_ALLOC_MAXIMUM 4032 /* reasonable circa 2006 */
#  endif
# else
#  define YYSTACK_ALLOC YYMALLOC
#  define YYSTACK_FREE YYFREE
#  ifndef YYSTACK_ALLOC_MAXIMUM
#   define YYSTACK_ALLOC_MAXIMUM YYSIZE_MAXIMUM
#  endif
#  if (defined __cplusplus && ! defined _STDLIB_H \
       && ! ((defined YYMALLOC || defined malloc) \
	     && (defined YYFREE || defined free)))
#   include <stdlib.h> /* INFRINGES ON USER NAME SPACE */
#   ifndef _STDLIB_H
#    define _STDLIB_H 1
#   endif
#  endif
#  ifndef YYMALLOC
#   define YYMALLOC malloc
#   if ! defined malloc && ! defined _STDLIB_H && (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
void *malloc (YYSIZE_T); /* INFRINGES ON USER NAME SPACE */
#   endif
#  endif
#  ifndef YYFREE
#   define YYFREE free
#   if ! defined free && ! defined _STDLIB_H && (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
void free (void *); /* INFRINGES ON USER NAME SPACE */
#   endif
#  endif
# endif
#endif /* ! defined yyoverflow || YYERROR_VERBOSE */


#if (! defined yyoverflow \
     && (! defined __cplusplus \
	 || (defined YYSTYPE_IS_TRIVIAL && YYSTYPE_IS_TRIVIAL)))

/* A type that is properly aligned for any stack member.  */
union yyalloc
{
  yytype_int16 yyss;
  YYSTYPE yyvs;
  };

/* The size of the maximum gap between one aligned stack and the next.  */
# define YYSTACK_GAP_MAXIMUM (sizeof (union yyalloc) - 1)

/* The size of an array large to enough to hold all stacks, each with
   N elements.  */
# define YYSTACK_BYTES(N) \
     ((N) * (sizeof (yytype_int16) + sizeof (YYSTYPE)) \
      + YYSTACK_GAP_MAXIMUM)

/* Copy COUNT objects from FROM to TO.  The source and destination do
   not overlap.  */
# ifndef YYCOPY
#  if defined __GNUC__ && 1 < __GNUC__
#   define YYCOPY(To, From, Count) \
      __builtin_memcpy (To, From, (Count) * sizeof (*(From)))
#  else
#   define YYCOPY(To, From, Count)		\
      do					\
	{					\
	  YYSIZE_T yyi;				\
	  for (yyi = 0; yyi < (Count); yyi++)	\
	    (To)[yyi] = (From)[yyi];		\
	}					\
      while (YYID (0))
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
    while (YYID (0))

#endif

/* YYFINAL -- State number of the termination state.  */
#define YYFINAL  4
/* YYLAST -- Last index in YYTABLE.  */
#define YYLAST   1144

/* YYNTOKENS -- Number of terminals.  */
#define YYNTOKENS  86
/* YYNNTS -- Number of nonterminals.  */
#define YYNNTS  34
/* YYNRULES -- Number of rules.  */
#define YYNRULES  102
/* YYNRULES -- Number of states.  */
#define YYNSTATES  154

/* YYTRANSLATE(YYLEX) -- Bison symbol number corresponding to YYLEX.  */
#define YYUNDEFTOK  2
#define YYMAXUTOK   338

#define YYTRANSLATE(YYX)						\
  ((unsigned int) (YYX) <= YYMAXUTOK ? yytranslate[YYX] : YYUNDEFTOK)

/* YYTRANSLATE[YYLEX] -- Bison symbol number corresponding to YYLEX.  */
static const yytype_uint8 yytranslate[] =
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
       2,     2,     2,    84,     2,    85,     2,     2,     2,     2,
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
      65,    66,    67,    68,    69,    70,    71,    72,    73,    74,
      75,    76,    77,    78,    79,    80,    81,    82,    83
};

#if YYDEBUG
/* YYPRHS[YYN] -- Index of the first RHS symbol of rule number YYN in
   YYRHS.  */
static const yytype_uint16 yyprhs[] =
{
       0,     0,     3,     4,     5,    13,    15,    17,    19,    21,
      23,    24,    27,    30,    33,    36,    39,    42,    43,    49,
      50,    56,    57,    63,    64,    70,    71,    77,    78,    84,
      85,    91,    92,    98,   102,   104,   106,   108,   110,   112,
     114,   116,   118,   120,   122,   124,   126,   128,   130,   132,
     134,   136,   138,   140,   142,   144,   146,   148,   150,   152,
     154,   156,   158,   160,   162,   164,   166,   168,   169,   171,
     173,   175,   176,   177,   187,   188,   189,   202,   203,   204,
     213,   218,   219,   222,   227,   234,   239,   240,   243,   246,
     249,   252,   254,   256,   258,   260,   262,   264,   266,   271,
     272,   275,   280
};

/* YYRHS -- A `-1'-separated list of the rules' RHS.  */
static const yytype_int8 yyrhs[] =
{
      87,     0,    -1,    -1,    -1,    84,    88,     4,    90,    91,
      89,    85,    -1,     5,    -1,     6,    -1,     7,    -1,     8,
      -1,    75,    -1,    -1,    91,   112,    -1,    91,   117,    -1,
      91,   101,    -1,    91,     3,    -1,    91,    92,    -1,    91,
       1,    -1,    -1,    84,    93,    91,   102,    85,    -1,    -1,
      84,    94,     9,    91,    85,    -1,    -1,    84,    95,    10,
      91,    85,    -1,    -1,    84,    96,    11,    91,    85,    -1,
      -1,    84,    97,    12,    91,    85,    -1,    -1,    84,    98,
      13,    91,    85,    -1,    -1,    84,    99,    14,    91,    85,
      -1,    -1,    84,   100,    15,    91,    85,    -1,    84,     1,
      85,    -1,    37,    -1,    38,    -1,    48,    -1,    49,    -1,
      50,    -1,    51,    -1,    52,    -1,    53,    -1,    54,    -1,
      55,    -1,    56,    -1,    71,    -1,    57,    -1,    58,    -1,
      59,    -1,    60,    -1,    62,    -1,    61,    -1,    18,    -1,
      63,    -1,    34,    -1,    35,    -1,    69,    -1,    70,    -1,
      64,    -1,    65,    -1,    66,    -1,    67,    -1,    68,    -1,
      16,    -1,    17,    -1,    19,    -1,    75,    -1,    -1,   103,
      -1,   106,    -1,   109,    -1,    -1,    -1,    84,    39,     3,
      40,    41,    85,   104,    91,   105,    -1,    -1,    -1,    84,
      42,    45,     3,    46,     3,    47,     3,    85,   107,    91,
     108,    -1,    -1,    -1,    84,    43,    45,     3,    85,   110,
      91,   111,    -1,    84,    76,   113,    85,    -1,    -1,   113,
     114,    -1,   113,    84,   114,    85,    -1,   113,    84,   114,
      92,     3,    85,    -1,    37,   116,   115,     3,    -1,    -1,
     115,    72,    -1,   115,    73,    -1,   115,    74,    -1,   115,
      92,    -1,    77,    -1,    78,    -1,    79,    -1,    80,    -1,
      81,    -1,    82,    -1,    83,    -1,    84,    36,   118,    85,
      -1,    -1,   118,   119,    -1,    31,    32,    33,     3,    -1,
       3,    -1
};

/* YYRLINE[YYN] -- source line where rule number YYN was defined.  */
static const yytype_uint16 yyrline[] =
{
       0,   180,   180,   180,   180,   183,   184,   185,   186,   188,
     191,   192,   193,   194,   195,   196,   197,   200,   200,   201,
     201,   202,   202,   203,   203,   204,   204,   205,   205,   206,
     206,   207,   207,   208,   216,   223,   230,   237,   244,   251,
     258,   265,   272,   279,   286,   293,   300,   301,   302,   303,
     304,   311,   312,   313,   314,   321,   328,   335,   342,   349,
     356,   363,   364,   365,   366,   367,   368,   372,   373,   374,
     375,   387,   387,   387,   402,   402,   402,   416,   416,   416,
     425,   428,   429,   430,   431,   437,   441,   442,   443,   444,
     445,   450,   451,   452,   453,   454,   455,   456,   464,   467,
     468,   472,   477
};
#endif

#if YYDEBUG || YYERROR_VERBOSE || YYTOKEN_TABLE
/* YYTNAME[SYMBOL-NUM] -- String name of the symbol SYMBOL-NUM.
   First, the terminals, then, starting at YYNTOKENS, nonterminals.  */
static const char *const yytname[] =
{
  "$end", "error", "$undefined", "RTFtext", "RTFstart", "RTFansi",
  "RTFmac", "RTFpc", "RTFpca", "RTFignore", "RTFinfo", "RTFstylesheet",
  "RTFfootnote", "RTFheader", "RTFfooter", "RTFpict", "RTFplain",
  "RTFparagraph", "RTFdefaultParagraph", "RTFrow", "RTFcell",
  "RTFtabulator", "RTFemdash", "RTFendash", "RTFemspace", "RTFenspace",
  "RTFbullet", "RTFlquote", "RTFrquote", "RTFldblquote", "RTFrdblquote",
  "RTFred", "RTFgreen", "RTFblue", "RTFcolorbg", "RTFcolorfg",
  "RTFcolortable", "RTFfont", "RTFfontSize", "RTFNeXTGraphic",
  "RTFNeXTGraphicWidth", "RTFNeXTGraphicHeight", "RTFNeXTHelpLink",
  "RTFNeXTHelpMarker", "RTFNeXTfilename", "RTFNeXTmarkername",
  "RTFNeXTlinkFilename", "RTFNeXTlinkMarkername", "RTFpaperWidth",
  "RTFpaperHeight", "RTFmarginLeft", "RTFmarginRight", "RTFmarginTop",
  "RTFmarginButtom", "RTFfirstLineIndent", "RTFleftIndent",
  "RTFrightIndent", "RTFalignCenter", "RTFalignJustified", "RTFalignLeft",
  "RTFalignRight", "RTFlineSpace", "RTFspaceAbove", "RTFstyle", "RTFbold",
  "RTFitalic", "RTFunderline", "RTFunderlineStop", "RTFunichar",
  "RTFsubscript", "RTFsuperscript", "RTFtabstop", "RTFfcharset", "RTFfprq",
  "RTFcpg", "RTFOtherStatement", "RTFfontListStart", "RTFfamilyNil",
  "RTFfamilyRoman", "RTFfamilySwiss", "RTFfamilyModern", "RTFfamilyScript",
  "RTFfamilyDecor", "RTFfamilyTech", "'{'", "'}'", "$accept", "rtfFile",
  "@1", "@2", "rtfCharset", "rtfIngredients", "rtfBlock", "@3", "@4", "@5",
  "@6", "@7", "@8", "@9", "@10", "rtfStatement", "rtfNeXTstuff",
  "rtfNeXTGraphic", "@11", "@12", "rtfNeXTHelpLink", "@13", "@14",
  "rtfNeXTHelpMarker", "@15", "@16", "rtfFontList", "rtfFonts",
  "rtfFontStatement", "rtfFontAttrs", "rtfFontFamily", "rtfColorDef",
  "rtfColors", "rtfColorStatement", 0
};
#endif

# ifdef YYPRINT
/* YYTOKNUM[YYLEX-NUM] -- Internal token number corresponding to
   token YYLEX-NUM.  */
static const yytype_uint16 yytoknum[] =
{
       0,   256,   257,   258,   259,   260,   261,   262,   263,   264,
     265,   266,   267,   268,   269,   270,   271,   272,   273,   274,
     275,   276,   277,   278,   279,   280,   281,   282,   283,   284,
     285,   286,   287,   288,   289,   290,   291,   292,   293,   294,
     295,   296,   297,   298,   299,   300,   301,   302,   303,   304,
     305,   306,   307,   308,   309,   310,   311,   312,   313,   314,
     315,   316,   317,   318,   319,   320,   321,   322,   323,   324,
     325,   326,   327,   328,   329,   330,   331,   332,   333,   334,
     335,   336,   337,   338,   123,   125
};
# endif

/* YYR1[YYN] -- Symbol number of symbol that rule YYN derives.  */
static const yytype_uint8 yyr1[] =
{
       0,    86,    88,    89,    87,    90,    90,    90,    90,    90,
      91,    91,    91,    91,    91,    91,    91,    93,    92,    94,
      92,    95,    92,    96,    92,    97,    92,    98,    92,    99,
      92,   100,    92,    92,   101,   101,   101,   101,   101,   101,
     101,   101,   101,   101,   101,   101,   101,   101,   101,   101,
     101,   101,   101,   101,   101,   101,   101,   101,   101,   101,
     101,   101,   101,   101,   101,   101,   101,   102,   102,   102,
     102,   104,   105,   103,   107,   108,   106,   110,   111,   109,
     112,   113,   113,   113,   113,   114,   115,   115,   115,   115,
     115,   116,   116,   116,   116,   116,   116,   116,   117,   118,
     118,   119,   119
};

/* YYR2[YYN] -- Number of symbols composing right hand side of rule YYN.  */
static const yytype_uint8 yyr2[] =
{
       0,     2,     0,     0,     7,     1,     1,     1,     1,     1,
       0,     2,     2,     2,     2,     2,     2,     0,     5,     0,
       5,     0,     5,     0,     5,     0,     5,     0,     5,     0,
       5,     0,     5,     3,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     0,     1,     1,
       1,     0,     0,     9,     0,     0,    12,     0,     0,     8,
       4,     0,     2,     4,     6,     4,     0,     2,     2,     2,
       2,     1,     1,     1,     1,     1,     1,     1,     4,     0,
       2,     4,     1
};

/* YYDEFACT[STATE-NAME] -- Default rule to reduce with in state
   STATE-NUM when YYTABLE doesn't specify something else to do.  Zero
   means the default is an error.  */
static const yytype_uint8 yydefact[] =
{
       0,     2,     0,     0,     1,     0,     5,     6,     7,     8,
       9,    10,     0,    16,    14,    63,    64,    52,    65,    54,
      55,    34,    35,    36,    37,    38,    39,    40,    41,    42,
      43,    44,    46,    47,    48,    49,    51,    50,    53,    58,
      59,    60,    61,    62,    56,    57,    45,    66,     0,     0,
      15,    13,    11,    12,     0,    99,    81,    10,     0,     0,
       0,     0,     0,     0,     0,     4,    33,     0,     0,     0,
      10,    10,    10,    10,    10,    10,    10,   102,     0,    98,
     100,     0,     0,    80,    82,     0,     0,    68,    69,    70,
       0,     0,     0,     0,     0,     0,     0,     0,    91,    92,
      93,    94,    95,    96,    97,    86,     0,     0,     0,     0,
      18,    20,    22,    24,    26,    28,    30,    32,     0,     0,
       0,    83,     0,     0,     0,     0,   101,    85,    87,    88,
      89,    90,     0,     0,     0,     0,    84,     0,     0,    77,
      71,     0,    10,    10,     0,     0,     0,     0,    79,    73,
      74,    10,     0,    76
};

/* YYDEFGOTO[NTERM-NUM].  */
static const yytype_int16 yydefgoto[] =
{
      -1,     2,     3,    49,    11,    12,    50,    57,    58,    59,
      60,    61,    62,    63,    64,    51,    86,    87,   143,   149,
      88,   151,   153,    89,   142,   148,    52,    68,    84,   119,
     105,    53,    67,    80
};

/* YYPACT[STATE-NUM] -- Index in YYTABLE of the portion describing
   STATE-NUM.  */
#define YYPACT_NINF -99
static const yytype_int16 yypact[] =
{
     -81,   -99,    11,     8,   -99,    -1,   -99,   -99,   -99,   -99,
     -99,   -99,   278,   -99,   -99,   -99,   -99,   -99,   -99,   -99,
     -99,   -99,   -99,   -99,   -99,   -99,   -99,   -99,   -99,   -99,
     -99,   -99,   -99,   -99,   -99,   -99,   -99,   -99,   -99,   -99,
     -99,   -99,   -99,   -99,   -99,   -99,   -99,   -99,   130,   -65,
     -99,   -99,   -99,   -99,   -54,   -99,   -99,   -99,    21,    22,
      23,    24,    20,    25,    26,   -99,   -99,    -2,   -35,   349,
     -99,   -99,   -99,   -99,   -99,   -99,   -99,   -99,     3,   -99,
     -99,   -55,     0,   -99,   -99,    53,   -47,   -99,   -99,   -99,
     420,   491,   562,   633,   704,   775,   846,     7,   -99,   -99,
     -99,   -99,   -99,   -99,   -99,   -99,   -75,    39,     1,     2,
     -99,   -99,   -99,   -99,   -99,   -99,   -99,   -99,    40,    78,
     207,   -99,    41,     5,    45,    48,   -99,   -99,   -99,   -99,
     -99,   -99,   -33,    12,     9,   -28,   -99,   -27,    56,   -99,
     -99,    13,   -99,   -99,    58,   917,   988,   -12,   -99,   -99,
     -99,   -99,  1059,   -99
};

/* YYPGOTO[NTERM-NUM].  */
static const yytype_int8 yypgoto[] =
{
     -99,   -99,   -99,   -99,   -99,   -57,   -98,   -99,   -99,   -99,
     -99,   -99,   -99,   -99,   -99,   -99,   -99,   -99,   -99,   -99,
     -99,   -99,   -99,   -99,   -99,   -99,   -99,   -99,    -7,   -99,
     -99,   -99,   -99,   -99
};

/* YYTABLE[YYPACT[STATE-NUM]].  What to do in state STATE-NUM.  If
   positive, shift that token.  If negative, reduce the rule which
   number is the opposite.  If zero, do what YYDEFACT says.
   If YYTABLE_NINF, syntax error.  */
#define YYTABLE_NINF -79
static const yytype_int16 yytable[] =
{
      69,    77,    81,     1,     6,     7,     8,     9,   122,   120,
     121,     4,     5,    90,    91,    92,    93,    94,    95,    96,
      65,   131,    98,    99,   100,   101,   102,   103,   104,    78,
      70,    66,    71,    74,    72,    97,    73,    81,   110,    75,
     118,    76,   123,   126,   132,   133,   124,   125,   134,    82,
      83,   135,   136,   137,    54,   138,   -17,   139,   140,   141,
     144,   147,   -19,   -21,   -23,   -25,   -27,   -29,   -31,   -17,
     -17,   -17,   -17,   150,    10,   106,     0,     0,     0,     0,
       0,   127,     0,    79,     0,   145,   146,   -17,   -17,    55,
     -17,   -17,   107,     0,   152,   108,   109,     0,     0,     0,
       0,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,
     -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,
     -17,   -17,   -17,   -17,   -17,     0,     0,     0,   -17,    56,
       0,    54,     0,   -17,     0,     0,     0,   -17,   -17,   -19,
     -21,   -23,   -25,   -27,   -29,   -31,   -17,   -17,   -17,   -17,
     128,   129,   130,     0,     0,     0,     0,     0,     0,     0,
       0,     0,   120,     0,   -17,   -17,    55,   -17,   -17,     0,
       0,     0,     0,     0,     0,     0,     0,     0,   -17,   -17,
     -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,
     -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,
     -17,   -17,     0,     0,     0,   -17,    56,     0,    54,     0,
     -17,     0,     0,     0,   -17,   -17,   -19,   -21,   -23,   -25,
     -27,   -29,   -31,   -17,   -17,   -17,   -17,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,   -17,   -17,     0,   -17,   -17,     0,     0,     0,     0,
       0,     0,     0,     0,     0,   -17,   -17,   -17,   -17,   -17,
     -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,
     -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,    13,
       0,    14,   -17,     0,     0,     0,     0,     0,     0,     0,
       0,   -17,   -17,     0,    15,    16,    17,    18,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,    19,    20,     0,    21,    22,     0,     0,     0,
       0,     0,     0,     0,     0,     0,    23,    24,    25,    26,
      27,    28,    29,    30,    31,    32,    33,    34,    35,    36,
      37,    38,    39,    40,    41,    42,    43,    44,    45,    46,
      13,     0,    14,    47,     0,     0,     0,     0,     0,     0,
       0,     0,    48,    -3,     0,    15,    16,    17,    18,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,    19,    20,     0,    21,    22,     0,     0,
       0,     0,     0,     0,     0,     0,     0,    23,    24,    25,
      26,    27,    28,    29,    30,    31,    32,    33,    34,    35,
      36,    37,    38,    39,    40,    41,    42,    43,    44,    45,
      46,    13,     0,    14,    47,     0,     0,     0,     0,     0,
       0,     0,     0,    85,   -67,     0,    15,    16,    17,    18,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,    19,    20,     0,    21,    22,     0,
       0,     0,     0,     0,     0,     0,     0,     0,    23,    24,
      25,    26,    27,    28,    29,    30,    31,    32,    33,    34,
      35,    36,    37,    38,    39,    40,    41,    42,    43,    44,
      45,    46,    13,     0,    14,    47,     0,     0,     0,     0,
       0,     0,     0,     0,    48,   111,     0,    15,    16,    17,
      18,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,    19,    20,     0,    21,    22,
       0,     0,     0,     0,     0,     0,     0,     0,     0,    23,
      24,    25,    26,    27,    28,    29,    30,    31,    32,    33,
      34,    35,    36,    37,    38,    39,    40,    41,    42,    43,
      44,    45,    46,    13,     0,    14,    47,     0,     0,     0,
       0,     0,     0,     0,     0,    48,   112,     0,    15,    16,
      17,    18,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,    19,    20,     0,    21,
      22,     0,     0,     0,     0,     0,     0,     0,     0,     0,
      23,    24,    25,    26,    27,    28,    29,    30,    31,    32,
      33,    34,    35,    36,    37,    38,    39,    40,    41,    42,
      43,    44,    45,    46,    13,     0,    14,    47,     0,     0,
       0,     0,     0,     0,     0,     0,    48,   113,     0,    15,
      16,    17,    18,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,    19,    20,     0,
      21,    22,     0,     0,     0,     0,     0,     0,     0,     0,
       0,    23,    24,    25,    26,    27,    28,    29,    30,    31,
      32,    33,    34,    35,    36,    37,    38,    39,    40,    41,
      42,    43,    44,    45,    46,    13,     0,    14,    47,     0,
       0,     0,     0,     0,     0,     0,     0,    48,   114,     0,
      15,    16,    17,    18,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,    19,    20,
       0,    21,    22,     0,     0,     0,     0,     0,     0,     0,
       0,     0,    23,    24,    25,    26,    27,    28,    29,    30,
      31,    32,    33,    34,    35,    36,    37,    38,    39,    40,
      41,    42,    43,    44,    45,    46,    13,     0,    14,    47,
       0,     0,     0,     0,     0,     0,     0,     0,    48,   115,
       0,    15,    16,    17,    18,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,    19,
      20,     0,    21,    22,     0,     0,     0,     0,     0,     0,
       0,     0,     0,    23,    24,    25,    26,    27,    28,    29,
      30,    31,    32,    33,    34,    35,    36,    37,    38,    39,
      40,    41,    42,    43,    44,    45,    46,    13,     0,    14,
      47,     0,     0,     0,     0,     0,     0,     0,     0,    48,
     116,     0,    15,    16,    17,    18,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
      19,    20,     0,    21,    22,     0,     0,     0,     0,     0,
       0,     0,     0,     0,    23,    24,    25,    26,    27,    28,
      29,    30,    31,    32,    33,    34,    35,    36,    37,    38,
      39,    40,    41,    42,    43,    44,    45,    46,    13,     0,
      14,    47,     0,     0,     0,     0,     0,     0,     0,     0,
      48,   117,     0,    15,    16,    17,    18,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,    19,    20,     0,    21,    22,     0,     0,     0,     0,
       0,     0,     0,     0,     0,    23,    24,    25,    26,    27,
      28,    29,    30,    31,    32,    33,    34,    35,    36,    37,
      38,    39,    40,    41,    42,    43,    44,    45,    46,    13,
       0,    14,    47,     0,     0,     0,     0,     0,     0,     0,
       0,    48,   -78,     0,    15,    16,    17,    18,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,    19,    20,     0,    21,    22,     0,     0,     0,
       0,     0,     0,     0,     0,     0,    23,    24,    25,    26,
      27,    28,    29,    30,    31,    32,    33,    34,    35,    36,
      37,    38,    39,    40,    41,    42,    43,    44,    45,    46,
      13,     0,    14,    47,     0,     0,     0,     0,     0,     0,
       0,     0,    48,   -72,     0,    15,    16,    17,    18,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,    19,    20,     0,    21,    22,     0,     0,
       0,     0,     0,     0,     0,     0,     0,    23,    24,    25,
      26,    27,    28,    29,    30,    31,    32,    33,    34,    35,
      36,    37,    38,    39,    40,    41,    42,    43,    44,    45,
      46,     0,     0,     0,    47,     0,     0,     0,     0,     0,
       0,     0,     0,    48,   -75
};

static const yytype_int16 yycheck[] =
{
      57,     3,    37,    84,     5,     6,     7,     8,   106,    84,
      85,     0,     4,    70,    71,    72,    73,    74,    75,    76,
      85,   119,    77,    78,    79,    80,    81,    82,    83,    31,
       9,    85,    10,    13,    11,    32,    12,    37,    85,    14,
      33,    15,     3,     3,     3,    40,    45,    45,     3,    84,
      85,     3,    85,    41,     1,    46,     3,    85,    85,     3,
      47,     3,     9,    10,    11,    12,    13,    14,    15,    16,
      17,    18,    19,    85,    75,    82,    -1,    -1,    -1,    -1,
      -1,     3,    -1,    85,    -1,   142,   143,    34,    35,    36,
      37,    38,    39,    -1,   151,    42,    43,    -1,    -1,    -1,
      -1,    48,    49,    50,    51,    52,    53,    54,    55,    56,
      57,    58,    59,    60,    61,    62,    63,    64,    65,    66,
      67,    68,    69,    70,    71,    -1,    -1,    -1,    75,    76,
      -1,     1,    -1,     3,    -1,    -1,    -1,    84,    85,     9,
      10,    11,    12,    13,    14,    15,    16,    17,    18,    19,
      72,    73,    74,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    84,    -1,    34,    35,    36,    37,    38,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    48,    49,
      50,    51,    52,    53,    54,    55,    56,    57,    58,    59,
      60,    61,    62,    63,    64,    65,    66,    67,    68,    69,
      70,    71,    -1,    -1,    -1,    75,    76,    -1,     1,    -1,
       3,    -1,    -1,    -1,    84,    85,     9,    10,    11,    12,
      13,    14,    15,    16,    17,    18,    19,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    34,    35,    -1,    37,    38,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    48,    49,    50,    51,    52,
      53,    54,    55,    56,    57,    58,    59,    60,    61,    62,
      63,    64,    65,    66,    67,    68,    69,    70,    71,     1,
      -1,     3,    75,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    84,    85,    -1,    16,    17,    18,    19,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    34,    35,    -1,    37,    38,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    48,    49,    50,    51,
      52,    53,    54,    55,    56,    57,    58,    59,    60,    61,
      62,    63,    64,    65,    66,    67,    68,    69,    70,    71,
       1,    -1,     3,    75,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    84,    85,    -1,    16,    17,    18,    19,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    34,    35,    -1,    37,    38,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    48,    49,    50,
      51,    52,    53,    54,    55,    56,    57,    58,    59,    60,
      61,    62,    63,    64,    65,    66,    67,    68,    69,    70,
      71,     1,    -1,     3,    75,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    84,    85,    -1,    16,    17,    18,    19,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    34,    35,    -1,    37,    38,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    48,    49,
      50,    51,    52,    53,    54,    55,    56,    57,    58,    59,
      60,    61,    62,    63,    64,    65,    66,    67,    68,    69,
      70,    71,     1,    -1,     3,    75,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    84,    85,    -1,    16,    17,    18,
      19,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    34,    35,    -1,    37,    38,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    48,
      49,    50,    51,    52,    53,    54,    55,    56,    57,    58,
      59,    60,    61,    62,    63,    64,    65,    66,    67,    68,
      69,    70,    71,     1,    -1,     3,    75,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    84,    85,    -1,    16,    17,
      18,    19,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    34,    35,    -1,    37,
      38,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      48,    49,    50,    51,    52,    53,    54,    55,    56,    57,
      58,    59,    60,    61,    62,    63,    64,    65,    66,    67,
      68,    69,    70,    71,     1,    -1,     3,    75,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    84,    85,    -1,    16,
      17,    18,    19,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    34,    35,    -1,
      37,    38,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    48,    49,    50,    51,    52,    53,    54,    55,    56,
      57,    58,    59,    60,    61,    62,    63,    64,    65,    66,
      67,    68,    69,    70,    71,     1,    -1,     3,    75,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    84,    85,    -1,
      16,    17,    18,    19,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    34,    35,
      -1,    37,    38,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    48,    49,    50,    51,    52,    53,    54,    55,
      56,    57,    58,    59,    60,    61,    62,    63,    64,    65,
      66,    67,    68,    69,    70,    71,     1,    -1,     3,    75,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    84,    85,
      -1,    16,    17,    18,    19,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    34,
      35,    -1,    37,    38,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    48,    49,    50,    51,    52,    53,    54,
      55,    56,    57,    58,    59,    60,    61,    62,    63,    64,
      65,    66,    67,    68,    69,    70,    71,     1,    -1,     3,
      75,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    84,
      85,    -1,    16,    17,    18,    19,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      34,    35,    -1,    37,    38,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    48,    49,    50,    51,    52,    53,
      54,    55,    56,    57,    58,    59,    60,    61,    62,    63,
      64,    65,    66,    67,    68,    69,    70,    71,     1,    -1,
       3,    75,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      84,    85,    -1,    16,    17,    18,    19,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    34,    35,    -1,    37,    38,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    48,    49,    50,    51,    52,
      53,    54,    55,    56,    57,    58,    59,    60,    61,    62,
      63,    64,    65,    66,    67,    68,    69,    70,    71,     1,
      -1,     3,    75,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    84,    85,    -1,    16,    17,    18,    19,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    34,    35,    -1,    37,    38,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    48,    49,    50,    51,
      52,    53,    54,    55,    56,    57,    58,    59,    60,    61,
      62,    63,    64,    65,    66,    67,    68,    69,    70,    71,
       1,    -1,     3,    75,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    84,    85,    -1,    16,    17,    18,    19,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    34,    35,    -1,    37,    38,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    48,    49,    50,
      51,    52,    53,    54,    55,    56,    57,    58,    59,    60,
      61,    62,    63,    64,    65,    66,    67,    68,    69,    70,
      71,    -1,    -1,    -1,    75,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    84,    85
};

/* YYSTOS[STATE-NUM] -- The (internal number of the) accessing
   symbol of state STATE-NUM.  */
static const yytype_uint8 yystos[] =
{
       0,    84,    87,    88,     0,     4,     5,     6,     7,     8,
      75,    90,    91,     1,     3,    16,    17,    18,    19,    34,
      35,    37,    38,    48,    49,    50,    51,    52,    53,    54,
      55,    56,    57,    58,    59,    60,    61,    62,    63,    64,
      65,    66,    67,    68,    69,    70,    71,    75,    84,    89,
      92,   101,   112,   117,     1,    36,    76,    93,    94,    95,
      96,    97,    98,    99,   100,    85,    85,   118,   113,    91,
       9,    10,    11,    12,    13,    14,    15,     3,    31,    85,
     119,    37,    84,    85,   114,    84,   102,   103,   106,   109,
      91,    91,    91,    91,    91,    91,    91,    32,    77,    78,
      79,    80,    81,    82,    83,   116,   114,    39,    42,    43,
      85,    85,    85,    85,    85,    85,    85,    85,    33,   115,
      84,    85,    92,     3,    45,    45,     3,     3,    72,    73,
      74,    92,     3,    40,     3,     3,    85,    41,    46,    85,
      85,     3,   110,   104,    47,    91,    91,     3,   111,   105,
      85,   107,    91,   108
};

#define yyerrok		(yyerrstatus = 0)
#define yyclearin	(yychar = YYEMPTY)
#define YYEMPTY		(-2)
#define YYEOF		0

#define YYACCEPT	goto yyacceptlab
#define YYABORT		goto yyabortlab
#define YYERROR		goto yyerrorlab


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
      YYPOPSTACK (1);						\
      goto yybackup;						\
    }								\
  else								\
    {								\
      yyerror (ctxt, lctxt, YY_("syntax error: cannot back up")); \
      YYERROR;							\
    }								\
while (YYID (0))


#define YYTERROR	1
#define YYERRCODE	256


/* YYLLOC_DEFAULT -- Set CURRENT to span from RHS[1] to RHS[N].
   If N is 0, then set CURRENT to the empty location which ends
   the previous symbol: RHS[0] (always defined).  */

#define YYRHSLOC(Rhs, K) ((Rhs)[K])
#ifndef YYLLOC_DEFAULT
# define YYLLOC_DEFAULT(Current, Rhs, N)				\
    do									\
      if (YYID (N))                                                    \
	{								\
	  (Current).first_line   = YYRHSLOC (Rhs, 1).first_line;	\
	  (Current).first_column = YYRHSLOC (Rhs, 1).first_column;	\
	  (Current).last_line    = YYRHSLOC (Rhs, N).last_line;		\
	  (Current).last_column  = YYRHSLOC (Rhs, N).last_column;	\
	}								\
      else								\
	{								\
	  (Current).first_line   = (Current).last_line   =		\
	    YYRHSLOC (Rhs, 0).last_line;				\
	  (Current).first_column = (Current).last_column =		\
	    YYRHSLOC (Rhs, 0).last_column;				\
	}								\
    while (YYID (0))
#endif


/* YY_LOCATION_PRINT -- Print the location on the stream.
   This macro was not mandated originally: define only if we know
   we won't break user code: when these are the locations we know.  */

#ifndef YY_LOCATION_PRINT
# if defined YYLTYPE_IS_TRIVIAL && YYLTYPE_IS_TRIVIAL
#  define YY_LOCATION_PRINT(File, Loc)			\
     fprintf (File, "%d.%d-%d.%d",			\
	      (Loc).first_line, (Loc).first_column,	\
	      (Loc).last_line,  (Loc).last_column)
# else
#  define YY_LOCATION_PRINT(File, Loc) ((void) 0)
# endif
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
} while (YYID (0))

# define YY_SYMBOL_PRINT(Title, Type, Value, Location)			  \
do {									  \
  if (yydebug)								  \
    {									  \
      YYFPRINTF (stderr, "%s ", Title);					  \
      yy_symbol_print (stderr,						  \
		  Type, Value, ctxt, lctxt); \
      YYFPRINTF (stderr, "\n");						  \
    }									  \
} while (YYID (0))


/*--------------------------------.
| Print this symbol on YYOUTPUT.  |
`--------------------------------*/

/*ARGSUSED*/
#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
static void
yy_symbol_value_print (FILE *yyoutput, int yytype, YYSTYPE const * const yyvaluep, void *ctxt, void *lctxt)
#else
static void
yy_symbol_value_print (yyoutput, yytype, yyvaluep, ctxt, lctxt)
    FILE *yyoutput;
    int yytype;
    YYSTYPE const * const yyvaluep;
    void *ctxt;
    void *lctxt;
#endif
{
  if (!yyvaluep)
    return;
  YYUSE (ctxt);
  YYUSE (lctxt);
# ifdef YYPRINT
  if (yytype < YYNTOKENS)
    YYPRINT (yyoutput, yytoknum[yytype], *yyvaluep);
# else
  YYUSE (yyoutput);
# endif
  switch (yytype)
    {
      default:
	break;
    }
}


/*--------------------------------.
| Print this symbol on YYOUTPUT.  |
`--------------------------------*/

#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
static void
yy_symbol_print (FILE *yyoutput, int yytype, YYSTYPE const * const yyvaluep, void *ctxt, void *lctxt)
#else
static void
yy_symbol_print (yyoutput, yytype, yyvaluep, ctxt, lctxt)
    FILE *yyoutput;
    int yytype;
    YYSTYPE const * const yyvaluep;
    void *ctxt;
    void *lctxt;
#endif
{
  if (yytype < YYNTOKENS)
    YYFPRINTF (yyoutput, "token %s (", yytname[yytype]);
  else
    YYFPRINTF (yyoutput, "nterm %s (", yytname[yytype]);

  yy_symbol_value_print (yyoutput, yytype, yyvaluep, ctxt, lctxt);
  YYFPRINTF (yyoutput, ")");
}

/*------------------------------------------------------------------.
| yy_stack_print -- Print the state stack from its BOTTOM up to its |
| TOP (included).                                                   |
`------------------------------------------------------------------*/

#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
static void
yy_stack_print (yytype_int16 *bottom, yytype_int16 *top)
#else
static void
yy_stack_print (bottom, top)
    yytype_int16 *bottom;
    yytype_int16 *top;
#endif
{
  YYFPRINTF (stderr, "Stack now");
  for (; bottom <= top; ++bottom)
    YYFPRINTF (stderr, " %d", *bottom);
  YYFPRINTF (stderr, "\n");
}

# define YY_STACK_PRINT(Bottom, Top)				\
do {								\
  if (yydebug)							\
    yy_stack_print ((Bottom), (Top));				\
} while (YYID (0))


/*------------------------------------------------.
| Report that the YYRULE is going to be reduced.  |
`------------------------------------------------*/

#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
static void
yy_reduce_print (YYSTYPE *yyvsp, int yyrule, void *ctxt, void *lctxt)
#else
static void
yy_reduce_print (yyvsp, yyrule, ctxt, lctxt)
    YYSTYPE *yyvsp;
    int yyrule;
    void *ctxt;
    void *lctxt;
#endif
{
  int yynrhs = yyr2[yyrule];
  int yyi;
  unsigned long int yylno = yyrline[yyrule];
  YYFPRINTF (stderr, "Reducing stack by rule %d (line %lu):\n",
	     yyrule - 1, yylno);
  /* The symbols being reduced.  */
  for (yyi = 0; yyi < yynrhs; yyi++)
    {
      fprintf (stderr, "   $%d = ", yyi + 1);
      yy_symbol_print (stderr, yyrhs[yyprhs[yyrule] + yyi],
		       &(yyvsp[(yyi + 1) - (yynrhs)])
		       		       , ctxt, lctxt);
      fprintf (stderr, "\n");
    }
}

# define YY_REDUCE_PRINT(Rule)		\
do {					\
  if (yydebug)				\
    yy_reduce_print (yyvsp, Rule, ctxt, lctxt); \
} while (YYID (0))

/* Nonzero means print parse trace.  It is left uninitialized so that
   multiple parsers can coexist.  */
int yydebug;
#else /* !YYDEBUG */
# define YYDPRINTF(Args)
# define YY_SYMBOL_PRINT(Title, Type, Value, Location)
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
   YYSTACK_ALLOC_MAXIMUM < YYSTACK_BYTES (YYMAXDEPTH)
   evaluated with infinite-precision integer arithmetic.  */

#ifndef YYMAXDEPTH
# define YYMAXDEPTH 10000
#endif



#if YYERROR_VERBOSE

# ifndef yystrlen
#  if defined __GLIBC__ && defined _STRING_H
#   define yystrlen strlen
#  else
/* Return the length of YYSTR.  */
#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
static YYSIZE_T
yystrlen (const char *yystr)
#else
static YYSIZE_T
yystrlen (yystr)
    const char *yystr;
#endif
{
  YYSIZE_T yylen;
  for (yylen = 0; yystr[yylen]; yylen++)
    continue;
  return yylen;
}
#  endif
# endif

# ifndef yystpcpy
#  if defined __GLIBC__ && defined _STRING_H && defined _GNU_SOURCE
#   define yystpcpy stpcpy
#  else
/* Copy YYSRC to YYDEST, returning the address of the terminating '\0' in
   YYDEST.  */
#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
static char *
yystpcpy (char *yydest, const char *yysrc)
#else
static char *
yystpcpy (yydest, yysrc)
    char *yydest;
    const char *yysrc;
#endif
{
  char *yyd = yydest;
  const char *yys = yysrc;

  while ((*yyd++ = *yys++) != '\0')
    continue;

  return yyd - 1;
}
#  endif
# endif

# ifndef yytnamerr
/* Copy to YYRES the contents of YYSTR after stripping away unnecessary
   quotes and backslashes, so that it's suitable for yyerror.  The
   heuristic is that double-quoting is unnecessary unless the string
   contains an apostrophe, a comma, or backslash (other than
   backslash-backslash).  YYSTR is taken from yytname.  If YYRES is
   null, do not copy; instead, return the length of what the result
   would have been.  */
static YYSIZE_T
yytnamerr (char *yyres, const char *yystr)
{
  if (*yystr == '"')
    {
      YYSIZE_T yyn = 0;
      char const *yyp = yystr;

      for (;;)
	switch (*++yyp)
	  {
	  case '\'':
	  case ',':
	    goto do_not_strip_quotes;

	  case '\\':
	    if (*++yyp != '\\')
	      goto do_not_strip_quotes;
	    /* Fall through.  */
	  default:
	    if (yyres)
	      yyres[yyn] = *yyp;
	    yyn++;
	    break;

	  case '"':
	    if (yyres)
	      yyres[yyn] = '\0';
	    return yyn;
	  }
    do_not_strip_quotes: ;
    }

  if (! yyres)
    return yystrlen (yystr);

  return yystpcpy (yyres, yystr) - yyres;
}
# endif

/* Copy into YYRESULT an error message about the unexpected token
   YYCHAR while in state YYSTATE.  Return the number of bytes copied,
   including the terminating null byte.  If YYRESULT is null, do not
   copy anything; just return the number of bytes that would be
   copied.  As a special case, return 0 if an ordinary "syntax error"
   message will do.  Return YYSIZE_MAXIMUM if overflow occurs during
   size calculation.  */
static YYSIZE_T
yysyntax_error (char *yyresult, int yystate, int yychar)
{
  int yyn = yypact[yystate];

  if (! (YYPACT_NINF < yyn && yyn <= YYLAST))
    return 0;
  else
    {
      int yytype = YYTRANSLATE (yychar);
      YYSIZE_T yysize0 = yytnamerr (0, yytname[yytype]);
      YYSIZE_T yysize = yysize0;
      YYSIZE_T yysize1;
      int yysize_overflow = 0;
      enum { YYERROR_VERBOSE_ARGS_MAXIMUM = 5 };
      char const *yyarg[YYERROR_VERBOSE_ARGS_MAXIMUM];
      int yyx;

# if 0
      /* This is so xgettext sees the translatable formats that are
	 constructed on the fly.  */
      YY_("syntax error, unexpected %s");
      YY_("syntax error, unexpected %s, expecting %s");
      YY_("syntax error, unexpected %s, expecting %s or %s");
      YY_("syntax error, unexpected %s, expecting %s or %s or %s");
      YY_("syntax error, unexpected %s, expecting %s or %s or %s or %s");
# endif
      char *yyfmt;
      char const *yyf;
      static char const yyunexpected[] = "syntax error, unexpected %s";
      static char const yyexpecting[] = ", expecting %s";
      static char const yyor[] = " or %s";
      char yyformat[sizeof yyunexpected
		    + sizeof yyexpecting - 1
		    + ((YYERROR_VERBOSE_ARGS_MAXIMUM - 2)
		       * (sizeof yyor - 1))];
      char const *yyprefix = yyexpecting;

      /* Start YYX at -YYN if negative to avoid negative indexes in
	 YYCHECK.  */
      int yyxbegin = yyn < 0 ? -yyn : 0;

      /* Stay within bounds of both yycheck and yytname.  */
      int yychecklim = YYLAST - yyn + 1;
      int yyxend = yychecklim < YYNTOKENS ? yychecklim : YYNTOKENS;
      int yycount = 1;

      yyarg[0] = yytname[yytype];
      yyfmt = yystpcpy (yyformat, yyunexpected);

      for (yyx = yyxbegin; yyx < yyxend; ++yyx)
	if (yycheck[yyx + yyn] == yyx && yyx != YYTERROR)
	  {
	    if (yycount == YYERROR_VERBOSE_ARGS_MAXIMUM)
	      {
		yycount = 1;
		yysize = yysize0;
		yyformat[sizeof yyunexpected - 1] = '\0';
		break;
	      }
	    yyarg[yycount++] = yytname[yyx];
	    yysize1 = yysize + yytnamerr (0, yytname[yyx]);
	    yysize_overflow |= (yysize1 < yysize);
	    yysize = yysize1;
	    yyfmt = yystpcpy (yyfmt, yyprefix);
	    yyprefix = yyor;
	  }

      yyf = YY_(yyformat);
      yysize1 = yysize + yystrlen (yyf);
      yysize_overflow |= (yysize1 < yysize);
      yysize = yysize1;

      if (yysize_overflow)
	return YYSIZE_MAXIMUM;

      if (yyresult)
	{
	  /* Avoid sprintf, as that infringes on the user's name space.
	     Don't have undefined behavior even if the translation
	     produced a string with the wrong number of "%s"s.  */
	  char *yyp = yyresult;
	  int yyi = 0;
	  while ((*yyp = *yyf) != '\0')
	    {
	      if (*yyp == '%' && yyf[1] == 's' && yyi < yycount)
		{
		  yyp += yytnamerr (yyp, yyarg[yyi++]);
		  yyf += 2;
		}
	      else
		{
		  yyp++;
		  yyf++;
		}
	    }
	}
      return yysize;
    }
}
#endif /* YYERROR_VERBOSE */


/*-----------------------------------------------.
| Release the memory associated to this symbol.  |
`-----------------------------------------------*/

/*ARGSUSED*/
#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
static void
yydestruct (const char *yymsg, int yytype, YYSTYPE *yyvaluep, void *ctxt, void *lctxt)
#else
static void
yydestruct (yymsg, yytype, yyvaluep, ctxt, lctxt)
    const char *yymsg;
    int yytype;
    YYSTYPE *yyvaluep;
    void *ctxt;
    void *lctxt;
#endif
{
  YYUSE (yyvaluep);
  YYUSE (ctxt);
  YYUSE (lctxt);

  if (!yymsg)
    yymsg = "Deleting";
  YY_SYMBOL_PRINT (yymsg, yytype, yyvaluep, yylocationp);

  switch (yytype)
    {

      default:
	break;
    }
}


/* Prevent warnings from -Wmissing-prototypes.  */

#ifdef YYPARSE_PARAM
#if defined __STDC__ || defined __cplusplus
int yyparse (void *YYPARSE_PARAM);
#else
int yyparse ();
#endif
#else /* ! YYPARSE_PARAM */
#if defined __STDC__ || defined __cplusplus
int yyparse (void *ctxt, void *lctxt);
#else
int yyparse ();
#endif
#endif /* ! YYPARSE_PARAM */






/*----------.
| yyparse.  |
`----------*/

#ifdef YYPARSE_PARAM
#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
int
yyparse (void *YYPARSE_PARAM)
#else
int
yyparse (YYPARSE_PARAM)
    void *YYPARSE_PARAM;
#endif
#else /* ! YYPARSE_PARAM */
#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
int
yyparse (void *ctxt, void *lctxt)
#else
int
yyparse (ctxt, lctxt)
    void *ctxt;
    void *lctxt;
#endif
#endif
{
  /* The look-ahead symbol.  */
int yychar;

/* The semantic value of the look-ahead symbol.  */
YYSTYPE yylval;

/* Number of syntax errors so far.  */
int yynerrs;

  int yystate;
  int yyn;
  int yyresult;
  /* Number of tokens to shift before error messages enabled.  */
  int yyerrstatus;
  /* Look-ahead token as an internal (translated) token number.  */
  int yytoken = 0;
#if YYERROR_VERBOSE
  /* Buffer for error messages, and its allocated size.  */
  char yymsgbuf[128];
  char *yymsg = yymsgbuf;
  YYSIZE_T yymsg_alloc = sizeof yymsgbuf;
#endif

  /* Three stacks and their tools:
     `yyss': related to states,
     `yyvs': related to semantic values,
     `yyls': related to locations.

     Refer to the stacks thru separate pointers, to allow yyoverflow
     to reallocate them elsewhere.  */

  /* The state stack.  */
  yytype_int16 yyssa[YYINITDEPTH];
  yytype_int16 *yyss = yyssa;
  yytype_int16 *yyssp;

  /* The semantic value stack.  */
  YYSTYPE yyvsa[YYINITDEPTH];
  YYSTYPE *yyvs = yyvsa;
  YYSTYPE *yyvsp;



#define YYPOPSTACK(N)   (yyvsp -= (N), yyssp -= (N))

  YYSIZE_T yystacksize = YYINITDEPTH;

  /* The variables used to return semantic value and location from the
     action routines.  */
  YYSTYPE yyval;


  /* The number of symbols on the RHS of the reduced rule.
     Keep to zero when no symbol should be popped.  */
  int yylen = 0;

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
     have just been pushed.  So pushing a state here evens the stacks.  */
  yyssp++;

 yysetstate:
  *yyssp = yystate;

  if (yyss + yystacksize - 1 <= yyssp)
    {
      /* Get the current used size of the three stacks, in elements.  */
      YYSIZE_T yysize = yyssp - yyss + 1;

#ifdef yyoverflow
      {
	/* Give user a chance to reallocate the stack.  Use copies of
	   these so that the &'s don't force the real ones into
	   memory.  */
	YYSTYPE *yyvs1 = yyvs;
	yytype_int16 *yyss1 = yyss;


	/* Each stack pointer address is followed by the size of the
	   data in use in that stack, in bytes.  This used to be a
	   conditional around just the two extra args, but that might
	   be undefined if yyoverflow is a macro.  */
	yyoverflow (YY_("memory exhausted"),
		    &yyss1, yysize * sizeof (*yyssp),
		    &yyvs1, yysize * sizeof (*yyvsp),

		    &yystacksize);

	yyss = yyss1;
	yyvs = yyvs1;
      }
#else /* no yyoverflow */
# ifndef YYSTACK_RELOCATE
      goto yyexhaustedlab;
# else
      /* Extend the stack our own way.  */
      if (YYMAXDEPTH <= yystacksize)
	goto yyexhaustedlab;
      yystacksize *= 2;
      if (YYMAXDEPTH < yystacksize)
	yystacksize = YYMAXDEPTH;

      {
	yytype_int16 *yyss1 = yyss;
	union yyalloc *yyptr =
	  (union yyalloc *) YYSTACK_ALLOC (YYSTACK_BYTES (yystacksize));
	if (! yyptr)
	  goto yyexhaustedlab;
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

  /* Do appropriate processing given the current state.  Read a
     look-ahead token if we need one and don't already have one.  */

  /* First try to decide what to do without reference to look-ahead token.  */
  yyn = yypact[yystate];
  if (yyn == YYPACT_NINF)
    goto yydefault;

  /* Not known => get a look-ahead token if don't already have one.  */

  /* YYCHAR is either YYEMPTY or YYEOF or a valid look-ahead symbol.  */
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
      YY_SYMBOL_PRINT ("Next token is", yytoken, &yylval, &yylloc);
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

  /* Count tokens shifted since error; after three, turn off error
     status.  */
  if (yyerrstatus)
    yyerrstatus--;

  /* Shift the look-ahead token.  */
  YY_SYMBOL_PRINT ("Shifting", yytoken, &yylval, &yylloc);

  /* Discard the shifted token unless it is eof.  */
  if (yychar != YYEOF)
    yychar = YYEMPTY;

  yystate = yyn;
  *++yyvsp = yylval;

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
#line 180 "rtfGrammar.y"
    { GSRTFstart(CTXT); ;}
    break;

  case 3:
#line 180 "rtfGrammar.y"
    { GSRTFstop(CTXT); ;}
    break;

  case 5:
#line 183 "rtfGrammar.y"
    { (yyval.number) = 1; ;}
    break;

  case 6:
#line 184 "rtfGrammar.y"
    { (yyval.number) = 2; ;}
    break;

  case 7:
#line 185 "rtfGrammar.y"
    { (yyval.number) = 3; ;}
    break;

  case 8:
#line 186 "rtfGrammar.y"
    { (yyval.number) = 4; ;}
    break;

  case 9:
#line 188 "rtfGrammar.y"
    { (yyval.number) = 1; free((void*)(yyvsp[(1) - (1)].cmd).name); ;}
    break;

  case 14:
#line 195 "rtfGrammar.y"
    { GSRTFmangleText(CTXT, (yyvsp[(2) - (2)].text)); free((void *)(yyvsp[(2) - (2)].text)); ;}
    break;

  case 17:
#line 200 "rtfGrammar.y"
    { GSRTFopenBlock(CTXT, NO); ;}
    break;

  case 18:
#line 200 "rtfGrammar.y"
    { GSRTFcloseBlock(CTXT, NO); ;}
    break;

  case 19:
#line 201 "rtfGrammar.y"
    { GSRTFopenBlock(CTXT, YES); ;}
    break;

  case 20:
#line 201 "rtfGrammar.y"
    { GSRTFcloseBlock(CTXT, YES); ;}
    break;

  case 21:
#line 202 "rtfGrammar.y"
    { GSRTFopenBlock(CTXT, YES); ;}
    break;

  case 22:
#line 202 "rtfGrammar.y"
    { GSRTFcloseBlock(CTXT, YES); ;}
    break;

  case 23:
#line 203 "rtfGrammar.y"
    { GSRTFopenBlock(CTXT, YES); ;}
    break;

  case 24:
#line 203 "rtfGrammar.y"
    { GSRTFcloseBlock(CTXT, YES); ;}
    break;

  case 25:
#line 204 "rtfGrammar.y"
    { GSRTFopenBlock(CTXT, YES); ;}
    break;

  case 26:
#line 204 "rtfGrammar.y"
    { GSRTFcloseBlock(CTXT, YES); ;}
    break;

  case 27:
#line 205 "rtfGrammar.y"
    { GSRTFopenBlock(CTXT, YES); ;}
    break;

  case 28:
#line 205 "rtfGrammar.y"
    { GSRTFcloseBlock(CTXT, YES); ;}
    break;

  case 29:
#line 206 "rtfGrammar.y"
    { GSRTFopenBlock(CTXT, YES); ;}
    break;

  case 30:
#line 206 "rtfGrammar.y"
    { GSRTFcloseBlock(CTXT, YES); ;}
    break;

  case 31:
#line 207 "rtfGrammar.y"
    { GSRTFopenBlock(CTXT, YES); ;}
    break;

  case 32:
#line 207 "rtfGrammar.y"
    { GSRTFcloseBlock(CTXT, YES); ;}
    break;

  case 34:
#line 216 "rtfGrammar.y"
    { int font;
		    
						  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      font = 0;
						  else
						      font = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFfontNumber(CTXT, font); ;}
    break;

  case 35:
#line 223 "rtfGrammar.y"
    { int size;

						  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      size = 24;
						  else
						      size = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFfontSize(CTXT, size); ;}
    break;

  case 36:
#line 230 "rtfGrammar.y"
    { int width; 
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      width = 12240;
						  else
						      width = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFpaperWidth(CTXT, width);;}
    break;

  case 37:
#line 237 "rtfGrammar.y"
    { int height; 
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      height = 15840;
						  else
						      height = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFpaperHeight(CTXT, height);;}
    break;

  case 38:
#line 244 "rtfGrammar.y"
    { int margin; 
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      margin = 1800;
						  else
						      margin = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFmarginLeft(CTXT, margin);;}
    break;

  case 39:
#line 251 "rtfGrammar.y"
    { int margin; 
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      margin = 1800;
						  else
						      margin = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFmarginRight(CTXT, margin); ;}
    break;

  case 40:
#line 258 "rtfGrammar.y"
    { int margin; 
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      margin = 1440;
						  else
						      margin = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFmarginTop(CTXT, margin); ;}
    break;

  case 41:
#line 265 "rtfGrammar.y"
    { int margin; 
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      margin = 1440;
						  else
						      margin = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFmarginButtom(CTXT, margin); ;}
    break;

  case 42:
#line 272 "rtfGrammar.y"
    { int indent; 
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      indent = 0;
						  else
						      indent = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFfirstLineIndent(CTXT, indent); ;}
    break;

  case 43:
#line 279 "rtfGrammar.y"
    { int indent; 
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      indent = 0;
						  else
						      indent = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFleftIndent(CTXT, indent);;}
    break;

  case 44:
#line 286 "rtfGrammar.y"
    { int indent; 
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      indent = 0;
						  else
						      indent = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFrightIndent(CTXT, indent);;}
    break;

  case 45:
#line 293 "rtfGrammar.y"
    { int location; 
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      location = 0;
						  else
						      location = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFtabstop(CTXT, location);;}
    break;

  case 46:
#line 300 "rtfGrammar.y"
    { GSRTFalignCenter(CTXT); ;}
    break;

  case 47:
#line 301 "rtfGrammar.y"
    { GSRTFalignJustified(CTXT); ;}
    break;

  case 48:
#line 302 "rtfGrammar.y"
    { GSRTFalignLeft(CTXT); ;}
    break;

  case 49:
#line 303 "rtfGrammar.y"
    { GSRTFalignRight(CTXT); ;}
    break;

  case 50:
#line 304 "rtfGrammar.y"
    { int space; 
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      space = 0;
						  else
						      space = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFspaceAbove(CTXT, space); ;}
    break;

  case 51:
#line 311 "rtfGrammar.y"
    { GSRTFlineSpace(CTXT, (yyvsp[(1) - (1)].cmd).parameter); ;}
    break;

  case 52:
#line 312 "rtfGrammar.y"
    { GSRTFdefaultParagraph(CTXT); ;}
    break;

  case 53:
#line 313 "rtfGrammar.y"
    { GSRTFstyle(CTXT, (yyvsp[(1) - (1)].cmd).parameter); ;}
    break;

  case 54:
#line 314 "rtfGrammar.y"
    { int color; 
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      color = 0;
						  else
						      color = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFcolorbg(CTXT, color); ;}
    break;

  case 55:
#line 321 "rtfGrammar.y"
    { int color; 
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      color = 0;
						  else
						      color = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFcolorfg(CTXT, color); ;}
    break;

  case 56:
#line 328 "rtfGrammar.y"
    { int script;
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      script = 6;
						  else
						      script = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFsubscript(CTXT, script); ;}
    break;

  case 57:
#line 335 "rtfGrammar.y"
    { int script;
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      script = 6;
						  else
						      script = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFsuperscript(CTXT, script); ;}
    break;

  case 58:
#line 342 "rtfGrammar.y"
    { BOOL on;

		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty || (yyvsp[(1) - (1)].cmd).parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFbold(CTXT, on); ;}
    break;

  case 59:
#line 349 "rtfGrammar.y"
    { BOOL on;

		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty || (yyvsp[(1) - (1)].cmd).parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFitalic(CTXT, on); ;}
    break;

  case 60:
#line 356 "rtfGrammar.y"
    { BOOL on;

		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty || (yyvsp[(1) - (1)].cmd).parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFunderline(CTXT, on); ;}
    break;

  case 61:
#line 363 "rtfGrammar.y"
    { GSRTFunderline(CTXT, NO); ;}
    break;

  case 62:
#line 364 "rtfGrammar.y"
    { GSRTFunicode(CTXT, (yyvsp[(1) - (1)].cmd).parameter); ;}
    break;

  case 63:
#line 365 "rtfGrammar.y"
    { GSRTFdefaultCharacterStyle(CTXT); ;}
    break;

  case 64:
#line 366 "rtfGrammar.y"
    { GSRTFparagraph(CTXT); ;}
    break;

  case 65:
#line 367 "rtfGrammar.y"
    { GSRTFparagraph(CTXT); ;}
    break;

  case 66:
#line 368 "rtfGrammar.y"
    { GSRTFgenericRTFcommand(CTXT, (yyvsp[(1) - (1)].cmd)); 
		                                  free((void*)(yyvsp[(1) - (1)].cmd).name); ;}
    break;

  case 71:
#line 387 "rtfGrammar.y"
    { GSRTFopenBlock(CTXT, YES); ;}
    break;

  case 72:
#line 387 "rtfGrammar.y"
    { GSRTFcloseBlock(CTXT, YES); ;}
    break;

  case 73:
#line 388 "rtfGrammar.y"
    {
			GSRTFNeXTGraphic (CTXT, (yyvsp[(3) - (9)].text), (yyvsp[(4) - (9)].cmd).parameter, (yyvsp[(5) - (9)].cmd).parameter);
		;}
    break;

  case 74:
#line 402 "rtfGrammar.y"
    { GSRTFopenBlock(CTXT, YES); ;}
    break;

  case 75:
#line 402 "rtfGrammar.y"
    { GSRTFcloseBlock(CTXT, YES); ;}
    break;

  case 76:
#line 403 "rtfGrammar.y"
    {
			GSRTFNeXTHelpLink (CTXT, (yyvsp[(2) - (12)].cmd).parameter, (yyvsp[(4) - (12)].text), (yyvsp[(6) - (12)].text), (yyvsp[(8) - (12)].text));
		;}
    break;

  case 77:
#line 416 "rtfGrammar.y"
    { GSRTFopenBlock(CTXT, YES); ;}
    break;

  case 78:
#line 416 "rtfGrammar.y"
    { GSRTFcloseBlock(CTXT, YES); ;}
    break;

  case 79:
#line 417 "rtfGrammar.y"
    {
			GSRTFNeXTHelpMarker (CTXT, (yyvsp[(2) - (8)].cmd).parameter, (yyvsp[(4) - (8)].text));
		;}
    break;

  case 84:
#line 432 "rtfGrammar.y"
    { free((void *)(yyvsp[(5) - (6)].text));;}
    break;

  case 85:
#line 437 "rtfGrammar.y"
    { GSRTFregisterFont(CTXT, (yyvsp[(4) - (4)].text), (yyvsp[(2) - (4)].number), (yyvsp[(1) - (4)].cmd).parameter);
                                                          free((void *)(yyvsp[(4) - (4)].text)); ;}
    break;

  case 91:
#line 450 "rtfGrammar.y"
    { (yyval.number) = RTFfamilyNil - RTFfamilyNil; ;}
    break;

  case 92:
#line 451 "rtfGrammar.y"
    { (yyval.number) = RTFfamilyRoman - RTFfamilyNil; ;}
    break;

  case 93:
#line 452 "rtfGrammar.y"
    { (yyval.number) = RTFfamilySwiss - RTFfamilyNil; ;}
    break;

  case 94:
#line 453 "rtfGrammar.y"
    { (yyval.number) = RTFfamilyModern - RTFfamilyNil; ;}
    break;

  case 95:
#line 454 "rtfGrammar.y"
    { (yyval.number) = RTFfamilyScript - RTFfamilyNil; ;}
    break;

  case 96:
#line 455 "rtfGrammar.y"
    { (yyval.number) = RTFfamilyDecor - RTFfamilyNil; ;}
    break;

  case 97:
#line 456 "rtfGrammar.y"
    { (yyval.number) = RTFfamilyTech - RTFfamilyNil; ;}
    break;

  case 101:
#line 473 "rtfGrammar.y"
    { 
		       GSRTFaddColor(CTXT, (yyvsp[(1) - (4)].cmd).parameter, (yyvsp[(2) - (4)].cmd).parameter, (yyvsp[(3) - (4)].cmd).parameter);
		       free((void *)(yyvsp[(4) - (4)].text));
		     ;}
    break;

  case 102:
#line 478 "rtfGrammar.y"
    { 
		       GSRTFaddDefaultColor(CTXT);
		       free((void *)(yyvsp[(1) - (1)].text));
		     ;}
    break;


/* Line 1267 of yacc.c.  */
#line 2429 "rtfGrammar.tab.c"
      default: break;
    }
  YY_SYMBOL_PRINT ("-> $$ =", yyr1[yyn], &yyval, &yyloc);

  YYPOPSTACK (yylen);
  yylen = 0;
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
#if ! YYERROR_VERBOSE
      yyerror (ctxt, lctxt, YY_("syntax error"));
#else
      {
	YYSIZE_T yysize = yysyntax_error (0, yystate, yychar);
	if (yymsg_alloc < yysize && yymsg_alloc < YYSTACK_ALLOC_MAXIMUM)
	  {
	    YYSIZE_T yyalloc = 2 * yysize;
	    if (! (yysize <= yyalloc && yyalloc <= YYSTACK_ALLOC_MAXIMUM))
	      yyalloc = YYSTACK_ALLOC_MAXIMUM;
	    if (yymsg != yymsgbuf)
	      YYSTACK_FREE (yymsg);
	    yymsg = (char *) YYSTACK_ALLOC (yyalloc);
	    if (yymsg)
	      yymsg_alloc = yyalloc;
	    else
	      {
		yymsg = yymsgbuf;
		yymsg_alloc = sizeof yymsgbuf;
	      }
	  }

	if (0 < yysize && yysize <= yymsg_alloc)
	  {
	    (void) yysyntax_error (yymsg, yystate, yychar);
	    yyerror (ctxt, lctxt, yymsg);
	  }
	else
	  {
	    yyerror (ctxt, lctxt, YY_("syntax error"));
	    if (yysize != 0)
	      goto yyexhaustedlab;
	  }
      }
#endif
    }



  if (yyerrstatus == 3)
    {
      /* If just tried and failed to reuse look-ahead token after an
	 error, discard it.  */

      if (yychar <= YYEOF)
	{
	  /* Return failure if at end of input.  */
	  if (yychar == YYEOF)
	    YYABORT;
	}
      else
	{
	  yydestruct ("Error: discarding",
		      yytoken, &yylval, ctxt, lctxt);
	  yychar = YYEMPTY;
	}
    }

  /* Else will try to reuse look-ahead token after shifting the error
     token.  */
  goto yyerrlab1;


/*---------------------------------------------------.
| yyerrorlab -- error raised explicitly by YYERROR.  |
`---------------------------------------------------*/
yyerrorlab:

  /* Pacify compilers like GCC when the user code never invokes
     YYERROR and the label yyerrorlab therefore never appears in user
     code.  */
  if (/*CONSTCOND*/ 0)
     goto yyerrorlab;

  /* Do not reclaim the symbols of the rule which action triggered
     this YYERROR.  */
  YYPOPSTACK (yylen);
  yylen = 0;
  YY_STACK_PRINT (yyss, yyssp);
  yystate = *yyssp;
  goto yyerrlab1;


/*-------------------------------------------------------------.
| yyerrlab1 -- common code for both syntax error and YYERROR.  |
`-------------------------------------------------------------*/
yyerrlab1:
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


      yydestruct ("Error: popping",
		  yystos[yystate], yyvsp, ctxt, lctxt);
      YYPOPSTACK (1);
      yystate = *yyssp;
      YY_STACK_PRINT (yyss, yyssp);
    }

  if (yyn == YYFINAL)
    YYACCEPT;

  *++yyvsp = yylval;


  /* Shift the error token.  */
  YY_SYMBOL_PRINT ("Shifting", yystos[yyn], yyvsp, yylsp);

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
/*-------------------------------------------------.
| yyexhaustedlab -- memory exhaustion comes here.  |
`-------------------------------------------------*/
yyexhaustedlab:
  yyerror (ctxt, lctxt, YY_("memory exhausted"));
  yyresult = 2;
  /* Fall through.  */
#endif

yyreturn:
  if (yychar != YYEOF && yychar != YYEMPTY)
     yydestruct ("Cleanup: discarding lookahead",
		 yytoken, &yylval, ctxt, lctxt);
  /* Do not reclaim the symbols of the rule which action triggered
     this YYABORT or YYACCEPT.  */
  YYPOPSTACK (yylen);
  YY_STACK_PRINT (yyss, yyssp);
  while (yyssp != yyss)
    {
      yydestruct ("Cleanup: popping",
		  yystos[*yyssp], yyvsp, ctxt, lctxt);
      YYPOPSTACK (1);
    }
#ifndef yyoverflow
  if (yyss != yyssa)
    YYSTACK_FREE (yyss);
#endif
#if YYERROR_VERBOSE
  if (yymsg != yymsgbuf)
    YYSTACK_FREE (yymsg);
#endif
  /* Make sure YYID is used.  */
  return YYID (yyresult);
}


#line 490 "rtfGrammar.y"


/*	some C code here	*/


