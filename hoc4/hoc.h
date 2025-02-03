typedef struct Symbol { // symbol table entry
	char* name;
	short type; // NUMBER, VAR, BLTIN, UNDEF
	union {
		double val; // if NUMBER, VAR
		double (*ptr)(); // if BLTIN
	} u;
	struct Symbol *next;
} Symbol;
Symbol *install(char*, int, double), *lookup(char*);

typedef union Datum { // interpreter stack type
		double val;
		Symbol *sym;
} Datum;
extern Datum pop();

typedef int (*Inst)(); // machine instruction
extern Inst prog[]; // a program is a sequence of instructions
#define STOP (Inst)0
Inst* code(Inst);
void init();
void initcode();
void execute(Inst*);

// instructions
int add();
int sub();
int mul();
int xdiv();
int negate();
int power();
int assign();
int eval();
int bltin();
int varpush();
int constpush();
int print();

// errors
void execerror(char*, char*);
