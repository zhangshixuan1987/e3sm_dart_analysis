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
     ModelOutRoot = "./E3SMV1_SIMULATION/"
  else
     ModelOutRoot = "/pic/projects/uq_climate/zhan391/climate_analysis/post_process_e3smv1/regrid_combine_fnl/"
  end if

;;;;;;;;;weight files for ESMF regrid function;;;;;
  wgt_dir  = "./"
  wgt_file = wgt_dir+"SE_NE30_to_FV_192x288.bilinear.nc"

;;;;;;;;;;select the regions to calculate the rmse;;;;;;;;;;;;;
  Regions      = (/"Global"/)
  nregs        = dimsizes(Regions)

;;;;;;;;;;select the regions to calculate the rmse;;;;;;;;;;;;;
  Casdir       = (/"FC5AV1C-L_initgen1800","FC5AV1C-L_initgen","FC5AV1C-L_initgen_macmic36","FC5AV1C-L_initgen_all300"/)
  Groups       = (/"CNTL",  "DT/6 ",  "StCld",  "StCld ~S~~F34~>~N~~F~"/)
  ngrps        = dimsizes(Groups)
  plot         = new(ngrps,graphic)

;;;;;;variables to be plotted;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  Varname      = (/"CLOUD"/) ;,"CLDTOT","TGCLDIWP","CLDTOT","TGCLDLWP"/)
  nvars        = dimsizes(Varname)
  Varstr       = ("Cloud fraction (CLOUD)")
  Varunt       = ("fraction")
  nvars        = dimsizes(Varname)
  Plttim       = (/"ANN"/)
  nptim        = dimsizes(Plttim)
  plotFileLabel = Varname+"_PD"
  P0mb         = 1000.                        ; reference pressure [mb]
  pnew         = (/100,150,200,250,300,400,500,600,700,850,925,1000/)
  pnew@units   = "hPa"
  pnew!0       = "lev"
  pnew&lev     = pnew

  plotcntl   = True
  plotcntl   = False
  plot_ttest = True
 ;plot_ttest = False
  plot_ttest = True
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

  diffgrp1    = (/-0.08,-0.04,-0.02,-0.01,-0.001,0.001,0.01,0.02,0.04,0.08/)
  diffgrp2    = (/-30,-20,-10,-5,-1,1,5,10,20,30/)
  ndiff       = dimsizes(diffgrp1)

do igp = 1,ngrps-1,1

  refcase = Casdir (0)
  tescase = Casdir (igp)

