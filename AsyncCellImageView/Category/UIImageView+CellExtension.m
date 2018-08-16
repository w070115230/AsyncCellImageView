//
//  UIImageView+CellExtension.m
//  AsyncCellImageView
//
//  Created by vincent on 2018/8/16.
//  Copyright © 2018年 wj. All rights reserved.
//

#import "UIImageView+CellExtension.h"
#import <SDWebImage/SDImageCache.h>
#import <UIImageView+WebCache.h>
#import <objc/runtime.h>
#import "UIImage+WJExtension.h"

static const char *imageUrlKey = "kImageUrl";

@implementation UIImageView (CellExtension)

-(void)setImageUrl:(NSString *)imageUrl{
    objc_setAssociatedObject(self, &imageUrlKey, imageUrl, OBJC_ASSOCIATION_COPY);
}

-(NSString *)imageUrl{
    return objc_getAssociatedObject(self, &imageUrlKey);
}



-(void)wj_loadCircelIconUrlStr:(NSString *)urlStr placeHolderImageName:(NSString *)placeHolderStr radius:(CGFloat)radius{
    NSURL *url;
    self.imageUrl = urlStr;
    if (placeHolderStr == nil) {
        placeHolderStr = @"temp";
    }
    
    //这里传CGFLOAT_MIN，就是默认以图片宽度的一半为圆角
    if (radius == CGFLOAT_MIN) {
        radius = self.frame.size.width/2.0;
    }
    
    url = [NSURL URLWithString:urlStr];
    
    if (radius != 0.0) {
        //头像需要手动缓存处理成圆角的图片
        NSString *cacheurlStr = [urlStr stringByAppendingString:@"radiusCache"];
        UIImage *cacheImage = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:cacheurlStr];
        if (cacheImage) {
            self.image = cacheImage;
        }
        else {
            
            __weak typeof(self) weakSelf = self;
            [self sd_setImageWithURL:url placeholderImage:[UIImage imageNamed:placeHolderStr] options:SDWebImageAvoidAutoSetImage completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                if (!error) {
                    if (image) {
                        if(image.size.width>1024 || image.size.height>1024){
                            dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
                            //异步函数
                            dispatch_async(queue, ^{
                                NSLog(@"压缩图片任务所在的线程----%@",[NSThread currentThread]);
                                UIImage *new = [self processImage:image];
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    //NSLog(@"图片回调所在的线程----%@",[NSThread currentThread]);
                                    UIImage *radiusImage = [UIImage createCircleImage:new size:self.frame.size];
                                    //self.image = radiusImage;//这里会造成cell显示的图片错乱，cell的缓存问题
                                    if ([weakSelf.imageUrl isEqualToString:[imageURL absoluteString]]) {
                                        weakSelf.image = radiusImage;
                                    }
                                    [[SDImageCache sharedImageCache] storeImage:radiusImage forKey:cacheurlStr completion:nil];
                                    //清除原有非圆角图片缓存
                                    [[SDImageCache sharedImageCache] removeImageForKey:urlStr withCompletion:nil];
                                });
                            });
                            
                        }else{
                            UIImage *radiusImage = [UIImage createCircleImage:image size:self.frame.size];
                            if([self.imageUrl isEqualToString:[imageURL absoluteString]]){
                                self.image = radiusImage;
                            }
                            [[SDImageCache sharedImageCache] storeImage:radiusImage forKey:cacheurlStr completion:nil];
                            [[SDImageCache sharedImageCache] removeImageForKey:urlStr withCompletion:nil];
                        }
                    }
                }
            }];
        }
    }
    else {
        [self sd_setImageWithURL:url placeholderImage:[UIImage imageNamed:placeHolderStr] completed:nil];
    }
}

- (UIImage *)processImage:(UIImage *)image {
    
    UIImage *resultImage = nil;
    NSData *data = UIImagePNGRepresentation(image);
    if (!data) {
        data = UIImageJPEGRepresentation(image, 0.5);
    }
    
    if(data){
        double dataLength = [data length] * 1.0;
        if(dataLength>1024){
            data = [self compressQualityWithMaxLength:1024 image:[UIImage imageWithData:data]];
            resultImage = [UIImage imageWithData: data];
        }else{
            resultImage = [UIImage imageWithData: data];
        }
    }else{
        resultImage = image;
    }
    
    double dataLength = [data length] * 1.0;
    NSArray *typeArray = @[@"bytes",@"KB",@"MB",@"GB",@"TB",@"PB", @"EB",@"ZB",@"YB"];
    NSInteger index = 0;
    while (dataLength > 1024) {
        dataLength /= 1024.0;
        index ++;
    }
    NSLog(@"image 文件大小 = %.3f %@",dataLength,typeArray[index]);
    
    CGFloat w = [UIScreen mainScreen].bounds.size.width;
    UIImage *newImage = [self imageCompressForWidthScale:resultImage targetWidth:w];

    return newImage;
}

- (NSData *)compressQualityWithMaxLength:(NSInteger)maxLength image:(UIImage *)image{
    CGFloat compression = 0.7;
    NSData *data = UIImageJPEGRepresentation(image, compression);
    while (data.length > maxLength && compression > 0) {
        compression -= 0.05;
        data = UIImageJPEGRepresentation(image, compression);
    }
    return data;
}


//指定宽度按比例缩放
-(UIImage *) imageCompressForWidthScale:(UIImage *)sourceImage targetWidth:(CGFloat)defineWidth{
    
    UIImage *newImage = nil;
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = defineWidth;
    CGFloat targetHeight = height / (width / targetWidth);
    CGSize size = CGSizeMake(targetWidth, targetHeight);
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0, 0.0);
    
    if(CGSizeEqualToSize(imageSize, size) == NO){
        
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        if(widthFactor > heightFactor){
            scaleFactor = widthFactor;
        }
        else{
            scaleFactor = heightFactor;
        }
        scaledWidth = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        
        if(widthFactor > heightFactor){
            
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
            
        }else if(widthFactor < heightFactor){
            
            thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
        }
    }
    
    UIGraphicsBeginImageContext(size);
    
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    
    [sourceImage drawInRect:thumbnailRect];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    if(newImage == nil){
        
        NSLog(@"scale image fail");
    }
    UIGraphicsEndImageContext();
    return newImage;
}


@end
