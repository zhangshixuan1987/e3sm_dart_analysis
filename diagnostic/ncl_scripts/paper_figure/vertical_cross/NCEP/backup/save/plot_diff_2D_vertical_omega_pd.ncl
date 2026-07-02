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

  nudge      = False
  nudge      = False
  if(nudge)then
    ModelOutRoot = "/global/cscratch1/sd/zhan391/climate_analysis/ncl_sythentical_compare/data/e3sm_ndg/"
  else
    ModelOutRoot = "/global/cscratch1/sd/zhan391/climate_analysis/ncl_sythentical_compare/data/e3sm_org/"
  end if
;;;;;;;;;;select the regions to calculate the rmse;;;;;;;;;;;;;
  Casdir       = (/"E3SMV1_dt1800", "E3SMV1_dt0300","E3SMV1_macmic36","E3SMV1_macmic01","E3SMV1_all300"/)
  Groups       = Casdir
  ngrps        = dimsizes(Groups)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  labels       = (/"V1_CNTL","V1_DT0300","V1_MACMIC36","V1_MACMIC01","V1_ALL0300"/)
  nlabls       = dimsizes(labels)
  sigr         = 0.05                        ; critical sig lvl for r
  iflag        = False

;;;;;;variables to be plotted;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  Varname      = (/"OMEGA"/)
  Varstr       = ("Pressure Velocity")
  Varunt        = "Omega (hPa day~S~-1~N~)"
  P0mb         = 1000.                        ; reference pressure [mb]
  pnew         = (/100,150,200,250,300,400,500,600,700,850,925,1000/)
  nvars        = dimsizes(Varname)  
  Plttim       = (/"ANN"/)
  nptim        = dimsizes(Plttim)

  if(nudge)then
    plotFileLabel = Varname+"_zonal_vert"+"_PD_nudg"
  else
    plotFileLabel = Varname+"_zonal_vert"+"_PD_orig"
  end if

;;;;;;;begin to work with the simulations;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  if(nudge)then
   Filnam1 = systemfunc("ls -1 "+ModelOutRoot+Casdir(0)+"/"+"*"+Plttim(0)+"_climo*")
   Filnam2 = systemfunc("ls -1 "+ModelOutRoot+Casdir(1)+"/"+"*"+Plttim(0)+"_climo*")
   Filnam3 = systemfunc("ls -1 "+ModelOutRoot+Casdir(2)+"/"+"*"+Plttim(0)+"_climo*")
   Filnam4 = systemfunc("ls -1 "+ModelOutRoot+Casdir(3)+"/"+"*"+Plttim(0)+"_climo*")
   Filnam5 = systemfunc("ls -1 "+ModelOutRoot+Casdir(4)+"/"+"*"+Plttim(0)+"_climo*")
  else
   Filnam1 = systemfunc("ls -1 "+ModelOutRoot+Casdir(0)+"/"+"*"+Plttim(0)+"_means*")
   Filnam2 = systemfunc("ls -1 "+ModelOutRoot+Casdir(1)+"/"+"*"+Plttim(0)+"_means*")
   Filnam3 = systemfunc("ls -1 "+ModelOutRoot+Casdir(2)+"/"+"*"+Plttim(0)+"_means*")
   Filnam4 = systemfunc("ls -1 "+ModelOutRoot+Casdir(3)+"/"+"*"+Plttim(0)+"_means*")
   Filnam5 = systemfunc("ls -1 "+ModelOutRoot+Casdir(4)+"/"+"*"+Plttim(0)+"_means*")
  end if

  File1   = addfile(Filnam1,"r")
  File2   = addfile(Filnam2,"r")
  File3   = addfile(Filnam3,"r")
  File4   = addfile(Filnam4,"r")
  File5   = addfile(Filnam5,"r")

  ;print(File1)
  ;print(File2)
  lat     = File1->lat
  lon     = File1->lon
  lndfra  = File1->LANDFRAC(0,:,:)
  lndmsk  = lndfra
  lndmsk  = where(lndfra.gt.0.0,32766,1.0)
  lndmsk@_FillValue = 32766
  hyam    = File1->hyam
  hybm    = File1->hybm
