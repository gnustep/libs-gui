/* GPSDrawContext - GNUstep drawing context class.

   Copyright (C) 1998 Free Software Foundation, Inc.

   Written by:  Adam Fedor <fedor@gnu.org>
   Date: Nov 1998
   
   This file is part of the GNU Objective C User : (int *)erface library.

   This library is free software { } you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation { } either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY { } without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.
   
   You should have received a copy of the GNU Library General Public
   License along with this library { } if not, write to the Free
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/
   

#include <Foundation/NSString.h> 
#include <Foundation/NSArray.h> 
#include <Foundation/NSDictionary.h>
#include <Foundation/NSException.h>
#include <Foundation/NSData.h>
#include "AppKit/GPSDrawContext.h"

/* The memory zone where all global objects are allocated from (Contexts
   are also allocated from this zone) */
NSZone *_globalGPSZone = NULL;

/* It's odd that we should have to control the list of contexts.  Maybe
   we should have a class ContextServer for this role */
static NSMutableArray *ctxtList;

/* The current context */
GPSDrawContext *_currentGPSContext = nil;

static Class defaultGPSContextClass = NULL;

@implementation GPSDrawContext 

+ (void) initialize
{
  if (self == [GPSDrawContext class])
    {
      ctxtList = [[NSMutableArray arrayWithCapacity:2] retain];
      //_globalGPSZone = NSCreateZone(4096, 4096, YES);
    }
}

+ (void) setDefaultContextClass: (Class)defaultContextClass
{
  defaultGPSContextClass = defaultContextClass;
}

+ defaultContextWithInfo: (NSDictionary *)info;
{
  GPSDrawContext *ctxt;

  NSAssert(defaultGPSContextClass, 
	   @"Internal Error: No default GPSContext set\n");
  ctxt = [[defaultGPSContextClass allocWithZone: _globalGPSZone]
	   initWithContextInfo: info];
  [ctxt autorelease];
  return ctxt;
}

+ streamContextWithPath: (NSString *)path;
{
  return [self notImplemented: _cmd];
}

+ (void) setCurrentContext: (GPSDrawContext *)context
{
  _currentGPSContext = context;
}

+ (GPSDrawContext *) currentContext
{
  return _currentGPSContext;
}

- init
{
  return [self initWithContextInfo: NULL];
}

/* designated initializer for the GPSDrawContext class */
- initWithContextInfo: (NSDictionary *)info
{
  [super init];
  [ctxtList addObject: self];
  [GPSDrawContext setCurrentContext: self];
  context_info = [info retain];
  return self;
}

- (BOOL)isDrawingToScreen
{
  return NO;
}

- (NSMutableData *)mutableData
{
  return context_data;
}

/* Just remove ourselves from the context list so we will be dealloced on
   the next autorelease pool end */
- (void) destroyContext;
{
  [ctxtList removeObject: self];
}

- (void) dealloc
{
  DESTROY(context_data);
  [super dealloc];
}

@end

@implementation GPSDrawContext (ColorOps)

- (void)DPScolorimage { }

- (void)DPScurrentblackgeneration { }

- (void)DPScurrentcmykcolor: (float *)c : (float *)m : (float *)y : (float *)k { }

- (void)DPScurrentcolorscreen { }

- (void)DPScurrentcolortransfer { }

- (void)DPScurrentundercolorremoval { }

- (void)DPSsetblackgeneration { }

- (void)DPSsetcmykcolor: (float)c : (float)m : (float)y : (float)k { }

- (void)DPSsetcolorscreen { }

- (void)DPSsetcolortransfer { }

- (void)DPSsetundercolorremoval { }

@end

@implementation GPSDrawContext (ControlOps)

- (void)DPSeq { }

- (void)DPSexit { }

- (void)DPSfalse { }

- (void)DPSfor { }

- (void)DPSforall { }

- (void)DPSge { }

- (void)DPSgt { }

- (void)DPSif { }

