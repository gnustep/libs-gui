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


/* Line 371 of yacc.c  */
#line 118 "rtfGrammar.tab.m"

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
     RTFfamilyTech = 361
   };
#endif


#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
typedef union YYSTYPE
{
/* Line 387 of yacc.c  */
#line 82 "rtfGrammar.y"

	int		number;
	const char	*text;
	RTFcmd		cmd;


/* Line 387 of yacc.c  */
#line 274 "rtfGrammar.tab.m"
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
#line 301 "rtfGrammar.tab.m"

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
#define YYLAST   1698

/* YYNTOKENS -- Number of terminals.  */
#define YYNTOKENS  109
/* YYNNTS -- Number of nonterminals.  */
#define YYNNTS  44
/* YYNRULES -- Number of rules.  */
#define YYNRULES  141
/* YYNRULES -- Number of states.  */
#define YYNSTATES  213

/* YYTRANSLATE(YYLEX) -- Bison symbol number corresponding to YYLEX.  */
#define YYUNDEFTOK  2
#define YYMAXUTOK   361

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
       2,     2,     2,   107,     2,   108,     2,     2,     2,     2,
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
     105,   106
};

#if YYDEBUG
/* YYPRHS[YYN] -- Index of the first RHS symbol of rule number YYN in
   YYRHS.  */
static const yytype_uint16 yyprhs[] =
{
       0,     0,     3,     4,     5,    13,    15,    17,    19,    21,
      23,    24,    27,    30,    33,    36,    39,    42,    43,    49,
      50,    56,    57,    63,    64,    70,    71,    77,    78,    84,
      85,    91,    92,    98,    99,   105,   109,   113,   115,   116,
     119,   122,   125,   128,   129,   131,   138,   139,   140,   152,
     156,   157,   159,   165,   174,   178,   179,   182,   185,   187,
     189,   191,   193,   195,   197,   199,   201,   203,   205,   207,
     209,   211,   213,   215,   217,   219,   221,   223,   225,   227,
     229,   231,   233,   235,   237,   239,   241,   243,   245,   247,
     249,   251,   253,   255,   257,   259,   261,   263,   265,   267,
     269,   271,   273,   275,   277,   279,   280,   282,   284,   286,
     287,   288,   298,   299,   300,   313,   314,   315,   324,   329,
     330,   333,   338,   345,   350,   351,   354,   357,   360,   363,
     366,   368,   370,   372,   374,   376,   378,   380,   385,   386,
     389,   394
};

/* YYRHS -- A `-1'-separated list of the rules' RHS.  */
static const yytype_int16 yyrhs[] =
{
     110,     0,    -1,    -1,    -1,   107,   111,     4,   113,   114,
     112,   108,    -1,     5,    -1,     6,    -1,     7,    -1,     8,
      -1,    98,    -1,    -1,   114,   145,    -1,   114,   150,    -1,
     114,   134,    -1,   114,     3,    -1,   114,   115,    -1,   114,
       1,    -1,    -1,   107,   116,   114,   135,   108,    -1,    -1,
     107,   117,     9,   114,   108,    -1,    -1,   107,   118,    10,
     114,   108,    -1,    -1,   107,   119,    11,   114,   108,    -1,
      -1,   107,   120,    12,   114,   108,    -1,    -1,   107,   121,
      13,   114,   108,    -1,    -1,   107,   122,    14,   114,   108,
      -1,    -1,   107,   123,    15,   114,   108,    -1,    -1,   107,
     124,    27,   125,   108,    -1,   107,     1,   108,    -1,   126,
     128,   132,    -1,     1,    -1,    -1,   126,    31,    -1,   126,
      32,    -1,   126,    33,    -1,   126,    34,    -1,    -1,     9,
      -1,   107,   127,    28,     3,   131,   108,    -1,    -1,    -1,
     107,   127,    28,   107,   129,   133,     3,   131,   108,   130,
     108,    -1,   107,     1,   108,    -1,    -1,    29,    -1,   107,
     127,    30,     3,   108,    -1,   107,   127,    30,   107,   133,
       3,   108,   108,    -1,   107,     1,   108,    -1,    -1,   133,
     134,    -1,   133,   115,    -1,    47,    -1,    48,    -1,    58,
      -1,    59,    -1,    60,    -1,    61,    -1,    62,    -1,    63,
      -1,    64,    -1,    65,    -1,    66,    -1,    94,    -1,    67,
      -1,    68,    -1,    69,    -1,    70,    -1,    72,    -1,    71,
      -1,    18,    -1,    73,    -1,    43,    -1,    44,    -1,    45,
      -1,    92,    -1,    93,    -1,    74,    -1,    75,    -1,    76,
      -1,    77,    -1,    78,    -1,    79,    -1,    80,    -1,    81,
      -1,    82,    -1,    83,    -1,    84,    -1,    85,    -1,    86,
      -1,    87,    -1,    88,    -1,    89,    -1,    90,    -1,    91,
      -1,    16,    -1,    17,    -1,    19,    -1,    98,    -1,    -1,
     136,    -1,   139,    -1,   142,    -1,    -1,    -1,   107,    49,
       3,    50,    51,   108,   137,   114,   138,    -1,    -1,    -1,
     107,    52,    55,     3,    56,     3,    57,     3,   108,   140,
     114,   141,    -1,    -1,    -1,   107,    53,    55,     3,   108,
     143,   114,   144,    -1,   107,    99,   146,   108,    -1,    -1,
     146,   147,    -1,   146,   107,   147,   108,    -1,   146,   107,
     147,   115,     3,   108,    -1,    47,   149,   148,     3,    -1,
      -1,   148,    95,    -1,   148,    96,    -1,   148,    97,    -1,
     148,    35,    -1,   148,   115,    -1,   100,    -1,   101,    -1,
     102,    -1,   103,    -1,   104,    -1,   105,    -1,   106,    -1,
     107,    46,   151,   108,    -1,    -1,   151,   152,    -1,    40,
      41,    42,     3,    -1,     3,    -1
};

/* YYRLINE[YYN] -- source line where rule number YYN was defined.  */
static const yytype_uint16 yyrline[] =
{
       0,   205,   205,   205,   205,   208,   209,   210,   211,   213,
     216,   217,   218,   219,   220,   221,   222,   225,   225,   226,
     226,   227,   227,   228,   228,   229,   229,   230,   230,   231,
     231,   232,   232,   233,   233,   234,   238,   239,   242,   243,
     244,   245,   246,   249,   250,   253,   254,   254,   254,   255,
     258,   259,   262,   263,   264,   267,   268,   269,   276,   283,
     290,   297,   304,   311,   318,   325,   332,   339,   346,   353,
     360,   361,   362,   363,   364,   371,   372,   373,   374,   381,
     388,   395,   402,   409,   416,   423,   430,   437,   444,   451,
     458,   465,   466,   473,   480,   487,   494,   501,   508,   514,
     515,   516,   517,   518,   519,   523,   524,   525,   526,   538,
     538,   538,   553,   553,   553,   567,   567,   567,   576,   579,
     580,   581,   582,   588,   592,   593,   594,   595,   596,   597,
     602,   603,   604,   605,   606,   607,   608,   616,   619,   620,
     624,   629
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
  "'{'", "'}'", "$accept", "rtfFile", "$@1", "$@2", "rtfCharset",
  "rtfIngredients", "rtfBlock", "$@3", "$@4", "$@5", "$@6", "$@7", "$@8",
  "$@9", "$@10", "$@11", "rtfField", "rtfFieldMod", "rtfIgnore",
  "rtfFieldinst", "$@12", "$@13", "rtfFieldalt", "rtfFieldrslt",
  "rtfStatementList", "rtfStatement", "rtfNeXTstuff", "rtfNeXTGraphic",
  "$@14", "$@15", "rtfNeXTHelpLink", "$@16", "$@17", "rtfNeXTHelpMarker",
  "$@18", "$@19", "rtfFontList", "rtfFonts", "rtfFontStatement",
  "rtfFontAttrs", "rtfFontFamily", "rtfColorDef", "rtfColors",
  "rtfColorStatement", YY_NULL
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
     355,   356,   357,   358,   359,   360,   361,   123,   125
};
# endif

