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

        UIPrintPaper *paper = [UIPrintPaper bestPaperForPageSize:CGSizeMake(595, 842) withPapersFromArray:nil];
        CGSize paperSize = paper.paperSize;

        CGRect printableRect = CGRectMake(72, 72, paperSize.width - 144, paperSize.height - 144);
        CGFloat scaleFactor = printableRect.size.width / (paperSize.width - 110);

        // Remove formatter margins
        UIViewPrintFormatter *formatter = [webView viewPrintFormatter];
        formatter.contentInsets = UIEdgeInsetsZero;  // Remove default insets

        UIPrintPageRenderer *renderer = [[UIPrintPageRenderer alloc] init];
        [renderer addPrintFormatter:formatter startingAtPageAtIndex:0];

        // Set renderer rects
        [renderer setValue:[NSValue valueWithCGRect:CGRectMake(0, 0, paperSize.width, paperSize.height)]
                 forKey:@"paperRect"];
        [renderer setValue:[NSValue valueWithCGRect:printableRect]
                 forKey:@"printableRect"];

        // Apply scaling directly to webview
        webView.transform = CGAffineTransformMakeScale(scaleFactor, scaleFactor);
        webView.frame = CGRectMake(0, 0,
                                 paperSize.width / scaleFactor,
                                 contentHeight / scaleFactor);

        printController.printPageRenderer = renderer;
        printController.printInfo.outputType = UIPrintInfoOutputGeneral;

        [printController presentAnimated:YES completionHandler:^(UIPrintInteractionController *pi, BOOL completed, NSError *error) {
            // Reset transform after printing
            webView.transform = CGAffineTransformIdentity;
            webView.frame = CGRectZero;

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
