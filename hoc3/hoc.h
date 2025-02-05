typedef struct Symbol {
	char* name;
	short type;
	union {
		double val;
		double (*ptr)(double);
	} u;
	struct Symbol *next;
} Symbol;
Symbol *install(char*, int, double), *lookup(char*);
