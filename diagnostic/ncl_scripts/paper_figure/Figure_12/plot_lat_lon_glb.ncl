  load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
  load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
  load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

; Purpose: A tempolate to make a 4-panel lat-lon plot
; panel 1: clim vs obs 
; panel 2: CAPT vs obs
; panel 3: DART vs obs
; Author : Shixuan Zhang

begin

  Plot_File = "./Global_map_e3sm_vs_obs_PRECT.nc"
  year      = 2011
  Varplt    = "PRECT"
  Varunt    = "mm day~S~-1~N~"
  l_ttest   = True
  l_spread  = True

  Groups  = (/"GPCP","CLIM","PDNUDG_ERA5_HIND_ENS01","PDDART_UVTQ_HIND_ENS80"/)
  ExpNam  = (/"GPCP","CLIM","hybrid IC ","EAM/DART"/)
  Hind    = (/"1hr","day1"/)
  Metric  = (/"BIAS","PROB"/)
  ngrps   = dimsizes(Groups)

  exp_key = (/"5YR_JAN"/)

  nexps   = 6
  plot    = new(nexps,graphic)
  dum     = new(nexps,graphic)
  dum0    = new(nexps,graphic)
  labels  = new(nexps,string)
  labels(0)   = "(a) " + ExpNam(0)   + (/" (JAN, 5yr)"/)
  labels(1)   = "(b) " + ExpNam(1)   + " ~F34~>~N~~F~ " + ExpNam(0) + (/" (JAN, 5yr)"/)
  labels(2:3) = (/"(c) ", "(d) "/) + ExpNam(2:3)  + (/" (1-hr)"/) ;+ " ~F34~>~N~~F~ " + ExpNam(0) + (/" (1-hr)"/)
  labels(4:5) = (/"(e) ", "(f) "/) + ExpNam(2:3)  + (/" (day 1)"/) ;+ " ~F34~>~N~~F~ " + ExpNam(0) + (/" (day 1)"/)

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  f = addfile(Plot_File,"r")
  ii = -1
  
  do i = 0,nexps-1,1

   if(i.eq.0) then
     varnam = Groups(i) + "_" + exp_key
     var1   = f->$varnam$
     Rstr   = "Global mean: "+sprintf("%5.2f",var1@global_mean(2))
     Lstr   = str_upper(Varplt)+ " ("+Varunt+")"

   else if (i.eq.1) then

     varnam  = Groups(i) + "_" + exp_key +"_BIAS"
     var1    = f->$varnam$

     Rstr   = "Global mean: "+sprintf("%5.2f",var1@global_mean(2))
     Lstr   = "~F33~D~N~~F~" +str_upper(Varplt)+ " ("+Varunt+")"

   else 

     if (i.le.3) then
       varnam1 = Groups(i)  + "_BIAS_" + Hind(0)
     else 
       varnam1 = Groups(i-2)  + "_BIAS_" + Hind(1)
     end if 
      
     var1    = f->$varnam1$
     Rstr   = "Corr: " + sprintf("%5.2f",var1@pattn_corr(2))
     if(var1@pattn_corr(3).ne.0) then
       Rstr = Rstr  + " ~F34~1~N~~F~ " + sprintf("%5.2f",var1@pattn_corr(3))
     end if
     Lstr    = "~F33~D~N~~F~" + str_upper(Varplt)+ " ("+Varunt+")"

   end if 
   end if 

   printVarSummary(var1)
   var1@_FillValue = -9999.0
   ;;;start to process the plot;;;;
   if (i.eq.0) then 
     wtype     = "pdf"
     figname   = "./"+"Fig12"
     wks       = gsn_open_wks(wtype,figname)
   end if 

   gsn_merge_colormaps(wks,"BlueDarkRed18","nrl_sirkes") ;"BlueWhiteOrangeRed")
   colorgroup1 = (/2,4,6,7,9,11,13,15,17,19/)

   s1    = (/.01,.1,1,2,3,4,5,6,8,10,12/)*1.0
   s2    = (/-5.0,-2.0,-1.0,-0.1,0,0.1,1.0,2.0,5.0/)*1.0
   s3    = (/0.0,0.1,0.2,0.3,0.4,0.5,0.6,0.8,1.0,1.2,1.6/)
 
  ;gsn_merge_colormaps(wks,"amwg","amwg_blueyellowred")  ; merge two color maps

   res                  	        = True                  ; plot mods desired
   res@cnFillOn         	        = True                  ; turn on color fill
   res@cnLinesOn          	        = False                 ; no contour lines
   res@cnLineLabelsOn     	        = False
   res@gsnFrame                      = False                 ; Do not draw plot
   res@gsnDraw                       = False                 ; Do not advance frame

   FontHeightF = 0.020
   res@tiMainFontThicknessF          = 3.0
   res@tiMainFontHeightF             = FontHeightF*1.2
   res@tmYLLabelFontHeightF          = FontHeightF
   res@tmXBLabelFontHeightF          = FontHeightF 
   res@tiXAxisFontHeightF            = FontHeightF
   res@tiYAxisFontHeightF            = FontHeightF
   res@gsnStringFontHeightF          = FontHeightF*1.2
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

 end if 

 delete([/s1,s2,s3,var1/])

 end do       ; end of looping over variables

   pres                              = True        ; panel plot mods desired
   pres@gsnMaximize                  = False       ; fill the page
   pres@txFontHeightF                = 0.012
   pres@txFontThicknessF             = 2.
   pres@gsnPanelXWhiteSpacePercent   = 3.
   pres@gsnPanelYWhiteSpacePercent   = 5.
   pres@txString                     = "" ;"("+seasons(kk)+")"  
   gsn_panel(wks,plot(:),(/3,2/),pres)

   delete([/res,pres,wks/])

end
