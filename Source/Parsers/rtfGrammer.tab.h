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
#define	RTFinfo	265
#define	RTFstylesheet	266
#define	RTFfootnote	267
#define	RTFheader	268
#define	RTFfooter	269
#define	RTFpict	270
#define	RTFred	271
#define	RTFgreen	272
#define	RTFblue	273
#define	RTFcolorbg	274
#define	RTFcolorfg	275
#define	RTFcolortable	276
#define	RTFfont	277
#define	RTFfontSize	278
#define	RTFpaperWidth	279
#define	RTFpaperHeight	280
#define	RTFmarginLeft	281
#define	RTFmarginRight	282
#define	RTFmarginTop	283
#define	RTFmarginButtom	284
#define	RTFfirstLineIndent	285
#define	RTFleftIndent	286
#define	RTFrightIndent	287
#define	RTFalignCenter	288
#define	RTFalignLeft	289
#define	RTFalignRight	290
#define	RTFstyle	291
#define	RTFbold	292
#define	RTFitalic	293
#define	RTFunderline	294
#define	RTFunderlineStop	295
#define	RTFsubscript	296
#define	RTFsuperscript	297
#define	RTFtabulator	298
#define	RTFtabstop	299
#define	RTFparagraph	300
#define	RTFdefaultParagraph	301
#define	RTFfcharset	302
#define	RTFfprq	303
#define	RTFcpg	304
#define	RTFOtherStatement	305
#define	RTFfontListStart	306
#define	RTFfamilyNil	307
#define	RTFfamilyRoman	308
#define	RTFfamilySwiss	309
#define	RTFfamilyModern	310
#define	RTFfamilyScript	311
#define	RTFfamilyDecor	312
#define	RTFfamilyTech	313

