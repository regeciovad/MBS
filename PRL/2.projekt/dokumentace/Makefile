# Latex Makefile 
# Bc. Dominika Regeciova, xregec00
FILE = xregec00

$(FILE).pdf: $(FILE).ps
	ps2pdf $(FILE).ps

$(FILE).ps: $(FILE).dvi
	dvips $(FILE).dvi

$(FILE).dvi: $(FILE).tex
	latex $(FILE).tex
	latex $(FILE).tex


clean:
	-rm $(FILE).dvi $(FILE).aux $(FILE).log $(FILE).ps $(FILE).bbl $(FILE).blg
