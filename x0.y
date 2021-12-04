////////////////////////////////////////////////////////
//声明部分
%{
#include <stdio.h>
#include <stdlib.h>
#include <malloc.h>
#include <memory.h>
#include <string.h>

#include "table.h"
#include "vm.h"
#include "sdt_structs.h"

FILE* fin;      
FILE* foutput;  
char fname[MAX_ID_LEN];

int err;
extern int line; 
int proc_table_bot, addr, len_prod[MAX_ARR_DIM];
float float_buf;

void init();
void gen_var_code(int tbl_idx);

#define MIN(a,b) (((a)<(b))?(a):(b))

//#define YYDEBUG 1
%}

////////////////////////////////////////////////////////
//辅助定义部分

%union{
char *ident;
struct lit_const* lit_c;
int number;
int id_t;
struct arr_dim* arr_dim;
struct var_info* var_inf;
struct case_list* clist;
}

%token MAINSYM, IFSYM, ELSESYM, WHILESYM, READSYM, WRITESYM, CONSTSYM
%token LBRACE, RBRACE, LBRACKET, RBRACKET, SEMICOLON, LPAREN, RPAREN 
%token DOSYM, REPEATSYM, UNTILSYM, FORSYM, INC, DEC, SWITCHSYM
%token CASESYM, COLON

%right NOT, BNOT, ODD
%left TIMES, SLASH, MOD, BAND, BOR, BXOR, SHIFTL, SHIFTR
%left PLUS, MINUS
%left AND, OR
%left LSS, LEQ, GTR, GEQ, EQ, NEQ
%left BECOMES

%token <id_t> INTSYM, CHARSYM, BOOLSYM, FLOATSYM
%token <ident> ID
%token <lit_c> NUM

%type <number> ident
%type <number> var, arr_offset, code_addr, else_stat
%type <id_t> type, expr, simple_expr, add_expr, term, factor, logic_expr
%type <arr_dim> dim_list
%type <clist> case_list

%start program

////////////////////////////////////////////////////////
//规则部分
%%
/* 程序 */
program: proc_list MAINSYM LBRACE 
                            {
                                proc_table_bot = tbl_tail;
                            }
decl_list
    {            
        addr = 2;
        for (int i = proc_table_bot;i < tbl_tail;++i) {
            if (table[i].is_const)
                continue;
            table[i].addr = addr++;
            if (table_arr_size(table[i]) != -1)
                addr += table_arr_size(table[i]);
        }
        vm_gen(ini,addr);
    }
stat_list RBRACE | ;

proc_list: ;

decl_list: decl_stat decl_list 
| decl_stat 
| ;

decl_stat: type ID SEMICOLON // 变量声明
            {
                strcpy(id_buf, $2);
                memset(len_buf,-1,sizeof(len_buf)); // 非数组的变量，用数组各维度长度均为-1表示 
                table_register($1, 0);
            }
| CONSTSYM type ID BECOMES NUM SEMICOLON // 常量声明
    {
        strcpy(id_buf, $3);
        memset(len_buf,-1,sizeof(len_buf)); // 由于不支持数组常量，则常量不可能是数组，用数组各维度长度均为-1表示 
        const_buf = *(int*)(&($5->val));
        table_register($2, 1);    
    }
| type ID dim_list SEMICOLON //数组声明
    {
        strcpy(id_buf, $2);
        memset(len_buf,-1,sizeof(len_buf));
        for (int i = 0;i < $3->d;++i)
            len_buf[i] = $3->len[i];
        table_register($1, 0);
    };

dim_list: LBRACKET NUM RBRACKET // 数组声明所用的下标列表
            {
                $$ = (struct arr_dim*)malloc(sizeof(struct arr_dim));
                $$->len[0] = $2->val;
                $$->d = 1;
            }
| dim_list LBRACKET NUM RBRACKET
    {
        if ($$->d == 5)
            yyerror("Too many array dimensions!");
        $$->len[$$->d++] = $3->val;
    };

type: INTSYM {$$ = $1;} | CHARSYM {$$ = $1;} | BOOLSYM {$$ = $1;} | FLOATSYM {$$ = $1;};

stat_list: stat_list stat | ;

stat: if_stat | while_stat | read_stat 
| write_stat | comp_stat | expr_stat
| for_stat | switch_stat {}; 

