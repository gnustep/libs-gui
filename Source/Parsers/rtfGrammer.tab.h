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

#define	RTFtext	258
#define	RTFstart	259
#define	RTFansi	260
#define	RTFmac	261
#define	RTFpc	262
#define	RTFpca	263
#define	RTFignore	264
#define	RTFred	265
#define	RTFgreen	266
#define	RTFblue	267
#define	RTFcolorbg	268
#define	RTFcolorfg	269
#define	RTFcolortable	270
#define	RTFfont	271
#define	RTFfontSize	272
#define	RTFpaperWidth	273
#define	RTFpaperHeight	274
#define	RTFmarginLeft	275
#define	RTFmarginRight	276
#define	RTFfirstLineIndent	277
#define	RTFleftIndent	278
#define	RTFalignCenter	279
#define	RTFalignLeft	280
#define	RTFalignRight	281
#define	RTFstyle	282
#define	RTFbold	283
#define	RTFitalic	284
#define	RTFunderline	285
#define	RTFunderlineStop	286
#define	RTFsubscript	287
#define	RTFsuperscript	288
#define	RTFtabulator	289
#define	RTFparagraph	290
#define	RTFdefaultParagraph	291
#define	RTFOtherStatement	292
#define	RTFfontListStart	293
#define	RTFfamilyNil	294
#define	RTFfamilyRoman	295
#define	RTFfamilySwiss	296
#define	RTFfamilyModern	297
#define	RTFfamilyScript	298
#define	RTFfamilyDecor	299
#define	RTFfamilyTech	300

