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

#import "FCChatHeadsController.h"
#import "FCChatHead.h"
#import <CMPopTipView/CMPopTipView.h>
#import <pop/POP.h>
#import "FCPopOverView.h"
#import "FCSinkView.h"


static FCChatHeadsController *_chatHeadsController;

@interface FCChatHeadsController() <CMPopTipViewDelegate>
{
    CGRect _activeChatHeadFrameInStack;
    CGRect _sinkCrossPeriphery;
}

@property (nonatomic, assign) BOOL isExpanded;

@property (nonatomic, weak) FCChatHead *activeChatHead;

@property (nonatomic, strong) NSMutableArray *chatHeads;
@property (nonatomic, strong) NSTimer *showChatHeadSinkTimer;

@property (nonatomic, strong) FCSinkView *sinkView;

@property (nonatomic, strong) FCPopOverView *popoverView;

@property (nonatomic, strong) UIView *backgroundView;

@property (nonatomic, strong) UIImageView *sinkCross;

@property (nonatomic, assign) BOOL allChatHeadsHidden;

@property (nonatomic, assign) BOOL chatHeadsMoving;

@property (nonatomic, strong) NSMutableArray *pendingChatHeads;

@property (nonatomic, assign) BOOL chatHeadsTransitioning;

@end






@implementation FCChatHeadsController


+ (instancetype)chatHeadsController
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _chatHeadsController = [FCChatHeadsController new];
    });
    
    return _chatHeadsController;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [self setup];
    }
    return self;
}

- (void)setup
{
    self.activeChatHead = nil;
    self.isExpanded = NO;
    self.chatHeads = [NSMutableArray array];
    _activeChatHeadFrameInStack = DEFAULT_CHAT_HEAD_FRAME;
    self.chatHeadsMoving = NO;
}

#pragma mark -
#pragma mark - Chatheads manipulation

- (void)presentChatHeadWithView:(UIView *)view chatID:(NSString *)chatID
{
    FCChatHead *aChatHead = [FCChatHead chatHeadWithView:view chatID:chatID delegate:self];
    aChatHead.frame = [self frameForNewChatHead];
    aChatHead.chatID = chatID;
    [self presentChatHead:aChatHead animated:YES];
}

- (void)presentChatHeadWithImage:(UIImage *)image chatID:(NSString *)chatID
{
    FCChatHead *aChatHead = [FCChatHead chatHeadWithImage:image chatID:chatID delegate:self];
    aChatHead.frame = [self frameForNewChatHead];
    aChatHead.chatID = chatID;
    
    [self presentChatHead:aChatHead animated:YES];
}

- (void)presentChatHeads:(NSArray *)chatHeads animated:(BOOL)animated
{
    for (NSInteger count = chatHeads.count - 1; count >= 0; count--)
    {
        FCChatHead *chatHead = (FCChatHead *)chatHeads[count];
        
        CGRect frame = [self frameForNewChatHead];
        frame.origin.x += count*(CHAT_HEAD_STACK_STEP_X);
        frame.origin.y += count*(CHAT_HEAD_STACK_STEP_Y);
        
        chatHead.frame = frame;
        
        [self presentChatHead:chatHead animated:animated];
        
        if (animated)
        {
            chatHead.transform = CGAffineTransformMakeScale(0.1, 0.1);
        }
    }
    
    if (animated && chatHeads.count)
    {
        for (FCChatHead *chatHead in chatHeads)
        {
            [self animateChatHeadPresentation:chatHead];
        }
    }
}

- (void)presentChatHead:(FCChatHead *)aChatHead animated:(BOOL)animated
{
    if (self.chatHeadsMoving)
    {
        [self.pendingChatHeads addObject:aChatHead];
        return;
    }
    
    if ([self bringChatHeadToFrontIfAlreadyPresent:aChatHead.chatID animated:animated])
        return;
    
    if (!self.headSuperView)
    {
        UIView *rootView = [[[UIApplication sharedApplication] delegate] window];
        self.headSuperView = rootView;
    }
    
    [self setIndentationLevelsForNewChatHead:aChatHead];
    
    if (self.chatHeads.count == MAX_NUMBER_OF_CHAT_HEADS)
    {
        [self addRemovalAnimationForChatHead:[self chatHeadToBeRemoved]];
    }
    
    if (!self.isExpanded)
    {
        [self.chatHeads addObject:aChatHead];
        [self setIndentationAndHierarchyLevels];
        
        if (animated)
        {
            aChatHead.animating = YES;
            aChatHead.transform = CGAffineTransformMakeScale(0.1, 0.1);
        }
        
        [self.headSuperView addSubview:aChatHead];
        [self.headSuperView bringSubviewToFront:aChatHead];
        
        self.activeChatHead = aChatHead;
    }
    else
    {
        BOOL firstChatHead = self.chatHeads.count == 0;
        
        [self.chatHeads insertObject:aChatHead atIndex:firstChatHead ? 0 : self.chatHeads.count - 1];
        [self layoutChatHeads:YES];
        
        if (animated)
        {
            aChatHead.animating = YES;
            aChatHead.transform = CGAffineTransformMakeScale(0.1, 0.1);
        }
        
        [self.headSuperView addSubview:aChatHead];
        [self.headSuperView bringSubviewToFront:self.activeChatHead];
        
        if (firstChatHead)
            self.activeChatHead = aChatHead;
    }
    
//    [self logChatHeadsStack];
    
    if (animated)
    {
        [self animateChatHeadPresentation:aChatHead];
    }
}

- (void)logChatHeadsStack
{
#if DEBUG
    NSLog(@"=====================================================================================\n\n");
    for (int count = 0; count < self.chatHeads.count; count++)
    {
        NSLog(@"index = %d, chat head ID = %@", count, [self.chatHeads[count] chatID]);
    }
    NSLog(@"\n=====================================================================================\n\n");
#endif
}

