#!/bin/bash
buildTex () {
    xelatex -interaction=nonstopmode "$1.tex" >/dev/null 2>&1
    bibtex $1 >/dev/null 2>&1
    xelatex -interaction=nonstopmode "$1.tex" >/dev/null 2>&1
    xelatex -interaction=nonstopmode "$1.tex" >/dev/null 2>&1
}
pdfA(){
    gs -dPDFA=1 -dBATCH -dNOPAUSE -sProcessColorModel=DeviceRGB -sDEVICE=pdfwrite -sPDFACompatibilityPolicy=1 -sOutputFile="$1.A.pdf" "$1.pdf" >/dev/null 2>&1
}

echo "Compilazione parallela avviata"
echo "L'output è nascosto, ma i file di log vengono generati"
{
    buildTex Main
    echo "Tesi: compilata"
    pdfA Main
    echo "Tesi: PDF/A generato"
} &
{
    buildTex Presentazione
    echo "Presentazione: compilata"
} &
wait
echo "Tutto finito"
