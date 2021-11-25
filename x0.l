%{
#include "stdio.h"
#include "string.h"
#include "malloc.h"
#include "x0.tab.h"

int line=1;
void yyerror(char *);
int yywrap(void);
%}

%%
[ \t]	{;}
[\n]	{line++;}
"main"	{return MAINSYM;}
"{"		{return LBRACE;}
"}"		{return RBRACE;}
"["		{return LBRACKET;}
"]"		{return RBRACKET;}
";"		{return SEMICOLON;}
"int"	{return INTSYM;}
"char"	{return CHARSYM;}
"if"	{return IFSYM;}
"("		{return LPAREN;}
")"		{return RPAREN;}
"else"	{return ELSESYM;}
"while"	{return WHILESYM;}
"write"	{return WRITESYM;}
"read"	{return READSYM;}
"="		{return BECOMES;}
"<"		{return LSS;}
"<="	{return LEQ;}
">"		{return GTR;}
">="	{return GEQ;}
"=="	{return EQ;}
"!="	{return NEQ;}
"+"		{return PLUS;}
"-"		{return MINUS;}
"*"		{return TIMES;}
"/"		{return	SLASH;}

[A-Za-z]([A-Za-z]|[0-9])*	{yylval.ident=(char *)malloc(strlen(yytext)+1);
                                 strcpy(yylval.ident,yytext);
                                 return ID;
}
[0-9]+	{yylval.number=atoi(yytext);
	 return NUM;}
(\/\*).*(\*\/) {}
.	{yyerror("Unknown character!");}

%%

void redirectInput(FILE *input)
{
	yyin=input;
}

int yygetchar(void)
{
	int ret;
	ret = getc(yyin);
	printf("%c",ret);
	return ret;
}

int yywrap(void)
{
	return 1;
}
