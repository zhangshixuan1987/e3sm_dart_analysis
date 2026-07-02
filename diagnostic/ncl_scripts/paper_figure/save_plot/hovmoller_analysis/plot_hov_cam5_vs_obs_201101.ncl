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

;;;;;;;;;;select the regions to calculate the rmse;;;;;;;;;;;;;
  trmmdir      = "/pic/projects/E3SM_DA/zhan391/e3sm_dart/acme_init/Observations/TRMM/"+year+"/"+ymstr1+"/"
  olrdir       = "/pic/projects/E3SM_DA/zhan391/e3sm_dart/acme_init/Observations/NOAA_HIRS/"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  Casdir1      = (/"OBS","PD_NDG_ERA5UV","PD_NDG_ERA5UVT","PD_NDG_ERA5UVTQ","PD_EDAUVTQ_EN80"/)+"_"+ymstr1
  Groups       = (/"OBS","NDG_ERA5UV","NDG_ERA5UVT","NDG_ERA5UVTQ","DART_EDA_EN80"/)
  ngrps        = dimsizes(Groups)
  Labels       = (/"OBS","NDG_ERA5UV","NDG_ERA5UVT","NDG_ERA5UVTQ","DART_EDA_EN80"/)
  OBSTR        = (/"TRMM", "NOAA-HIRS"/)
  plot         = new(ngrps,graphic)
  Plttim       = (/"*","*ens*.cam.h0.*.nc","*ens*.cam.h0.*.nc","*ens*.cam.h0.*.nc","*ens*.cam.h0.*.nc"/)

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

 ;;;loop the regions and plot the PDF
 load "./sc_cloud_region.ncl"
 do irg = 0,nsubreg-1,1
  mpMinLatF = minlat(irg)
  mpMaxLatF = maxlat(irg)
  mpMinLonF = minlon(irg)
  mpMaxLonF = maxlon(irg)
  Figstr  = Subreg(irg) ;+ "["+mpMinLatF+"-"+mpMaxLatF;+mpMinLonF+"-"+mpMaxLonF +"]" ;PltNums(iv)

 do iv = 0,nvars-1, 1

  Varname = VarList(iv)
  Varunt  = UnitList(iv)
  Varstr  = VstList(iv)

  plotFileLabel = Varname+"_hovmoller"
 ;;;;;;;open a wks for plot;;;;;;;;;;;;;;;;;;;
  OUTDir  = "./"
  wtype = "png"
  wtype@wkWidth = 2500
  wtype@wkHeight = 2500
  ;wtype@wkPaperSize     = "A4"
  ;wtype@wkOrientation   = "landscape"    ;;pictures displayed along the length
  ;wtype@wkOrientation   = "landscape"    ;;pictures displayed along the length
  wks1 = gsn_open_wks(wtype,OUTDir+"fig_pdf_"+Subrgs(irg)+"_"+plotFileLabel)

  load "./var_share_colorbar.ncl"
 
 do igp = 1, ngrps-1,1
 
  ;;;;read the observations;;;;;;;;;;;;;; 
  if (Varname.eq."PRECT")then
   trmmdat0 = systemfunc("cd "+trmmdir+"/"+"; ls -1 "+Plttim(0))
   trmmdat  = trmmdat0(7:)
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
   obstim  = cd_convert( tmptim, "days since "+ymstr2+"-01 00:00")
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
    xwxcre0300 = File1[:]->PRECC
    xwxcre0300 = File1[:]->PRECC + File1[:]->PRECL
    xwxcre0300 = xwxcre0300*1000.0 *24.0 *3600.0 ;; mm/day
  else if(Varname.eq."NETCF") then
    xwxcre0300 = File1[:]->LWCF
    xwxcre0300 = File1[:]->LWCF + File1[:]->SWCF
  else
    xwxcre0300 = File1[:]->$Varname$
  end if
  end if

  dimy=dimsizes(xwxcre0300)

  if(igp.le.3)then

   wxcre0300 = xwxcre0300(::4,:,:)
   do j = 0, dimy(0)/4-1
      wxcre0300(j,:,:) = dim_avg_n(xwxcre0300(j*4:(j+1)*4-1,:,:),0)
   end do
   print(dimy(0)+ " "+dimy(0)/8)

  else

   wxcre0300 = xwxcre0300(:,::4,:,:)
   do j = 0, dimy(1)/4-1
      wxcre0300(:,j,:,:) = dim_avg_n(xwxcre0300(:,j*4:(j+1)*4-1,:,:),1)
   end do
   print(dimy(0)+ " "+dimy(0)/8)

  end if 

   printVarSummary(wxcre0300)
   delete([/dimy,xwxcre0300/])

   Ptimes    = cd_convert(times(::4), "days since 2011-01-01 00:00")
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
   
 ;;;pattern correlation
  encorr    = pattern_cor(wncre0300, pncre0300, 1.0, 0)
  printVarSummary(encorr)

  if(igp.le.3)then
    corr      = sprintf("%3.2f", avg(encorr)) ;+" ~F34~1~N~~F~ " + sprintf("%5.0e",stddev(encorr))  
  else
    corr      = sprintf("%3.2f", avg(encorr)) +" ~F34~1~N~~F~ " + sprintf("%5.0e",stddev(encorr)) 
  end if 

  ;;;calculate the RMSE between observations and simulations;;;
  if(igp.le.3)then
    ermse     = wgt_arearmse(wncre0300,pncre0300, 1.0, 1.0, 0)
    rmse      = sprintf("%3.2f",avg(ermse)) ;+ " ~F34~1~N~~F~ " + sprintf("%5.0e",stddev(ermse))
  else
    ermse     = wgt_arearmse(wncre0300,pncre0300, 1.0, 1.0, 0)
    rmse      = sprintf("%3.2f",avg(ermse))+ " ~F34~1~N~~F~ " + sprintf("%5.0e",stddev(ermse))
  end if 

  ;;;ensemble mean;;;;;;;
  if(igp.le.3)then
    wncreplt   = wncre0300
    pncreplt   = pncre0300
  else
    wncreplt   = dim_avg_n_Wrap(wncre0300,0)
    pncreplt   = dim_avg_n_Wrap(pncre0300,0)
  end if 

  wncreplt&time = Ptimes
  pncreplt&time = Ptimes

  printVarSummary(wncreplt)
  delete([/wxcre0300,pxcre0300,Filnam1,File1,encorr,ermse/])
