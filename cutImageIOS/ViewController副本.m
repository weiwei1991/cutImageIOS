//
//  ViewController.m
//  cutImageIOS
//
//  Created by vk on 15/8/21.
//  Copyright (c) 2015年 quxiu8. All rights reserved.
//  方形编辑区域

#import "ViewController.h"
#import <Foundation/Foundation.h>
#import "UIImage+IF.h"
#define LINESTEP 5
#define DEFLINEWIDTH 10

@interface ViewController ()

@property (nonatomic, strong) UIImage* photoImg;
@property (nonatomic, strong) UIImageView *appImageView;
@property (nonatomic, strong) UIImageView *showImgView;
@property (nonatomic, strong) UIButton *openPhotoAlbum;
@property (nonatomic, strong) UIButton *addCalculatePoint;
@property (nonatomic, strong) UIButton *addMaskPoint;
@property (nonatomic, strong) UIButton *deleteMaskPoint;
@property (nonatomic, strong) UIButton *moveImg;
@property (nonatomic, strong) UIButton *undoButton; //前进
@property (nonatomic, strong) UIButton *redoButton; //返回
@property (nonatomic, strong) UIButton *addLineWidth;
@property (nonatomic, strong) UIButton *subtractLineWidth;


@property (nonatomic, strong) NSMutableArray *pointArray;  //同时发送的只能有一组array, 删除，添加，选取都是这一个array
@property (nonatomic, strong) UIButton *sysTestButton;
@property (nonatomic, strong) UIButton *resetDrawButton;
@property (nonatomic) CGRect orgRect;
@property (nonatomic, strong) Bridge2OpenCV *b2opcv;
@property (nonatomic) CGSize imgWindowSize;
@property (nonatomic) CGAffineTransform orgTrf;
@property (nonatomic) BOOL isMove; //移动时最好禁用其他操作
@property (nonatomic) BOOL isDraw; //YES是直接画mark NO是添加生长点
@property (nonatomic) BOOL isDelete; //YES则调用删除点，NO是再判断上面的Draw

@property (nonatomic) int setLineWidth;

/**
 *  画图测试
 */



