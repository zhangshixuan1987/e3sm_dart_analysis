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
                  "PDDART_UVTQ_ENS80","PDDART_UVT_ENS80","PDDART_UV_ENS80", \
                  "PDNUDG_UVTQ_ENS01","PDNUDG_UVT_ENS01","PDNUDG_UV_ENS01"/)
  ngrps       = dimsizes(Groups)

  region      = "Global"
  regind      = 0

  Ystring     = "Pressure (hPa)"
  MinY        = 5.0 ; top level

  label1      = (/"ERA5        ","EDA-UVTQ","EDA-UVT   ","EDA-UV    "/)
  label2      = (/"ERA5        ","NDG-UVTQ","NDG-UVT   ","NDG-UV    "/)
  
  xmin        = 0.0
  xmax        = 6.0

  VarNameList = (/"T"/)
  VarString   = (/"T"/)
  UnitList    = (/"K"/)
  nvars       = dimsizes(VarNameList)

  Leftstring1  = "(a) EAM-DART analysis" 
  Rightstring1 = ""

  Leftstring2  = "(b) Nudged towards ERA5"
  Rightstring2 = ""

  Leftstring3  = "(c) # of observations" 
  Rightstring3 = ""

  plot = new(3,"graphic")
  dum1 = new(4,graphic)
  dum2 = new(4,graphic)
  dum2x= new(4,graphic)
  dum3 = new(4,graphic)

  do iv  = 0,nvars-1,1

   Varstr = VarNameList(iv)
   Varunt = UnitList(iv)

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
 ;res@vpXF          = 0.25
 ;res@vpYF          = 0.8
  res@vpWidthF      = 0.6                      ; set width of plot
  res@vpHeightF     = 1.0                      ; set height of plot
  res@gsnDraw       = False
  res@gsnFrame      = False

  res@tmYROn = False            ; Turn off right tickmarks.
  res@tmXTOn = False            ; Turn off top tickmarks
  FontHeight = 0.030

  res@gsnStringFontHeightF  = FontHeight*1.2
  res@tmXBLabelFontHeightF  = FontHeight
  res@tmYLLabelFontHeightF  = FontHeight
  res@tmYRLabelFontHeightF  = FontHeight
  res@tiMainFontHeightF     = FontHeight
  res@tiXAxisFontHeightF    = FontHeight
  res@tiYAxisFontHeightF    = FontHeight

  ;res@tiMainFontThicknessF  = 8.0
  ;res@tiYAxisFontThicknessF = 5.0
  ;res@tiXAxisFontThicknessF = 5.0

  res@tmBorderThicknessF    = 1.0 
  res@tmXBMajorThicknessF   = 1.0 
  res@tmXBMinorThicknessF   = res@tmXBMajorThicknessF/2.0
  res@tmYLMajorThicknessF   = 1.0
  res@tmYLMinorThicknessF   = res@tmYLMajorThicknessF/2.0

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
  res@tmYLValues              = fspan(1.15,2*nlevs+.15,nlevs) ;ispan(1,nvars,1)
  res@tmYLMinorValues         = fspan(1.15,2*nlevs+.15,nlevs) ;ispan(1,nvars,1)
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
  ;res@tmXTAutoPrecision    = False
  ;res@tmYLPrecision        =  2

   res@tmYLOn             = False           ; Turn off top tickmarks
   res@tiYAxisString      = ""

