//
//  NoteListController.m
//  Voice2Note
//
//  Created by liaojinxing on 14-6-11.
//  Copyright (c) 2014年 jinxing. All rights reserved.
//

#import "NoteListController.h"
#import "NoteManager.h"
#import "NoteDetailController.h"
#import "VNNote.h"
#import "VNConstants.h"
#import "NoteListCell.h"
#import "MobClick.h"
#import "iflyMSC/IFlyRecognizerView.h"
#import "iflyMSC/IFlySpeechConstant.h"
#import "iflyMSC/IFlyRecognizerView.h"
#import "iflyMSC/IFlySpeechUtility.h"
#import "SVProgressHUD.h"
#import "UIColor+VNHex.h"
#import "SignViewController.h"
#import "YYTextEditExample.h"

@interface NoteListController ()<IFlyRecognizerViewDelegate>
{
    IFlyRecognizerView *_iflyRecognizerView;
    NSMutableString *_resultString;
}
@property (nonatomic, strong) NSMutableArray *dataSource;

@end

#pragma mark -

@implementation NoteListController

- (void)viewDidLoad
{
    [super viewDidLoad];
    //是否可以多选
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    self.navigationItem.title = kAppName;
    cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];
    addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(createTask)];
    editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(edit)];
    deleteButton = [[UIBarButtonItem alloc] initWithTitle:@"Delete All" style:UIBarButtonItemStylePlain target:self action:@selector(delete)];
    [deleteButton setTintColor:[UIColor redColor]];
    
    [self updateButtonsToMatchTableState];
    [self setupVoiceRecognizerView];
    self.view.backgroundColor = [UIColor whiteColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    
    
    _searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    _searchController.searchResultsUpdater = self;
    _searchController.dimsBackgroundDuringPresentation = YES; //在搜索状态下，设置背景框的颜色为灰色
    _searchController.hidesNavigationBarDuringPresentation = YES; //点击搜索框的时候，是否隐藏导航栏
    [_searchController.searchBar sizeToFit];
    self.tableView.tableHeaderView = self.searchController.searchBar;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadData)
                                                 name:kNotificationCreateFile
                                               object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [IFlySpeechUtility destroy];
}

- (void)setupVoiceRecognizerView
{
    NSString *initString = [NSString stringWithFormat:@"%@=%@", [IFlySpeechConstant APPID], kIFlyAppID];
    
    [IFlySpeechUtility createUtility:initString];
    _iflyRecognizerView = [[IFlyRecognizerView alloc] initWithCenter:self.view.center];
    _iflyRecognizerView.delegate = self;
    
    [_iflyRecognizerView setParameter:@"iat" forKey:[IFlySpeechConstant IFLY_DOMAIN]];
    [_iflyRecognizerView setParameter:@"asr.pcm" forKey:[IFlySpeechConstant ASR_AUDIO_PATH]];
    [_iflyRecognizerView setParameter:@"plain" forKey:[IFlySpeechConstant RESULT_TYPE]];
    
    _resultString = [NSMutableString string];
}

- (void)reloadData
{
    _dataSource = [[NoteManager sharedManager] readAllNotes];
    [self.tableView reloadData];
}

- (NSMutableArray *)dataSource
{
    if (!_dataSource) {
        _dataSource = [[NoteManager sharedManager] readAllNotes];
    }
    return _dataSource;
}

- (void)createVoiceTask
{
    [_iflyRecognizerView start];
}

#pragma mark IFlyRecognizerViewDelegate

- (void)onResult:(NSArray *)resultArray isLast:(BOOL)isLast
{
    NSMutableString *result = [[NSMutableString alloc] init];
    NSDictionary *dic = [resultArray objectAtIndex:0];
    for (NSString *key in dic) {
        [result appendFormat:@"%@", key];
    }
    [_resultString appendString:result];
    if (isLast && _resultString.length > 0) {
        VNNote *note = [[VNNote alloc] initWithTitle:nil
                                             content:_resultString
                                         createdDate:[NSDate date]
                                          updateDate:[NSDate date]];
        BOOL success = [note Persistence];
        if (success) {
            [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"SaveSuccess", @"")];
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationCreateFile object:nil userInfo:nil];
        } else {
            [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"SaveFail", @"")];
        }
        _resultString = [NSMutableString string];
    }
}

- (void)onError:(IFlySpeechError *)error
{
    NSLog(@"errorCode:%@", [error errorDesc]);
}

- (void)createTask
{
    [MobClick event:kEventAddNewNote];
    NoteDetailController *controller = [[NoteDetailController alloc] init];
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)edit
{
    [self.tableView setEditing:YES animated:YES];
    [self updateButtonsToMatchTableState];
}

