/* gsnd

   GNUstep sound server

   Copyright (C) 2002 Free Software Foundation, Inc.

   Author:  Enrico Sersale <enrico@imago.ro>
   Date: August 2002

   This file is part of the GNUstep Project

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; either version 2
   of the License, or (at your option) any later version.

   You should have received a copy of the GNU General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/

#include <Foundation/Foundation.h>
#include "portaudio/pa_common/portaudio.h"
#include <math.h>
#include <unistd.h>
#include <fcntl.h>

#ifdef __MINGW__
#include "process.h"
#endif

#ifdef	HAVE_SYSLOG_H
#include <syslog.h>
#endif

#define	GSNDNAME @"GNUstepGSSoundServer"
#define FRAME_SIZE 4
#define BUFFER_SIZE_IN_FRAMES (1024 * FRAME_SIZE)  
#define CHUNK_LENGTH (BUFFER_SIZE_IN_FRAMES * 4)
#define DEFAULT_CHANNELS 2
#define PLAY_RATE (44100)
#define CACHE_SIZE 4194304

/* Conversion constants */
#define Nhc       8
#define Na        7
#define Np       (Nhc + Na)
#define Npc      (1 << Nhc)
#define Amask    ((1 << Na) - 1)
#define Pmask    ((1 << Np) - 1)
#define Nh       16
#define Nb       16
#define Nhxn     14
#define Nhg      (Nh - Nhxn)
#define NLpScl   13

#ifndef INT16_MAX
	#define INT16_MAX (32767)
	#define INT16_MIN (-32767-1)
#endif

#define IBUFFSIZE 4096

#define CLAMP(x, low, high) \
(((x) > (high)) ? (high) : (((x) < (low)) ? (low) : (x)))

static int	is_daemon = 0;		/* Currently running as daemon.	 */

static short **sX;
static short **sY;
static unsigned int sTime;
static double sfactor;
static BOOL sinitial;

void clearResamplerMemory();
void initializeResampler(double fac);
int resample(int inCount, int outCount, short inArray[], short outArray[]);
int resampleFast(int inCount, int outCount, short inArray[], short outArray[]);
int SrcLinear(short X[], short Y[], double factor, unsigned int *Time, 
																				unsigned short Nx, unsigned short Nout);
inline short WordToHword(int v, int scl);
int resamplerReadData(int inCount, short inArray[], short *outPtr[], 
															int dataArraySize, int Xoff, BOOL init_count);
int resampleError(char *s);
		
static char	ebuf[2048];

#ifdef HAVE_SYSLOG

static int	log_priority;

static void
gsnd_log (int prio)
{
  if (is_daemon)
    {
      syslog (log_priority | prio, ebuf);
    }
  else if (prio == LOG_INFO)
    {
      write (1, ebuf, strlen (ebuf));
      write (1, "\n", 1);
    }
  else
    {
      write (2, ebuf, strlen (ebuf));
      write (2, "\n", 1);
    }

  if (prio == LOG_CRIT)
    {
      if (is_daemon)
	{
	  syslog (LOG_CRIT, "exiting.");
	}
      else
     	{
	  fprintf (stderr, "exiting.\n");
	  fflush (stderr);
	}
      exit(EXIT_FAILURE);
    }
}
#else

#define	LOG_CRIT	2
#define LOG_DEBUG	0
#define LOG_ERR		1
#define LOG_INFO	0
#define LOG_WARNING	0
void
gsnd_log (int prio)
{
  write (2, ebuf, strlen (ebuf));
  write (2, "\n", 1);
  if (prio == LOG_CRIT)
    {
      fprintf (stderr, "exiting.\n");
      fflush (stderr);
      exit(EXIT_FAILURE);
    }
}
#endif

@protocol GSSndObj

- (void)setIdentifier:(NSString *)identifier;
- (NSString *)identifier;
- (NSString *)name;
- (float)samplingRate;
- (long)frameCount;
- (NSData *)data;

@end 

@interface Snd : NSObject <NSCopying>
{
	NSString *name;
	NSString *identifier;
	long frameCount;
	float rate;
	
	long startPos;
	long endPos;
	long posInBytes;
	
	BOOL playing;
	BOOL paused;
	
	NSMutableData *data;
}

- (id)initWithNSSoundObject:(id<GSSndObj>)anobject; 

- (void)setIdentifier:(NSString *)identstr;

- (void)resampleWithFactor:(float)factor;

- (void)reset;

- (NSData *)data;

- (NSData *)remainingData;

- (void)setStartPos:(long)p;

