//
//  VNNote.m
//  Voice2Note
//
//  Created by liaojinxing on 14-6-11.
//  Copyright (c) 2014年 jinxing. All rights reserved.
//

#import "NoteManager.h"
#import "VNNote.h"

#define kNoteIDKey @"NoteID"
#define kTitleKey @"Title"
#define kContentKey @"Content"
#define kCreatedDate @"CreatedDate"
#define kUpdatedDate @"UpdatedDate"

@implementation VNNote

// 修改默认的实例变量名，但不建议这么做
//@synthesize noteID = _myNoteID;

- (id)initWithTitle:(NSString *)title
            content:(NSString *)content
        createdDate:(NSDate *)createdDate
         updateDate:(NSDate *)updatedDate {
    self = [super init];
    if (self) {
        _noteID = [NSNumber numberWithDouble:[createdDate timeIntervalSince1970]].stringValue;
        _title = title;
        _content = content;
        _createdDate = createdDate;
        _updatedDate = updatedDate;
        if (_title == nil || _title.length == 0) {
            _title = VNNOTE_DEFAULT_TITLE;
        }
        if (_content == nil || _content.length == 0) {
            _content = @"";
        }
    }
    return self;
}

/**
 *  归档，通过固定的编码规则转成 NSData 类型数据
 *
 *  @param encoder <#encoder description#>
 */
- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:_noteID forKey:kNoteIDKey];
    [encoder encodeObject:_title forKey:kTitleKey];
    [encoder encodeObject:_content forKey:kContentKey];
    [encoder encodeObject:_createdDate forKey:kCreatedDate];
}

/**
 *  //解档
 *
 *  @param decoder <#decoder description#>
 *
 *  @return <#return value description#>
 */
- (id)initWithCoder:(NSCoder *)decoder {
    NSString *title = [decoder decodeObjectForKey:kTitleKey];
    NSString *content = [decoder decodeObjectForKey:kContentKey];
    NSDate *createDate = [decoder decodeObjectForKey:kCreatedDate];
    NSDate *updateDate = [decoder decodeObjectForKey:kUpdatedDate];
    return [self initWithTitle:title
                       content:content
                   createdDate:createDate
                    updateDate:updateDate];
}

- (BOOL)Persistence {
    return [[NoteManager sharedManager] storeNote:self];
}

@end
