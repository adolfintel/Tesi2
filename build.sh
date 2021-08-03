#!/bin/bash
SECONDS=0
export LC_ALL=en_US.UTF-8
export TEXMFCNF='.:'
log(){
    echo "[$BASHPID] $1: $2"
}
compile(){
    log $1 "compilazione"
    for i in 1 2 3; do
        xelatex -interaction=nonstopmode "$1.tex" >/dev/null 2>&1
        if [[ $? -ne 0 ]]; then
            log $1 "fallito"
            return 1
        fi
        if [[ $i -eq 0 ]]; then
            bibtex $1 >/dev/null 2>&1
        fi
    done
    log $1 "compilato"
    return 0
}
countPages(){
    log $1 "conteggio pagine"
    local gsout=$(gs  -o - -sDEVICE=inkcov \"$1.pdf\")
    local gsoutQ=$(grep "CMYK" <<< "$gsout")
    log $1 "$(wc -l <<< "$gsoutQ") pagine, di cui $(grep -v '^ 0.00000  0.00000  0.00000' <<< "$gsoutQ" | wc -l) a colori e $(grep '^ 0.00000  0.00000  0.00000' <<< "$gsoutQ" | wc -l) in bianco e nero"
    log $1 "pagine Col: $(grep -v '^ 0.00000  0.00000  0.00000' <<< "$gsout" | grep "CMYK" -B 1 | grep "Page " | paste -s -d, | sed 's/Page //g')"
    log $1 "pagine B/N: $(grep '^ 0.00000  0.00000  0.00000' -B 1 <<< "$gsout" | grep "CMYK" -B 1 | grep "Page " | paste -s -d, | sed 's/Page //g')"
}
pdfA(){
    log $1 "generazione PDF/A"
    gs -dPDFA=1 -dBATCH -dNOPAUSE -sProcessColorModel=DeviceRGB -sDEVICE=pdfwrite -sPDFACompatibilityPolicy=1 -sOutputFile="$1.A.pdf" "$1.pdf" >/dev/null 2>&1
    if [[ $? -ne 0 ]]; then
        log $1 "fallito"
        return 1
    fi;
    log $1 "PDF/A generato"
}
build(){
    local startT=$SECONDS
    compile $1
    if [[ $? -eq 0 ]]; then
        if [[ $2 -eq 1 && $3 -eq 1 ]]; then
            pdfA $1 &
            countPages $1 &
            wait
        else
            if [[ $2 -eq 1 ]]; then
                pdfA $1
            fi;
            if [[ $3 -eq 1 ]]; then
                countPages $1
            fi;
        fi;
    fi;
    log $1 "completato in $(($SECONDS-$startT)) secondi"
}
echo "Controllo... "
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
echo "Compilazione parallela avviata. L'output è nascosto, ma vengono generati i file di log"
build Tesi 1 1 &
{
    build Presentazione 0 1
    build Riassunto 0 1
    build TestStampa 0 1
} &

wait
echo "Build completata in $SECONDS secondi"
