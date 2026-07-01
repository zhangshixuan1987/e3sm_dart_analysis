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
;;;;;;;;;;select the regions to calculate the rmse;;;;;;;;;;;;;
  era5dir      = ""
  trmmdir      = "/pic/projects/E3SM_DA/zhan391/e3sm_dart/acme_init/Observations/TRMM/"+year+"/"+ymstr1+"/"
  olrdir       = "/pic/projects/E3SM_DA/zhan391/e3sm_dart/acme_init/Observations/NOAA_HIRS/"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  Casdir1      = (/"OBS","PD_Transpose-AMIP_Hind_d1","PD_Transpose-AMIP_Hind_d2","PD_Transpose-AMIP_Hind_d5","PD_EDAUVT_Hind_d1","PD_EDAUVT_Hind_d2","PD_EDAUVT_Hind_d5"/)
  Casdir1      = Casdir1 + "_"+ymstr1
  Groups       = (/"OBS","Transpose-AMIP_Hind_d1","Transpose-AMIP_Hind_d2","Transpose-AMIP_Hind_d5","EDAUVT_Hind_d1","EDAUVT_Hind_d2","EDAUVT_Hind_d5"/)
  ngrps        = dimsizes(Groups)
  Labels       = Groups
  OBSTR        = (/"TRMM", "NOAA-HIRS"/)
  plot         = new(ngrps,graphic)

  Plttim       = (/"*","*ens*.cam.h0.*.nc","*ens*.cam.h0.*.nc","*ens*.cam.h0.*.nc","*ens*.cam.h0.*.nc","*ens*.cam.h0.*.nc","*ens*.cam.h0.*.nc","*ens*.cam.h0.*.nc","*ens*.cam.h0.*.nc"/)

 ;;;;;;variables to be plotted;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  VarList      = (/"PRECT","FLUT"/)
  VstList      = (/"total precp.","OLR"/)
  UnitList     = (/"mm day~S~-1~N~","W m~S~-2~N~"/)
  PltNums      = (/"", "", "", "", "", "", "", "", "", "", ""/)
  nvars        = dimsizes(VarList)

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

 do iv = 0,nvars-1, 1

  Varname = VarList(iv)
  Varunt  = UnitList(iv)
  Varstr  = VstList(iv)

  plotFileLabel = Varname+"_tcc_2dmap"
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
 
 do igp = 1, ngrps-1,1
 
  ;;;;read the observations;;;;;;;;;;;;;; 
  if (Varname.eq."PRECT")then
   trmmdat0 = systemfunc("cd "+trmmdir+"/"+"; ls -1 "+Plttim(0))
   trmmdat  = trmmdat0(1:)
   Filobs  = addfiles(trmmdir+"/"+trmmdat,"r")
   ListSetType (Filobs, "join")
   Obname  = OBSTR(0)
   obsdat1 = Filobs[:]->precipitation
   ;;process the daily mean data
   dimx = dimsizes(obsdat1)
   dim1 = dimx(0)
   dim2 = dimx(1)
   dim3 = dimx(2)
   obsdat = new((/dim1/8,dim2,dim3/),typeof(obsdat1))
   do j = 0, dim1/8-1
      obsdat(j,:,:) = dim_avg_n(obsdat1(j*8:(j+1)*8-1,:,:),0) * 24.0
   end do
   print(dim1+ " "+dim1/8)
   printVarSummary(obsdat)
   delete([/trmmdat0,trmmdat,obsdat1/])
  else if (Varname.eq."FLUT")then
   olrdat  = olrdir+"olr.day.mean_1.9x2.5.nc"
   Filob1  = addfile(olrdat,"r")
   Obname  = OBSTR(1)
   obsdat0 = Filob1->olr
   tmptim  = Filob1->time
   tmptim  = tmptim+1
   ;;note that we should use 2010-12-31 instead of 2011-01-01 for hindcast;;;;;
   obstim  = cd_convert( tmptim, "days since 2010-12-31 00:00")
   indxx   = ind(obstim.ge.1.and.obstim.le.nday)
   ;print(indxx)
   obsdat  = obsdat0(indxx,:,:)
   ;printVarSummary(obsdat)
   delete([/tmptim,obsdat0,obstim,indxx/])
  end if 
  end if 

  ;print(obstim)
  ;;;;;;;begin to work with the simulations;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  tescase = Casdir1 (igp)
  Filnam1 = systemfunc("cd "+ModelOutRoot+tescase+"/"+"; ls -1 "+Plttim(igp))
  File1   = addfiles(ModelOutRoot+tescase+"/"+Filnam1,"r")
  ListSetType (File1, "join")
  
  lat       = File1[0]->lat
  lon       = File1[0]->lon
  times     = File1[0]->time

  if(Varname.eq."PRECT") then
    wxcre0300 = File1[:]->PRECC
    wxcre0300 = File1[:]->PRECC + File1[:]->PRECL
    wxcre0300 = wxcre0300*1000.0 *24.0 *3600.0 ;; mm/day
  else if(Varname.eq."NETCF") then
    wxcre0300 = File1[:]->LWCF
    wxcre0300 = File1[:]->LWCF + File1[:]->SWCF
  else
    wxcre0300 = File1[:]->$Varname$
  end if
  end if

  printVarSummary(wxcre0300)
  printVarSummary(wxcre0300)
  Ptimes    = cd_convert(times, "days since "+ymstr2+"-01 00:00")
  datestr   = cd_calendar(Ptimes, -2 )      ; yyyymmdd
  print(datestr)

  ;;zonal mean;;;;;;;
  rad     = 4.*atan(1.)/180.    ;
  cost    = lat
  cost    = cos(lat*rad)
  pxcre0300  = wxcre0300
  printVarSummary(obsdat)
  printVarSummary(pxcre0300)
  printVarSummary(wxcre0300)
  printVarSummary(obsdat)
  if(igp.le.3)then
    pxcre0300   = (/obsdat/)
    copy_VarCoords(wxcre0300,pxcre0300)
    pncre0300  = dim_avg_wgt_n_Wrap(pxcre0300(:,{mpMinLatF:mpMaxLatF},{mpMinLonF:mpMaxLonF}),cost({mpMinLatF:mpMaxLatF}),1,1)
    wncre0300  = dim_avg_wgt_n_Wrap(wxcre0300(:,{mpMinLatF:mpMaxLatF},{mpMinLonF:mpMaxLonF}),cost({mpMinLatF:mpMaxLatF}),1,1)
  else
    pxcre0300  = conform(wxcre0300,obsdat,(/1,2,3/)) 
    copy_VarCoords(wxcre0300,pxcre0300)
    pncre0300  = dim_avg_wgt_n_Wrap(pxcre0300(:,:,{mpMinLatF:mpMaxLatF},{mpMinLonF:mpMaxLonF}),cost({mpMinLatF:mpMaxLatF}),1,2)
    wncre0300  = dim_avg_wgt_n_Wrap(wxcre0300(:,:,{mpMinLatF:mpMaxLatF},{mpMinLonF:mpMaxLonF}),cost({mpMinLatF:mpMaxLatF}),1,2)
  end if
  
  if(igp.le.3)then
   ccr = wxcre0300(0,:,:)
   ccr = escorc_n(wxcre0300,pxcre0300,0,0) ;;  ===> ccr(lat,lon)
  else
   ccr = wxcre0300(:,0,:,:)
   ccr = escorc_n(wxcre0300,pxcre0300,1,1) ;;  ===> ccr(lat,lon)
  end if 

 ;;;;pattern correlation
 ;encorr    = pattern_cor(wncre0300, pncre0300, 1.0, 0)
 ;printVarSummary(encorr)

 ;if(igp.le.3)then
 ;   corr      = sprintf("%3.2f", avg(encorr)) ;+" ~F34~1~N~~F~ " + sprintf("%5.0e",stddev(encorr))  
 ; else
 ;   corr      = sprintf("%3.2f", avg(encorr)) +" ~F34~1~N~~F~ " + sprintf("%5.0e",stddev(encorr)) 
 ; end if 

 ; ;;;calculate the RMSE between observations and simulations;;;
 ; if(igp.le.3)then
 ;   ermse     = wgt_arearmse(wncre0300,pncre0300, 1.0, 1.0, 0)
 ;   rmse      = sprintf("%3.2f",avg(ermse)) ;+ " ~F34~1~N~~F~ " + sprintf("%5.0e",stddev(ermse))
 ; else
 ;   ermse     = wgt_arearmse(wncre0300,pncre0300, 1.0, 1.0, 0)
 ;   rmse      = sprintf("%3.2f",avg(ermse))+ " ~F34~1~N~~F~ " + sprintf("%5.0e",stddev(ermse))
 ; end if 

  ;;;ensemble mean;;;;;;;
  if(igp.le.3)then
    wncreplt   = wncre0300
    pncreplt   = pncre0300
    crrplt     = ccr
  else
    wncreplt   = dim_avg_n_Wrap(wncre0300,0)
    pncreplt   = dim_avg_n_Wrap(pncre0300,0)
    crrplt     = dim_avg_n_Wrap(ccr,0)
  end if 

  ;wncreplt&time = Ptimes
  ;pncreplt&time = Ptimes
  ;printVarSummary(wncreplt)
  printVarSummary(crrplt)

  delete([/wxcre0300,pxcre0300,wncre0300,pncre0300,Filnam1,File1,ccr/]) ;encorr,ermse,ccr/])

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

    res@lbLabelBarOn            = True      ; Will turn on in panel later
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

    leftstr                  = "" ;"Surface Temperature ("+ts@units+")"
    res@gsnLeftString        = "" ; leftstr ;var_name0    ; long_name is too long!
    res@gsnRightString       = "" ;" ("+Varunt+")";""
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
    plot(igp) = gsn_csm_map(wks1,mpres)

    res2=res
    res2@gsnAddCyclic                   = True
    ;res2@cnLevelSelectionMode          = "ManualLevels"
    ;res2@cnMinLevelValF                = mnmxint(0)
    ;res2@cnMaxLevelValF                = mnmxint(1)
    ;res2@cnLevelSpacingF               = mnmxint(2)
     res2@cnLevelSelectionMode           := "ExplicitLevels"
     res2@cnLevels                       := fspan(0,1,11) ;diffgrp1
     res2@cnFillPalette                  := "precip3_16lev" ;dcname
 ;    res2@lbBoxSeparatorLinesOn           = True
   ;res2@cnFillColors                   = orgcolors
    res2@lbBoxLinesOn                   = True
   ;res2@lbBoxSeparatorLinesOn          = False
   ;res2@lbLabelStride                  = 15
    res2@gsnAddCyclic                   = True
    res2@tiMainString                   = Groups(igp)
    res2@gsnLeftString                  = Varstr + "  ("+ Varunt + ")"
    res2@gsnLeftStringOrthogonalPosF    = 0.02
   ;res2@gsnLeftStringParallelPosF      = 0.05
