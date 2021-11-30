%{
#include "stdio.h"
#include "string.h"
#include "malloc.h"
#include "x0.tab.h"
#include "sdt_structs.h"

int line=1;
void yyerror(char *);
int yywrap(void);
%}

%%
[ \t]		{;}
[\n]		{line++;}
"main"		{return MAINSYM;}
"{"			{return LBRACE;}
"}"			{return RBRACE;}
"["			{return LBRACKET;}
"]"			{return RBRACKET;}
";"			{return SEMICOLON;}
"int"		{yylval.id_t=0;return INTSYM;}
"char"		{yylval.id_t=1;return CHARSYM;}
"if"		{return IFSYM;}
"("			{return LPAREN;}
")"			{return RPAREN;}
"else"		{return ELSESYM;}
"while"		{return WHILESYM;}
"write"		{return WRITESYM;}
"read"		{return READSYM;}
"="			{return BECOMES;}
"<"			{return LSS;}
"<="		{return LEQ;}
">"			{return GTR;}
">="		{return GEQ;}
"=="		{return EQ;}
"!="		{return NEQ;}
"+"			{return PLUS;}
"-"			{return MINUS;}
"*"			{return TIMES;}
"/"			{return	SLASH;}

"%"			{return MOD;}
"and"		{return AND;}
"or"		{return OR;}
"not"		{return NOT;}
"bool"		{yylval.id_t=2;return BOOLSYM;}
"float" 	{yylval.id_t=3;return FLOATSYM;}
"const" 	{return CONSTSYM;}
"do"		{return DOSYM;}
"repeat"	{return REPEATSYM;}
"until"		{return UNTILSYM;}
"&"			{return BAND;}
"|"			{return BOR;}
"~"			{return BNOT;}
"^"			{return BXOR;}
"<<"		{return SHIFTL;}
">>"		{return SHIFTR;}
"odd"		{return ODD;}
"for"		{return FORSYM;}
"++"		{return INC;}
"--"		{return DEC;}

"true"  {yylval.lit_c = (struct lit_const*)malloc(sizeof(struct lit_const));
	yylval.lit_c -> t = xbool;
	yylval.lit_c -> val = 1;
	return NUM;}
"false" {yylval.lit_c = (struct lit_const*)malloc(sizeof(struct lit_const));
	yylval.lit_c -> t = xbool;
	yylval.lit_c -> val = 0;
	return NUM;}

[A-Za-z]([A-Za-z]|[0-9])*	{yylval.ident=(char *)malloc(strlen(yytext)+1);
                                 strcpy(yylval.ident,yytext);
                                 return ID;
}
[0-9]+\.[0-9]+ {yylval.lit_c = (struct lit_const*)malloc(sizeof(struct lit_const));
	yylval.lit_c -> t = xfloat;
	sscanf(yytext,"%f",(float*)(&(yylval.lit_c -> val)));
	return NUM;}
[0-9]+	{yylval.lit_c = (struct lit_const*)malloc(sizeof(struct lit_const));
	yylval.lit_c -> t = xint;
	yylval.lit_c -> val = atoi(yytext);
	return NUM;}
'[\0-\177]' {yylval.lit_c = (struct lit_const*)malloc(sizeof(struct lit_const));
	yylval.lit_c -> t = xchar;
	yylval.lit_c -> val = yytext[1];
	return NUM;}
(\/\*).*(\*\/) {}
.	{yyerror("Unknown character!");}

%%

void redirectInput(FILE *input) {
	yyin=input;
}

int yygetchar(void) {
	int ret;
	ret = getc(yyin);
	printf("%c",ret);
	return ret;
}

int yywrap(void) {
	return 1;
}
