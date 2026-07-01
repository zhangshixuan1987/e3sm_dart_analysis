  load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
  load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
  load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

; Purpose: A tempolate to make a 4-panel lat-lon plot
; panel 1: clim vs obs 
; panel 2: CAPT vs obs
; panel 3: DART vs obs
; Author : Shixuan Zhang

begin

  Plot_File = "./Time_series_dart_vs_hybridIC.nc"
  year      = 2011
  Varplt    = (/"PRECT", "CLDTOT", "FLUT"/)
  Varunt    = (/"mm day~S~-1~N~", "fraction", "W m~S~-2~N~"/)
  nvars     = dimsizes(Varplt)
  ymin      = (/1.0, 0.42, 230/)
  ymax      = (/3.4, 0.72, 248/)

  Groups    = (/"PDNUDG_ERA5_HIND_ENS01","PDDART_UVTQ_HIND_ENS80"/)
  ExpNam    = (/"hybrid IC","EAM/DART"/)
  Metric    = (/"MEAN","RMSD"/)
  ngrps     = dimsizes(Groups)

  labels       = (/"hybrid IC", "EAM/DART", "CLIM (Jan, 5yr)"/)
  left_string  = (/"(a) total precipitation",\
                   "(b) total cloud fraction", \
                   "(c) outgoing longwave radiation"/)

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  f = addfile(Plot_File,"r")
  
  do iv = 0,nvars-1,1

   clmdat = new((/3/),double)
   vclm1 = "CLIM_"+Varplt(iv) + "_MEAN"
   vclm2 = "CLIM_"+Varplt(iv) + "_RMSD"
   clmdat(0) = f->$vclm1$
   clmdat(1) = f->$vclm1$ - f->$vclm2$ 
   clmdat(2) = f->$vclm1$ + f->$vclm2$ 

   do i = 0,ngrps-1,1

    time   = f->time 
    ntime  = dimsizes(time)

    if(i.eq.0)then
     pltdat = new((/ngrps+1,3,ntime/),double)
    end if 
    varnam1 = Groups(i)+"_"+Varplt(iv) + "_MEAN"
    varnam2 = Groups(i)+"_"+Varplt(iv) + "_RMSD"
    pltdat(i,0,:)   = f->$varnam1$
    pltdat(i,1,:)   = f->$varnam1$ - f->$varnam2$
    pltdat(i,2,:)   = f->$varnam1$ + f->$varnam2$

   end do 
    
   pltdat(ngrps,0,:) = clmdat(0)
   pltdat(ngrps,1,:) = clmdat(1)
   pltdat(ngrps,2,:) = clmdat(2)

   pltdat(:,:,0) = -9999
   pltdat@_FillValue = -9999

   ;;;start to process the plot;;;;
   if(iv.eq.0)
     wtype     = "pdf"
     figname   = "./"+"Fig10"
     wks       = gsn_open_wks(wtype,figname)
     plot      = new(nvars,graphic)
     dum       = new((/nvars,ngrps+1/),graphic)
   end if 

   gsn_define_colormap(wks,"cb_9step")
   colors  = (/2, 28, 1/)
   markers = (/16, 4, 1/)
   mkszf   = (/0.5, 0.6, 0.1/)*1.2
   dashind = (/0,0,0/)       ;;line dash pattern
   mkthick = (/2,2,1/)
   lnthick = (/3,3,2/) ;*1.5   ;;line thichness

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

   res@trXMaxF                = max(time)+1.0
   res@trXMinF                = 0
   res@tmXBMode               = "Explicit"
   res@tmXBValues             = time(::4)
   res@tmXBLabels             = "" + res@tmXBValues
   res@tmXBMinorValues        = time

   res@trYMinF                = ymin(iv)
   res@trYMaxF                = ymax(iv)
   res@tmYLMode               = "Explicit"                ; explicit labels
   res@tmYLValues             = fspan(ymin(iv),ymax(iv),7)
   res@tmYLMinorValues        = fspan(ymin(iv),ymax(iv),19)

   if(iv.le.1)then 
     res@tmYLLabels              = ""+sprintf("%5.2f",res@tmYLValues)         ; make strings
     res@tiXAxisString          := ""
   else
     res@tmYLLabels              = ""+res@tmYLValues         ; make strings
     res@tiXAxisString          := "Hindcast time (hour)"
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
   resL@gsnLeftString           = left_string(iv) ;""
   resL@gsnLeftStringFontColor  = "Black"
   resL@gsnRightString          = ""
   resL@gsnRightStringFontColor = "Black"
   resL@tiMainString            = ""

   plot(iv)   = gsn_csm_xy(wks,time,pltdat(:,0,:),resL)

   gsres1                       = res                        ; poly res
   gsres1@tmYROn                = False            ; Turn off right tickmarks.
   gsres1@tmYLOn                = False            ; Turn off top tickmarks
   gsres1@tmXTOn                = False            ; Turn off top tickmarks
   gsres1@tmXBOn                = False            ; Turn off top tickmarks
   gsres1@gsnXYFillOpacities    = 0.15
   gsres1@xyLineColors          = (/-1,-1/)
   gsres1@gsnXYFillColors       = colors(0)                ; color chosen
   str1 = unique_string("tmp1")
   dum(iv,0)   = gsn_csm_xy (wks,time,pltdat(0,1:2,:),gsres1)
   overlay(plot(iv),dum(iv,0))
   str2 = unique_string("tmp2")
   gsres1@gsnXYFillColors       = colors(1)                ; color chosen
   dum(iv,1)   = gsn_csm_xy (wks,time,pltdat(1,1:2,:),gsres1)
   overlay(plot(iv),dum(iv,1))
   str3 = unique_string("tmp3")
   gsres1@gsnXYFillColors       = colors(2)                ; color chosen
   dum(iv,2)  = gsn_csm_xy (wks,time,pltdat(2,1:2,:),gsres1)
   overlay(plot(iv),dum(iv,2))