- (void)setIndentationLevelsForNewChatHead:(FCChatHead *)chatHead
{
    if (self.isExpanded)
    {
        if (self.chatHeads.count < MAX_NUMBER_OF_CHAT_HEADS)
        {
            chatHead.indentationLevel = [self maxIndentationLevel] + (self.chatHeads.count > 0)*1;
        }
        else
        {
            FCChatHead *chatHeadToBeRemoved = [self chatHeadToBeRemoved];
            
            if (chatHeadToBeRemoved.indentationLevel > self.activeChatHead.indentationLevel)
            {
                chatHead.indentationLevel = self.activeChatHead.indentationLevel + 1;
                for (FCChatHead *aChatHead in self.chatHeads)
                {
                    if ((chatHead == aChatHead) || (self.activeChatHead == aChatHead) || (chatHeadToBeRemoved == aChatHead)) continue;
                    
                    if ((aChatHead.indentationLevel < chatHeadToBeRemoved.indentationLevel) && (aChatHead.indentationLevel > self.activeChatHead.indentationLevel))
                        aChatHead.indentationLevel = aChatHead.indentationLevel + 1;
                }
            }
            else
            {
                chatHead.indentationLevel = self.activeChatHead.indentationLevel - 1;
                for (FCChatHead *aChatHead in self.chatHeads)
                {
                    if ((chatHead == aChatHead) || (self.activeChatHead == aChatHead) || (chatHeadToBeRemoved == aChatHead)) continue;
                    
                    if ((aChatHead.indentationLevel > chatHeadToBeRemoved.indentationLevel) && (aChatHead.indentationLevel < self.activeChatHead.indentationLevel))
                        aChatHead.indentationLevel = aChatHead.indentationLevel - 1;
                }
            }
        }
    }
}

- (NSUInteger)maxIndentationLevel
{
    NSUInteger indentationLevel = 1;
    
    FCChatHead *chatHeadWithMaxIndentation = [self chatHeadWithMaxIndentation];
    if (chatHeadWithMaxIndentation)
    {
        indentationLevel = chatHeadWithMaxIndentation.indentationLevel;
    }
    
    return indentationLevel;
}

- (FCChatHead *)chatHeadToBeRemoved
{
    return self.chatHeads.count >= MAX_NUMBER_OF_CHAT_HEADS ? self.chatHeads[0] : nil;
}

- (FCChatHead *)chatHeadWithMaxIndentation
{
    FCChatHead *chatHead = nil;
    
    NSPredicate *maxIndentationPredicate = [NSPredicate predicateWithFormat:@"SELF.indentationLevel == %@.@max.indentationLevel", self.chatHeads];
    NSArray *resutArray = [self.chatHeads filteredArrayUsingPredicate:maxIndentationPredicate];
    if (resutArray.count)
    {
        chatHead = (FCChatHead *)resutArray[0];
    }
    
    return chatHead;
}

- (FCChatHead *)chatHeadWithIndentation:(NSUInteger)indentationLevel
{
    FCChatHead *chatHead = nil;
    
    NSPredicate *indentationPredicate = [NSPredicate predicateWithFormat:@"SELF.indentationLevel == %d", indentationLevel];
    NSArray *resutArray = [self.chatHeads filteredArrayUsingPredicate:indentationPredicate];
    if (resutArray.count)
    {
        chatHead = (FCChatHead *)resutArray[0];
    }
    
    return chatHead;
}

- (CGRect)frameForNewChatHead
{
    CGRect frame = DEFAULT_CHAT_HEAD_FRAME;
    
    if (!self.isExpanded)
    {
        frame = _activeChatHeadFrameInStack;
    }
    else
    {
        if (self.chatHeads.count < MAX_NUMBER_OF_CHAT_HEADS)
        {
            frame.origin.x = self.headSuperView.bounds.size.width - ((self.chatHeads.count + 1)*(CHAT_HEAD_DIMENSION + CHAT_HEAD_MARGIN_X));
            frame.origin.y = CHAT_HEAD_MARGIN_Y;
        }
        else
        {
            FCChatHead *chatHeadToBeRemoved = [self chatHeadToBeRemoved];
            frame = chatHeadToBeRemoved.frame;
            if (chatHeadToBeRemoved.indentationLevel > self.activeChatHead.indentationLevel)
            {
                frame.origin.x = self.headSuperView.bounds.size.width - ((self.activeChatHead.indentationLevel + 1)*(CHAT_HEAD_DIMENSION + CHAT_HEAD_MARGIN_X));
                frame.origin.y = CHAT_HEAD_MARGIN_Y;
            }
            else
            {
                frame.origin.x = self.headSuperView.bounds.size.width - ((self.activeChatHead.indentationLevel - 1)*(CHAT_HEAD_DIMENSION + CHAT_HEAD_MARGIN_X));
                frame.origin.y = CHAT_HEAD_MARGIN_Y;
            }
        }
    }
    return frame;
}

- (BOOL)bringChatHeadToFrontIfAlreadyPresent:(NSString *)chatID animated:(BOOL)animated
{
    BOOL success = NO;
    FCChatHead *chatHead = [self chatHeadWithID:chatID];
    if (chatHead)
    {
        success = YES;
        
        if (!chatHead.animating)
        {
            [self bringChatHeadToTop:chatHead animated:animated];
        }
    }
    return success;
}


