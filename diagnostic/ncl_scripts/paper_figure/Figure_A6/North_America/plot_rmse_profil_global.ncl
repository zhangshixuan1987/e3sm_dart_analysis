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
begin

  data_dir    = "./"

 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  Groups      = (/"ERA5_ANL_ENS01",\
                  "PDDART_UV_ENS80","PDDART_UVT_ENS80","PDDART_UVTQ_ENS80", \
                  "PDNUDG_UV_ENS01","PDNUDG_UVT_ENS01","PDNUDG_UVTQ_ENS01"/)
  ngrps       = dimsizes(Groups)

  region      = "Global"
  regind      = 0

  Ystring     = "Pressure (hPa)"
  MinY        = 5.0 ; top level

  label1      = (/"ERA5    ","EDA-UV","EDA_UVT","EDA-UVTQ"/)
  label2      = (/"ERA5    ","NDG-UV","NDG-UVT","NDG-UVTQ"/)
  
  xmin        = (/  0,    0,     0.0/)
  xmax        = (/  10.,  6.,    3.0/)
  xpos        = (/ 0.75,  0.75,  0.75/)
  ypos        = (/-1.05, -1.05, -0.75/)

  VarNameList = (/"U", "T", "Q" /)
  VarString   = (/"U", "T", "Q"/)
  UnitList    = (/"m s~S~-1~N~", "K", "g kg~S~-1~N~"/)
  nvars       = dimsizes(VarNameList)

  Leftstring1  = (/"(a) ", "(b) ", "(c) "/) + VarNameList
  Rightstring1 = "EAM/DART analysis"

  Leftstring2  = (/"(d) ", "(e) ", "(f) "/) + VarNameList
  Rightstring2 = "Nudged simulation"

  Leftstring3  = (/"(g) ", "(h) ", "(i) "/) + VarNameList
  Rightstring3 = "# of observations"

  plot = new(nvars*3,"graphic")
  dum1 = new(4,graphic)
  dum2 = new(4,graphic)
  dum3 = new(4,graphic)

  do iv  = 0,nvars-1,1

   do igp = 0,ngrps-1,1

    fnm   = data_dir + "RMSE_"+Groups(igp)+"_vs_obs_UTQ.nc"
    fln   = addfile(fnm,"r")
   
    plev  = fln->plev
    nlevs = dimsizes(plev)

    if(igp.eq.0)then
      pltdat = new((/3,ngrps,nlevs/),double)
    end if

    vnmobs = VarNameList(iv)+"_rmse"
    pltdat(0,igp,:) = fln->$vnmobs$(regind,:)

    vnmobs = VarNameList(iv)+"_std"
    pltdat(1,igp,:) = fln->$vnmobs$(regind,:)

    vnmobs = VarNameList(iv)+"_nobs"
    pltdat(2,igp,:) = fln->$vnmobs$(regind,:)

   end do 

   print(pltdat(2,0,:)+ " "+pltdat(2,1,:)+ "  "+pltdat(2,2,:))

   if(iv.eq.0)then 

   plotlabel = "Fig04"
   wtype = "pdf"
  ;wtype@wkWidth = 2500
  ;wtype@wkHeight = 2500
   wks = gsn_open_wks(wtype,plotlabel)             ; send graphics to PNG file
   load "./var_share_profile.ncl"
  end if 

