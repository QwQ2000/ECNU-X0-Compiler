#include "table.h"
#include <string.h>

/* 在符号表中加入一个标识符 */
void table_register(enum id_type t,int is_const) {
	++tbl_tail;
	table[tbl_tail].type = t;
	table[tbl_tail].is_const = is_const;
	strcpy(table[tbl_tail].name, id_buf);
	memcpy(table[tbl_tail].const_val, const_buf, sizeof(const_buf));
	memcpy(table[tbl_tail].len, len_buf, sizeof(len_buf));
}

/* 在符号表中查找标识符 */
int table_find(char *id) {
	int i;
	strcpy(table[0].name, id);
	i = tbl_tail;
	while (strcmp(table[i].name, id) != 0)
		i--;
	return i;
}