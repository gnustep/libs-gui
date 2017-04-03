/* A Bison parser, made by GNU Bison 2.7.  */

/* Bison implementation for Yacc-like parsers in C
   
      Copyright (C) 1984, 1989-1990, 2000-2012 Free Software Foundation, Inc.
   
   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.
   
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.  */

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
#define YYBISON_VERSION "2.7"

/* Skeleton name.  */
#define YYSKELETON_NAME "yacc.c"

/* Pure parsers.  */
#define YYPURE 1

/* Push parsers.  */
#define YYPUSH 0

/* Pull parsers.  */
#define YYPULL 1


/* Substitute the variable and function names.  */
#define yyparse         GSRTFparse
#define yylex           GSRTFlex
#define yyerror         GSRTFerror
#define yylval          GSRTFlval
#define yychar          GSRTFchar
#define yydebug         GSRTFdebug
#define yynerrs         GSRTFnerrs

/* Copy the first part of user declarations.  */
/* Line 371 of yacc.c  */
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

#import <AppKit/AppKit.h>
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
#define YYDEBUG 1

#include "RTFConsumerFunctions.h"
/*int GSRTFlex (YYSTYPE *lvalp, RTFscannerCtxt *lctxt); */
int GSRTFlex(void *lvalp, void *lctxt);

/* */
int fieldStart = 0;


/* Line 371 of yacc.c  */
#line 121 "rtfGrammar.tab.m"

# ifndef YY_NULL
#  if defined __cplusplus && 201103L <= __cplusplus
#   define YY_NULL nullptr
#  else
#   define YY_NULL 0
#  endif
# endif

/* Enabling verbose error messages.  */
#ifdef YYERROR_VERBOSE
# undef YYERROR_VERBOSE
# define YYERROR_VERBOSE 1
#else
# define YYERROR_VERBOSE 0
#endif

/* In a future release of Bison, this section will be replaced
   by #include "rtfGrammar.tab.h".  */
#ifndef YY_GSRTF_RTFGRAMMAR_TAB_H_INCLUDED
# define YY_GSRTF_RTFGRAMMAR_TAB_H_INCLUDED
/* Enabling traces.  */
#ifndef YYDEBUG
# define YYDEBUG 0
#endif
#if YYDEBUG
extern int GSRTFdebug;
#endif

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
     RTFfield = 282,
     RTFfldinst = 283,
     RTFfldalt = 284,
     RTFfldrslt = 285,
     RTFflddirty = 286,
     RTFfldedit = 287,
     RTFfldlock = 288,
     RTFfldpriv = 289,
     RTFfttruetype = 290,
     RTFlquote = 291,
     RTFrquote = 292,
     RTFldblquote = 293,
     RTFrdblquote = 294,
     RTFred = 295,
     RTFgreen = 296,
     RTFblue = 297,
     RTFcolorbg = 298,
     RTFcolorfg = 299,
     RTFunderlinecolor = 300,
     RTFcolortable = 301,
     RTFfont = 302,
     RTFfontSize = 303,
     RTFNeXTGraphic = 304,
     RTFNeXTGraphicWidth = 305,
     RTFNeXTGraphicHeight = 306,
     RTFNeXTHelpLink = 307,
     RTFNeXTHelpMarker = 308,
     RTFNeXTfilename = 309,
     RTFNeXTmarkername = 310,
     RTFNeXTlinkFilename = 311,
     RTFNeXTlinkMarkername = 312,
     RTFpaperWidth = 313,
     RTFpaperHeight = 314,
     RTFmarginLeft = 315,
     RTFmarginRight = 316,
     RTFmarginTop = 317,
     RTFmarginButtom = 318,
     RTFfirstLineIndent = 319,
     RTFleftIndent = 320,
     RTFrightIndent = 321,
     RTFalignCenter = 322,
     RTFalignJustified = 323,
     RTFalignLeft = 324,
     RTFalignRight = 325,
     RTFlineSpace = 326,
     RTFspaceAbove = 327,
     RTFstyle = 328,
     RTFbold = 329,
     RTFitalic = 330,
     RTFunderline = 331,
     RTFunderlineDot = 332,
     RTFunderlineDash = 333,
     RTFunderlineDashDot = 334,
     RTFunderlineDashDotDot = 335,
     RTFunderlineDouble = 336,
     RTFunderlineStop = 337,
     RTFunderlineThick = 338,
     RTFunderlineThickDot = 339,
     RTFunderlineThickDash = 340,
     RTFunderlineThickDashDot = 341,
     RTFunderlineThickDashDotDot = 342,
     RTFunderlineWord = 343,
     RTFstrikethrough = 344,
     RTFstrikethroughDouble = 345,
     RTFunichar = 346,
     RTFsubscript = 347,
     RTFsuperscript = 348,
     RTFtabstop = 349,
     RTFfcharset = 350,
     RTFfprq = 351,
     RTFcpg = 352,
     RTFOtherStatement = 353,
     RTFfontListStart = 354,
     RTFfamilyNil = 355,
     RTFfamilyRoman = 356,
     RTFfamilySwiss = 357,
     RTFfamilyModern = 358,
     RTFfamilyScript = 359,
     RTFfamilyDecor = 360,
     RTFfamilyTech = 361,
     RTFfamilyBiDi = 362
   };
#endif


#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
typedef union YYSTYPE
{
/* Line 387 of yacc.c  */
#line 85 "rtfGrammar.y"

	int		number;
	const char	*text;
	RTFcmd		cmd;


/* Line 387 of yacc.c  */
#line 278 "rtfGrammar.tab.m"
} YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define yystype YYSTYPE /* obsolescent; will be withdrawn */
# define YYSTYPE_IS_DECLARED 1
#endif


#ifdef YYPARSE_PARAM
#if defined __STDC__ || defined __cplusplus
int GSRTFparse (void *YYPARSE_PARAM);
#else
int GSRTFparse ();
#endif
#else /* ! YYPARSE_PARAM */
#if defined __STDC__ || defined __cplusplus
int GSRTFparse (void *ctxt, void *lctxt);
#else
int GSRTFparse ();
#endif
#endif /* ! YYPARSE_PARAM */

#endif /* !YY_GSRTF_RTFGRAMMAR_TAB_H_INCLUDED  */

/* Copy the second part of user declarations.  */

/* Line 390 of yacc.c  */
#line 305 "rtfGrammar.tab.m"

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
#   define YY_(Msgid) dgettext ("bison-runtime", Msgid)
#  endif
# endif
# ifndef YY_
#  define YY_(Msgid) Msgid
# endif
#endif

/* Suppress unused-variable warnings by "using" E.  */
#if ! defined lint || defined __GNUC__
# define YYUSE(E) ((void) (E))
#else
# define YYUSE(E) /* empty */
#endif

/* Identity function, used to suppress warnings about constant conditions.  */
#ifndef lint
# define YYID(N) (N)
#else
#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
static int
YYID (int yyi)
#else
static int
YYID (yyi)
    int yyi;
#endif
{
  return yyi;
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
#    if ! defined _ALLOCA_H && ! defined EXIT_SUCCESS && (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
#     include <stdlib.h> /* INFRINGES ON USER NAME SPACE */
      /* Use EXIT_SUCCESS as a witness for stdlib.h.  */
#     ifndef EXIT_SUCCESS
#      define EXIT_SUCCESS 0
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
#  if (defined __cplusplus && ! defined EXIT_SUCCESS \
       && ! ((defined YYMALLOC || defined malloc) \
	     && (defined YYFREE || defined free)))
#   include <stdlib.h> /* INFRINGES ON USER NAME SPACE */
#   ifndef EXIT_SUCCESS
#    define EXIT_SUCCESS 0
#   endif
#  endif
#  ifndef YYMALLOC
#   define YYMALLOC malloc
#   if ! defined malloc && ! defined EXIT_SUCCESS && (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
void *malloc (YYSIZE_T); /* INFRINGES ON USER NAME SPACE */
#   endif
#  endif
#  ifndef YYFREE
#   define YYFREE free
#   if ! defined free && ! defined EXIT_SUCCESS && (defined __STDC__ || defined __C99__FUNC__ \
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
  yytype_int16 yyss_alloc;
  YYSTYPE yyvs_alloc;
};

/* The size of the maximum gap between one aligned stack and the next.  */
# define YYSTACK_GAP_MAXIMUM (sizeof (union yyalloc) - 1)

/* The size of an array large to enough to hold all stacks, each with
   N elements.  */
# define YYSTACK_BYTES(N) \
     ((N) * (sizeof (yytype_int16) + sizeof (YYSTYPE)) \
      + YYSTACK_GAP_MAXIMUM)

# define YYCOPY_NEEDED 1

/* Relocate STACK from its old location to the new one.  The
   local variables YYSIZE and YYSTACKSIZE give the old and new number of
   elements in the stack, and YYPTR gives the new location of the
   stack.  Advance YYPTR to a properly aligned location for the next
   stack.  */
# define YYSTACK_RELOCATE(Stack_alloc, Stack)				\
    do									\
      {									\
	YYSIZE_T yynewbytes;						\
	YYCOPY (&yyptr->Stack_alloc, Stack, yysize);			\
	Stack = &yyptr->Stack_alloc;					\
	yynewbytes = yystacksize * sizeof (*Stack) + YYSTACK_GAP_MAXIMUM; \
	yyptr += yynewbytes / sizeof (*yyptr);				\
      }									\
    while (YYID (0))

#endif

#if defined YYCOPY_NEEDED && YYCOPY_NEEDED
/* Copy COUNT objects from SRC to DST.  The source and destination do
   not overlap.  */
# ifndef YYCOPY
#  if defined __GNUC__ && 1 < __GNUC__
#   define YYCOPY(Dst, Src, Count) \
      __builtin_memcpy (Dst, Src, (Count) * sizeof (*(Src)))
#  else
#   define YYCOPY(Dst, Src, Count)              \
      do                                        \
        {                                       \
          YYSIZE_T yyi;                         \
          for (yyi = 0; yyi < (Count); yyi++)   \
            (Dst)[yyi] = (Src)[yyi];            \
        }                                       \
      while (YYID (0))
#  endif
# endif
#endif /* !YYCOPY_NEEDED */

/* YYFINAL -- State number of the termination state.  */
#define YYFINAL  4
/* YYLAST -- Last index in YYTABLE.  */
#define YYLAST   1734

/* YYNTOKENS -- Number of terminals.  */
#define YYNTOKENS  110
/* YYNNTS -- Number of nonterminals.  */
#define YYNNTS  45
/* YYNRULES -- Number of rules.  */
#define YYNRULES  143
/* YYNRULES -- Number of states.  */
#define YYNSTATES  218

/* YYTRANSLATE(YYLEX) -- Bison symbol number corresponding to YYLEX.  */
#define YYUNDEFTOK  2
#define YYMAXUTOK   362

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
       2,     2,     2,   108,     2,   109,     2,     2,     2,     2,
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
      75,    76,    77,    78,    79,    80,    81,    82,    83,    84,
      85,    86,    87,    88,    89,    90,    91,    92,    93,    94,
      95,    96,    97,    98,    99,   100,   101,   102,   103,   104,
     105,   106,   107
};