;----------------------------------------------------------------------
; Plotting section
;---Resources to share between both plots

  res               = True           ; plot mods desired
  res@vpXF          = 0.25
  res@vpYF          = 0.8
  res@vpWidthF      = 0.4                      ; set width of plot
  res@vpHeightF     = 1.0                      ; set height of plot
  res@gsnDraw       = False
  res@gsnFrame      = False

  res@tmYROn = False            ; Turn off right tickmarks.
  res@tmXTOn = False            ; Turn off top tickmarks
  FontHeight = 0.028

  res@gsnStringFontHeightF  = FontHeight
  res@tmXBLabelFontHeightF  = FontHeight
  res@tmYLLabelFontHeightF  = FontHeight
  res@tmYRLabelFontHeightF  = FontHeight
  res@tiMainFontHeightF     = FontHeight
  res@tiXAxisFontHeightF    = FontHeight
  res@tiYAxisFontHeightF    = FontHeight

  ;res@tiMainFontThicknessF  = 8.0
  ;res@tiYAxisFontThicknessF = 5.0
  ;res@tiXAxisFontThicknessF = 5.0

  res@tmBorderThicknessF    = 1.5 * 2.0
  res@tmXBMajorThicknessF   = 1.5 * 2.0
  res@tmXBMinorThicknessF   = res@tmXBMajorThicknessF/2.0

  ;res@gsnYRefLine           = 0.0             ; create a reference line
  ;res@gsnYRefLineDashPattern= 2
  ;res@gsnYRefLineColor      = "Black"
  ;res@gsnYRefLineThicknessF = 1.0

  res@tiMainString         = "";pltreg
  res@tiMainOffsetYF       = 0.02
  res@tiMainFontThicknessF = 3.0

  res@gsnLeftStringFontColor  = "Black"
  res@gsnRightStringFontColor = "Black"
  res@gsnRightString          = "" ;hindstr ;VstList(0)
  res@gsnLeftString           = "" ;Leftstring ;Groups(0)
  res@gsnCenterString         = "" ;regions(ireg)

  res@trYMinF                 = 0.1 ;min(latrgd)
  res@trYMaxF                 = 2*nlevs+1.5 ;max(latrgd)
  res@tmYLMode                = "Explicit"
  res@tmYLValues              = fspan(1.075,2*nlevs+.075,nlevs) ;ispan(1,nvars,1)
  res@tmYLMinorValues         = fspan(1.075,2*nlevs+.075,nlevs) ;ispan(1,nvars,1)
  res@tmYLLabels              = plev
 ;res@tmYLLabelDirection      = "Across"
 ;res@tmYLLabelAngleF         = 90.0
 ;res@tmYLLabelJust           = "CenterRight"

  res@tmYMajorGrid            = False        ; Add horizontal grid lines
  res@tmYMinorGrid            = False
  res@tmYMajorGridLineColor   = "LightGrey"
  res@tmYMinorGridLineColor   = "White"
  res@tmYMajorGridLineDashPattern = 5
  res@tmYMinorGridLineDashPattern = 5
  res@tmYMajorGridThicknessF  = 1.0
  res@tmGridDrawOrder         = "draw"    ; new resource added in NCL V6.5.0

  res@gsnXYBarChart         = True ; create bar chart
  res@gsnXRefLine = 0.			; set the reference line equal to 0
  res@gsnXYBarChartOutlineThicknessF = 0.5;1.008
  res@gsnXYBarChartFillLineThicknessF = 1.0

  ;res@xyLineThicknessF     = 10.0            ; make thicker
  ;res@xyDashPatterns       = dashind(0:nvars)
  ;res@xyMarkerSizes        = 0.012
  ;res@xyLineColors         = colors(0:nvars)
  ;res@xyMarkers            = markers(0:nvars)
  ;res@xyMarkerColors       = colors(0:nvars)

  ;res@tmXTAutoPrecision    = False
  ;res@tmYLPrecision        =  2

 ; if(ireg.eq.0)then
    res@tmYLOn             = True            ; Turn off top tickmarks
    res@tiYAxisString      = Ystring
;  else
;    res@tmYLOn             = False           ; Turn off top tickmarks
;    res@tiYAxisString      = ""
;  end if 

;;;;;;;first figure for PD origional values;;;;;;;;;;;;;;;;;;;;
  res0                      = res
  res0@trXMaxF              = xmax(iv)
  res0@trXMinF              = xmin(iv)
  res0@tmXBOn               = True            ; Turn off top tickmarks
  res0@tmXBLabelsOn         = True            ; Turn off top tickmarks
  res0@tmXBMode             = "Explicit"
  res0@tmXBValues          := fspan(res0@trXMinF,res0@trXMaxF,5)
  res0@tmXBMinorValues     := fspan(res0@trXMinF,res0@trXMaxF,13)
  res0@tmXBLabels          := res0@tmXBValues  ;(/"-0.2","-0.1","0.0","0.1","0.2"/)
  res0@tiMainString         = ""
  res0@tiXAxisString        = "" ;Varstr + " ("+Varunt+")" ;
 ;res0@tiXAxisOffsetYF      = -0.015
  res0@gsnLeftString        = "" ;leftstring(0)
  res0@gsnLeftStringOrthogonalPosF = 0.04

  ;;;;First figure;;;; 
  do i = 0,3
    res0@xyLineColors              = lncolor(i)
    res0@gsnXYBarChartColors       = colors(i)  
    res0@gsnXYBarChartBarWidth     = barWidth(i)          ; change bar widths
    res0@gsnXYBarChartFillOpacityF = bopc(i)
    res0@gsnXYBarChartPatterns     = pattns(i)
    res0@gsnXYBarChartFillScaleF   = 0.5
    yy  = pltdat(0,i,:)
    xx  = fspan(.60,2*nlevs-0.4,nlevs) + i*0.38

    if(i.eq.0) then 
      plot(iv) = gsn_csm_xy (wks,yy,xx,res0)   ; create plot
    else
      dum1(i)     = gsn_csm_xy (wks,yy,xx,res0)   ; create plot
      overlay(plot(iv),dum1(i))
    end if 

    delete([/xx,yy/])

  end do

  ;;;;Second figure;;;;
  do i = 0,3
    res0@xyLineColors              = lncolor(i)
    res0@gsnXYBarChartColors       = colors(i)
    res0@gsnXYBarChartBarWidth     = barWidth(i)          ; change bar widths
    res0@gsnXYBarChartFillOpacityF = bopc(i)
    res0@gsnXYBarChartPatterns     = pattns(i)
    res0@gsnXYBarChartFillScaleF   = 0.5
    if(i.eq.0) then
      j = i 
    else 
      j = i+3
    end if 

    yy  = pltdat(0,j,:)
    xx  = fspan(.60,2*nlevs-0.4,nlevs) + i*0.38

    if(i.eq.0) then
      plot(iv+nvars) = gsn_csm_xy (wks,yy,xx,res0)   ; create plot
    else
      dum2(i)     = gsn_csm_xy (wks,yy,xx,res0)   ; create plot
      overlay(plot(iv+nvars),dum2(i))
    end if
    delete([/xx,yy/])
  end do
 
  ;;;;Third figure;;;;
  resx=res
  resx@gsnXYBarChart        = False ; create bar chart
  resx@tiMainString         = ""
  resx@tiXAxisString        = ""
  resx@tiYAxisString        = ""
  resx@gsnLeftString        = "" ;"Solid: 1800s       Dash: 300s"
  resx@xyLineColors         = "Black"
  resx@xyLineThicknessF     = 2
  resx@xyDashPatterns       = 0
  resx@xyMarkerSizes        = 0.012
  resx@xyMarkers            = 16
  resx@xyMarkerColors       = "Black"

  do i = 0,2

    plot(i+nvars*2) = gsn_csm_xy (wks,pltdat(2,0,:),plev,resx)   ; create plot

  end do 

