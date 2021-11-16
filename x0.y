////////////////////////////////////////////////////////
//声明部分
%{
#include<stdio.h>
#include<stdlib.h>
#include<malloc.h>
#include<memory.h>
#include<string.h>


#define txmax 100     /* 符号表容量 */
#define al 10         /* 标识符的最大长度 */

/* 符号表中的类型 */
enum object {
    var, 
    array,
};

/* 符号表结构 */
struct tablestruct
{
   char name[al];     /* 名字 */
   enum object type;  /* 类型：var或array */
   int len; /*数组长度：-1或长度*/
};
struct tablestruct table[txmax]; /* 符号表 */


int tx;         /* 符号表当前尾指针 */
char id[al];

FILE* fin;      /* 输入源文件 */
FILE* foutput;  /* 输出出错示意（如有错） */
char fname[al];
int err;
extern int line; 

void init();
void enter(enum object k,int len);
int position(char *s);
%}

////////////////////////////////////////////////////////
//辅助定义部分
%union{
char *ident;
int number;
}


%token MAINSYM, INTSYM, CHARSYM, IFSYM, ELSESYM, WHILESYM, READSYM, WRITESYM
%token LBRACE, RBRACE, LBRACKET, RBRACKET, SEMICOLON, LPAREN, RPAREN
%token BECOMES, LSS, LEQ, GTR, GEQ, EQ, NEQ, PLUS, MINUS, TIMES, SLASH

%token <ident> ID
%token <number> NUM

%type <number> ident
%type <number> var

%start program

////////////////////////////////////////////////////////
//规则部分
%%
/* 程序 */
program: MAINSYM LBRACE decl_list stat_list RBRACE | ;

decl_list: decl_list decl_stat 
| decl_stat 
| ;

decl_stat: type ID SEMICOLON 
            {
                strcpy(id, $2); 
                enter(var,-1);
            }
| type ID LBRACKET NUM RBRACKET SEMICOLON
    {
        strcpy(id, $2);
        if ($4 <= 0)
            yyerror("Invalid array length"); 
        enter(var, $4);
    };

type: INTSYM | CHARSYM ;

var: ident 
        {
            if ($1 == 0)
                yyerror("Symbol does not exist");
            else {
                if (table[$1].type != var)
                    yyerror("Symbol should be a variable");
            }
            $$ = $1;
        }
| ident LBRACKET expr RBRACKET
    {
        if ($1 == 0)
                yyerror("Symbol does not exist");
        else {
            if (table[$1].type != var)
                yyerror("Symbol should be an array");
        }
        $$ = $1;
    };

stat_list: stat_list stat | ;

stat: if_stat | while_stat | read_stat 
| write_stat | comp_stat | expr_stat ; 

if_stat: IFSYM LPAREN expr RPAREN stat 
| IFSYM LPAREN expr RPAREN stat ELSESYM stat ;

while_stat: WHILESYM LPAREN expr RPAREN stat ;

write_stat: WRITESYM expr SEMICOLON ;

read_stat: READSYM var SEMICOLON ;

comp_stat: LBRACE stat_list RBRACE ;

expr_stat: expr SEMICOLON | SEMICOLON ;

expr: var BECOMES expr 
| simple_expr ;

simple_expr: add_expr 
| add_expr LSS add_expr
| add_expr LEQ add_expr 
| add_expr GEQ add_expr
| add_expr GTR add_expr
| add_expr EQ add_expr
| add_expr NEQ add_expr ;

add_expr: term 
| term PLUS term
| term MINUS term ;

term: factor
| factor TIMES factor
| factor SLASH factor ; 

factor: NUM 
| var 
| LPAREN expr RPAREN ;

ident: ID 
         {
            $$ = position($1); 
         } ;


////////////////////////////////////////////////////////
//程序部分
%%
int yyerror(char *s)
{
	err = err + 1;
    printf("%s in line %d\n", s, line);
	fprintf(foutput, "%s in line %d\n", s, line);
	return 0;
}

void init()
{
	tx = 0;
    err = 0;
}

void enter(enum object k,int len)
{
	tx = tx + 1;
	strcpy(table[tx].name, id);
	table[tx].type = k;
    table[tx].len = len;
}

int position(char *s)
{
	int i;
	strcpy(table[0].name, s);
	i = tx;
	while(strcmp(table[i].name, s) != 0)
		i--;
	return i;
}

int main(int argc,char **argv)
{
    char* out_file_name = NULL;
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
		fprintf(foutput, "\n===Parsing success!===\n");
	} else {
		printf("%d errors in x0 program\n", err);
		fprintf(foutput, "%d errors in x0 program\n", err);
	}
    
    fclose(foutput);
	fclose(fin);
	
    return 0;
}