;;;;read the control experiment;;;;;;;;;;;;
   x11     = vinth2p (File1->$Varname$,File1->hyam,File1->hybm,pnew,File1->PS,1,P0mb,1,False)
   x1      = dim_avg_Wrap(x11)
   v1cntl  = dim_avg_n_Wrap(x1,0)

   x11     = vinth2p (File1->$Varname$,File1->hyam,File1->hybm,pnew,File1->PS,1,P0mb,1,False)
   y11     = vinth2p (File2->$Varname$,File2->hyam,File2->hybm,pnew,File2->PS,1,P0mb,1,False)
   x1      = dim_avg_Wrap(x11)
   y1      = dim_avg_Wrap(y11)
   xt1     = x1(lev_p|:,lat|:,time|:)       ; reorder but do it only once [temporary]
   tt1     = y1(lev_p|:,lat|:,time|:)
   xa1     = dim_avg(xt1)              ; calculate means at each grid point
   ya1     = dim_avg(tt1)
   xv1     = dim_variance (xt1)         ; calculate variances
   yv1     = dim_variance (tt1)
   xeq1    = equiv_sample_size (xt1, sigr,0)
   yeq1    = equiv_sample_size (tt1, sigr,0)
   rad     = 4.*atan(1.)/180.    ;
   wgty    = cos(lat*rad)
   xN      = wgt_areaave (xeq1, 1.0, wgty,  0)    ; wgty could be gaussian weights
   yN      = wgt_areaave (yeq1, 1.0, wgty,  0)
   prb1    = ttest(xa1,xv1,xN, ya1,yv1,yN, iflag, False)
  ;y1@_FillValue=32766
   v1exp1  = dim_avg_n_Wrap(y1,0)
   v1mndf1 = v1exp1
   v1mndf1 = v1exp1-v1cntl
   if(.not.nudge)then
   v1mnts1 = v1mndf1
   v1mnts1 = where(prb1.le.sigr,v1mndf1,y1@_FillValue)
   end if
   delete([/x1,y1,xt1,tt1,xa1,ya1,xv1,yv1,xeq1,yeq1,xN,yN,wgty/])

   x11     = vinth2p (File1->$Varname$,File1->hyam,File1->hybm,pnew,File1->PS,1,P0mb,1,False)
   y11     = vinth2p (File3->$Varname$,File3->hyam,File3->hybm,pnew,File3->PS,1,P0mb,1,False)
   x1      = dim_avg_Wrap(x11)
   y1      = dim_avg_Wrap(y11)
   xt1     = x1(lev_p|:,lat|:,time|:)       ; reorder but do it only once [temporary]
   tt1     = y1(lev_p|:,lat|:,time|:)
   xa1     = dim_avg(xt1)              ; calculate means at each grid point
   ya1     = dim_avg(tt1)
   xv1     = dim_variance (xt1)         ; calculate variances
   yv1     = dim_variance (tt1)
   xeq1    = equiv_sample_size (xt1, sigr,0)
   yeq1    = equiv_sample_size (tt1, sigr,0)
   rad     = 4.*atan(1.)/180.    ;
   wgty    = cos(lat*rad)
   xN      = wgt_areaave (xeq1, 1.0, wgty,  0)    ; wgty could be gaussian weights
   yN      = wgt_areaave (yeq1, 1.0, wgty,  0)
   prb1    = ttest(xa1,xv1,xN, ya1,yv1,yN, iflag, False)
   ;y1@_FillValue=32766
   v1exp2  = dim_avg_n_Wrap(y1,0)
   v1mndf2 = v1exp2
   v1mndf2 = v1exp2-v1cntl
   if(.not.nudge)then
   v1mnts2 = v1mndf2
   v1mnts2 = where(prb1.le.sigr,v1mndf2,y1@_FillValue)
   end if
   delete([/x1,y1,xt1,tt1,xa1,ya1,xv1,yv1,xeq1,yeq1,xN,yN,wgty/])

   x11     = vinth2p (File1->$Varname$,File1->hyam,File1->hybm,pnew,File1->PS,1,P0mb,1,False)
   y11     = vinth2p (File4->$Varname$,File4->hyam,File4->hybm,pnew,File4->PS,1,P0mb,1,False)
   x1      = dim_avg_Wrap(x11)
   y1      = dim_avg_Wrap(y11)
   xt1     = x1(lev_p|:,lat|:,time|:)       ; reorder but do it only once [temporary]
   tt1     = y1(lev_p|:,lat|:,time|:)
   xa1     = dim_avg(xt1)              ; calculate means at each grid point
   ya1     = dim_avg(tt1)
   xv1     = dim_variance (xt1)         ; calculate variances
   yv1     = dim_variance (tt1)        
   xeq1    = equiv_sample_size (xt1, sigr,0)
   yeq1    = equiv_sample_size (tt1, sigr,0)
   rad     = 4.*atan(1.)/180.    ;      
   wgty    = cos(lat*rad)
   xN      = wgt_areaave (xeq1, 1.0, wgty,  0)    ; wgty could be gaussian weights
   yN      = wgt_areaave (yeq1, 1.0, wgty,  0)
   prb1    = ttest(xa1,xv1,xN, ya1,yv1,yN, iflag, False)
   ;y1@_FillValue=32766
   v1exp3  = dim_avg_n_Wrap(y1,0)
   v1mndf3 = v1exp3
   v1mndf3 = v1exp3-v1cntl
   if(.not.nudge)then
   v1mnts3 = v1mndf3
   v1mnts3 = where(prb1.le.sigr,v1mndf3,y1@_FillValue)
   end if
   delete([/x1,y1,xt1,tt1,xa1,ya1,xv1,yv1,xeq1,yeq1,xN,yN,wgty/])

   x11     = vinth2p (File1->$Varname$,File1->hyam,File1->hybm,pnew,File1->PS,1,P0mb,1,False)
   y11     = vinth2p (File5->$Varname$,File5->hyam,File5->hybm,pnew,File5->PS,1,P0mb,1,False)
   x1      = dim_avg_Wrap(x11)
   y1      = dim_avg_Wrap(y11)
   xt1     = x1(lev_p|:,lat|:,time|:)       ; reorder but do it only once [temporary]
   tt1     = y1(lev_p|:,lat|:,time|:)
   xa1     = dim_avg(xt1)              ; calculate means at each grid point
   ya1     = dim_avg(tt1)
   xv1     = dim_variance (xt1)         ; calculate variances
   yv1     = dim_variance (tt1)        
   xeq1    = equiv_sample_size (xt1, sigr,0)
   yeq1    = equiv_sample_size (tt1, sigr,0)
   rad     = 4.*atan(1.)/180.    ;      
   wgty    = cos(lat*rad)
   xN      = wgt_areaave (xeq1, 1.0, wgty,  0)    ; wgty could be gaussian weights
   yN      = wgt_areaave (yeq1, 1.0, wgty,  0)
   prb1    = ttest(xa1,xv1,xN, ya1,yv1,yN, iflag, False)
   ;y1@_FillValue=32766
   v1exp4  = dim_avg_n_Wrap(y1,0)
   v1mndf4 = v1exp4
   v1mndf4 = v1exp4-v1cntl
   if(.not.nudge)then
   v1mnts4 = v1mndf4
   v1mnts4 = where(prb1.le.sigr,v1mndf4,y1@_FillValue)
   end if
   delete([/x1,y1,xt1,tt1,xa1,ya1,xv1,yv1,xeq1,yeq1,xN,yN,wgty/])

   v1cntl!0 = "lev"
   v1cntl&lev = pnew
   v1cntl&lev@units = "hPa"
   v1cntl@_FillValue = 32766
   copy_VarCoords(v1cntl,v1exp1)
   copy_VarCoords(v1cntl,v1exp2)
   copy_VarCoords(v1cntl,v1exp3)
   copy_VarCoords(v1cntl,v1exp4)
   copy_VarCoords(v1cntl,v1mndf1)
   copy_VarCoords(v1cntl,v1mndf2)
   copy_VarCoords(v1cntl,v1mndf3)
   copy_VarCoords(v1cntl,v1mndf4)

   v1cntl   = v1cntl*3600.0*24.0/100.0
   v1exp1   = v1exp1*3600.0*24.0/100.0
   v1exp2   = v1exp2*3600.0*24.0/100.0
   v1exp3   = v1exp3*3600.0*24.0/100.0
   v1exp4   = v1exp4*3600.0*24.0/100.0
   v1mndf1  = v1mndf1*3600.0*24.0/100.0
   v1mndf2  = v1mndf2*3600.0*24.0/100.0
   v1mndf3  = v1mndf3*3600.0*24.0/100.0
   v1mndf4  = v1mndf4*3600.0*24.0/100.0
   if(.not.nudge)then
   copy_VarCoords(v1cntl,v1mnts1)
   copy_VarCoords(v1cntl,v1mnts2)
   copy_VarCoords(v1cntl,v1mnts3)
   copy_VarCoords(v1cntl,v1mnts4)
   v1mnts1  = v1mnts1*3600.0*24.0/100.0
   v1mnts2  = v1mnts2*3600.0*24.0/100.0
   v1mnts3  = v1mnts3*3600.0*24.0/100.0
   v1mnts4  = v1mnts4*3600.0*24.0/100.0
   end if 

