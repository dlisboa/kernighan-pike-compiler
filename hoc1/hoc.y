// hoc program, Kernighan and Pike

%{
// These lines were added here instead of how the book describes them due to
// compiling errors in newer C versions. Some function declarations were changed
// to match newer C standards.
#include <stdio.h>
#include <ctype.h>
int yylex();
void yyerror(char*);

#define  YYSTYPE double
%}
%token NUMBER
%left '+' '-'
%left '*' '/'
%%
list: /* nothing */
	| list '\n'
	| list expr '\n' { printf("\t%.8g\n", $2); }
	;
expr: NUMBER { $$ = $1; }
	| expr '+' expr { $$ = $1 + $3; }
	| expr '-' expr { $$ = $1 - $3; }
	| expr '*' expr { $$ = $1 * $3; }
	| expr '/' expr { $$ = $1 / $3; }
	| '(' expr ')' { $$ = $2; }
	;
%%

char *progname;
int lineno = 1;

int yylex() {
	int c;
	while ((c=getchar()) == ' ' || c == '\t')
		;
	if (c == EOF) {
		return 0;
	}
	if (c == '.' || isdigit(c)) { // number
		ungetc(c, stdin);
		scanf("%lf", &yylval);
		return NUMBER;
	}
	if (c == '\n') {
		lineno++;
	}

	return c;
}

void warning(char* s, char* t) {
	fprintf(stderr, "%s: %s", progname, s);
	if (t) {
		fprintf(stderr, " %s", t);
	}
	fprintf(stderr, " near line %d\n", lineno);
}

void yyerror(char *s) {
	warning(s, (char*)0);
}

int main(int argc, char** argv) {
	progname = argv[0];
	yyparse();
}
