#!/bin/bash
xelatex -interaction=nonstopmode Main.tex
bibtex Main
xelatex -interaction=nonstopmode Main.tex
xelatex -interaction=nonstopmode Main.tex
gs -dPDFA=1 -dBATCH -dNOPAUSE -sProcessColorModel=DeviceRGB -sDEVICE=pdfwrite -sPDFACompatibilityPolicy=1 -sOutputFile=Main.A.pdf Main.pdf
xelatex -interaction=nonstopmode Presentazione.tex
xelatex -interaction=nonstopmode Presentazione.tex
xelatex -interaction=nonstopmode Presentazione.tex
