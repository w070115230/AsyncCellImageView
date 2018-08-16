//
//  UIImage+WJExtension.m
//  AsyncCellImageView
//
//  Created by vincent on 2018/8/16.
//  Copyright © 2018年 wj. All rights reserved.
//

#import "UIImage+WJExtension.h"

@implementation UIImage (WJExtension)

static void addRoundedRectToPath(CGContextRef context, CGRect rect, float ovalWidth,
                                 float ovalHeight)
{
    float w, h;
    if (ovalWidth == 0 || ovalHeight == 0)
    {
        CGContextAddRect(context, rect);
        return;
    }
    
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, CGRectGetMinX(rect), CGRectGetMinY(rect));
    CGContextScaleCTM(context, ovalWidth, ovalHeight);
    w = CGRectGetWidth(rect) / ovalWidth;
    h = CGRectGetHeight(rect) / ovalHeight;
    
    //根据圆角路径绘制
    CGContextMoveToPoint(context, w, h/2);
    CGContextAddArcToPoint(context, w, h, w/2, h, 1);
    CGContextAddArcToPoint(context, 0, h, 0, h/2, 1);
    CGContextAddArcToPoint(context, 0, 0, w/2, 0, 1);
    CGContextAddArcToPoint(context, w, 0, w, h/2, 1);
    
    CGContextClosePath(context);
    CGContextRestoreGState(context);
}

+ (id)createCircleImage:(UIImage*)image size:(CGSize)size
{
    int w = image.size.width;
    int h = image.size.height;

    if(w>1024){
        image = [self processImage:image];
        w = image.size.width;
        h = image.size.height;
    }
    UIImage *img = [self cutCenterImageSize:CGSizeMake(w, h) iMg:image];//截取图片的中间部分，头像会造成部分被裁剪掉
    CGFloat r = img.size.width*0.5;
    w = img.size.width;
    h = img.size.height;
    //UIImage *img = image;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, w, h, 8, 4 * w, colorSpace, (CGBitmapInfo)kCGImageAlphaPremultipliedFirst);
    //CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect rect = CGRectMake(0, 0, w, h);
    
    CGContextBeginPath(context);
    addRoundedRectToPath(context, rect, r, r);
    CGContextClosePath(context);
    CGContextClip(context);
    CGContextDrawImage(context, CGRectMake(0, 0, w, h), img.CGImage);
    CGImageRef imageMasked = CGBitmapContextCreateImage(context);
    img = [UIImage imageWithCGImage:imageMasked];
    
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    CGImageRelease(imageMasked);
    
    return img;
    
}

//传入size记得屏幕的1x的size
+ (UIImage *)cutCenterImageSize:(CGSize)size iMg:(UIImage *)img {
    CGFloat scale = [UIScreen mainScreen].scale;
    size.width = size.width*scale;
    size.height = size.height *scale;
    CGSize imageSize = img.size;
    CGRect rect;
    
    //根据图片的大小计算出图片中间矩形区域的位置与大小
    if (imageSize.width > imageSize.height) {
        float leftMargin = (imageSize.width - imageSize.height) *0.5;
        rect = CGRectMake(leftMargin,0, imageSize.height, imageSize.height);
    }else{
        float topMargin = (imageSize.height - imageSize.width) *0.5;
        rect = CGRectMake(0, topMargin, imageSize.width, imageSize.width);
    }
    
    CGImageRef imageRef = img.CGImage;
    //截取中间区域矩形图片
    CGImageRef imageRefRect =CGImageCreateWithImageInRect(imageRef, rect);
    UIImage *tmp = [[UIImage alloc] initWithCGImage:imageRefRect];
    CGImageRelease(imageRefRect);
    UIGraphicsBeginImageContext(rect.size);
    //CGRect rectDraw =CGRectMake(0,0, size.width, size.height);
    CGRect rectDraw =CGRectMake(0,0, rect.size.width, rect.size.height);
    [tmp drawInRect:rectDraw];
    
    // 从当前context中创建一个改变大小后的图片
    tmp = UIGraphicsGetImageFromCurrentImageContext();
    
    // 使当前的context出堆栈
    UIGraphicsEndImageContext();
    NSLog(@"tmp sizewidth is %f sizeHeight is %f",tmp.size.width,tmp.size.height);
    return tmp;
}



+(UIImage *)processImage:(UIImage *)image {
    
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
    
    
    CGFloat w = [UIScreen mainScreen].bounds.size.width;;
    UIImage *newImage = [self imageCompressForWidthScale:resultImage targetWidth:w];
    
    
    return newImage;
}

+ (NSData *)compressQualityWithMaxLength:(NSInteger)maxLength image:(UIImage *)image{
    CGFloat compression = 0.7;
    NSData *data = UIImageJPEGRepresentation(image, compression);
    while (data.length > maxLength && compression > 0) {
        compression -= 0.05;
        data = UIImageJPEGRepresentation(image, compression); // When compression less than a value, this code dose not work
    }
    return data;
}

//指定宽度按比例缩放
+(UIImage *) imageCompressForWidthScale:(UIImage *)sourceImage targetWidth:(CGFloat)defineWidth{
    
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
