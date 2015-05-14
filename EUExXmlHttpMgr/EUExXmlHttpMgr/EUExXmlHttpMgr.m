//
//  EUExXmlHttpMgr.m
//  webKitCorePalm
//
//  Created by AppCan on 11-10-19.
//  Copyright 2011 AppCan. All rights reserved.
//

#import "EUExXmlHttpMgr.h"
#import "EUExXmlHttp.h"
#import "EUtility.h"
#import <Security/Security.h>
#import "WidgetOneDelegate.h"
#import "JSON.h"

@implementation EUExXmlHttpMgr
@synthesize httpDict;

-(id)initWithBrwView:(EBrowserView *) eInBrwView{
	if (self = [super initWithBrwView:eInBrwView]) {
		httpDict =  [[NSMutableDictionary alloc] initWithCapacity:5];
	}
	return self;
}

#pragma mark -
#pragma mark - 证书解析

//证书解析
- (BOOL)extractIdentity:(NSString*)pwdStr andIdentity:(SecIdentityRef *)outIdentity andTrust:(SecTrustRef*)outTrust andCertChain:(SecCertificateRef*)outCertChain fromPKCS12Data:(NSData *)inPKCS12Data {
    BOOL backBool=NO;
	
    OSStatus securityError          = errSecSuccess;
    NSDictionary *optionsDictionary = [NSDictionary dictionaryWithObject:pwdStr forKey:(id)kSecImportExportPassphrase];
    CFArrayRef items  = CFArrayCreate(NULL, 0, 0, NULL);
    securityError     = SecPKCS12Import((CFDataRef)inPKCS12Data,(CFDictionaryRef)optionsDictionary,&items);
    
	if (securityError == 0) {
		CFDictionaryRef myIdentityAndTrust = CFArrayGetValueAtIndex (items, 0);
		const void *tempIdentity = NULL;
		tempIdentity = CFDictionaryGetValue (myIdentityAndTrust, kSecImportItemIdentity);
		*outIdentity = (SecIdentityRef)tempIdentity;
		const void *tempTrust = NULL;
		tempTrust = CFDictionaryGetValue (myIdentityAndTrust, kSecImportItemTrust);
		*outTrust = (SecTrustRef)tempTrust;
        const void *tempCertChain = NULL;
		tempCertChain = CFArrayGetValueAtIndex((CFArrayRef)CFDictionaryGetValue (myIdentityAndTrust, kSecImportItemCertChain), 0);
		*outCertChain = (SecCertificateRef)tempCertChain;
        
        backBool=YES;
	} else {
		//
	}
	return backBool;
}

-(void)httpsRequest:(ASIHTTPRequest *)request withPwd:(NSString *)pwdStr withPath:(NSString *)pathStr {
    if (request!=nil && pathStr!=nil && [pathStr length]>0 && pwdStr!=nil && [pwdStr length]>0) {
    	// Now, let's grab the certificate (included in the resources of the test app)
        SecIdentityRef identity = NULL;
        SecTrustRef trust = NULL;
        SecCertificateRef certChain=NULL;
        NSData *PKCS12Data = [NSData dataWithContentsOfFile:pathStr];
        if (PKCS12Data) {
            BOOL resultBool=[self extractIdentity:pwdStr andIdentity:&identity andTrust:&trust  andCertChain:&certChain fromPKCS12Data:PKCS12Data];
            
            if (resultBool) {
                [request setValidatesSecureCertificate:YES];
                [request setClientCertificateIdentity:identity];
            }
        }
    }
}

#pragma mark -
#pragma mark - Plugin Method

//inUrl = @"https://192.168.1.131:8002";
//设置https请求证书
//NSMutableArray* array=[NSMutableArray arrayWithObjects:inOpId, @"q1w2e3r4", [[NSBundle mainBundle] pathForResource:@"client_3g2win" ofType:@"p12"], nil];
//[self setCertificate:array];

