#ifndef __SDT_STRUCTS_H__
#define __SDT_STRUCTS_H__

#include "table.h"

struct arr_dim {
    int len[MAX_ARR_DIM];
    int d;
};

struct lit_const {
    int val;
    enum id_type t;
};

#endif