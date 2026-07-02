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

  ;;;;;;;;;;select the regions to calculate the rmse;;;;;;;;;;;;;
  Regions      = (/"Global"/)
  nregs        = dimsizes(Regions)

  ;;;;;;;;;;select the regions to calculate the rmse;;;;;;;;;;;;;
  Groups  = (/"NCEP","CLIM","PDNUDG_ERA5_HIND_ENS01","PDDART_UVT_HIND_ENS80"/)
  ExpNam  = (/"NCEP","CLIM","Hybrid IC","EAM/DART"/)
  Hind    = (/"day1","day2","day5"/)
  Metric  = (/"BIAS","PROB"/)
  ngrps   = dimsizes(Groups)
  Plot_File = "./Global_map_e3sm_vs_"+Groups(0)+".nc"

 ;;;;;;variables to be plotted;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  Varname      = (/"U"/) 
  Varstr       = ("Zonal wind (U)")
  Varunt       = ("m s~S~-1~N~")
  nvars        = dimsizes(Varname)
  plotFileLabel = Varname+"_PD"

  ;;;;;;;;;;;;;;;;;;;;;;;;;;
  gpcp_key = (/"5YR_JAN"/)

  nexps   = 8
  plot    = new(nexps,graphic)
  dum     = new(nexps,graphic)
  labels  = new(nexps,string)
  labels(0)   = ExpNam(0)   + (/" (JAN, 5yr)"/)
  labels(1)   = ExpNam(1)   + " ~F34~>~N~~F~ " + ExpNam(0) + (/" (JAN, 5yr)"/)
  labels(2:3) = ExpNam(2:3) + " ~F34~>~N~~F~ " + ExpNam(0) + (/" (day 1)"/)
  labels(4:5) = ExpNam(2:3) + " ~F34~>~N~~F~ " + ExpNam(0) + (/" (day 2)"/)
  labels(6:7) = ExpNam(2:3) + " ~F34~>~N~~F~ " + ExpNam(0) + (/" (day 5)"/)

  plotcntl   = True
 ;plotcntl   = False
 ;plot_leftstr = False
  plot_leftstr = True

;;;;;;;open a wks for plot;;;;;;;;;;;;;;;;;;;
  OUTDir  = "./"
  wtype = "pdf"
 ;wtype@wkPaperSize     = "A4"
 ;wtype@wkOrientation   = "landscape"    ;;pictures displayed along the length
  wks1 = gsn_open_wks(wtype,OUTDir+"fig_sensitivity_"+plotFileLabel)
  gsn_define_colormap(wks1,"ncl_default")  
  gsn_define_colormap(wks1,"MPL_BrBG")
  gsn_define_colormap(wks1,"MPL_RdBu")
  colorgroup1 = (/12,22,32,42,52,0,81,89,99,109,119/)
  colorgroup1 = colorgroup1(::-1)
  gsn_define_colormap(wks1, "amwg_blueyellowred") ; choose colormap
  colorgroup1 = (/2,3,5,7,8,0,11,12,14,15,17/)
  gsn_define_colormap(wks1, "precip_diff_12lev") ; choose colormap
  colorgroup1 = (/2,3,4,5,6,0,10,11,12,13,14/)
  colorgroup1 = colorgroup1(::-1)
  gsn_define_colormap(wks1, "CBR_drywet") ; choose colormap
  colorgroup1 = (/2,3,4,5,6,0,8,9,10,11,12/)
  colorgroup1 = colorgroup1(::-1)

  diffgrp1    = (/-2.0,-1.0,-0.5,-0.2,-0.1,0.1, 0.2, 0.5, 1.5,2.0/)
  diffgrp2    = (/-30,-20,-10,-5,-1,1,5,10,20,30/)
  ndiff       = dimsizes(diffgrp1)

  f = addfile(Plot_File,"r")

  do i = 0,nexps-1,1

   if(i.eq.0) then
     varnam = Groups(i) + "_" + gpcp_key
     var1   = f->$varnam$
   else if (i.eq.1) then
     varnam = Groups(i) + "_" + gpcp_key +"_BIAS"
     var1   = f->$varnam$
   else

     if (i.le.3) then
       varnam = Groups(i)  + "_BIAS_" + Hind(0)
     else if(i.le.5) then
       varnam = Groups(i-2)  + "_BIAS_" + Hind(1)
     else
       varnam = Groups(i-4)  + "_BIAS_" + Hind(2)
     end if
     end if
     var1   = f->$varnam$

   end if 
   end if 
  
   printVarSummary(var1)

  ;rad     = 4.*atan(1.)/180.    ;
  ;cost    = cos(lat*rad)       ; cosine weights
  ;mean1x  = wgt_areaave(pncre0300,cost,1.0,0)
  ;mean2x  = wgt_areaave(wncredf1,cost,1.0,0)
  ;mean3x  = wgt_areaave(wncredf2,cost,1.0,0)
  ;mean1   = sprintf("%5.2f", mean1x)
  ;mean2   = sprintf("%5.2f", mean2x)
  ;mean3   = sprintf("%5.2f", mean3x) ;+ "%"

