//
//  XCRequestManager.h
//  Cocoapods学习
//
//  Created by xc on 16/2/18.
//  Copyright © 2016年 xc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XCBaseRequest.h"


typedef NS_ENUM(NSInteger, XCRequestReachabilityStatus) {
    XCRequestReachabilityStatusUnknow = 0,
    XCRequestReachabilityStatusNotReachable,
    XCRequestReachabilityStatusViaWWAN,
    XCRequestReachabilityStatusViaWiFi
};
@interface XCRequestManager : NSObject


+ (instancetype)shareManager;

// default 4
@property (nonatomic, assign) NSInteger maxConcurrentRequestCount;

@property (nonatomic, assign, readonly) XCRequestReachabilityStatus reachabilityStatus;

- (void)startRequest:(XCBaseRequest *)request;
- (void)cancelRequest:(XCBaseRequest *)request;
- (void)cancelAllRequests;

// start monitor network status
- (void)startNetworkStateMonitoring;

@end

FOUNDATION_EXPORT NSString * const XCRequestOutOfNetwork;