;Attach manual legend
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
   lgres@lgPerimThicknessF  = 1.0

   lgres1 = lgres
   lgres1@vpWidthF           = 0.25           ; width of legend (NDC)
   lgres1@vpHeightF          = 0.12           ; height of legend (NDC)
   lgres1@lgLineColors       = colors(:) ;(/"Black","Black","Black"/)
   lgres1@lgDashIndexes      = dashind(:)
   lgres1@lgLineThicknesses  = lnthick(:)
   lgres1@lgMarkerColors     = colors(:)
   lgres1@lgMarkerIndexes    = markers(:)
   lgres1@lgMarkerThicknesses= mkthick(:)
   label1  = "  " +labels
   legend1 = gsn_create_legend (wks,dimsizes(label1), label1,lgres1)

   if(iv.le.1)then
     amres                  = True
     amres@amJust           = "BottomRight"
     amres@amParallelPosF   =  0.45
     amres@amOrthogonalPosF =  0.46
   else
     amres                  = True
     amres@amJust           = "TopRight"
     amres@amParallelPosF   =  0.45
     amres@amOrthogonalPosF = -0.46
   end if
   annoid1 = gsn_add_annotation(plot(iv),legend1,amres)  ; add legend to the top figure

 end do       ; end of looping over variables

   pres                              = True        ; panel plot mods desired
   pres@gsnMaximize                  = False       ; fill the page
   pres@txFontHeightF                = FontHeightF
   pres@txFontThicknessF             = 2.
  ;pres@gsnPanelXWhiteSpacePercent   = 2.
  ;pres@gsnPanelYWhiteSpacePercent   = 5.
  ;pres@txString                     = "" ;"("+seasons(kk)+")"  
   pres@gsnPanelYF                   = (/0.95,0.64,0.33/)
   gsn_panel(wks,plot(:),(/3,1/),pres)

   delete([/res,pres,wks/])

end
