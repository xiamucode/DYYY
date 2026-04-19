#import "AwemeHeaders.h"
#import "DYYYUtils.h"

// 资源下载地址优选
%hook AWEURLModel
%new - (NSURL *)getDYYYSrcURLDownload {
    NSURL *bestURL = nil;
    NSInteger bestScore = NSIntegerMin;
    NSArray<NSString *> *qualityHints = @[ @"4k", @"2160", @"2k", @"1440", @"1080", @"uhd", @"fhd", @"720", @"540", @"480", @"360" ];

    for (NSString *urlString in self.originURLList) {
        if (![urlString isKindOfClass:[NSString class]] || urlString.length == 0) {
            continue;
        }

        NSString *lowerURL = urlString.lowercaseString;
        NSInteger score = 0;

        if ([lowerURL containsString:@"video_mp4"]) {
            score += 1000;
        } else if ([lowerURL containsString:@".jpeg"] || [lowerURL containsString:@".jpg"]) {
            score += 500;
        } else if ([lowerURL containsString:@".mp3"]) {
            score += 500;
        }

        for (NSInteger index = 0; index < qualityHints.count; index++) {
            NSString *hint = qualityHints[index];
            if ([lowerURL containsString:hint]) {
                score += (NSInteger)(qualityHints.count - index) * 100;
                break;
            }
        }

        if ([lowerURL containsString:@"low"] || [lowerURL containsString:@"lowest"] || [lowerURL containsString:@"playwm"]) {
            score -= 300;
        }

        if (score > bestScore) {
            bestScore = score;
            bestURL = [NSURL URLWithString:urlString];
        }
    }

    if (!bestURL && self.originURLList.count > 0) {
        bestURL = [NSURL URLWithString:[self.originURLList firstObject]];
    }

    return bestURL;
}
%end

// 隐藏视频页底部“转发日常”按钮
%hook AFDShareToDailyBottomButton
- (void)layoutSubviews {
    %orig;
    if (DYYYGetBool(@"DYYYHideShareToDailyBottomButton")) {
        self.hidden = YES;
    }
}
%end

%hook AWEUserProfileUGCContributionGuideEmptyCollectionViewCell
- (void)layoutSubviews {
    %orig;

    if (!DYYYGetBool(@"DYYYHidePostView"))
        return;

    UIView *view = (UIView *)self;
    view.hidden = YES;
    view.alpha = 0.0;
    view.userInteractionEnabled = NO;

    CGRect f = view.frame;
    f.size.height = 0;
    view.frame = f;
}
%end

// 隐藏搜索后的 AI 搜索
%hook UIView
- (void)addSubview:(UIView *)view {
    NSString *cls = NSStringFromClass([view class]);

    if ([cls containsString:@"AIBall"] || [cls containsString:@"AIGCSummaryEntryView"]) {
        return;
    }

    %orig;
}

- (void)layoutSubviews {
    %orig;

    if (!DYYYGetBool(@"DYYYHideMusicTopText")) {
        return;
    }

    UIViewController *viewController = [DYYYUtils firstAvailableViewControllerFromView:self];
    if (![viewController isKindOfClass:%c(AWEPlayInteractionViewController)]) {
        return;
    }

    NSString *className = NSStringFromClass([self class]);
    NSString *superviewClassName = NSStringFromClass([self.superview class]);
    BOOL isMusicContainerClass = [className containsString:@"PlayInteractionStyleOneMusic"] || [className containsString:@"PlayInteractionSingleSongMusicStyle"] || [className containsString:@"MusicCoverButton"];
    BOOL isMusicContainerSuperview = [superviewClassName containsString:@"PlayInteractionStyleOneMusic"] || [superviewClassName containsString:@"PlayInteractionSingleSongMusicStyle"] || [superviewClassName containsString:@"MusicCoverButton"];
    BOOL matchSelfFrame = self.frame.origin.x == 0.0 && self.frame.origin.y == 0.0 && self.frame.size.width >= 40.0 && self.frame.size.width <= 48.0 && self.frame.size.height >= 40.0 && self.frame.size.height <= 48.0;
    BOOL matchState = !self.userInteractionEnabled && self.clipsToBounds;
    if (!((isMusicContainerClass || isMusicContainerSuperview) && matchSelfFrame && matchState)) {
        return;
    }

    BOOL hasShadowStripImageView = NO;
    BOOL hasMusicTextLabel = NO;
    for (UIView *subview in self.subviews) {
        if ([subview isKindOfClass:[UIImageView class]]) {
            CGRect frame = subview.frame;
            BOOL matchFrame = frame.origin.x >= -1.0 && frame.origin.x <= 2.0 && frame.origin.y >= 24.0 && frame.origin.y <= 36.0 && frame.size.width >= 40.0 && frame.size.width <= 48.0 && frame.size.height >= 12.0 && frame.size.height <= 16.0;
            if (matchFrame) {
                hasShadowStripImageView = YES;
            }
        } else if ([subview isKindOfClass:[UILabel class]]) {
            UILabel *label = (UILabel *)subview;
            NSString *text = label.text;
            if ([text isKindOfClass:[NSString class]] && ([text containsString:@"同款"] || [text containsString:@"听"])) {
                hasMusicTextLabel = YES;
            }
        }
    }

    if (hasShadowStripImageView || hasMusicTextLabel) {
        self.hidden = YES;
        self.alpha = 0.0;
    }
}
%end

