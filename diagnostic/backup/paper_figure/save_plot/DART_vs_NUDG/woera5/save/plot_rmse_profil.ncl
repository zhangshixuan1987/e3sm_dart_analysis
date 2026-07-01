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
  Groups       = (/"ERA5","NDG_ERA5UVT","DARTEDA-UVT"/)
  ngrps        = dimsizes(Groups)
  labels       = (/"ERA5","NDGUVT","EDAUVT"/)

  VarNameList = (/"U_rmse", "V_rmse", "T_rmse", "Q_rmse" /)
  VarString   = (/"U", "V", "T", "Q"/)
  UnitList    = (/"m s~S~-1~N~", "m s~S~-1~N~", "K", "g kg~S~-1~N~"/)
  nvars       = dimsizes(VarNameList)
 
  xmin        = (/  0,  0, 0.5, 0.0/)
  xmax        = (/ 8., 8., 4.5, 2.5/)
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

  gsn_define_colormap(wks,"temp1")              ; choose colormap
  gsn_define_colormap(wks,"cb_9step")
  ;colors  = (/1,2,6,28,59/)
  ;gsn_merge_colormaps(wks1,"StepSeq25","cb_9step")
  ;colors  = (/1,2,17,85,55/) ;(/1,55,2,17,85/)       ;;(/18,4,9,18,4,9/); (/"palegreen4","orange4","navy"/)
  colors  = (/1,28,2,6,36,3/)
  markers = (/16, 4, 3, 6, 7, 9/)
  mkszf   = (/0.8, 0.8, 0.8, 0.8, 0.8, 0.8/)
  dashind = (/0,0,0,0,0,0/)    ;;line dash pattern
  lnthick = (/3,3,3,3,3,3/)*2.0 ;*1.0/2    ;;line thichness

  do ireg = 0,nregs-1,1

  pltdat = var3d(:,ireg,:)

  pltreg  = regions(regs(ireg)-1)
  
  ;print(pltdat@_FillValue)
  pltdat@_FillValue = 32766
  ;print(pltdat)

  mdat  = dim_avg_n(pltdat,1) 
;----------------------------------------------------------------------
; Plotting section
;---Resources to share between both plots
  res          = True                   ; plot mods desired
  res@vpHeightF = 0.6
  res@vpWidthF =  0.5
  res@gsnDraw  = False
  res@gsnFrame = False

  FontHeight = 0.025
  res@gsnStringFontHeightF = FontHeight*0.8
  res@tmXBLabelFontHeightF = FontHeight
  res@tmYLLabelFontHeightF = FontHeight
  res@tmYRLabelFontHeightF = FontHeight
  res@tiMainFontHeightF    = FontHeight
  res@tiXAxisFontHeightF   = FontHeight
  res@tiYAxisFontHeightF   = FontHeight

; add a legend
  res@pmLegendDisplayMode    = "Always"              ; turn on legend
  res@pmLegendSide           = "Top"                 ; Change location of
  res@pmLegendParallelPosF   = .75                   ; move units right
  res@pmLegendOrthogonalPosF = -0.45                  ; more neg = down
  res@pmLegendWidthF         = 0.12                  ; Change width and
  res@pmLegendHeightF        = 0.18                  ; height of legend.
  res@lgLabelFontHeightF     = .014                   ; change font height
  res@lgPerimOn              = False                 ; no box around

  res@trYReverse        = True                       ; reverse Y-axis
 ;res@xyYStyle          = "Log"
  res@tmYLMode          = "Explicit"                ; explicit labels
  res@tmYLValues        = (/1000,850,700,600,500,400,300,200,100/)
  res@tmYLLabels        = ""+res@tmYLValues         ; make strings

  res@tmXTOn  = False
  res@trYMaxF = 1000.0
  res@trYMinF = 50.0
  res@trXMaxF = xmax(iv)
  res@trXMinF = xmin(iv)

  res@gsnXRefLine             = (/0./)      ; four X reference lines
  res@gsnXRefLineThicknesses  = 1.0
  res@gsnXRefLineDashPatterns = 0
  res@gsnXRefLineColors       = "Grey"

  res@gsnRightString = Leftstring
  res@gsnLeftString  = "" ;Groups(0)

;  cloud fraction line variable
;  res@tmXTOn                  = True
;  resT                        = res
;  resT@pmLegendDisplayMode    = "Always" ;"Never"
;  resT@pmLegendSide           = "Top"                 ; Change location of
;  resT@pmLegendParallelPosF   = .22                   ; move units right
;  resT@pmLegendOrthogonalPosF = -0.39                ; more neg = down
; ;resT@trXMaxF                := tmax ;0.21
; ;resT@trXMinF                := tmin ;0.0
;  resT@gsnRightString         := ""
;  resT@gsnLeftString          := ""
;  resT@tiXAxisString          := "" ;"Cloud (fraction)";
;  resT@xyDashPatterns         := 2                   ; dashed line for 2nd
;  resT@xyMarkLineMode         := "Markers" ;"MarkLines"
;  resT@xyLineColors           := colors(2:3)
;  resT@xyMarkers              := markers(2:3)
;  resT@xyMarkerColors         := colors(2:3)
;  resT@xyLineThicknesses      := lnthick(2:3)              ; thicker line
;  resT@xyMarkerSizes          := 0.015*mkszf(2:3) 
;  resT@xyMarkerThicknesses    := lnthick(2:3) 
;  resT@tiXAxisString          = "# of observations" + " (x 10~S~"+log10(facts(3))+"~N~)";
;  resT@tiXAxisOffsetYF        = -0.005
;  resT@xyExplicitLegendLabels := "  "+(/"Possible","Assimilated"/) ;subvar(2:3)

  res@xyMarkLineMode         = "MarkLines"
  res@xyLineColors           = colors       ;(0:1)
  res@xyMarkers              = markers      ;(0:1)
  res@xyMarkerColors         = colors       ;(0:1)
  res@xyMarkerSizes          = 0.015*mkszf  ;(0:1)
  res@xyMarkerThicknesses    = lnthick      ;(0:1)
  res@xyDashPatterns         = dashind      ;(0:1)
  res@xyLineThicknesses      = lnthick      ;(0:1)
  res@pmLegendParallelPosF   = xpos(iv)                   ; move units right
  res@pmLegendOrthogonalPosF = ypos(iv)
 ; labels for the legend

  ;labels  = "  "+labels  ;+ "  pr="+sprintf("%5.2f",mdat)
  res@xyExplicitLegendLabels = "  " + labels ;subvar(0:1)

  res@tiMainString         = pltreg 
  res@tiMainOffsetYF       = 0.02
  res@tiMainFontThicknessF = 3.0

  res@gsnRightString       = hindstr ;VstList(0)
  res@gsnLeftString        = Leftstring ;Groups(0)
  res@tiXAxisString        = Varstr + " ("+Varunt+")" ;
  res@tiXAxisOffsetYF      = -0.015
  res@tiYAxisString        = Ystring

  plot(ireg)  = gsn_csm_xy (wks,pltdat,plevel,res)   ; create plot
              ;gsn_csm_x2y (wks,pltdat(0:1,:),pltdat(2:3,:),plevel,res,resT)   ; create plot

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
  pnres@gsnPanelXF = (/0.05,0.17,0.29,0.41,0.53,0.65/)    ; Adjust rightmost plots
  gsn_panel(wks,(/plot/),(/1,nregs/),pnres)
  delete([/pnres/])

end do 
end
