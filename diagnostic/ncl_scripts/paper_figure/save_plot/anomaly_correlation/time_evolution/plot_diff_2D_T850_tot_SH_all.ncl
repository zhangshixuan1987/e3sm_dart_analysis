;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;This script used to calculate and plot the zonal mean variables from CAM;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;The terms zonal and meridional are used to describe directions on a globe;;;;;;;
;;;;;;;Zonal means "along a latitudinal circle" or "in the west–east direction";;;;;;;;
;;;;;;;while meridional means "along a longitudinal circle" (a.k.a. meridian) ;;;;;;;;;
;;;;;;;or "in the north–south direction" [2];;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

  ldatalocal = True
  ldatalocal = False

  if (ldatalocal) then
     ModelOutRoot = "./E3SMV1_SIMULATION/"
  else
     ModelOutRoot = "/global/cscratch1/sd/zhan391/E3SM_V201806_DTENS/regrid/"
     ClimoOutRoot = "/global/cscratch1/sd/zhan391/E3SM_V201806_DTENS/regrid_obs/"
  end if

;;;;;;;;;weight files for ESMF regrid function;;;;;
  wgt_dir  = "./"
  wgt_file = wgt_dir+"SE_NE30_to_FV_192x288.bilinear.nc"

;;;;;;;;;;select the regions to calculate the rmse;;;;;;;;;;;;;
  Regions      = (/"Global"/)
  nregs        = dimsizes(Regions)

;;;;;;;;;;select the regions to calculate the rmse;;;;;;;;;;;;;
  Casdir       = (/"DT1800",  "DT0300"/)
  Groups       = (/"DT1800",  "DT0300"/)
  ngrps        = dimsizes(Groups)
   
  nens         = 30 
  nday         = 15
  ntime        = nday*8 ;every 3h
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  labels       = (/"(a)  Cold CLUBB","(b)  Warm CLUBB - Cold CLUBB"/)
  nlabls       = dimsizes(labels)

;;;;;;variables to be plotted;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  Varname      = (/"T850"/) ;;"Net shortwave flux at top of model" ;
  Varstr       = ("850hPa Temperature")
  Varunt       = ("%")
  nvars        = dimsizes(Varname)
  Plttim       = (/"SH"/)
  nptim        = dimsizes(Plttim)

  plotFileLabel = Varname+"_2d_SH_all_PD"

  leftstring = Varstr+ "~C~" +\
               "Anomaly correlation ~C~" + \
               "Date: day 1 to day 15 ~C~"+ \
               "SHem Extratropics (lat -90.0 to 0.0. lon 0.0 to 360.0)"
 print(leftstring)

;;;;;;;begin to read climatology;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  Climfnm = systemfunc("cd "+ClimoOutRoot+"; ls ERAI_ANN_climo_rgd.nc")
  Fclim   = addfile(ClimoOutRoot+Climfnm,"r")
  varclm  = Fclim->$Varname$(0,:,:)
;;;;;;;begin to work with the simulations;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  Filnam0 = systemfunc("cd "+ModelOutRoot+"; ls *"+Casdir(0)+"*ENS"+"*")
  Filnam1 = systemfunc("cd "+ModelOutRoot+"; ls *"+Casdir(1)+"*ENS"+"*")
  File0   = addfiles(ModelOutRoot+Filnam0,"r")
  File1   = addfiles(ModelOutRoot+Filnam1,"r")
  ListSetType (File0, "join")
  ListSetType (File1, "join")
  lat     = File0[0]->lat
  lon     = File0[0]->lon
  time    = File0[:]->time
  area    = File0[0]->area
  var1pd  = File0[:]->$Varname$
  var2pd  = File1[:]->$Varname$
  dimsvar = dimsizes(var1pd)
  nlat    = dimsizes(lat)
  nlon    = dimsizes(lon)
  rtime   = reshape(time,(/nens,ntime/))
  plttim  = rtime(0,:)-rtime(0,0)+0.125
  rvar1   = reshape(var1pd,(/nens,ntime,nlat,nlon/))
  rvar2   = reshape(var2pd,(/nens,ntime,nlat,nlon/))
  rvar1!0 = "ens" 
  rvar1!1 = "time"
  rvar1!2 = "lat"
  rvar1!3 = "lon"
  rvar1&ens  = ispan(1,nens,1)
  rvar1&time = plttim
  rvar1&lat  = lat
  rvar1&lon  = lon
  var1mx  = conform(rvar1,varclm,(/2,3/))
  copy_VarCoords(rvar1,rvar2)
  copy_VarCoords(rvar1,var1mx)
  printVarSummary(var1mx)
  lat1    = -90 
  lat2    = 0
  lon1    = 0 
  lon2    = 358.75
  fmp     = rvar1(:,:,{lat1:lat2},{lon1:lon2})-var1mx(:,:,{lat1:lat2},{lon1:lon2})
  omp     = rvar2(:,:,{lat1:lat2},{lon1:lon2})-var1mx(:,:,{lat1:lat2},{lon1:lon2})
  wgt     = area({lat1:lat2},{lon1:lon2})
  fbar    = wgt_areaave2(fmp,wgt,0)
  obar    = wgt_areaave2(omp,wgt,0)
  fb3d    = conform(fmp,fbar,(/0,1/)) 
  ob3d    = conform(omp,fbar,(/0,1/))
  printVarSummary(fmp)
  printVarSummary(fbar)
  covar1  = wgt_areasum2((fmp-fb3d)*(omp-ob3d),wgt,0)
  sigm11  = wgt_areasum2((fmp-fb3d)*(fmp-fb3d),wgt,0)
  sigm12  = wgt_areasum2((omp-ob3d)*(omp-ob3d),wgt,0)
  accvar1 = 100.0*covar1/sqrt(sigm11*sigm12)
