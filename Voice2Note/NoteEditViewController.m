//
//  NoteEditViewController.m
//  Voice2Note
//
//  Created by ibireme on 15/9/3.
//  Copyright (c) 2015 ibireme. All rights reserved.
//

#import "AppContext.h"
#import "CALayer+YYAdd.h"
#import "HSDatePickerViewController.h"
#import "NSBundle+YYAdd.h"
#import "NSData+YYAdd.h"
#import "NSString+YYAdd.h"
#import "NoteEditViewController.h"
#import "QTClickImageView.h"
#import "SVProgressHUD.h"
#import "SignViewController.h"
#import "UIColor+VNHex.h"
#import "UIControl+YYAdd.h"
#import "UIGestureRecognizer+YYAdd.h"
#import "UIImage+YYWebImage.h"
#import "UIView+YYAdd.h"
#import "UMSocial.h"
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

// 多用类型常量，少用 #define 预处理指令（Effective - 4）
static const CGFloat kViewOriginY = 70;
static const CGFloat kTextFieldHeight = 30;
static const CGFloat kToolbarHeight = 44;
static const CGFloat kVoiceButtonWidth = 100;
static const CGFloat kVerticalMargin = 10;
static const NSInteger kLockTag = 1;
static const NSInteger kUploadTag = 2;
static const NSInteger kMoreActionTag = 3;
static const NSInteger kPickPhotoTag = 4;

@interface NoteEditViewController () <YYTextViewDelegate, YYTextKeyboardObserver, IFlyRecognizerViewDelegate, HSDatePickerViewControllerDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate, UINavigationControllerDelegate, UIAlertViewDelegate, UIImagePickerControllerDelegate, QTClickImageViewDelegate>

/**
 *  YYTextView - The API and behavior is similar to UITextView, but provides more features.
 *  第一，它是文本系统用来绘制的视图；第二，它是处理所有的用户交互
 */
@property (nonatomic, strong) YYTextView *textView;
@property (nonatomic, strong) NSMutableAttributedString *attrString;
@property (nonatomic, strong) IFlyRecognizerView *iflyRecognizerView;
@property (nonatomic, strong) UISwitch *verticalSwitch;
@property (nonatomic, strong) VNNote *note;
@property (nonatomic, strong) NSDate *selectedDate;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UIToolbar *comps;
@property (nonatomic, strong) UIView *toolbar;
@property (nonatomic, strong) UIBarButtonItem *photoBarButton, *mediaBarButton, *alarmBarButton, *voiceBarButton, *brushBarButton, *doneBarButton;
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

    // Compability with automaticallyAdjustsScrollViewInsets: http://stackoverflow.com/questions/20550019/compability-with-automaticallyadjustsscrollviewinsets
    if ([self respondsToSelector:@selector(setAutomaticallyAdjustsScrollViewInsets:)]) {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }

    [self initVertical];
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
}

#pragma mark -
#pragma mark === InitViews ===
#pragma mark -

// 使用懒加载 UI
- (UIBarButtonItem *)photoBarButton {
    if (!_photoBarButton) {
        _photoBarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"bar_font_white"] style:UIBarButtonItemStylePlain target:self action:@selector(setFont)];
        _photoBarButton.width = ceilf(self.view.frame.size.width) / 6 - 12;
    }
    return _photoBarButton;
}

- (UIBarButtonItem *)mediaBarButton {
    if (!_mediaBarButton) {
        _mediaBarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"bar_media_white"] style:UIBarButtonItemStylePlain target:self action:@selector(pickPhoto)];
        _mediaBarButton.width = ceilf(self.view.frame.size.width) / 6 - 12;
    }
    return _mediaBarButton;
}

- (UIBarButtonItem *)alarmBarButton {
    if (!_alarmBarButton) {
        _alarmBarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"bar_alarm_white"] style:UIBarButtonItemStylePlain target:self action:@selector(addAlarm)];
        _alarmBarButton.width = ceilf(self.view.frame.size.width) / 6 - 12;
    }
    return _alarmBarButton;
}

- (UIBarButtonItem *)voiceBarButton {
    if (!_voiceBarButton) {
        _voiceBarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"bar_voice_white"] style:UIBarButtonItemStylePlain target:self action:@selector(useVoiceInput)];
        _voiceBarButton.width = ceilf(self.view.frame.size.width) / 6 - 12;
    }
    return _voiceBarButton;
}