/* YYR1[YYN] -- Symbol number of symbol that rule YYN derives.  */
static const yytype_uint8 yyr1[] =
{
       0,   109,   111,   112,   110,   113,   113,   113,   113,   113,
     114,   114,   114,   114,   114,   114,   114,   116,   115,   117,
     115,   118,   115,   119,   115,   120,   115,   121,   115,   122,
     115,   123,   115,   124,   115,   115,   125,   125,   126,   126,
     126,   126,   126,   127,   127,   128,   129,   130,   128,   128,
     131,   131,   132,   132,   132,   133,   133,   133,   134,   134,
     134,   134,   134,   134,   134,   134,   134,   134,   134,   134,
     134,   134,   134,   134,   134,   134,   134,   134,   134,   134,
     134,   134,   134,   134,   134,   134,   134,   134,   134,   134,
     134,   134,   134,   134,   134,   134,   134,   134,   134,   134,
     134,   134,   134,   134,   134,   135,   135,   135,   135,   137,
     138,   136,   140,   141,   139,   143,   144,   142,   145,   146,
     146,   146,   146,   147,   148,   148,   148,   148,   148,   148,
     149,   149,   149,   149,   149,   149,   149,   150,   151,   151,
     152,   152
};

/* YYR2[YYN] -- Number of symbols composing right hand side of rule YYN.  */
static const yytype_uint8 yyr2[] =
{
       0,     2,     0,     0,     7,     1,     1,     1,     1,     1,
       0,     2,     2,     2,     2,     2,     2,     0,     5,     0,
       5,     0,     5,     0,     5,     0,     5,     0,     5,     0,
       5,     0,     5,     0,     5,     3,     3,     1,     0,     2,
       2,     2,     2,     0,     1,     6,     0,     0,    11,     3,
       0,     1,     5,     8,     3,     0,     2,     2,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     0,     1,     1,     1,     0,
       0,     9,     0,     0,    12,     0,     0,     8,     4,     0,
       2,     4,     6,     4,     0,     2,     2,     2,     2,     2,
       1,     1,     1,     1,     1,     1,     1,     4,     0,     2,
       4,     1
};

/* YYDEFACT[STATE-NAME] -- Default reduction number in state STATE-NUM.
   Performed when YYTABLE doesn't specify something else to do.  Zero
   means the default is an error.  */
static const yytype_uint8 yydefact[] =
{
       0,     2,     0,     0,     1,     0,     5,     6,     7,     8,
       9,    10,     0,    16,    14,   101,   102,    76,   103,    78,
      79,    80,    58,    59,    60,    61,    62,    63,    64,    65,
      66,    67,    68,    70,    71,    72,    73,    75,    74,    77,
      83,    84,    85,    86,    87,    88,    89,    90,    91,    92,
      93,    94,    95,    96,    97,    98,    99,   100,    81,    82,
      69,   104,     0,     0,    15,    13,    11,    12,     0,   138,
     119,    10,     0,     0,     0,     0,     0,     0,     0,     0,
       4,    35,     0,     0,     0,    10,    10,    10,    10,    10,
      10,    10,     0,   141,     0,   137,   139,     0,     0,   118,
     120,     0,     0,   106,   107,   108,     0,     0,     0,     0,
       0,     0,     0,    37,     0,     0,     0,   130,   131,   132,
     133,   134,   135,   136,   124,     0,     0,     0,     0,    18,
      20,    22,    24,    26,    28,    30,    32,    34,    39,    40,
      41,    42,     0,     0,     0,     0,     0,   121,     0,     0,
       0,     0,     0,    44,     0,     0,    36,   140,   123,   128,
     125,   126,   127,   129,     0,     0,     0,     0,    49,     0,
       0,     0,   122,     0,     0,   115,    50,    46,    54,     0,
     109,     0,    10,    51,     0,    55,     0,    55,    10,     0,
       0,    45,     0,    52,     0,     0,     0,   117,    50,    57,
      56,     0,   111,   112,     0,     0,    10,    47,    53,     0,
       0,   114,    48
};

/* YYDEFGOTO[NTERM-NUM].  */
static const yytype_int16 yydefgoto[] =
{
      -1,     2,     3,    63,    11,    12,    64,    71,    72,    73,
      74,    75,    76,    77,    78,    79,   114,   115,   154,   143,
     185,   210,   184,   156,   192,    65,   102,   103,   188,   202,
     104,   206,   211,   105,   182,   197,    66,    83,   100,   145,
     124,    67,    82,    96
};

/* YYPACT[STATE-NUM] -- Index in YYTABLE of the portion describing
   STATE-NUM.  */
#define YYPACT_NINF -158
static const yytype_int16 yypact[] =
{
    -100,  -158,    24,    25,  -158,     4,  -158,  -158,  -158,  -158,
    -158,  -158,   372,  -158,  -158,  -158,  -158,  -158,  -158,  -158,
    -158,  -158,  -158,  -158,  -158,  -158,  -158,  -158,  -158,  -158,
    -158,  -158,  -158,  -158,  -158,  -158,  -158,  -158,  -158,  -158,
    -158,  -158,  -158,  -158,  -158,  -158,  -158,  -158,  -158,  -158,
    -158,  -158,  -158,  -158,  -158,  -158,  -158,  -158,  -158,  -158,
    -158,  -158,   178,   -72,  -158,  -158,  -158,  -158,   -65,  -158,
    -158,  -158,    35,    36,    34,    45,    46,    33,    43,    37,
    -158,  -158,     1,   -42,   466,  -158,  -158,  -158,  -158,  -158,
    -158,  -158,     0,  -158,     7,  -158,  -158,   -50,    13,  -158,
    -158,    78,   -47,  -158,  -158,  -158,   560,   654,   748,   842,
     936,  1030,  1124,  -158,   -46,    -6,    26,  -158,  -158,  -158,
    -158,  -158,  -158,  -158,  -158,   -68,    60,    14,    16,  -158,
    -158,  -158,  -158,  -158,  -158,  -158,  -158,  -158,  -158,  -158,
    -158,  -158,    21,   -40,    70,     3,   278,  -158,    71,    27,
      72,    73,   -30,  -158,    52,    12,  -158,  -158,  -158,  -158,
    -158,  -158,  -158,  -158,   -26,    32,    28,   -23,  -158,    -1,
     -22,    74,  -158,    -5,   105,  -158,    84,  -158,  -158,     5,
    -158,    57,  -158,  -158,     8,  -158,    10,  -158,  -158,   112,
    1218,  -158,  1499,  -158,  1591,  1312,    11,  -158,    84,  -158,
    -158,    20,  -158,  -158,    65,    66,  -158,  -158,  -158,  1406,
      67,  -158,  -158
};

