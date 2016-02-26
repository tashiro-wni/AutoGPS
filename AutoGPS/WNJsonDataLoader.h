//
//  WNJsonDataLoader.h
//  Weathernews Touch
//
//  Created by Tomohiro Tashiro on 2015/03/02.
//  Copyright (c) 2015年 weathernews. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WNHTTPLoader.h"

typedef enum{
    WNJsonDataLoaderStateInitial = 0,
    WNJsonDataLoaderStateLoading = 1,
    WNJsonDataLoaderStateLoaded  = 2,
    WNJsonDataLoaderStateFailed  = 999,
} WNJsonDataLoaderState;


@interface WNJsonDataLoader : NSObject
{
    WNHTTPLoader *HTTPLoader;
}

@property (readonly) WNJsonDataLoaderState state;
@property (nonatomic, weak) id delegate;
@property (readonly) NSError *error;
@property (nonatomic, retain) NSDate *updateTime;
@property (nonatomic, retain) NSString *debugStr; // Debug用

+ (id)sharedData;
- (void)initData;
- (NSString *)dataURL;
- (void)reloadData;
- (void)reloadDataForce:(BOOL)force;
- (void)reloadDataFinished;
- (void)reloadDataFinishedFrom:(id)loader;
- (BOOL)parseJson:(id)jsonValue;
- (void)setError:(NSError *)error;
- (NSString *)errorMessage;
- (void)showAlert:(NSString *)message;
@end
