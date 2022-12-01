SRCDIR = src
OUTDIR = out

$(OUTDIR)/day02: $(SRCDIR)/day02.vala | $(OUTDIR)
	valac -o $@ $<

$(OUTDIR):
	mkdir -p $@

.PHONY: run
run: $(OUTDIR)/day02
	@$<
