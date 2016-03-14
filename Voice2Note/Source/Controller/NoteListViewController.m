//
//  NoteListViewController.m
//  Voice2Note
//
//  Created by liaojinxing on 14-6-11.
//  Copyright (c) 2014年 jinxing. All rights reserved.
//

#import "Masonry.h"
#import "NoteEditViewController.h"
#import "NoteListCell.h"
#import "NoteListViewController.h"
#import "NoteManager.h"
#import "SVProgressHUD.h"
#import "SignViewController.h"
#import "UIColor+VNHex.h"
#import "VNConstants.h"
#import "VNNote.h"

static NSString *kCellReuseIdentifier = @"ListCell";

// 注释掉下面的宏定义，就是用“传统”的模板 Cell 计算高度
//#define IOS_8_NEW_FEATURE_SELF_SIZING

@interface NoteListViewController () <UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, UIAlertViewDelegate, UISearchResultsUpdating>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, assign) NSInteger selectedIndex;
@property (nonatomic, strong) NSMutableArray *dataSource;
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, strong) UIBarButtonItem *cancelButton, *addButton, *editButton, *deleteButton;
@property (nonatomic, strong) NSMutableDictionary *offscreenCells;
@property (nonatomic, strong) UILabel *countLabel;

@end

@implementation NoteListViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.title = kAppName;
    self.view.backgroundColor = [UIColor whiteColor];

    self.cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(edit)];
    self.addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addNote)];
    self.editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(edit)];
    self.deleteButton = [[UIBarButtonItem alloc] initWithTitle:@"删除所有" style:UIBarButtonItemStylePlain target:self action:@selector(delete)];
    [self.deleteButton setTintColor:[UIColor redColor]];

    [self updateButtonsToMatchTableState];

    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    // 在搜索状态下，设置背景框的颜色为灰色
    self.searchController.dimsBackgroundDuringPresentation = YES;
    // 点击搜索框的时候，是否隐藏导航栏
    self.searchController.hidesNavigationBarDuringPresentation = YES;
    // 添加搜索范围分类
    self.searchController.searchBar.scopeButtonTitles = @[ NSLocalizedString(@"ScopeButtonContent", @"内容"),
                                                           NSLocalizedString(@"ScopeButtonDate", @"日期") ];
    [self.searchController.searchBar sizeToFit];
    UITableView *tv = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, kScreenHeight)];
    tv.delegate = self;
    tv.dataSource = self;
    [self addObserver:self forKeyPath:@"dataSource" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    [self.view addSubview:tv];
    self.tableView = tv;

    self.tableView.tableHeaderView = self.searchController.searchBar;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];

    // 在此添加底部视图，显示笔记总数
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, kScreenHeight - 43, kScreenWidth, 43)];
    footerView.backgroundColor = [UIColor whiteColor];
    self.countLabel = [UILabel new];
    NSUInteger count = self.dataSource.count;
    NSString *str = [NSString stringWithFormat:@"共 %ld 条笔记", (long) count];
    self.countLabel.text = str;
    self.countLabel.textColor = [UIColor blackColor];
    self.countLabel.font = [UIFont systemFontOfSize:14];
    [footerView addSubview:self.countLabel];
    [self.countLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(footerView);
    }];
    [self.view addSubview:footerView];

    // 是否可以多选
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;

    // 注册 Cell - 不使用 nib 的方式，此时会调用 cell 的 - (id)initWithStyle:withReuseableCellIdentifier:
    [self.tableView registerClass:[NoteListCell class] forCellReuseIdentifier:kCellReuseIdentifier];

    // iOS 7
    self.tableView.estimatedRowHeight = UITableViewAutomaticDimension;
    self.offscreenCells = [NSMutableDictionary dictionary];

#ifdef IOS_8_NEW_FEATURE_SELF_SIZING
    // iOS 8 的 Self-sizing 特性
    if ([UIDevice currentDevice].systemVersion.integerValue > 7) {
        // iOS8 系统中 rowHeight 的默认值已经设置成了 UITableViewAutomaticDimension，所以可以省略
        self.tableView.rowHeight = UITableViewAutomaticDimension;
        self.tableView.estimatedRowHeight = 88.0f;
    }
#endif
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadData)
                                                 name:kNotificationCreateFile
                                               object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self removeObserver:self forKeyPath:@"dataSource" context:NULL];
}

- (void)reloadData {
    self.dataSource = [[NoteManager sharedManager] readAllNotes];
    [self.tableView reloadData];
    [self updateButtonsToMatchTableState];
}

- (NSMutableArray *)dataSource {
    if (!_dataSource) {
        _dataSource = [[NoteManager sharedManager] readAllNotes];
    }
    return _dataSource;
}

#pragma mark -
#pragma mark === Toolbar Action ===
#pragma mark -

- (void)addNote {
    NoteEditViewController *note = [[NoteEditViewController alloc] init];
    [self.navigationController pushViewController:note animated:YES];
}

