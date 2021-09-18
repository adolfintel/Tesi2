#!/bin/bash
SECONDS=0
export LC_ALL=en_US.UTF-8
export TEXMFCNF='.:'
log(){
    echo "[$BASHPID] $1: $2"
}
compile(){
    log $1 "compilazione"
    local PASSES=3
    for i in $(seq $PASSES); do
        if [[ $i -eq $PASSES ]]; then
            xelatex -interaction=nonstopmode "$1.tex" >/dev/null 2>&1
        else
            xelatex -interaction=nonstopmode -no-pdf "$1.tex" >/dev/null 2>&1
        fi
        if [[ $? -ne 0 ]]; then
            log $1 "fallito"
            return 1
        fi
        if [[ $i -eq 1 ]]; then
            bibtex "$1" >/dev/null 2>&1
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
    gs -dPDFA=1 -dPDFACompatibilityPolicy=1 -dBATCH -dNOPAUSE -dNOOUTERSAVE -sDEVICE=pdfwrite -dNOSAFER -sColorConverionStrategy=/UseDeviceIndependentColor -dPDFSETTINGS=/prepress -dDownsampleColorImages=false -dDownsampleGrayImages=false -dDownsampleMonoImages=false -dAutoFilterColorImages=false -dColorImageFilter=/FlateEncode -sOutputFile="$1.A.pdf" PDFA_def.ps "$1.pdf" >/dev/null 2>&1
    if [[ $? -ne 0 ]]; then
        log $1 "fallito"
        return 1
    fi;
    log $1 "PDF/A generato"
}
extractFrontespizio(){
    log $1 "generazione PDF solo frontespizio"
    gs -dPDFA=1 -dPDFACompatibilityPolicy=1 -dBATCH -dNOPAUSE -dNOOUTERSAVE -sDEVICE=pdfwrite -dNOSAFER -sColorConverionStrategy=/UseDeviceIndependentColor -dPDFSETTINGS=/prepress -dDownsampleColorImages=false -dDownsampleGrayImages=false -dDownsampleMonoImages=false -dAutoFilterColorImages=false -dColorImageFilter=/FlateEncode -dFirstPage=1 -dLastPage=1 -sOutputFile="$1.Frontespizio.pdf" PDFA_def.ps "$1.pdf" >/dev/null 2>&1
    if [[ $? -ne 0 ]]; then
        log $1 "fallito"
        return 1
    fi;
    log $1 "PDF solo frontespizio generato"
}
build(){
    local startT=$SECONDS
    rm -f "$1.pdf"
    rm -f "$1.*.pdf"
    compile $1
    if [[ $? -eq 0 ]]; then
        if [[ $2 -eq 1 ]]; then
            countPages $1 &
        fi;
        if [[ $3 -eq 1 ]]; then
            pdfA $1 &
        fi;
        if [[ $4 -eq 1 ]]; then
            extractFrontespizio $1 &
        fi;
        wait
    fi;
    log $1 "completato in $(($SECONDS-$startT)) secondi"
}
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
if [ "$1" == "release" ]; then
    echo "$(tput setaf 11)Tipo di build: completa, parallela$(tput sgr 0)"
    build Tesi 1 1 1 &
    {
        build Presentazione 1 0 0
        build PresentazioneParlata 1 0 0
    } &
    {
        build Riassunto 1 0 0
        build TestStampa 1 1 0
    } &
else
    echo "$(tput setaf 11)Tipo di build: rapida, parallela (usa ./build.sh release per fare una build completa)$(tput sgr 0)"
    build Tesi 0 0 0 &
    {
        build Presentazione 0 0 0
        build PresentazioneParlata 0 0 0
    } &
    build Riassunto 0 0 0 &
fi;
wait
echo "Build completata in $SECONDS secondi"
