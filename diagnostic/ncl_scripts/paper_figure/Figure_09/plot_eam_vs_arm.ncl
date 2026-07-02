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

  arm_site   = "TWP"
  data_file  = "./Profile_6h_Plev_EAM_vs_ARM_"+arm_site+"_DAT.nc"
  varnam    = (/"T","RH","U","V"/)
  vardes    = (/"Temperature", "Relative humidity","Zonal wind", "Meridional wind"/)
  varunt    = (/"~S~o~N~C","%","m s~S~-1~N~", "m s~S~-1~N~"/)
  nvars     = dimsizes(varnam)

  minlev1   = (/0.0,  0.0, 0.0, 0.0/)
  maxlev1   = (/5.0, 90.0,10.0,10.0/)

  minlev2   = (/-0.3,  -0.3,  0.0, -0.3/)
  maxlev2   = (/ 1.2,   1.2,  1.2,  1.2/)

  fignum1   = (/"a","b","c","d"/)
  fignum2   = (/"e","f","g","h"/)
  plot1     = new (nvars,graphic)
  plot2     = new (nvars,graphic)
  grp_num   = (/0,1,2,3,4,5,6,7/)
  
  fobs      = addfile(data_file,"r")
  time      = fobs->time
  plev      = fobs->lev
  groups    = fobs->group
  ngrps     = dimsizes(groups)
  
  labels    = "   "+(/"ERA5", "hybrid IC (day 1)", "hybrid IC (day 2)", \
                    "hybrid IC (day 3)", "hybrid IC (day 4)", "hybrid IC (day 5)", \
                    "EAM/DART (day 1)", "EAM/DART (day 2)", "EAM/DART (day 3)", \
                    "EAM/DART (day 4)", "EAM/DART (day 5)" /)

  do iv    = 0,nvars-1,1

    varnm   = varnam(iv)+"_"+arm_site
    var1    =  fobs->$varnm$ 

    ;;;calculate RMSE;;;;
    rmsd    = var1(1:,0,:)
    do igp = 1,ngrps-1
     rmsd(igp-1,:) = dim_rmsd_n(var1(igp,:,:),var1(0,:,:),0)
    end do
    
    ;;;calculate the correlation
    ;corr   = var1(1:,0,:)
    ;do igp = 1,ngrps-1
    ; corr(igp-1,:) = escorc_n(var1(igp,:,:),var1(0,:,:),0,0)
    ;end do

    ;;;calculate the anomaly with respect to ARM;;; 
    vanm   = var1 - conform(var1,dim_avg_n(var1(0,:,:),0),(/2/))
    corr   = vanm(1:,0,:)
    do igp = 1,ngrps-1
      nsamp = dimsizes(vanm(0,:,0))-1
      covar = dim_sum_n(vanm(igp,:,:)*vanm(0,:,:),0)
      std1  = dim_sum_n(vanm(igp,:,:)^2,0)
      std2  = dim_sum_n(vanm(0,:,:)^2,0)
      corr(igp-1,:) = covar/sqrt(std1*std2) ;/nsamp
    end do 
   ;printVarSummary(corr)
   
   ;************************************************
   ; plotting section
   ;************************************************

    plotname  = "Fig09"
    wtype     = "pdf"

    print("plotname : " + plotname + ".pdf" )

    if(iv.eq.0)then 
     wks       = gsn_open_wks(wtype,plotname)
    end if 

    gsn_define_colormap(wks,"cb_9step")
    colors    = (/1,2,13,28,3,38,2,13,28,3,38/)
    lthick    = (/3,3,3,3,3,3,3,3,3,3,3,3/)/2.0
    ldash     = (/0,2,2,2,2,2,0,0,0,0,0/)
    marker    = (/16,4,4,4,4,4,16,16,16,16,16/)
    mksize    = (/0.01,0.014,0.014,0.014,0.014,0.014,0.01,0.01,0.01,0.01,0.01/) *1.2
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
    res@pmLegendDisplayMode    = "Never" ;"Always"              ; turn on legend
    res@pmLegendSide           = "Top"                 ; Change location of
    res@pmLegendParallelPosF   =  1.25                   ; move units right
    res@pmLegendOrthogonalPosF = -1.15                  ; more neg = down
    res@pmLegendWidthF         = 0.30                  ; Change width and
    res@pmLegendHeightF        = 0.80                  ; height of legend.
    res@lgLabelFontHeightF     = FontHeight/1.2                  ; change font height
    res@lgPerimOn              = True                ; no box around
    res@lgBoxBackground        = "White"
    res@lgPerimFillColor       = "White"
    res@lgPerimFill            = 0
    res@lgPerimColor           = "White"

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

    res@gsnXRefLine              = (/999./)      ; four X reference lines
    res@gsnXRefLineColors        = (/"Black"/)
    res@gsnXRefLineDashPatterns  = (/2/)
    res@gsnXRefLineThicknesses   = (/1/)

    res@trYMaxF                  = 1000.0
    res@trYMinF                  = 50.0

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
    res@tiMainString           = "" 
    res@gsnRightString         = ""
    res@xyExplicitLegendLabels := "  "+labels

    res1 = res
    res1@gsnLeftString          = "" ;leftstring1 
    res1@tiXAxisString          = "RMSE in "+varnam(iv)+" ("+varunt(iv)+")"
    res1@trXMinF                = minlev1(iv) 
    res1@trXMaxF                = maxlev1(iv)
    plot1(iv) = gsn_csm_xy (wks, rmsd, plev, res1)

    res2 = res
    res2@gsnLeftString          = "" ;leftstring2 
    res2@tiXAxisString          = "Correlation in "+ varnam(iv) + " (unitless)" 
    res2@trXMinF                = minlev2(iv)  
    res2@trXMaxF                = maxlev2(iv)
    plot2(iv) = gsn_csm_xy (wks, corr, plev, res2)

   ;;;;;;;generate labels for the plot;;;;;;;;;
    txres                       = True
    txres@txPerimOn             = False
    txres@txFontHeightF         = FontHeight*1.5
    ;---Top right string
    amres_tr                  = True
    amres_tr@amParallelPosF   =  0.45    ; This is the right edge of the plot.
    amres_tr@amOrthogonalPosF = -0.47    ; This is the top edge of the plot.
    amres_tr@amJust           = "TopRight"
    if(iv.eq.1)then 
      amres_tr@amParallelPosF   = -0.45    ; This is the right edge of the plot.
      amres_tr@amOrthogonalPosF = -0.47    ; This is the top edge of the plot.
      amres_tr@amJust           = "TopLeft"
    end if 
    tr_label1 =  "("+fignum1(iv)+")"
    txid_tr1  = gsn_create_text(wks, tr_label1, txres)
    str1  = unique_string("txt")
    plot1@$str1$ = gsn_add_annotation(plot1(iv), txid_tr1, amres_tr)

    amres_tr                  = True
    amres_tr@amParallelPosF   = -0.45    ; This is the right edge of the plot.
    amres_tr@amOrthogonalPosF = -0.45    ; This is the top edge of the plot.
    amres_tr@amJust           = "TopLeft"
    if (iv.eq.1)then 
      amres_tr@amParallelPosF   =  0.45    ; This is the right edge of the plot.
      amres_tr@amOrthogonalPosF = -0.47    ; This is the top edge of the plot.
      amres_tr@amJust           = "TopRight"
    end if 
    tr_label2 =  "("+fignum2(iv)+")"
    txid_tr2  = gsn_create_text(wks, tr_label2, txres)
    str2  = unique_string("txt")
    plot2@$str2$ = gsn_add_annotation(plot2(iv), txid_tr2, amres_tr)

    end do 