/* YYPGOTO[NTERM-NUM].  */
static const yytype_int16 yypgoto[] =
{
    -158,  -158,  -158,  -158,  -158,   -71,  -122,  -158,  -158,  -158,
    -158,  -158,  -158,  -158,  -158,  -158,  -158,  -158,   -35,  -158,
    -158,  -158,   -69,  -158,   -55,  -157,  -158,  -158,  -158,  -158,
    -158,  -158,  -158,  -158,  -158,  -158,  -158,  -158,    80,  -158,
    -158,  -158,  -158,  -158
};

/* YYTABLE[YYPACT[STATE-NUM]].  What to do in state STATE-NUM.  If
   positive, shift that token.  If negative, reduce the rule which
   number is the opposite.  If YYTABLE_NINF, syntax error.  */
#define YYTABLE_NINF -117
static const yytype_int16 yytable[] =
{
      84,   113,   176,   148,    93,    97,   158,     1,   186,     6,
       7,     8,     9,   170,   106,   107,   108,   109,   110,   111,
     112,   153,   152,   163,     4,   138,   139,   140,   141,     5,
     153,   -38,   -38,   -38,   -38,   200,    80,   200,   159,   146,
     147,    94,   -43,    81,    85,    87,    86,    90,   116,   -43,
     117,   118,   119,   120,   121,   122,   123,    88,    91,    89,
      97,   129,   137,   149,    92,    98,    99,   155,   144,   150,
     199,   151,   199,   157,   164,   166,   167,   165,   168,    68,
     169,   -17,   172,   173,   174,   175,   178,   -19,   -21,   -23,
     -25,   -27,   -29,   -31,   -17,   -17,   -17,   -17,   160,   161,
     162,   142,    10,   180,   179,   -33,   177,   -38,   181,    95,
     146,   190,   187,   183,   189,   196,   191,   195,   193,   203,
     171,   -17,   -17,   -17,    69,   -17,   -17,   126,   205,   204,
     127,   128,   194,     0,     0,   209,   -17,   -17,   -17,   -17,
     -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,
     -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,
     -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,
     -17,   -17,   -17,   207,   208,   212,   -17,    70,   125,    68,
       0,   -17,     0,     0,     0,   -17,   -17,   -19,   -21,   -23,
     -25,   -27,   -29,   -31,   -17,   -17,   -17,   -17,     0,     0,
       0,     0,     0,     0,     0,   -33,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,   -17,   -17,   -17,    69,   -17,   -17,     0,     0,     0,
       0,     0,     0,     0,     0,     0,   -17,   -17,   -17,   -17,
     -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,
     -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,
     -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,
     -17,   -17,   -17,     0,     0,     0,   -17,    70,     0,    68,
       0,   -17,     0,     0,     0,   -17,   -17,   -19,   -21,   -23,
     -25,   -27,   -29,   -31,   -17,   -17,   -17,   -17,     0,     0,
       0,     0,     0,     0,     0,   -33,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,   -17,   -17,   -17,     0,   -17,   -17,     0,     0,     0,
       0,     0,     0,     0,     0,     0,   -17,   -17,   -17,   -17,
     -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,
     -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,
     -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,   -17,
     -17,   -17,   -17,    13,     0,    14,   -17,     0,     0,     0,
       0,     0,     0,     0,     0,   -17,   -17,     0,    15,    16,
      17,    18,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,    19,    20,    21,     0,    22,
      23,     0,     0,     0,     0,     0,     0,     0,     0,     0,
      24,    25,    26,    27,    28,    29,    30,    31,    32,    33,
      34,    35,    36,    37,    38,    39,    40,    41,    42,    43,
      44,    45,    46,    47,    48,    49,    50,    51,    52,    53,
      54,    55,    56,    57,    58,    59,    60,    13,     0,    14,
      61,     0,     0,     0,     0,     0,     0,     0,     0,    62,
      -3,     0,    15,    16,    17,    18,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,    19,
      20,    21,     0,    22,    23,     0,     0,     0,     0,     0,
       0,     0,     0,     0,    24,    25,    26,    27,    28,    29,
      30,    31,    32,    33,    34,    35,    36,    37,    38,    39,
      40,    41,    42,    43,    44,    45,    46,    47,    48,    49,
      50,    51,    52,    53,    54,    55,    56,    57,    58,    59,
      60,    13,     0,    14,    61,     0,     0,     0,     0,     0,
       0,     0,     0,   101,  -105,     0,    15,    16,    17,    18,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,    19,    20,    21,     0,    22,    23,     0,
       0,     0,     0,     0,     0,     0,     0,     0,    24,    25,
      26,    27,    28,    29,    30,    31,    32,    33,    34,    35,
      36,    37,    38,    39,    40,    41,    42,    43,    44,    45,
      46,    47,    48,    49,    50,    51,    52,    53,    54,    55,
      56,    57,    58,    59,    60,    13,     0,    14,    61,     0,
       0,     0,     0,     0,     0,     0,     0,    62,   130,     0,
      15,    16,    17,    18,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,    19,    20,    21,
       0,    22,    23,     0,     0,     0,     0,     0,     0,     0,
       0,     0,    24,    25,    26,    27,    28,    29,    30,    31,
      32,    33,    34,    35,    36,    37,    38,    39,    40,    41,
      42,    43,    44,    45,    46,    47,    48,    49,    50,    51,
      52,    53,    54,    55,    56,    57,    58,    59,    60,    13,
       0,    14,    61,     0,     0,     0,     0,     0,     0,     0,
       0,    62,   131,     0,    15,    16,    17,    18,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,    19,    20,    21,     0,    22,    23,     0,     0,     0,
       0,     0,     0,     0,     0,     0,    24,    25,    26,    27,
      28,    29,    30,    31,    32,    33,    34,    35,    36,    37,
      38,    39,    40,    41,    42,    43,    44,    45,    46,    47,
      48,    49,    50,    51,    52,    53,    54,    55,    56,    57,
      58,    59,    60,    13,     0,    14,    61,     0,     0,     0,
       0,     0,     0,     0,     0,    62,   132,     0,    15,    16,
      17,    18,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,    19,    20,    21,     0,    22,
      23,     0,     0,     0,     0,     0,     0,     0,     0,     0,
      24,    25,    26,    27,    28,    29,    30,    31,    32,    33,
      34,    35,    36,    37,    38,    39,    40,    41,    42,    43,
      44,    45,    46,    47,    48,    49,    50,    51,    52,    53,
      54,    55,    56,    57,    58,    59,    60,    13,     0,    14,
      61,     0,     0,     0,     0,     0,     0,     0,     0,    62,
     133,     0,    15,    16,    17,    18,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,    19,
      20,    21,     0,    22,    23,     0,     0,     0,     0,     0,
       0,     0,     0,     0,    24,    25,    26,    27,    28,    29,
      30,    31,    32,    33,    34,    35,    36,    37,    38,    39,
      40,    41,    42,    43,    44,    45,    46,    47,    48,    49,
      50,    51,    52,    53,    54,    55,    56,    57,    58,    59,
      60,    13,     0,    14,    61,     0,     0,     0,     0,     0,
       0,     0,     0,    62,   134,     0,    15,    16,    17,    18,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,    19,    20,    21,     0,    22,    23,     0,
       0,     0,     0,     0,     0,     0,     0,     0,    24,    25,
      26,    27,    28,    29,    30,    31,    32,    33,    34,    35,
      36,    37,    38,    39,    40,    41,    42,    43,    44,    45,
      46,    47,    48,    49,    50,    51,    52,    53,    54,    55,
      56,    57,    58,    59,    60,    13,     0,    14,    61,     0,
       0,     0,     0,     0,     0,     0,     0,    62,   135,     0,
      15,    16,    17,    18,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,    19,    20,    21,
       0,    22,    23,     0,     0,     0,     0,     0,     0,     0,
       0,     0,    24,    25,    26,    27,    28,    29,    30,    31,
      32,    33,    34,    35,    36,    37,    38,    39,    40,    41,
      42,    43,    44,    45,    46,    47,    48,    49,    50,    51,
      52,    53,    54,    55,    56,    57,    58,    59,    60,    13,
       0,    14,    61,     0,     0,     0,     0,     0,     0,     0,
       0,    62,   136,     0,    15,    16,    17,    18,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,    19,    20,    21,     0,    22,    23,     0,     0,     0,
       0,     0,     0,     0,     0,     0,    24,    25,    26,    27,
      28,    29,    30,    31,    32,    33,    34,    35,    36,    37,
      38,    39,    40,    41,    42,    43,    44,    45,    46,    47,
      48,    49,    50,    51,    52,    53,    54,    55,    56,    57,
      58,    59,    60,    13,     0,    14,    61,     0,     0,     0,
       0,     0,     0,     0,     0,    62,  -116,     0,    15,    16,
      17,    18,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,    19,    20,    21,     0,    22,
      23,     0,     0,     0,     0,     0,     0,     0,     0,     0,
      24,    25,    26,    27,    28,    29,    30,    31,    32,    33,
      34,    35,    36,    37,    38,    39,    40,    41,    42,    43,
      44,    45,    46,    47,    48,    49,    50,    51,    52,    53,
      54,    55,    56,    57,    58,    59,    60,    13,     0,    14,
      61,     0,     0,     0,     0,     0,     0,     0,     0,    62,
    -110,     0,    15,    16,    17,    18,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,    19,
      20,    21,     0,    22,    23,     0,     0,     0,     0,     0,
       0,     0,     0,     0,    24,    25,    26,    27,    28,    29,
      30,    31,    32,    33,    34,    35,    36,    37,    38,    39,
      40,    41,    42,    43,    44,    45,    46,    47,    48,    49,
      50,    51,    52,    53,    54,    55,    56,    57,    58,    59,
      60,     0,   198,     0,    61,     0,     0,     0,     0,     0,
       0,     0,     0,    62,  -113,    15,    16,    17,    18,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,    19,    20,    21,     0,    22,    23,     0,     0,
       0,     0,     0,     0,     0,     0,     0,    24,    25,    26,
      27,    28,    29,    30,    31,    32,    33,    34,    35,    36,
      37,    38,    39,    40,    41,    42,    43,    44,    45,    46,
      47,    48,    49,    50,    51,    52,    53,    54,    55,    56,
      57,    58,    59,    60,   201,     0,     0,    61,     0,     0,
       0,     0,     0,     0,     0,     0,   146,    15,    16,    17,
      18,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,    19,    20,    21,     0,    22,    23,
       0,     0,     0,     0,     0,     0,     0,     0,     0,    24,
      25,    26,    27,    28,    29,    30,    31,    32,    33,    34,
      35,    36,    37,    38,    39,    40,    41,    42,    43,    44,
      45,    46,    47,    48,    49,    50,    51,    52,    53,    54,
      55,    56,    57,    58,    59,    60,     0,     0,     0,    61,
       0,     0,     0,     0,     0,     0,     0,     0,   146
};