-(void)open:(NSMutableArray *)inArguments{
    if ([inArguments isKindOfClass:[NSMutableArray class]] && [inArguments count]>0) {
        NSString *inOpId = [inArguments objectAtIndex:0];
        NSString *inMethods = [inArguments objectAtIndex:1];
        NSString *inUrl = [inArguments objectAtIndex:2];
        NSString *inTime = [inArguments objectAtIndex:3];
        EUExXmlHttp *httpObj = [httpDict objectForKey:inOpId];
        if (httpObj) {
            [self uexOnHttpMgrWithOpId:[inOpId intValue] status:-1 data:@"对象已存在，不能重复创建" requestCode:0];
            return;
        }else {
            httpObj = [[EUExXmlHttp alloc] init];
            httpObj.euexObj = self;
            httpObj.httpID = inOpId;
            httpObj.httpMethod = inMethods;
            httpObj.isSending = YES;
            httpObj.urlString = inUrl;
            httpObj.isVerify = NO;
            if ([inTime intValue]==0) {
                inTime = @"30000";
            }
            httpObj.timeOutString = inTime;
            
            if ([[inMethods lowercaseString] isEqualToString:@"post"]) {
                NSURL *url = [NSURL URLWithString:inUrl];
                httpObj.asiRequest = [ASIFormDataRequest requestWithURL:url];
            }else{
                NSURL *url = [NSURL URLWithString:inUrl];
                httpObj.asiRequest = [ASIHTTPRequest requestWithURL:url];
            }
            //每次新的请求都要解除证书验证 证书要设置为空 不然会使用之前的证书
            [httpObj.asiRequest setValidatesSecureCertificate:NO];
            [httpObj.asiRequest setClientCertificateIdentity:nil];
            [httpDict setObject:httpObj forKey:inOpId];
            [httpObj release];
        }
    }
}

//设置证书路径及密码
-(void)setCertificate:(NSMutableArray *)inArguments{
    NSString *inOpId = [inArguments objectAtIndex:0];
	NSString *inpwd = [inArguments objectAtIndex:1];
	NSString *inPath = [inArguments objectAtIndex:2];
    
    if (inpwd && inPath) {
        EUExXmlHttp *httpObj = [httpDict objectForKey:inOpId];
        if (httpObj) {
            if ([inPath isEqualToString:@"default"]) {
                httpObj.httpsCertiPwd = theApp.useCertificatePassWord;
                NSString *sslPath = nil;
                if (theApp.useUpdateWgtHtmlControl) {
                    float version = [[[UIDevice currentDevice] systemVersion] floatValue];
                    if (version<5.0) {
                        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
                        NSString *cacheDirectory = [paths objectAtIndex:0];
                        sslPath = [cacheDirectory stringByAppendingPathComponent:@"widget/wgtRes/clientCertificate.p12"];
                    }else {
                        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                        sslPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"widget/wgtRes/clientCertificate.p12"];
                    }
                }else {
                    sslPath = [EUtility getResPath:@"widget/wgtRes/clientCertificate.p12"];
                }
                httpObj.httpsCertiPath = sslPath;
            }else{
                httpObj.httpsCertiPwd = inpwd;
                NSString* pathStr = [self absPath:inPath];
                httpObj.httpsCertiPath = pathStr;
            }
            
            //设置https请求证书
            [self httpsRequest:httpObj.asiRequest withPwd:httpObj.httpsCertiPwd withPath:httpObj.httpsCertiPath];
        }
    }
}

-(long)getFileLength:(NSString *)fileName{
	NSFileManager *fmanager = [NSFileManager defaultManager];
	NSDictionary *dic = [fmanager attributesOfItemAtPath:fileName error:nil];
	NSNumber *fileSize = [dic objectForKey:NSFileSize];
	long sum = (long)[fileSize longLongValue];
	return sum;
}