- (void)setEndPos:(long)p;

- (void)setPlaying:(BOOL)value;

- (void)setPaused:(BOOL)value;

- (NSString *)name;

- (NSString *)identifier;

- (long)frameCount;

- (float)rate;

- (long)startPos;

- (long)endPos;

- (long)posInBytes;

- (void)posInBytesAdd;

- (BOOL)isPlaying;

- (BOOL)isPaused;

@end

@interface SoundServer : NSObject 
{
	NSMutableData *soundData;
	NSMutableArray *sounds;
	long maxCacheSize;
	long frameCount;
		
	long position;
	long posInBytes;
	
	BOOL isPlaying;	
	
	NSConnection *conn;
	NSNotificationCenter *nc;
}

- (BOOL)playSound:(id)aSound;

- (BOOL)stopSoundWithIdentifier:(NSString *)identifier;

- (BOOL)pauseSoundWithIdentifier:(NSString *)identifier;

- (BOOL)resumeSoundWithIdentifier:(NSString *)identifier;

- (BOOL)isPlayingSoundWithIdentifier:(NSString *)identifier;

- (void)play;

- (void)mixWithSound:(Snd *)snd;

- (void)unMixSound:(Snd *)snd;

- (void)updatePosition;

- (void)stopAll;

- (void)checkIsPlaying;

- (Snd *)cachedSoundWithName:(NSString *)aName;

- (void)checkCachedSounds;

- (Snd *)soundWithIdentifier:(NSString *)identifier;

- (Snd *)soundWithName:(NSString *)aName identifier:(NSString *)ident;

- (NSString *)uniqueSoundIdentifier;

- (BOOL)connection:(NSConnection*)ancestor
  				shouldMakeNewConnection:(NSConnection*)newConn;

- (id)connectionBecameInvalid:(NSNotification*)notification;

@end


SoundServer *gsnd = nil;
PortAudioStream *pStream = NULL;

struct SoundServer_t {
	@defs(SoundServer)
} *serverPtr;


@implementation Snd

- (void)dealloc
{
  RELEASE (name);
  TEST_RELEASE (identifier);
  RELEASE (data);
  [super dealloc];
}
	
- (id)initWithNSSoundObject:(id<GSSndObj>)anobject
{
  self = [super init];
	
  if (self) 
    {	
      ASSIGN (name, [anobject name]);
      ASSIGN (identifier, [anobject identifier]);		
      data = [[anobject data] mutableCopy];
      frameCount = [anobject frameCount];
      rate = [anobject samplingRate];
      startPos = 0;
      endPos = 0;
      posInBytes = 0;
      playing = NO;
      paused = NO;
					
      [self resampleWithFactor: (PLAY_RATE / rate)];
    }
	
  return self;
}

- (void)setIdentifier:(NSString *)identstr
{
  ASSIGN (identifier, identstr);	
}

- (void)resampleWithFactor:(float)factor
{
  gss16 *outbuff;
  int extra_sample;
  long out_count;
  float out_length;
	
  rate *= factor;
	
  if (factor <= 1.0) {
    extra_sample = 50;
  } else {
    extra_sample = (int)factor + 50;
  }
		
  out_count = (long)ceil((frameCount) * factor) + extra_sample;	
  out_length = out_count * FRAME_SIZE;
	
  outbuff = NSZoneMalloc(NSDefaultMallocZone(), GS_SIZEOF_SHORT * out_length);

  initializeResampler(factor);
  resample(frameCount, out_count, (gss16 *)[data bytes], outbuff);

  TEST_RELEASE (data);
  data = [[NSMutableData alloc] initWithCapacity: 1];
		
  [data appendBytes: (const void *)outbuff 
	length: out_length];

  NSZoneFree(NSDefaultMallocZone(), outbuff);
  clearResamplerMemory();
	
  frameCount = (long)([data length] / FRAME_SIZE);	
}

- (void)reset
{
  startPos = 0;
  endPos = 0;
  posInBytes = 0;	
  playing = NO;
  paused = NO;
  DESTROY (identifier);
}

- (NSData *)data
{
  return data;
}

- (NSData *)remainingData
{
  long start = (long)(posInBytes * FRAME_SIZE);
  long length = (long)([data length] - start);		
  return [data subdataWithRange: NSMakeRange(start, length)];
}

- (void)setStartPos:(long)p
{
  startPos = p;
}

- (void)setEndPos:(long)p
{
  endPos = p;
}

- (void)setPlaying:(BOOL)value
{
  playing = value;
}

