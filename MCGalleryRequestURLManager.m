//
//  MCGalleryRequestURLManager.m
//

#import "MCGalleryRequestURLManager.h"

@implementation MCGalleryRequestURLItem

@end

@implementation MCGalleryRequestURLManager

- (instancetype)init {
    if (self = [super init]) {
        _imageIdToRequestItem = [NSMutableDictionary dictionary];
        _httpOperationQueue = [[NSOperationQueue alloc] init];
        _httpOperationQueue.maxConcurrentOperationCount = 1;
        
        _httpOperationManager = [AFHTTPRequestOperationManager manager];
        _httpOperationManager.responseSerializer = [AFHTTPResponseSerializer serializer];
        _httpOperationManager.requestSerializer.timeoutInterval = 30.0;
    }
    return self;
}

+ (instancetype)sharedManager {
    static MCGalleryRequestURLManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (void)onTime {
    NSParameterAssert([[NSOperationQueue mainQueue] isEqual:[NSOperationQueue currentQueue]]);
    
    MCImageSyncAdapter * adapter = [MCImageSyncAdapter sharedAdapter];
    NSDictionary<NSNumber *, MCGalleryRequestURLItem *> *items = [self.imageIdToRequestItem copy];
    NSArray *imageIds = self.imageIdToRequestItem.allKeys;
    [self.imageIdToRequestItem removeAllObjects];
    
    if (imageIds.count == 0) {
        return;
    }
#if DEBUG
    NSLog(@"--- 本次请求一共有 %d 个 image id 需要换取 url", (int)imageIds.count);
#endif
    NSURLRequest * request = [adapter requestImageThumbnailUrls:imageIds
                                                           size:CGSizeMake(300, 300)];
    AFHTTPRequestOperation *httpOperation =
    [self.httpOperationManager HTTPRequestOperationWithRequest:request
                                                       success:
     ^(AFHTTPRequestOperation *operation, id responseObject) {
         NSError * error = nil;
         id jsonObject =
         [adapter.httpRequestManager.responseSerializer responseObjectForResponse:operation.response
                                                                             data:operation.responseData
                                                                      passportSid:kMiCloudSidKey
                                                                            error:&error];
         if (error) {
             [items.allValues enumerateObjectsUsingBlock:^(MCGalleryRequestURLItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                 if (obj.callBack) {
                     obj.callBack(nil, error);
                     obj.callBack = nil;
                 }
             }];
#if DEBUG
             if (error) {
                 NSLog(@"request failure: %@", error);
             }
#endif
         }
         else {
             NSDictionary *data = jsonObject[@"data"];
             NSDictionary *content = data[@"content"];
#if DEBUG
             NSLog(@"--- %d 个 imageId 换取 url 成功", (int)content.count);
#endif
             [content enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                 MCGalleryRequestURLItem *item = [items objectForKey:@([key longLongValue])];
                 if (item.callBack) {
                     item.callBack(@{key:obj}, error);
                     item.callBack = nil;
                 }
             }];
         }
     }
                                                       failure:
     ^(AFHTTPRequestOperation * operation, NSError * error) {
         [items.allValues enumerateObjectsUsingBlock:^(MCGalleryRequestURLItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
             if (obj.callBack) {
                 obj.callBack(nil, error);
                 obj.callBack = nil;
             }
         }];
#if DEBUG
         if (error) {
             NSLog(@"request failure: %@", error);
         }
#endif
     }];
    [self.httpOperationQueue addOperation:httpOperation];
}

- (void)addRequestWithImageId:(NSNumber *)imageId
                       finish:(void (^)(NSDictionary * imageUrls, NSError * error))finish {
#if DEBUG
    NSParameterAssert([[NSOperationQueue mainQueue] isEqual:[NSOperationQueue currentQueue]]);
#endif
    if (_timer == nil) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                  target:self
                                                selector:@selector(onTime)
                                                userInfo:nil
                                                 repeats:YES];
    }
    MCGalleryRequestURLItem *item = [MCGalleryRequestURLItem new];
    item.callBack = finish;
    item.imageId = imageId;
    [self.imageIdToRequestItem setObject:item forKey:imageId];
}

- (void)removeRequestWithImageId:(NSNumber *)imageId {
#if DEBUG
    NSParameterAssert([[NSOperationQueue mainQueue] isEqual:[NSOperationQueue currentQueue]]);
#endif
    [self.imageIdToRequestItem removeObjectForKey:imageId];
}

- (void)destory {
    [self.imageIdToRequestItem removeAllObjects];
    [_timer invalidate];
    _timer = nil;
}

@end
