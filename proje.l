%{
#include "y.tab.h"
%}

%%

[ \t\n]+           ;                      // Skip whitespace
[0-9]+             { yylval.num = atoi(yytext); return NUMBER; }
[a-zA-Z][a-zA-Z0-9]* { yylval.str = strdup(yytext); return ID; }
"="                return ASSIGN;
"+"                return PLUS;
"-"                return MINUS;
"*"                return MULTIPLY;
"/"                return DIVIDE;
"^"                return EXPONENT;      
";"                return SEMICOLON;

.                  return yytext[0];      // Other characters

%%

int yywrap() {
    return 1;
}