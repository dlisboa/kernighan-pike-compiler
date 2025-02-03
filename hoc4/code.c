#include "hoc.h"
#include "y.tab.h"
#include <stdio.h>
#include <math.h>

#define NSTACK 256
static Datum stack[NSTACK]; // the stack
static Datum *stackp; // next free spot on stack

// can have at most 2000 instructions
#define NPROG 2000
Inst prog[NPROG]; // the machine
Inst *progp; // next free spot for code generation
Inst *pc; // program counter during execution

// initialize for code generation
void initcode() {
		stackp = stack;
		progp = prog;
}

void push(Datum d) {
		if (stackp >= &stack[NSTACK])
				execerror("stack overflow", (char*)0);
		*stackp++ = d;
}

Datum pop() {
		if (stackp <= stack)
				execerror("stack underflow", (char*)0);
		return *--stackp;
}

// install one instruction or operand
Inst *code(Inst f) {
		Inst *origprogp = progp;
		if (progp >= &prog[NPROG])
				execerror("program too big", (char*)0);
		*progp++ = f;
		return origprogp;
}

// start program counter at p, go until STOP, calling each instruction
void execute(Inst *p) {
		for (pc = p; *pc != STOP; )
				(*(*pc++))();
}

// push constant onto stack
int constpush() {
		Datum d;
		// set the stack to the next instruction's value, then increment program
		// counter
		d.val = ((Symbol*)*pc++)->u.val;
		push(d);
		return 0;
}

// push variable onto stack
int varpush() {
		Datum d;
		d.sym = (Symbol*)(*pc++);
		push(d);
		return 0;
}

// evaluate variable on stack
int eval() {
		Datum d;
		d = pop();
		if (d.sym->type == UNDEF)
				execerror("undefined variable", d.sym->name);
		d.val = d.sym->u.val;
		push(d);
		return 0;
}

// assign top value to next value
int assign() {
		Datum d1, d2;
		d1 = pop();
		d2 = pop();
		if (d1.sym->type != VAR && d1.sym->type != UNDEF)
				execerror("assignment to non-variable", d1.sym->name);
		d1.sym->u.val = d2.val;
		d1.sym->type = VAR;
		push(d2);
		return 0;
}

// pop top value from stack; print it
int print() {
		Datum d;
		d = pop();
		printf("\t%.8g\n", d.val);
		return 0;
}

// evaluate built-in on top of stack
int bltin() {
	Datum d;
	d = pop();
	d.val = (*(double (*)())(*pc++))(d.val);
	push(d);
	return 0;
}

int add() {
		Datum d1, d2;
		d2 = pop();
		d1 = pop();
		d1.val += d2.val; // reuse d1; no reason, just looks clean
		push(d1);
		return 0;
}

int sub() {
		Datum d1, d2;
		d2 = pop();
		d1 = pop();
		d1.val -= d2.val;
		push(d1);
		return 0;
}

int mul() {
		Datum d1, d2;
		d2 = pop();
		d1 = pop();
		d1.val *= d2.val;
		push(d1);
		return 0;
}

int xdiv() {
		Datum d1, d2;
		d2 = pop();
		d1 = pop();
		d1.val /= d2.val;
		push(d1);
		return 0;
}

int power() {
		Datum d1, d2;
		d2 = pop();
		d1 = pop();
		d1.val = pow(d1.val, d2.val);
		push(d1);
		return 0;
}

int negate() {
		Datum d1;
		d1 = pop();
		d1.val = -d1.val;
		push(d1);
		return 0;
}
