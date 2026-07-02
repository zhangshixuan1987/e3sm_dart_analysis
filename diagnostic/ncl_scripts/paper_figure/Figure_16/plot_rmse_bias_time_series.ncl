;*************************************************
; histo_4.ncl
;
; Concepts illustrated:
;   - Drawing a histogram using exact min/max of data
;   - Generating dummy data using "rand"
;   - Drawing X axis labels at a 45 degree angle
;
;************************************************
;
; This file is loaded by default in NCL V6.2.0 and newer
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
;************************************************

load "./function_read_dart_diag.ncl"

begin

  l_create_plot_data = True

  Casename     = (/"EAMv0_EDAUVTQ_EN80_15d","EAMv0_EDAUVTQ_EN20_15d"/)
  Expname      = (/"EAMv0-EDA80",           "EAMv0-EDA20"/)
  ModelOutRoot = "/pic/projects/E3SM_DA/zhan391/dart_paper_materials/DATA/dart_obs_spaced_diag/"
  ncases       = dimsizes(Casename)

  regions   = (/"Global"/) 
  nregs     = dimsizes(regions)

  labels    = (/"Total spread", "RMSE", "Rejection rate"/)
  nlabs     = dimsizes(labels)
  
  time_unit   = "days since 2010-12-01 00:00:00"
  time_string = "Days since 0000 UTC 01 December 2010"
 
  nday      = 18; only plot first 15 days
  plev      = 850.0 ; only plot 850hPa data

  ;;;read the variable information;;
  fvar     = "./variable_name.info" 
  data     = asciiread(fvar,-1,"string")
  VarName  = str_squeeze(str_get_field(data, 1," "))
  nvars    = dimsizes(VarName)

  nvar     = 3 ; variable to be plotted: totalspread,rmse and data rejection rate 
  pltdat   = new((/ncases,nvar,nday*4+1/),double)
  pltdat@_FillValue = -999.0

  do iv = 0,nvars-1,1

  ObsTypeString = VarName(iv)

  if(l_create_plot_data)then 

    do irg = 0,ncases-1,1

    fname    = ModelOutRoot+Casename(irg)+"/obs_diag_output_6hourly_mean_201012.nc"
    region   = regions
    type     = "guess"
   
    CopyString1 = "totalspread" 
    tspread = read_dart_diag_netcdf(fname, CopyString1, ObsTypeString, region, type)
 
    CopyString2 = "rmse"
    rmse  = read_dart_diag_netcdf(fname, CopyString2, ObsTypeString, region, type)

    CopyString3 = "Nposs"
    Nposs = read_dart_diag_netcdf(fname, CopyString3, ObsTypeString, region, type)

    CopyString4 = "Nused"
    Nused = read_dart_diag_netcdf(fname, CopyString4, ObsTypeString, region, type)

    if(rmse@lev_unit .eq."hPa") then
     indlev     = ind(rmse@lev.eq.plev)
    else 
     indlev     = ind(rmse@lev.eq.plev*100.0)
    end if 

    pltlev       = rmse@lev(indlev)
    pltlev@units = rmse@lev_unit
    pltlev@range = rmse@levp(indlev)+"-"+rmse@lev(indlev+1)
    pltlev!0     = "lev"

    time       = rmse@time
    time@units = rmse@time_unit
    time       = cd_convert(time, time_unit)
    indtim     = ind(time.le.nday)
    plttim     = (/time(indtim)/)
    plttim!0   = "time"

    pltdat(irg,0,:)   = (/tspread(indtim,indlev)/)
    pltdat(irg,1,:)   = (/rmse(indtim,indlev)/)
    tmpdat            = Nposs(indtim,indlev)
    tmpdat            = where(Nposs(indtim,indlev).eq.0.0,-999,Nposs(indtim,indlev))
    tmpdat@_FillValue = -999
    pltdat(irg,2,:)   = 100.0 - Nused(indtim,indlev)*100.0 /tmpdat
    delete([/tmpdat,indtim/])

    end do

    pltdat!0  = "ncases"
    pltdat!1  = "nvar"
    pltdat!2  = "time"
    
    ;;save the plot data;;;;;
    ff  = ""+ObsTypeString+".nc"
    system("rm -f " + ff)
 
    print(" ")
    print("output : " + ff)
    print(" ")
 
    flo = addfile(ff,"c")
    flo->date          = plttim
    flo->date@units    = time_unit
    flo->plev          = pltlev
    flo->plev@units    = pltlev@units 
    flo->ObsTypeString = pltdat
    
    ObsTypeString = VarName(iv)
    ff     = ObsTypeString+".nc"
    fno    = addfile(ff,"r")
    pltdat = fno->ObsTypeString
    plttim = fno->date
    pltlev = fno->plev

   else

    ObsTypeString = VarName(iv)
    ff     = ObsTypeString+".nc"
    fno    = addfile(ff,"r")
    pltdat = fno->ObsTypeString
    plttim = fno->date
    pltlev = fno->plev  

   end if 

  ;;start to do the plot ;;;;;
  plot = new(ncases,graphic)

  plot_name = "Fig16"

  print(" ")
  print("plot figure : " + plot_name+".pdf")
  print(" ")
  
  wtype = "pdf"
  wks = gsn_open_wks(wtype,plot_name)             ; send graphics to PNG file

  gsn_define_colormap(wks,"cb_9step")
  colors  = (/2,28,14/)
  markers = (/16, 4, 7/)
  mkszf   = (/0.9, 1.0, 1.0/)
  dashind = (/0,0,0/)       ;;line dash pattern
  mkthick = (/2,3,3/)
  lnthick = (/3,3,3/) ;*1.5   ;;line thichness

  ;left_string  = (/"(a) ","(b) ", "(c) "/) +Expname

  labelL       = labels(0:1)
  labelR       = labels(2)
  ystrL        = "RMSE and total spread"
  ystrR        = "Obs. rejection rate (%)"
  ymaxL        = (/4.0,  4.0,  4.0/)
  yminL        = (/0.0,  0.0,  0.0/)
  ymaxR        = (/80.0, 80.0, 80.0/)
  yminR        = (/0.0,  0.0,  0.0/)
  
  ;---Resources to share between both plots
  res          = True                   ; plot mods desired
  res@vpHeightF = 0.35
  res@vpWidthF =  0.9
  res@gsnDraw  = False
  res@gsnFrame = False

  FontHeight = 0.022
  res@gsnStringFontHeightF = FontHeight
  res@tmXBLabelFontHeightF = FontHeight
  res@tmYLLabelFontHeightF = FontHeight
  res@tmYRLabelFontHeightF = FontHeight
  res@tiMainFontHeightF    = FontHeight
  res@tiXAxisFontHeightF   = FontHeight
  res@tiYAxisFontHeightF   = FontHeight

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
  res@lgLabelFontHeightF     = FontHeight*0.95       ; change font height
  res@lgPerimOn              = False                 ; no box around
  
  res@trYReverse        = False                      ; reverse Y-axis
 ;res@xyYStyle          = "Log"

  res@tmXTOn  = False
  res@gsnYRefLine             = (/0./)      ; four X reference lines
  res@gsnYRefLineThicknesses  = 1.0
  res@gsnYRefLineDashPatterns = 0
  res@gsnYRefLineColors       = "Grey"

  res@gsnRightString  = ""   ;VstList(0)
  res@gsnLeftString   = ""   ;Groups(0)
  res@gsnCenterString = ""   ;fig_label
  res@gsnRightStringOrthogonalPosF  = 0.02
  res@gsnLeftStringOrthogonalPosF   = 0.02
  res@gsnCenterStringOrthogonalPosF = 0.02

  res@tiMainString         = "" 
  res@tiMainOffsetYF       = 0.02
  res@tiMainFontThicknessF = 3.0

  res@tiXAxisString        = "" 
 ;res@tiXAxisOffsetYF      = -0.015

  res@trXMaxF         = nday+0.5
  res@trXMinF         = 0
  res@tmXBMode        = "Explicit"	
  res@tmXBValues      = ispan(0,nday,1) 
  res@tmXBLabels      = "" + res@tmXBValues 
  res@tmXBMinorValues = fspan(0,nday,2*nday+1)
  res@tmXBLabelsOn    = False
  res@tiXAxisString   = " "

  ;left axis
  resL  = res
  resL@tiYAxisString          := ystrL
  resL@xyMarkLineMode         := "MarkLines"
  resL@xyLineColors           := colors(0:1)
  resL@xyMarkers              := markers(0:1)
  resL@xyMarkerColors         := colors(0:1)
  resL@xyMarkerSizes          := 0.015*mkszf(0:1)
  resL@xyMarkerThicknesses    := mkthick
  resL@xyDashPatterns         := dashind(0:1)
  resL@xyLineThicknesses      := lnthick(0:1)
 
  ;;right axis
  resR                        = res
  resR@gsnRightString         := ""
  resR@gsnLeftString          := ""
  resR@tiXAxisString          := "" ;"Cloud (fraction)";
  resR@tiYAxisString          := ystrR
  resR@xyDashPatterns         := 2                   ; dashed line for 2nd
  resR@xyMarkLineMode         := "Markers" ;"MarkLines"
  resR@xyLineColors           := colors(2)
  resR@xyMarkers              := markers(2)
  resR@xyMarkerColors         := colors(2)
  resR@xyLineThicknesses      := mkthick
  resR@xyMarkerSizes          := 0.015*mkszf(2)
  resR@xyMarkerThicknesses    := lnthick(2)
  resR@tiYAxisFontColor        = colors(2)
  resR@tmYRLabelFontColor      = colors(2)

  do irg = 0,ncases-1,1

   if(irg.eq.2) then
     resL@tmXBLabelsOn            = True
     resL@tiXAxisString           = time_string
   else
     resL@tmXBLabelsOn            = False
     resL@tiXAxisString           = " "
   end if

   resL@gsnLeftString  = "" ;left_string(irg)
   resL@trYMaxF       := ymaxL(irg) ;0.21
   resL@trYMinF       := yminL(irg) ;0.0
   resR@trYMaxF       := ymaxR(irg) ;0.21
   resR@trYMinF       := yminR(irg) ;0.0

   resR@xyExplicitLegendLabels := "  "+labelR
   resR@pmLegendDisplayMode    := "Always" ;"Never"
   resR@pmLegendSide           := "Top"                 ; Change location of
   resR@pmLegendParallelPosF   := .80                   ; move units right
   resR@pmLegendOrthogonalPosF := -0.60   
   resL@xyExplicitLegendLabels := "  " +labelL
   resL@pmLegendDisplayMode    := "Always" ;"Never"
   resL@pmLegendSide           := "Top"                 ; Change location of
   resL@pmLegendParallelPosF   :=  0.45                   ; move units right
   resL@pmLegendOrthogonalPosF := -0.35                ; more neg = down
   plot(irg)  = gsn_csm_xy2 (wks,plttim,pltdat(irg,0:1,:),pltdat(irg,2,:),resL,resR)   ; create plot

  end do 
 
 end do 

;--Draw both plots in a panel
  pnres                         = True
  pnres@gsnMaximize             = False
  pnres@gsnPanelMainString      = " "
  pnres@gsnPanelMainFontColor   = "Black"
  pnres@gsnPanelMainFontHeightF = 0.020
  pnres@gsnPanelLabelBar        = False
  pnres@gsnPanelBottom          = 0.05
  pnres@gsnPanelYWhiteSpacePercent = 2
  pnres@gsnPanelYF = (/0.85,0.58,0.31/)+0.1    ; Adjust rightmost plots
  gsn_panel(wks,(/plot/),(/3,1/),pnres)
  delete([/pnres/])

end
