/* A Bison parser, made by GNU Bison 3.5.  */

/* Bison implementation for Yacc-like parsers in C

   Copyright (C) 1984, 1989-1990, 2000-2015, 2018-2019 Free Software Foundation,
   Inc.

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

/* Undocumented macros, especially those whose name start with YY_,
   are private implementation details.  Do not rely on them.  */

/* Identify Bison output.  */
#define YYBISON 1

/* Bison version.  */
#define YYBISON_VERSION "3.5"

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
#define yydebug         GSRTFdebug
#define yynerrs         GSRTFnerrs

/* First part of user prologue.  */
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
/*#undef YYLSP_NEEDED*/
#define CTXT            ctxt

#define	YYERROR_VERBOSE
#define YYDEBUG 1

#include "RTFConsumerFunctions.h"
/*int GSRTFlex (YYSTYPE *lvalp, RTFscannerCtxt *lctxt); */
int GSRTFlex(void *lvalp, void *lctxt);

/* */
int fieldStart = 0;


#line 117 "rtfGrammar.tab.m"

# ifndef YY_CAST
#  ifdef __cplusplus
#   define YY_CAST(Type, Val) static_cast<Type> (Val)
#   define YY_REINTERPRET_CAST(Type, Val) reinterpret_cast<Type> (Val)
#  else
#   define YY_CAST(Type, Val) ((Type) (Val))
#   define YY_REINTERPRET_CAST(Type, Val) ((Type) (Val))
#  endif
# endif
# ifndef YY_NULLPTR
#  if defined __cplusplus
#   if 201103L <= __cplusplus
#    define YY_NULLPTR nullptr
#   else
#    define YY_NULLPTR 0
#   endif
#  else
#   define YY_NULLPTR ((void*)0)
#  endif
# endif

/* Enabling verbose error messages.  */
#ifdef YYERROR_VERBOSE
# undef YYERROR_VERBOSE
# define YYERROR_VERBOSE 1
#else
# define YYERROR_VERBOSE 0
#endif

/* Use api.header.include to #include this header
   instead of duplicating it here.  */
#ifndef YY_GSRTF_RTFGRAMMAR_TAB_H_INCLUDED
# define YY_GSRTF_RTFGRAMMAR_TAB_H_INCLUDED
/* Debug traces.  */
#ifndef YYDEBUG
# define YYDEBUG 0
#endif
#if YYDEBUG
extern int GSRTFdebug;
#endif

/* Token type.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
  enum yytokentype
  {
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
    RTFansicpg = 353,
    RTFOtherStatement = 354,
    RTFfontListStart = 355,
    RTFfamilyNil = 356,
    RTFfamilyRoman = 357,
    RTFfamilySwiss = 358,
    RTFfamilyModern = 359,
    RTFfamilyScript = 360,
    RTFfamilyDecor = 361,
    RTFfamilyTech = 362,
    RTFfamilyBiDi = 363
  };
#endif

/* Value type.  */
#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
union YYSTYPE
{
#line 82 "rtfGrammar.y"

	int		number;
	const char	*text;
	RTFcmd		cmd;

#line 284 "rtfGrammar.tab.m"

};
typedef union YYSTYPE YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define YYSTYPE_IS_DECLARED 1
#endif



int GSRTFparse (void *ctxt, void *lctxt);

#endif /* !YY_GSRTF_RTFGRAMMAR_TAB_H_INCLUDED  */



#ifdef short
# undef short
#endif

/* On compilers that do not define __PTRDIFF_MAX__ etc., make sure
   <limits.h> and (if available) <stdint.h> are included
   so that the code can choose integer types of a good width.  */

#ifndef __PTRDIFF_MAX__
# include <limits.h> /* INFRINGES ON USER NAME SPACE */
# if defined __STDC_VERSION__ && 199901 <= __STDC_VERSION__
#  include <stdint.h> /* INFRINGES ON USER NAME SPACE */
#  define YY_STDINT_H
# endif
#endif

/* Narrow types that promote to a signed type and that can represent a
   signed or unsigned integer of at least N bits.  In tables they can
   save space and decrease cache pressure.  Promoting to a signed type
   helps avoid bugs in integer arithmetic.  */

#ifdef __INT_LEAST8_MAX__
typedef __INT_LEAST8_TYPE__ yytype_int8;
#elif defined YY_STDINT_H
typedef int_least8_t yytype_int8;
#else
typedef signed char yytype_int8;
#endif

#ifdef __INT_LEAST16_MAX__
typedef __INT_LEAST16_TYPE__ yytype_int16;
#elif defined YY_STDINT_H
typedef int_least16_t yytype_int16;
#else
typedef short yytype_int16;
#endif

#if defined __UINT_LEAST8_MAX__ && __UINT_LEAST8_MAX__ <= __INT_MAX__
typedef __UINT_LEAST8_TYPE__ yytype_uint8;
#elif (!defined __UINT_LEAST8_MAX__ && defined YY_STDINT_H \
       && UINT_LEAST8_MAX <= INT_MAX)
typedef uint_least8_t yytype_uint8;
#elif !defined __UINT_LEAST8_MAX__ && UCHAR_MAX <= INT_MAX
typedef unsigned char yytype_uint8;
#else
typedef short yytype_uint8;
#endif

#if defined __UINT_LEAST16_MAX__ && __UINT_LEAST16_MAX__ <= __INT_MAX__
typedef __UINT_LEAST16_TYPE__ yytype_uint16;
#elif (!defined __UINT_LEAST16_MAX__ && defined YY_STDINT_H \
       && UINT_LEAST16_MAX <= INT_MAX)
typedef uint_least16_t yytype_uint16;
#elif !defined __UINT_LEAST16_MAX__ && USHRT_MAX <= INT_MAX
typedef unsigned short yytype_uint16;
#else
typedef int yytype_uint16;
#endif

#ifndef YYPTRDIFF_T
# if defined __PTRDIFF_TYPE__ && defined __PTRDIFF_MAX__
#  define YYPTRDIFF_T __PTRDIFF_TYPE__
#  define YYPTRDIFF_MAXIMUM __PTRDIFF_MAX__
# elif defined PTRDIFF_MAX
#  ifndef ptrdiff_t
#   include <stddef.h> /* INFRINGES ON USER NAME SPACE */
#  endif
#  define YYPTRDIFF_T ptrdiff_t
#  define YYPTRDIFF_MAXIMUM PTRDIFF_MAX
# else
#  define YYPTRDIFF_T long
#  define YYPTRDIFF_MAXIMUM LONG_MAX
# endif
#endif

#ifndef YYSIZE_T
# ifdef __SIZE_TYPE__
#  define YYSIZE_T __SIZE_TYPE__
# elif defined size_t
#  define YYSIZE_T size_t
# elif defined __STDC_VERSION__ && 199901 <= __STDC_VERSION__
#  include <stddef.h> /* INFRINGES ON USER NAME SPACE */
#  define YYSIZE_T size_t
# else
#  define YYSIZE_T unsigned
# endif
#endif

#define YYSIZE_MAXIMUM                                  \
  YY_CAST (YYPTRDIFF_T,                                 \
           (YYPTRDIFF_MAXIMUM < YY_CAST (YYSIZE_T, -1)  \
            ? YYPTRDIFF_MAXIMUM                         \
            : YY_CAST (YYSIZE_T, -1)))

#define YYSIZEOF(X) YY_CAST (YYPTRDIFF_T, sizeof (X))

/* Stored state numbers (used for stacks). */
typedef yytype_uint8 yy_state_t;

/* State numbers in computations.  */
typedef int yy_state_fast_t;

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

#ifndef YY_ATTRIBUTE_PURE
# if defined __GNUC__ && 2 < __GNUC__ + (96 <= __GNUC_MINOR__)
#  define YY_ATTRIBUTE_PURE __attribute__ ((__pure__))
# else
#  define YY_ATTRIBUTE_PURE
# endif
#endif

#ifndef YY_ATTRIBUTE_UNUSED
# if defined __GNUC__ && 2 < __GNUC__ + (7 <= __GNUC_MINOR__)
#  define YY_ATTRIBUTE_UNUSED __attribute__ ((__unused__))
# else
#  define YY_ATTRIBUTE_UNUSED
# endif
#endif

/* Suppress unused-variable warnings by "using" E.  */
#if ! defined lint || defined __GNUC__
# define YYUSE(E) ((void) (E))
#else
# define YYUSE(E) /* empty */
#endif

#if defined __GNUC__ && ! defined __ICC && 407 <= __GNUC__ * 100 + __GNUC_MINOR__
/* Suppress an incorrect diagnostic about yylval being uninitialized.  */
# define YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN                            \
    _Pragma ("GCC diagnostic push")                                     \
    _Pragma ("GCC diagnostic ignored \"-Wuninitialized\"")              \
    _Pragma ("GCC diagnostic ignored \"-Wmaybe-uninitialized\"")
# define YY_IGNORE_MAYBE_UNINITIALIZED_END      \
    _Pragma ("GCC diagnostic pop")
#else
# define YY_INITIAL_VALUE(Value) Value
#endif
#ifndef YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
# define YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
# define YY_IGNORE_MAYBE_UNINITIALIZED_END
#endif
#ifndef YY_INITIAL_VALUE
# define YY_INITIAL_VALUE(Value) /* Nothing. */
#endif

#if defined __cplusplus && defined __GNUC__ && ! defined __ICC && 6 <= __GNUC__
# define YY_IGNORE_USELESS_CAST_BEGIN                          \
    _Pragma ("GCC diagnostic push")                            \
    _Pragma ("GCC diagnostic ignored \"-Wuseless-cast\"")
# define YY_IGNORE_USELESS_CAST_END            \
    _Pragma ("GCC diagnostic pop")
#endif
#ifndef YY_IGNORE_USELESS_CAST_BEGIN
# define YY_IGNORE_USELESS_CAST_BEGIN
# define YY_IGNORE_USELESS_CAST_END
#endif


#define YY_ASSERT(E) ((void) (0 && (E)))

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
#    if ! defined _ALLOCA_H && ! defined EXIT_SUCCESS
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
   /* Pacify GCC's 'empty if-body' warning.  */
#  define YYSTACK_FREE(Ptr) do { /* empty */; } while (0)
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
#   if ! defined malloc && ! defined EXIT_SUCCESS
void *malloc (YYSIZE_T); /* INFRINGES ON USER NAME SPACE */
#   endif
#  endif
#  ifndef YYFREE
#   define YYFREE free
#   if ! defined free && ! defined EXIT_SUCCESS
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
  yy_state_t yyss_alloc;
  YYSTYPE yyvs_alloc;
};

/* The size of the maximum gap between one aligned stack and the next.  */
# define YYSTACK_GAP_MAXIMUM (YYSIZEOF (union yyalloc) - 1)

/* The size of an array large to enough to hold all stacks, each with
   N elements.  */
# define YYSTACK_BYTES(N) \
     ((N) * (YYSIZEOF (yy_state_t) + YYSIZEOF (YYSTYPE)) \
      + YYSTACK_GAP_MAXIMUM)

