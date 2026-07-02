;*************************************************
; histo_4.ncl
;
; Concepts illustrated:
;   - Drawing a histogram using exact min/max of data
;   - Generating dummy data using "rand"
;   - Drawing X axis labels at a 45 degree angle
;
;************************************************
;
; This file is loaded by default in NCL V6.2.0 and newer
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
;************************************************
begin

  regions  = (/"Northern Hemisphere","Southern Hemisphere", "Tropics", "North America"/)
  lonlim1  = (/  0.0,   0.0,   0.0, 235.0/)
  lonlim2  = (/360.0, 360.0, 360.0, 295.0/)
  latlim1  = (/ 20.0, -20.0, -90.0, 25.0/)
  latlim2  = (/ 90.0,  20.0, -20.0, 55.0/)

  hindstr      = "Analysis"
  figstr       = "d1"

  outdir = "/pic/projects/E3SM_DA/zhan391/final_analysis/post_processing/dart_nudg_obs_rmse/radiosonde_obs/"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  Groups       = (/"ERA5","EDAUVTQ_EN80","NDG_ERA5UVTQ","NDG_ERA5UV"/)
  ngrps        = dimsizes(Groups)
  labels       = (/"ERA5    ","DART    ", "NDG_UVTQ", "NDG_UV  "/)

  VarNameList = (/"U_rmse", "V_rmse", "T_rmse", "Q_rmse" /)
  VnmNameList = (/"U_ntob", "V_ntob", "T_ntob", "Q_ntob" /)
  VarString   = (/"U", "V", "T", "Q"/)
  UnitList    = (/"m s~S~-1~N~", "m s~S~-1~N~", "K", "g kg~S~-1~N~"/)
  nvars       = dimsizes(VarNameList)
 
  Leftstring  = "Mean rmse (January 2011)"
  Ystring     = "Pressure (hPa)"
 
 do iv = 0,nvars-1,1

  Varname = VarNameList(iv)
  Vnmname = VnmNameList(iv)
  Varunt  = UnitList(iv)
  Varstr  = VarString(iv)
  
  filnames = Groups(:)+"_obs_diag.nc"
  fxx      = addfiles(outdir+"/"+filnames,"r")
  ListSetType (fxx, "join")       
  print(filnames)

  regs        = fxx[0]->region
  plevel      = fxx[0]->plevel
  nlevs       = dimsizes(plevel)
  nregs       = dimsizes(regs)
  var4d       = fxx[:]->$Varname$  
  num4d       = fxx[:]->$Vnmname$

  if(Varstr.eq."Q")then
    var4d = var4d * 1000.0 ; convert to g/kg   
  end if 

  ;;;monthly mean;;;;;
  var3d       = dim_avg_n_Wrap(var4d,1)
  num3d       = dim_sum_n_Wrap(num4d,1)
 
  printVarSummary(var3d)
  print(num(ismissing(var3d)))
  print(min(var3d)+ " "+max(var3d))

  annoid      = new(nregs,graphic)
  plot        = new(nregs,graphic)
  plotlabel = Varname+"_profil"
  wtype = "png"
  wtype@wkWidth = 2500
  wtype@wkHeight = 2500
  wks = gsn_open_wks(wtype,plotlabel)             ; send graphics to PNG file
  
  load "./var_share_profile.ncl"

  do ireg = 0,nregs-1,1

   pltdat = var3d(:,ireg,:)
   pltnum = num3d(:,ireg,:) *1.0 / num_fact ; scale down the numebr of observations
   pltreg  = regions(regs(ireg)-1)
  ;print(pltdat@_FillValue)
   pltdat@_FillValue = 32766
  ;print(pltdat)
   mdat  = dim_avg_n(pltdat,1) 

