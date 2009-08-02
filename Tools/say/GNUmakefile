ETOILE_CORE_MODULE = YES

include $(GNUSTEP_MAKEFILES)/common.make

GSSPEECHENGINE = Flite

VERSION = 0.1
TOOL_NAME = say 

say_LANGUAGES = English

say_OBJC_FILES = \
							say.m

say_OBJCFLAGS += -std=c99 -g -Werror
say_LDFLAGS += -lgnustep-gui

include $(GNUSTEP_MAKEFILES)/tool.make