#if YYDEBUG
/* YYPRHS[YYN] -- Index of the first RHS symbol of rule number YYN in
   YYRHS.  */
static const yytype_uint16 yyprhs[] =
{
       0,     0,     3,     4,     5,    12,    14,    16,    18,    20,
      21,    24,    27,    30,    33,    36,    39,    42,    43,    49,
      50,    56,    57,    63,    64,    70,    71,    77,    78,    84,
      85,    91,    92,    98,    99,   105,   109,   110,   115,   117,
     118,   121,   124,   127,   130,   131,   133,   140,   141,   142,
     154,   158,   159,   161,   167,   171,   172,   175,   178,   180,
     182,   184,   186,   188,   190,   192,   194,   196,   198,   200,
     202,   204,   206,   208,   210,   212,   214,   216,   218,   220,
     222,   224,   226,   228,   230,   232,   234,   236,   238,   240,
     242,   244,   246,   248,   250,   252,   254,   256,   258,   260,
     262,   264,   266,   268,   270,   272,   273,   275,   277,   279,
     280,   281,   291,   292,   293,   306,   307,   308,   317,   322,
     323,   326,   331,   338,   343,   349,   356,   357,   360,   363,
     366,   369,   372,   374,   376,   378,   380,   382,   384,   386,
     391,   392,   395,   400
};

/* YYRHS -- A `-1'-separated list of the rules' RHS.  */
static const yytype_int16 yyrhs[] =
{
     111,     0,    -1,    -1,    -1,   108,   112,     4,   115,   113,
     109,    -1,     5,    -1,     6,    -1,     7,    -1,     8,    -1,
      -1,   115,   114,    -1,   115,   147,    -1,   115,   152,    -1,
     115,   136,    -1,   115,     3,    -1,   115,   116,    -1,   115,
       1,    -1,    -1,   108,   117,   115,   137,   109,    -1,    -1,
     108,   118,     9,   115,   109,    -1,    -1,   108,   119,    10,
     115,   109,    -1,    -1,   108,   120,    11,   115,   109,    -1,
      -1,   108,   121,    12,   115,   109,    -1,    -1,   108,   122,
      13,   115,   109,    -1,    -1,   108,   123,    14,   115,   109,
      -1,    -1,   108,   124,    15,   115,   109,    -1,    -1,   108,
     125,    27,   126,   109,    -1,   108,     1,   109,    -1,    -1,
     127,   128,   130,   134,    -1,     1,    -1,    -1,   128,    31,
      -1,   128,    32,    -1,   128,    33,    -1,   128,    34,    -1,
      -1,     9,    -1,   108,   129,    28,     3,   133,   109,    -1,
      -1,    -1,   108,   129,    28,   108,   131,   135,     3,   133,
     109,   132,   109,    -1,   108,     1,   109,    -1,    -1,    29,
      -1,   108,   129,    30,   115,   109,    -1,   108,     1,   109,
      -1,    -1,   135,   136,    -1,   135,   116,    -1,    47,    -1,
      48,    -1,    58,    -1,    59,    -1,    60,    -1,    61,    -1,
      62,    -1,    63,    -1,    64,    -1,    65,    -1,    66,    -1,
      94,    -1,    67,    -1,    68,    -1,    69,    -1,    70,    -1,
      72,    -1,    71,    -1,    18,    -1,    73,    -1,    43,    -1,
      44,    -1,    45,    -1,    92,    -1,    93,    -1,    74,    -1,
      75,    -1,    76,    -1,    77,    -1,    78,    -1,    79,    -1,
      80,    -1,    81,    -1,    82,    -1,    83,    -1,    84,    -1,
      85,    -1,    86,    -1,    87,    -1,    88,    -1,    89,    -1,
      90,    -1,    91,    -1,    16,    -1,    17,    -1,    19,    -1,
      98,    -1,    -1,   138,    -1,   141,    -1,   144,    -1,    -1,
      -1,   108,    49,     3,    50,    51,   109,   139,   115,   140,
      -1,    -1,    -1,   108,    52,    55,     3,    56,     3,    57,
       3,   109,   142,   115,   143,    -1,    -1,    -1,   108,    53,
      55,     3,   109,   145,   115,   146,    -1,   108,    99,   148,
     109,    -1,    -1,   148,   149,    -1,   148,   108,   149,   109,
      -1,   148,   108,   149,   116,     3,   109,    -1,    47,   151,
     150,     3,    -1,    47,   107,   151,   150,     3,    -1,    98,
      47,   107,   151,   150,     3,    -1,    -1,   150,    95,    -1,
     150,    96,    -1,   150,    97,    -1,   150,    35,    -1,   150,
     116,    -1,   100,    -1,   101,    -1,   102,    -1,   103,    -1,
     104,    -1,   105,    -1,   106,    -1,   108,    46,   153,   109,
      -1,    -1,   153,   154,    -1,    40,    41,    42,     3,    -1,
       3,    -1
};

/* YYRLINE[YYN] -- source line where rule number YYN was defined.  */
static const yytype_uint16 yyrline[] =
{
       0,   209,   209,   209,   209,   213,   214,   215,   216,   219,
     220,   221,   222,   223,   224,   225,   226,   229,   229,   230,
     230,   231,   231,   232,   232,   233,   233,   234,   234,   235,
     235,   236,   236,   237,   237,   238,   242,   242,   243,   246,
     247,   248,   249,   250,   253,   254,   257,   258,   258,   258,
     259,   262,   263,   266,   267,   270,   271,   272,   279,   286,
     293,   300,   307,   314,   321,   328,   335,   342,   349,   356,
     363,   364,   365,   366,   367,   374,   375,   376,   377,   384,
     391,   398,   405,   412,   419,   426,   433,   440,   447,   454,
     461,   468,   469,   476,   483,   490,   497,   504,   511,   517,
     518,   519,   520,   521,   522,   526,   527,   528,   529,   541,
     541,   541,   556,   556,   556,   570,   570,   570,   579,   582,
     583,   584,   585,   591,   594,   597,   601,   602,   603,   604,
     605,   606,   611,   612,   613,   614,   615,   616,   617,   625,
     628,   629,   633,   638
};
#endif

#if YYDEBUG || YYERROR_VERBOSE || 0
/* YYTNAME[SYMBOL-NUM] -- String name of the symbol SYMBOL-NUM.
   First, the terminals, then, starting at YYNTOKENS, nonterminals.  */
static const char *const yytname[] =
{
  "$end", "error", "$undefined", "RTFtext", "RTFstart", "RTFansi",
  "RTFmac", "RTFpc", "RTFpca", "RTFignore", "RTFinfo", "RTFstylesheet",
  "RTFfootnote", "RTFheader", "RTFfooter", "RTFpict", "RTFplain",
  "RTFparagraph", "RTFdefaultParagraph", "RTFrow", "RTFcell",
  "RTFtabulator", "RTFemdash", "RTFendash", "RTFemspace", "RTFenspace",
  "RTFbullet", "RTFfield", "RTFfldinst", "RTFfldalt", "RTFfldrslt",
  "RTFflddirty", "RTFfldedit", "RTFfldlock", "RTFfldpriv", "RTFfttruetype",
  "RTFlquote", "RTFrquote", "RTFldblquote", "RTFrdblquote", "RTFred",
  "RTFgreen", "RTFblue", "RTFcolorbg", "RTFcolorfg", "RTFunderlinecolor",
  "RTFcolortable", "RTFfont", "RTFfontSize", "RTFNeXTGraphic",
  "RTFNeXTGraphicWidth", "RTFNeXTGraphicHeight", "RTFNeXTHelpLink",
  "RTFNeXTHelpMarker", "RTFNeXTfilename", "RTFNeXTmarkername",
  "RTFNeXTlinkFilename", "RTFNeXTlinkMarkername", "RTFpaperWidth",
  "RTFpaperHeight", "RTFmarginLeft", "RTFmarginRight", "RTFmarginTop",
  "RTFmarginButtom", "RTFfirstLineIndent", "RTFleftIndent",
  "RTFrightIndent", "RTFalignCenter", "RTFalignJustified", "RTFalignLeft",
  "RTFalignRight", "RTFlineSpace", "RTFspaceAbove", "RTFstyle", "RTFbold",
  "RTFitalic", "RTFunderline", "RTFunderlineDot", "RTFunderlineDash",
  "RTFunderlineDashDot", "RTFunderlineDashDotDot", "RTFunderlineDouble",
  "RTFunderlineStop", "RTFunderlineThick", "RTFunderlineThickDot",
  "RTFunderlineThickDash", "RTFunderlineThickDashDot",
  "RTFunderlineThickDashDotDot", "RTFunderlineWord", "RTFstrikethrough",
  "RTFstrikethroughDouble", "RTFunichar", "RTFsubscript", "RTFsuperscript",
  "RTFtabstop", "RTFfcharset", "RTFfprq", "RTFcpg", "RTFOtherStatement",
  "RTFfontListStart", "RTFfamilyNil", "RTFfamilyRoman", "RTFfamilySwiss",
  "RTFfamilyModern", "RTFfamilyScript", "RTFfamilyDecor", "RTFfamilyTech",
  "RTFfamilyBiDi", "'{'", "'}'", "$accept", "rtfFile", "$@1", "$@2",
  "rtfCharset", "rtfIngredients", "rtfBlock", "$@3", "$@4", "$@5", "$@6",
  "$@7", "$@8", "$@9", "$@10", "$@11", "rtfField", "$@12", "rtfFieldMod",
  "rtfIgnore", "rtfFieldinst", "$@13", "$@14", "rtfFieldalt",
  "rtfFieldrslt", "rtfStatementList", "rtfStatement", "rtfNeXTstuff",
  "rtfNeXTGraphic", "$@15", "$@16", "rtfNeXTHelpLink", "$@17", "$@18",
  "rtfNeXTHelpMarker", "$@19", "$@20", "rtfFontList", "rtfFonts",
  "rtfFontStatement", "rtfFontAttrs", "rtfFontFamily", "rtfColorDef",
  "rtfColors", "rtfColorStatement", YY_NULL
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
     335,   336,   337,   338,   339,   340,   341,   342,   343,   344,
     345,   346,   347,   348,   349,   350,   351,   352,   353,   354,
     355,   356,   357,   358,   359,   360,   361,   362,   123,   125
};
# endif

