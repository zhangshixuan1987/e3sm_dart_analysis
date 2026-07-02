;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;this script is used to difine the absolute difference levels (diffgrp1),;;; 
;;;;;;;;the relative difference levels (diffgrp2), then choose color bar for plot;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

 ;Peruvian Sc region for sythentic analysis
  lats         = -20 ;-30
  late         = -5  ;-10
  lons         = -95 + 360
  lone         = -80 + 360

  ;;;colors and line setups  
  linstyle     = "MarkLines"
  gsn_define_colormap(wks1,"cb_9step")
  colors     = (/2,28,14,3,38/) ;(/3,28,2,14,36,77/)
  lncolors   = (/2,28,14,3,38/) ;(/1,1,1,1,1/)
  markers    = (/16, 16, 16, 16, 16, 16/)
  markers    = 4 
  mkthk      = markers
  mkthk      = 5
  mkszf      = (/0.8, 0.8, 0.8, 0.8, 0.8, 0.8/) ;/4
  dashind    = (/0,0,0,0,0,0/)       ;;line dash pattern
  lnthick    = (/1,1,1,1,1,1/)*5.0 ;1.5   ;;line thichness

  ;;;;;;;
  xyfillOpac = 0.2  ;;shading opacity for standard deviation
  FontHeight = 0.02 ;;font sizes of the figure 

  ;;;Legend setups 
  label1   := "" +labels
  colorsx  := colors(0:dimsizes(label1)-1)
  lnthickx := lnthick(0:dimsizes(label1)-1)
  dashindx := dashind(0:dimsizes(label1)-1)
  markersx := markers(0:dimsizes(label1)-1)
  mkthkx   := mkthk(0:dimsizes(label1)-1)
  mkszfx   := mkszf(0:dimsizes(label1)-1)
  fontsizx := colorsx
  fontsizx := FontHeight*0.3
  lnopacx  := lnthickx
  lnopacx  := 1
  itemspc  := 2 ; expressed as %, 0->100, space between legend items (Default = 5.)
  lbwhspc  := 1 ; expressed as %, 0->100, space between line and label (Default = 3.)
  lnlenpc  := 2 ; expressed as %, 0->100, length of line

  ;;;position of lagend labels
  spos         = "Top"
  xpos         = 8 ;.80
  ypos         = 65 ;-0.55
  xpos1        = .80
  ypos1        = -0.55

if (Varname .eq. "US") then
  ;; range of the x axises
  xmin         =  0.3
  xmax         =  1.2
end if 

if (Varname .eq. "VS") then
  ;; range of the x axises
  xmin         =  0.3
  xmax         =  1.2

end if

if (Varname .eq. "T") then
  ;; range of the x axises
  xmin         =  0.3
  xmax         =  1.2

end if

if (Varname .eq. "Q") then
  ;; range of the x axises
  if(Region_name(irg).eq.3)then
   xmin         =  0.0
   xmax         =  1.0
  else
   xmin         =  0.0
   xmax         =  1.0
  end if 
end if

