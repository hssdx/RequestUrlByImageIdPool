# RequestUrlByImageIdPool
由于项目有一个需求，是通过 imageId 换取 url。

通常是这样处理：

```
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ... //获取 cellData 等数据
    NSURL *url = [RequestUrlAPI urlForImageId:cellData.imageId];
    [cell.imageView sd_setWebImage:url];
}
```

但是有一个问题，但是如果集中大量调取这个 [RequestUrlAPI urlForImageId:cellData.imageId] API，
会导致服务器拒绝访问，在一个页面有大量图片浏览时出现大量加载错误。

可以改成这样

```
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    [cell.imageView requestThumbnailUrl:imageObject.serverID
                                   size:thumbnailSize
                                 finish:
             ^(NSDictionary * imageUrls, NSError * error) {
                 if (!error) {
                    //判断 cell.imageId 是否和 imageUrls 中一致（重用替换）
                    //拿到 url
                    //调用 [cell.imageView sd_setWebImage:url]
                    //注意 cell 的循环引用等问题
                    ...
                    [cell.imageView sd_setWebImage:url];
                 }
             }];
}
```

其中 requestThumbnailUrl:size:finish:这样实现：

```
- (void)requestThumbnailUrl:(NSNumber *)imageID
                       size:(CGSize)size
                     finish:(void (^)(NSDictionary * imageUrls, NSError * error))finish
{
	if (!imageID)
		return;
    
	// Cancel
    if (self.imageId) {
        [[MCGalleryRequestURLManager sharedManager] removeRequestWithImageId:self.imageId];
        self.imageId = nil;
    }
    self.imageId = imageID;
    [[MCGalleryRequestURLManager sharedManager] addRequestWithImageId:imageID finish:finish];
}
```

由于 MCGalleryRequestURLManager 缓存了一个 url 请求池，并且隔一定时间扫描一次，换 url 的 API 改成批量换取接口。
极大地减少了 API 的调用频率，完美地解决了前面的问题！



