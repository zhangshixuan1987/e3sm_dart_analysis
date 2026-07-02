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
  ldatalocal = False

  if (ldatalocal) then
     ModelOutRoot = "./"
  else
     ModelOutRoot = "/pic/projects/E3SM_DA/zhan391/final_analysis/post_processing/post_processing_data/"
  end if

;;;;;;;;;weight files for ESMF regrid function;;;;;
  wgt_dir  = "./"
  wgt_file = wgt_dir+"SE_NE30_to_FV_192x288.bilinear.nc"

;;;;;;;date strings for the data directory;;;;;;;;
  year         = 2011
  month        = 1
  nday         = 31
  ymstr1       = sprinti("%04d",year)+sprinti("%02d",month)
  ymstr2       = sprinti("%04d",year)+"-"+sprinti("%02d",month)

  mpMinLatF = -90.
  mpMaxLatF =  90.
  mpMinLonF =  0.
  mpMaxLonF = 360.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  Casdir1      = (/"PD_NDG_ERA5UV","PD_NDG_ERA5UVT","PD_NDG_ERA5UVTQ","PD_EDAUV_EN80","PD_EDAUVT_EN80","PD_EDAUVTQ_EN80"/)
  Casdir1      = Casdir1 + "_"+ymstr1
  Groups       = (/"NDG_ERA5UV","NDG_ERA5UVT","NDG_ERA5UVTQ","DARTEDA-UV","DARTEDA-UVT","DARTEDA-UVTQ"/)
  ngrps        = dimsizes(Groups)
  Labels       = Groups

  preslevs     = (/950,700,500,200/)
  nplevs       = dimsizes(preslevs)
  plot         = new(nplevs,graphic)

  Plttim       = (/"*ens*.cam.h0.*.nc","*ens*.cam.h0.*.nc","*ens*.cam.h0.*.nc","*ens*.cam.h0.*.nc","*ens*.cam.h0.*.nc","*ens*.cam.h0.*.nc","*ens*.cam.h0.*.nc","*ens*.cam.h0.*.nc","*ens*.cam.h0.*.nc"/)

 ;;;;;;variables to be plotted;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  VarList      = (/"U","T"/)
  VstList      = (/"Zonal wind","Temperature"/)
  UnitList     = (/"m s~S~-1~N~","K"/)
  PltNums      = (/"", "", "", "", "", "", "", "", "", "", ""/)
  nvars        = dimsizes(VarList)
  leftstr      = "TCC between "+VarList(0)+" and "+VarList(1)
                 ;"The temporal correlation coefficient (TCC) between "+VarList(0)+" and "+VarList(1)

 ;;; flags to control the plot style
  plotcntl          = False   ; if True, plot the CNTL origianl field on the leftmost panel

  plotrdif          = False  ; True  ; if True, plot the relative difference with respect to CNTL

  plot_ttest_mskout = False  ; if True, mask the non-significant region as missing values

  plot_ttest_hatch  = True  ; if True, plot the significant region as hatch region

  plot_ttest_hatrv  = False  ; if True, plot the non-significant region as hatch region

  plot_contour      = False  ; True   ; if True, plot the contour in the figure

  plot_leftstr      = True   ; if True, the lefadd igure captions as left string

  plot_lndmsk       = False ;
 ;;;these flags control the zonal mean plot
  plot_zonal_mean   = False  ; whether or not plot zonal mean
  add_fill_line     = False  ; Turn off (on if True) fill color below the zonal mean line
  add_std_shading   = False ; If true, the grey shading is added for uncertainty of zonal mean
  add_std_line      = False  ; If true, the dash red lines are added for upper and bottom bounds
                            ; of uncertainty for zonal mean

 ;;color for the map boundary line
  lndcolor = "Black" ;"Grey50"

 ;;flags to perform significant test;;;;;;;;
  l_studentttest    = False ; True if perform student-t test
  l_pairedttest     = True ;False ; True  ; True if perform parired-t test
  l_kstest          = False ;True  ; True if perform K-S test, see https://www.ncl.ucar.edu/Document/Functions/Built-in/kolsm2_n.shtml

 do igp = 0, ngrps-1,1
 
  plotFileLabel = Groups(igp)+"_"+VarList(0)+"_"+VarList(1)+"_tcc_2dmap"
 ;;;;;;;open a wks for plot;;;;;;;;;;;;;;;;;;;
  OUTDir  = "./"
  wtype = "png"
  wtype@wkWidth = 2500
  wtype@wkHeight = 2500
  ;wtype@wkPaperSize     = "A4"
  ;wtype@wkOrientation   = "landscape"    ;;pictures displayed along the length
  ;wtype@wkOrientation   = "landscape"    ;;pictures displayed along the length
  wks1 = gsn_open_wks(wtype,OUTDir+"fig_pdf_"+plotFileLabel)

  load "./var_share_colorbar.ncl"


  ;;;;;;;begin to work with the simulations;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  tescase   = Casdir1 (igp)
  Filnam1   = systemfunc("cd "+ModelOutRoot+tescase+"/"+"; ls -1 "+Plttim(igp))
  File1     = addfiles(ModelOutRoot+tescase+"/"+Filnam1,"r")
  ListSetType (File1, "join")
  
  lat       = File1[0]->lat
  lon       = File1[0]->lon
  times     = File1[0]->time
  pxcre0300 = File1[:]->$VarList(0)$
  wxcre0300 = File1[:]->$VarList(1)$
  printVarSummary(pxcre0300)
  printVarSummary(wxcre0300)

  Ptimes    = cd_convert(times, "days since "+ymstr2+"-01 00:00")
  datestr   = cd_calendar(Ptimes, -2 )      ; yyyymmdd
  print(datestr)
 
 do ilev = 0,nplevs-1,1 
  pres = preslevs (ilev)

  ;;calclulate the correlation;;;;;;;
  if(igp.le.2)then
   ccr = wxcre0300(0,{pres},:,:)
   ccr = escorc_n(wxcre0300(:,{pres},:,:),pxcre0300(:,{pres},:,:),0,0) ;;  ===> ccr(lat,lon)
  else
   ccr = wxcre0300(:,0,{pres},:,:)
   ccr = escorc_n(wxcre0300(:,:,{pres},:,:),pxcre0300(:,:,{pres},:,:),1,1) ;;  ===> ccr(lat,lon)
  end if 

  ;;;ensemble mean;;;;;;;
  if(igp.le.2)then
    crrplt     = ccr
  else
    crrplt     = dim_avg_n_Wrap(ccr,0)
  end if 

  ;wncreplt&time = Ptimes
  ;pncreplt&time = Ptimes
  ;printVarSummary(wncreplt)
  printVarSummary(crrplt)