- (void)bringChatHeadToTop:(FCChatHead *)chatHead animated:(BOOL)animated
{
    if (!self.isExpanded)
    {
        self.activeChatHead = chatHead;
        chatHead.frame = [(FCChatHead *)[self.chatHeads lastObject] frame];
        [self.chatHeads removeObject:chatHead];
        [self.chatHeads addObject:chatHead];
    }
    else
    {
        if (chatHead != self.activeChatHead)
        {
            NSUInteger index = self.chatHeads.count == 0 ? 0 : [self.chatHeads indexOfObject:self.activeChatHead] - 1;
            [self.chatHeads removeObject:chatHead];
            [self.chatHeads insertObject:chatHead atIndex:index];
        }
    }
    
    [self layoutChatHeads:YES];
    
    if (animated)
    {
        chatHead.animating = YES;
        chatHead.transform = CGAffineTransformMakeScale(0.5, 0.5);
    }
    
    [self.headSuperView bringSubviewToFront:chatHead];
    
    if (animated)
    {
        [self animateChatHeadPresentation:chatHead];
    }
    
//    [self logChatHeadsStack];
}


- (BOOL)chatHeadAlreadyPresent:(NSString *)chatID
{
    FCChatHead *chatHead = [self chatHeadWithID:chatID];
    return chatHead != nil;
}


- (FCChatHead *)chatHeadWithID:(NSString *)chatID
{
    FCChatHead *result = nil;
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.chatID LIKE[c] %@", chatID];
    NSArray *resultArray = [self.chatHeads filteredArrayUsingPredicate:predicate];
    if (resultArray.count)
    {
        result = [resultArray firstObject];
    }
    return result;
}


- (void)setIndentationAndHierarchyLevels
{
    if (!self.isExpanded)
    {
        NSUInteger indentationLevel = 1;
        for (NSInteger count = self.chatHeads.count - 1; count >= 0; count--)
        {
            FCChatHead *chatHead = (FCChatHead *)self.chatHeads[count];
            
            chatHead.hierarchyLevel = self.chatHeads.count - 1 - count;
            chatHead.indentationLevel = indentationLevel++;
        }
    }
}


- (void)layoutChatHeads:(BOOL)animated completion:(void(^)(BOOL finished))completion
{
    if (!self.isExpanded)
    {
        CGRect frame;
        
        if (CGRectEqualToRect(_activeChatHeadFrameInStack, CGRectZero))
        {
            frame = [(FCChatHead *)[self.chatHeads lastObject] frame];
        }
        else
        {
            frame = _activeChatHeadFrameInStack;
        }
        
        NSUInteger indentationLevel = 1;
        for (NSInteger count = self.chatHeads.count - 1; count >= 0; count--)
        {
            FCChatHead *chatHead = (FCChatHead *)self.chatHeads[count];
            
            chatHead.hierarchyLevel = self.chatHeads.count - 1 - count;
            chatHead.indentationLevel = indentationLevel++;
            
            if (animated)
            {
                [UIView animateWithDuration:0.357f
                                 animations:^{
                                     [chatHead setFrame:frame];
                                 }
                                 completion:^(BOOL finished) {
                                     
                                     if ((count == 0) && completion)
                                     {
                                         completion(finished);
                                     }
                                 }];
            }
            else
                [chatHead setFrame:frame];
            
            frame.origin.x += CHAT_HEAD_STACK_STEP_X;
            frame.origin.y += CHAT_HEAD_STACK_STEP_Y;
        }
        
        if (!animated && completion)
        {
            completion(YES);
        }
    }
    else
    {
        CGRect frame = DEFAULT_CHAT_HEAD_FRAME;
        frame.origin.y = CHAT_HEAD_MARGIN_Y;
        
        NSInteger count = self.chatHeads.count - 1;
        
        for (FCChatHead *chatHead in self.chatHeads)
        {
            chatHead.hierarchyLevel = 0;
            
            frame.origin.x = self.headSuperView.bounds.size.width - (chatHead.indentationLevel*(CHAT_HEAD_MARGIN_X + CHAT_HEAD_DIMENSION));
            
            if (animated)
            {
                [UIView animateWithDuration:0.357f
                                 animations:^{
                                     [chatHead setFrame:frame];
                                 }
                                 completion:^(BOOL finished) {
                                     
                                     if (!self.popoverView)
                                     {
                                         [self presentPopover];
                                     }
                                     
                                     if ((count == 0) && completion)
                                     {
                                         completion(finished);
                                     }
                                 }];
            }
            else
                [chatHead setFrame:frame];
            
            count--;
        }
        
        if (!animated && completion)
        {
            completion(YES);
        }
    }
}


- (void)layoutChatHeads:(BOOL)animated
{
    [self layoutChatHeads:animated completion:nil];
}


- (void)animateChatHeadPresentation:(FCChatHead *)aChatHead
{
    aChatHead.animating = YES;
    
    [UIView animateWithDuration:0.357
                          delay:0
         usingSpringWithDamping:0.5
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         
                         aChatHead.transform = CGAffineTransformIdentity;
                     }
                     completion:^(BOOL finished) {
                         
                         [aChatHead setNeedsLayout];
                         if (finished)
                         {
                             aChatHead.animating = NO;
                             if (!self.isExpanded)
                             {
                                 [self layoutChatHeads:YES];
                             }
                         }
                     }];
}


