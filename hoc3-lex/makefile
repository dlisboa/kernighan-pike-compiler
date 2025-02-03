YFLAGS = -d	# force creation of y.tab.h
OBJS = hoc.o lex.o init.o math.o symbol.o	# abbreviation

hoc3: $(OBJS)
	cc $(OBJS) -lm -ll -o hoc3 # -lfl is flex

hoc.o: hoc.h

lex.o init.o symbol.o: hoc.h y.tab.h

# unecessary for me but keeping with the 1970s theme
pr:
	@pr hoc.y hoc.h lex.l init.c math.c symbol.c makefile
clean:
	rm -f $(OBJS) y.tab.[ch]