;;;;;;;first figure for PD origional values;;;;;;;;;;;;;;;;;;;;
  res0                      = res
  res0@trXMaxF              = xmax(iv)
  res0@trXMinF              = xmin(iv)
  res0@tmXBOn               = True            ; Turn off top tickmarks
  res0@tmXBLabelsOn         = True            ; Turn off top tickmarks
  res0@tmXBMode             = "Explicit"
  res0@tmXBValues          := fspan(res0@trXMinF,res0@trXMaxF,7)
  res0@tmXBMinorValues     := fspan(res0@trXMinF,res0@trXMaxF,13)
  res0@tmXBLabels          := res0@tmXBValues  ;(/"-0.2","-0.1","0.0","0.1","0.2"/)
  res0@tiMainString         = ""
  res0@tiXAxisString        = "RMSE in " + Varstr + " ("+Varunt+")" ;
 ;res0@tiXAxisOffsetYF      = -0.015

  ;;;;First figure;;;; 
  res0@tmYLOn             = True            ; Turn off top tickmarks
  res0@tiYAxisString      = Ystring

  do i = 0,3

    if(i.eq.0) then
     res0@gsnLeftString        =  Leftstring1(iv)
     res0@gsnLeftStringOrthogonalPosF = 0.02
     res0@gsnRightString       =  Rightstring1
     res0@gsnRightStringOrthogonalPosF = 0.022
    else
     res0@gsnLeftString        = ""
     res0@gsnRightString       = ""
    end if

    res0@xyLineColors              = lncolor(i)
    res0@gsnXYBarChartColors       = colors(i)  
    res0@gsnXYBarChartBarWidth     = barWidth(i)          ; change bar widths
    res0@gsnXYBarChartFillOpacityF = bopc(i)
    res0@gsnXYBarChartPatterns     = pattns(i)
    res0@gsnXYBarChartFillScaleF   = 0.5
    yy  = pltdat(0,i,:)
    xx  = fspan(.60,2*nlevs-0.4,nlevs) + i*0.45
    yy1 = pltdat(0,i,:) - pltdat(1,i,:)
    yy2 = pltdat(0,i,:) + pltdat(1,i,:) 

    dum1(i) = gsn_csm_xy (wks,yy,xx,res0)   ; create plot
    dumx    = new((/dimsizes(yy)/),"graphic")
    plres   = True
    plres@gsLineThicknessF = 0.9
    plres@gsLineColor = "Grey23" ;colors(i)

    do ix = 0,dimsizes(yy)-1
     baryy = (/xx(ix),xx(ix)/)
     barxx = (/yy1(ix),yy2(ix)/)
     str1  = unique_string("bar")
     dumx@$str1$ =  gsn_add_polyline( wks,dum1(i), barxx, baryy, plres )
     baryy = (/xx(ix)-0.10,xx(ix)+0.10/)
     barxx = (/yy1(ix),yy1(ix)/)
     str1  = unique_string("bar")
     dumx@$str1$ =  gsn_add_polyline( wks,dum1(i), barxx, baryy, plres )
     baryy = (/xx(ix)-0.10,xx(ix)+0.10/)
     barxx = (/yy2(ix),yy2(ix)/)
     str1  = unique_string("bar")
     dumx@$str1$ =  gsn_add_polyline( wks,dum1(i), barxx, baryy, plres )
    end do

    if(i.eq.0) then 
      plot(iv) = dum1(i)
    else
      overlay(plot(iv),dum1(i))
    end if 

    delete([/xx,yy/])

  end do

  ;;;;Second figure;;;;
   res0@tmYLOn             = False           ; Turn off top tickmarks
   res0@tiYAxisString      = ""

  do i = 0,3

    if(i.eq.0) then 
     res0@gsnLeftString        =  Leftstring2(iv) 
     res0@gsnLeftStringOrthogonalPosF = 0.02
     res0@gsnRightString       =  Rightstring2
     res0@gsnRightStringOrthogonalPosF = 0.02
    else
     res0@gsnLeftString        = ""
     res0@gsnRightString       = ""
    end if 

    res0@xyLineColors              = lncolor(i)
    res0@gsnXYBarChartColors       = color1(i)
    res0@gsnXYBarChartBarWidth     = barWidth(i)          ; change bar widths
    res0@gsnXYBarChartFillOpacityF = bopc(i)
    res0@gsnXYBarChartPatterns     = pattns(i)
    res0@gsnXYBarChartFillScaleF   = 0.5
    if(i.eq.0) then
      j = i 
    else 
      j = i+3
    end if 

    yy      = pltdat(0,j,:)
    xx      = fspan(.60,2*nlevs-0.4,nlevs) + i*0.45
    yy1     = pltdat(0,j,:) - pltdat(1,j,:)
    yy2     = pltdat(0,j,:) + pltdat(1,j,:)
  
    dum2(i) = gsn_csm_xy (wks,yy,xx,res0)   ; create plot
    res0@gsnXYBarChartPatterns     = pattnx(i)
    res0@gsnXYBarChartColors       = 1
    dum2x(i) = gsn_csm_xy (wks,yy,xx,res0)   ; create plot
    overlay(dum2(i),dum2x(i))

    dumy    = new((/dimsizes(yy)/),"graphic")
    plres   = True
    plres@gsLineThicknessF = 0.9
    plres@gsLineColor = "Grey23";colors(i)
    do ix = 0,dimsizes(yy)-1
     baryy = (/xx(ix),xx(ix)/)
     barxx = (/yy1(ix),yy2(ix)/)
     str1  = unique_string("bar")
     dumy@$str1$ =  gsn_add_polyline( wks,dum2(i), barxx, baryy, plres )
     baryy = (/xx(ix)-0.10,xx(ix)+0.10/)
     barxx = (/yy1(ix),yy1(ix)/)
     str1  = unique_string("bar")
     dumy@$str1$ =  gsn_add_polyline( wks,dum2(i), barxx, baryy, plres )
     baryy = (/xx(ix)-0.10,xx(ix)+0.10/)
     barxx = (/yy2(ix),yy2(ix)/)
     str1  = unique_string("bar")
     dumy@$str1$ =  gsn_add_polyline( wks,dum2(i), barxx, baryy, plres )
    end do

    if(i.eq.0) then
      plot(iv+nvars) = dum2(i)
    else
      overlay(plot(iv+nvars),dum2(i))
    end if

    delete([/xx,yy/])
  end do
 
  ;;;;Third figure;;;;
  resx=res
  resx@gsnLeftString        =  Leftstring3(iv)
  resx@gsnLeftStringOrthogonalPosF = 0.02
  resx@gsnRightString       = "" ; Rightstring3
  resx@gsnRightStringOrthogonalPosF = 0.02
  resx@gsnXYBarChart        = False ; create bar chart
  resx@xyMarkLineMode       = "MarkLines"               ; Markers *and* lines
  resx@tiMainString         = ""
  resx@tiXAxisString        = ""
  resx@tiYAxisString        = ""
  resx@xyLineColors         = "Black"
  resx@xyLineThicknessF     = 2
  resx@xyDashPatterns       = 0
  resx@xyMarkerSizes        = 0.028
  resx@xyMarkers            = 16
  resx@xyMarkerColors       = "Black"
  resx@tiXAxisString        = "# of " + Varstr +" (x 10~S~5~N~)"
  xx  = fspan(.60,2*nlevs-0.4,nlevs) + 2.0*0.45
  yy  = pltdat(2,0,:)/1e5
  plot(iv+nvars*2)         = gsn_csm_xy (wks,yy,xx,resx)   ; create plot

 end do