- (void)DPSifelse { }

- (void)DPSle { }

- (void)DPSloop { }

- (void)DPSlt { }

- (void)DPSne { }

- (void)DPSnot { }

- (void)DPSor { }

- (void)DPSrepeat { }

- (void)DPSstop { }

- (void)DPSstopped { }

- (void)DPStrue { }

@end

@implementation GPSDrawContext (CtxOps)

- (void)DPScondition { }

- (void)DPScurrentcontext: (int *)cid { }

- (void)DPScurrentobjectformat: (int *)code { }

- (void)DPSdefineusername: (int)i : (const char *)username { }

- (void)DPSdefineuserobject { }

- (void)DPSdetach { }

- (void)DPSexecuserobject: (int)index { }

- (void)DPSfork { }

- (void)DPSjoin { }

- (void)DPSlock { }

- (void)DPSmonitor { }

- (void)DPSnotify { }

- (void)DPSsetobjectformat: (int)code { }

- (void)DPSsetvmthreshold: (int)i { }

- (void)DPSundefineuserobject: (int)index { }

- (void)DPSuserobject { }

- (void)DPSwait { }

- (void)DPSyield { }

@end

@implementation GPSDrawContext (DataOps)

- (void)DPSaload { }

- (void)DPSanchorsearch: (int *)truth { }

- (void)DPSarray: (int)len { }

- (void)DPSastore { }

- (void)DPSbegin { }

- (void)DPSclear { }

- (void)DPScleartomark { }

- (void)DPScopy: (int)n { }

- (void)DPScount: (int *)n { }

- (void)DPScounttomark: (int *)n { }

- (void)DPScvi { }

- (void)DPScvlit { }

- (void)DPScvn { }

- (void)DPScvr { }

- (void)DPScvrs { }

- (void)DPScvs { }

- (void)DPScvx { }

- (void)DPSdef { }

- (void)DPSdict: (int)len { }

- (void)DPSdictstack { }

- (void)DPSdup { }

- (void)DPSend { }

- (void)DPSexch { }

- (void)DPSexecstack { }

- (void)DPSexecuteonly { }

- (void)DPSget { }

- (void)DPSgetinterval { }

- (void)DPSindex: (int)i { }

- (void)DPSknown: (int *)b { }

- (void)DPSlength: (int *)len { }

- (void)DPSload { }

- (void)DPSmark { }

- (void)DPSmatrix { }

- (void)DPSmaxlength: (int *)len { }

- (void)DPSnoaccess { }

- (void)DPSnull { }

- (void)DPSpackedarray { }

- (void)DPSpop { }

- (void)DPSput { }

- (void)DPSputinterval { }

- (void)DPSrcheck: (int *)b { }

- (void)DPSreadonly { }

- (void)DPSroll: (int)n : (int)j { }

- (void)DPSscheck: (int *)b { }

- (void)DPSsearch: (int *)b { }

- (void)DPSshareddict { }

- (void)DPSstatusdict { }

- (void)DPSstore { }

- (void)DPSstring: (int)len { }

- (void)DPSstringwidth: (const char *)s : (float *)xp : (float *)yp { }

- (void)DPSsystemdict { }

- (void)DPSuserdict { }

- (void)DPSwcheck: (int *)b { }

- (void)DPSwhere: (int *)b { }

- (void)DPSxcheck: (int *)b { }

@end

@implementation GPSDrawContext (FontOps)

- (void)DPSFontDirectory { }

- (void)DPSISOLatin1Encoding { }

- (void)DPSSharedFontDirectory { }

- (void)DPSStandardEncoding { }

- (void)DPScachestatus: (int *)bsize : (int *)bmax : (int *)msize { }

- (void)DPScurrentcacheparams { }

- (void)DPScurrentfont { }

- (void)DPSdefinefont { }

- (void)DPSfindfont: (const char *)name { }

- (void)DPSmakefont { }

- (void)DPSscalefont: (float)size { }

