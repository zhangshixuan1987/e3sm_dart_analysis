;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;This script used to calculate and plot the zonal mean variables from CAM;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;The terms zonal and meridional are used to describe directions on a globe;;;;;;;
;;;;;;;Zonal means "along a latitudinal circle" or "in the west–east direction";;;;;;;;
;;;;;;;while meridional means "along a longitudinal circle" (a.k.a. meridian) ;;;;;;;;;
;;;;;;;or "in the north–south direction" [2];;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

  ldatalocal = True
  ldatalocal = True

  if (ldatalocal) then
     ModelOutRoot = "./"
  else
     ModelOutRoot = "./output/"
  end if
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  labels       = (/"EAMv0 (JAN)", "EAMv0 (ANN)"/)
  nlabls       = dimsizes(labels)
  Groups       = (/"PDFREE"/)
  ngrps        = dimsizes(Groups)

  season       = (/"01","ANN"/)
  nseas        = dimsizes(season)

  file_name = "Bias_and_RMSE_5year_mean_with_respect_to_observations.nc"
  fin = addfile(ModelOutRoot+"/"+file_name,"r")

  xlabnam      = fin->Evaluated_variables
  nvars        = dimsizes(xlabnam)

  outname0     = Groups+"_BIAS_"+season(0)
  outname1     = Groups+"_BIAS_"+season(1)
  outname2     = Groups+"_RMSE_"+season(0)
  outname3     = Groups+"_RMSE_"+season(1)

  v0_bias      = fin->$outname0$ 
  v1_bias      = fin->$outname1$
  v0_rmse      = fin->$outname2$
  v1_rmse      = fin->$outname3$

;;;;;;variables to be plotted;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  plotFileLabel ="global_mean_rmse_bias"

  leftstring = (/"(a) Relative error in global mean","(b) Relative error in global pattern"/)

;;;;;;;open a wks for plot;;;;;;;;;;;;;;;;;;;
  OUTDir  = "./"
  wtype = "pdf"
 ;wtype@wkPaperSize     = "A4"
 ;wtype@wkOrientation   = "landscape"    ;;pictures displayed along the length
  wks = gsn_open_wks(wtype,OUTDir+"Fig04_"+plotFileLabel)
;;;;;;;;;;;;;;;;;;;;;;;;
  ;colors  = (/"palegreen4","orange4","navy","palegreen4","orange4","navy"/)
