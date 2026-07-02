;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;this script is used to difine the absolute difference levels (diffgrp1),;;; 
;;;;;;;;the relative difference levels (diffgrp2), then choose color bar for plot;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ;;;;;;;;;;;;;;;;;;;;;;;;
   ;colors  = (/"palegreen4","orange4","navy","palegreen4","orange4","navy"/)
   ; gsn_define_colormap(wks,"StepSeq25")
   ;;colors  = (/12,17/) ;(/1, 8 , 26, 15/)
   ; colors  = (/4,19/); (/"palegreen4","orange4","navy"/)
   gsn_define_colormap(wks,"t2m_29lev")
   colors  = (/26,2,19,5/)
   color1  = (/26,3,20,4/)

  ;gsn_define_colormap(wks,"cb_9step")
  ; colors  = (/2, 13, 30, 28, 20/)
  ;colors  = (/2, 6, 28, 35, 59/)
   lncolor = colors
   lncolor = -1

  barWidth = (/0.35,0.35,0.35,0.35,0.35/)
  barclr  = (/4,-1,-1,-1,-1,-1/)
  markers = (/11,8,4,2,7/)
  mkszf   = (/0.8,0.8,0.8,0.8/)
  dashind = (/0,0,0,0/)
  lnthick = (/5.0,5.0,5.0,5.0/)
  llth    = (/3.0,3.0,3.0,3.0/)
  bopc    = (/1.0,1.0,0.9,0.9,1.0/)
  bopc1   = (/1.0,0.6,0.6,0.6,1.0/)
  pattns  = (/0,0,0,0,0/)
 ;pattns  = (/0,3,3,3,3/)

