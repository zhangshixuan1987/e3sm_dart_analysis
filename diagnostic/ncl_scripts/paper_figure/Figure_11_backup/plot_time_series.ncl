  load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
  load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
  load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

; Purpose: A tempolate to make a 4-panel lat-lon plot
; panel 1: clim vs obs 
; panel 2: CAPT vs obs
; panel 3: DART vs obs
; Author : Shixuan Zhang

begin

  year      = 2011
  Varplt    = (/"PRECT", "FLUT"/)
  Varunt    = (/"mm day~S~-1~N~", "W m~S~-2~N~"/)
  nvars     = dimsizes(Varplt)
  nhind     = 5

  Groups    = (/"PDNUDG_ERA5_HIND_ENS01","PDDART_UVTQ_HIND_ENS80"/)
  ExpNam    = (/"hybrid IC","EAM/DART"/)
  Metric    = (/"MEAN","RMSD"/)
  ngrps     = dimsizes(Groups)

  Regions   = (/"Global", "Tropics", "MidLat"/)
  Regstrs   = (/"Global", "Tropics",  "Midlatitude (NH)"/)

  nregs     = dimsizes(Regions)
  ymin      = (/1.7, 231, \
                3.0, 245, \
                1.5, 215 /)
  ymax      = (/3.2, 246, \
                4.5, 265, \
                2.7, 231 /)
  ny        = (/6,6,5/)

  left_string  = (/"total precipitation","outgoing longwave radiation"/)
  fig_string   = (/"(a)","(b)","(c)","(d)","(e)","(f)"/)
  
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
 do irg = 0,nregs-1,1

  Plot_File = "./Time_series_dart_vs_hybridIC_mean_"+Regions(irg)+".nc"
  f = addfile(Plot_File,"r")

  do iv = 0,nvars-1,1

   Varname = Varplt(iv)
   if(Varname.eq."PRECT") then
     labels  = (/"hybrid IC", "EAM/DART", "CLIM (Jan, 5yr)", "GPCP (Jan, 5yr)"/)
   else
     labels  = (/"hybrid IC", "EAM/DART", "CLIM (Jan, 5yr)", "CERES-EBAF (Jan, 5yr)"/)
   end if 
  
   clmdat = new((/3/),double)
   obsdat = new((/3/),double)
   vclm1  = "CLIM_"+Varname + "_5yr_MEAN"
   vclm2  = "CLIM_"+Varname + "_5yr_RMSD"
   clmdat(0) = f->$vclm1$
   clmdat(1) = f->$vclm1$ - f->$vclm2$ 
   clmdat(2) = f->$vclm1$ + f->$vclm2$ 
   vobs1     = "OBS_"+Varname + "_5yr_MEAN"
   vobs2     = "OBS_"+Varname + "_5yr_RMSD"
   obsdat(0) = f->$vobs1$
   obsdat(1) = f->$vobs1$ - f->$vobs2$
   obsdat(2) = f->$vobs1$ + f->$vobs2$

   do i = 0,ngrps-1,1

    time   = ispan(1,nhind,1)
    ntime  = dimsizes(time)

    if(i.eq.0)then
     pltdat = new((/ngrps+2,3,nhind/),double)
    end if 

    varnam1 = Groups(i)+"_" + Varname + "_JAN_MEAN"
    varnam2 = Groups(i)+"_" + Varname + "_JAN_RMSD"

    pltdat(i,0,:)   = f->$varnam1$(0,:)
    pltdat(i,1,:)   = f->$varnam1$(0,:) - f->$varnam2$(0,:)
    pltdat(i,2,:)   = f->$varnam1$(0,:) + f->$varnam2$(0,:)

   end do 
    
   pltdat(ngrps,0,:)   = clmdat(0)
   pltdat(ngrps,1,:)   = clmdat(1)
   pltdat(ngrps,2,:)   = clmdat(2)

   pltdat(ngrps+1,0,:) = obsdat(0)
   pltdat(ngrps+1,1,:) = obsdat(1)
   pltdat(ngrps+1,2,:) = obsdat(2)

   ;;;start to process the plot;;;;
   if((iv+nvars*irg).eq.0)
     wtype     = "pdf"
     figname   = "./"+"Fig13"
     wks       = gsn_open_wks(wtype,figname)
     plot      = new(nvars*nregs,graphic)
     dum       = new((/nvars*nregs,ngrps+2/),graphic)
   end if 

   gsn_define_colormap(wks,"cb_9step")
   colors  = (/2, 28, 1, 13/)
   markers = (/16, 4, 1, 1/)
   mkszf   = (/0.5, 0.6, 0.01, 0.01/)*3.0
   dashind = (/0,0,0,0/)       ;;line dash pattern
   mkthick = (/2,2,2,2/)
   lnthick = (/3,3,2,2/) ;*1.5   ;;line thichness

  ;---Resources to share between both plots
   res          = True                   ; plot mods desired
   res@vpHeightF = 0.35
   res@vpWidthF =  0.9
   res@gsnDraw  = False
   res@gsnFrame = False

   FontHeightF = 0.024
   res@tiMainFontThicknessF          = 3.0
   res@tiMainFontHeightF             = FontHeightF*1.2
   res@tmYLLabelFontHeightF          = FontHeightF
   res@tmXBLabelFontHeightF          = FontHeightF 
   res@tiXAxisFontHeightF            = FontHeightF*1.1
   res@tiYAxisFontHeightF            = FontHeightF*1.1
   res@gsnStringFontHeightF          = FontHeightF*1.1

   BorderThick = 1
   res@tmBorderThicknessF    = BorderThick
   res@tmXBMajorThicknessF   = BorderThick
   res@tmYLMajorThicknessF   = BorderThick
   res@tmXTMajorThicknessF   = BorderThick
   res@tmYRMajorThicknessF   = BorderThick
   res@tmXBMinorThicknessF   = res@tmXBMajorThicknessF/2.0
   res@tmYLMinorThicknessF   = res@tmYLMajorThicknessF/2.0
   res@tmXTMinorThicknessF   = res@tmXTMajorThicknessF/2.0
   res@tmYRMinorThicknessF   = res@tmYRMajorThicknessF/2.0

 ; add a legend
   res@pmLegendDisplayMode    = "Never"              ; turn on legend
   res@pmLegendSide           = "Top"                 ; Change location of
   res@pmLegendWidthF         = 0.12                  ; Change width and
   res@pmLegendHeightF        = 0.10                  ; height of legend.
   res@lgLabelFontHeightF     = FontHeightF*0.95       ; change font height
   res@lgPerimOn              = False                 ; no box around

   res@tmXTOn                 = False
   res@tmYROn                 = False
  ;res@tmYLLabelFontHeightF   = FontHeightF
 
   res@tmXTOn  = False
   res@trXMinF               = 0.8 ;min(latrgd)
   res@trXMaxF               = 5.2 ;192 ;max(latrgd)
   res@tmXBMode              = "Explicit"
   res@tmXBValues            = ispan(1,5,1)
   res@tmXBLabels            = "" + (/"Day 1", "Day 2", "Day 3", "Day 4", "Day 5"/)
  ;res@tmXBMinorValues        = time

   res@trYMinF                = ymin(iv+nvars*irg)
   res@trYMaxF                = ymax(iv+nvars*irg)
   res@tmYLMode               = "Explicit"                ; explicit labels
   res@tmYLValues             = fspan(ymin(iv+nvars*irg),ymax(iv+nvars*irg),ny(irg))
   res@tmYLMinorValues        = fspan(ymin(iv+nvars*irg),ymax(iv+nvars*irg),(ny(irg)-1)*2+1)

   if(iv.eq.0)then 
     res@tmYLLabels              = ""+sprintf("%4.1f",res@tmYLValues)  
     res@tiXAxisString          := ""
   else
     res@tmYLLabels              = ""+res@tmYLValues         ; make strings
     res@tiXAxisString          := "" ;"Hindcast time (hour)"
   end if 
  
  ;left axis
   resL  = res
   resL@tiYAxisString          := "("+Varunt(iv)+")"
   resL@xyMarkLineMode         := "MarkLines"
   resL@xyLineColors           := colors
   resL@xyMarkers              := markers
   resL@xyMarkerColors         := colors
   resL@xyMarkerSizes          := 0.015*mkszf
   resL@xyMarkerThicknesses    := mkthick
   resL@xyDashPatterns         := dashind
   resL@xyLineThicknesses      := lnthick
   resL@gsnLeftString           = fig_string(iv+nvars*irg) + "  " +left_string(iv) ;""
   resL@gsnLeftStringFontColor  = "Black"
   resL@gsnRightString          = Regstrs(irg)
   resL@gsnRightStringFontColor = "Black"
   resL@tiMainString            = ""

   plot(iv+nvars*irg)   = gsn_csm_xy(wks,time,pltdat(:,0,:),resL)

   gsres1                       = res                        ; poly res
   gsres1@tmYROn                = False            ; Turn off right tickmarks.
   gsres1@tmYLOn                = False            ; Turn off top tickmarks
   gsres1@tmXTOn                = False            ; Turn off top tickmarks
   gsres1@tmXBOn                = False            ; Turn off top tickmarks
   gsres1@gsnXYFillOpacities    = 0.15
   gsres1@xyLineColors          = (/-1,-1/)
   gsres1@gsnXYFillColors       = colors(0)                ; color chosen
   str1 = unique_string("tmp1")
   dum(iv+nvars*irg,0)   = gsn_csm_xy (wks,time,pltdat(0,1:2,:),gsres1)
   overlay(plot(iv+nvars*irg),dum(iv+nvars*irg,0))
   str2 = unique_string("tmp2")
   gsres1@gsnXYFillColors       = colors(1)                ; color chosen
   dum(iv+nvars*irg,1)   = gsn_csm_xy (wks,time,pltdat(1,1:2,:),gsres1)
   overlay(plot(iv+nvars*irg),dum(iv+nvars*irg,1))
   str3 = unique_string("tmp3")
   gsres1@gsnXYFillColors       = colors(2)                ; color chosen
   dum(iv+nvars*irg,2)  = gsn_csm_xy (wks,time,pltdat(2,1:2,:),gsres1)
   overlay(plot(iv+nvars*irg),dum(iv+nvars*irg,2))
   str4 = unique_string("tmp4")
   gsres1@gsnXYFillColors       = colors(3)                ; color chosen
   dum(iv+nvars*irg,3)  = gsn_csm_xy (wks,time,pltdat(3,1:2,:),gsres1)
   overlay(plot(iv+nvars*irg),dum(iv+nvars*irg,3))

  ;Attach manual legend
   lgres                           = True
   lgres@lgItemTypes               = (/"MarkLines","MarkLines","Lines","Lines"/)
   lgres@lgLineLabelFontThicknessF = 1.0
 ; lgres@lgLineDashSegLenF     = 0.01
   lgres@lgMonoItemType        = False
   lgres@lgMonoDashIndex       = False
   lgres@lgMonoLineThickness   = False
   lgres@lgMonoMarkerThickness = False
   lgres@lgMonoMarkerSize      = True
   lgres@lgPerimOn          = False ;True
  ;lgres@lgRightMarginF     = 0.5
  ;lgres@lgLeftMarginF      = 0.5
  ;lgres@lgTopMarginF       = 0.5
  ;lgres@lgBottomtMarginF   = 0.5
   lgres@lgPerimThicknessF  = 1.0

   lgres1 = lgres
   if(iv.eq.0)then 
     lgres1@vpWidthF           = 0.32           ; width of legend (NDC)
     lgres1@vpHeightF          = 0.16           ; height of legend (NDC)
     lgres1@lgBoxMinorExtentF  = 0.20
     lgres1@lgBoxMajorExtentF  = 0.1
   else
     lgres1@vpWidthF           = 0.42           ; width of legend (NDC)
     lgres1@vpHeightF          = 0.18           ; height of legend (NDC)
     lgres1@lgBoxMinorExtentF  = 0.15
     lgres1@lgBoxMajorExtentF  = 0.1
   end if 

   lgres1@lgLineColors       = colors(:) ;(/"Black","Black","Black"/)
   lgres1@lgDashIndexes      = dashind(:)
   lgres1@lgLineThicknesses  = lnthick(:)/1.5
   lgres1@lgMarkerColors     = colors(:)
   lgres1@lgMarkerIndexes    = markers(:)
   lgres1@lgMarkerSizeF      = 0.006
   lgres1@lgMarkerThicknesses= mkthick(:)/1.5
   label1  = "  " +labels
   legend1 = gsn_create_legend (wks,dimsizes(label1), label1,lgres1)

   if(iv.eq.0)then
     amres                  = True
     amres@amJust           = "BottomRight"
     amres@amParallelPosF   =  0.45
     amres@amOrthogonalPosF =  0.48
   else
     amres                  = True
     amres@amJust           = "TopRight"
     amres@amParallelPosF   =  0.45
     amres@amOrthogonalPosF = -0.48
   end if

   if(irg.eq.0)then 
    annoid1 = gsn_add_annotation(plot(iv+nvars*irg),legend1,amres)  ; add legend to the top figure
   end if 

  delete([/res,resL,lgres,lgres1/])

  end do       ; end of looping over variables
  
 end do  ; end of regions

   pres                              = True        ; panel plot mods desired
   pres@gsnMaximize                  = False       ; fill the page
   pres@txFontHeightF                = FontHeightF
   pres@txFontThicknessF             = 2.
  ;pres@gsnPanelXWhiteSpacePercent   = 2.
  ;pres@gsnPanelYWhiteSpacePercent   = 5.
  ;pres@txString                     = "" ;"("+seasons(kk)+")"  
  ;pres@gsnPanelYF                   = (/-0.5,0.45/)
   gsn_panel(wks,plot(:),(/3,2/),pres)

   delete([/pres,wks/])

end
