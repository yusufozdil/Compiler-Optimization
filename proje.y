%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <math.h>

int yylex();

int yyerror(const char *s);

typedef struct Node {
    char *id;
    int value;
    int usage_count;
} Node;

Node symbol_table[100];
int symbol_count = 0;
int valid = 1; // Flag for error handling

Node* lookup(char *id) {
    for (int i = 0; i < symbol_count; i++) {
        if (strcmp(symbol_table[i].id, id) == 0) {
            return &symbol_table[i];
        }
    }
    return NULL;
}

void insert(char *id, int value) {
    Node *node = lookup(id);
    if (node) {
        node->value = value;
    } else {
        symbol_table[symbol_count].id = strdup(id);
        symbol_table[symbol_count].value = value;
        symbol_table[symbol_count].usage_count = 0;
        symbol_count++;
    }
}

void print_table() {

    // Symbol Table
    printf("\nSymbol Table:\n");
    printf("----------\n");
    for (int i = 0; i < symbol_count; i++) {
        if (symbol_table[i].usage_count != 0) {
            printf("| %s = %d (Usage: %d)\n", symbol_table[i].id, symbol_table[i].value, symbol_table[i].usage_count);
        } 
    }
    printf("----------\n");

    // Dead Code Elimination
    printf("\nEliminated by Dead Code Elimination\n");
    printf("----------\n");
    for (int i = 0; i < symbol_count; i++) {
        if (symbol_table[i].usage_count == 0) {
            printf("| %s = %d (No consumers)\n", symbol_table[i].id, symbol_table[i].value);
        } 
    }
    printf("----------\n");

}   
%}

%union {
    int num;        // For calculating the value of the expression
    char *str;      // For storing the expression
    struct {
        char *expr; // Expression
        int value;  // Calculated value
    } full;
}

%token <num> NUMBER
%token <str> ID
%token ASSIGN PLUS MINUS MULTIPLY DIVIDE EXPONENT SEMICOLON
%type <full> expression

%left PLUS MINUS
%left MULTIPLY DIVIDE
%right EXPONENT

%%

program:
    program statement SEMICOLON
    | statement SEMICOLON
    ;

statement:
    ID ASSIGN expression {
        Node *node = lookup($1);
        if (node) {
            if ($3.value == node->value) {
                printf("Deleted: %s = %s; Because the code has no meaningful efect.\n", $1, $3.expr); // Algebraic Simplification
            } else if(valid){
                insert($1, $3.value);
                printf("%s = %s;   %d\n", $1, $3.expr, $3.value);
            }
        } else if(valid){
            insert($1, $3.value);
            printf("%s = %s;   %d\n", $1, $3.expr, $3.value);
        }
        valid = 1; // Reset the flag
    }
    ;

expression:
    expression PLUS expression {
        if ($1.value == 0) {
            $$.value = $3.value;
            asprintf(&$$.expr, "%s + %s", $1.expr, $3.expr);
        } else if ($3.value == 0) {
            $$.value = $1.value;
            asprintf(&$$.expr, "%s + %s", $1.expr, $3.expr);
        } else {
            $$.value = $1.value + $3.value;
            asprintf(&$$.expr, "%s + %s", $1.expr, $3.expr);
        }
    }
    | expression MINUS expression {
        if ($3.value == 0) {
            $$.value = $1.value;
            asprintf(&$$.expr, "%s - %s", $1.expr, $3.expr);
        } else {
            $$.value = $1.value - $3.value;
            asprintf(&$$.expr, "%s - %s", $1.expr, $3.expr);
        }
    }
    | expression MULTIPLY expression {
        if ($1.value == 0 || $3.value == 0) {
            $$.value = 0;
            asprintf(&$$.expr, "%s * %s", $1.expr, $3.expr);
        } else if ($1.value == 1) {
            $$.value = $3.value;
            asprintf(&$$.expr, "%s * %s", $1.expr, $3.expr);
        } else if ($3.value == 1) {
            $$.value = $1.value;
            asprintf(&$$.expr, "%s * %s", $1.expr, $3.expr);
        } else {
            $$.value = $1.value * $3.value;
            asprintf(&$$.expr, "%s * %s", $1.expr, $3.expr);
        }
    }
    | expression DIVIDE expression {
        if ($3.value == 0) {
            yyerror("Division by zero");
            valid = 0;
        }else if($1.value == 0){
            $$.value = 0;
            asprintf(&$$.expr, "%s / %s", $1.expr, $3.expr);
        } else {
            $$.value = $1.value / $3.value;
            asprintf(&$$.expr, "%s / %s", $1.expr, $3.expr);
        }
    }
    | expression EXPONENT expression {
        if($3.value==2){
            $$.value = $1.value * $1.value;
            asprintf(&$$.expr, "%s ^ %s", $1.expr, $3.expr);
        } else if($3.value == 0) {
            $$.value = 1;
            asprintf(&$$.expr, "%s ^ %s", $1.expr, $3.expr);
        } else if($3.value == 1){
            $$.value = $1.value;
            asprintf(&$$.expr, "%s ^ %s", $1.expr, $3.expr);
        } else if($1.value == 0) {
            $$.value = 0;
            asprintf(&$$.expr, "%s ^ %s", $1.expr, $3.expr);
        } else if($1.value == 1) {
            $$.value = 1;
            asprintf(&$$.expr, "%s ^ %s", $1.expr, $3.expr);
        } else {
            $$.value = (int)pow($1.value, $3.value);
            asprintf(&$$.expr, "%s ^ %s", $1.expr, $3.expr);
        }
    }
    | NUMBER {
        $$.value = $1;
        asprintf(&$$.expr, "%d", $1);
    }
    | ID {
        Node *node = lookup($1);
        if (node) {
            $$.value = node->value; // Constant propagation
            asprintf(&$$.expr, "%s", $1);
            node->usage_count++;
        } else {
            $$.value = 0;
            asprintf(&$$.expr, "%s", $1);
        }
    }
;
%%

int yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
    return 0;
}

int main() {
    printf("Enter your code:\n");
    yyparse();
    print_table();
    return 0;
}
