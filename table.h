#ifndef __TABLE_H__

#define __TABLE_H__

#define MAX_ID_TABLE_LEN 100     /* 符号表容量 */
#define MAX_ID_LEN 10         /* 标识符的最大长度 */
#define MAX_ARR_DIM 5            /* 数组的最大维度 */

/* 符号表中标识符的类型 */
enum id_type {
    xint, xchar, xbool, xfloat, proc
};

/* 符号表结构 */
struct table_t {
    char name[MAX_ID_LEN];     /* 名字 */
    enum id_type type;  /* 类型：id_type中定义的类型，字符、整数、布尔、浮点、过程*/
    int len[MAX_ARR_DIM]; /*数组长度：全部为-1则为变量，从左到右依次为多维数组各个维度的长度*/
    int is_const; /* 是否为常量 */
    int const_val; /* 仅支持非数组常量，故统一用4字节的空间存储常量的值 */
    int addr;  /* 存储标识符在运行时分配的地址*/
    int size; /* 存储过程占用的栈空间大小 */
};

struct table_t table[MAX_ID_TABLE_LEN]; /* 符号表 */

int tbl_tail;             /* 符号表当前尾指针 */
char id_buf[MAX_ID_LEN];  /* 存储编译过程中出现的标识符 */
int const_buf;        /* 存储编译过程中出现的常量值 */
char len_buf[MAX_ARR_DIM]; /* 存储编译过程中的数组维度 */

void table_register(enum id_type t,int is_const); /* 在符号表中加入一个标识符 */
int table_find(char *id); /* 在符号表中查找标识符 */
void table_print(); /* 打印符号表信息 */
int table_arr_size(struct table_t t); /* 输出数组所占的空间，非数组为-1 */
int table_arr_dim(struct table_t t); /* 输出数组的维度数 */
#endif