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
  ;colors  = (/ 6,2/)
  ;colors  = (/26,2/)
  gsn_define_colormap(wks,"cb_9step")
  ;colors  = (/13,52/)
  ;colors  = (/6,2/)
  ;colors  = (/13,2/)
  colors   = (/13,25,28,29,51/)
  colors   = (/2, 13, 30, 28, 20/)
  colors   = (/2, 6, 28, 35, 59/)
  colors   = (/2, 14, 28, 3,38/) ;(/3,28,2,14,36,77/)

  barWidth = (/0.3,0.3,0.3,0.3,0.3/)
  barclr  = (/4,-1,-1,-1,-1,-1/)
  markers = (/11,8,4,2,7/)
  mkszf   = (/0.8,0.8,0.8,0.8/)
  dashind = (/0,0,0,0/)
  lnthick = (/5.0,5.0,5.0,5.0/)
  llth    = (/3.0,3.0,3.0,3.0/)
  bopc    = (/1.0,1.0,1.0,1.0,1.0/)
  bopc1   = (/0.35,0.5,0.65,0.65,0.65/)
  pattns  = (/0,0,0,0,0/)



if (Varname .eq. "U_rmse") then
  xmin        = (/  0,  0,    0.0,  0.0/)
  xmax        = (/  6., 6.,   6.0,  6.0/)
  xpos        = (/ 0.75, 0.75, 0.75, 0.75/)
  ypos        = (/-1.05,-1.05,-0.75,-0.75/)

  x2min       = (/  0,  0,    0.0, 0.0/)
  x2max       = (/ 16., 4.,   6.0, 4.0/)
  num_fact    = 1e4 ; scale factor for number of observations
end if 

if (Varname .eq. "V_rmse") then
  xmin        = (/  0,  0,    0.0,  0.0/)
  xmax        = (/  6., 6.,   6.0,  6.0/)
  xpos        = (/ 0.75, 0.75, 0.75, 0.75/)
  ypos        = (/-1.05,-1.05,-0.75,-0.75/)

  x2min       = (/  0,  0,    0.0, 0.0/)
  x2max       = (/ 16., 4.,   5.0, 4.0/)
  num_fact    = 1e4 ; scale factor for number of observations
end if


if (Varname .eq. "T_rmse") then
  xmin        = (/    0,      0,    0.0,    0.0/)
  xmax        = (/  4.0,    4.0,    4.0,    4.0/)
  xpos        = (/ 0.75,   0.75,   0.75,   0.75/)
  ypos        = (/-1.05,  -1.05,  -0.75,  -0.75/)

  x2min       = (/  0,   0,   0.0,  0.0/)
  x2max       = (/ 16.,  2.,  4.0,  6.0/)
  num_fact    = 1e4 ; scale factor for number of observations
end if


if (Varname .eq. "Q_rmse") then
  xmin        = (/    0,    0,   0.0,  0.0/)
  xmax        = (/  1.2,   2.,   2.8,  1.2/)
  xpos        = (/ 0.75, 0.75, 0.75, 0.75/)
  ypos        = (/-1.05,-1.05,-0.75,-0.75/)

  x2min       = (/  0,  0,    0.0, 0.0/)
  x2max       = (/ 15., 3.,   4.0, 5.0/)
  num_fact    = 1e4 ; scale factor for number of observations
end if



