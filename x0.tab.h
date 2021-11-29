/* A Bison parser, made by GNU Bison 3.5.1.  */

/* Bison interface for Yacc-like parsers in C

   Copyright (C) 1984, 1989-1990, 2000-2015, 2018-2020 Free Software Foundation,
   Inc.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

/* Undocumented macros, especially those whose name start with YY_,
   are private implementation details.  Do not rely on them.  */

#ifndef YY_YY_X0_TAB_H_INCLUDED
# define YY_YY_X0_TAB_H_INCLUDED
/* Debug traces.  */
#ifndef YYDEBUG
# define YYDEBUG 0
#endif
#if YYDEBUG
extern int yydebug;
#endif

/* Token type.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
  enum yytokentype
  {
    MAINSYM = 258,
    IFSYM = 259,
    ELSESYM = 260,
    WHILESYM = 261,
    READSYM = 262,
    WRITESYM = 263,
    CONSTSYM = 264,
    LBRACE = 265,
    RBRACE = 266,
    LBRACKET = 267,
    RBRACKET = 268,
    SEMICOLON = 269,
    LPAREN = 270,
    RPAREN = 271,
    DOSYM = 272,
    REPEATSYM = 273,
    UNTILSYM = 274,
    FORSYM = 275,
    BECOMES = 276,
    LSS = 277,
    LEQ = 278,
    GTR = 279,
    GEQ = 280,
    EQ = 281,
    NEQ = 282,
    PLUS = 283,
    MINUS = 284,
    TIMES = 285,
    SLASH = 286,
    MOD = 287,
    AND = 288,
    OR = 289,
    BAND = 290,
    BOR = 291,
    BXOR = 292,
    SHIFTL = 293,
    SHIFTR = 294,
    NOT = 295,
    BNOT = 296,
    ODD = 297,
    INTSYM = 298,
    CHARSYM = 299,
    BOOLSYM = 300,
    FLOATSYM = 301,
    ID = 302,
    NUM = 303
  };
#endif

/* Value type.  */
#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
union YYSTYPE
{
#line 31 "x0.y"

char *ident;
struct lit_const* lit_c;
int number;
int id_t;
struct arr_dim* arr_dim;
struct var_info* var_inf;

#line 115 "x0.tab.h"

};
typedef union YYSTYPE YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define YYSTYPE_IS_DECLARED 1
#endif


extern YYSTYPE yylval;

int yyparse (void);

#endif /* !YY_YY_X0_TAB_H_INCLUDED  */
