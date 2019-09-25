/**
 *
 *	@file   	: EUExXmlHttpMgr.m  in EUExXmlHttpMgr
 *
 *	@author 	: CeriNo 
 * 
 *	@date   	: Created on 16/5/20.
 *
 *	@copyright 	: 2016 The AppCan Open Source Project.
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Lesser General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Lesser General Public License for more details.
 *  You should have received a copy of the GNU Lesser General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

#import "EUExXmlHttpMgr.h"
#import "uexXmlHttpRequest.h"
#import "uexXmlHttpPOSTRequest.h"
#import "uexXmlHttpHelper.h"
#import "JSON.h"

//#define FILEPATH [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0]

@interface EUExXmlHttpMgr()

@property (nonatomic,strong)NSMutableDictionary<NSString *,__kindof uexXmlHttpRequest *> *requestDict;
@end

@implementation EUExXmlHttpMgr

static NSDictionary<NSString *,NSNumber *> *HTTPMethods = nil;




static inline NSString * newID(){
    return [NSUUID UUID].UUIDString;
}

+ (void)initialize{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        HTTPMethods = @{
            @"get":@(uexXmlHttpRequestMethodGET),
            @"post":@(uexXmlHttpRequestMethodPOST)
            };
    });
}


- (instancetype)initWithWebViewEngine:(id<AppCanWebViewEngineObject>)engine{
    self = [super initWithWebViewEngine:engine];
    if(self){
        _requestDict = [NSMutableDictionary dictionary];
    }
    return self;
}


- (void)clean{
    [self.requestDict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, __kindof uexXmlHttpRequest * _Nonnull request, BOOL * _Nonnull stop) {
        [request close];
    }];
    [self.requestDict removeAllObjects];
}


//- (void)test:(NSMutableArray *)inArguments{
//    uexXmlHttpRequest *request = [uexXmlHttpRequest requestWithMethod:uexXmlHttpRequestMethodGET identifier:@"id" euexObj:self];
//    request.serverPath = @"http://192.168.1.4:45678/get?key1=value1&key2=value2&arr[]=aaa&arr[]=bbb&arr[]=ccc";
//    //request.appVerifyEnabled = YES;
//    //[request setHeaders:@{@"myKey":@"myValue"}];
//    [request send];
//}

#pragma mark - AppDelegate
+ (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
//    NSFileManager * fileManager = [NSFileManager defaultManager];
//    NSArray * tempFileList = [[NSArray alloc] initWithArray:[fileManager contentsOfDirectoryAtPath:FILEPATH error:nil]]
//                              ;
//    NSLog(@"arr = %@",tempFileList);
    
    //清除缓存
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    return YES;
}

#pragma mark - UEXAPI


- (NSString *)create:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSDictionary *info) = inArguments;
    NSString *methodStr = stringArg(info[@"method"]).lowercaseString;
    NSString *url = stringArg(info[@"url"]);
    NSNumber *timeoutNum = numberArg(info[@"timeout"]) ?: @(30 * 1000);
    NSString *identifier = stringArg(info[@"id"]) ?: newID();
    NSNumber *certificateValidation = numberArg(info[@"certificateValidation"]);
    if (!identifier || [self.requestDict.allKeys containsObject:identifier] || !methodStr || ![HTTPMethods.allKeys containsObject:methodStr] || !url || url.length == 0) {
        return nil;
    }
    uexXmlHttpRequestMethod method = (uexXmlHttpRequestMethod)[HTTPMethods[methodStr] integerValue];
    uexXmlHttpRequest *request = [uexXmlHttpRequest requestWithMethod:method identifier:identifier euexObj:self];
    if (!request) {
        return nil;
    }
    request.serverPath = url;
    if (certificateValidation) {
        request.certificateValidationEnabled = certificateValidation.boolValue;
    }

    NSTimeInterval timeout = [timeoutNum doubleValue];
    if (timeout >= 1) {
        request.timeoutInterval = timeout;
    }
    [self.requestDict setObject:request forKey:identifier];
    return identifier;
}

- (UEX_BOOL)open:(NSMutableArray *)inArguments{

    
    ACArgsUnpack(NSString *identifier,NSString *methodStr,NSString *urlStr,NSNumber *timeoutNum) = inArguments;
    methodStr = methodStr.lowercaseString;
    if (!identifier || [self.requestDict.allKeys containsObject:identifier] || !methodStr || ![HTTPMethods.allKeys containsObject:methodStr] || !urlStr || urlStr.length == 0) {
        return UEX_FALSE;
    }
    uexXmlHttpRequestMethod method = (uexXmlHttpRequestMethod)[HTTPMethods[methodStr] integerValue];
    uexXmlHttpRequest *request = [uexXmlHttpRequest requestWithMethod:method identifier:identifier euexObj:self];
    if (!request) {
        return UEX_FALSE;
    }
    request.serverPath = urlStr;
    if (timeoutNum) {
        NSTimeInterval timeout = [timeoutNum doubleValue];
        if (timeout >= 1) {
            request.timeoutInterval = timeout;
        }
    }
    [self.requestDict setObject:request forKey:identifier];
    return UEX_TRUE;
}

- (void)send:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSString *identifier,NSNumber *flagNum,ACJSFunctionRef *resultCB,ACJSFunctionRef *progressCB) = inArguments;
    NSInteger flag = flagNum.integerValue;
    switch (flag) {
        default:
            break;
    }
    __kindof uexXmlHttpRequest *request = self.requestDict[identifier];
    request.resultCB = resultCB;
    request.progressCB = progressCB;
    [request send];
}

- (UEX_BOOL)setAppVerify:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSString *identifier,NSNumber *appVerityNum) = inArguments;
    BOOL appVerifyEnabled = [appVerityNum boolValue];
    if (!self.requestDict[identifier]) {
        return UEX_FALSE;

    }
    self.requestDict[identifier].appVerifyEnabled = appVerifyEnabled;
    return UEX_TRUE;

}

- (UEX_BOOL)setHeaders:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSString *identifier,NSDictionary *headers) = inArguments;
    if (!headers || !self.requestDict[identifier]) {
        return UEX_FALSE;
    }
    self.requestDict[identifier].headers = headers;
    return UEX_TRUE;
}

- (UEX_BOOL)close:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSString *identifier) = inArguments;
    if (!self.requestDict[identifier]) {
        return UEX_FALSE;
    }
    [self.requestDict[identifier] close];
    return UEX_TRUE;
}

- (UEX_BOOL)setCertificate:(NSMutableArray *)inArguments{

    ACArgsUnpack(NSString *identifier,NSString* password,NSString *certPath) = inArguments;
    
    BOOL useAppCanCert = NO;
    if ([certPath.lowercaseString isEqual:@"default"]) {
        useAppCanCert = YES;
    }
    __kindof uexXmlHttpRequest *request = self.requestDict[identifier];
    if (!request) {
        return  UEX_FALSE;
    }
    uexXmlHttpAuthentication *auth = [[uexXmlHttpAuthentication alloc]init];
    if(!useAppCanCert){
        NSData *p12Data = [NSData dataWithContentsOfFile:[self absPath:certPath]];
        if (!p12Data) {
            return UEX_FALSE;
        }
        auth.PKGCS12ClientCertificateData = p12Data;
        auth.clientCertificatePassword = password;
    }
    request.authentication = auth;
    return  UEX_TRUE;
}

- (UEX_BOOL)setPostData:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSString *identifier,NSNumber *typeNum,NSString *field,id data) = inArguments;
    uexXmlHttpPOSTRequest *request = [self getPostRequestByIdentifier:identifier];
    UEX_PARAM_GUARD_NOT_NIL(request,UEX_FALSE);
    UEX_PARAM_GUARD_NOT_NIL(typeNum,UEX_FALSE);
    UEX_PARAM_GUARD_NOT_NIL(field,UEX_FALSE);
    UEX_PARAM_GUARD_NOT_NIL(data,UEX_FALSE);

    NSInteger dataType = [typeNum integerValue];


    switch (dataType) {
        case 0:{
            if ([data isKindOfClass:[NSString class]] ||
                [data isKindOfClass:[NSNumber class]] ||
                [data isKindOfClass:[NSDictionary class]] ||
                [data isKindOfClass:[NSArray class]]) {
                [request setPostData:data forField:field];
            }
            break;
        }
        case 1:{
            if ([data isKindOfClass:[NSString class]]) {
                [request setFile:[self absPath:data] forField:field];
            }
            break;
        }
        default:
            return UEX_FALSE;
            break;
    }
    return UEX_TRUE;

}

- (UEX_BOOL)setInputStream:(NSMutableArray *)inArguments{

    ACArgsUnpack(NSString *identifier,NSString *filePath) = inArguments;
    

    uexXmlHttpPOSTRequest *request = [self getPostRequestByIdentifier:identifier];
    if (!request || !filePath) {
        return UEX_FALSE;
    }
    NSData *fileData = [NSData dataWithContentsOfFile:[self absPath:filePath]];
    [request setPostBody:fileData];
    return UEX_TRUE;
}


- (UEX_BOOL)setBody:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSString *identifier,NSString *body) = inArguments;
    uexXmlHttpPOSTRequest *request = [self getPostRequestByIdentifier:identifier];
    if (!request) {
        return UEX_FALSE;
    }
    NSData *data = [body dataUsingEncoding:NSUTF8StringEncoding];
    [request setPostBody:data];
    return  UEX_TRUE;
}

- (void)clearCookie:(NSMutableArray *)inArguments {
    if ([inArguments count] < 1) {
        NSArray * cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
        for (int i = 0; i < [cookies count]; i++) {
            NSHTTPCookie *cookie = (NSHTTPCookie *)[cookies objectAtIndex:i];
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
        }
    } else {
        NSURL * url = [NSURL URLWithString:[inArguments objectAtIndex:0]];
        if (url) {
            NSArray * cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:url];
            for (int i = 0; i < [cookies count]; i++) {
                NSHTTPCookie *cookie = (NSHTTPCookie *)[cookies objectAtIndex:i];
                [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
            }
        }
    }
}

- (void)setCookie:(NSMutableArray *)inArguments {
    if ([inArguments count] < 2) {
        return;
    }
    ACArgsUnpack(NSString *cookieUrl, NSString *cookieDataAll) = inArguments;
    // 获取cookieStorage
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray *cookieDataList = [cookieDataAll componentsSeparatedByString:@";"];
    for (NSString *cookieDataStr in cookieDataList) {
        NSArray *cookieDataArr = [cookieDataStr componentsSeparatedByString:@"="];
        if ([cookieDataArr count] == 2) {
            // 按照格式分割cookie
            NSString *cookieName = [cookieDataArr objectAtIndex:0];
            NSString *cookieValue = [cookieDataArr objectAtIndex:1];
            // 创建一个可变字典存放cookie
            NSMutableDictionary *cookieDict = [NSMutableDictionary dictionary];
            [cookieDict setObject:cookieName forKey:NSHTTPCookieName];
            [cookieDict setObject:cookieValue forKey:NSHTTPCookieValue];
            [cookieDict setObject:cookieUrl forKey:NSHTTPCookieOriginURL];
            [cookieDict setObject:@"/" forKey:NSHTTPCookiePath];
            // 将可变字典转化为cookie
            NSHTTPCookie *cookie = [NSHTTPCookie cookieWithProperties:cookieDict];
            // 存储cookie
            [cookieStorage setCookie:cookie];
        }
    }
}

- (NSString *)getCookie:(NSMutableArray *)inArguments {
    if ([inArguments count] < 1) {
        return nil;
    }
    NSString *httpStr = [inArguments objectAtIndex:0];
    NSHTTPCookieStorage *cookieJar = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSMutableArray *cookies = [NSMutableArray array];
    NSString *cookieAll = @"";
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
    NSDictionary * cookieDict = [NSDictionary dictionaryWithObject:cookieAll forKey:@"cookie"];
    [self callbackWithFunctionKeyPathByMainThread:@"uexXmlHttpMgr.cbGetCookie" arguments:ACArgsPack([cookieDict ac_JSONFragment])];
    return cookieAll;

}

#pragma mark - uexXmlHttpRequestDelegate

- (void)request:(__kindof uexXmlHttpRequest *)request taskCompleteWithError:(NSError *)error{
    NSString *responseStr = nil;
    NSHTTPURLResponse *response = request.response;

    if ([request.responseObject isKindOfClass:[NSData class]]) {
        responseStr = [[NSString alloc]initWithData:request.responseObject encoding:NSUTF8StringEncoding];
    }
    NSString *identifier = request.identifier;
    

    NSString *result = [self responseStringFromObject:request.responseObject];
    NSInteger statusCode = response.statusCode;
    NSMutableDictionary *responseDict = [NSMutableDictionary dictionary];
    [responseDict setValue:response.allHeaderFields forKey:@"responseHeaders"];
    [responseDict setValue:@(statusCode) forKey:@"responseStatusCode"];
    [responseDict setValue:[NSHTTPURLResponse localizedStringForStatusCode:statusCode] forKey:@"responseStatusMessage"];
    [responseDict setValue:error.localizedDescription forKey:@"responseError"];
    
    ACLogDebug(@"->uexXmlHttpMgr request %@ complete! \n response:%@ \n responseObject:%@ \n error:%@",identifier,responseDict,result,error.localizedDescription);
    [self jsCallbackExecuteByMainThread:request.resultCB withArguments:ACArgsPack(@(request.status),result,@(statusCode),responseDict)];
    [self callbackWithFunctionKeyPathByMainThread:@"uexXmlHttpMgr.onData" arguments:ACArgsPack(numberArg(identifier),@(request.status),result,@(statusCode),[responseDict JSONFragment])];
    request.resultCB = nil;
    request.progressCB = nil;

    
    
    
}
- (void)request:(__kindof uexXmlHttpRequest *)request sessionInvalidatedWithError:(NSError *)error{
    if (error) {
        ACLogDebug(@"->uexXmlHttpMgr request %@ invalidate session FAILED!error:%@",request.identifier,error.localizedDescription);
    }else{
        ACLogDebug(@"->uexXmlHttpMgr request %@ invalidate session SUCCESS!",request.identifier);
    }
    [self.requestDict removeObjectForKey:request.identifier];
    
}
- (void)request:(__kindof uexXmlHttpRequest *)request updateRequestProgress:(NSProgress *)progress{
    if (![request isKindOfClass:[uexXmlHttpPOSTRequest class]]) {
        return;
    }
    uexXmlHttpPOSTRequest *postRequest = (uexXmlHttpPOSTRequest *)request;
    ACLogDebug(@"->uexXmlHttpMgr request %@ update progress:%@%%",postRequest.identifier,@(postRequest.percent));
    [self jsCallbackExecuteByMainThread:request.progressCB withArguments:ACArgsPack(@(postRequest.percent))];
    [self callbackWithFunctionKeyPathByMainThread:@"uexXmlHttpMgr.onPostProgress" arguments:ACArgsPack(numberArg(postRequest.identifier),@(postRequest.percent))];
}

#pragma mark - Tool

- (NSString *)responseStringFromObject:(id)responseObj{
    NSString *responseStr = nil;
    if ([responseObj isKindOfClass:[NSData class]]) {
        responseStr = [[NSString alloc]initWithData:responseObj encoding:NSUTF8StringEncoding];
    }
    if ([responseObj isKindOfClass:[NSDictionary class]] || [responseObj isKindOfClass:[NSArray class]]) {
        responseStr = [responseObj JSONFragment];
    }
    if ([responseObj isKindOfClass:[NSString class]]) {
        responseStr = responseObj;
    }
    return responseStr;
}



- (uexXmlHttpPOSTRequest *)getPostRequestByIdentifier:(NSString *)identifier{
    __kindof uexXmlHttpRequest *request = self.requestDict[identifier];
    if ([request isKindOfClass:[uexXmlHttpPOSTRequest class]]) {
        return request;
    }
    return nil;
}

/**
 保证在主线程中完成JS回调操作
 
 @param jsFunc 回调JS方法
 @param args 参数
 */
- (void)jsCallbackExecuteByMainThread:(ACJSFunctionRef *)jsFunc withArguments:(NSArray *)args {
    if([NSThread isMainThread]){
        [jsFunc executeWithArguments:args];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [jsFunc executeWithArguments:args];
        });
    }
}

/**
 保证在主线程中完成JS回调操作
 
 @param jsString 回调需要执行的JS字符串
 */
- (void)callbackWithFunctionKeyPathByMainThread:(NSString *)JSKeyPath arguments:(nullable NSArray *)arguments {
    if([NSThread isMainThread]){
        [self.webViewEngine callbackWithFunctionKeyPath:JSKeyPath arguments:arguments];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.webViewEngine callbackWithFunctionKeyPath:JSKeyPath arguments:arguments];
        });
    }
}

@end
