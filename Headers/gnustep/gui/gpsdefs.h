/* gpsdefs - Rename PS functions to GS functions avoiding name clashing

   Copyright (C) 1995 Free Software Foundation, Inc.
   Written by:  Adam Fedor <fedor@gnu.org>
   Date: Nov 1998

   Generated autmatically by gpsformat
    
*/

#ifndef _gpsdefs_h_INCLUDE
#define _gpsdefs_h_INCLUDE

/* ----------------------------------------------------------------------- */
/* Color operations */
/* ----------------------------------------------------------------------- */
#define PScolorimage GScolorimage
#define PScurrentblackgeneration GScurrentblackgeneration
#define PScurrentcmykcolor GScurrentcmykcolor
#define PScurrentcolorscreen GScurrentcolorscreen
#define PScurrentcolortransfer GScurrentcolortransfer
#define PScurrentundercolorremoval GScurrentundercolorremoval
#define PSsetblackgeneration GSsetblackgeneration
#define PSsetcmykcolor GSsetcmykcolor
#define PSsetcolorscreen GSsetcolorscreen
#define PSsetcolortransfer GSsetcolortransfer
#define PSsetundercolorremoval GSsetundercolorremoval
/* ----------------------------------------------------------------------- */
/* Font operations */
/* ----------------------------------------------------------------------- */
#define PSFontDirectory GSFontDirectory
#define PSISOLatin1Encoding GSISOLatin1Encoding
#define PSSharedFontDirectory GSSharedFontDirectory
#define PSStandardEncoding GSStandardEncoding
#define PScachestatus GScachestatus
#define PScurrentcacheparams GScurrentcacheparams
#define PScurrentfont GScurrentfont
#define PSdefinefont GSdefinefont
#define PSfindfont GSfindfont
#define PSmakefont GSmakefont
#define PSscalefont GSscalefont
#define PSselectfont GSselectfont
#define PSsetcachedevice GSsetcachedevice
#define PSsetcachelimit GSsetcachelimit
#define PSsetcacheparams GSsetcacheparams
#define PSsetcharwidth GSsetcharwidth
#define PSsetfont GSsetfont
#define PSundefinefont GSundefinefont
/* ----------------------------------------------------------------------- */
/* Gstate operations */
/* ----------------------------------------------------------------------- */
#define PSconcat GSconcat
#define PScurrentdash GScurrentdash
#define PScurrentflat GScurrentflat
#define PScurrentgray GScurrentgray
#define PScurrentgstate GScurrentgstate
#define PScurrenthalftone GScurrenthalftone
#define PScurrenthalftonephase GScurrenthalftonephase
#define PScurrenthsbcolor GScurrenthsbcolor
#define PScurrentlinecap GScurrentlinecap
#define PScurrentlinejoin GScurrentlinejoin
#define PScurrentlinewidth GScurrentlinewidth
#define PScurrentmatrix GScurrentmatrix
#define PScurrentmiterlimit GScurrentmiterlimit
#define PScurrentpoint GScurrentpoint
#define PScurrentrgbcolor GScurrentrgbcolor
#define PScurrentscreen GScurrentscreen
#define PScurrentstrokeadjust GScurrentstrokeadjust
#define PScurrenttransfer GScurrenttransfer
#define PSdefaultmatrix GSdefaultmatrix
#define PSgrestore GSgrestore
#define PSgrestoreall GSgrestoreall
#define PSgsave GSgsave
#define PSgstate GSgstate
#define PSinitgraphics GSinitgraphics
#define PSinitmatrix GSinitmatrix
#define PSrotate GSrotate
#define PSscale GSscale
#define PSsetdash GSsetdash
#define PSsetflat GSsetflat
#define PSsetgray GSsetgray
#define PSsetgstate GSsetgstate
#define PSsethalftone GSsethalftone
#define PSsethalftonephase GSsethalftonephase
#define PSsethsbcolor GSsethsbcolor
#define PSsetlinecap GSsetlinecap
#define PSsetlinejoin GSsetlinejoin
#define PSsetlinewidth GSsetlinewidth
#define PSsetmatrix GSsetmatrix
#define PSsetmiterlimit GSsetmiterlimit
#define PSsetrgbcolor GSsetrgbcolor
#define PSsetscreen GSsetscreen
#define PSsetstrokeadjust GSsetstrokeadjust
#define PSsettransfer GSsettransfer
#define PStranslate GStranslate
/* ----------------------------------------------------------------------- */
/* I/O operations */
/* ----------------------------------------------------------------------- */
#define PSequals GSequals
#define PSequalsequals GSequalsequals
#define PSbytesavailable GSbytesavailable
#define PSclosefile GSclosefile
#define PScurrentfile GScurrentfile
#define PSdeletefile GSdeletefile
#define PSecho GSecho
#define PSfile GSfile
#define PSfilenameforall GSfilenameforall
#define PSfileposition GSfileposition
#define PSflush GSflush
#define PSflushfile GSflushfile
#define PSprint GSprint
#define PSprintobject GSprintobject
#define PSpstack GSpstack
#define PSread GSread
#define PSreadhexstring GSreadhexstring
#define PSreadline GSreadline
#define PSreadstring GSreadstring
#define PSrenamefile GSrenamefile
#define PSresetfile GSresetfile
#define PSsetfileposition GSsetfileposition
#define PSstack GSstack
#define PSstatus GSstatus
#define PStoken GStoken
#define PSwrite GSwrite
#define PSwritehexstring GSwritehexstring
#define PSwriteobject GSwriteobject
#define PSwritestring GSwritestring
/* ----------------------------------------------------------------------- */
/* Matrix operations */
/* ----------------------------------------------------------------------- */
#define PSconcatmatrix GSconcatmatrix
#define PSdtransform GSdtransform
#define PSidentmatrix GSidentmatrix
#define PSidtransform GSidtransform
#define PSinvertmatrix GSinvertmatrix
#define PSitransform GSitransform
#define PStransform GStransform
/* ----------------------------------------------------------------------- */
/* Paint operations */
/* ----------------------------------------------------------------------- */
#define PSashow GSashow
#define PSawidthshow GSawidthshow
#define PScopypage GScopypage
#define PSeofill GSeofill
#define PSerasepage GSerasepage
#define PSfill GSfill
#define PSimage GSimage
#define PSimagemask GSimagemask
#define PSkshow GSkshow
#define PSrectfill GSrectfill
#define PSrectstroke GSrectstroke
#define PSshow GSshow
#define PSshowpage GSshowpage
#define PSstroke GSstroke
#define PSstrokepath GSstrokepath
#define PSueofill GSueofill
#define PSufill GSufill
#define PSustroke GSustroke
#define PSustrokepath GSustrokepath
#define PSwidthshow GSwidthshow
#define PSxshow GSxshow
#define PSxyshow GSxyshow
#define PSyshow GSyshow
/* ----------------------------------------------------------------------- */
/* Path operations */
/* ----------------------------------------------------------------------- */
#define PSarc GSarc
#define PSarcn GSarcn
#define PSarct GSarct
#define PSarcto GSarcto
#define PScharpath GScharpath
#define PSclip GSclip
#define PSclippath GSclippath
#define PSclosepath GSclosepath
#define PScurveto GScurveto
#define PSeoclip GSeoclip
#define PSeoviewclip GSeoviewclip
#define PSflattenpath GSflattenpath
#define PSinitclip GSinitclip
#define PSinitviewclip GSinitviewclip
#define PSlineto GSlineto
#define PSmoveto GSmoveto
#define PSnewpath GSnewpath
#define PSpathbbox GSpathbbox
#define PSpathforall GSpathforall
#define PSrcurveto GSrcurveto
#define PSrectclip GSrectclip
#define PSrectviewclip GSrectviewclip
#define PSreversepath GSreversepath
#define PSrlineto GSrlineto
#define PSrmoveto GSrmoveto
#define PSsetbbox GSsetbbox
#define PSsetucacheparams GSsetucacheparams
#define PSuappend GSuappend
#define PSucache GSucache
#define PSucachestatus GSucachestatus
#define PSupath GSupath
#define PSviewclip GSviewclip
#define PSviewclippath GSviewclippath
/* ----------------------------------------------------------------------- */
/* X operations */
/* ----------------------------------------------------------------------- */
#define PScurrentXdrawingfunction GScurrentXdrawingfunction
#define PScurrentXgcdrawable GScurrentXgcdrawable
#define PScurrentXgcdrawablecolor GScurrentXgcdrawablecolor
#define PScurrentXoffset GScurrentXoffset
#define PSsetXdrawingfunction GSsetXdrawingfunction
#define PSsetXgcdrawable GSsetXgcdrawable
#define PSsetXgcdrawablecolor GSsetXgcdrawablecolor
#define PSsetXoffset GSsetXoffset
#define PSsetXrgbactual GSsetXrgbactual

#endif