- (void)setPaused:(BOOL)value
{
  paused = value;
}
				
- (NSString *)name
{
  return name;
}

- (NSString *)identifier
{
  return identifier;
}

- (long)frameCount
{
  return frameCount;
}

- (float)rate
{
  return rate;
}

- (long)startPos
{
  return startPos;
}

- (long)endPos
{
  return endPos;
}

- (long)posInBytes
{
  return posInBytes;
}

- (void)posInBytesAdd
{
  posInBytes++;
}

- (BOOL)isPlaying
{
  return playing;
}

- (BOOL)isPaused
{
  return paused;
}

- (id)copyWithZone:(NSZone *)zone
{
  Snd *snd = (Snd *)NSCopyObject(self, 0, zone);

  snd->name = [name copy];		
  snd->identifier = nil;			
  snd->frameCount = frameCount;
  snd->rate = rate;
  snd->startPos = 0;
  snd->endPos = 0;
  snd->posInBytes = 0;
  snd->playing = NO;
  snd->paused = NO;
  snd->data = [data mutableCopy];		

  return snd;
}

@end


@implementation SoundServer

static int paCallback(void *inputBuffer,
                      void *outputBuffer,
		      unsigned long framesPerBuffer,
		      PaTimestamp outTime,
                      void *userData)
{
  NSData *data;
  long length;	
  int chunkLength;
  int retvalue;
  void *buffer[CHUNK_LENGTH];
  gss16 *in;
  int i;
	
  CREATE_AUTORELEASE_POOL(pool);										
								
  data = serverPtr->soundData;
  length = [data length];	
		
  if ((serverPtr->position + CHUNK_LENGTH) < length) {
    chunkLength = CHUNK_LENGTH;
    retvalue = 0;
  } else {	
    chunkLength = length - serverPtr->position;
    retvalue = 1;
  }

  [data getBytes: &buffer range: NSMakeRange(serverPtr->position, chunkLength)];
  in = (gss16 *)buffer;	
	
  for(i = 0; i < framesPerBuffer; i++) {	 
    ((gss16 *)outputBuffer)[i * 2] = in[i * 2];
    ((gss16 *)outputBuffer)[i * 2 + 1] = in[i * 2 + 1];
    [(SoundServer *)serverPtr updatePosition];
  }

  if (retvalue == 1) {
    PaError err;
				
    err = Pa_CloseStream(pStream);
    if (err != paNoError) {
      NSLog(@"PortAudio Pa_CloseStream error: %s", Pa_GetErrorText(err));			
    }
		
    err = Pa_Terminate();	
    if (err != paNoError) {
      NSLog(@"PortAudio Pa_Terminate error: %s", Pa_GetErrorText(err));			
    }
		
    [(SoundServer *)serverPtr stopAll];
  }

  serverPtr->isPlaying = !retvalue;
	
  RELEASE (pool);
	
  return retvalue;
}

- (void)dealloc
{
  [nc removeObserver: self];
  RELEASE (sounds);
  RELEASE (soundData);
  [super dealloc];
}

- (id)init
{
  self = [super init];

  if (self) {
    NSString *hostname;
    NSNumber *csize;

    serverPtr = (struct SoundServer_t *)self;		
    nc = [NSNotificationCenter defaultCenter];

    csize = [[NSUserDefaults standardUserDefaults] objectForKey: @"cachesize"];			
    maxCacheSize = csize ? [csize longValue] : CACHE_SIZE;					

    sounds = [[NSMutableArray alloc] initWithCapacity: 1];
    soundData = [[NSMutableData alloc] initWithCapacity: 1];
    frameCount = 0;
    position = 0;
    posInBytes = 0;
    isPlaying = NO;		

    conn = [NSConnection defaultConnection];
    [conn setRootObject: self];
    [conn setDelegate: self];
    [nc addObserver: self
	selector: @selector(connectionBecameInvalid:)
	name: NSConnectionDidDieNotification object: (id)conn];

    hostname = [[NSUserDefaults standardUserDefaults] stringForKey: @"NSHost"];
    if ([hostname length] == 0
    	|| [[NSHost hostWithName: hostname] isEqual: [NSHost currentHost]] == YES) {
      if ([conn registerName: GSNDNAME] == NO) {
	NSLog(@"Unable to register with name server.\n");
	exit(1);
      }
    } else {
      NSHost *host = [NSHost hostWithName: hostname];
      NSPort *port = [conn receivePort];
      NSPortNameServer *ns = [NSPortNameServer systemDefaultPortNameServer];
      NSArray *a;
      unsigned c;

      if (host == nil) {
	NSLog(@"gsnd - unknown NSHost argument  ... %@ - quiting.", hostname);
	exit(1);
      }

      a = [host names];
      c = [a count];
      while (c-- > 0) {
	NSString *name = [a objectAtIndex: c];

	name = [GSNDNAME stringByAppendingFormat: @"-%@", name];
	if ([ns registerPort: port forName: name] == NO) {
	}
      }

      a = [host addresses];
      c = [a count];
      while (c-- > 0) {
	NSString *name = [a objectAtIndex: c];

	name = [GSNDNAME stringByAppendingFormat: @"-%@", name];
	if ([ns registerPort: port forName: name] == NO) {
	}
      }
    }
  }
		
  return self;
}