;*****************************************************   
; CALCULATE MIN & MAX
;***************************************************** 
  mnmx      = new ((/3,ntime/), float)
  mnmx(0,:) = dim_min_n( accvar1,0)
  mnmx(1,:) = dim_max_n( accvar1,0)
  mnmx(2,:) = dim_avg_n( accvar1,0)

;;;;;;;open a wks for plot;;;;;;;;;;;;;;;;;;;
  OUTDir  = "./"
  wtype = "png"
 ;wtype@wkPaperSize     = "A4"
 ;wtype@wkOrientation   = "landscape"    ;;pictures displayed along the length
  wks = gsn_open_wks(wtype,OUTDir+"fig_1d_acc_"+plotFileLabel)
;;;;;;;;;;;;;;;;;;;;;;;;
  ;colors  = (/"palegreen4","orange4","navy","palegreen4","orange4","navy"/)
  gsn_define_colormap(wks,"StepSeq25")
  colors  =(/18,4/); (/"palegreen4","orange4","navy"/)

  markers = (/16,11,8,16,11,8/)
  mkszf   = (/0.8,0.8,0.8,0.8/)
  dashind = (/0,0,0,1,1,1/)
  lnthick = (/3.0,3.0,3.0,3.0,3.0,3.0/)
  llth    = (/3.0,3.0,3.0/)
  plot    = new(3,graphic)
 
  res               = True           ; plot mods desired
  res@vpXF          = 0.17
  res@vpYF          = 0.8
  res@vpWidthF      = 0.8                      ; set width of plot
  res@vpHeightF     = 0.4                      ; set height of plot
  res@gsnDraw  = False
  res@gsnFrame = False

  res@tmYROn = False            ; Turn off right tickmarks.
  res@tmXTOn = False            ; Turn off top tickmarks
  FontHeight = 0.028
  res@gsnStringFontHeightF  = FontHeight*0.8
  res@tmXBLabelFontHeightF  = FontHeight
  res@tmYLLabelFontHeightF  = FontHeight
  res@tmYRLabelFontHeightF  = FontHeight
  res@tiMainFontHeightF     = FontHeight
  res@tiXAxisFontHeightF    = FontHeight
  res@tiYAxisFontHeightF    = FontHeight
  ;res@tiMainFontThicknessF  = 8.0
  ;res@tiYAxisFontThicknessF = 5.0
  ;res@tiXAxisFontThicknessF = 5.0

  ;res@trXMinF               = -90 ;min(latrgd)
  ;res@trXMaxF               =  90 ;max(latrgd)
  ;res@tmXBMode              = "Explicit"
  ;res@tmXBValues            = ispan(-90,90,30)
  ;res@tmXBLabels            = "" + res@tmXBValues
  ;res@tmXBMinorValues       = ispan(-90,90,10)

  res@tmXMajorGrid         = True
  res@tmYMajorGrid         = True
 ;res@tmXMinorGrid         = True
 ;res@tmYMinorGrid         = True
  gridthickness = 0.5
  res@tmXMinorGridThicknessF = gridthickness
  res@tmYMinorGridThicknessF = gridthickness
  res@tmXMajorGridThicknessF = gridthickness
  res@tmYMajorGridThicknessF = gridthickness

  griddash = 2
  res@tmXMajorGridLineDashPattern = griddash
  res@tmYMajorGridLineDashPattern = griddash

  ;res@gsnYRefLine           = 50.0             ; create a reference line
  ;res@gsnYRefLineDashPattern= 2
  ;res@gsnYRefLineColor      = "Black"
  ;res@gsnYRefLineThicknessF = 1.0

  res@gsnLeftString         ="" ;"Solid: 1800s       Dash: 300s"
  res@gsnLeftStringFontColor= "Black"
  res@gsnRightString         = "";"(PD)"
  res@gsnRightStringFontColor= "Black"
  res@trYMinF              = 40.0 ;floor(min(pltobs)) ;min(ynflx)-0.1 ;You could also just use
  res@trYMaxF              = 100.0   ;ceil(max(pltobs)) ;max(ynflx)+0.1 ;min/max of u0,u1,u2.
  res@xyMarkLineModes      = "Lines"

