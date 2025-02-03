YFLAGS = -d	# force creation of y.tab.h
OBJS = hoc.o init.o math.o symbol.o	# abbreviation

hoc3: $(OBJS)
	cc $(OBJS) -lm -o hoc3

hoc.o: hoc.h

init.o symbol.o: hoc.h y.tab.h

# unecessary for me but keeping with the 1970s theme
pr:
	@pr hoc.y hoc.h init.c math.c symbol.c makefile
clean:
	rm -f $(OBJS) y.tab.[ch]
