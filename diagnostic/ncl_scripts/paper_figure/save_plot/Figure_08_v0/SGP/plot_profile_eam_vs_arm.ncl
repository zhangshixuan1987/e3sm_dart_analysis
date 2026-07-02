;=======================================================
; arm_2.ncl
;=======================================================
;
; These files are loaded by default in NCL V6.2.0 and newer
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
; load "./contributed.ncl"

begin

  data_dir  = "./"
  arm_site  = "SGP"
  case      = (/"ARM-"+arm_site, "ERI_ANL", "ER5_ANL", "NGEI_UV6", "NGEI_UVT6", \
                       "NGE5_UV6", "NGE5_UVT6", "NGE5_UVT3", "NGE5_UVT1" /)
  ncases    = dimsizes(case)

  labels    = "  " + case
  nlabs     = dimsizes(labels)

  filenam   = "Profile_EAM_vs_ARM_"+arm_site+"_20100102_112100.nc"

  varnam    = (/"T","RH","U","V"/)
  varstr    = (/"T","RH","U","V"/)
  vardes    = (/"Temperature", "Relative humidity", "Zonal wind", "Meridional wind"/)
  varunt    = (/"~S~o~N~C","%","m s~S~-1~N~", "m s~S~-1~N~"/)
  nvars     = dimsizes(varnam)
 
  fignum    = (/"a","b","c","d"/)
  plot      = new (nvars,graphic)
  tmp       = new(nvars,graphic)

  fobs      = addfile(data_dir+filenam,"r")

  
  do iv    = 0,nvars-1,1

    leftstring = "("+fignum(iv)+") "+vardes(iv)+" profile"

    levnm  = str_lower(varnam(iv))+"lev"
    if(varnam(iv).eq."RH")then
     levnm = "qlev"
    end if 
    pres   = fobs->$levnm$
    nlevs  = dimsizes(pres)
    
    var1   = new((/ncases,nlevs/),double)
    var1@_FillValue = -9999.

    do icas = 0,ncases-1
      varnm  = varnam(iv) + "_"+case(icas)
      var1(icas,:) = fobs->$varnm$
    end do 

    presel = (/1000, 900, 800, 700, 600, 500, 400, 300, 200, 100, 0/)
    indlev = ind_nearest_coord(presel,pres,0)

   ;************************************************
   ; plotting parameters
   ;************************************************

    plotname  = "fig_profile_ARM_"+arm_site+"_vs_E3SM"
    wtype     = "pdf"

    print("plotname : " + plotname + ".pdf" )

    if(iv.eq.0)then
     wks       = gsn_open_wks(wtype,plotname)
    end if

    gsn_define_colormap(wks,"cb_9step")
    colors    = (/75,1,1,13,2,13,2,28,3/)
    lthick    = (/4.0,2.0,3.0,2.0,2.0,3.0,3.0,3.0,3.0/)
    ldash     = (/  0,  2,  0,  2,  2,  0,0,0,0/)

    marker    = (/4,16,4,4,16,16,16,16,16,16/)
    mksize    = (/0.012,0.01,0.012,0.012,0.01,0.01,0.01,0.012,0.01,0.012,0.01/) ;*1.2
    mkthick   = lthick

    ;---Resources to share between both plots
    res                      = True              ; Plot modes desired.
    res@gsnDraw              = False
    res@gsnFrame             = False
    res@gsnMaximize          = True              ; Maximize plot

    FontHeight = 0.028
    res@gsnStringFontHeightF = FontHeight*1.2
    res@tmXBLabelFontHeightF = FontHeight
    res@tmYLLabelFontHeightF = FontHeight
    res@tmYRLabelFontHeightF = FontHeight
    res@tiMainFontHeightF    = FontHeight
    res@tiXAxisFontHeightF   = FontHeight*1.2
    res@tiYAxisFontHeightF   = FontHeight*1.2
    res@trYReverse           = True                       ; reverse Y-axis

  ; add a legend
    if(iv.eq.0)then
      res@pmLegendDisplayMode    = "Always"              ; turn on legend
      res@pmLegendSide           = "Top"                 ; Change location of
      res@pmLegendParallelPosF   =  0.26                   ; move units right
      res@pmLegendOrthogonalPosF = -1.15                  ; more neg = down
      res@pmLegendWidthF         = 0.12                  ; Change width and
      res@pmLegendHeightF        = 0.34                  ; height of legend.
      res@lgLabelFontHeightF     = FontHeight/1.2        ; change font height
      res@lgPerimOn              = True                ; no box around
      res@lgBoxBackground        = "White"
      res@lgPerimFillColor       = "White"
      res@lgPerimFill            = 0
      res@lgPerimColor           = "White"
    else
      res@pmLegendDisplayMode    = "Never"
    end if

    res@tmXTOn               = False
    res@tmYROn               = False
   ;res@tmYLPrecision        = 2        ; set the precision to 2 significant digits
   ;res@tmYLFormat           = "#0^se"   ; don't use "e" symbol, always show +/-
   ;res@xyComputeYMin        = True

    res@tmBorderThicknessF    = lthick/3.0
    res@tmXBMajorThicknessF   = lthick/3.0
    res@tmYLMajorThicknessF   = lthick/3.0
    res@tmXBMinorThicknessF   = res@tmXBMajorThicknessF/2.0
    res@tmYLMinorThicknessF   = res@tmYLMajorThicknessF/2.0

    res@tmXMajorGrid         = False
    res@tmYMajorGrid         = False
 ;  res@tmXMinorGrid         = False
 ;  res@tmYMinorGrid         = False
    gridthickness = 0.5
    res@tmXMinorGridThicknessF = gridthickness
    res@tmYMinorGridThicknessF = gridthickness
    res@tmXMajorGridThicknessF = gridthickness
    res@tmYMajorGridThicknessF = gridthickness
    griddash = 2
    res@tmXMajorGridLineDashPattern = griddash
    res@tmYMajorGridLineDashPattern = griddash

    res@trYMaxF           = 1000.0
    res@trYMinF           = 0.0
    res@trXMaxF           = max(var1)+max(abs(var1))/10.0
    res@trXMinF           = min(var1)-max(abs(var1))/10.0

    if(varstr(iv).eq."U")then
      res@trXMaxF                  =  50.0   ;max(abs(corr)) + max(abs(corr))/10.0
      res@trXMinF                  = -10.0   ;- max(abs(corr)) - max(abs(corr))/10.0
    end if

    if(varstr(iv).eq."V")then
      res@trXMaxF                  =   9.0  ;max(abs(corr)) + max(abs(corr))/10.0
      res@trXMinF                  = -12.0  ;- max(abs(corr)) - max(abs(corr))/10.0
    end if

    if(varstr(iv).eq."T")then
      res@trXMinF                  = -71.0  ;max(abs(corr)) + max(abs(corr))/10.0
      res@trXMaxF                  =   7.0   ;- max(abs(corr)) - max(abs(corr))/10.0
    end if

    if(varstr(iv).eq."RH")then
      res@trXMinF                  =  0.0  ;max(abs(corr)) + max(abs(corr))/10.0
      res@trXMaxF                  = 120.0  ;- max(abs(corr)) - max(abs(corr))/10.0
    end if

    res@tmYLMode          = "Explicit"                ; explicit labels
    res@tmYLValues        = presel
    res@tmYLLabels        = ""+res@tmYLValues         ; make strings

    res@tmXBMode          = "Explicit"                ; explicit labels
    res@tmXBValues        = fspan(res@trXMinF,res@trXMaxF,7)
    res@tmXBLabels        = ""+sprintf("%3.1f",res@tmXBValues)

    res1 = res
    res1@xyMarkLineMode         = "Lines" ;"MarkLines"               ; Markers *and* lines
    res1@xyMarkers              = marker              ; 3 different markers
    res1@xyMarkerSizes          = mksize
    res1@xyMarkerColors         = colors
    res1@xyMarkerThicknesses    = mkthick
    res1@xyLineThicknesses      = lthick
    res1@xyLineColors           = colors
    res1@xyDashPatterns         = ldash
    res1@tiYAxisString          = "Pressure (hPa)"
    res1@tiXAxisString          = varstr(iv)+" (" + varunt(iv)+")"
    res1@gsnLeftString          = leftstring 
    res1@tiMainString           = ""
    res1@gsnRightString         = ""

   ;;;;;;;generate labels for the plot;;;;;;;;;
    res1@xyExplicitLegendLabels = labels
    plot(iv) = gsn_csm_xy (wks, var1, pres, res1)

    res2 = res
    res2@pmLegendDisplayMode    = "Never"
    res2@xyMarkLineMode         = "Markers" ;"MarkLines"               ; Markers *and* lines
    res2@xyMarkers              = marker              ; 3 different markers
    res2@xyMarkerSizes          = mksize
    res2@xyMarkerColors         = colors
    res2@xyMarkerThicknesses    = mkthick
    res2@tiYAxisString          = ""
    res2@tiXAxisString          = ""
    res2@gsnLeftString          = ""
    res2@tiMainString           = ""
    res2@gsnRightString         = ""
   ;tmp(iv) = gsn_csm_xy (wks, var1(:,indlev), pres(indlev), res2)
   ;overlay(plot(iv),tmp(iv))
    delete([/indlev/]) 
    delete([/var1,pres/])

   end do ; end of variable loop

;---Draw both plots in a panel
    pnres                    = True
    pnres@gsnMaximize        = False
    pnres@gsnPanelMainString = " " 
    pnres@gsnPanelMainFontColor   = "Black"
    pnres@gsnPanelMainFontHeightF = 0.028
;   pnres@gsnPanelBottom     = 0.05
    gsn_panel(wks,(/plot/),(/1,nvars/),pnres)
end
