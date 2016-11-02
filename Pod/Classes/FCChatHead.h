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



#import <UIKit/UIKit.h>
#import "FCChatHeadsDelegate.h"
#import "FCCHConstants.h"


/**
 @brief The base class for view to be used as floating chat head.
 @discussion Instantiate this class and use for presenting through {@sa @b FCChatHeadsController}.
 */

@interface FCChatHead : UIView

/**
 @brief The label used to display badge count on chat head.
 @discussion Hidden at value @b 0 or less. Max value is @b 99. Shows @b 99+ for larger values.
 @discussion Set value using {@ref @b unreadCount}
 */
@property (nonatomic, readonly, strong) UILabel *badge;

/**
 @brief Image view for chat heads presented using images.
 @discussion Used when chat head is initialised with image. Image view is circular and content mode is UIViewContentModeScaleAspectFit.
 */
@property (nonatomic, strong, readonly) UIImageView *imageView;

/**
 @brief Delegate for handling chat head gestures.
 @discussion {@see FCChatHeadsDelegate}.
 */
@property (nonatomic, weak) id<FCChatHeadsDelegate> delegate;

/**
 @brief Unique identifier for chat head.
 @discussion Property to help identify the chat head.
 */
@property (nonatomic, strong) NSString *chatID;

/**
 @brief Hierarchy of chat head in chat head stack in collapsed state.
 */
@property (nonatomic, assign) NSUInteger hierarchyLevel;

/**
 @brief Indentation level of chat head in expanded state.
 */
@property (nonatomic, assign) NSUInteger indentationLevel;

/**
 @brief Boolean indicating whether chat head is being animated.
 @discussion Chat head may do some operations based on this e.g. hiding badge while animating.
 */
@property (nonatomic, assign) BOOL animating;

/**
 @brief Integer for displaying badge count on chat head.
 @discussion {@see @b badge}.
 */
@property (nonatomic, assign) NSInteger unreadCount;

/**
 @brief Initializer that returns a chat head with image.
 @param image The image to be used for chat head.
 @return an instance of circular chat head with image.
 */
+ (instancetype)chatHeadWithImage:(UIImage *)image;

/**
 @brief Initializer that returns a chat head with image.
 @param image The image to be used for chat head.
 @param delegate The delegate to handle chat head gestures.
 @return an instance of circular chat head with image and delegate.
 */
+ (instancetype)chatHeadWithImage:(UIImage *)image delegate:(id<FCChatHeadsDelegate>)delegate;

/**
 @brief Initializer that returns a chat head with image.
 @param image The image to be used for chat head.
 @param chatID Unique identifier for chat head.
 @param delegate The delegate to handle chat head gestures.
 @return an instance of circular chat head with image, identifier and delegate.
 */
+ (instancetype)chatHeadWithImage:(UIImage *)image chatID:(NSString *)chatID delegate:(id<FCChatHeadsDelegate>)delegate;

/**
 @brief Initializer that returns a chat head with image.
 @param view The view to be used for chat head. The view does not need to be circular. view will be used as it is for chat head.
 @param chatID Unique identifier for chat head.
 @param delegate The delegate to handle chat head gestures.
 @return an instance of chat head with view, identifier and delegate.
 */
+ (instancetype)chatHeadWithView:(UIView *)view chatID:(NSString *)chatID delegate:(id<FCChatHeadsDelegate>)delegate;


@end





