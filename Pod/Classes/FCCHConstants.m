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



#import "FCCHConstants.h"




extern FCRay FCRayCreate(CGPoint startPoint, CGPoint toPoint);


BOOL FCRayIntersectsWithRect(FCRay ray, CGRect rect)
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






