#define yypact_value_is_default(Yystate) \
  (!!((Yystate) == (-158)))

#define yytable_value_is_error(Yytable_value) \
  YYID (0)

static const yytype_int16 yycheck[] =
{
      71,     1,     3,   125,     3,    47,     3,   107,     3,     5,
       6,     7,     8,     1,    85,    86,    87,    88,    89,    90,
      91,     9,     1,   145,     0,    31,    32,    33,    34,     4,
       9,    31,    32,    33,    34,   192,   108,   194,    35,   107,
     108,    40,    30,   108,     9,    11,    10,    14,    41,    28,
     100,   101,   102,   103,   104,   105,   106,    12,    15,    13,
      47,   108,   108,     3,    27,   107,   108,   107,    42,    55,
     192,    55,   194,     3,     3,     3,     3,    50,   108,     1,
      28,     3,   108,    51,    56,   108,   108,     9,    10,    11,
      12,    13,    14,    15,    16,    17,    18,    19,    95,    96,
      97,   107,    98,   108,    30,    27,   107,   107,     3,   108,
     107,   182,   107,    29,    57,     3,   108,   188,   108,   108,
     155,    43,    44,    45,    46,    47,    48,    49,   108,   198,
      52,    53,   187,    -1,    -1,   206,    58,    59,    60,    61,
      62,    63,    64,    65,    66,    67,    68,    69,    70,    71,
      72,    73,    74,    75,    76,    77,    78,    79,    80,    81,
      82,    83,    84,    85,    86,    87,    88,    89,    90,    91,
      92,    93,    94,   108,   108,   108,    98,    99,    98,     1,
      -1,     3,    -1,    -1,    -1,   107,   108,     9,    10,    11,
      12,    13,    14,    15,    16,    17,    18,    19,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    27,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    43,    44,    45,    46,    47,    48,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    58,    59,    60,    61,
      62,    63,    64,    65,    66,    67,    68,    69,    70,    71,
      72,    73,    74,    75,    76,    77,    78,    79,    80,    81,
      82,    83,    84,    85,    86,    87,    88,    89,    90,    91,
      92,    93,    94,    -1,    -1,    -1,    98,    99,    -1,     1,
      -1,     3,    -1,    -1,    -1,   107,   108,     9,    10,    11,
      12,    13,    14,    15,    16,    17,    18,    19,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    27,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    43,    44,    45,    -1,    47,    48,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    58,    59,    60,    61,
      62,    63,    64,    65,    66,    67,    68,    69,    70,    71,
      72,    73,    74,    75,    76,    77,    78,    79,    80,    81,
      82,    83,    84,    85,    86,    87,    88,    89,    90,    91,
      92,    93,    94,     1,    -1,     3,    98,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,   107,   108,    -1,    16,    17,
      18,    19,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    43,    44,    45,    -1,    47,
      48,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      58,    59,    60,    61,    62,    63,    64,    65,    66,    67,
      68,    69,    70,    71,    72,    73,    74,    75,    76,    77,
      78,    79,    80,    81,    82,    83,    84,    85,    86,    87,
      88,    89,    90,    91,    92,    93,    94,     1,    -1,     3,
      98,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,   107,
     108,    -1,    16,    17,    18,    19,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    43,
      44,    45,    -1,    47,    48,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    58,    59,    60,    61,    62,    63,
      64,    65,    66,    67,    68,    69,    70,    71,    72,    73,
      74,    75,    76,    77,    78,    79,    80,    81,    82,    83,
      84,    85,    86,    87,    88,    89,    90,    91,    92,    93,
      94,     1,    -1,     3,    98,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,   107,   108,    -1,    16,    17,    18,    19,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    43,    44,    45,    -1,    47,    48,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    58,    59,
      60,    61,    62,    63,    64,    65,    66,    67,    68,    69,
      70,    71,    72,    73,    74,    75,    76,    77,    78,    79,
      80,    81,    82,    83,    84,    85,    86,    87,    88,    89,
      90,    91,    92,    93,    94,     1,    -1,     3,    98,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,   107,   108,    -1,
      16,    17,    18,    19,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    43,    44,    45,
      -1,    47,    48,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    58,    59,    60,    61,    62,    63,    64,    65,
      66,    67,    68,    69,    70,    71,    72,    73,    74,    75,
      76,    77,    78,    79,    80,    81,    82,    83,    84,    85,
      86,    87,    88,    89,    90,    91,    92,    93,    94,     1,
      -1,     3,    98,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,   107,   108,    -1,    16,    17,    18,    19,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    43,    44,    45,    -1,    47,    48,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    58,    59,    60,    61,
      62,    63,    64,    65,    66,    67,    68,    69,    70,    71,
      72,    73,    74,    75,    76,    77,    78,    79,    80,    81,
      82,    83,    84,    85,    86,    87,    88,    89,    90,    91,
      92,    93,    94,     1,    -1,     3,    98,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,   107,   108,    -1,    16,    17,
      18,    19,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    43,    44,    45,    -1,    47,
      48,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      58,    59,    60,    61,    62,    63,    64,    65,    66,    67,
      68,    69,    70,    71,    72,    73,    74,    75,    76,    77,
      78,    79,    80,    81,    82,    83,    84,    85,    86,    87,
      88,    89,    90,    91,    92,    93,    94,     1,    -1,     3,
      98,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,   107,
     108,    -1,    16,    17,    18,    19,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    43,
      44,    45,    -1,    47,    48,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    58,    59,    60,    61,    62,    63,
      64,    65,    66,    67,    68,    69,    70,    71,    72,    73,
      74,    75,    76,    77,    78,    79,    80,    81,    82,    83,
      84,    85,    86,    87,    88,    89,    90,    91,    92,    93,
      94,     1,    -1,     3,    98,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,   107,   108,    -1,    16,    17,    18,    19,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    43,    44,    45,    -1,    47,    48,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    58,    59,
      60,    61,    62,    63,    64,    65,    66,    67,    68,    69,
      70,    71,    72,    73,    74,    75,    76,    77,    78,    79,
      80,    81,    82,    83,    84,    85,    86,    87,    88,    89,
      90,    91,    92,    93,    94,     1,    -1,     3,    98,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,   107,   108,    -1,
      16,    17,    18,    19,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    43,    44,    45,
      -1,    47,    48,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    58,    59,    60,    61,    62,    63,    64,    65,
      66,    67,    68,    69,    70,    71,    72,    73,    74,    75,
      76,    77,    78,    79,    80,    81,    82,    83,    84,    85,
      86,    87,    88,    89,    90,    91,    92,    93,    94,     1,
      -1,     3,    98,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,   107,   108,    -1,    16,    17,    18,    19,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    43,    44,    45,    -1,    47,    48,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    58,    59,    60,    61,
      62,    63,    64,    65,    66,    67,    68,    69,    70,    71,
      72,    73,    74,    75,    76,    77,    78,    79,    80,    81,
      82,    83,    84,    85,    86,    87,    88,    89,    90,    91,
      92,    93,    94,     1,    -1,     3,    98,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,   107,   108,    -1,    16,    17,
      18,    19,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    43,    44,    45,    -1,    47,
      48,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      58,    59,    60,    61,    62,    63,    64,    65,    66,    67,
      68,    69,    70,    71,    72,    73,    74,    75,    76,    77,
      78,    79,    80,    81,    82,    83,    84,    85,    86,    87,
      88,    89,    90,    91,    92,    93,    94,     1,    -1,     3,
      98,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,   107,
     108,    -1,    16,    17,    18,    19,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    43,
      44,    45,    -1,    47,    48,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    58,    59,    60,    61,    62,    63,
      64,    65,    66,    67,    68,    69,    70,    71,    72,    73,
      74,    75,    76,    77,    78,    79,    80,    81,    82,    83,
      84,    85,    86,    87,    88,    89,    90,    91,    92,    93,
      94,    -1,     3,    -1,    98,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,   107,   108,    16,    17,    18,    19,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    43,    44,    45,    -1,    47,    48,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    58,    59,    60,
      61,    62,    63,    64,    65,    66,    67,    68,    69,    70,
      71,    72,    73,    74,    75,    76,    77,    78,    79,    80,
      81,    82,    83,    84,    85,    86,    87,    88,    89,    90,
      91,    92,    93,    94,     3,    -1,    -1,    98,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,   107,    16,    17,    18,
      19,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    43,    44,    45,    -1,    47,    48,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    58,
      59,    60,    61,    62,    63,    64,    65,    66,    67,    68,
      69,    70,    71,    72,    73,    74,    75,    76,    77,    78,
      79,    80,    81,    82,    83,    84,    85,    86,    87,    88,
      89,    90,    91,    92,    93,    94,    -1,    -1,    -1,    98,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,   107
};

