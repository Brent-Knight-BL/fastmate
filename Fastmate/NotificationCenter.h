//
//  NotificationCenter.h
//  Fastmate
//
//  Created by Joel Ekström on 2020-04-28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class NotificationCenter;

@protocol NotificationCenterDelegate
- (void)notificationCenter:(NotificationCenter *)center notificationClickedWithIdentifier:(NSString *)identifier;
@end

@interface NotificationCenter : NSObject

+ (instancetype)sharedInstance;
- (void)registerForNotifications;
- (void)postNotificationWithIdentifier:(NSString *)identifier title:(NSString *)title body:(NSString *)body;

@property (nonatomic, weak) id<NotificationCenterDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
