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
#import "ACEUtils.h"
#import "EUtility.h"
@interface EUExXmlHttpMgr()

@property (nonatomic,strong)NSMutableDictionary<NSNumber *,__kindof uexXmlHttpRequest *> *requestDict;
@end

@implementation EUExXmlHttpMgr

static NSDictionary<NSString *,NSNumber *> *HTTPMethods = nil;


+ (void)initialize{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        HTTPMethods = @{
            @"get":@(uexXmlHttpRequestMethodGET),
            @"post":@(uexXmlHttpRequestMethodPOST)
            };
    });
}


- (instancetype)initWithBrwView:(EBrowserView *)eInBrwView{
    self = [super initWithBrwView:eInBrwView];
    if(self){
        _requestDict = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)clean{
    [self.requestDict enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, __kindof uexXmlHttpRequest * _Nonnull request, BOOL * _Nonnull stop) {
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

- (void)open:(NSMutableArray *)inArguments{
    if([inArguments count] < 3){
        return;
    }
    NSNumber *identifier = getIdentifier(inArguments[0]);
    NSString *methodStr = getString(inArguments[1]).lowercaseString;
    NSString *urlStr = getString(inArguments[2]);
    if (!identifier || [self.requestDict.allKeys containsObject:identifier] || !methodStr || ![HTTPMethods.allKeys containsObject:methodStr] || !urlStr || urlStr.length == 0) {
        return;
    }
    uexXmlHttpRequestMethod method = (uexXmlHttpRequestMethod)[HTTPMethods[methodStr] integerValue];
    uexXmlHttpRequest *request = [uexXmlHttpRequest requestWithMethod:method identifier:identifier euexObj:self];
    if (!request) {
        return;
    }
    request.serverPath = urlStr;
    if (inArguments.count > 3) {
        NSTimeInterval timeout = [inArguments[3] doubleValue];
        if (timeout >= 1) {
            request.timeoutInterval = timeout;
        }
    }
    [self.requestDict setObject:request forKey:identifier];
}

- (void)send:(NSMutableArray *)inArguments{
    if([inArguments count] < 1){
        return;
    }
    NSNumber *identifier = getIdentifier(inArguments[0]);
    [self.requestDict[identifier] send];
}

- (void)setAppVerify:(NSMutableArray *)inArguments{
    if([inArguments count] < 2){
        return;
    }
    NSNumber *identifier = getIdentifier(inArguments[0]);
    BOOL appVerifyEnabled = [inArguments[1] boolValue];
    self.requestDict[identifier].appVerifyEnabled = appVerifyEnabled;
}

- (void)setHeaders:(NSMutableArray *)inArguments{
    if([inArguments count] < 2){
        return;
    }
    NSNumber *identifier = getIdentifier(inArguments[0]);
    id headers = [inArguments[1] JSONValue];
    if (headers && [headers isKindOfClass:[NSDictionary class]]) {
        [self.requestDict[identifier] setHeaders:headers];
    }
}

- (void)close:(NSMutableArray *)inArguments{
    if([inArguments count] < 1){
        return;
    }
    NSNumber *identifier = getIdentifier(inArguments[0]);
    [self.requestDict[identifier] close];
}

- (void)setCertificate:(NSMutableArray *)inArguments{
    if ([inArguments count] < 3) {
        return;
    }
    NSNumber *identifier = getIdentifier(inArguments[0]);
    NSString *password = getString(inArguments[1]);
    NSString *certPath = getString(inArguments[2]);
    BOOL useAppCanCert = NO;
    if ([certPath.lowercaseString isEqual:@"default"]) {
        useAppCanCert = YES;
    }
    __kindof uexXmlHttpRequest *request = self.requestDict[identifier];
    uexXmlHttpAuthentication *auth = [[uexXmlHttpAuthentication alloc]init];
    if(!useAppCanCert){
        NSData *p12Data = [NSData dataWithContentsOfFile:[self absPath:certPath]];
        if (!p12Data) {
            return;
        }
        auth.PKGCS12ClientCertificateData = p12Data;
        auth.clientCertificatePassword = password;
    }
    request.authentication = auth;
}

- (void)setPostData:(NSMutableArray *)inArguments{
    if([inArguments count] < 4){
        return;
    }
    NSNumber *identifier = getIdentifier(inArguments[0]);
    NSInteger dataType = [inArguments[1] integerValue];
    NSString *field = getString(inArguments[2]);
    uexXmlHttpPOSTRequest *request = [self getPostRequestByIdentifier:identifier];
    if (!request) {
        return;
    }
    id obj = inArguments[3];
    switch (dataType) {
        case 0:{
            if ([obj isKindOfClass:[NSString class]] || [obj isKindOfClass:[NSNumber class]] || [obj isKindOfClass:[NSDictionary class]] || [obj isKindOfClass:[NSArray class]]) {
                [request setPostData:obj forField:field];
            }
            break;
        }
        case 1:{
            if ([obj isKindOfClass:[NSString class]]) {
                [request setFile:[self absPath:obj] forField:field];
            }
            break;
        }
        default:
            break;
    }

}

- (void)setInputStream:(NSMutableArray *)inArguments{
    if([inArguments count] < 2){
        return;
    }
    NSNumber *identifier = getIdentifier(inArguments[0]);
    NSString *filePath = getString(inArguments[1]);
    uexXmlHttpPOSTRequest *request = [self getPostRequestByIdentifier:identifier];
    if (!request) {
        return;
    }
    NSData *fileData = [NSData dataWithContentsOfFile:[self absPath:filePath]];
    [request setPostBody:fileData];
}
- (void)setBody:(NSMutableArray *)inArguments{
    if([inArguments count] < 2){
        return;
    }
    NSNumber *identifier = getIdentifier(inArguments[0]);
    NSString *body = getString(inArguments[1]);
    uexXmlHttpPOSTRequest *request = [self getPostRequestByIdentifier:identifier];
    if (!request) {
        return;
    }
    NSData *data = [body dataUsingEncoding:NSUTF8StringEncoding];
    [request setPostBody:data];
}
- (void)setDebugMode:(NSMutableArray *)inArguments{
    if([inArguments count] < 1){
        return;
    }
    [uexXmlHttpHelper setDebugMode:[inArguments[0] boolValue]];
}

-(void)clearCookie:(NSMutableArray *)inArguments {
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

-(void)getCookie:(NSMutableArray *)inArguments {
    if ([inArguments count] < 1) {
        return;
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
    if (ACE_Available()) {
        [EUtility browserView:self.meBrwView
  callbackWithFunctionKeyPath:@"uexXmlHttpMgr.cbGetCookie"
                    arguments:ACE_ArgsPack([cookieDict JSONFragment])
                   completion:nil];
    }else{
        NSString *jsStr = [NSString stringWithFormat:@"if(uexXmlHttpMgr.cbGetCookie){uexXmlHttpMgr.cbGetCookie(%@);}",[cookieDict JSONFragment].JSONFragment];
        [EUtility brwView:self.meBrwView evaluateScript:jsStr];
    }
}

#pragma mark - uexXmlHttpRequestDelegate

- (void)request:(__kindof uexXmlHttpRequest *)request taskCompleteWithError:(NSError *)error{
    NSString *responseStr = nil;
    NSHTTPURLResponse *response = request.response;

    if ([request.responseObject isKindOfClass:[NSData class]]) {
        responseStr = [[NSString alloc]initWithData:request.responseObject encoding:NSUTF8StringEncoding];
    }
    NSNumber *identifier = request.identifier;
    

    NSString *result = [self responseStringFromObject:request.responseObject];
    NSInteger statusCode = response.statusCode;
    NSMutableDictionary *responseDict = [NSMutableDictionary dictionary];
    [responseDict setValue:response.allHeaderFields forKey:@"responseHeaders"];
    [responseDict setValue:@(statusCode) forKey:@"responseStatusCode"];
    [responseDict setValue:[NSHTTPURLResponse localizedStringForStatusCode:statusCode] forKey:@"responseStatusMessage"];
    [responseDict setValue:error.localizedDescription forKey:@"responseError"];
    
    UEXLog(@"->uexXmlHttpMgr request %@ complete! \n response:%@ \n responseObject:%@ \n error:%@",identifier,responseDict,result,error.localizedDescription);
    
    if (ACE_Available()) {
        [EUtility browserView:self.meBrwView
  callbackWithFunctionKeyPath:@"uexXmlHttpMgr.onData"
                    arguments:ACE_ArgsPack(identifier,@(request.status),result,@(statusCode),[responseDict JSONFragment])
                   completion:nil];
    }else{
        NSString *resultJSON = result ? [result JSONFragment] : @"(null)";
        NSString *jsStr = [NSString stringWithFormat:@"if(uexXmlHttpMgr.onData){uexXmlHttpMgr.onData(%@,%@,%@,%@,%@);}",identifier,@(request.status),resultJSON,@(statusCode),[responseDict JSONFragment].JSONFragment];
        NSLog(@"%@",jsStr);
        [EUtility brwView:self.meBrwView evaluateScript:jsStr];
    }
    
    
    
}
- (void)request:(__kindof uexXmlHttpRequest *)request sessionInvalidatedWithError:(NSError *)error{
    if (error) {
        UEXLog(@"->uexXmlHttpMgr request %@ invalidate session FAILED!error:%@",request.identifier,error.localizedDescription);
    }else{
        UEXLog(@"->uexXmlHttpMgr request %@ invalidate session SUCCESS!",request.identifier);
    }
    [self.requestDict removeObjectForKey:request.identifier];
    
}
- (void)request:(__kindof uexXmlHttpRequest *)request updateRequestProgress:(NSProgress *)progress{
    if (![request isKindOfClass:[uexXmlHttpPOSTRequest class]]) {
        return;
    }
    uexXmlHttpPOSTRequest *postRequest = (uexXmlHttpPOSTRequest *)request;
    UEXLog(@"->uexXmlHttpMgr request %@ update progress:%@%%",postRequest.identifier,@(postRequest.percent));
    
    if (ACE_Available()) {
        [EUtility browserView:self.meBrwView
  callbackWithFunctionKeyPath:@"uexXmlHttpMgr.onPostProgress"
                    arguments:ACE_ArgsPack(postRequest.identifier,@(postRequest.percent))
                   completion:nil];
    }else{
        NSString *jsStr = [NSString stringWithFormat:@"if(uexXmlHttpMgr.onPostProgress){uexXmlHttpMgr.onPostProgress(%@,%@);}",postRequest.identifier,@(postRequest.percent)];
        [EUtility brwView:self.meBrwView evaluateScript:jsStr];
    }
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

static NSString * getString(id obj){
    NSString *str = nil;
    if ([obj isKindOfClass:[NSString class]]) {
        str = obj;
    }
    if ([obj isKindOfClass:[NSNumber class]]) {
        str = [obj stringValue];
    }
    return str;
}
static NSNumber * getIdentifier(id obj){
    NSNumber *num = nil;
    if ([obj isKindOfClass:[NSString class]] && [obj length] > 0) {
        num = [NSDecimalNumber decimalNumberWithString:obj];
    }
    if ([obj isKindOfClass:[NSNumber class]]) {
        num = obj;
    }
    return num;
}


- (uexXmlHttpPOSTRequest *)getPostRequestByIdentifier:(NSNumber *)identifier{
    __kindof uexXmlHttpRequest *request = self.requestDict[identifier];
    if ([request isKindOfClass:[uexXmlHttpPOSTRequest class]]) {
        return request;
    }
    return nil;
}

@end
