#import "MCNewsDetailViewController.h"

#import <QuartzCore/QuartzCore.h>
#import "JTSImageViewController.h"
#import "JTSImageInfo.h"
#import "MBProgressHUD.h"

#import "MCNewsDetailsObject.h"
#import "MCNewsDetailScrollView.h"
#import "MCNavigationController.h"
#import "MCNavigationBarCustomizationDelegate.h"
#import "MCParsedRSSItem.h"
#import "MCWebContentService.h"

//static CGFloat kScrollViewContentBottomInset = 20.0f;

@interface MCNewsDetailViewController ()
<
    MCNewsDetailScrollViewDelegate,
    JTSImageViewControllerImageSavingDelegate,
    MBProgressHUDDelegate,
    MCNavigationBarCustomizationDelegate
>
@end

@implementation MCNewsDetailViewController {
  MCNewsDetailScrollView *_scrollView;
  MBProgressHUD *_HUD;
  MCParsedRSSItem *_item;
  MCNewsDetailsObject *_data;
}

- (instancetype)initWithRSSItem:(MCParsedRSSItem *)item {
  self = [super init];
  if (self) {
    _item = item;
  }
  return self;
}

- (void)loadView {
  _scrollView = [[MCNewsDetailScrollView alloc] init];
  self.view = _scrollView;
  //register self to MCNewsDetailScrollView delegate
  _scrollView.mcDelegate = self;
  //_scrollView.contentInset = UIEdgeInsetsMake(0,0,kScrollViewContentBottomInset,0);
  self.automaticallyAdjustsScrollViewInsets = NO;
  
  //add right bar items: font and share item
  UIBarButtonItem *fontButton =
  [[UIBarButtonItem alloc] initWithTitle:@"Aa"
                                   style: UIBarButtonItemStylePlain
                                  target:self
                                  action:@selector(fontButtonPressed:)];
  UIBarButtonItem *shareButton =
  [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                target:self
                                                action:@selector(shareButtonPressed:)];
  NSArray *actionBarItems = @[shareButton, fontButton];
  self.navigationItem.rightBarButtonItems = actionBarItems;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [[MCWebContentService sharedInstance] fetchNewsDetailsWithItem:_item completionBlock:^(MCNewsDetailsObject *data, NSError *error) {
    if (!error) {
      _data = data;
      dispatch_async(dispatch_get_main_queue(), ^{
        [self reload];
      });
    } else {
      // TODO(shinfan): Handle error here.
    }
  }];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [(MCNavigationController *)self.navigationController notifyViewControllerWillAppearAnimated:animated];
}

- (void)reload {
  // TODO: Use real image
  [_scrollView setImage:[UIImage imageNamed:@"Cherry-Blossom"]];
  [_scrollView setNewsTitle:_data.title];
  [_scrollView setSource:_data.source];
  [_scrollView setAuthor:_data.author];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    [_scrollView setPublishDate:[dateFormatter dateFromString:@"2014-12-11"]];
  [_scrollView setNewsMainBody:[_data content]];
}

#pragma mark - MCNewsDetailScrollViewDelegate methods
- (void)imageBlockTappedForImageView:(UIImageView *)imageView {
  JTSImageInfo *imageInfo = [[JTSImageInfo alloc] init];
  imageInfo.image = imageView.image;
  imageInfo.referenceRect = imageView.frame;
  imageInfo.referenceView = imageView.superview;
  imageInfo.referenceContentMode = imageView.contentMode;
  imageInfo.referenceCornerRadius = imageView.layer.cornerRadius;
  JTSImageViewController *imageViewer =
      [[JTSImageViewController alloc] initWithImageInfo:imageInfo
                                                   mode:JTSImageViewControllerMode_Image
                                        backgroundStyle:JTSImageViewControllerBackgroundOption_Scaled];
  imageViewer.imageSavingDelegate = self;
  [imageViewer showFromViewController:self transition:JTSImageViewControllerTransition_FromOriginalPosition];
}

#pragma mark - button press target actions
- (void)shareButtonPressed:(UIBarButtonItem *)sender {
  // TODO: get the actual url and text to share
  NSString *textToShare = @"Mocha is so good!";
  NSURL *website = [NSURL URLWithString:@"https://www.google.ca/"];
  NSArray *objectsToShare = @[textToShare, website];
  // TODO: add weixin activity SDK
  UIActivityViewController *activityVC =
      [[UIActivityViewController alloc] initWithActivityItems:objectsToShare
                                        applicationActivities: nil];
  activityVC.excludedActivityTypes = @[UIActivityTypePrint, UIActivityTypeAssignToContact,
                                       UIActivityTypeSaveToCameraRoll, UIActivityTypePostToFlickr,
                                       UIActivityTypePostToVimeo, UIActivityTypeAirDrop];
  [self presentViewController:activityVC animated:YES completion:nil];
}

- (void)image:(UIImage *)image didSavingWithError:(NSError *)error contextInfo: (void *) contextInfo {
  //bring up an alertView showing the error msg to user
  NSLog(@"cannot save image.");
  UIAlertView *failureAlert =[[UIAlertView alloc] initWithTitle:@" Unable to Save Image"
                                                        message:@"Motcha does not have permission to access your photos. Please go to Settings > Privacy > Photos, and turn on Motcha."
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil, nil];
  [failureAlert show];
}
- (void)image:(UIImage *)image didSavingWithSuccess:(NSError *)error contextInfo:(void *)contextInfo target:(JTSImageViewController *)viewController {
  //bring up an HUD showing successful image
  NSLog(@"image saved successfully.");
  _HUD = [[MBProgressHUD alloc] initWithView:viewController.view];
  [viewController.view addSubview:_HUD];

  _HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]];
  
  // Set custom view mode
  _HUD.mode = MBProgressHUDModeCustomView;
  
  _HUD.delegate = self;
  _HUD.labelText = @"Saved successfully";
  
  [_HUD show:YES];
  [_HUD hide:YES afterDelay:1];

}


- (void)fontButtonPressed:(UIBarButtonItem *)sender {
  [_scrollView toggleTextFontSize];
}

#pragma mark - MCNavigationBarCustomizationDelegate methods
@synthesize navigationBarBackgroundAlpha = _navigationBarBackgroundAlpha;

- (CGFloat)navigationBarBackgroundAlpha {
  return 0.0f;
}
@end