;----------------------------------------------------------------------
; Plotting section
;---Resources to share between both plots
  res                           = True                   ; plot mods desired
  res@vpHeightF                 = vpHeightF
  res@vpWidthF                  =  vpWidthF
 ;res@vpXF                      = 0.02
  res@gsnDraw                   = False
  res@gsnFrame                  = False
  res@gsnStringFontHeightF      = FontHeight
  res@gsnRightStringFontHeightF = FontHeight
  res@gsnLeftStringFontHeightF  = FontHeight
  res@tmXBLabelFontHeightF      = FontHeight
  res@tmYLLabelFontHeightF      = FontHeight
  res@tmYRLabelFontHeightF      = FontHeight
  res@tiMainFontHeightF         = FontHeight*1.2
  res@tiXAxisFontHeightF        = FontHeight
  res@tiYAxisFontHeightF        = FontHeight

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
 ;res@lbTitleFontHeightF      = 0.022       

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
  res@tmYLMajorThicknessF       = 2.0
  res@tmYLMinorLengthF          = 0.01
  res@tmYLMinorOutwardLengthF   = 0.01
  res@tmYLMinorPerMajor         = 4
  res@tmYLMinorThicknessF       = 2.0
  res@tmYLLabelFontThicknessF   = 2.0
  ;res@tmYLMode         = "Manual"
  ;res@tmYLTickSpacingF = 2
  ;res@tmYLFormat       = "f"
  ;res@tmYLTickSpacingF = yint
  ;res@trYMaxF          = ymax
  ;res@trYMinF          = ymin
  res@trYMinF           = min(Ptimes)
  res@trYMaxF           = max(Ptimes)
  res@tmYLValues        = Ptimes(::3)
  res@tmYLLabels        = datestr(::3)
  res@tmYLMinorValues   = Ptimes

  res@tmXBMode                  = "Explicit"
  res@tmXBMinorOn               = True
  res@tmXBMajorLengthF          = 0.015
  res@tmXBMajorOutwardLengthF   = 0.015
  res@tmXBMajorThicknessF       = 2.0
  res@tmXBMinorLengthF          = 0.01
  res@tmXBMinorOutwardLengthF   = 0.01
  res@tmXBMinorPerMajor         = 4
  res@tmXBMinorThicknessF       = 2.0
  res@tmXBLabelFontHeightF      = FontHeight
  res@tmXBLabelFontThicknessF   = 2.0
  res@tmXBLabelDeltaF           = -0.6
  ;res@tmXBMode          = "Manual"
  ;res@tmXBFormat        = "f"
  ;res@tmXBTickSpacingF  = xint
  ;res@trXMaxF           = xmax
  ;res@trXMinF           = xmin
  res@gsnMajorLonSpacing = 60.
  res@gsnMinorLonSpacing = res@gsnMajorLonSpacing
  res@trXMinF            = wncreplt&lon(0)
  res@trXMaxF            = wncreplt&lon(dimsizes(wncreplt&lon)-1)
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

