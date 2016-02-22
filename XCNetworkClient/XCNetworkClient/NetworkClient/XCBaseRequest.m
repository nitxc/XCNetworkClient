//
//  XCBaseRequest.m
//  Cocoapods学习
//
//  Created by xc on 16/2/18.
//  Copyright © 2016年 xc. All rights reserved.
//

#import "XCBaseRequest.h"
#import "XCRequestManager.h"

NSString * const XCRequestWillStartNotification = @"com.XC-s.request.start";
NSString * const XCRequestDidFinishNotification = @"com.XC-s.request.finish";

@implementation XCBaseRequest


- (instancetype)init
{
    self = [super init];
    if (self) {
        self.requestBaseURL = @"www.baidu.com";
        self.requestURL = @"";
        self.requestTimeoutInterval = 60;
        self.requestMethod = XCRequestMethodGet;
        //Base Param
        self.requestParameters = [self query];
        self.requestSerializerType = XCRequestSerializerTypeForm;
        self.responseSerializerType = XCResponseSerializerTypeJSON;
        self.useCookies = YES;
        self.constructionBodyBlock = nil;
        self.validLoginStatus = true;
    }
    return self;
}

#pragma mark private

- (NSDictionary *)query
{
    //共有参数
    
    self.requestParameters = [NSMutableDictionary dictionary];
    
    [self.requestParameters setObject:@"ios" forKey:@"appKey"];
    [self.requestParameters setObject:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]?[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]:nil forKey:@"version"];
    [self.requestParameters setObject:self.idfvString forKey:@"deviceId"];
    
    //需要验证用户是否登录存取token值
//    if ([XC_AccountTool isLogin]) {
//        [self.requestParameters setObject:[[XC_AccountTool account] token] forKey:@"token"];
//    }
    
    
    return self.requestParameters;
}

- (NSString *)idfvString
{
    if([[UIDevice currentDevice] respondsToSelector:@selector(identifierForVendor)]) {
        return [[UIDevice currentDevice].identifierForVendor UUIDString];
    }
    
    return @"";
}

#pragma publick method

- (NSTimeInterval)requestTimeoutInterval
{
    return 60;
}

- (void)requestWillStartTag {
    if (self.requestStartBlock) {
        self.requestStartBlock(self);
    }
    
    if ([self.delegate respondsToSelector:@selector(requestWillStart:)]) {
        [self.delegate requestWillStart:self];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:XCRequestWillStartNotification object:self];
    });
    
    [self requestWillStart];
}

- (BOOL)isLoading
{
    
    return self.task.state != NSURLSessionTaskStateCompleted;
    
}

- (void)start {
    [self requestWillStartTag];
    [[XCRequestManager shareManager] startRequest:self];
}

- (void)startWithRequestSuccessBlock:(void(^)(XCBaseRequest *request))success  resultClass:(Class)resultClass failureBlock:(void(^)(XCBaseRequest *request))failure {
    self.responseClass = resultClass;
    [self setRequestSuccessBlock:success failureBlock:failure];
    [self start];
    
}

- (void)setRequestSuccessBlock:(void(^)(XCBaseRequest *request))success failureBlock:(void(^)(XCBaseRequest *request))failure {
    self.successCompletionBlock = success;
    self.failureCompletionBlock = failure;
}

- (void)stop {
    [[XCRequestManager shareManager] cancelRequest:self];
}

- (void)requestWillStart {
    
}

- (void)requestCompleteSuccess {
    
}

- (void)requestCompleteFailure {
    
}

- (void)methodPath
{
}

@end
