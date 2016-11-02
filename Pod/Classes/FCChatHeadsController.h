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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FCChatHead.h"
#import "FCCHConstants.h"


@protocol FCChatHeadsControllerDatasource;
@protocol FCChatHeadsControllerDelegate;


/**
 @brief Singleton class for controlling the interaction and business logic of chat heads
 @discussion Singleton instance of this class should be used for presenting, dismissing and updating chat heads.
 */
@interface FCChatHeadsController : NSObject <FCChatHeadsDelegate>

/**
 @brief @b optional view to be used as container for chat heads
 @discussion By default system uses the main window of applicaiton as container for chat heads. 
        Host app may provide a different window for containing chat heads. Some custom window subclass or even a view.
 */
@property (nonatomic, strong) UIView *headSuperView;

/**
 @brief datasource for chat heads controller
 @discussion {@see FCChatHeadsControllerDatasource}
 */
@property (nonatomic, weak) id<FCChatHeadsControllerDatasource> datasource;

/**
 @brief delegate for chat heads controller
 @discussion {@see FCChatHeadsControllerDelegate}
 */
@property (nonatomic, weak) id<FCChatHeadsControllerDelegate> delegate;

/**
 @brief @b readonly boolean denoting whether all chat heads have been hidden
 */
@property (nonatomic, assign, readonly) BOOL allChatHeadsHidden;


/**
 @brief method for accessing default chat heads controller instance
 */
+ (instancetype)chatHeadsController;

/**
 @brief method for presenting chat head with image
 @param image The image to be used for chat head.
 @param chatID Unique identifier for chat head.
 */
- (void)presentChatHeadWithImage:(UIImage *)image chatID:(NSString *)chatID;

/**
 @brief method for presenting chat head with view
 @param view The view to be used for chat head. The view does not need to be circular. view will be used as it is for chat head.
 @param chatID Unique identifier for chat head.
 */
- (void)presentChatHeadWithView:(UIView *)view chatID:(NSString *)chatID;

/**
 @brief method for presenting multiple chat heads at once
 @param chatHeads array containing instances of @b FCChatHead
 @param animated param indicating whether the presentation should be animated
 */
- (void)presentChatHeads:(NSArray *)chatHeads animated:(BOOL)animated;

/**
 @brief method to hide all chat heads without animation.
 @param hidden boolean to indicate whether to hide chat heads or show.
 @discussion Hidind chat heads will remove the chatheads from screen but will not clear the stack.
    To present them again, use this method with false boolean value. If you wish to dismiss the chatheads use @b dismissAllChatHeads:
    Dismissing all chatheads also clears the chat heads stack from memory.
 */
- (void)setChatHeadsHidden:(BOOL)hidden;

/**
 @brief method to programmatically collapse all chat heads and arrange them in a stack at their last known location i.e. the location at which they were before they expanded.
 */
- (void)collapseChatHeads;

/**
 @brief method to programmatically expand all chat heads.
 @param chatID unique identifier for chat head that should be selected after chat heads expand.
 */
- (void)expandChatHeadsWithActiveChatID:(NSString *)chatID;


/**
 @brief method to set badge count on chat head with given unique identifier
 @param chatID unique identifier for chat head
 @param unreadCount value for badge count or unread count
 */
- (void)setUnreadCount:(NSInteger)unreadCount forChatHeadWithChatID:(NSString *)chatID;


/**
 @brief method to dismiss all chat heads
 @param animated param indicating whether the dismissal should be animated
 */
- (void)dismissAllChatHeads:(BOOL)animated;

@end



/**
 @brief protocol for datasource of chat heads controller
 */
@protocol FCChatHeadsControllerDatasource <NSObject>

@optional

/**
 @brief method to return view to be presented in popover when a chat head is selected
 @param chatHeadsController instance of FCChatHeadsController
 @param chatID unique identifier for chat head
 @return an instance of UIView to be presented inside popover
 */
- (UIView *)chatHeadsController:(FCChatHeadsController *)chatHeadsController viewForPopoverForChatHeadWithChatID:(NSString *)chatID;

@end


/**
 @brief protocol for delegate of chat heads controller
 */
@protocol FCChatHeadsControllerDelegate <NSObject>

/**
 @brief called after chat heads controller has presented popover for selected chat head
 @param chatHeadsController instance of FCChatHeadsController
 */
- (void)chatHeadsControllerDidDisplayChatView:(FCChatHeadsController *)chatHeadsController;

/**
 @brief called before popover for chat head is dismissed
 @param chController instance of FCChatHeadsController
 @param chatID unique identifier for chat head
 */
- (void)chatHeadsController:(FCChatHeadsController *)chController willDismissPopoverForChatID:(NSString *)chatID;

/**
 @brief called after popover for chat head is dismissed
 @param chController instance of FCChatHeadsController
 @param chatID unique identifier for chat head
 */
- (void)chatHeadsController:(FCChatHeadsController *)chController didDismissPopoverForChatID:(NSString *)chatID;

/**
 @brief called after a chat head has been dismissed or removed by user action i.e. by dragging to the bottom of screen 
 @param chController instance of FCChatHeadsController
 @param chatID unique identifier for chat head
 */
- (void)chatHeadsController:(FCChatHeadsController *)chController didRemoveChatHeadWithChatID:(NSString *)chatID;

@end