- (BOOL)playSound:(id)aSound
{
  id<GSSndObj> obj;
  NSString *soundName;
  NSString *idendstr;	
  Snd *snd = nil;

  [self checkCachedSounds];
		
  obj = (id<GSSndObj>)aSound;	
  soundName = [obj name];
  idendstr = [obj identifier];	
	
  if (idendstr == nil) {
    idendstr = [self uniqueSoundIdentifier];
    [obj setIdentifier: idendstr]; 
  } else {		
    snd = [self soundWithIdentifier: idendstr];

    if ((snd != nil) && (([snd isPlaying]) || ([snd isPaused]))) {
      return NO;
    }
  }
	
  if (snd == nil) {	
    snd = [self cachedSoundWithName: soundName];

    if (snd == nil) {
      snd = [[Snd alloc] initWithNSSoundObject: obj];
      [sounds addObject: snd];	
      RELEASE (snd);
    } else {		
      if ([snd isPlaying] || [snd isPaused]) {
	snd = [snd copy];
	[sounds addObject: snd];
	RELEASE (snd);
      }					
      [snd reset];
      [snd setIdentifier: idendstr];					
    }
  }				
	
  if (isPlaying == NO) {
    frameCount = [snd frameCount];			
    TEST_RELEASE (soundData);
    soundData = [[snd data] mutableCopy];
    isPlaying = YES;	
		
    [snd setStartPos: 0];
    [snd setEndPos: (long)([soundData length] / FRAME_SIZE)];
    [snd setPlaying: YES];
			
    [self play];
		
  } else {
    [self mixWithSound: snd];
  }
	
  return YES;
}

- (BOOL)stopSoundWithIdentifier:(NSString *)identifier
{
  Snd *snd = [self soundWithIdentifier: identifier];
		
  if (snd && [snd isPlaying]) {
    [self unMixSound: snd];
    [snd reset];
    [self checkIsPlaying];
    return YES;
  }		

  return NO;
}

- (BOOL)pauseSoundWithIdentifier:(NSString *)identifier
{
  Snd *snd = [self soundWithIdentifier: identifier];
		
  if (snd && [snd isPlaying]) {
    [self unMixSound: snd];

    [snd setPlaying: NO];
    [snd setPaused: YES];
    [snd setStartPos: 0];
    [snd setEndPos: 0];
		
    [self checkIsPlaying];
    return YES;
  }		

  return NO;
}

- (BOOL)resumeSoundWithIdentifier:(NSString *)identifier
{
  Snd *snd = [self soundWithIdentifier: identifier];
		
  if (snd  && [snd isPaused]) {
    if (isPlaying == NO) {
      TEST_RELEASE (soundData);
      soundData = [[snd remainingData] mutableCopy];

      frameCount = (long)([soundData length] / FRAME_SIZE);

      [snd setStartPos: 0];
      [snd setEndPos: (long)([soundData length] / FRAME_SIZE)];	
      [snd setPaused: NO];
      [snd setPlaying: YES];
			
      isPlaying = YES;	
      [self play];
						
    } else {
      [snd setPlaying: YES];
      [snd setPaused: NO];
      [self mixWithSound: snd];
    }
		
    return YES;
  }		

  return NO;
}

- (BOOL)isPlayingSoundWithIdentifier:(NSString *)identifier
{
  Snd *snd = [self soundWithIdentifier: identifier];
		
  if (snd) {
    return [snd isPlaying];
  }		

  return NO;
}

