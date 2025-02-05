// hoc program, Kernighan and Pike

%{
// These lines were added here instead of how the book describes them due to
// compiling errors in newer C versions. Some function declarations were changed
// to match newer C standards.
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include "hoc.h"
int yylex();
void yyerror(char*);
void execerror(char*, char*);

#define code2(c1,c2) code(c1); code(c2)
#define code3(c1,c2,c3) code(c1); code(c2); code(c3)
%}
%union {
	Symbol *sym; // symbol table pointer
	Inst *inst; // machine instruction
}
%token <sym> NUMBER VAR BLTIN UNDEF
%right '='
%left '+' '-'
%left '*' '/'
%left UNARYMINUS
%right '^' // exponentiation
%%
list: /* nothing */
	| list '\n'
	| list asgn '\n'	{ code2((Inst)pop, STOP); return 1; } // return 1 makes the result of `yyparse()` true
	| list expr '\n'	{ code2(print, STOP); return 1; }
	| list error '\n'	{ yyerrok; }
	;
asgn:	VAR '=' expr	{ code3(varpush, (Inst)$1, assign); }
expr: 	NUMBER			{ code2(constpush, (Inst)$1); }
	| VAR				{ code3(varpush, (Inst)$1, eval);}
	| asgn
	| BLTIN '(' expr ')' { code2(bltin, (Inst)$1->u.ptr); }
	| '(' expr ')'
	| expr '+' expr		{ code(add); }
	| expr '-' expr		{ code(sub); }
	| expr '*' expr		{ code(mul); }
	| expr '/' expr		{ code(xdiv); }
	| expr '^' expr		{ code(power); }
	| '-' expr %prec UNARYMINUS { code(negate); }
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
		double d;
		ungetc(c, stdin);
		scanf("%lf", &d);
		yylval.sym = install("", NUMBER, d);
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

extern Datum* stack;
extern Datum* stackp;
extern Inst* progp, pc;

void inspectstack() {
  puts("\tstack:");

  puts("\t\t-- top --");
  for (Datum* d = stack; d; d++) {
    if (stackp == d) {
    // printf("\t\t%p: |%g|\n", &d->val, d->val);
      printf("\t\t%p: |%g| <-- stackp (next free)\n", &d->val, d->val);
    } else if (stackp == d + 1) {
      printf("\t\t%p: |%g| <-- actual top\n", &d->val, d->val);
    } else {
      printf("\t\t%p: |%g|\n", &d->val, d->val);
    }
  }
  puts("\t\t-- bottom --");
}

struct inst {
  char* name;
  Inst func;
} insts[] = {
  "constpush", constpush,
  "varpush", varpush,
  "eval", eval,
  "assign", assign,
  "print", print,
  "bltin", bltin,
  "add", add,
  "sub", sub,
  "stop", STOP,
  0, 0,
};

void inspectops() {
  puts("\tinstructions:");
  for (int i=0; insts[i].name; i++) {
    printf("\t\t%s: %p\n", insts[i].name, insts[i].func);
  }
}

void lookupinst(Inst key, char* buf) {
	// printf("looking up: %p\n", key);
	struct inst *i;
	for (i = insts; i; i++) {
		if (i->func == key) {
			strcpy(buf, i->name);
		} else {
			strcpy(buf, "<notfound>");
		}
		break;
	}
}

void inspectprogram() {
  puts("\tprogram:");

  puts("\t\t-- start --");
	char buf[100];
  for (int p = 0; p < 10; p++) {
  	Inst i = prog[p];
  	if (prog == &prog[p]) {
			lookupinst(*i, buf);
	  	printf("%16s%10p: |%p| (%s)\n", "prog --> ", &prog[p], *i, buf);
  	} else if (i != NULL) {
			lookupinst(*i, buf);
	  	printf("\t\t%10p: |%p| (%s)\n", &prog[p], *i, buf);
  	} else {
	  	printf("\t\t%10p: |%p|\n", &prog[p], *i);
  	}
  }
  puts("\t\t-- end --");
}

void inspectpointers() {
  puts("\tpointers:");
  printf("\t\tpc: %p\n", pc);
  printf("\t\tprogp: %p\n", progp);
  printf("\t\tprog: %p\n", prog);
  printf("\t\tstackp: %p\n", (void*)stackp);
}

void inspectmachine() {
  inspectops();
  inspectprogram();
  inspectpointers();
  inspectstack();
}

int main(int argc, char** argv) {
	progname = argv[0];
	init();
	setjmp(begin);
	signal(SIGFPE, fpecatch);

	initcode();
	puts("== initial state, machine at rest");
	inspectmachine();
	// start and end with a "clean" machine each time we parse
	puts("== ready to interpret");
	// for (initcode(); yyparse(); initcode()) {
	// 	inspectmachine();
	// 	puts("== execution");
	// 	execute(prog);
	// }

	// yyparse();

	inspectmachine();
	puts("== execution");
	execute(prog);
}