- (void)edit {
    [self.tableView setEditing:!self.tableView.isEditing animated:YES];
    [self updateButtonsToMatchTableState];
}

- (void) delete {
    if ([[self.tableView indexPathsForSelectedRows] count] > 0) {
        NSString *actionTitle;

        if (([[self.tableView indexPathsForSelectedRows] count] == 1)) {
            actionTitle = @"你确定要删除这一项吗?";
        } else if (([[self.tableView indexPathsForSelectedRows] count] > 1)) {
            actionTitle = @"你确定要删除这些项目吗?";
        }
        NSString *cancelTitle = @"取消";
        NSString *okTitle = @"确定";

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:actionTitle message:nil preferredStyle:UIAlertControllerStyleActionSheet];

        [alert addAction:[UIAlertAction actionWithTitle:cancelTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action){

                         }]];

        [alert addAction:[UIAlertAction actionWithTitle:okTitle style:UIAlertActionStyleDestructive handler:^(UIAlertAction *_Nonnull action) {

                   NSArray *selectedRows = [self.tableView indexPathsForSelectedRows];
                   BOOL deleteSpecificRows = selectedRows.count > 0;
                   if (deleteSpecificRows) {
                       NSMutableIndexSet *indicesOfItemsToDelete = [NSMutableIndexSet new];
                       for (NSIndexPath *selectionIndex in selectedRows) {
                           [indicesOfItemsToDelete addIndex:selectionIndex.row];
                           VNNote *note = [self.dataSource objectAtIndex:selectionIndex.row];
                           [[NoteManager sharedManager] deleteNote:note];
                       }

                       [self.dataSource removeObjectsAtIndexes:indicesOfItemsToDelete];

                       [self.tableView deleteRowsAtIndexPaths:selectedRows withRowAnimation:UITableViewRowAnimationAutomatic];

                   } else {
                       [self.dataSource removeAllObjects];
                       // 根据模型 更新 view
                       [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
                   }
                   // 退出编辑模式
                   [self.tableView setEditing:NO animated:YES];
                   [self reloadData];
                   [self updateButtonsToMatchTableState];
               }]];

        [self presentViewController:alert animated:YES completion:nil];
    }
}

#pragma mark -
#pragma mark === DataSource & Delegate ===
#pragma mark -

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {

    static NSInteger count = 0;
    count++;
    NSLog(@"%ld", count);

#ifdef IOS_8_NEW_FEATURE_SELF_SIZING
    // iOS 8 的 Self-sizing 特性
    return UITableViewAutomaticDimension;
#else

    NSString *reuseIdentifier = kCellReuseIdentifier;

    // 从 cell 字典中取出重用标示符对应的 cell。如果没有，就创建一个新的然后存储在字典里面。
    // 警告：不要调用 tableview 的 dequeueReusableCellWithIdentifier: 方法，因为这会导致 cell 被创建了但是又未曾被 tableView:cellForRowAtIndexPath: 方法返回，会造成内存泄露！
    NoteListCell *_templateCell = [self.offscreenCells objectForKey:reuseIdentifier];
    if (!_templateCell) {
        _templateCell = [[NoteListCell alloc] init];
        [self.offscreenCells setObject:_templateCell forKey:reuseIdentifier];
    }

    VNNote *note = [self.dataSource objectAtIndex:indexPath.row];
    // 判断高度是否已经计算过
    if (note.cellHeight <= 0) {
        // 填充数据
        [_templateCell updateWithNote:note];

        // ???: 是否需要调用
        [_templateCell setNeedsUpdateConstraints];
        [_templateCell updateConstraintsIfNeeded];

        [_templateCell setNeedsLayout]; // 告诉 _templateCell 页面需要更新，但不立即执行
        [_templateCell layoutIfNeeded]; // 告诉 _templateCell 页面布局立即更新
        // layoutSubviews: 系统重写布局的实际方法

        // 根据当前数据，计算 Cell 的高度，注意 +1，并缓存起来供在 cellForRowAtIndexPath:中使用
        note.cellHeight = [_templateCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height + 1.0f;
        NSLog(@"Calculate: %ld, height: %g", (long) indexPath.row, note.cellHeight);
    } else {
        NSLog(@"Get cache: %ld, height: %g", (long) indexPath.row, note.cellHeight);
    }

    return note.cellHeight;
#endif
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

/**
 *  数据绑定
 */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // dequeueReusableCellWithIdentifier:forIndexPath: 相比不带 “forIndexPath” 的版本会多调用一次高度计算(>_<)
    // 样式与数据分开
    NoteListCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellReuseIdentifier];
    // 使用 dequeueReusableCellWithIdentifier:forIndexPath: 的话，必须注册 Cell，而且，不需要再判断 Cell 是否为 nil 和创建 Cell
    if (!cell) {
        cell = [[NoteListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellReuseIdentifier];
        NSLog(@"cellForRowAtIndexPath->");
    }
    // 搜素状态
    if (self.searchController.active) {

    } else {
        VNNote *note = [self.dataSource objectAtIndex:indexPath.row];
        note.index = indexPath.row;
        [cell updateWithNote:note];
        // Make sure the constraints have been added to this cell, since it may have just been created from scratch
        [cell setNeedsUpdateConstraints]; // 告诉 cell 需要更新约束，在下次计算或者更新约束会更新约束
        [cell updateConstraintsIfNeeded]; // 告诉 cell 立即更新约束
        // updateConstraints:系统更新约束的实际方法
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.tableView.editing) {
        [self updateDeleteButtonTitle];
    } else {
        _selectedIndex = indexPath.row;
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *pwd = [defaults objectForKey:[NSString stringWithFormat:@"%ld", (long) self.selectedIndex]];
        if (pwd) {
            // 锁定文本，弹出输入密码
            UIAlertView *alter = [[UIAlertView alloc] initWithTitle:@"请输入解锁密码"
                                                            message:nil
                                                           delegate:self
                                                  cancelButtonTitle:@"取消"
                                                  otherButtonTitles:@"确定", nil];
            [alter setAlertViewStyle:UIAlertViewStyleSecureTextInput];
            // 以解决 Multiple UIAlertView 的代理事件
            [alter show];

        } else {
            [tableView deselectRowAtIndexPath:indexPath animated:NO];
            VNNote *note = [self.dataSource objectAtIndex:indexPath.row];

            NoteEditViewController *yy = [[NoteEditViewController alloc] initWithNote:note];
            [self.navigationController pushViewController:yy animated:YES];
        }
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self updateDeleteButtonTitle];
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    // TODO: 搜索逻辑
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    // 左划删除
    if (editingStyle == UITableViewCellEditingStyleDelete) // 删除模式
    {

        // 刷新表格
        //[self.tableView reloadData];
        // 带有的的动画的删除方式，需要指定参
        VNNote *note = [self.dataSource objectAtIndex:indexPath.row];
        [[NoteManager sharedManager] deleteNote:note];
        [self.dataSource removeObjectAtIndex:indexPath.row]; // 从数组中移除
        [tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationLeft];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) // 添加模式
    {
        NSLog(@"UITableViewCellEditingStyleInsert--");
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqual:@"dataSource"]) {
        NSUInteger count = self.dataSource.count;
        NSString *str = [NSString stringWithFormat:@"共 %ld 条笔记", (long) count];
        self.countLabel.text = str;
    }
}

