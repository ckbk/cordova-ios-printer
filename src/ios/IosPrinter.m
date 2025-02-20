#import "IosPrinter.h"
#import <WebKit/WebKit.h>

@interface IosPrinter() <WKNavigationDelegate, UIPrintInteractionControllerDelegate>
@property (strong, nonatomic) WKWebView *printerWebView;
@property (copy, nonatomic) NSString *callbackId;
@end

@implementation IosPrinter

- (void)print:(CDVInvokedUrlCommand*)command {
    self.callbackId = command.callbackId;
    NSString* htmlString = [command.arguments objectAtIndex:0];

    if (!htmlString || [htmlString isEqualToString:@""]) {
        [self sendErrorResult:@"Empty HTML content"];
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        CGFloat paperWidth = 633;
        CGFloat paperHeight = 841.8;

        self.printerWebView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, paperWidth, paperHeight)];
        self.printerWebView.navigationDelegate = self;
        self.printerWebView.hidden = YES; // Hide but keep in hierarchy
        [self.viewController.view addSubview:self.printerWebView];

        NSURL *baseURL = [NSURL fileURLWithPath:NSTemporaryDirectory()];
        [self.printerWebView loadHTMLString:htmlString baseURL:baseURL];
    });
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
  NSString *dimensionsJS = @"(() => {"
          "const meta = document.createElement('meta');"
          "meta.name = 'viewport';"
          "meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';"
          "document.head.appendChild(meta);"
          "return {"
              "width: Math.min(document.documentElement.scrollWidth, document.documentElement.offsetWidth),"
          "};"
      "})()";
    // Add additional delay to ensure rendering completion
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      [webView evaluateJavaScript:dimensionsJS completionHandler:^(NSDictionary* results, NSError* errorDimentions) {
            if (errorDimentions) {
              NSLog(@"Error: %@", errorDimentions.localizedDescription);
              [self sendErrorResult:errorDimentions.localizedDescription];
              return;
            }

            CGFloat contentWidth = [results[@"width"] doubleValue];

            UIPrintInteractionController *printController = [UIPrintInteractionController sharedPrintController];
            printController.delegate = self;



            UIPrintPaper *paper = [UIPrintPaper bestPaperForPageSize:CGSizeMake(633, 842) withPapersFromArray:@[]];
            CGSize paperSize = paper.paperSize;

            CGRect paperRect = CGRectMake(0, 0, paperSize.width, paperSize.height);

            CGFloat scaleFactor = paperSize.width / contentWidth;

            webView.transform = CGAffineTransformMakeScale(scaleFactor, scaleFactor);

            CGRect printableRect = CGRectInset(paperRect, 0, 0);

            // Remove formatter margins
            UIViewPrintFormatter *formatter = [webView viewPrintFormatter];
            formatter.perPageContentInsets = UIEdgeInsetsZero;  // Remove default insets

            UIPrintPageRenderer *renderer = [[UIPrintPageRenderer alloc] init];
            [renderer addPrintFormatter:formatter startingAtPageAtIndex:0];

            [renderer setValue:[NSValue valueWithCGRect:paperRect] forKey:@"paperRect"];
            [renderer setValue:[NSValue valueWithCGRect:printableRect]
                     forKey:@"printableRect"];


            printController.printPageRenderer = renderer;
            printController.showsPaperSelectionForLoadedPapers = YES;

            [printController presentAnimated:YES completionHandler:^(UIPrintInteractionController *piController, BOOL completed, NSError *error) {
                [self cleanupWebView];
                if (error) {
                    [self sendErrorResult:error.localizedDescription];
                } else if (!completed) {
                    [self sendErrorResult:@"Print cancelled"];
                } else {
                    [self sendSuccessResult];
                }
            }];
        }];
    });
}


- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [self cleanupWebView];
    [self sendErrorResult:error.localizedDescription];
}

- (void)cleanupWebView {
    [self.printerWebView removeFromSuperview];
    self.printerWebView = nil;
}

- (void)sendSuccessResult {
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:result callbackId:self.callbackId];
}

- (void)sendErrorResult:(NSString*)message {
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:message];
    [self.commandDelegate sendPluginResult:result callbackId:self.callbackId];
}

@end

