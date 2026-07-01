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
  xstring      = "Days since 01 January 2011"

;;;;;;;;;;select the regions to calculate the rmse;;;;;;;;;;;;;
  trmmdir      = "/pic/projects/E3SM_DA/zhan391/e3sm_dart/acme_init/Observations/TRMM/"+year+"/"+ymstr1+"/"
  olrdir       = "/pic/projects/E3SM_DA/zhan391/e3sm_dart/acme_init/Observations/NOAA_HIRS/"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  Casdir1      = (/"OBS","PD_Transpose-AMIP_Hind_d2","PD_EDAUVT_Hind_d2"/)
  Casdir1      = Casdir1 + "_"+ymstr1
  Groups       = (/"OBS","PD_Transpose-AMIP_Hind_d2","PD_EDAUVT_Hind_d2"/)
  ngrps        = dimsizes(Groups)
  Labels       = Groups
  OBSTR        = (/"TRMM", "NOAA-HIRS"/)

  labels       = (/"Observations", "Transpose-AMIP","DART DA"/)

  ;plot         = new(ngrps,graphic)

  Plttim       = (/"*","*ens*.cam.h0.*.nc","*ens*.cam.h0.*.nc","*ens*.cam.h0.*.nc","*ens*.cam.h0.*.nc","*ens*.cam.h0.*.nc","*ens*.cam.h0.*.nc","*ens*.cam.h0.*.nc","*ens*.cam.h0.*.nc"/)

 ;;;;;;variables to be plotted;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  VarList      = (/"PRECT","FLUT"/)
  VstList      = (/"Total precipitation","Outgoing longwave radiation (OLR)"/)
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

 do iv = 1,nvars-1, 1

  Varname = VarList(iv)
  Varunt  = UnitList(iv)
  Varstr  = VstList(iv)

  if(iv.eq.0)then
    miny = pcpminy
    maxy = pcpmaxy
  else
    miny = olrminy
    maxy = olrmaxy
  end if 

  plotFileLabel = Varname+"_monthly_evolution"
 ;;;;;;;open a wks for plot;;;;;;;;;;;;;;;;;;;
  OUTDir  = "./"
  wtype = "png"
  wtype@wkWidth = 2500
  wtype@wkHeight = 2500
  ;wtype@wkPaperSize     = "A4"
  ;wtype@wkOrientation   = "landscape"    ;;pictures displayed along the length
  ;wtype@wkOrientation   = "landscape"    ;;pictures displayed along the length
  wks1 = gsn_open_wks(wtype,OUTDir+"fig_day2_"+Subrgs(irg)+"_"+plotFileLabel)

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
  if(igp.le.1)then
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

  if(igp.le.1)then
    corr      = sprintf("%3.2f", avg(encorr)) ;+" ~F34~1~N~~F~ " + sprintf("%5.0e",stddev(encorr))  
  else
    corr      = sprintf("%3.2f", avg(encorr)) +" ~F34~1~N~~F~ " + sprintf("%5.0e",stddev(encorr)) 
  end if 

  ;;;calculate the RMSE between observations and simulations;;;

  if(igp.le.1)then
    ermse     = wgt_arearmse(wncre0300,pncre0300, 1.0, 1.0, 0)
    rmse      = sprintf("%3.2f",avg(ermse)) ;+ " ~F34~1~N~~F~ " + sprintf("%5.0e",stddev(ermse))
  else
    ermse     = wgt_arearmse(wncre0300,pncre0300, 1.0, 1.0, 0)
    rmse      = sprintf("%3.2f",avg(ermse))+ " ~F34~1~N~~F~ " + sprintf("%5.0e",stddev(ermse))
  end if 

  ;;;ensemble mean;;;;;;;
  if(igp.eq.1)then
    plotdat = new((/ngrps,dimsizes(Ptimes)/),typeof(wncre0300))
  end if 

  if(igp.le.1)then
    wncreplt   = dim_avg_n_Wrap(wncre0300,1)
    pncreplt   = dim_avg_n_Wrap(pncre0300,1)
  else
    wncreplt   = dim_avg_n_Wrap(dim_avg_n_Wrap(wncre0300,0),1)
    pncreplt   = dim_avg_n_Wrap(dim_avg_n_Wrap(pncre0300,0),1)
  end if 

  plotdat(0,:)   = pncreplt
  plotdat(igp,:) = wncreplt

  wncreplt&time = Ptimes
  pncreplt&time = Ptimes

  printVarSummary(Ptimes)
  printVarSummary(wncreplt)

  delete([/wxcre0300,pxcre0300,Filnam1,File1,encorr,ermse/])
  delete([/wncre0300,wncreplt, pncre0300,pncreplt,times/])
 end do ; end of igp loop