;----------------------------------------------------------------------
; Plotting section
;---Resources to share between both plots
  res                      = True              ; Plot modes desired.
  res@gsnDraw              = False
  res@gsnFrame             = False
  res@gsnMaximize          = False              ; Maximize plot
  res@gsnAddCyclic         = False

  res@cnFillOn              = True              ; color plot desired
 ;res@cnFillPalette         = "ViBlGrWhYeOrRe";"testcmap" ;"NCV_jaisnd";"temp_19lev"
  res@cnLinesOn             = False             ; turn off contour lines
  res@cnLineLabelsOn        = False             ; turn off contour labels
 ;res@cnFillMode            = "RasterFill"      ; turn raster on
  res@cnInfoLabelOn         = False
  res@cnMissingValFillColor = "White"


  res@lbLabelBarOn            = True      ; Will turn on in panel later
  res@lbAutoManage            = False             ; we control label bar
  res@lbLabelStride           = 1                 ; skip every other label
  res@lbLabelFontHeightF      = .022              ; default is HUGE
  res@lbPerimOn               = False             ; default has box
  res@lbOrientation           = "vertical"        ; vertical label bar
  res@pmLabelBarHeightF       = 0.6
  res@pmLabelBarWidthF        = 0.12
; res@pmLabelBarParallelPosF  = 0.026
; res@pmLabelBarOrthogonalPosF= 0.15


  res@tmXTOn                = False
  res@tmYROn                = False
  res@tmYRMode              = "Automatic"
  res@tiYAxisString         = "Pressure (hPa)"

  res@tiMainFontThicknessF   = 3.0
  res@tiMainFontHeightF      = 0.030
  res@tmYLLabelFontHeightF   = 0.028
  res@tmXBLabelFontHeightF   = 0.028
  res@lbLabelFontHeightF     = 0.028
  res@lbTitleFontHeightF     = 0.028                              ; font height
  res@tiXAxisFontHeightF     = 0.030
  res@tiYAxisFontHeightF     = 0.030
  res@gsnStringFontHeightF   = 0.028
  res@cnLineLabelFontHeightF = 0.025


  leftstr                  = "" ;"Surface Temperature ("+ts@units+")"
  res@gsnLeftString        = "" ; leftstr ;var_name0    ; long_name is too long!
  res@gsnRightString       = "" ;" ("+Varunt+")";""
 ;res@tiMaingString        = "Annual Mean Response to Present-day climate"

  res@lbTitleString        = "" ;Varunt;Varstr+ " ("+Varunt+")";
  res@lbTitlePosition      = "Right"                           ; title location
  res@lbTitleDirection     = "Across"                          ; letter angle
  res@lbTitleAngleF        = 90.                               ; title angle
  res@lbTitleFontHeightF   = 0.022                              ; font height

