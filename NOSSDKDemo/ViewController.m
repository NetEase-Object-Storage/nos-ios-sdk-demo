//
//  ViewController.m
//  NOSSDKDemo
//
//  Created by 来 东敏 on 15/1/20.
//  Copyright (c) 2015年 来 东敏. All rights reserved.
//

#import "ViewController.h"
#import "NOSTokenUtils.h"
#import "include/NOSSDK.h"
#import "MD5Utils.h"

@interface ViewController ()<UIImagePickerControllerDelegate,UINavigationControllerDelegate>
//@property (weak, nonatomic) IBOutlet UITextField *connectTimeoutText;
@property (weak, nonatomic) IBOutlet UITextField *soTimeoutText;
@property (weak, nonatomic) IBOutlet UITextField *chunkSizeText;
@property (weak, nonatomic) IBOutlet UITextField *retryCountText;
@property (weak, nonatomic) IBOutlet UITextField *monitorInterval;
@property (weak, nonatomic) IBOutlet UITextField *objectName;
@property (weak, nonatomic) IBOutlet UITextField *bucketName;

@end

BOOL isHttps = NO;
BOOL cancelUpload = NO;
NOSUploadManager *upManager = nil;

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSError *error = nil;
    NSString *dir = [NSTemporaryDirectory() stringByAppendingString:@"nos-ios-sdk-test"];
    NSLog(@"%@", dir);
    NOSFileRecorder *file = [NOSFileRecorder fileRecorderWithFolder:dir error:&error];
    
    NOSConfig *conf = [[NOSConfig alloc] initWithLbsHost: @"https://lbs-eastchina1.126.net/lbs"
                                           withSoTimeout: [_soTimeoutText.text intValue]
                                   //withConnectionTimeout: [_connectTimeoutText.text intValue]
                                     withRefreshInterval: [_monitorInterval.text intValue]
                                           withChunkSize: [_chunkSizeText.text intValue] * 1024
                                     withMoniterInterval: [_monitorInterval.text intValue]
                                          withRetryCount: [_retryCountText.text intValue]];

    [NOSUploadManager setGlobalConf:conf];
    
    if (error) {
        NSLog(@"%@", error);
    }
    upManager = [NOSUploadManager sharedInstanceWithRecorder: file
                                        recorderKeyGenerator: nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)timerFireMethod:(NSTimer*)theTimer
{
    UIAlertView *promptAlert = (UIAlertView*)[theTimer userInfo];
    [promptAlert dismissWithClickedButtonIndex:0 animated:NO];
    promptAlert =NULL;
}

- (void)showAlert:(NSString *) _message{
    UIAlertView *promptAlert = [[UIAlertView alloc] initWithTitle:@"提示:" message:_message delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    
    [NSTimer scheduledTimerWithTimeInterval:0.5f
                                     target:self
                                   selector:@selector(timerFireMethod:)
                                   userInfo:promptAlert
                                    repeats:YES];
    [promptAlert show];
}

- (IBAction)DemoHttpUpload:(id)sender {
    
    UIImagePickerController *ipc = [[UIImagePickerController alloc] init];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]){
        ipc.sourceType =  UIImagePickerControllerSourceTypePhotoLibrary;
        ipc.mediaTypes =[UIImagePickerController availableMediaTypesForSourceType:ipc.sourceType];
    }
    ipc.delegate = self;
    [self presentViewController:ipc
                       animated:YES
                     completion:nil];
    
}

- (IBAction)DemoHttpsUpload:(id)sender {
    isHttps = YES;
    UIImagePickerController *ipc = [[UIImagePickerController alloc] init];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]){
        ipc.sourceType =  UIImagePickerControllerSourceTypePhotoLibrary;
        ipc.mediaTypes =[UIImagePickerController availableMediaTypesForSourceType:ipc.sourceType];
    }
    ipc.delegate = self;
    [self presentViewController:ipc
                       animated:YES
                     completion:nil];
}

- (IBAction)DemoCancel:(id)sender {
    cancelUpload = YES;
}

- (void)doUpload:(NSString *) filepath {
    
    cancelUpload = NO;
    NSString *bucket = _bucketName.text;;
    NSString *object = _objectName.text;
    NSString *accessKey = @"xxxx";
    NSString *secretKey = @"xxxx";
    
    NSString *localFileName = filepath;
    NSString *token = [NOSTokenUtils genTokenWithBucket: bucket
                                                withKey: object
                                             withElipse: 1000
                                          withAccessKey: accessKey
                                          withSecretKey: secretKey];
    
    NOSUploadOption *option = [[NOSUploadOption alloc] initWithMime: @"image/jpeg"
                                                    progressHandler: ^(NSString *key, float percent) {
                                                        NSLog(@"current progress:%f", percent);
                                                    }
                                                              metas: nil
                                                 cancellationSignal: ^BOOL{
                                                     return cancelUpload;
                                                 }];
    
    if (isHttps) {
        NSLog(@"https : futh");
        [upManager putFileByHttps: localFileName bucket:bucket key:object
                            token: token
                         complete: ^(NOSResponseInfo *info, NSString *key, NSDictionary *resp) {
                             NSLog(@"上传完成~~");
                             NSLog(@"%@", info);
                             NSLog(@"%@", resp);
                         }
                           option: option];
    } else {
        [upManager putFileByHttp: localFileName bucket:bucket key:object
                           token: token
                        complete: ^(NOSResponseInfo *info, NSString *key, NSDictionary *resp) {
                            NSLog(@"上传完成~~");
                            NSLog(@"%@", info);
                            NSLog(@"%@", resp);
                        }
                          option: option];
    }
    [self showAlert:@"开始上传~~"];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    NSData *data = UIImageJPEGRepresentation(image, 1.0);
    
    NSString *dataMd5 = [Md5Utls getMD5WithData:data];
    NSString *filepath = [NSString stringWithFormat:@"%@%@",NSTemporaryDirectory(),dataMd5];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:filepath]) {
        [data writeToFile:filepath atomically:YES];
    }
    [self doUpload:filepath];
    [picker dismissViewControllerAnimated:YES
                                   completion:nil];
}

@end