;----------------------------------------------------------------------
; Plotting section
;---Resources to share between both plots
    res                      = True              ; Plot modes desired.
    res@gsnDraw              = False
    res@gsnFrame             = False
    res@gsnMaximize          = False              ; Maximize plot

    res@tmXTOn               = False
    res@tmYROn               = False
    res@tiMainFontHeightF    = 0.018
    res@tmYLLabelFontHeightF = 0.022
    res@tmXBLabelFontHeightF = 0.022

    mpres                    = res

    res@lbLabelFontHeightF   = 0.018
    res@gsnStringFontHeightF = 0.028
    res@cnFillOn             = True              ; color plot desired
   ;res@cnFillPalette        = "ViBlGrWhYeOrRe";"testcmap" ;"NCV_jaisnd";"temp_19lev"
    res@cnLinesOn            = False             ; turn off contour lines
    res@cnLineLabelsOn       = False             ; turn off contour labels
   ;res@cnFillMode           = "RasterFill"      ; turn raster on
    res@cnMissingValFillColor = "White"

    res@lbLabelBarOn            = False      ; Will turn on in panel later
   ;res@pmLabelBarParallelPosF  = 0.55
    res@pmLabelBarOrthogonalPosF= 0.15
    res@lbOrientation           = "Horizontal";"vertical"        ; vertical label bar
    res@pmLabelBarHeightF       = 0.2 ;0.65
    res@pmLabelBarWidthF        = 0.6 ;0.1
   ;res@lbTitleString           = "" ;Varunt;Varstr+ " ("+Varunt+")";
   ;res@lbTitlePosition         = "Right"                           ; title location
   ;res@lbTitleDirection        = "Across"                          ; letter angle
   ;res@lbTitleAngleF           = 90.                               ; title angle
   ;res@lbTitleFontHeightF      = 0.022                              ; font height

    res@gsnLeftString        = "";leftstr ;var_name0    ; long_name is too long!
    res@gsnRightString       = "";pres+" hPa" ;" ("+Varunt+")";""
 ;  res@tiMaingString        = "Annual Mean Response to Present-day climate"

;---Control appearance of map.
    mpres@gsnMajorLatSpacing     = 30 ;20
    mpres@gsnMajorLonSpacing     = 45 ;30
    mpres@gsnMinorLatSpacing     = 15 ;10
    mpres@gsnMinorLonSpacing     = 15 ;15
   ;mpres@mpProjection           = "Robinson"       ; choose projection
    mpres@mpLabelsOn             = False
    mpres@mpPerimOn              = False
    mpres@mpFillOn               = False
    mpres@mpGeophysicalLineColor = lndcolor  ; color of cont. outlines
    mpres@mpGeophysicalLineThicknessF = 1.0          ; thickness of outlines
   ;mpres@mpOutlineOn            = True
   ;mpres@mpOutlineDrawOrder     = "PostDraw"
   ;mpres@mpFillDrawOrder        = "Predraw"
   ;mpres@mpGridAndLimbOn        = True
   ;mpres@mpGridLatSpacingF      = 90.0
   ;mpres@mpGridLonSpacingF      = 180.0
   ;mpres@mpGridLineThicknessF   = 3.0
   ;mpres@mpGridAndLimbDrawOrder="PreDraw"

    ;mpres@mpMinLatF              = mpMinLatF
    ;mpres@mpMaxLatF              = mpMaxLatF
    ;mpres@mpMinLonF              = mpMinLonF
    ;mpres@mpMaxLonF              = mpMaxLonF
    ;mpres@mpCenterLonF           = mpCenterLonF
    mpres@mpCenterLonF           = 240 ;150.0
