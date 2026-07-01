;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;this script is used to difine the absolute difference levels (diffgrp1),;;; 
;;;;;;;;the relative difference levels (diffgrp2), then choose color bar for plot;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ;;setup for fill pattern
  FillColor           = "Grey28";"Grey";"Black"
  FillPattern         = 0 ;17 ;6 ;17;11
  FillScaleF          = 0.1
  FillDotSizeF        = 0.0002    ; increase dot size of contours
  FillOpacityF        = 0.2

 ; FillColor           = "White" ;"Lightgrey";"Grey28";"Grey";"Black"
 ; FillPattern         = 0   ;11 ;17 ;6 ;17;11
 ; FillScaleF          = 0.5
 ; FillDotSizeF        = 0.002    ; increase dot size of contours
 ; FillOpacityF        = 0.8

  ocname := "NCV_banded" ;"amwg"  ; color bar name for cntrol model plot

  gsn_define_colormap(wks1, "ViBlGrWhYeOrRe") ; choose colormap

  colorbar_without_white := False

 if (Varname .eq. "U".or.Varname .eq. "US") then
  mskthres = 0.001  ;threshold used to mask out the regions with T < 0.001

  ocname := "amwg"  ; color bar name for cntrol model plot
  ;orglev := ispan(180,300,10)
  ;ocname    := "prcp_3"  ; color bar name for cntrol model plot
  ;orgcolors := (/3,4,5,7,10,11,12,13,14,17,18,19/) ;fspan(10,90,81)
  orglev    := (/-50, -40, -30, -20, -10, 0, 10, 20, 30, 40, 50/)

  xocname := "precip_11lev"
  xocname := "BlueDarkRed18"
  docname := "precip3_16lev"

  colorgroup1 := (/15,26,33,42,75,85,102,2/)

  diffgrp1    := (/-10.0,-5.0,-2.0,-1.0,1.0, 2.0, 5.0, 10.0/)/10.0
  diffgrp2    := (/0.1,0.2,0.4,0.8,1.2,1.6,2.0,3.0,4.0/)

  ndiff       := dimsizes(diffgrp1)
 end if

 if (Varname .eq. "V".or.Varname .eq. "VS") then
  mskthres = 0.001  ;threshold used to mask out the regions with T < 0.001

  ocname := "amwg"  ; color bar name for cntrol model plot
  ;orglev := ispan(180,300,10)
  ;ocname    := "prcp_3"  ; color bar name for cntrol model plot
  ;orgcolors := (/3,4,5,7,10,11,12,13,14,17,18,19/) ;fspan(10,90,81)
  orglev    := (/ -10, -8, -4, -2, -1, 0, 1, 2, 4, 8, 10/)

  xocname := "precip_11lev"
  xocname := "BlueDarkRed18"
  docname := "precip3_16lev"

  colorgroup1 := (/15,26,33,42,75,85,102,2/)

  diffgrp1    := (/-5.0,-3.0,-2.0,-1.0,1.0, 2.0, 3.0, 5.0/)/10.0
  diffgrp2    := (/0.1,0.2,0.4,0.8,1.2,1.6,2.0,3.0,4.0/)

  ndiff       := dimsizes(diffgrp1)
 end if

 if (Varname .eq. "T") then
  mskthres = 0.001  ;threshold used to mask out the regions with T < 0.001

  ocname := "amwg"  ; color bar name for cntrol model plot
  ;orglev := ispan(180,300,10)
  ;ocname    := "prcp_3"  ; color bar name for cntrol model plot
  ;orgcolors := (/3,4,5,7,10,11,12,13,14,17,18/) ;fspan(10,90,81)
  orglev    := (/200,210,220,230,240,250,260,270,280,300/)

  xocname := "precip_11lev"
  xocname := "BlueDarkRed18"
  docname := "precip3_16lev"

  colorgroup1 := (/15,26,33,42,75,85,102,2/)

  diffgrp1    := (/-0.3,-0.2,-0.1,-0.05,0.05,0.1,0.2,0.3/)
  diffgrp2    := (/0.1,0.2,0.4,0.8,1.2,1.6,2.0,2.4,2.8/)

  ndiff       := dimsizes(diffgrp1)
 end if 

 if (Varname .eq. "CLOUD") then
  mskthres = 0.02   ;threshold used to mask out the regions with CLOUD < 0.01

  ocname := "amwg"  ; color bar name for cntrol model plot
  ;orglev := (/0.01,0.02,0.05,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8/) ;fspan(10,90,81)
  ;ocname    := "prcp_3"  ; color bar name for cntrol model plot
  ;orgcolors := (/3,4,5,7,10,11,12,13,14,17,18/) ;fspan(10,90,81)
  orglev    := (/0.01,0.02,0.05,0.1,0.2,0.3,0.4,0.5,0.6,0.8/)

  if (colorbar_without_white) then ; do not include white in colorbar
     diffgrp1    := (/-0.08,-0.04,-0.02,0,0.02,0.04,0.08/)
     diffgrp1    := (/-0.05,-0.02,-0.01,0,0.01,0.02,0.05/)
     colorgroup1 := (/15,26,33,42,75,85,102,2/)
     diffgrp2    := (/-20,-10,-5,0,5,10,20/)
  else
    ;colorgroup1 := (/15,26,33,42,50,75,85,102,2/)
     colorgroup1 := (/15,30,40,45,50,75,85,102,2/)
     diffgrp1    := (/-0.08,-0.04,-0.02,-0.01,0.01,0.02,0.04,0.08/)
     diffgrp2    := (/-20,-10,-5,-1,1,5,10,20/)
  end if
  ndiff       := dimsizes(diffgrp1)
 end if


 if (Varname .eq. "RELHUM") then
  mskthres = 0.05   ;threshold used to mask out the regions with RH < 0.05
  ocname := "amwg"  ; color bar name for cntrol model plot
 ;orglev := (/0.05,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1.0/) ;fspan(10,90,81)
 ;ocname    := "prcp_3"  ; color bar name for cntrol model plot
 ;orgcolors := (/3,4,5,7,10,11,12,13,14,17,18/) ;fspan(10,90,81)
  orglev    := (/0.05,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9/)
  
  if (colorbar_without_white) then ; do not include white in colorbar
     diffgrp1    := (/-0.06,-0.03,-0.01,0.,0.01,0.03,0.06/)
     colorgroup1 := (/15,26,33,42,75,85,102,2/)
     diffgrp2    := (/-20,-10,-5,0,5,10,20/)
  else
    ;colorgroup1 := (/15,26,33,42,50,75,85,102,2/)
     colorgroup1 := (/15,30,40,45,50,75,85,102,2/)
     diffgrp1    := (/-0.08,-0.04,-0.02,-0.01,0.01,0.02,0.04,0.08/)
     diffgrp2    := (/-20,-10,-5,-1,1,5,10,20/)
  end if
  ndiff       := dimsizes(diffgrp1)
 end if 

 if (Varname .eq. "Q") then

  mskthres = 0.002  ;threshold used to mask out the regions with Q < 0.01

  ocname := "amwg"  ; color bar name for cntrol model plot
  ;orglev := (/0.01,0.05,0.1,0.2,0.5,1,2,5,8,10,12,15/)
  ;ocname    := "prcp_3"  ; color bar name for cntrol model plot
  ;orgcolors := (/3,4,5,7,10,11,12,13,14,17,18/) ;fspan(10,90,81)
  orglev    := (/0.01,0.05,0.1,0.2,0.5,1,2,5,8,10/)

  xocname := "precip_11lev"
  xocname := "BlueDarkRed18"
  docname := "precip3_16lev"

  colorgroup1 := (/15,26,33,42,75,85,102,2/)

  diffgrp1    := (/-1.2,-0.8,-0.4,-0.2,0.2,0.4,0.8,1.2/)
  diffgrp2    := (/0.1,0.2,0.4,0.6,0.8,1.2,1.6,2.0,2.4/)

  ndiff       := dimsizes(diffgrp1)

 end if 