- (void)finishPanEndMotionWithVelocity:(CGPoint)panEndVelocity forChatHead:(FCChatHead *)chatHead
{
    NSArray *chatHeadsToAnimate = self.isExpanded ? @[chatHead] : self.chatHeads;
    
    BOOL removeChatHead;
    CGPoint proposedEndPoint = [self proposedPanMotionEndPointForChatHead:chatHead
                                                             withVelocity:panEndVelocity
                                                              shoudRemove:&removeChatHead];
    if (self.isExpanded)
    {
        if (removeChatHead)
        {
            NSUInteger activeIndentation = chatHead.indentationLevel;
            for (FCChatHead *aChatHead in self.chatHeads)
            {
                if (aChatHead.indentationLevel > activeIndentation)
                {
                    aChatHead.indentationLevel--;
                }
            }
            if (self.chatHeads.count == 1)
            {
                [self removeBackgroundView:YES];
            }
        }
        else
        {
            NSUInteger finalIndentation = (SCREEN_BOUNDS.size.width - chatHead.center.x)/(CHAT_HEAD_DIMENSION + CHAT_HEAD_MARGIN_X) + 1;
            finalIndentation = MIN(self.chatHeads.count, finalIndentation);
            finalIndentation = MAX(finalIndentation, 1);
            proposedEndPoint.x = SCREEN_BOUNDS.size.width - finalIndentation*(CHAT_HEAD_DIMENSION + CHAT_HEAD_MARGIN_X) + CHAT_HEAD_DIMENSION/2;
            proposedEndPoint.y = CHAT_HEAD_MARGIN_Y + CHAT_HEAD_DIMENSION/2;
        }
    }
    
    for (NSInteger count = chatHeadsToAnimate.count - 1; count >= 0; count--)
    {
        POPSpringAnimation *positionAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerPosition];
        positionAnimation.velocity = [NSValue valueWithCGPoint:panEndVelocity];
        positionAnimation.dynamicsTension = 10000.0;
        positionAnimation.name = @"fc.chathead.motionEnd";
        positionAnimation.dynamicsFriction = 1.0f;
        positionAnimation.springBounciness = 12.5f;
        positionAnimation.springSpeed = 20.0;
        positionAnimation.toValue = [NSValue valueWithCGPoint:CGPointMake(proposedEndPoint.x, proposedEndPoint.y)];
        
        proposedEndPoint.x += (!removeChatHead)*CHAT_HEAD_STACK_STEP_X;
        proposedEndPoint.y += (!removeChatHead)*CHAT_HEAD_STACK_STEP_Y;
        
        FCChatHead *aChatHead = (FCChatHead *)chatHeadsToAnimate[count];
        
        if (removeChatHead)
        {
            positionAnimation.springBounciness = 5.0;
            positionAnimation.completionBlock = ^(POPAnimation *anim, BOOL finished) {
                [self addRemovalAnimationForChatHead:aChatHead];
                
                [self removeSink:YES];
            };
        }
        else
        {
            positionAnimation.completionBlock = ^(POPAnimation *anim, BOOL finished) {
                
                if (self.isExpanded)
                {
                    if (!self.popoverView)
                    {
                        [self presentPopover];
                    }
                }
                else
                {
                    _activeChatHeadFrameInStack = self.activeChatHead.frame;
                }
                
                self.chatHeadsMoving = NO;
            };
            
            [self removeSink:YES];
        }
        
        [[aChatHead layer] pop_addAnimation:positionAnimation forKey:@"fc.chathead.motionEnd"];
    }
}

- (CGPoint)proposedPanMotionEndPointForChatHead:(FCChatHead *)chatHead
                                   withVelocity:(CGPoint)panEndVelocity
                                    shoudRemove:(BOOL *)removeChatHead
{
    HorizontalMotionDirection horizontalDirection = panEndVelocity.x < 0 ? kDirectionLeft : kDirectionRight;
    VerticalMotionDirection verticalDirection = panEndVelocity.y < 0 ? kDirectionUp : kDirectionDown;
    
    CGPoint initialPosition = chatHead.center;
    CGRect superBounds = chatHead.superview.bounds;
    
    double minX = CHAT_HEAD_DIMENSION/2 + CHAT_HEAD_MARGIN_X;
    double maxX = superBounds.size.width - CHAT_HEAD_MARGIN_X - CHAT_HEAD_DIMENSION/2;
    double minY = CHAT_HEAD_DIMENSION/2 + CHAT_HEAD_MARGIN_Y;
    double maxY = superBounds.size.height - CHAT_HEAD_MARGIN_Y - CHAT_HEAD_DIMENSION/2;
    
    double proposedTimeForCompletion = fabs(panEndVelocity.x)/CHAT_HEAD_DECELERATION_X;
    
    double proposedFinalX = panEndVelocity.x*proposedTimeForCompletion - 0.5*horizontalDirection*CHAT_HEAD_DECELERATION_X*pow(proposedTimeForCompletion, 2.0) + initialPosition.x;
    double proposedFinalY = panEndVelocity.y*proposedTimeForCompletion - 0.5*verticalDirection*CHAT_HEAD_DECELERATION_Y*pow(proposedTimeForCompletion, 2.0) + initialPosition.y;
    
    
    BOOL shouldRemoveChatHead = NO;
    if (self.sinkView.superview)
    {
        if ((proposedFinalY > (SCREEN_BOUNDS.size.height - CHAT_HEAD_SINK_HEIGHT)) && FCRayIntersectsWithRect(FCRayCreate(initialPosition, CGPointMake(proposedFinalX, proposedFinalY)), CHAT_HEAD_SINK_ZONE))
        {
            shouldRemoveChatHead = YES;
            proposedFinalY = self.sinkView.center.y;
            proposedFinalX = self.sinkView.center.x;
            *removeChatHead = shouldRemoveChatHead;
            
            CGPoint proposedEndPoint = CGPointMake(proposedFinalX, proposedFinalY);
            
            return proposedEndPoint;
        }
    }
    
    if (proposedFinalX < superBounds.size.width/2)
    {
        if (proposedFinalX <= minX)
        {
            double velocityAtMinX = -pow(pow(panEndVelocity.x, 2.0) - 2*CHAT_HEAD_DECELERATION_X*(initialPosition.x - minX), 0.5);
            
            double timeTakenToMinX = fabs(velocityAtMinX - panEndVelocity.x)/CHAT_HEAD_DECELERATION_X;
            double yAtMinX = panEndVelocity.y*timeTakenToMinX - 0.5*(CHAT_HEAD_DECELERATION_Y*pow(timeTakenToMinX, 2.0)) + initialPosition.y;
            proposedFinalY = yAtMinX;
        }
        proposedFinalX = minX;
    }
    else
    {
        if (proposedFinalX >= maxX)
        {
            double velocityAtMaxX = pow(pow(panEndVelocity.x, 2.0) - 2*CHAT_HEAD_DECELERATION_X*(maxX - initialPosition.x), 0.5);
            double timeTakenToMaxX = fabs(velocityAtMaxX - panEndVelocity.x)/CHAT_HEAD_DECELERATION_X;
            double yAtMaxX = panEndVelocity.y*timeTakenToMaxX - 0.5*(CHAT_HEAD_DECELERATION_Y*pow(timeTakenToMaxX, 2.0)) + initialPosition.y;
            proposedFinalY = yAtMaxX;
        }
        proposedFinalX = maxX;
    }
    
    if (proposedFinalY < minY)
        proposedFinalY = minY;
    
    if (proposedFinalY > maxY)
        proposedFinalY = maxY;
    
    *removeChatHead = shouldRemoveChatHead;
    
    CGPoint proposedEndPoint = CGPointMake(proposedFinalX, proposedFinalY);
    
    return proposedEndPoint;
}

