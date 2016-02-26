//
//  WNJsonDataLoader.m
//  WeathernewsTouch
//
//  Created by Tomohiro Tashiro on 2015/03/02.
//  Copyright (c) 2015年 weathernews. All rights reserved.
//

#import "WNJsonDataLoader.h"
#import "NSObject+FRTypeTest.h"

const NSTimeInterval DEFAULT_HTTP_TIMEOUT = 30;

@implementation WNJsonDataLoader

+ (id)sharedData
{
    NSAssert(0, @"継承したclassでそれぞれ sharedData を実装してね。");
    static id sData = nil;
    @synchronized(sData) {
        if(sData == nil) {
            sData = self.new;
            [sData reloadDataForce:YES];
        }
    }
    return sData;
}

- (NSString *)dataURL
{
    NSAssert(0, @"継承したclassでそれぞれ sharedData を実装してね。");
    return nil;
}

- (void)setError:(NSError *)error
{
    _error = error;
}

- (void)initData
{
    _state = WNJsonDataLoaderStateInitial;
    _error = nil;
}

- (void)reloadData
{
    [self reloadDataForce:NO];
}

- (void)reloadDataForce:(BOOL)force
{
    NSLog( @"%@ reloadDataForce:%d", self.class, force );
    NSString *strUrl = self.dataURL;
    if(strUrl.length == 0){
        _state = WNJsonDataLoaderStateFailed;
        [self reloadDataFinishedFrom:self];
        return;
    }
    if( _state == WNJsonDataLoaderStateLoading ){
        if( force == YES ){
            [HTTPLoader cancel];  // 前のリクエストをキャンセルして、再読み込み
        } else {
            NSLog( @"%@ is now loading Skip reloadData.", self.class);
            return;
        }
    }
    
    if( force == NO && _updateTime != nil && _updateTime.timeIntervalSinceNow > -30 ){
        NSLog( @"%@ lastUpdated:%@, Skip reloadData.", self.class, _updateTime.description );
        return;
    }

    NSLog(@"%@, url:%@", self.class, strUrl);
    [self initData];
    _state = WNJsonDataLoaderStateLoading;
    [[NSURLCache sharedURLCache] removeAllCachedResponses]; // キャッシュクリア
    NSURL *url = [NSURL URLWithString:strUrl];
    NSURLRequest *request = [NSURLRequest requestWithURL:url
                                             cachePolicy:NSURLRequestReloadIgnoringCacheData
                                         timeoutInterval:DEFAULT_HTTP_TIMEOUT];
    NSString *loaderID = [NSString stringWithFormat:@"%@", self.class];
    HTTPLoader = [[WNHTTPLoader alloc] initWithRequest:request delegate:self loaderID:loaderID];
}

#pragma mark WNHTTPLoaderDelegate
- (void)loader:(WNHTTPLoader *)loader didReceiveData:(NSData *)data loaderID:(NSString *)loaderID
{
    NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    //FRLog( @"%@ response:%@", self.class, jsonString );
    id jsonValue = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    
    if( jsonValue && [self parseJson:jsonValue] ){
        //FRLog( @"%@, %@ parse finished.", self.class, (self.debugStr)? self.debugStr:@"" );
        _updateTime = NSDate.date;
        _state = WNJsonDataLoaderStateLoaded;
        [self reloadDataFinishedFrom:self];
        
    } else {
        NSLog( @"%@, %@ parse failed.", self.class, (self.debugStr)? self.debugStr:@"" );
        NSLog( @"%@", jsonString );
        _state = WNJsonDataLoaderStateFailed;
        [self reloadDataFinishedFrom:self];
    }
}

- (void)loader:(WNHTTPLoader *)loader didFailWithError:(NSError *)error loaderID:(NSString *)loaderID
{
    //FRLogSelfAndCommand();
    HTTPLoader.delegate = nil;
    HTTPLoader = nil;
    
    _state = WNJsonDataLoaderStateFailed;
    _error = error;
    [self reloadDataFinishedFrom:self];
}

- (void)reloadDataFinishedFrom:(id)loader
{
    if(_delegate && [_delegate respondsToSelector:@selector(reloadDataFinishedFrom:)] ){
        [_delegate reloadDataFinishedFrom:loader];
    } else {
        [self reloadDataFinished];
    }
}

- (void)reloadDataFinished
{
    if(_delegate && [_delegate respondsToSelector:@selector(reloadDataFinished)] ){
        [_delegate reloadDataFinished];
    }
}

- (BOOL)parseJson:(id)jsonValue
{
    // Json を Parse する部分を各Class で実装する。Parse成功時はYES, 失敗時はNOを帰す。
    NSAssert(0, @"継承したclassでそれぞれ parseJson を実装してね。");
    return YES;
}

- (NSString *)errorMessage
{
    return @"Data Load Failed.";
}

- (void)showAlert:(NSString *)message
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Info"
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

@end
