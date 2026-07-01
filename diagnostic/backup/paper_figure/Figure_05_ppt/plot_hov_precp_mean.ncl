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
     ModelOutRoot = "/pic/projects/uq_climate/zhan391/Nudging_analysis/F20TRC5-CMIP6_NUDG_ISSUE/JIAN_DIAG/VARS/"
  end if

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  Groups       = (/"TRMM", "PDNUDG_UV_ENS01", "PDNUDG_UVTQ_ENS01",  "PDDART_UVTQ_ENS80"/)
  Labels       = (/"TRMM", "NDG-UV", "NDG-UVTQ", "EDA-UVTQ"/)

  ngrps        = dimsizes(Groups)
  plot         = new(9,graphic)

 ;;;;;;variables to be plotted;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  VarList      = (/"PRECT"/)
  UnitList     = (/"mm day~S~-1~N~"/)
  PltNums      = (/"a", "b", "c", "d", "e", "f", "g", "h"/)
  nvars        = dimsizes(VarList)

 ;;;loop the regions and plot the PDF
 load "./sc_cloud_region.ncl"

 do irg = 0,nsubreg-1,1

 do iv = 0,nvars-1, 1

  Varname = VarList(iv)
  Varunt  = UnitList(iv)

  plotFileLabel = "Fig05" ;VarList(iv)+"_hovmoller"
 ;;;;;;;open a wks for plot;;;;;;;;;;;;;;;;;;;
  OUTDir  = "./"
  wtype = "pdf"
  ;wtype@wkWidth = 2500
  ;wtype@wkHeight = 2500
  ;wtype@wkPaperSize     = "A4"
  ;wtype@wkOrientation   = "landscape"    ;;pictures displayed along the length
  ;wtype@wkOrientation   = "landscape"    ;;pictures displayed along the length
  wks1 = gsn_open_wks(wtype,OUTDir+plotFileLabel)

  load "./var_share_colorbar.ncl"

  do igp = 0,ngrps-1,1

  Figstr  = "("+PltNums (igp)+") "+Labels(igp)

  Vardat  = Subrgs(irg)+"_"+VarList(iv)+"_"+Groups(igp)

  out_file_name = "Hovmoller_201101_daily_mean_vs_TRMM_Meridional_Mean_"+str_sub_str(Subreg(irg)," ","_")+".nc"

  File1       = addfile(ModelOutRoot+"/"+out_file_name,"r")
  pncreplt    = File1->$Vardat$
  Ptimes      = File1->time
  datestr     = cd_calendar(Ptimes, -2 )      ; yyyymmdd
 
  LeftString  = ""
  RightString = ""

  LeftString   = "("+PltNums (igp)+") "+Labels(igp)

  if(pncreplt@pc(0).ne.-9999.0) then

     Rstr1        = "   Corr: "+sprintf("%5.2f",pncreplt@pc(0))
     Rstr2        = "RMSE: "+sprintf("%5.2f",pncreplt@rmse(0))

     if(pncreplt@pc(3).ne.0) then
       Rstr1      = Rstr1 + " ~F34~1~N~~F~ " + sprintf("%5.2f",pncreplt@pc(3)) 
       Rstr2      = Rstr2 + " ~F34~1~N~~F~ " + sprintf("%5.2f",pncreplt@rmse(3))
     end if

     RightString  = Rstr1 + "~C~" + Rstr2

  end if 
 
 ;print(datestr)
 ;printVarSummary(pncreplt)