; gsn_define_colormap(wks,"StepSeq25")
;;colors  = (/12,17/) ;(/1, 8 , 26, 15/)
; colors  = (/4,19/); (/"palegreen4","orange4","navy"/)

  gsn_define_colormap(wks,"t2m_29lev")
  ;colors  = (/ 6,2/)
  ;colors  = (/26,2,18/)
  colors  = (/26,2,19/)

  barWidth = (/0.8,0.8,0.55/)/1.2
  barclr  = (/4,-1,-1/)
  markers = (/11,8,7/)
  mkszf   = (/0.8,0.8,0.8,0.8/)
  dashind = (/0,0,0,0/) 
  lnthick = (/5.0,5.0,5.0,5.0/)
  llth    = (/3.0,3.0,3.0,3.0/)
  bopc    = (/1.0,0.5,0.5/)
  bopc1   = (/0.35,0.5,0.8/)
 ;pattns  = (/8,0/)
  pattns  = (/0,0,0/)

  plot    = new(2,graphic)                      

  res               = True           ; plot mods desired
  res@vpXF          = 0.17
  res@vpYF          = 0.8
  res@vpWidthF      = 0.9                      ; set width of plot
  res@vpHeightF     = 0.2                      ; set height of plot
  res@gsnDraw  = False
  res@gsnFrame = False

  res@tmYROn = False            ; Turn off right tickmarks.
  res@tmXTOn = False            ; Turn off top tickmarks
  FontHeight = 0.016
  res@gsnStringFontHeightF  = FontHeight*1.15
  res@tmXBLabelFontHeightF  = FontHeight
  res@tmYLLabelFontHeightF  = FontHeight
  res@tmYRLabelFontHeightF  = FontHeight
  res@tiMainFontHeightF     = FontHeight
  res@tiXAxisFontHeightF    = FontHeight*0.3
  res@tiYAxisFontHeightF    = FontHeight
  ;res@tiMainFontThicknessF  = 8.0
  ;res@tiYAxisFontThicknessF = 5.0
  ;res@tiXAxisFontThicknessF = 5.0

  res@gsnYRefLine           = 0.0             ; create a reference line   
  ;res@gsnYRefLineDashPattern= 2             
  ;res@gsnYRefLineColor      = "Black"
  ;res@gsnYRefLineThicknessF = 1.0
  
  res@gsnLeftString         ="" ;"Solid: 1800s       Dash: 300s"
  res@gsnLeftStringFontColor= "Black"
  res@gsnRightString         = "";"(PD)"
  res@gsnRightStringFontColor= "Black"
  res@xyMarkLineModes      = "Lines"

  res@trXMinF               = 0.1 ;min(latrgd)
  res@trXMaxF               = 2*nvars+1.25 ;max(latrgd)
  res@tmXBMode              = "Explicit"
  res@tmXBValues            = fspan(1.075,2*nvars+.075,nvars) ;ispan(1,nvars,1)
  res@tmXBMinorValues       = fspan(1.075,2*nvars+.075,nvars) ;ispan(1,nvars,1)
  res@tmXBLabels            = xlabnam
  res@tmXBLabelDirection    = "Across"
  res@tmXBLabelAngleF       = 90.0
  res@tmXBLabelJust         = "CenterRight"
  res@tmYLMinorPerMajor     = 2

  res@tmYMajorGrid            = False        ; Add horizontal grid lines
  res@tmYMinorGrid            = False
  res@tmYMajorGridLineColor   = "LightGrey"
  res@tmYMinorGridLineColor   = "White"
  res@tmYMajorGridLineDashPattern = 5
  res@tmYMinorGridLineDashPattern = 5
  res@tmYMajorGridThicknessF  = 1.0
  res@tmGridDrawOrder         = "draw"    ; new resource added in NCL V6.5.0

  res@gsnXYBarChart         = True ; create bar chart
  res@gsnXYBarChartOutlineThicknessF = 0.5;1.008
  res@gsnXYBarChartFillLineThicknessF = 1.0

  ;res@xyLineThicknessF     = 10.0            ; make thicker
  ;res@xyDashPatterns       = dashind(0:nvars)
  ;res@xyMarkerSizes        = 0.012
  ;res@xyLineColors         = colors(0:nvars)
  ;res@xyMarkers            = markers(0:nvars)
  ;res@xyMarkerColors       = colors(0:nvars)

  ;res@tmXTAutoPrecision    = False
  ;res@tmYLPrecision        =  2

  xx0 = fspan(.83,2*nvars-.17,nvars)-0.07
  xx1 = fspan(1.28,2*nvars+.28,nvars)+0.07

