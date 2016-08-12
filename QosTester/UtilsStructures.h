//
//  UtilsStructures.h
//  QosTester
//
//  Created by wang lei on 15/1/13.
//  Copyright (c) 2015年 handwin. All rights reserved.
//

#ifndef QosTester_UtilsStructures_h
#define QosTester_UtilsStructures_h

#pragma  pack(push,1)

typedef struct
{
    uint32_t seq_no;
    uint16_t size;
    uint32_t send_time;
    uint32_t recv_time;
}code_report_rec_packet_info_t;
typedef struct
{
    uint32_t seq_no;
    uint16_t size;
}code_report_send_packet_info_t;
typedef struct
{
    uint32_t last_max_number;
    uint32_t last_min_number;
    uint32_t last_total_size;
    uint32_t total_number;
    uint8_t net_type;
}code_report_history_rec_summary_t;
typedef struct
{
    uint32_t last_max_number;
    uint32_t last_min_number;
    uint32_t last_total_size;
    uint32_t total_number;
}code_report_history_send_summary_t;

#endif