- (void)addRemovalAnimationForChatHead:(FCChatHead *)chatHead
{
    chatHead.transform = CGAffineTransformIdentity;
    [UIView animateWithDuration:0.246
                     animations:^{
                         chatHead.transform = CGAffineTransformMakeScale(0.1, 0.1);
                     }
                     completion:^(BOOL finished) {
                         [self removeChatHead:chatHead];
                         self.chatHeadsMoving = NO;
                     }];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatHeadsController:didRemoveChatHeadWithChatID:)]) {
        [self.delegate chatHeadsController:self didRemoveChatHeadWithChatID:chatHead.chatID];
    }
    
    [self.chatHeads removeObject:chatHead];
}

- (void)removeChatHead:(FCChatHead *)chatHead
{
    BOOL wasActive = self.activeChatHead == chatHead;
    [chatHead removeFromSuperview];
    if (self.isExpanded)
    {
        [self layoutChatHeads:YES];
        
        if (wasActive)
        {
            self.activeChatHead = nil;
            FCChatHead *chatHead = [self.chatHeads lastObject];
            if (chatHead)
            {
                self.activeChatHead = chatHead;
            }
        }
        if (self.chatHeads.count == 0)
        {
            self.isExpanded = NO;
        }
    }
    else
    {
        self.activeChatHead = nil;
    }
    
//    [self logChatHeadsStack];
}

- (void)handleTapOnChatHead:(FCChatHead *)chatHead
{
    if (self.chatHeadsTransitioning)
    {
        return;
    }
    
    if (!self.isExpanded)
    {
        self.chatHeadsTransitioning = YES;
        
        [self insertBackgroundView:YES];
        
        self.isExpanded = YES;
        _activeChatHeadFrameInStack = self.activeChatHead.frame;
        
        [self layoutChatHeads:YES completion:^(BOOL finished) {
            
            [NSTimer scheduledTimerWithTimeInterval:0.2
                                             target:self
                                           selector:@selector(resetTransitioning:)
                                           userInfo:nil
                                            repeats:NO];
        }];
    }
    else
    {
        if (chatHead == self.activeChatHead)
        {
            self.chatHeadsTransitioning = YES;
            
            [self removeBackgroundView:YES];
            
            self.isExpanded = NO;
            
            [self layoutChatHeads:YES completion:^(BOOL finished) {
                
                [NSTimer scheduledTimerWithTimeInterval:0.2
                                                 target:self
                                               selector:@selector(resetTransitioning:)
                                               userInfo:nil
                                                repeats:NO];
            }];
            
            [self dismissPopover];
        }
        else
        {
            self.activeChatHead = chatHead;
            
            [self.headSuperView bringSubviewToFront:self.activeChatHead];
            [self.chatHeads removeObject:chatHead];
            [self.chatHeads addObject:chatHead];
            
            [self presentPopover];
        }
    }
//    [self logChatHeadsStack];
}

- (void)handleTapOnBackground:(UITapGestureRecognizer *)tap
{
    if (self.chatHeadsTransitioning)
    {
        return;
    }
    
    if (self.activeChatHead == nil)
    {
        [self removeBackgroundView:YES];
        self.isExpanded = !self.isExpanded;
        [self dismissPopover];
    }
    else
        [self handleTapOnChatHead:self.activeChatHead];
}

- (void)insertBackgroundView:(BOOL)animated
{
    if (!self.headSuperView.subviews.count)
        return;
    
    if (!self.backgroundView)
    {
        self.backgroundView = [[UIView alloc] initWithFrame:self.headSuperView.bounds];
        self.backgroundView.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.8];
        
        UITapGestureRecognizer *tapOnBackground = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapOnBackground:)];
        [self.backgroundView addGestureRecognizer:tapOnBackground];
        
        if (animated)
        {
            self.backgroundView.alpha = 0.0;
        }
        
        FCChatHead *lowestChatHead = nil;
        for (NSInteger count = self.headSuperView.subviews.count - 1; count >= 0; count--)
        {
            UIView *subview = self.headSuperView.subviews[count];
            if ([subview isKindOfClass:[FCChatHead class]])
            {
                lowestChatHead = (FCChatHead *)subview;
            }
        }
        
        [self.headSuperView insertSubview:self.backgroundView belowSubview:lowestChatHead];
        
        if (animated)
        {
            [UIView animateWithDuration:0.257
                             animations:^{
                                 self.backgroundView.alpha = 1.0;
                             }
                             completion:^(BOOL finished) {
                                 
                             }];
        }
    }
}

