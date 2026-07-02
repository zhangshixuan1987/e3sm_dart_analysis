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
load "./NCL_add_latlon_labels_to_robinson_projection.ncl"
begin

  ldatalocal = True
  ldatalocal = False

  if (ldatalocal) then
     ObsDatRoot   = "./ceres_ebaf/"
     ModelOutRoot = "./"
  else
     ObsDatRoot   = "/pic/projects/E3SM_DA/zhan391/e3sm_dart/acme_init/Observations/GPCP/daily/"
     ModelOutRoot = "/pic/projects/E3SM_DA/zhan391/final_analysis/post_processing/post_processing_data/"
  end if

;;;;regions to calculate mean and RMSE;;;;;
  region = ("Pac")
  minlat =  -45.0
  maxlat =   60.0 
  minlon =  -100.0
  maxlon =   110.0

  region = ("Ind")
  minlat =  -30.0
  maxlat =   30.0
  minlon =   30.0
  maxlon =   110.0

;;;;;;;date strings for the data directory;;;;;;;;
  year         = 2011
  month        = 1
  nday         = 31
  ymstr1       = sprinti("%04d",year)+sprinti("%02d",month)
  ymstr2       = sprinti("%04d",year)+"-"+sprinti("%02d",month)

;;;;;;;;;;select the regions to calculate the rmse;;;;;;;;;;;;;
  Casdir       = (/"GPCP","PD_NDG_ERA5UV","PD_NDG_ERA5UVT","PD_NDG_ERA5UVTQ","PD_EDAUVTQ_EN80"/)
  Casdir(1:)   = Casdir(1:)+"_"+ymstr1
  Groups       = (/"GPCP","NDG_ERA5UV","NDG_ERA5UVT","NDG_ERA5UVTQ","DART_EDA_EN80"/)
  ngrps        = dimsizes(Groups)
  Labels       = (/"GPCP","NDG_ERA5UV","NDG_ERA5UVT","NDG_ERA5UVTQ","DART_EDA_EN80"/)

  Plttim       = (/"GPCP_daily_2011_1.9x2.5.nc","*mean.cam.h0.2011-01.nc*","*mean.cam.h0.2011-01.nc*","*mean.cam.h0.2011-01.nc*","*mean.cam.h0.2011-01.nc*"/)
  nptim        = dimsizes(Plttim)

  LabList      = Groups
  LabList(1:)  = LabList(1:) + "  ~F34~>~N~~F~  " + "GPCP"

 ;;;;;;variables to be plotted;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  VarList      = (/"PRECT"/)
  VstList      = (/"PRECT"/)
  UnitList     = (/"mm day~S~-1~N~"/)
  PltNums      = (/"", "", "", "", "", "", "", "", "", "", ""/)
  nvars        = dimsizes(VarList)

 ;;; flags to control the plot style
  plotcntl          = True   ; if True, plot the CNTL origianl field on the leftmost panel

  plotrdif          = False  ; True  ; if True, plot the relative difference with respect to CNTL

  plot_ttest_mskout = False  ; if True, mask the non-significant region as missing values

  plot_ttest_hatch  = False  ; if True, plot the significant region as hatch region

  plot_ttest_hatrv  = False  ; if True, plot the non-significant region as hatch region

  plot_contour      = False  ; True   ; if True, plot the contour in the figure

  plot_leftstr      = True   ; if True, the lefadd igure captions as left string

  plot_lndmsk       = False ;
 ;;;these flags control the zonal mean plot
  plot_zonal_mean   = False  ; whether or not plot zonal mean
  add_fill_line     = False  ; Turn off (on if True) fill color below the zonal mean line
  add_std_shading   = False ; If true, the grey shading is added for uncertainty of zonal mean
  add_std_line      = False  ; If true, the dash red lines are added for upper and bottom bounds
                            ; of uncertainty for zonal mean

 ;;color for the map boundary line
  lndcolor = "Black" ;"Grey50"

 ;;flags to perform significant test;;;;;;;;
  l_studentttest    = True ; True if perform student-t test
  l_pairedttest     = False  ; True if perform parired-t test
  l_kstest          = False  ; True if perform K-S test, see https://www.ncl.ucar.edu/Document/Functions/Built-in/kolsm2_n.shtml

 plot         = new(ngrps,graphic)

 do iv = 0,nvars-1, 1

  Varname = VarList(iv)
  Varunt  = UnitList(iv)
  Varstr  = VstList(iv)
  Figstr  = PltNums(iv)

  plotFileLabel = Varname+"_PD"

 ;;;;;;;open a wks for plot;;;;;;;;;;;;;;;;;;;
  OUTDir  = "./"
  wtype = "pdf"
 ;wtype@wkWidth = 2500
 ;wtype@wkHeight = 2500
 ;wtype@wkPaperSize     = "A4"
 ;wtype@wkOrientation   = "landscape"    ;;pictures displayed along the length
 ;wtype@wkOrientation   = "landscape"    ;;pictures displayed along the length
  wks1 = gsn_open_wks(wtype,OUTDir+"fig_2d_map_"+plotFileLabel)

 ;;;;extract the observational data;;;;
 Obsnam  = systemfunc("cd "+ObsDatRoot+"; ls -1 *"+Plttim(0))
 Obsfil  = addfiles(ObsDatRoot+Obsnam,"r")
 time    = Obsfil[:]->time
 date    = Obsfil[:]->date
 obsdat1 = Obsfil[:]->PREC

 ;;;extract the data for 201101;;;;
 indtim  = ind ((date.ge.20110101).and.(date.le.20110131))
 obsdat  = obsdat1(indtim,:,:)
 delete([/indtim,date,Obsnam,Obsfil,time,obsdat1/])

 do igp = 1,ngrps-1,1

  tescase = Casdir (igp)
  
