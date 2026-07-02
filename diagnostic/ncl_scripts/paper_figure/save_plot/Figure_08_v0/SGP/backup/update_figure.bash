#! /bin/bash

   #generate figure data#
   #profile
   #ncl 1_generate_profile_data.ncl
   #correlation
   #ncl 2_generate_correlation_data.ncl

   #figure#
   ncl plot_profile_eam_vs_arm.ncl
   ncl plot_correlation_eam_vs_arm.ncl
   
   sh run_crop_pdf.sh
   pdflatex Fig08.tex 
   rm -rvf fig*.pdf
   sh run_crop_pdf.sh