;;;;;;;first figure for PD origional values;;;;;;;;;;;;;;;;;;;;
  res0                      = res
  res0@tiMainString         = ""
  res0@tiXAxisString        = "Forecast day"
  res0@tiYAxisString        = Varunt
  res0@gsnLeftString        = leftstring
  res0@xyLineThicknessF     = llth(0)            ; make thicker
  res0@xyDashPatterns       = dashind
  res0@xyMarkerSizes        = 0.012
  res0@xyLineColors         = colors
  res0@xyMarkers            = markers
  res0@xyMarkerColors       = colors
  top_plot = gsn_csm_xy (wks,plttim,mnmx(2,:),res0)       ; create line plot

; Create a plot with the area between both curves filled in blue.
  ;delete(res@xyLineColors)
  res@gsnXYFillColors = "LightBlue"
  res@xyLineColor     = -1                           ; We don't want the line, so make it transparent.
  bot_plot  = gsn_csm_xy (wks,plttim,mnmx(0:1,:),res)  ; Create filled XY plot.

  overlay(bot_plot,top_plot)
  ;Attach a legend
  ;;manual legend

;  label1=(/"  ACC(~F8~D~N~~F~t=30min~N~)"/) ;, "  ACC(~F8~D~N~~F~t=5min~N~)"/)
;  dum1  = new(dimsizes(label1),graphic)
;
;  txx = new( dimsizes(label1),"float" )
;  txx = (/ 3,  3/)
;  txy = (/ 30, 35/)
;  txres = True
;  txres@txFontHeightF = FontHeight*0.7
;  txres@txJust = "CenterRight"
;  do iy= 0,dimsizes(label1)-1
;     txres@txFontColor = res0@xyLineColors(iy)
;     txt = "~F22~"+label1(iy)
;;    txt = txt +" ("+sprintf("%3.1f",slope(iy))+")~F~"
;;    dum1(iy) = gsn_add_text(wks,bot_plot, txt, txx(iy),txy(iy),txres)
;  end do

   lgres                    = True
   lgres@lgItemType         = "Lines"
   lgres@lgLineLabelFontThicknessF= 3
   lgres@vpWidthF           = 0.24           ; width of legend (NDC)
   lgres@vpHeightF          = 0.14           ; height of legend (NDC)
   lgres@lgLabelFontHeightF = .22            ; legend label font thickness
   lgres@lgMonoDashIndex    = False
   lgres@lgMonoLineThickness= False
   lgres@lgPerimOn          = False
   lgres@lgPerimThicknessF  = 0.5

   lgres1 = lgres
   lgres1@lgLineColors       = colors
   lgres1@lgDashIndexes      = dashind
   lgres1@lgLineThicknesses  = llth(:)
   label1=(/"  ACC(~F8~D~N~~F~t=30min~N~)"/) ;, "  ACC(~F8~D~N~~F~t=5min~N~)"/)
   legend1 = gsn_create_legend (wks,dimsizes(label1), label1,lgres1)
 
;;;;;;;;;;;;
   amres                  = True
   amres@amJust           = "BottomLeft"    ; Use bottom right corner of box
   amres@amParallelPosF   =  -0.45             ; Move legend to right
   amres@amOrthogonalPosF =   0.5              ; Move legend down.
   annoid0 = gsn_add_annotation(bot_plot,legend1,amres)  ; add legend to the top figure


  ;  tres                      = True                ; text mods desired
  ;  tres@txFontHeightF        = 0.020               ; make smaller
  ;  txid1 = gsn_create_text(wks, Varunt, tres)
  ;  txid2 = gsn_create_text(wks, Varunt, tres)
  ;  amres = True
  ;  amres@amParallelPosF   =  0.435    ; This is the right edge of the plot.
  ;  amres@amOrthogonalPosF = -0.5    ; This is the bottom edge of the plot.
  ;  annoid1 = gsn_add_annotation(mpid1, txid1, amres)
  ;  annoid2 = gsn_add_annotation(mpid2, txid2, amres)

;---Draw both plots in a panel
    pnres                         = True
    pnres@gsnMaximize             = True
    pnres@gsnPanelLabelBar        = True
    pnres@gsnPanelMainString      = "";Varstr; "Surface Temperature ("+ts@units+")"
    pnres@gsnPanelLabelBar        = False                ; add common colorbar
    pnres@gsnPanelMainFontColor   = "Black"
    pnres@gsnPanelMainFontHeightF = 0.030
;   pnres@lbLabelFontHeightF      = 0.018               ; make labels smaller
;   pnres@pmLabelBarParallelPosF  = 0.026
;   pnres@pmLabelBarOrthogonalPosF= 0.015
;   pnres@pmLabelBarHeightF       = 0.1
;   pnres@pmLabelBarWidthF        = 0.57
;   pnres@gsnPanelBottom          = 0.05
    pnres@gsnPanelYWhiteSpacePercent = 2
    gsn_panel(wks,(/bot_plot/),(/1,1/),pnres)

end
