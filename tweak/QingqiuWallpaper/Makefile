TARGET := iphone:clang:latest:14.0
ARCHS := arm64 arm64e
THEOS_PACKAGE_SCHEME := rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME := QingqiuWallpaper
QingqiuWallpaper_FILES := Tweak.xm
QingqiuWallpaper_FRAMEWORKS := UIKit
QingqiuWallpaper_CFLAGS := -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "sbreload"
