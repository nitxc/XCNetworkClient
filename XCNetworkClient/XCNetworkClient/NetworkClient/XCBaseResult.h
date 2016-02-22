//
//  XC_BaseResult.h
//  XC-S
//
//  Created by xc on 15/7/8.
//  Copyright (c) 2015年 XChe. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XCBaseResult : NSObject
@property (nonatomic, copy) NSString *errCode;
@property (nonatomic, copy) NSString *errMsg;
/**
 *  返回成功标志
 */
@property (nonatomic, assign) BOOL success;
@end