- (void)removeBackgroundView:(BOOL)animated
{
    if (animated)
    {
        [UIView animateWithDuration:0.257
                         animations:^{
                             self.backgroundView.alpha = 0.0;
                         }
                         completion:^(BOOL finished) {
                             [self.backgroundView removeFromSuperview];
                             self.backgroundView = nil;
                         }];
    }
    else
    {
        [self.backgroundView removeFromSuperview];
        self.backgroundView = nil;
    }
}

- (void)presentPopover
{
    [self dismissPopover];
    
    CGRect frame = [[[[[UIApplication sharedApplication] delegate] window] screen] bounds];
    frame.size.height -= CGRectGetMaxY(self.activeChatHead.frame) + 8.0;
    
    UIView *contentView = nil;
    if (self.datasource && [self.datasource respondsToSelector:@selector(chatHeadsController:viewForPopoverForChatHeadWithChatID:)])
    {
        contentView = [self.datasource chatHeadsController:self viewForPopoverForChatHeadWithChatID:self.activeChatHead.chatID];
        contentView.frame = frame;
    }
    
    if (contentView)
    {
        self.popoverView = [[FCPopOverView alloc] initWithCustomView:contentView];
        
        self.popoverView.pointerSize = 8.0;
        self.popoverView.sidePadding = 0.0;
        self.popoverView.topMargin = 0.0;
        self.popoverView.cornerRadius = 0.0;
        self.popoverView.delegate = self;
        self.popoverView.backgroundColor = [UIColor whiteColor];
        self.popoverView.has3DStyle = NO;
        self.popoverView.animation = CMPopTipAnimationSlide;
        self.popoverView.hasGradientBackground = NO;
        self.popoverView.disableTapToDismiss = YES;
        self.popoverView.borderColor = [UIColor clearColor];
        self.popoverView.borderWidth = 0.0f;
        self.popoverView.preferredPointDirection = PointDirectionUp;
        [self.popoverView presentPointingAtView:self.activeChatHead inView:self.headSuperView animated:NO];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(chatHeadsControllerDidDisplayChatView:)])
        {
            [self.delegate chatHeadsControllerDidDisplayChatView:self];
        }
    }
}

- (void)dismissPopover
{
    if (self.popoverView)
    {
        if (self.delegate && [self.delegate respondsToSelector:@selector(chatHeadsController:willDismissPopoverForChatID:)])
        {
            [self.delegate chatHeadsController:self willDismissPopoverForChatID:self.activeChatHead.chatID];
        }
        
        [self.popoverView dismissAnimated:NO];
        self.popoverView = nil;
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(chatHeadsController:didDismissPopoverForChatID:)])
        {
            [self.delegate chatHeadsController:self didDismissPopoverForChatID:self.activeChatHead.chatID];
        }
    }
}

#pragma mark -
#pragma mark - FCChatHeadsDelegate


- (void)chatHeadSelected:(FCChatHead *)chatHead
{
    [self handleTapOnChatHead:chatHead];
}

- (void)chatHead:(FCChatHead *)chatHead didObservePan:(UIPanGestureRecognizer *)panGesture
{
    if (!self.isExpanded && chatHead != self.activeChatHead)
        return;
    
    switch (panGesture.state)
    {
        case UIGestureRecognizerStateBegan:
            [self startSinkTimer];
            
        case UIGestureRecognizerStateChanged:
        {
            self.chatHeadsMoving = YES;
            
            NSArray *chatHeadsToMove = nil;
            if (self.isExpanded)
            {
                [self.headSuperView bringSubviewToFront:chatHead];
                chatHeadsToMove = @[chatHead];
                [self updateChatHeadsLayoutForDraggingChatHead:chatHead toPosition:[panGesture locationInView:chatHead.superview]];
            }
            else
            {
                chatHeadsToMove = self.chatHeads;
            }
            [self moveChatHeadStack:chatHeadsToMove
                         toLocation:[panGesture locationInView:chatHead.superview]
                           animated:YES];
        }
            break;
            
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded:
        {
            [self stopSinkTimer];
            
            CGPoint velocity = [panGesture velocityInView:chatHead.superview];
            [self finishPanEndMotionWithVelocity:velocity forChatHead:chatHead];
        }
            break;
            
        default:
            break;
    }
}


- (void)updateChatHeadsLayoutForDraggingChatHead:(FCChatHead *)chatHead toPosition:(CGPoint)panPosition
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (chatHead == self.activeChatHead)
        {
            [self dismissPopover];
        }
    });
    
    NSUInteger currentIndentation = (SCREEN_BOUNDS.size.width - panPosition.x)/(CHAT_HEAD_DIMENSION + CHAT_HEAD_MARGIN_X) + 1;
    currentIndentation = MIN(self.chatHeads.count, currentIndentation);
    currentIndentation = MAX(currentIndentation, 1);
    
    if (currentIndentation > chatHead.indentationLevel)
    {
        FCChatHead *chatHeadToMove = [self chatHeadWithIndentation:currentIndentation];
        if (chatHeadToMove && (chatHeadToMove != chatHead))
        {
            if (chatHeadToMove == self.activeChatHead)
            {
                [self dismissPopover];
            }
            
            chatHead.indentationLevel = currentIndentation;
            
            chatHeadToMove.indentationLevel = currentIndentation - 1;
            CGRect frame = CHAT_HEAD_EXPANDED_FRAME(currentIndentation - 1);
            [UIView animateWithDuration:0.2f
                             animations:^{
                                 chatHeadToMove.frame = frame;
                             }];
        }
    }
    if (currentIndentation < chatHead.indentationLevel)
    {
        FCChatHead *chatHeadToMove = [self chatHeadWithIndentation:currentIndentation];
        if (chatHeadToMove && (chatHeadToMove != chatHead))
        {
            if (chatHeadToMove == self.activeChatHead)
            {
                [self dismissPopover];
            }
            
            chatHead.indentationLevel = currentIndentation;
            
            chatHeadToMove.indentationLevel = currentIndentation + 1;
            CGRect frame = CHAT_HEAD_EXPANDED_FRAME(currentIndentation + 1);
            [UIView animateWithDuration:0.2f
                             animations:^{
                                 chatHeadToMove.frame = frame;
                             }];
        }
    }
}

