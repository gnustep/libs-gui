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
     RTFpaperWidth = 297,
     RTFpaperHeight = 298,
     RTFmarginLeft = 299,
     RTFmarginRight = 300,
     RTFmarginTop = 301,
     RTFmarginButtom = 302,
     RTFfirstLineIndent = 303,
     RTFleftIndent = 304,
     RTFrightIndent = 305,
     RTFalignCenter = 306,
     RTFalignJustified = 307,
     RTFalignLeft = 308,
     RTFalignRight = 309,
     RTFlineSpace = 310,
     RTFspaceAbove = 311,
     RTFstyle = 312,
     RTFbold = 313,
     RTFitalic = 314,
     RTFunderline = 315,
     RTFunderlineStop = 316,
     RTFunichar = 317,
     RTFsubscript = 318,
     RTFsuperscript = 319,
     RTFtabstop = 320,
     RTFfcharset = 321,
     RTFfprq = 322,
     RTFcpg = 323,
     RTFOtherStatement = 324,
     RTFfontListStart = 325,
     RTFfamilyNil = 326,
     RTFfamilyRoman = 327,
     RTFfamilySwiss = 328,
     RTFfamilyModern = 329,
     RTFfamilyScript = 330,
     RTFfamilyDecor = 331,
     RTFfamilyTech = 332
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
#define RTFpaperWidth 297
#define RTFpaperHeight 298
#define RTFmarginLeft 299
#define RTFmarginRight 300
#define RTFmarginTop 301
#define RTFmarginButtom 302
#define RTFfirstLineIndent 303
#define RTFleftIndent 304
#define RTFrightIndent 305
#define RTFalignCenter 306
#define RTFalignJustified 307
#define RTFalignLeft 308
#define RTFalignRight 309
#define RTFlineSpace 310
#define RTFspaceAbove 311
#define RTFstyle 312
#define RTFbold 313
#define RTFitalic 314
#define RTFunderline 315
#define RTFunderlineStop 316
#define RTFunichar 317
#define RTFsubscript 318
#define RTFsuperscript 319
#define RTFtabstop 320
#define RTFfcharset 321
#define RTFfprq 322
#define RTFcpg 323
#define RTFOtherStatement 324
#define RTFfontListStart 325
#define RTFfamilyNil 326
#define RTFfamilyRoman 327
#define RTFfamilySwiss 328
#define RTFfamilyModern 329
#define RTFfamilyScript 330
#define RTFfamilyDecor 331
#define RTFfamilyTech 332




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
#line 306 "rtfGrammar.tab.c"
	YYSTYPE;
# define yystype YYSTYPE /* obsolescent; will be withdrawn */
# define YYSTYPE_IS_DECLARED 1
# define YYSTYPE_IS_TRIVIAL 1
#endif



/* Copy the second part of user declarations.  */


/* Line 216 of yacc.c.  */
#line 319 "rtfGrammar.tab.c"

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
#define YYLAST   799

/* YYNTOKENS -- Number of terminals.  */
#define YYNTOKENS  80
/* YYNNTS -- Number of nonterminals.  */
#define YYNNTS  27
/* YYNRULES -- Number of rules.  */
#define YYNRULES  93
/* YYNRULES -- Number of states.  */
#define YYNSTATES  134

/* YYTRANSLATE(YYLEX) -- Bison symbol number corresponding to YYLEX.  */
#define YYUNDEFTOK  2
#define YYMAXUTOK   332

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
       2,     2,     2,    78,     2,    79,     2,     2,     2,     2,
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
      75,    76,    77
};

#if YYDEBUG
/* YYPRHS[YYN] -- Index of the first RHS symbol of rule number YYN in
   YYRHS.  */
static const yytype_uint8 yyprhs[] =
{
       0,     0,     3,     4,     5,    13,    15,    17,    19,    21,
      23,    24,    27,    30,    33,    36,    39,    42,    45,    46,
      51,    52,    58,    59,    65,    66,    72,    73,    79,    80,
      86,    87,    93,    94,   100,   104,   106,   108,   110,   112,
     114,   116,   118,   120,   122,   124,   126,   128,   130,   132,
     134,   136,   138,   140,   142,   144,   146,   148,   150,   152,
     154,   156,   158,   160,   162,   164,   166,   168,   170,   171,
     172,   184,   189,   190,   193,   198,   205,   210,   211,   214,
     217,   220,   223,   225,   227,   229,   231,   233,   235,   237,
     242,   243,   246,   251
};

