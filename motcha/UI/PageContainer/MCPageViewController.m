#import "MCPageViewController.h"

#import "MCNavigationController.h"
#import "MCNewsCategorySelectorScrollView.h"
#import "MCKeyValuePair.h"
#import "NSMutableArray+Manipulation.h"

static void *scrollViewContext = &scrollViewContext;

@interface MCPageViewController ()<MCPageViewDelegate>
@end

@implementation MCPageViewController {
  NSMutableArray *_viewControllers; // An array of (MCNewsListViewController *)viewController
  Class _pageViewItemClass;
  NSUInteger _pageIndex;
  BOOL _observingPageView;
}

- (instancetype)init {
  if (self = [super init]) {
    _viewControllers = [NSMutableArray array];
  }
  return self;
}

- (void)registerClass:(Class)pageViewItemClass {
  if (![pageViewItemClass isSubclassOfClass:[UIViewController class]]) {
    @throw [NSException exceptionWithName:NSInvalidArgumentException
                                   reason:@"class must be a subclass of UIViewController."
                                 userInfo:nil];
  }
  _pageViewItemClass = pageViewItemClass;
}

- (UIViewController *)viewControllerAtIndex:(NSUInteger)index {
  return [_viewControllers objectAtIndex:index];
}

- (void)loadView {
  self.pageView = [[MCPageView alloc] init];
  self.pageView.delegate = self;
  self.pageView.translatesAutoresizingMaskIntoConstraints = NO;
  self.view = self.pageView;
  self.automaticallyAdjustsScrollViewInsets = NO;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [self observePageView];
}

- (void)insertViewControllerAtIndex:(NSUInteger)index {
  if (!_pageViewItemClass) {
    @throw [NSException exceptionWithName:NSGenericException
                                   reason:@"-(void)registerClass: must be called prior to this method."
                                 userInfo:nil];
  }
  UIViewController *viewController = [self createViewController];
  [_viewControllers insertObject:viewController atIndex:index];
}

- (UIViewController *)removeViewControllerAtIndex:(NSUInteger)index {
  UIViewController *viewController = [_viewControllers objectAtIndex:index];
  [_viewControllers removeObjectAtIndex:index];
  return viewController;
}

- (void)moveViewControllerFromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex {
  [_viewControllers moveObjectFromIndex:fromIndex toIndex:toIndex];
}

- (void)exchangeViewControllerAtIndex:(NSUInteger)index1 withViewControllerAtIndex:(NSUInteger)index2 {
  [self moveViewControllerFromIndex:index1 toIndex:index2];
  [self moveViewControllerFromIndex:index2+(index1 < index2 ? -1 : 1) toIndex:index1];
}
/*
 1. remove observer if observing
 2. remove child view controllers and views
 3. add child view controllers and views according to array
 4. add observer
 5. force layout
 */
- (void)reloadViewControllers {
  [self deobservePageView];
  for (UIViewController *viewController in self.childViewControllers) {
    [viewController willMoveToParentViewController:nil];
    [self.pageView removePageViewItem:viewController.view];
    [viewController removeFromParentViewController];
  }
  for (UIViewController *viewController in _viewControllers) {
    if ([_delegate conformsToProtocol:@protocol(MCPageViewControllerDelegate)] &&
        [_delegate respondsToSelector:@selector(pageViewController:willLoadViewController:atIndex:)]) {
      [_delegate pageViewController:self
             willLoadViewController:viewController
                            atIndex:[_viewControllers indexOfObject:viewController]];
    }
    [self addChildViewController:viewController];
    viewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    if ([_delegate conformsToProtocol:@protocol(MCPageViewControllerDelegate)] &&
        [_delegate respondsToSelector:@selector(pageViewController:didLoadViewController:atIndex:)]) {
      [_delegate pageViewController:self
              didLoadViewController:viewController
                            atIndex:[_viewControllers indexOfObject:viewController]];
    }
    [self.pageView addPageViewItem:viewController.view];
    [viewController didMoveToParentViewController:self];
  }
  [self.pageView reloadViews];
  [self observePageView];
  [self.pageView setNeedsLayout];
  [self.pageView layoutIfNeeded];
}

- (NSUInteger)viewControllerCount {
  return [_viewControllers count];
}

#pragma mark - MCPageViewDelegate<UIScrollView> methods
- (void)scrollViewDidEndScrollingWithoutAnimation:(UIScrollView *)scrollView {
  [self scrollViewDidEndChangingAnimated:NO];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
  [self scrollViewDidEndChangingAnimated:YES];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
  [self scrollViewDidEndChangingAnimated:YES];
}

- (void)scrollViewDidEndChangingAnimated:(BOOL)animated {
  if ([_delegate conformsToProtocol:@protocol(MCPageViewControllerDelegate)] &&
      [_delegate respondsToSelector:@selector(pageViewController:pageDidFinishAnimated:withCurrentPage:atIndex:)]) {
    UIViewController *viewController = [self viewControllerAtIndex:_pageIndex];
    [_delegate pageViewController:self
            pageDidFinishAnimated:animated
                  withCurrentPage:viewController
                          atIndex:_pageIndex];
  }
}

#pragma mark - NSKeyValueObserving methods
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
  if (context == scrollViewContext) {
    CGFloat contentOffsetX = [(NSValue*)[change objectForKey:@"new"] CGPointValue].x;
    CGFloat pageOffset = contentOffsetX / self.pageView.frame.size.width;
    pageOffset = MIN([_viewControllers count]-1, MAX(0, pageOffset));
    _pageIndex = round(pageOffset);
  }
}

#pragma mark - UIContentContainer methods
- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
  NSUInteger localPageIndex = _pageIndex;
  [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
    self.pageView.contentOffset = CGPointMake(self.pageView.frame.size.width * localPageIndex, 0);
  } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
    _pageIndex = localPageIndex;
  }];
  [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

#pragma mark - Helpers
- (UIViewController *)createViewController {
  UIViewController *viewController = [[_pageViewItemClass alloc] init];
  return viewController;
}

- (void)observePageView {
  if (!_observingPageView) {
    [self.pageView addObserver:self
                    forKeyPath:@"contentOffset"
                       options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                       context:scrollViewContext];
    _observingPageView = YES;
  }
}

- (void)deobservePageView {
  if (_observingPageView) {
    [self.pageView removeObserver:self forKeyPath:@"contentOffset"];
    _observingPageView = NO;
  }
}

#pragma mark - dealloc
- (void)dealloc {
  [self deobservePageView];
}
@end
