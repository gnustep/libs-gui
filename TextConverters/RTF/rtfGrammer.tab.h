#ifndef BISON_RTFGRAMMER_TAB_H
# define BISON_RTFGRAMMER_TAB_H

#ifndef YYSTYPE
typedef union {
	int		number;
	const char	*text;
	RTFcmd		cmd;
} yystype;
# define YYSTYPE yystype
# define YYSTYPE_IS_TRIVIAL 1
#endif
# define	RTFtext	257
# define	RTFstart	258
# define	RTFansi	259
# define	RTFmac	260
# define	RTFpc	261
# define	RTFpca	262
# define	RTFignore	263
# define	RTFinfo	264
# define	RTFstylesheet	265
# define	RTFfootnote	266
# define	RTFheader	267
# define	RTFfooter	268
# define	RTFpict	269
# define	RTFplain	270
# define	RTFparagraph	271
# define	RTFdefaultParagraph	272
# define	RTFrow	273
# define	RTFcell	274
# define	RTFtabulator	275
# define	RTFemdash	276
# define	RTFendash	277
# define	RTFemspace	278
# define	RTFenspace	279
# define	RTFbullet	280
# define	RTFlquote	281
# define	RTFrquote	282
# define	RTFldblquote	283
# define	RTFrdblquote	284
# define	RTFred	285
# define	RTFgreen	286
# define	RTFblue	287
# define	RTFcolorbg	288
# define	RTFcolorfg	289
# define	RTFcolortable	290
# define	RTFfont	291
# define	RTFfontSize	292
# define	RTFpaperWidth	293
# define	RTFpaperHeight	294
# define	RTFmarginLeft	295
# define	RTFmarginRight	296
# define	RTFmarginTop	297
# define	RTFmarginButtom	298
# define	RTFfirstLineIndent	299
# define	RTFleftIndent	300
# define	RTFrightIndent	301
# define	RTFalignCenter	302
# define	RTFalignJustified	303
# define	RTFalignLeft	304
# define	RTFalignRight	305
# define	RTFlineSpace	306
# define	RTFspaceAbove	307
# define	RTFstyle	308
# define	RTFbold	309
# define	RTFitalic	310
# define	RTFunderline	311
# define	RTFunderlineStop	312
# define	RTFsubscript	313
# define	RTFsuperscript	314
# define	RTFtabstop	315
# define	RTFfcharset	316
# define	RTFfprq	317
# define	RTFcpg	318
# define	RTFOtherStatement	319
# define	RTFfontListStart	320
# define	RTFfamilyNil	321
# define	RTFfamilyRoman	322
# define	RTFfamilySwiss	323
# define	RTFfamilyModern	324
# define	RTFfamilyScript	325
# define	RTFfamilyDecor	326
# define	RTFfamilyTech	327


#endif /* not BISON_RTFGRAMMER_TAB_H */