switch_stat: SWITCHSYM LPAREN expr 
                                { 
                                    vm_gen(adr, 0);
                                    vm_gen(lit, 1);
                                    vm_gen(arti, 1);
                                    vm_gen(mov, 0); // 将expr计算结果的地址存入辅助栈，便于后续反复读取
                                } 
RPAREN  LBRACE case_list RBRACE 
    { 
        vm_gen(pop, 0); // 消耗掉expr的值
        vm_gen(pop, 1); // 消耗掉辅助栈中expr结果的地址 
        
        for (int i = 0;i < $7 -> len; ++i) // 检查expr和case中常数的类型是否匹配
            if ($7 -> t[i] == 3 && $3 != 3 || $7 -> t[i] != 3 && $3 == 3)
                yyerror("Incompatible value type in switch-case statement!");
        for (int i = 0;i < $7 -> len - 1; ++i) // 回填jpc指令
            vcode[$7 -> beg_pos[i] + 3].a = $7 -> beg_pos[i + 1];
        vcode[$7 -> beg_pos[$7 -> len - 1] + 3].a = $7 -> end_pos; // 回填最后一个case的jpc指令
    };

case_list: CASESYM NUM COLON code_addr 
                        {
                            $<clist>$ = (struct case_list*)malloc(sizeof(struct case_list));
                            $<clist>$ -> len = 1;
                            $<clist>$ -> beg_pos[0] = $4;
                            $<clist>$ -> t[0] = $2 -> t;
                            vm_gen(lit, $2 -> val); // 将当前case的值放入栈顶
                            vm_gen(lodr, 0); // 将switch小括号中的表达式值放入栈顶
                            if ($2 -> t == 3)
                                vm_gen(cmpf, 4);
                            else
                                vm_gen(cmpi, 4);
                            vm_gen(jpc, -1); // 二者不相等则跳转，等待回填
                        } stat code_addr
                            {
                                $$ = $<clist>5; 
                                $$ -> end_pos = $7;
                            }
| case_list CASESYM NUM COLON code_addr 
                                        {
                                            $<clist>$ = $1;
                                            $<clist>$ -> beg_pos[$<clist>$ -> len] = $5;
                                            $<clist>$ -> t[$<clist>$ -> len++] = $3 -> t;
                                            vm_gen(lit, $3 -> val); // 将当前case的值放入栈顶
                                            vm_gen(lodr, 0); // 将switch小括号中的表达式值放入栈顶
                                            if ($3 -> t == 3)
                                                vm_gen(cmpf, 4);
                                            else
                                                vm_gen(cmpi, 4);
                                            vm_gen(jpc, -1); // 二者不相等则跳转，等待回填
                                        } stat code_addr { $$ = $<clist>6; $$ -> end_pos = $8;};

if_stat: IFSYM LPAREN expr RPAREN code_addr   
                                    {
                                        vm_gen(jpc, 0);
                                    } 
stat else_stat   
        {
            vcode[$5].a = $8;
        };

else_stat: ELSESYM code_addr  
                    {
                        vm_gen(jmp, 0);
                    } 
stat   
    {
        $$ = $2 + 1;
        vcode[$2].a = code_cnt;
    }
| { $$ = code_cnt; };

while_stat: WHILESYM code_addr LPAREN expr RPAREN code_addr 
                                                    {
                                                        vm_gen(jpc, 0);
                                                    }
stat
    {
        vm_gen(jmp, $2);
        vcode[$6].a = code_cnt;
    }
| DOSYM code_addr stat WHILESYM LPAREN expr 
                                        {
                                            vm_gen(log, 2);
                                            vm_gen(jpc, $2);
                                        }
RPAREN SEMICOLON
| REPEATSYM code_addr stat UNTILSYM LPAREN expr 
                                            {
                                                vm_gen(jpc, $2);
                                            }
RPAREN SEMICOLON;

for_stat: FORSYM LPAREN for_expr SEMICOLON code_addr for_expr SEMICOLON code_addr
                                                                        {
                                                                            vm_gen(jpc, 0);
                                                                            vm_gen(jmp, 0);
                                                                        }
for_expr 
    {
        vm_gen(jmp, $5);
    }
RPAREN code_addr stat
                    {
                        vm_gen(jmp, $8 + 2);
                        vcode[$8].a = code_cnt;
                        vcode[$8 + 1].a = $13;
                    };

