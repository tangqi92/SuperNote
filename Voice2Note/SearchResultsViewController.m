//
//  SearchResultsViewController.m
//  UISearchControllerDemo
//
//  Created by 大欢 on 15/9/19.
//  Copyright © 2015年 大欢. All rights reserved.
//

#import "SearchResultsViewController.h"
#import "VNNote.h"
#import "NoteListCell.h"
@interface SearchResultsViewController ()

@end

@implementation SearchResultsViewController

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    VNNote *note = [self.searchResults objectAtIndex:indexPath.row];
    return [NoteListCell heightWithNote:note];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [self.searchResults count];
   
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NoteListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SearchResultsCell"];
    if (!cell) {
        cell = [[NoteListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SearchResultsCell"];
    }
    NSLog(@"------->%d", self.searchResults.count);
    VNNote *note = [self.searchResults objectAtIndex:indexPath.row];
    cell.index = indexPath.row;
    [cell updateWithNote:note];
    return cell;
}


@end
