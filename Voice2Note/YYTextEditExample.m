//
//  YYTextEditExample.m
//  YYKitExample
//
//  Created by ibireme on 15/9/3.
//  Copyright (c) 2015 ibireme. All rights reserved.
//

#import "YYTextEditExample.h"
#import "YYText.h"
#import "YYImage.h"
#import "UIImage+YYWebImage.h"
#import "UIView+YYAdd.h"
#import "NSBundle+YYAdd.h"
#import "NSString+YYAdd.h"
#import "UIControl+YYAdd.h"
#import "CALayer+YYAdd.h"
#import "NSData+YYAdd.h"
#import "UIGestureRecognizer+YYAdd.h"
#import "YYTextExampleHelper.h"
#import "VNConstants.h"
#import "SignViewController.h"
#import "UIColor+VNHex.h"
#import "VNNote.h"
#import "iflyMSC/IFlyRecognizerView.h"
#import "iflyMSC/IFlySpeechConstant.h"
#import "iflyMSC/IFlySpeechUtility.h"
#import "iflyMSC/IFlyRecognizerView.h"
#import "iflyMSC/IFlyDataUploader.h"
#import "iflyMSC/IFlyContact.h"
#import "AppContext.h"
#import "SVProgressHUD.h"
#import "AppContext.h"
#import "HSDatePickerViewController.h"

static const CGFloat kViewOriginY = 70;
static const CGFloat kTextFieldHeight = 30;
static const CGFloat kToolbarHeight = 44;
static const CGFloat kVoiceButtonWidth = 100;

@interface YYTextEditExample () <YYTextViewDelegate, YYTextKeyboardObserver, IFlyRecognizerViewDelegate, UIActionSheetDelegate,
MFMailComposeViewControllerDelegate, UINavigationControllerDelegate, UIAlertViewDelegate, HSDatePickerViewControllerDelegate>


@property (nonatomic, assign) YYTextView *textView;
@property (nonatomic, assign) IFlyRecognizerView *iflyRecognizerView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UISwitch *verticalSwitch;
@property (nonatomic, strong) UISwitch *debugSwitch;
@property (nonatomic, strong) UISwitch *exclusionSwitch;
@property (nonatomic, strong) VNNote *note;
@property (nonatomic, strong) NSDate *selectedDate;
@property (nonatomic) BOOL isEditingTitle;





@end

@implementation YYTextEditExample

- (instancetype)initWithNote:(VNNote *)note
{
    self = [super init];
    if (self) {
        _note = note;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    if ([self respondsToSelector:@selector(setAutomaticallyAdjustsScrollViewInsets:)]) {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    [self initImageView];
    __weak typeof(self) _self = self;
    
    UIView *toolbar;
    if ([UIVisualEffectView class]) {
        toolbar = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight]];
    } else {
        toolbar = [UIToolbar new];
    }
    toolbar.size = CGSizeMake(kScreenWidth, 40);
    toolbar.top = kiOS7Later ? 64 : 0;
    [self.view addSubview:toolbar];
    
    
    CGRect frame = CGRectMake(10.f, 70, self.view.frame.size.width - 10.f * 2, 30);
    
    
    UIBarButtonItem *photoBarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_photo_size_select_actual_white_18pt_2x"] style:UIBarButtonItemStylePlain target:self action:@selector(addPhoto)];
    photoBarButton.width = ceilf(self.view.frame.size.width) / 6 - 12;
    
    
    UIBarButtonItem *mediaBarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_movie_filter_white_18pt_2x"] style:UIBarButtonItemStylePlain target:self action:@selector(addMedia)];
    mediaBarButton.width = ceilf(self.view.frame.size.width) / 6 - 12;
    
    
    UIBarButtonItem *alarmBarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_access_alarm_white_18pt_2x"] style:UIBarButtonItemStylePlain target:self action:@selector(addAlarm)];
    alarmBarButton.width = ceilf(self.view.frame.size.width) / 6 - 12;
    
    
    UIBarButtonItem *voiceBarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_settings_voice_white_18pt_2x"] style:UIBarButtonItemStylePlain target:self action:@selector(useVoiceInput)];
    voiceBarButton.width = ceilf(self.view.frame.size.width) / 6 - 12;
    
    UIBarButtonItem *brushBarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_brush_white_18pt_2x"] style:UIBarButtonItemStylePlain target:self action:@selector(addBrush)];
    brushBarButton.width = ceilf(self.view.frame.size.width) / 6 - 12;
    
    
    UIBarButtonItem *doneBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(hideKeyboard)];
    doneBarButton.width = ceilf(self.view.frame.size.width) / 6 - 12;
    
    UIToolbar *toolbarr = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    toolbarr.tintColor = [UIColor systemColor];
    toolbarr.items = [NSArray arrayWithObjects:photoBarButton,mediaBarButton, alarmBarButton, brushBarButton, voiceBarButton, doneBarButton, nil];
    
    frame = CGRectMake(10.f,
                       0,
                       self.view.frame.size.width - 10.f * 2,
                       self.view.frame.size.height - 100 - 10.f * 2);
    
    
    
    
    
    
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithString:_note.content];
    text.yy_font = [UIFont fontWithName:@"Times New Roman" size:20];
    text.yy_lineSpacing = 4;
    text.yy_firstLineHeadIndent = 20;
    
    
    
    
    
    
    YYTextView *textView = [YYTextView new];
    textView.attributedText = text;
    textView.size = self.view.size;
    textView.autocorrectionType = UITextAutocorrectionTypeNo;
    textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
    textView.textContainerInset = UIEdgeInsetsMake(10, 10, 10, 10);
    textView.delegate = self;
    if (kiOS7Later) {
        textView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    } else {
        textView.height -= 64;
    }
    textView.contentInset = UIEdgeInsetsMake(toolbar.bottom, 0, 0, 0);
    textView.scrollIndicatorInsets = textView.contentInset;
    textView.selectedRange = NSMakeRange(text.length, 0);
    textView.inputAccessoryView = toolbarr;
    [self.view insertSubview:textView belowSubview:toolbar];
    self.textView = textView;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [textView becomeFirstResponder];
    });
    
    
    
    /*------------------------------ Toolbar ---------------------------------*/
    UILabel *label;
    label = [UILabel new];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont systemFontOfSize:14];
    label.text = @"Vertical:";
    label.size = CGSizeMake([label.text widthForFont:label.font] + 2, toolbar.height);
    label.left = 10;
    [toolbar addSubview:label];
    
    _verticalSwitch = [UISwitch new];
    [_verticalSwitch sizeToFit];
    _verticalSwitch.centerY = toolbar.height / 2;
    _verticalSwitch.left = label.right - 5;
    _verticalSwitch.layer.transformScale = 0.8;
    // 选择逻辑
    [_verticalSwitch addBlockForControlEvents:UIControlEventValueChanged block:^(UISwitch *switcher) {
        [_self.textView endEditing:YES];
        _self.textView.verticalForm = switcher.isOn; /// Set vertical form
    }];
    [toolbar addSubview:_verticalSwitch];
    
    
    [[YYTextKeyboardManager defaultManager] addObserver:self];
    
    
    
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
}