;----------------------------------------------------------------------
; Plotting section
;---Resources to share between both plots

  res               = True           ; plot mods desired
  res@vpXF          = 0.25
  res@vpYF          = 0.8
  res@vpWidthF      = 0.4                      ; set width of plot
  res@vpHeightF     = 1.0                      ; set height of plot
  res@gsnDraw       = False
  res@gsnFrame      = False

  res@tmYROn = False            ; Turn off right tickmarks.
  res@tmXTOn = False            ; Turn off top tickmarks
  FontHeight = 0.028

  res@gsnStringFontHeightF  = FontHeight
  res@tmXBLabelFontHeightF  = FontHeight
  res@tmYLLabelFontHeightF  = FontHeight
  res@tmYRLabelFontHeightF  = FontHeight
  res@tiMainFontHeightF     = FontHeight
  res@tiXAxisFontHeightF    = FontHeight
  res@tiYAxisFontHeightF    = FontHeight

  ;res@tiMainFontThicknessF  = 8.0
  ;res@tiYAxisFontThicknessF = 5.0
  ;res@tiXAxisFontThicknessF = 5.0

  res@tmBorderThicknessF    = 1.5 * 2.0
  res@tmXBMajorThicknessF   = 1.5 * 2.0
  res@tmXBMinorThicknessF   = res@tmXBMajorThicknessF/2.0

  ;res@gsnYRefLine           = 0.0             ; create a reference line
  ;res@gsnYRefLineDashPattern= 2
  ;res@gsnYRefLineColor      = "Black"
  ;res@gsnYRefLineThicknessF = 1.0

  res@tiMainString         = "";pltreg
  res@tiMainOffsetYF       = 0.02
  res@tiMainFontThicknessF = 3.0

  res@gsnLeftStringFontColor  = "Black"
  res@gsnRightStringFontColor = "Black"
  res@gsnRightString          = "" ;hindstr ;VstList(0)
  res@gsnLeftString           = "" ;Leftstring ;Groups(0)
  res@gsnCenterString         = "" ;regions(ireg)

  res@trYMinF                 = 0.1 ;min(latrgd)
  res@trYMaxF                 = 2*nlevs+1.5 ;max(latrgd)
  res@tmYLMode                = "Explicit"
  res@tmYLValues              = fspan(1.075,2*nlevs+.075,nlevs) ;ispan(1,nvars,1)
  res@tmYLMinorValues         = fspan(1.075,2*nlevs+.075,nlevs) ;ispan(1,nvars,1)
  res@tmYLLabels              = plevel
 ;res@tmYLLabelDirection      = "Across"
 ;res@tmYLLabelAngleF         = 90.0
 ;res@tmYLLabelJust           = "CenterRight"

  res@tmYMajorGrid            = False        ; Add horizontal grid lines
  res@tmYMinorGrid            = False
  res@tmYMajorGridLineColor   = "LightGrey"
  res@tmYMinorGridLineColor   = "White"
  res@tmYMajorGridLineDashPattern = 5
  res@tmYMinorGridLineDashPattern = 5
  res@tmYMajorGridThicknessF  = 1.0
  res@tmGridDrawOrder         = "draw"    ; new resource added in NCL V6.5.0

  ;res@xyLineThicknessF     = 10.0            ; make thicker
  ;res@xyDashPatterns       = dashind(0:nvars)
  ;res@xyMarkerSizes        = 0.012
  ;res@xyLineColors         = colors(0:nvars)
  ;res@xyMarkers            = markers(0:nvars)
  ;res@xyMarkerColors       = colors(0:nvars)

  ;res@tmXTAutoPrecision    = False
  ;res@tmYLPrecision        =  2

  if(ireg.eq.0)then
    res@tmYLOn             = True            ; Turn off top tickmarks
    res@tiYAxisString      = Ystring
  else
    res@tmYLOn             = False           ; Turn off top tickmarks
    res@tiYAxisString      = ""
  end if 

  yy  = pltdat

  do igp = 0,ngrps-1
    yy(igp,:) = fspan(.60,2*nlevs-0.4,nlevs) + igp*0.32
  end do 

  yy1 = fspan(.60,2*nlevs-0.4,nlevs) + 0.48

