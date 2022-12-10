SRCDIR = src
OUTDIR = out

$(OUTDIR)/day10: $(SRCDIR)/day10.c | $(OUTDIR)
	$(CC) -o $@ $<

$(OUTDIR):
	mkdir -p $@

.PHONY: run
run: $(OUTDIR)/day10
	@$<
