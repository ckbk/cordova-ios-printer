#import <Cordova/CDVPlugin.h>

@interface IosPrinter : CDVPlugin

@property (nonatomic, readonly) WKWebView *printerWebView;
- (void)print:(CDVInvokedUrlCommand*)command;

@end
