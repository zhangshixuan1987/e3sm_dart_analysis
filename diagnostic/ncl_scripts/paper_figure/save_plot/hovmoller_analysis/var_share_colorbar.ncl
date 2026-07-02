;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;this script is used to difine the absolute difference levels (diffgrp1),;;; 
;;;;;;;;the relative difference levels (diffgrp2), then choose color bar for plot;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;;setup for fill pattern
  ;FillColor           = "Grey75" ;"Grey65";"Grey28";"Grey";"Black"
  ;FillPattern         = 0 ;17 ;6 ;17;11
  ;FillScaleF          = 0.1
  ;FillDotSizeF        = 0.0002    ; increase dot size of contours
  ;FillOpacityF        = 1.0 ;0.15

  FillColor           = "Grey28";"Grey";"Black"
  FillPattern         = 17 ;6 ;17;11
  FillScaleF          = 0.5
  FillDotSizeF        = 0.002    ; increase dot size of contours
  FillOpacityF        = 0.8


  ;gsn_define_colormap(wks1,"StepSeq25")
  ;gsn_merge_colormaps(wks1,"StepSeq25","cb_9step")
  ;colors  = (/55,17,2,96/)
  gsn_define_colormap(wks1,"cb_9step")
  colors  = (/1,2,14,28,3/)

  markers = (/16,4,7,8,2,11/)       ;;line markers
  mkszf   = (/0.8,0.8,0.8,0.8,0.8/)/2.0   ;;line marker size
  lnthick = (/3,3,3,3,3/)*1.5   ;;line thichness
  dashind = (/0,0,0,0,0/)       ;;line dash pattern

  ;;set up for fig size
  vpHeightF  = 0.8
  vpWidthF   = 0.4
  vpXF       = 0.25
  FontHeight = 0.022
  ylabs   := "Frequency of occurence (%)"
  xlabs   := Varstr + " ("+Varunt+")"

 if (Varname .eq. "PRECT") then

  gsn_define_colormap(wks1, "MPL_BrBG") ; choose colormap
  colorgroup1 := (/10,25,40,55, 77,92,107,122/)

  gsn_define_colormap(wks1, "NCV_blu_red") ; choose colormap
  colorgroup1 := (/8,58,88,118,138,168,198,248/)

  gsn_define_colormap(wks1, "WhiteBlueGreenYellowRed") ; choose colormap
  colorgroup1 := (/8,28,48,68,88,108,128,148,168,188,208,228,248/)

  gsn_define_colormap(wks1, "WhBlGrYeRe") 
  colorgroup1 := (/5,10,20,30,40,50,60,70,80,90,100/)

  gsn_define_colormap(wks1, "MPL_PRGn") ; choose colormap
  colorgroup1 := (/12,28,44,56,73,87,103,119/)

  gsn_define_colormap(wks1, "BlueDarkRed18") ; choose colormap
  colorgroup1 := (/2,4,6,8,10,11,13,15,17,19/)

  gsn_define_colormap(wks1, "prcp_3") ; choose colormap
  colorgroup1 := (/3,4,5,7,10,11,12,13,14,17,19/) ;fspan(10,90,81)
  colorgroup1 := (/3,4,5,7,10,11,12,13,14,16,20/) ;fspan(10,90,81)

  gsn_define_colormap(wks1, "WhBlGrYeRe")
  colorgroup1 := (/5,10,20,30,40,50,60,70,80,90,100/)

  gsn_define_colormap (wks1,"amwg_blueyellowred")
  colorgroup1 := (/2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17/)
  colorgroup1 := (/2,5,6,7,9,10,11,12,13,14,15,17/)

  xmin1   := 0.
  xmax1   := 29.

  if (irg.eq.0)then
   ymin1   :=  0
   ymax1   := 16.
   yint1   :=  2
   ylevs   := (/0,0.5,1,2,3,4,5,6,8,10,12/)
  end if

  if (irg.eq.1)then
   ymin1   := 0
   ymax1   := 16.
   yint1   := 2
   ylevs   := (/0,0.5,1,2,3,4,5,6,8,12,16/)
  end if

  if (irg.eq.2)then
   ymin1   := 0
   ymax1   := 18.
   yint1   := 2
   ylevs   := (/0,1,2,3,4,5,6,8,10,12,14/)
  end if

  amJust               = "TopRight"    ; Use bottom right corner of box
  amParallelPosF       =   0.48             ; Move legend to right
  amOrthogonalPosF     =  -0.48             ; Move legend down.
 end if

 if (Varname .eq. "FLUT") then

  gsn_define_colormap(wks1, "MPL_BrBG") ; choose colormap
  colorgroup1 := (/10,25,40,55, 77,92,107,122/)
  
  gsn_define_colormap(wks1, "NCV_blu_red") ; choose colormap
  colorgroup1 := (/8,58,88,118,138,168,198,248/)
  
  gsn_define_colormap(wks1, "WhiteBlueGreenYellowRed") ; choose colormap
  colorgroup1 := (/8,28,48,68,88,108,128,148,168,188,208,228,248/)

  gsn_define_colormap(wks1, "WhBlGrYeRe")
  colorgroup1 := (/5,10,20,30,40,50,60,70,80,90,100/)

  gsn_define_colormap(wks1, "MPL_PRGn") ; choose colormap
  colorgroup1 := (/12,28,44,56,73,87,103,119/)

  gsn_define_colormap(wks1, "BlueDarkRed18") ; choose colormap
  colorgroup1 := (/2,4,6,8,10,11,13,15,17,19/)

  gsn_define_colormap(wks1, "prcp_3") ; choose colormap
  colorgroup1 := (/3,4,5,7,10,11,12,13,14,17,19/) ;fspan(10,90,81)
  colorgroup1 := (/3,4,5,7,10,11,12,13,14,16,20/) ;fspan(10,90,81)

  gsn_define_colormap(wks1, "WhBlGrYeRe")
  colorgroup1 := (/5,10,20,30,40,50,60,70,80,90,100/)

  xmin1   := 0.
  xmax1   := 29.

  if (irg.eq.0)then
   ymin1   := 180
   ymax1   := 260.
   yint1   := 8
   yref    := (/130,210/)
   ylevs   := (/200,208,216,224,228,232,236,240,244,248/)
  end if 

  if (irg.eq.1)then
   ymin1   := 200
   ymax1   := 254.
   yint1   := 6
   yref    := (/180,240/)
   ylevs   := (/200,208,212,216,220,224,228,232,236,242/)
  end if

  if (irg.eq.2)then
   ymin1   := 192
   ymax1   := 292.
   yint1   := 10
   yref    := (/80,180/)
   ylevs   := (/210,216,222,228,232,248,260,272,284,296/)
  end if
 
  amJust               = "TopRight"    ; Use bottom right corner of box
  amParallelPosF       =   0.48             ; Move legend to right
  amOrthogonalPosF     =  -0.48             ; Move legend down.
 end if

