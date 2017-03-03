/**
 *
 *	@file   	: uexXmlHttpRequest.m  in EUExXmlHttpMgr
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

#import "uexXmlHttpRequest.h"
#import "uexXmlHttpGETRequest.h"
#import "uexXmlHttpPOSTRequest.h"
#import "EUExXmlHttpMgr.h"
#import "uexXmlHttpHelper.h"
#import <AppCanKit/ACEXTScope.h>
@implementation uexXmlHttpRequest

+ (instancetype)requestWithMethod:(uexXmlHttpRequestMethod)method identifier:(NSString *)identifier euexObj:(EUExXmlHttpMgr *)euexObj{
    __kindof uexXmlHttpRequest *request = nil;
    
    switch (method) {
        case uexXmlHttpRequestMethodPOST: {
            request = [[uexXmlHttpPOSTRequest alloc]initWithEuexObj:euexObj];
            break;
        }
        case uexXmlHttpRequestMethodGET: {
            request = [[uexXmlHttpGETRequest alloc]initWithEuexObj:euexObj];
            break;
        }
    }
    request.identifier = identifier;
    return request;
}


- (instancetype)initWithEuexObj:(EUExXmlHttpMgr *)euexObj
{
    self = [super init];
    if (self) {
        _euexObj = euexObj;
        _timeoutInterval = 30;
        AFHTTPSessionManager *mgr = [[AFHTTPSessionManager alloc]initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        [mgr setRequestSerializer:[AFHTTPRequestSerializer serializer]];
        [mgr setResponseSerializer:[AFHTTPResponseSerializer serializer]];
        @weakify(self);
        [mgr setSessionDidBecomeInvalidBlock:^(NSURLSession * _Nonnull session, NSError * _Nonnull error) {
            @strongify(self);
            [self.euexObj request:self sessionInvalidatedWithError:error];
        }];
        [mgr setTaskDidCompleteBlock:^(NSURLSession * _Nonnull session, NSURLSessionTask * _Nonnull task, NSError * _Nullable error) {
            @strongify(self);
            [self close];
        }];
        _manager = mgr;
        
    }
    return self;
}

- (void)close{
    [self.manager invalidateSessionCancelingTasks:YES];
}

- (void)setupAuthentication{
    if ([self.serverPath.lowercaseString hasPrefix:@"https://"] && self.authentication) {
        @weakify(self);
        [self.manager setTaskDidReceiveAuthenticationChallengeBlock:^NSURLSessionAuthChallengeDisposition(NSURLSession * _Nonnull session, NSURLSessionTask * _Nonnull task, NSURLAuthenticationChallenge * _Nonnull challenge, NSURLCredential *__autoreleasing  _Nullable * _Nullable credential) {
            @strongify(self);
            return [self.authentication authChallengeDispositionWithSession:session challenge:challenge credential:credential];
        }];
        [self.manager setSessionDidReceiveAuthenticationChallengeBlock:^NSURLSessionAuthChallengeDisposition(NSURLSession * _Nonnull session, NSURLAuthenticationChallenge * _Nonnull challenge, NSURLCredential *__autoreleasing  _Nullable * _Nullable credential) {
            @strongify(self);
            return [self.authentication authChallengeDispositionWithSession:session challenge:challenge credential:credential];
        }];
    }else if(!self.certificateValidationEnabled){
        self.manager.securityPolicy.validatesDomainName = NO;
        self.manager.securityPolicy.allowInvalidCertificates = YES;
    }
    
    

}




#pragma mark - must override

- (uexXmlHttpRequestMethod)method{
    NSAssert(self.class != [uexXmlHttpRequest class], @"subclass MUST override this method:%s",__func__);
    return uexXmlHttpRequestMethodPOST;
}

- (void)send{
    NSAssert(self.class != [uexXmlHttpRequest class], @"subclass MUST override this method:%s",__func__);
    [self.manager.requestSerializer setTimeoutInterval:self.timeoutInterval];
    [self.headers enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if (![key isKindOfClass:[NSString class]] || ![obj isKindOfClass:[NSString class]]) {
            return;
        }
        [self.manager.requestSerializer setValue:obj forHTTPHeaderField:key];
    }];
    if (self.appVerifyEnabled) {
        [[uexXmlHttpHelper AppCanHTTPHeadersWithEUExObj:self.euexObj] enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
            [self.manager.requestSerializer setValue:obj forHTTPHeaderField:key];
        }];
    }
    [self setupAuthentication];
}


@end
