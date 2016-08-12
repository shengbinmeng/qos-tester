//
//  Utils.h
//  QosTester
//
//  Created by wang lei on 15/1/12.
//  Copyright (c) 2015年 handwin. All rights reserved.
//

#ifndef QosTester_Utils_h
#define QosTester_Utils_h

#import <sys/time.h>

#define TEST_HOST_PORT 18000
#define TEST_REMOTE_PORT 18000
#define TEST_REMOTE_IP @"192.168.31.124"
//#define TEST_REMOTE_IP @"192.168.31.86"
//#define TEST_REMOTE_IP @"192.168.31.122"

static unsigned long get_current_timestamp();
static uint64_t read_u64_be(unsigned char *buf);
static void write_u64_be(unsigned char *buf, uint64_t n);
static uint64_t read_u48_be(unsigned char *buf);
static void write_u48_be(unsigned char *buf, uint64_t n);
static uint32_t read_u32_be(unsigned char *buf);
static void write_u32_be(unsigned char *buf, uint32_t n);
static uint16_t read_u16_be(unsigned char *buf);
static void write_u16_be(unsigned char *buf, uint16_t n);

/*****************************************************************
 格式定义如下：
 0               1               2               3
 0 1 2 3 4 5 6 7 0 1 2 3 4 5 6 7 0 1 2 3 4 5 6 7 0 1 2 3 4 5 6 7 8
 +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 |--> cmdType <--| 0x01bandwitch |--> -------- <-|---> ---- <----|
 4               5               6               7
 0 1 2 3 4 5 6 7 0 1 2 3 4 5 6 7 0 1 2 3 4 5 6 7 0 1 2 3 4 5 6 7 8
 +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 |-----------------------------> -------- <----------------------|
 8               9               10              11
 0 1 2 3 4 5 6 7 0 1 2 3 4 5 6 7 0 1 2 3 4 5 6 7 0 1 2 3 4 5 6 7 8
 +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 |--------> ----------- <--------|----> 8 bytes timestamp ...
 *****************************************************************/

static unsigned long get_current_timestamp() {
    struct timeval current;
    gettimeofday(&current, NULL);
    
    return current.tv_sec * 1000 + current.tv_usec/1000;
}

static uint64_t read_u64_be(unsigned char *buf) {
    uint64_t n = 0;
    n |= (uint64_t) buf[0] << 56;
    n |= (uint64_t) buf[1] << 48;
    n |= (uint64_t) buf[2] << 40;
    n |= (uint64_t) buf[3] << 32;
    n |= (uint64_t) buf[4] << 24;
    n |= buf[5] << 16;
    n |= buf[6] << 8;
    n |= buf[7];
    return n;
}

static void write_u64_be(unsigned char *buf, uint64_t n) {
    buf[0] = n >> 56 & 0xff;
    buf[1] = n >> 48 & 0xff;
    buf[2] = n >> 40 & 0xff;
    buf[3] = n >> 32 & 0xff;
    buf[4] = n >> 24 & 0xff;
    buf[5] = n >> 16 & 0xff;
    buf[6] = n >> 8 & 0xff;
    buf[7] = n & 0xff;
}

static uint64_t read_u48_be(unsigned char *buf) {
    uint64_t n = 0;
    n |= (uint64_t) buf[0] << 40;
    n |= (uint64_t) buf[1] << 32;
    n |= (uint64_t) buf[2] << 24;
    n |= (uint64_t) buf[3] << 16;
    n |= (uint64_t) buf[4] << 8;
    n |= buf[5];
    return n;
}

static void write_u48_be(unsigned char *buf, uint64_t n) {
    buf[0] = n >> 40 & 0xff;
    buf[1] = n >> 32 & 0xff;
    buf[2] = n >> 24 & 0xff;
    buf[3] = n >> 16 & 0xff;
    buf[4] = n >> 8 & 0xff;
    buf[5] = n & 0xff;
}

static uint32_t read_u32_be(unsigned char *buf) {
    uint32_t n = 0;
    n |= (uint32_t)buf[0] << 24;
    n |= (uint32_t)buf[1] << 16;
    n |= buf[2] << 8;
    n |= buf[3];
    return n;
}

static void write_u32_be(unsigned char *buf, uint32_t n) {
    buf[0] = n >> 24 & 0xff;
    buf[1] = n >> 16 & 0xff;
    buf[2] = n >> 8 & 0xff;
    buf[3] = n & 0xff;
}

static uint16_t read_u16_be(unsigned char *buf) {
    uint16_t n = 0;
    n |= buf[0] << 8;
    n |= buf[1];
    return n;
}

static void write_u16_be(unsigned char *buf, uint16_t n) {
    buf[0] = n >> 8 & 0xff;
    buf[1] = n & 0xff;
}

#endif