- (void)DPSselectfont: (const char *)name : (float)scale { }

- (void)DPSsetcachedevice: (float)wx : (float)wy : (float)llx : (float)lly : (float)urx : (float)ury { }

- (void)DPSsetcachelimit: (float)n { }

- (void)DPSsetcacheparams { }

- (void)DPSsetcharwidth: (float)wx : (float)wy { }

- (void)DPSsetfont: (int)f { }

- (void)DPSundefinefont: (const char *)name { }

@end

@implementation GPSDrawContext (GStateOps)

- (void)DPSconcat: (const float *)m { }

- (void)DPScurrentdash { }

- (void)DPScurrentflat: (float *)flatness { }

- (void)DPScurrentgray: (float *)gray { }

- (void)DPScurrentgstate: (int)gst { }

- (void)DPScurrenthalftone { }

- (void)DPScurrenthalftonephase: (float *)x : (float *)y { }

- (void)DPScurrenthsbcolor: (float *)h : (float *)s : (float *)b { }

- (void)DPScurrentlinecap: (int *)linecap { }

- (void)DPScurrentlinejoin: (int *)linejoin { }

- (void)DPScurrentlinewidth: (float *)width { }

- (void)DPScurrentmatrix { }

- (void)DPScurrentmiterlimit: (float *)limit { }

- (void)DPScurrentpoint: (float *)x : (float *)y { }

- (void)DPScurrentrgbcolor: (float *)r : (float *)g : (float *)b { }

- (void)DPScurrentscreen { }

- (void)DPScurrentstrokeadjust: (int *)b { }

- (void)DPScurrenttransfer { }

- (void)DPSdefaultmatrix { }

- (void)DPSgrestore { }

- (void)DPSgrestoreall { }

- (void)DPSgsave { }

- (void)DPSgstate { }

- (void)DPSinitgraphics { }

- (void)DPSinitmatrix { }

- (void)DPSrotate: (float)angle { }

- (void)DPSscale: (float)x : (float)y { }

- (void)DPSsetdash: (const float *)pat : (int)size : (float)offset { }

- (void)DPSsetflat: (float)flatness { }

- (void)DPSsetgray: (float)gray { }

- (void)DPSsetgstate: (int)gst { }

- (void)DPSsethalftone { }

- (void)DPSsethalftonephase: (float)x : (float)y { }

- (void)DPSsethsbcolor: (float)h : (float)s : (float)b { }

- (void)DPSsetlinecap: (int)linecap { }

- (void)DPSsetlinejoin: (int)linejoin { }

- (void)DPSsetlinewidth: (float)width { }

- (void)DPSsetmatrix { }

- (void)DPSsetmiterlimit: (float)limit { }

- (void)DPSsetrgbcolor: (float)r : (float)g : (float)b { }

- (void)DPSsetscreen { }

- (void)DPSsetstrokeadjust: (int)b { }

- (void)DPSsettransfer { }

- (void)DPStranslate: (float)x : (float)y { }

@end

@implementation GPSDrawContext (IOOps)

- (void)DPSequals { }

- (void)DPSequalsequals { }

- (void)DPSbytesavailable: (int *)n { }

- (void)DPSclosefile { }

- (void)DPScurrentfile { }

- (void)DPSdeletefile: (const char *)filename { }

- (void)DPSecho: (int)b { }

- (void)DPSfile: (const char *)name : (const char *)access { }

- (void)DPSfilenameforall { }

- (void)DPSfileposition: (int *)pos { }

- (void)DPSflush { }

- (void)DPSflushfile { }

- (void)DPSprint { }

- (void)DPSprintobject: (int)tag { }

- (void)DPSpstack { }

- (void)DPSread: (int *)b { }

- (void)DPSreadhexstring: (int *)b { }

- (void)DPSreadline: (int *)b { }

- (void)DPSreadstring: (int *)b { }

- (void)DPSrenamefile: (const char *)old : (const char *)new { }

