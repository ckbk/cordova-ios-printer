#import "IosPrinter.h"
@import ObjectiveC;

@implementation IosPrinter {
    WKWebView *_printView;
}

- (void)print:(CDVInvokedUrlCommand*)command {
    NSString *htmlContent = [command.arguments objectAtIndex:0];

    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];

    if (@available(iOS 14.0, *)) {
        [config.preferences setValue:@YES forKey:@"allowFileAccessFromFileURLs"];
    }

    _printView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:config];
    _printView.navigationDelegate = self;

    NSString *wwwPath = [[NSBundle mainBundle] resourcePath];
    NSURL *baseURL = [NSURL fileURLWithPath:wwwPath];

    [_printView loadHTMLString:htmlContent baseURL:baseURL];
    objc_setAssociatedObject(_printView, @"command", command, OBJC_ASSOCIATION_RETAIN);
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    CDVInvokedUrlCommand* command = objc_getAssociatedObject(webView, @"command");

    UIPrintInteractionController *printController = [UIPrintInteractionController sharedPrintController];
    UIPrintInfo *printInfo = [UIPrintInfo printInfo];

    [webView evaluateJavaScript:@"document.documentElement.scrollHeight" completionHandler:^(id result, NSError *error) {
        CGFloat contentHeight = [result doubleValue];

        // Get actual paper size using UIPrintPaper API
        UIPrintPaper *paper = [UIPrintPaper bestPaperForPageSize:CGSizeMake(612, 792)  // Default to Letter size (8.5" x 11")
                                              withPapersFromArray:nil];

        CGSize paperSize = paper.paperSize;
        webView.frame = CGRectMake(0, 0, paperSize.width, contentHeight);

        UIPrintPageRenderer *renderer = [[UIPrintPageRenderer alloc] init];
        [renderer addPrintFormatter:[webView viewPrintFormatter] startingAtPageAtIndex:0];

        CGFloat margin = 72.0;
        CGRect printableRect = CGRectMake(margin, margin,
                                        paperSize.width - (margin * 2),
                                        paperSize.height - (margin * 2));

        [renderer setValue:[NSValue valueWithCGRect:CGRectMake(0, 0, paperSize.width, paperSize.height)]
                  forKey:@"paperRect"];
        [renderer setValue:[NSValue valueWithCGRect:printableRect]
                  forKey:@"printableRect"];

        printController.printPageRenderer = renderer;
        printController.printInfo = printInfo;

        [printController presentAnimated:YES completionHandler:^(UIPrintInteractionController *pi, BOOL completed, NSError *error) {
            CDVPluginResult* pluginResult;
            if (completed) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            } else {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                    messageAsString:error ? error.localizedDescription : @"Print cancelled"];
            }
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }];
    }];
}


@end