/* YYR1[YYN] -- Symbol number of symbol that rule YYN derives.  */
static const yytype_uint8 yyr1[] =
{
       0,   110,   112,   113,   111,   114,   114,   114,   114,   115,
     115,   115,   115,   115,   115,   115,   115,   117,   116,   118,
     116,   119,   116,   120,   116,   121,   116,   122,   116,   123,
     116,   124,   116,   125,   116,   116,   127,   126,   126,   128,
     128,   128,   128,   128,   129,   129,   130,   131,   132,   130,
     130,   133,   133,   134,   134,   135,   135,   135,   136,   136,
     136,   136,   136,   136,   136,   136,   136,   136,   136,   136,
     136,   136,   136,   136,   136,   136,   136,   136,   136,   136,
     136,   136,   136,   136,   136,   136,   136,   136,   136,   136,
     136,   136,   136,   136,   136,   136,   136,   136,   136,   136,
     136,   136,   136,   136,   136,   137,   137,   137,   137,   139,
     140,   138,   142,   143,   141,   145,   146,   144,   147,   148,
     148,   148,   148,   149,   149,   149,   150,   150,   150,   150,
     150,   150,   151,   151,   151,   151,   151,   151,   151,   152,
     153,   153,   154,   154
};

/* YYR2[YYN] -- Number of symbols composing right hand side of rule YYN.  */
static const yytype_uint8 yyr2[] =
{
       0,     2,     0,     0,     6,     1,     1,     1,     1,     0,
       2,     2,     2,     2,     2,     2,     2,     0,     5,     0,
       5,     0,     5,     0,     5,     0,     5,     0,     5,     0,
       5,     0,     5,     0,     5,     3,     0,     4,     1,     0,
       2,     2,     2,     2,     0,     1,     6,     0,     0,    11,
       3,     0,     1,     5,     3,     0,     2,     2,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     0,     1,     1,     1,     0,
       0,     9,     0,     0,    12,     0,     0,     8,     4,     0,
       2,     4,     6,     4,     5,     6,     0,     2,     2,     2,
       2,     2,     1,     1,     1,     1,     1,     1,     1,     4,
       0,     2,     4,     1
};

/* YYDEFACT[STATE-NAME] -- Default reduction number in state STATE-NUM.
   Performed when YYTABLE doesn't specify something else to do.  Zero
   means the default is an error.  */
static const yytype_uint8 yydefact[] =
{
       0,     2,     0,     0,     1,     9,     0,    16,    14,     5,
       6,     7,     8,   101,   102,    76,   103,    78,    79,    80,
      58,    59,    60,    61,    62,    63,    64,    65,    66,    67,
      68,    70,    71,    72,    73,    75,    74,    77,    83,    84,
      85,    86,    87,    88,    89,    90,    91,    92,    93,    94,
      95,    96,    97,    98,    99,   100,    81,    82,    69,   104,
       0,     0,    10,    15,    13,    11,    12,     0,   140,   119,
       9,     0,     0,     0,     0,     0,     0,     0,     0,     4,
      35,     0,     0,     0,     9,     9,     9,     9,     9,     9,
       9,     0,   143,     0,   139,   141,     0,     0,     0,   118,
     120,     0,     0,   106,   107,   108,     0,     0,     0,     0,
       0,     0,     0,    38,     0,    39,     0,   132,   133,   134,
     135,   136,   137,   138,     0,   126,     0,     0,     0,     0,
       0,    18,    20,    22,    24,    26,    28,    30,    32,    34,
       0,     0,   126,     0,     0,     0,   121,     0,     0,     0,
       0,    40,    41,    42,    43,     0,     0,   142,     0,   123,
     130,   127,   128,   129,   131,   126,     0,     0,     0,     0,
       0,    45,     0,     0,    37,   124,     0,   122,     0,     0,
     115,    50,     0,     0,     0,   125,   109,     0,     9,    51,
      47,    54,     9,     9,     0,     0,    52,     0,    55,     0,
       0,     0,   117,    46,     0,    53,   111,   112,    51,    57,
      56,     9,     0,     0,    48,   114,     0,    49
};

/* YYDEFGOTO[NTERM-NUM].  */
static const yytype_int16 yydefgoto[] =
{
      -1,     2,     3,    61,    62,     6,    63,    70,    71,    72,
      73,    74,    75,    76,    77,    78,   114,   115,   140,   172,
     156,   198,   216,   197,   174,   204,    64,   102,   103,   193,
     206,   104,   211,   215,   105,   188,   202,    65,    82,   100,
     143,   125,    66,    81,    95
};

/* YYPACT[STATE-NUM] -- Index in YYTABLE of the portion describing
   STATE-NUM.  */
#define YYPACT_NINF -120
static const yytype_int16 yypact[] =
{
    -100,  -120,    11,     5,  -120,  -120,   340,  -120,  -120,  -120,
    -120,  -120,  -120,  -120,  -120,  -120,  -120,  -120,  -120,  -120,
    -120,  -120,  -120,  -120,  -120,  -120,  -120,  -120,  -120,  -120,
    -120,  -120,  -120,  -120,  -120,  -120,  -120,  -120,  -120,  -120,
    -120,  -120,  -120,  -120,  -120,  -120,  -120,  -120,  -120,  -120,
    -120,  -120,  -120,  -120,  -120,  -120,  -120,  -120,  -120,  -120,
     137,   -96,  -120,  -120,  -120,  -120,  -120,   -68,  -120,  -120,
    -120,    34,    45,    33,    46,    47,    49,    44,    35,  -120,
    -120,     7,    28,   434,  -120,  -120,  -120,  -120,  -120,  -120,
    -120,    20,  -120,    31,  -120,  -120,    65,    14,   -42,  -120,
    -120,    21,   -32,  -120,  -120,  -120,   528,   622,   716,   810,
     904,   998,  1092,  -120,    12,  -120,    82,  -120,  -120,  -120,
    -120,  -120,  -120,  -120,    57,  -120,    18,  -102,   124,    76,
      77,  -120,  -120,  -120,  -120,  -120,  -120,  -120,  -120,  -120,
     -30,   130,  -120,   265,    57,   246,  -120,   131,    85,   136,
     170,  -120,  -120,  -120,  -120,    48,    66,  -120,   268,  -120,
    -120,  -120,  -120,  -120,  -120,  -120,    67,   126,   119,    69,
      70,  -120,   158,    41,  -120,  -120,   453,  -120,    78,   185,
    -120,  -120,     9,    80,   160,  -120,  -120,   134,  -120,   163,
    -120,  -120,  -120,  -120,   190,  1186,  -120,   123,  -120,  1280,
    1374,   125,  -120,  -120,  1562,  -120,  -120,  -120,   163,  -120,
    -120,  -120,   128,  1468,  -120,  -120,   129,  -120
};

/* YYPGOTO[NTERM-NUM].  */
static const yytype_int16 yypgoto[] =
{
    -120,  -120,  -120,  -120,  -120,   -70,  1530,  -120,  -120,  -120,
    -120,  -120,  -120,  -120,  -120,  -120,  -120,  -120,  -120,    60,
    -120,  -120,  -120,   -14,  -120,  -120,    36,  -120,  -120,  -120,
    -120,  -120,  -120,  -120,  -120,  -120,  -120,  -120,  -120,   141,
    -119,   -99,  -120,  -120,  -120
};

/* YYTABLE[YYPACT[STATE-NUM]].  What to do in state STATE-NUM.  If
   positive, shift that token.  If negative, reduce the rule which
   number is the opposite.  If YYTABLE_NINF, syntax error.  */