#pragma mark -
#pragma mark === EditMode ===
#pragma mark -

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

#pragma mark -
#pragma mark === Updating button state ===
#pragma mark -

- (void)updateButtonsToMatchTableState {
    // 处于编辑状态
    if (self.tableView.editing) {
        // 显示取消按钮
        self.navigationItem.rightBarButtonItem = self.cancelButton;
        [self updateDeleteButtonTitle];
        // 显示删除按钮
        self.navigationItem.leftBarButtonItem = self.deleteButton;
    } else {
        // 显示添加按钮
        self.navigationItem.leftBarButtonItem = self.addButton;
        if (self.dataSource.count > 0) {
            self.editButton.enabled = YES;
        } else {
            self.editButton.enabled = NO;
        }
        // 显示编辑按钮
        self.navigationItem.rightBarButtonItem = self.editButton;
    }
}

- (void)updateDeleteButtonTitle {
    // 根据选中情况，更新删除标题
    NSArray *selectedRows = [self.tableView indexPathsForSelectedRows];

    BOOL allItemsAreSelected = selectedRows.count == self.dataSource.count;
    BOOL noItemsAreSelected = selectedRows.count == 0;

    if (allItemsAreSelected || noItemsAreSelected) {
        self.deleteButton.title = @"删除所有";
    } else {
        self.deleteButton.title = [NSString stringWithFormat:@"删除 (%lu)", (unsigned long) selectedRows.count];
    }
}

#pragma mark -
#pragma mark === UIAlertViewDelegate ===
#pragma mark -

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *userDefaults_pwd = [userDefaults objectForKey:[NSString stringWithFormat:@"%ld", (long) self.selectedIndex]];
    NSString *text_pwd = [[alertView textFieldAtIndex:0] text];
    if (buttonIndex == 1) {
        // 判读密码是否相等
        if ([userDefaults_pwd isEqualToString:text_pwd]) {
            VNNote *note = [self.dataSource objectAtIndex:_selectedIndex];
            NoteEditViewController *yy = [[NoteEditViewController alloc] initWithNote:note];
            [self.navigationController pushViewController:yy animated:NO];
        } else {
            // 密码错误
            UIAlertView *alter = [[UIAlertView alloc] initWithTitle:@"密码错误"
                                                            message:nil
                                                           delegate:self
                                                  cancelButtonTitle:@"确定"
                                                  otherButtonTitles:nil, nil];
            [alter show];
        }
    }
}

@end
