//
//  DataManage.m
//  MyPlayer
//
//  Created by SU on 16/8/23.
//  Copyright © 2016年 SU. All rights reserved.
//

#import "DataManage.h"
#import "SidModel.h"
#import "VideoModel.h"

@implementation DataManage

/**
 *  <#Description#>
 */
+ (DataManage *)shareManager
{
    static DataManage *dataManage = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        dataManage = [[DataManage alloc] init];
    });
    return dataManage;
}

/**
 *  获取sid 数据
 */
- (void)getSidArrayWithURLString:(NSString *)URLString succecc:(onSuccess)success failed:(onFailed)failed
{
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    dispatch_async(queue, ^{
        NSMutableArray *sidArray = [NSMutableArray array];
        NSMutableArray *videoArray = [NSMutableArray array];
        
        NSURL *url = [NSURL URLWithString:URLString];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        NSOperationQueue *queue = [NSOperationQueue mainQueue];
        [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
            if (connectionError) {
                NSLog(@"错误%@",connectionError);
            }
            else{
                NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                for (NSDictionary *videoDict in [dict objectForKey:@"videoList"]) {
                    VideoModel *model = [[VideoModel alloc] init];
                    [model setValuesForKeysWithDictionary:videoDict];
                    [videoArray addObject:model];
                }
                self.videoArray = [NSArray arrayWithArray:videoArray];
                //加载头标题
                for (NSDictionary *sidDict in [dict objectForKey:@"videoSidList"]) {
                    SidModel *model = [[SidModel alloc] init];
                    [model setValuesForKeysWithDictionary:sidDict];
                    [sidArray addObject:model];
                }
                self.sidArray = [NSArray arrayWithArray:sidArray];
            }
            success(sidArray, videoArray);
        }];
    });
}

/**
 *  获取video 数据
 */
- (void)getVideoArrayWithURLString:(NSString *)URLString listID:(NSString *)ID success:(onSuccess)success failed:(onFailed)failed
{
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    dispatch_async(queue, ^{
        NSURL *url = [NSURL URLWithString:URLString];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        NSOperationQueue *queue = [NSOperationQueue mainQueue];
        NSMutableArray *listArray = [NSMutableArray array];
        [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
            if (connectionError) {
                NSLog(@"错误%@",connectionError);
            }
            else{
                NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                NSArray *videoList = [dict objectForKey:ID];
                for (NSDictionary *videoDict in videoList) {
                    VideoModel *model = [[VideoModel alloc] init];
                    [model setValuesForKeysWithDictionary:videoDict];
                    [listArray addObject:model];
                }
                success(nil,listArray);
            }
        }];
        
    });
}
@end