- (void)play
{
  PaError err;
  int d = 0;
		
  err = Pa_Initialize();
  if(err != paNoError) {
    NSLog(@"PortAudio error: %s", Pa_GetErrorText(err));
  } else {
    NSLog(@"Pa_Initialize");
  }

  err = Pa_OpenDefaultStream(&pStream, 0, DEFAULT_CHANNELS, paInt16, 
			     PLAY_RATE, BUFFER_SIZE_IN_FRAMES, 0, paCallback, &d);

  if(err != paNoError) {
    NSLog(@"PortAudio Pa_OpenDefaultStream error: %s", Pa_GetErrorText(err));
  } else {
    NSLog(@"Pa_OpenDefaultStream");
  }

  err = Pa_StartStream(pStream);
  if(err != paNoError) {
    NSLog(@"PortAudio Pa_StartStream error: %s", Pa_GetErrorText(err));
  } else {
    NSLog(@"Pa_StartStream");
  }

  Pa_Sleep(2);
}

- (void)mixWithSound:(Snd *)snd
{
  if (isPlaying == NO) {
    return;
		
  } else {
    NSData *snddata = [snd remainingData];
    long inFrameCount = (long)([snddata length] / FRAME_SIZE); 
    gss16 *in = (gss16 *)[snddata bytes];		
    gss16 *out = (gss16 *)[soundData mutableBytes];
    gss32 sum_l;
    gss32 sum_r;	
    long inPos;
    int i, j;

    [snd setStartPos: posInBytes + [snd posInBytes]];
    [snd setEndPos: posInBytes + (long)([snddata length] / FRAME_SIZE)];

    j = 0;	
    for (i = posInBytes; i < frameCount; i++) {
      sum_l = out[i * 2] + in[j * 2];
      sum_r = out[i * 2 + 1] + in[j * 2 + 1];

      out[i * 2] = CLAMP (sum_l, INT16_MIN, INT16_MAX);
      out[i * 2 + 1] = CLAMP (sum_r, INT16_MIN, INT16_MAX);
									
      j++;
      if (j == inFrameCount) {
	break;
      }
    }

    inPos = (j * FRAME_SIZE);	
    if (inPos < ([snddata length] - 1)) {
      long remLength = [snddata length] - inPos;
      NSRange range = NSMakeRange(inPos, remLength);

      [soundData appendData: [snddata subdataWithRange: range]];		
      frameCount = (long)([soundData length] / FRAME_SIZE);
    }	

    [snd setPlaying: YES];
  }
}

- (void)unMixSound:(Snd *)snd
{
  if (isPlaying == NO) {
    return;
		
  } else {
    int *in = (int *)[[snd data] bytes];		
    int *out = (int *)[soundData mutableBytes];
    long deleteFrom = [snd startPos] + [snd posInBytes];
    long deleteTo = [snd endPos];	
    int i, j;

    j = [snd posInBytes];	
    for (i = deleteFrom; i < frameCount; i++) {
      out[i] -= in[j]; 				
      j++;
      if (j == deleteTo) {
	break;
      }
    }
  }
}

- (void)updatePosition
{
  int i;

  posInBytes++;
  position = (long)(posInBytes * FRAME_SIZE);		
	
  for (i = 0; i < [sounds count]; i++) {
    Snd *snd = [sounds objectAtIndex: i];
	
    if ([snd isPlaying]) {		
      [snd posInBytesAdd];
			
      if (posInBytes == [snd endPos]) {
	[snd reset];
      }
    }
  }
}

- (void)stopAll
{
  int i;
	
  [self checkCachedSounds];
	
  for (i = 0; i < [sounds count]; i++) {
    Snd *snd = [sounds objectAtIndex: i];
		
    if ([snd isPaused]) {		
      [snd setStartPos: 0];
      [snd setEndPos: 0];			
    } else {
      [snd reset];
    }
  }
	
  TEST_RELEASE (soundData);
  soundData = [[NSMutableData alloc] initWithCapacity: 1];
  frameCount = 0;
  position = 0;
  posInBytes = 0;
  isPlaying = NO;			
}

- (void)checkIsPlaying
{
  int i;
  BOOL found = NO;
	
  for (i = 0; i < [sounds count]; i++) {
    Snd *snd = [sounds objectAtIndex: i];
		
    if ([snd isPlaying]) {		
      found = YES;
      break;
    } 
  }

  if (found == NO) {
    [self stopAll];
  }
}

- (Snd *)cachedSoundWithName:(NSString *)aName
{
  int i;
			
  for (i = 0; i < [sounds count]; i++) {
    Snd *snd = [sounds objectAtIndex: i];	
    if ([[snd name] isEqual: aName]) {
      return snd;
    }
  }

  return nil;
}

