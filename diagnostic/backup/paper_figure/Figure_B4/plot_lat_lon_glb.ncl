  load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
  load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
  load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

; Purpose: A tempolate to make a 4-panel lat-lon plot
; panel 1: clim vs obs 
; panel 2: CAPT vs obs
; panel 3: DART vs obs
; Author : Shixuan Zhang

begin

  VarList = (/"CLDTOT",    "PRECT", "FLUT",      "SWCF",      "LWCF"/)
  UntList = (/"%", "mm day~S~-1~N~", "W m~S~-2~N~", "W m~S~-2~N~", "W m~S~-2~N~"/)
  ObsList = (/"CERES-EBAF","GPCP",  "NOAA-AVHRR","CERES-EBAF","CERES-EBAF"/)
  nvars   = dimsizes(VarList)

  Groups   = (/"CLIM","PDNUDG_ERA5_HIND_ENS01","PDDART_UVTQ_HIND_ENS80","PDDART_UVTQ_HIND_ENS80"/)
  ExpNam   = (/"CLIM","hybrid IC","EAM/DART","EAM/DART"/)
  Hind     = (/"day2"/)
  Metric   = (/"BIAS"/)
  ngrps    = dimsizes(Groups)
  l_ttest  = False
  l_spread = True
  exp_key  = (/"5YR_JAN"/)

  npanels  = nvars*ngrps
  plot     = new(npanels,graphic)
  dum      = new(npanels,graphic)
  dum0     = new(npanels,graphic)
  fignum   = (/"a","b","c","d","e"/)

  do iv = 0,nvars-1,1

   Varplt    = VarList(iv)
   Varunt    = UntList(iv)
   labels    = new(ngrps,string)

   Plot_File = "./Global_map_e3sm_vs_obs_"+Varplt+".nc"
   f = addfile(Plot_File,"r")

   lat       = f->lat
   lon       = f->lon
   
   do igp = 1,ngrps,1

    if (igp.eq.1) then
     varnam  = Groups(igp-1) + "_" + exp_key +"_BIAS"
     var1    = f->$varnam$
     Rstr    = "Global mean: "+sprintf("%5.2f",var1@global_mean(2))

    else if (igp.le.3) then
     varnam  = Groups(igp-1)  + "_BIAS_"+Hind
     var1    = f->$varnam$
     Rstr    = "Corr: " + sprintf("%5.2f",var1@pattn_corr(2))
     if(var1@pattn_corr(3).ne.0) then
       Rstr  = Rstr  + " ~F34~1~N~~F~ " + sprintf("%5.2f",var1@pattn_corr(3))
     end if

    else
     varnam  = Groups(igp-1)  + "_SPREAD_"+Hind
     var1    = f->$varnam$
     printVarSummary(var1)
     Rstr    = "" ;"Mean: "+sprintf("%5.2f",var1@global_mean(0))

    end if
    end if 

    var1@_FillValue = -9999.0
    Lstr   = "("+Varunt+")" ;"~F33~D~N~~F~" +str_upper(Varplt)+ " ("+Varunt+")"

    if(igp.ne.ngrps)then
      labels(igp-1) = "("+fignum(iv)+igp+") " + ExpNam(igp-1) + " (~F33~D~N~~F~"+Varplt+")" ; "+Varunt+")"  
    else
      labels(igp-1) = "("+fignum(iv)+igp+") " + ExpNam(igp-1) + " ensemble spread" + " (~F33~D~N~~F~"+Varplt+")" ; "+Varunt+")"  
    end if

   load "./fig_setup.ncl" 

   ;;;;;; start to process the figures 
   res                  	        = True                  ; plot mods desired
   res@cnFillOn         	        = True                  ; turn on color fill
   res@cnLinesOn          	        = False                 ; no contour lines
   res@cnLineLabelsOn     	        = False
   res@gsnFrame                      = False                 ; Do not draw plot
   res@gsnDraw                       = False                 ; Do not advance frame

   FontHeightF = 0.024
   res@tiMainFontThicknessF          = 3.0
   res@tiMainFontHeightF             = FontHeightF*1.1
   res@tmYLLabelFontHeightF          = FontHeightF
   res@tmXBLabelFontHeightF          = FontHeightF 
   res@tiXAxisFontHeightF            = FontHeightF
   res@tiYAxisFontHeightF            = FontHeightF
   res@gsnStringFontHeightF          = FontHeightF*1.1
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
   res@mpGeophysicalLineThicknessF   = 1.0
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
 
  print(iv*ngrps+igp-1)

  if(igp.eq.ngrps) then 
   res1 = res
   res1@cnLevels                    := sprintf("%.1f",s3)
   res1@cnFillPalette                = "percent_11lev"
   res1@gsnLeftString                = labels(igp-1)
   res1@tiMainString                 = "" 
   res1@gsnRightString               = Rstr
   res1@lbLabelStrings              := sprintf("%.1f",s3)
   plot(iv*ngrps+igp-1)              = gsn_csm_contour_map_ce(wks,var1,res1)

  else

   res2 = res
   res2@cnLevels      		    := s2 ;sprintf("%5.1f",s2)
   res2@cnFillColors  	       	     = colorgroup1 
  ;res2@cnFillPalette                =  "BlueDarkRed18" ;"NCV_jaisnd"          
   res2@gsnLeftString 		     = labels(igp-1) 
   res2@tiMainString                 = ""
   res2@gsnCenterString              = "" ;seasons(kk)
   res2@gsnRightString               = Rstr
   res2@lbLabelStrings              := s2 ;sprintf("%5.1f",s2)
   plot(iv*ngrps+igp-1)            = gsn_csm_contour_map_ce(wks,var1,res2)

  end if 

  delete([/s1,s2,s3,var1/])

 end do 
 end do       ; end of looping over variables

   pres                              = True        ; panel plot mods desired
   pres@gsnMaximize                  = False       ; fill the page
   pres@txFontHeightF                = 0.012
   pres@txFontThicknessF             = 2.
   pres@gsnPanelXWhiteSpacePercent   = 3.
   pres@gsnPanelYWhiteSpacePercent   = 5.
   pres@txString                     = "" ;"("+seasons(kk)+")"  
   print(num(ismissing(plot)))
   gsn_panel(wks,plot,(/nvars,ngrps/),pres)
   delete([/res,pres,wks/])

end