for_expr: expr | ;

write_stat: WRITESYM expr SEMICOLON 
    {
        vm_gen(wrt, $2);
    };

read_stat: READSYM var SEMICOLON 
    {
        vm_gen(red, table[$2].type);
        vm_gen(sto, table[$2].addr);
    };

comp_stat: LBRACE stat_list RBRACE ;

expr_stat: expr SEMICOLON
            {
                vm_gen(pop,0);
            }
| SEMICOLON;

expr: var BECOMES expr 
        {
            $$ = $3;

            if (table[$1].is_const) 
                yyerror("Assigning value to a constant variable!");
            else if (table[$1].len[0] != -1) {
                vm_gen(stor,0);
                vm_gen(lodr,0);
                vm_gen(pop, 1);
            } else {
                vm_gen(sto,table[$1].addr);
                vm_gen(lod,table[$1].addr);
            }
        }
| logic_expr 
    {
        $$ = $1;
    };

logic_expr: simple_expr
                {
                    $$ = $1;
                }
| simple_expr AND simple_expr
    {
        $$ = 2;
        vm_gen(log, 0);
    }
| simple_expr OR simple_expr
    {
        $$ = 2;
        vm_gen(log, 1);
    }
| NOT simple_expr
    {
        $$ = 2;
        vm_gen(log, 2);
    };

simple_expr: add_expr 
                {
                    $$ = $1;
                }
| add_expr GTR add_expr
    {
        $$ = 2;
        if ($1 == $3 && $1 == 3) 
            vm_gen(cmpf,0);
        else if ($1 != 3 && $3 != 3)
            vm_gen(cmpi,0);
        else
            yyerror("Incompatible types in comparison operation!");
    }
| add_expr GEQ add_expr
    {
        $$ = 2;
        if ($1 == $3 && $1 == 3) 
            vm_gen(cmpf,1);
        else if ($1 != 3 && $3 != 3)
            vm_gen(cmpi,1);
        else
            yyerror("Incompatible types in comparison operation!");
    }
| add_expr LSS add_expr
    {
        $$ = 2;
        if ($1 == $3 && $1 == 3) 
            vm_gen(cmpf,2);
        else if ($1 != 3 && $3 != 3)
            vm_gen(cmpi,2);
        else
            yyerror("Incompatible types in comparison operation!");
    }
| add_expr LEQ add_expr
    {
        $$ = 2;
        if ($1 == $3 && $1 == 3) 
            vm_gen(cmpf,3);
        else if ($1 != 3 && $3 != 3)
            vm_gen(cmpi,3);
        else
            yyerror("Incompatible types in comparison operation!");
    }
| add_expr EQ add_expr
    {
        $$ = 2;
        if ($1 == $3 && $1 == 3) 
            vm_gen(cmpf,4);
        else if ($1 != 3 && $3 != 3)
            vm_gen(cmpi,4);
        else
            yyerror("Incompatible types in comparison operation!");
    }
| add_expr NEQ add_expr 
    {
        $$ = 2;
        if ($1 == $3 && $1 == 3) 
            vm_gen(cmpf,5);
        else if ($1 != 3 && $3 != 3)
            vm_gen(cmpi,5);
        else
            yyerror("Incompatible types in comparison operation!");
    };

add_expr: term 
            {
                $$ = $1;
            }
| term PLUS term
    {
        if ($1 == $3 && $1 == 3) 
            vm_gen(artf,0);
        else if ($1 != 3 && $3 != 3)
            vm_gen(arti,0);
        else
            yyerror("Incompatible types in arithmetic operation!");
        $$ = MIN($1,$3);
    }
| term MINUS term 
    {
        if ($1 == $3 && $1 == 3) 
            vm_gen(artf,1);
        else if ($1 != 3 && $3 != 3)
            vm_gen(arti,1);
        else
            yyerror("Incompatible types in arithmetic operation!");
        $$ = MIN($1,$3);
    };

term: factor 
        {
            $$ = $1;
        }
| factor TIMES factor
    {
        if ($1 == $3 && $1 == 3) 
            vm_gen(artf,2);
        else if ($1 != 3 && $3 != 3)
            vm_gen(arti,2);
        else
            yyerror("Incompatible types in arithmetic operation!");
        $$ = MIN($1,$3);
    }
