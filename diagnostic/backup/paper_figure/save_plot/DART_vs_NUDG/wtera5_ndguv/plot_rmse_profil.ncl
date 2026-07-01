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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  Groups       = (/"ERA5","NDG_ERA5UV","DARTEDA-UVTQ"/)
  ngrps        = dimsizes(Groups)
  labels       = (/"ERA5      ","Nudging","DART DA"/)

  VarNameList = (/"U_rmse", "V_rmse", "T_rmse", "Q_rmse" /)
  VarString   = (/"U", "V", "T", "Q"/)
  UnitList    = (/"m s~S~-1~N~", "m s~S~-1~N~", "K", "g kg~S~-1~N~"/)
  nvars       = dimsizes(VarNameList)
 
  xmin        = (/  0,  0,    0.0, 0.0/)
  xmax        = (/  8., 8.,   4.0, 4.0/)
  xpos        = (/ 0.75, 0.75, 0.75, 0.75/)
  ypos        = (/-1.05,-1.05,-0.75,-0.75/)

  Leftstring  = "Mean rmse (January 2011)"
  Ystring     = "Pressure (hPa)"
  MinY        = 5.0 ; top level

  outdir = "./"
 
 do iv = 0,nvars-1,1

  Varname = VarNameList(iv)
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
  
  if(Varstr.eq."Q")then
    var4d = var4d * 1000.0 ; convert to g/kg   
  end if 

  ;;;monthly mean;;;;;
  var3d       = dim_avg_n_Wrap(var4d,1)
  
  printVarSummary(var3d)
  print(num(ismissing(var3d)))
  print(min(var3d)+ " "+max(var3d))

  plot        = new(nregs,graphic)
  plotlabel = Varname+"_profil"
  wtype = "png"
  wtype@wkWidth = 2500
  wtype@wkHeight = 2500
  wks = gsn_open_wks(wtype,plotlabel)             ; send graphics to PNG file

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
  colors  = (/13,51,28/)

  barWidth = (/0.8,0.8,0.4/) ;(/0.65,0.8/)
  barclr  = (/4,-1,-1/)
  markers = (/11,8,4/)
  mkszf   = (/0.8,0.8,0.8,0.8/)
  dashind = (/0,0,0,0/)
  lnthick = (/5.0,5.0,5.0,5.0/)
  llth    = (/3.0,3.0,3.0,3.0/)
  bopc    = (/1.0,1.0,1.0/)
  bopc1   = (/0.35,0.5,0.65/)
  pattns  = (/0,0,0/)

  do ireg = 0,nregs-1,1

   pltdat = var3d(:,ireg,:)
   pltreg  = regions(regs(ireg)-1)
  ;print(pltdat@_FillValue)
   pltdat@_FillValue = 32766
  ;print(pltdat)
   mdat  = dim_avg_n(pltdat,1) 
   yy    = plevel(:)
;----------------------------------------------------------------------
; Plotting section
;---Resources to share between both plots

  res               = True           ; plot mods desired
  res@vpXF          = 0.25
  res@vpYF          = 0.8
  res@vpWidthF      = 0.4                      ; set width of plot
  res@vpHeightF     = 0.9                      ; set height of plot
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

  res@tiMainString         = pltreg
  res@tiMainOffsetYF       = 0.02
  res@tiMainFontThicknessF = 3.0

  res@gsnLeftStringFontColor  = "Black"
  res@gsnRightStringFontColor = "Black"
  res@gsnRightString          = "" ;hindstr ;VstList(0)
  res@gsnLeftString           = "" ;Leftstring ;Groups(0)
  res@gsnCenterString         = regions(ireg)

  res@trYMinF                 = 0.1 ;min(latrgd)
  res@trYMaxF                 = 2*nlevs+1.25 ;max(latrgd)
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

  res@gsnXYBarChart         = True ; create bar chart
  res@gsnXRefLine = 0.			; set the reference line equal to 0
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

  if(ireg.eq.0)then
    res@tmYLOn             = True            ; Turn off top tickmarks
    res@tiYAxisString      = Ystring
  else
    res@tmYLOn             = False           ; Turn off top tickmarks
    res@tiYAxisString      = ""
  end if 

  yy1 = fspan(.90,2*nlevs-0.1,nlevs)-0.2
  yy2 = fspan(1.28,2*nlevs+.28,nlevs)+0.2
  yy3 = 0.5*(yy1+yy2)

