%{
#include "parser.hpp"
%}

%%

"do"        { return DO; }
"while"     { return WHILE; }
"print"     { return PRINT; }
"++"        { return INC; }
"--"        { return DEC; }
"<"         { return LT; }
">"         { return GT; }
"("         { return LPAREN; }
")"         { return RPAREN; }
"{"         { return LBRACE; }
"}"         { return RBRACE; }
";"         { return SEMICOLON; }
[a-zA-Z][a-zA-Z0-9_]* { yylval.str = new std::string(yytext); return VAR; }
[0-9]+      { yylval.ival = atoi(yytext); return NUMBER; }
[ \t\n]+    { /* skip whitespace */ }
.           { return yytext[0]; }

%%

int yywrap() { return 1; }