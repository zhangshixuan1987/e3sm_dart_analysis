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
  colors  = (/1,14,2,28,3/)
  colors  = (/1,28,14,2,3/)

  linemod  = (/"MarkLines","MarkLines","MarkLines", "MarkLines"/)
  markers  = (/16,6,4,7,8,2,11/)       ;;line markers
  mkszf    = (/0.8,0.8,0.8,0.8,0.8/)/4.0   ;;line marker size
  lnthick  = (/3,3,3,3,3/)*3.0   ;;line thichness
  dashind  = (/0,0,0,0,0/)       ;;line dash pattern
  mkthk    = mkszf
  mkthk    = 8.0


  ;;set up for fig size
  vpHeightF  = 0.8
  vpWidthF   = 0.4
  vpXF       = 0.25
  FontHeight = 0.022
  ylabs   := "Frequency of occurence (%)"
  xlabs   := Varstr + " ("+Varunt+")"

  amJust               = "TopRight"    ; Use bottom right corner of box
  amParallelPosF       =   0.48             ; Move legend to right
  amOrthogonalPosF     =  -0.48             ; Move legend down.

