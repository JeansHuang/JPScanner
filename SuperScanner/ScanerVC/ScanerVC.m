//
//  ScanerVC.m
//  SuperScanner
//
//  Created by Jeans Huang on 10/19/15.
//  Copyright © 2015 gzhu. All rights reserved.
//

#import "ScanerVC.h"
#import "ScanerView.h"

@import AVFoundation;

@interface ScanerVC ()<AVCaptureMetadataOutputObjectsDelegate,UIAlertViewDelegate>

//! 加载中视图
@property (weak, nonatomic) IBOutlet UIView     *loadingView;

//! 扫码区域动画视图
@property (weak, nonatomic) IBOutlet ScanerView *scanerView;

//AVFoundation
//! AV协调器
@property (strong,nonatomic) AVCaptureSession           *session;
//! 取景视图
@property (strong,nonatomic) AVCaptureVideoPreviewLayer *previewLayer;

@end

@implementation ScanerVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.scanerView.alpha = 0;
    //设置扫描区域边长
    self.scanerView.scanAreaEdgeLength = [[UIScreen mainScreen] bounds].size.width - 2 * 50;
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];

    if (!self.session){
        
        //添加镜头盖开启动画
        CATransition *animation = [CATransition animation];
        animation.duration = 0.5;
        animation.type = @"cameraIrisHollowOpen";
        animation.timingFunction = UIViewAnimationOptionCurveEaseInOut;
        animation.delegate = self;
        [self.view.layer addAnimation:animation forKey:@"animation"];
        
        //初始化扫码
        [self setupAVFoundation];
        
        //调整摄像头取景区域
        self.previewLayer.frame = self.view.bounds;
        
        //调整扫描区域
        AVCaptureMetadataOutput *output = self.session.outputs.firstObject;
        //根据实际偏差调整y轴
        CGRect rect = CGRectMake((self.scanerView.scanAreaRect.origin.y + 20) / HEIGHT(self.scanerView),
                                 self.scanerView.scanAreaRect.origin.x / WIDTH(self.scanerView),
                                 self.scanerView.scanAreaRect.size.height / HEIGHT(self.scanerView),
                                 self.scanerView.scanAreaRect.size.width / WIDTH(self.scanerView));
        output.rectOfInterest = rect;
    }
}

//! 动画结束回调
- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag{
    self.loadingView.hidden = YES;
    [UIView animateWithDuration:0.25
                     animations:^{
                         self.scanerView.alpha = 1;
                     }];
}

//! 初始化扫码
- (void)setupAVFoundation{
    //创建会话
    self.session = [[AVCaptureSession alloc] init];
    
    //获取摄像头设备
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error = nil;

    //创建输入流
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];

    if(input) {
        [self.session addInput:input];
    } else {
        //出错处理
        NSLog(@"%@", error);
        NSString *msg = [NSString stringWithFormat:@"请在手机【设置】-【隐私】-【相机】选项中，允许【%@】访问您的相机",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"]];

        UIAlertView *av = [[UIAlertView alloc]initWithTitle:@"提醒"
                                                    message:msg
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles: nil];
        [av show];
        return;
    }
    
    //创建输出流
    AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc] init];
    [self.session addOutput:output];
    
    //设置扫码类型
    output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode,  //条形码
                                   AVMetadataObjectTypeEAN13Code,
                                   AVMetadataObjectTypeEAN8Code,
                                   AVMetadataObjectTypeCode128Code];
    //设置代理，在主线程刷新
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    //创建摄像头取景区域
    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer insertSublayer:self.previewLayer atIndex:0];
    
    if ([self.previewLayer connection].isVideoOrientationSupported)
        [self.previewLayer connection].videoOrientation = AVCaptureVideoOrientationPortrait;
        
    //开始扫码
    [self.session startRunning];
}

#pragma mark - AVCaptureMetadataOutputObjects Delegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    for (AVMetadataMachineReadableCodeObject *metadata in metadataObjects) {
        if ([metadata.type isEqualToString:AVMetadataObjectTypeQRCode]) {
            [self.session stopRunning];
            
            UIAlertView *av = [[UIAlertView alloc]initWithTitle:@"二维码"
                                                        message:metadata.stringValue
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles: nil];
            [av show];

            break;
        }else{
            [self.session stopRunning];
            
            UIAlertView *av = [[UIAlertView alloc]initWithTitle:@"条形码"
                                                        message:metadata.stringValue
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles: nil];
            [av show];
            
            break;
        }
    }
}

#pragma mark - UIAlertView Delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
