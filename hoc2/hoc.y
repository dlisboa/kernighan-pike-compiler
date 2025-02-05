// hoc program, Kernighan and Pike

%{
// These lines were added here instead of how the book describes them due to
// compiling errors in newer C versions. Some function declarations were changed
// to match newer C standards.
#include <stdio.h>
#include <ctype.h>
int yylex();
void yyerror(char*);
void execerror(char*, char*);
void inspect();

double mem[26];
%}
%union {
	double val;
	int index;
}
%token <val> NUMBER
%token <index> VAR
%type <val> expr
%right '='
%left '+' '-'
%left '*' '/'
%left UNARYMINUS
%%
list: /* nothing */
	| list '\n'
	| list expr '\n' { inspect(); printf("\t%.8g\n", $2); }
	| list error '\n' { yyerrok; }
	;
expr: NUMBER { $$ = $1; }
	| VAR { $$ = mem[$1]; }
	| VAR '=' expr { $$ = mem[$1] = $3; }
	| expr '+' expr { $$ = $1 + $3; }
	| expr '-' expr { $$ = $1 - $3; }
	| expr '*' expr { $$ = $1 * $3; }
	| expr '/' expr {
		if ($3 == 0.0) {
			execerror("division by zero", (char*)0);
		}
		$$ = $1 / $3;
	}
	| '(' expr ')' { $$ = $2; }
	| '-' expr %prec UNARYMINUS { $$ = -$2; }
	;
%%

void inspect() {
	puts("--");
	puts("mem:");
	for (int i = 0; i < 26; i++) {
		if (i % 6 == 0) {
			puts("");
		}
		printf("%c: |%7.2lf| ", i + 'a', mem[i]);
	}
	puts("\n--");
}

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
		scanf("%lf", &yylval.val);
		return NUMBER;
	}
	if (islower(c)) {
		yylval.index = c - 'a'; // ascii only
		return VAR;
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

#include <signal.h>
#include <setjmp.h>
jmp_buf begin;

void execerror(char* s, char* t) {
	warning(s, t);
	longjmp(begin, 0);
}

void fpecatch() {
	execerror("floating point exception", (char*)0);
}

int main(int argc, char** argv) {
	progname = argv[0];
	setjmp(begin);
	signal(SIGFPE, fpecatch);
	yyparse();
}
