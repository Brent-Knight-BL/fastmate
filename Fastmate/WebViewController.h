//
//  WebViewController.h
//  Fastmate
//
//  Created by Joel Ekström on 2018-08-14.
//

#import <Cocoa/Cocoa.h>

@interface WebViewController : NSViewController

- (void)composeNewEmail;
- (void)focusSearchField;
- (void)handleMailtoURL:(NSURL *)URL;

@end