# define YYCOPY_NEEDED 1

/* Relocate STACK from its old location to the new one.  The
   local variables YYSIZE and YYSTACKSIZE give the old and new number of
   elements in the stack, and YYPTR gives the new location of the
   stack.  Advance YYPTR to a properly aligned location for the next
   stack.  */
# define YYSTACK_RELOCATE(Stack_alloc, Stack)                           \
    do                                                                  \
      {                                                                 \
        YYPTRDIFF_T yynewbytes;                                         \
        YYCOPY (&yyptr->Stack_alloc, Stack, yysize);                    \
        Stack = &yyptr->Stack_alloc;                                    \
        yynewbytes = yystacksize * YYSIZEOF (*Stack) + YYSTACK_GAP_MAXIMUM; \
        yyptr += yynewbytes / YYSIZEOF (*yyptr);                        \
      }                                                                 \
    while (0)

#endif

#if defined YYCOPY_NEEDED && YYCOPY_NEEDED
/* Copy COUNT objects from SRC to DST.  The source and destination do
   not overlap.  */
# ifndef YYCOPY
#  if defined __GNUC__ && 1 < __GNUC__
#   define YYCOPY(Dst, Src, Count) \
      __builtin_memcpy (Dst, Src, YY_CAST (YYSIZE_T, (Count)) * sizeof (*(Src)))
#  else
#   define YYCOPY(Dst, Src, Count)              \
      do                                        \
        {                                       \
          YYPTRDIFF_T yyi;                      \
          for (yyi = 0; yyi < (Count); yyi++)   \
            (Dst)[yyi] = (Src)[yyi];            \
        }                                       \
      while (0)
#  endif
# endif
#endif /* !YYCOPY_NEEDED */

/* YYFINAL -- State number of the termination state.  */
#define YYFINAL  4
/* YYLAST -- Last index in YYTABLE.  */
#define YYLAST   1750

/* YYNTOKENS -- Number of terminals.  */
#define YYNTOKENS  111
/* YYNNTS -- Number of nonterminals.  */
#define YYNNTS  45
/* YYNRULES -- Number of rules.  */
#define YYNRULES  144
/* YYNSTATES -- Number of states.  */
#define YYNSTATES  219

#define YYUNDEFTOK  2
#define YYMAXUTOK   363


/* YYTRANSLATE(TOKEN-NUM) -- Symbol number corresponding to TOKEN-NUM
   as returned by yylex, with out-of-bounds checking.  */
#define YYTRANSLATE(YYX)                                                \
  (0 <= (YYX) && (YYX) <= YYMAXUTOK ? yytranslate[YYX] : YYUNDEFTOK)

/* YYTRANSLATE[TOKEN-NUM] -- Symbol number corresponding to TOKEN-NUM
   as returned by yylex.  */
static const yytype_int8 yytranslate[] =
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
       2,     2,     2,   109,     2,   110,     2,     2,     2,     2,
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
     105,   106,   107,   108
};

#if YYDEBUG
  /* YYRLINE[YYN] -- Source line where rule number YYN was defined.  */
static const yytype_int16 yyrline[] =
{
       0,   207,   207,   207,   207,   210,   211,   212,   213,   214,
     217,   218,   219,   220,   221,   222,   223,   224,   227,   227,
     228,   228,   229,   229,   230,   230,   231,   231,   232,   232,
     233,   233,   234,   234,   235,   235,   236,   240,   240,   241,
     244,   245,   246,   247,   248,   251,   252,   255,   256,   256,
     256,   257,   260,   261,   264,   265,   268,   269,   270,   277,
     284,   291,   298,   305,   312,   319,   326,   333,   340,   347,
     354,   361,   362,   363,   364,   365,   372,   373,   374,   375,
     382,   389,   396,   403,   410,   417,   424,   431,   438,   445,
     452,   459,   466,   467,   474,   481,   488,   495,   502,   509,
     515,   516,   517,   518,   519,   520,   524,   525,   526,   527,
     539,   539,   539,   554,   554,   554,   568,   568,   568,   577,
     580,   581,   582,   583,   589,   592,   595,   599,   600,   601,
     602,   603,   604,   609,   610,   611,   612,   613,   614,   615,
     623,   626,   627,   631,   636
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
  "RTFtabstop", "RTFfcharset", "RTFfprq", "RTFcpg", "RTFansicpg",
  "RTFOtherStatement", "RTFfontListStart", "RTFfamilyNil",
  "RTFfamilyRoman", "RTFfamilySwiss", "RTFfamilyModern", "RTFfamilyScript",
  "RTFfamilyDecor", "RTFfamilyTech", "RTFfamilyBiDi", "'{'", "'}'",
  "$accept", "rtfFile", "$@1", "$@2", "rtfCharset", "rtfIngredients",
  "rtfBlock", "$@3", "$@4", "$@5", "$@6", "$@7", "$@8", "$@9", "$@10",
  "$@11", "rtfField", "$@12", "rtfFieldMod", "rtfIgnore", "rtfFieldinst",
  "$@13", "$@14", "rtfFieldalt", "rtfFieldrslt", "rtfStatementList",
  "rtfStatement", "rtfNeXTstuff", "rtfNeXTGraphic", "$@15", "$@16",
  "rtfNeXTHelpLink", "$@17", "$@18", "rtfNeXTHelpMarker", "$@19", "$@20",
  "rtfFontList", "rtfFonts", "rtfFontStatement", "rtfFontAttrs",
  "rtfFontFamily", "rtfColorDef", "rtfColors", "rtfColorStatement", YY_NULLPTR
};
#endif

# ifdef YYPRINT
/* YYTOKNUM[NUM] -- (External) token number corresponding to the
   (internal) symbol number NUM (which must be that of a token).  */
static const yytype_int16 yytoknum[] =
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
     355,   356,   357,   358,   359,   360,   361,   362,   363,   123,
     125
};
# endif

#define YYPACT_NINF (-123)

#define yypact_value_is_default(Yyn) \
  ((Yyn) == YYPACT_NINF)

#define YYTABLE_NINF (-118)

#define yytable_value_is_error(Yyn) \
  0

  /* YYPACT[STATE-NUM] -- Index in YYTABLE of the portion describing
     STATE-NUM.  */
static const yytype_int16 yypact[] =
{
    -107,  -123,     6,     3,  -123,  -123,   343,  -123,  -123,  -123,
    -123,  -123,  -123,  -123,  -123,  -123,  -123,  -123,  -123,  -123,
    -123,  -123,  -123,  -123,  -123,  -123,  -123,  -123,  -123,  -123,
    -123,  -123,  -123,  -123,  -123,  -123,  -123,  -123,  -123,  -123,
    -123,  -123,  -123,  -123,  -123,  -123,  -123,  -123,  -123,  -123,
    -123,  -123,  -123,  -123,  -123,  -123,  -123,  -123,  -123,  -123,
     138,  -102,   -87,  -123,  -123,  -123,  -123,   -98,  -123,  -123,
    -123,     4,    31,    32,    30,    42,    43,    41,    33,  -123,
    -123,  -123,    22,   -38,   438,  -123,  -123,  -123,  -123,  -123,
    -123,  -123,    13,  -123,    17,  -123,  -123,    68,    12,   -46,
    -123,  -123,    21,   -47,  -123,  -123,  -123,   533,   628,   723,
     818,   913,  1008,  1103,  -123,   -35,  -123,    34,  -123,  -123,
    -123,  -123,  -123,  -123,  -123,    87,  -123,   -30,  -105,   114,
      63,    70,  -123,  -123,  -123,  -123,  -123,  -123,  -123,  -123,
    -123,    18,   123,  -123,   268,    87,   248,  -123,   125,    83,
     131,   132,  -123,  -123,  -123,  -123,   159,    27,  -123,   363,
    -123,  -123,  -123,  -123,  -123,  -123,  -123,    28,    89,   103,
      51,    52,  -123,   135,   128,  -123,  -123,   458,  -123,    54,
     163,  -123,  -123,     7,    57,   147,  -123,  -123,   121,  -123,
     150,  -123,  -123,  -123,  -123,   177,  1198,  -123,    85,  -123,
    1293,  1388,   124,  -123,  -123,  1578,  -123,  -123,  -123,   150,
    -123,  -123,  -123,   126,  1483,  -123,  -123,   129,  -123
};

  /* YYDEFACT[STATE-NUM] -- Default reduction number in state STATE-NUM.
     Performed when YYTABLE does not specify something else to do.  Zero
     means the default is an error.  */
static const yytype_uint8 yydefact[] =
{
       0,     2,     0,     0,     1,    10,     0,    17,    15,     5,
       6,     7,     8,   102,   103,    77,   104,    79,    80,    81,
      59,    60,    61,    62,    63,    64,    65,    66,    67,    68,
      69,    71,    72,    73,    74,    76,    75,    78,    84,    85,
      86,    87,    88,    89,    90,    91,    92,    93,    94,    95,
      96,    97,    98,    99,   100,   101,    82,    83,    70,   105,
       0,     0,    11,    16,    14,    12,    13,     0,   141,   120,
      10,     0,     0,     0,     0,     0,     0,     0,     0,     4,
       9,    36,     0,     0,     0,    10,    10,    10,    10,    10,
      10,    10,     0,   144,     0,   140,   142,     0,     0,     0,
     119,   121,     0,     0,   107,   108,   109,     0,     0,     0,
       0,     0,     0,     0,    39,     0,    40,     0,   133,   134,
     135,   136,   137,   138,   139,     0,   127,     0,     0,     0,
       0,     0,    19,    21,    23,    25,    27,    29,    31,    33,
      35,     0,     0,   127,     0,     0,     0,   122,     0,     0,
       0,     0,    41,    42,    43,    44,     0,     0,   143,     0,
     124,   131,   128,   129,   130,   132,   127,     0,     0,     0,
       0,     0,    46,     0,     0,    38,   125,     0,   123,     0,
       0,   116,    51,     0,     0,     0,   126,   110,     0,    10,
      52,    48,    55,    10,    10,     0,     0,    53,     0,    56,
       0,     0,     0,   118,    47,     0,    54,   112,   113,    52,
      58,    57,    10,     0,     0,    49,   115,     0,    50
};

  /* YYPGOTO[NTERM-NUM].  */
static const yytype_int16 yypgoto[] =
{
    -123,  -123,  -123,  -123,  -123,   -70,  1545,  -123,  -123,  -123,
    -123,  -123,  -123,  -123,  -123,  -123,  -123,  -123,  -123,    59,
    -123,  -123,  -123,    26,  -123,  -123,    35,  -123,  -123,  -123,
    -123,  -123,  -123,  -123,  -123,  -123,  -123,  -123,  -123,   142,
     -89,  -122,  -123,  -123,  -123
};

  /* YYDEFGOTO[NTERM-NUM].  */