- (void)checkCachedSounds
{
  int i, j, count;
  long csize = 0;
	
  count = [sounds count];
	
  for (i = 0; i < count; i++) {
    Snd *snd0 = [sounds objectAtIndex: i];
    NSString *name = [snd0 name];
	
    for (j = 0; j < count; j++) {
      Snd *snd1 = [sounds objectAtIndex: j];
	
      if (([[snd1 name] isEqual: name]) && (snd0 != snd1)) {			
	if (([snd1 isPaused] == NO) && ([snd1 isPlaying] == NO)) {
	  [sounds removeObject: snd1];	
	  count--;
	  i--;
	  j--;
	}
      }
    }
  }
	
  count = [sounds count];
	
  for (i = 0; i < count; i++) {
    csize += [[[sounds objectAtIndex: i] data] length];
  }

  if (csize > maxCacheSize) {		
    for (i = 0; i < count; i++) {
      Snd *snd = [sounds objectAtIndex: i];		
	
      if (([snd isPlaying] == NO) && ([snd isPaused] == NO)) {
	csize -= [[snd data] length];	
	[sounds removeObject: snd];	
	count--;
	i--;
      }		
      if (csize <= maxCacheSize) {
	break;
      }
    }
  }	
}

- (Snd *)soundWithIdentifier:(NSString *)identifier
{
  int i;
		
  for (i = 0; i < [sounds count]; i++) {
    Snd *snd = [sounds objectAtIndex: i];

    if ([[snd identifier] isEqual: identifier]) {
      return snd;
    }		
  }

  return nil;
}

- (Snd *)soundWithName:(NSString *)aName identifier:(NSString *)ident
{
  int i;
		
  for (i = 0; i < [sounds count]; i++) {
    Snd *snd = [sounds objectAtIndex: i];

    if ([[snd identifier] isEqual: ident]) {
      NSString *sname = [snd name];
				
      if ([sname isEqual: aName]) {
	return snd;
      }
    }		
  }

  return nil;
}

- (NSString *)uniqueSoundIdentifier
{
  int identifier = [[NSProcessInfo processInfo] processIdentifier];
  NSString *identstr = [NSString stringWithFormat: @"sound_%i_%i", identifier, random()];

  return identstr;
}

- (BOOL)connection:(NSConnection*)ancestor
shouldMakeNewConnection:(NSConnection*)newConn;
{
  [nc addObserver: self
      selector: @selector(connectionBecameInvalid:)
      name: NSConnectionDidDieNotification
      object: newConn];

  [newConn setDelegate: self];

  return YES;
}

- (id)connectionBecameInvalid:(NSNotification*)notification
{
  id connection = [notification object];

  if (connection == conn) {
    NSLog(@"Help - sound server connection has died!\n");
    exit(1);
  }

  return self;
}

@end

int 
main(int argc, char** argv, char **env)
{
  int c;
  CREATE_AUTORELEASE_POOL(pool);

#ifdef GS_PASS_ARGUMENTS
  [NSProcessInfo initializeWithArguments: argv count: argc environment: env];
#endif

#ifdef __MINGW__
  {
    char **a = malloc((argc+2) * sizeof(char*));

    memcpy(a, argv, argc * sizeof(char*));
    a[argc] = "--no-fork";
    a[argc+1] = 0;
    if (_spawnv(_P_NOWAIT, argv[0], a) == -1) {
      fprintf(stderr, "gsnd - spawn failed - bye.\n");
      exit(1);
    }
    exit(0);
  }
#else
  is_daemon = 1;
  switch (fork()) {
  case -1:
    NSLog(@"gsnd - fork failed - bye.\n");
    exit(1);

  case 0:
#ifdef NeXT
    setpgrp(0, getpid());
#else
    setsid();
#endif
    break;

  default:
    exit(0);
  }

  /*
   *	Ensure we don't have any open file descriptors which may refer
   *	to sockets bound to ports we may try to use.
   *
   *	Use '/dev/null' for stdin and stdout.  Assume stderr is ok.
   */
  for (c = 0; c < FD_SETSIZE; c++)
    {
      if (is_daemon || (c != 2))
	{
	  (void)close(c);
	}
    }
  if (open("/dev/null", O_RDONLY) != 0)
    {
      sprintf(ebuf, "failed to open stdin from /dev/null (%s)\n",
	      strerror(errno));
      gsnd_log(LOG_CRIT);
      exit(EXIT_FAILURE);
    }
  if (open("/dev/null", O_WRONLY) != 1)
    {
      sprintf(ebuf, "failed to open stdout from /dev/null (%s)\n",
	      strerror(errno));
      gsnd_log(LOG_CRIT);
      exit(EXIT_FAILURE);
    }
  if (is_daemon && open("/dev/null", O_WRONLY) != 2)
    {
      sprintf(ebuf, "failed to open stderr from /dev/null (%s)\n",
	      strerror(errno));
      gsnd_log(LOG_CRIT);
      exit(EXIT_FAILURE);
    }
#endif 

  gsnd = [[SoundServer alloc] init];

  if (gsnd == nil) 
    {
      NSLog(@"Unable to create gsnd object.\n");
      exit(1);
    }
	
  [[NSRunLoop currentRunLoop] run];
  RELEASE(pool);
  exit(0);
}



