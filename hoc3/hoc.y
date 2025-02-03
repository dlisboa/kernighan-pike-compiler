// hoc program, Kernighan and Pike

%{
// These lines were added here instead of how the book describes them due to
// compiling errors in newer C versions. Some function declarations were changed
// to match newer C standards.
#include <stdio.h>
#include <ctype.h>
#include "hoc.h"
int yylex();
void yyerror(char*);
void execerror(char*, char*);
extern double Pow(double, double);
%}
%union {
	double val;
	Symbol *sym;
}
%token <val> NUMBER
%token <sym> VAR BLTIN UNDEF
%type <val> expr asgn
%right '='
%left '+' '-'
%left '*' '/'
%left UNARYMINUS
%right '^' // exponentiation
%%
list: /* nothing */
	| list '\n'
	| list asgn '\n'
	| list expr '\n' { printf("\t%.8g\n", $2); }
	| list error '\n' { yyerrok; }
	;
asgn:	VAR '=' expr { $$ = $1->u.val = $3; $1->type = VAR; }
expr: 	NUMBER
	| VAR { if ($1->type == UNDEF)
		    execerror("undefined variable", $1->name);
		$$ = $1->u.val; }
	| asgn
	| BLTIN '(' expr ')' { $$ = (*($1->u.ptr))($3); }
	| expr '+' expr { $$ = $1 + $3; }
	| expr '-' expr { $$ = $1 - $3; }
	| expr '*' expr { $$ = $1 * $3; }
	| expr '/' expr {
		if ($3 == 0.0) {
			execerror("division by zero", (char*)0);
		}
		$$ = $1 / $3;
	}
	| expr '^' expr { $$ = Pow($1, $3); }
	| '(' expr ')' { $$ = $2; }
	| '-' expr %prec UNARYMINUS { $$ = -$2; }
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
		scanf("%lf", &yylval.val);
		return NUMBER;
	}
	if (isalpha(c)) {
		Symbol *s;
		char sbuf[100]; // vars can be at most 100 chars long
		char *p = sbuf;
		do {
			*p++ = c;
		} while ((c=getchar()) != EOF && isalnum(c));
		ungetc(c, stdin);
		*p = '\0';
		if ((s=lookup(sbuf)) == 0)
			s = install(sbuf, UNDEF, 0.0);
		yylval.sym = s;
		return s->type == UNDEF ? VAR : s->type;
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
	void init();

	progname = argv[0];
	init();
	setjmp(begin);
	signal(SIGFPE, fpecatch);
	yyparse();
}
