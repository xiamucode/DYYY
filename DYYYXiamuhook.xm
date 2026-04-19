#import "AwemeHeaders.h"

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

// 隐藏音乐按钮上的同款/听抖音文字
%hook AWEPlayInteractionStyleOneMusicView
- (void)layoutSubviews {
    %orig;

    if (!DYYYGetBool(@"DYYYHideMusicTopText")) {
        return;
    }

    NSMutableArray<UIView *> *stack = [NSMutableArray arrayWithObject:self];
    while (stack.count > 0) {
        UIView *currentView = stack.lastObject;
        [stack removeLastObject];

        for (UIView *subview in currentView.subviews) {
            [stack addObject:subview];

            if (![subview isKindOfClass:[UILabel class]]) {
                continue;
            }

            UILabel *label = (UILabel *)subview;
            NSString *text = label.text;
            if (![text isKindOfClass:[NSString class]] || text.length == 0) {
                continue;
            }

            BOOL matchText = [text containsString:@"同款"] || [text containsString:@"听"];
            CGRect frame = label.frame;
            BOOL matchSize = frame.size.width >= 33.0 && frame.size.width <= 40.0 && frame.size.height >= 12.0 && frame.size.height <= 16.0;
            BOOL matchPosition = frame.origin.x >= 2.0 && frame.origin.x <= 8.0 && frame.origin.y >= 24.0 && frame.origin.y <= 36.0;

            if (matchText && matchSize && matchPosition) {
                label.hidden = YES;
                label.alpha = 0.0;
            }
        }
    }
}
%end
