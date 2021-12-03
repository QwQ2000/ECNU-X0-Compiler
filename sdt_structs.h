#ifndef __SDT_STRUCTS_H__
#define __SDT_STRUCTS_H__

#include "table.h"

#define MAX_CASE_N 10

struct arr_dim {
    int len[MAX_ARR_DIM];
    int d;
};

struct lit_const {
    int val;
    enum id_type t;
};

struct case_list {
    int len;
    int beg_pos[MAX_CASE_N];
    int end_pos;
    enum id_type t[MAX_CASE_N];
};

#endif