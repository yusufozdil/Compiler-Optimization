yacc -d proje.y
lex proje.l  
gcc y.tab.c lex.yy.c -o proje -ll
./proje < input.txt