| factor SLASH factor 
    {
        if ($1 == $3 && $1 == 3) 
            vm_gen(artf,3);
        else if ($1 != 3 && $3 != 3)
            vm_gen(arti,3);
        else
            yyerror("Incompatible types in arithmetic operation!");
        $$ = MIN($1,$3);
    }
| factor MOD factor
    {
        if ($1 != 3 && $3 != 3)
            vm_gen(arti,4);
        else
            yyerror("Incompatible types in arithmetic operation!");
        $$ = MIN($1,$3);
    }
| factor BAND factor
    {
        if ($1 != 3 && $3 != 3)
            vm_gen(bit, 0);
        else
            yyerror("Incompatible types in bit-wise operation!");
        $$ = MIN($1,$3);
    }
| factor BOR factor
    {
        if ($1 != 3 && $3 != 3)
            vm_gen(bit, 1);
        else
            yyerror("Incompatible types in bit-wise operation!");
        $$ = MIN($1,$3);
    }
| BNOT factor
    {
        if ($2 != 3)
            vm_gen(bit, 2);
        else
            yyerror("Incompatible types in bit-wise operation!");
        $$ = $2;
    }
| factor BXOR factor
    {
        if ($1 != 3 && $3 != 3)
            vm_gen(bit, 3);
        else
            yyerror("Incompatible types in bit-wise operation!");
        $$ = MIN($1,$3);
    }
| factor SHIFTL factor
    {
        if ($1 != 3 && $3 != 3)
            vm_gen(bit, 4);
        else
            yyerror("Incompatible types in bit-wise operation!");
        $$ = MIN($1,$3);
    }
| factor SHIFTR factor
    {
        if ($1 != 3 && $3 != 3)
            vm_gen(bit, 5);
        else
            yyerror("Incompatible types in bit-wise operation!");
        $$ = MIN($1,$3);
    }
| ODD factor 
    {
        if ($2 != 3) {
            vm_gen(lit, 1);
            vm_gen(bit, 0);
        } else
            yyerror("Incompatible types in odd/even classification!");
        $$ = $2;
    }; 

factor: NUM 
        {
            $$ = $1 -> t;
            vm_gen(lit, $1 -> val);
        }
| var 
    {
        $$ = table[$1].type;
        if (table[$1].is_const)
            vm_gen(lit,table[$1].const_val);
        else gen_var_code($1);
    }
| INC var
    {
        $$ = table[$2].type;
        if (table[$2].is_const)
            yyerror("Using self-increment operation on constant values");
        else
            gen_var_code($2);
        if (table[$2].type == 3) {
            float_buf = 1;
            vm_gen(lit, F2I(float_buf));
            vm_gen(artf, 0);
            vm_gen(sto, table[$2].addr);
            vm_gen(lod, table[$2].addr);
        } else {
            vm_gen(lit, 1);
            vm_gen(arti, 0);
            vm_gen(sto, table[$2].addr);
            vm_gen(lod, table[$2].addr);
        }
    }
| DEC var
    {
        $$ = table[$2].type;
        if (table[$2].is_const)
            yyerror("Using self-decrement operation on constant values");
        else
            gen_var_code($2);
        if (table[$2].type == 3) {
            float_buf = 1;
            vm_gen(lit, F2I(float_buf));
            vm_gen(artf, 1);
            vm_gen(sto, table[$2].addr);
            vm_gen(lod, table[$2].addr);
        } else {
            vm_gen(lit, 1);
            vm_gen(arti, 1);
            vm_gen(sto, table[$2].addr);
            vm_gen(lod, table[$2].addr);
        }
    }
| var INC
    {
        $$ = table[$1].type;
        if (table[$1].is_const)
            yyerror("Using self-increment operation on constant values");
        else
            gen_var_code($1);
        if (table[$1].type == 3) {
            float_buf = 1;
            vm_gen(lit, F2I(float_buf));
            vm_gen(artf, 0);
            vm_gen(sto, table[$1].addr);
            vm_gen(lod, table[$1].addr);
            vm_gen(lit, F2I(float_buf));
            vm_gen(artf, 1);
        } else {
            vm_gen(lit, 1);
            vm_gen(arti, 0);
            vm_gen(sto, table[$1].addr);
            vm_gen(lod, table[$1].addr);
            vm_gen(lit, 1);
            vm_gen(arti, 1);
        }
    }
