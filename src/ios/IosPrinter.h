#import <Cordova/CDVPlugin.h>
#import <WebKit/WebKit.h>

@interface IosPrinter : CDVPlugin <WKNavigationDelegate>

- (void)print:(CDVInvokedUrlCommand*)command;

@end