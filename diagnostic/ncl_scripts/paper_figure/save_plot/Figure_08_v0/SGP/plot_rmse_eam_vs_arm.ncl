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

  arm_site   = "SGP"
  data_file  = "./Profile_6h_Plev_EAM_vs_ARM_"+arm_site+"_DAT.nc"
  varnam    = (/"T","RH","U","V"/)
  vardes    = (/"Temperature", "Relative humidity","Zonal wind", "Meridional wind"/)
  varunt    = (/"~S~o~N~C","%","m s~S~-1~N~", "m s~S~-1~N~"/)
  nvars     = dimsizes(varnam)
  
  fignum    = (/"e","f","g","h"/)
  plot      = new (nvars,graphic)
  grp_num   = (/0,1,2,3,4,5,6,7/)
  
  fobs      = addfile(data_file,"r")
  time      = fobs->time
  plev      = fobs->lev
  groups    = fobs->group
  ngrps     = dimsizes(groups)
  
  labels    = " "+groups(1:)

  do iv    = 0,nvars-1,1

    leftstring = "("+fignum(iv)+") "+vardes(iv)+" correlation" 

    varnm   = varnam(iv)+"_"+arm_site
    var1    =  fobs->$varnm$ 
    ;;;calculate the rmse beween ARM and E3SM
    printVarSummary(var1)
    corr    = var1(1:,0,:)
    do igp  = 1,ngrps-1
     corr(igp-1,:)   = dim_rmsd_n(var1(igp,:,:),var1(0,:,:),0) 
    end do 
    ;printVarSummary(corr)
   
   ;************************************************
   ; plotting section
   ;************************************************

    plotname  = "fig_rmse_ARM_"+arm_site+"_vs_E3SM"
    wtype     = "pdf"

    print("plotname : " + plotname + ".pdf" )

    if(iv.eq.0)then 
     wks       = gsn_open_wks(wtype,plotname)
    end if 

    gsn_define_colormap(wks,"cb_9step")
    colors    = (/1,13,2,28,3,38,13,2,28,3,38/)
    lthick    = (/3.0,3.0,3.0,3.0,3.0,3.0,3.0,3.0/)/1.5
    ldash     = (/0,2,2,2,2,2,0,0,0,0,0,0/)

    marker    = (/4,16,16,16,16,16,4,4,4,4,4/)
    mksize    = (/0.012,0.01,0.01,0.01,0.01,0.01,0.012,0.012,0.012,0.012,0.012/)*1.2
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
      res@lgLabelFontHeightF     = FontHeight/1.2                  ; change font height
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

    res@tmBorderThicknessF    = lthick/2.0
    res@tmXBMajorThicknessF   = lthick/2.0
    res@tmYLMajorThicknessF   = lthick/2.0
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

    res@gsnXRefLine              = (/0./)      ; four X reference lines
    res@gsnXRefLineColors        = (/"Black"/)
    res@gsnXRefLineDashPatterns  = (/2/)
    res@gsnXRefLineThicknesses   = (/1/)

    res@trYMaxF                  = 1000.0
    res@trYMinF                  = 50.0

  ;  if(varnam(iv).eq."U")then 
  ;    res@trXMinF                  = -0.6  ;max(abs(corr)) + max(abs(corr))/10.0
  ;    res@trXMaxF                  =  1.2   ;- max(abs(corr)) - max(abs(corr))/10.0
  ;  end if 
;
;    if(varnam(iv).eq."V")then 
;      res@trXMinF                  = -0.6 ;max(abs(corr)) + max(abs(corr))/10.0
;      res@trXMaxF                  =  1.2  ;- max(abs(corr)) - max(abs(corr))/10.0
;    end if
;
;    if(varnam(iv).eq."T")then 
;      res@trXMinF                  = -0.6  ;max(abs(corr)) + max(abs(corr))/10.0
;      res@trXMaxF                  =  1.2   ;- max(abs(corr)) - max(abs(corr))/10.0
;    end if
;
;    if(varnam(iv).eq."RH")then 
 ;;     res@trXMinF                  = -0.6  ;max(abs(corr)) + max(abs(corr))/10.0
 ;     res@trXMaxF                  =  1.2  ;- max(abs(corr)) - max(abs(corr))/10.0
 ;   end if


    res@tmYLMode          = "Explicit"                ; explicit labels
    res@tmYLValues        = (/1000, 900, 800, 700, 600, 500, 400, 300, 200, 100/)
    res@tmYLLabels        = ""+res@tmYLValues         ; make strings

    ;res@tmXBMode          = "Explicit"                ; explicit labels
    ;res@tmXBValues        = fspan(res@trXMinF,res@trXMaxF,7) 
    ;res@tmXBLabels        = ""+sprintf("%3.2f",res@tmXBValues)

    res@xyMarkLineMode         = "MarkLines"               ; Markers *and* lines
    res@xyMarkers              = marker              ; 3 different markers
    res@xyMarkerSizes          = mksize
    res@xyMarkerColors         = colors
    res@xyMarkerThicknesses    = mkthick
    res@xyLineThicknesses      = lthick
    res@xyLineColors           = colors
    res@xyDashPatterns         = ldash 
    res@tiYAxisString          = "Pressure (hPa)" 
    res@tiXAxisString          = "Correlation"
    res@gsnLeftString          = leftstring ;vardes(iv)+" (" + varnam(iv)+")"
    res@tiMainString           = "" 
    res@gsnRightString         = ""

   ;;;;;;;generate labels for the plot;;;;;;;;;
    res@xyExplicitLegendLabels = "  "+labels
    plot(iv) = gsn_csm_xy (wks, corr, plev, res)

    end do 

;---Draw both plots in a panel
    pnres                    = True
    pnres@gsnMaximize        = False
    pnres@gsnPanelMainString = " " 
    pnres@gsnPanelMainFontColor   = "Black"
    pnres@gsnPanelMainFontHeightF = 0.028
;   pnres@gsnPanelBottom     = 0.05
    gsn_panel(wks,(/plot/),(/1,4/),pnres)

end