;;;;;;;open a wks for plot;;;;;;;;;;;;;;;;;;;
  OUTDir  = "./"
  wtype = "png"
 ;wtype@wkPaperSize     = "A4"
 ;wtype@wkOrientation   = "landscape"    ;;pictures displayed along the length
  wks = gsn_open_wks(wtype,OUTDir+"fig_sensitivity_"+plotFileLabel)

  gsn_define_colormap(wks,"ncl_default")  ; use the BlWhRe colormap (instead of default colormap)
;----------------------------------------------------------------------
; Plotting section
;---Resources to share between both plots
  res                      = True              ; Plot modes desired.
  res@gsnDraw              = False
  res@gsnFrame             = False
  res@gsnAddCyclic         = False
  res@gsnMaximize            = True              ; Maximize plot

  stres                    = res
  cnres                    = res
  mpres                    = res
  vcres                    = res

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

  res@tiMainFontThicknessF  = 3.0
  res@tiMainFontHeightF     = 0.038
  res@tmYLLabelFontHeightF  = 0.035
  res@tmXBLabelFontHeightF  = 0.035
  res@lbLabelFontHeightF    = 0.035
  res@lbTitleFontHeightF    = 0.035                              ; font height
  res@tiXAxisFontHeightF    = 0.038
  res@tiYAxisFontHeightF    = 0.038
  res@gsnStringFontHeightF  = 0.035
  res@cnLineLabelFontHeightF= 0.028

  leftstr                  = "" ;"Surface Temperature ("+ts@units+")"
  res@gsnLeftString        = "" ; leftstr ;var_name0    ; long_name is too long!
  res@gsnRightString       = "" ;"("+Varunt+")";""
 ;res@tiMaingString        = "Annual Mean Response to Present-day climate"

  res@lbTitleString        = Varunt;Varstr+ "("+Varunt+")";
  res@lbTitlePosition      = "Right"                           ; title location
  res@lbTitleDirection     = "Across"                          ; letter angle
  res@lbTitleAngleF        = 90.                               ; title angle

 ;res@gsnMajorLatSpacing   = 45
 ;res@gsnMajorLonSpacing   = 90
 ;res@gsnMinorLatSpacing   = 15
 ;res@gsnMinorLonSpacing   = 10

  res@cnFillOn              = True              ; color plot desired
  res@cnLinesOn             = False             ; turn off contour lines
  res@cnLineLabelsOn        = False            ; turn off contour labels
  res@cnInfoLabelOn         = False