- (void)DPSresetfile { }

- (void)DPSsetfileposition: (int)pos { }

- (void)DPSstack { }

- (void)DPSstatus: (int *)b { }

- (void)DPStoken: (int *)b { }

- (void)DPSwrite { }

- (void)DPSwritehexstring { }

- (void)DPSwriteobject: (int)tag { }

- (void)DPSwritestring { }

@end

@implementation GPSDrawContext (MathOps)

- (void)DPSabs { }

- (void)DPSadd { }

- (void)DPSand { }

- (void)DPSatan { }

- (void)DPSbitshift: (int)shift { }

- (void)DPSceiling { }

- (void)DPScos { }

- (void)DPSdiv { }

- (void)DPSexp { }

- (void)DPSfloor { }

- (void)DPSidiv { }

- (void)DPSln { }

- (void)DPSlog { }

- (void)DPSmod { }

- (void)DPSmul { }

- (void)DPSneg { }

- (void)DPSround { }

- (void)DPSsin { }

- (void)DPSsqrt { }

- (void)DPSsub { }

- (void)DPStruncate { }

- (void)DPSxor { }

@end

@implementation GPSDrawContext (MatrixOps)

- (void)DPSconcatmatrix { }

- (void)DPSdtransform: (float)x1 : (float)y1 : (float *)x2 : (float *)y2 { }

- (void)DPSidentmatrix { }

- (void)DPSidtransform: (float)x1 : (float)y1 : (float *)x2 : (float *)y2 { }

- (void)DPSinvertmatrix { }

- (void)DPSitransform: (float)x1 : (float)y1 : (float *)x2 : (float *)y2 { }

- (void)DPStransform: (float)x1 : (float)y1 : (float *)x2 : (float *)y2 { }

@end

@implementation GPSDrawContext (MiscOps)

- (void)DPSbanddevice { }

- (void)DPSframedevice { }

- (void)DPSnulldevice { }

- (void)DPSrenderbands { }

@end

@implementation GPSDrawContext (Opstack)

- (void)DPSgetboolean: (int *)it { }

- (void)DPSgetchararray: (int)size : (char *)s { }

- (void)DPSgetfloat: (float *)it { }

- (void)DPSgetfloatarray: (int)size : (float *)a { }

- (void)DPSgetint: (int *)it { }

- (void)DPSgetintarray: (int)size : (int *)a { }

- (void)DPSgetstring: (char *)s { }

- (void)DPSsendboolean: (int)it { }

- (void)DPSsendchararray: (const char *)s : (int)size { }

- (void)DPSsendfloat: (float)it { }

- (void)DPSsendfloatarray: (const float *)a : (int)size { }

- (void)DPSsendint: (int)it { }

- (void)DPSsendintarray: (const int *)a : (int)size { }

- (void)DPSsendstring: (const char *)s { }

@end

@implementation GPSDrawContext (PaintOps)

- (void)DPSashow: (float)x : (float)y : (const char *)s { }

- (void)DPSawidthshow: (float)cx : (float)cy : (int)c : (float)ax : (float)ay : (const char *)s { }

- (void)DPScopypage { }

- (void)DPSeofill { }

- (void)DPSerasepage { }

- (void)DPSfill { }

- (void)DPSimage { }

- (void)DPSimagemask { }

- (void)DPSkshow: (const char *)s { }

- (void)DPSrectfill: (float)x : (float)y : (float)w : (float)h { }

- (void)DPSrectstroke: (float)x : (float)y : (float)w : (float)h { }

- (void)DPSshow: (const char *)s { }

- (void)DPSshowpage { }

- (void)DPSstroke { }

- (void)DPSstrokepath { }

- (void)DPSueofill: (const char *)nums : (int)n : (const char *)ops : (int)l { }

- (void)DPSufill: (const char *)nums : (int)n : (const char *)ops : (int)l { }

- (void)DPSustroke: (const char *)nums : (int)n : (const char *)ops : (int)l { }

