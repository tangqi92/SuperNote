//
//  NoteListCell.m
//  Voice2Note
//
//  Created by liaojinxing on 14-6-12.
//  Copyright (c) 2014年 jinxing. All rights reserved.
//

#import "Colours.h"
#import "Masonry.h"
#import "NoteListCell.h"
#import "UIColor+VNHex.h"
#import "VNConstants.h"
#import "VNNote.h"

@interface NoteListCell ()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, assign) BOOL didSetupConstraints;

@end

@implementation NoteListCell

// 调用UITableView的dequeueReusableCellWithIdentifier方法时会通过这个方法初始化 Cell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self initView];
        [self updateConstraints];
    }
    return self;
}

- (void)initView {
    // ???:
    self.tag = 1000;
    // 计算 UILabel 的 preferredMaxLayoutWidth 值，多行时必须设置这个值，否则系统无法决定 Label 的宽度
    CGFloat preferredMaxWidth = [UIScreen mainScreen].bounds.size.width - 75;
    // 从此以后基本可以抛弃 CGRectMake 了
    _titleLabel = [UILabel new];
    [_titleLabel setTextColor:[UIColor charcoalColor]];
    [_titleLabel setFont:[UIFont boldSystemFontOfSize:17]];
    [_titleLabel setNumberOfLines:0];
    _titleLabel.preferredMaxLayoutWidth = preferredMaxWidth; // 多行时必须设置
    // 使用 AutoLayout 之前，一定要先将 view 添加到 superview 上，否则会报错
    [self.contentView addSubview:_titleLabel];

    _timeLabel = [UILabel new];
    [_timeLabel setTextColor:[UIColor charcoalColor]];
    [_timeLabel setFont:[UIFont systemFontOfSize:14]];
    [_timeLabel setTextAlignment:NSTextAlignmentRight];
    [self.contentView addSubview:_timeLabel];

    self.selectionStyle = UITableViewCellSelectionStyleBlue;
}

- (void)updateConstraints {
    if (!self.didSetupConstraints) {
        [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.contentView).with.offset(15);
            make.left.equalTo(self.contentView).with.offset(15);
            make.right.equalTo(self.contentView).with.offset(-15);
            make.bottom.equalTo(self.contentView).with.offset(-15);
        }];

        [_titleLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];

        [_timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo(@15);
            make.right.equalTo(self.contentView).with.offset(-15);
            make.bottom.equalTo(self.titleLabel).with.offset(15);
        }];

        // 避免重复设置相同的约束
        self.didSetupConstraints = YES;
    }

    [super updateConstraints];
}

- (void)updateWithNote:(VNNote *)note {
    NSString *string = note.title;
    [_titleLabel setText:note.title];
    if (!note.title || note.title.length <= 0 || [note.title isEqualToString:NSLocalizedString(@"NoTitleNote", @"")]) {
        string = note.content;
        [_titleLabel setText:note.content];
    }
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm"];
    [_timeLabel setText:[formatter stringFromDate:note.createdDate]];
}

@end
