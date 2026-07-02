;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;this script is used to difine the absolute difference levels (diffgrp1),;;; 
;;;;;;;;the relative difference levels (diffgrp2), then choose color bar for plot;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;regions for the regional map plot (pacific ocean region)
  mpMinLatF    =-90  ; 20  ;-180.
  mpMaxLatF    = 90  ; 60  ;180.
  mpMinLonF    =  0  ;100  ;-180.
  mpMaxLonF    = 360 ;260  ;180.
  mpCenterLonF = 240 ;180  ;150.0

 ;;;subregions used by the analyses;;;;;;;;;;;;;;;;
 ;Low stratocumulus clouds
 ;Northeast Pacific (NEP) 15–35N, 120–140W
 ;Southeast Pacific (SEP) 10–30S, 75–95W
 ;Southeast Atlantic (SEA) 10–30S, 10W–10E
 ;Southeast Indian Ocean (SEI) 20–40S, 90–110E
 ;Stormtrack
 ;North Pacific (NP) 40–60N, 165–185E
 ;Northeast Atlantic (NEA) 10–30N, 25–45W
 ;North Atlantic (NA) 45–65N, 30–50W
 ;High Clouds
 ;Southern Ocean (SO) 45–65S, 130-170E; 180W–180E
  Subreg       = (/ "NEP",  "SEP",  "SEA",  "SEI",  "NP", "NEA",  "NA",   "SO"/)
  minlat       = (/  15.0,  -10.0,  -10.0,  -20.0,  40.0,  10.0,  45.0,   -45.0/)
  maxlat       = (/  35.0,  -30.0,  -30.0,  -40.0,  60.0,  30.0,  65.0,   -65.0/)
  minlon       = (/-140.0,  -95.0,  -10.0,   90.0, 165.0, -45.0, -50.0,   130.0/)
  maxlon       = (/-120.0,  -75.0,   10.0,  110.0, 185.0, -25.0, -30.0,   170.0/)
  nsubreg      = dimsizes(Subreg)

 ;;setup for fill pattern
  ;FillColor           = "Grey75" ;"Grey65";"Grey28";"Grey";"Black"
  ;FillPattern         = 0 ;17 ;6 ;17;11
  ;FillScaleF          = 0.1
  ;FillDotSizeF        = 0.0002    ; increase dot size of contours
  ;FillOpacityF        = 1.0 ;0.15

  FillColor           = "Magenta"; "Grey28";"Green3";"Magenta";"Grey28";"Grey";"Black"
  FillPattern         = 17 ;6 ;17;11
  FillScaleF          = 0.3 ;0.5
  FillDotSizeF        = 0.003    ; increase dot size of contours
  FillOpacityF        = 0.8

  FillColor1          = "Green3";"Magenta";"Grey28";"Grey";"Black"
  FillPattern1        = 17 ;6 ;17;11
  FillScaleF1         = 0.5
  FillDotSizeF1       = 0.002    ; increase dot size of contours
  FillOpacityF1       = 0.8

  if (plot_ttest_mskout ) then
     colorbar_without_white := True
  else if (plot_ttest_hatrv .or. plot_ttest_hatch) then
     colorbar_without_white := True
  else
     colorbar_without_white := False
  end if
  end if

  ocname  := "WhBlGrYeRe" ;"NCV_banded" ;"amwg"  ; color bar name for cntrol model plot
  xcname  := "MPL_YlGn"; "precip_11lev"
  dcname  := "BlueDarkRed18"
  dcname  := "CBR_coldhot"

 if (Varname .eq. "TH7001000") then
  minvar := 8
  maxvar := 24
  maxLev := 17
  mnmxint:= nice_mnmxintvl(minvar,maxvar,maxLev, False)
  ocname := "WhBlGrYeRe" ;"NCV_banded" ;"amwg"  ; color bar name for cntrol model plot
  orglev := fspan(2,22,11)

  dcname := "BlueDarkRed18"
  gsn_define_colormap(wks1, "NCV_blu_red") ; choose colormap
  if (colorbar_without_white) then ; do not include white in colorbar
     colorgroup1 := (/8,58,88,118, 138,168,198,248/)
     diffgrp1    := (/-0.8,-0.4,-0.2,0,0.2,0.4,0.8/)
     diffgrp2    := (/-50,-20,-10,0,10,20,50/)
  else
     colorgroup1 := (/8,58,88,118,0,138,168,198,248/)
     diffgrp1    := (/-0.8,-0.4,-0.2,-0.1,0.1,0.2,0.4,0.8/)
     diffgrp2    := (/-50,-20,-10,-5,5,10,20,50/)
  end if
  ndiff       := dimsizes(diffgrp1)
 end if

 if (Varname .eq. "TGCLDLWP") then
  minvar := 0
  maxvar := 80
  maxLev := 9
  mnmxint:= nice_mnmxintvl(minvar,maxvar,maxLev, False)
  ocname := "WhBlGrYeRe" ;"NCV_banded" ;"amwg"  ; color bar name for cntrol model plot
  ;ocname := "NCV_banded" ;"amwg"  ; color bar name for cntrol model plot
  orglev := (/5, 10, 15, 20, 25, 30, 40, 50, 60, 70, 80, 100, 120, 140/);

  dcname := "BlueDarkRed18"
  gsn_define_colormap(wks1, "NCV_blu_red") ; choose colormap
  gsn_define_colormap(wks1, "BlueDarkRed18") ; choose colormap
  if (colorbar_without_white) then ; do not include white in colorbar
     ;colorgroup1 := (/8,58,88,118,138,168,198,248/)
     colorgroup1 := (/2,4,6,8,10,11,13,15,17,19/)
     diffgrp1    := (/-20,-10,-5,-1,0,1,5,10,20/)
     diffgrp2    := (/-50,-20,-10,0,10,20,50/)
  else
     colorgroup1 := (/8,58,88,118,0,138,168,198,248/)
     diffgrp1    := (/-40,-20,-10, -5,5,10,20,40/)
     diffgrp2    := (/-50,-20,-10,-5,5,10,20,50/)
  end if

  xcname   := "MPL_YlGn"; "precip_11lev"
  diffgrp0 := fspan(0,3,11)

  dcname   := read_colormap_file("CBR_coldhot")
  dcname   := dcname(::-1,:)
  diffgrp1 := (/-60.0,-40.0,-20.0,-10.0,-5.0,5.0,10.0,20.0,40.0,60.0/)
  ndiff    := dimsizes(diffgrp1)
 end if

 if (Varname .eq. "TREFHT") then
  minvar := -40
  maxvar :=  40
  maxLev := 9
  mnmxint:= nice_mnmxintvl(minvar,maxvar,maxLev, False)
  ocname := "NCV_banded" ;"amwg"  ; color bar name for cntrol model plot
  orglev := (/220,225,230,235,240,245,250,255,260,270,280/)

  xcname   := "MPL_YlGn"; "precip_11lev"
  diffgrp0 := fspan(0,0.2,11)

  dcname   := read_colormap_file("CBR_coldhot")
  dcname   := dcname(::-1,:)
  diffgrp1 := (/-6.0,-4.0,-2.0,-1.0,-0.5,0.5,1.0,2.0,4.0,6.0/)
  ndiff    := dimsizes(diffgrp1)

 end if

 if (Varname .eq. "OMEGA500") then
  minvar := -40
  maxvar :=  40
  maxLev := 9
  mnmxint:= nice_mnmxintvl(minvar,maxvar,maxLev, False)
  ocname := "NCV_banded" ;"amwg"  ; color bar name for cntrol model plot
  orglev := (/-80,-60,-40,-20,-10,0,10,20,40,60,80/)

  xcname   := "MPL_YlGn"; "precip_11lev"
  diffgrp0 := fspan(0,3,11)

  dcname   := read_colormap_file("CBR_coldhot")
  dcname   := dcname(::-1,:)
  diffgrp1 := (/-60.0,-40.0,-20.0,-10.0,-5.0,5.0,10.0,20.0,40.0,60.0/)/5.0
  ndiff    := dimsizes(diffgrp1)

 end if

 if (Varname .eq. "U10") then
  minvar :=  0
  maxvar :=  30
  maxLev := 9
  mnmxint:= nice_mnmxintvl(minvar,maxvar,maxLev, False)
  ocname := "NCV_banded" ;"amwg"  ; color bar name for cntrol model plot
  orglev := (/0,1,2,3,4,5,6,7,8,10,12/)

  xcname   := "MPL_YlGn"; "precip_11lev"
  diffgrp0 := fspan(0,0.1,11)

  dcname   := read_colormap_file("CBR_coldhot")
  dcname   := dcname(::-1,:)
  diffgrp1 := (/-5.0,-2.0,-1.0,-0.5,-0.1,0.1,0.5,1.0,2.0,5.0/)
  ndiff    := dimsizes(diffgrp1)
 end if

 if (Varname .eq. "SHFLX") then
  minvar :=  0
  maxvar :=  30
  maxLev := 9
  mnmxint:= nice_mnmxintvl(minvar,maxvar,maxLev, False)
  ocname := "NCV_banded" ;"amwg"  ; color bar name for cntrol model plot
  orglev := (/0,5,10,20,30,40,50,60,70,80,100/)

  xcname   := "MPL_YlGn"; "precip_11lev"
  diffgrp0 := fspan(0,3,11)

  dcname   := read_colormap_file("CBR_coldhot")
  dcname   := dcname(::-1,:)
  diffgrp1 := (/-60.0,-40.0,-20.0,-10.0,-5.0,5.0,10.0,20.0,40.0,60.0/)/5.0
  ndiff    := dimsizes(diffgrp1)

 end if

 if (Varname .eq. "LHFLX") then
  minvar :=  0
  maxvar := 120
  maxLev := 9
  mnmxint:= nice_mnmxintvl(minvar,maxvar,maxLev, False)
  ocname := "NCV_banded" ;"amwg"  ; color bar name for cntrol model plot
  orglev := (/-15.0,0.0,15.0,30.0,45.0,60.0,75.0,90.0,105.0,120.0/)

  xcname   := "MPL_YlGn"; "precip_11lev"
  diffgrp0 := fspan(0,3,11)

  dcname   := read_colormap_file("CBR_coldhot")
  dcname   := dcname(::-1,:)
  diffgrp1 := (/-60.0,-40.0,-20.0,-10.0,-5.0,5.0,10.0,20.0,40.0,60.0/)/5.0
  ndiff    := dimsizes(diffgrp1)

 end if

 if (Varname .eq. "PRECT") then
  minvar := 0
  maxvar := 4
  maxLev := 9
  mnmxint:= nice_mnmxintvl(minvar,maxvar,maxLev, False)
  ocname := "WhBlGrYeRe" ;"NCV_banded" ;"amwg"  ; color bar name for cntrol model plot
  orglev := (/0.1,0.2,0.5,1.0,1.5,2.0,2.5,3.0,3.5,4.0,5.0/)

  xcname   := "MPL_YlGn"; "precip_11lev"
  diffgrp0 := fspan(0,0.1,11)

  dcname   := read_colormap_file("CBR_coldhot")
  dcname   := dcname(::-1,:)
  diffgrp1 := (/-1.0,-0.8,-0.5,-0.1,-0.05,0.05,0.1,0.5,0.8,1.0/)
  ndiff    := dimsizes(diffgrp1)

 end if

 if (Varname .eq. "PRECC") then
  minvar := 0
  maxvar := 4
  maxLev := 9
  mnmxint:= nice_mnmxintvl(minvar,maxvar,maxLev, False)
  ocname := "WhBlGrYeRe" ;"NCV_banded" ;"amwg"  ; color bar name for cntrol model plot
  orglev := (/0.0,0.1,0.2,0.5,0.8,1.0,2.0,3.0,4.0,6.0,8.0/)
  orglev := (/0.01,0.05,0.08,0.1,0.2,0.5,0.8,1.0,1.5,2.0/)

  xcname   := "MPL_YlGn"; "precip_11lev"
  diffgrp0 := fspan(0,0.06,11)

  dcname   := read_colormap_file("CBR_coldhot")
  dcname   := dcname(::-1,:)
  diffgrp1 := (/-0.8,-0.4,-0.2,-0.1,-0.01,0.01,0.1,0.2,0.4,0.8/)
  ndiff    := dimsizes(diffgrp1)

 end if

 if (Varname .eq. "PRECL") then
  minvar := 0
  maxvar := 4
  maxLev := 9
  mnmxint:= nice_mnmxintvl(minvar,maxvar,maxLev, False)
  ocname := "WhBlGrYeRe" ;"NCV_banded" ;"amwg"  ; color bar name for cntrol model plot
  orglev := (/0.1,0.2,0.3,0.4,0.5,0.8,1.0,2.0,3.0,4.0,5.0,6.0,7.0,8.0/)
  orglev := (/0.01,0.1,0.5,1.0,1.5,2.0,2.5,3.0,4.0,6.0,8.0/)
  orglev := (/0.1,0.2,0.5,1.0,1.5,2.0,2.5,3.0,3.5,4.0,5.0/)

  xcname   := "MPL_YlGn"; "precip_11lev"
  diffgrp0 := fspan(0,0.1,11)

  dcname   := read_colormap_file("CBR_coldhot")
  dcname   := dcname(::-1,:)
  diffgrp1 := (/-1.0,-0.8,-0.5,-0.1,-0.05,0.05,0.1,0.5,0.8,1.0/)
  ndiff    := dimsizes(diffgrp1)
 end if

 if (Varname .eq. "UVS") then

  if(refpres.eq.1000.)then
   refvec1 = 10. 
   refvec2 = 1.
   difflevs := (/-1.0,-0.75,-0.5,-0.25,0,0.25,0.5,0.75,1.0/)
  else if (refpres.eq.850.)
   refvec1 = 10.
   refvec2 = 1.
   difflevs := (/-1.0,-0.75,-0.5,-0.25,0,0.25,0.5,0.75,1.0/)
  else if (refpres.eq.700.)
   refvec1 = 20.
   refvec2 = 1.
   difflevs := (/-1.0,-0.75,-0.5,-0.25,0,0.25,0.5,0.75,1.0/)
  else if (refpres.eq.500.)
   refvec1 = 25.
   refvec2 = 1.5 
   difflevs := (/-2.0,-1.0,-0.5,-0.25,0,0.25,0.5,1.0,2.0/)
  else if (refpres.eq.200.)
   refvec1 = 30.
   refvec2 = 2.
   difflevs := (/-2.0,-1.0,-0.5,-0.25,0,0.25,0.5,1.0,2.0/)
  else
   refvec1 = 10.
   refvec2 = 1.
  end if 
  end if 
  end if 
  end if 
  end if 

  ocname := "NCV_banded" ;"amwg"  ; color bar name for cntrol model plot
  orglev := ispan(190,240,5) ;(/-10,0, 5, 10, 15, 20, 25, 30, 40, 50, 60, 70, 80, 90/)
  ocname  := "WhBlGrYeRe" ;"NCV_banded" ;"amwg"  ; color bar name for cntrol model plot

  dcname   := "BlueDarkRed18"
  difflevs := (/-2.0,-1.0,-0.5,-0.2,0,0.2,0.5,1.0,2.0/)

 end if