//
// Resampler Functions
//

void 
clearResamplerMemory()
{
  int i;

  if (sX != NULL) 
    {
      for (i = 0; i < DEFAULT_CHANNELS; i++) 
	{
	  NSZoneFree(NSDefaultMallocZone(), sX[i]);
	  sX[i] = NULL;
	  NSZoneFree(NSDefaultMallocZone(), sY[i]);		
	  sY[i] = NULL;
	}
      NSZoneFree(NSDefaultMallocZone(), sX);
      sX = NULL;
      NSZoneFree(NSDefaultMallocZone(), sY);		
      sY = NULL;
    }
}

void 
initializeResampler(double fac)
{
  int i;

  clearResamplerMemory();

  sfactor = fac;
  sinitial = YES;

  // Allocate all new memory
  sX = NSZoneMalloc(NSDefaultMallocZone(), GS_SIZEOF_SHORT * DEFAULT_CHANNELS);
  sY = NSZoneMalloc(NSDefaultMallocZone(), GS_SIZEOF_SHORT * DEFAULT_CHANNELS);

  for (i = 0; i < DEFAULT_CHANNELS; i++) 
    {
      // Add extra to allow of offset of input data (Xoff in main routine)
      sX[i] = NSZoneMalloc(NSDefaultMallocZone(), GS_SIZEOF_SHORT * (IBUFFSIZE + 256));
      sY[i] = NSZoneMalloc(NSDefaultMallocZone(), GS_SIZEOF_SHORT * (int)(((double)IBUFFSIZE) * sfactor));
      memset(sX[i], 0, GS_SIZEOF_SHORT * (IBUFFSIZE + 256));    
    }
}

int 
resample(int inCount, int outCount, short inArray[], short outArray[])
{
  int Ycount = resampleFast(inCount, outCount, inArray, outArray);
  sinitial = NO;
  return Ycount;
}

int resampleFast(int inCount, int outCount, short inArray[], short outArray[])
{
  unsigned int Time2;		/* Current time/pos in input sample */
  unsigned short Xp, Xread;
  int OBUFFSIZE = (int)(((double)IBUFFSIZE) * sfactor);
  unsigned short Nout = 0, Nx, orig_Nx;
  unsigned short maxOutput;
  int total_inCount = 0;
  int c, i, Ycount, last;
  BOOL first_pass = YES;
  unsigned short Xoff = 10;

  Nx = IBUFFSIZE - 2 * Xoff;     /* # of samples to process each iteration */
  last = 0;			/* Have not read last input sample yet */
  Ycount = 0;			/* Current sample and length of output file */

  Xp = Xoff;			/* Current "now"-sample pointer for input */
  Xread = Xoff;		/* Position in input array to read into */

  if (sinitial == YES) 
    {
      sTime = (Xoff << Np);	/* Current-time pointer for converter */
    }
	
  do 
    {
      if (!last) 
	{		/* If haven't read last sample yet */
	  last = resamplerReadData(inCount, inArray, sX, IBUFFSIZE, (int)Xread, first_pass);
	  first_pass = NO;
			
	  if (last && ((last - Xoff) < Nx)) 
	    { /* If last sample has been read... */
	      Nx = last - Xoff;	/* ...calc last sample affected by filter */
	      if (Nx <= 0) 
		{
		  break;
		}
	    }
	}

      if ((outCount-Ycount) > (OBUFFSIZE - (2 * Xoff * sfactor)))
	{
	  maxOutput = OBUFFSIZE - (unsigned short)(2 * Xoff * sfactor);
	} 
      else 
	{
	  maxOutput = outCount-Ycount;
	}
		    
      for (c = 0; c < DEFAULT_CHANNELS; c++) 
	{
	  orig_Nx = Nx;
	  Time2 = sTime;
	
	  /* Resample stuff in input buffer */
	  Nout = SrcLinear(sX[c], sY[c], sfactor, &Time2, orig_Nx, maxOutput);
	}
			
      Nx = orig_Nx;
      sTime = Time2;

      sTime -= (Nx << Np);	/* Move converter Nx samples back in time */
      Xp += Nx;		/* Advance by number of samples processed */
		
      for (c = 0; c < DEFAULT_CHANNELS; c++) 
	{
	  for (i = 0; i < (IBUFFSIZE - Xp + Xoff); i++) 
	    { /* Copy part of input signal */
	      sX[c][i] = sX[c][i + Xp - Xoff]; /* that must be re-used */
	    }
	}
		
      if (last) 
	{		/* If near end of sample... */
	  last -= Xp;		/* ...keep track were it ends */
			
	  if (!last) 
	    {		/* Lengthen input by 1 sample if... */
	      last++;	
	    }             	/* ...needed to keep flag YES */
	}

      Xread = IBUFFSIZE - Nx;	/* Pos in input buff to read new data into */
      Xp = Xoff;
	
      Ycount += Nout;
      if (Ycount > outCount) 
	{
	  Nout -= (Ycount - outCount);
	  Ycount = outCount;
	}

      if (Nout > OBUFFSIZE) 
	{ /* Check to see if output buff overflowed */
	  return resampleError("Output array overflow");
	}
		
      for (c = 0; c < DEFAULT_CHANNELS; c++) 
	{
	  for (i = 0; i < Nout; i++) 
	    {
	      outArray[c * outCount + i + Ycount - Nout] = sY[c][i];
	    }
	}
		
      total_inCount += Nx;

    } while (Ycount < outCount); /* Continue until done */

  inCount = total_inCount;

  return(Ycount);		/* Return # of samples in output file */
}

