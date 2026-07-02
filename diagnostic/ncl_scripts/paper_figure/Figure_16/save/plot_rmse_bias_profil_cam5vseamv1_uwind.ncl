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

  ldatalocal = True
  ldatalocal = False

  if (ldatalocal) then
     ModelOutRoot = "./"
  else
     ModelOutRoot = "/pic/projects/E3SM_DA/zhan391/e3sm_dart_NE30/diagnostics/EAM_NE30_Diags_2010-12_fnl/"
  end if

  outdir = "./"

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  Casdir       = (/"FV80",  "FV20"/)
  Groups       = (/"EAMv0 (80 members)", "EAMv0 (20 members)"/)
  ngrps        = dimsizes(Groups)
  labels       = (/"  80 ens","  20 ens"/)

  filname  = "obs_diag_output_6hourly_mean.nc"

  VarNameList = (/"RADIOSONDE_U_WIND_COMPONENT",\
                  "RADIOSONDE_V_WIND_COMPONENT",\
                  "RADIOSONDE_TEMPERATURE",\
                  "RADIOSONDE_SPECIFIC_HUMIDITY"/)
  nvars       = dimsizes(VarNameList)
  VarStrList  = (/"Zonal wind (m s~S~-1~N~)","Meridional wind (m s~S~-1~N~)", "Temperature (K)","Specific humidity (g/kg)"/)

  subvar   = (/"bias","rmse","Nposs","Nused"/)

  facts    = (/1,1,1e3,1e3/)
  nsubvs   = dimsizes(subvar)

  MinY     = 40.0 ; top level
 
  regions  = (/"Northern Hemisphere", "Southern Hemisphere", "Tropics", "North America"/)
  lonlim1  = (/  0.0,   0.0,   0.0, 235.0/)
  lonlim2  = (/360.0, 360.0, 360.0, 295.0/)
  latlim1  = (/ 20.0, -20.0, -90.0, 25.0/)
  latlim2  = (/ 90.0,  20.0, -20.0, 55.0/)