//设置头
-(void)setHeaders:(NSMutableArray *)inArguments{
    if ([inArguments isKindOfClass:[NSMutableArray class]] && [inArguments count]>=2) {
        NSString *inOpId = [inArguments objectAtIndex:0];
        NSString *inJsonHeaderStr = [inArguments objectAtIndex:1];
        
        EUExXmlHttp *httpObj = [httpDict objectForKey:inOpId];
        if (httpObj) {
            NSMutableDictionary *headerDict = [inJsonHeaderStr JSONValue];
            if (headerDict && [headerDict isKindOfClass:[NSMutableDictionary class]]) {
                [httpObj.asiRequest setRequestHeaders:headerDict];
            }
        }
    }
}

//设置post数据
-(void)setBody:(NSMutableArray *)inArguments{
    if ([inArguments count]>=2) {
        NSString *inOpId = [inArguments objectAtIndex:0];
        NSString *inDataString = [inArguments objectAtIndex:1];
        
        EUExXmlHttp *httpObj = [httpDict objectForKey:inOpId];
        if (httpObj) {
            //do action
            NSData* data = [inDataString dataUsingEncoding:NSUTF8StringEncoding];
            if (data) {
                [httpObj.asiRequest setPostBody:[NSMutableData dataWithData:data]];
            }
        }
    }
}

-(UIImage *)rotateImage:(UIImage *)aImage {
	CGImageRef imgRef = aImage.CGImage;
	CGFloat width = CGImageGetWidth(imgRef);
	CGFloat height = CGImageGetHeight(imgRef);
	CGAffineTransform transform = CGAffineTransformIdentity;
	CGRect bounds = CGRectMake(0, 0, width, height);
	CGFloat scaleRatio = 1;
	CGFloat boundHeight;
	UIImageOrientation orient = aImage.imageOrientation;
	switch(orient)
	{
		case UIImageOrientationUp: //EXIF = 1
			transform = CGAffineTransformIdentity;
			break;
		case UIImageOrientationUpMirrored: //EXIF = 2
			transform = CGAffineTransformMakeTranslation(width, 0.0);
			transform = CGAffineTransformScale(transform, -1.0, 1.0);
			break;
		case UIImageOrientationDown: //EXIF = 3
			transform = CGAffineTransformMakeTranslation(width, height);
			transform = CGAffineTransformRotate(transform, M_PI);
			break;
		case UIImageOrientationDownMirrored: //EXIF = 4
			transform = CGAffineTransformMakeTranslation(0.0, height);
			transform = CGAffineTransformScale(transform, 1.0, -1.0);
			break;
		case UIImageOrientationLeftMirrored: //EXIF = 5
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransformMakeTranslation(height, width);
			transform = CGAffineTransformScale(transform, -1.0, 1.0);
			transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
			break;
		case UIImageOrientationLeft: //EXIF = 6
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransformMakeTranslation(0.0, width);
			transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
			break;
		case UIImageOrientationRightMirrored: //EXIF = 7
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransformMakeScale(-1.0, 1.0);
			transform = CGAffineTransformRotate(transform, M_PI / 2.0);
			break;
		case UIImageOrientationRight: //EXIF = 8
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransformMakeTranslation(height, 0.0);
			transform = CGAffineTransformRotate(transform, M_PI / 2.0);
			break;
		default:
			[NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];
	}
	
	UIGraphicsBeginImageContext(bounds.size);
	CGContextRef context = UIGraphicsGetCurrentContext();
	if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft) {
		CGContextScaleCTM(context, -scaleRatio, scaleRatio);
		CGContextTranslateCTM(context, -height, 0);
	} else {
		CGContextScaleCTM(context, scaleRatio, -scaleRatio);
		CGContextTranslateCTM(context, 0, -height);
	}
	CGContextConcatCTM(context, transform);
	CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);
	UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return imageCopy;
}

