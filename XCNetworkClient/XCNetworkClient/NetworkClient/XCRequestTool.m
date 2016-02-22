//
//  XCRequestTool.m
//  Cocoapods学习
//
//  Created by xc on 16/2/18.
//  Copyright © 2016年 xc. All rights reserved.
//

#import "XCRequestTool.h"
#import <CommonCrypto/CommonDigest.h>

@implementation XCRequestTool

+ (BOOL)validateUrl:(NSString *)url {
    NSString *urlRegEx = @"(http|https)://((\\w)*|([0-9]*)|([-|_])*)+([\\.|/]((\\w)*|([0-9]*)|([-|_])*))+";
    NSPredicate *urlTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", urlRegEx];
    return [urlTest evaluateWithObject:url];
}

+ (NSString *)md5String:(NSString *)string {
    if (string.length <= 0) {
        return nil;
    }
    
    const char *value = [string UTF8String];
    unsigned char outputBuffer[CC_MD5_DIGEST_LENGTH];
    CC_MD5(value, (CC_LONG)strlen(value), outputBuffer);
    
    NSMutableString *outputString = [[NSMutableString alloc] initWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(NSInteger count = 0; count < CC_MD5_DIGEST_LENGTH; count++){
        [outputString appendFormat:@"%02x",outputBuffer[count]];
    }
    
    return outputString;
}

+ (void)addDoNotBackupAttribute:(NSString *)path {
    NSURL *url = [NSURL fileURLWithPath:path];
    NSError *error = nil;
    [url setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:&error];
    if (error) {
        NSLog(@"error in set back up attribute: %@", error.localizedDescription);
    }
}


@end
