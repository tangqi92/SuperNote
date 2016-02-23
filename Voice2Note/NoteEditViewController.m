//
//  YYTextEditExample.m
//  YYKitExample
//
//  Created by ibireme on 15/9/3.
//  Copyright (c) 2015 ibireme. All rights reserved.
//

#import "AppContext.h"
#import "CALayer+YYAdd.h"
#import "CRMediaPickerController.h"
#import "HSDatePickerViewController.h"
#import "NSBundle+YYAdd.h"
#import "NSData+YYAdd.h"
#import "NSString+YYAdd.h"
#import "NoteEditViewController.h"
#import "SVProgressHUD.h"
#import "SignViewController.h"
#import "UIColor+VNHex.h"
#import "UIControl+YYAdd.h"
#import "UIGestureRecognizer+YYAdd.h"
#import "UIImage+YYWebImage.h"
#import "UIView+YYAdd.h"
#import "VNConstants.h"
#import "VNNote.h"
#import "YYImage.h"
#import "YYText.h"
#import "YYTextExampleHelper.h"
#import "iflyMSC/IFlyContact.h"
#import "iflyMSC/IFlyDataUploader.h"
#import "iflyMSC/IFlyRecognizerView.h"
#import "iflyMSC/IFlyRecognizerView.h"
#import "iflyMSC/IFlySpeechConstant.h"
#import "iflyMSC/IFlySpeechUtility.h"
@import MediaPlayer;

static const CGFloat kViewOriginY = 70;
static const CGFloat kTextFieldHeight = 30;
static const CGFloat kToolbarHeight = 44;
static const CGFloat kVoiceButtonWidth = 100;
static const CGFloat kVerticalMargin = 10;

@interface NoteEditViewController () <YYTextViewDelegate, YYTextKeyboardObserver, IFlyRecognizerViewDelegate, HSDatePickerViewControllerDelegate, CRMediaPickerControllerDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate, UINavigationControllerDelegate, UIAlertViewDelegate>

@property (nonatomic, assign) YYTextView *textView;
@property (nonatomic, retain) NSMutableAttributedString *attrString;
@property (nonatomic, strong) IFlyRecognizerView *iflyRecognizerView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UISwitch *verticalSwitch;
@property (nonatomic, strong) VNNote *note;
@property (nonatomic, strong) NSDate *selectedDate;
@property (nonatomic, strong) UIToolbar *comps;
@property (nonatomic, strong) UIView *toolbar;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UIBarButtonItem *photoBarButton, *mediaBarButton, *alarmBarButton, *voiceBarButton, *brushBarButton, *doneBarButton;
@property (nonatomic, strong) MPMoviePlayerController *moviePlayer;
@property (nonatomic, strong) CRMediaPickerController *mediaPickerController;
@property (nonatomic, assign) CRMediaPickerControllerMediaType selectedMediaType;
@property (nonatomic, assign) CRMediaPickerControllerSourceType selectedSourceType;
@property (nonatomic, assign) BOOL allowsEditing;
@property (nonatomic, assign) BOOL cameraOverlay;
@property (nonatomic, assign) NSInteger deviceCameraSelected;
@property (nonatomic) BOOL isEditingTitle;

@end

@implementation NoteEditViewController

- (instancetype)initWithNote:(VNNote *)note {
    self = [super init];
    if (self) {
        _note = note;
    }
    // 返回初始化后的对象的新地址
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor whiteColor];

    // compability with automaticallyAdjustsScrollViewInsets: http://stackoverflow.com/questions/20550019/compability-with-automaticallyadjustsscrollviewinsets
    if ([self respondsToSelector:@selector(setAutomaticallyAdjustsScrollViewInsets:)]) {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }

    [self initComps];
    [self initToolbar];
    [self initVertical];
    [self initImageView];
    [self initMediaPick];
    [self setupSpeechRecognizer];
    [self initAttributedString];
    [self initTextView];

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
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.mediaPickerController = nil;
    [self.moviePlayer stop];
    [self.moviePlayer.view removeFromSuperview];
    self.moviePlayer = nil;
}

#pragma mark -
#pragma mark === Init ===
#pragma mark -