/* YYRHS -- A `-1'-separated list of the rules' RHS.  */
static const yytype_int8 yyrhs[] =
{
      81,     0,    -1,    -1,    -1,    78,    82,     4,    84,    85,
      83,    79,    -1,     5,    -1,     6,    -1,     7,    -1,     8,
      -1,    69,    -1,    -1,    85,    96,    -1,    85,    99,    -1,
      85,   104,    -1,    85,    95,    -1,    85,     3,    -1,    85,
      86,    -1,    85,     1,    -1,    -1,    78,    87,    85,    79,
      -1,    -1,    78,    88,     9,    85,    79,    -1,    -1,    78,
      89,    10,    85,    79,    -1,    -1,    78,    90,    11,    85,
      79,    -1,    -1,    78,    91,    12,    85,    79,    -1,    -1,
      78,    92,    13,    85,    79,    -1,    -1,    78,    93,    14,
      85,    79,    -1,    -1,    78,    94,    15,    85,    79,    -1,
      78,     1,    79,    -1,    37,    -1,    38,    -1,    42,    -1,
      43,    -1,    44,    -1,    45,    -1,    46,    -1,    47,    -1,
      48,    -1,    49,    -1,    50,    -1,    65,    -1,    51,    -1,
      52,    -1,    53,    -1,    54,    -1,    56,    -1,    55,    -1,
      18,    -1,    57,    -1,    34,    -1,    35,    -1,    63,    -1,
      64,    -1,    58,    -1,    59,    -1,    60,    -1,    61,    -1,
      62,    -1,    16,    -1,    17,    -1,    19,    -1,    69,    -1,
      -1,    -1,    78,    78,    39,     3,    40,    41,    79,    97,
      85,    98,    79,    -1,    78,    70,   100,    79,    -1,    -1,
     100,   101,    -1,   100,    78,   101,    79,    -1,   100,    78,
     101,    86,     3,    79,    -1,    37,   103,   102,     3,    -1,
      -1,   102,    66,    -1,   102,    67,    -1,   102,    68,    -1,
     102,    86,    -1,    71,    -1,    72,    -1,    73,    -1,    74,
      -1,    75,    -1,    76,    -1,    77,    -1,    78,    36,   105,
      79,    -1,    -1,   105,   106,    -1,    31,    32,    33,     3,
      -1,     3,    -1
};

/* YYRLINE[YYN] -- source line where rule number YYN was defined.  */
static const yytype_uint16 yyrline[] =
{
       0,   174,   174,   174,   174,   177,   178,   179,   180,   182,
     185,   186,   187,   188,   189,   190,   191,   192,   195,   195,
     196,   196,   197,   197,   198,   198,   199,   199,   200,   200,
     201,   201,   202,   202,   203,   211,   218,   225,   232,   239,
     246,   253,   260,   267,   274,   281,   288,   295,   296,   297,
     298,   299,   306,   307,   308,   309,   316,   323,   330,   337,
     344,   351,   358,   359,   360,   361,   362,   363,   376,   376,
     376,   385,   388,   389,   390,   391,   397,   401,   402,   403,
     404,   405,   410,   411,   412,   413,   414,   415,   416,   424,
     427,   428,   432,   437
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
  "RTFNeXTGraphicWidth", "RTFNeXTGraphicHeight", "RTFpaperWidth",
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
  "@6", "@7", "@8", "@9", "@10", "rtfStatement", "rtfNeXTGraphic", "@11",
  "@12", "rtfFontList", "rtfFonts", "rtfFontStatement", "rtfFontAttrs",
  "rtfFontFamily", "rtfColorDef", "rtfColors", "rtfColorStatement", 0
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
     325,   326,   327,   328,   329,   330,   331,   332,   123,   125
};
# endif

/* YYR1[YYN] -- Symbol number of symbol that rule YYN derives.  */
static const yytype_uint8 yyr1[] =
{
       0,    80,    82,    83,    81,    84,    84,    84,    84,    84,
      85,    85,    85,    85,    85,    85,    85,    85,    87,    86,
      88,    86,    89,    86,    90,    86,    91,    86,    92,    86,
      93,    86,    94,    86,    86,    95,    95,    95,    95,    95,
      95,    95,    95,    95,    95,    95,    95,    95,    95,    95,
      95,    95,    95,    95,    95,    95,    95,    95,    95,    95,
      95,    95,    95,    95,    95,    95,    95,    95,    97,    98,
      96,    99,   100,   100,   100,   100,   101,   102,   102,   102,
     102,   102,   103,   103,   103,   103,   103,   103,   103,   104,
     105,   105,   106,   106
};

