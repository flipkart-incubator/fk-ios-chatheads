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

/**
 @discussion Chat heads can take a lot of these parameters as input in future iterations.
 */

/**
 @brief dimension @a (height/width) of chat head
 @discussion dimension is fixed at @b 50 units for screen with width @b 320 units and scaled proportionally to other screen sizes.
        Max value is @b 65 units.
 */
#define CHAT_HEAD_DIMENSION             MIN((CGRectGetWidth([[UIScreen mainScreen] bounds])*(50.0/320.0)), 65.0)

/**
 @brief inset for image or view inside chat head.
 @discussion Think of this as the border width for chat head content. Not used right now.
 */
#define CHAT_HEAD_IMAGE_INSET           0.0

/**
 @brief deceleration/friction for chat head motion in horizontal direction.
 @discussion After user stops dragging and throws chat heads, this is the friction chat head faces in horizontal direction.
 */
#define CHAT_HEAD_DECELERATION_X        1200.0

/**
 @brief deceleration/friction for chat head motion in vertical direction.
 @discussion After user stops dragging and throws chat heads, this is the friction chat head faces in vertical direction.
 */
#define CHAT_HEAD_DECELERATION_Y        1200.0

/**
 @brief deceleration/friction vector for chat head motion.
 */
#define CHAT_HEAD_DECELERATION          {CHAT_HEAD_DECELERATION_X, CHAT_HEAD_DECELERATION_Y};

/**
 @brief horizontal margin inside window or super view of chat heads.
 */
#define CHAT_HEAD_MARGIN_X              15.0

/**
 @brief vertical margin inside window or super view of chat heads.
 */
#define CHAT_HEAD_MARGIN_Y              20.0



/**
 @brief horizontal motion direction enums.
 */
typedef enum {
    kDirectionLeft     = -1,
    kDirectionRight    =  1
} HorizontalMotionDirection;

/**
 @brief vertical motion direction enums.
 */
typedef enum {
    kDirectionUp     = -1,
    kDirectionDown   =  1
} VerticalMotionDirection;




/**
 @brief convenience method to access singleton instance of FCChatheadsController.
 */
#define ChatHeadsController         [FCChatHeadsController chatHeadsController]


/**
 @brief bounds of main device screen.
 */
#define SCREEN_BOUNDS                   ([[UIScreen mainScreen] bounds])

/**
 @brief default frame for new chat head.
 */
#define DEFAULT_CHAT_HEAD_FRAME         (CGRectMake(SCREEN_BOUNDS.size.width - CHAT_HEAD_DIMENSION - CHAT_HEAD_MARGIN_X,        \
                                                    SCREEN_BOUNDS.size.height - CHAT_HEAD_DIMENSION - 2.5*CHAT_HEAD_MARGIN_Y,   \
                                                    CHAT_HEAD_DIMENSION,                                                        \
                                                    CHAT_HEAD_DIMENSION))

/**
 @brief offset delta for chat heads on x axis.
 */
#define CHAT_HEAD_STACK_STEP_X          2.0

/**
 @brief offset delta for chat heads on y axis.
 */
#define CHAT_HEAD_STACK_STEP_Y          2.0


/**
 @brief time after which chat head sink should appear at the bottom of the screen.
 */
#define SHOW_CHAT_HEAD_SINK_TIMEOUT     0.5


/**
 @brief height of sink zone.
 */
#define CHAT_HEAD_SINK_HEIGHT           (SCREEN_BOUNDS.size.height*0.2)

/**
 @brief width of sink zone.
 */
#define CHAT_HEAD_SINK_WIDTH            (SCREEN_BOUNDS.size.width*0.8)

/**
 @brief frame of sink zone.
 */
#define CHAT_HEAD_SINK_ZONE             CGRectMake((SCREEN_BOUNDS.size.width - CHAT_HEAD_SINK_WIDTH)/2,                     \
                                                    (SCREEN_BOUNDS.size.height - CHAT_HEAD_SINK_HEIGHT),                    \
                                                    CHAT_HEAD_SINK_WIDTH,                                                   \
                                                    CHAT_HEAD_SINK_HEIGHT)

/**
 @brief Maximum number of concurrent visible chat heads.
 */
#define MAX_NUMBER_OF_CHAT_HEADS        3

/**
 @brief frame for chat head in expanded state based on indentation.
 */
#define CHAT_HEAD_EXPANDED_FRAME(indentation)   CGRectMake(SCREEN_BOUNDS.size.width -                                       \
                                                            (indentation)*(CHAT_HEAD_DIMENSION + CHAT_HEAD_MARGIN_X),       \
                                                            CHAT_HEAD_MARGIN_Y,                                             \
                                                            CHAT_HEAD_DIMENSION,                                            \
                                                            CHAT_HEAD_DIMENSION)




#pragma mark -
#pragma mark - FCRay


typedef struct FCRay {
    CGPoint startPoint;
    CGPoint toPoint;
} FCRay;



inline FCRay FCRayCreate(CGPoint startPoint, CGPoint toPoint)
{
    FCRay aRay = {startPoint, toPoint};
    
    return aRay;
}

extern BOOL FCRayIntersectsWithRect(FCRay ray, CGRect rect);

typedef enum PositionOnLine
{
    kPointPositionNone      = -2,
    kPointPositionPositive  = 0,
    kPointPositionNegative  = 1
} PointPositionOnLine;


