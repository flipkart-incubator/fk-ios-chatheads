# FCChatHeads

Library to use chat heads within your iOS app with complete physics and animations which drive multi user chat behaviour to support collapsed/stacked or expanded states.

# Demo
![chat heads demo](/Example/Demo/FCDemo.gif?raw=true)

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.


## Installation

FCChatHeads is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "FCChatHeads"
```
## Usage

Include the following import in your file

```objective-c
#import <FCChatHeads/FCChatHeads.h>
```

### To present chat head with image

```objective-c
[ChatHeadsController presentChatHeadWithImage:<UIImage instance> chatID:<Unique identifier>];
```

### To present chat head with view

```objective-c
[ChatHeadsController presentChatHeadWithView:<UIView instance> chatID:<Unique identifier>];
```

### To set badge count on chat head

```objective-c
[ChatHeadsController setUnreadCount:<Unread count> forChatHeadWithChatID:<Unique identifier>];
```

### To show view in popover on chat head selection

Set datasource for ChatHeadsController

```objective-c
ChatHeadsController.datasource = <datasource>;
```

Return view from callback

```objective-c
- (UIView *)chatHeadsController:(FCChatHeadsController *)chatHeadsController viewForPopoverForChatHeadWithChatID:(NSString *)chatID
{
    UIView *view = <Create view for presentation>;

    return view;
}

```

Refer [FCChatHeadsController.h](Pod/Classes/FCChatHeadsController.h) for more information on how to present or dismiss or hide chatheads.
For information on callbacks refer FCChatHeadsControllerDatasource and FCChatHeadsControllerDelegate protocols in [FCChatHeadsController.h](Pod/Classes/FCChatHeadsController.h)

Also checkout code in [FCViewController.m](Example/FCChatHeads/FCViewController.m)



## Author

Rajat Gupta, rajat.g@flipkart.com

## License

Copyright 2014 Flipkart Internet Pvt Ltd

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