;;;;;;;begin to work with the simulations;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  Filnam0 = systemfunc("cd "+ModelOutRoot+refcase+"/"+"; ls *"+Plttim(0)+"_mean*")
  File0   = addfile(ModelOutRoot+refcase+"/"+Filnam0,"r")
  Filnam1 = systemfunc("cd "+ModelOutRoot+tescase+"/"+"; ls *"+Plttim(0)+"_mean*")
  File1   = addfile(ModelOutRoot+tescase+"/"+Filnam1,"r")
  print(Filnam0)
  print(Filnam1)

  lat       = File0->lat
  lon       = File0->lon
  lev       = File0->lev
  x11       = vinth2p(File0->$Varname$,File0->hyam,File0->hybm,pnew,File0->PS,1,P0mb,1,False)
  y11       = vinth2p(File1->$Varname$,File1->hyam,File1->hybm,pnew,File1->PS,1,P0mb,1,False)
  printVarSummary(x11)
  pncre0300 = dim_avg_n_Wrap(dim_avg_n_Wrap(x11,0),2)
  wncre0300 = dim_avg_n_Wrap(dim_avg_n_Wrap(y11,0),2)
  pncre0300 = pncre0300
  wncre0300 = wncre0300

  wncredf1  = wncre0300
  wncredf1  = wncre0300 - pncre0300
  wncredf2  = wncre0300
  mskxx     = pncre0300
  mskxx     = where(pncre0300.ge.0.05,pncre0300,32766)
  mskxx@_FillValue = 32766
  wncredf2  = (wncre0300 - mskxx)*100/mskxx
  wncredf2  = where(ismissing(wncredf2),0.0,wncredf2)

  ;rad     = 4.*atan(1.)/180.    ;
  ;cost    = cos(lat*rad)       ; cosine weights
  ;mean1x  = wgt_areaave(pncre0300,cost,1.0,0)
  ;mean2x  = wgt_areaave(wncredf1,cost,1.0,0)
  ;mean3x  = wgt_areaave(wncredf2,cost,1.0,0)
  ;mean1   = sprintf("%5.2f", mean1x)
  ;mean2   = sprintf("%5.2f", mean2x)
  ;mean3   = sprintf("%5.2f", mean3x) ;+ "%"

  rad  = 4.*atan(1.)/180.    ;
  wgty = cos(lat*rad)
  sigr = 0.05
  x1   = dim_avg_Wrap(x11)
  y1   = dim_avg_Wrap(y11)
  xt1  = x1(lev|:,lat|:,time|:)       ; reorder but do it only once [temporary]
  tt1  = y1(lev|:,lat|:,time|:)
  xa1  = dim_avg(xt1)              ; calculate means at each grid point
  ya1  = dim_avg(tt1)
  xv1  = dim_variance (xt1)         ; calculate variances
  yv1  = dim_variance (tt1)
  xeq1 = equiv_sample_size (xt1, sigr,0)
  yeq1 = equiv_sample_size (tt1, sigr,0)
  xN   = wgt_areaave (xeq1, 1.0, wgty,  0)    ; wgty could be gaussian weights
  yN   = wgt_areaave (yeq1, 1.0, wgty,  0)
  iflag   = False                        ; population variance similar
  prob    = ttest(xa1,xv1,xN, ya1,yv1,yN, iflag, False)
  v1mnts1 = wncredf1
  v1mnts1 = where(prob.le.sigr,wncredf1, 32766)
  v1mnts1@_FillValue = 32766
  delete([/x1,y1,xt1,tt1,xa1,ya1,xv1,yv1,xeq1,yeq1,xN,yN,wgty,prob/])

  labels  = (/ "(b1) "+"~F33~D~N~~F~"+ "f  "+ "("+Groups(0)+")","(b"+igp+") "+"~F33~D~N~~F~"+ "f  "+"("+Groups(igp)+ " - " + Groups(0)+")"/)
              ;(/Varstr ,"~F33~D~N~~F~"+ "RH","~F33~D~N~~F~"+ "RH"/)
             ;(/ "(b1)  " + Varname +" ("+Groups(0)+")","(b2)  "+Varname + " ("+Groups(igp)+ " - " + Groups(0)+")"/)
  nlabls       = dimsizes(labels)

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


  res@lbLabelBarOn            = False;True      ; Will turn on in panel later
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
    res1@cnLevels             = (/0.05,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1.0/) ;fspan(10,90,81)
   ;res1@cnLevels             = (/5,10,15,20,25,30,40,50,60,70,80,90/) ;fspan(10,90,81)
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
    ;plot_org1  = gsn_csm_contour(wks1,pncre0300,res1)
    plot_org1  = gsn_csm_pres_hgt(wks1,pncre0300,res1)
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
    res2@gsnLeftString               = labels(1)
   ;res2@gsnLeftStringOrthogonalPosF = 0.04
   ;res2@gsnLeftStringParallelPosF   = 0.2 
    res2@gsnRightString              = "";Varname ;Varunt
 
   ;res2@lbTitleString                  = Varunt 

    if(igp.gt.1)then
    res2@tmXTOn                = False
   ;res2@tmYLOn                = False
    res2@tmYLLabelsOn          = False
    res2@tiYAxisString         = "" 
    end if 

   ;plot_rgd1                  = gsn_csm_contour(wks1,wncredf1,res2)  
    plot_rgd1                  = gsn_csm_pres_hgt(wks1,wncredf1,res2)
   ;overlay(mpid2,plot_rgd1)

    res2@cnFillColors                = colorgroup1
    res2@cnLevels                    = diffgrp1
    res2@tiMainString                = "";"PD300 - CNTL"
    res2@gsnLeftString               = "" ;labels(2)
    res2@gsnLeftStringOrthogonalPosF = 0.04
   ;res2@gsnLeftStringParallelPosF   = 0.2
    res2@gsnRightString              = "" ;Varname; Varunt
    ;res2@lbTitleString                  = "%" 
    plot_rgd2                  = gsn_csm_pres_hgt(wks1,wncredf2,res2) 
   ;overlay(mpid3,plot_rgd2)