| var DEC
    {
        $$ = table[$1].type;
        if (table[$1].is_const)
            yyerror("Using self-decrement operation on constant values");
        else
            gen_var_code($1);
        if (table[$1].type == 3) {
            float_buf = 1;
            vm_gen(lit, F2I(float_buf));
            vm_gen(artf, 1);
            vm_gen(sto, table[$1].addr);
            vm_gen(lod, table[$1].addr);
            vm_gen(lit, F2I(float_buf));
            vm_gen(artf, 0);
        } else {
            vm_gen(lit, 1);
            vm_gen(arti, 1);
            vm_gen(sto, table[$1].addr);
            vm_gen(lod, table[$1].addr);
            vm_gen(lit, 1);
            vm_gen(arti, 0);
        }
    }
| LPAREN expr RPAREN 
    {
        $$ = $2;
    }
| FLOATSYM LPAREN expr RPAREN
    {
        $$ = 3;
        if ($3 != 3)
            vm_gen(cvt,0);
    }
| INTSYM LPAREN expr RPAREN
    {
        $$ = 0;
        if ($3 == 3)
            vm_gen(cvt,1);
    }
| BOOLSYM LPAREN expr RPAREN
    {
        $$ = 2;
        if ($3 == 3)
            vm_gen(cvt,1);
    }
| CHARSYM LPAREN expr RPAREN
    {
        $$ = 1;
        if ($3 == 3)
            vm_gen(cvt,1);
    };

var: ident 
        {
            $$ = $1;
        }
| ident arr_offset // 数组变量的语法制导翻译，解析数组元素的偏移量，并将计算好的偏移量移入辅助栈
    {
        $$ = $1;
        if ($2 != table_arr_dim(table[$1]))
            yyerror("Incompatible array dimensions between definition and access!");
        len_prod[$2 - 1] = table[$1].len[$2 - 1];
        for (int i = $2 - 2;i > -1;--i)
            len_prod[i] = len_prod[i + 1] * table[$1].len[i];
        vm_gen(mov,0);
        for (int i = 1;i < $2; ++i) {
            vm_gen(lit, len_prod[$2 - i]);
            vm_gen(arti,2);
            vm_gen(mov,1);
            vm_gen(arti,0);
            vm_gen(mov,0);
        }
    };

arr_offset: LBRACKET expr RBRACKET // 属性指示数组有多少维度
                {
                    $$ = 1;
                } 
| arr_offset LBRACKET expr RBRACKET
    {
        $$ = $1 + 1;
        if ($$ > MAX_ARR_DIM)
            yyerror("Too many array dimensions!");
    };

ident: ID 
         {
            $$ = table_find($1);
            if ($$ == -1)
                yyerror("Symbol does not exist"); 
         };

code_addr: 
    {
        $$ = code_cnt;
    };

////////////////////////////////////////////////////////
//程序部分
%%
void gen_var_code(int tbl_idx) {
    if (table[tbl_idx].len[0] != -1) {
        vm_gen(lodr, 0);
        vm_gen(pop, 1);
    } else
        vm_gen(lod, table[tbl_idx].addr);
}

int yyerror(char *s) {
	err = err + 1;
    printf("%s in line %d\n", s, line);
	return 0;
}

void init() {
    tbl_tail = 0;
	code_cnt = 0;
    err = 0;
}

int main(int argc,char **argv) {
    char* out_file_name = NULL;

    //yydebug = 1;
    
    printf("The X0 Compiler\n");
    if (argc == 1) {
        printf("Usage:x0_compiler input_file [output_file]");
    }

	if ((fin = fopen(argv[1], "r")) == NULL) {
		printf("Can't open the input file!\n");
		exit(1);
	}
    if (argc < 3)
        out_file_name = "output.txt"; 
    else
        out_file_name = argv[2];	
	if ((foutput = fopen(out_file_name, "w")) == NULL) {
		printf("Can't open the output file!\n");
		exit(1);
	}
	
	redirectInput(fin);		
	
    init();
    yyparse();
	
    if (err == 0) {
		printf("\n===Parsing success!===\n");
        table_print();
        vm_save_ins(foutput);

        // 不使用IDE单独运行命令行编译器
        printf("\n===Start===\n");
        vm_init();
        vm_execute(stdin,stdout);
	} else
		printf("%d errors in x0 program\n", err);
    
    fclose(foutput);
	fclose(fin);
	
    return 0;
}