;----------------------------------------------------------------------
; Plotting section
;---Resources to share between both plots
  res                           = True                   ; plot mods desired
  res@vpHeightF                 = vpHeightF
  res@vpWidthF                  = vpWidthF
 ;res@vpXF                      = 0.02
  res@gsnDraw                   = False
  res@gsnFrame                  = False
  res@gsnStringFontHeightF      = FontHeight*0.95
  res@gsnRightStringFontHeightF = FontHeight
  res@gsnLeftStringFontHeightF  = FontHeight
  res@tmXBLabelFontHeightF      = FontHeight
  res@tmYLLabelFontHeightF      = FontHeight
  res@tmYRLabelFontHeightF      = FontHeight
  res@tiMainFontHeightF         = FontHeight*1.2
  res@tiXAxisFontHeightF        = FontHeight*1.2
  res@tiYAxisFontHeightF        = FontHeight*1.2

  res@lbLabelBarOn            = False      ; Will turn on in panel later
 ;res@pmLabelBarParallelPosF  = 0.55
  res@pmLabelBarOrthogonalPosF= 0.15
  res@lbOrientation           = "Horizontal";"vertical"        ; vertical label bar
  res@pmLabelBarHeightF       = 0.25 ;0.65
  res@pmLabelBarWidthF        = 0.7 ;0.1
 ;res@lbTitleString           = "" ;Varunt;Varstr+ " ("+Varunt+")";
 ;res@lbTitlePosition         = "Right"                           ; title location
 ;res@lbTitleDirection        = "Across"                          ; letter angle
 ;res@lbTitleAngleF           = 90.                               ; title angle
 ;res@lbTitleFontHeightF      = 0.022       

  bthick = 1.0
  res@tmBorderThicknessF      = bthick

  ;res@gsnLeftStringParallelPosF    = -0.15
  ;res@gsnLeftStringOrthogonalPosF  =  0.06
  ;res@gsnRightStringOrthogonalPosF =  0.06
  ;res@gsnXYBarChart             = True              ; Create bar plot
  ;res@gsnXYBarChartOutlineOnly  = True
  ;res@trXLog                    = False
  ;res@trYLog                    = True

  res@tmXTOn                    = False
  res@tmYROn                    = True

  res@tmYLMode                  = "Explicit"
  res@tmYLMinorOn               = True
  res@tmYLMajorLengthF          = 0.015
  res@tmYLMajorOutwardLengthF   = 0.015
  res@tmYLMajorThicknessF       = bthick
  res@tmYLMinorLengthF          = 0.01
  res@tmYLMinorOutwardLengthF   = 0.01
  res@tmYLMinorPerMajor         = 4
  res@tmYLMinorThicknessF       = bthick
  res@tmYLLabelFontThicknessF   = bthick
  ;res@tmYLMode         = "Manual"
  ;res@tmYLTickSpacingF = 2
  ;res@tmYLFormat       = "f"
  ;res@tmYLTickSpacingF = yint
  ;res@trYMaxF          = ymax
  ;res@trYMinF          = ymin
  res@trYMinF           = min(Ptimes)
  res@trYMaxF           = max(Ptimes)
  res@tmYLValues        = Ptimes(::5)
  res@tmYLLabels        = datestr(::5)
  res@tmYLMinorValues   = Ptimes(::1)

  res@tmXBMode                  = "Explicit"
  res@tmXBMinorOn               = True
  res@tmXBMajorLengthF          = 0.015
  res@tmXBMajorOutwardLengthF   = 0.015
  res@tmXBMajorThicknessF       = bthick
  res@tmXBMinorLengthF          = 0.01
  res@tmXBMinorOutwardLengthF   = 0.01
  res@tmXBMinorPerMajor         = 4
  res@tmXBMinorThicknessF       = bthick
  res@tmXBLabelFontHeightF      = FontHeight
  res@tmXBLabelFontThicknessF   = bthick
  res@tmXBLabelDeltaF           = -0.6
 ;res@tmXBMode          = "Manual"
 ;res@tmXBFormat        = "f"
 ;res@tmXBTickSpacingF  = xint
 ;res@trXMaxF           = xmax
 ;res@trXMinF           = xmin
  res@gsnMajorLonSpacing = 60.
  res@gsnMinorLonSpacing = 30. ;res@gsnMajorLonSpacing
  res@trXMinF            = pncreplt&lon(0)
  res@trXMaxF            = pncreplt&lon(dimsizes(pncreplt&lon)-1)
  res@trYReverse         = True

  res@tmYLLabelJust     = "CenterRight"
  res@tmYRLabelJust     = "CenterRight"
  res@tmYUseLeft        = True
  res@tmYRLabelsOn      = False
  res@tiXAxisString     = "Longitude"
  res@tiYAxisString     = ""
  res@tiXAxisOffsetYF   = 0.
  res@tiYAxisOffsetXF   = 0.005
 ;res@xyComputeYMin     = True

  ;plotting
  ;res@gsnYRefLine            = (/-100.0/)            ; create a reference line
  ;res@gsnYRefLineDashPattern = 0
  ;res@gsnYRefLineColor       = "Grey";"Black"
  ;res@gsnYRefLineThicknessF  = 1.0

  res@tmYLLabelsOn           = False
  res@tmYLOn                 = False

  res=res
  res@cnFillOn             = True               ; turn on color fill
 ;res@cnFillPalette        = "WhiteBlueGreenYellowRed" ;"WhBlGrYeRe"
 ;res@cnLevelSelectionMode = "ManualLevels"     ; manual contour levels
 ;res@cnMinLevelValF       = ymin1
 ;res@cnMaxLevelValF       = ymax1
 ;res@cnLevelSpacingF      = yint1                 ; contour level spacing
  res@cnLevelSelectionMode  = "ExplicitLevels"
  res@cnLevels             := ylevs
  res@cnFillColors         := colorgroup1
  res@cnLinesOn                      = False ;plot_contour
  res@cnLineLabelsOn                 = False
  res@cnInfoLabelOn                  = False
  res@cnLineLabelDensityF            = 1.0
  res@cnLineLabelFontHeightF         = 0.018
  res@cnLineLabelBackgroundColor     = -1
  res@gsnContourLineThicknessesScale = 1.0
  res@cnLineThicknessF               = 1.0
  res@cnLineColor                    = "Black"
  res@gsnContourZeroLineThicknessF   = 1.
  res@gsnContourNegLineDashPattern   = 2

  res1 = res
  res1@tiMainString         = LeftString
  res1@gsnLeftString        = "" ;LeftString
  res1@gsnRightString       = "" ;RightString 
 ;res1@gsnRightStringOrthogonalPosF = 0.02
 ;res1@gsnLeftStringOrthogonalPosF = 0.02
  res1@gsnCenterString      = RightString
  res1@gsnRightStringOrthogonalPosF = 0.04
  res1@gsnLeftStringOrthogonalPosF = 0.04

  if(igp.ne.3)then
    res1@gsnCenterStringOrthogonalPosF = 0.02
  else
    res1@gsnCenterStringOrthogonalPosF = 0.0
  end if 
 ; if(igp.eq.0)then
 ;  res1@lbLabelBarOn            = True
 ;  res1@lbOrientation           = "vertical"        ; vertical label bar
 ;  res1@pmLabelBarHeightF       = 0.50
 ;  res1@pmLabelBarWidthF        = 0.10
 ;  res1@lbLabelFontHeightF      = 0.010               ; make labels smaller
 ;  res1@pmLabelBarParallelPosF  = 0.2
 ;  res1@pmLabelBarOrthogonalPosF= 0.01
 ; else
 ;  res1@lbLabelBarOn            = False
 ; end if 

  res1@tiMainFontThicknessF  = 2.0

  if(igp.eq.0)then
   res1@tiMainOffsetYF       = 0.02
  else
   res1@tiMainOffsetYF       = 0.0
  end if 

  if(igp.eq.0)then 
   res1@tmYLLabelsOn         = True
   res1@tmYLOn               = True
  else
   res1@tmYLLabelsOn         = False
   res1@tmYLOn               = False
  end if 

  plot(igp)                 = gsn_csm_hov(wks1,pncreplt,res1)

  delete([/pncreplt/])

 end do 