;---Add test shading to plot

    if(plot_ttest)then
    res3=res
    res3@cnFillOn              = True     ; color plot desired
    res3@lbLabelBarOn          = False    ; turn off contour labels
    res3@cnLinesOn             = False    ; turn off contour lines
    res3@cnLineLabelsOn        = False    ; turn off contour labels
    res3@cnMissingValFillColor = -1
    res3@cnMonoFillColor       = True     ; default color is fground [black]
    res3@cnMonoFillPattern     = True     ; want multiple patterns
    res3@cnMonoFillScale       = True     ; want patterns w/ diff densities
    res3@cnFillColor           = "Grey28";"Grey";"Black"
    res3@cnFillPattern         = 11 ;17 ;6 ;17;11
    res3@cnFillScaleF          = 0.5
    res3@cnFillDotSizeF        = 0.002    ; increase dot size of contours
    res3@tiMainString          = "" ;label
    res3@cnInfoLabelOn         = False
    str=unique_string("tmp1")
   ;wrf_smooth_2d(v1mnts1,3)
    plot_rgd1@str                = gsn_csm_pres_hgt(wks1,v1mnts1,res3) ;gsn_csm_contour(wks1,v1mnts1,res3)
    plot_rgd2@str                = gsn_csm_pres_hgt(wks1,v1mnts1,res3) ;gsn_csm_contour(wks1,v1mnts1,res3)
    overlay(plot_rgd1,plot_rgd1@str)
    overlay(plot_rgd2,plot_rgd2@str)
    delete([/res3/])
    end if
    delete([/res/])

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
    
  plot(igp) = plot_rgd1

end do ; end of igp loop

;---Draw both plots in a panel
    pnres                         = True
    pnres@gsnMaximize             = True
    pnres@gsnPanelLabelBar        = True
    pnres@gsnPanelMainString      = "";Varstr; "Surface Temperature ("+ts@units+")"
    pnres@gsnPanelMainFontColor   = "Black"
    pnres@gsnPanelMainFontHeightF = 0.030
    pnres@lbLabelFontHeightF      = .01            ; default is HUGE
    pnres@lbPerimOn               = False             ; default has box
    pnres@lbOrientation           = "vertical"        ; vertical label bar 
    pnres@lbTitleString           = "("+Varunt+")" ;"~F33~D~N~~F~"+ "CLOUD"+" ("+Varunt+")"
    pnres@lbTitlePosition         = "Right" 
    pnres@lbTitleDirection        = "Across" 
    pnres@lbTitleAngleF           = 90 
    pnres@lbTitleFontHeightF      = 0.01
    pnres@pmLabelBarHeightF       = 0.22
    pnres@pmLabelBarWidthF        = 0.06
    pnres@pmLabelBarParallelPosF  = -0.005
;   pnres@pmLabelBarOrthogonalPosF= 0.15
    pnres@gsnPanelYWhiteSpacePercent = 2
    pnres@gsnPanelXWhiteSpacePercent = 5
    pnres@gsnPanelXF = (/0.05,0.28,0.51/)    ; Adjust rightmost plots
    gsn_panel(wks1,(/plot(1:)/),(/1,3/),pnres)

end
