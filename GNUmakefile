# EDMessage.framework
# $Id: GNUmakefile,v 2.1 2003-09-04 14:36:46 znek Exp $


ifeq "$(GNUSTEP_SYSTEM_ROOT)" ""
  include Makefile
else

# Install into the local root by default
GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_LOCAL_ROOT)

include $(GNUSTEP_MAKEFILES)/common.make

ifeq "$(OBJC_RUNTIME_LIB)" "gnu"
ADDITIONAL_OBJCFLAGS += -DGNU_RUNTIME
endif


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


# leave certain stuff out if we're building without UI
ifeq "$(GUI_LIB)" "nil"
ADDITIONAL_OBJCFLAGS += -DEDMESSAGE_WOBUILD
endif


-include Makefile.preamble

# This seems odd, but on Mach the dyld supports
# major/compatibility, thus you just need a single number.
# On UNIX things are different, hence we prefix our version
# with a "1".

MAJOR_VERSION = 1
MINOR_VERSION = $(CURRENT_PROJECT_VERSION)

-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/framework.make

-include GNUmakefile.postamble

-include Makefile.postamble

endif