- (UIBarButtonItem *)brushBarButton {
    if (!_brushBarButton) {
        _brushBarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"bar_brush_white"] style:UIBarButtonItemStylePlain target:self action:@selector(addBrush)];
        _brushBarButton.width = ceilf(self.view.frame.size.width) / 6 - 12;
    }
    return _brushBarButton;
}

- (UIBarButtonItem *)doneBarButton {
    if (!_doneBarButton) {
        _doneBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(hideKeyboard)];
        _doneBarButton.width = ceilf(self.view.frame.size.width) / 6 - 12;
    }
    return _doneBarButton;
}

- (UIToolbar *)comps {
    if (!_comps) {
        _comps = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, kToolbarHeight)];
        _comps.tintColor = [UIColor systemColor];
        // 多用字面量语法，少用与之等价的方法（Effective - 3）
        _comps.items = @[ self.photoBarButton, self.mediaBarButton, self.alarmBarButton, self.brushBarButton, self.voiceBarButton, self.doneBarButton ];
    }
    return _comps;
}

- (UIView *)toolbar {
    if (!_toolbar) {
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
    return _toolbar;
}

- (IFlyRecognizerView *)iflyRecognizerView {
    if (!_iflyRecognizerView) {
        NSString *initString = [NSString stringWithFormat:@"%@=%@", [IFlySpeechConstant APPID], kIFlyAppID];
        [IFlySpeechUtility createUtility:initString];

        _iflyRecognizerView = [[IFlyRecognizerView alloc] initWithCenter:self.view.center];
        _iflyRecognizerView.delegate = self;
        [_iflyRecognizerView setParameter:@"iat" forKey:[IFlySpeechConstant IFLY_DOMAIN]];
        [_iflyRecognizerView setParameter:@"asr.pcm" forKey:[IFlySpeechConstant ASR_AUDIO_PATH]];
        [_iflyRecognizerView setParameter:@"plain" forKey:[IFlySpeechConstant RESULT_TYPE]];
    }
    return _iflyRecognizerView;
}

- (void)edit:(UIBarButtonItem *)item {
    if (_textView.isFirstResponder) {
        [_textView resignFirstResponder];
    } else {
        [_textView becomeFirstResponder];
    }
}

- (NSMutableAttributedString *)attrString {
    if (!_attrString) {
        if (self.note) {
            _attrString = [[NSMutableAttributedString alloc] initWithString:self.note.content];
        } else {
            // This is a tricky method
            _attrString = [[NSMutableAttributedString alloc] initWithString:@" "];
        }
        _attrString.yy_font = [UIFont fontWithName:@"Times New Roman" size:18];
        _attrString.yy_lineSpacing = 4;
        _attrString.yy_firstLineHeadIndent = 20;
    }
    return _attrString;
}

- (void)initTextView {

    if (!_textView) {
        _textView = [YYTextView new];
        _textView.attributedText = self.attrString;
        _textView.size = self.view.size;
        _textView.autocorrectionType = UITextAutocorrectionTypeNo;
        _textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _textView.textContainerInset = UIEdgeInsetsMake(10, 10, 10, 10);
        _textView.delegate = self;
        if (kiOS7Later) {
            _textView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
        } else {
            _textView.height -= 64;
        }
        _textView.contentInset = UIEdgeInsetsMake(self.toolbar.bottom, 0, 0, 0);
        _textView.scrollIndicatorInsets = _textView.contentInset;
        _textView.selectedRange = NSMakeRange(self.attrString.length, 0);
        _textView.inputAccessoryView = self.comps;
        [self.view insertSubview:_textView belowSubview:self.toolbar];
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.textView becomeFirstResponder];
    });
}

- (UILabel *)label {
    if (!_label) {
        _label = [UILabel new];
        _label.backgroundColor = [UIColor clearColor];
        _label.font = [UIFont systemFontOfSize:14];
        _label.text = @"Vertical:";
        _label.size = CGSizeMake([_label.text widthForFont:_label.font] + 2, self.toolbar.height);
        _label.left = 10;
        [self.toolbar addSubview:_label];
    }
    return _label;
}