static const yytype_int16 yydefgoto[] =
{
      -1,     2,     3,    61,    62,     6,    63,    70,    71,    72,
      73,    74,    75,    76,    77,    78,   115,   116,   141,   173,
     157,   199,   217,   198,   175,   205,    64,   103,   104,   194,
     207,   105,   212,   216,   106,   189,   203,    65,    83,   101,
     144,   126,    66,    82,    96
};

  /* YYTABLE[YYPACT[STATE-NUM]] -- What to do in state STATE-NUM.  If
     positive, shift that token.  If negative, reduce the rule whose
     number is the opposite.  If YYTABLE_NINF, syntax error.  */
static const yytype_int16 yytable[] =
{
      84,    97,     1,   143,   146,   147,     4,     5,    79,    97,
     190,    80,    81,    85,   114,   107,   108,   109,   110,   111,
     112,   113,    67,   166,   -18,    93,   -18,   -18,   -18,   -18,
     -20,   -22,   -24,   -26,   -28,   -30,   -32,   -18,   -18,   -18,
     -18,    86,    88,    87,   -37,   -37,   -37,   -37,   -34,   152,
     153,   154,   155,    98,   159,    89,    91,    90,   117,   127,
      92,    98,    94,   132,   -18,   -18,   -18,    68,   -18,   -18,
     129,    99,   100,   130,   131,   140,   142,   177,   145,   -18,
     -18,   -18,   -18,   -18,   -18,   -18,   -18,   -18,   -18,   -18,
     -18,   -18,   -18,   -18,   -18,   -18,   -18,   -18,   -18,   -18,
     -18,   -18,   -18,   -18,   -18,   -18,   -18,   -18,   -18,   -18,
     -18,   -18,   -18,   -18,   -18,   -18,   191,   149,   150,   196,
     -18,    69,   -37,   200,   201,   151,   158,   156,   167,   184,
     -18,   -18,    95,   168,   169,   170,   174,   172,   178,    67,
     179,   -18,   214,   -18,   -18,   -18,   -18,   -20,   -22,   -24,
     -26,   -28,   -30,   -32,   -18,   -18,   -18,   -18,   -45,   180,
     171,   181,   182,   183,   187,   -34,   188,   192,   172,   118,
     119,   120,   121,   122,   123,   124,   125,   193,   195,   197,
     202,   -18,   -18,   -18,    68,   -18,   -18,   -45,   118,   119,
     120,   121,   122,   123,   124,   204,   -18,   -18,   -18,   -18,
     -18,   -18,   -18,   -18,   -18,   -18,   -18,   -18,   -18,   -18,
     -18,   -18,   -18,   -18,   -18,   -18,   -18,   -18,   -18,   -18,
     -18,   -18,   -18,   -18,   -18,   -18,   -18,   -18,   -18,   -18,
     -18,   -18,   -18,   185,   208,   213,   215,   -18,    69,   218,
     211,   128,     0,     0,     0,     0,     0,   -18,   -18,    67,
       0,   -18,     0,   -18,   -18,   -18,   -18,   -20,   -22,   -24,
     -26,   -28,   -30,   -32,   -18,   -18,   -18,   -18,     0,     0,
       0,   160,     0,     0,     0,   -34,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,   -18,   -18,   -18,     0,   -18,   -18,     0,     0,     0,
       0,     0,     0,   161,     0,     0,   -18,   -18,   -18,   -18,
     -18,   -18,   -18,   -18,   -18,   -18,   -18,   -18,   -18,   -18,
     -18,   -18,   -18,   -18,   -18,   -18,   -18,   -18,   -18,   -18,
     -18,   -18,   -18,   -18,   -18,   -18,   -18,   -18,   -18,   -18,
     -18,   -18,   -18,     0,     7,     0,     8,   -18,     9,    10,
      11,    12,     0,     0,     0,     0,     0,   -18,   -18,    13,
      14,    15,    16,   162,   163,   164,   176,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,   146,     0,     0,
       0,     0,     0,     0,     0,     0,    17,    18,    19,     0,
      20,    21,     0,     0,     0,     0,     0,     0,   161,     0,
       0,    22,    23,    24,    25,    26,    27,    28,    29,    30,
      31,    32,    33,    34,    35,    36,    37,    38,    39,    40,
      41,    42,    43,    44,    45,    46,    47,    48,    49,    50,
      51,    52,    53,    54,    55,    56,    57,    58,     0,     7,
       0,     8,    59,     9,    10,    11,    12,     0,     0,     0,
       0,     0,    60,    -3,    13,    14,    15,    16,   162,   163,
     164,   186,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,   146,     0,     0,     0,     0,     0,     0,     0,
       0,    17,    18,    19,     0,    20,    21,     0,     0,     0,
       0,     0,     0,   161,     0,     0,    22,    23,    24,    25,
      26,    27,    28,    29,    30,    31,    32,    33,    34,    35,
      36,    37,    38,    39,    40,    41,    42,    43,    44,    45,
      46,    47,    48,    49,    50,    51,    52,    53,    54,    55,
      56,    57,    58,     0,     7,     0,     8,    59,     9,    10,
      11,    12,     0,     0,     0,     0,     0,   102,  -106,    13,
      14,    15,    16,   162,   163,   164,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,   146,     0,     0,
       0,     0,     0,     0,     0,     0,    17,    18,    19,     0,
      20,    21,     0,     0,     0,     0,     0,     0,     0,     0,
       0,    22,    23,    24,    25,    26,    27,    28,    29,    30,
      31,    32,    33,    34,    35,    36,    37,    38,    39,    40,
      41,    42,    43,    44,    45,    46,    47,    48,    49,    50,
      51,    52,    53,    54,    55,    56,    57,    58,     0,     7,
       0,     8,    59,     9,    10,    11,    12,     0,     0,     0,
       0,     0,    60,   133,    13,    14,    15,    16,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,    17,    18,    19,     0,    20,    21,     0,     0,     0,
       0,     0,     0,     0,     0,     0,    22,    23,    24,    25,
      26,    27,    28,    29,    30,    31,    32,    33,    34,    35,
      36,    37,    38,    39,    40,    41,    42,    43,    44,    45,
      46,    47,    48,    49,    50,    51,    52,    53,    54,    55,
      56,    57,    58,     0,     7,     0,     8,    59,     9,    10,
      11,    12,     0,     0,     0,     0,     0,    60,   134,    13,
      14,    15,    16,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,    17,    18,    19,     0,
      20,    21,     0,     0,     0,     0,     0,     0,     0,     0,
       0,    22,    23,    24,    25,    26,    27,    28,    29,    30,
      31,    32,    33,    34,    35,    36,    37,    38,    39,    40,
      41,    42,    43,    44,    45,    46,    47,    48,    49,    50,
      51,    52,    53,    54,    55,    56,    57,    58,     0,     7,
       0,     8,    59,     9,    10,    11,    12,     0,     0,     0,
       0,     0,    60,   135,    13,    14,    15,    16,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,    17,    18,    19,     0,    20,    21,     0,     0,     0,
       0,     0,     0,     0,     0,     0,    22,    23,    24,    25,
      26,    27,    28,    29,    30,    31,    32,    33,    34,    35,
      36,    37,    38,    39,    40,    41,    42,    43,    44,    45,
      46,    47,    48,    49,    50,    51,    52,    53,    54,    55,
      56,    57,    58,     0,     7,     0,     8,    59,     9,    10,
      11,    12,     0,     0,     0,     0,     0,    60,   136,    13,
      14,    15,    16,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,    17,    18,    19,     0,
      20,    21,     0,     0,     0,     0,     0,     0,     0,     0,
       0,    22,    23,    24,    25,    26,    27,    28,    29,    30,
      31,    32,    33,    34,    35,    36,    37,    38,    39,    40,
      41,    42,    43,    44,    45,    46,    47,    48,    49,    50,
      51,    52,    53,    54,    55,    56,    57,    58,     0,     7,
       0,     8,    59,     9,    10,    11,    12,     0,     0,     0,
       0,     0,    60,   137,    13,    14,    15,    16,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,    17,    18,    19,     0,    20,    21,     0,     0,     0,
       0,     0,     0,     0,     0,     0,    22,    23,    24,    25,
      26,    27,    28,    29,    30,    31,    32,    33,    34,    35,
      36,    37,    38,    39,    40,    41,    42,    43,    44,    45,
      46,    47,    48,    49,    50,    51,    52,    53,    54,    55,
      56,    57,    58,     0,     7,     0,     8,    59,     9,    10,
      11,    12,     0,     0,     0,     0,     0,    60,   138,    13,
      14,    15,    16,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,    17,    18,    19,     0,
      20,    21,     0,     0,     0,     0,     0,     0,     0,     0,
       0,    22,    23,    24,    25,    26,    27,    28,    29,    30,
      31,    32,    33,    34,    35,    36,    37,    38,    39,    40,
      41,    42,    43,    44,    45,    46,    47,    48,    49,    50,
      51,    52,    53,    54,    55,    56,    57,    58,     0,     7,
       0,     8,    59,     9,    10,    11,    12,     0,     0,     0,
       0,     0,    60,   139,    13,    14,    15,    16,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,    17,    18,    19,     0,    20,    21,     0,     0,     0,
       0,     0,     0,     0,     0,     0,    22,    23,    24,    25,
      26,    27,    28,    29,    30,    31,    32,    33,    34,    35,
      36,    37,    38,    39,    40,    41,    42,    43,    44,    45,
      46,    47,    48,    49,    50,    51,    52,    53,    54,    55,
      56,    57,    58,     0,     7,     0,     8,    59,     9,    10,
      11,    12,     0,     0,     0,     0,     0,    60,  -117,    13,
      14,    15,    16,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,    17,    18,    19,     0,
      20,    21,     0,     0,     0,     0,     0,     0,     0,     0,
       0,    22,    23,    24,    25,    26,    27,    28,    29,    30,
      31,    32,    33,    34,    35,    36,    37,    38,    39,    40,
      41,    42,    43,    44,    45,    46,    47,    48,    49,    50,
      51,    52,    53,    54,    55,    56,    57,    58,     0,     7,
       0,     8,    59,     9,    10,    11,    12,     0,     0,     0,
       0,     0,    60,   206,    13,    14,    15,    16,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,    17,    18,    19,     0,    20,    21,     0,     0,     0,
       0,     0,     0,     0,     0,     0,    22,    23,    24,    25,
      26,    27,    28,    29,    30,    31,    32,    33,    34,    35,
      36,    37,    38,    39,    40,    41,    42,    43,    44,    45,
      46,    47,    48,    49,    50,    51,    52,    53,    54,    55,
      56,    57,    58,     0,     7,     0,     8,    59,     9,    10,
      11,    12,     0,     0,     0,     0,     0,    60,  -111,    13,
      14,    15,    16,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,    17,    18,    19,     0,
      20,    21,     0,     0,     0,     0,     0,     0,     0,     0,
       0,    22,    23,    24,    25,    26,    27,    28,    29,    30,
      31,    32,    33,    34,    35,    36,    37,    38,    39,    40,
      41,    42,    43,    44,    45,    46,    47,    48,    49,    50,
      51,    52,    53,    54,    55,    56,    57,    58,     0,     0,
       0,   209,    59,     0,     0,     0,     0,     0,     0,     0,
       0,     0,    60,  -114,    13,    14,    15,    16,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,    17,    18,    19,     0,    20,    21,     0,     0,     0,
       0,     0,     0,     0,     0,     0,    22,    23,    24,    25,
      26,    27,    28,    29,    30,    31,    32,    33,    34,    35,
      36,    37,    38,    39,    40,    41,    42,    43,    44,    45,
      46,    47,    48,    49,    50,    51,    52,    53,    54,    55,
      56,    57,    58,   148,     0,     0,     0,    59,     0,     0,
       0,     0,     0,     0,     0,     0,     0,   146,     0,   165,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,   165,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,   165,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     210
};

