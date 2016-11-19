//
//  Copyright 2014 Flipkart Internet Pvt Ltd
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.



#import "FCChatHead.h"
#import <pop/POP.h>

@interface FCChatHead () <POPAnimationDelegate>
{
    UIPanGestureRecognizer *_panGesture;
    BOOL _didPan;
}
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *badge;

@end

@implementation FCChatHead

// ---- Using corner radius to make round image right now.
// ---- Will move to a performance efficient method later.

+ (instancetype)chatHeadWithImage:(UIImage *)image
{
    CGRect frame = CGRectMake(0, 0, CHAT_HEAD_DIMENSION, CHAT_HEAD_DIMENSION);
    
    FCChatHead *aChatHead = [[FCChatHead alloc] initWithFrame:frame];
    aChatHead.imageView.image = image;
    
    return aChatHead;
}

+ (instancetype)chatHeadWithImage:(UIImage *)image delegate:(id<FCChatHeadsDelegate>)delegate
{
    FCChatHead *aChatHead = [FCChatHead chatHeadWithImage:image];
    aChatHead.delegate = delegate;
    
    return aChatHead;
}

+ (instancetype)chatHeadWithImage:(UIImage *)image chatID:(NSString *)chatID delegate:(id<FCChatHeadsDelegate>)delegate
{
    FCChatHead *aChatHead = [FCChatHead chatHeadWithImage:image delegate:delegate];
    aChatHead.chatID = chatID;
    
    return aChatHead;
}

+ (instancetype)chatHeadWithView:(UIView *)view chatID:(NSString *)chatID delegate:(id<FCChatHeadsDelegate>)delegate
{
    CGRect frame = CGRectMake(0, 0, CHAT_HEAD_DIMENSION, CHAT_HEAD_DIMENSION);
    
    FCChatHead *aChatHead = [[FCChatHead alloc] initWithFrame:frame];
    aChatHead.delegate = delegate;
    aChatHead.chatID = chatID;
    
    view.frame = frame;
    view.userInteractionEnabled = NO;
    [aChatHead addSubview:view];
    
    return aChatHead;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self setup];
    }
    return self;
}


- (void)setup
{
    self.backgroundColor = [UIColor clearColor];
    
    self.exclusiveTouch = YES;
    
    if (!_panGesture)
    {
        _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:_panGesture];
    }
}


- (UIImageView *)imageView
{
    if (!_imageView)
    {
        CGRect frame = CGRectInset(self.bounds, CHAT_HEAD_IMAGE_INSET, CHAT_HEAD_IMAGE_INSET);
        frame.origin = CGPointMake(CHAT_HEAD_IMAGE_INSET, CHAT_HEAD_IMAGE_INSET);
        
        _imageView = [[UIImageView alloc] initWithFrame:frame];
        _imageView.autoresizingMask = UIViewAutoresizingNone;
        
        double radius = CGRectGetHeight(frame)/2.0;
        
        _imageView.layer.cornerRadius = radius;
        _imageView.clipsToBounds = YES;
        
        [self addSubview:_imageView];
    }
    
    return _imageView;
}

- (UILabel *)badge
{
    if (!_badge)
    {
        CGRect frame = CGRectMake(self.frame.size.width - 15.0, 0.0, 15.0, 15.0);
        _badge = [UILabel new];
        _badge.frame = frame;
        _badge.layer.cornerRadius = 7.0;
        _badge.layer.masksToBounds = YES;
        _badge.backgroundColor = [UIColor colorWithRed:232.0/255.0 green:62.0/255.0 blue:50.0/255.0 alpha:1.0];
        _badge.textColor = [UIColor whiteColor];
        _badge.font = [UIFont boldSystemFontOfSize:11.0];
        _badge.textAlignment = NSTextAlignmentCenter;
        
        [self addSubview:_badge];
    }
    
    return _badge;
}


#pragma mark -
#pragma mark - Touch Event/Gesture handlers


- (void)handlePan:(UIPanGestureRecognizer *)pan
{
    if (pan != _panGesture)
        return;
#if DEBUG
    NSLog(@"%s", __func__);
#endif
    _didPan = YES;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatHead:didObservePan:)]) {
        [self.delegate chatHead:self didObservePan:pan];
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
#if DEBUG
    NSLog(@"%s", __func__);
#endif
    [super touchesBegan:touches withEvent:event];
    
    _didPan = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self highlightTouch];
        
    });
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self unhightlight];
        
    });
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self unhightlight];
        
    });
    
    if (!_didPan) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(chatHeadSelected:)]) {
            [self.delegate chatHeadSelected:self];
        }
    }
}

#pragma mark -
#pragma mark - View Layout


- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (self.animating)
    {
        self.badge.hidden = YES;
    }
    else
    {
        self.badge.hidden = (self.unreadCount == 0);
    }
    
    [self layoutBadge];
}

- (void)layoutBadge
{
    CGRect frame = [self.badge.text boundingRectWithSize:CGSizeMake(CHAT_HEAD_DIMENSION, CGFLOAT_MAX)
                                                 options:NSStringDrawingUsesLineFragmentOrigin
                                              attributes:@{NSFontAttributeName : self.badge.font}
                                                 context:nil];
    frame.origin = self.badge.frame.origin;
    frame.size.width = MAX(frame.size.width + 8, 15.0);
    frame.origin.x = self.frame.size.width - frame.size.width/2;
    self.badge.frame = frame;
}

#pragma mark -
#pragma mark - Misc

// Highlights the touch by giving some visual response to it.
- (void)highlightTouch
{
    // can write code here to update visual state of chat head when touches are received on it
}

- (void)unhightlight
{
    // can write code here to revert highlight changes
}

- (void)setUnreadCount:(NSInteger)unreadCount
{
    if (_unreadCount != unreadCount)
    {
        _unreadCount = unreadCount;
        
        if (_unreadCount == 0)
        {
            self.badge.hidden = YES;
        }
        else
        {
            self.badge.hidden = self.animating;
            
            NSString *text;
            if (unreadCount > 99)
            {
                text = @"99+";
            }
            else
            {
                text = [NSString stringWithFormat:@"%ld", (long)unreadCount];
            }
            
            self.badge.text = text;
            
            [self layoutBadge];
        }
    }
}

- (void)setHierarchyLevel:(NSUInteger)hierarchyLevel
{
    if (hierarchyLevel != _hierarchyLevel)
    {
        _hierarchyLevel = hierarchyLevel;
        
        [self setViewStateForHierarchyLevel:hierarchyLevel];
    }
}

- (void)setViewStateForHierarchyLevel:(NSUInteger)hierarchy
{
    // Can use this place to set different visual traits for chatheads with different hierarchy
    self.imageView.alpha = 1;
    self.backgroundColor = [UIColor clearColor];
    self.userInteractionEnabled = hierarchy == 0;
}

- (void)setIndentationLevel:(NSUInteger)indentationLevel
{
    if (indentationLevel != _indentationLevel)
    {
        if (indentationLevel < 1)
            _indentationLevel = 1;
        else if (indentationLevel > MAX_NUMBER_OF_CHAT_HEADS)
            _indentationLevel = MAX_NUMBER_OF_CHAT_HEADS;
        else
            _indentationLevel = indentationLevel;
    }
}












@end
