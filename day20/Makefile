SRCDIR = src
OUTDIR = out

$(OUTDIR)/day20: $(SRCDIR)/day20.m | $(OUTDIR)
	clang -g -framework Foundation -o $@ $<

$(OUTDIR):
	mkdir -p $@

.PHONY: run
run: $(OUTDIR)/day20
	@$<