;Attach a legend
;;manual legend
 lgres                    = True
 lgres@vpWidthF           = 0.12           ; width of legend (NDC)
 lgres@vpHeightF          = 0.07           ; height of legend (NDC)
 lgres@lbBoxMajorExtentF  = 0.12          ; puts space between color boxes
 lgres@lbMonoFillPattern  = False          ; Solid fill pattern
 lgres@lgLabelFontHeightF = FontHeight*0.1     ; legend label font thickness
 lgres@lgMonoDashIndex    = False
 lgres@lgMonoLineThickness= False
 lgres@lgPerimOn          = True
 lgres@lgPerimThicknessF  = 1.0
 lgres@lbLabelJust        = "CenterLeft"  ; left justify labels
 ;label1  = "  "+labels ;(/"  "+labels(0),"  "+labels(1),"  "+labels(2)/)
 ;label1  = label1(::-1)

 ; patt1=pattns ;(::-1)
 ; do i=0,dimsizes(label1)-1
 ; ;lgres@lbBoxLineDashPattern = 2;dashind(i)
 ;  lgres@lbBoxLineColor   = 0 ;colors(i)
 ;  lgres@lbFillColors     = colors(i)
 ;  lgres@lbFillOpacityF   = bopc(1)*3.0
 ;  lgres@lbFillPatterns   = patt1(i)
 ; ;lgres@lbBoxLineThicknessF = 1
 ; ;lgres@gsnXYBarChartFillScaleF = 0.5
 ;  ;gsn_labelbar_ndc(wks,1,label1(i),0.86,0.97+i*0.024,lgres)
 ; ; gsn_labelbar_ndc(wks,1,label1(i),0.78,0.80+i*0.024,lgres)
 ; end do
;
;  do i=0,dimsizes(label1)-1
;   lgres@lbBoxLineColor   = 1 ;colors(i)
;   lgres@lbFillColors     = colors(i)
;   lgres@lbFillOpacityF   = bopc(1)*3.0
;   lgres@lbFillPatterns   = patt1(i)
;   ;lgres@gsnXYBarChartFillScaleF = 0.5
;   ;gsn_labelbar_ndc(wks,1,label1(i),0.86,0.97+i*0.024,lgres)
;  ; gsn_labelbar_ndc(wks,1,label1(i),0.78,0.80+i*0.024,lgres)
;  end do
;
 end do

;---Draw both plots in a panel
  pnres                         = True
  pnres@gsnMaximize             = False
  pnres@gsnPanelMainString      = "" ;"Hovmoller plots for " + Varstr
  pnres@gsnPanelMainFontColor   = "Black"
  pnres@gsnPanelMainFontHeightF = 0.016
  pnres@gsnPanelLabelBar        = False
  pnres@gsnPanelBottom          = 0.05
  pnres@gsnPanelYWhiteSpacePercent = 2
 ;pnres@gsnPanelXF = (/0.15,0.35,0.55,0.75/)    ; Adjust rightmost plots
  gsn_panel(wks,(/plot/),(/3,3/),pnres)
  delete([/pnres/])

end