#define YYTABLE_NINF -117
static const yytype_int16 yytable[] =
{
      83,   151,   152,   153,   154,    96,   145,   146,     1,     5,
      92,     4,   189,    79,   106,   107,   108,   109,   110,   111,
     112,   113,    67,   158,   -17,   142,   -17,   -17,   -17,   -17,
     -19,   -21,   -23,   -25,   -27,   -29,   -31,   -17,   -17,   -17,
     -17,    80,   183,    84,    86,   165,   176,    93,   -33,   170,
     171,   -36,   -36,   -36,   -36,    85,    97,   171,    87,    90,
      88,   126,    91,    89,   -17,   -17,   -17,    68,   -17,   -17,
     128,   -44,   116,   129,   130,    96,   -44,   131,   155,   -17,
     -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,
     -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,
     -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,
     -17,   -17,   -17,   -17,   -17,   -17,    94,   190,   195,   -17,
      69,   139,   199,   200,   141,   144,    97,   148,   -36,   -17,
     -17,   149,   150,   157,   166,   167,    98,    99,    67,   168,
     -17,   213,   -17,   -17,   -17,   -17,   -19,   -21,   -23,   -25,
     -27,   -29,   -31,   -17,   -17,   -17,   -17,   117,   118,   119,
     120,   121,   122,   123,   -33,   117,   118,   119,   120,   121,
     122,   123,   124,   169,   173,   179,   177,   178,   180,   181,
     -17,   -17,   -17,    68,   -17,   -17,   182,   186,   187,   191,
     192,   194,   196,   201,   212,   -17,   -17,   -17,   -17,   -17,
     -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,
     -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,
     -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,
     -17,   -17,   203,   184,   207,   -17,    69,   214,   217,   127,
     210,     0,     0,     0,     0,   -17,   -17,    67,     0,   -17,
       0,   -17,   -17,   -17,   -17,   -19,   -21,   -23,   -25,   -27,
     -29,   -31,   -17,   -17,   -17,   -17,     0,     0,   159,     0,
       0,   175,     0,   -33,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,   -17,
     -17,   -17,     0,   -17,   -17,     0,     0,     0,     0,     0,
     160,     0,     0,   160,   -17,   -17,   -17,   -17,   -17,   -17,
     -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,
     -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,
     -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,
     -17,     7,     0,     8,   -17,     9,    10,    11,    12,     0,
       0,     0,     0,     0,   -17,   -17,    13,    14,    15,    16,
     161,   162,   163,   161,   162,   163,     0,     0,     0,     0,
       0,     0,     0,   145,     0,     0,   145,     0,     0,     0,
       0,     0,     0,    17,    18,    19,     0,    20,    21,     0,
       0,     0,     0,     0,     0,     0,     0,     0,    22,    23,
      24,    25,    26,    27,    28,    29,    30,    31,    32,    33,
      34,    35,    36,    37,    38,    39,    40,    41,    42,    43,
      44,    45,    46,    47,    48,    49,    50,    51,    52,    53,
      54,    55,    56,    57,    58,     7,     0,     8,    59,     9,
      10,    11,    12,     0,     0,     0,     0,     0,    60,    -3,
      13,    14,    15,    16,     0,     0,   185,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,    17,    18,    19,
       0,    20,    21,     0,     0,     0,     0,     0,   160,     0,
       0,     0,    22,    23,    24,    25,    26,    27,    28,    29,
      30,    31,    32,    33,    34,    35,    36,    37,    38,    39,
      40,    41,    42,    43,    44,    45,    46,    47,    48,    49,
      50,    51,    52,    53,    54,    55,    56,    57,    58,     7,
       0,     8,    59,     9,    10,    11,    12,     0,     0,     0,
       0,     0,   101,  -105,    13,    14,    15,    16,   161,   162,
     163,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,   145,     0,     0,     0,     0,     0,     0,     0,     0,
       0,    17,    18,    19,     0,    20,    21,     0,     0,     0,
       0,     0,     0,     0,     0,     0,    22,    23,    24,    25,
      26,    27,    28,    29,    30,    31,    32,    33,    34,    35,
      36,    37,    38,    39,    40,    41,    42,    43,    44,    45,
      46,    47,    48,    49,    50,    51,    52,    53,    54,    55,
      56,    57,    58,     7,     0,     8,    59,     9,    10,    11,
      12,     0,     0,     0,     0,     0,    60,   132,    13,    14,
      15,    16,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,    17,    18,    19,     0,    20,
      21,     0,     0,     0,     0,     0,     0,     0,     0,     0,
      22,    23,    24,    25,    26,    27,    28,    29,    30,    31,
      32,    33,    34,    35,    36,    37,    38,    39,    40,    41,
      42,    43,    44,    45,    46,    47,    48,    49,    50,    51,
      52,    53,    54,    55,    56,    57,    58,     7,     0,     8,
      59,     9,    10,    11,    12,     0,     0,     0,     0,     0,
      60,   133,    13,    14,    15,    16,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,    17,
      18,    19,     0,    20,    21,     0,     0,     0,     0,     0,
       0,     0,     0,     0,    22,    23,    24,    25,    26,    27,
      28,    29,    30,    31,    32,    33,    34,    35,    36,    37,
      38,    39,    40,    41,    42,    43,    44,    45,    46,    47,
      48,    49,    50,    51,    52,    53,    54,    55,    56,    57,
      58,     7,     0,     8,    59,     9,    10,    11,    12,     0,
       0,     0,     0,     0,    60,   134,    13,    14,    15,    16,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,    17,    18,    19,     0,    20,    21,     0,
       0,     0,     0,     0,     0,     0,     0,     0,    22,    23,
      24,    25,    26,    27,    28,    29,    30,    31,    32,    33,
      34,    35,    36,    37,    38,    39,    40,    41,    42,    43,
      44,    45,    46,    47,    48,    49,    50,    51,    52,    53,
      54,    55,    56,    57,    58,     7,     0,     8,    59,     9,
      10,    11,    12,     0,     0,     0,     0,     0,    60,   135,
      13,    14,    15,    16,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,    17,    18,    19,
       0,    20,    21,     0,     0,     0,     0,     0,     0,     0,
       0,     0,    22,    23,    24,    25,    26,    27,    28,    29,
      30,    31,    32,    33,    34,    35,    36,    37,    38,    39,
      40,    41,    42,    43,    44,    45,    46,    47,    48,    49,
      50,    51,    52,    53,    54,    55,    56,    57,    58,     7,
       0,     8,    59,     9,    10,    11,    12,     0,     0,     0,
       0,     0,    60,   136,    13,    14,    15,    16,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,    17,    18,    19,     0,    20,    21,     0,     0,     0,
       0,     0,     0,     0,     0,     0,    22,    23,    24,    25,
      26,    27,    28,    29,    30,    31,    32,    33,    34,    35,
      36,    37,    38,    39,    40,    41,    42,    43,    44,    45,
      46,    47,    48,    49,    50,    51,    52,    53,    54,    55,
      56,    57,    58,     7,     0,     8,    59,     9,    10,    11,
      12,     0,     0,     0,     0,     0,    60,   137,    13,    14,
      15,    16,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,    17,    18,    19,     0,    20,
      21,     0,     0,     0,     0,     0,     0,     0,     0,     0,
      22,    23,    24,    25,    26,    27,    28,    29,    30,    31,
      32,    33,    34,    35,    36,    37,    38,    39,    40,    41,
      42,    43,    44,    45,    46,    47,    48,    49,    50,    51,
      52,    53,    54,    55,    56,    57,    58,     7,     0,     8,
      59,     9,    10,    11,    12,     0,     0,     0,     0,     0,
      60,   138,    13,    14,    15,    16,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,    17,
      18,    19,     0,    20,    21,     0,     0,     0,     0,     0,
       0,     0,     0,     0,    22,    23,    24,    25,    26,    27,
      28,    29,    30,    31,    32,    33,    34,    35,    36,    37,
      38,    39,    40,    41,    42,    43,    44,    45,    46,    47,
      48,    49,    50,    51,    52,    53,    54,    55,    56,    57,
      58,     7,     0,     8,    59,     9,    10,    11,    12,     0,
       0,     0,     0,     0,    60,  -116,    13,    14,    15,    16,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,    17,    18,    19,     0,    20,    21,     0,
       0,     0,     0,     0,     0,     0,     0,     0,    22,    23,
      24,    25,    26,    27,    28,    29,    30,    31,    32,    33,
      34,    35,    36,    37,    38,    39,    40,    41,    42,    43,
      44,    45,    46,    47,    48,    49,    50,    51,    52,    53,
      54,    55,    56,    57,    58,     7,     0,     8,    59,     9,
      10,    11,    12,     0,     0,     0,     0,     0,    60,   205,
      13,    14,    15,    16,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,    17,    18,    19,
       0,    20,    21,     0,     0,     0,     0,     0,     0,     0,
       0,     0,    22,    23,    24,    25,    26,    27,    28,    29,
      30,    31,    32,    33,    34,    35,    36,    37,    38,    39,
      40,    41,    42,    43,    44,    45,    46,    47,    48,    49,
      50,    51,    52,    53,    54,    55,    56,    57,    58,     7,
       0,     8,    59,     9,    10,    11,    12,     0,     0,     0,
       0,     0,    60,  -110,    13,    14,    15,    16,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,    17,    18,    19,     0,    20,    21,     0,     0,     0,
       0,     0,     0,     0,     0,     0,    22,    23,    24,    25,
      26,    27,    28,    29,    30,    31,    32,    33,    34,    35,
      36,    37,    38,    39,    40,    41,    42,    43,    44,    45,
      46,    47,    48,    49,    50,    51,    52,    53,    54,    55,
      56,    57,    58,     0,     0,   208,    59,     0,     0,     0,
       0,     0,     0,     0,     0,     0,    60,  -113,    13,    14,
      15,    16,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,    17,    18,    19,     0,    20,
      21,     0,     0,     0,     0,     0,     0,     0,     0,     0,
      22,    23,    24,    25,    26,    27,    28,    29,    30,    31,
      32,    33,    34,    35,    36,    37,    38,    39,    40,    41,
      42,    43,    44,    45,    46,    47,    48,    49,    50,    51,
      52,    53,    54,    55,    56,    57,    58,   147,     0,     0,
      59,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     145,     0,     0,   164,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,   164,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,   164,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,   209
};

#define yypact_value_is_default(Yystate) \
  (!!((Yystate) == (-120)))

#define yytable_value_is_error(Yytable_value) \
  YYID (0)

