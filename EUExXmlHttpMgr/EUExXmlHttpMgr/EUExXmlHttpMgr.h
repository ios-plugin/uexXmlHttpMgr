//
//  EUExXmlHttpMgr.h
//  webKitCorePalm
//
//  Created by AppCan on 11-10-19.
//  Copyright 2011 AppCan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EUExBase.h"

enum dataType {
	UEX_XMLHTTPMGR_POST_TEXT = 0,
	UEX_XMLHTTPMGR_POST_BINARY = 1,
};
enum onDataStauts {
	UEX_XMLHTTPMGR_STATUS_RECEIVE = 0,
	UEX_XMLHTTPMGR_STATUS_FINISH = 1,
	UEX_XMLHTTPMGR_STATUS_ERROR = -1,
};
@interface EUExXmlHttpMgr : EUExBase {
	NSMutableDictionary *httpDict;
}
@property(nonatomic,retain)NSMutableDictionary *httpDict;
-(void)uexOnHttpMgrWithOpId:(int)inOpId status:(int)inStatus data:(NSString*)inData requestCode:(int)requestCode json:(NSString *)json;
-(void)uexOnHttpMgrProgress:(int)inOpId progress:(int)inProgress;
@end