-(void)setPostData:(NSMutableArray *)inArguments{
    if ([inArguments isKindOfClass:[NSMutableArray class]] && [inArguments count]>0) {
        NSString *inOpId = [inArguments objectAtIndex:0];
        NSString *inType = [inArguments objectAtIndex:1];
        NSString *inName = [inArguments objectAtIndex:2];
        NSString *inValue = [inArguments objectAtIndex:3];
        EUExXmlHttp *httpObj = [httpDict objectForKey:inOpId];
        if (httpObj) {
            //do action
            if ([[httpObj.httpMethod lowercaseString] isEqualToString:@"post"]) {
                if ([inType intValue]==0) {
                    if ([inName length]==0) {
                        [httpObj.asiRequest setPostBody:[NSMutableData dataWithData:[inValue dataUsingEncoding:NSUTF8StringEncoding]]];
                    }else {
                        [httpObj.asiRequest setPostValue:inValue forKey:inName];
                    }
                }else if ([inType intValue]==1) {
                    NSString *filepath = [self absPath:inValue];
                    if ([[NSFileManager defaultManager] fileExistsAtPath:filepath]) {
                        UIImage* img=[UIImage imageWithContentsOfFile:filepath];
                        if (img) {
                            if ([img imageOrientation]!=UIImageOrientationUp) {
                                UIImage* newImg=[self rotateImage:img];
                                if (newImg) {
                                    NSData *imageData = UIImageJPEGRepresentation(newImg,0.0);
                                    if (imageData) {
                                        NSFileManager *fmanager = [NSFileManager defaultManager];
                                        if ([fmanager fileExistsAtPath:filepath]) {
                                            [fmanager removeItemAtPath:filepath error:nil];
                                        }
                                        BOOL succ = [imageData writeToFile:filepath atomically:YES];
                                        if (succ) {
                                            
                                        }
                                    }
                                }
                            }
                        }
                        
                        [httpObj.asiRequest setFile:filepath forKey:inName];
                        httpObj.uploadFileLength = [self getFileLength:filepath];
                        httpObj.sendLen = 0;
                    }else {
                        //error
                    }
                }
            }
        }
    }
}

-(void)setInputStream:(NSMutableArray *)inArguments{
    if ([inArguments isKindOfClass:[NSMutableArray class]] && [inArguments count]>0) {
        NSString *inOpId = [inArguments objectAtIndex:0];
        NSString *inFile = [inArguments objectAtIndex:1];
        EUExXmlHttp *httpObj = [httpDict objectForKey:inOpId];
        if (httpObj) {
            if ([[httpObj.httpMethod lowercaseString] isEqualToString:@"post"]) {
                NSString *filepath = [self absPath:inFile];
                if ([[NSFileManager defaultManager] fileExistsAtPath:filepath]) {
                    NSMutableData *data = [[[NSMutableData alloc] initWithContentsOfFile:filepath] autorelease];
                    [httpObj.asiRequest setPostBody:data];
                }
            }
        }
    }
}

-(void)setAppVerify:(NSMutableArray *)inArguments{
    if ([inArguments isKindOfClass:[NSMutableArray class]] && [inArguments count]>0) {
        NSString *inOpId = [inArguments objectAtIndex:0];
        EUExXmlHttp *httpObj = [httpDict objectForKey:inOpId];
        if (httpObj) {
            if (2 == [inArguments count]) {
                NSString *isVerify = [inArguments objectAtIndex:1];
                if ([isVerify boolValue]) {
                    httpObj.isVerify = [isVerify boolValue];
                }
            }
        }
    }
}

-(void)send:(NSMutableArray *)inArguments{
	NSString *inOpId = [inArguments objectAtIndex:0];
	EUExXmlHttp *httpObj = [httpDict objectForKey:inOpId];
	if (httpObj) {
		if (httpObj.isSending ==YES) {
			httpObj.isSending = NO;
            NSString *str = [httpObj.httpMethod lowercaseString];
			if ([str isEqualToString:@"get"]) {
                [httpObj requestForGetRequest];
			}else if([str isEqualToString:@"post"]){
				[httpObj requestForPostRequest];
			}else if([str isEqualToString:@"put"]){
				[httpObj requestForPutRequest];
			}else if([str isEqualToString:@"delete"]){
				[httpObj requestForDeleteRequest];
			}else{
                
            }
		}
	}
}

