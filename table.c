#include "table.h"
#include <string.h>
#include <stdio.h>

/* 在符号表中加入一个标识符 */
void table_register(enum id_type t,int is_const) {
	table[tbl_tail].type = t;
	table[tbl_tail].is_const = is_const;
	strcpy(table[tbl_tail].name, id_buf);
	table[tbl_tail].const_val =  const_buf;
	for (int i = 0;i < MAX_ARR_DIM;++i)
		table[tbl_tail].len[i] = len_buf[i];
	++tbl_tail;
}

/* 在符号表中查找标识符 */
int table_find(char *id) {
	for (int i = 0;i < tbl_tail;++i)
		if (!strcmp(table[i].name, id))
			return i;
	return -1;
}

void table_print() {
	printf("\n===Symbol Table===\n");
	printf("NAME\tTYPE\tCONST\tADDR\tCVAL\tLEN\n");
	for (int i = 0;i < tbl_tail;++i) {
		printf("%s\t%d\t%d\t%d\t%d\t", table[i].name, table[i].type, table[i].is_const, table[i].addr, table[i].const_val);
		for (int j = 0;j < MAX_ARR_DIM;++j)
			printf((j == MAX_ARR_DIM - 1) ? "%d\n" : "%d,",table[i].len[j]);
	}
}

int table_arr_size(struct table_t t) {
	int r = 1;
	if (t.len[0] == -1)
		return -1;
	for (int i = 0;i < MAX_ARR_DIM;++i) {
		if (t.len[i] == -1)
			break;
		r *= t.len[i];
	}
	return r;
}

int table_arr_dim(struct table_t t) {
	int r = 0;
	for (;r < MAX_ARR_DIM;++r)
		if (t.len[r] == -1)
			break;
	return r;
}