/* YYR2[YYN] -- Number of symbols composing right hand side of rule YYN.  */
static const yytype_uint8 yyr2[] =
{
       0,     2,     0,     0,     7,     1,     1,     1,     1,     1,
       0,     2,     2,     2,     2,     2,     2,     2,     0,     4,
       0,     5,     0,     5,     0,     5,     0,     5,     0,     5,
       0,     5,     0,     5,     3,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     0,     0,
      11,     4,     0,     2,     4,     6,     4,     0,     2,     2,
       2,     2,     1,     1,     1,     1,     1,     1,     1,     4,
       0,     2,     4,     1
};

/* YYDEFACT[STATE-NAME] -- Default rule to reduce with in state
   STATE-NUM when YYTABLE doesn't specify something else to do.  Zero
   means the default is an error.  */
static const yytype_uint8 yydefact[] =
{
       0,     2,     0,     0,     1,     0,     5,     6,     7,     8,
       9,    10,     0,    17,    15,    64,    65,    53,    66,    55,
      56,    35,    36,    37,    38,    39,    40,    41,    42,    43,
      44,    45,    47,    48,    49,    50,    52,    51,    54,    59,
      60,    61,    62,    63,    57,    58,    46,    67,     0,     0,
      16,    14,    11,    12,    13,     0,    90,    72,     0,    10,
       0,     0,     0,     0,     0,     0,     0,     4,    34,     0,
       0,     0,     0,    10,    10,    10,    10,    10,    10,    10,
      93,     0,    89,    91,     0,     0,    71,    73,     0,    19,
       0,     0,     0,     0,     0,     0,     0,     0,    82,    83,
      84,    85,    86,    87,    88,    77,     0,     0,    21,    23,
      25,    27,    29,    31,    33,     0,     0,     0,    74,     0,
       0,    92,    76,    78,    79,    80,    81,     0,    68,    75,
      10,     0,     0,    70
};

/* YYDEFGOTO[NTERM-NUM].  */
static const yytype_int16 yydefgoto[] =
{
      -1,     2,     3,    49,    11,    12,    50,    59,    60,    61,
      62,    63,    64,    65,    66,    51,    52,   130,   132,    53,
      70,    87,   116,   105,    54,    69,    83
};

/* YYPACT[STATE-NUM] -- Index in YYTABLE of the portion describing
   STATE-NUM.  */
#define YYPACT_NINF -79
static const yytype_int16 yypact[] =
{
     -77,   -79,     6,     3,   -79,    89,   -79,   -79,   -79,   -79,
     -79,   -79,   135,   -79,   -79,   -79,   -79,   -79,   -79,   -79,
     -79,   -79,   -79,   -79,   -79,   -79,   -79,   -79,   -79,   -79,
     -79,   -79,   -79,   -79,   -79,   -79,   -79,   -79,   -79,   -79,
     -79,   -79,   -79,   -79,   -79,   -79,   -79,   -79,    -1,   -53,
     -79,   -79,   -79,   -79,   -79,   -50,   -79,   -79,    -9,   -79,
      22,    29,    21,    28,    53,    56,    52,   -79,   -79,    62,
      64,    69,   200,   -79,   -79,   -79,   -79,   -79,   -79,   -79,
     -79,    42,   -79,   -79,    88,    38,   -79,   -79,    58,   -79,
     265,   330,   395,   460,   525,   590,   655,    66,   -79,   -79,
     -79,   -79,   -79,   -79,   -79,   -79,   -75,    59,   -79,   -79,
     -79,   -79,   -79,   -79,   -79,   100,    24,    70,   -79,   103,
      30,   -79,   -79,   -79,   -79,   -79,   -79,    31,   -79,   -79,
     -79,   720,    32,   -79
};

/* YYPGOTO[NTERM-NUM].  */
static const yytype_int8 yypgoto[] =
{
     -79,   -79,   -79,   -79,   -79,   -54,   -78,   -79,   -79,   -79,
     -79,   -79,   -79,   -79,   -79,   -79,   -79,   -79,   -79,   -79,
     -79,    55,   -79,   -79,   -79,   -79,   -79
};

/* YYTABLE[YYPACT[STATE-NUM]].  What to do in state STATE-NUM.  If
   positive, shift that token.  If negative, reduce the rule which
   number is the opposite.  If zero, do what YYDEFACT says.
   If YYTABLE_NINF, syntax error.  */