;;;;;;read the shared information;;;;;;;
  fxx         = addfile(ModelOutRoot+"/"+Casdir(0)+"/"+filname,"r")
  region      = fxx->region
  regnam      = fxx->region_names
  obstypes    = chartostring(fxx->ObservationTypes)
  rank_bins   = fxx->rank_bins
  plevel      = fxx->plevel
  plevel_edg  = fxx->plevel_edges
  timecenters = fxx->time
  timeedges   = fxx->time_bounds
  vNames      = getfilevarnames(fxx)
  copynams    = chartostring(fxx->CopyMetaData)
  ncops       = dimsizes(copynams)
  nregs       = dimsizes(region)
  nlevs       = dimsizes(plevel)
  ntimes      = dimsizes(timecenters)
  ;print(timecenters)
  ;print(timeedges)

  ;;;create the time string;;;
  date_str = new(2,string)
  do itim = 0,1
   if (itim.eq.0)then
    tmptim = timecenters(0) ;timeedges(0,itim)
   else
    tmptim = timecenters(ntimes-1) ;timeedges(0,itim)
   end if
   utc_date = cd_calendar(tmptim, 0)
   year   = tointeger(utc_date(:,0))    ; Convert to integer for
   month  = tointeger(utc_date(:,1))    ; use sprinti 
   day    = tointeger(utc_date(:,2))
   hour   = tointeger(utc_date(:,3))
   minute = tointeger(utc_date(:,4))
   second = utc_date(:,5)
   date_str(itim) = sprinti("%0.4i", year)+ \
              "-"+sprinti("%0.2i", month) + \
              "-"+sprinti("%0.2i", day) + \
              "_"+sprinti("%0.2iZ", hour)

  end do
  timrange = "00Z 05 -- 00Z 19 Dec. 2010" ;date_str(0) + "  --  " + date_str(1)
  print(timrange) 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  plot        = new(3,graphic)

  do iv = 0,0 ; nvars-1,1

  do irg   = 0,0 ; nregs-1

  pltreg  = str_squeeze(chartostring(regnam(irg,:)))
  plotlabel =   outdir + VarNameList(iv)+"_"+str_sub_str(str_strip(pltreg)," ","_")+"_profile_"+subvar(0)+ "_"+subvar(1)

  wks = gsn_open_wks("pdf",plotlabel)             ; send graphics to PNG file
  gsn_define_colormap(wks,"temp1")              ; choose colormap
  gsn_define_colormap(wks,"cb_9step")
  ;colors  = (/1,2,6,28,59/)
  ;gsn_merge_colormaps(wks,"StepSeq25","cb_9step")
  ;colors  = (/1,2,17,85,55/) ;(/1,55,2,17,85/)       ;;(/18,4,9,18,4,9/); (/"palegreen4","orange4","navy"/)
  colors  = (/2,6,28,1,36/)

  markers = (/16, 4, 3, 6, 16/)
  mkszf   = (/0.7, 0.9, 0.8, 0.8/)*2.0
  dashind = (/0,0,0,0,0/)       ;;line dash pattern
  lnthick = (/3,3,3,3,3/)/1.5   ;;line thichness
  mkthk   = mkszf
  mkthk   = 1.0

  varname = VarNameList(iv)+"_VPguess"
  pltdat1 = new((/ngrps,nsubvs,nlevs/),typeof(fxx->$varname$))
  pltdat2 = new((/ngrps,3,nlevs/),typeof(fxx->$varname$))

  do igp = 0, ngrps-1, 1

   fxx     = addfile(ModelOutRoot+"/"+Casdir(igp)+"/"+filname,"r")
   tempvar = fxx->$varname$(:,:,irg)
   printVarSummary(tempvar)
   ;;;;;;;get the data to be plotted 
   do isv  = 0,nsubvs-1,1
   do icp  = 0,ncops-1,1
    if (str_squeeze(copynams(icp)).eq.subvar(isv))then
      print(copynams(icp) + "  "+subvar(isv))
      pltdat1(igp,isv,:) = tempvar(icp,:)/facts(isv)
    end if   
   end do 
   end do 
 
  end do 

  pltdat1 = where(pltdat1.eq.0,32766,pltdat1)
  pltdat1@_FillValue = 32766
  pltdat2(:,0:1,:) = pltdat1(:,0:1,:)
  ;;calculate the data rejection rate 
  pltdat2(:,2,:)  = (pltdat1(:,2,:) - pltdat1(:,3,:))*100.0/pltdat1(:,2,:)
  pltdat2@_FillValue = 32766
  xmin1  = -1.2 ;floor(min(pltdat2(:,0,:)))
  xmax1  =  1.8  ;ceil(max(pltdat2(:,0,:)))
  xmin2  = 1.5;floor(min(pltdat2(:,1,:)))
  xmax2  = 4.5;ceil(max(pltdat2(:,1,:)))
  xmin3  = 0.   ;floor(min(pltdat2(:,2,:)))
  xmax3  = 100. ;ceil(max(pltdat2(:,2,:)))

  dplev  = plevel_edg(1:nlevs)-plevel_edg(0:nlevs-1)
  mdat   = dim_avg_n(pltdat2,2)
 
;----------------------------------------------------------------------
; Plotting section
;---Resources to share between both plots
  res          = True                   ; plot mods desired
  res@vpHeightF = 0.8
  res@vpWidthF =  0.5
  res@gsnDraw  = False
  res@gsnFrame = False

  FontHeight = 0.028
  res@gsnStringFontHeightF = FontHeight
  res@tmXBLabelFontHeightF = FontHeight
  res@tmYLLabelFontHeightF = FontHeight
  res@tmYRLabelFontHeightF = FontHeight
  res@tiMainFontHeightF    = FontHeight*1.1
  res@tiXAxisFontHeightF   = FontHeight
  res@tiYAxisFontHeightF   = FontHeight

  res@tmBorderThicknessF    = 1.5 
  res@tmXBMajorThicknessF   = 1.5 
  res@tmXBMinorThicknessF   = res@tmXBMajorThicknessF/2.0