- (void)cancel
{
    [self.tableView setEditing:NO animated:YES];
    [self updateButtonsToMatchTableState];
}

- (void)delete
{
    NSString *actionTitle;
    if (([[self.tableView indexPathsForSelectedRows] count] == 1)) {
        actionTitle = @"你确定要删除这一项吗?";
    } else {
        actionTitle = @"你确定要删除这些项目吗?";
    }
    NSString *cancelTitle = @"取消";
    NSString *okTitle = @"好的";
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:actionTitle message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alert addAction:[UIAlertAction actionWithTitle:cancelTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:okTitle style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        
        NSArray *selectedRows = [self.tableView indexPathsForSelectedRows];
        BOOL deleteSpecificRows = selectedRows.count > 0 ;
        if (deleteSpecificRows) {
            NSMutableIndexSet *indicesOfItemsToDelete = [NSMutableIndexSet new];
            for (NSIndexPath *selectionIndex in selectedRows) {
                [indicesOfItemsToDelete addIndex:selectionIndex.row];
            }
            
            [self.dataSource removeObjectsAtIndexes:indicesOfItemsToDelete];
            
            [self.tableView deleteRowsAtIndexPaths:selectedRows withRowAnimation:UITableViewRowAnimationAutomatic];
            
        } else {
            [self.dataSource removeAllObjects];
            //根据模型 更新view
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        //退出编辑模式
        [self.tableView setEditing:NO animated:YES];
        [self updateButtonsToMatchTableState];
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}



#pragma mark - DataSource & Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    VNNote *note = [self.dataSource objectAtIndex:indexPath.row];
    return [NoteListCell heightWithNote:note];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
        return self.dataSource.count;
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NoteListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ListCell"];
    if (!cell) {
        cell = [[NoteListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ListCell"];
    }
    
    if (self.searchController.active) {
//        [cell.textLabel setText:self.searchList[indexPath.row]];
    }
    else{
            VNNote *note = [self.dataSource objectAtIndex:indexPath.row];
            cell.index = indexPath.row;
            [cell updateWithNote:note];
    }
    
    
    

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.tableView.editing) {
        [self updateDeleteButtonTitle];
    } else {
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
        VNNote *note = [self.dataSource objectAtIndex:indexPath.row];
//        NoteDetailController *controller = [[NoteDetailController alloc] initWithNote:note];
//        controller.hidesBottomBarWhenPushed = YES;
//        [self.navigationController pushViewController:controller animated:YES];
        
        
        YYTextEditExample *yy = [[YYTextEditExample alloc] initWithNote:note];
        [self.navigationController pushViewController:yy animated:YES];
    }
    
//    SignViewController *test = [[SignViewController alloc] initWithNibName:@"SignViewController" bundle:nil];
//    [self.navigationController pushViewController:test animated:YES];
    
   

}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self updateDeleteButtonTitle];
}

-(void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    
    
    
}

#pragma mark - EditMode

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete | UITableViewCellEditingStyleInsert;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        VNNote *note = [self.dataSource objectAtIndex:indexPath.row];
        [[NoteManager sharedManager] deleteNote:note];
        
        [self.dataSource removeObjectAtIndex:indexPath.row];
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

#pragma mark - Updating button state

- (void)updateButtonsToMatchTableState
{
    if (self.tableView.editing) {
        //显示取消按钮
        self.navigationItem.rightBarButtonItem = cancelButton;
        [self updateDeleteButtonTitle];
        
        //显示删除按钮
        self.navigationItem.leftBarButtonItem = deleteButton;
    } else {
        //显示添加按钮
        self.navigationItem.leftBarButtonItem = addButton;
        
        
        if (self.dataSource.count > 0) {
            editButton.enabled = YES;
        } else {
            editButton.enabled = NO;
        }
        //显示编辑按钮
        
        self.navigationItem.rightBarButtonItem = editButton;
        
    }
}

- (void)updateDeleteButtonTitle
{
    // 根据选中情况 更新删除标题
    NSArray *selectedRows = [self.tableView indexPathsForSelectedRows];
    
    BOOL allItemsAreSelected = selectedRows.count == self.dataSource.count;
    BOOL noItemsAreSelected = selectedRows.count == 0;
    
    if (allItemsAreSelected || noItemsAreSelected)
    {
        deleteButton.title = @"Delete All";
    }
    else
    {
        deleteButton.title = [NSString stringWithFormat:@"Delete (%d)", selectedRows.count];
    }
}


@end
