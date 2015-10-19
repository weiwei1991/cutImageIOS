//
//  ViewController.m
//  cutImageIOS
//
//  Created by vk on 15/8/21.
//  Copyright (c) 2015年 quxiu8. All rights reserved.
//  方形编辑区域

#import "CutNailViewController.h"
#import <Foundation/Foundation.h>
#import "UIImage+IF.h"
#import "RotateCutImageViewController.h"
#import "CustomPopAnimation.h"
//#import "ImageShowView.h"
#import "ImageEditView.h"
#define LINESTEP 5
#define DEFLINEWIDTH 10

@interface CutNailViewController ()

@property (nonatomic, strong) ImageEditView  *appImageView;
//@property (nonatomic, strong) UIImageView *showImgView;
@property (nonatomic, strong) UIButton *openPhotoAlbum;
@property (nonatomic, strong) UIButton *addCalculatePoint;
@property (nonatomic, strong) UIButton *addMaskPoint;
@property (nonatomic, strong) UIButton *deleteMaskPoint;
@property (nonatomic, strong) UIButton *moveImg;
@property (nonatomic, strong) UIButton *undoButton; //前进
@property (nonatomic, strong) UIButton *redoButton; //返回
@property (nonatomic, strong) UIButton *addLineWidth;
@property (nonatomic, strong) UIButton *subtractLineWidth;
@property (nonatomic, strong) UIButton *nextStep;


@property (nonatomic, strong) NSMutableArray *pointArray;  //同时发送的只能有一组array, 删除，添加，选取都是这一个array
@property (nonatomic, strong) UIButton *sysTestButton;
@property (nonatomic, strong) UIButton *resetDrawButton;
@property (nonatomic) CGRect orgRect;
//@property (nonatomic, strong) Bridge2OpenCV *b2opcv;
@property (nonatomic) CGSize imgWindowSize;
@property (nonatomic) CGAffineTransform orgTrf;
@property (nonatomic) BOOL isDraw; //YES是直接画mark NO是添加生长点
@property (nonatomic) BOOL isDelete; //YES则调用删除点，NO是再判断上面的Draw

@property (nonatomic) int setLineWidth;
@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;
@property (nonatomic, strong) UIPinchGestureRecognizer *pinchGestureRecognizer;

@property (nonatomic, strong)  RotateCutImageViewController *rotateCutImageViewController;

@property (nonatomic, strong) dispatch_queue_t getFinnalImageQueue;

@property (nonatomic, strong) UIButton *popViewCtrlButton;
@property (nonatomic, strong) CustomPopAnimation *custompopanimation;
@property (nonatomic, assign) BOOL lockNextStep;

/**
 *  画图测试
 */



@end

@implementation CutNailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.lockNextStep = YES;
    //CGRect pointRect = self.view.frame;
    //NSLog(@"pointRect = %@ ",NSStringFromCGRect(pointRect));
    CGRect mainScreen = [[UIScreen mainScreen] bounds];
    NSLog(@"mainScreen = %@ ", NSStringFromCGRect(mainScreen));
    
    CGPoint screenCenter = CGPointMake(mainScreen.size.width/2, mainScreen.size.height/2 + 20 );
    
    self.navigationController.delegate = self;
    self.navigationController.navigationBar.translucent = YES;
    self.custompopanimation = [[CustomPopAnimation alloc]init];
    self.rotateCutImageViewController = [[RotateCutImageViewController alloc]init];
    self.setLineWidth = DEFLINEWIDTH;              //线宽默认是10
    self.pointArray = [[NSMutableArray alloc]init];

    //Init All View
    UIImageView *upKeepOutView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, CGRectGetWidth(mainScreen), 70)];
    upKeepOutView.backgroundColor = [UIColor greenColor];
   
    float appImageViewW = CGRectGetWidth(mainScreen)*(19.0/20.0);
    float appImageViewH = appImageViewW*4.0/3.0;
    self.appImageView = [[ImageEditView alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(upKeepOutView.frame), appImageViewW, appImageViewH ) andEditImage:self.editImage];
    self.appImageView.center = CGPointMake(CGRectGetMidX(mainScreen), self.appImageView.center.y);
    self.orgRect = self.appImageView.frame;
    /**
     *  初始化手势
     */
    [self creatPan];
    //生成一个遮挡平面
