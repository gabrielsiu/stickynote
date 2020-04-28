include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = StickyNotePrefs

StickyNotePrefs_FILES = SNPRootListController.m SNPAcknowledgementsController.m
StickyNotePrefs_INSTALL_PATH = /Library/PreferenceBundles
StickyNotePrefs_FRAMEWORKS = UIKit
StickyNotePrefs_PRIVATE_FRAMEWORKS = Preferences
StickyNotePrefs_CFLAGS = -fobjc-arc
StickyNotePrefs_EXTRA_FRAMEWORKS = CepheiPrefs
include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/StickyNotePrefs.plist$(ECHO_END)