;;;;;;;first figure for PD origional values;;;;;;;;;;;;;;;;;;;;
  res0                      = res
  res0@trXMaxF              = xmax(iv)
  res0@trXMinF              = xmin(iv)
  res0@tmXBOn               = True            ; Turn off top tickmarks
  res0@tmXBLabelsOn         = True            ; Turn off top tickmarks
  res0@tmXBMode             = "Explicit"
  res0@tmXBValues          := fspan(res0@trXMinF,res0@trXMaxF,5)
  res0@tmXBMinorValues     := fspan(res0@trXMinF,res0@trXMaxF,13)
  res0@tmXBLabels          := res0@tmXBValues  ;(/"-0.2","-0.1","0.0","0.1","0.2"/)
  res0@tiMainString         = ""
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

  plot(ireg) = gsn_csm_xy (wks,pltdat(2,:),yy2,res0)   ; create plot

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
  plot01   = gsn_csm_xy (wks,pltdat(2,:),yy2,res0)   ; create plot
 ;overlay(plot(ireg),plot01)


  ;;;;;the second experiment for MEAN (CNTL);;;;;
  resx=res0
  resx@tiMainString         = ""
  resx@tiXAxisString        = ""
  resx@tiYAxisString        = ""
  resx@gsnLeftString        = "" ;"Solid: 1800s       Dash: 300s"
  resx@gsnXYBarChartBarWidth= barWidth(1)          ; change bar widths
  resx@xyLineColors         = (/-1,-1/) ;(/colors(1),colors(1)/)
  resx@gsnXYBarChartColors  = colors(1)
  resx@gsnXYBarChartFillOpacityF = bopc(1)
  plt1 = gsn_csm_xy (wks,pltdat(1,:),yy1,resx)   ; create plot

  ;;;;add the patterns on bar plot;;;;;
  resx0 = resx
 ;resx0@xyLineThicknessF     = llth(1)            ; make thicker
 ;resx0@xyDashPatterns       = dashind(1)
 ;resx0@xyMarkerSizes        = 0.012
 ;resx0@xyMarkers            = markers(1)
 ;resx0@xyMarkerColors       = colors(1)
  resx0@xyLineColors         = (/-1,-1/);(/colors(1),colors(1)/)
  resx0@gsnXYBarChartColors  = colors(1)
  resx0@gsnXYBarChartPatterns = pattns(1)
  resx@gsnXYBarChartFillOpacityF = bopc(1)
  resx0@gsnLeftString         = ""
  resx0@gsnXYBarChartFillScaleF = 0.5
  plotx0                     = gsn_csm_xy (wks,pltdat(1,:),yy1,resx0)   ; create plot
 ;overlay(plt1,plotx0)
  overlay(plot(ireg),plotx0)

  ;;;;;the thrid experiment for MEAN (CNTL);;;;;
  resy=res0
  resy@tiMainString         = ""
  resy@tiXAxisString        = ""
  resy@tiYAxisString        = ""
  resy@gsnLeftString        = "" ;"Solid: 1800s       Dash: 300s"
  resy@xyLineColors         = (/-1,-1/) ;(/colors(1),colors(1)/)
  resy@gsnXYBarChartColors  = colors(2)
  resy@gsnXYBarChartFillOpacityF = bopc(2)
  resx@gsnXYBarChartBarWidth= barWidth(2)          ; change bar widths
  plty = gsn_csm_xy (wks,pltdat(0,:),yy3,resy)   ; create plot

  ;;;;add the patterns on bar plot;;;;;
  resy0 = resy
 ;resy0@xyLineThicknessF      = llth(2)            ; make thicker
 ;resy0@xyDashPatterns        = dashind(2)
 ;resy0@xyMarkerSizes         = 0.012
 ;resy0@xyMarkers             = markers(2)
 ;resy0@xyMarkerColors        = colors(2)
  resy0@xyLineColors          = (/-1,-1/);(/colors(1),colors(1)/)
  resy0@gsnXYBarChartColors   = colors(2)
  resy0@gsnXYBarChartPatterns = pattns(2)
  resy0@gsnXYBarChartFillOpacityF = bopc(2)
  resy0@gsnLeftString         = ""
  resy0@gsnXYBarChartFillScaleF = 0.5
  ploty1                     = gsn_csm_xy (wks,pltdat(0,:),yy3,resy0)   ; create plot
 ;overlay(plt1,ploty1)
  overlay(plot(ireg),ploty1)

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
 label1  = (/"  "+labels(0),"  "+labels(1),"  "+labels(2)/)
 label1  = label1(::-1)

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