static const yytype_int16 yycheck[] =
{
      70,    47,   109,   125,   109,   110,     0,     4,   110,    47,
       3,    98,   110,     9,     1,    85,    86,    87,    88,    89,
      90,    91,     1,   145,     3,     3,     5,     6,     7,     8,
       9,    10,    11,    12,    13,    14,    15,    16,    17,    18,
      19,    10,    12,    11,    31,    32,    33,    34,    27,    31,
      32,    33,    34,    99,   143,    13,    15,    14,    41,    47,
      27,    99,    40,   110,    43,    44,    45,    46,    47,    48,
      49,   109,   110,    52,    53,   110,    42,   166,   108,    58,
      59,    60,    61,    62,    63,    64,    65,    66,    67,    68,
      69,    70,    71,    72,    73,    74,    75,    76,    77,    78,
      79,    80,    81,    82,    83,    84,    85,    86,    87,    88,
      89,    90,    91,    92,    93,    94,   109,     3,    55,   189,
      99,   100,   109,   193,   194,    55,     3,   109,     3,     1,
     109,   110,   110,    50,     3,     3,   109,     9,   110,     1,
      51,     3,   212,     5,     6,     7,     8,     9,    10,    11,
      12,    13,    14,    15,    16,    17,    18,    19,    30,    56,
       1,   110,   110,    28,   110,    27,     3,   110,     9,   101,
     102,   103,   104,   105,   106,   107,   108,    30,    57,    29,
       3,    43,    44,    45,    46,    47,    48,    28,   101,   102,
     103,   104,   105,   106,   107,   110,    58,    59,    60,    61,
      62,    63,    64,    65,    66,    67,    68,    69,    70,    71,
      72,    73,    74,    75,    76,    77,    78,    79,    80,    81,
      82,    83,    84,    85,    86,    87,    88,    89,    90,    91,
      92,    93,    94,   174,   110,   209,   110,    99,   100,   110,
     205,    99,    -1,    -1,    -1,    -1,    -1,   109,   110,     1,
      -1,     3,    -1,     5,     6,     7,     8,     9,    10,    11,
      12,    13,    14,    15,    16,    17,    18,    19,    -1,    -1,
      -1,     3,    -1,    -1,    -1,    27,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    43,    44,    45,    -1,    47,    48,    -1,    -1,    -1,
      -1,    -1,    -1,    35,    -1,    -1,    58,    59,    60,    61,
      62,    63,    64,    65,    66,    67,    68,    69,    70,    71,
      72,    73,    74,    75,    76,    77,    78,    79,    80,    81,
      82,    83,    84,    85,    86,    87,    88,    89,    90,    91,
      92,    93,    94,    -1,     1,    -1,     3,    99,     5,     6,
       7,     8,    -1,    -1,    -1,    -1,    -1,   109,   110,    16,
      17,    18,    19,    95,    96,    97,     3,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,   109,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    43,    44,    45,    -1,
      47,    48,    -1,    -1,    -1,    -1,    -1,    -1,    35,    -1,
      -1,    58,    59,    60,    61,    62,    63,    64,    65,    66,
      67,    68,    69,    70,    71,    72,    73,    74,    75,    76,
      77,    78,    79,    80,    81,    82,    83,    84,    85,    86,
      87,    88,    89,    90,    91,    92,    93,    94,    -1,     1,
      -1,     3,    99,     5,     6,     7,     8,    -1,    -1,    -1,
      -1,    -1,   109,   110,    16,    17,    18,    19,    95,    96,
      97,     3,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,   109,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    43,    44,    45,    -1,    47,    48,    -1,    -1,    -1,
      -1,    -1,    -1,    35,    -1,    -1,    58,    59,    60,    61,
      62,    63,    64,    65,    66,    67,    68,    69,    70,    71,
      72,    73,    74,    75,    76,    77,    78,    79,    80,    81,
      82,    83,    84,    85,    86,    87,    88,    89,    90,    91,
      92,    93,    94,    -1,     1,    -1,     3,    99,     5,     6,
       7,     8,    -1,    -1,    -1,    -1,    -1,   109,   110,    16,
      17,    18,    19,    95,    96,    97,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,   109,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    43,    44,    45,    -1,
      47,    48,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    58,    59,    60,    61,    62,    63,    64,    65,    66,
      67,    68,    69,    70,    71,    72,    73,    74,    75,    76,
      77,    78,    79,    80,    81,    82,    83,    84,    85,    86,
      87,    88,    89,    90,    91,    92,    93,    94,    -1,     1,
      -1,     3,    99,     5,     6,     7,     8,    -1,    -1,    -1,
      -1,    -1,   109,   110,    16,    17,    18,    19,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    43,    44,    45,    -1,    47,    48,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    58,    59,    60,    61,
      62,    63,    64,    65,    66,    67,    68,    69,    70,    71,
      72,    73,    74,    75,    76,    77,    78,    79,    80,    81,
      82,    83,    84,    85,    86,    87,    88,    89,    90,    91,
      92,    93,    94,    -1,     1,    -1,     3,    99,     5,     6,
       7,     8,    -1,    -1,    -1,    -1,    -1,   109,   110,    16,
      17,    18,    19,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    43,    44,    45,    -1,
      47,    48,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    58,    59,    60,    61,    62,    63,    64,    65,    66,
      67,    68,    69,    70,    71,    72,    73,    74,    75,    76,
      77,    78,    79,    80,    81,    82,    83,    84,    85,    86,
      87,    88,    89,    90,    91,    92,    93,    94,    -1,     1,
      -1,     3,    99,     5,     6,     7,     8,    -1,    -1,    -1,
      -1,    -1,   109,   110,    16,    17,    18,    19,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    43,    44,    45,    -1,    47,    48,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    58,    59,    60,    61,
      62,    63,    64,    65,    66,    67,    68,    69,    70,    71,
      72,    73,    74,    75,    76,    77,    78,    79,    80,    81,
      82,    83,    84,    85,    86,    87,    88,    89,    90,    91,
      92,    93,    94,    -1,     1,    -1,     3,    99,     5,     6,
       7,     8,    -1,    -1,    -1,    -1,    -1,   109,   110,    16,
      17,    18,    19,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    43,    44,    45,    -1,
      47,    48,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    58,    59,    60,    61,    62,    63,    64,    65,    66,
      67,    68,    69,    70,    71,    72,    73,    74,    75,    76,
      77,    78,    79,    80,    81,    82,    83,    84,    85,    86,
      87,    88,    89,    90,    91,    92,    93,    94,    -1,     1,
      -1,     3,    99,     5,     6,     7,     8,    -1,    -1,    -1,
      -1,    -1,   109,   110,    16,    17,    18,    19,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    43,    44,    45,    -1,    47,    48,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    58,    59,    60,    61,
      62,    63,    64,    65,    66,    67,    68,    69,    70,    71,
      72,    73,    74,    75,    76,    77,    78,    79,    80,    81,
      82,    83,    84,    85,    86,    87,    88,    89,    90,    91,
      92,    93,    94,    -1,     1,    -1,     3,    99,     5,     6,
       7,     8,    -1,    -1,    -1,    -1,    -1,   109,   110,    16,
      17,    18,    19,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    43,    44,    45,    -1,
      47,    48,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    58,    59,    60,    61,    62,    63,    64,    65,    66,
      67,    68,    69,    70,    71,    72,    73,    74,    75,    76,
      77,    78,    79,    80,    81,    82,    83,    84,    85,    86,
      87,    88,    89,    90,    91,    92,    93,    94,    -1,     1,
      -1,     3,    99,     5,     6,     7,     8,    -1,    -1,    -1,
      -1,    -1,   109,   110,    16,    17,    18,    19,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    43,    44,    45,    -1,    47,    48,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    58,    59,    60,    61,
      62,    63,    64,    65,    66,    67,    68,    69,    70,    71,
      72,    73,    74,    75,    76,    77,    78,    79,    80,    81,
      82,    83,    84,    85,    86,    87,    88,    89,    90,    91,
      92,    93,    94,    -1,     1,    -1,     3,    99,     5,     6,
       7,     8,    -1,    -1,    -1,    -1,    -1,   109,   110,    16,
      17,    18,    19,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    43,    44,    45,    -1,
      47,    48,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    58,    59,    60,    61,    62,    63,    64,    65,    66,
      67,    68,    69,    70,    71,    72,    73,    74,    75,    76,
      77,    78,    79,    80,    81,    82,    83,    84,    85,    86,
      87,    88,    89,    90,    91,    92,    93,    94,    -1,     1,
      -1,     3,    99,     5,     6,     7,     8,    -1,    -1,    -1,
      -1,    -1,   109,   110,    16,    17,    18,    19,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    43,    44,    45,    -1,    47,    48,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    58,    59,    60,    61,
      62,    63,    64,    65,    66,    67,    68,    69,    70,    71,
      72,    73,    74,    75,    76,    77,    78,    79,    80,    81,
      82,    83,    84,    85,    86,    87,    88,    89,    90,    91,
      92,    93,    94,    -1,     1,    -1,     3,    99,     5,     6,
       7,     8,    -1,    -1,    -1,    -1,    -1,   109,   110,    16,
      17,    18,    19,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    43,    44,    45,    -1,
      47,    48,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    58,    59,    60,    61,    62,    63,    64,    65,    66,
      67,    68,    69,    70,    71,    72,    73,    74,    75,    76,
      77,    78,    79,    80,    81,    82,    83,    84,    85,    86,
      87,    88,    89,    90,    91,    92,    93,    94,    -1,    -1,
      -1,     3,    99,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,   109,   110,    16,    17,    18,    19,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    43,    44,    45,    -1,    47,    48,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    58,    59,    60,    61,
      62,    63,    64,    65,    66,    67,    68,    69,    70,    71,
      72,    73,    74,    75,    76,    77,    78,    79,    80,    81,
      82,    83,    84,    85,    86,    87,    88,    89,    90,    91,
      92,    93,    94,   128,    -1,    -1,    -1,    99,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,   109,    -1,   144,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,   159,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,   177,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
     205
};

  /* YYSTOS[STATE-NUM] -- The (internal number of the) accessing
     symbol of state STATE-NUM.  */
