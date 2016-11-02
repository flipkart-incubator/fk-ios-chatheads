//
//  FCViewController.m
//  FCChatHeads
//
//  Created by Rajat Gupta on 04/09/2015.
//  Copyright (c) 2014 Rajat Gupta. All rights reserved.
//

#import "FCViewController.h"
#import <FCChatHeads/FCChatHeads.h>

@interface FCViewController () <FCChatHeadsControllerDatasource>
{
    NSUInteger _index;
    BOOL _chatHeadsShown;
    NSUInteger _unreadCount;
    BOOL _stopBombarding;
    
    NSArray *_imageNames;
    NSArray *_displayTexts;
}

@end

@implementation FCViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    UIAlertView *instruction = [[UIAlertView alloc] initWithTitle:nil
                                                          message:@"Double tap on screen to present chat heads"
                                                         delegate:nil
                                                cancelButtonTitle:@"OK"
                                                otherButtonTitles:nil, nil];
    [instruction show];
    
    _imageNames = @[@"costanza", @"einstein", @"letterman", @"nigella", @"steve", @"trump"];
    _displayTexts = @[@"\"I'm much more comfortable criticizing people behind their backs.\"", @"\"Two things are infinite: the universe and human stupidity... and I'm not so sure about the universe.\"", @"\"I'm just trying to make a smudge on the collective unconscious.\"", @"\"I don't believe in low fat coooking.\"", @"\"I want to put a ding in the universe.\"", @"\"I know words, I have the best words. I have the best, but there is no better word than stupid.\""];
    
    self.view.backgroundColor = [UIColor colorWithRed:40.0/255.0 green:116.0/255.0 blue:240.0/255.0 alpha:1.0];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tapGesture.numberOfTapsRequired = 2;
    tapGesture.numberOfTouchesRequired = 1;
    
    [self.view addGestureRecognizer:tapGesture];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongTap:)];
    
    [self.view addGestureRecognizer:longPress];
    
    ChatHeadsController.datasource = self;
}


- (void)handleTap:(UITapGestureRecognizer *)tap
{
    _stopBombarding = YES;
    
    switch (_index%2) {
        case 0: {
            // Presenting with image
            NSString *imageName = _imageNames[_index%6];
            
            [ChatHeadsController presentChatHeadWithImage:[UIImage imageNamed:imageName] chatID:imageName];
            [ChatHeadsController setUnreadCount:_unreadCount++ forChatHeadWithChatID:imageName];
            
            _index++;
        }
            break;
            
        case 1: {
            // Presenting with view
            
            NSString *imageName = _imageNames[_index%6];
            
            UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imageName]];
            imageView.frame = DEFAULT_CHAT_HEAD_FRAME;
            imageView.layer.cornerRadius = CGRectGetHeight(imageView.bounds)/2;
            imageView.clipsToBounds = YES;
            
            [ChatHeadsController presentChatHeadWithView:imageView chatID:imageName];
            [ChatHeadsController setUnreadCount:_unreadCount++ forChatHeadWithChatID:imageName];
            
            _index++;
        }
            break;
            
            
        default:
            break;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)handleLongTap:(UILongPressGestureRecognizer *)longPress
{
    if (longPress.state == UIGestureRecognizerStateBegan)
    {
        if (_chatHeadsShown)
        {
            _chatHeadsShown = NO;
            
            [ChatHeadsController dismissAllChatHeads:YES];
        }
        else
        {
            _chatHeadsShown = YES;
            
            NSMutableArray *chatHeads = [NSMutableArray array];
            
            for (int count = 0; count < 3; count++)
            {
                NSString *imageName = _imageNames[count];
                
                UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imageName]];
                imageView.frame = DEFAULT_CHAT_HEAD_FRAME;
                imageView.layer.cornerRadius = CGRectGetHeight(imageView.bounds)/2;
                imageView.layer.masksToBounds = YES;
                
                FCChatHead *chatHead = [FCChatHead chatHeadWithView:imageView
                                                             chatID:imageName
                                                           delegate:ChatHeadsController];
                
                [chatHeads addObject:chatHead];
            }
            
            [ChatHeadsController presentChatHeads:chatHeads animated:YES];
        }
    }
}

- (UIView *)chatHeadsController:(FCChatHeadsController *)chatHeadsController viewForPopoverForChatHeadWithChatID:(NSString *)chatID
{
    UIView *view = [[UIView alloc] initWithFrame:self.view.bounds];
    [view setBackgroundColor:[UIColor whiteColor]];
    
    UILabel *displayText = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, view.bounds.size.width - 40, view.bounds.size.height - 100)];
    displayText.font = [UIFont systemFontOfSize:17.0];
    displayText.numberOfLines = 0;
    displayText.textColor = [UIColor colorWithWhite:0.2 alpha:1.0];
    displayText.textAlignment = NSTextAlignmentCenter;
//    displayText.shadowColor = [UIColor colorWithWhite:0.6 alpha:0.7];
    
    displayText.text = _displayTexts[[_imageNames indexOfObject:chatID]];
    
    [view addSubview:displayText];
    
    return view;
}



- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}



@end
