//
//  Utils.h
//  QosTester
//
//  Created by wang lei on 15/1/12.
//  Copyright (c) 2015年 handwin. All rights reserved.
//

#ifndef QosTester_Utils_h
#define QosTester_Utils_h

unsigned long get_current_timestamp();
uint64_t read_u64_be(unsigned char *buf);
void write_u64_be(unsigned char *buf, uint64_t n);
uint64_t read_u48_be(unsigned char *buf);
void write_u48_be(unsigned char *buf, uint64_t n);
uint32_t read_u32_be(unsigned char *buf);
void write_u32_be(unsigned char *buf, uint32_t n);
uint16_t read_u16_be(unsigned char *buf);
void write_u16_be(unsigned char *buf, uint16_t n);

#endif
