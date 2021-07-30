#!/bin/bash
export TEXMFCNF='.:'
buildTex () {
    echo "$1: passo 1"
    xelatex -interaction=nonstopmode "$1.tex" >/dev/null 2>&1
    if [[ $? -ne 0 ]]; then
        echo "$1: fallito"
        return 1
    fi;
    echo "$1: bibtex"
    bibtex $1 >/dev/null 2>&1
    echo "$1: passo 2"
    xelatex -interaction=nonstopmode "$1.tex" >/dev/null 2>&1
    if [[ $? -ne 0 ]]; then
        echo "$1: fallito"
        return 1
    fi;
    echo "$1: passo 3"
    xelatex -interaction=nonstopmode "$1.tex" >/dev/null 2>&1
    if [[ $? -ne 0 ]]; then
        echo "$1: fallito"
        return 1
    fi;
    echo "$1: compilato"
    echo "$1: $(gs -q  -o - -sDEVICE=inkcov \"$1.pdf\" | wc -l) pagine, di cui $(gs -q  -o - -sDEVICE=inkcov \"$1.pdf\" | grep -v '^ 0.00000  0.00000  0.00000' | wc -l) a colori e $(gs -q  -o - -sDEVICE=inkcov \"$1.pdf\" | grep '^ 0.00000  0.00000  0.00000' | wc -l) bianco/nero"
    return 0
}
pdfA(){
    echo "$1: generazione PDF/A"
    gs -dPDFA=1 -dBATCH -dNOPAUSE -sProcessColorModel=DeviceRGB -sDEVICE=pdfwrite -sPDFACompatibilityPolicy=1 -sOutputFile="$1.A.pdf" "$1.pdf" >/dev/null 2>&1
    if [[ $? -ne 0 ]]; then
        echo "$1: fallito"
        return 1
    fi;
    echo "$1: PDF/A generato"
}
echo "Controllo..."
command -v xelatex > /dev/null
if [[ $? -ne 0 ]]; then
    echo "Manca xelatex, forse texlive-full non è installato?"
    return 1
fi;
command -v bibtex > /dev/null
if [[ $? -ne 0 ]]; then
    echo "Manca bibtex, forse texlive-full non è installato?"
    return 1
fi;
command -v gs > /dev/null
if [[ $? -ne 0 ]]; then
    echo "Manca Ghostscript"
    return 1
fi;
echo "Compilazione parallela avviata"
echo "L'output è nascosto, ma vengono generati i file di log"
{
    buildTex Tesi
    if [[ $? -eq 0 ]]; then
        pdfA Tesi
    fi;
} &
{
    buildTex Presentazione
} &
{
    buildTex Riassunto
} &
wait
echo "Build completata"
