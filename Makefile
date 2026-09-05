# CV build system.
# Out-of-tree xelatex builds: sources in src/, PDFs in build/.
# Tracked release copies at the repo root are refreshed with `make release`.
#
# Targets:
#   all       build both CV variants (default)
#   full      build the full (2-page) CV
#   onepage   build the condensed (1-page) CV
#   check     build both + assert the one-pager fits on 1 page
#   release   build both + copy to ./cv.pdf and ./cv-onepage.pdf
#   clean     remove build/ and stray in-tree LaTeX byproducts
#   distclean clean + remove the release PDFs
#   help      list targets

LATEX      ?= xelatex
LATEXFLAGS ?= -interaction=nonstopmode -halt-on-error

SRCDIR   := src
SECDIR   := $(SRCDIR)/sections
BUILDDIR := build

FULL_SRC    := $(SRCDIR)/cv-full.tex
ONEPAGE_SRC := $(SRCDIR)/cv-onepage.tex
FULL_PDF    := $(BUILDDIR)/cv-full.pdf
ONEPAGE_PDF := $(BUILDDIR)/cv-onepage.pdf

RELEASE_FULL    := cv.pdf
RELEASE_ONEPAGE := cv-onepage.pdf

# In-tree byproducts left by previous builds without -output-directory.
LEGACY_BYPRODUCTS := *.aux *.log *.out *.fls *.fdb_latexmk *.synctex.gz *.xdv

.PHONY: all full onepage check release clean distclean help
.DELETE_ON_ERROR:

all: full onepage

full: $(FULL_PDF)

onepage: $(ONEPAGE_PDF)

$(FULL_PDF): $(FULL_SRC) $(wildcard $(SECDIR)/*.tex) cv.cls | $(BUILDDIR)
	$(LATEX) $(LATEXFLAGS) -output-directory=$(BUILDDIR) -jobname=cv-full $(FULL_SRC)

$(ONEPAGE_PDF): $(ONEPAGE_SRC) cv.cls | $(BUILDDIR)
	$(LATEX) $(LATEXFLAGS) -output-directory=$(BUILDDIR) -jobname=cv-onepage $(ONEPAGE_SRC)

$(BUILDDIR):
	mkdir -p $(BUILDDIR)

release: all
	cp $(FULL_PDF) $(RELEASE_FULL)
	cp $(ONEPAGE_PDF) $(RELEASE_ONEPAGE)

check: all
	@command -v pdfinfo >/dev/null || { echo "pdfinfo not found, skipping page check"; exit 0; }; \
	full_pages=$$(pdfinfo $(FULL_PDF) | awk '/^Pages:/ {print $$2}'); \
	one_pages=$$(pdfinfo $(ONEPAGE_PDF) | awk '/^Pages:/ {print $$2}'); \
	echo "cv-full: $$full_pages page(s), cv-onepage: $$one_pages page(s)"; \
	test "$$one_pages" = "1" || { echo "ERROR: cv-onepage overflowed 1 page"; exit 1; }

clean:
	rm -rf $(BUILDDIR)
	rm -f $(LEGACY_BYPRODUCTS)

distclean: clean
	rm -f $(RELEASE_FULL) $(RELEASE_ONEPAGE)

help:
	@echo "Targets: all full onepage check release clean distclean help"
	@echo "  make [all]   build build/cv-full.pdf + build/cv-onepage.pdf"
	@echo "  make release copy them to ./cv.pdf + ./cv-onepage.pdf (tracked)"
