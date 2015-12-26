//
//  VNNoteManager.m
//  Voice2Note
//
//  Created by liaojinxing on 14-6-11.
//  Copyright (c) 2014年 jinxing. All rights reserved.
//

#import "NoteManager.h"
#import "VNConstants.h"
#import "VNNote.h"
#import "NSDate+Conversion.h"

@implementation NoteManager

+ (instancetype)sharedManager
{
    static id instance = nil;
    static dispatch_once_t onceToken = 0L;
    dispatch_once(&onceToken, ^{
        instance = [[super allocWithZone:NULL] init];
    });
    return instance;
}

 /**
 *  创建存储路径
 *
 *  @return <#return value description#>
 */
- (NSString *)createDataPathIfNeeded
{
    NSString *documentsDirectory = [self documentDirectoryPath];
    self.docPath = documentsDirectory;
    
    // defaultManager 创建单例对象，判断指定路径文件是否存在
    if ([[NSFileManager defaultManager] fileExistsAtPath:documentsDirectory]) {
        return self.docPath;
    }
    
    // 声明一个指向 NSError 对象的指针，但是不创建相应的对象
    // 实际上，只有当发生错误时，才会由 writeToFile 创建相应的 NSError 对象
    NSError *error;
    BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:documentsDirectory
                                             withIntermediateDirectories:YES
                                                              attributes:nil
                                                                   error:&error];
    // 检查返回的布尔值，如果写入文件失败，就查询 NSError 对象并输出错误描述
    if (!success) {
        NSLog(@"Error creating data path: %@", [error localizedDescription]);
    }
    return self.docPath;
}

- (NSString *)documentDirectoryPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    // 在 Documents 目录下 kAppEngName 文件夹
    documentsDirectory = [documentsDirectory stringByAppendingPathComponent:kAppEngName];
    return documentsDirectory;
}

- (NSMutableArray *)readAllNotes
{
    NSMutableArray *array = [NSMutableArray array];
    NSError *error;
    NSString *documentsDirectory = [self createDataPathIfNeeded];
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:&error];
    
    if (files == nil) {
        NSLog(@"Error reading contents of documents directory: %@", [error localizedDescription]);
        return nil;
    }
    // Create Note for each file
    for (NSString *file in files) {
        VNNote *note = [self readNoteWithID:file];
        if (note) {
            [array addObject:note];
        }
    }
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdDate"
                                                 ascending:NO];
    return [NSMutableArray arrayWithArray:[array sortedArrayUsingDescriptors:@[sortDescriptor]]];
}

- (VNNote *)readNoteWithID:(NSString *)noteID;
{
    NSString *dataPath = [_docPath stringByAppendingPathComponent:noteID];
    NSData *codedData = [[NSData alloc] initWithContentsOfFile:dataPath];
    if (codedData == nil) {
        return nil;
    }
    VNNote *note = [NSKeyedUnarchiver unarchiveObjectWithData:codedData];
    return note;
}

- (BOOL)storeNote:(VNNote *)note
{
    [self createDataPathIfNeeded];
    NSString *dataPath = [_docPath stringByAppendingPathComponent:note.noteID];
    // 通过归档，将复杂对象转换为NSData；通过反归档，将NSData转换为复杂对象
    NSData *savedData = [NSKeyedArchiver archivedDataWithRootObject:note];
    return [savedData writeToFile:dataPath atomically:YES];
}

- (void)deleteNote:(VNNote *)note
{
    NSString *filePath = [_docPath stringByAppendingPathComponent:note.noteID];
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
}

- (VNNote *)todayNote
{
    NSMutableArray *notes = [self readAllNotes];
    for (VNNote *note in notes) {
        if ([NSDate isSameDay:note.createdDate andDate:[NSDate date]]) {
            return note;
        }
    }
    return nil;
}

@end
