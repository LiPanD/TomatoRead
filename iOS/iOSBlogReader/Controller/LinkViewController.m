//
//  LinkViewController.m
//  iOSBlogReader
//
//  Created by everettjf on 16/4/6.
//  Copyright © 2016年 everettjf. All rights reserved.
//

#import "LinkViewController.h"
#import "RestApi.h"
#import "LinkTableViewCell.h"
#import "WebViewController.h"

static NSString * const kLinkCell = @"LinkCell";

@interface LinkViewController ()<UITableViewDelegate, UITableViewDataSource>
@property (strong,nonatomic) UITableView *tableView;
@property (strong,nonatomic) NSMutableArray<RestLinkModel*> *dataset;
@property (strong,nonatomic) RestLinkListModel *lastQuery;

@end

@implementation LinkViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        _dataset = [NSMutableArray new];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSLog(@"link view did load : %@", @(self.item.linkData.oid));
    
    _tableView = [UITableView new];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [_tableView registerClass:[LinkTableViewCell class] forCellReuseIdentifier:kLinkCell];
    [self.view addSubview:_tableView];
    [_tableView mas_makeConstraints:^(MASConstraintMaker *make){
        make.edges.equalTo(self.view);
    }];
    
    [[RestApi api] queryLinkList:self.item.linkData.oid complete:^(RestLinkListModel *model, NSError *error) {
        if(error) return;
        self.lastQuery = model;
        
        [_dataset addObjectsFromArray:model.results];
        
        [_tableView reloadData];
    } url:nil];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _dataset.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    LinkTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kLinkCell forIndexPath:indexPath];
    RestLinkModel *model = [_dataset objectAtIndex:indexPath.row];
    cell.favicon = model.favicon;
    cell.title = model.name;
    cell.subTitle = model.desc;
    
    return cell;;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 60;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    RestLinkModel *model = [_dataset objectAtIndex:indexPath.row];
    
    WebViewController *webViewController = [[WebViewController alloc]init];
    webViewController.title = model.name;
    webViewController.url = model.url;
    [self.navigationController pushViewController:webViewController animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