- (UISwitch *)verticalSwitch {
    if (!_verticalSwitch) {
        __weak typeof(self) _self = self;

        _verticalSwitch = [UISwitch new];
        [_verticalSwitch sizeToFit];
        _verticalSwitch.centerY = self.toolbar.height / 2;
        _verticalSwitch.left = self.label.right - 5;
        _verticalSwitch.layer.transformScale = 0.8;
        // 选择逻辑
        [_verticalSwitch addBlockForControlEvents:UIControlEventValueChanged block:^(UISwitch *switcher) {
            [_self.textView endEditing:YES];
            _self.textView.verticalForm = switcher.isOn; /// Set vertical form
        }];
    }
    return _verticalSwitch;
}

- (void)initVertical {
    [self.toolbar addSubview:self.verticalSwitch];
}

#pragma mark -
#pragma mark === YYTextViewDelegate ===
#pragma mark -

- (void)textViewDidBeginEditing:(YYTextView *)textView {
    UIBarButtonItem *saveItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"ActionSheetSave", @"")
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(saveNote)];

    UIBarButtonItem *moreItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"toolbar_more_white"]
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(moreAction)];
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:moreItem, saveItem, nil];
}

- (void)textViewDidEndEditing:(YYTextView *)textView {
    self.navigationItem.rightBarButtonItem = nil;
}

#pragma mark -
#pragma mark === UIAlertViewDelegate ===
#pragma mark -

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == kLockTag) {
        UITextField *text_field = [alertView textFieldAtIndex:0];
        if (buttonIndex == 1) {
            // 获取输入的密码
            NSLog(@"Password: %@", text_field.text);
            NSLog(@"_note.index: %lu", (unsigned long) _note.index);
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            [userDefaults setObject:text_field.text forKey:[NSString stringWithFormat:@"%lu", (unsigned long) _note.index]];
            // 如果没有调用 synchronize 方法，系统会根据 I/O 情况不定时刻地保存到文件中!
            [userDefaults synchronize];
        }
    } else if (alertView.tag == kUploadTag) {
        if (buttonIndex == 1) {
            IFlyDataUploader *_uploader = [[IFlyDataUploader alloc] init];
            IFlyContact *iFlyContact = [[IFlyContact alloc] init];
            NSString *contactList = [iFlyContact contact];
            [_uploader setParameter:@"uup" forKey:@"subject"];
            [_uploader setParameter:@"contact" forKey:@"dtt"];
            // 启动上传
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
    [self.iflyRecognizerView start];
    NSLog(@"start listenning...");
}

- (void)useVoiceInput {
    if (![AppContext appContext].hasUploadAddressBook) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                            message:NSLocalizedString(@"UploadABForBetter", @"")
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"ActionSheetCancel", @"")
                                                  otherButtonTitles:NSLocalizedString(@"GotoUploadAB", @""), nil];
        alertView.tag = kUploadTag;
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

- (void)setFont {
    //TODO:
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

- (void)moreAction {
    [self hideKeyboard];
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"ActionSheetCancel", @"")
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:NSLocalizedString(@"ActionSheetShare", @""),
                                                                      NSLocalizedString(@"ActionSheetCopy", @""),
                                                                      NSLocalizedString(@"ActionSheetLock", @""), nil];
    actionSheet.tag = kMoreActionTag;
    [actionSheet showInView:self.view];
}