- (void)initComps {
    _photoBarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_photo_size_select_actual_white_18pt_2x"] style:UIBarButtonItemStylePlain target:self action:@selector(addPhoto)];
    _photoBarButton.width = ceilf(self.view.frame.size.width) / 6 - 12;

    _mediaBarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_movie_filter_white_18pt_2x"] style:UIBarButtonItemStylePlain target:self action:@selector(addMedia)];
    _mediaBarButton.width = ceilf(self.view.frame.size.width) / 6 - 12;

    _alarmBarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_access_alarm_white_18pt_2x"] style:UIBarButtonItemStylePlain target:self action:@selector(addAlarm)];
    _alarmBarButton.width = ceilf(self.view.frame.size.width) / 6 - 12;

    _voiceBarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_settings_voice_white_18pt_2x"] style:UIBarButtonItemStylePlain target:self action:@selector(useVoiceInput)];
    _voiceBarButton.width = ceilf(self.view.frame.size.width) / 6 - 12;

    _brushBarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_brush_white_18pt_2x"] style:UIBarButtonItemStylePlain target:self action:@selector(addBrush)];
    _brushBarButton.width = ceilf(self.view.frame.size.width) / 6 - 12;

    _doneBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(hideKeyboard)];
    _doneBarButton.width = ceilf(self.view.frame.size.width) / 6 - 12;

    _comps = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, kToolbarHeight)];
    _comps.tintColor = [UIColor systemColor];
    _comps.items = [NSArray arrayWithObjects:_photoBarButton, _mediaBarButton, _alarmBarButton, _brushBarButton, _voiceBarButton, _doneBarButton, nil];
}

- (void)initToolbar {
    // 使用 UIVisualEffctView 来进行 Blur
    if ([UIVisualEffectView class]) {
        _toolbar = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight]];
    } else {
        _toolbar = [UIToolbar new];
    }
    _toolbar.size = CGSizeMake(kScreenWidth, 40);
    _toolbar.top = kiOS7Later ? 64 : 0;
    [self.view addSubview:_toolbar];
}

- (void)setupSpeechRecognizer {
    NSString *initString = [NSString stringWithFormat:@"%@=%@", [IFlySpeechConstant APPID], kIFlyAppID];

    [IFlySpeechUtility createUtility:initString];
    _iflyRecognizerView = [[IFlyRecognizerView alloc] initWithCenter:self.view.center];
    _iflyRecognizerView.delegate = self;

    [_iflyRecognizerView setParameter:@"iat" forKey:[IFlySpeechConstant IFLY_DOMAIN]];
    [_iflyRecognizerView setParameter:@"asr.pcm" forKey:[IFlySpeechConstant ASR_AUDIO_PATH]];
    [_iflyRecognizerView setParameter:@"plain" forKey:[IFlySpeechConstant RESULT_TYPE]];
}

- (void)initMediaPick {
    _selectedMediaType = CRMediaPickerControllerMediaTypeImage | CRMediaPickerControllerMediaTypeVideo; // Both
    _selectedSourceType = CRMediaPickerControllerSourceTypePhotoLibrary |
                          CRMediaPickerControllerSourceTypeCamera |
                          CRMediaPickerControllerSourceTypeSavedPhotosAlbum |
                          CRMediaPickerControllerSourceTypeLastPhotoTaken; // Prompt
}

- (void)setExclusionPathEnabled:(BOOL)enabled {
    if (enabled) {
        [self.textView addSubview:self.imageView];
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:self.imageView.frame
                                                        cornerRadius:self.imageView.layer.cornerRadius];
        self.textView.exclusionPaths = @[ path ]; /// Set exclusion paths
    } else {
        [self.imageView removeFromSuperview];
        self.textView.exclusionPaths = nil;
    }
}

- (void)initImageView {
    NSData *data = [NSData dataNamed:@"default_image.png"];
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
        self.textView.exclusionPaths = @[ path ];
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

- (void)initAttributedString {
    if (self.note) {
        _attrString = [[NSMutableAttributedString alloc] initWithString:_note.content];
    } else {
        _attrString = [[NSMutableAttributedString alloc] initWithString:@"请输入内容："];
    }
    _attrString.yy_font = [UIFont fontWithName:@"Times New Roman" size:20];
    _attrString.yy_lineSpacing = 4;
    _attrString.yy_firstLineHeadIndent = 20;
}

- (void)initTextView {
    YYTextView *textView = [YYTextView new];
    textView.attributedText = _attrString;
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
    textView.contentInset = UIEdgeInsetsMake(_toolbar.bottom, 0, 0, 0);
    textView.scrollIndicatorInsets = textView.contentInset;
    textView.selectedRange = NSMakeRange(_attrString.length, 0);
    textView.inputAccessoryView = self.comps;
    [self.view insertSubview:textView belowSubview:_toolbar];
    self.textView = textView;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [textView becomeFirstResponder];
    });
}