;---Resources for plotting original data
  if(plotcntl)then
    res1=res
    res1@cnFillPalette        = "amwg"; cmap;"MPL_RdYlGn" 
    res1@cnLevelSelectionMode = "ExplicitLevels"  
    res1@cnLevels             = (/-4.0,0,4,8,12,16,20,24,28,32,36/);ispan(-50,50,10)
    res1@lbBoxLinesOn         = True
   ;res1@lbBoxSeparatorLinesOn= False  
   ;res1@lbLabelStride        = 15
    res1@gsnLeftString        = labels(0)
   ;res1@gsnLeftStringOrthogonalPosF = 0.04
   ;res1@gsnLeftStringParallelPosF   = 0.2
    res1@gsnRightString              = Varunt

    res1@tiMainString         = "";"CNTL (PD1800)"
    res1@cnLinesOn            = False        
    res1@cnLineLabelsOn                 = False     
    res1@cnInfoLabelOn                  = False
    res1@cnLineLabelDensityF            = 2.0
    res1@cnLineLabelFontHeightF         = 0.018
    res1@cnLineLabelBackgroundColor     = -1
    res1@gsnContourLineThicknessesScale = 2.0
    res1@cnLineThicknessF               = 3.0
    res1@cnLineColor                    = "Black"
    res1@gsnContourZeroLineThicknessF   = 2.
    res1@gsnContourNegLineDashPattern   = 1
    ;res1@lbTitleString                  = Varunt 
   ;plot_org1  = gsn_csm_contour(wks1,var1,res1)
    plot_org1  = gsn_csm_pres_hgt(wks1,var1,res1)
   ;overlay(mpid1,plot_org1)
   plot(0) = plot_org1
  end if 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    res2=res
    res2@cnLevelSelectionMode   = "ExplicitLevels"  
    res2@cnFillColors           = colorgroup1
    res2@cnLevels               = diffgrp1
    res2@cnLinesOn              = False             ; turn off contour lines
    res2@cnLineLabelsOn         = False            ; turn off contour labels
    res2@cnInfoLabelOn                  = False
    res2@cnLineLabelDensityF            = 2.0
    res2@cnLineLabelFontHeightF         = 0.018
    res2@cnLineLabelBackgroundColor     = -1
    res2@gsnContourLineThicknessesScale = 2.0
    res2@cnLineThicknessF               = 3.0
    res2@cnLineColor                    = "Black"
    res2@gsnContourZeroLineThicknessF   = 2.
    res2@gsnContourNegLineDashPattern   = 1
    res2@tiMainString                = "";"PD300 - CNTL"
    res2@gsnLeftString               = labels(i)
   ;res2@gsnLeftStringOrthogonalPosF = 0.04
   ;res2@gsnLeftStringParallelPosF   = 0.2 
    res2@gsnRightString              = "";Varname ;Varunt
 
   ;res2@lbTitleString                  = Varunt 

  ;  if(igp.gt.0)then
  ;  res2@tmXTOn                = False
  ; ;res2@tmYLOn                = False
  ;  res2@tmYLLabelsOn          = False
  ;  res2@tiYAxisString         = "" 
  ;  end if 
  ;
  ;  if(igp.gt.0.and.igp.lt.3)then
  ;  res2@lbLabelBarOn            = False      ; Will turn on in panel later
  ;  end if 

   ;plot_rgd1                  = gsn_csm_contour(wks1,var1,res2)  
    plot_rgd1                  = gsn_csm_pres_hgt(wks1,var1,res2)
   ;overlay(mpid2,plot_rgd1)

    res2@cnFillColors                = colorgroup1
    res2@cnLevels                    = diffgrp1
    res2@tiMainString                = "";"PD300 - CNTL"
    res2@gsnLeftString               = "" ;labels(2)
    res2@gsnLeftStringOrthogonalPosF = 0.04
   ;res2@gsnLeftStringParallelPosF   = 0.2
    res2@gsnRightString              = "" ;Varname; Varunt
    ;res2@lbTitleString                  = "%" 
    plot_rgd2                  = gsn_csm_pres_hgt(wks1,var1,res2) 
   ;overlay(mpid3,plot_rgd2)

    tres                      = True                ; text mods desired
    tres@txFontHeightF        = 0.028               ; make smaller
    txid1 = gsn_create_text(wks1, Varunt, tres)
    txid2 = gsn_create_text(wks1, Varunt, tres)
    txid3 = gsn_create_text(wks1, "%", tres)
    amres = True
    amres@amParallelPosF   =  0.58    ; This is the right edge of the plot.
    amres@amOrthogonalPosF = -0.58    ; This is the bottom edge of the plot.
    ;annoid1 = gsn_add_annotation(plot_org1, txid1, amres)
    ;annoid2 = gsn_add_annotation(plot_rgd1, txid2, amres)
    ;annoid3 = gsn_add_annotation(plot_rgd2, txid3, amres)
    
  plot(i) = plot_rgd1

end do ; end of igp loop

;---Draw both plots in a panel
    pnres                         = True
    pnres@gsnMaximize             = False
    pnres@gsnPanelLabelBar        = False
    pnres@gsnPanelMainString      = "";Varstr; "Surface Temperature ("+ts@units+")"
    pnres@gsnPanelMainFontColor   = "Black"
    pnres@gsnPanelMainFontHeightF = 0.030
    pnres@lbLabelFontHeightF      = .01            ; default is HUGE
    pnres@lbPerimOn               = False             ; default has box
    pnres@lbOrientation           = "vertical"        ; vertical label bar 
    pnres@lbTitleString           = "("+Varunt+")" ;"~F33~D~N~~F~"+ "RH"+" ("+Varunt+")"
    pnres@lbTitlePosition         = "Right" 
    pnres@lbTitleDirection        = "Across" 
    pnres@lbTitleAngleF           = 90 
    pnres@lbTitleFontHeightF      = 0.01
    pnres@pmLabelBarHeightF       = 0.22
    pnres@pmLabelBarWidthF        = 0.06
    pnres@pmLabelBarParallelPosF  = -0.005
   ;pnres@pmLabelBarOrthogonalPosF= -0.15
    pnres@gsnPanelYWhiteSpacePercent = 2
    pnres@gsnPanelXWhiteSpacePercent = 5
    ;pnres@gsnPanelXF = (/0.05,0.25,0.42,0.59/)    ; Adjust rightmost plots
    gsn_panel(wks1,(/plot(0:)/),(/4,2/),pnres)

end
