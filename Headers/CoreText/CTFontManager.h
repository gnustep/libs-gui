/** <title>CTFontManager</title>

   <abstract>C Interface to text layout library</abstract>

   Copyright <copy>(C) 2010 Free Software Foundation, Inc.</copy>

   Author: Eric Wasylishen
   Date: Aug 2010

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
   Lesser General Public License for more details.
   
   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
   */
   
#ifndef OPAL_CTFontManager_h
#define OPAL_CTFontManager_h

#include <CoreGraphics/CGBase.h>
#include <CoreText/CTFontDescriptor.h>

/* Constants */

extern const CFStringRef kCTFontManagerBundleIdentifier;
extern const CFStringRef kCTFontManagerRegisteredFontsChangedNotification;

typedef enum {
  kCTFontManagerScopeNone = 0,
  kCTFontManagerScopeProcess = 1,
  kCTFontManagerScopeUser = 2,
  kCTFontManagerScopeSession = 3
} CTFontManagerScope;

typedef enum {
  kCTFontManagerAutoActivationDefault = 0,
  kCTFontManagerAutoActivationDisabled = 1,
  kCTFontManagerAutoActivationEnabled = 2,
  kCTFontManagerAutoActivationPromptUser = 3
} CTFontManagerAutoActivationSetting;

/* Functions */

CFArrayRef CTFontManagerCopyAvailablePostScriptNames();

CFArrayRef CTFontManagerCopyAvailableFontFamilyNames();

CFArrayRef CTFontManagerCopyAvailableFontURLs();

CFComparisonResult CTFontManagerCompareFontFamilyNames(
  const void *a,
  const void *b,
  void *info
);

CFArrayRef CTFontManagerCreateFontDescriptorsFromURL(CFURLRef fileURL);

bool CTFontManagerRegisterFontsForURL(
  CFURLRef fontURL,
  CTFontManagerScope scope,
  CFErrorRef *errors
);

bool CTFontManagerUnregisterFontsForURL(
  CFURLRef fontURL,
  CTFontManagerScope scope,
  CFErrorRef *errors
);

bool CTFontManagerRegisterFontsForURLs(
  CFArrayRef fontURLs,
  CTFontManagerScope scope,
  CFArrayRef *errors
);

bool CTFontManagerUnregisterFontsForURLs(
  CFArrayRef fontURLs,
  CTFontManagerScope scope,
  CFArrayRef *errors
);

void CTFontManagerEnableFontDescriptors(
  CFArrayRef descriptors,
  bool enable
);

CTFontManagerScope CTFontManagerGetScopeForURL(CFURLRef fontURL);

bool CTFontManagerIsSupportedFont(CFURLRef fontURL);

#if defined(__BLOCKS__)
CFRunLoopSourceRef CTFontManagerCreateFontRequestRunLoopSource(
  CFIndex sourceOrder, 
  CFArrayRef (^createMatchesCallback)(CFDictionaryRef requestAttributes, pid_t requestingProcess)
);
#endif

void CTFontManagerSetAutoActivationSetting(
  CFStringRef bundleIdentifier,
  CTFontManagerAutoActivationSetting setting
);

CTFontManagerAutoActivationSetting CTFontManagerGetAutoActivationSetting(
  CFStringRef bundleIdentifier
);

#endif
