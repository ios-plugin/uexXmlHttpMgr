//
//  EUExXmlHttp.m
//  AppCan
//
//  Created by AppCan on 11-10-26.
//  Copyright 2011 AppCan. All rights reserved.
//

#import "EUExXmlHttp.h"
#import "EUExXmlHttpMgr.h"
#import "EUtility.h"
#import "ASIDataDecompressor.h"
#import <CommonCrypto/CommonCrypto.h>
#import "BUtility.h"
#import "WWidget.h"
#import "EBrowserView.h"
#import "JSON.h"

@implementation EUExXmlHttp
@synthesize httpMethod;
@synthesize httpID;
@synthesize asiRequest;
@synthesize euexObj;
@synthesize receiveData;
@synthesize timeOutString;
@synthesize isVerify;
@synthesize isSending;
@synthesize uploadFileLength;
@synthesize sendLen;
@synthesize httpsCertiPath;
@synthesize httpsCertiPwd;
@synthesize urlString;

#pragma mark -
#pragma mark - 设置默认的UserAgent

-(NSString *)defaultUserAgentString{
    if (!defaultUserAgent) {
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        // Attempt to find a name for this application
        NSString *appName = [bundle objectForInfoDictionaryKey:@"CFBundleDisplayName"];
        if (!appName) {
            appName = [bundle objectForInfoDictionaryKey:@"CFBundleName"];
        }
        NSData *latin1Data = [appName dataUsingEncoding:NSUTF8StringEncoding];
        appName = [[[NSString alloc] initWithData:latin1Data encoding:NSUTF8StringEncoding] autorelease];
        
        // If we couldn't find one, we'll give up (and ASIHTTPRequest will use the standard CFNetwork user agent)
        if (!appName) {
            return nil;
        }
        NSString *appVersion = nil;
        NSString *marketingVersionNumber = [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        NSString *developmentVersionNumber = [bundle objectForInfoDictionaryKey:@"CFBundleVersion"];
        if (marketingVersionNumber && developmentVersionNumber) {
            if ([marketingVersionNumber isEqualToString:developmentVersionNumber]) {
                appVersion = marketingVersionNumber;
            } else {
                appVersion = [NSString stringWithFormat:@"%@ rv:%@",marketingVersionNumber,developmentVersionNumber];
            }
        } else {
            appVersion = (marketingVersionNumber ? marketingVersionNumber : developmentVersionNumber);
        }
        
        NSString *deviceName;
        NSString *OSName;
        NSString *OSVersion;
        NSString *locale = [[NSLocale currentLocale] localeIdentifier];
        
#if TARGET_OS_IPHONE
        UIDevice *device = [UIDevice currentDevice];
        deviceName = [device model];
        OSName = [device systemName];
        OSVersion = [device systemVersion];
#else
        deviceName = @"Macintosh";
        OSName = @"Mac OS X";
        
        // From http://www.cocoadev.com/index.pl?DeterminingOSVersion
        // We won't bother to check for systems prior to 10.4, since ASIHTTPRequest only works on 10.5+
        OSErr err;
        SInt32 versionMajor, versionMinor, versionBugFix;
        err = Gestalt(gestaltSystemVersionMajor, &versionMajor);
        if (err != noErr) return nil;
        err = Gestalt(gestaltSystemVersionMinor, &versionMinor);
        if (err != noErr) return nil;
        err = Gestalt(gestaltSystemVersionBugFix, &versionBugFix);
        if (err != noErr) return nil;
        OSVersion = [NSString stringWithFormat:@"%u.%u.%u", versionMajor, versionMinor, versionBugFix];
#endif
        // Takes the form "My Application 1.0 (Macintosh; Mac OS X 10.5.7; en_GB)"
        defaultUserAgent = [[NSString alloc ]initWithFormat:@"%@ %@ (%@; %@ %@; %@)", appName, appVersion, deviceName, OSName, OSVersion, locale];
    }
    return defaultUserAgent;
}

#pragma mark -
#pragma mark - md5

- (NSString *)md5:(NSString *)appKeyAndAppId {
    const char *cStr = [appKeyAndAppId UTF8String];
    unsigned char result[16];
    CC_MD5(cStr, strlen(cStr), result); // This is the md5 call
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ]; 
}

#pragma mark -
#pragma mark - 获得当前时间戳

-(NSString *)getCurrentTS{
    NSString *timeSp = [NSString stringWithFormat:@"%ld", (long)[[NSDate  date] timeIntervalSince1970]];
    return timeSp;
//    NSDate* dat = [NSDate dateWithTimeIntervalSinceNow:0];
//    NSTimeInterval a = [dat timeIntervalSince1970]*1000;
//    NSString *timeString = [NSString stringWithFormat:@"%d",a];//转为字符型
//    return timeString;
}

