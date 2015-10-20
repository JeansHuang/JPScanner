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
关键是设置这个属性，但是很多坑，参考不少资料试了很多方法，都不对，准确地说，限制的区域不是100%精准。

包括下面参考的博文资料中，有位大神是阿里的，我测试了下支付宝，也不是100%精准限制了区域。不过其实也不大影响实际使用。

> **参考（感谢）博文资料：**  
[IOS7使用原生API进行二维码和条形码的扫描][3]  
[iOS 原生二维码扫描（可限制扫描区域）][4]  
[IOS二维码扫描,你需要注意的两件事][5]  

Google一番，发现[Radar Samples][6]其中报告了
> **iOS 7 Bugs**
> **ScanAreaBug:** [AVCaptureMetadataOutput ignores Full-Screen rectOfInterest][7] (rdar://14427767)

其实是有bug的，因此就不太纠结100%精准的问题。  
最后给出最终限制区域的关键代码：  
***y轴上的20是我用4寸屏的5c得到的偏差，可以根据实际情况修正下，或许不用+20也行。此设置已经基本只会扫码框内的二维码了***
```
//调整扫描区域
        AVCaptureMetadataOutput *output = self.session.outputs.firstObject;
        //
        CGRect rect = CGRectMake((self.scanerView.scanAreaRect.origin.y + 20) / HEIGHT(self.scanerView),
                                 self.scanerView.scanAreaRect.origin.x / WIDTH(self.scanerView),
                                 self.scanerView.scanAreaRect.size.height / HEIGHT(self.scanerView),
                                 self.scanerView.scanAreaRect.size.width / WIDTH(self.scanerView));
        output.rectOfInterest = rect;
```


#### 3.最后 ####
如果大家有100%精准的解决方法或更方便的计算方式，请评论回复指教下。谢谢。
```
- (CGRect)metadataOutputRectOfInterestForRect:(CGRect)rectInLayerCoordinates
- (CGRect)rectForMetadataOutputRectOfInterest:(CGRect)rectInMetadataOutputCoordinates
```
据说上面的方法可以直接转换坐标，可是我的结果总是0，无奈只能自己计算了。

[博文地址][8]



  [2]: https://raw.githubusercontent.com/JeansHuang/SuperScanner/master/%E6%88%AA%E5%9B%BE.jpg
  [3]: http://my.oschina.net/u/2340880/blog/405847
  [4]: http://blog.csdn.net/lc_obj/article/details/41549469?utm_source=tuicool&utm_medium=referral
  [5]: http://blog.cnbluebox.com/blog/2014/08/26/ioser-wei-ma-sao-miao/
  [6]: https://github.com/Cocoanetics/RadarSamples
  [7]: https://www.cocoanetics.com/2013/09/welcome-to-ios-7-issues/
  [8]: http://my.oschina.net/jeans/blog/519365#OSC_h4_4
  