int 
SrcLinear(short X[], short Y[], double factor, unsigned int *Time, 
	  unsigned short Nx, unsigned short Nout)
{
  short iconst;
  short *Xp, *Ystart;
  int v, x1, x2;

  double dt;                  /* Step through input signal */ 
  unsigned int dtb;           /* Fixed-point version of Dt */
  unsigned int start_sample, end_sample;

  dt = 1.0 / factor;            /* Output sampling period */
  dtb = (unsigned int)(dt * (1 << Np) + 0.5); /* Fixed-point representation */

  start_sample = *Time >> Np;
  Ystart = Y;

  while (Y - Ystart != Nout) 
    {
      iconst = *Time & Pmask;
      Xp = &X[*Time >> Np];      /* Ptr to current input sample */
      x1 = *Xp++;
      x2 = *Xp;
      x1 *= (1 << Np) - iconst;
      x2 *= iconst;
      v = x1 + x2;
      *Y++ = WordToHword(v, Np);   /* Deposit output */
      *Time += dtb;		    /* Move to next sample by time increment */
    }
	
  end_sample = *Time >> Np;
  Nx = end_sample - start_sample;
  return (Y - Ystart);            /* Return number of output samples */
}

inline short
WordToHword(int v, int scl)
{
  short out;	
  int llsb;
	
  llsb = (1 << (scl - 1));
  v += llsb;          /* round */
  v >>= scl;
  if (v > INT16_MAX) 
    {
      v = INT16_MAX;
    } 
  else if (v < INT16_MIN)
    {
      v = INT16_MIN;
    }
  out = (short)v;
	
  return out;
}

int 
resamplerReadData(int inCount, short inArray[], short *outPtr[], 
		  int dataArraySize, int Xoff, BOOL init_count) 
{
  int i, Nsamps, c;
  static unsigned int framecount;  /* frames previously read */
  short *ptr;

  if (init_count == YES) 
    {
      framecount = 0;       /* init this too */
    }
	
  Nsamps = dataArraySize - Xoff;   /* Calculate number of samples to get */

  // Don't overrun input buffers
  if (Nsamps > (inCount - (int)framecount)) 
    {
      Nsamps = inCount - framecount;
    }

  for (c = 0; c < DEFAULT_CHANNELS; c++)
    {
      ptr = outPtr[c];
      ptr += Xoff;        /* Start at designated sample number */

      for (i = 0; i < Nsamps; i++) 
	{
	  *ptr++ = (short) inArray[c * inCount + i + framecount];
	}
    }

  framecount += Nsamps;

  if ((int)framecount >= inCount) 
    {          /* return index of last samp */
      return (((Nsamps - (framecount - inCount)) - 1) + Xoff);
    }
	
  return 0;
}

int 
resampleError(char *s)
{
  NSLog([NSString stringWithCString: s]);
  return -1;
}