#define YYTABLE_NINF -70
static const yytype_int16 yytable[] =
{
      55,     1,   -18,   117,   118,    72,     4,     5,   -20,   -22,
     -24,   -26,   -28,   -30,   -32,   -18,   -18,   -18,   -18,    90,
      91,    92,    93,    94,    95,    96,    67,   122,   119,    68,
      71,    73,    75,   -18,   -18,    56,   -18,   -18,   126,    74,
      76,   -18,   -18,   -18,   -18,   -18,   -18,   -18,   -18,   -18,
     -18,   -18,   -18,   -18,   -18,   -18,   -18,   -18,   -18,   -18,
     -18,   -18,   -18,   -18,   -18,    80,    77,    79,   -18,    57,
      78,    55,    88,   -18,    97,    84,   131,    58,   -18,   -20,
     -22,   -24,   -26,   -28,   -30,   -32,   -18,   -18,   -18,   -18,
     123,   124,   125,    81,     6,     7,     8,     9,   107,   115,
     120,    84,   117,   121,   -18,   -18,   127,   -18,   -18,   128,
     129,   133,   -18,   -18,   -18,   -18,   -18,   -18,   -18,   -18,
     -18,   -18,   -18,   -18,   -18,   -18,   -18,   -18,   -18,   -18,
     -18,   -18,   -18,   -18,   -18,   -18,    13,     0,    14,   -18,
     106,    82,    85,    86,     0,     0,     0,     0,   -18,   -18,
       0,    15,    16,    17,    18,     0,     0,     0,    10,    98,
      99,   100,   101,   102,   103,   104,     0,     0,     0,    19,
      20,     0,    21,    22,     0,     0,     0,    23,    24,    25,
      26,    27,    28,    29,    30,    31,    32,    33,    34,    35,
      36,    37,    38,    39,    40,    41,    42,    43,    44,    45,
      46,    13,     0,    14,    47,     0,     0,     0,     0,     0,
       0,     0,     0,    48,    -3,     0,    15,    16,    17,    18,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,    19,    20,     0,    21,    22,     0,
       0,     0,    23,    24,    25,    26,    27,    28,    29,    30,
      31,    32,    33,    34,    35,    36,    37,    38,    39,    40,
      41,    42,    43,    44,    45,    46,    13,     0,    14,    47,
       0,     0,     0,     0,     0,     0,     0,     0,    48,    89,
       0,    15,    16,    17,    18,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,    19,
      20,     0,    21,    22,     0,     0,     0,    23,    24,    25,
      26,    27,    28,    29,    30,    31,    32,    33,    34,    35,
      36,    37,    38,    39,    40,    41,    42,    43,    44,    45,
      46,    13,     0,    14,    47,     0,     0,     0,     0,     0,
       0,     0,     0,    48,   108,     0,    15,    16,    17,    18,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,    19,    20,     0,    21,    22,     0,
       0,     0,    23,    24,    25,    26,    27,    28,    29,    30,
      31,    32,    33,    34,    35,    36,    37,    38,    39,    40,
      41,    42,    43,    44,    45,    46,    13,     0,    14,    47,
       0,     0,     0,     0,     0,     0,     0,     0,    48,   109,
       0,    15,    16,    17,    18,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,    19,
      20,     0,    21,    22,     0,     0,     0,    23,    24,    25,
      26,    27,    28,    29,    30,    31,    32,    33,    34,    35,
      36,    37,    38,    39,    40,    41,    42,    43,    44,    45,
      46,    13,     0,    14,    47,     0,     0,     0,     0,     0,
       0,     0,     0,    48,   110,     0,    15,    16,    17,    18,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,    19,    20,     0,    21,    22,     0,
       0,     0,    23,    24,    25,    26,    27,    28,    29,    30,
      31,    32,    33,    34,    35,    36,    37,    38,    39,    40,
      41,    42,    43,    44,    45,    46,    13,     0,    14,    47,
       0,     0,     0,     0,     0,     0,     0,     0,    48,   111,
       0,    15,    16,    17,    18,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,    19,
      20,     0,    21,    22,     0,     0,     0,    23,    24,    25,
      26,    27,    28,    29,    30,    31,    32,    33,    34,    35,
      36,    37,    38,    39,    40,    41,    42,    43,    44,    45,
      46,    13,     0,    14,    47,     0,     0,     0,     0,     0,
       0,     0,     0,    48,   112,     0,    15,    16,    17,    18,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,    19,    20,     0,    21,    22,     0,
       0,     0,    23,    24,    25,    26,    27,    28,    29,    30,
      31,    32,    33,    34,    35,    36,    37,    38,    39,    40,
      41,    42,    43,    44,    45,    46,    13,     0,    14,    47,
       0,     0,     0,     0,     0,     0,     0,     0,    48,   113,
       0,    15,    16,    17,    18,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,    19,
      20,     0,    21,    22,     0,     0,     0,    23,    24,    25,
      26,    27,    28,    29,    30,    31,    32,    33,    34,    35,
      36,    37,    38,    39,    40,    41,    42,    43,    44,    45,
      46,    13,     0,    14,    47,     0,     0,     0,     0,     0,
       0,     0,     0,    48,   114,     0,    15,    16,    17,    18,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,    19,    20,     0,    21,    22,     0,
       0,     0,    23,    24,    25,    26,    27,    28,    29,    30,
      31,    32,    33,    34,    35,    36,    37,    38,    39,    40,
      41,    42,    43,    44,    45,    46,     0,     0,     0,    47,
       0,     0,     0,     0,     0,     0,     0,     0,    48,   -69
};