@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    float smallButtonWidth = 50;
    float bigButtonWidth = 100;
    self.setLineWidth = DEFLINEWIDTH;              //线宽默认是10
    CGRect mainScreen = [[UIScreen mainScreen] applicationFrame];
    NSLog(@" mainScreen.size.height = %f  mainScreen.size.width = %f ",mainScreen.size.height, mainScreen.size.width);
    NSLog(@" mainScreen.origin.x    = %f  mainScreen.origin.y   = %f  ",mainScreen.origin.x,mainScreen.origin.y);
    CGPoint screenCenter = CGPointMake(mainScreen.size.width/2, mainScreen.size.height/2 + 20);
    self.pointArray = [[NSMutableArray alloc]init];
    self.b2opcv = [[Bridge2OpenCV alloc]init];
    self.b2opcv.delegate = self;
    
    //上半部分遮挡view
    
    //
    self.showImgView= [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, mainScreen.size.width, mainScreen.size.width)];
    self.showImgView.center = CGPointMake( screenCenter.x, screenCenter.y - ((mainScreen.size.height - mainScreen.size.width)/4) );
    self.showImgView.backgroundColor = [UIColor whiteColor];
    //
    self.appImageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, mainScreen.size.width, mainScreen.size.width)];
    self.appImageView.center = CGPointMake( screenCenter.x, screenCenter.y - ((mainScreen.size.height - mainScreen.size.width)/4) );
    self.orgRect = self.appImageView.frame;
    self.appImageView.backgroundColor = [UIColor greenColor];
    
    UIImage *imageInit =  [UIImage imageWithColor:self.appImageView.backgroundColor andRect:CGRectMake(0, 0, self.appImageView.frame.size.width, self.appImageView.frame.size.width)]; // [self.appImageView image];
    self.imgWindowSize = CGSizeMake(self.appImageView.frame.size.width, self.appImageView.frame.size.height);
    self.orgTrf = self.appImageView.transform;

    [self.b2opcv setCalculateImage:imageInit andWindowSize:self.imgWindowSize];
    
    [self creatPan];
    //生成一个遮挡平面，这样可以得到小图的剪切
    float tmpHeight =   self.showImgView.frame.origin.y;
    UIImageView *upKeepOutView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, mainScreen.size.width, tmpHeight)];
    upKeepOutView.backgroundColor = [UIColor grayColor];
    //[upKeepOutView.layer setCornerRadius:5];
    UIImageView *bottomKeepOutView = [[UIImageView alloc]initWithFrame:CGRectMake(0, tmpHeight + self.showImgView.frame.size.height, mainScreen.size.width, mainScreen.size.height - tmpHeight - self.showImgView.frame.size.height + 20)];
    bottomKeepOutView.backgroundColor = [UIColor grayColor];
    //[bottomKeepOutView.layer setCornerRadius:5];
    
    //打开相册按键
    self.openPhotoAlbum = [UIButton buttonWithType:UIButtonTypeCustom];
    self.openPhotoAlbum.frame = CGRectMake(mainScreen.size.width - 100, mainScreen.size.height - 30, 100, 50);
    self.openPhotoAlbum.backgroundColor = [UIColor whiteColor];
    [self.openPhotoAlbum.layer setCornerRadius:5];
    [self.openPhotoAlbum setTitle:@"打开相册" forState:UIControlStateNormal];
    [self.openPhotoAlbum setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.openPhotoAlbum setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [self.openPhotoAlbum addTarget:self action:@selector(takePictureClick:) forControlEvents:UIControlEventTouchUpInside];
    //测试用按键，图片位置复位
    self.sysTestButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.sysTestButton.frame =CGRectMake(0, mainScreen.size.height - 30, 100, 50);
    self.sysTestButton.backgroundColor = [UIColor whiteColor];
    [self.sysTestButton.layer setCornerRadius:5];
    [self.sysTestButton setTitle:@"重置位置" forState:UIControlStateNormal];
    [self.sysTestButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.sysTestButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [self.sysTestButton addTarget:self action:@selector(resetPosion:) forControlEvents:UIControlEventTouchUpInside];
    /**
     *  重画按键，点击后消除所有当前图像所有Mask
     */
    self.resetDrawButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.resetDrawButton.frame = CGRectMake(110, mainScreen.size.height - 30, 100, 50);
    self.resetDrawButton.backgroundColor = [UIColor whiteColor];
    [self.resetDrawButton.layer setCornerRadius:5];
    [self.resetDrawButton setTitle:@"重置绘制" forState:UIControlStateNormal];
    [self.resetDrawButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.resetDrawButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [self.resetDrawButton addTarget:self action:@selector(resetDraw:) forControlEvents:UIControlEventTouchUpInside];
    
    //添加计算点按键
    self.addCalculatePoint = [UIButton buttonWithType:UIButtonTypeCustom];
    self.addCalculatePoint.frame = CGRectMake(0, (screenCenter.y - ((mainScreen.size.height - mainScreen.size.width)/4) - (mainScreen.size.width/2) ) + mainScreen.size.width , smallButtonWidth, 50);
    self.addCalculatePoint.center = CGPointMake(mainScreen.size.width/5,self.addCalculatePoint.center.y);
    self.addCalculatePoint.backgroundColor = [UIColor yellowColor];
    [self.addCalculatePoint.layer setCornerRadius:5];
    [self.addCalculatePoint setTitle:@"选取" forState:UIControlStateNormal];
    [self.addCalculatePoint setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.addCalculatePoint setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [self.addCalculatePoint addTarget:self action:@selector(cutImageCut:) forControlEvents:UIControlEventTouchUpInside];
    //添加移动图片按键
    self.moveImg= [UIButton buttonWithType:UIButtonTypeCustom];
    self.moveImg.frame = CGRectMake(mainScreen.size.width - smallButtonWidth, (screenCenter.y - ((mainScreen.size.height - mainScreen.size.width)/4) - (mainScreen.size.width/2) ) + mainScreen.size.width, smallButtonWidth , 50);
    self.moveImg.center = CGPointMake(mainScreen.size.width/5*4,self.moveImg.center.y);
    self.moveImg.backgroundColor = [UIColor whiteColor];
    [self.moveImg.layer setCornerRadius:5];
    [self.moveImg setTitle:@"移动" forState:UIControlStateNormal];
    [self.moveImg setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.moveImg setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [self.moveImg addTarget:self action:@selector(enableMoveImg:) forControlEvents:UIControlEventTouchUpInside];
    //添加单独添加Mask按键
    self.addMaskPoint = [UIButton buttonWithType:UIButtonTypeCustom];
    self.addMaskPoint.frame = CGRectMake(0, (screenCenter.y - ((mainScreen.size.height - mainScreen.size.width)/4) - (mainScreen.size.width/2) ) + mainScreen.size.width, smallButtonWidth, 50);
    self.addMaskPoint.center = CGPointMake(mainScreen.size.width/5*2, self.addMaskPoint.center.y);
    self.addMaskPoint.backgroundColor = [UIColor whiteColor];
    [self.addMaskPoint.layer setCornerRadius:5];
    [self.addMaskPoint setTitle:@"添加" forState:UIControlStateNormal];
    [self.addMaskPoint setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.addMaskPoint setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [self.addMaskPoint addTarget:self action:@selector(addMaskPointFoo:) forControlEvents:UIControlEventTouchUpInside];
    //添加删除Mark的按键
    self.deleteMaskPoint = [UIButton buttonWithType:UIButtonTypeCustom];
    self.deleteMaskPoint.frame = CGRectMake(0, (screenCenter.y - ((mainScreen.size.height - mainScreen.size.width)/4) - (mainScreen.size.width/2) ) + mainScreen.size.width, smallButtonWidth, 50);
    self.deleteMaskPoint.center = CGPointMake(mainScreen.size.width/5*3, self.deleteMaskPoint.center.y);
    self.deleteMaskPoint.backgroundColor = [UIColor whiteColor];
    [self.deleteMaskPoint.layer setCornerRadius:5];
    [self.deleteMaskPoint setTitle:@"删除" forState:UIControlStateNormal];
    [self.deleteMaskPoint setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.deleteMaskPoint setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [self.deleteMaskPoint addTarget:self action:@selector(deleteMaskPointFoo:) forControlEvents:UIControlEventTouchUpInside];
    /**
     *  增加回退按钮
     */
    self.redoButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.redoButton.frame = CGRectMake(0, (screenCenter.y - ((mainScreen.size.height - mainScreen.size.width)/4) - (mainScreen.size.width/2) ) + mainScreen.size.width , smallButtonWidth, 50);
    self.redoButton.center = CGPointMake(mainScreen.size.width/5,self.addCalculatePoint.center.y + 60);
    self.redoButton.backgroundColor = [UIColor whiteColor];
    [self.redoButton.layer setCornerRadius:5];
    [self.redoButton  setTitle:@"返回" forState:UIControlStateNormal];
    [self.redoButton  setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.redoButton  setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [self.redoButton  addTarget:self action:@selector(redoButtonFoo) forControlEvents:UIControlEventTouchUpInside];
    /**
     *  增加前进按钮
     */
    self.undoButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.undoButton.frame = CGRectMake(mainScreen.size.width - smallButtonWidth, (screenCenter.y - ((mainScreen.size.height - mainScreen.size.width)/4) - (mainScreen.size.width/2) ) + mainScreen.size.width, smallButtonWidth , 50);
    self.undoButton.center = CGPointMake(mainScreen.size.width/5*4,self.moveImg.center.y + 60);
    self.undoButton.backgroundColor = [UIColor whiteColor];
    [self.undoButton.layer setCornerRadius:5];
    [self.undoButton setTitle:@"前进" forState:UIControlStateNormal];
    [self.undoButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.undoButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [self.undoButton addTarget:self action:@selector(undoButtonFoo) forControlEvents:UIControlEventTouchUpInside];
    /**
     *  增加线宽按钮
     */
    self.addLineWidth = [UIButton buttonWithType:UIButtonTypeCustom];
    self.addLineWidth.frame = CGRectMake(0, (screenCenter.y - ((mainScreen.size.height - mainScreen.size.width)/4) - (mainScreen.size.width/2) ) + mainScreen.size.width, smallButtonWidth, 50);
    self.addLineWidth.center = CGPointMake(mainScreen.size.width/5*2, self.addMaskPoint.center.y + 60);
    self.addLineWidth.backgroundColor = [UIColor whiteColor];
    [self.addLineWidth.layer setCornerRadius:5];
    [self.addLineWidth setTitle:@"+" forState:UIControlStateNormal];
    [self.addLineWidth setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.addLineWidth setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [self.addLineWidth addTarget:self action:@selector(addLineWidthFoo) forControlEvents:UIControlEventTouchUpInside];
    /**
     *  减少线宽
     */
    self.subtractLineWidth = [UIButton buttonWithType:UIButtonTypeCustom];
    self.subtractLineWidth .frame = CGRectMake(0, (screenCenter.y - ((mainScreen.size.height - mainScreen.size.width)/4) - (mainScreen.size.width/2) ) + mainScreen.size.width, smallButtonWidth, 50);
    self.subtractLineWidth.center = CGPointMake(mainScreen.size.width/5*3, self.deleteMaskPoint.center.y + 60);
    self.subtractLineWidth.backgroundColor = [UIColor whiteColor];
    [self.subtractLineWidth.layer setCornerRadius:5];
    [self.subtractLineWidth setTitle:@"-" forState:UIControlStateNormal];
    [self.subtractLineWidth setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.subtractLineWidth setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [self.subtractLineWidth addTarget:self action:@selector(subtractLineWidthFoo) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.showImgView];
    [self.view addSubview:self.appImageView];
    [self.view addSubview:upKeepOutView];
    [self.view addSubview:bottomKeepOutView];
    [self.view addSubview:self.openPhotoAlbum];
    [self.view addSubview:self.sysTestButton];
    [self.view addSubview:self.addCalculatePoint];
    [self.view addSubview:self.addMaskPoint];
    [self.view addSubview:self.deleteMaskPoint];
    [self.view addSubview:self.moveImg];
    [self.view addSubview:self.resetDrawButton];
    [self.view addSubview:self.redoButton];
    [self.view addSubview:self.undoButton];
    [self.view addSubview:self.addLineWidth];
    [self.view addSubview:self.subtractLineWidth];
    self.view.backgroundColor = [UIColor grayColor];
    
    self.isMove = NO;
    self.isDraw = NO;       //默认是添加
    self.isDelete   = NO;
    // Do any additional setup after loading the view, typically from a nib.
}

-(void) resultImageReady:(UIImage *)sendImage
{
    dispatch_async(dispatch_get_global_queue(0,0), ^{
        //耗时处理
        dispatch_async( dispatch_get_main_queue(), ^{
            //同步显示
            self.appImageView.image = sendImage;
        });
    });
}

-(void) resetPosion:(id)sender
{
    self.appImageView.transform =CGAffineTransformScale(self.orgTrf, 1, 1);
    self.appImageView.frame = self.orgRect;
}
/**
 *  重置所有绘制
 *
 *  @param sender <#sender description#>
 */
-(void) resetDraw:(id)sender
{
    self.appImageView.transform =CGAffineTransformScale(self.orgTrf, 1, 1);
    self.appImageView.frame = self.orgRect;
    self.setLineWidth = DEFLINEWIDTH;
    [self.b2opcv resetAllMask];
}
/**
 *  回退操作
 */
-(void) redoButtonFoo
{
    [self.b2opcv redoPoint];
}
/**
 *  前进操作
 */
-(void) undoButtonFoo
{
    [self.b2opcv undoPoint];
}
/**
 *  加线宽
 */
-(void) addLineWidthFoo
{
    self.setLineWidth = self.setLineWidth + LINESTEP;
}
/**
 *  减线宽
 */
-(void) subtractLineWidthFoo
{
    if( self.setLineWidth - LINESTEP > 0  ){
        self.setLineWidth = self.setLineWidth - LINESTEP;
    }
}

-(void) cutImageCut:(id)sender
{
    [self.appImageView setUserInteractionEnabled:NO];
    self.addCalculatePoint.backgroundColor  = [UIColor yellowColor];
    self.addMaskPoint.backgroundColor  = [UIColor whiteColor];
    self.deleteMaskPoint.backgroundColor  = [UIColor whiteColor];
    self.moveImg.backgroundColor  = [UIColor whiteColor];
    self.isDraw = NO;
    self.isMove = NO;
    self.isDelete= NO;
}

-(void) addMaskPointFoo:(id)sender          //直接添加种子点
{
    [self.appImageView setUserInteractionEnabled:NO];
    self.addCalculatePoint.backgroundColor  = [UIColor whiteColor];
    self.addMaskPoint.backgroundColor       = [UIColor yellowColor];
    self.deleteMaskPoint.backgroundColor    = [UIColor whiteColor];
    self.moveImg.backgroundColor            = [UIColor whiteColor];
    self.isDraw = YES;
    self.isMove = NO;
    self.isDelete= NO;
}

-(void) deleteMaskPointFoo:(id)sender
{
    [self.appImageView setUserInteractionEnabled:NO];
    self.addCalculatePoint.backgroundColor  = [UIColor whiteColor];
    self.addMaskPoint.backgroundColor       = [UIColor whiteColor];
    self.deleteMaskPoint.backgroundColor    = [UIColor yellowColor];
    self.moveImg.backgroundColor            = [UIColor whiteColor];
    self.isDelete = YES;
    self.isMove = NO;
}

-(void) enableMoveImg:(id)sender
{
    [self.appImageView setUserInteractionEnabled:YES];
    self.addCalculatePoint.backgroundColor  = [UIColor whiteColor];
    self.addMaskPoint.backgroundColor       = [UIColor whiteColor];
    self.deleteMaskPoint.backgroundColor    = [UIColor whiteColor];
    self.moveImg.backgroundColor            = [UIColor yellowColor];
    self.isMove = YES;
}

-(void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSSet *allTouches = [event allTouches];    //返回与当前接收者有关的所有的触摸对象
    UITouch *touch = [allTouches anyObject];   //视图中的所有对象
    CGPoint point = [touch locationInView:self.appImageView]; //返回触摸点在视图中的当前坐标
    int x = point.x;
    int y = point.y;
   // if(x >= 0 && x<= self.orgRect.size.width)
    NSLog(@"touch moved (x, y) is (%d, %d)", x, y);
    [self addPoint2Array:point];
}

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    
    NSSet *allTouches = [event allTouches];    //返回与当前接收者有关的所有的触摸对象
    UITouch *touch = [allTouches anyObject];   //视图中的所有对象
    CGPoint point = [touch locationInView:self.appImageView]; //返回触摸点在视图中的当前坐标
    int x = point.x;
    int y = point.y;
    NSLog(@" ");
    NSLog(@"touch began (x, y) is (%d, %d)", x, y);
    [self.pointArray removeAllObjects];
    [self addPoint2Array:point];
}

-(void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSSet *allTouches = [event allTouches];    //返回与当前接收者有关的所有的触摸对象
    UITouch *touch = [allTouches anyObject];   //视图中的所有对象
    CGPoint point = [touch locationInView:self.appImageView]; //返回触摸点在视图中的当前坐标
    int x = point.x;
    int y = point.y;
    NSLog(@"touch ended (x, y) is (%d, %d)", x, y);
    [self addPoint2Array:point];
    if(self.isMove == NO){
        if(self.isDelete == NO){
            if(self.isDraw == NO){
                [self.b2opcv setCreatPoint:self.pointArray andLineWidth:self.setLineWidth];
            }
            else{
                [self.b2opcv setDrawPoint:self.pointArray andLineWidth:self.setLineWidth];
            }
        }
        else
        {
            [self.b2opcv setDeletePoint:self.pointArray andLineWidth:self.setLineWidth];
        }
    }
    //UIImage *imgSend = self.appImageView.image;
}

-(void)takePictureClick:(id)sender
{
    /*注：使用，需要实现以下协议：UIImagePickerControllerDelegate,
     UINavigationControllerDelegate
     */
    UIImagePickerController *picker = [[UIImagePickerController alloc]init];
    //设置图片源(相簿)
    picker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    //设置代理
    picker.delegate = self;
    //设置可以编辑
    picker.allowsEditing = YES;
    //打开拾取器界面
    [self presentViewController:picker animated:YES completion:nil];
}

//完成选择图片
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo
{
    //加载图片
    self.appImageView.image = image;
    [self.b2opcv setCalculateImage:image andWindowSize:self.imgWindowSize];
    //重置绘制线宽
    self.setLineWidth = DEFLINEWIDTH;
    //每次打开时，将appImageView归到初始位置
    self.appImageView.frame = self.orgRect;
//    [self creatPan];
    //选择框消失
    [picker dismissViewControllerAnimated:YES completion:nil];
}
//取消选择图片
-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

-(void) creatPan
{
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc]
                                                    initWithTarget:self
                                                    action:@selector(handlePan:)];
    panGestureRecognizer.delegate = self;
    [self.appImageView  addGestureRecognizer:panGestureRecognizer];
    
    UIPinchGestureRecognizer *pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc]
                                                        initWithTarget:self
                                                        action:@selector(handlePinch:)];
    pinchGestureRecognizer.delegate = self;
    [self.appImageView  addGestureRecognizer:pinchGestureRecognizer];
    [self.appImageView setUserInteractionEnabled:NO];
    //[self.view setBackgroundColor:[UIColor whiteColor]];
    //[self.view addSubview:snakeImageView];
}

- (void) handlePan:(UIPanGestureRecognizer*) recognizer
{
    CGPoint translation = [recognizer translationInView:self.view];
    recognizer.view.center = CGPointMake(recognizer.view.center.x + translation.x,
                                         recognizer.view.center.y + translation.y);
    [recognizer setTranslation:CGPointZero inView:self.view];
    
//    NSLog(@"x = %f",self.appImageView.frame.origin.x);
//    NSLog(@"y = %f",self.appImageView.frame.origin.y);
    
}
- (void) handlePinch:(UIPinchGestureRecognizer*) recognizer
{
    recognizer.view.transform = CGAffineTransformScale(recognizer.view.transform, recognizer.scale, recognizer.scale);
    NSLog(@"recognizer.scale = %f",recognizer.scale);
    recognizer.scale = 1; //不重置为1则变化会太快
   
    if(self.appImageView.frame.size.width < 320.0)
    {
        CGPoint tmpp = self.appImageView.frame.origin;
        self.appImageView.frame = CGRectMake(tmpp.x, tmpp.y, 320, 320);
    }
    
    NSLog(@"scale Width = %f",self.appImageView.frame.size.width);
    NSLog(@"scale Height= %f",self.appImageView.frame.size.height);
    
//    NSLog(@" width  = %f",self.appImageView.frame.size.width) ;
//    NSLog(@" height = %f",self.appImageView.frame.size.height);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) addPoint2Array:(CGPoint)aPoint
{
    if( aPoint.x >= 0 && aPoint.x < self.orgRect.size.width && aPoint.y >= 0 && aPoint.y < self.orgRect.size.height ){
    [self.pointArray addObject: [NSValue valueWithCGPoint:aPoint]];
    }
}

/**
 *  画图测试
 */



@end
