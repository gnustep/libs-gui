typedef union {
	int		number;
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
#define	RTFplain	271
#define	RTFparagraph	272
#define	RTFdefaultParagraph	273
#define	RTFrow	274
#define	RTFcell	275
#define	RTFtabulator	276
#define	RTFemdash	277
#define	RTFendash	278
#define	RTFemspace	279
#define	RTFenspace	280
#define	RTFbullet	281
#define	RTFlquote	282
#define	RTFrquote	283
#define	RTFldblquote	284
#define	RTFrdblquote	285
#define	RTFred	286
#define	RTFgreen	287
#define	RTFblue	288
#define	RTFcolorbg	289
#define	RTFcolorfg	290
#define	RTFcolortable	291
#define	RTFfont	292
#define	RTFfontSize	293
#define	RTFpaperWidth	294
#define	RTFpaperHeight	295
#define	RTFmarginLeft	296
#define	RTFmarginRight	297
#define	RTFmarginTop	298
#define	RTFmarginButtom	299
#define	RTFfirstLineIndent	300
#define	RTFleftIndent	301
#define	RTFrightIndent	302
#define	RTFalignCenter	303
#define	RTFalignJustified	304
#define	RTFalignLeft	305
#define	RTFalignRight	306
#define	RTFlineSpace	307
#define	RTFspaceAbove	308
#define	RTFstyle	309
#define	RTFbold	310
#define	RTFitalic	311
#define	RTFunderline	312
#define	RTFunderlineStop	313
#define	RTFsubscript	314
#define	RTFsuperscript	315
#define	RTFtabstop	316
#define	RTFfcharset	317
#define	RTFfprq	318
#define	RTFcpg	319
#define	RTFOtherStatement	320
#define	RTFfontListStart	321
#define	RTFfamilyNil	322
#define	RTFfamilyRoman	323
#define	RTFfamilySwiss	324
#define	RTFfamilyModern	325
#define	RTFfamilyScript	326
#define	RTFfamilyDecor	327
#define	RTFfamilyTech	328