- (void)moveChatHeadStack:(NSArray *)chatHeadsToMove toLocation:(CGPoint)location animated:(BOOL)animated
{
    NSUInteger chatHeads = chatHeadsToMove.count;
    __block double delay = 0.0;
    __block double delayStep = 0.4;
    __block double duration = 0.1;
    
    __block CGPoint center = CGPointMake(location.x + (chatHeads - 1)*CHAT_HEAD_STACK_STEP_X, location.y + (chatHeads - 1)*CHAT_HEAD_STACK_STEP_Y);
    
    if (self.sinkView.superview && CGRectContainsPoint(CHAT_HEAD_SINK_ZONE, center))
    {
        center = CGPointMake(CGRectGetMidX(CHAT_HEAD_SINK_ZONE), CGRectGetMidY(CHAT_HEAD_SINK_ZONE));
    }
    
    [chatHeadsToMove enumerateObjectsWithOptions:NSEnumerationReverse
                                      usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                                          
                                          FCChatHead *chatHead = (FCChatHead *)obj;
                                          
                                          [UIView animateWithDuration:duration
                                                                delay:delay
                                               usingSpringWithDamping:0.7
                                                initialSpringVelocity:0.9
                                                              options:UIViewAnimationOptionBeginFromCurrentState
                                                           animations:^{
                                                               
                                                               chatHead.center = center;
                                                           }
                                                           completion:nil];
                                          
                                          center.x -= CHAT_HEAD_STACK_STEP_X;
                                          center.y -= CHAT_HEAD_STACK_STEP_Y;
                                          
                                          duration += delayStep;
                                      }];
}


#pragma mark -
#pragma mark - Timer Methods

- (void)stopSinkTimer
{
    if (self.showChatHeadSinkTimer)
    {
        [self.showChatHeadSinkTimer invalidate];
        self.showChatHeadSinkTimer = nil;
    }
}

- (void)startSinkTimer
{
    [self stopSinkTimer];
    
    self.showChatHeadSinkTimer = [NSTimer scheduledTimerWithTimeInterval:SHOW_CHAT_HEAD_SINK_TIMEOUT
                                                                  target:self
                                                                selector:@selector(showChatHeadSink:)
                                                                userInfo:nil
                                                                 repeats:NO];
}

- (void)showChatHeadSink:(NSTimer *)timer
{
    [self stopSinkTimer];
    [self showSink:YES];
}

- (void)resetTransitioning:(NSTimer *)timer
{
    self.chatHeadsTransitioning = NO;
}

#pragma mark -
#pragma mark - Sink methods

- (void)showSink:(BOOL)animated
{
    [self removeSink:NO];
    
    self.sinkView = [FCSinkView new];
    self.sinkView.frame = CGRectMake(self.headSuperView.bounds.origin.x,
                                     self.headSuperView.bounds.size.height - CHAT_HEAD_SINK_HEIGHT,
                                     self.headSuperView.bounds.size.width,
                                     CHAT_HEAD_SINK_HEIGHT);
    
    self.sinkView.backgroundColor = [UIColor clearColor];
    
    UIImage *sinkCrossImage = [UIImage imageNamed:@"FCChatHeads.bundle/dismiss"];
    self.sinkCross = [[UIImageView alloc] initWithImage:sinkCrossImage];
    CGRect sinkCrossFrame = CGRectMake(CGRectGetMinX(self.sinkView.frame) + (self.sinkView.frame.size.width - sinkCrossImage.size.width)/2,
                                       CGRectGetMinY(self.sinkView.frame) + (self.sinkView.frame.size.height - sinkCrossImage.size.height)/2,
                                       sinkCrossImage.size.width,
                                       sinkCrossImage.size.height);
    
    self.sinkCross.frame = sinkCrossFrame;
    
    _sinkCrossPeriphery = CGRectInset(sinkCrossFrame, -CGRectGetHeight(sinkCrossFrame)/2, -CGRectGetHeight(sinkCrossFrame)/2);
    
    if (animated)
    {
        self.sinkCross.alpha = 0.0;
        self.sinkView.alpha = 0.0;
    }
    
    [self.headSuperView addSubview:self.sinkView];
    [self.headSuperView addSubview:self.sinkCross];
    
    if (animated)
    {
        [UIView animateWithDuration:0.357
                         animations:^{
                             self.sinkView.alpha = 1.0;
                             self.sinkCross.alpha = 1.0;
                         }
                         completion:^(BOOL finished) {
                             
                         }];
    }
}

- (void)removeSink:(BOOL)animated
{
    [self.headSuperView bringSubviewToFront:self.sinkCross];
    if (animated)
    {
        [UIView animateWithDuration:0.375
                         animations:^{
                             self.sinkView.alpha = 0.0;
                             self.sinkCross.alpha = 0.5;
                             self.sinkCross.transform = CGAffineTransformMakeScale(0.1, 0.1);
                         }
                         completion:^(BOOL finished) {
                             [self.sinkCross removeFromSuperview];
                             self.sinkCross = nil;
                             [self.sinkView removeFromSuperview];
                             self.sinkView = nil;
                         }];
    }
    else
    {
        [self.sinkCross removeFromSuperview];
        self.sinkCross = nil;
        [self.sinkView removeFromSuperview];
        self.sinkView = nil;
    }
}

