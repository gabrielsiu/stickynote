INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = StickyNote

StickyNote_FILES = Tweak.xm Note.m NoteViewController.m Constants.m NSDictionary+DefaultsValue.m
StickyNote_CFLAGS = -fobjc-arc
StickyNote_EXTRA_FRAMEWORKS += Cephei
StickyNote_LIBRARIES = colorpicker

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += stickynoteprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