/* YYSTOS[STATE-NUM] -- The (internal number of the) accessing
   symbol of state STATE-NUM.  */
static const yytype_uint8 yystos[] =
{
       0,   107,   110,   111,     0,     4,     5,     6,     7,     8,
      98,   113,   114,     1,     3,    16,    17,    18,    19,    43,
      44,    45,    47,    48,    58,    59,    60,    61,    62,    63,
      64,    65,    66,    67,    68,    69,    70,    71,    72,    73,
      74,    75,    76,    77,    78,    79,    80,    81,    82,    83,
      84,    85,    86,    87,    88,    89,    90,    91,    92,    93,
      94,    98,   107,   112,   115,   134,   145,   150,     1,    46,
      99,   116,   117,   118,   119,   120,   121,   122,   123,   124,
     108,   108,   151,   146,   114,     9,    10,    11,    12,    13,
      14,    15,    27,     3,    40,   108,   152,    47,   107,   108,
     147,   107,   135,   136,   139,   142,   114,   114,   114,   114,
     114,   114,   114,     1,   125,   126,    41,   100,   101,   102,
     103,   104,   105,   106,   149,   147,    49,    52,    53,   108,
     108,   108,   108,   108,   108,   108,   108,   108,    31,    32,
      33,    34,   107,   128,    42,   148,   107,   108,   115,     3,
      55,    55,     1,     9,   127,   107,   132,     3,     3,    35,
      95,    96,    97,   115,     3,    50,     3,     3,   108,    28,
       1,   127,   108,    51,    56,   108,     3,   107,   108,    30,
     108,     3,   143,    29,   131,   129,     3,   107,   137,    57,
     114,   108,   133,   108,   133,   114,     3,   144,     3,   115,
     134,     3,   138,   108,   131,   108,   140,   108,   108,   114,
     130,   141,   108
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
#line 205 "rtfGrammar.y"
    { GSRTFstart(CTXT); }
    break;

  case 3:
/* Line 1792 of yacc.c  */
#line 205 "rtfGrammar.y"
    { GSRTFstop(CTXT); }
    break;

  case 5:
/* Line 1792 of yacc.c  */
#line 208 "rtfGrammar.y"
    { (yyval.number) = 1; }
    break;

  case 6:
/* Line 1792 of yacc.c  */
#line 209 "rtfGrammar.y"
    { (yyval.number) = 2; }
    break;

  case 7:
/* Line 1792 of yacc.c  */
#line 210 "rtfGrammar.y"
    { (yyval.number) = 3; }
    break;

  case 8:
/* Line 1792 of yacc.c  */
#line 211 "rtfGrammar.y"
    { (yyval.number) = 4; }
    break;

  case 9:
/* Line 1792 of yacc.c  */
#line 213 "rtfGrammar.y"
    { (yyval.number) = 1; free((void*)(yyvsp[(1) - (1)].cmd).name); }
    break;

  case 14:
/* Line 1792 of yacc.c  */
#line 220 "rtfGrammar.y"
    { GSRTFmangleText(CTXT, (yyvsp[(2) - (2)].text)); free((void *)(yyvsp[(2) - (2)].text)); }
    break;

  case 17:
/* Line 1792 of yacc.c  */
#line 225 "rtfGrammar.y"
    { GSRTFopenBlock(CTXT, NO); }
    break;

  case 18:
/* Line 1792 of yacc.c  */
#line 225 "rtfGrammar.y"
    { GSRTFcloseBlock(CTXT, NO); }
    break;

  case 19:
/* Line 1792 of yacc.c  */
#line 226 "rtfGrammar.y"
    { GSRTFopenBlock(CTXT, YES); }
    break;

  case 20:
/* Line 1792 of yacc.c  */
#line 226 "rtfGrammar.y"
    { GSRTFcloseBlock(CTXT, YES); }
    break;

  case 21:
/* Line 1792 of yacc.c  */
#line 227 "rtfGrammar.y"
    { GSRTFopenBlock(CTXT, YES); }
    break;

  case 22:
/* Line 1792 of yacc.c  */
#line 227 "rtfGrammar.y"
    { GSRTFcloseBlock(CTXT, YES); }
    break;

  case 23:
/* Line 1792 of yacc.c  */
#line 228 "rtfGrammar.y"
    { GSRTFopenBlock(CTXT, YES); }
    break;

  case 24:
/* Line 1792 of yacc.c  */
#line 228 "rtfGrammar.y"
    { GSRTFcloseBlock(CTXT, YES); }
    break;

  case 25:
/* Line 1792 of yacc.c  */
#line 229 "rtfGrammar.y"
    { GSRTFopenBlock(CTXT, YES); }
    break;

  case 26:
/* Line 1792 of yacc.c  */
#line 229 "rtfGrammar.y"
    { GSRTFcloseBlock(CTXT, YES); }
    break;

  case 27:
/* Line 1792 of yacc.c  */
#line 230 "rtfGrammar.y"
    { GSRTFopenBlock(CTXT, YES); }
    break;

  case 28:
/* Line 1792 of yacc.c  */
#line 230 "rtfGrammar.y"
    { GSRTFcloseBlock(CTXT, YES); }
    break;

  case 29:
/* Line 1792 of yacc.c  */
#line 231 "rtfGrammar.y"
    { GSRTFopenBlock(CTXT, YES); }
    break;

  case 30:
/* Line 1792 of yacc.c  */
#line 231 "rtfGrammar.y"
    { GSRTFcloseBlock(CTXT, YES); }
    break;

  case 31:
/* Line 1792 of yacc.c  */
#line 232 "rtfGrammar.y"
    { GSRTFopenBlock(CTXT, YES); }
    break;

  case 32:
/* Line 1792 of yacc.c  */
#line 232 "rtfGrammar.y"
    { GSRTFcloseBlock(CTXT, YES); }
    break;

  case 33:
/* Line 1792 of yacc.c  */
#line 233 "rtfGrammar.y"
    { GSRTFopenBlock(CTXT, NO); }
    break;

  case 34:
/* Line 1792 of yacc.c  */
#line 233 "rtfGrammar.y"
    { GSRTFcloseBlock(CTXT, NO); }
    break;

  case 36:
/* Line 1792 of yacc.c  */
#line 238 "rtfGrammar.y"
    { GSRTFaddField(CTXT, (yyvsp[(2) - (3)].text), (yyvsp[(3) - (3)].text)); free((void *)(yyvsp[(2) - (3)].text)); free((void *)(yyvsp[(3) - (3)].text)); }
    break;

  case 45:
/* Line 1792 of yacc.c  */
#line 253 "rtfGrammar.y"
    { (yyval.text) = (yyvsp[(4) - (6)].text);}
    break;

  case 46:
/* Line 1792 of yacc.c  */
#line 254 "rtfGrammar.y"
    { GSRTFopenBlock(CTXT, YES); }
    break;

  case 47:
/* Line 1792 of yacc.c  */
#line 254 "rtfGrammar.y"
    { GSRTFcloseBlock(CTXT, YES); }
    break;

  case 48:
/* Line 1792 of yacc.c  */
#line 254 "rtfGrammar.y"
    { (yyval.text) = (yyvsp[(7) - (11)].text);}
    break;

  case 49:
/* Line 1792 of yacc.c  */
#line 255 "rtfGrammar.y"
    { (yyval.text) = NULL;}
    break;

  case 52:
/* Line 1792 of yacc.c  */
#line 262 "rtfGrammar.y"
    { (yyval.text) = (yyvsp[(4) - (5)].text);}
    break;

  case 53:
/* Line 1792 of yacc.c  */
#line 263 "rtfGrammar.y"
    { (yyval.text) = (yyvsp[(6) - (8)].text);}
    break;

  case 54:
/* Line 1792 of yacc.c  */
#line 264 "rtfGrammar.y"
    { (yyval.text) = NULL;}
    break;

  case 58:
/* Line 1792 of yacc.c  */
#line 276 "rtfGrammar.y"
    { int font;
		    
						  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      font = 0;
						  else
						      font = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFfontNumber(CTXT, font); }
    break;

  case 59:
/* Line 1792 of yacc.c  */
#line 283 "rtfGrammar.y"
    { int size;

						  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      size = 24;
						  else
						      size = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFfontSize(CTXT, size); }
    break;

  case 60:
/* Line 1792 of yacc.c  */
#line 290 "rtfGrammar.y"
    { int width; 
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      width = 12240;
						  else
						      width = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFpaperWidth(CTXT, width);}
    break;

  case 61:
/* Line 1792 of yacc.c  */
#line 297 "rtfGrammar.y"
    { int height; 
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      height = 15840;
						  else
						      height = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFpaperHeight(CTXT, height);}
    break;

  case 62:
/* Line 1792 of yacc.c  */
#line 304 "rtfGrammar.y"
    { int margin; 
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      margin = 1800;
						  else
						      margin = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFmarginLeft(CTXT, margin);}
    break;

  case 63:
/* Line 1792 of yacc.c  */
#line 311 "rtfGrammar.y"
    { int margin; 
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      margin = 1800;
						  else
						      margin = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFmarginRight(CTXT, margin); }
    break;

  case 64:
/* Line 1792 of yacc.c  */
#line 318 "rtfGrammar.y"
    { int margin; 
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      margin = 1440;
						  else
						      margin = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFmarginTop(CTXT, margin); }
    break;

  case 65:
/* Line 1792 of yacc.c  */
#line 325 "rtfGrammar.y"
    { int margin; 
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      margin = 1440;
						  else
						      margin = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFmarginButtom(CTXT, margin); }
    break;

  case 66:
/* Line 1792 of yacc.c  */
#line 332 "rtfGrammar.y"
    { int indent; 
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      indent = 0;
						  else
						      indent = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFfirstLineIndent(CTXT, indent); }
    break;

  case 67:
/* Line 1792 of yacc.c  */
#line 339 "rtfGrammar.y"
    { int indent; 
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      indent = 0;
						  else
						      indent = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFleftIndent(CTXT, indent);}
    break;

  case 68:
/* Line 1792 of yacc.c  */
#line 346 "rtfGrammar.y"
    { int indent; 
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      indent = 0;
						  else
						      indent = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFrightIndent(CTXT, indent);}
    break;

  case 69:
/* Line 1792 of yacc.c  */
#line 353 "rtfGrammar.y"
    { int location; 
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      location = 0;
						  else
						      location = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFtabstop(CTXT, location);}
    break;

  case 70:
/* Line 1792 of yacc.c  */
#line 360 "rtfGrammar.y"
    { GSRTFalignCenter(CTXT); }
    break;

  case 71:
/* Line 1792 of yacc.c  */
#line 361 "rtfGrammar.y"
    { GSRTFalignJustified(CTXT); }
    break;

  case 72:
/* Line 1792 of yacc.c  */
#line 362 "rtfGrammar.y"
    { GSRTFalignLeft(CTXT); }
    break;

  case 73:
/* Line 1792 of yacc.c  */
#line 363 "rtfGrammar.y"
    { GSRTFalignRight(CTXT); }
    break;

  case 74:
/* Line 1792 of yacc.c  */
#line 364 "rtfGrammar.y"
    { int space; 
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      space = 0;
						  else
						      space = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFspaceAbove(CTXT, space); }
    break;

  case 75:
/* Line 1792 of yacc.c  */
#line 371 "rtfGrammar.y"
    { GSRTFlineSpace(CTXT, (yyvsp[(1) - (1)].cmd).parameter); }
    break;

  case 76:
/* Line 1792 of yacc.c  */
#line 372 "rtfGrammar.y"
    { GSRTFdefaultParagraph(CTXT); }
    break;

  case 77:
/* Line 1792 of yacc.c  */
#line 373 "rtfGrammar.y"
    { GSRTFstyle(CTXT, (yyvsp[(1) - (1)].cmd).parameter); }
    break;

  case 78:
/* Line 1792 of yacc.c  */
#line 374 "rtfGrammar.y"
    { int color; 
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      color = 0;
						  else
						      color = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFcolorbg(CTXT, color); }
    break;

  case 79:
/* Line 1792 of yacc.c  */
#line 381 "rtfGrammar.y"
    { int color; 
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      color = 0;
						  else
						      color = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFcolorfg(CTXT, color); }
    break;

  case 80:
/* Line 1792 of yacc.c  */
#line 388 "rtfGrammar.y"
    { int color; 
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      color = 0;
						  else
						      color = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFunderlinecolor(CTXT, color); }
    break;

  case 81:
/* Line 1792 of yacc.c  */
#line 395 "rtfGrammar.y"
    { int script;
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      script = 6;
						  else
						      script = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFsubscript(CTXT, script); }
    break;

  case 82:
/* Line 1792 of yacc.c  */
#line 402 "rtfGrammar.y"
    { int script;
		
		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty)
						      script = 6;
						  else
						      script = (yyvsp[(1) - (1)].cmd).parameter;
						  GSRTFsuperscript(CTXT, script); }
    break;

  case 83:
