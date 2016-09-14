//
//  DataManage.h
//  MyPlayer
//
//  Created by SU on 16/8/23.
//  Copyright © 2016年 SU. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^onSuccess)(NSArray *sidArray, NSArray *videoArray);
typedef void (^onFailed)(NSError *error);

@interface DataManage : NSObject

@property (nonatomic, strong)NSArray *sidArray;
@property (nonatomic, strong)NSArray *videoArray;

//单例
+ (DataManage *)shareManager;

//
- (void)getSidArrayWithURLString:(NSString *)URLString succecc:(onSuccess)success failed:(onFailed)failed;

//请求video数据
- (void)getVideoArrayWithURLString:(NSString *)URLString listID:(NSString *)ID success:(onSuccess)success failed:(onFailed)failed;

@end