;;;;;;;first figure for PD origional values;;;;;;;;;;;;;;;;;;;;
  res0                      = res
  res0@trYMinF              = -0.2 ;floor(min(pltobs)) ;min(ynflx)-0.1 ;You could also just use
  res0@trYMaxF              =  0.2   ;ceil(max(pltobs)) ;max(ynflx)+0.1 ;min/max of u0,u1,u2.
  res0@tmYLMode             = "Explicit"
  res0@tmYLValues           := fspan(res0@trYMinF,res0@trYMaxF,5)
  res0@tmYLMinorValues      := fspan(res0@trYMinF,res0@trYMaxF,13)
  res0@tmYLLabels           := (/"-0.2","-0.1","0.0","0.1","0.2"/)
  res0@tiMainString         = ""
  res0@tiYAxisString        = "(EAM - OBS) / OBS"
  res0@tiXAxisString        = "";Varname(iv)+ " ("+var@units+")"
  res0@gsnLeftString        = leftstring(0)
  res0@gsnLeftStringOrthogonalPosF = 0.04
  res0@xyLineColors         = (/-1,-1/);(/colors(0),colors(0)/)
  res0@gsnXYBarChartBarWidth = barWidth(0)          ; change bar widths
  res0@gsnXYBarChartColors  = colors(0)
 ;res0@gsnXYBarChartFillOpacityF = bopc(1)
  res0@gsnXYBarChartPatterns = pattns(0)
  res0@gsnXYBarChartFillScaleF = 0.5
  res0@tmXBOn               = True            ; Turn off top tickmarks
  res0@tmXBLabelsOn         = False            ; Turn off top tickmarks
  plot(0)                   = gsn_csm_xy(wks,xx0,v0_bias,res0)

  ;;;;add patterns on the bar plot;;;;;;;;
  res01 = res0
 ;res01@xyLineThicknessF     = llth(0:1)            ; make thicker
 ;res01@xyDashPatterns       = dashind(0)
 ;res01@xyMarkerSizes        = 0.012
 ;res01@xyMarkers            = markers(0)
 ;res01@xyMarkerColors       = colors(0)
  res01@xyLineColors         = (/-1,-1/) ;(/colors(0),colors(0)/)
  res01@gsnXYBarChartColors  = colors(0)
  res01@gsnXYBarChartPatterns = pattns(0)
  res01@gsnLeftString         = ""
  res01@gsnXYBarChartFillScaleF = 0.5
  plot01                     = gsn_csm_xy(wks,xx1,v1_bias,res01)
 ;overlay(plot(0),plot01)

  ;;;;;the second experiment for MEAN (CNTL);;;;;
  resx=res0
  resx@tiMainString         = ""
  resx@tiXAxisString        = ""
  resx@tiYAxisString        = ""
  resx@gsnLeftString        = "" ;"Solid: 1800s       Dash: 300s"
  resx@xyLineColors         = (/-1,-1/) ;(/colors(1),colors(1)/)
  resx@gsnXYBarChartColors  = colors(1)
  resx@gsnXYBarChartFillOpacityF = 1.0 ;bopc(1)
  plt1 = gsn_csm_xy(wks,xx1,v1_bias,resx)

  ;;;;add the patterns on bar plot;;;;;
  resx0 = resx
 ;resx0@xyLineThicknessF     = llth(2)            ; make thicker
 ;resx0@xyDashPatterns       = dashind(2)
 ;resx0@xyMarkerSizes        = 0.012
 ;resx0@xyMarkers            = markers(2)
 ;resx0@xyMarkerColors       = colors(2)
  resx0@xyLineColors         = (/-1,-1/);(/colors(2),colors(2)/)
  resx0@gsnXYBarChartColors  = colors(2)
  resx0@gsnXYBarChartPatterns = pattns(2)
  resx0@gsnLeftString         = ""
  resx0@gsnXYBarChartFillScaleF = 0.5
  plotx0                     = gsn_csm_xy(wks,xx0,v0_bias,resx0)
 ;overlay(plt1,plotx0)
  overlay(plot(0),plotx0)
  
 ;;;;;;start the plot for rmsd;;;;;;
  res1 = res0
  res1@tiMainString         = ""
  res1@tiYAxisString        = "cRMSD / RMS~B~OBS~N~"
  res1@tiXAxisString        = "";Varname(iv)+ " ("+var@units+")"
  res1@gsnLeftString        = leftstring(1)
  res1@gsnLeftStringOrthogonalPosF = 0.04
  res1@tmXBOn               = True            ; Turn off top tickmarks
  res1@tmXBLabelsOn         = True            ; Turn off top tickmarks
  res1@trYMinF              = 0.0
  res1@trYMaxF              = 1.0
  res1@tmYLMode             = "Explicit"
  res1@tmYLValues           := fspan(res1@trYMinF,res1@trYMaxF,6)
  res1@tmYLMinorValues      := fspan(res1@trYMinF,res1@trYMaxF,16)
  res1@tmYLLabels           := (/"0.0","0.2","0.4","0.6","0.8","1.0"/)
  plot(1)                   = gsn_csm_xy(wks,xx0,v0_rmse,res1)

  ;;;;add patterns on the bar plot;;;;
  res11 = res1
  res11@xyLineColors          = (/-1,-1/) ;(/colors(0),colors(0)/)
  res11@gsnXYBarChartBarWidth = barWidth(1)          ; change bar widths
  res11@gsnXYBarChartColors   = colors(0)
  res11@gsnXYBarChartPatterns = pattns(0)
  res11@gsnLeftString         = ""
  res11@gsnXYBarChartFillScaleF = 0.5
  plot11                      = gsn_csm_xy(wks,xx1,v1_rmse,res11)
  overlay(plot(1),plot11)
  ;;;;;;;;

  ;;;;;;the second experiment for RMSD (CNTL);;;;
  resy1  = resx1
  resy1@trYMinF              = 0.0
  resy1@trYMaxF              = 1.0
  ploty1 = gsn_csm_xy(wks,xx1,v1_rmse,resy1)
  overlay(plot(1),ploty1)

