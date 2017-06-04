//
//  MCGalleryRequestURLManager.h
//

#import <Foundation/Foundation.h>

@class AFHTTPRequestOperationManager;

@interface MCGalleryRequestURLItem : NSObject

@property (strong, nonatomic) NSNumber *imageId;
@property (copy, nonatomic) void (^callBack)(NSDictionary * imageUrls, NSError * error);

@end

@interface MCGalleryRequestURLManager : NSObject

@property (strong, nonatomic) NSMutableDictionary<NSNumber *, MCGalleryRequestURLItem *> *imageIdToRequestItem;
@property (strong, nonatomic) NSDate *lastCallTime;
@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic) AFHTTPRequestOperationManager *httpOperationManager;
@property (strong, nonatomic) NSOperationQueue *httpOperationQueue;

+ (instancetype)sharedManager;

- (void)addRequestWithImageId:(NSNumber *)imageId
                       finish:(void (^)(NSDictionary * imageUrls, NSError * error))finish;

- (void)removeRequestWithImageId:(NSNumber *)imageId;

- (void)destory;

@end