; res@cnFillMode            = "RasterFill"      ; turn raster on
  res@cnMissingValFillColor = "White"

  cmap = read_colormap_file("BlWhRe")
  dims = dimsizes(cmap)
  nx   = dims(0)/2
  cmap(nx-5:nx+5,:)= 0.0

;;;---Resources for plotting original data
  res1=res
  res1@cnFillPalette        = "amwg256"
  res1@cnLevelSelectionMode = "ExplicitLevels"  ; set explicit contour levels
  res1@cnLevels             = ispan(-16,16,4) ;(/0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0/)*10.0
; res1@tiMainString         = "ANN "+Varname+" (%)"
  res1@tiMainString         = "CNTL"
; plot_org1                 = gsn_csm_contour(wks,v1cntl,res1)
  plot_org1                 = gsn_csm_pres_hgt(wks,v1cntl,res1)

  res2=res
  res2@cnFillOn             = False              ; color plot desired
  res2@cnLinesOn            = True             ; turn off contour lines
  res2@cnLineColor          = "Black"
  res2@cnLineThicknessF     = 3.0
  res2@gsnContourZeroLineThicknessF = 3.
  res2@gsnContourNegLineDashPattern = 1
  res2@cnLevelSelectionMode = "ExplicitLevels"  ; set explicit contour levels
  res2@cnLevels             = (/-10,10/);ispan(-20,20,10) ;(/0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0/)*10.0
  res2@cnLineLabelsOn       = True             ; turn off contour labels