- (void)initVertical {
    _label = [UILabel new];
    _label.backgroundColor = [UIColor clearColor];
    _label.font = [UIFont systemFontOfSize:14];
    _label.text = @"Vertical:";
    _label.size = CGSizeMake([_label.text widthForFont:_label.font] + 2, _toolbar.height);
    _label.left = 10;
    [_toolbar addSubview:_label];
    __weak typeof(self) _self = self;

    _verticalSwitch = [UISwitch new];
    [_verticalSwitch sizeToFit];
    _verticalSwitch.centerY = _toolbar.height / 2;
    _verticalSwitch.left = _label.right - 5;
    _verticalSwitch.layer.transformScale = 0.8;
    // 选择逻辑
    [_verticalSwitch addBlockForControlEvents:UIControlEventValueChanged block:^(UISwitch *switcher) {
        [_self.textView endEditing:YES];
        _self.textView.verticalForm = switcher.isOn; /// Set vertical form
    }];
    [_toolbar addSubview:_verticalSwitch];
}

#pragma mark -
#pragma mark === YYTextViewDelegate ===
#pragma mark -

- (void)textViewDidBeginEditing:(YYTextView *)textView {
    UIBarButtonItem *saveItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"ActionSheetSave", @"")
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(saveNote)];

    UIBarButtonItem *moreItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_more_white"]
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(moreActionButtonPressed)];
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:moreItem, saveItem, nil];
}

- (void)textViewDidEndEditing:(YYTextView *)textView {
    self.navigationItem.rightBarButtonItem = nil;
}

#pragma mark -
#pragma mark === UIAlertViewDelegate ===
#pragma mark -

#define TAG_LOCK 1
#define TAG_UPLOADER 2

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == TAG_LOCK) {
        UITextField *text_field = [alertView textFieldAtIndex:0];
        if (buttonIndex == 1) {
            // 获取输入的密码
            NSLog(@"Password: %@", text_field.text);
            NSLog(@"_note.index: %lu", (unsigned long) _note.index);
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            [userDefaults setObject:text_field.text forKey:[NSString stringWithFormat:@"%lu", (unsigned long) _note.index]];
            // 如果没有调用synchronize方法，系统会根据I/O情况不定时刻地保存到文件中!
            [userDefaults synchronize];
        }
    } else if (alertView.tag == TAG_UPLOADER) {
        if (buttonIndex == 1) {
            IFlyDataUploader *_uploader = [[IFlyDataUploader alloc] init];
            IFlyContact *iFlyContact = [[IFlyContact alloc] init];
            NSString *contactList = [iFlyContact contact];
            [_uploader setParameter:@"uup" forKey:@"subject"];
            [_uploader setParameter:@"contact" forKey:@"dtt"];
            //启动上传
            [_uploader uploadDataWithCompletionHandler:^(NSString *grammerID, IFlySpeechError *error) {
                [SVProgressHUD showSuccessWithStatus:@"上传成功"];
            }
                                                  name:@"contact"
                                                  data:contactList];
        }
    }
}

#pragma mark -
#pragma mark === IFlyRecognizerViewDelegate ===
#pragma mark -

- (void)onResult:(NSArray *)resultArray isLast:(BOOL)isLast {
    NSMutableString *result = [[NSMutableString alloc] init];
    NSDictionary *dic = [resultArray objectAtIndex:0];
    for (NSString *key in dic) {
        [result appendFormat:@"%@", key];
    }
    _textView.text = [NSString stringWithFormat:@"%@%@", _textView.text, result];
}

- (void)onError:(IFlySpeechError *)error {
    NSLog(@"errorCode:%@", [error errorDesc]);
}

- (void)startListenning {
    [_iflyRecognizerView start];
    NSLog(@"start listenning...");
}