- (void)DPSustrokepath: (const char *)nums : (int)n : (const char *)ops : (int)l { }

- (void)DPSwidthshow: (float)x : (float)y : (int)c : (const char *)s { }

- (void)DPSxshow: (const char *)s : (const float *)numarray : (int)size { }

- (void)DPSxyshow: (const char *)s : (const float *)numarray : (int)size { }

- (void)DPSyshow: (const char *)s : (const float *)numarray : (int)size { }

@end

@implementation GPSDrawContext (PathOps)

- (void)DPSarc: (float)x : (float)y : (float)r : (float)angle1 : (float)angle2 { }

- (void)DPSarcn: (float)x : (float)y : (float)r : (float)angle1 : (float)angle2 { }

- (void)DPSarct: (float)x1 : (float)y1 : (float)x2 : (float)y2 : (float)r { }

- (void)DPSarcto: (float)x1 : (float)y1 : (float)x2 : (float)y2 : (float)r : (float *)xt1 : (float *)yt1 : (float *)xt2 : (float *)yt2 { }

- (void)DPScharpath: (const char *)s : (int)b { }

- (void)DPSclip { }

- (void)DPSclippath { }

- (void)DPSclosepath { }

- (void)DPScurveto: (float)x1 : (float)y1 : (float)x2 : (float)y2 : (float)x3 : (float)y3 { }

- (void)DPSeoclip { }

- (void)DPSeoviewclip { }

- (void)DPSflattenpath { }

- (void)DPSinitclip { }

- (void)DPSinitviewclip { }

- (void)DPSlineto: (float)x : (float)y { }

- (void)DPSmoveto: (float)x : (float)y { }

- (void)DPSnewpath { }

- (void)DPSpathbbox: (float *)llx : (float *)lly : (float *)urx : (float *)ury { }

- (void)DPSpathforall { }

- (void)DPSrcurveto: (float)x1 : (float)y1 : (float)x2 : (float)y2 : (float)x3 : (float)y3 { }

- (void)DPSrectclip: (float)x : (float)y : (float)w : (float)h { }

- (void)DPSrectviewclip: (float)x : (float)y : (float)w : (float)h { }

- (void)DPSreversepath { }

- (void)DPSrlineto: (float)x : (float)y { }

- (void)DPSrmoveto: (float)x : (float)y { }

- (void)DPSsetbbox: (float)llx : (float)lly : (float)urx : (float)ury { }

- (void)DPSsetucacheparams { }

- (void)DPSuappend: (const char *)nums : (int)n : (const char *)ops : (int)l { }

- (void)DPSucache { }

- (void)DPSucachestatus { }

- (void)DPSupath: (int)b { }

- (void)DPSviewclip { }

- (void)DPSviewclippath { }

@end

@implementation GPSDrawContext (SysOps)

- (void)DPSbind { }

- (void)DPScountdictstack: (int *)n { }

- (void)DPScountexecstack: (int *)n { }

- (void)DPScurrentdict { }

- (void)DPScurrentpacking: (int *)b { }

- (void)DPScurrentshared: (int *)b { }

- (void)DPSdeviceinfo { }

- (void)DPSerrordict { }

- (void)DPSexec { }

- (void)DPSprompt { }

- (void)DPSquit { }

- (void)DPSrand { }

- (void)DPSrealtime: (int *)i { }

- (void)DPSrestore { }

- (void)DPSrrand { }

- (void)DPSrun: (const char *)filename { }

- (void)DPSsave { }

- (void)DPSsetpacking: (int)b { }

- (void)DPSsetshared: (int)b { }

- (void)DPSsrand { }

- (void)DPSstart { }

- (void)DPStype { }

- (void)DPSundef: (const char *)name { }

- (void)DPSusertime: (int *)milliseconds { }

- (void)DPSversion: (int)bufsize : (char *)buf { }

- (void)DPSvmreclaim: (int)code { }

