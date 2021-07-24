#!/bin/bash
buildTex () {
    echo "$1: passo 1"
    xelatex -interaction=nonstopmode "$1.tex" >/dev/null 2>&1
    echo "$1: bibtex"
    bibtex $1 >/dev/null 2>&1
    echo "$1: passo 2"
    xelatex -interaction=nonstopmode "$1.tex" >/dev/null 2>&1
    echo "$1: passo 3"
    xelatex -interaction=nonstopmode "$1.tex" >/dev/null 2>&1
    echo "$1: compilato"
}
pdfA(){
    echo "$1: generazione PDF/A"
    gs -dPDFA=1 -dBATCH -dNOPAUSE -sProcessColorModel=DeviceRGB -sDEVICE=pdfwrite -sPDFACompatibilityPolicy=1 -sOutputFile="$1.A.pdf" "$1.pdf" >/dev/null 2>&1
    echo "$1: PDF/A generato"
}

echo "Compilazione parallela avviata"
echo "L'output è nascosto, ma vengono generati i file di log"
{
    buildTex Main
    pdfA Main
    echo "Main: Fine"
} &
{
    buildTex Presentazione
    echo "Presentazione: Fine"
} &
wait
echo "Tutto finito"