; plotting
  ;res@gsnYRefLine            = (/-100.0/)            ; create a reference line
  ;res@gsnYRefLineDashPattern = 0
  ;res@gsnYRefLineColor       = "Grey";"Black"
  ;res@gsnYRefLineThicknessF  = 1.0

  res@tmYLLabelsOn           = False
  res@tmYLOn                 = False

  if(igp.le.3)then
   res0=res
   res0@tmYLLabelsOn         = True
   res0@tmYLOn               = True
   res0@gsnLeftString        = "" ;
   res0@gsnRightString       = "" ;Groups(igp)
   res0@tiMainString         = Obname ;+ " (" +Figstr+")"
   res0@cnFillOn             = True               ; turn on color fill
   ;res0@cnFillPalette        = "WhiteBlueGreenYellowRed" ;"WhBlGrYeRe"
   ;res0@cnLevelSelectionMode = "ManualLevels"     ; manual contour levels
   ;res0@cnMinLevelValF       = ymin1
   ;res0@cnMaxLevelValF       = ymax1
   ;res0@cnLevelSpacingF      = yint1                 ; contour level spacing
   res0@cnLevelSelectionMode = "ExplicitLevels"
   res0@cnLevels            := ylevs
   res0@cnFillColors        := colorgroup1
   res0@cnLinesOn                      = True ;plot_contour
   res0@cnLineLabelsOn                 = False
   res0@cnInfoLabelOn                  = False
   res0@cnLineLabelDensityF            = 2.0
   res0@cnLineLabelFontHeightF         = 0.018
   res0@cnLineLabelBackgroundColor     = -1
   res0@gsnContourLineThicknessesScale = 1.0
   res0@cnLineThicknessF               = 0.2
   res0@cnLineColor                    = "Black"
   res0@gsnContourZeroLineThicknessF   = 1.
   res0@gsnContourNegLineDashPattern   = 2
   print(min(pncreplt)+ " "+max(pncreplt))
   print(min(wncreplt)+ " "+max(wncreplt))
   printVarSummary(pncreplt)
   plot(0)  = gsn_csm_hov(wks1,pncreplt,res0)
  end if 

  res1=res
  res1@gsnLeftString        = "Corr. coef: "+corr +"~C~" + "RMSE: "+rmse ;+ " ("+Varname+")"
  res1@gsnRightString       = "" ;Groups(igp)
  res1@tiMainString         = Groups(igp) ;+ " (" +Figstr+")"
  res1@cnFillOn             = True               ; turn on color fill
  ;res1@cnFillPalette        = "WhiteBlueGreenYellowRed" ;"WhBlGrYeRe"
  ;res1@cnLevelSelectionMode = "ManualLevels"     ; manual contour levels
  ;res1@cnMinLevelValF       = ymin1
  ;res1@cnMaxLevelValF       = ymax1
  ;res1@cnLevelSpacingF      = yint1                 ; contour level spacing
  res1@cnLevelSelectionMode  = "ExplicitLevels"
  res1@cnLevels             := ylevs
  res1@cnFillColors         := colorgroup1
  res1@cnLinesOn                      = True ;plot_contour
  res1@cnLineLabelsOn                 = False
  res1@cnInfoLabelOn                  = False
  res1@cnLineLabelDensityF            = 2.0
  res1@cnLineLabelFontHeightF         = 0.018
  res1@cnLineLabelBackgroundColor     = -1
  res1@gsnContourLineThicknessesScale = 1.0
  res1@cnLineThicknessF               = 0.2
  res1@cnLineColor                    = "Black"
  res1@gsnContourZeroLineThicknessF   = 1.
  res1@gsnContourNegLineDashPattern   = 2
  plot(igp)  = gsn_csm_hov(wks1,wncreplt,res1)

 delete([/wncre0300,wncreplt, pncre0300,pncreplt,times/])
 end do ; end of igp loop

;---Draw both plots in a panel
    pnres                         = True
    pnres@gsnMaximize             = False
    pnres@gsnPanelMainString      = "Hovmoller diagrams of "+Varstr+" over " + Figstr 
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
    pnres@gsnPanelXF = (/0.05,0.20,0.35,0.50,0.65/)    ; Adjust rightmost plots
    gsn_panel(wks1,(/plot(:)/),(/1,ngrps/),pnres)
   delete([/pnres/])

 end do ; end of var loop

end do ; end of subreg loop

end

