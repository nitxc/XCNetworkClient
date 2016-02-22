//
//  XCRequestManager.m
//  Cocoapods学习
//
//  Created by xc on 16/2/18.
//  Copyright © 2016年 xc. All rights reserved.
//

#import "XCRequestManager.h"
#import <YYModel.h>
#import "XCRequestTool.h"
#import <AFNetworkActivityIndicatorManager.h>
#import "XCBaseResult.h"

#define XC_HTTP_COOKIE_KEY @"XCHTTPCookieKey"

NSString * const XCRequestOutOfNetwork = @"com.XC-s.request.outOfNetwork";

typedef NS_ENUM(NSInteger, XCRequestError) {
    XCRequestErrorOutOfNetwork = 0
};
@interface XCRequestManager()

@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;

@property (nonatomic, strong) AFURLSessionManager *urlSessionManager;

@property (nonatomic, strong) NSMutableDictionary *requests;

@end

@implementation XCRequestManager

+ (instancetype)shareManager {
    
    static XCRequestManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

#pragma mark - Setter
- (void)setMaxConcurrentRequestCount:(NSInteger)maxConcurrentRequestCount {
    self.sessionManager.operationQueue.maxConcurrentOperationCount = maxConcurrentRequestCount;
}

#pragma mark - Private
- (instancetype)init {
    
    self = [super init];
    if (self) {
        self.sessionManager = [AFHTTPSessionManager manager];
        self.requests = [NSMutableDictionary dictionary];
        self.maxConcurrentRequestCount = 4;
        self.urlSessionManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    }
    return self;
}
- (NSString *)configRequestURL:(XCBaseRequest *)request {
 
    // 初始化url
    [request methodPath];
    
    if ([request.requestURL hasPrefix:@"http"]) {
        return request.requestURL;
    }
    
    if ([request.requestBaseURL hasPrefix:@"http"]) {
        return [NSString stringWithFormat:@"%@%@", request.requestBaseURL, request.requestURL];
    } else {
        NSLog(@"未配置好请求地址 %@ requestURL: %@", request.requestBaseURL, request.requestURL);
        return @"";
    }
}

#pragma mark - cookies
- (void)saveCookies {
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray *cookies = [cookieStorage cookies];
    if (cookies.count > 0) {
        NSData *cookieData = [NSKeyedArchiver archivedDataWithRootObject:cookies];
        
        [[NSUserDefaults standardUserDefaults] setObject:cookieData forKey:XC_HTTP_COOKIE_KEY];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)loadCookies {
    id cookieData = [[NSUserDefaults standardUserDefaults] objectForKey:XC_HTTP_COOKIE_KEY];
    if (!cookieData) {
        return;
    }
    NSArray *cookies = [NSKeyedUnarchiver unarchiveObjectWithData:cookieData];
    if ([cookies isKindOfClass:[NSArray class]] && cookies.count > 0) {
        NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        for (NSHTTPCookie *cookie in cookies) {
            [cookieStorage setCookie:cookie];
        }
    }
}
#pragma mark - 请求结束处理
- (void)requestDidFinishTag:(XCBaseRequest *)request {
    
    if (request.error) {
        if (request.failureCompletionBlock) {
            request.failureCompletionBlock(request);
        }
        
        if ([request.delegate respondsToSelector:@selector(requestDidFailure:)]) {
            [request.delegate requestDidFailure:request];
        }
        
        [request requestCompleteFailure];
        
    } else {
        if (request.successCompletionBlock) {
            request.successCompletionBlock(request);
        }
        
        if ([request.delegate respondsToSelector:@selector(requestDidSuccess:)]) {
            [request.delegate requestDidSuccess:request];
        }
        
        [request requestCompleteSuccess];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:XCRequestDidFinishNotification object:request];
    });
}

- (void)handleReponseResult:(NSURLSessionDataTask *)task response:(id)responseObject error:(NSError *)error{
    
    NSString *key = [self taskHashKey:task];
    XCBaseRequest *request = self.requests[key];
    
    // 需要我们自动转换(采用YYModel)
    
    request.responseObject = [request.responseClass yy_modelWithJSON:responseObject];
    
    request.error = error;
    
    // 使用cookie时需要保存cookie
    if (request.useCookies) {
        [self saveCookies];
    }
    
    // 发送结束tag
    [self requestDidFinishTag:request];
    
    // 请求成功后移除此次请求
    [self removeRequest:task];
    
    // 异步登陆提示
    
    if (request.isValidLoginStatus) {
        
        [self sendAuthorLoginFailNotificaitonWithRequest:request];
        
        
    }
    
    
}

- (void)sendAuthorLoginFailNotificaitonWithRequest:(XCBaseRequest *)request
{
    
//    XC_BaseResult *baseResult = (XC_BaseResult *)request.responseObject;
    
//    if ([baseResult.errCode isEqualToString:AtherLogin]) {
//        //token过期重新登录
//        [[NSNotificationCenter defaultCenter] postNotificationName:kStatueFailed object:nil];
//    }else if ([baseResult.errCode isEqualToString:RestrictCode]){
//        //账号异常，被系统限制
//        [[NSNotificationCenter defaultCenter] postNotificationName:kStatueRestrict object:nil userInfo:@{@"reason":baseResult.errMsg}];
//    }
    
}

- (NSString *)taskHashKey:(NSURLSessionDataTask *)task
{
    return [NSString stringWithFormat:@"%lu", (unsigned long)[task hash]];
}