; add a legend
  res@pmLegendDisplayMode    = "Never"              ; turn on legend
  res@pmLegendSide           = "Top"                 ; Change location of
  res@pmLegendParallelPosF   = .75                   ; move units right
  res@pmLegendOrthogonalPosF = -0.35                  ; more neg = down
  res@pmLegendWidthF         = 0.14                  ; Change width and
  res@pmLegendHeightF        = 0.08                  ; height of legend.
  res@lgLabelFontHeightF     = .022                   ; change font height
  res@lgPerimOn              = False                 ; no box around

  res@trYReverse        = True                       ; reverse Y-axis
 ;res@xyYStyle          = "Log"
  res@tmYLMode          = "Explicit"                ; explicit labels
  if (MinY.ge.500)then
   res@tmYLValues        = (/ 1000,950,900,850,800,750,700,650,600,500,400,300,200,100,50,30,10,5,1/)
  else
   res@tmYLValues        = (/ 1000,850,700,600,500,400,300,200,100,10/)
  end if
  res@tmYLLabels        = ""+res@tmYLValues         ; make strings
  res@tmXTOn  = False
  res@trYMaxF = 1000.0
  res@trYMinF = 10 ;-200.0

  res@gsnXRefLine             = (/0./)      ; four X reference lines
  res@gsnXRefLineThicknesses  = 1.0
  res@gsnXRefLineDashPatterns = 2
  res@gsnXRefLineColors       = "Black"

  res@xyMarkLineMode         = "MarkLines"
  res@xyLineColors           = colors(0:1)
  res@xyMarkers              = markers(0:1)
  res@xyMarkerColors         = colors(0:1)
  res@xyMarkerSizes          = 0.015*mkszf(0:1)
  res@xyMarkerThicknesses    = lnthick(0:1)
  res@xyDashPatterns         = dashind(0:1)
  res@xyLineThicknesses      = lnthick(0:1)

  res@tiMainString           = ""; Groups(igp) 
  res@tiMainOffsetYF         = 0.02
  res@tiMainFontThicknessF   = 3.0

  res@gsnRightString         = "" ;VstList(0)
  res@gsnLeftString          = "" ;VarStrList(iv); "Temperature (K)" ;Groups(0)

  res1 = res
  res1@tmYLOn                 = True
  res1@tiYAxisString          = "Pressure (hPa)";"log~B~10~N~(~F8~D~F10~t~F~)"
  res1@tiXAxisString          = "        "+VarStrList(iv) + "~C~" \
                                + ""+timrange
  res1@tiXAxisOffsetYF        = -0.015
  res1@gsnLeftString          = "Mean bias"; "Temperature (K)" ;Groups(0)
  res1@trXMaxF               := xmax1 ;0.21
  res1@trXMinF               := xmin1 ;0.0
  plot(0)  = gsn_csm_xy (wks,pltdat2(:,0,:),plevel,res1)   ; create plot

  res2 = res
  res2@tmYLOn          = False
  res2@tiYAxisString   = ""
  res2@tiXAxisString   = "        "+VarStrList(iv) + "~C~" \
                           + ""+timrange
  res2@tiXAxisOffsetYF  = -0.015
  res2@gsnLeftString          = "Root mean square error"; "Temperature (K)" ;Groups(0)
  res2@trXMaxF                := xmax2 ;0.21
  res2@trXMinF                := xmin2 ;0.0
  plot(1)  = gsn_csm_xy (wks,pltdat2(:,1,:),plevel,res2)   ; create plot

  res3 = res
  res3@xyLineColors           = colors(2:3)
  res3@xyMarkerColors         = colors(2:3)
  res3@tmYLOn                 = False
  res3@tiYAxisString          = ""
  res3@tiXAxisString          = "    Data rejection rate (%)"+ "~C~" \
                                  + ""+timrange
  res3@tiXAxisOffsetYF        = -0.015
  res3@gsnLeftString          = "Data rejection" ; "Temperature (K)" ;Groups(0)
  res3@trXMaxF                := xmax3 ;0.21
  res3@trXMinF                := xmin3 ;0.0
  plot(2)  = gsn_csm_xy (wks,pltdat2(:,2,:),plevel,res3)   ; create plot