;;;;;;;first figure for PD origional values;;;;;;;;;;;;;;;;;;;;
  res0                      = res
  res0@gsnXYBarChart         = True ; create bar chart
  res0@gsnXRefLine = 0.                  ; set the reference line equal to 0
  res0@gsnXYBarChartOutlineThicknessF = 0.5;1.008
  res0@gsnXYBarChartFillLineThicknessF = 1.0
  res0@trXMaxF              = xmax(ireg)
  res0@trXMinF              = xmin(ireg)
  res0@tmXBOn               = True            ; Turn off top tickmarks
  res0@tmXBLabelsOn         = True            ; Turn off top tickmarks
  res0@tmXBMode             = "Explicit"
  res0@tmXBValues          := fspan(res0@trXMinF,res0@trXMaxF,5)
  res0@tmXBMinorValues     := fspan(res0@trXMinF,res0@trXMaxF,13)
  res0@tmXBLabels          := res0@tmXBValues  ;(/"-0.2","-0.1","0.0","0.1","0.2"/)

  res0@tiMainString         = regions(ireg) ;""
  res0@tiMainOffsetYF       = 0.2
  res0@tiXAxisString        = Varstr + " ("+Varunt+")" ;
 ;res0@tiXAxisOffsetYF      = -0.015
  res0@gsnLeftString        = "" ;leftstring(0)
  res0@gsnLeftStringOrthogonalPosF = 0.04
  res0@xyLineColors              = (/-1,-1/);(/colors(0),colors(0)/)
  res0@gsnXYBarChartBarWidth     = barWidth(0)          ; change bar widths
  res0@gsnXYBarChartColors       = colors(0)
  res0@gsnXYBarChartFillOpacityF = bopc(0)
  res0@gsnXYBarChartPatterns     = pattns(0)
  res0@gsnXYBarChartFillScaleF   = 0.5

  plot(ireg) = gsn_csm_xy (wks,pltdat(0,:),yy(0,:),res0)   ; create plot

  ;;;;add patterns on the bar plot;;;;;;
  res01 = res0
 ;res01@xyLineThicknessF         = llth(0:1)            ; make thicker
 ;res01@xyDashPatterns           = dashind(0)
 ;res01@xyMarkerSizes            = 0.012
 ;res01@xyMarkers                = markers(0)
 ;res01@xyMarkerColors           = colors(0)
  res01@xyLineColors             = (/-1,-1/) ;(/colors(0),colors(0)/)
  res01@gsnXYBarChartColors      = colors(0)
  res01@gsnXYBarChartPatterns    = pattns(0)
  res01@gsnLeftString            = ""
  res01@gsnXYBarChartFillScaleF  = 0.5
  plot01   = gsn_csm_xy (wks,pltdat(0,:),yy(0,:),res0)   ; create plot
 ;overlay(plot(ireg),plot01)

  do igp = 1,ngrps-1

  ;;;;;the second experiment for MEAN (CNTL);;;;;
  resx=res0
  resx@tiMainString         = ""
  resx@tiXAxisString        = ""
  resx@tiYAxisString        = ""
  resx@gsnLeftString        = "" ;"Solid: 1800s       Dash: 300s"
  resx@gsnXYBarChartBarWidth= barWidth(igp)          ; change bar widths
  resx@xyLineColors         = (/-1,-1/) ;(/colors(1),colors(1)/)
  resx@gsnXYBarChartColors  = colors(igp)
  resx@gsnXYBarChartFillOpacityF = bopc(igp)
  plt1 = gsn_csm_xy (wks,pltdat(igp,:),yy(igp,:),resx)   ; create plot

  ;;;;add the patterns on bar plot;;;;;
  resx0 = resx
 ;resx0@xyLineThicknessF     = llth(igp)            ; make thicker
 ;resx0@xyDashPatterns       = dashind(igp)
 ;resx0@xyMarkerSizes        = 0.012
 ;resx0@xyMarkers            = markers(igp)
 ;resx0@xyMarkerColors       = colors(igp)
  resx0@xyLineColors         = (/-1,-1/);(/colors(1),colors(1)/)
  resx0@gsnXYBarChartColors  = colors(igp)
  resx0@gsnXYBarChartPatterns = pattns(igp)
  resx@gsnXYBarChartFillOpacityF = bopc(igp)
  resx0@gsnLeftString         = ""
  resx0@gsnXYBarChartFillScaleF = 0.5
  plotx0                     = gsn_csm_xy (wks,pltdat(igp,:),yy(igp,:),resx0)   ; create plot
 ;overlay(plt1,plotx0)
  overlay(plot(ireg),plt1) ;plotx0)

  end do 

;Attach a legend
;;manual legend
 lgres                    = True
 lgres@vpWidthF           = 0.12           ; width of legend (NDC)
 lgres@vpHeightF          = 0.07           ; height of legend (NDC)
 lgres@lbBoxMajorExtentF  = 0.12          ; puts space between color boxes
 lgres@lbMonoFillPattern  = False          ; Solid fill pattern
 lgres@lgLabelFontHeightF = FontHeight*0.1     ; legend label font thickness
 lgres@lgMonoDashIndex    = False
 lgres@lgMonoLineThickness= False
 lgres@lgPerimOn          = True
 lgres@lgPerimThicknessF  = 1.0
 lgres@lbLabelJust        = "CenterLeft"  ; left justify labels
 label1  = "  "+labels ;(/"  "+labels(0),"  "+labels(1),"  "+labels(2)/)
 ;label1  = label1(::-1)

  patt1=pattns ;(::-1)
  do i=0,dimsizes(label1)-1
  ;lgres@lbBoxLineDashPattern = 2;dashind(i)
   lgres@lbBoxLineColor   = 0 ;colors(i)
   lgres@lbFillColors     = colors(i)
   lgres@lbFillOpacityF   = bopc(1)*3.0
   lgres@lbFillPatterns   = patt1(i)
  ;lgres@lbBoxLineThicknessF = 1
  ;lgres@gsnXYBarChartFillScaleF = 0.5
   ;gsn_labelbar_ndc(wks,1,label1(i),0.86,0.97+i*0.024,lgres)
   gsn_labelbar_ndc(wks,1,label1(i),0.78,0.80+i*0.024,lgres)
  end do

  do i=0,dimsizes(label1)-1
   lgres@lbBoxLineColor   = 1 ;colors(i)
   lgres@lbFillColors     = colors(i)
   lgres@lbFillOpacityF   = bopc(1)*3.0
   lgres@lbFillPatterns   = patt1(i)
   ;lgres@gsnXYBarChartFillScaleF = 0.5
   ;gsn_labelbar_ndc(wks,1,label1(i),0.86,0.97+i*0.024,lgres)
   gsn_labelbar_ndc(wks,1,label1(i),0.78,0.80+i*0.024,lgres)
  end do

