//
//  XCBaseRequest.h
//  Cocoapods学习
//
//  Created by xc on 16/2/18.
//  Copyright © 2016年 xc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking.h>


/**
 *  HTTP request method
 */
typedef NS_ENUM(NSInteger , XCRequestMethod) {
    XCRequestMethodGet = 0,
    XCRequestMethodPost,
    XCRequestMethodPut,
    XCRequestMethodDelete
};

/**
 *  request serializer type
 */
typedef NS_ENUM(NSInteger, XCRequestSerializerType) {
    /**
     *  content-type: application/x-www-form-urlencoded not json type
     */
    XCRequestSerializerTypeForm = 0,
    /**
     *  content-type: application/json
     */
    XCRequestSerializerTypeJSON
};

/**
 *  response serializer type
 */
typedef NS_ENUM(NSInteger, XCResponseSerializerType) {
    /**
     *  get the origin data from server
     */
    XCResponseSerializerTypeHTTP = 0,
    /**
     *  JSON from server
     */
    XCResponseSerializerTypeJSON
};

@class XCBaseRequest;

typedef void(^XCRequestCompletionBlock)(__kindof XCBaseRequest *request);

@class XCBaseRequest;

@protocol XCRequestDelegate <NSObject>

@optional

- (void)requestWillStart:(XCBaseRequest *)request;
- (void)requestDidSuccess:(XCBaseRequest *)request;
- (void)requestDidFailure:(XCBaseRequest *)request;

@end


@interface XCBaseRequest : NSObject

@property (nonatomic, strong) NSURLSessionDataTask *task;

//------------------处理返回值的方式----------------------
// block
// `requestStartBlock`should not call `start`
@property (nonatomic, copy) void(^requestStartBlock)(XCBaseRequest *);

@property (nonatomic, copy) void (^uploadProgress)(NSProgress *progress);

@property (nonatomic, copy) XCRequestCompletionBlock successCompletionBlock;

@property (nonatomic, copy) XCRequestCompletionBlock failureCompletionBlock;

@property (nonatomic, strong) NSMutableArray *requestAccessories;

@property (nonatomic, strong) id responseObject;

@property (nonatomic, readonly) NSInteger responseStatusCode;

@property (nonatomic, strong) Class responseClass;

@property (nonatomic, strong) NSError *error;

@property (nonatomic, assign, getter=isValidLoginStatus) BOOL validLoginStatus;//是否校验登陆提示 default true

// delegate
@property (nonatomic, weak) id <XCRequestDelegate> delegate;

//-----------------------------------------------------

/**
 *  custom properties
 *
 */

@property (nonatomic, copy) NSString *requestBaseURL;

// default is ``
@property (nonatomic, copy) NSString *requestURL;

// default is 60
@property (nonatomic, assign) NSTimeInterval requestTimeoutInterval;

// default is `XCRequestMethodGET`
@property (nonatomic, assign) XCRequestMethod requestMethod;

// default is save appKey、 version、 deviceId ,if login will save token.
@property (nonatomic, strong) id requestParameters;

// default is `XCRequestSerializerTypeJSON`
@property (nonatomic, assign) XCRequestSerializerType requestSerializerType;

// default is `XCResponseSerializerTypeJSON`
@property (nonatomic, assign) XCResponseSerializerType responseSerializerType;

// default is YES
@property (nonatomic, assign) BOOL useCookies;

// POST upload request such as images, default nil
@property (nonatomic, copy) void (^constructionBodyBlock)(id<AFMultipartFormData>formData);

/**
 *  if overwrite, call super or call `startRequest:` in `XCRequestManager`. `start` method invoke the will start tag and begin the request
 */
- (void)start;

- (void)startWithRequestSuccessBlock:(void(^)(XCBaseRequest *request))success resultClass:(Class)resultClass failureBlock:(void(^)(XCBaseRequest *request))failure;

- (void)stop;

- (BOOL)isLoading;

/**
 *  操作接口号路径
 *
 *  @return
 */
- (void)methodPath;

/// 请求的连接超时时间，默认为60秒
- (NSTimeInterval)requestTimeoutInterval;

// toggle when requst start
- (void)requestWillStart;

// toggle when request success
- (void)requestCompleteSuccess;

// toggle when request failure
- (void)requestCompleteFailure;

// set `requestStartBlock`, `requestSuccessBlock`, `requestFailureBlock` to nil
//- (void)clearRequestBlock;



@end
/**
 *  通知
 */
FOUNDATION_EXPORT NSString * const XCRequestWillStartNotification;
FOUNDATION_EXPORT NSString * const XCRequestDidFinishNotification;