;Attach a legend
;;manual legend
 lgres                    = True
 lgres@vpWidthF           = 0.18          ; width of legend (NDC)
 lgres@vpHeightF          = 0.10           ; height of legend (NDC)
 lgres@lbBoxMajorExtentF  = 0.12          ; puts space between color boxes
 lgres@lbMonoFillPattern  = False          ; Solid fill pattern
 lgres@lgLabelFontHeightF = FontHeight*2 ;*0.5     ; legend label font thickness
 lgres@lgMonoDashIndex    = False
 lgres@lgMonoLineThickness= False
 lgres@lgPerimOn          = True
 lgres@lgPerimThicknessF  = 1.0
 lgres@lbLabelJust        = "CenterLeft"  ; left justify labels
 label1  = (/"  "+labels(0),"  "+labels(1)/)

  patt1=pattns ;(::-1)
  do i=0,dimsizes(label1)-1
  ;lgres@lbBoxLineDashPattern = 2;dashind(i) 
   lgres@lbBoxLineColor   = 0 ;colors(i)
   lgres@lbFillColors     = colors(i)
   lgres@lbFillOpacityF   = bopc(1)*3.0
   lgres@lbFillPatterns   = patt1(i)
  ;lgres@lbBoxLineThicknessF = 1
  ;lgres@gsnXYBarChartFillScaleF = 0.5
   gsn_labelbar_ndc(wks,1,label1(i),0.80,0.99+i*0.024,lgres)
  end do

  do i=0,dimsizes(label1)-1
   lgres@lbBoxLineColor   = 1 ;colors(i)
   lgres@lbFillColors     = colors(i)
   lgres@lbFillOpacityF   = bopc(1)*3.0
   lgres@lbFillPatterns   = patt1(i)
   ;lgres@gsnXYBarChartFillScaleF = 0.5
   gsn_labelbar_ndc(wks,1,label1(i),0.80,0.99+i*0.024,lgres)
  end do

;  draw(plot(0))
;  frame(wks)
;
   panres = True                                         ; panel resource list
   panres@gsnMaximize                = True
   panres@gsnPaperMargin             = 0.3
   panres@gsnPanelBottom             = 0.38     ; move bottom up so size is 0.3
   panres@gsnPanelYWhiteSpacePercent = 8.1       ;set spacing vertically between 2 panels
   panres@gsnPanelYF          = (/ -1.0,.64/)      ; Adjust bottommost plots.
   gsn_panel(wks,plot,(/2,1/),panres)
;  frame(wks)
end

