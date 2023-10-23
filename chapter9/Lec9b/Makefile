PROG       := prog
LIBS       := unix
SOURCES    := sub1.ml sub2.ml main.ml

INTERFACES := $(wildcard *.mli)
OBJS       := $(patsubst %.ml,%.cmx,$(SOURCES))
LIBS       := $(patsubst %,%.cmxa,$(LIBS))

$(PROG): $(OBJS)
	ocamlopt -o $@ $(LIBS) $(OBJS)

clean:
	rm -rf $(PROG) *.o *.cmx *.cmi *~

%.cmx: %.ml
	ocamlopt -c $*.ml

%.cmi: %.mli
	ocamlopt -c $*.mli

depend: $(SOURCES) $(INTERFACES)
	ocamldep -native $(SOURCES) $(INTERFACES) >.depend

include .depend