static const yytype_int16 yycheck[] =
{
       1,    78,     3,    78,    79,    59,     0,     4,     9,    10,
      11,    12,    13,    14,    15,    16,    17,    18,    19,    73,
      74,    75,    76,    77,    78,    79,    79,     3,   106,    79,
      39,     9,    11,    34,    35,    36,    37,    38,   116,    10,
      12,    42,    43,    44,    45,    46,    47,    48,    49,    50,
      51,    52,    53,    54,    55,    56,    57,    58,    59,    60,
      61,    62,    63,    64,    65,     3,    13,    15,    69,    70,
      14,     1,     3,     3,    32,    37,   130,    78,    79,     9,
      10,    11,    12,    13,    14,    15,    16,    17,    18,    19,
      66,    67,    68,    31,     5,     6,     7,     8,    40,    33,
      41,    37,    78,     3,    34,    35,     3,    37,    38,    79,
      79,    79,    42,    43,    44,    45,    46,    47,    48,    49,
      50,    51,    52,    53,    54,    55,    56,    57,    58,    59,
      60,    61,    62,    63,    64,    65,     1,    -1,     3,    69,
      85,    79,    78,    79,    -1,    -1,    -1,    -1,    78,    79,
      -1,    16,    17,    18,    19,    -1,    -1,    -1,    69,    71,
      72,    73,    74,    75,    76,    77,    -1,    -1,    -1,    34,
      35,    -1,    37,    38,    -1,    -1,    -1,    42,    43,    44,
      45,    46,    47,    48,    49,    50,    51,    52,    53,    54,
      55,    56,    57,    58,    59,    60,    61,    62,    63,    64,
      65,     1,    -1,     3,    69,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    78,    79,    -1,    16,    17,    18,    19,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    34,    35,    -1,    37,    38,    -1,
      -1,    -1,    42,    43,    44,    45,    46,    47,    48,    49,
      50,    51,    52,    53,    54,    55,    56,    57,    58,    59,
      60,    61,    62,    63,    64,    65,     1,    -1,     3,    69,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    78,    79,
      -1,    16,    17,    18,    19,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    34,
      35,    -1,    37,    38,    -1,    -1,    -1,    42,    43,    44,
      45,    46,    47,    48,    49,    50,    51,    52,    53,    54,
      55,    56,    57,    58,    59,    60,    61,    62,    63,    64,
      65,     1,    -1,     3,    69,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    78,    79,    -1,    16,    17,    18,    19,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    34,    35,    -1,    37,    38,    -1,
      -1,    -1,    42,    43,    44,    45,    46,    47,    48,    49,
      50,    51,    52,    53,    54,    55,    56,    57,    58,    59,
      60,    61,    62,    63,    64,    65,     1,    -1,     3,    69,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    78,    79,
      -1,    16,    17,    18,    19,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    34,
      35,    -1,    37,    38,    -1,    -1,    -1,    42,    43,    44,
      45,    46,    47,    48,    49,    50,    51,    52,    53,    54,
      55,    56,    57,    58,    59,    60,    61,    62,    63,    64,
      65,     1,    -1,     3,    69,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    78,    79,    -1,    16,    17,    18,    19,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    34,    35,    -1,    37,    38,    -1,
      -1,    -1,    42,    43,    44,    45,    46,    47,    48,    49,
      50,    51,    52,    53,    54,    55,    56,    57,    58,    59,
      60,    61,    62,    63,    64,    65,     1,    -1,     3,    69,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    78,    79,
      -1,    16,    17,    18,    19,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    34,
      35,    -1,    37,    38,    -1,    -1,    -1,    42,    43,    44,
      45,    46,    47,    48,    49,    50,    51,    52,    53,    54,
      55,    56,    57,    58,    59,    60,    61,    62,    63,    64,
      65,     1,    -1,     3,    69,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    78,    79,    -1,    16,    17,    18,    19,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    34,    35,    -1,    37,    38,    -1,
      -1,    -1,    42,    43,    44,    45,    46,    47,    48,    49,
      50,    51,    52,    53,    54,    55,    56,    57,    58,    59,
      60,    61,    62,    63,    64,    65,     1,    -1,     3,    69,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    78,    79,
      -1,    16,    17,    18,    19,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    34,
      35,    -1,    37,    38,    -1,    -1,    -1,    42,    43,    44,
      45,    46,    47,    48,    49,    50,    51,    52,    53,    54,
      55,    56,    57,    58,    59,    60,    61,    62,    63,    64,
      65,     1,    -1,     3,    69,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    78,    79,    -1,    16,    17,    18,    19,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    34,    35,    -1,    37,    38,    -1,
      -1,    -1,    42,    43,    44,    45,    46,    47,    48,    49,
      50,    51,    52,    53,    54,    55,    56,    57,    58,    59,
      60,    61,    62,    63,    64,    65,    -1,    -1,    -1,    69,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    78,    79
};

