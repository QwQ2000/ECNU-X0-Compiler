all: x0_compiler clean

x0_compiler: lex yacc
	gcc -o x0_compiler x0.tab.c lex.yy.c table.c vm.c

lex: x0.l
	flex x0.l

yacc: x0.y
	bison -d x0.y

clean:
	rm lex.yy.c x0.tab.c x0.tab.h