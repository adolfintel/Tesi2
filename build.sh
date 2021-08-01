#!/bin/bash
export LC_ALL=en_US.UTF-8
export TEXMFCNF='.:'
buildTex(){
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
    return 0
}
countPages(){
    echo "$1: conteggio pagine"
    local gsout=$(gs  -o - -sDEVICE=inkcov \"$1.pdf\")
    local gsoutQ=$(grep "CMYK" <<< "$gsout")
    echo "$1: $(wc -l <<< "$gsoutQ") pagine, di cui $(grep -v '^ 0.00000  0.00000  0.00000' <<< "$gsoutQ" | wc -l) a colori e $(grep '^ 0.00000  0.00000  0.00000' <<< "$gsoutQ" | wc -l) in bianco e nero"
    echo "$1: pagine Col: $(grep -v '^ 0.00000  0.00000  0.00000' <<< "$gsout" | grep "CMYK" -B 1 | grep "Page " | paste -s -d, | sed 's/Page //g')"
    echo "$1: pagine B/N: $(grep '^ 0.00000  0.00000  0.00000' -B 1 <<< "$gsout" | grep "CMYK" -B 1 | grep "Page " | paste -s -d, | sed 's/Page //g')"
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
command -v sed > /dev/null
if [[ $? -ne 0 ]]; then
    echo "Manca GNU sed"
    return 1
fi;
echo "Compilazione parallela avviata"
echo "L'output è nascosto, ma vengono generati i file di log"
{
    buildTex Tesi
    if [[ $? -eq 0 ]]; then
        pdfA Tesi &
        countPages Tesi &
        wait
    fi;
} &
{
    buildTex Presentazione
    countPages Presentazione
} &
{
    buildTex Riassunto
    countPages Riassunto
} &
wait
echo "Build completata"
