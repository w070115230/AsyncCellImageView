# AsyncCellImageView

UITableViewCell 异步加载图片问题

1、使用SDWebImage异步下载图片

2、图片下载完成后如果超过一定的大小，开启异步线程去处理，并裁剪成圆形头像

3、扩展UIImageView，添加了tag来防止UITableView在滑动的过程中图片错乱的问题
