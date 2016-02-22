//
//  XCRequestTool.h
//  Cocoapods学习
//
//  Created by xc on 16/2/18.
//  Copyright © 2016年 xc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XCRequestTool : NSObject

+ (BOOL)validateUrl:(NSString *)url;

+ (NSString *)md5String:(NSString *)string;

+ (void)addDoNotBackupAttribute:(NSString *)path;
@end
