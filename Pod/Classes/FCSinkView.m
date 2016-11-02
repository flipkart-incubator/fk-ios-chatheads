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

#import "FCSinkView.h"

@implementation FCSinkView

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];

    CGFloat width = CGRectGetWidth(rect);
    
    CGPoint c = CGPointMake(width/2, width);

    CGContextRef cx = UIGraphicsGetCurrentContext();
    
    [[UIColor clearColor] set];
    CGContextFillRect(cx, rect);
    
    CGContextSaveGState(cx);
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    
    CGFloat comps[] = {0.2, 0.2, 0.2, 1.0,
                       0.0, 0.0, 0.0, 0.0};
    CGFloat locs[] = {0,1};
    CGGradientRef g = CGGradientCreateWithColorComponents(space, comps, locs, 2);
    
    CGContextDrawRadialGradient(cx, g, c, width/2, CGPointMake(c.x, c.y + width), 2*width, 0);
    
    CGContextRestoreGState(cx);
}

@end