- (void)useVoiceInput {
    if (![AppContext appContext].hasUploadAddressBook) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                            message:NSLocalizedString(@"UploadABForBetter", @"")
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"ActionSheetCancel", @"")
                                                  otherButtonTitles:NSLocalizedString(@"GotoUploadAB", @""), nil];
        alertView.tag = TAG_UPLOADER;
        [alertView show];
        [[AppContext appContext] setHasUploadAddressBook:YES];
        return;
    }

    [self hideKeyboard];
    [self startListenning];
}

#pragma mark -
#pragma mark === UIBarButtonItemAction ===
#pragma mark -

// FIXME:
- (void)addPhoto {
    [self setExclusionPathEnabled:YES];
}

- (void)addMedia {
    [self hideKeyboard];
    self.mediaPickerController = [[CRMediaPickerController alloc] init];
    self.mediaPickerController.delegate = self;
    self.mediaPickerController.mediaType = self.selectedMediaType;
    self.mediaPickerController.sourceType = self.selectedSourceType;
    self.mediaPickerController.allowsEditing = self.allowsEditing;
    self.mediaPickerController.cameraDevice = (UIImagePickerControllerCameraDevice) self.deviceCameraSelected;

    [self.mediaPickerController show];
}

- (void)addAlarm {
    HSDatePickerViewController *hsdpvc = [HSDatePickerViewController new];
    hsdpvc.delegate = self;
    if (self.selectedDate) {
        hsdpvc.date = self.selectedDate;
    }
    [self presentViewController:hsdpvc animated:YES completion:nil];
}

- (void)addBrush {
    SignViewController *test = [[SignViewController alloc] initWithNibName:@"SignViewController" bundle:nil];
    [self hideKeyboard];

    [self.navigationController pushViewController:test animated:YES];
}

#pragma mark -
#pragma mark === saveNote ===
#pragma mark -

- (void)saveNote {
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
        [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"保存失败", @"")];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark === More Action ===
#pragma mark -

#define MORE_ACTION 3

- (void)moreActionButtonPressed {
    [self hideKeyboard];
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"ActionSheetCancel", @"")
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:NSLocalizedString(@"ActionSheetCopy", @""),
                                                                      NSLocalizedString(@"ActionSheetLock", @""),
                                                                      NSLocalizedString(@"ActionSheetMail", @""), nil];
    actionSheet.tag = MORE_ACTION;
    [actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {

    if (actionSheet.tag == MORE_ACTION) {
        if (buttonIndex == 0) {
            // 复制至剪切板
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            pasteboard.string = _textView.text;
            [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"CopySuccess", @"")];
        } else if (buttonIndex == 1) {
            [self lockTextAction];
        } else if (buttonIndex == 2) {
            if ([MFMailComposeViewController canSendMail]) { // 用户已设置邮件账户
                [self sendEmailAction];                      // 调用发送邮件的代码
            }
        }
    }
}

- (void)lockTextAction {
    // 锁定文本，弹出输入密码
    UIAlertView *alter = [[UIAlertView alloc] initWithTitle:@"请输入锁定密码"
                                                    message:nil
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"OK", nil];
    [alter setAlertViewStyle:UIAlertViewStyleSecureTextInput];
    // 以解决 Multiple UIAlertView 的代理事件
    alter.tag = TAG_LOCK;
    [alter show];
}

/**
 *  模拟器存在 BUG
 */