//    UIImageView *upKeepOutView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, CGRectGetWidth(mainScreen), tmpHeight)];
    
    UIImageView *bottomKeepOutView = [[UIImageView alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(self.appImageView.frame), mainScreen.size.width, mainScreen.size.height - (CGRectGetHeight(upKeepOutView.frame) + CGRectGetHeight(self.appImageView.frame) ))];
    bottomKeepOutView.backgroundColor = [UIColor redColor];
  
    //开始添加按键
    /**
     *  增加回退按钮
     */
    float smallButtonWidth = 50;
    self.redoButton = [UIButton buttonWithType:UIButtonTypeCustom];
    NSLog(@"midx = %f",CGRectGetMidX(mainScreen));
    self.redoButton.frame = CGRectMake(CGRectGetMidX(mainScreen) - 60, CGRectGetMaxY(upKeepOutView.frame) - 50 , smallButtonWidth, 50);
    //self.redoButton.center = CGPointMake(mainScreen.size.width/5,self.addCalculatePoint.center.y + 60);
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
    self.undoButton.frame = CGRectMake(CGRectGetMidX(mainScreen) + 10  , CGRectGetMaxY(upKeepOutView.frame) - 50, smallButtonWidth , 50);
    //self.undoButton.center = CGPointMake(mainScreen.size.width/5*4,self.moveImg.center.y + 60);
    self.undoButton.backgroundColor = [UIColor whiteColor];
    [self.undoButton.layer setCornerRadius:5];
    [self.undoButton setTitle:@"前进" forState:UIControlStateNormal];
    [self.undoButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.undoButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [self.undoButton addTarget:self action:@selector(undoButtonFoo) forControlEvents:UIControlEventTouchUpInside];
    
    
    self.popViewCtrlButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.popViewCtrlButton.frame = CGRectMake( 0, CGRectGetMaxY(mainScreen) - 50, 50, 50);
    self.popViewCtrlButton.backgroundColor = [UIColor clearColor];
    [self.popViewCtrlButton.layer setCornerRadius:5];
    [self.popViewCtrlButton setTitle:@"<-- " forState:UIControlStateNormal];
    [self.popViewCtrlButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.popViewCtrlButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [self.popViewCtrlButton addTarget:self action:@selector(goback:) forControlEvents:UIControlEventTouchUpInside];
    
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
    self.addMaskPoint.frame = CGRectMake(  CGRectGetMidX(mainScreen) - 25, CGRectGetMaxY(self.appImageView.frame) + 10, smallButtonWidth, 50);
    //self.addMaskPoint.center = CGPointMake(mainScreen.size.width/5*2, self.addMaskPoint.center.y);
    self.addMaskPoint.backgroundColor = [UIColor whiteColor];
    [self.addMaskPoint.layer setCornerRadius:5];
    [self.addMaskPoint setTitle:@"画笔" forState:UIControlStateNormal];
    [self.addMaskPoint setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.addMaskPoint setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [self.addMaskPoint addTarget:self action:@selector(addMaskPointFoo:) forControlEvents:UIControlEventTouchUpInside];
    
    //添加计算点按键
    self.addCalculatePoint = [UIButton buttonWithType:UIButtonTypeCustom];
    self.addCalculatePoint.frame = CGRectMake( CGRectGetMinX(self.addMaskPoint.frame) - (60 + 50) , CGRectGetMinY(self.addMaskPoint.frame) , smallButtonWidth, 50);
   // self.addCalculatePoint.center = CGPointMake(mainScreen.size.width/5,self.addCalculatePoint.center.y);
    self.addCalculatePoint.backgroundColor = [UIColor yellowColor];
    [self.addCalculatePoint.layer setCornerRadius:5];
    [self.addCalculatePoint setTitle:@"魔棒" forState:UIControlStateNormal];
    [self.addCalculatePoint setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.addCalculatePoint setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [self.addCalculatePoint addTarget:self action:@selector(cutImageCut:) forControlEvents:UIControlEventTouchUpInside];
    
    //添加删除Mark的按键
    self.deleteMaskPoint = [UIButton buttonWithType:UIButtonTypeCustom];
    self.deleteMaskPoint.frame = CGRectMake(CGRectGetMaxX(self.addMaskPoint.frame) + 60, CGRectGetMinY(self.addMaskPoint.frame), smallButtonWidth, 50);
   // self.deleteMaskPoint.center = CGPointMake(mainScreen.size.width/5*3, self.deleteMaskPoint.center.y);
    self.deleteMaskPoint.backgroundColor = [UIColor whiteColor];
    [self.deleteMaskPoint.layer setCornerRadius:5];
    [self.deleteMaskPoint setTitle:@"删除" forState:UIControlStateNormal];
    [self.deleteMaskPoint setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.deleteMaskPoint setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [self.deleteMaskPoint addTarget:self action:@selector(deleteMaskPointFoo:) forControlEvents:UIControlEventTouchUpInside];
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
  
    
    //CGRectMake(<#CGFloat x#>, <#CGFloat y#>, <#CGFloat width#>, <#CGFloat height#>)
    self.nextStep = [UIButton buttonWithType:UIButtonTypeCustom];
    self.nextStep.frame = CGRectMake( CGRectGetMaxX(mainScreen) - 100, CGRectGetMaxY(mainScreen) - 50, 100, 50);
    self.nextStep.backgroundColor = [UIColor whiteColor];
    [self.nextStep.layer setCornerRadius:5];
    [self.nextStep setTitle:@"下一步 >" forState:UIControlStateNormal];
    [self.nextStep setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    //[self.nextStep setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [self.nextStep addTarget:self action:@selector(nextStepFoo:) forControlEvents:UIControlEventTouchUpInside];
   

    //
    //[self.view addSubview:self.showImgView];
    [self.view addSubview:self.appImageView];
    [self.view addSubview:upKeepOutView];
    [self.view addSubview:bottomKeepOutView];
    //[self.view addSubview:self.openPhotoAlbum];
  //  [self.view addSubview:self.sysTestButton];
    [self.view addSubview:self.addCalculatePoint];
    [self.view addSubview:self.addMaskPoint];
    [self.view addSubview:self.deleteMaskPoint];
    //[self.view addSubview:self.moveImg];
   // [self.view addSubview:self.resetDrawButton];
    [self.view addSubview:self.redoButton];
    [self.view addSubview:self.undoButton];
  //  [self.view addSubview:self.addLineWidth];
  //  [self.view addSubview:self.subtractLineWidth];
    [self.view addSubview:self.nextStep];
    [self.view addSubview:self.popViewCtrlButton];
    
    self.view.backgroundColor = [UIColor grayColor];
    
    self.isDraw = NO;       //默认是添加
    self.isDelete  = NO;
    
    /**
     *  得到最终的剪切图的线程建立
     *
     *  @param "com.clover.cutImageIOS" <#"com.clover.cutImageIOS" description#>
     *  @param NULL                     <#NULL description#>
     *
     *  @return <#return value description#>
     */
    self.getFinnalImageQueue = dispatch_queue_create("com.clover.cutImageIOS", NULL);
   
    
    /**
     *  初始化观察者
     */
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(haveMaskMatFoo:)
                                                 name:@"com.clover.cutImageGetResultImage"
                                               object:nil];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)haveMaskMatFoo:(NSNotification *)notification{
    NSValue *haveMaskMat = [notification object];
    BOOL hb;
    [haveMaskMat getValue:&hb];
    if(hb){
        [self unLockNextStepButton];
    }
    else{
        [self LockNextStepButton];
    }
}
    
- (void)unLockNextStepButton{
    if(self.lockNextStep){
        self.lockNextStep = !self.lockNextStep;
        [self.nextStep setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    }
}

- (void)LockNextStepButton{
    if(!self.lockNextStep){
        self.lockNextStep = !self.lockNextStep;
        [self.nextStep setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    }
}


- (BOOL)prefersStatusBarHidden{
    return YES;
}

-(id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                animationControllerForOperation :(UINavigationControllerOperation) operation
                                              fromViewController:(UIViewController *)fromVC
                                                toViewController:(UIViewController *) toVC
{
    /**
     *  typedef NS_ENUM(NSInteger, UINavigationControllerOperation) {
     *     UINavigationControllerOperationNone,
     *     UINavigationControllerOperationPush,
     *     UINavigationControllerOperationPop,
     *  };
     */
    //push的时候用我们自己定义的customPush
    if ( operation == UINavigationControllerOperationPop ) {
        return self.custompopanimation;//customPush ;
    } else {
        return nil ;
    }
}

-(void)goback:(id)sender{
    /*
    CATransition *transition = [CATransition animation];
    transition.duration =0.4;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFromBottom;
    transition.delegate = self;
    [self.navigationController.view.layer addAnimation:transition forKey:nil];
     */
   
    [self.custompopanimation setEndPoint:self.returnPoint];
    [self.navigationController popViewControllerAnimated:YES];
}
/*
-(void) resultImageReady:(UIImage *)sendImage
{
    dispatch_async(dispatch_get_global_queue(0,0), ^{
        //耗时处理
        dispatch_async( dispatch_get_main_queue(), ^{
            //同步显示
            //self.appImageView.image = sendImage;
            //self.appImageView.layer.contents = sendImage;
            [self.appImageView setPicture:sendImage];
            //self.showImgView.image = sendImage;
        });
    });
}
 */
/**
 *  将试图恢复到初始位置,并且添加动画
 *
 *  @param sender 按键sender
 */
-(void) resetPosion:(id)sender
{
    //     self.appImageView.transform=CGAffineTransformIdentity;//取消一切形变
    //self.appImageView.transform =CGAffineTransformScale(self.orgTrf, 1, 1);
    [UIView animateWithDuration:.5 animations:^{
        self.appImageView.transform = CGAffineTransformMake(1, 0.0, 0.0, 1, 0, 0);
        self.appImageView.frame = self.orgRect;
    }];
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
    [self.appImageView resetAllMask];
}
/**
 *  回退操作
 */
-(void) redoButtonFoo
{
    [self.appImageView redo];
}
/**
 *  前进操作
 */
-(void) undoButtonFoo
{
    [self.appImageView undo];
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
    [self.appImageView setMove:NO];
    [self.appImageView setUserInteractionEnabled:YES];
    self.appImageView.isDraw = NO;
    self.appImageView.isDelete = NO;
    self.addCalculatePoint.backgroundColor  = [UIColor yellowColor];
    self.addMaskPoint.backgroundColor  = [UIColor whiteColor];
    self.deleteMaskPoint.backgroundColor  = [UIColor whiteColor];
    self.moveImg.backgroundColor  = [UIColor whiteColor];
    self.isDraw = NO;
    self.isDelete= NO;
    //[self.appImageView removeGestureRecognizer:self.panGestureRecognizer];
    //[self.appImageView removeGestureRecognizer:self.pinchGestureRecognizer];
}

-(void) addMaskPointFoo:(id)sender          //直接添加种子点
{
    [self.appImageView setMove:NO];
    [self.appImageView setUserInteractionEnabled:YES];
    self.appImageView.isDraw = YES;
    self.appImageView.isDelete = NO;
    self.addCalculatePoint.backgroundColor  = [UIColor whiteColor];
    self.addMaskPoint.backgroundColor       = [UIColor yellowColor];
    self.deleteMaskPoint.backgroundColor    = [UIColor whiteColor];
    self.moveImg.backgroundColor            = [UIColor whiteColor];
    self.isDraw = YES;
    self.isDelete= NO;
    //[self.appImageView removeGestureRecognizer:self.panGestureRecognizer];
    //[self.appImageView removeGestureRecognizer:self.pinchGestureRecognizer];
}

-(void) deleteMaskPointFoo:(id)sender
{
    [self.appImageView setMove:NO];
    [self.appImageView setUserInteractionEnabled:YES];
    self.appImageView.isDraw = NO;
    self.appImageView.isDelete = YES;
    self.addCalculatePoint.backgroundColor  = [UIColor whiteColor];
    self.addMaskPoint.backgroundColor       = [UIColor whiteColor];
    self.deleteMaskPoint.backgroundColor    = [UIColor yellowColor];
    self.moveImg.backgroundColor            = [UIColor whiteColor];
    self.isDelete = YES;
    //[self.appImageView removeGestureRecognizer:self.panGestureRecognizer];
    //[self.appImageView removeGestureRecognizer:self.pinchGestureRecognizer];
}

-(void) enableMoveImg:(id)sender
{
    [self.appImageView setMove:YES];
    [self.appImageView setUserInteractionEnabled:YES];
    self.addCalculatePoint.backgroundColor  = [UIColor whiteColor];
    self.addMaskPoint.backgroundColor       = [UIColor whiteColor];
    self.deleteMaskPoint.backgroundColor    = [UIColor whiteColor];
    self.moveImg.backgroundColor            = [UIColor yellowColor];
   
    //[self.appImageView addGestureRecognizer:self.panGestureRecognizer];
    //[self.appImageView addGestureRecognizer:self.pinchGestureRecognizer];
}

-(void) nextStepFoo:(id) sender
{
    if(!self.lockNextStep){
        //    [self.rotateCutImageViewController setImageRect:self.orgRect];
        
        dispatch_async(self.getFinnalImageQueue, ^{
            UIImage *setImage = [self.appImageView getReusltImage];
            [self.rotateCutImageViewController setImageRect:self.orgRect andImage:setImage];
            [self.rotateCutImageViewController setCreatNailRootVC:self.creatNailRootVC];
        });
        [self toRotateCutImageVCAnimationWithTimeDuration:0.5];
        [self.navigationController pushViewController:self.rotateCutImageViewController animated:YES];
    }
}
/**
 *  利用系统现有的动画定义VCpush动画
 *
 *  @param duration <#duration description#>
 */
- (void) toRotateCutImageVCAnimationWithTimeDuration:(float)duration{
    CATransition *transition = [CATransition animation];
    transition.duration = duration;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = @"oglFlip";
    transition.subtype = kCATransitionFromRight;
    transition.delegate = self;
    [self.navigationController.view.layer addAnimation:transition forKey:nil];
}

/**
 *  开打相册功能函数
 *
 *  @param sender
 */
-(void)takePictureClick:(id)sender
{
    
    /*注：使用，需要实现以下协议：UIImagePickerControllerDelegate,
     UINavigationControllerDelegate
     */
    
    UIImagePickerController *picker = [[UIImagePickerController alloc]init];
    
    //设置图片源(相簿)
//    picker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    //picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    //设置代理
    picker.delegate = self;
    //设置可以编辑
    picker.allowsEditing = YES;
    //打开拾取器界面
    [self presentViewController:picker animated:YES completion:nil];
}

//完成选择图片
//-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo
-(void)imagePickerController:(UIImagePickerController *)picker  didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    //加载图片
//    self.appImageView.image = image;
//    self.appImageView.layer.contents = image;
   // UIImage *image = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
    UIImage *image = [info objectForKey:@"UIImagePickerControllerEditedImage"];
    
    CGRect corpRect = [[info objectForKey:@"UIImagePickerControllerCropRect"]CGRectValue];
    
    [self.appImageView  setPicture:image];
    //self.showImgView.image = image;
    //[self.b2opcv setCalculateImage:image andWindowSize:self.imgWindowSize];
    //重置绘制线宽
    self.setLineWidth = DEFLINEWIDTH;
    //每次打开时，将appImageView归到初始位置
//    self.appImageView.frame = self.orgRect;
//    [self creatPan];
    //选择框消失
    [picker dismissViewControllerAnimated:YES completion:nil];
}
//取消选择图片

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

/**
 *  初始化手势动作相关接口
 *  添加多点触摸支持
 */
-(void) creatPan
{
    //self.appImageView.multipleTouchEnabled = YES;
    self.panGestureRecognizer = [[UIPanGestureRecognizer alloc]
                                                    initWithTarget:self
                                                    action:@selector(handlePan:)];
    self.panGestureRecognizer.minimumNumberOfTouches = 2;
    self.panGestureRecognizer.delegate = self;
    self.pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc]
                                                        initWithTarget:self
                                                        action:@selector(handlePinch:)];
    self.pinchGestureRecognizer.delegate = self;
    [self.appImageView addGestureRecognizer:self.panGestureRecognizer];
    [self.appImageView addGestureRecognizer:self.pinchGestureRecognizer];
}

- (void) handlePan:(UIPanGestureRecognizer*) recognizer
{
    
    if (recognizer.state==UIGestureRecognizerStateChanged) {
        //NSLog(@" UIGestureRecognizerStateChanged ");
        CGPoint translation = [recognizer translationInView:self.view];
        recognizer.view.center = CGPointMake(recognizer.view.center.x + translation.x,
                                             recognizer.view.center.y + translation.y);
        [recognizer setTranslation:CGPointZero inView:self.view];
    }
    else if(recognizer.state == UIGestureRecognizerStateEnded){
        CGAffineTransform show =  recognizer.view.transform;
        CGAffineTransform show2 =  self.orgTrf;
    }
}

- (void) handlePinch:(UIPinchGestureRecognizer*) recognizer
{
    if (recognizer.state==UIGestureRecognizerStateChanged) {
        recognizer.view.transform=CGAffineTransformScale(recognizer.view.transform, recognizer.scale, recognizer.scale);
        recognizer.scale = 1; //不重置为1则变化会太快
    }
    else if(recognizer.state == UIGestureRecognizerStateEnded){
        if(recognizer.view.transform.a > 2.0){
            [UIView animateWithDuration:.25 animations:^{
                recognizer.view.transform= CGAffineTransformMake(2.0, 0.0, 0.0, 2.0, 0, 0) ;//取消一切形变
            }];
        }
        else if( recognizer.view.transform.a < 0.6 ){
            [UIView animateWithDuration:.25 animations:^{
                recognizer.view.transform= CGAffineTransformMake(0.6, 0.0, 0.0, 0.6, 0, 0) ;//取消一切形变
            }];
        }
        
        [self.appImageView setLineScale:recognizer.view.transform.a];
        NSLog(@"view.transform.a = %f",recognizer.view.transform.a);
        CGAffineTransform show =  recognizer.view.transform;
        CGAffineTransform show2 =  self.orgTrf;
    }
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

/*
-(void) setReturnPoint:(CGPoint)setPoint
{
    self.rurnPoint = setPoint;
}
 */

/**
 *  画图测试
 */



@end