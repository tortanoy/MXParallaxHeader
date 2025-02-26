// MXParallaxHeader.m
//
// Copyright (c) 2019 Maxime Epain
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <objc/runtime.h>
#import "MXParallaxHeader.h"

@interface MXParallaxView : UIView
@property (nonatomic,weak) MXParallaxHeader *parent;
@end

@implementation MXParallaxView

static void * const kMXParallaxHeaderKVOContext = (void*)&kMXParallaxHeaderKVOContext;

- (void)willMoveToSuperview:(UIView *)newSuperview {
    if ([self.superview isKindOfClass:[UIScrollView class]]) {
        [self.superview removeObserver:self.parent forKeyPath:NSStringFromSelector(@selector(contentOffset)) context:kMXParallaxHeaderKVOContext];
    }
}

- (void)didMoveToSuperview{
    if ([self.superview isKindOfClass:[UIScrollView class]]) {
        [self.superview addObserver:self.parent
                         forKeyPath:NSStringFromSelector(@selector(contentOffset))
                            options:NSKeyValueObservingOptionNew
                            context:kMXParallaxHeaderKVOContext];
    }
}

@end

@interface MXParallaxHeader ()
@property (nonatomic,weak) UIScrollView *scrollView;
@end

@implementation MXParallaxHeader {
    BOOL _isObserving;
}

@synthesize contentView = _contentView;

#pragma mark Properties

- (UIView *)contentView {
    if (!_contentView) {
        MXParallaxView *contentView = [MXParallaxView new];
        contentView.parent = self;
        contentView.clipsToBounds = YES;
        _contentView = contentView;
    }
    return _contentView;
}

- (void)setView:(UIView *)view {
    if (view != _view) {
        [_view removeFromSuperview];
        
        _view = view;
        [self updateConstraints];
    }
}

- (void)setMode:(MXParallaxHeaderMode)mode {
    if (_mode != mode) {
        _mode = mode;
        [self updateConstraints];
    }
}

- (void)setHeight:(CGFloat)height {
    if (_height != height) {
        
        //Adjust content inset
        [self adjustScrollViewTopInset:self.scrollView.contentInset.top - _height + height];
        
        _height = height;
        [self updateConstraints];
        [self layoutContentView];
    }
}

- (void)setMinimumHeight:(CGFloat)minimumHeight {
    _minimumHeight = minimumHeight;
    [self layoutContentView];
}

- (void)setScrollView:(UIScrollView *)scrollView {
    if (_scrollView != scrollView) {
        _scrollView = scrollView;
        
        //Adjust content inset
        [self adjustScrollViewTopInset:scrollView.contentInset.top + self.height];
        [scrollView addSubview:self.contentView];
        
        //Layout content view
        [self layoutContentView];
        _isObserving = YES;
    }
}

- (void)setProgress:(CGFloat)progress {
    if(_progress != progress) {
        _progress = progress;
        
        if ([self.delegate respondsToSelector:@selector(parallaxHeaderDidScroll:)]) {
            [self.delegate parallaxHeaderDidScroll:self];
        }
    }
}
    
- (void)setYOffset:(CGFloat)yOffset {
    if(_yOffset != yOffset) {
        _yOffset = yOffset;
        
        if ([self.delegate respondsToSelector:@selector(parallaxHeaderDidScroll:)]) {
            [self.delegate parallaxHeaderDidScroll:self];
        }
    }
}

- (void)loadWithNibName:(NSString *)name bundle:(nullable NSBundle *)bundleOrNil options:(nullable NSDictionary<UINibOptionsKey, id> *)optionsOrNil {
    UINib *nib = [UINib nibWithNibName:name bundle:bundleOrNil];
    [nib instantiateWithOwner:self options:optionsOrNil];
}

#pragma mark Constraints