static const yytype_int16 yycheck[] =
{
      70,    31,    32,    33,    34,    47,   108,   109,   108,     4,
       3,     0,     3,   109,    84,    85,    86,    87,    88,    89,
      90,     1,     1,   142,     3,   124,     5,     6,     7,     8,
       9,    10,    11,    12,    13,    14,    15,    16,    17,    18,
      19,   109,     1,     9,    11,   144,   165,    40,    27,     1,
       9,    31,    32,    33,    34,    10,    98,     9,    12,    15,
      13,    47,    27,    14,    43,    44,    45,    46,    47,    48,
      49,    30,    41,    52,    53,    47,    28,   109,   108,    58,
      59,    60,    61,    62,    63,    64,    65,    66,    67,    68,
      69,    70,    71,    72,    73,    74,    75,    76,    77,    78,
      79,    80,    81,    82,    83,    84,    85,    86,    87,    88,
      89,    90,    91,    92,    93,    94,   109,   108,   188,    98,
      99,   109,   192,   193,    42,   107,    98,     3,   108,   108,
     109,    55,    55,     3,     3,    50,   108,   109,     1,     3,
       3,   211,     5,     6,     7,     8,     9,    10,    11,    12,
      13,    14,    15,    16,    17,    18,    19,   100,   101,   102,
     103,   104,   105,   106,    27,   100,   101,   102,   103,   104,
     105,   106,   107,     3,   108,    56,   109,    51,   109,   109,
      43,    44,    45,    46,    47,    48,    28,   109,     3,   109,
      30,    57,    29,     3,   208,    58,    59,    60,    61,    62,
      63,    64,    65,    66,    67,    68,    69,    70,    71,    72,
      73,    74,    75,    76,    77,    78,    79,    80,    81,    82,
      83,    84,    85,    86,    87,    88,    89,    90,    91,    92,
      93,    94,   109,   173,   109,    98,    99,   109,   109,    98,
     204,    -1,    -1,    -1,    -1,   108,   109,     1,    -1,     3,
      -1,     5,     6,     7,     8,     9,    10,    11,    12,    13,
      14,    15,    16,    17,    18,    19,    -1,    -1,     3,    -1,
      -1,     3,    -1,    27,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    43,
      44,    45,    -1,    47,    48,    -1,    -1,    -1,    -1,    -1,
      35,    -1,    -1,    35,    58,    59,    60,    61,    62,    63,
      64,    65,    66,    67,    68,    69,    70,    71,    72,    73,
      74,    75,    76,    77,    78,    79,    80,    81,    82,    83,
      84,    85,    86,    87,    88,    89,    90,    91,    92,    93,
      94,     1,    -1,     3,    98,     5,     6,     7,     8,    -1,
      -1,    -1,    -1,    -1,   108,   109,    16,    17,    18,    19,
      95,    96,    97,    95,    96,    97,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,   108,    -1,    -1,   108,    -1,    -1,    -1,
      -1,    -1,    -1,    43,    44,    45,    -1,    47,    48,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    58,    59,
      60,    61,    62,    63,    64,    65,    66,    67,    68,    69,
      70,    71,    72,    73,    74,    75,    76,    77,    78,    79,
      80,    81,    82,    83,    84,    85,    86,    87,    88,    89,
      90,    91,    92,    93,    94,     1,    -1,     3,    98,     5,
       6,     7,     8,    -1,    -1,    -1,    -1,    -1,   108,   109,
      16,    17,    18,    19,    -1,    -1,     3,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    43,    44,    45,
      -1,    47,    48,    -1,    -1,    -1,    -1,    -1,    35,    -1,
      -1,    -1,    58,    59,    60,    61,    62,    63,    64,    65,
      66,    67,    68,    69,    70,    71,    72,    73,    74,    75,
      76,    77,    78,    79,    80,    81,    82,    83,    84,    85,
      86,    87,    88,    89,    90,    91,    92,    93,    94,     1,
      -1,     3,    98,     5,     6,     7,     8,    -1,    -1,    -1,
      -1,    -1,   108,   109,    16,    17,    18,    19,    95,    96,
      97,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,   108,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    43,    44,    45,    -1,    47,    48,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    58,    59,    60,    61,
      62,    63,    64,    65,    66,    67,    68,    69,    70,    71,
      72,    73,    74,    75,    76,    77,    78,    79,    80,    81,
      82,    83,    84,    85,    86,    87,    88,    89,    90,    91,
      92,    93,    94,     1,    -1,     3,    98,     5,     6,     7,
       8,    -1,    -1,    -1,    -1,    -1,   108,   109,    16,    17,
      18,    19,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    43,    44,    45,    -1,    47,
      48,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      58,    59,    60,    61,    62,    63,    64,    65,    66,    67,
      68,    69,    70,    71,    72,    73,    74,    75,    76,    77,
      78,    79,    80,    81,    82,    83,    84,    85,    86,    87,
      88,    89,    90,    91,    92,    93,    94,     1,    -1,     3,
      98,     5,     6,     7,     8,    -1,    -1,    -1,    -1,    -1,
     108,   109,    16,    17,    18,    19,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    43,
      44,    45,    -1,    47,    48,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    58,    59,    60,    61,    62,    63,
      64,    65,    66,    67,    68,    69,    70,    71,    72,    73,
      74,    75,    76,    77,    78,    79,    80,    81,    82,    83,
      84,    85,    86,    87,    88,    89,    90,    91,    92,    93,
      94,     1,    -1,     3,    98,     5,     6,     7,     8,    -1,
      -1,    -1,    -1,    -1,   108,   109,    16,    17,    18,    19,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    43,    44,    45,    -1,    47,    48,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    58,    59,
      60,    61,    62,    63,    64,    65,    66,    67,    68,    69,
      70,    71,    72,    73,    74,    75,    76,    77,    78,    79,
      80,    81,    82,    83,    84,    85,    86,    87,    88,    89,
      90,    91,    92,    93,    94,     1,    -1,     3,    98,     5,
       6,     7,     8,    -1,    -1,    -1,    -1,    -1,   108,   109,
      16,    17,    18,    19,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    43,    44,    45,
      -1,    47,    48,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    58,    59,    60,    61,    62,    63,    64,    65,
      66,    67,    68,    69,    70,    71,    72,    73,    74,    75,
      76,    77,    78,    79,    80,    81,    82,    83,    84,    85,
      86,    87,    88,    89,    90,    91,    92,    93,    94,     1,
      -1,     3,    98,     5,     6,     7,     8,    -1,    -1,    -1,
      -1,    -1,   108,   109,    16,    17,    18,    19,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    43,    44,    45,    -1,    47,    48,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    58,    59,    60,    61,
      62,    63,    64,    65,    66,    67,    68,    69,    70,    71,
      72,    73,    74,    75,    76,    77,    78,    79,    80,    81,
      82,    83,    84,    85,    86,    87,    88,    89,    90,    91,
      92,    93,    94,     1,    -1,     3,    98,     5,     6,     7,
       8,    -1,    -1,    -1,    -1,    -1,   108,   109,    16,    17,
      18,    19,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    43,    44,    45,    -1,    47,
      48,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      58,    59,    60,    61,    62,    63,    64,    65,    66,    67,
      68,    69,    70,    71,    72,    73,    74,    75,    76,    77,
      78,    79,    80,    81,    82,    83,    84,    85,    86,    87,
      88,    89,    90,    91,    92,    93,    94,     1,    -1,     3,
      98,     5,     6,     7,     8,    -1,    -1,    -1,    -1,    -1,
     108,   109,    16,    17,    18,    19,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    43,
      44,    45,    -1,    47,    48,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    58,    59,    60,    61,    62,    63,
      64,    65,    66,    67,    68,    69,    70,    71,    72,    73,
      74,    75,    76,    77,    78,    79,    80,    81,    82,    83,
      84,    85,    86,    87,    88,    89,    90,    91,    92,    93,
      94,     1,    -1,     3,    98,     5,     6,     7,     8,    -1,
      -1,    -1,    -1,    -1,   108,   109,    16,    17,    18,    19,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    43,    44,    45,    -1,    47,    48,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    58,    59,
      60,    61,    62,    63,    64,    65,    66,    67,    68,    69,
      70,    71,    72,    73,    74,    75,    76,    77,    78,    79,
      80,    81,    82,    83,    84,    85,    86,    87,    88,    89,
      90,    91,    92,    93,    94,     1,    -1,     3,    98,     5,
       6,     7,     8,    -1,    -1,    -1,    -1,    -1,   108,   109,
      16,    17,    18,    19,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    43,    44,    45,
      -1,    47,    48,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    58,    59,    60,    61,    62,    63,    64,    65,
      66,    67,    68,    69,    70,    71,    72,    73,    74,    75,
      76,    77,    78,    79,    80,    81,    82,    83,    84,    85,
      86,    87,    88,    89,    90,    91,    92,    93,    94,     1,
      -1,     3,    98,     5,     6,     7,     8,    -1,    -1,    -1,
      -1,    -1,   108,   109,    16,    17,    18,    19,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    43,    44,    45,    -1,    47,    48,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    58,    59,    60,    61,
      62,    63,    64,    65,    66,    67,    68,    69,    70,    71,
      72,    73,    74,    75,    76,    77,    78,    79,    80,    81,
      82,    83,    84,    85,    86,    87,    88,    89,    90,    91,
      92,    93,    94,    -1,    -1,     3,    98,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,   108,   109,    16,    17,
      18,    19,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    43,    44,    45,    -1,    47,
      48,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      58,    59,    60,    61,    62,    63,    64,    65,    66,    67,
      68,    69,    70,    71,    72,    73,    74,    75,    76,    77,
      78,    79,    80,    81,    82,    83,    84,    85,    86,    87,
      88,    89,    90,    91,    92,    93,    94,   127,    -1,    -1,
      98,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
     108,    -1,    -1,   143,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,   158,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,   176,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,   204
};

/* YYSTOS[STATE-NUM] -- The (internal number of the) accessing
   symbol of state STATE-NUM.  */
