#import "MCDetailNewsBodyView.h"

#import "MCNewsDetailsObject.h"
#import "MCNewsImageBlock.h"
#import "MCNewsTextBlock.h"
#import "UIFont+DINFont.h"

static CGFloat kTextBlockMargin = 12.0f;
static CGFloat kImageBlockMargin = 15.0f;
static CGFloat kTitleBlockMargin = 10.0f;

@implementation MCDetailNewsBodyView {
  CGFloat _fontSize;
}

- (instancetype)init {
  if (self = [super init]) {
    [self setTranslatesAutoresizingMaskIntoConstraints:NO];

  }
  return self;
}

- (void)setupControls {
}

- (void)layoutSubviews {
  for (NSObject *view in self.subviews) {
    if ([view isKindOfClass:[MCNewsTextBlock class]]) {
      MCNewsTextBlock *textView = (MCNewsTextBlock*)view;
      if (textView.fontSize != _fontSize) {
        textView.fontSize = _fontSize;
      }
    }
  }
  [super layoutSubviews];
}

- (void)setBodyContents:(NSArray *)bodyContents {
  _bodyContents = bodyContents;
  NSObject *prevBlock;
  for (NSObject *bodyItem in bodyContents) {
    NSDictionary *metrics;
    NSObject *block;
    if ([bodyItem isKindOfClass:[MCNewsDetailsParagraph class]]) {
      MCNewsTextBlock *textBlock = [[MCNewsTextBlock alloc] init];
      textBlock.text = ((MCNewsDetailsParagraph *)bodyItem).text;
      [textBlock setTranslatesAutoresizingMaskIntoConstraints:NO];
      [self addSubview:textBlock];
      metrics = @{@"blockMargin":[NSNumber numberWithDouble:kTextBlockMargin]};
      block = textBlock;
    } else if ([bodyItem isKindOfClass:[MCNewsDetailsImage class]]) {
      // TODO:handle images
      MCNewsTextBlock *textBlock = [[MCNewsTextBlock alloc] init];
      textBlock.text = @"[IMAGE PLACEHOLDER]";
      [textBlock setTranslatesAutoresizingMaskIntoConstraints:NO];
      [self addSubview:textBlock];
      metrics = @{@"blockMargin":[NSNumber numberWithDouble:kImageBlockMargin]};
      block = textBlock;
    } else if ([bodyItem isKindOfClass:[MCNewsDetailsTitle class]]) {
      // TODO: (Phoebe)handle title
      MCNewsTextBlock *textBlock = [[MCNewsTextBlock alloc] init];
      textBlock.text = @"[SUBTITLE PLACEHOLDER]";
      [textBlock setTranslatesAutoresizingMaskIntoConstraints:NO];
      [self addSubview:textBlock];
      metrics = @{@"blockMargin":[NSNumber numberWithDouble:kTitleBlockMargin]};
      block = textBlock;
    }
    if (bodyItem == [bodyContents firstObject]) { // first one, pin to top
      [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[block]"
                                                                   options:0
                                                                   metrics:nil
                                                                     views:@{@"block":block}]];
    } else { // else, pin to previous
      [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[prevBlock][block]"
                                                                   options:0
                                                                   metrics:nil
                                                                     views:@{@"block":block, @"prevBlock":prevBlock}]];
      if (bodyItem == [bodyContents lastObject]) { //last one, pin to bottom
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[block]|"
                                                                     options:0
                                                                     metrics:nil
                                                                       views:@{@"block":block}]];
      }
    }
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-blockMargin-[block]-blockMargin-|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:@{@"block":block}]];
    prevBlock = block;
  }
}

- (void)changeTextFontSize:(NSInteger)fontSize needsLayoutSubviews:(BOOL)needsLayoutSubviews {
  _fontSize = fontSize;
  if (needsLayoutSubviews) {
    [self setNeedsLayout];
    [self layoutIfNeeded];
  }
}

#pragma mark - UIGestureRecognizer action
- (void)imageBlockTapped:(UIGestureRecognizer*)tapGestureRecognizer {
  if ([_delegate conformsToProtocol:@protocol(MCNewsDetailScrollViewDelegate)] &&
      [_delegate respondsToSelector:@selector(imageBlockTappedForImageView:)]) {
    [_delegate imageBlockTappedForImageView:(UIImageView*)tapGestureRecognizer.view];
  }
}
@end
