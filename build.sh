#!/bin/bash
xelatex -interaction=nonstopmode Main.tex
if [ $? -eq 0 ]; then
    gs -dPDFA=1 -dBATCH -dNOPAUSE -sProcessColorModel=DeviceRGB -sDEVICE=pdfwrite -sPDFACompatibilityPolicy=1 -sOutputFile=Main.A.pdf Main.pdf
else
    echo Build failed
fi;
