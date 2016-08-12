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
#import "Utils.h"
#import "UtilsStructures.h"

#define SELF_PORT   18000

@interface ViewController () <GCDAsyncUdpSocketDelegate, WebFrameLoadDelegate> {
    GCDAsyncUdpSocket *gcdUdpSocket;
    WebView *webView;
    BOOL isChartOK;
    
    NSMutableArray *statisticData;
    NSInteger statisticSequence;
    int receivedBytes;
    int receiveBitrate;
    int receivedPackets;
    int receivePps;
    
    uint64_t lastDrawTimestamp;
    int lastTargetRateCount;
    int lastPracticalRateCount;
    int lastPerCount;
    int lastRecvRate;
    int lastRecvPackets;
    int lastCount;
    
    int averageTargetRate;
    int averagePracticalRate;
    int averagePer;
    int averageRecvRate;
    int averageRecvPackets;
}
@end

@interface QosStatisticPacket : NSObject
@property (nonatomic, assign) uint64_t sendTimeStamp;
@property (nonatomic, assign) uint64_t recvTimeStamp;
@property (nonatomic, assign) uint32_t packetSequence;
@property (nonatomic, assign) uint16_t packetSize;

- (instancetype)initWithSendTime:(uint64_t)sendTime recvTime:(uint64_t)recvTime seq:(uint32_t)seq size:(uint16_t)size;

@end
@implementation QosStatisticPacket

- (instancetype)initWithSendTime:(uint64_t)sendTime recvTime:(uint64_t)recvTime seq:(uint32_t)seq size:(uint16_t)size {
    self = [super init];
    if (self) {
        _sendTimeStamp = sendTime;
        _recvTimeStamp = recvTime;
        _packetSequence = seq;
        _packetSize = size;
    }
    
    return self;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    isChartOK = NO;
    
    [self initGraphs];
    
    [self initGCDUdpSocket];
    
    statisticData = [[NSMutableArray alloc] init];
    [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(statisticReceived) userInfo:nil repeats:YES];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    
}

- (void)statisticReceived {
    static BOOL isDouble = YES;
    if (isDouble) {
        receiveBitrate = receivedBytes/128;
        receivePps = receivedPackets;
        receivedBytes = 0;
        receivedPackets = 0;
        // update
        [self updateGraphWithTargetRate:averageTargetRate practicalRate:averagePracticalRate packerPerSecond:averagePer];
    }
    isDouble = !isDouble;
    
    //make buffer
    uint8_t *bufferNeeded = (uint8_t*)malloc([self countBufferSizeWithArray:statisticData]);
    for (QosStatisticPacket *pakcet in statisticData) {
        //TODO: make buffer
    }
    statisticSequence++;
}

- (int)countBufferSizeWithArray:(NSArray*)array {
    int all_buff_need = 0;
    all_buff_need += 2 + 4 + 1;
    all_buff_need += array.count * sizeof(code_report_rec_packet_info_t);
    all_buff_need += array.count * sizeof(code_report_send_packet_info_t);
    all_buff_need += array.count * sizeof(code_report_history_rec_summary_t);
    all_buff_need += array.count * sizeof(code_report_history_send_summary_t);
    all_buff_need += 4*sizeof(uint8_t);
    
    return all_buff_need;
}

#pragma mark - Graph methods

- (void)initGraphs {
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
    NSLog(@"webView:didFinishLoadForFrame");
    isChartOK = YES;
}

- (void)countWithTargetRate:(int)targetRate practicalRate:(int)practicalRate packerPerSecond:(int)per
                   recvRate:(int)recvRate recvPackets:(int)recvPackets {
    NSLog(@"😊 %ukB/s, 🐶 %ukB/s, 👛 %u/s, 🍉 %ukB/s, ❀ %u/s.", targetRate, practicalRate, per, recvRate, recvPackets);
    uint64_t timeStamp = get_current_timestamp();
    if (lastDrawTimestamp+1000 < timeStamp) {
        if (0 != lastCount) {
            averageTargetRate = lastTargetRateCount/lastCount;
            averagePracticalRate = lastPracticalRateCount/lastCount;
            averagePer = lastPerCount/lastCount;
            averageRecvRate = lastRecvRate/lastCount;
            averageRecvPackets = lastRecvPackets/lastCount;
        }
        lastTargetRateCount = 0;
        lastPracticalRateCount = 0;
        lastPerCount = 0;
        lastRecvRate = 0;
        lastRecvPackets = 0;
        lastCount = 0;
        lastDrawTimestamp = timeStamp;
    } else {
        lastTargetRateCount += targetRate;
        lastPracticalRateCount += practicalRate;
        lastPerCount += per;
        lastRecvRate += recvRate;
        lastRecvPackets += recvPackets;
        lastCount++;
        return;
    }
}

- (void)updateGraphWithTargetRate:(int)targetRate practicalRate:(int)practicalRate packerPerSecond:(int)per {
    NSDate* nowDate = [[NSDate alloc]init];
    NSTimeInterval nowTimeInterval = [nowDate timeIntervalSince1970] * 1000;
    
    NSString* jsStr = [NSString stringWithFormat:@"updateData(%f, %u, %u, %u, %u, %u)", nowTimeInterval, targetRate, practicalRate, per, receiveBitrate, receivePps];
    [webView stringByEvaluatingJavaScriptFromString:jsStr];
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
//    NSString *peerIp;
//    uint16_t peerPort;
//    [GCDAsyncUdpSocket getHost:&peerIp port:&peerPort fromAddress:address];
//    NSLog(@"Receive data with length: %ld; from %@:%d", (unsigned long)data.length, peerIp, peerPort);
    [self dealwithDataReceived:data];
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag {
    //NSLog(@"Send data with tag:%ld", tag);
}

- (void)dealwithDataReceived:(NSData*)data {
    if (!data || !data.length) {
        return;
    }
    uint8_t* temp = (uint8_t*)data.bytes;
    switch (temp[0]) {
        case 0x00: { //data
            uint64_t sendTimeStamp = read_u64_be(temp+1);
            uint64_t recvTimeStamp = get_current_timestamp();
            uint32_t packetSequence = read_u32_be(temp+1+8);
            uint16_t packetSize = data.length;
            [statisticData addObject:[[QosStatisticPacket alloc] initWithSendTime:sendTimeStamp recvTime:recvTimeStamp seq:packetSequence size:packetSize]];
            receivedPackets++;
            receivedBytes += packetSize;
            break;
        }
        case 0x01: { //cmd
            uint16_t targetBitrate = read_u16_be(temp+1);
            uint16_t practicalRate = read_u16_be(temp+3);
            uint16_t packetPerSecond = read_u16_be(temp+5);
            uint16_t recvBitrate = 0;
            uint16_t recvPackets = 0;
            if (data.length > 7) {
                recvBitrate = read_u16_be(temp+7);
                recvPackets = read_u16_be(temp+9);
            }
            [self countWithTargetRate:targetBitrate practicalRate:practicalRate packerPerSecond:packetPerSecond recvRate:recvBitrate recvPackets:recvPackets];
            break;
        }
        case 0x02: { //others
            break;
        }
            
        default:
            break;
    }
}

@end