- (void)DPSvmstatus: (int *)level : (int *)used : (int *)maximum { }

@end

@implementation GPSDrawContext (WinOps)

- (void)DPSineofill: (float)x : (float)y : (int *)b { }

- (void)DPSinfill: (float)x : (float)y : (int *)b { }

- (void)DPSinstroke: (float)x : (float)y : (int *)b { }

- (void)DPSinueofill: (float)x : (float)y : (const char *)nums : (int)n : (const char *)ops : (int)l : (int *)b { }

- (void)DPSinufill: (float)x : (float)y : (const char *)nums : (int)n : (const char *)ops : (int)l : (int *)b { }

- (void)DPSinustroke: (float)x : (float)y : (const char *)nums : (int)n  : (const char *)ops : (int)l : (int *)b { }

- (void)DPSwtranslation: (float *)x : (float *)y { }

@end

@implementation GPSDrawContext (L2Ops)

- (void)DPSleftbracket { }

- (void)DPSrightbracket { }

- (void)DPSleftleft { }

- (void)DPSrightright { }

- (void)DPScshow: (const char *)s { }

- (void)DPScurrentcolor { }

- (void)DPScurrentcolorrendering { }

- (void)DPScurrentcolorspace { }

- (void)DPScurrentdevparams: (const char *)dev { }

- (void)DPScurrentglobal: (int *)b { }

- (void)DPScurrentoverprint: (int *)b { }

- (void)DPScurrentpagedevice { }

- (void)DPScurrentsystemparams { }

- (void)DPScurrentuserparams { }

- (void)DPSdefineresource: (const char *)category { }

- (void)DPSexecform { }

- (void)DPSfilter { }

- (void)DPSfindencoding: (const char *)key { }

- (void)DPSfindresource: (const char *)key : (const char *)category { }

- (void)DPSgcheck: (int *)b { }

- (void)DPSglobaldict { }

- (void)DPSGlobalFontDirectory { }

- (void)DPSglyphshow: (const char *)name { }

- (void)DPSlanguagelevel: (int *)n { }

- (void)DPSmakepattern { }

- (void)DPSproduct { }

- (void)DPSresourceforall: (const char *)category { }

- (void)DPSresourcestatus: (const char *)key : (const char *)category : (int *)b { }

- (void)DPSrevision: (int *)n { }

- (void)DPSrootfont { }

- (void)DPSserialnumber: (int *)n { }

- (void)DPSsetcolor { }

- (void)DPSsetcolorrendering { }

- (void)DPSsetcolorspace { }

- (void)DPSsetdevparams { }

- (void)DPSsetglobal: (int)b { }

- (void)DPSsetoverprint: (int)b { }

- (void)DPSsetpagedevice { }

- (void)DPSsetpattern: (int)patternDict { }

- (void)DPSsetsystemparams { }

- (void)DPSsetuserparams { }

- (void)DPSstartjob: (int)b : (const char *)password { }

- (void)DPSundefineresource: (const char *)key : (const char *)category { }

@end

@implementation GPSDrawContext (X11Ops)

- (void) DPScurrentXdrawingfunction: (int *)function { }

- (void) DPScurrentXgcdrawable: (int *)gc : (int *)draw : (int *)x : (int *)y { }

- (void) DPScurrentXgcdrawablecolor: (int *)gc : (int *)draw : (int *)x 
				  : (int *)y : (int *)colorInfo { }

- (void) DPScurrentXoffset: (int *)x : (int *)y { }

- (void) DPSsetXdrawingfunction: (int) function { }

- (void) DPSsetXgcdrawable: (int)gc : (int)draw : (int)x : (int)y { }

- (void) DPSsetXgcdrawablecolor: (int)gc : (int)draw : (int)x : (int)y
				  : (const int *)colorInfo { }

- (void) DPSsetXoffset: (short int)x : (short int)y { }

- (void) DPSsetXrgbactual: (double)r : (double)g : (double)b : (int *)success { }

@end