/* Line 1792 of yacc.c  */
#line 409 "rtfGrammar.y"
    { BOOL on;

		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty || (yyvsp[(1) - (1)].cmd).parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFbold(CTXT, on); }
    break;

  case 84:
/* Line 1792 of yacc.c  */
#line 416 "rtfGrammar.y"
    { BOOL on;

		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty || (yyvsp[(1) - (1)].cmd).parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFitalic(CTXT, on); }
    break;

  case 85:
/* Line 1792 of yacc.c  */
#line 423 "rtfGrammar.y"
    { BOOL on;

		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty || (yyvsp[(1) - (1)].cmd).parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFunderline(CTXT, on, NSUnderlineStyleSingle | NSUnderlinePatternSolid); }
    break;

  case 86:
/* Line 1792 of yacc.c  */
#line 430 "rtfGrammar.y"
    { BOOL on;

		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty || (yyvsp[(1) - (1)].cmd).parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFunderline(CTXT, on, NSUnderlineStyleSingle | NSUnderlinePatternDot); }
    break;

  case 87:
/* Line 1792 of yacc.c  */
#line 437 "rtfGrammar.y"
    { BOOL on;

		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty || (yyvsp[(1) - (1)].cmd).parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFunderline(CTXT, on, NSUnderlineStyleSingle | NSUnderlinePatternDash); }
    break;

  case 88:
