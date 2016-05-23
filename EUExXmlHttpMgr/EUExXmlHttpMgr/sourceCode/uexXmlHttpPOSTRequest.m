/**
 *
 *	@file   	: uexXmlHttpPOSTRequest.m  in EUExXmlHttpMgr
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

#import "uexXmlHttpPOSTRequest.h"
#import "EUExXmlHttpMgr.h"
#import "ACEUtils.h"
#import "uexXmlHttpFormFile.h"
#import "uexXmlHttpHelper.h"
typedef NS_ENUM(NSInteger,uexXmlHttpPOSTRequestConstructMode){
    uexXmlHttpPOSTRequestConstructModeDefault,
    uexXmlHttpPOSTRequestConstructModeMultipart,
    uexXmlHttpPOSTRequestConstructModeUserModified
};


@interface uexXmlHttpPOSTRequest()
@property (nonatomic,strong)NSMutableDictionary * params;
@property (nonatomic,strong)NSMutableDictionary<NSString *,uexXmlHttpFormFile *> * files;
@property (nonatomic,assign)uexXmlHttpPOSTRequestConstructMode mode;
@property (nonatomic,strong)NSData *bodyData;

@end



@implementation uexXmlHttpPOSTRequest

- (instancetype)initWithEuexObj:(EUExXmlHttpMgr *)euexObj
{
    self = [super initWithEuexObj:euexObj];
    if (self) {
        _params = [NSMutableDictionary dictionary];
        _files = [NSMutableDictionary dictionary];
        _mode = uexXmlHttpPOSTRequestConstructModeDefault;
    }
    return self;
}


- (void)setPostBody:(NSData *)bodyData{
    if(!bodyData){
        return;
    }
    self.bodyData = bodyData;
    self.mode = uexXmlHttpPOSTRequestConstructModeUserModified;
}

- (void)setPostData:(id)data forField:(NSString *)field{
    [self.params setValue:data forKey:field];
}

- (void)setFile:(NSString *)filePath forField:(NSString *)field{
    uexXmlHttpFormFile *file = [[uexXmlHttpFormFile alloc]initWithFilePath:filePath];
    [self.files setValue:file forKey:field];
    if (self.mode == uexXmlHttpPOSTRequestConstructModeDefault) {
        self.mode = uexXmlHttpPOSTRequestConstructModeMultipart;
    }
}

- (uexXmlHttpRequestMethod)method{
    return uexXmlHttpRequestMethodPOST;
}


- (void)send{
    [super send];
    
    void (^handleProgressBlock)(NSProgress * _Nonnull uploadProgress) = ^(NSProgress * _Nonnull uploadProgress){
        NSInteger percent = (NSInteger)(uploadProgress.fractionCompleted * 100);
        if (percent == 0 || percent == 100 || percent != self.percent) {
            self.percent = percent;
            [self.euexObj request:self updateRequestProgress:uploadProgress];
        }
        
    };
    void (^handleSuccessBlock)(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) = ^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject){
        if ([task.response isKindOfClass:[NSHTTPURLResponse class]]) {
            self.response = (NSHTTPURLResponse *)task.response;
        }
        self.status = uexXmlHttpRequestStatusSuccess;
        self.responseObject = responseObject;
        [self.euexObj request:self taskCompleteWithError:nil];
    };
    void (^handleFailureBlock)(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) = ^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error){
        if ([task.response isKindOfClass:[NSHTTPURLResponse class]]) {
            self.response = (NSHTTPURLResponse *)task.response;
        }
        self.status = uexXmlHttpRequestStatusFailed;
        [self.euexObj request:self taskCompleteWithError:error];
    };
    
    
    
    switch (self.mode) {
        case uexXmlHttpPOSTRequestConstructModeDefault: {
            [self.manager POST:self.serverPath
                    parameters:self.params
                      progress:handleProgressBlock
                       success:handleSuccessBlock
                       failure:handleFailureBlock];
            break;
        }
        case uexXmlHttpPOSTRequestConstructModeMultipart: {
            [self.manager POST:self.serverPath
                    parameters:self.params
     constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
         [self.files enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, uexXmlHttpFormFile * _Nonnull obj, BOOL * _Nonnull stop) {
             NSData *data = obj.fileData;
             if (data) {
                 [formData appendPartWithFileData:data  name:key fileName:obj.fileName mimeType:obj.MIMEType];
             }
         }];
         [self.files removeAllObjects];
     }
                      progress:handleProgressBlock
                       success:handleSuccessBlock
                       failure:handleFailureBlock];
            break;
        }
        case uexXmlHttpPOSTRequestConstructModeUserModified: {
            NSError *serializationError = nil;
            NSMutableURLRequest *request = [self.manager.requestSerializer
                                            requestWithMethod:@"POST"
                                            URLString:self.serverPath
                                            parameters:nil
                                            error:&serializationError];
            
            if (serializationError) {
                handleFailureBlock(nil,serializationError);
                return;
            }
            request.HTTPBody = self.bodyData;
            __block NSURLSessionDataTask *dataTask = nil;
            dataTask = [self.manager dataTaskWithRequest:request
                                          uploadProgress:handleProgressBlock
                                        downloadProgress:nil
                                       completionHandler:^(NSURLResponse * __unused response, id responseObject, NSError *error) {

                                           if (error) {
                                               handleFailureBlock(dataTask, error);
                                           }else {
                                               handleSuccessBlock(dataTask, responseObject);
                                           }
                                       }];
            [dataTask resume];
            break;
        }
    }

}
@end
