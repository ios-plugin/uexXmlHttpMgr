/**
 *
 *	@file   	: uexXmlHttpRequest.h  in EUExXmlHttpMgr
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
 
#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>
#import "uexXmlHttpAuthentication.h"





@class EUExXmlHttpMgr;


typedef NS_ENUM(NSInteger,uexXmlHttpRequestMethod){
    uexXmlHttpRequestMethodPOST,
    uexXmlHttpRequestMethodGET
};

typedef NS_ENUM(NSInteger,uexXmlHttpRequestStatus){
    uexXmlHttpRequestStatusFailed = -1,
    uexXmlHttpRequestStatusRunning,
    uexXmlHttpRequestStatusSuccess,
};



/**
 *  abstract class
 */
@interface uexXmlHttpRequest : NSObject
@property (nonatomic,assign)uexXmlHttpRequestStatus status;
@property (nonatomic,assign,readonly)uexXmlHttpRequestMethod method;

@property (nonatomic,assign)NSTimeInterval timeoutInterval;
@property (nonatomic,strong)uexXmlHttpAuthentication *authentication;
@property (nonatomic,strong)NSNumber *identifier;
@property (nonatomic,strong)NSString *serverPath;
@property (nonatomic,strong)NSDictionary *headers;
@property (nonatomic,assign)BOOL appVerifyEnabled;

@property (nonatomic,strong)NSHTTPURLResponse *response;
@property (nonatomic,strong)id responseObject;




+ (instancetype)requestWithMethod:(uexXmlHttpRequestMethod)method identifier:(NSNumber *)identifier euexObj:(EUExXmlHttpMgr *)euexObj;
- (void)close;

#pragma mark - subclass MUST override the methods below!
- (uexXmlHttpRequestMethod)method;
- (void)send NS_REQUIRES_SUPER;







@end


#pragma mark - Private

@interface uexXmlHttpRequest()
@property (nonatomic,weak)EUExXmlHttpMgr *euexObj;
@property (nonatomic,strong)AFHTTPSessionManager *manager;



- (instancetype)initWithEuexObj:(EUExXmlHttpMgr *)euexObj NS_REQUIRES_SUPER;

@end





@protocol uexXmlHttpRequestDelegate <NSObject>
- (void)request:(__kindof uexXmlHttpRequest *)request sessionInvalidatedWithError:(NSError *)error;
- (void)request:(__kindof uexXmlHttpRequest *)request taskCompleteWithError:(NSError *)error;
- (void)request:(__kindof uexXmlHttpRequest *)request updateRequestProgress:(NSProgress *)progress;
@end