;---Get viewport values for bar plot
  getvalues plot(ireg)
    "vpXF"      : vpx
    "vpYF"      : vpy
    "vpWidthF"  : vpw
    "vpHeightF" : vph
  end getvalues
;
; Make sure XY curve is drawn in same viewport space as bar plot
; Note there is no attempt to mathematically map the left and 
; right Y axis to each other. 
;
;---XY curve resources
  resT                        = res
  resT@vpXF      = vpx
  resT@vpYF      = vpy
  resT@vpWidthF  = vpw
  resT@vpHeightF = vph

  resT@tmXTOn                  = True
  resT@pmLegendDisplayMode    = "Never"
  resT@pmLegendSide           = "Top"                 ; Change location of
  resT@pmLegendParallelPosF   = .22                   ; move units right
  resT@pmLegendOrthogonalPosF = -0.33                ; more neg = down
  resT@trXMaxF                := x2max(ireg)
  resT@trXMinF                := x2min(ireg) 
  resT@gsnRightString         := ""
  resT@gsnLeftString          := ""
  resT@tiXAxisString          := "" ;"Cloud (fraction)";
  resT@xyDashPatterns         := 2                   ; dashed line for 2nd
  resT@xyMarkLineMode         := "MarkLines"
  resT@xyLineColors           := "Black"
  resT@xyMarkers              := markers
  resT@xyMarkerColors         := "Black"
  resT@xyLineThicknesses      := lnthick
  resT@xyMarkerSizes          := 0.015*mkszf
  resT@xyMarkerThicknesses    := lnthick

 ;;;;set a title on the top ;;;
  resT@tiYAxisString          = ""
  resT@tiXAxisString          = "# of observations" + " (x 10~S~"+log10(num_fact)+"~N~)";
  resT@tiXAxisOffsetYF        = -0.005
  resT@tiXAxisSide            = "Top";"Right"
  resT@tiXAxisAngleF          = 0.0  ;270              ; Rotate the Y-axis title 270 degrees

  resT@xyExplicitLegendLabels := "  "+(/"Possible","Assimilated"/) 

 ;---Turn off bottom, top, and left tickmarks
  resT@tmXBOn              = False
  resT@tmXTOn              = True
  resT@tmYLOn              = False
  resT@tmYROn              = False
  resT@tmXTLabelsOn        = True

  ;resT@gsnYRefLine           = 20               ; Draw horiz line at y=20
  ;resT@gsnYRefLineColor      = "NavyBlue"
  ;resT@gsnYRefLineThicknessF = 2.0

  resT@vpXF      = vpx
  resT@vpYF      = vpy
  resT@vpWidthF  = vpw
  resT@vpHeightF = vph

  xy_plot = gsn_csm_xy (wks,pltnum,yy1,resT)
  
  annoid(ireg) = gsn_add_annotation(plot(ireg), xy_plot, False)

 end do ; end of region

;---Draw both plots in a panel
  pnres                         = True
  pnres@gsnMaximize             = False
  pnres@gsnPanelMainString      = "" ;"Hovmoller plots for " + Varstr
  pnres@gsnPanelMainFontColor   = "Black"
  pnres@gsnPanelMainFontHeightF = 0.016
  pnres@gsnPanelLabelBar        = False
  pnres@gsnPanelBottom          = 0.05
  pnres@gsnPanelYWhiteSpacePercent = 2
  pnres@gsnPanelXF = (/0.15,0.35,0.55,0.75/)    ; Adjust rightmost plots
  gsn_panel(wks,(/plot/),(/1,nregs/),pnres)
  delete([/pnres/])

end do 
end
