# SuperScanner
QRScanner BarCodeScanner 二维码条形码扫描  
iOS二维码条形码扫描，支持iOS7+，限制扫描区域，提高扫描速度
## iOS使用系统API进行二维码条形码扫描&限制扫描区域
---
GitHub看了不少，找了些，发现没几个满意的，于是自己整理了一下。
重新写了个demo
#### 1.创建扫描 ####
关键代码如下：  

```
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
```

----------
#### 2. 限制扫描区域 ####
![demo截图][2]  
如图所示，非指定区域内不会识别，这样能够这样能够加快识别速度。

```
AVCaptureMetadataOutput *output;
output.rectOfInterest
```
关键是设置这个属性，但是很多坑，参考不少资料试了很多方法，原来是要在`AVCaptureInputPortFormatDescriptionDidChangeNotification`通知内设置才行。


```
__weak typeof(self) weakSelf = self;
[[NSNotificationCenter defaultCenter]addObserverForName:AVCaptureInputPortFormatDescriptionDidChangeNotification
                                                 object:nil
                                                  queue:[NSOperationQueue mainQueue]
                                             usingBlock:^(NSNotification * _Nonnull note) {
                                                 if (weakSelf){
                                                     //调整扫描区域
                                                     AVCaptureMetadataOutput *output = weakSelf.session.outputs.firstObject;
                                                     output.rectOfInterest = [weakSelf.previewLayer metadataOutputRectOfInterestForRect:weakSelf.scanerView.scanAreaRect];
                                                 }
                                             }];
```

> **参考（感谢）博文资料：**  
[IOS7使用原生API进行二维码和条形码的扫描][3]  
[iOS 原生二维码扫描（可限制扫描区域）][4]  
[IOS二维码扫描,你需要注意的两件事][5]  
[iOS 原生扫 QR 码的那些事][9]  

[博文地址][8]  



  [2]: https://raw.githubusercontent.com/JeansHuang/SuperScanner/master/%E6%88%AA%E5%9B%BE.jpg
  [3]: http://my.oschina.net/u/2340880/blog/405847
  [4]: http://blog.csdn.net/lc_obj/article/details/41549469?utm_source=tuicool&utm_medium=referral
  [5]: http://blog.cnbluebox.com/blog/2014/08/26/ioser-wei-ma-sao-miao/
  [6]: https://github.com/Cocoanetics/RadarSamples
  [7]: https://www.cocoanetics.com/2013/09/welcome-to-ios-7-issues/
  [8]: http://my.oschina.net/jeans/blog/519365#OSC_h4_4
  [9]: http://c0ming.me/qr-code-scan/