;---Draw both plots in a panel
  pnres                         = True
  pnres@gsnMaximize             = False
  pnres@gsnPanelMainString      = "" ;"Hovmoller diagrams of "+Varname+" over " + Figstr 
  pnres@gsnPanelMainFontColor   = "Black"
  pnres@gsnPanelMainFontHeightF = 0.012
  pnres@gsnPanelLabelBar        = True
  pnres@lbOrientation           = "vertical"        ; vertical label bar
  pnres@pmLabelBarHeightF       = 0.29
  pnres@pmLabelBarWidthF        = 0.06
  pnres@lbLabelFontHeightF      = 0.010               ; make labels smaller
  ;pnres@pmLabelBarParallelPosF  = 0.195
  ;pnres@pmLabelBarOrthogonalPosF= -0.17
  pnres@lbTitleString           = Varname+ " ("+Varunt+")"
  pnres@lbTitlePosition         = "Right"                           ; title location
  pnres@lbTitleDirection        = "Across"                          ; letter angle
  pnres@lbTitleAngleF           = 90.                               ; title angle
  pnres@lbTitleFontHeightF      = 0.010                              ; font height
 ;pnres@gsnPanelBottom          = 0.05
  pnres@gsnPanelYWhiteSpacePercent = 4
 ;pnres@gsnPanelXF = (/0.05,0.17,0.29,0.41,0.53,0.65/)    ; Adjust rightmost plots
  pnres@gsnPanelXF = (/0.10,0.28,0.46,0.64/)
  gsn_panel(wks1,(/plot(0),plot(1),plot(2),plot(3)/),(/1,4/),pnres)

 end do ; end of var loop

end do ; end of subreg loop

end

