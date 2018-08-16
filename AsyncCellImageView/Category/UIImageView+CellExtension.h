//
//  UIImageView+CellExtension.h
//  AsyncCellImageView
//
//  Created by vincent on 2018/8/16.
//  Copyright © 2018年 wj. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImageView (CellExtension)

@property (nonatomic,copy) NSString *imageUrl;

-(void)wj_loadCircelIconUrlStr:(NSString *)urlStr placeHolderImageName:(NSString *)placeHolderStr radius:(CGFloat)radius;

@end
