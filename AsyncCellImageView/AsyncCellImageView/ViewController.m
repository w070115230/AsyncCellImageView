//
//  ViewController.m
//  AsyncCellImageView
//
//  Created by vincent on 2018/8/16.
//  Copyright © 2018年 wj. All rights reserved.
//

#import "ViewController.h"
#import "WJTableViewCell.h"
#import "UIImageView+CellExtension.h"

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>{
    
    NSArray *_data;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [_tableView registerNib:[UINib nibWithNibName:@"WJTableViewCell" bundle:nil] forCellReuseIdentifier:@"wj"];
    
    
    _data = @[@"https://m.360buyimg.com/babel/jfs/t23557/158/2130009247/44742/201feee4/5b7403b3N97fb471c.jpg",@"https://image.suning.cn/uimg/aps/material/153423458645575824.jpg",@"https://img1.360buyimg.com/pop/jfs/t23731/194/2035496789/166000/409e2393/5b729898N2d38f07d.jpg",
              @"https://m.360buyimg.com/babel/jfs/t23557/158/2130009247/44742/201feee4/5b7403b3N97fb471c.jpg",@"https://img1.360buyimg.com/pop/jfs/t24136/100/2015773918/100112/b0188e7f/5b726cb8N40abd03b.jpg",@"https://image.suning.cn/uimg/aps/material/153414077701688321.jpg",@"https://image.suning.cn/uimg/aps/material/153423458645575824.jpg",@"https://img1.360buyimg.com/pop/jfs/t23731/194/2035496789/166000/409e2393/5b729898N2d38f07d.jpg",
              @"https://m.360buyimg.com/babel/jfs/t23557/158/2130009247/44742/201feee4/5b7403b3N97fb471c.jpg"];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 80;
}


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _data.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    WJTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"wj"];
    ///[cell.icon setImage:[UIImage imageNamed:@"temp"]];
    
    [cell.icon wj_loadCircelIconUrlStr:_data[indexPath.row] placeHolderImageName:@"temp" radius:CGFLOAT_MIN];
    return cell;
}

@end
