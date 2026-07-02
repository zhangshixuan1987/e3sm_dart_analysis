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
     ModelOutRoot = "./"
  else
     ModelOutRoot = "/compyfs/zhan391/e3sm_dart/post/"
     ObsRoot      = "/compyfs/zhan391/e3sm_dart/diagnostics/obs_diag/"
  end if

;;;;;;;;;weight files for ESMF regrid function;;;;;
  wgt_dir  = "./"
  wgt_file = wgt_dir+"SE_NE30_to_FV_192x288.bilinear.nc"

;;;;;;;define flags to control data and plot style
  hindstr      = "day 0"
  figstr       = "d0"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  Casdir1      = (/"Anl_ERA5_"+figstr,"Anl_ERA5NDG_UV_"+figstr,"Anl_ERA5NDG_UVT_"+figstr,"Anl_DARTEDA_UV_"+figstr,"Anl_DARTEDA_UVT_"+figstr,"Anl_DARTEDA_UVTQ_"+figstr/)
  Groups       = (/"ERA5","NDG_ERA5UV","NDG_ERA5UVT","DARTEDA-UV","DARTEDA-UVT","DARTEDA-UVTQ"/)
  ngrps        = dimsizes(Groups)
  labels       = (/"NDGUV","NDGUVT","EDAUV","EDAUVT","EDAUVTQ"/)
  Plttim       = (/"era5_reanalysis*2011-01*","*mean.cam.i.2011-01.nc","*mean.cam.i.2011-01.nc","*cam_output_mean.2011-01.nc","*cam_output_mean.2011-01.nc","*cam_output_mean.2011-01.nc"/)
  nptim        = dimsizes(Plttim)

 ;;;;;;variables to be plotted;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  VarList      = (/"US","VS","T","Q"/)
  VstList      = (/"Zonal wind (U)","Meridional wind (V)","Temperature (T)", "Specific humidity (Q)"/)
  UnitList     = (/"m s~S~-1~N~","m s~S~-1~N~","K","g kg~S~-1~N~"/)
  nvars        = dimsizes(VarList)

  plevel                = (/1000, 925, 850, 700, 500, 400, 300, 250, 200, 150, 100/)
  plevel_edges          = (/1050, 962.5, 887.5, 775, 600, 450, 350, 275, 225, 175, 125, 75/)
  nplev                 = dimsizes(plevel)
  Nregions              = 4
  lonlim1               = (/  0.0,   0.0,   0.0, 235.0 /)
  lonlim2               = (/360.0, 360.0, 360.0, 295.0 /)
  latlim1               = (/20.0, -80.0, -20.0,  25.0  /)
  latlim2               = (/80.0, -20.0,  20.0,  55.0  /)
  reg_names             = (/"Northern Hemisphere", "Southern Hemisphere", "Tropics", "North America"/)

 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


  plot         = new((/nvars/),graphic)

 ;;;loop the regions and plot the PDF
  plotFileLabel = "acc_profl_"+figstr+"_cortp1"

 ;;;;;;;open a wks for plot;;;;;;;;;;;;;;;;;;;
  OUTDir  = "./"
  wtype = "png"
  wtype@wkWidth = 2500
  wtype@wkHeight = 2500
  ;wtype@wkPaperSize     = "A4"
  ;wtype@wkOrientation   = "landscape"    ;;pictures displayed along the length
  ;wtype@wkOrientation   = "landscape"    ;;pictures displayed along the length
  wks1 = gsn_open_wks(wtype,OUTDir+"fig_pdf_"+plotFileLabel)

  do igp = 0, 0 ;ngrps-1,1

  ;; read observational file list
  flist = asciiread(ObsRoot+"obs_pres_list.txt",-1,"string")
  nfiles= dimsizes(flist)

  fno = Groups(igp)+"_obs_diag.nc"
  system("rm " + fno)
  flo = addfile(fno,"c")

  plevel!0 ="plevel"
  plevel&plevel=plevel
  plevel@units = "hPa"

  region=new(4,integer)
  region!0 = "region"
  region&region = ispan(1,4,1)
  region@name1  = reg_names(0)
  region@name2  = reg_names(1)
  region@name3  = reg_names(2)
  region@name4  = reg_names(3)

  U_bias  = new ((/nfiles,Nregions,nplev/),float)
  U_bias!0 = "time"
  U_bias!1 = "region"
  U_bias!2 = "plevel"
  U_bias&time = ispan(0,nfiles-1,1)*6 
  U_bias&time@units = "hours since 2011-01-01 00:00:0.0"
  U_bias&region = ispan(1,4,1)
  U_bias&plevel = plevel 
  U_bias&plevel@units = "hPa"
  U_bias@units = "m s~S~-1~N~" 

  U_rmse  = U_bias
  V_bias  = U_bias
  V_rmse  = U_bias

  T_bias  = U_bias
  T_rmse  = U_bias
  T_bias@units = "K"
  T_rmse@units = "K"

  Q_bias  = U_bias
  Q_rmse  = U_bias
  Q_bias@units = "kg kg~S~-1~N~"
  Q_rmse@units = "kg kg~S~-1~N~"
  
  flo->plevel=plevel
  flo->region=region
  flo->U_bias=U_bias
  flo->V_bias=V_bias
  flo->T_bias=T_bias
  flo->Q_bias=Q_bias

  flo->U_rmse=U_rmse
  flo->V_rmse=V_rmse
  flo->T_rmse=T_rmse
  flo->Q_rmse=Q_rmse

  bias  = new ((/Nregions,nplev/),float)
  rmse  = new ((/Nregions,nplev/),float)

  do iv = 0,nvars-1, 1

  Varname = VarList(iv)
  Varunt  = UnitList(iv)
  Varstr  = VstList(iv)

  do ifil = 0,nfiles-1,1 
 
  print("observational file :" + flist(ifil))

  fxx         = addfile(ObsRoot+flist(ifil),"r")

  CopyMetaData     = chartostring(fxx->CopyMetaData)
  ObsTypesMetaData = chartostring(fxx->ObsTypesMetaData) ; ( ObsTypes, stringlength )
  ObsTypes         = fxx->ObsTypes ; ( ObsTypes )
  ObsIndex         = fxx->ObsIndex ; ( ObsIndex ) ; dim+1
  obs_type         = fxx->obs_type ; ( ObsIndex )
  location         = fxx->location ; ( ObsIndex, locdim )
  time             = fxx->time
  observations     = fxx->observations(:,0) ;;
  vertype          = fxx->which_vert ;( ObsIndex )

  if(Varname.eq."U".or.Varname.eq."US")then

      indob01       = ind(str_squeeze(ObsTypesMetaData).eq."RADIOSONDE_U_WIND_COMPONENT" .or. \
                          str_squeeze(ObsTypesMetaData).eq."AIRCRAFT_U_WIND_COMPONENT" .or. \
                          str_squeeze(ObsTypesMetaData).eq."ACARS_U_WIND_COMPONENT" .or. \
                          str_squeeze(ObsTypesMetaData).eq."SAT_U_WIND_COMPONENT" )
      indtp1        = ind(obs_type.eq.ObsTypes(indob01(0)).or. \
                          obs_type.eq.ObsTypes(indob01(1)).or. \
                          obs_type.eq.ObsTypes(indob01(2)).or. \
                          obs_type.eq.ObsTypes(indob01(3)).and. \
                          vertype.eq.2)
  end if 

  if(Varname.eq."V".or.Varname.eq."VS")then

      indob01       = ind(str_squeeze(ObsTypesMetaData).eq."RADIOSONDE_V_WIND_COMPONENT" .or. \
                          str_squeeze(ObsTypesMetaData).eq."AIRCRAFT_V_WIND_COMPONENT" .or. \
                          str_squeeze(ObsTypesMetaData).eq."ACARS_V_WIND_COMPONENT" .or. \
                          str_squeeze(ObsTypesMetaData).eq."SAT_V_WIND_COMPONENT")
      indtp1        = ind(obs_type.eq.ObsTypes(indob01(0)).or. \
                          obs_type.eq.ObsTypes(indob01(1)).or. \
                          obs_type.eq.ObsTypes(indob01(2)).or. \
                          obs_type.eq.ObsTypes(indob01(3)).and. \
                          vertype.eq.2)
  end if 

  if(Varname.eq."T")then

      indob01       = ind(str_squeeze(ObsTypesMetaData).eq."RADIOSONDE_TEMPERATURE" .or. \
                          str_squeeze(ObsTypesMetaData).eq."AIRCRAFT_TEMPERATURE" .or. \
                          str_squeeze(ObsTypesMetaData).eq."AIRS_TEMPERATURE" )
      indtp1        = ind(obs_type.eq.ObsTypes(indob01(0)).or. \
                          obs_type.eq.ObsTypes(indob01(1)).or. \
                          obs_type.eq.ObsTypes(indob01(2)).and.\
                          vertype.eq.2)
  end if 

  if(Varname.eq."Q")then

      indob01       = ind(str_squeeze(ObsTypesMetaData).eq."RADIOSONDE_SPECIFIC_HUMIDITY" .or. \
                          str_squeeze(ObsTypesMetaData).eq."AIRS_SPECIFIC_HUMIDITY")
      indtp1        = ind(obs_type.eq.ObsTypes(indob01(0)).or. \
                          obs_type.eq.ObsTypes(indob01(1)).and. \
                          vertype.eq.2)
  end if 

  lon1d1        = location(indtp1,0)
  lat1d1        = location(indtp1,1)
  zlevs1        = location(indtp1,2)
  obs1          = observations(indtp1)
  zlevs1        = zlevs1/100.0         ; convert to hPa

  delete([/indob01,indtp1,CopyMetaData,ObsTypesMetaData,ObsTypes,ObsIndex,obs_type,location,time,observations,vertype/])

  ;;;;;;;begin to work with the simulations;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;extract the coordinate;;;;;;
  Filex   = addfile(ModelOutRoot+"PDNDGUVT_ENS1_F20TRC5-AMIP_f19_d025_201101/PDNDGUVT_ENS1_F20TRC5-AMIP_f19_d025_ens01.cam.h0.2011-01.nc","r")
  hyam = Filex->hyam
  hybm = Filex->hybm
  P0mb =1000.
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  refcase = Casdir1 (igp)
  Filnam0 = systemfunc("cd "+ModelOutRoot+refcase+"/"+"; ls -1 "+Plttim(igp))
  File0   = addfiles(ModelOutRoot+refcase+"/"+Filnam0,"r")
 ;ListSetType (File1, "join")

  lat       = File0[0]->lat
  lon       = File0[0]->lon
  levs      = File0[0]->lev

  PHIS = File0[:]->PHIS(ifil,:,:)                       ; surface geopotential [2D]
  PS   = File0[:]->PS(ifil,:,:)  
  T    = File0[:]->T(ifil,:,:,:)                          ; temperature at hybrid levels
  var  = File0[:]->$Varname$(ifil,:,:,:)                          ; temperature at hybrid levels

  nlev = dimsizes(hyam)                ; number of vertical levels
  tbot = T(nlev-1,:,:)               ; bot temp level [clarity]

  if(Varname.eq."US")then
     var0 = var
     delete(var)
     var= linint2 (var0&lon,var0&slat,var0, True, lon,lat, 0)
     delete(var0)
  end if
  if(Varname.eq."VS")then
     var0 = var
     delete(var)
     var= linint2 (var0&slon,var0&lat,var0, True, lon,lat, 0)
     delete(var0)
  end if

 ;;;;;;;interpolate the model level and grid to observational level and location 
  nobs = dimsizes(zlevs1)
  fn   = new(nobs,typeof(var))

  do iobs = 0,nobs-1,1
    lev_p = (/zlevs1(iobs)/)
    lev_p!0         = "lev_p"            ; variable and dimension name the same
    lev_p&lev_p     = lev_p              ; create coordinate variable
    lev_p@long_name = "pressure"         ; attach some attributes
    lev_p@units     = "hPa"
    lev_p@positive  = "down"
    intyp    = 1                            ; 1=linear, 2=log, 3=log-log
    kxtrp    = True                         ; True=extrapolate
    varflg   = 1                           ; temperature is variable
    vintp    = vinth2p_ecmwf(var,hyam,hybm,lev_p,PS,intyp,P0mb,1,kxtrp,varflg,tbot,PHIS)
    fn(iobs) = linint2_points_Wrap(lon,lat,vintp(0,:,:), True, lon1d1(iobs), lat1d1(iobs), 0) 
    delete([/vintp/])
  end do 

  delete([/var,tbot,T,PS,PHIS/])

  ;;;;;create bins and calculate the mean biases;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  do ireg = 0, Nregions-1
   do ip = 1,nplev
    indxx1 = ind (lon1d1.ge.lonlim1(ireg).and.lon1d1.le.lonlim2(ireg) .and. \ 
                  lat1d1.ge.latlim1(ireg).and.lat1d1.le.latlim2(ireg) .and. \ 
                  zlevs1.le.plevel_edges(ip-1).and.zlevs1.gt.plevel_edges(ip) \                
                  )

    if(.not.all(ismissing(indxx1)))then
      rad    = 4.0*atan(1.0)/180.0
      wgt    =  cos(lat1d1(indxx1)*rad)
      bias(ireg,ip-1) = tofloat(dim_avg_wgt_n(fn(indxx1) - obs1(indxx1),wgt,1,0))
      rmse(ireg,ip-1) = tofloat(sqrt(dim_avg_wgt_n((fn(indxx1) - obs1(indxx1))^2,wgt,1,0)))
      delete([/indxx1,rad,wgt/])
    else
      bias(ireg,ip-1) = bias@_FillValue
      rmse(ireg,ip-1) = rmse@_FillValue
      delete([/indxx1/])
    end if
   end do 
  end do
  delete([/fn,obs1,lon1d1,lat1d1,zlevs1/])

  ;bias!0 = "region"
  ;bias!1 = "plevel"
  ;bias&region=ispan(1,Nregions,1)  
  ;bias&lev=plevel
  ;bias&region@long_name=reg_names
  ;bias@units=Varunt
  
  ;rmse!0 = "region"
  ;rmse!1 = "plevel"
  ;rmse&region=ispan(1,Nregions,1)
  ;rmse&lev=plevel
  ;rmse&region@long_name=reg_names
  ;rmse@units=Varunt

  if(Varname.eq."U".or.Varname.eq."US")then
   flo->U_bias(ifil,:,:)=(/bias/)
   flo->U_rmse(ifil,:,:)=(/rmse/)
  end if 

  if(Varname.eq."V".or.Varname.eq."VS")then
   flo->V_bias(ifil,:,:)=(/bias/)
   flo->V_rmse(ifil,:,:)=(/rmse/)
  end if

  if(Varname.eq."T")then
   flo->T_bias(ifil,:,:)=(/bias/)
   flo->T_rmse(ifil,:,:)=(/rmse/)
  end if

  if(Varname.eq."Q")then
   flo->Q_bias(ifil,:,:)=(/bias/)
   flo->Q_rmse(ifil,:,:)=(/rmse/)
  end if

  end do ; end of file list

  end do ; end of varloop

  end do ; end of igp loop

end