#pragma mark -
#pragma mark - ASIHTTPRequestDelegate

- (void)request:(ASIHTTPRequest *)request didReceiveResponseHeaders:(NSDictionary *)responseHeaders{
	NSNumber *totNum = [responseHeaders objectForKey:@"Content-Length"];
	if (totNum) {
		receiveTotalLength = [totNum intValue];
		isSendProgress = YES;
        receiveLen = 0;
	}
    if (receiveData) {
        [receiveData setLength:0];
    }
}

- (void)request:(ASIHTTPRequest *)request didSendBytes:(long long)bytes{
	if (uploadFileLength>0) {
		sendLen+=bytes;
		NSInteger percent = (NSInteger)sendLen*100/uploadFileLength;
		if (percent>100) {
			percent = 100;
		}
        
		[euexObj uexOnHttpMgrProgress:[self.httpID intValue] progress:percent];
	}
}

- (void)requestFailed:(ASIHTTPRequest *)request{
    
    NSString * recString = nil;
    
    if (receiveData) {
        
        if ([request isResponseCompressed]) {
            
            NSError * error = nil;
            NSData * data = [ASIDataDecompressor uncompressData:receiveData error:&error];
            recString = [EUtility transferredString:data];
            
        } else {
            
            recString = [EUtility transferredString:receiveData];
            
            if (recString) {
                
            } else {
                
                recString = request.responseString;
                
                if (recString) {
                    
                } else {
                    
                    recString = [EUtility transferredString:[request responseData]];
                    
                }
                
            }
            
        }
        
    } else {
        
        recString = request.responseString;
        
        if (recString) {
            
        } else {
            
            recString = [EUtility transferredString:[request responseData]];
            
        }
        
    }

    int requestCode = request.responseStatusCode;
    
    NSMutableDictionary * cbDic = [NSMutableDictionary dictionary];
    
    NSString * responseStatusCode = [NSString stringWithFormat:@"%d",requestCode];
    
    NSDictionary * responseHeaders = [NSDictionary dictionary];
    if (request.responseHeaders) {
        responseHeaders = request.responseHeaders;
    }
    [cbDic setObject:responseHeaders forKey:@"responseHeaders"];
    
    if (responseStatusCode) {
        [cbDic setObject:responseStatusCode forKey:@"responseStatusCode"];
    }
    
    NSString * responseStatusMessage = @"";
    if (request.responseStatusMessage) {
        responseStatusMessage = request.responseStatusMessage;
    }
    [cbDic setObject:responseStatusMessage forKey:@"responseStatusMessage"];
    
    NSString * responseError = @"";
    if (request.error) {
        responseError = [request.error localizedDescription];
    }
    [cbDic setObject:responseError forKey:@"responseError"];
    
    NSString * cbJson = [cbDic JSONFragment];
    
    if (requestCode == 0) {
        requestCode = -1;
        [euexObj uexOnHttpMgrWithOpId:[self.httpID intValue] status:-1 data:responseError requestCode:requestCode json:@""];
    } else {
        [euexObj uexOnHttpMgrWithOpId:[self.httpID intValue] status:1 data:recString requestCode:requestCode json:cbJson];
    }
	
    
}

-(void)request:(ASIHTTPRequest *)request didReceiveData:(NSData *)data{
    if (receiveData) {
        [receiveData appendData:data];
    }
	if (isSendProgress) {
		receiveLen +=[data length];
		NSInteger percent = (NSInteger)receiveLen*100/(receiveTotalLength);
		NSString *progress = [NSString stringWithFormat:@"%d",percent];
        int requestCode = request.responseStatusCode;
//		[euexObj uexOnHttpMgrWithOpId:[self.httpID intValue] status:0 data:progress requestCode:requestCode];
	}
}

- (void)requestStarted:(ASIHTTPRequest *)request{
    //
}

