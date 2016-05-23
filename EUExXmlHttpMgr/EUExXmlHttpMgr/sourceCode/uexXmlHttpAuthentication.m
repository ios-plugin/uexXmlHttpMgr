/**
 *
 *	@file   	: uexXmlHttpAuthentication.m  in EUExXmlHttpMgr
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

#import "uexXmlHttpAuthentication.h"
#import "WidgetOneDelegate.h"
#import "BUtility.h"



@implementation uexXmlHttpAuthentication


- (NSString *)clientCertificatePassword{
    if (!_clientCertificatePassword) {
        _clientCertificatePassword = theApp.useCertificatePassWord;
    }
    return _clientCertificatePassword;
}

- (NSData *)PKGCS12ClientCertificateData{
    if (!_PKGCS12ClientCertificateData) {
        _PKGCS12ClientCertificateData = [NSData dataWithContentsOfFile:[BUtility clientCertficatePath]];
    }
    return _PKGCS12ClientCertificateData;
}


- (NSURLSessionAuthChallengeDisposition)authChallengeDispositionWithSession:(NSURLSession *)session challenge:(NSURLAuthenticationChallenge *)challenge credential:(NSURLCredential *__autoreleasing *)credential{
    if(challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust) {
        //服务器认证
        /* 可以在这里添加服务器域名验证
         NSArray *trustHosts = @[@"www.baidu.com"];
         if (![trustHosts containsObject:challenge.protectionSpace.host]) {
         return NSURLSessionAuthChallengeCancelAuthenticationChallenge;
         }
         */
        //目前没有提供服务器的SSL证书认证功能,直接信任
        *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        return NSURLSessionAuthChallengeUseCredential;
    }
    
    if(challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodClientCertificate){
        //客户端认证
        SecIdentityRef identity=NULL;
        
        if (![self extractPKCS12Data:self.PKGCS12ClientCertificateData toIdentity:&identity]) {
            return NSURLSessionAuthChallengeCancelAuthenticationChallenge;
        }
        SecCertificateRef certificate = NULL;
        SecIdentityCopyCertificate (identity, &certificate);
        const void *certs[] = {certificate};
        CFArrayRef certArray = CFArrayCreate(kCFAllocatorDefault, certs, 1, NULL);
        *credential = [NSURLCredential credentialWithIdentity:identity certificates:(__bridge NSArray*)certArray persistence:NSURLCredentialPersistencePermanent];
        return NSURLSessionAuthChallengeUseCredential;
    }
    
    return NSURLSessionAuthChallengePerformDefaultHandling;
}

- (OSStatus)extractPKCS12Data:(NSData *)PKCS12Data toIdentity:(SecIdentityRef *)identity {
    if (!PKCS12Data || PKCS12Data.length == 0) {
        return errSecSuccess;
    }
    OSStatus result = errSecSuccess;
    CFDataRef inPKCS12Data = (CFDataRef)CFBridgingRetain(PKCS12Data);
    CFStringRef password = (__bridge CFStringRef)self.clientCertificatePassword;
    const void *keys[] = {kSecImportExportPassphrase};
    const void *values[] = {password};
    CFDictionaryRef options = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);
    CFArrayRef items = CFArrayCreate(NULL, 0, 0, NULL);
    result = SecPKCS12Import(inPKCS12Data, options, &items);
    if (result == 0) {
        CFDictionaryRef ident = CFArrayGetValueAtIndex(items,0);
        const void *tempIdentity = NULL;
        tempIdentity = CFDictionaryGetValue(ident, kSecImportItemIdentity);
        *identity = (SecIdentityRef)tempIdentity;
    }
    if(inPKCS12Data){
        CFRelease(inPKCS12Data);
    }
    if (options) {
        CFRelease(options);
    }
    return result;
}
@end