static const yytype_uint8 yystos[] =
{
       0,   109,   112,   113,     0,     4,   116,     1,     3,     5,
       6,     7,     8,    16,    17,    18,    19,    43,    44,    45,
      47,    48,    58,    59,    60,    61,    62,    63,    64,    65,
      66,    67,    68,    69,    70,    71,    72,    73,    74,    75,
      76,    77,    78,    79,    80,    81,    82,    83,    84,    85,
      86,    87,    88,    89,    90,    91,    92,    93,    94,    99,
     109,   114,   115,   117,   137,   148,   153,     1,    46,   100,
     118,   119,   120,   121,   122,   123,   124,   125,   126,   110,
      98,   110,   154,   149,   116,     9,    10,    11,    12,    13,
      14,    15,    27,     3,    40,   110,   155,    47,    99,   109,
     110,   150,   109,   138,   139,   142,   145,   116,   116,   116,
     116,   116,   116,   116,     1,   127,   128,    41,   101,   102,
     103,   104,   105,   106,   107,   108,   152,    47,   150,    49,
      52,    53,   110,   110,   110,   110,   110,   110,   110,   110,
     110,   129,    42,   152,   151,   108,   109,   110,   117,     3,
      55,    55,    31,    32,    33,    34,   109,   131,     3,   151,
       3,    35,    95,    96,    97,   117,   152,     3,    50,     3,
       3,     1,     9,   130,   109,   135,     3,   151,   110,    51,
      56,   110,   110,    28,     1,   130,     3,   110,     3,   146,
       3,   109,   110,    30,   140,    57,   116,    29,   134,   132,
     116,   116,     3,   147,   110,   136,   110,   141,   110,     3,
     117,   137,   143,   134,   116,   110,   144,   133,   110
};

  /* YYR1[YYN] -- Symbol number of symbol that rule YYN derives.  */
static const yytype_uint8 yyr1[] =
{
       0,   111,   113,   114,   112,   115,   115,   115,   115,   115,
     116,   116,   116,   116,   116,   116,   116,   116,   118,   117,
     119,   117,   120,   117,   121,   117,   122,   117,   123,   117,
     124,   117,   125,   117,   126,   117,   117,   128,   127,   127,
     129,   129,   129,   129,   129,   130,   130,   131,   132,   133,
     131,   131,   134,   134,   135,   135,   136,   136,   136,   137,
     137,   137,   137,   137,   137,   137,   137,   137,   137,   137,
     137,   137,   137,   137,   137,   137,   137,   137,   137,   137,
     137,   137,   137,   137,   137,   137,   137,   137,   137,   137,
     137,   137,   137,   137,   137,   137,   137,   137,   137,   137,
     137,   137,   137,   137,   137,   137,   138,   138,   138,   138,
     140,   141,   139,   143,   144,   142,   146,   147,   145,   148,
     149,   149,   149,   149,   150,   150,   150,   151,   151,   151,
     151,   151,   151,   152,   152,   152,   152,   152,   152,   152,
     153,   154,   154,   155,   155
};

  /* YYR2[YYN] -- Number of symbols on the right hand side of rule YYN.  */
static const yytype_int8 yyr2[] =
{
       0,     2,     0,     0,     6,     1,     1,     1,     1,     2,
       0,     2,     2,     2,     2,     2,     2,     2,     0,     5,
       0,     5,     0,     5,     0,     5,     0,     5,     0,     5,
       0,     5,     0,     5,     0,     5,     3,     0,     4,     1,
       0,     2,     2,     2,     2,     0,     1,     6,     0,     0,
      11,     3,     0,     1,     5,     3,     0,     2,     2,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     0,     1,     1,     1,
       0,     0,     9,     0,     0,    12,     0,     0,     8,     4,
       0,     2,     4,     6,     4,     5,     6,     0,     2,     2,
       2,     2,     2,     1,     1,     1,     1,     1,     1,     1,
       4,     0,     2,     4,     1
};


#define yyerrok         (yyerrstatus = 0)
#define yyclearin       (yychar = YYEMPTY)
#define YYEMPTY         (-2)
#define YYEOF           0

#define YYACCEPT        goto yyacceptlab
#define YYABORT         goto yyabortlab
#define YYERROR         goto yyerrorlab


#define YYRECOVERING()  (!!yyerrstatus)

#define YYBACKUP(Token, Value)                                    \
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
        YYERROR;                                                  \
      }                                                           \
  while (0)

/* Error token number */
#define YYTERROR        1
#define YYERRCODE       256



/* Enable debugging if requested.  */
#if YYDEBUG

# ifndef YYFPRINTF
#  include <stdio.h> /* INFRINGES ON USER NAME SPACE */
#  define YYFPRINTF fprintf
# endif

# define YYDPRINTF(Args)                        \
do {                                            \
  if (yydebug)                                  \
    YYFPRINTF Args;                             \
} while (0)

/* This macro is provided for backward compatibility. */
#ifndef YY_LOCATION_PRINT
# define YY_LOCATION_PRINT(File, Loc) ((void) 0)
#endif


# define YY_SYMBOL_PRINT(Title, Type, Value, Location)                    \
do {                                                                      \
  if (yydebug)                                                            \
    {                                                                     \
      YYFPRINTF (stderr, "%s ", Title);                                   \
      yy_symbol_print (stderr,                                            \
                  Type, Value, ctxt, lctxt); \
      YYFPRINTF (stderr, "\n");                                           \
    }                                                                     \
} while (0)


/*-----------------------------------.
| Print this symbol's value on YYO.  |
`-----------------------------------*/

static void
yy_symbol_value_print (FILE *yyo, int yytype, YYSTYPE const * const yyvaluep, void *ctxt, void *lctxt)
{
  FILE *yyoutput = yyo;
  YYUSE (yyoutput);
  YYUSE (ctxt);
  YYUSE (lctxt);
  if (!yyvaluep)
    return;
# ifdef YYPRINT
  if (yytype < YYNTOKENS)
    YYPRINT (yyo, yytoknum[yytype], *yyvaluep);
# endif
  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  YYUSE (yytype);
  YY_IGNORE_MAYBE_UNINITIALIZED_END
}


/*---------------------------.
| Print this symbol on YYO.  |
`---------------------------*/

static void
yy_symbol_print (FILE *yyo, int yytype, YYSTYPE const * const yyvaluep, void *ctxt, void *lctxt)
{
  YYFPRINTF (yyo, "%s %s (",
             yytype < YYNTOKENS ? "token" : "nterm", yytname[yytype]);

  yy_symbol_value_print (yyo, yytype, yyvaluep, ctxt, lctxt);
  YYFPRINTF (yyo, ")");
}

/*------------------------------------------------------------------.
| yy_stack_print -- Print the state stack from its BOTTOM up to its |
| TOP (included).                                                   |
`------------------------------------------------------------------*/

static void
yy_stack_print (yy_state_t *yybottom, yy_state_t *yytop)
{
  YYFPRINTF (stderr, "Stack now");
  for (; yybottom <= yytop; yybottom++)
    {
      int yybot = *yybottom;
      YYFPRINTF (stderr, " %d", yybot);
    }
  YYFPRINTF (stderr, "\n");
}

# define YY_STACK_PRINT(Bottom, Top)                            \
do {                                                            \
  if (yydebug)                                                  \
    yy_stack_print ((Bottom), (Top));                           \
} while (0)


/*------------------------------------------------.
| Report that the YYRULE is going to be reduced.  |
`------------------------------------------------*/

static void
yy_reduce_print (yy_state_t *yyssp, YYSTYPE *yyvsp, int yyrule, void *ctxt, void *lctxt)
{
  int yylno = yyrline[yyrule];
  int yynrhs = yyr2[yyrule];
  int yyi;
  YYFPRINTF (stderr, "Reducing stack by rule %d (line %d):\n",
             yyrule - 1, yylno);
  /* The symbols being reduced.  */
  for (yyi = 0; yyi < yynrhs; yyi++)
    {
      YYFPRINTF (stderr, "   $%d = ", yyi + 1);
      yy_symbol_print (stderr,
                       yystos[yyssp[yyi + 1 - yynrhs]],
                       &yyvsp[(yyi + 1) - (yynrhs)]
                                              , ctxt, lctxt);
      YYFPRINTF (stderr, "\n");
    }
}