;Attach a legend
 lgres                    = True
 lgres@vpWidthF           = 0.10           ; width of legend (NDC)
 lgres@vpHeightF          = 0.12           ; height of legend (NDC)
 lgres@lbBoxMajorExtentF  = 0.08          ; puts space between color boxes
 lgres@lbMonoFillPattern  = False          ; Solid fill pattern
 lgres@lgLabelFontHeightF = FontHeight*0.08     ; legend label font thickness
 lgres@lgMonoDashIndex    = False
 lgres@lgMonoLineThickness= False
 lgres@lgPerimOn          = True
 lgres@lgPerimThicknessF  = 1.0
 lgres@lbLabelJust        = "CenterLeft"  ; left justify labels

 patt1=pattns 
 patt2=pattnx
 label1 = " "+label1
 label2 = " "+label2

 do i=0,dimsizes(label1)-1
  ;lgres@lbBoxLineDashPattern = 2;dashind(i)
   lgres@lbBoxLineColor   = 1 ;colors(i)
   lgres@lbFillColors     = colors(i)
   lgres@lbFillOpacityF   = bopc(1)*3.0
   lgres@lbFillPatterns   = patt1(i)
   lgres@lbBoxLineThicknessF = 1
   lgres@gsnXYBarChartFillScaleF = 0.5
   gsn_labelbar_ndc(wks,1,label1(i),0.26,0.60+i*0.020,lgres)
   lgres@lbFillColors     = colors(i)
   gsn_labelbar_ndc(wks,1,label2(i),0.54,0.60+i*0.020,lgres)
   lgres@lbFillPatterns   = patt2(i)
   lgres@gsnXYBarChartFillScaleF = 0.1
   lgres@lbFillColors     = 1
   gsn_labelbar_ndc(wks,1,label2(i),0.54,0.60+i*0.020,lgres)

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
  pnres@gsnPanelXF = (/0.12,0.40,0.68/)
  gsn_panel(wks,(/plot/),(/1,3/),pnres)
  delete([/pnres/])

end