/* Line 1792 of yacc.c  */
#line 444 "rtfGrammar.y"
    { BOOL on;

		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty || (yyvsp[(1) - (1)].cmd).parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFunderline(CTXT, on, NSUnderlineStyleSingle | NSUnderlinePatternDashDot); }
    break;

  case 89:
/* Line 1792 of yacc.c  */
#line 451 "rtfGrammar.y"
    { BOOL on;

		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty || (yyvsp[(1) - (1)].cmd).parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFunderline(CTXT, on, NSUnderlineStyleSingle | NSUnderlinePatternDashDotDot); }
    break;

  case 90:
/* Line 1792 of yacc.c  */
#line 458 "rtfGrammar.y"
    { BOOL on;

		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty || (yyvsp[(1) - (1)].cmd).parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFunderline(CTXT, on, NSUnderlineStyleDouble | NSUnderlinePatternSolid); }
    break;

  case 91:
/* Line 1792 of yacc.c  */
#line 465 "rtfGrammar.y"
    { GSRTFunderline(CTXT, NO, NSUnderlineStyleNone); }
    break;

  case 92:
/* Line 1792 of yacc.c  */
#line 466 "rtfGrammar.y"
    { BOOL on;

		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty || (yyvsp[(1) - (1)].cmd).parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFunderline(CTXT, on, NSUnderlineStyleThick | NSUnderlinePatternSolid); }
    break;

  case 93:
/* Line 1792 of yacc.c  */
#line 473 "rtfGrammar.y"
    { BOOL on;

		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty || (yyvsp[(1) - (1)].cmd).parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFunderline(CTXT, on, NSUnderlineStyleThick | NSUnderlinePatternDot); }
    break;

  case 94:
/* Line 1792 of yacc.c  */
#line 480 "rtfGrammar.y"
    { BOOL on;

		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty || (yyvsp[(1) - (1)].cmd).parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFunderline(CTXT, on, NSUnderlineStyleThick | NSUnderlinePatternDash); }
    break;

  case 95:
/* Line 1792 of yacc.c  */
#line 487 "rtfGrammar.y"
    { BOOL on;

		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty || (yyvsp[(1) - (1)].cmd).parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFunderline(CTXT, on, NSUnderlineStyleThick | NSUnderlinePatternDashDot); }
    break;

  case 96:
/* Line 1792 of yacc.c  */
#line 494 "rtfGrammar.y"
    { BOOL on;

		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty || (yyvsp[(1) - (1)].cmd).parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFunderline(CTXT, on, NSUnderlineStyleThick | NSUnderlinePatternDashDotDot); }
    break;

  case 97:
/* Line 1792 of yacc.c  */
#line 501 "rtfGrammar.y"
    { BOOL on;

		                                  if ((yyvsp[(1) - (1)].cmd).isEmpty || (yyvsp[(1) - (1)].cmd).parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFunderline(CTXT, on, NSUnderlineStyleSingle | NSUnderlinePatternSolid | NSUnderlineByWordMask); }
    break;

  case 98:
/* Line 1792 of yacc.c  */
#line 508 "rtfGrammar.y"
    {   NSInteger style;
   if ((yyvsp[(1) - (1)].cmd).isEmpty || (yyvsp[(1) - (1)].cmd).parameter)
     style = NSUnderlineStyleSingle | NSUnderlinePatternSolid;
   else
     style = NSUnderlineStyleNone;
   GSRTFstrikethrough(CTXT, style); }
    break;

  case 99:
/* Line 1792 of yacc.c  */
#line 514 "rtfGrammar.y"
    { GSRTFstrikethrough(CTXT, NSUnderlineStyleDouble | NSUnderlinePatternSolid); }
    break;

  case 100:
/* Line 1792 of yacc.c  */
#line 515 "rtfGrammar.y"
    { GSRTFunicode(CTXT, (yyvsp[(1) - (1)].cmd).parameter); }
    break;

  case 101:
/* Line 1792 of yacc.c  */
#line 516 "rtfGrammar.y"
    { GSRTFdefaultCharacterStyle(CTXT); }
    break;

  case 102:
/* Line 1792 of yacc.c  */
#line 517 "rtfGrammar.y"
    { GSRTFparagraph(CTXT); }
    break;

  case 103:
/* Line 1792 of yacc.c  */
#line 518 "rtfGrammar.y"
    { GSRTFparagraph(CTXT); }
    break;

  case 104:
/* Line 1792 of yacc.c  */
#line 519 "rtfGrammar.y"
    { GSRTFgenericRTFcommand(CTXT, (yyvsp[(1) - (1)].cmd)); 
		                                  free((void*)(yyvsp[(1) - (1)].cmd).name); }
    break;

  case 109:
/* Line 1792 of yacc.c  */
#line 538 "rtfGrammar.y"
    { GSRTFopenBlock(CTXT, YES); }
    break;

  case 110:
/* Line 1792 of yacc.c  */
#line 538 "rtfGrammar.y"
    { GSRTFcloseBlock(CTXT, YES); }
    break;

  case 111:
/* Line 1792 of yacc.c  */
#line 539 "rtfGrammar.y"
    {
			GSRTFNeXTGraphic (CTXT, (yyvsp[(3) - (9)].text), (yyvsp[(4) - (9)].cmd).parameter, (yyvsp[(5) - (9)].cmd).parameter);
		}
    break;

  case 112:
/* Line 1792 of yacc.c  */
#line 553 "rtfGrammar.y"
    { GSRTFopenBlock(CTXT, YES); }
    break;

  case 113:
/* Line 1792 of yacc.c  */
#line 553 "rtfGrammar.y"
    { GSRTFcloseBlock(CTXT, YES); }
    break;

  case 114:
/* Line 1792 of yacc.c  */
#line 554 "rtfGrammar.y"
    {
			GSRTFNeXTHelpLink (CTXT, (yyvsp[(2) - (12)].cmd).parameter, (yyvsp[(4) - (12)].text), (yyvsp[(6) - (12)].text), (yyvsp[(8) - (12)].text));
		}
    break;

  case 115:
/* Line 1792 of yacc.c  */
#line 567 "rtfGrammar.y"
    { GSRTFopenBlock(CTXT, YES); }
    break;

  case 116:
/* Line 1792 of yacc.c  */
#line 567 "rtfGrammar.y"
    { GSRTFcloseBlock(CTXT, YES); }
    break;

  case 117:
/* Line 1792 of yacc.c  */
#line 568 "rtfGrammar.y"
    {
			GSRTFNeXTHelpMarker (CTXT, (yyvsp[(2) - (8)].cmd).parameter, (yyvsp[(4) - (8)].text));
		}
    break;

  case 122:
/* Line 1792 of yacc.c  */
#line 583 "rtfGrammar.y"
    { free((void *)(yyvsp[(5) - (6)].text));}
    break;

  case 123:
/* Line 1792 of yacc.c  */
#line 588 "rtfGrammar.y"
    { GSRTFregisterFont(CTXT, (yyvsp[(4) - (4)].text), (yyvsp[(2) - (4)].number), (yyvsp[(1) - (4)].cmd).parameter);
                                                          free((void *)(yyvsp[(4) - (4)].text)); }
    break;

  case 130:
/* Line 1792 of yacc.c  */
#line 602 "rtfGrammar.y"
    { (yyval.number) = RTFfamilyNil - RTFfamilyNil; }
    break;

  case 131:
/* Line 1792 of yacc.c  */
#line 603 "rtfGrammar.y"
    { (yyval.number) = RTFfamilyRoman - RTFfamilyNil; }
    break;

  case 132:
/* Line 1792 of yacc.c  */
#line 604 "rtfGrammar.y"
    { (yyval.number) = RTFfamilySwiss - RTFfamilyNil; }
    break;

  case 133:
/* Line 1792 of yacc.c  */
#line 605 "rtfGrammar.y"
    { (yyval.number) = RTFfamilyModern - RTFfamilyNil; }
    break;

  case 134:
/* Line 1792 of yacc.c  */
#line 606 "rtfGrammar.y"
    { (yyval.number) = RTFfamilyScript - RTFfamilyNil; }
    break;

  case 135:
/* Line 1792 of yacc.c  */
#line 607 "rtfGrammar.y"
    { (yyval.number) = RTFfamilyDecor - RTFfamilyNil; }
    break;

  case 136:
/* Line 1792 of yacc.c  */
#line 608 "rtfGrammar.y"
    { (yyval.number) = RTFfamilyTech - RTFfamilyNil; }
    break;

  case 140:
/* Line 1792 of yacc.c  */
#line 625 "rtfGrammar.y"
    { 
		       GSRTFaddColor(CTXT, (yyvsp[(1) - (4)].cmd).parameter, (yyvsp[(2) - (4)].cmd).parameter, (yyvsp[(3) - (4)].cmd).parameter);
		       free((void *)(yyvsp[(4) - (4)].text));
		     }
    break;

  case 141:
/* Line 1792 of yacc.c  */
#line 630 "rtfGrammar.y"
    { 
		       GSRTFaddDefaultColor(CTXT);
		       free((void *)(yyvsp[(1) - (1)].text));
		     }
    break;


/* Line 1792 of yacc.c  */
#line 2883 "rtfGrammar.tab.m"
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
#line 642 "rtfGrammar.y"


/*	some C code here	*/