/* YYSTOS[STATE-NUM] -- The (internal number of the) accessing
   symbol of state STATE-NUM.  */
static const yytype_uint8 yystos[] =
{
       0,    78,    81,    82,     0,     4,     5,     6,     7,     8,
      69,    84,    85,     1,     3,    16,    17,    18,    19,    34,
      35,    37,    38,    42,    43,    44,    45,    46,    47,    48,
      49,    50,    51,    52,    53,    54,    55,    56,    57,    58,
      59,    60,    61,    62,    63,    64,    65,    69,    78,    83,
      86,    95,    96,    99,   104,     1,    36,    70,    78,    87,
      88,    89,    90,    91,    92,    93,    94,    79,    79,   105,
     100,    39,    85,     9,    10,    11,    12,    13,    14,    15,
       3,    31,    79,   106,    37,    78,    79,   101,     3,    79,
      85,    85,    85,    85,    85,    85,    85,    32,    71,    72,
      73,    74,    75,    76,    77,   103,   101,    40,    79,    79,
      79,    79,    79,    79,    79,    33,   102,    78,    79,    86,
      41,     3,     3,    66,    67,    68,    86,     3,    79,    79,
      97,    85,    98,    79
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
#line 174 "rtfGrammar.y"
    { GSRTFstart(CTXT); ;}
    break;

  case 3:
#line 174 "rtfGrammar.y"
    { GSRTFstop(CTXT); ;}
    break;

  case 5:
#line 177 "rtfGrammar.y"
    { (yyval.number) = 1; ;}
    break;

  case 6:
#line 178 "rtfGrammar.y"
    { (yyval.number) = 2; ;}
    break;

  case 7:
#line 179 "rtfGrammar.y"
    { (yyval.number) = 3; ;}
    break;

  case 8:
#line 180 "rtfGrammar.y"
    { (yyval.number) = 4; ;}
    break;

  case 9:
#line 182 "rtfGrammar.y"
    { (yyval.number) = 1; free((void*)(yyvsp[(1) - (1)].cmd).name); ;}
    break;

  case 15:
#line 190 "rtfGrammar.y"
    { GSRTFmangleText(CTXT, (yyvsp[(2) - (2)].text)); free((void *)(yyvsp[(2) - (2)].text)); ;}
    break;

  case 18:
#line 195 "rtfGrammar.y"
    { GSRTFopenBlock(CTXT, NO); ;}
    break;

  case 19:
#line 195 "rtfGrammar.y"
    { GSRTFcloseBlock(CTXT, NO); ;}
    break;

  case 20:
#line 196 "rtfGrammar.y"
    { GSRTFopenBlock(CTXT, YES); ;}
    break;

  case 21:
#line 196 "rtfGrammar.y"
    { GSRTFcloseBlock(CTXT, YES); ;}
    break;

  case 22:
#line 197 "rtfGrammar.y"
    { GSRTFopenBlock(CTXT, YES); ;}
    break;

  case 23:
#line 197 "rtfGrammar.y"
    { GSRTFcloseBlock(CTXT, YES); ;}
    break;

  case 24:
#line 198 "rtfGrammar.y"
    { GSRTFopenBlock(CTXT, YES); ;}
    break;

  case 25:
#line 198 "rtfGrammar.y"
    { GSRTFcloseBlock(CTXT, YES); ;}
    break;

  case 26:
#line 199 "rtfGrammar.y"
    { GSRTFopenBlock(CTXT, YES); ;}
    break;

  case 27:
#line 199 "rtfGrammar.y"
    { GSRTFcloseBlock(CTXT, YES); ;}
    break;

  case 28:
#line 200 "rtfGrammar.y"
    { GSRTFopenBlock(CTXT, YES); ;}
    break;

  case 29:
#line 200 "rtfGrammar.y"
    { GSRTFcloseBlock(CTXT, YES); ;}
    break;

  case 30:
#line 201 "rtfGrammar.y"
    { GSRTFopenBlock(CTXT, YES); ;}
    break;

  case 31:
#line 201 "rtfGrammar.y"
    { GSRTFcloseBlock(CTXT, YES); ;}
    break;

  case 32:
#line 202 "rtfGrammar.y"
    { GSRTFopenBlock(CTXT, YES); ;}
    break;

  case 33:
#line 202 "rtfGrammar.y"
    { GSRTFcloseBlock(CTXT, YES); ;}
    break;

  case 35:
#line 211 "rtfGrammar.y"
    { int font;
		    
						  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      font = 0;
						  else
						      font = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFfontNumber(CTXT, font); ;}
    break;

  case 36:
#line 218 "rtfGrammar.y"
    { int size;

						  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      size = 24;
						  else
						      size = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFfontSize(CTXT, size); ;}
    break;

  case 37:
#line 225 "rtfGrammar.y"
    { int width; 
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      width = 12240;
						  else
						      width = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFpaperWidth(CTXT, width);;}
    break;

  case 38:
#line 232 "rtfGrammar.y"
    { int height; 
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      height = 15840;
						  else
						      height = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFpaperHeight(CTXT, height);;}
    break;

  case 39:
#line 239 "rtfGrammar.y"
    { int margin; 
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      margin = 1800;
						  else
						      margin = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFmarginLeft(CTXT, margin);;}
    break;

  case 40:
#line 246 "rtfGrammar.y"
    { int margin; 
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      margin = 1800;
						  else
						      margin = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFmarginRight(CTXT, margin); ;}
    break;

  case 41:
#line 253 "rtfGrammar.y"
    { int margin; 
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      margin = 1440;
						  else
						      margin = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFmarginTop(CTXT, margin); ;}
    break;

  case 42:
#line 260 "rtfGrammar.y"
    { int margin; 
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      margin = 1440;
						  else
						      margin = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFmarginButtom(CTXT, margin); ;}
    break;

  case 43:
#line 267 "rtfGrammar.y"
    { int indent; 
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      indent = 0;
						  else
						      indent = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFfirstLineIndent(CTXT, indent); ;}
    break;

  case 44:
#line 274 "rtfGrammar.y"
    { int indent; 
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      indent = 0;
						  else
						      indent = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFleftIndent(CTXT, indent);;}
    break;

  case 45:
#line 281 "rtfGrammar.y"
    { int indent; 
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      indent = 0;
						  else
						      indent = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFrightIndent(CTXT, indent);;}
    break;

  case 46:
#line 288 "rtfGrammar.y"
    { int location; 
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      location = 0;
						  else
						      location = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFtabstop(CTXT, location);;}
    break;

  case 47:
#line 295 "rtfGrammar.y"
    { GSRTFalignCenter(CTXT); ;}
    break;

  case 48:
#line 296 "rtfGrammar.y"
    { GSRTFalignJustified(CTXT); ;}
    break;

  case 49:
#line 297 "rtfGrammar.y"
    { GSRTFalignLeft(CTXT); ;}
    break;

  case 50:
#line 298 "rtfGrammar.y"
    { GSRTFalignRight(CTXT); ;}
    break;

  case 51:
#line 299 "rtfGrammar.y"
    { int space; 
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      space = 0;
						  else
						      space = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFspaceAbove(CTXT, space); ;}
    break;

  case 52:
#line 306 "rtfGrammar.y"
    { GSRTFlineSpace(CTXT, (yyvsp[(1) - (1)].cmd).parameter); ;}
    break;

  case 53:
#line 307 "rtfGrammar.y"
    { GSRTFdefaultParagraph(CTXT); ;}
    break;

  case 54:
#line 308 "rtfGrammar.y"
    { GSRTFstyle(CTXT, (yyvsp[(1) - (1)].cmd).parameter); ;}
    break;

  case 55:
#line 309 "rtfGrammar.y"
    { int color; 
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      color = 0;
						  else
						      color = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFcolorbg(CTXT, color); ;}
    break;

  case 56:
#line 316 "rtfGrammar.y"
    { int color; 
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      color = 0;
						  else
						      color = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFcolorfg(CTXT, color); ;}
    break;

  case 57:
#line 323 "rtfGrammar.y"
    { int script;
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      script = 6;
						  else
						      script = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFsubscript(CTXT, script); ;}
    break;

  case 58:
#line 330 "rtfGrammar.y"
    { int script;
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      script = 6;
						  else
						      script = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFsuperscript(CTXT, script); ;}
    break;

  case 59:
#line 337 "rtfGrammar.y"
    { BOOL on;

		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty || (yyvsp[(1) - (1)].cmd).parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFbold(CTXT, on); ;}
    break;

  case 60:
#line 344 "rtfGrammar.y"
    { BOOL on;

		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty || (yyvsp[(1) - (1)].cmd).parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFitalic(CTXT, on); ;}
    break;

  case 61:
#line 351 "rtfGrammar.y"
    { BOOL on;

		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty || (yyvsp[(1) - (1)].cmd).parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFunderline(CTXT, on); ;}
    break;

  case 62:
#line 358 "rtfGrammar.y"
    { GSRTFunderline(CTXT, NO); ;}
    break;

  case 63:
#line 359 "rtfGrammar.y"
    { GSRTFunicode(CTXT, (yyvsp[(1) - (1)].cmd).parameter); ;}
    break;

  case 64:
#line 360 "rtfGrammar.y"
    { GSRTFdefaultCharacterStyle(CTXT); ;}
    break;

  case 65:
#line 361 "rtfGrammar.y"
    { GSRTFparagraph(CTXT); ;}
    break;

  case 66:
#line 362 "rtfGrammar.y"
    { GSRTFparagraph(CTXT); ;}
    break;

  case 67:
#line 363 "rtfGrammar.y"
    { GSRTFgenericRTFcommand(CTXT, (yyvsp[(1) - (1)].cmd)); 
		                                  free((void*)(yyvsp[(1) - (1)].cmd).name); ;}
    break;

  case 68:
#line 376 "rtfGrammar.y"
    { GSRTFopenBlock(CTXT, YES); ;}
    break;

  case 69:
#line 376 "rtfGrammar.y"
    { GSRTFcloseBlock(CTXT, YES); ;}
    break;

  case 70:
#line 377 "rtfGrammar.y"
    {
			GSRTFNeXTGraphic (CTXT, (yyvsp[(4) - (11)].text), (yyvsp[(5) - (11)].cmd).parameter, (yyvsp[(6) - (11)].cmd).parameter);
		;}
    break;

  case 75:
#line 392 "rtfGrammar.y"
    { free((void *)(yyvsp[(5) - (6)].text));;}
    break;

  case 76:
#line 397 "rtfGrammar.y"
    { GSRTFregisterFont(CTXT, (yyvsp[(4) - (4)].text), (yyvsp[(2) - (4)].number), (yyvsp[(1) - (4)].cmd).parameter);
                                                          free((void *)(yyvsp[(4) - (4)].text)); ;}
    break;

  case 82:
#line 410 "rtfGrammar.y"
    { (yyval.number) = RTFfamilyNil - RTFfamilyNil; ;}
    break;

  case 83:
#line 411 "rtfGrammar.y"
    { (yyval.number) = RTFfamilyRoman - RTFfamilyNil; ;}
    break;

  case 84:
#line 412 "rtfGrammar.y"
    { (yyval.number) = RTFfamilySwiss - RTFfamilyNil; ;}
    break;

  case 85:
#line 413 "rtfGrammar.y"
    { (yyval.number) = RTFfamilyModern - RTFfamilyNil; ;}
    break;

  case 86:
#line 414 "rtfGrammar.y"
    { (yyval.number) = RTFfamilyScript - RTFfamilyNil; ;}
    break;

  case 87:
#line 415 "rtfGrammar.y"
    { (yyval.number) = RTFfamilyDecor - RTFfamilyNil; ;}
    break;

  case 88:
#line 416 "rtfGrammar.y"
    { (yyval.number) = RTFfamilyTech - RTFfamilyNil; ;}
    break;

  case 92:
#line 433 "rtfGrammar.y"
    { 
		       GSRTFaddColor(CTXT, (yyvsp[(1) - (4)].cmd).parameter, (yyvsp[(2) - (4)].cmd).parameter, (yyvsp[(3) - (4)].cmd).parameter);
		       free((void *)(yyvsp[(4) - (4)].text));
		     ;}
    break;

  case 93:
#line 438 "rtfGrammar.y"
    { 
		       GSRTFaddDefaultColor(CTXT);
		       free((void *)(yyvsp[(1) - (1)].text));
		     ;}
    break;


/* Line 1267 of yacc.c.  */
#line 2293 "rtfGrammar.tab.c"
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


#line 450 "rtfGrammar.y"


/*	some C code here	*/