;   mpres@mpCenterLatF           = -90.     ; This is necessary to get the correct map
;   mpres@mpOceanFillColor       = "lightskyblue1"
;   mpres@mpLandFillColor        = "gray33"

;---Resources for plotting original data
    if (igp.eq.1)then
     if(plotcntl)then
      mpres@tmYLLabelsOn           = True
      mpres@tmYLOn                 = True
     else
      mpres@tmYLLabelsOn           = False
      mpres@tmYLOn                 = False
     end if
    else
     mpres@tmYLLabelsOn           = False
     mpres@tmYLOn                 = False
    end if
    plot(ilev) = gsn_csm_map(wks1,mpres)

    res2=res
    res2@gsnAddCyclic                   = True
    ;res2@cnLevelSelectionMode          = "ManualLevels"
    ;res2@cnMinLevelValF                = mnmxint(0)
    ;res2@cnMaxLevelValF                = mnmxint(1)
    ;res2@cnLevelSpacingF               = mnmxint(2)
     res2@cnLevelSelectionMode           := "ExplicitLevels"
     res2@cnLevels                       := fspan(-1,1,11) ;diffgrp1
     res2@cnFillPalette                  := "ViBlGrWhYeOrRe";"precip3_16lev" ;dcname
 ;    res2@lbBoxSeparatorLinesOn           = True
   ;res2@cnFillColors                   = orgcolors
    res2@lbBoxLinesOn                   = True
   ;res2@lbBoxSeparatorLinesOn          = False
   ;res2@lbLabelStride                  = 15
    res2@gsnAddCyclic                   = True
    res2@tiMainString                   = "" ;Groups(igp)
    res2@gsnLeftString                  = leftstr;"TCC of " ;Varstr + "  ("+ Varunt + ")"
    res2@gsnLeftStringOrthogonalPosF    = 0.02
   ;res2@gsnLeftStringParallelPosF      = 0.05
    res2@gsnRightString                 = pres+" hPa" ;" ("+Varunt+")";""
    res2@gsnRightStringOrthogonalPosF   = 0.02
   ;res2@gsnRightStringParallelPosF     = 0.9
    res2@cnLinesOn                      = plot_contour
    res2@cnLineLabelsOn                 = False
    res2@cnInfoLabelOn                  = False
    res2@cnLineLabelDensityF            = 2.0
    res2@cnLineLabelFontHeightF         = 0.018
    res2@cnLineLabelBackgroundColor     = -1
    res2@gsnContourLineThicknessesScale = 1.0
    res2@cnLineThicknessF               = 1.0
    res2@cnLineColor                    = "Black"
    res2@gsnContourZeroLineThicknessF   = 2.
    res2@gsnContourNegLineDashPattern   = 1
    plot_rgd1  = gsn_csm_contour(wks1,crrplt,res2)

    overlay(plot(ilev),plot_rgd1)
  
 end do ; end of ilev loop

;---Draw both plots in a panel
    pnres                         = True
    pnres@gsnMaximize             = False
    pnres@gsnPanelMainString      = "";"Hovmoller diagrams of "+Varstr+" over " + Figstr 
    pnres@gsnPanelMainFontColor   = "Black"
    pnres@gsnPanelMainFontHeightF = 0.012
    pnres@gsnPanelLabelBar        = True
    pnres@lbOrientation           = "vertical"        ; vertical label bar
    pnres@pmLabelBarHeightF       = 0.18
    pnres@pmLabelBarWidthF        = 0.04
    pnres@lbLabelFontHeightF      = 0.006               ; make labels smaller
   ;pnres@pmLabelBarParallelPosF  = -0.005
   ;pnres@pmLabelBarOrthogonalPosF= 0.005
    pnres@lbTitleString           = "";Varstr+ " ("+Varunt+")"
    pnres@lbTitlePosition         = "Right"                           ; title location
    pnres@lbTitleDirection        = "Across"                          ; letter angle
    pnres@lbTitleAngleF           = 90.                               ; title angle
    pnres@lbTitleFontHeightF      = 0.006                              ; font height
   ;pnres@gsnPanelBottom          = 0.05
    pnres@gsnPanelYWhiteSpacePercent = 4
   ;pnres@gsnPanelXF = (/0.05,0.17,0.29,0.41,0.53,0.65/)    ; Adjust rightmost plots
   ;pnres@gsnPanelXF = (/0.05,0.17,0.29,0.41/)
    gsn_panel(wks1,(/plot(0:)/),(/1,nplevs/),pnres)
   delete([/pnres/])

  delete([/wxcre0300,pxcre0300,Filnam1,File1,ccr/]) ;encorr,ermse,ccr/])

 end do ; end of igp loop

end

