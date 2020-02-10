include $(GNUSTEP_MAKEFILES)/common.make
include ../../config.make

VERSION = 0.1

# This is an app not a tool because, eventually, it will present the user
# interface for the GUI part of the speech engine.
APP_NAME = GSSpeechRecognitionServer
SUBPROJECTS = Plugins

GSSpeechRecognitionServer_LANGUAGES = English

GSSpeechRecognitionServer_OBJC_FILES = \
	GSSpeechRecognitionEngine.m \
	GSSpeechRecognitionServer.m \
	main.m

GSSpeechRecognitionServer_RESOURCE_FILES = \
	Plugins/Pocketsphinx/PocketSphinx.recognizer


# Add includes and link dirs.... 
GSSpeechRecognitionServer_INCLUDE_DIRS += \
	-I../../Headers \
	-I../../Headers/Additions
GSSpeechRecognitionServer_LIB_DIRS += -L../../Source/$(GNUSTEP_OBJ_DIR) \
	-L/usr/local/lib -lgnustep-gui 


include $(GNUSTEP_MAKEFILES)/aggregate.make
include $(GNUSTEP_MAKEFILES)/application.make
