//---------------------------------------------------------------------------------------
//  EDMessage.h created by erik on Wed 12-Apr-2000
//  $Id: EDMessage.h,v 2.2 2003/04/08 17:06:02 znek Exp $
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

#import <Foundation/Foundation.h>

#import <EDMessage/EDMessageDefines.h>

#import <EDMessage/NSDate+NetExt.h>
#import <EDMessage/NSCharacterSet+MIME.h>
#import <EDMessage/NSData+MIME.h>
#import <EDMessage/NSString+MessageUtils.h>
#import <EDMessage/NSString+PlainTextFlowedExtensions.h>

#import <EDMessage/EDMConstants.h>
#import <EDMessage/EDHeaderBearingObject.h>
#import <EDMessage/EDMessagePart.h>
#import <EDMessage/EDInternetMessage.h>

#import <EDMessage/EDHeaderFieldCoder.h>
#import <EDMessage/EDTextFieldCoder.h>
#import <EDMessage/EDDateFieldCoder.h>
#import <EDMessage/EDIdListFieldCoder.h>
#import <EDMessage/EDEntityFieldCoder.h>

#import <EDMessage/EDContentCoder.h>
#import <EDMessage/EDCompositeContentCoder.h>
#import <EDMessage/EDPlainTextContentCoder.h>
#import <EDMessage/EDHTMLTextContentCoder.h>
#import <EDMessage/EDMultimediaContentCoder.h>
#import <EDMessage/EDTextContentCoder.h>

