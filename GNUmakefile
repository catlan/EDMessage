# EDMessage.framework
# $Id: GNUmakefile,v 2.3 2003-11-10 00:06:32 znek Exp $


ifeq "$(GNUSTEP_SYSTEM_ROOT)" ""
  include Makefile
else

# Install into the local root by default
GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_LOCAL_ROOT)

include $(GNUSTEP_MAKEFILES)/common.make


FRAMEWORK_NAME = EDMessage


EDMessage_HEADER_FILES = \
EDMessage.h \
EDMessageDefines.h \
utilities.h


EDMessage_OBJC_FILES = framework.m


EDMessage_LIBRARIES_DEPEND_UPON += -lEDCommon


EDMessage_SUBPROJECTS = \
FoundationExtensions.subproj \
Message.subproj \
HeaderFieldCoder.subproj \
ContentCoder.subproj \
Mail.subproj


include GNUstepBuild


# Additional target specific settings

# Mac OS X
ifneq ($(findstring darwin, $(GNUSTEP_HOST_OS)),)
  EDMessage_LDFLAGS += -seg1addr 0x5080000
endif


include Version

# This seems odd, but on Mach the dyld supports
# major/compatibility, thus you just need a single number.
# On UNIX things are different, hence we use the
# CURRENT_PROJECT_VERSION as the MAJOR_VERSION.

MAJOR_VERSION = $(CURRENT_PROJECT_VERSION)
#MINOR_VERSION = 0
#SUBMINOR_VERSION = 0


-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/framework.make

-include GNUmakefile.postamble

endif