;;;;;;;begin to work with the simulations;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  Filnam1 = systemfunc("cd "+ModelOutRoot+tescase+"/"+"; ls -1 *"+Plttim(igp))
  File1   = addfiles(ModelOutRoot+tescase+"/"+Filnam1,"r")
  ListSetType (File1, "join")

  lat       = File1[0]->lat
  lon       = File1[0]->lon
  lndmsk    = File1[0]->LANDFRAC(0,:,:)


  if(Varname.eq."PRECT") then
    owxcre0300 = File1[:]->PRECC
    owxcre0300 = File1[:]->PRECC + File1[:]->PRECL  
   else if(Varname.eq."NETCF") then
    owxcre0300 = File1[:]->SWCF
    owxcre0300 = File1[:]->LWCF + File1[:]->SWCF
   else
    owxcre0300 = File1[:]->$Varname$
   end if
  end if 
  
  if (Varname .eq. "PRECT" .or. Varname .eq. "PRECC" .or. Varname .eq. "PRECL") then
   owxcre0300 = owxcre0300*1000.0 *24.0 *3600.0 ;; mm/day
  end if

  dimx      = dimsizes (obsdat)
  fpxcre0300 = obsdat
  fwxcre0300 = obsdat
  ;;;;convert the 6hourly data to daily data;;;;
  do it     = 0, dimx(0)-1
   fwxcre0300(it,:,:) = dim_avg_n(owxcre0300(it*4:(it+1)*4-1,:,:),0)
  end do 

  dim1 = dimsizes(fpxcre0300)
  dim2 = dimsizes(fwxcre0300)

  nens = dim1(0)
  ;;;calculate the monthly mean 
  if (num(dim1).le.3)then
   nens = 1
   opycre0300=reshape(fpxcre0300,(/nens,dim1(0),dim1(1),dim1(2)/))
   opycre0300!0="ncl_join"
   opycre0300!1="time"
   opycre0300!2="lat"
   opycre0300!3="lon"
   opycre0300&lat = lat
   opycre0300&lon = lon 
  end if 

  if (num(dim2).le.3)then
   nens = 1
   owycre0300=reshape(fwxcre0300,(/nens,dim2(0),dim2(1),dim2(2)/))
   owycre0300!0="ncl_join"
   owycre0300!1="time"
   owycre0300!2="lat"
   owycre0300!3="lon"     
   owycre0300&lat = lat       
   owycre0300&lon = lon 
  end if 
 
  opycre0300 = lonFlip(opycre0300)
  owycre0300 = lonFlip(owycre0300)

  ;;mask out the land;;;;;;;;
  xlndmsk   = conform(owycre0300,lndmsk,(/2,3/))
  opycre0300@_FillValue = 32766
  owycre0300@_FillValue = 32766
  opycre0300  = where(xlndmsk.eq.1,opycre0300@_FillValue,opycre0300)
  owycre0300  = where(xlndmsk.eq.1,owycre0300@_FillValue,owycre0300)

  wxcre0300  = dim_avg_n_Wrap(owycre0300(:,:,{minlat:maxlat},{minlon:maxlon}),1)
  pxcre0300  = dim_avg_n_Wrap(opycre0300(:,:,{minlat:maxlat},{minlon:maxlon}),1)

  printVarSummary(wxcre0300)

  ;;calculate the differences
  wxcredf1  = wxcre0300
  wxcredf1  = wxcre0300 - pxcre0300
  if (plotrdif)then
   mskxx     = pxcre0300
   mskxx     = where(pxcre0300.ne.0.0,pxcre0300,32766)
   mskxx@_FillValue = 32766
   wxcredf1  = pxcre0300
   wxcredf1  = (wxcre0300 - pxcre0300)*100/mskxx
   wxcredf1  = where(ismissing(wxcredf1),0.0,wxcredf1)
  end if
  delete([/opycre0300,owycre0300,fpxcre0300,fwxcre0300,owxcre0300/])

  ;;calculate the ensemble mean;;;;;;
  pncre0300  = dim_avg_n_Wrap(pxcre0300,0)
  wncre0300  = dim_avg_n_Wrap(wxcre0300,0)
  wncredf1   = dim_avg_n_Wrap(wxcredf1,0)

  ;;;;calculate the regional mean and RMSE;;;;;;;
  rad      = 4.*atan(1.)/180.    ;
  cost     = tofloat(lat({minlat:maxlat}))
  cost     = tofloat(cos(lat({minlat:maxlat})*rad))       ; cosine weights

  if (nens.gt.1)then 
   orgmeanx = wgt_areaave_Wrap( pxcre0300, cost, 1.0, 0 )
   orgmean  = sprintf("%5.1f", avg(orgmeanx)) + " ~F34~1~N~~F~ " + sprintf("%5.1f",stddev(orgmeanx))

   difmeanx = wgt_areaave_Wrap( wxcredf1,  cost, 1.0, 0 )
   difmean  = sprintf("%5.1f", avg(difmeanx)) + " ~F34~1~N~~F~ " + sprintf("%5.1f",stddev(difmeanx))

   difrmsex = wgt_arearmse(wxcre0300,pxcre0300, cost, 1.0, 0 )
   difrmse  = sprintf("%5.1f",avg(difrmsex)) + " ~F34~1~N~~F~ " + sprintf("%5.1f",stddev(difrmsex))

  ;;;calculate the pattern correlation;;;;
   pcorx    = tofloat(pattern_cor(pxcre0300, wxcre0300,cost, 0))
   pcor     = sprintf("%5.2f",avg(pcorx)) + " ~F34~1~N~~F~ " + sprintf("%5.2f",stddev(pcorx))

 else
   orgmeanx = wgt_areaave_Wrap( pxcre0300, cost, 1.0, 0 )
   orgmean  = sprintf("%5.1f", avg(orgmeanx)) 

   difmeanx = wgt_areaave_Wrap( wxcredf1,  cost, 1.0, 0 )
   difmean  = sprintf("%5.1f", avg(difmeanx)) 

   difrmsex = wgt_arearmse(wxcre0300,pxcre0300, cost, 1.0, 0 )
   difrmse  = sprintf("%5.1f",avg(difrmsex)) 

  ;;;calculate the pattern correlation;;;;
   pcorx    = pattern_cor(pxcre0300, wxcre0300,cost, 0)
   pcor     = sprintf("%5.2f",avg(pcorx)) 

 end if 

 errorstring = "Mean / RMSE ("+ str_squeeze(difmean)+" / "+str_squeeze(difrmse)+ ")"

 print(tescase+ ":" +pcor)
 print(tescase+ ":" +errorstring)
 
 end do ; end of experiment group loop

 end do ; end of var loop

end

