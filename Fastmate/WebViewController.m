#import "WebViewController.h"
@import WebKit;

@interface WebViewController () <WKNavigationDelegate, WKScriptMessageHandler>

@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) WKUserContentController *userContentController;
@property (nonatomic, strong) NSURL *baseURL;

@end

@implementation WebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.baseURL = [NSURL URLWithString:@"https://www.fastmail.com"];
    [self configureUserContentController];

    WKWebViewConfiguration *configuration = [WKWebViewConfiguration new];
    configuration.applicationNameForUserAgent = @"Fastmate";
    configuration.userContentController = self.userContentController;

    self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:configuration];
    self.webView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.webView.navigationDelegate = self;
    self.webView.enclosingScrollView.contentInsets = NSEdgeInsetsMake(40.0, 0.0, 0.0, 0.0);
    [self.view addSubview:self.webView];

    [self.webView loadRequest:[NSURLRequest requestWithURL:self.baseURL]];
    [self addObserver:self forKeyPath:@"webView.title" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"webView.title"];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (object == self && [keyPath isEqualToString:@"webView.title"]) {
        [self webViewTitleDidChange:change[NSKeyValueChangeNewKey]];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)webViewTitleDidChange:(NSString *)newTitle {
    NSRange unreadCountRange = [newTitle rangeOfString:@"^\\(\\d+\\)" options:NSRegularExpressionSearch];
    if (unreadCountRange.location == NSNotFound) {
        [self setUnreadCount:0];
    } else {
        NSString *unreadString = [newTitle substringWithRange:unreadCountRange];
        NSCharacterSet *decimalCharacterSet = [NSCharacterSet decimalDigitCharacterSet];
        NSInteger unreadCount = [[unreadString stringByTrimmingCharactersInSet:decimalCharacterSet.invertedSet] integerValue];
        [self setUnreadCount:unreadCount];
    }
}

- (void)setUnreadCount:(NSUInteger)unreadCount {
    [[[NSApplication sharedApplication] dockTile] setBadgeLabel:unreadCount > 0 ? [NSString stringWithFormat:@"%ld", unreadCount] : nil];
}

- (void)configureUserContentController {
    self.userContentController = [WKUserContentController new];
    [self.userContentController addScriptMessageHandler:self name:@"Fastmate"];

    NSString *source = [NSString stringWithContentsOfURL:[NSBundle.mainBundle URLForResource:@"NotificationHooks" withExtension:@"js"] encoding:NSUTF8StringEncoding error:nil];
    WKUserScript *script = [[WKUserScript alloc] initWithSource:source injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
    [self.userContentController addUserScript:script];
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:[message.body dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    NSLog(@"%@", dictionary);

    NSUserNotification *notification = [NSUserNotification new];
    notification.identifier = message.body;
    notification.title = dictionary[@"title"];
    notification.subtitle = [dictionary valueForKeyPath:@"options.body"];
    notification.soundName = NSUserNotificationDefaultSoundName;

    if ([dictionary valueForKeyPath:@"options.icon"]) {
        NSURL *iconURL = [NSURL URLWithString:[dictionary valueForKeyPath:@"options.icon"] relativeToURL:self.baseURL];
        notification.contentImage = [[NSImage alloc] initWithContentsOfURL:iconURL];
    }

    [NSUserNotificationCenter.defaultUserNotificationCenter deliverNotification:notification];
}

@end