# define YY_REDUCE_PRINT(Rule)          \
do {                                    \
  if (yydebug)                          \
    yy_reduce_print (yyssp, yyvsp, Rule, ctxt, lctxt); \
} while (0)

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
#ifndef YYINITDEPTH
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
#   define yystrlen(S) (YY_CAST (YYPTRDIFF_T, strlen (S)))
#  else
/* Return the length of YYSTR.  */
static YYPTRDIFF_T
yystrlen (const char *yystr)
{
  YYPTRDIFF_T yylen;
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
static char *
yystpcpy (char *yydest, const char *yysrc)
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
static YYPTRDIFF_T
yytnamerr (char *yyres, const char *yystr)
{
  if (*yystr == '"')
    {
      YYPTRDIFF_T yyn = 0;
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
            else
              goto append;

          append:
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

  if (yyres)
    return yystpcpy (yyres, yystr) - yyres;
  else
    return yystrlen (yystr);
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
yysyntax_error (YYPTRDIFF_T *yymsg_alloc, char **yymsg,
                yy_state_t *yyssp, int yytoken)
{
  enum { YYERROR_VERBOSE_ARGS_MAXIMUM = 5 };
  /* Internationalized format string. */
  const char *yyformat = YY_NULLPTR;
  /* Arguments of yyformat: reported tokens (one for the "unexpected",
     one per "expected"). */
  char const *yyarg[YYERROR_VERBOSE_ARGS_MAXIMUM];
  /* Actual size of YYARG. */
  int yycount = 0;
  /* Cumulated lengths of YYARG.  */
  YYPTRDIFF_T yysize = 0;

  /* There are many possibilities here to consider:
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
      YYPTRDIFF_T yysize0 = yytnamerr (YY_NULLPTR, yytname[yytoken]);
      yysize = yysize0;
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
                  YYPTRDIFF_T yysize1
                    = yysize + yytnamerr (YY_NULLPTR, yytname[yyx]);
                  if (yysize <= yysize1 && yysize1 <= YYSTACK_ALLOC_MAXIMUM)
                    yysize = yysize1;
                  else
                    return 2;
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
    default: /* Avoid compiler warnings. */
      YYCASE_(0, YY_("syntax error"));
      YYCASE_(1, YY_("syntax error, unexpected %s"));
      YYCASE_(2, YY_("syntax error, unexpected %s, expecting %s"));
      YYCASE_(3, YY_("syntax error, unexpected %s, expecting %s or %s"));
      YYCASE_(4, YY_("syntax error, unexpected %s, expecting %s or %s or %s"));
      YYCASE_(5, YY_("syntax error, unexpected %s, expecting %s or %s or %s or %s"));
# undef YYCASE_
    }

  {
    /* Don't count the "%s"s in the final size, but reserve room for
       the terminator.  */
    YYPTRDIFF_T yysize1 = yysize + (yystrlen (yyformat) - 2 * yycount) + 1;
    if (yysize <= yysize1 && yysize1 <= YYSTACK_ALLOC_MAXIMUM)
      yysize = yysize1;
    else
      return 2;
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
          ++yyp;
          ++yyformat;
        }
  }
  return 0;
}
#endif /* YYERROR_VERBOSE */

/*-----------------------------------------------.
| Release the memory associated to this symbol.  |
`-----------------------------------------------*/

static void
yydestruct (const char *yymsg, int yytype, YYSTYPE *yyvaluep, void *ctxt, void *lctxt)
{
  YYUSE (yyvaluep);
  YYUSE (ctxt);
  YYUSE (lctxt);
  if (!yymsg)
    yymsg = "Deleting";
  YY_SYMBOL_PRINT (yymsg, yytype, yyvaluep, yylocationp);

  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  YYUSE (yytype);
  YY_IGNORE_MAYBE_UNINITIALIZED_END
}




/*----------.
| yyparse.  |
`----------*/

int
yyparse (void *ctxt, void *lctxt)
{
/* The lookahead symbol.  */
int yychar;


/* The semantic value of the lookahead symbol.  */
/* Default value used for initialization, for pacifying older GCCs
   or non-GCC compilers.  */
YY_INITIAL_VALUE (static YYSTYPE yyval_default;)
YYSTYPE yylval YY_INITIAL_VALUE (= yyval_default);

    /* Number of syntax errors so far.  */
    int yynerrs;

    yy_state_fast_t yystate;
    /* Number of tokens to shift before error messages enabled.  */
    int yyerrstatus;

    /* The stacks and their tools:
       'yyss': related to states.
       'yyvs': related to semantic values.

       Refer to the stacks through separate pointers, to allow yyoverflow
       to reallocate them elsewhere.  */

    /* The state stack.  */
    yy_state_t yyssa[YYINITDEPTH];
    yy_state_t *yyss;
    yy_state_t *yyssp;

    /* The semantic value stack.  */
    YYSTYPE yyvsa[YYINITDEPTH];
    YYSTYPE *yyvs;
    YYSTYPE *yyvsp;

    YYPTRDIFF_T yystacksize;

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
  YYPTRDIFF_T yymsg_alloc = sizeof yymsgbuf;
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
| yynewstate -- push a new state, which is found in yystate.  |
`------------------------------------------------------------*/
yynewstate:
  /* In all cases, when you get here, the value and location stacks
     have just been pushed.  So pushing a state here evens the stacks.  */
  yyssp++;


/*--------------------------------------------------------------------.
| yysetstate -- set current state (the top of the stack) to yystate.  |
`--------------------------------------------------------------------*/
yysetstate:
  YYDPRINTF ((stderr, "Entering state %d\n", yystate));
  YY_ASSERT (0 <= yystate && yystate < YYNSTATES);
  YY_IGNORE_USELESS_CAST_BEGIN
  *yyssp = YY_CAST (yy_state_t, yystate);
  YY_IGNORE_USELESS_CAST_END

  if (yyss + yystacksize - 1 <= yyssp)
#if !defined yyoverflow && !defined YYSTACK_RELOCATE
    goto yyexhaustedlab;
#else
    {
      /* Get the current used size of the three stacks, in elements.  */
      YYPTRDIFF_T yysize = yyssp - yyss + 1;

# if defined yyoverflow
      {
        /* Give user a chance to reallocate the stack.  Use copies of
           these so that the &'s don't force the real ones into
           memory.  */
        yy_state_t *yyss1 = yyss;
        YYSTYPE *yyvs1 = yyvs;

        /* Each stack pointer address is followed by the size of the
           data in use in that stack, in bytes.  This used to be a
           conditional around just the two extra args, but that might
           be undefined if yyoverflow is a macro.  */
        yyoverflow (YY_("memory exhausted"),
                    &yyss1, yysize * YYSIZEOF (*yyssp),
                    &yyvs1, yysize * YYSIZEOF (*yyvsp),
                    &yystacksize);
        yyss = yyss1;
        yyvs = yyvs1;
      }
# else /* defined YYSTACK_RELOCATE */
      /* Extend the stack our own way.  */
      if (YYMAXDEPTH <= yystacksize)
        goto yyexhaustedlab;
      yystacksize *= 2;
      if (YYMAXDEPTH < yystacksize)
        yystacksize = YYMAXDEPTH;

      {
        yy_state_t *yyss1 = yyss;
        union yyalloc *yyptr =
          YY_CAST (union yyalloc *,
                   YYSTACK_ALLOC (YY_CAST (YYSIZE_T, YYSTACK_BYTES (yystacksize))));
        if (! yyptr)
          goto yyexhaustedlab;
        YYSTACK_RELOCATE (yyss_alloc, yyss);
        YYSTACK_RELOCATE (yyvs_alloc, yyvs);
# undef YYSTACK_RELOCATE
        if (yyss1 != yyssa)
          YYSTACK_FREE (yyss1);
      }
# endif

      yyssp = yyss + yysize - 1;
      yyvsp = yyvs + yysize - 1;

      YY_IGNORE_USELESS_CAST_BEGIN
      YYDPRINTF ((stderr, "Stack size increased to %ld\n",
                  YY_CAST (long, yystacksize)));
      YY_IGNORE_USELESS_CAST_END

      if (yyss + yystacksize - 1 <= yyssp)
        YYABORT;
    }
#endif /* !defined yyoverflow && !defined YYSTACK_RELOCATE */

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
      yychar = yylex (&yylval, lctxt);
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
  yystate = yyn;
  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  *++yyvsp = yylval;
  YY_IGNORE_MAYBE_UNINITIALIZED_END

  /* Discard the shifted token.  */
  yychar = YYEMPTY;
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
| yyreduce -- do a reduction.  |
`-----------------------------*/
yyreduce:
  /* yyn is the number of a rule to reduce with.  */
  yylen = yyr2[yyn];

  /* If YYLEN is nonzero, implement the default value of the action:
     '$$ = $1'.

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
#line 207 "rtfGrammar.y"
                    { GSRTFstart(CTXT); }
#line 1971 "rtfGrammar.tab.m"
    break;

  case 3:
#line 207 "rtfGrammar.y"
                                                                  { GSRTFstop(CTXT); }
#line 1977 "rtfGrammar.tab.m"
    break;

  case 5:
#line 210 "rtfGrammar.y"
                    { GSRTFencoding(CTXT, 1); }
#line 1983 "rtfGrammar.tab.m"
    break;

  case 6:
#line 211 "rtfGrammar.y"
                               { GSRTFencoding(CTXT, 2); }
#line 1989 "rtfGrammar.tab.m"
    break;

  case 7:
#line 212 "rtfGrammar.y"
                               { GSRTFencoding(CTXT, (yyval.number) = 3); }
#line 1995 "rtfGrammar.tab.m"
    break;

  case 8:
#line 213 "rtfGrammar.y"
                               { GSRTFencoding(CTXT, 4); }
#line 2001 "rtfGrammar.tab.m"
    break;

  case 9:
#line 214 "rtfGrammar.y"
                                              { GSRTFencoding(CTXT, (yyvsp[0].cmd).parameter); }
#line 2007 "rtfGrammar.tab.m"
    break;

  case 15:
#line 222 "rtfGrammar.y"
                                                        { GSRTFmangleText(CTXT, (yyvsp[0].text)); free((void *)(yyvsp[0].text)); }
#line 2013 "rtfGrammar.tab.m"
    break;

  case 18:
#line 227 "rtfGrammar.y"
                    { GSRTFopenBlock(CTXT, NO); }
#line 2019 "rtfGrammar.tab.m"
    break;

  case 19:
#line 227 "rtfGrammar.y"
                                                                                  { GSRTFcloseBlock(CTXT, NO); }
#line 2025 "rtfGrammar.tab.m"
    break;

  case 20:
#line 228 "rtfGrammar.y"
                            { GSRTFopenBlock(CTXT, YES); }
#line 2031 "rtfGrammar.tab.m"
    break;

  case 21:
#line 228 "rtfGrammar.y"
                                                                                        { GSRTFcloseBlock(CTXT, YES); }
#line 2037 "rtfGrammar.tab.m"
    break;

  case 22:
#line 229 "rtfGrammar.y"
                            { GSRTFopenBlock(CTXT, YES); }
#line 2043 "rtfGrammar.tab.m"
    break;

  case 23:
#line 229 "rtfGrammar.y"
                                                                                      { GSRTFcloseBlock(CTXT, YES); }
#line 2049 "rtfGrammar.tab.m"
    break;

  case 24:
#line 230 "rtfGrammar.y"
                            { GSRTFopenBlock(CTXT, YES); }
#line 2055 "rtfGrammar.tab.m"
    break;

  case 25:
#line 230 "rtfGrammar.y"
                                                                                            { GSRTFcloseBlock(CTXT, YES); }
#line 2061 "rtfGrammar.tab.m"
    break;

  case 26:
#line 231 "rtfGrammar.y"
                            { GSRTFopenBlock(CTXT, YES); }
#line 2067 "rtfGrammar.tab.m"
    break;

  case 27:
#line 231 "rtfGrammar.y"
                                                                                          { GSRTFcloseBlock(CTXT, YES); }
#line 2073 "rtfGrammar.tab.m"
    break;

  case 28:
#line 232 "rtfGrammar.y"
                            { GSRTFopenBlock(CTXT, YES); }
#line 2079 "rtfGrammar.tab.m"
    break;

  case 29:
#line 232 "rtfGrammar.y"
                                                                                        { GSRTFcloseBlock(CTXT, YES); }
#line 2085 "rtfGrammar.tab.m"
    break;

  case 30:
#line 233 "rtfGrammar.y"
                            { GSRTFopenBlock(CTXT, YES); }
#line 2091 "rtfGrammar.tab.m"
    break;

  case 31:
#line 233 "rtfGrammar.y"
                                                                                        { GSRTFcloseBlock(CTXT, YES); }
#line 2097 "rtfGrammar.tab.m"
    break;

  case 32:
#line 234 "rtfGrammar.y"
                            { GSRTFopenBlock(CTXT, YES); }
#line 2103 "rtfGrammar.tab.m"
    break;

  case 33:
#line 234 "rtfGrammar.y"
                                                                                      { GSRTFcloseBlock(CTXT, YES); }
#line 2109 "rtfGrammar.tab.m"
    break;

  case 34:
#line 235 "rtfGrammar.y"
                            { GSRTFopenBlock(CTXT, NO); }
#line 2115 "rtfGrammar.tab.m"
    break;

  case 35:
#line 235 "rtfGrammar.y"
                                                                                { GSRTFcloseBlock(CTXT, NO); }
#line 2121 "rtfGrammar.tab.m"
    break;

  case 37:
#line 240 "rtfGrammar.y"
          { fieldStart = GSRTFgetPosition(CTXT);}
#line 2127 "rtfGrammar.tab.m"
    break;

  case 38:
#line 240 "rtfGrammar.y"
                                                                                        { GSRTFaddField(CTXT, fieldStart, (yyvsp[-1].text)); free((void *)(yyvsp[-1].text)); }
#line 2133 "rtfGrammar.tab.m"
    break;

  case 47:
#line 255 "rtfGrammar.y"
                                                               { (yyval.text) = (yyvsp[-2].text);}
#line 2139 "rtfGrammar.tab.m"
    break;

  case 48:
#line 256 "rtfGrammar.y"
                                               { GSRTFopenBlock(CTXT, YES); }
#line 2145 "rtfGrammar.tab.m"
    break;

  case 49:
#line 256 "rtfGrammar.y"
                                                                                                                       { GSRTFcloseBlock(CTXT, YES); }
#line 2151 "rtfGrammar.tab.m"
    break;

  case 50:
#line 256 "rtfGrammar.y"
                                                                                                                                                           { (yyval.text) = (yyvsp[-4].text);}
#line 2157 "rtfGrammar.tab.m"
    break;

  case 51:
#line 257 "rtfGrammar.y"
                                { (yyval.text) = NULL;}
#line 2163 "rtfGrammar.tab.m"
    break;

  case 59:
#line 277 "rtfGrammar.y"
                                                { int font;
		    
						  if ((yyvsp[0].cmd).isEmpty)
						      font = 0;
						  else
						      font = (yyvsp[0].cmd).parameter;
						  GSRTFfontNumber(CTXT, font); }
#line 2175 "rtfGrammar.tab.m"
    break;

  case 60:
#line 284 "rtfGrammar.y"
                                                { int size;

						  if ((yyvsp[0].cmd).isEmpty)
						      size = 24;
						  else
						      size = (yyvsp[0].cmd).parameter;
						  GSRTFfontSize(CTXT, size); }
#line 2187 "rtfGrammar.tab.m"
    break;

  case 61:
#line 291 "rtfGrammar.y"
                                                { int width; 
		
		                                  if ((yyvsp[0].cmd).isEmpty)
						      width = 12240;
						  else
						      width = (yyvsp[0].cmd).parameter;
						  GSRTFpaperWidth(CTXT, width);}
#line 2199 "rtfGrammar.tab.m"
    break;

  case 62:
#line 298 "rtfGrammar.y"
                                                { int height; 
		
		                                  if ((yyvsp[0].cmd).isEmpty)
						      height = 15840;
						  else
						      height = (yyvsp[0].cmd).parameter;
						  GSRTFpaperHeight(CTXT, height);}
#line 2211 "rtfGrammar.tab.m"
    break;

  case 63:
#line 305 "rtfGrammar.y"
                                                { int margin; 
		
		                                  if ((yyvsp[0].cmd).isEmpty)
						      margin = 1800;
						  else
						      margin = (yyvsp[0].cmd).parameter;
						  GSRTFmarginLeft(CTXT, margin);}
#line 2223 "rtfGrammar.tab.m"
    break;

  case 64:
#line 312 "rtfGrammar.y"
                                                { int margin; 
		
		                                  if ((yyvsp[0].cmd).isEmpty)
						      margin = 1800;
						  else
						      margin = (yyvsp[0].cmd).parameter;
						  GSRTFmarginRight(CTXT, margin); }
#line 2235 "rtfGrammar.tab.m"
    break;

  case 65:
#line 319 "rtfGrammar.y"
                                                { int margin; 
		
		                                  if ((yyvsp[0].cmd).isEmpty)
						      margin = 1440;
						  else
						      margin = (yyvsp[0].cmd).parameter;
						  GSRTFmarginTop(CTXT, margin); }
#line 2247 "rtfGrammar.tab.m"
    break;

  case 66:
#line 326 "rtfGrammar.y"
                                                { int margin; 
		
		                                  if ((yyvsp[0].cmd).isEmpty)
						      margin = 1440;
						  else
						      margin = (yyvsp[0].cmd).parameter;
						  GSRTFmarginButtom(CTXT, margin); }
#line 2259 "rtfGrammar.tab.m"
    break;

  case 67:
#line 333 "rtfGrammar.y"
                                                { int indent; 
		
		                                  if ((yyvsp[0].cmd).isEmpty)
						      indent = 0;
						  else
						      indent = (yyvsp[0].cmd).parameter;
						  GSRTFfirstLineIndent(CTXT, indent); }
#line 2271 "rtfGrammar.tab.m"
    break;

  case 68:
#line 340 "rtfGrammar.y"
                                                { int indent; 
		
		                                  if ((yyvsp[0].cmd).isEmpty)
						      indent = 0;
						  else
						      indent = (yyvsp[0].cmd).parameter;
						  GSRTFleftIndent(CTXT, indent);}
#line 2283 "rtfGrammar.tab.m"
    break;

  case 69:
#line 347 "rtfGrammar.y"
                                                { int indent; 
		
		                                  if ((yyvsp[0].cmd).isEmpty)
						      indent = 0;
						  else
						      indent = (yyvsp[0].cmd).parameter;
						  GSRTFrightIndent(CTXT, indent);}
#line 2295 "rtfGrammar.tab.m"
    break;

  case 70:
#line 354 "rtfGrammar.y"
                                                { int location; 
		
		                                  if ((yyvsp[0].cmd).isEmpty)
						      location = 0;
						  else
						      location = (yyvsp[0].cmd).parameter;
						  GSRTFtabstop(CTXT, location);}
#line 2307 "rtfGrammar.tab.m"
    break;

  case 71:
#line 361 "rtfGrammar.y"
                                                { GSRTFalignCenter(CTXT); }
#line 2313 "rtfGrammar.tab.m"
    break;

  case 72:
#line 362 "rtfGrammar.y"
                                                { GSRTFalignJustified(CTXT); }
#line 2319 "rtfGrammar.tab.m"
    break;

  case 73:
#line 363 "rtfGrammar.y"
                                                { GSRTFalignLeft(CTXT); }
#line 2325 "rtfGrammar.tab.m"
    break;

  case 74:
#line 364 "rtfGrammar.y"
                                                { GSRTFalignRight(CTXT); }
#line 2331 "rtfGrammar.tab.m"
    break;

  case 75:
#line 365 "rtfGrammar.y"
                                                { int space; 
		
		                                  if ((yyvsp[0].cmd).isEmpty)
						      space = 0;
						  else
						      space = (yyvsp[0].cmd).parameter;
						  GSRTFspaceAbove(CTXT, space); }
#line 2343 "rtfGrammar.tab.m"
    break;

  case 76:
#line 372 "rtfGrammar.y"
                                                { GSRTFlineSpace(CTXT, (yyvsp[0].cmd).parameter); }
#line 2349 "rtfGrammar.tab.m"
    break;

  case 77:
#line 373 "rtfGrammar.y"
                                                { GSRTFdefaultParagraph(CTXT); }
#line 2355 "rtfGrammar.tab.m"
    break;

  case 78:
#line 374 "rtfGrammar.y"
                                                { GSRTFstyle(CTXT, (yyvsp[0].cmd).parameter); }
#line 2361 "rtfGrammar.tab.m"
    break;

  case 79:
#line 375 "rtfGrammar.y"
                                                { int color; 
		
		                                  if ((yyvsp[0].cmd).isEmpty)
						      color = 0;
						  else
						      color = (yyvsp[0].cmd).parameter;
						  GSRTFcolorbg(CTXT, color); }
#line 2373 "rtfGrammar.tab.m"
    break;

  case 80:
#line 382 "rtfGrammar.y"
                                                { int color; 
		
		                                  if ((yyvsp[0].cmd).isEmpty)
						      color = 0;
						  else
						      color = (yyvsp[0].cmd).parameter;
						  GSRTFcolorfg(CTXT, color); }
#line 2385 "rtfGrammar.tab.m"
    break;

  case 81:
#line 389 "rtfGrammar.y"
                                                { int color; 
		
		                                  if ((yyvsp[0].cmd).isEmpty)
						      color = 0;
						  else
						      color = (yyvsp[0].cmd).parameter;
						  GSRTFunderlinecolor(CTXT, color); }
#line 2397 "rtfGrammar.tab.m"
    break;

  case 82:
#line 396 "rtfGrammar.y"
                                                { int script;
		
		                                  if ((yyvsp[0].cmd).isEmpty)
						      script = 6;
						  else
						      script = (yyvsp[0].cmd).parameter;
						  GSRTFsubscript(CTXT, script); }
#line 2409 "rtfGrammar.tab.m"
    break;

  case 83:
#line 403 "rtfGrammar.y"
                                                { int script;
		
		                                  if ((yyvsp[0].cmd).isEmpty)
						      script = 6;
						  else
						      script = (yyvsp[0].cmd).parameter;
						  GSRTFsuperscript(CTXT, script); }
#line 2421 "rtfGrammar.tab.m"
    break;

  case 84:
#line 410 "rtfGrammar.y"
                                                { BOOL on;

		                                  if ((yyvsp[0].cmd).isEmpty || (yyvsp[0].cmd).parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFbold(CTXT, on); }
#line 2433 "rtfGrammar.tab.m"
    break;

  case 85:
#line 417 "rtfGrammar.y"
                                                { BOOL on;

		                                  if ((yyvsp[0].cmd).isEmpty || (yyvsp[0].cmd).parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFitalic(CTXT, on); }
#line 2445 "rtfGrammar.tab.m"
    break;

  case 86:
#line 424 "rtfGrammar.y"
                                                { BOOL on;

		                                  if ((yyvsp[0].cmd).isEmpty || (yyvsp[0].cmd).parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFunderline(CTXT, on, NSUnderlineStyleSingle | NSUnderlinePatternSolid); }
#line 2457 "rtfGrammar.tab.m"
    break;

  case 87:
#line 431 "rtfGrammar.y"
                                                { BOOL on;

		                                  if ((yyvsp[0].cmd).isEmpty || (yyvsp[0].cmd).parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFunderline(CTXT, on, NSUnderlineStyleSingle | NSUnderlinePatternDot); }
#line 2469 "rtfGrammar.tab.m"
    break;

  case 88:
#line 438 "rtfGrammar.y"
                                                { BOOL on;

		                                  if ((yyvsp[0].cmd).isEmpty || (yyvsp[0].cmd).parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFunderline(CTXT, on, NSUnderlineStyleSingle | NSUnderlinePatternDash); }
#line 2481 "rtfGrammar.tab.m"
    break;

  case 89:
#line 445 "rtfGrammar.y"
                                                { BOOL on;

		                                  if ((yyvsp[0].cmd).isEmpty || (yyvsp[0].cmd).parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFunderline(CTXT, on, NSUnderlineStyleSingle | NSUnderlinePatternDashDot); }
#line 2493 "rtfGrammar.tab.m"
    break;

  case 90:
#line 452 "rtfGrammar.y"
                                                { BOOL on;

		                                  if ((yyvsp[0].cmd).isEmpty || (yyvsp[0].cmd).parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFunderline(CTXT, on, NSUnderlineStyleSingle | NSUnderlinePatternDashDotDot); }
#line 2505 "rtfGrammar.tab.m"
    break;

  case 91:
#line 459 "rtfGrammar.y"
                                                { BOOL on;

		                                  if ((yyvsp[0].cmd).isEmpty || (yyvsp[0].cmd).parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFunderline(CTXT, on, NSUnderlineStyleDouble | NSUnderlinePatternSolid); }
#line 2517 "rtfGrammar.tab.m"
    break;

  case 92:
#line 466 "rtfGrammar.y"
                                { GSRTFunderline(CTXT, NO, NSUnderlineStyleNone); }
#line 2523 "rtfGrammar.tab.m"
    break;

  case 93:
#line 467 "rtfGrammar.y"
                                                { BOOL on;

		                                  if ((yyvsp[0].cmd).isEmpty || (yyvsp[0].cmd).parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFunderline(CTXT, on, NSUnderlineStyleThick | NSUnderlinePatternSolid); }
#line 2535 "rtfGrammar.tab.m"
    break;

  case 94:
#line 474 "rtfGrammar.y"
                                                { BOOL on;

		                                  if ((yyvsp[0].cmd).isEmpty || (yyvsp[0].cmd).parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFunderline(CTXT, on, NSUnderlineStyleThick | NSUnderlinePatternDot); }
#line 2547 "rtfGrammar.tab.m"
    break;

  case 95:
#line 481 "rtfGrammar.y"
                                                { BOOL on;

		                                  if ((yyvsp[0].cmd).isEmpty || (yyvsp[0].cmd).parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFunderline(CTXT, on, NSUnderlineStyleThick | NSUnderlinePatternDash); }
#line 2559 "rtfGrammar.tab.m"
    break;

  case 96:
#line 488 "rtfGrammar.y"
                                                        { BOOL on;

		                                  if ((yyvsp[0].cmd).isEmpty || (yyvsp[0].cmd).parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFunderline(CTXT, on, NSUnderlineStyleThick | NSUnderlinePatternDashDot); }
#line 2571 "rtfGrammar.tab.m"
    break;

  case 97:
#line 495 "rtfGrammar.y"
                                                    { BOOL on;

		                                  if ((yyvsp[0].cmd).isEmpty || (yyvsp[0].cmd).parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFunderline(CTXT, on, NSUnderlineStyleThick | NSUnderlinePatternDashDotDot); }
#line 2583 "rtfGrammar.tab.m"
    break;

  case 98:
#line 502 "rtfGrammar.y"
                                                { BOOL on;

		                                  if ((yyvsp[0].cmd).isEmpty || (yyvsp[0].cmd).parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFunderline(CTXT, on, NSUnderlineStyleSingle | NSUnderlinePatternSolid | NSUnderlineByWordMask); }
#line 2595 "rtfGrammar.tab.m"
    break;

  case 99:
#line 509 "rtfGrammar.y"
                                {   NSInteger style;
   if ((yyvsp[0].cmd).isEmpty || (yyvsp[0].cmd).parameter)
     style = NSUnderlineStyleSingle | NSUnderlinePatternSolid;
   else
     style = NSUnderlineStyleNone;
   GSRTFstrikethrough(CTXT, style); }
#line 2606 "rtfGrammar.tab.m"
    break;

  case 100:
#line 515 "rtfGrammar.y"
                                { GSRTFstrikethrough(CTXT, NSUnderlineStyleDouble | NSUnderlinePatternSolid); }
#line 2612 "rtfGrammar.tab.m"
    break;

  case 101:
#line 516 "rtfGrammar.y"
                                                { GSRTFunicode(CTXT, (yyvsp[0].cmd).parameter); }
#line 2618 "rtfGrammar.tab.m"
    break;

  case 102:
#line 517 "rtfGrammar.y"
                                                { GSRTFdefaultCharacterStyle(CTXT); }
#line 2624 "rtfGrammar.tab.m"
    break;

  case 103:
#line 518 "rtfGrammar.y"
                                                { GSRTFparagraph(CTXT); }
#line 2630 "rtfGrammar.tab.m"
    break;

  case 104:
#line 519 "rtfGrammar.y"
                                                { GSRTFparagraph(CTXT); }
#line 2636 "rtfGrammar.tab.m"
    break;

  case 105:
#line 520 "rtfGrammar.y"
                                                { GSRTFgenericRTFcommand(CTXT, (yyvsp[0].cmd)); 
		                                  free((void*)(yyvsp[0].cmd).name); }
#line 2643 "rtfGrammar.tab.m"
    break;

  case 110:
#line 539 "rtfGrammar.y"
                                                                                        { GSRTFopenBlock(CTXT, YES); }
#line 2649 "rtfGrammar.tab.m"
    break;

  case 111:
#line 539 "rtfGrammar.y"
                                                                                                                                      { GSRTFcloseBlock(CTXT, YES); }
#line 2655 "rtfGrammar.tab.m"
    break;

  case 112:
#line 540 "rtfGrammar.y"
                {
			GSRTFNeXTGraphic (CTXT, (yyvsp[-6].text), (yyvsp[-5].cmd).parameter, (yyvsp[-4].cmd).parameter);
		}
#line 2663 "rtfGrammar.tab.m"
    break;

  case 113:
#line 554 "rtfGrammar.y"
                                                                                                                             { GSRTFopenBlock(CTXT, YES); }
#line 2669 "rtfGrammar.tab.m"
    break;

  case 114:
#line 554 "rtfGrammar.y"
                                                                                                                                                                           { GSRTFcloseBlock(CTXT, YES); }
#line 2675 "rtfGrammar.tab.m"
    break;

  case 115:
#line 555 "rtfGrammar.y"
                {
			GSRTFNeXTHelpLink (CTXT, (yyvsp[-10].cmd).parameter, (yyvsp[-8].text), (yyvsp[-6].text), (yyvsp[-4].text));
		}
#line 2683 "rtfGrammar.tab.m"
    break;

  case 116:
#line 568 "rtfGrammar.y"
                                                                       { GSRTFopenBlock(CTXT, YES); }
#line 2689 "rtfGrammar.tab.m"
    break;

  case 117:
#line 568 "rtfGrammar.y"
                                                                                                                     { GSRTFcloseBlock(CTXT, YES); }
#line 2695 "rtfGrammar.tab.m"
    break;

  case 118:
#line 569 "rtfGrammar.y"
                {
			GSRTFNeXTHelpMarker (CTXT, (yyvsp[-6].cmd).parameter, (yyvsp[-4].text));
		}
#line 2703 "rtfGrammar.tab.m"
    break;

  case 123:
#line 584 "rtfGrammar.y"
                    { free((void *)(yyvsp[-1].text));}
#line 2709 "rtfGrammar.tab.m"
    break;

  case 124:
#line 589 "rtfGrammar.y"
                                                                        { GSRTFregisterFont(CTXT, (yyvsp[0].text), (yyvsp[-2].number), (yyvsp[-3].cmd).parameter);
                                                          free((void *)(yyvsp[0].text)); }
#line 2716 "rtfGrammar.tab.m"
    break;

  case 125:
#line 592 "rtfGrammar.y"
                                                                                        { GSRTFregisterFont(CTXT, (yyvsp[0].text), (yyvsp[-2].number), (yyvsp[-4].cmd).parameter);
                                                          free((void *)(yyvsp[0].text)); }
#line 2723 "rtfGrammar.tab.m"
    break;

  case 126:
#line 595 "rtfGrammar.y"
                                                                                                        { GSRTFregisterFont(CTXT, (yyvsp[0].text), (yyvsp[-2].number), (yyvsp[-4].cmd).parameter);
                                                          free((void *)(yyvsp[0].text)); }
#line 2730 "rtfGrammar.tab.m"
    break;

  case 133:
#line 609 "rtfGrammar.y"
                                        { (yyval.number) = RTFfamilyNil - RTFfamilyNil; }
#line 2736 "rtfGrammar.tab.m"
    break;

  case 134:
#line 610 "rtfGrammar.y"
                                        { (yyval.number) = RTFfamilyRoman - RTFfamilyNil; }
#line 2742 "rtfGrammar.tab.m"
    break;

  case 135:
#line 611 "rtfGrammar.y"
                                        { (yyval.number) = RTFfamilySwiss - RTFfamilyNil; }
#line 2748 "rtfGrammar.tab.m"
    break;

  case 136:
#line 612 "rtfGrammar.y"
                                        { (yyval.number) = RTFfamilyModern - RTFfamilyNil; }
#line 2754 "rtfGrammar.tab.m"
    break;

  case 137:
#line 613 "rtfGrammar.y"
                                        { (yyval.number) = RTFfamilyScript - RTFfamilyNil; }
#line 2760 "rtfGrammar.tab.m"
    break;

  case 138:
#line 614 "rtfGrammar.y"
                                        { (yyval.number) = RTFfamilyDecor - RTFfamilyNil; }
#line 2766 "rtfGrammar.tab.m"
    break;

  case 139:
#line 615 "rtfGrammar.y"
                                        { (yyval.number) = RTFfamilyTech - RTFfamilyNil; }
#line 2772 "rtfGrammar.tab.m"
    break;

  case 143:
#line 632 "rtfGrammar.y"
                     { 
		       GSRTFaddColor(CTXT, (yyvsp[-3].cmd).parameter, (yyvsp[-2].cmd).parameter, (yyvsp[-1].cmd).parameter);
		       free((void *)(yyvsp[0].text));
		     }
#line 2781 "rtfGrammar.tab.m"
    break;

  case 144:
#line 637 "rtfGrammar.y"
                     { 
		       GSRTFaddDefaultColor(CTXT);
		       free((void *)(yyvsp[0].text));
		     }
#line 2790 "rtfGrammar.tab.m"
    break;


#line 2794 "rtfGrammar.tab.m"

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

  /* Now 'shift' the result of the reduction.  Determine what state
     that goes to, based on the state we popped back to and the rule
     number reduced by.  */
  {
    const int yylhs = yyr1[yyn] - YYNTOKENS;
    const int yyi = yypgoto[yylhs] + *yyssp;
    yystate = (0 <= yyi && yyi <= YYLAST && yycheck[yyi] == *yyssp
               ? yytable[yyi]
               : yydefgoto[yylhs]);
  }

  goto yynewstate;


/*--------------------------------------.
| yyerrlab -- here on detecting error.  |
`--------------------------------------*/
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
            yymsg = YY_CAST (char *, YYSTACK_ALLOC (YY_CAST (YYSIZE_T, yymsg_alloc)));
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
  /* Pacify compilers when the user code never invokes YYERROR and the
     label yyerrorlab therefore never appears in user code.  */
  if (0)
    YYERROR;

  /* Do not reclaim the symbols of the rule whose action triggered
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
  yyerrstatus = 3;      /* Each real token shifted decrements this.  */

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


/*-----------------------------------------------------.
| yyreturn -- parsing is finished, return the result.  |
`-----------------------------------------------------*/
yyreturn:
  if (yychar != YYEMPTY)
    {
      /* Make sure we have latest lookahead translation.  See comments at
         user semantic actions for why this is necessary.  */
      yytoken = YYTRANSLATE (yychar);
      yydestruct ("Cleanup: discarding lookahead",
                  yytoken, &yylval, ctxt, lctxt);
    }
  /* Do not reclaim the symbols of the rule whose action triggered
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
  return yyresult;
}
#line 649 "rtfGrammar.y"


/*	some C code here	*/