; plot_org2                 = gsn_contour(wks,v1cntl,res2)
  plot_org2                 = gsn_csm_pres_hgt(wks,v1cntl,res2)
  overlay(plot_org1,plot_org2)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  res3 = res
  gsn_define_colormap(wks, "amwg_blueyellowred") ; choose colormap
  res3@cnFillColors        = (/2,3,5,7,8,0,11,12,14,15,17/)
  res3@cnLevelSelectionMode= "ExplicitLevels"  ; set explicit contour levels
  res3@cnLevels            = (/-1.2,-0.8,-0.4,-0.2,-0.1,0.1,0.2,0.4,0.8,1.2/)
; res3@tiMainString        = "ANN "+Varname+" (%)"
  res3@tiMainString        = "DT0300 - CNTL"
; plot_rgd1                = gsn_contour(wks,v1mndf1,res3)
  plot_rgd1                = gsn_csm_pres_hgt(wks,v1mndf1,res3)
  res3@tiMainString        = "MACMIC36 - CNTL"
; plot_rgd2                = gsn_contour(wks,v1mndf2,res3)
  plot_rgd2                = gsn_csm_pres_hgt(wks,v1mndf2,res3)
  res3@tiMainString        = "MACMIC01 - CNTL"
; plot_rgd3                = gsn_contour(wks,v1mndf3,res3)
  plot_rgd3                = gsn_csm_pres_hgt(wks,v1mndf3,res3)
  res3@tiMainString        = "ALL0300 - CNTL"
; plot_rgd4                = gsn_contour(wks,v1mndf4,res3)
  plot_rgd4                = gsn_csm_pres_hgt(wks,v1mndf4,res3)

  res4=res
  res4@cnFillOn             = False              ; color plot desired
  res4@cnLinesOn            = True             ; turn off contour lines
  res4@cnLineLabelsOn       = True             ; turn off contour labels
  res4@cnLineThicknessF     = 3.0
  res4@cnLineColor          = "Black"
  res4@gsnContourZeroLineThicknessF = 5.
  res4@gsnContourNegLineDashPattern = 1
  res4@cnLevelSelectionMode = "ExplicitLevels"  ; set explicit contour levels
  res4@cnLevels             = (/0/);(/-1.2,-0.6,-0.3,-0.1,-0.01,0.01,0.1,0.3,0.6,1.2/)
  res4@tiMainString         = "DT0300 - CNTL"
; plot_rgd11                = gsn_contour(wks,v1mndf1,res4)
  plot_rgd11                = gsn_csm_pres_hgt(wks,v1mndf1,res4)
  res4@tiMainString         = "MACMIC36 - CNTL"