- (void)pickPhoto {
    [self hideKeyboard];
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"ActionSheetCancel", @"")
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:NSLocalizedString(@"ActionSheetPhoto", @""),
                                                                      NSLocalizedString(@"ActionSheetAlbum", @""), nil];
    actionSheet.tag = kPickPhotoTag;
    [actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {

    if (actionSheet.tag == kMoreActionTag) {
        if (buttonIndex == 0) {
            [self shareToSocial];
        } else if (buttonIndex == 1) {
            // 复制至剪切板
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            pasteboard.string = _textView.text;
            [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"CopySuccess", @"")];
        } else if (buttonIndex == 2) {
            [self lockTextAction];
        }
    } else if (actionSheet.tag == kPickPhotoTag) {
        if (buttonIndex == 0) {
            // 拍照选取
            [self photoFromCamera];
        } else if (buttonIndex == 1) {
            // 从相册选取照片
            [self photoFromAlbum];
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
    alter.tag = kLockTag;
    [alter show];
}

/**
 *  分享
 */
- (void)shareToSocial {

    [UMSocialSnsService presentSnsIconSheetView:self
                                         appKey:@"507fcab25270157b37000010"
                                      shareText:self.note.content
                                     shareImage:nil
                                shareToSnsNames:[NSArray arrayWithObjects:UMShareToSina, UMShareToWechatSession, UMShareToQQ, UMShareToEmail, UMShareToSms, nil]
                                       delegate:nil];
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

        notification.fireDate = fireDate; //触发通知的时间
        notification.repeatInterval = 0;  //循环次数，

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

#pragma mark -
#pragma mark === PickPhoto ===
#pragma mark -

// 从相机获取图片
- (void)photoFromCamera {

    // returns YES if source is available (i.e. camera present)
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypeCamera; //设置类型为相机
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];               //初始化
        picker.delegate = self;                                                                 //设置代理
        picker.allowsEditing = YES;                                                             //设置照片可编辑
        picker.sourceType = sourceType;
        //picker.showsCameraControls = NO;//默认为YES
        //创建叠加层
        UIView *overLayView = [[UIView alloc] initWithFrame:CGRectMake(0, 120, 320, 254)];
        //取景器的背景图片，该图片中间挖掉了一块变成透明，用来显示摄像头获取的图片；
        UIImage *overLayImag = [UIImage imageNamed:@"zhaoxiangdingwei"];
        UIImageView *bgImageView = [[UIImageView alloc] initWithImage:overLayImag];
        [overLayView addSubview:bgImageView];
        picker.cameraOverlayView = overLayView;
        picker.cameraDevice = UIImagePickerControllerCameraDeviceFront; //选择前置摄像头或后置摄像头
        [self presentViewController:picker animated:YES completion:^{
        }];
    } else {
        NSLog(@"该设备无相机");
    }
}
// 从相册获取图片
- (void)photoFromAlbum {

    UIImagePickerController *pickerImage = [[UIImagePickerController alloc] init];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        pickerImage.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        //pickerImage.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
        pickerImage.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:pickerImage.sourceType];
    }
    pickerImage.delegate = self;
    pickerImage.allowsEditing = NO;
    [self presentViewController:pickerImage animated:YES completion:^{
    }];
}

// 从相册选择图片后操作
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {

    [picker dismissViewControllerAnimated:YES completion:^{
    }];
    //保存原始图片
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    [self saveImage:image withName:@"currentImage.png"];
}

// 保存图片
- (void)saveImage:(UIImage *)currentImage withName:(NSString *)imageName {
    NSData *imageData = UIImageJPEGRepresentation(currentImage, 0.5);
    // 获取沙盒目录
    NSString *fullPath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:imageName];
    // 将图片写入文件
    [imageData writeToFile:fullPath atomically:NO];
    // 将选择的图片显示出来
    UIImage *image = [UIImage imageWithContentsOfFile:fullPath];
    image = [UIImage imageWithCGImage:image.CGImage scale:10 orientation:UIImageOrientationUp];

    QTClickImageView *clickImage = [[QTClickImageView alloc] initWithImage:image];
    clickImage.delegate = self;
    NSMutableAttributedString *attachText = [NSMutableAttributedString yy_attachmentStringWithContent:clickImage contentMode:UIViewContentModeCenter attachmentSize:clickImage.size alignToFont:self.attrString.yy_font alignment:YYTextVerticalAlignmentCenter];

    NSMutableAttributedString *newAttrString = [[NSMutableAttributedString alloc] initWithString:self.textView.text];
    [newAttrString appendAttributedString:attachText];
    [newAttrString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n" attributes:nil]];
    // 插入图片后，重新设置样式
    newAttrString.yy_font = [UIFont fontWithName:@"Times New Roman" size:18];
    newAttrString.yy_lineSpacing = 4;
    newAttrString.yy_firstLineHeadIndent = 20;

    self.textView.attributedText = newAttrString;

    //将图片保存到disk
    //    UIImageWriteToSavedPhotosAlbum(currentImage, nil, nil, nil);
}

// 取消操作时调用
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:^{
    }];
}

#pragma mark - QTClickImageViewDelegate

- (void)didSelectItemWith {
    NSLog(@"------------(UIImageView *)view");
    [self hideKeyboard];
}

@end
