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
#define	RTFalignCenter	287
#define	RTFalignLeft	288
#define	RTFalignRight	289
#define	RTFstyle	290
#define	RTFbold	291
#define	RTFitalic	292
#define	RTFunderline	293
#define	RTFunderlineStop	294
#define	RTFsubscript	295
#define	RTFsuperscript	296
#define	RTFtabulator	297
#define	RTFparagraph	298
#define	RTFdefaultParagraph	299
#define	RTFfcharset	300
#define	RTFfprq	301
#define	RTFcpg	302
#define	RTFOtherStatement	303
#define	RTFfontListStart	304
#define	RTFfamilyNil	305
#define	RTFfamilyRoman	306
#define	RTFfamilySwiss	307
#define	RTFfamilyModern	308
#define	RTFfamilyScript	309
#define	RTFfamilyDecor	310
#define	RTFfamilyTech	311