- (void)setActiveChatHead:(FCChatHead *)activeChatHead
{
    if (_activeChatHead != activeChatHead)
    {
        for (FCChatHead *chatHead in self.chatHeads)
        {
            if (chatHead == activeChatHead)
            {
                _activeChatHead = activeChatHead;
            }
        }
    }
}


- (void)setChatHeadsMoving:(BOOL)chatHeadsMoving
{
    if (_chatHeadsMoving != chatHeadsMoving)
    {
        _chatHeadsMoving = chatHeadsMoving;
        
        if (!_chatHeadsMoving)
        {
            if (self.pendingChatHeads.count)
            {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        [self presentChatHeads:self.pendingChatHeads animated:YES];
                    });
                });
            }
        }
    }
}


- (NSMutableArray *)pendingChatHeads
{
    if (!_pendingChatHeads)
    {
        _pendingChatHeads = [NSMutableArray array];
    }
    return _pendingChatHeads;
}


#pragma mark -
#pragma mark - CMPopTipViewDelegate

- (void)popTipViewWasDismissedByUser:(CMPopTipView *)popTipView
{
    self.popoverView = nil;
}

#pragma mark -
#pragma mark - MISC


- (BOOL)fcRay:(FCRay)ray intersectsWithRect:(CGRect)rect
{
    BOOL result = NO;
    
    CGPoint topLeft = rect.origin;
    CGPoint topRight = CGPointMake(topLeft.x + CGRectGetWidth(rect), topLeft.y);
    CGPoint bottomLeft = CGPointMake(topLeft.x, topLeft.y + CGRectGetHeight(rect));
    CGPoint bottomRight = CGPointMake(topLeft.x + CGRectGetWidth(rect), topLeft.y + CGRectGetHeight(rect));
    
    NSArray *points = @[[NSValue valueWithCGPoint:topLeft],
                        [NSValue valueWithCGPoint:topRight],
                        [NSValue valueWithCGPoint:bottomLeft],
                        [NSValue valueWithCGPoint:bottomRight]];
    
    PointPositionOnLine previousPosition = kPointPositionNone;
    for (NSValue *pointValue in points)
    {
        CGPoint point = [pointValue CGPointValue];
        int sign = signbit((ray.toPoint.x - ray.startPoint.x)*(point.y - ray.startPoint.y) - (ray.toPoint.y - ray.startPoint.y)*(point.x - ray.startPoint.x));
        PointPositionOnLine position = (sign == 0) ? kPointPositionPositive : kPointPositionNegative;
        
        if (previousPosition == kPointPositionNone)
            previousPosition = position;
        else if (previousPosition != position)
        {
            result = YES;
            break;
        }
    }
    
    return result;
}

#pragma mark -
#pragma mark - UI state

- (void)setChatHeadsHidden:(BOOL)hidden
{
    if (hidden) {
        [self hideAllChatHeads];
    } else {
        [self unhideAllChatHeads];
    }
}

- (void)hideAllChatHeads
{
    for (FCChatHead *chatHead in self.chatHeads)
    {
        [chatHead setHidden:YES];
    }

    self.allChatHeadsHidden = YES;
}

- (void)unhideAllChatHeads
{
    for (FCChatHead *chatHead in self.chatHeads)
    {
        [chatHead setHidden:NO];
    }

    self.allChatHeadsHidden = NO;
}

- (void)collapseChatHeads
{
    if (self.chatHeads.count == 0)
        return;
    
    if (self.isExpanded)
    {
        [self handleTapOnChatHead:self.activeChatHead];
    }
}

- (void)expandChatHeadsWithActiveChatID:(NSString *)chatID
{
    if (self.chatHeads.count == 0)
        return;
    
    if (!self.isExpanded)
    {
        FCChatHead *chatHeadToPresent = self.activeChatHead;
        if (chatID.length > 0)
        {
            FCChatHead *chatHead = [self chatHeadWithID:chatID];
            if (chatHead)
            {
                [self presentChatHead:chatHead animated:NO];
                chatHeadToPresent = chatHead;
            }
        }
        
        [self handleTapOnChatHead:chatHeadToPresent];
    }
}

- (void)setUnreadCount:(NSInteger)unreadCount forChatHeadWithChatID:(NSString *)chatID
{
    FCChatHead *chatHead = [self chatHeadWithID:chatID];
    [chatHead setUnreadCount:unreadCount];
}

- (void)dismissAllChatHeads:(BOOL)animated
{
    NSInteger index = self.chatHeads.count - 1;
    while (self.chatHeads.count)
    {
        FCChatHead *chatHead = self.chatHeads[index--];
        [self dismissChatheadWithID:chatHead.chatID animated:animated];
    }
}

- (void)dismissChatheadWithID:(NSString *)chatID animated:(BOOL)animated
{
    FCChatHead *chatHead = [self chatHeadWithID:chatID];
    
    if (self.isExpanded)
    {
        if (chatHead == self.activeChatHead)
            [self dismissPopover];
        
        NSUInteger activeIndentation = chatHead.indentationLevel;
        
        for (FCChatHead *aChatHead in self.chatHeads)
        {
            if (aChatHead.indentationLevel > activeIndentation)
            {
                aChatHead.indentationLevel--;
            }
        }
    }
    if (animated)
    {
        [self addRemovalAnimationForChatHead:chatHead];
    }
    else
    {
        [self removeChatHead:chatHead];
        [self.chatHeads removeObject:chatHead];
    }
}

@end









