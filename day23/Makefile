SRCDIR = src
OUTDIR = out

$(OUTDIR)/day22: $(SRCDIR)/day22.cpp | $(OUTDIR)
	$(CXX) -o $@ $<

$(OUTDIR):
	mkdir -p $@

.PHONY: run
run: $(OUTDIR)/day22
	@$<