- (void)dealloc {
    [[YYTextKeyboardManager defaultManager] removeObserver:self];
}

- (void)setExclusionPathEnabled:(BOOL)enabled {
    if (enabled) {
        [self.textView addSubview:self.imageView];
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:self.imageView.frame
                                                        cornerRadius:self.imageView.layer.cornerRadius];
        self.textView.exclusionPaths = @[path]; /// Set exclusion paths
    } else {
        [self.imageView removeFromSuperview];
        self.textView.exclusionPaths = nil;
    }
}

- (void)initImageView {
    NSData *data = [NSData dataNamed:@"dribbble256_imageio.png"];
    UIImage *image = [[YYImage alloc] initWithData:data scale:2];
    UIImageView *imageView = [[YYAnimatedImageView alloc] initWithImage:image];
    imageView.clipsToBounds = YES;
    imageView.userInteractionEnabled = YES;
    imageView.layer.cornerRadius = imageView.height / 2;
    imageView.center = CGPointMake(kScreenWidth / 2, kScreenWidth / 2);
    self.imageView = imageView;
    
    
    __weak typeof(self) _self = self;
    UIPanGestureRecognizer *g = [[UIPanGestureRecognizer alloc] initWithActionBlock:^(UIPanGestureRecognizer *g) {
        __strong typeof(_self) self = _self;
        if (!self) return;
        CGPoint p = [g locationInView:self.textView];
        self.imageView.center = p;
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:self.imageView.frame
                                                        cornerRadius:self.imageView.layer.cornerRadius];
        self.textView.exclusionPaths = @[path];
    }];
    [imageView addGestureRecognizer:g];
}

- (void)edit:(UIBarButtonItem *)item {
    if (_textView.isFirstResponder) {
        [_textView resignFirstResponder];
    } else {
        [_textView becomeFirstResponder];
    }
}

#pragma mark text view

- (void)textViewDidBeginEditing:(YYTextView *)textView {
    UIBarButtonItem *saveItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"ActionSheetSave", @"")
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(save)];
    
    UIBarButtonItem *moreItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_more_white"]
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(moreActionButtonPressed)];
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:moreItem, saveItem, nil];
}

- (void)textViewDidEndEditing:(YYTextView *)textView {
    self.navigationItem.rightBarButtonItem = nil;
}


#pragma mark - keyboard

- (void)keyboardChangedWithTransition:(YYTextKeyboardTransition)transition {
    BOOL clipped = NO;
    if (_textView.isVerticalForm && transition.toVisible) {
        CGRect rect = [[YYTextKeyboardManager defaultManager] convertRect:transition.toFrame toView:self.view];
        if (CGRectGetMaxY(rect) == self.view.height) {
            CGRect textFrame = self.view.bounds;
            textFrame.size.height -= rect.size.height;
            _textView.frame = textFrame;
            clipped = YES;
        }
    }
    
    if (!clipped) {
        _textView.frame = self.view.bounds;
    }
}




