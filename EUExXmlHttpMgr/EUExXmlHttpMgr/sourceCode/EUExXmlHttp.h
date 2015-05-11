//
//  EUExXmlHttp.h
//  AppCan
//
//  Created by AppCan on 11-10-26.
//  Copyright 2011 AppCan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASIHTTPRequest.h"
#import "ASIHTTPRequestDelegate.h"
#import "ASIFormDataRequest.h"
@class EUExXmlHttpMgr;
@interface EUExXmlHttp : NSObject <ASIHTTPRequestDelegate,ASIProgressDelegate>{
	NSString *httpMethod;
	NSString *httpID;
    EUExXmlHttpMgr *euexObj;
	NSMutableData *receiveData;
	NSString *urlString;
	NSString *timeOutString;
	ASIFormDataRequest *asiRequest;
	BOOL isVerify;
	BOOL isSending;
	long long receiveLen;
	long long receiveTotalLength;
	long long uploadFileLength;
	long long sendLen;
	BOOL isSendProgress;
    NSString *defaultUserAgent;    
}
@property (nonatomic, retain)ASIFormDataRequest *asiRequest;
@property (nonatomic, retain)NSString *httpMethod;
@property (nonatomic, copy)NSString *httpID;
@property (nonatomic,copy)NSString *timeOutString;
@property (nonatomic, assign) EUExXmlHttpMgr *euexObj;
@property (nonatomic, assign)NSMutableData *receiveData;
@property (nonatomic, copy)NSString *urlString;
@property (nonatomic, assign)BOOL isVerify;
@property (nonatomic, assign)BOOL isSending;
@property (nonatomic,assign)long long uploadFileLength;
@property (nonatomic,assign)long long sendLen;

//https证书
@property (nonatomic, retain)NSString *httpsCertiPath;
@property (nonatomic, retain)NSString *httpsCertiPwd;

-(void)requestForGetRequest;
-(void)requestForPostRequest;
-(void)requestForPutRequest;
-(void)requestForDeleteRequest;
-(NSString *)defaultUserAgentString;

@end
