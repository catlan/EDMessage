//---------------------------------------------------------------------------------------
//  EDMessage.h created by erik on Wed 12-Apr-2000
//  $Id: EDMessage.h,v 2.2 2003-04-08 17:06:02 znek Exp $
//
//  Copyright (c) 2000 by Erik Doernenburg. All rights reserved.
//
//  Permission to use, copy, modify and distribute this software and its documentation
//  is hereby granted, provided that both the copyright notice and this permission
//  notice appear in all copies of the software, derivative works or modified versions,
//  and any portions thereof, and that both notices appear in supporting documentation,
//  and that credit is given to Erik Doernenburg in all documents and publicity
//  pertaining to direct or indirect use of this code or its derivatives.
//
//  THIS IS EXPERIMENTAL SOFTWARE AND IT IS KNOWN TO HAVE BUGS, SOME OF WHICH MAY HAVE
//  SERIOUS CONSEQUENCES. THE COPYRIGHT HOLDER ALLOWS FREE USE OF THIS SOFTWARE IN ITS
//  "AS IS" CONDITION. THE COPYRIGHT HOLDER DISCLAIMS ANY LIABILITY OF ANY KIND FOR ANY
//  DAMAGES WHATSOEVER RESULTING DIRECTLY OR INDIRECTLY FROM THE USE OF THIS SOFTWARE
//  OR OF ANY DERIVATIVE WORK.
//---------------------------------------------------------------------------------------


#ifndef	__EDMessage_h_INCLUDE
#define	__EDMessage_h_INCLUDE


#import <Foundation/Foundation.h>
#ifndef EDMESSAGE_WOBUILD
#import <AppKit/AppKit.h>
#endif // EDMESSAGE_WOBUILD

#include "EDMessageDefines.h"

#include "NSCalendarDate+NetExt.h"
#include "NSCharacterSet+MIME.h"
#include "NSData+MIME.h"
#ifndef EDMESSAGE_WOBUILD
#include "NSImage+XFace.h"
#endif // EDMESSAGE_WOBUILD
#include "NSString+MessageUtils.h"
#include "NSString+PlainTextFlowedExtensions.h"

#include "EDMConstants.h"
#include "EDHeaderBearingObject.h"
#include "EDMessagePart.h"
#include "EDInternetMessage.h"

#include "EDHeaderFieldCoder.h"
#include "EDTextFieldCoder.h"
#include "EDDateFieldCoder.h"
#include "EDIdListFieldCoder.h"
#include "EDEntityFieldCoder.h"
#ifndef EDMESSAGE_WOBUILD
#include "EDFaceFieldCoder.h"
#endif // EDMESSAGE_WOBUILD

#include "EDContentCoder.h"
#include "EDCompositeContentCoder.h"
#include "EDPlainTextContentCoder.h"
#include "EDHTMLTextContentCoder.h"
#include "EDMultimediaContentCoder.h"
#ifndef EDMESSAGE_WOBUILD
#include "EDTextContentCoder.h"
#endif // EDMESSAGE_WOBUILD

#include "EDSMTPStream.h"
#include "EDMailAgent.h"

#endif	/* __EDMessage_h_INCLUDE */

