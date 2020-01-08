slides.tex: *.md
	pandoc \
		--top-level-division=part \
		--toc  \
		--verbose \
		-s \
		-t latex --standalone\
	       	-t beamer-simple_tables-multiline_tables-grid_tables+emoji \
		Lab5.md \
	       	-V theme:metropolis  -V aspectratio:43  \
	       	-o $@

slides.pdf: slides.tex
all: slides.pdf
	pdflatex slides.tex

clean:
	rm -rf slides.* auto 

#latexmk -xelatex slides.tex