- (void)sendEmailAction {
    MFMailComposeViewController *composer = [[MFMailComposeViewController alloc] init];
    [composer setMailComposeDelegate:self];
    if ([MFMailComposeViewController canSendMail]) {
        [composer setSubject:@"来超级记事本的一封信"];
        [composer setMessageBody:_textView.text isHTML:NO];
        [composer setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];
        [self presentViewController:composer animated:YES completion:nil];
    } else {
        [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"CanNoteSendMail", @"")];
    }
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    if (result == MFMailComposeResultFailed) {
        [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"SendEmailFail", @"")];
    } else if (result == MFMailComposeResultSent) {
        [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"SendEmailSuccess", @"")];
    }
    [controller dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -
#pragma mark === HSDatePickerViewControllerDelegate ===
#pragma mark -

- (void)hsDatePickerPickedDate:(NSDate *)date {
    NSLog(@"Date picked %@", date);
    NSDateFormatter *dateFormater = [NSDateFormatter new];
    dateFormater.dateFormat = @"yyyy.MM.dd HH:mm:ss";
    // 获取日期后处理
    NSLog(@"Date picked stringFromDate %@", [dateFormater stringFromDate:date]);
   
    [self setNotification:date];
}

//optional
- (void)hsDatePickerDidDismissWithQuitMethod:(HSDatePickerQuitMethod)method {
    NSLog(@"Picker did dismiss with %lu", (unsigned long) method);
}

//optional
- (void)hsDatePickerWillDismissWithQuitMethod:(HSDatePickerQuitMethod)method {
    NSLog(@"Picker will dismiss with %lu", (unsigned long) method);
}

- (void)setNotification:(NSDate *)fireDate {
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    if (notification != nil) {

        notification.fireDate = fireDate;                         //触发通知的时间
        notification.repeatInterval = 0;                          //循环次数，

        notification.timeZone = [NSTimeZone defaultTimeZone];
        notification.soundName = UILocalNotificationDefaultSoundName;
        notification.alertBody = @"你有一条消啦(≧▽≦)";

        notification.alertAction = @"打开"; //提示框按钮
        notification.hasAction = YES;       //是否显示额外的按钮，为no时alertAction消失

        notification.applicationIconBadgeNumber = 1; //设置app图标右上角的数字

        //下面设置本地通知发送的消息，这个消息可以接受
        NSDictionary *infoDic = [NSDictionary dictionaryWithObject:@"value" forKey:@"key"];
        notification.userInfo = infoDic;
        //发送通知
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    }
}
#pragma mark -
#pragma mark === Keyboard ===
#pragma mark -

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

- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    [UIView animateWithDuration:[userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue]
                          delay:0.f
                        options:[userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue]
                     animations:^{
                         CGRect keyboardFrame = [[userInfo valueForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
                         CGFloat keyboardHeight = keyboardFrame.size.height;

                         CGRect frame = _textView.frame;
                         frame.size.height = self.view.frame.size.height - keyboardHeight,
                         _textView.frame = frame;
                     }
                     completion:NULL];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    [UIView animateWithDuration:[userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue]
                          delay:0.f
                        options:[userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue]
                     animations:^{
                         CGRect frame = _textView.frame;
                         frame.size.height = self.view.frame.size.height - kViewOriginY - kTextFieldHeight - kVoiceButtonWidth - kVerticalMargin * 3;
                         _textView.frame = frame;
                     }
                     completion:NULL];
}

- (void)hideKeyboard {
    if ([_textView isFirstResponder]) {
        _isEditingTitle = NO;
        [_textView resignFirstResponder];
    }
}

#pragma mark - CPDMediaPickerControllerDelegate

- (void)CRMediaPickerController:(CRMediaPickerController *)mediaPickerController didFinishPickingAsset:(ALAsset *)asset error:(NSError *)error {
    if (!error) {

        if (asset) {

            if ([[asset valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypePhoto]) {

                ALAssetRepresentation *representation = asset.defaultRepresentation;
                UIImage *image = [UIImage imageWithCGImage:representation.fullScreenImage];
                self.imageView.image = image;

            } else if ([[asset valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypeVideo]) {

                self.moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:asset.defaultRepresentation.url];
                self.moviePlayer.movieSourceType = MPMediaTypeMovie;
                self.moviePlayer.controlStyle = MPMovieControlStyleDefault;
                self.moviePlayer.scalingMode = MPMovieScalingModeAspectFit;
                self.moviePlayer.repeatMode = MPMovieRepeatModeNone;
                self.moviePlayer.allowsAirPlay = NO;
                self.moviePlayer.shouldAutoplay = NO;

                //                self.moviePlayer.view.frame = self.videoView.bounds;
                //                self.moviePlayer.view.autoresizingMask = (UIViewAutoresizing)(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
                //                [self.videoView addSubview:self.moviePlayer.view];
                // TODO: 获取视频后操作
                [self.moviePlayer prepareToPlay];
            }

        } else {
            NSLog(@"No media selected");
        }

    } else {
        NSLog(@"%@", error.localizedDescription);
    }
}

- (void)CRMediaPickerControllerDidCancel:(CRMediaPickerController *)mediaPickerController {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

@end
