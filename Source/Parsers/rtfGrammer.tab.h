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

#define	RTFtext	257
#define	RTFstart	258
#define	RTFfont	259
#define	RTFfontSize	260
#define	RTFpaperWidth	261
#define	RTFpaperHeight	262
#define	RTFmarginLeft	263
#define	RTFmarginRight	264
#define	RTFbold	265
#define	RTFitalic	266
#define	RTFunderline	267
#define	RTFunderlineStop	268
#define	RTFOtherStatement	269
#define	RTFfontListStart	270
#define	RTFfamilyNil	271
#define	RTFfamilyRoman	272
#define	RTFfamilySwiss	273
#define	RTFfamilyModern	274
#define	RTFfamilyScript	275
#define	RTFfamilyDecor	276
#define	RTFfamilyTech	277