// 管理`request`的生命周期, 防止多线程处理同一key
- (void)addRequest:(XCBaseRequest *)request {
    
    if (request.task) {
        NSString *key = [self taskHashKey:request.task];
        @synchronized(self) {
            [self.requests setValue:request forKey:key];
        }
    }
}

- (void)removeRequest:(NSURLSessionDataTask *)task {
    
    NSString *key = [self taskHashKey:task];
    @synchronized(self) {
        [self.requests removeObjectForKey:key];
    }
}

#pragma mark - Public
- (void)startRequest:(XCBaseRequest *)request {
    
    
    // 使用cookie
    if (request.useCookies) {
        [self loadCookies];
    }
    
    // 处理URL
    NSString *urlCoded = [self configRequestURL:request];
    
    NSString *url = [urlCoded stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet];
    
    NSLog(@"请求url:%@", url);
    NSLog(@"-----------------分割线--------------");
    
    
    
    if (![XCRequestTool validateUrl:url]) {
        NSLog(@"error in url format：%@", url);
        return;
    }
    
    // 处理参数
    id params = request.requestParameters;
    
    NSLog(@"请求参数:%@", params);

    if (request.requestSerializerType == XCRequestSerializerTypeJSON) {
        if (![NSJSONSerialization isValidJSONObject:params] && params) {
            NSLog(@"error in JSON parameters：%@", params);
            return;
        }
    }
    
    // 处理序列化类型
    XCRequestSerializerType requestSerializerType = request.requestSerializerType;
    switch (requestSerializerType) {
        case XCRequestSerializerTypeForm:
            self.sessionManager.requestSerializer = [AFHTTPRequestSerializer serializer];
            break;
        case XCRequestSerializerTypeJSON:
            self.sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
        default:
            break;
    }
    self.sessionManager.requestSerializer.timeoutInterval = request.requestTimeoutInterval;
    
    XCResponseSerializerType responseSerializerType = request.responseSerializerType;
    switch (responseSerializerType) {
        case XCResponseSerializerTypeJSON:
            self.sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
            break;
        case XCResponseSerializerTypeHTTP:
            self.sessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
            break;
        default:
            break;
    }
    self.sessionManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/html", @"text/xml", @"text/plain", @"text/json", @"text/javascript", @"image/png", @"image/jpeg", @"application/json", nil];
    
    // 处理请求
    XCRequestMethod requestMethod = request.requestMethod;
    NSURLSessionDataTask *task = nil;
    switch (requestMethod) {
        case XCRequestMethodGet:
        {
            task = [self.sessionManager GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                [self handleReponseResult:task response:responseObject error:nil];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                [self handleReponseResult:task response:nil error:error];
            }];
            
        }
            break;
            
        case XCRequestMethodPost:
        {
            if ([request constructionBodyBlock]) {
                // 图片上传
                task = [self.sessionManager POST:url parameters:params constructingBodyWithBlock:[request constructionBodyBlock] progress:^(NSProgress * _Nonnull uploadProgress) {
                    
                    if (request.uploadProgress) {
                        request.uploadProgress(uploadProgress);

                    }
                    
                } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                    [self handleReponseResult:task response:responseObject error:nil];
                } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                    [self handleReponseResult:task response:nil error:error];
                }];
                
//                NSMutableURLRequest *upLoadrequest = [[AFHTTPRequestSerializer serializer] multipartFormRequestWithMethod:@"POST" URLString:url parameters:params constructingBodyWithBlock:[request constructionBodyBlock] error:nil];
//                
//                task = [self.urlSessionManager uploadTaskWithStreamedRequest:upLoadrequest progress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
//                   
//                    [self handleReponseResult:task response:responseObject error:error];
//
//                    
//                }];
//                [task resume];
                
            } else {
                task = [self.sessionManager POST:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                    [self handleReponseResult:task response:responseObject error:nil];
                } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                    [self handleReponseResult:task response:nil error:error];
                }];
            }
        }
            break;
            
        case XCRequestMethodPut:
        {
            task = [self.sessionManager PUT:url parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                [self handleReponseResult:task response:responseObject error:nil];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                [self handleReponseResult:task response:nil error:error];
            }];
        }
            break;
            
        case XCRequestMethodDelete:
        {
            task = [self.sessionManager DELETE:url parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                [self handleReponseResult:task response:responseObject error:nil];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                [self handleReponseResult:task response:nil error:error];
            }];
        }
            break;
        default:
            break;
    }
    
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    
    request.task = task;
    [self addRequest:request];
}

- (void)cancelRequest:(XCBaseRequest *)request {
    
    [request.task cancel];
    [self removeRequest:request.task];
}

- (void)cancelAllRequests {
    for (NSString *key in self.requests) {
        XCBaseRequest *request = self.requests[key];
        [self cancelRequest:request];
    }
}

- (void)startNetworkStateMonitoring {
    [self.sessionManager.reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
            case AFNetworkReachabilityStatusUnknown:
                _reachabilityStatus = XCRequestReachabilityStatusUnknow;
                break;
            case AFNetworkReachabilityStatusNotReachable:
                _reachabilityStatus = XCRequestReachabilityStatusNotReachable;
                break;
            case AFNetworkReachabilityStatusReachableViaWWAN:
                _reachabilityStatus = XCRequestReachabilityStatusViaWWAN;
                break;
            case AFNetworkReachabilityStatusReachableViaWiFi:
                _reachabilityStatus = XCRequestReachabilityStatusViaWiFi;
                break;
            default:
                break;
        }
    }];
    [self.sessionManager.reachabilityManager startMonitoring];
}

@end