;Attach a legend
;;manual legend
   lgres                    = True
   lgres@lgItemType         = "MarkLines"
   lgres@lgLineLabelFontThicknessF= 1.0
 ; lgres@lgLineDashSegLenF  = 0.01
   lgres@lgBoxMinorExtentF  = 0.25
   lgres@lgBoxMajorExtentF  = 0.1
   lgres@lgMonoDashIndex    = False
   lgres@lgMonoLineThickness= False
   lgres@lgMonoMarkerThickness = False
   lgres@lgPerimOn          = False ;True
  ;lgres@lgRightMarginF     = 0.5
  ;lgres@lgLeftMarginF      = 0.5
  ;lgres@lgTopMarginF       = 0.5
  ;lgres@lgBottomtMarginF   = 0.5

   lgres@lgPerimThicknessF  = 1.0

  lgres1 = lgres
  lgres1@vpWidthF           = 0.30           ; width of legend (NDC)
  lgres1@vpHeightF          = 0.12           ; height of legend (NDC)
  lgres1@lgLineColors       = colors(0:1) ;(/"Black","Black","Black"/)
  lgres1@lgDashIndexes      = dashind(0:1)
  lgres1@lgLineThicknesses  = lnthick(0:1)
  lgres1@lgMarkerColors     = colors(0:1)
  lgres1@lgMarkerIndexes    = markers(0:1)
  lgres1@lgMarkerThicknesses= mkthk(0:1)

  lgres2 = lgres
  lgres2@vpWidthF           = 0.30           ; width of legend (NDC)
  lgres2@vpHeightF          = 0.12           ; height of legend (NDC)
  lgres2@lgLineColors       = colors(2:3) ;(/"Black","Black","Black"/)
  lgres2@lgDashIndexes      = dashind(0:1)
  lgres2@lgLineThicknesses  = lnthick(0:1)
  lgres2@lgMarkerColors     = colors(2:3)
  lgres2@lgMarkerIndexes    = markers(0:1)
  lgres2@lgMarkerThicknesses= mkthk(0:1)


  ;Labels for the legend
  labls = labels
  do ii= 0,1
   labls(ii) = labels(ii) + " ("+sprintf("%5.2f",mdat(ii,0))+")"
  end do
  legend1 = gsn_create_legend (wks,dimsizes(labls), labls,lgres1)

  labls = labels
  do ii= 0,1
   labls(ii) = labels(ii) + " ("+sprintf("%5.2f",mdat(ii,1))+")"
  end do
  legend2 = gsn_create_legend (wks,dimsizes(labls), labls,lgres1)

  labls = labels
  do ii= 0,1
   labls(ii) = labels(ii) + " ("+sprintf("%5.2f",mdat(ii,2))+")"
  end do
  legend3 = gsn_create_legend (wks,dimsizes(labls), labls,lgres2)

  amres1                  = True
  amres1@amJust           = "TopRight"
  amres1@amParallelPosF   =   0.48
  amres1@amOrthogonalPosF =  -0.35
  annoid1 = gsn_add_annotation(plot(0),legend1,amres1)  ; add legend to the top figure

  amres2                  = True
  amres2@amJust           = "TopLeft"
  amres2@amParallelPosF   = -0.45
  amres2@amOrthogonalPosF = -0.30
  annoid2 = gsn_add_annotation(plot(1),legend2,amres2)  ; add legend to the top figure

  amres3                  = True
  amres3@amJust           = "BottomRight"
  amres3@amParallelPosF   =  0.40
  amres3@amOrthogonalPosF =  0.1
  annoid3 = gsn_add_annotation(plot(2),legend3,amres3)  ; add legend to the top figure

;---Draw both plots in a panel
  pnres                         = True
  pnres@gsnMaximize             = False
  pnres@gsnPanelMainString      = "    "+VarNameList(iv) + " ("+ pltreg+")" ;"     "+ pltreg + "~C~"+ VarNameList(iv)
  pnres@gsnPanelMainFontColor   = "Black"
  pnres@gsnPanelMainFontHeightF = 0.020
  pnres@gsnPanelLabelBar        = False
  pnres@gsnPanelBottom          = 0.05
  pnres@gsnPanelYWhiteSpacePercent = 2
  pnres@gsnPanelXF = (/0.15,0.45,0.75/)    ; Adjust rightmost plots
  gsn_panel(wks,(/plot/),(/1,3/),pnres)
  delete([/pnres/])

end do

end do 
end