%hook AWESearchAIGCSummaryEntryView
- (void)didMoveToSuperview {
    %orig;
    self.hidden = YES;
}

- (void)layoutSubviews {
    %orig;
    self.hidden = YES;
}
%end

// 隐藏 iPad 右上搜索，但可点击
%hook AWEPadSearchEntranceView
- (void)layoutSubviews {
    %orig;

    BOOL shouldHideDiscover = DYYYGetBool(@"DYYYHideIPadDiscover");
    self.hidden = NO;
    self.userInteractionEnabled = YES;
    for (UIView *subview in self.subviews) {
        subview.alpha = shouldHideDiscover ? 0.0 : 1.0;
    }
}
%end

// 隐藏音乐按钮上方文字（拍同款/玩同款/听抖音等）
%hook UILabel
- (void)layoutSubviews {
    %orig;

    if (!DYYYGetBool(@"DYYYHideMusicTopText")) {
        return;
    }

    UIViewController *viewController = [DYYYUtils firstAvailableViewControllerFromView:self];
    if (![viewController isKindOfClass:%c(AWEPlayInteractionViewController)]) {
        return;
    }

    NSString *text = self.text;
    BOOL matchText = [text isKindOfClass:[NSString class]] && ([text containsString:@"同款"] || [text containsString:@"听"]);
    CGRect frame = self.frame;
    BOOL matchSize = frame.size.width >= 33.0 && frame.size.width <= 40.0 && frame.size.height >= 12.0 && frame.size.height <= 16.0;
    BOOL matchPosition = frame.origin.x >= 2.0 && frame.origin.x <= 8.0 && frame.origin.y >= 24.0 && frame.origin.y <= 36.0;

    NSString *parentAccessibilityLabel = self.superview.accessibilityLabel;
    BOOL matchParentText = [parentAccessibilityLabel isKindOfClass:[NSString class]] && ([parentAccessibilityLabel containsString:@"同款"] || [parentAccessibilityLabel containsString:@"听"]);
    BOOL matchParentSize = self.superview.frame.size.width >= 40.0 && self.superview.frame.size.width <= 48.0 && self.superview.frame.size.height >= 40.0 && self.superview.frame.size.height <= 48.0;

    if ((matchText && matchSize && matchPosition) || (matchParentText && matchParentSize)) {
        self.hidden = YES;
        self.alpha = 0.0;
        self.userInteractionEnabled = NO;
    }
}
%end

// 隐藏音乐按钮上方文案的底色阴影条
%hook UIImageView
- (void)layoutSubviews {
    %orig;

    if (!DYYYGetBool(@"DYYYHideMusicTopText")) {
        return;
    }

    UIViewController *viewController = [DYYYUtils firstAvailableViewControllerFromView:self];
    if (![viewController isKindOfClass:%c(AWEPlayInteractionViewController)]) {
        return;
    }

    CGRect frame = self.frame;
    BOOL matchFrame = frame.origin.x >= -1.0 && frame.origin.x <= 2.0 && frame.origin.y >= 24.0 && frame.origin.y <= 36.0 && frame.size.width >= 40.0 && frame.size.width <= 48.0 && frame.size.height >= 12.0 && frame.size.height <= 16.0;
    BOOL matchImage = (self.image == nil);
    BOOL matchBgAlpha = (self.backgroundColor && CGColorGetAlpha(self.backgroundColor.CGColor) >= 0.35);
    BOOL matchParentSize = self.superview.frame.size.width >= 40.0 && self.superview.frame.size.width <= 48.0 && self.superview.frame.size.height >= 40.0 && self.superview.frame.size.height <= 48.0;

    BOOL hasTargetLabelSibling = NO;
    for (UIView *sibling in self.superview.subviews) {
        if (![sibling isKindOfClass:[UILabel class]]) {
            continue;
        }

        UILabel *label = (UILabel *)sibling;
        NSString *text = label.text;
        BOOL matchText = [text isKindOfClass:[NSString class]] && ([text containsString:@"同款"] || [text containsString:@"听"]);
        CGRect labelFrame = label.frame;
        BOOL matchLabelFrame = labelFrame.origin.x >= 2.0 && labelFrame.origin.x <= 8.0 && labelFrame.origin.y >= 24.0 && labelFrame.origin.y <= 36.0 && labelFrame.size.width >= 33.0 && labelFrame.size.width <= 40.0 && labelFrame.size.height >= 12.0 && labelFrame.size.height <= 16.0;

        if (matchText || matchLabelFrame || label.hidden || label.alpha < 0.05) {
            hasTargetLabelSibling = YES;
            break;
        }
    }

    if (matchFrame && matchImage && matchBgAlpha && matchParentSize && hasTargetLabelSibling) {
        self.hidden = YES;
        self.alpha = 0.0;
        self.userInteractionEnabled = NO;
    }
}
%end
