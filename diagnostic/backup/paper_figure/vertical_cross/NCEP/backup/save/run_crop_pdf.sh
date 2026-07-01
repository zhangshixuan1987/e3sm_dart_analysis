#!/bin/sh

rm -rvf *crop*.pdf

for file in *.pdf;do

pdfcrop --margins '5 5 5 5' $file

done