;---Draw both plots in a panel
    pnres                    = True
    pnres@gsnFrame           = False                ; don't advance frame yet
    pnres@gsnMaximize        = False
    pnres@gsnPanelMainString = " " 
    pnres@gsnPanelMainFontColor   = "Black"
    pnres@gsnPanelMainFontHeightF = 0.028
    pnres@gsnPanelRight      = 0.85
   ;pnres@gsnPanelBottom     = 0.05
   ;pnres@gsnPanelXF     = (/0.08,0.33,0.58,0.78/)
   ;pnres@gsnPanelYF     = (/0.35,0.35,0.35,0.30/)
    tmpplt = new(nvars*2,graphic)
    tmpplt(0:nvars-1) = plot1
    tmpplt(nvars:)    = plot2
    gsn_panel(wks,(/tmpplt/),(/2,4/),pnres)


   ;***********************************************
   ; legend resources
   ;***********************************************
    lgres                    = True
    lgres@vpWidthF           = 0.20                   ; width of legend (NDC)
    lgres@vpHeightF          = 0.30                   ; height of legend (NDC)
    lgres@lgBoxMajorExtentF  = 0.3
    lgres@lgBoxMinorExtentF  = 0.2
    lgres@lgMonoLineThickness = True
    lgres@lgMonoMarkerSize    = True
    lgres@lgLineColors       = colors
    lgres@lgItemType         = "MarkLines"
    lgres@lgPerimOn          = False                 ; turn off perimeter
    lgres@lgLineDashSegLenF  = 0.2
    lgres@lgMarkerIndexes    = marker              ; 3 different markers
    lgres@lgMarkerSizeF      = 0.006
    lgres@lgMarkerColors     = colors
    lgres@lgMarkerThicknessF = 1.5 
    lgres@lgLineThicknessF   = 2.0
    lgres@lgLineColors       = colors
    lgres@lgDashIndexes      = ldash
    lgres@lgLabelFontHeightF = FontHeight*1.2               ; change font height

   ;**************************************************************
   ; Draw the legend, indicating the number of items, a label for each
   ; item, and the X, Y position of the legend in NDC coordinates.
   ;**************************************************************
     gsn_legend_ndc(wks,dimsizes(labels),labels,0.85,0.6,lgres)
     frame(wks)      

end
