YFLAGS = -d	# force creation of y.tab.h
OBJS = hoc.o code.o init.o math.o symbol.o	# abbreviation

hoc3: $(OBJS)
	cc $(OBJS) -lm -o hoc4

hoc.o code.o init.h symbo.o: hoc.h

code.o init.o symbol.o: x.tab.h

x.tab.h: y.tab.h
	-cmp -s x.tab.h y.tab.h || cp y.tab.h x.tab.h

# unecessary for me but keeping with the 1970s theme
pr: hoc.y hoc.h code.c init.c math.c symbol.c
	@pr $?
	@touch pr

clean:
	rm -f $(OBJS) [xy].tab.[ch]