- (void)requestFinished:(ASIHTTPRequest *)request{
	NSString *recString = nil;
    if (receiveData) {
        if ([request isResponseCompressed]) {
            NSError *error = nil;
            NSData* data = [ASIDataDecompressor uncompressData:receiveData error:&error];
            recString = [EUtility transferredString:data];
        }else{
            recString = [EUtility transferredString:receiveData];
            if (recString) {
                
            }else{
                recString = request.responseString;
                if (recString) {
                    
                }else{
                    recString = [EUtility transferredString:[request responseData]];
                }
            }
        }
    }else{
        recString = [EUtility transferredString:[request responseData]];
    }
    int requestCode = request.responseStatusCode;
    
    NSMutableDictionary * cbDic = [NSMutableDictionary dictionary];
    
    NSString * responseStatusCode = [NSString stringWithFormat:@"%d",requestCode];
    
    NSDictionary * responseHeaders = [NSDictionary dictionary];
    if (request.responseHeaders) {
        responseHeaders = request.responseHeaders;
    }
    [cbDic setObject:responseHeaders forKey:@"responseHeaders"];
    
    if (responseStatusCode) {
        [cbDic setObject:responseStatusCode forKey:@"responseStatusCode"];
    }
    
    NSString * responseStatusMessage = @"";
    if (request.responseStatusMessage) {
        responseStatusMessage = request.responseStatusMessage;
    }
    [cbDic setObject:responseStatusMessage forKey:@"responseStatusMessage"];
    
    NSString * responseError = @"";
    if (request.error) {
        responseError = [request.error localizedDescription];
    }
    [cbDic setObject:responseError forKey:@"responseError"];

    
    NSString * cbJson = [cbDic JSONFragment];
    
    
    if (cbJson) {
        
        [euexObj uexOnHttpMgrProgress:[self.httpID intValue] progress:100];
        
        [euexObj uexOnHttpMgrWithOpId:[self.httpID intValue] status:1 data:recString requestCode:requestCode json:cbJson];
        
    } else {
        
        [euexObj uexOnHttpMgrWithOpId:[self.httpID intValue] status:-1 data:[[request error] localizedDescription] requestCode:requestCode json:@""];
        
    }
}

#pragma mark -
#pragma mark - 设置请求方式

-(void)requestIsVerify{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    WWidget *curWgt = euexObj.meBrwView.mwWgt;
    NSString *time = [self getCurrentTS];
    NSString *str = [NSString stringWithFormat:@"%@:%@:%@",curWgt.appId,[BUtility appKey],time];
    str = [self md5:str];
    str = [NSString stringWithFormat:@"md5=%@;ts=%@;",str,time];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:asiRequest.requestHeaders];
    [dict setObject:str forKey:@"appverify"];
    [asiRequest setRequestHeaders:dict];
    [pool release];
}

-(void)requestForPostRequest{
    receiveData = [[NSMutableData alloc] initWithCapacity:100];
	if (asiRequest) {
 		[asiRequest setDelegate:self];
        if (isVerify) {
            [self requestIsVerify];
        }
        if (asiRequest.requestHeaders) {
            //
        } else {
            [asiRequest setUserAgent:[self defaultUserAgentString]];
        }
 		[asiRequest setRequestMethod:@"POST"];
		[asiRequest setUploadProgressDelegate:self];
		[asiRequest setTimeOutSeconds:([timeOutString intValue]/1000)];
		[asiRequest startAsynchronous];
	}
}

-(void)requestForGetRequest{
	receiveData = [[NSMutableData alloc] initWithCapacity:100];
    if (asiRequest) {
 		[asiRequest setDelegate:self];
        [asiRequest setUserAgent:[self defaultUserAgentString]];
        if (isVerify) {
            [self requestIsVerify];
        }
 		[asiRequest setRequestMethod:@"GET"];
		[asiRequest setTimeOutSeconds:([timeOutString intValue]/1000)];
		[asiRequest startAsynchronous];
	}
}

-(void)requestForPutRequest{
	receiveData = [[NSMutableData alloc] initWithCapacity:100];
    if (asiRequest) {
 		[asiRequest setDelegate:self];
        [asiRequest setUserAgent:[self defaultUserAgentString]];
 		[asiRequest setRequestMethod:@"PUT"];
		[asiRequest setTimeOutSeconds:([timeOutString intValue]/1000)];
		[asiRequest startAsynchronous];
	}
}

-(void)requestForDeleteRequest{
	receiveData = [[NSMutableData alloc] initWithCapacity:100];
    if (asiRequest) {
 		[asiRequest setDelegate:self];
        [asiRequest setUserAgent:[self defaultUserAgentString]];
 		[asiRequest setRequestMethod:@"DELETE"];
		[asiRequest setTimeOutSeconds:([timeOutString intValue]/1000)];
		[asiRequest startAsynchronous];
	}
}

#pragma mark -
#pragma mark - dealloc

-(void)dealloc{
	if (receiveData) {
		[receiveData release];
		receiveData = nil;
	}
    if (httpMethod) {
        [httpMethod release];
		httpMethod = nil;
    }
    if (httpID) {
        [httpID release];
		httpID = nil;
    }
    if (timeOutString) {
        [timeOutString release];
		timeOutString = nil;
    }
    if (urlString) {
        [urlString release];
		urlString = nil;
    }
	if (asiRequest) {
		[asiRequest setDelegate:nil];
		[asiRequest release];
		asiRequest = nil;
	}
    if (defaultUserAgent) {
        [defaultUserAgent release];
        defaultUserAgent = nil;
    }
    
    if (self.httpsCertiPath) {
        self.httpsCertiPath=nil;
    }
    if (self.httpsCertiPwd) {
        self.httpsCertiPwd=nil;
    }
	[super dealloc];
}
@end