; plot_rgd21                = gsn_contour(wks,v1mndf2,res4)
  plot_rgd21                = gsn_csm_pres_hgt(wks,v1mndf2,res4)
  res4@tiMainString         = "MACMIC01 - CNTL"
; plot_rgd31                = gsn_contour(wks,v1mndf3,res4)
  plot_rgd31                = gsn_csm_pres_hgt(wks,v1mndf3,res4)
  res4@tiMainString         = "ALL0300 - CNTL"
; plot_rgd41                = gsn_contour(wks,v1mndf4,res4)
  plot_rgd41                = gsn_csm_pres_hgt(wks,v1mndf4,res4)

  overlay(plot_rgd1,plot_rgd11)
  overlay(plot_rgd2,plot_rgd21)
  overlay(plot_rgd3,plot_rgd31)
  overlay(plot_rgd4,plot_rgd41)

  if(.not.nudge)then

;---Add test shading to plot
  print(min(v1mnts1)+ " "+max(v1mnts1))
  res5=res
  res5@cnFillOn             = True             ; color plot desired
  res5@lbLabelBarOn         = False             ; turn off contour labels
  res5@cnLinesOn            = False             ; turn off contour lines
  res5@cnLineLabelsOn       = False             ; turn off contour labels
  res5@cnMissingValFillColor = "Transparent"
  res5@cnMonoFillColor      = True             ; default color is fground [black]
  res5@cnMonoFillPattern    = False             ; want multiple patterns 
  res5@cnMonoFillScale      = False              ; want patterns w/ diff densities 
  res5@cnFillPatterns       = 11
  res5@cnFillScaleF         = 2.0
  res5@cnFillDotSizeF       = 0.005            ; increase dot size of contours
  res5@tiMainString         = "DT0300 - CNTL"
; plot_rgd12                = gsn_contour(wks,v1mnts1,res5)
  plot_rgd12                = gsn_csm_pres_hgt(wks,v1mnts1,res5)
  res5@tiMainString         = "MACMIC36 - CNTL"
; plot_rgd22                = gsn_contour(wks,v1mnts2,res5)
  plot_rgd22                = gsn_csm_pres_hgt(wks,v1mnts2,res5)
  res5@tiMainString         = "MACMIC01 - CNTL"
; plot_rgd32                = gsn_contour(wks,v1mnts3,res5)
  plot_rgd32                = gsn_csm_pres_hgt(wks,v1mnts3,res5)
  res5@tiMainString         = "ALL0300 - CNTL"
; plot_rgd42                = gsn_contour(wks,v1mnts4,res5)
  plot_rgd42                = gsn_csm_pres_hgt(wks,v1mnts4,res5)

  overlay(plot_rgd1,plot_rgd12)
  overlay(plot_rgd2,plot_rgd22)
  overlay(plot_rgd3,plot_rgd32)
  overlay(plot_rgd4,plot_rgd42)
  end if 
;---Draw both plots in a panel
  pnres                    = True
  pnres@gsnMaximize        = True
  pnres@gsnPanelLabelBar   = True
  pnres@gsnPanelMainString = Varstr; "Surface Temperature ("+ts@units+")"
  pnres@gsnPanelLabelBar   = False                ; add common colorbar
  pnres@gsnPanelMainFontColor   = "Black"
  pnres@gsnPanelMainFontHeightF = 0.030
; pnres@lbLabelFontHeightF      = 0.018               ; make labels smaller
; pnres@pmLabelBarParallelPosF  = 0.026
; pnres@pmLabelBarOrthogonalPosF= 0.015
; pnres@pmLabelBarHeightF       = 0.1
; pnres@pmLabelBarWidthF        = 0.57
;  pnres@gsnPanelBottom          = 0.05
  pnres@gsnPanelYWhiteSpacePercent = 2
; gsn_panel(wks,(/plot_rgd1, plot_rgd2, plot_rgd3, plot_rgd2, plot_rgd3,plot_rgd4/),(/5,1/),pnres)
  gsn_panel(wks,(/plot_rgd1, plot_rgd2, plot_rgd3/),(/3,1/),pnres)

end
