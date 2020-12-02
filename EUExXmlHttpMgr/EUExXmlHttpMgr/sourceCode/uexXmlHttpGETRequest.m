/**
 *
 *	@file   	: uexXmlHttpGETRequest.m  in EUExXmlHttpMgr
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

#import "uexXmlHttpGETRequest.h"
#import "EUExXmlHttpMgr.h"
@implementation uexXmlHttpGETRequest

- (uexXmlHttpRequestMethod)method{
    return uexXmlHttpRequestMethodGET;
}

- (void)send{
    [super send];
    [self.manager GET:self.serverPath
           parameters:nil
              headers:nil
             progress:^(NSProgress * _Nonnull downloadProgress) {
                 [self.euexObj request:self updateRequestProgress:downloadProgress];
             }
              success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                  if ([task.response isKindOfClass:[NSHTTPURLResponse class]]) {
                      self.response = (NSHTTPURLResponse *)task.response;
                  }
                  self.status = uexXmlHttpRequestStatusSuccess;
                  self.responseObject = responseObject;
                  [self.euexObj request:self taskCompleteWithError:nil];
              }
              failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                  if ([task.response isKindOfClass:[NSHTTPURLResponse class]]) {
                      self.response = (NSHTTPURLResponse *)task.response;
                  }
                  self.status = uexXmlHttpRequestStatusFailed;
                  [self.euexObj request:self taskCompleteWithError:error];
              }];
}


@end
