#import "uexXmlHttpPATCHRequest.h"
#import "EUExXmlHttpMgr.h"

#import "uexXmlHttpHelper.h"

@interface uexXmlHttpPATCHRequest()
@property (nonatomic,strong)NSData *bodyData;

@end

@implementation uexXmlHttpPATCHRequest

- (instancetype)initWithEuexObj:(EUExXmlHttpMgr *)euexObj
{
    self = [super initWithEuexObj:euexObj];
    return self;
}

- (void)setPATCHBody:(NSData *)bodyData{
    if(!bodyData){
        return;
    }
    self.bodyData = bodyData;
}

- (uexXmlHttpRequestMethod)method{
    return uexXmlHttpRequestMethodPATCH;
}

- (void)setBody:(NSData *)bodyData {
    [self setPATCHBody:bodyData];
}

- (void)send{
    [super send];
    
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

    NSError *serializationError = nil;
    NSMutableURLRequest *request = [self.manager.requestSerializer
                                    requestWithMethod:@"PATCH"
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
                                  uploadProgress:nil
                                downloadProgress:nil
                               completionHandler:^(NSURLResponse * __unused response, id responseObject, NSError *error) {
                                   if (error) {
                                       handleFailureBlock(dataTask, error);
                                   }else {
                                       handleSuccessBlock(dataTask, responseObject);
                                   }
                               }];
    [dataTask resume];
    
}
@end
