//
//  NoteListViewController.h
//  Voice2Note
//
//  Created by liaojinxing on 14-6-11.
//  Copyright (c) 2014年 jinxing. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NoteListViewController : UITableViewController <UISearchResultsUpdating> {
    UIBarButtonItem *cancelButton;
    UIBarButtonItem *addButton;
    UIBarButtonItem *editButton;
    UIBarButtonItem *deleteButton;
}

@property (nonatomic, strong) UISearchController *searchController;

@end