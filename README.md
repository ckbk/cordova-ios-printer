# Cordova iOS Printer Plugin

A Cordova plugin that enables HTML content printing capabilities for iOS applications. This plugin provides a simple interface to access native iOS printing functionality from your Cordova-based applications.

## Features

- Print HTML content using native iOS printing dialog
- Support for WKWebView
- iOS 14+ compatibility
- Automatic content scaling and pagination
- Portrait orientation support
- Callback support for print completion and error handling

## Technical Details

- Uses native iOS `UIPrintInteractionController` for printing
- Implements `WKWebView` for HTML content rendering
- Supports asynchronous JavaScript callbacks
- Compatible with Cordova's plugin architecture

## Usage Example

```javascript
cordova.plugins.IosPrinter.print(
    '<html><body><h1>Hello World</h1></body></html>',
    () => console.log('Print successful'),
    (error) => console.error('Print failed:', error)
);
```

## Requirements

- iOS 14.0 or later
- Cordova iOS platform
- WKWebView-based project

## Installation

```shell script
cordova plugin add cordova-ios-printer
```

This plugin is ideal for Cordova applications that require native iOS printing capabilities, such as receipt printing, document printing, or any HTML-based content printing needs.
