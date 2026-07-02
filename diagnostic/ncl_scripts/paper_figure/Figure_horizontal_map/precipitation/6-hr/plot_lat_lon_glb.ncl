  load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
  load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
  load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

; Purpose: A tempolate to make a 4-panel lat-lon plot
; panel 1: clim vs obs 
; panel 2: CAPT vs obs
; panel 3: DART vs obs
; Author : Shixuan Zhang

begin

  Plot_File = "./Global_map_e3sm_vs_GPCP_PRECT.nc"
  year      = 2011
  Varplt    = "PRECT"
  Varunt    = "mm day~S~-1~N~"
 
  Groups  = (/"GPCP","CLIM",\
              "PDDART_UV_ENS80","PDDART_UVT_ENS80","PDDART_UVTQ_ENS80", \
              "PDNUDG_UV_ENS01", "PDNUDG_UVT_ENS01", "PDNUDG_UVTQ_ENS01"/)
  ExpNam  = (/"GPCP","CLIM","EDA-UV","EDA-UVT","EDA-UVTQ","NDG-UV","NDG-UVT","NDG-UVTQ"/)
  Hind    = (/"day1"/)
  Metric  = (/"BIAS","PROB"/)
  ngrps   = dimsizes(Groups)

  gpcp_key = (/"5YR_JAN"/)

  nexps   = 8
  plot    = new(nexps,graphic)
  dum     = new(nexps,graphic)
  labels  = new(nexps,string)
  labels(0)   = ExpNam(0)   + (/" (JAN, 5yr)"/)
  labels(1)   = ExpNam(1)   + " ~F34~>~N~~F~ " + ExpNam(0) + (/" (JAN, 5yr)"/)
  labels(2:3) = ExpNam(2:3) + " ~F34~>~N~~F~ " + ExpNam(0) + (/" (day 1)"/)
  labels(4:5) = ExpNam(4:5) + " ~F34~>~N~~F~ " + ExpNam(0) + (/" (day 2)"/)
  labels(6:7) = ExpNam(6:7) + " ~F34~>~N~~F~ " + ExpNam(0) + (/" (day 5)"/)

  l_ttest = True 
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  f = addfile(Plot_File,"r")
  
  do i = 0,nexps-1,1

   if(i.eq.0) then
     varnam = Groups(i) + "_" + gpcp_key
     var1   = f->$varnam$
     Rstr   = "Global mean: "+sprintf("%5.2f",var1@global_mean(2))
     if(var1@global_mean(3).ne.0) then
       Rstr = Rstr  + " ~F34~1~N~~F~ " + sprintf("%5.2f",var1@global_mean(3))
     end if 
     Lstr   = str_upper(Varplt)+ " ("+Varunt+")"
     prob   = -9999

   else if (i.eq.1) then


     varnam1 = Groups(i) + "_" + gpcp_key +"_BIAS"
     varnam2 = Groups(i) + "_" + gpcp_key +"_TTEST"

     var1   = f->$varnam1$
     prob   = f->$varnam2$
     prob@_FillValue = -9999
     prob   = where(prob.ge.95.0, prob@_FillValue, prob)

     Rstr   = "RMSE: "+sprintf("%5.2f",var1@global_rmse(2))
     if(var1@global_rmse(3).ne.0) then
       Rstr  = Rstr  + " ~F34~1~N~~F~ " + sprintf("%5.2f",var1@global_rmse(3))
     end if
     Rstr   = Rstr + "~C~" + "Bias: "+sprintf("%5.2f",var1@global_mean(2))
     if(var1@global_mean(3).ne.0) then
       Rstr  = Rstr  + " ~F34~1~N~~F~ " + sprintf("%5.2f",var1@global_mean(3))
     end if
     Rstr   = Rstr + "~C~" + "Corr: " + sprintf("%5.2f",var1@pattn_corr(2))
     if(var1@pattn_corr(3).ne.0) then
       Rstr = Rstr  + " ~F34~1~N~~F~ " + sprintf("%5.2f",var1@pattn_corr(3))
     end if
     Lstr   = "~F33~D~N~~F~" +str_upper(Varplt)+ " ("+Varunt+")"
     prob   = -9999

   else 

     varnam1 = Groups(i)  + "_BIAS_" + Hind(0)
     varnam2 = Groups(i)  + "_TTEST_" + Hind(0)

     var1    = f->$varnam1$
     prob    = f->$varnam2$
     prob@_FillValue = -9999
     prob    = where(prob.ge.95.0, prob@_FillValue, prob)

     Rstr   = "RMSE: "+sprintf("%5.2f",var1@global_rmse(2))
     if(var1@global_rmse(3).ne.0) then
       Rstr  = Rstr  + " ~F34~1~N~~F~ " + sprintf("%5.2f",var1@global_rmse(3))
     end if
     Rstr   = Rstr + "~C~" + "Bias: "+sprintf("%5.2f",var1@global_mean(2))
     if(var1@global_mean(3).ne.0) then
       Rstr  = Rstr  + " ~F34~1~N~~F~ " + sprintf("%5.2f",var1@global_mean(3))
     end if
     Rstr   = Rstr + "~C~" + "Corr: " + sprintf("%5.2f",var1@pattn_corr(2))
     if(var1@pattn_corr(3).ne.0) then
       Rstr = Rstr  + " ~F34~1~N~~F~ " + sprintf("%5.2f",var1@pattn_corr(3))
     end if
     Lstr    = "~F33~D~N~~F~" + str_upper(Varplt)+ " ("+Varunt+")"

   end if 
   end if 
   
   prob@_FillValue = -9999 
   ;;;start to process the plot;;;;
   if (i.eq.0) then 
     wtype     = "pdf"
     figname   = "./"+"Fig_latlon"
     wks       = gsn_open_wks(wtype,figname)
   end if 

   s1    = (/.01,.1,1,2,3,4,5,6,8,10,12/)*1.0
   s2    = (/-5.0,-3.0,-2.0,-1.0,-0.2,0,0.2,1.0,2.0,3.0,5.0/)*1.0
   s3    = (/-100,-80,-50,-20,-10,10,20,50,80,100/)/1.0

   gsn_merge_colormaps(wks,"amwg","amwg_blueyellowred")  ; merge two color maps

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
  ;res1@cnFillColors                 = (/3,4,5,6,7,8,9,10,11,12,13,29,30,15,16,17/)
   res1@cnFillPalette                = "percent_11lev"
   res1@gsnLeftString                = labels(i)
   res1@tiMainString                 = "" 
   res1@gsnRightString               = Rstr
   res1@lbLabelStrings               = sprintf("%5.1f",s1)
   plot(i)   			     = gsn_csm_contour_map_ce(wks,var1,res1)
 
  else
 
   res2 = res
   res2@cnLevels      		     = sprintf("%7.2f",s2)
  ;res2@cnFillColors  	       	     = (/18,20,22,23,24,25,26,27,28,30,31,33/)
   res2@cnFillPalette                =  "BlueDarkRed18" ;"NCV_jaisnd"          
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
     rescn2@cnFillColor     = "black"
     rescn2@cnFillOpacityF  = 0.5
     dum(i)   = gsn_csm_contour(wks,prob,rescn2) ; contours are at 95,100
     overlay(plot(i),dum(i))
   end if 

  end if 

 end if 

 delete([/s1,s2,s3,var1,prob/])

 end do       ; end of looping over variables

   pres                              = True        ; panel plot mods desired
   pres@gsnMaximize                  = False       ; fill the page
   pres@txFontHeightF                = 0.012
   pres@txFontThicknessF             = 2.
   pres@gsnPanelXWhiteSpacePercent   = 3.
   pres@gsnPanelYWhiteSpacePercent   = 5.
   pres@txString                     = "" ;"("+seasons(kk)+")"  
   gsn_panel(wks,plot(:),(/3,3/),pres)

   ;convert the figure 
   ;if (wtype .eq. "png") then
   ;  tmpa = systemfunc("convert "+figdir+fe+".png -trim del.png")
   ;  tmpb = systemfunc("mv del.png "+fe+".png")
   ;end if

   delete([/res,pres,wks/])

end