;----------------------------------------------------------------------
; Plotting section
;---Resources to share between both plots
  res          = True                   ; plot mods desired
  res@vpHeightF = 0.3
  res@vpWidthF =  0.8
  res@gsnDraw  = False
  res@gsnFrame = False

  FontHeight = 0.016
  res@gsnStringFontHeightF = FontHeight*1.0
  res@tmXBLabelFontHeightF = FontHeight
  res@tmYLLabelFontHeightF = FontHeight
  res@tmYRLabelFontHeightF = FontHeight
  res@tiMainFontHeightF    = FontHeight
  res@tiXAxisFontHeightF   = FontHeight
  res@tiYAxisFontHeightF   = FontHeight
  res@tiMainFontThicknessF  = 8.0
  res@tiYAxisFontThicknessF = 5.0
  res@tiXAxisFontThicknessF = 5.0

  res@tmXTOn  = False
  res@trXMinF               = 0  ;min(latrgd)
  res@trXMaxF               = 31 ;192 ;max(latrgd)
  res@tmXBMode              = "Explicit"
  res@tmXBValues            = ispan(res@trXMinF,res@trXMaxF,3)
  res@tmXBLabels            = "" + res@tmXBValues
  res@tmXBMinorValues       = ispan(res@trXMinF,res@trXMaxF,1)

  res@trYMinF               = miny(irg);min((/vavg1,vavg2/)) ;miny(iv)
  res@trYMaxF               = maxy(irg) ;max((/vavg1,vavg2/));maxy(iv)
 ;res@tmYLMode              = "Explicit"                ; explicit labels
 ;res@tmYLLabels            = ""+res@tmYLValues         ; make strings

  ;res@gsnXRefLine             = (/5.9/)      ; four X reference lines
  ;res@gsnXRefLineThicknesses  = 1.0
  ;res@gsnXRefLineDashPatterns = 5
  ;res@gsnXRefLineColors       = "Black"

;;;;;;;first figure for PD origional values;;;;;;;;;;;;;;;;;;;;
  res1                         = res
  res1@gsnLeftString           = Varstr ;""
  res1@gsnLeftStringFontColor  = "Black"
  res1@gsnRightString          = Figstr ;"(PD)"
  res1@gsnRightStringFontColor = "Black"
  res1@tiMainString            = "" ;mainstr
  res1@xyMarkLineModes         = linemod(:)
  res1@xyLineThicknesses       = lnthick(:)            ; make thicker
  res1@xyDashPatterns          = dashind(:)
  res1@xyMarkerSizes           = mkszf(:)*0.1
  res1@xyMarkerThicknesses     = mkthk
  res1@xyLineColors            = colors(:)
  res1@xyMarkers               = markers(:)
  res1@xyMarkerColors          = colors(:)
  res1@tiXAxisString           = xstring
  res1@tiYAxisString           = Varunt
  plot                         = gsn_csm_xy(wks1,Ptimes,plotdat,res1)

;Attach a legend
;;manual legend
   lgres                    = True
   lgres@lgItemType         = "MarkLines"
   lgres@lgLineLabelFontThicknessF= 1.0
 ; lgres@lgLineDashSegLenF  = 0.01
   lgres@lgBoxMinorExtentF  = 0.25
   lgres@lgBoxMajorExtentF  = 0.1
   lgres@lgMonoDashIndex    = False
   lgres@lgMonoLineThickness= False
   lgres@lgMonoMarkerThickness = False
   lgres@lgPerimOn          = True
  ;lgres@lgRightMarginF     = 0.5
  ;lgres@lgLeftMarginF      = 0.5
  ;lgres@lgTopMarginF       = 0.5
  ;lgres@lgBottomtMarginF   = 0.5

   lgres@lgPerimThicknessF  = 2.0

   lgres1 = lgres
   lgres1@vpWidthF           = 0.18           ; width of legend (NDC)
   lgres1@vpHeightF          = 0.10           ; height of legend (NDC)
   lgres1@lgLineColors       = colors(:) ;(/"Black","Black","Black"/)
   lgres1@lgDashIndexes      = dashind(:)
   lgres1@lgLineThicknesses  = lnthick(:)
   lgres1@lgMarkerColors     = colors(:)
   lgres1@lgMarkerIndexes    = markers(:)
   lgres1@lgMarkerThicknesses= mkthk(:)

   label1  = "  " +labels
   legend1 = gsn_create_legend (wks1,dimsizes(label1), label1,lgres1)

   amres                  = True
   amres@amJust           = "BottomRight"
   amres@amParallelPosF   =  0.40
   amres@amOrthogonalPosF =  0.48
   annoid1 = gsn_add_annotation(plot,legend1,amres)  ; add legend to the top figure

;---Draw both plots in a panel
    pnres                         = True
    pnres@gsnMaximize             = False
    pnres@gsnPanelMainString      = "" ;"Hovmoller diagrams of "+Varstr+" over " + Figstr 
    pnres@gsnPanelMainFontColor   = "Black"
    pnres@gsnPanelMainFontHeightF = 0.012
   ;pnres@gsnPanelBottom          = 0.05
    pnres@gsnPanelYWhiteSpacePercent = 4
   ;pnres@gsnPanelXF = (/0.05,0.17,0.29,0.41,0.53,0.65/)    ; Adjust rightmost plots
    pnres@gsnPanelXF = (/0.05,0.17,0.29,0.41/)
    gsn_panel(wks1,(/plot(:)/),(/1,1/),pnres)
   delete([/pnres,res,res1/])
 end do ; end of var loop

end do ; end of subreg loop

end