- (void)updateConstraints {
    if (!self.view) {
        return;
    }
    
    [self.view removeFromSuperview];
    [self.contentView addSubview:self.view];
    
    self.view.translatesAutoresizingMaskIntoConstraints = NO;
    
    switch (self.mode) {
        case MXParallaxHeaderModeFill:
            [self setFillModeConstraints];
            break;
            
        case MXParallaxHeaderModeTopFill:
            [self setTopFillModeConstraints];
            break;
            
        case MXParallaxHeaderModeTop:
            [self setTopModeConstraints];
            break;
            
        case MXParallaxHeaderModeBottom:
            [self setBottomModeConstraints];
            break;
            
        default:
            [self setCenterModeConstraints];
            break;
    }
}

- (void)setCenterModeConstraints {
    [self.view.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor].active = YES;
    [self.view.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor].active = YES;
    [self.view.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor].active = YES;
    [self.view.heightAnchor constraintEqualToConstant:self.height].active = YES;
}

- (void)setFillModeConstraints {
    [self.view.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor].active = YES;
    [self.view.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor].active = YES;
    [self.view.topAnchor constraintEqualToAnchor:self.contentView.topAnchor].active = YES;
    [self.view.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor].active = YES;
}

- (void)setTopFillModeConstraints {
    [self.view.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor].active = YES;
    [self.view.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor].active = YES;
    [self.view.topAnchor constraintEqualToAnchor:self.contentView.topAnchor].active = YES;
    [self.view.heightAnchor constraintGreaterThanOrEqualToConstant:self.height].active = YES;

    NSLayoutConstraint *constraint = [self.view.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor];
    constraint.priority = UILayoutPriorityDefaultHigh;
    constraint.active = YES;
}

- (void)setTopModeConstraints {
    [self.view.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor].active = YES;
    [self.view.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor].active = YES;
    [self.view.topAnchor constraintEqualToAnchor:self.contentView.topAnchor].active = YES;
    [self.view.heightAnchor constraintEqualToConstant:self.height].active = YES;
}

- (void)setBottomModeConstraints {
    [self.view.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor].active = YES;
    [self.view.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor].active = YES;
    [self.view.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor].active = YES;
    [self.view.heightAnchor constraintEqualToConstant:self.height].active = YES;
}

#pragma mark Private Methods

- (void)layoutContentView {
    CGFloat relativeYOffset = self.scrollView.contentOffset.y;
    CGRect frame = (CGRect){
        .origin.x       = 0,
        .origin.y       = -self.height,
        .size.width     = self.scrollView.frame.size.width,
        .size.height    = self.height
    };
    self.contentView.frame = frame;
    CGFloat div = self.height - self.minimumHeight;
    self.progress = (self.contentView.frame.size.height - self.minimumHeight) / (div? : self.height);
    self.yOffset = relativeYOffset;
}

- (void)adjustScrollViewTopInset:(CGFloat)top {
    UIEdgeInsets inset = self.scrollView.contentInset;
    
    //Adjust content offset
    CGPoint offset = self.scrollView.contentOffset;
    offset.y += inset.top - top;
    self.scrollView.contentOffset = offset;
    
    //Adjust content inset
    inset.top = top;
    self.scrollView.contentInset = inset;
}

#pragma mark KVO

//This is where the magic happens...
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if (context == kMXParallaxHeaderKVOContext) {
        if ([keyPath isEqualToString:NSStringFromSelector(@selector(contentOffset))]) {
            [self layoutContentView];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end

@implementation UIScrollView (MXParallaxHeader)

- (MXParallaxHeader *)parallaxHeader {
    MXParallaxHeader *parallaxHeader = objc_getAssociatedObject(self, @selector(parallaxHeader));
    if (!parallaxHeader) {
        parallaxHeader = [MXParallaxHeader new];
        [self setParallaxHeader:parallaxHeader];
    }
    return parallaxHeader;
}

- (void)setParallaxHeader:(MXParallaxHeader *)parallaxHeader {
    parallaxHeader.scrollView = self;
    objc_setAssociatedObject(self, @selector(parallaxHeader), parallaxHeader, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
