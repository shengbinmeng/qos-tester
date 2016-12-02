//
//  ViewController.m
//  QosTester
//
//  Created by wang lei on 15/1/8.
//  Copyright (c) 2015年 handwin. All rights reserved.
//

#import "ViewController.h"
#import "GCDAsyncUdpSocket.h"
#import <WebKit/WebKit.h>
#include "Utils.h"

#define SELF_PORT   18000

@interface ViewController () <GCDAsyncUdpSocketDelegate, WebFrameLoadDelegate> {
    GCDAsyncUdpSocket *gcdUdpSocket;
    WebView *webView;
    BOOL chartReady;
    BOOL needUpdate;
    
    // Data series that will be drawn (currently only support at most 8 numbers)
    int series[8];
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    chartReady = NO;
    needUpdate = NO;
    
    [self initChart];
    
    [self initGCDUdpSocket];
    
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateChart) userInfo:nil repeats:YES];
}

- (void)updateChart {
    if (!chartReady || !needUpdate) {
        return;
    }
    NSDate* nowDate = [[NSDate alloc]init];
    NSTimeInterval timeInterval = [nowDate timeIntervalSince1970] * 1000;
    
    NSString* jsStr = [NSString stringWithFormat:@"updateData(%f, %u, %u, %u, %u, %u, %u, %u, %u)", timeInterval, series[0], series[1], series[2], series[3], series[4], series[5], series[6], series[7]];
    [webView stringByEvaluatingJavaScriptFromString:jsStr];
    
    // Because we have updated. (If other places decide to update, they should set to YES there)
    needUpdate = NO;
}

#pragma mark - Chart methods

- (void)initChart {
    [self.view setFrame:NSRectFromCGRect(CGRectMake(0, 0, 1920, 1024))];
    webView = [[WebView alloc] initWithFrame:NSRectFromCGRect(CGRectMake(0, 0, 1920, 1004))];
    [self.view addSubview:webView];
    webView.frameLoadDelegate = self;
    
    //所有的资源都在source.bundle这个文件夹里
    NSString* htmlPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"source.bundle/index.html"];
    NSURL* url = [NSURL fileURLWithPath:htmlPath];
    NSURLRequest* request = [NSURLRequest requestWithURL:url];
    WebFrame *mainFrame = [webView mainFrame];
    [mainFrame loadRequest:request];
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
    NSLog(@"Chart is ready");
    chartReady = YES;
}

#pragma mark - Socket methods

- (void)initGCDUdpSocket {
    NSError *error;
    if (!gcdUdpSocket) {
        gcdUdpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        if (![gcdUdpSocket bindToPort:SELF_PORT error:&error] || ![gcdUdpSocket beginReceiving:&error]) {
            NSLog(@"Error binding: %@", error);
            return;
        }
    }
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext {
    if (!data || !data.length) {
        return;
    }
    uint8_t* bytes = (uint8_t*)data.bytes;
    switch (bytes[0]) {
        // The first byte specifies the data protocol.
        case 0x01: {
            // Protocol used by the echorobot's status report.
            // All values are of type uint16_t which consume 2 bytes.
            series[0] = read_u16_be(bytes+1); // target sending bitrate
            series[1] = read_u16_be(bytes+3); // actual sending bitrate
            series[2] = read_u16_be(bytes+5); // sending packet rate
            if (data.length > 7) {
                series[3] = read_u16_be(bytes+7); // available bandwidth
            }
            series[4] = 0;
            series[5] = 0;
            series[6] = 0;
            series[7] = 0;
            break;
        }
        case 0x02: {
            // Protocol used by the udpServer's net control analytics.
            // All values are of type uint16_t which consume 2 bytes.
            series[0] = read_u16_be(bytes+1); // reported sending bitrate
            series[1] = read_u16_be(bytes+3); // calculated sending bitrate
            series[2] = read_u16_be(bytes+5); // receiving bitrate
            series[3] = read_u16_be(bytes+7); // delay average
            series[4] = read_u16_be(bytes+9); // packet loss percent
            series[5] = read_u16_be(bytes+11); // sampled bandwidth
            series[6] = read_u16_be(bytes+13); // decided bandwidth
            series[7] = read_u16_be(bytes+15); // decided per
            break;
        }
        default: {
            NSLog(@"%@", data.description);
        }
    }
    
    NSLog(@"New data arrived: %d, %d, %d, %d, %d, %d, %d, %d", series[0], series[1], series[2], series[3], series[4], series[5], series[6], series[7]);
    needUpdate = YES;
}

@end
