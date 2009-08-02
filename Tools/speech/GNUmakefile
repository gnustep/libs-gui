ETOILE_CORE_MODULE = YES

include $(GNUSTEP_MAKEFILES)/common.make

# Set the default.  Eventually this should be conditional.
GSSPEECHENGINE = Flite

VERSION = 0.1

# This is an app not a tool because, eventually, it will present the user
# interface for the GUI part of the speech engine.
APP_NAME = GSSpeechServer

GSSpeechServer_LANGUAGES = English

GSSpeechServer_OBJC_FILES = \
							GSSpeechEngine.m\
							GSSpeechServer.m\
							GSSpeechSynthesizer.m\
							main.m

ifeq ($(GSSPEECHENGINE), Flite)
GSSpeechServer_OBJC_FILES += FliteSpeechEngine.m
GSSpeechServer_INCLUDE_DIRS += -I/usr/local/include/flite
GSSpeechServer_LIB_DIRS += -L/usr/local/lib -lflite_cmu_us_kal -lflite_usenglish -lflite_cmulex -lflite
endif

GSSpeechServer_OBJCFLAGS = -std=c99 -g -Werror

include $(GNUSTEP_MAKEFILES)/application.make
