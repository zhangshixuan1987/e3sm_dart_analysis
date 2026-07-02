  load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
  load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
  load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

; Purpose: A tempolate to make a 4-panel lat-lon plot
; panel 1: clim vs obs 
; panel 2: CAPT vs obs
; panel 3: DART vs obs
; Author : Shixuan Zhang

begin

  Plot_File = "./Global_map_e3sm_vs_obs_FLUT.nc"
  year      = 2011
  Varplt    = "FLUT"
  Varunt    = "W m~S~-2~N~"
  l_ttest   = True
  l_spread  = True

  Groups  = (/"CERES-EBAF","CLIM","CERES-EBAF_NOAA-AVHRR","PDNUDG_ERA5_HIND_ENS01","PDDART_UVTQ_HIND_ENS80"/)
  ExpNam  = (/"CERES-EBAF","CLIM","NOAA-AVHRR","ERA5/NDGUV","EAM/DART"/)
  Hind    = (/"day1","day2","day5"/)
  Metric  = (/"BIAS","PROB"/)
  ngrps   = dimsizes(Groups)

  exp_key = (/"5YR_JAN"/)

  nexps   = 9
  plot    = new(nexps,graphic)
  dum     = new(nexps,graphic)
  dum0    = new(nexps,graphic)
  labels  = new(nexps,string)
  labels(0)   = "(a) " + ExpNam(0)   + (/" (JAN, 5yr)"/)
  labels(1)   = "(b) " + ExpNam(1)   + " ~F34~>~N~~F~ " + ExpNam(0) + (/" (JAN, 5yr)"/)
  labels(2)   = "(c) " + ExpNam(2)   + " ~F34~>~N~~F~ " + ExpNam(0) + (/" (JAN, 2011)"/)
  labels(3:4) = (/"(d) ", "(e) "/) + ExpNam(3:4) + " ~F34~>~N~~F~ " + ExpNam(0) + (/" (day 1)"/)
  labels(5:6) = (/"(g) ", "(h) "/) + ExpNam(3:4) + " ~F34~>~N~~F~ " + ExpNam(0) + (/" (day 2)"/)
  labels(7:8) = (/"(j) ", "(k) "/) + ExpNam(3:4) + " ~F34~>~N~~F~ " + ExpNam(0) + (/" (day 5)"/)

  plot1       = new(3,graphic)
  labels1     = new(3,string)
  labels1(0)  = "(f) " + ExpNam(4) + " spread" + (/" (day 1)"/)
  labels1(1)  = "(i) " + ExpNam(4) + " spread" + (/" (day 2)"/)
  labels1(2)  = "(l) " + ExpNam(4) + " spread" + (/" (day 5)"/)

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  f = addfile(Plot_File,"r")
  ii = -1
  
  do i = 0,nexps-1,1

   if(i.eq.0) then
     varnam = Groups(i) + "_" + exp_key
     var1   = f->$varnam$
     vspd   = -9999.0
     Rstr   = "Global mean: "+sprintf("%5.2f",var1@global_mean(2))
     Lstr   = str_upper(Varplt)+ " ("+Varunt+")"
     prob   = -9999

   else if (i.eq.1) then

     varnam  = Groups(i) + "_" + exp_key +"_BIAS"
     var1    = f->$varnam$
     prob    = -9999
     vspd   = -9999.0

     Rstr   = "Global mean: "+sprintf("%5.2f",var1@global_mean(2))
     Lstr   = "~F33~D~N~~F~" +str_upper(Varplt)+ " ("+Varunt+")"
     prob   = -9999

   else if (i.eq.2) then

     varnam = Groups(i) + "_" + exp_key
     var1   = f->$varnam$
     Rstr   = "Global mean: "+sprintf("%5.2f",var1@global_mean(2))
     Lstr   = str_upper(Varplt)+ " ("+Varunt+")"
     prob   = -9999
     vspd   = -9999.0

   else 

     if (i.le.4) then
       varnam1 = Groups(i)  + "_BIAS_" + Hind(0)
       varnam2 = Groups(i)  + "_TTEST_" + Hind(0)
       varnam3 = Groups(i)  + "_SPREAD_" + Hind(0)

     else if(i.le.6) then
       varnam1 = Groups(i-2)  + "_BIAS_" + Hind(1)
       varnam2 = Groups(i-2)  + "_TTEST_" + Hind(1)
       varnam3 = Groups(i-2)  + "_SPREAD_" + Hind(1)

     else
       varnam1 = Groups(i-4)  + "_BIAS_" + Hind(2)
       varnam2 = Groups(i-4)  + "_TTEST_" + Hind(2)
       varnam3 = Groups(i-4)  + "_SPREAD_" + Hind(2)

     end if
     end if 

     var1    = f->$varnam1$
     prob    = f->$varnam2$
     prob@_FillValue = -9999
     prob    = where((prob+0.5).ge.95.0, prob@_FillValue, prob)
     vspd    = f->$varnam3$
     Rspd    = "Global mean: " + sprintf("%5.2f",var1@global_mean(2))
     prob1   = prob 
     prob1   = where(abs(var1).ge.vspd-0.01,prob,prob@_FillValue)

     Rstr   = "Corr: " + sprintf("%5.2f",var1@pattn_corr(2))
     if(var1@pattn_corr(3).ne.0) then
       Rstr = Rstr  + " ~F34~1~N~~F~ " + sprintf("%5.2f",var1@pattn_corr(3))
     end if
     Lstr    = "~F33~D~N~~F~" + str_upper(Varplt)+ " ("+Varunt+")"

   end if 
   end if 
   end if 

   print(min(vspd)+  " "+max(vspd))
   printVarSummary(var1)
   var1@_FillValue = -9999.0
   vspd@_FillValue = -9999.0
   prob@_FillValue = -9999 
   ;;;start to process the plot;;;;
   if (i.eq.0) then 
     wtype     = "pdf"
     figname   = "./"+"Fig15"
     wks       = gsn_open_wks(wtype,figname)
   end if 

   gsn_merge_colormaps(wks,"BlueDarkRed18","nrl_sirkes") ;"BlueWhiteOrangeRed")
   colorgroup1 = (/2,4,6,7,8,29,11,12,14,15,17,19/)

   s1    = (/140,150,160,170,180,200,220,240,260,280,300/)*1.0
   s2    = (/-20.0,-15.0,-10.0,-5.0,-1,0,1,5.0,10.0,15.0,20.0/)
   s3    = (/0.1,0.4,0.8,1.2,1.6,2.0,3.0,4.0,5.0,6.0,7.0,8/)

  ;gsn_merge_colormaps(wks,"amwg","amwg_blueyellowred")  ; merge two color maps

   res                  	        = True                  ; plot mods desired
   res@cnFillOn         	        = True                  ; turn on color fill
   res@cnLinesOn          	        = False                 ; no contour lines
   res@cnLineLabelsOn     	        = False
   res@gsnFrame                      = False                 ; Do not draw plot
   res@gsnDraw                       = False                 ; Do not advance frame

   FontHeightF = 0.018
   res@tiMainFontThicknessF          = 3.0
   res@tiMainFontHeightF             = FontHeightF*1.2
   res@tmYLLabelFontHeightF          = FontHeightF
   res@tmXBLabelFontHeightF          = FontHeightF 
   res@tiXAxisFontHeightF            = FontHeightF
   res@tiYAxisFontHeightF            = FontHeightF
   res@gsnStringFontHeightF          = FontHeightF
   res@cnLineLabelFontHeightF        = FontHeightF
   res@lbLabelFontHeightF            = FontHeightF*0.8
   res@lbTitleFontHeightF            = FontHeightF*0.8

   res@tmXTOn                        = False
  ;res@tmYLLabelFontHeightF	 	= 0.015
   res@tmBorderThicknessF            = 1.0
   res@tmXBMajorThicknessF           = 1.0
   res@tmXBMinorThicknessF           = 1.0
   res@tmYLMajorThicknessF           = 1.0
   res@tmYLMinorThicknessF           = 1.0
   res@tmYRMajorThicknessF           = 1.0
   res@tmYRMinorThicknessF           = 1.0

   res@mpFillOn                      = False        ; turn off map fill
   res@mpGeophysicalLineThicknessF   = 2.0
   res@mpMinLonF                     =   0
   res@mpMaxLonF                     = 360
   res@mpCenterLonF                  = 180     ; This is necessary to get the correct map

   res@gsnMajorLatSpacing            = 30
   res@gsnMajorLonSpacing            = 45
   res@gsnMinorLatSpacing            = 15
   res@gsnMinorLonSpacing            = 15

   res@lbLabelBarOn      	     = True
   res@lbOrientation     	     = "Vertical"
   res@lbPerimOn                     = False             ; default has box
   res@pmLabelBarHeightF             = 0.38
   res@pmLabelBarWidthF              = 0.1
   res@pmLabelBarParallelPosF        = 0.50
   res@pmLabelBarOrthogonalPosF      = 0.05
   res@lbTitleString                 = Lstr 
   res@lbOrientation                 = "Vertical"
   res@lbTitlePosition               = "Right"                           ; title location
   res@lbTitleDirection              = "Across"                          ; letter angle
   res@lbTitleAngleF                 = 90.                               ; title angle

   res@cnInfoLabelOn     		= False
   res@cnLevelSelectionMode      	= "ExplicitLevels"       ; manual levels
   res@cnMissingValFillColor 	= "White" ;"gray76"               ; black = 1

  ;res@gsnRightStringFontHeightF	= 0.025
  ;res@gsnRightStringOrthogonalPosF  = 0.06
  ;res@gsnLeftStringFontHeightF	= 0.025

  if(i.eq.0) then 

   res1 = res
   res1@cnLevels                    := sprintf("%7.2f",s1)
   res1@cnFillPalette                = "percent_11lev"
   res1@gsnLeftString                = labels(i)
   res1@tiMainString                 = "" 
   res1@gsnRightString               = Rstr
   res1@lbLabelStrings               = sprintf("%5.1f",s1)
   plot(i)   			     = gsn_csm_contour_map_ce(wks,var1,res1)
 
  else
 
   res2 = res
   res2@cnLevels      		     = sprintf("%7.2f",s2)
   res2@cnFillColors  	       	     = colorgroup1 ;(/18,20,22,23,24,25,26,27,28,30,31,33/)
  ;res2@cnFillPalette                =  "BlueDarkRed18" ;"NCV_jaisnd"          
   res2@gsnLeftString 		     = labels(i) 
   res2@tiMainString                 = ""
   res2@gsnCenterString              = "" ;seasons(kk)
   res2@gsnRightString               = Rstr
   res2@lbLabelStrings               = sprintf("%5.1f",s2)
   plot(i) 			     = gsn_csm_contour_map_ce(wks,var1,res2)

  if (l_ttest) then 

   if(.not.all(ismissing(prob)))then 
     rescn2 = True
     rescn2@lbLabelBarOn    = False
     rescn2@gsnTickMarksOn  = False     ; no tickmarks
     rescn2@gsnDraw         = False     ; don't draw
     rescn2@gsnFrame        = False     ; don't advance frame
     rescn2@tiMainString    = ""
     rescn2@gsnLeftString   = ""
     rescn2@gsnRightString  = ""
    ;rescn2@cnMinLevelValF  = 95.0
    ;rescn2@cnMaxLevelValF  = 100.0
    ;rescn2@cnLevelSpacingF = 1.
     rescn2@cnMonoFillPattern = True
     rescn2@cnMonoFillColor = True
     rescn2@cnFillOn        = True      ; color fill
     rescn2@cnLinesOn       = False
     rescn2@cnLineLabelsOn  = False        ; True is default
     rescn2@cnInfoLabelOn   = False                ; turn off info label
     rescn2@cnFillMode      = "AreaFill" ; raster fill significance patterns
     rescn2@cnFillPattern   = 17
     rescn2@cnFillDotSizeF  = 0.004
     rescn2@cnFillColor     = "Magenta";"black"
     rescn2@cnFillOpacityF  = 0.6
     dum(i)   = gsn_csm_contour(wks,prob,rescn2) ; contours are at 95,100
     rescn2@cnFillColor     = "Black" ;"Magenta"
     dum0(i)  = gsn_csm_contour(wks,prob1,rescn2) ; contours are at 95,100 
     overlay(plot(i),dum(i))
     overlay(plot(i),dum0(i))
   end if 

  end if 

 end if 

   if(l_spread.and.isStrSubset(labels(i),"DART"))then
    ii = ii +1
    res3 = res
    res3@cnLevels                     = sprintf("%7.2f",s3)
    res3@cnFillPalette                = "precip3_16lev" ;"percent_11lev";
    res3@gsnLeftString                = labels1(ii)
    res3@tiMainString                 = ""
    res3@gsnCenterString              = "" 
    res3@gsnRightString               = Rspd
    res3@lbLabelStrings               = sprintf("%5.2f",s3)
    plot1(ii)                         = gsn_csm_contour_map_ce(wks,vspd,res3)
   end if

 delete([/s1,s2,s3,var1,prob,vspd/])

 end do       ; end of looping over variables

   pres                              = True        ; panel plot mods desired
   pres@gsnMaximize                  = False       ; fill the page
   pres@txFontHeightF                = 0.012
   pres@txFontThicknessF             = 2.
   pres@gsnPanelXWhiteSpacePercent   = 3.
   pres@gsnPanelYWhiteSpacePercent   = 5.
   pres@txString                     = "" ;"("+seasons(kk)+")"  
   gsn_panel(wks,(/plot(0),plot(1),plot(2),plot(3),plot(4),plot1(0), \
                    plot(5),plot(6),plot1(1),plot(7),plot(8),plot1(2) /),(/4,3/),pres)

   delete([/res,pres,wks/])

end