#pragma mark - Keyboard

- (void)keyboardWillShow:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    [UIView animateWithDuration:[userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue]
                          delay:0.f
                        options:[userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue]
                     animations:^
     {
         CGRect keyboardFrame = [[userInfo valueForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
         CGFloat keyboardHeight = keyboardFrame.size.height;
         
         CGRect frame = _textView.frame;
         self.view.frame.size.height - kTextFieldHeight - keyboardHeight,
         _textView.frame = frame;
     }               completion:NULL];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    [UIView animateWithDuration:[userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue]
                          delay:0.f
                        options:[userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue]
                     animations:^
     {
         CGRect frame = _textView.frame;
         frame.size.height = self.view.frame.size.height - kViewOriginY - kTextFieldHeight - kVoiceButtonWidth - kVerticalMargin * 3;
         _textView.frame = frame;
     }               completion:NULL];
}

- (void)hideKeyboard
{
    if ([_textView isFirstResponder]) {
        _isEditingTitle = NO;
        [_textView resignFirstResponder];
    }
}


#pragma mark - bar

- (void)startListenning
{
    [_iflyRecognizerView start];
    NSLog(@"start listenning...");
}

- (void)useVoiceInput
{
    if (![AppContext appContext].hasUploadAddressBook) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                            message:NSLocalizedString(@"UploadABForBetter", @"")
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"ActionSheetCancel", @"")
                                                  otherButtonTitles:NSLocalizedString(@"GotoUploadAB", @""), nil];
        [alertView show];
        [[AppContext appContext] setHasUploadAddressBook:YES];
        return;
    }
    
    [self hideKeyboard];
    [self startListenning];
    
}


- (void)addPhoto
{
    [self setExclusionPathEnabled:YES];
}

- (void)addMedia
{
    
}

- (void)addAlarm
{
    HSDatePickerViewController *hsdpvc = [HSDatePickerViewController new];
    hsdpvc.delegate = self;
    if (self.selectedDate) {
        hsdpvc.date = self.selectedDate;
    }
    [self presentViewController:hsdpvc animated:YES completion:nil];
}

- (void)addBrush
{
    
    //    TestViewController *test = [[TestViewController alloc] init];
    //    [self hideKeyboard];
    //    [self.navigationController pushViewController:test animated:YES];
    
    SignViewController *test = [[SignViewController alloc] initWithNibName:@"SignViewController" bundle:nil];
    [self hideKeyboard];
    
    [self.navigationController pushViewController:test animated:YES];
}


#pragma mark - Save

- (void)save
{
    [self hideKeyboard];
    if ((_textView.text == nil || _textView.text.length == 0)) {
        return;
    }
    NSDate *createDate;
    if (_note && _note.createdDate) {
        createDate = _note.createdDate;
    } else {
        createDate = [NSDate date];
    }
    VNNote *note = [[VNNote alloc] initWithTitle:nil
                                         content:_textView.text
                                     createdDate:createDate
                                      updateDate:[NSDate date]];
    _note = note;
    BOOL success = [note Persistence];
    if (success) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationCreateFile object:nil userInfo:nil];
    } else {
        [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"SaveFail", @"")];
    }
    [self.navigationController popViewControllerAnimated:YES];
}
#pragma mark - More Action

- (void)moreActionButtonPressed
{
    [self hideKeyboard];
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"ActionSheetCancel", @"")
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:NSLocalizedString(@"ActionSheetCopy", @""),NSLocalizedString(@"ActionSheetLock", @""), nil];
    [actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = _textView.text;
        [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"CopySuccess", @"")];
    } else if (buttonIndex == 1) {
    // 锁定文本，弹出输入密码
        UIAlertView *alter = [[UIAlertView alloc] initWithTitle:@"请输入锁定密码"
                                                        message:nil
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"OK", nil];
        [alter setAlertViewStyle:UIAlertViewStyleSecureTextInput];
        [alter show];
    
    } else if (buttonIndex == 2) {
    }
}



#pragma mark - HSDatePickerViewControllerDelegate
- (void)hsDatePickerPickedDate:(NSDate *)date {
    NSLog(@"Date picked %@", date);
    NSDateFormatter *dateFormater = [NSDateFormatter new];
    dateFormater.dateFormat = @"yyyy.MM.dd HH:mm:ss";
//    self.dateLabel.text = [dateFormater stringFromDate:date];
//    
//    self.selectedDate = date;
}

//optional
- (void)hsDatePickerDidDismissWithQuitMethod:(HSDatePickerQuitMethod)method {
    NSLog(@"Picker did dismiss with %lu", (unsigned long)method);
}

//optional
- (void)hsDatePickerWillDismissWithQuitMethod:(HSDatePickerQuitMethod)method {
    NSLog(@"Picker will dismiss with %lu", (unsigned long)method);
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
    UITextField *text_field = [alertView textFieldAtIndex:0];
    

    if (buttonIndex == 1) {
        // 获取输入的密码
        NSLog(@"text: %@", text_field.text);
        
    }
}


@end
