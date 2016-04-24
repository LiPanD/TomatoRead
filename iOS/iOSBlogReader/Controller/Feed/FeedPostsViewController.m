//
//  FeedViewController.m
//  iOSBlogReader
//
//  Created by everettjf on 16/4/6.
//  Copyright © 2016年 everettjf. All rights reserved.
//

#import "FeedPostsViewController.h"
#import "FeedPostTableViewCell.h"
#import "FeedManager.h"
#import <MJRefresh.h>
#import "MainContext.h"
#import "FeedPostContentViewController.h"

static NSString * kFeedCell = @"FeedCell";

@interface FeedPostsViewController ()<FeedManagerDelegate,UITableViewDelegate,UITableViewDataSource>
@property (strong,nonatomic) UITableView *tableView;
@property (strong,nonatomic) UIView *topPanel;
@property (strong,nonatomic) UILabel *topInfoLabel;
@property (strong,nonatomic) NSMutableArray<FeedItemUIEntity*> *dataset;
@property (strong,nonatomic) FeedManager *feedManager;

@property (strong,nonatomic) FeedSourceUIEntity *oneFeed;
@end

@implementation FeedPostsViewController

- (instancetype)init{
    self = [super init];
    if(self){
        _mode = FeedPostsViewControllerModeAll;
    }
    return self;
}

- (instancetype)initWithOne:(FeedSourceUIEntity *)feed{
    self = [super init];
    if(self){
        _mode = FeedPostsViewControllerModeOne;
        _oneFeed = feed;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    _feedManager = [FeedManager new];
    _feedManager.delegate = self;
    
    if(_mode == FeedPostsViewControllerModeOne){
        [_feedManager bindOne:_oneFeed];
    }
    
    _dataset = [NSMutableArray new];
    
    _topPanel = [UIView new];
    [self.view addSubview:_topPanel];
    
    _tableView = [UITableView new];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [_tableView registerClass:[FeedPostTableViewCell class] forCellReuseIdentifier:kFeedCell];
    [self.view addSubview:_tableView];
    
    [_topPanel mas_makeConstraints:^(MASConstraintMaker *make){
        make.left.equalTo(self.view);
        make.right.equalTo(self.view);
        make.top.equalTo(self.mas_topLayoutGuide);
        make.height.equalTo(@30);
    }];

    [_tableView mas_makeConstraints:^(MASConstraintMaker *make){
        make.left.equalTo(self.view);
        make.right.equalTo(self.view);
        make.top.equalTo(_topPanel.mas_bottom);
        make.bottom.equalTo(self.view).offset(-60);
    }];
    
    _tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(_pullDown)];
    
    MJRefreshAutoNormalFooter *footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(_pullUp)];
    [footer setTitle:@"" forState:MJRefreshStateIdle];
    _tableView.mj_footer = footer;
    
    [self _setupTopPanel];
    
    [self _loadInitialFeeds];
}

- (void)_setupTopPanel{
    _topInfoLabel = [UILabel new];
    _topInfoLabel.text = @"加载中...";
    _topInfoLabel.font = [UIFont systemFontOfSize:12];
    _topInfoLabel.textColor = [UIColor colorWithRed:0.298 green:0.298 blue:0.298 alpha:1.0];
    [_topPanel addSubview:_topInfoLabel];
    
    [_topInfoLabel mas_makeConstraints:^(MASConstraintMaker *make){
        make.center.equalTo(_topPanel);
    }];
}

- (void)_pullDown{
    [self _loadInitialFeeds];
    
    [_feedManager loadFeeds];
}
- (void)_pullUp{
    [self _loadMoreFeeds];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _dataset.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    FeedPostTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kFeedCell forIndexPath:indexPath];
    FeedItemUIEntity *feedItem = [_dataset objectAtIndex:indexPath.row];
    
    cell.title = feedItem.title;
    cell.date = feedItem.date;
    cell.author = feedItem.author;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 60;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)feedManagerLoadStart{
    _topInfoLabel.text = @"加载中...";
}
- (void)feedManagerLoadProgress:(NSUInteger)loadCount totalCount:(NSUInteger)totalCount{
    float progress = 0;
    if(totalCount>0)progress=loadCount*1.0/totalCount;
    
    _topInfoLabel.text = [NSString stringWithFormat:@"正在更新 %@ / %@",@(loadCount),@(totalCount)];
    
    if(loadCount > 10 && _dataset.count == 0){
        [self _loadMoreFeeds];
    }
}

- (void)feedManagerLoadFinish{
    [self _loadMoreFeeds];
}

- (void)_loadInitialFeeds{
    [_feedManager fetchLocalFeeds:0 limit:20 completion:^(NSArray<FeedItemUIEntity *> *feedItems, NSUInteger totalItemCount, NSUInteger totalFeedCount) {
        if(feedItems){
            _dataset = [feedItems mutableCopy];
            [_tableView reloadData];
            
            if(totalItemCount == 0){
                if(_mode == FeedPostsViewControllerModeOne)
                    [_feedManager loadFeeds];
            }
        }
        [self _showFeedsInfo:totalFeedCount totalItemCount:totalItemCount];
        
        [_tableView.mj_header endRefreshing];
        [_tableView.mj_footer endRefreshing];
    }];
}

- (void)_loadMoreFeeds{
    [_feedManager fetchLocalFeeds:_dataset.count limit:20 completion:^(NSArray<FeedItemUIEntity *> *feedItems, NSUInteger totalItemCount, NSUInteger totalFeedCount) {
        if(feedItems){
            [_dataset addObjectsFromArray:feedItems];
            [_tableView reloadData];
        }
        [self _showFeedsInfo:totalFeedCount totalItemCount:totalItemCount];
        
        [_tableView.mj_header endRefreshing];
        [_tableView.mj_footer endRefreshing];
    }];
}

- (void)_showFeedsInfo:(NSUInteger)totalFeedCount totalItemCount:(NSUInteger)totalItemCount{
    if(!totalFeedCount || !totalItemCount)return;
    if(_mode == FeedPostsViewControllerModeOne){
        _topInfoLabel.text = [NSString stringWithFormat:@"%@ 文章",@(totalItemCount)];
    }else{
        _topInfoLabel.text = [NSString stringWithFormat:@"%@ 订阅, %@ 文章",@(totalFeedCount),@(totalItemCount)];
    }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    FeedItemUIEntity *feedItem = [_dataset objectAtIndex:indexPath.row];
    
    FeedPostContentViewController *contentViewController = [[FeedPostContentViewController alloc]initWithFeedPost:feedItem];
    [[MainContext sharedContext].mainNavigationController pushViewController:contentViewController animated:YES];
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