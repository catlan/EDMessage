# EDMessage.framework
# $Id: GNUmakefile,v 2.2 2003-10-21 16:27:15 znek Exp $


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