static const yytype_uint8 yystos[] =
{
       0,   108,   111,   112,     0,     4,   115,     1,     3,     5,
       6,     7,     8,    16,    17,    18,    19,    43,    44,    45,
      47,    48,    58,    59,    60,    61,    62,    63,    64,    65,
      66,    67,    68,    69,    70,    71,    72,    73,    74,    75,
      76,    77,    78,    79,    80,    81,    82,    83,    84,    85,
      86,    87,    88,    89,    90,    91,    92,    93,    94,    98,
     108,   113,   114,   116,   136,   147,   152,     1,    46,    99,
     117,   118,   119,   120,   121,   122,   123,   124,   125,   109,
     109,   153,   148,   115,     9,    10,    11,    12,    13,    14,
      15,    27,     3,    40,   109,   154,    47,    98,   108,   109,
     149,   108,   137,   138,   141,   144,   115,   115,   115,   115,
     115,   115,   115,     1,   126,   127,    41,   100,   101,   102,
     103,   104,   105,   106,   107,   151,    47,   149,    49,    52,
      53,   109,   109,   109,   109,   109,   109,   109,   109,   109,
     128,    42,   151,   150,   107,   108,   109,   116,     3,    55,
      55,    31,    32,    33,    34,   108,   130,     3,   150,     3,
      35,    95,    96,    97,   116,   151,     3,    50,     3,     3,
       1,     9,   129,   108,   134,     3,   150,   109,    51,    56,
     109,   109,    28,     1,   129,     3,   109,     3,   145,     3,
     108,   109,    30,   139,    57,   115,    29,   133,   131,   115,
     115,     3,   146,   109,   135,   109,   140,   109,     3,   116,
     136,   142,   133,   115,   109,   143,   132,   109
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
   Once GCC version 2 has supplanted version 1, this can go.  However,
   YYFAIL appears to be in use.  Nevertheless, it is formally deprecated
   in Bison 2.4.2's NEWS entry, where a plan to phase it out is
   discussed.  */

#define YYFAIL		goto yyerrlab
#if defined YYFAIL
  /* This is here to suppress warnings from the GCC cpp's
     -Wunused-macros.  Normally we don't worry about that warning, but
     some users do, and we want to make it easy for users to remove
     YYFAIL uses, which will produce warnings from Bison 2.5.  */
#endif

#define YYRECOVERING()  (!!yyerrstatus)

#define YYBACKUP(Token, Value)                                  \
do                                                              \
  if (yychar == YYEMPTY)                                        \
    {                                                           \
      yychar = (Token);                                         \
      yylval = (Value);                                         \
      YYPOPSTACK (yylen);                                       \
      yystate = *yyssp;                                         \
      goto yybackup;                                            \
    }                                                           \
  else                                                          \
    {                                                           \
      yyerror (ctxt, lctxt, YY_("syntax error: cannot back up")); \
      YYERROR;							\
    }								\
while (YYID (0))

/* Error token number */
#define YYTERROR	1
#define YYERRCODE	256


/* This macro is provided for backward compatibility. */
#ifndef YY_LOCATION_PRINT
# define YY_LOCATION_PRINT(File, Loc) ((void) 0)
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
  FILE *yyo = yyoutput;
  YYUSE (yyo);
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
yy_stack_print (yytype_int16 *yybottom, yytype_int16 *yytop)
#else
static void
yy_stack_print (yybottom, yytop)
    yytype_int16 *yybottom;
    yytype_int16 *yytop;
#endif
{
  YYFPRINTF (stderr, "Stack now");
  for (; yybottom <= yytop; yybottom++)
    {
      int yybot = *yybottom;
      YYFPRINTF (stderr, " %d", yybot);
    }
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
      YYFPRINTF (stderr, "   $%d = ", yyi + 1);
      yy_symbol_print (stderr, yyrhs[yyprhs[yyrule] + yyi],
		       &(yyvsp[(yyi + 1) - (yynrhs)])
		       		       , ctxt, lctxt);
      YYFPRINTF (stderr, "\n");
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

/* Copy into *YYMSG, which is of size *YYMSG_ALLOC, an error message
   about the unexpected token YYTOKEN for the state stack whose top is
   YYSSP.

   Return 0 if *YYMSG was successfully written.  Return 1 if *YYMSG is
   not large enough to hold the message.  In that case, also set
   *YYMSG_ALLOC to the required number of bytes.  Return 2 if the
   required number of bytes is too large to store.  */
static int
yysyntax_error (YYSIZE_T *yymsg_alloc, char **yymsg,
                yytype_int16 *yyssp, int yytoken)
{
  YYSIZE_T yysize0 = yytnamerr (YY_NULL, yytname[yytoken]);
  YYSIZE_T yysize = yysize0;
  enum { YYERROR_VERBOSE_ARGS_MAXIMUM = 5 };
  /* Internationalized format string. */
  const char *yyformat = YY_NULL;
  /* Arguments of yyformat. */
  char const *yyarg[YYERROR_VERBOSE_ARGS_MAXIMUM];
  /* Number of reported tokens (one for the "unexpected", one per
     "expected"). */
  int yycount = 0;

  /* There are many possibilities here to consider:
     - Assume YYFAIL is not used.  It's too flawed to consider.  See
       <http://lists.gnu.org/archive/html/bison-patches/2009-12/msg00024.html>
       for details.  YYERROR is fine as it does not invoke this
       function.
     - If this state is a consistent state with a default action, then
       the only way this function was invoked is if the default action
       is an error action.  In that case, don't check for expected
       tokens because there are none.
     - The only way there can be no lookahead present (in yychar) is if
       this state is a consistent state with a default action.  Thus,
       detecting the absence of a lookahead is sufficient to determine
       that there is no unexpected or expected token to report.  In that
       case, just report a simple "syntax error".
     - Don't assume there isn't a lookahead just because this state is a
       consistent state with a default action.  There might have been a
       previous inconsistent state, consistent state with a non-default
       action, or user semantic action that manipulated yychar.
     - Of course, the expected token list depends on states to have
       correct lookahead information, and it depends on the parser not
       to perform extra reductions after fetching a lookahead from the
       scanner and before detecting a syntax error.  Thus, state merging
       (from LALR or IELR) and default reductions corrupt the expected
       token list.  However, the list is correct for canonical LR with
       one exception: it will still contain any token that will not be
       accepted due to an error action in a later state.
  */
  if (yytoken != YYEMPTY)
    {
      int yyn = yypact[*yyssp];
      yyarg[yycount++] = yytname[yytoken];
      if (!yypact_value_is_default (yyn))
        {
          /* Start YYX at -YYN if negative to avoid negative indexes in
             YYCHECK.  In other words, skip the first -YYN actions for
             this state because they are default actions.  */
          int yyxbegin = yyn < 0 ? -yyn : 0;
          /* Stay within bounds of both yycheck and yytname.  */
          int yychecklim = YYLAST - yyn + 1;
          int yyxend = yychecklim < YYNTOKENS ? yychecklim : YYNTOKENS;
          int yyx;

          for (yyx = yyxbegin; yyx < yyxend; ++yyx)
            if (yycheck[yyx + yyn] == yyx && yyx != YYTERROR
                && !yytable_value_is_error (yytable[yyx + yyn]))
              {
                if (yycount == YYERROR_VERBOSE_ARGS_MAXIMUM)
                  {
                    yycount = 1;
                    yysize = yysize0;
                    break;
                  }
                yyarg[yycount++] = yytname[yyx];
                {
                  YYSIZE_T yysize1 = yysize + yytnamerr (YY_NULL, yytname[yyx]);
                  if (! (yysize <= yysize1
                         && yysize1 <= YYSTACK_ALLOC_MAXIMUM))
                    return 2;
                  yysize = yysize1;
                }
              }
        }
    }

  switch (yycount)
    {
# define YYCASE_(N, S)                      \
      case N:                               \
        yyformat = S;                       \
      break
      YYCASE_(0, YY_("syntax error"));
      YYCASE_(1, YY_("syntax error, unexpected %s"));
      YYCASE_(2, YY_("syntax error, unexpected %s, expecting %s"));
      YYCASE_(3, YY_("syntax error, unexpected %s, expecting %s or %s"));
      YYCASE_(4, YY_("syntax error, unexpected %s, expecting %s or %s or %s"));
      YYCASE_(5, YY_("syntax error, unexpected %s, expecting %s or %s or %s or %s"));
# undef YYCASE_
    }

  {
    YYSIZE_T yysize1 = yysize + yystrlen (yyformat);
    if (! (yysize <= yysize1 && yysize1 <= YYSTACK_ALLOC_MAXIMUM))
      return 2;
    yysize = yysize1;
  }

  if (*yymsg_alloc < yysize)
    {
      *yymsg_alloc = 2 * yysize;
      if (! (yysize <= *yymsg_alloc
             && *yymsg_alloc <= YYSTACK_ALLOC_MAXIMUM))
        *yymsg_alloc = YYSTACK_ALLOC_MAXIMUM;
      return 1;
    }

  /* Avoid sprintf, as that infringes on the user's name space.
     Don't have undefined behavior even if the translation
     produced a string with the wrong number of "%s"s.  */
  {
    char *yyp = *yymsg;
    int yyi = 0;
    while ((*yyp = *yyformat) != '\0')
      if (*yyp == '%' && yyformat[1] == 's' && yyi < yycount)
        {
          yyp += yytnamerr (yyp, yyarg[yyi++]);
          yyformat += 2;
        }
      else
        {
          yyp++;
          yyformat++;
        }
  }
  return 0;
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
/* The lookahead symbol.  */
int yychar;


#if defined __GNUC__ && 407 <= __GNUC__ * 100 + __GNUC_MINOR__
/* Suppress an incorrect diagnostic about yylval being uninitialized.  */
# define YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN \
    _Pragma ("GCC diagnostic push") \
    _Pragma ("GCC diagnostic ignored \"-Wuninitialized\"")\
    _Pragma ("GCC diagnostic ignored \"-Wmaybe-uninitialized\"")
# define YY_IGNORE_MAYBE_UNINITIALIZED_END \
    _Pragma ("GCC diagnostic pop")
#else
/* Default value used for initialization, for pacifying older GCCs
   or non-GCC compilers.  */
static YYSTYPE yyval_default;
# define YY_INITIAL_VALUE(Value) = Value
#endif
#ifndef YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
# define YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
# define YY_IGNORE_MAYBE_UNINITIALIZED_END
#endif
#ifndef YY_INITIAL_VALUE
# define YY_INITIAL_VALUE(Value) /* Nothing. */
#endif

/* The semantic value of the lookahead symbol.  */
YYSTYPE yylval YY_INITIAL_VALUE(yyval_default);

    /* Number of syntax errors so far.  */
    int yynerrs;

    int yystate;
    /* Number of tokens to shift before error messages enabled.  */
    int yyerrstatus;

    /* The stacks and their tools:
       `yyss': related to states.
       `yyvs': related to semantic values.

       Refer to the stacks through separate pointers, to allow yyoverflow
       to reallocate them elsewhere.  */

    /* The state stack.  */
    yytype_int16 yyssa[YYINITDEPTH];
    yytype_int16 *yyss;
    yytype_int16 *yyssp;

    /* The semantic value stack.  */
    YYSTYPE yyvsa[YYINITDEPTH];
    YYSTYPE *yyvs;
    YYSTYPE *yyvsp;

    YYSIZE_T yystacksize;

  int yyn;
  int yyresult;
  /* Lookahead token as an internal (translated) token number.  */
  int yytoken = 0;
  /* The variables used to return semantic value and location from the
     action routines.  */
  YYSTYPE yyval;

#if YYERROR_VERBOSE
  /* Buffer for error messages, and its allocated size.  */
  char yymsgbuf[128];
  char *yymsg = yymsgbuf;
  YYSIZE_T yymsg_alloc = sizeof yymsgbuf;
#endif

#define YYPOPSTACK(N)   (yyvsp -= (N), yyssp -= (N))

  /* The number of symbols on the RHS of the reduced rule.
     Keep to zero when no symbol should be popped.  */
  int yylen = 0;

  yyssp = yyss = yyssa;
  yyvsp = yyvs = yyvsa;
  yystacksize = YYINITDEPTH;

  YYDPRINTF ((stderr, "Starting parse\n"));

  yystate = 0;
  yyerrstatus = 0;
  yynerrs = 0;
  yychar = YYEMPTY; /* Cause a token to be read.  */
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
	YYSTACK_RELOCATE (yyss_alloc, yyss);
	YYSTACK_RELOCATE (yyvs_alloc, yyvs);
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

  if (yystate == YYFINAL)
    YYACCEPT;

  goto yybackup;

/*-----------.
| yybackup.  |
`-----------*/
yybackup:

  /* Do appropriate processing given the current state.  Read a
     lookahead token if we need one and don't already have one.  */

  /* First try to decide what to do without reference to lookahead token.  */
  yyn = yypact[yystate];
  if (yypact_value_is_default (yyn))
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
      if (yytable_value_is_error (yyn))
        goto yyerrlab;
      yyn = -yyn;
      goto yyreduce;
    }

  /* Count tokens shifted since error; after three, turn off error
     status.  */
  if (yyerrstatus)
    yyerrstatus--;

  /* Shift the lookahead token.  */
  YY_SYMBOL_PRINT ("Shifting", yytoken, &yylval, &yylloc);

  /* Discard the shifted token.  */
  yychar = YYEMPTY;

  yystate = yyn;
  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  *++yyvsp = yylval;
  YY_IGNORE_MAYBE_UNINITIALIZED_END

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
/* Line 1792 of yacc.c  */
#line 209 "rtfGrammar.y"
    { GSRTFstart(CTXT); }
    break;

  case 3:
/* Line 1792 of yacc.c  */
#line 209 "rtfGrammar.y"
    { GSRTFstop(CTXT); }
    break;

  case 5:
/* Line 1792 of yacc.c  */
#line 213 "rtfGrammar.y"
    { (yyval.number) = 1; }
    break;

  case 6:
/* Line 1792 of yacc.c  */
#line 214 "rtfGrammar.y"
    { (yyval.number) = 2; }
    break;

  case 7:
/* Line 1792 of yacc.c  */
#line 215 "rtfGrammar.y"
    { (yyval.number) = 3; }
    break;

  case 8:
/* Line 1792 of yacc.c  */
#line 216 "rtfGrammar.y"
    { (yyval.number) = 4; }
    break;

  case 14:
/* Line 1792 of yacc.c  */
#line 224 "rtfGrammar.y"
    { GSRTFmangleText(CTXT, (yyvsp[(2) - (2)].text)); free((void *)(yyvsp[(2) - (2)].text)); }
    break;

  case 17:
/* Line 1792 of yacc.c  */
#line 229 "rtfGrammar.y"
    { GSRTFopenBlock(CTXT, NO); }
    break;

  case 18:
/* Line 1792 of yacc.c  */
#line 229 "rtfGrammar.y"
    { GSRTFcloseBlock(CTXT, NO); }
    break;

  case 19:
/* Line 1792 of yacc.c  */
#line 230 "rtfGrammar.y"
    { GSRTFopenBlock(CTXT, YES); }
    break;

  case 20:
/* Line 1792 of yacc.c  */
#line 230 "rtfGrammar.y"
    { GSRTFcloseBlock(CTXT, YES); }
    break;

  case 21:
/* Line 1792 of yacc.c  */
#line 231 "rtfGrammar.y"
    { GSRTFopenBlock(CTXT, YES); }
    break;

  case 22:
/* Line 1792 of yacc.c  */
#line 231 "rtfGrammar.y"
    { GSRTFcloseBlock(CTXT, YES); }
    break;

  case 23:
/* Line 1792 of yacc.c  */
#line 232 "rtfGrammar.y"
    { GSRTFopenBlock(CTXT, YES); }
    break;

  case 24:
/* Line 1792 of yacc.c  */
#line 232 "rtfGrammar.y"
    { GSRTFcloseBlock(CTXT, YES); }
    break;

  case 25:
/* Line 1792 of yacc.c  */
#line 233 "rtfGrammar.y"
    { GSRTFopenBlock(CTXT, YES); }
    break;

  case 26:
/* Line 1792 of yacc.c  */
#line 233 "rtfGrammar.y"
    { GSRTFcloseBlock(CTXT, YES); }
    break;

  case 27:
/* Line 1792 of yacc.c  */
#line 234 "rtfGrammar.y"
    { GSRTFopenBlock(CTXT, YES); }
    break;

  case 28:
/* Line 1792 of yacc.c  */
#line 234 "rtfGrammar.y"
    { GSRTFcloseBlock(CTXT, YES); }
    break;

  case 29:
/* Line 1792 of yacc.c  */
#line 235 "rtfGrammar.y"
    { GSRTFopenBlock(CTXT, YES); }
    break;

  case 30:
/* Line 1792 of yacc.c  */
#line 235 "rtfGrammar.y"
    { GSRTFcloseBlock(CTXT, YES); }
    break;

  case 31:
/* Line 1792 of yacc.c  */
#line 236 "rtfGrammar.y"
    { GSRTFopenBlock(CTXT, YES); }
    break;

  case 32:
/* Line 1792 of yacc.c  */
#line 236 "rtfGrammar.y"
    { GSRTFcloseBlock(CTXT, YES); }
    break;

  case 33:
/* Line 1792 of yacc.c  */
#line 237 "rtfGrammar.y"
    { GSRTFopenBlock(CTXT, NO); }
    break;

  case 34:
/* Line 1792 of yacc.c  */
#line 237 "rtfGrammar.y"
    { GSRTFcloseBlock(CTXT, NO); }
    break;

  case 36:
/* Line 1792 of yacc.c  */
#line 242 "rtfGrammar.y"
    { fieldStart = GSRTFgetPosition(CTXT);}
    break;

  case 37:
/* Line 1792 of yacc.c  */
#line 242 "rtfGrammar.y"
    { GSRTFaddField(CTXT, fieldStart, (yyvsp[(3) - (4)].text)); free((void *)(yyvsp[(3) - (4)].text)); }
    break;

  case 46:
/* Line 1792 of yacc.c  */
#line 257 "rtfGrammar.y"
    { (yyval.text) = (yyvsp[(4) - (6)].text);}
    break;

  case 47:
/* Line 1792 of yacc.c  */
#line 258 "rtfGrammar.y"
    { GSRTFopenBlock(CTXT, YES); }
    break;

  case 48:
/* Line 1792 of yacc.c  */
#line 258 "rtfGrammar.y"
    { GSRTFcloseBlock(CTXT, YES); }
    break;

  case 49:
/* Line 1792 of yacc.c  */
#line 258 "rtfGrammar.y"
    { (yyval.text) = (yyvsp[(7) - (11)].text);}
    break;

  case 50:
/* Line 1792 of yacc.c  */
#line 259 "rtfGrammar.y"
    { (yyval.text) = NULL;}
    break;

  case 58:
/* Line 1792 of yacc.c  */
#line 279 "rtfGrammar.y"
    { int font;
		    
						  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      font = 0;
						  else
						      font = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFfontNumber(CTXT, font); }
    break;

  case 59:
/* Line 1792 of yacc.c  */
#line 286 "rtfGrammar.y"
    { int size;

						  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      size = 24;
						  else
						      size = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFfontSize(CTXT, size); }
    break;

  case 60:
/* Line 1792 of yacc.c  */
#line 293 "rtfGrammar.y"
    { int width; 
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      width = 12240;
						  else
						      width = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFpaperWidth(CTXT, width);}
    break;

  case 61:
/* Line 1792 of yacc.c  */
#line 300 "rtfGrammar.y"
    { int height; 
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      height = 15840;
						  else
						      height = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFpaperHeight(CTXT, height);}
    break;

  case 62:
/* Line 1792 of yacc.c  */
#line 307 "rtfGrammar.y"
    { int margin; 
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      margin = 1800;
						  else
						      margin = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFmarginLeft(CTXT, margin);}
    break;

  case 63:
/* Line 1792 of yacc.c  */
#line 314 "rtfGrammar.y"
    { int margin; 
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      margin = 1800;
						  else
						      margin = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFmarginRight(CTXT, margin); }
    break;

  case 64:
/* Line 1792 of yacc.c  */
#line 321 "rtfGrammar.y"
    { int margin; 
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      margin = 1440;
						  else
						      margin = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFmarginTop(CTXT, margin); }
    break;

  case 65:
/* Line 1792 of yacc.c  */
#line 328 "rtfGrammar.y"
    { int margin; 
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      margin = 1440;
						  else
						      margin = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFmarginButtom(CTXT, margin); }
    break;

  case 66:
/* Line 1792 of yacc.c  */
#line 335 "rtfGrammar.y"
    { int indent; 
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      indent = 0;
						  else
						      indent = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFfirstLineIndent(CTXT, indent); }
    break;

  case 67:
/* Line 1792 of yacc.c  */
#line 342 "rtfGrammar.y"
    { int indent; 
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      indent = 0;
						  else
						      indent = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFleftIndent(CTXT, indent);}
    break;

  case 68:
/* Line 1792 of yacc.c  */
#line 349 "rtfGrammar.y"
    { int indent; 
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      indent = 0;
						  else
						      indent = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFrightIndent(CTXT, indent);}
    break;

  case 69:
/* Line 1792 of yacc.c  */
#line 356 "rtfGrammar.y"
    { int location; 
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      location = 0;
						  else
						      location = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFtabstop(CTXT, location);}
    break;

  case 70:
/* Line 1792 of yacc.c  */
#line 363 "rtfGrammar.y"
    { GSRTFalignCenter(CTXT); }
    break;

  case 71:
/* Line 1792 of yacc.c  */
#line 364 "rtfGrammar.y"
    { GSRTFalignJustified(CTXT); }
    break;

  case 72:
/* Line 1792 of yacc.c  */
#line 365 "rtfGrammar.y"
    { GSRTFalignLeft(CTXT); }
    break;

  case 73:
/* Line 1792 of yacc.c  */
#line 366 "rtfGrammar.y"
    { GSRTFalignRight(CTXT); }
    break;

  case 74:
/* Line 1792 of yacc.c  */
#line 367 "rtfGrammar.y"
    { int space; 
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      space = 0;
						  else
						      space = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFspaceAbove(CTXT, space); }
    break;

  case 75:
/* Line 1792 of yacc.c  */
#line 374 "rtfGrammar.y"
    { GSRTFlineSpace(CTXT, (yyvsp[(1) - (1)].cmd).parameter); }
    break;

  case 76:
/* Line 1792 of yacc.c  */
#line 375 "rtfGrammar.y"
    { GSRTFdefaultParagraph(CTXT); }
    break;

  case 77:
/* Line 1792 of yacc.c  */
#line 376 "rtfGrammar.y"
    { GSRTFstyle(CTXT, (yyvsp[(1) - (1)].cmd).parameter); }
    break;

  case 78:
/* Line 1792 of yacc.c  */
#line 377 "rtfGrammar.y"
    { int color; 
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      color = 0;
						  else
						      color = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFcolorbg(CTXT, color); }
    break;

  case 79:
/* Line 1792 of yacc.c  */
#line 384 "rtfGrammar.y"
    { int color; 
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      color = 0;
						  else
						      color = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFcolorfg(CTXT, color); }
    break;

  case 80:
/* Line 1792 of yacc.c  */
#line 391 "rtfGrammar.y"
    { int color; 
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      color = 0;
						  else
						      color = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFunderlinecolor(CTXT, color); }
    break;

  case 81:
/* Line 1792 of yacc.c  */
#line 398 "rtfGrammar.y"
    { int script;
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      script = 6;
						  else
						      script = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFsubscript(CTXT, script); }
    break;

  case 82:
/* Line 1792 of yacc.c  */
#line 405 "rtfGrammar.y"
    { int script;
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      script = 6;
						  else
						      script = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFsuperscript(CTXT, script); }
    break;

  case 83:
/* Line 1792 of yacc.c  */
#line 412 "rtfGrammar.y"
    { BOOL on;

		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty || (yyvsp[(1) - (1)].cmd).parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFbold(CTXT, on); }
    break;

  case 84:
/* Line 1792 of yacc.c  */
#line 419 "rtfGrammar.y"
    { BOOL on;

		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty || (yyvsp[(1) - (1)].cmd).parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFitalic(CTXT, on); }
    break;

  case 85:
/* Line 1792 of yacc.c  */
#line 426 "rtfGrammar.y"
    { BOOL on;

		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty || (yyvsp[(1) - (1)].cmd).parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFunderline(CTXT, on, NSUnderlineStyleSingle | NSUnderlinePatternSolid); }
    break;

  case 86:
/* Line 1792 of yacc.c  */
#line 433 "rtfGrammar.y"
    { BOOL on;

		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty || (yyvsp[(1) - (1)].cmd).parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFunderline(CTXT, on, NSUnderlineStyleSingle | NSUnderlinePatternDot); }
    break;

  case 87:
/* Line 1792 of yacc.c  */
#line 440 "rtfGrammar.y"
    { BOOL on;

		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty || (yyvsp[(1) - (1)].cmd).parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFunderline(CTXT, on, NSUnderlineStyleSingle | NSUnderlinePatternDash); }
    break;

  case 88:
/* Line 1792 of yacc.c  */
#line 447 "rtfGrammar.y"
    { BOOL on;

		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty || (yyvsp[(1) - (1)].cmd).parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFunderline(CTXT, on, NSUnderlineStyleSingle | NSUnderlinePatternDashDot); }
    break;

  case 89:
/* Line 1792 of yacc.c  */
#line 454 "rtfGrammar.y"
    { BOOL on;

		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty || (yyvsp[(1) - (1)].cmd).parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFunderline(CTXT, on, NSUnderlineStyleSingle | NSUnderlinePatternDashDotDot); }
    break;

  case 90:
/* Line 1792 of yacc.c  */
#line 461 "rtfGrammar.y"
    { BOOL on;

		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty || (yyvsp[(1) - (1)].cmd).parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFunderline(CTXT, on, NSUnderlineStyleDouble | NSUnderlinePatternSolid); }
    break;

  case 91:
/* Line 1792 of yacc.c  */
#line 468 "rtfGrammar.y"
    { GSRTFunderline(CTXT, NO, NSUnderlineStyleNone); }
    break;

  case 92:
/* Line 1792 of yacc.c  */
#line 469 "rtfGrammar.y"
    { BOOL on;

		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty || (yyvsp[(1) - (1)].cmd).parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFunderline(CTXT, on, NSUnderlineStyleThick | NSUnderlinePatternSolid); }
    break;

  case 93:
/* Line 1792 of yacc.c  */
#line 476 "rtfGrammar.y"
    { BOOL on;

		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty || (yyvsp[(1) - (1)].cmd).parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFunderline(CTXT, on, NSUnderlineStyleThick | NSUnderlinePatternDot); }
    break;

  case 94:
/* Line 1792 of yacc.c  */
#line 483 "rtfGrammar.y"
    { BOOL on;

		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty || (yyvsp[(1) - (1)].cmd).parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFunderline(CTXT, on, NSUnderlineStyleThick | NSUnderlinePatternDash); }
    break;

  case 95:
/* Line 1792 of yacc.c  */
#line 490 "rtfGrammar.y"
    { BOOL on;

		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty || (yyvsp[(1) - (1)].cmd).parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFunderline(CTXT, on, NSUnderlineStyleThick | NSUnderlinePatternDashDot); }
    break;

  case 96:
/* Line 1792 of yacc.c  */
#line 497 "rtfGrammar.y"
    { BOOL on;

		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty || (yyvsp[(1) - (1)].cmd).parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFunderline(CTXT, on, NSUnderlineStyleThick | NSUnderlinePatternDashDotDot); }
    break;

  case 97:
/* Line 1792 of yacc.c  */
#line 504 "rtfGrammar.y"
    { BOOL on;

		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty || (yyvsp[(1) - (1)].cmd).parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFunderline(CTXT, on, NSUnderlineStyleSingle | NSUnderlinePatternSolid | NSUnderlineByWordMask); }
    break;

  case 98:
/* Line 1792 of yacc.c  */
#line 511 "rtfGrammar.y"
    {   NSInteger style;
   if ((yyvsp[(1) - (1)].cmd).isEmpty || (yyvsp[(1) - (1)].cmd).parameter)
     style = NSUnderlineStyleSingle | NSUnderlinePatternSolid;
   else
     style = NSUnderlineStyleNone;
   GSRTFstrikethrough(CTXT, style); }
    break;

  case 99:
/* Line 1792 of yacc.c  */
#line 517 "rtfGrammar.y"
    { GSRTFstrikethrough(CTXT, NSUnderlineStyleDouble | NSUnderlinePatternSolid); }
    break;

  case 100:
/* Line 1792 of yacc.c  */
#line 518 "rtfGrammar.y"
    { GSRTFunicode(CTXT, (yyvsp[(1) - (1)].cmd).parameter); }
    break;

  case 101:
/* Line 1792 of yacc.c  */
#line 519 "rtfGrammar.y"
    { GSRTFdefaultCharacterStyle(CTXT); }
    break;

  case 102:
/* Line 1792 of yacc.c  */
#line 520 "rtfGrammar.y"
    { GSRTFparagraph(CTXT); }
    break;

  case 103:
/* Line 1792 of yacc.c  */
#line 521 "rtfGrammar.y"
    { GSRTFparagraph(CTXT); }
    break;

  case 104:
/* Line 1792 of yacc.c  */
#line 522 "rtfGrammar.y"
    { GSRTFgenericRTFcommand(CTXT, (yyvsp[(1) - (1)].cmd)); 
		                                  free((void*)(yyvsp[(1) - (1)].cmd).name); }
    break;

  case 109:
/* Line 1792 of yacc.c  */
#line 541 "rtfGrammar.y"
    { GSRTFopenBlock(CTXT, YES); }
    break;

  case 110:
/* Line 1792 of yacc.c  */
#line 541 "rtfGrammar.y"
    { GSRTFcloseBlock(CTXT, YES); }
    break;

  case 111:
/* Line 1792 of yacc.c  */
#line 542 "rtfGrammar.y"
    {
			GSRTFNeXTGraphic (CTXT, (yyvsp[(3) - (9)].text), (yyvsp[(4) - (9)].cmd).parameter, (yyvsp[(5) - (9)].cmd).parameter);
		}
    break;

  case 112:
/* Line 1792 of yacc.c  */
#line 556 "rtfGrammar.y"
    { GSRTFopenBlock(CTXT, YES); }
    break;

  case 113:
/* Line 1792 of yacc.c  */
#line 556 "rtfGrammar.y"
    { GSRTFcloseBlock(CTXT, YES); }
    break;

  case 114:
/* Line 1792 of yacc.c  */
#line 557 "rtfGrammar.y"
    {
			GSRTFNeXTHelpLink (CTXT, (yyvsp[(2) - (12)].cmd).parameter, (yyvsp[(4) - (12)].text), (yyvsp[(6) - (12)].text), (yyvsp[(8) - (12)].text));
		}
    break;

  case 115:
/* Line 1792 of yacc.c  */
#line 570 "rtfGrammar.y"
    { GSRTFopenBlock(CTXT, YES); }
    break;

  case 116:
/* Line 1792 of yacc.c  */
#line 570 "rtfGrammar.y"
    { GSRTFcloseBlock(CTXT, YES); }
    break;

  case 117:
/* Line 1792 of yacc.c  */
#line 571 "rtfGrammar.y"
    {
			GSRTFNeXTHelpMarker (CTXT, (yyvsp[(2) - (8)].cmd).parameter, (yyvsp[(4) - (8)].text));
		}
    break;

  case 122:
/* Line 1792 of yacc.c  */
#line 586 "rtfGrammar.y"
    { free((void *)(yyvsp[(5) - (6)].text));}
    break;

  case 123:
/* Line 1792 of yacc.c  */
#line 591 "rtfGrammar.y"
    { GSRTFregisterFont(CTXT, (yyvsp[(4) - (4)].text), (yyvsp[(2) - (4)].number), (yyvsp[(1) - (4)].cmd).parameter);
                                                          free((void *)(yyvsp[(4) - (4)].text)); }
    break;

  case 124:
/* Line 1792 of yacc.c  */
#line 594 "rtfGrammar.y"
    { GSRTFregisterFont(CTXT, (yyvsp[(5) - (5)].text), (yyvsp[(3) - (5)].number), (yyvsp[(1) - (5)].cmd).parameter);
                                                          free((void *)(yyvsp[(5) - (5)].text)); }
    break;

  case 125:
/* Line 1792 of yacc.c  */
#line 597 "rtfGrammar.y"
    { GSRTFregisterFont(CTXT, (yyvsp[(6) - (6)].text), (yyvsp[(4) - (6)].number), (yyvsp[(2) - (6)].cmd).parameter);
                                                          free((void *)(yyvsp[(6) - (6)].text)); }
    break;

  case 132:
/* Line 1792 of yacc.c  */
#line 611 "rtfGrammar.y"
    { (yyval.number) = RTFfamilyNil - RTFfamilyNil; }
    break;

  case 133:
/* Line 1792 of yacc.c  */
#line 612 "rtfGrammar.y"
    { (yyval.number) = RTFfamilyRoman - RTFfamilyNil; }
    break;

  case 134:
/* Line 1792 of yacc.c  */
#line 613 "rtfGrammar.y"
    { (yyval.number) = RTFfamilySwiss - RTFfamilyNil; }
    break;

  case 135:
/* Line 1792 of yacc.c  */
#line 614 "rtfGrammar.y"
    { (yyval.number) = RTFfamilyModern - RTFfamilyNil; }
    break;

  case 136:
/* Line 1792 of yacc.c  */
#line 615 "rtfGrammar.y"
    { (yyval.number) = RTFfamilyScript - RTFfamilyNil; }
    break;

  case 137:
/* Line 1792 of yacc.c  */
#line 616 "rtfGrammar.y"
    { (yyval.number) = RTFfamilyDecor - RTFfamilyNil; }
    break;

  case 138:
/* Line 1792 of yacc.c  */
#line 617 "rtfGrammar.y"
    { (yyval.number) = RTFfamilyTech - RTFfamilyNil; }
    break;

  case 142:
/* Line 1792 of yacc.c  */
#line 634 "rtfGrammar.y"
    { 
		       GSRTFaddColor(CTXT, (yyvsp[(1) - (4)].cmd).parameter, (yyvsp[(2) - (4)].cmd).parameter, (yyvsp[(3) - (4)].cmd).parameter);
		       free((void *)(yyvsp[(4) - (4)].text));
		     }
    break;

  case 143:
/* Line 1792 of yacc.c  */
#line 639 "rtfGrammar.y"
    { 
		       GSRTFaddDefaultColor(CTXT);
		       free((void *)(yyvsp[(1) - (1)].text));
		     }
    break;


/* Line 1792 of yacc.c  */
#line 2892 "rtfGrammar.tab.m"
      default: break;
    }
  /* User semantic actions sometimes alter yychar, and that requires
     that yytoken be updated with the new translation.  We take the
     approach of translating immediately before every use of yytoken.
     One alternative is translating here after every semantic action,
     but that translation would be missed if the semantic action invokes
     YYABORT, YYACCEPT, or YYERROR immediately after altering yychar or
     if it invokes YYBACKUP.  In the case of YYABORT or YYACCEPT, an
     incorrect destructor might then be invoked immediately.  In the
     case of YYERROR or YYBACKUP, subsequent parser actions might lead
     to an incorrect destructor call or verbose syntax error message
     before the lookahead is translated.  */
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
  /* Make sure we have latest lookahead translation.  See comments at
     user semantic actions for why this is necessary.  */
  yytoken = yychar == YYEMPTY ? YYEMPTY : YYTRANSLATE (yychar);

  /* If not already recovering from an error, report this error.  */
  if (!yyerrstatus)
    {
      ++yynerrs;
#if ! YYERROR_VERBOSE
      yyerror (ctxt, lctxt, YY_("syntax error"));
#else
# define YYSYNTAX_ERROR yysyntax_error (&yymsg_alloc, &yymsg, \
                                        yyssp, yytoken)
      {
        char const *yymsgp = YY_("syntax error");
        int yysyntax_error_status;
        yysyntax_error_status = YYSYNTAX_ERROR;
        if (yysyntax_error_status == 0)
          yymsgp = yymsg;
        else if (yysyntax_error_status == 1)
          {
            if (yymsg != yymsgbuf)
              YYSTACK_FREE (yymsg);
            yymsg = (char *) YYSTACK_ALLOC (yymsg_alloc);
            if (!yymsg)
              {
                yymsg = yymsgbuf;
                yymsg_alloc = sizeof yymsgbuf;
                yysyntax_error_status = 2;
              }
            else
              {
                yysyntax_error_status = YYSYNTAX_ERROR;
                yymsgp = yymsg;
              }
          }
        yyerror (ctxt, lctxt, yymsgp);
        if (yysyntax_error_status == 2)
          goto yyexhaustedlab;
      }
# undef YYSYNTAX_ERROR
#endif
    }



  if (yyerrstatus == 3)
    {
      /* If just tried and failed to reuse lookahead token after an
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

  /* Else will try to reuse lookahead token after shifting the error
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
      if (!yypact_value_is_default (yyn))
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

  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  *++yyvsp = yylval;
  YY_IGNORE_MAYBE_UNINITIALIZED_END


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

#if !defined yyoverflow || YYERROR_VERBOSE
/*-------------------------------------------------.
| yyexhaustedlab -- memory exhaustion comes here.  |
`-------------------------------------------------*/
yyexhaustedlab:
  yyerror (ctxt, lctxt, YY_("memory exhausted"));
  yyresult = 2;
  /* Fall through.  */
#endif

yyreturn:
  if (yychar != YYEMPTY)
    {
      /* Make sure we have latest lookahead translation.  See comments at
         user semantic actions for why this is necessary.  */
      yytoken = YYTRANSLATE (yychar);
      yydestruct ("Cleanup: discarding lookahead",
                  yytoken, &yylval, ctxt, lctxt);
    }
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


/* Line 2055 of yacc.c  */
#line 651 "rtfGrammar.y"


/*	some C code here	*/

