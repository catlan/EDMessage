# Message.subproj
# $Id: GNUmakefile,v 2.1 2003-10-21 16:27:19 znek Exp $


ifeq "$(GNUSTEP_SYSTEM_ROOT)" ""
  include Makefile
else

include $(GNUSTEP_MAKEFILES)/common.make

ADDITIONAL_INCLUDE_DIRS = \
-I.. \
-I../FoundationExtensions.subproj \
-I../HeaderFieldCoder.subproj


SUBPROJECT_NAME = Message.subproj


Message.subproj_HEADER_FILES = \
EDHeaderBearingObject.h EDMConstants.h \
EDInternetMessage.h     EDMessagePart.h


Message.subproj_OBJC_FILES = \
EDHeaderBearingObject.m EDMConstants.m \
EDInternetMessage.m     EDMessagePart.m


include ../GNUstepBuild


-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/subproject.make

-include GNUmakefile.postamble

endif