#pragma mark -
#pragma mark - 获取Cookie

-(void)getCookie:(NSMutableArray *)inArguments {
    
    if ([inArguments count] < 1) {
        
        return;
        
    }
    
    NSString * httpStr = [inArguments objectAtIndex:0];
    
    NSHTTPCookieStorage * cookieJar = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    
    NSMutableArray * cookies = [NSMutableArray array];
    
    NSString * cookieAll = @"";
    
    for (NSHTTPCookie * cookie in [cookieJar cookies]) {
        
        NSString * domain = cookie.domain;
        
        if ([httpStr rangeOfString:domain].location != NSNotFound) {
            
            NSString * cookieStr = [NSString stringWithFormat:@"%@=%@",cookie.name,cookie.value];
            
            if (![cookies containsObject:cookieStr]) {
                
                [cookies addObject:cookieStr];
                
                if ([cookieAll length] == 0) {
                    
                    cookieAll = cookieStr;
                    
                } else {
                    
                    cookieAll = [NSString stringWithFormat:@"%@;%@",cookieAll,cookieStr];
                    
                }
                
            }
            
        }
        
    }
    
    NSDictionary * tempDic = [NSDictionary dictionaryWithObject:cookieAll forKey:@"cookie"];
    
    NSString * cbStr = [tempDic JSONFragment];
    
    [self jsSuccessWithName:@"uexXmlHttpMgr.cbGetCookie" opId:0 dataType:1 strData:cbStr];
    
}


#pragma mark -
#pragma mark - CallBack

-(void)uexOnHttpMgrProgress:(int)inOpId progress:(int)inProgress{
	NSString *jsStr = [NSString stringWithFormat:@"if(uexXmlHttpMgr.onPostProgress){uexXmlHttpMgr.onPostProgress(%d,%d)}",inOpId,inProgress];
	[self.meBrwView stringByEvaluatingJavaScriptFromString:jsStr];
}

-(void)uexOnHttpMgrWithOpId:(int)inOpId status:(int)inStatus data:(NSString*)inData requestCode:(int)requestCode json:(NSString *)json{
	NSString *jsStr = [NSString stringWithFormat:@"if(uexXmlHttpMgr.onData!=null){uexXmlHttpMgr.onData(%d,%d,\'%@\',%d,\'%@\')}",inOpId,inStatus,inData,requestCode,json];
	[self.meBrwView stringByEvaluatingJavaScriptFromString:jsStr];
}

- (void)stopNetService {
}

#pragma mark -
#pragma mark - 内存管理

-(void)close:(NSMutableArray *)inArguments{
	NSString *inOpID = [inArguments objectAtIndex:0];
	if (httpDict) {
		EUExXmlHttp *httpObj = [httpDict objectForKey:inOpID];
		if (httpObj) {
            if (httpObj.httpsCertiPath) {
                httpObj.httpsCertiPath = nil;
                httpObj.httpsCertiPwd = nil;
                
                //每次新的请求都要解除证书验证 证书要设置为空 不然会使用之前的证书
                [httpObj.asiRequest setValidatesSecureCertificate:NO];
                [httpObj.asiRequest setClientCertificateIdentity:nil];
            }
			if (httpObj.asiRequest) {
				[httpObj.asiRequest clearDelegatesAndCancel];
			}
			[httpDict removeObjectForKey:inOpID];
		}
	}
}

-(void)clean{
	if (httpDict) {
		NSArray *arr = [httpDict allValues];
		for (EUExXmlHttp *hobj in arr){
			if (hobj) {
				if (hobj.asiRequest) {
					[hobj.asiRequest clearDelegatesAndCancel];
				}
			}
		}
		[httpDict removeAllObjects];
	}
}

-(void)dealloc{
	if (httpDict) {
		[httpDict release];
        httpDict  = nil;
	}
	[super dealloc];
}

@end