;    if (plotrdif)then
;      res2@gsnLeftString                = Varstr + "  (%)"
;      res2@gsnRightString               = "Global mean: " + mean2+"; "+ "RMSE: "+ rmse2
;    else
;      res2@gsnLeftString                = Varstr + "  ("+ Varunt + ")"
;      res2@gsnRightString               = "Global mean: " + mean2+"; "+ "RMSE: "+ rmse2
;    end if
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

    overlay(plot(igp),plot_rgd1)
    draw(plot(igp))
    frame(wks1)
 end do ; end of igp loop

;---Draw both plots in a panel
    pnres                         = True
    pnres@gsnMaximize             = False
    pnres@gsnPanelMainString      = "";"Hovmoller diagrams of "+Varstr+" over " + Figstr 
    pnres@gsnPanelMainFontColor   = "Black"
    pnres@gsnPanelMainFontHeightF = 0.012
    pnres@gsnPanelLabelBar        = True
    pnres@lbOrientation           = "vertical"        ; vertical label bar
    pnres@pmLabelBarHeightF       = 0.21
    pnres@pmLabelBarWidthF        = 0.04
    pnres@lbLabelFontHeightF      = 0.006               ; make labels smaller
   ;pnres@pmLabelBarParallelPosF  = -0.005
   ;pnres@pmLabelBarOrthogonalPosF= 0.005
    pnres@lbTitleString           = Varstr+ " ("+Varunt+")"
    pnres@lbTitlePosition         = "Right"                           ; title location
    pnres@lbTitleDirection        = "Across"                          ; letter angle
    pnres@lbTitleAngleF           = 90.                               ; title angle
    pnres@lbTitleFontHeightF      = 0.006                              ; font height
   ;pnres@gsnPanelBottom          = 0.05
    pnres@gsnPanelYWhiteSpacePercent = 4
   ;pnres@gsnPanelXF = (/0.05,0.17,0.29,0.41,0.53,0.65/)    ; Adjust rightmost plots
    pnres@gsnPanelXF = (/0.05,0.17,0.29,0.41/)
    ;plot1 = new(8,graphic)
    ;plot1(0:3) = plot(0:3)
    ;plot1(5:7) = plot(4:6)
    gsn_panel(wks1,(/plot(1:)/),(/1,ngrps-1/),pnres)
   delete([/pnres/])

 end do ; end of var loop

end

