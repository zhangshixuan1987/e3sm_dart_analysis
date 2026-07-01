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
     ModelOutRoot = "../Figure_DATA/rmse_bias_vs_clim//"
  end if

  plotFileLabel = "FigA1"

  load  "./fig_setup.ncl"

  plot     = new(2,graphic)
  dum1     = new((/2/),graphic)
  dum2     = new((/2/),graphic)

  ;;;;;;variables to be plotted;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  leftstring    = (/"(a) Relative difference in global mean","(b) Relative difference in global pattern"/)
  file_name     = "Bias_and_RMSE_5year_mean_with_respect_to_observations.nc"
  right_string  = "CLIM (5-yr)"

  ;;;;;;;;;;select the regions to calculate the rmse;;;;;;;;;;;;;
  l_shorter_name  = False
  labels       = (/"JAN (EAMv0)", "ANN (EAMv0)"/)
  nlabs        = dimsizes(labels)
  Groups       = (/"PDFREE"/)
  ngrps        = dimsizes(Groups)
  season       = (/"01","ANN"/)
  nseas        = dimsizes(season)

  fin = addfile(ModelOutRoot+"/"+file_name,"r")

  xlabnam             = fin->Evaluated_variables
  nvars               = dimsizes(xlabnam)
 
 ;;;processe the zonal mean data;;;;
  plotbias  = new((/nseas,nvars/),float)
  plotrmse  = new((/nseas,nvars/),float)
  plotxlab  = new((/nseas,nvars/),float)

  do igp  = 0,nseas-1

   vnmbias             = Groups+"_BIAS_"+season(igp)
   vnmrmse             = Groups+"_RMSE_"+season(igp)
   
   plotxlab(igp,:)     = ispan(1,nvars,1) + 0.5*(igp-ngrps/2.0) 
   plotbias(igp,:)     = fin->$vnmbias$
   plotrmse(igp,:)     = fin->$vnmrmse$

  end do 

  ;;;;;start to plot;;;;;;
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

  bthick = 1.0
  res@tmBorderThicknessF    = bthick
  res@tmXBMajorThicknessF   = bthick
  res@tmXBMinorThicknessF   = res@tmXBMajorThicknessF/2.0
  res@tmYLMajorThicknessF   = bthick
  res@tmYLMinorThicknessF   = res@tmYLMajorThicknessF/2.0

  res@gsnYRefLine           = 0.0             ; create a reference line   
  ;res@gsnYRefLineDashPattern= 2             
  ;res@gsnYRefLineColor      = "Black"
  ;res@gsnYRefLineThicknessF = 1.0

  res@tiMainString            = ""
  res@gsnLeftString           = "" ;"Solid: 1800s       Dash: 300s"
  res@gsnLeftStringFontColor  = ""
  res@gsnRightString          = ""
  res@gsnRightStringFontColor = ""

  
  res@xyMarkLineModes         = "Lines"

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

  ;res@tmYMajorGrid            = False        ; Add horizontal grid lines
  ;res@tmYMinorGrid            = False
  ;res@tmYMajorGridLineColor   = "LightGrey"
  ;res@tmYMinorGridLineColor   = "White"
  ;res@tmYMajorGridLineDashPattern = 5
  ;res@tmYMinorGridLineDashPattern = 5
  ;res@tmYMajorGridThicknessF  = 1.0
  ;res@tmGridDrawOrder         = "draw"    ; new resource added in NCL V6.5.0

  res@gsnXYBarChart                   = True ; create bar chart
  res@gsnXYBarChartOutlineThicknessF  = 0.5;1.008
  res@gsnXYBarChartFillLineThicknessF = 1.0

  ;res@xyLineThicknessF     = 10.0            ; make thicker
  ;res@xyDashPatterns       = dashind(0:nvars)
  ;res@xyMarkerSizes        = 0.012
  ;res@xyLineColors         = colors(0:nvars)
  ;res@xyMarkers            = markers(0:nvars)
  ;res@xyMarkerColors       = colors(0:nvars)

  ;res@tmXTAutoPrecision    = False
  ;res@tmYLPrecision        =  2
   res@tmXBOn               = True            ; Turn off top tickmarks
   res@tmXBLabelsOn         = True            ; Turn off top tickmarks

  do igp = 0,nseas-1,1

   res@xyLineColors              = (/-1,-1/);(/colors(0),colors(0)/)
   res@gsnXYBarChartBarWidth     = barWidth(igp)          ; change bar widths
   res@gsnXYBarChartColors       = colors(igp)
   res@gsnXYBarChartFillOpacityF = bopc(igp)
   res@gsnXYBarChartPatterns     = pattns(igp)
   res@gsnXYBarChartFillScaleF   = 0.5

   xx  = fspan(1.05,2*nvars+0.25,nvars)+0.5*(igp-ngrps/2.0)

   ;;;;plot global mean biases
   res0 = res
   res0@tmXBLabelsOn         = False            ; Turn off top tickmarks
   res0@trYMinF              = -0.15 ;floor(min(pltobs)) ;min(ynflx)-0.1 ;You could also just use
   res0@trYMaxF              =  0.15   ;ceil(max(pltobs)) ;max(ynflx)+0.1 ;min/max of u0,u1,u2.
   res0@tmYLMode             = "Explicit"
   res0@tmYLValues          := fspan(res0@trYMinF,res0@trYMaxF,5)
   res0@tmYLMinorValues     := fspan(res0@trYMinF,res0@trYMaxF,13)
   res0@tmYLLabels          := (/"-0.15","-0.10","-0.0","0.10","0.15"/)
   if(igp.eq.0)then
     res0@tiMainString                = ""
     res0@tiYAxisString               = "(NDG - CLIM) / CLIM"
     res0@tiXAxisString               = "";Varname(iv)+ " ("+var@units+")"
     res0@gsnLeftString               = leftstring(0)
     res0@gsnLeftStringOrthogonalPosF = 0.04
     res0@gsnLeftStringFontColor      = "Black"
     res0@gsnRightString              = right_string
     res0@gsnRightStringFontColor     = "Black"
   else
     res0@tiMainString                = ""
     res0@tiYAxisString               = ""
     res0@tiXAxisString               = ""
     res0@gsnLeftString               = ""
     res0@gsnRightString              = ""
   end if 

   dum1(igp) = gsn_csm_xy(wks,xx,plotbias(igp,:),res0)

   ;;;;plot global mean centered RMSD with respect to RMS of CLIM
   res1 = res
   res1@tmXBOn              = True            ; Turn off top tickmarks
   res1@tmXBLabelsOn        = True            ; Turn off top tickmarks
   res1@tiMainString         = ""
   res1@trYMinF              = 0.0
   res1@trYMaxF              = 1.0
   res1@tmYLMode             = "Explicit"
   res1@tmYLValues          := fspan(res1@trYMinF,res1@trYMaxF,6)
   res1@tmYLMinorValues     := fspan(res1@trYMinF,res1@trYMaxF,16)
   res1@tmYLLabels          := (/"0.0","0.2","0.4","0.6","0.8","1.0"/)
   if(igp.eq.0)then
     res1@tiMainString                = ""
     res1@tiYAxisString               = "cRMSD / RMS~B~CLIM~N~"
     res1@tiXAxisString               = "";Varname(iv)+ " ("+var@units+")"
     res1@gsnLeftString               = leftstring(1)
     res1@gsnLeftStringOrthogonalPosF = 0.02
     res1@gsnLeftStringFontColor      = "Black"
     res1@gsnRightString              = right_string
     res1@gsnRightStringOrthogonalPosF = 0.02
     res1@gsnRightStringFontColor     = "Black"
   else
     res1@tiMainString                = ""
     res1@tiYAxisString               = ""
     res1@tiXAxisString               = ""
     res1@gsnLeftString               = ""
     res1@gsnRightString              = ""
   end if 

   dum2(igp) = gsn_csm_xy(wks,xx,plotrmse(igp,:),res1)

   if(igp.eq.0)then
    plot(0) = dum1(igp)
    plot(1) = dum2(igp)
   else
    overlay (plot(0),dum1(igp))
    overlay (plot(1),dum2(igp))
   end if

  end do 

  ;Attach a legend
  lgres                    = True
  lgres@vpWidthF           = 0.16          ; width of legend (NDC)
  lgres@vpHeightF          = 0.10           ; height of legend (NDC)
  lgres@lbBoxMajorExtentF  = 0.12          ; puts space between color boxes
  lgres@lbBoxMinorExtentF  = 0.18
  lgres@lbMonoFillPattern  = False          ; Solid fill pattern
  lgres@lgLabelFontHeightF = FontHeight*0.1     ; legend label font thickness
  lgres@lgMonoDashIndex    = False
  lgres@lgMonoLineThickness= False
  lgres@lgPerimOn          = True
  lgres@lgPerimThicknessF  = 1.0
  lgres@lbLabelJust        = "CenterLeft"  ; left justify labels

  do i = 0,nlabs-1,1
  ;lgres@lbBoxLineDashPattern = 2;dashind(i) 
   lgres@lbBoxLineColor       = "black"
   lgres@lbBoxLineThicknessF  = 0.5
   lgres@lbFillColors         = colors(i)
   lgres@lbFillOpacityF       = bopc(1)*3.0
   lgres@lbFillPatterns       = pattns(i)
  ;lgres@gsnXYBarChartFillScaleF = 0.5
   ypos = 0.928 + (nlabs-i-1)*0.022
   gsn_labelbar_ndc(wks,1,labels(i),0.75,ypos,lgres)
  end do

   panres = True                                         ; panel resource list
   panres@gsnMaximize                = True
   panres@gsnPaperMargin             = 0.3
   panres@gsnPanelBottom             = 0.38     ; move bottom up so size is 0.3
   panres@gsnPanelYWhiteSpacePercent = 8.1       ;set spacing vertically between 2 panels
   panres@gsnPanelYF          = (/ -1.0,.64/)      ; Adjust bottommost plots.
   gsn_panel(wks,plot,(/2,1/),panres)
;  frame(wks)
end

