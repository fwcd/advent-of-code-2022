SRCDIR = src
OUTDIR = out

$(OUTDIR)/day02: $(SRCDIR)/day02.vala | $(OUTDIR)
	valac --pkg gio-2.0 -o $@ $<

$(OUTDIR):
	mkdir -p $@

.PHONY: run
run: $(OUTDIR)/day02
	@$<
