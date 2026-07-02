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

  ObsSrc = "CERES_EBAF"
  ModelOutRoot  = "/pic/projects/E3SM_DA/zhan391/dart_paper_materials/DATA/"
  LocalObsRoot  = ModelOutRoot+"/"+ObsSrc+"/monthly/"
  OutRoot       = "./"

  ;;;;;;variables to be plotted;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  VarList      = (/"LWCF"/)
  UnitList     = (/"W m~S~-2~N~"/)
  nvars        = dimsizes(VarList)
  year         = 2011
  month        = 1
  nhind        = 1

  ;;open netcdf file to save the data for plots;;;;;
  setfileoption("nc", "Format",  "NetCDF4")
  out_file_name = "Global_map_e3sm_vs_obs_"+VarList+".nc"
  system("rm " + out_file_name)
  fout = addfile(out_file_name,"c")
 
  ;;;;;process the 5-year JAN clim vs OBS obs;;;;;
  filobs   = systemfunc("ls "+ LocalObsRoot+"*.nc") ; 
  filmod   = systemfunc("ls "+ ModelOutRoot+"/PDCLIM_ENS01/cam_h0/monthly/"+"*.nc")  
  f1       = addfiles(filobs,"r")
  f2       = addfiles(filmod,"r")
  if (VarList.eq."PRECT") then 
    var2     = f2[:]->PRECC
    var2     = f2[:]->PRECC +f2[:]->PRECL
    var2     = var2 * 24.0 * 3600.0 * 1000.0
    var2@units = "mm/day"
  else if (VarList.eq."NETCF") then 
    var2     = f2[:]->SWCF
    var2     = f2[:]->SWCF +f2[:]->LWCF
  else 
    var2     = f2[:]->$VarList$ 
  end if 
  end if 
  var1       = var2

  if(isfilevar(f1[0],"FLUT")) then 
    var1     = (/f1[:]->$VarList$/) 
  else if (isfilevar(f1[0],"OLR"))
    var1     = (/f1[:]->OLR/)
  else
    var1     = (/f1[:]->$VarList$/)
  end if
  end if 

  ;;;calculate the global mean;;; 
  rad      = 4.0*atan(1.0)/180.0
  clat     = cos(f1[0]->lat*rad)
  ogav     = wgt_areaave(var1, clat, 1.0, 0)
  dgav     = wgt_areaave(var2, clat, 1.0, 0)
  rmse     = wgt_arearmse(var1,var2,clat,1.0,0)
  dgav     = dgav - ogav
  
  ;;;calculate pattern correlation (E3SM vs OBS);;
  var1_tmp = var1 - conform(var1,ogav,0) 
  var2_tmp = var2 - conform(var2,dgav,0)
  corr     = pattern_cor(var1_tmp, var2_tmp,tofloat(clat), 1)
  delete([/var1_tmp,var2_tmp/])

  ;;;;difference between OBS and CLIM
  var2     = var2 - var1
  varx1    = dim_avg_n_Wrap(var1,0)
  varx2    = dim_avg_n_Wrap(var2,0)
  varx1!0  = "lat"
  varx1!1  = "lon"
  varx2!0  = "lat"
  varx2!1  = "lon"
  varx1@stats_name   = (/"min","max","mean","std"/)
  varx1@global_mean  = (/min(ogav),max(ogav),avg(ogav),stddev(ogav)/)
  varx2@stats_name   = (/"min","max","mean","std"/)
  varx2@global_mean  = (/min(dgav),max(dgav),avg(dgav),stddev(dgav)/)
  varx2@global_rmse  = (/min(rmse),max(rmse),avg(rmse),stddev(rmse)/)
  varx2@pattn_corr   = (/min(corr),max(corr),avg(corr),stddev(corr)/)
  varx1@description  = "5-year mean "+ObsSrc+" (JAN)"
  varx2@description  = "5-year mean clim - "+ObsSrc+" (JAN)"

  varout = "OBS_5YR_JAN"
  fout->$varout$     = varx1
  varout = "CLIM_5YR_JAN_BIAS"
  fout->$varout$     = varx2

  varo_ref = var1
  vard_ref = var2

  delete([/filobs,filmod,f1,f2,var1,var2,varx1,varx2,dgav,ogav,rmse,varout,corr/])

  ;;;;;process the hindcast simulation for JAN 2011 ;;;;;
  ;;;;read and process observational file 
  obsfile = LocalObsRoot+year+".nc"
  File0   = addfile(obsfile,"r")
  if(isfilevar(File0,"FLUT")) then          
    precobs     = (/File0->$VarList$/)
  else if (isfilevar(File0,"OLR"))
    precobs     = (/File0->OLR/)
  else
    precobs     = (/File0->$VarList$/)
  end if
  end if

  ;;;;process 6-h hindcast simulaiton;;;
  Groups  = (/"PDDART_UVTQ_HIND_ENS80", "PDNUDG_ERA5_HIND_ENS01"/)
  ngrps   = dimsizes(Groups)

  do igp  = 0,ngrps-1,1

   hindstr    = "day5"
   topdir     = ModelOutRoot+Groups(igp)+"/"+hindstr+"/cam_h0/monthly"
   modfils    = systemfunc("ls " + topdir+"/2011_00*.nc")
   f          = addfiles(modfils,"r")
   ListSetType (f, "join")  

   if (VarList.eq."PRECT") then
     var2     = f[:]->PRECC(:,0,:,:)
     var2     = f[:]->PRECC(:,0,:,:) +f[:]->PRECL(:,0,:,:)
     var2     = var2 * 24.0 * 3600.0 * 1000.0
     var2@units = "mm/day"
   else if (VarList.eq."NETCF") then
     var2     = f[:]->SWCF(:,0,:,:)
     var2     = f[:]->SWCF(:,0,:,:) +f[:]->LWCF(:,0,:,:)
   else
     var2     = f[:]->$VarList$(:,0,:,:)
   end if
   end if

   var2_enm   = dim_avg_n_Wrap(var2,0)      ;;ensemble mean
   var1_enm   = dim_avg_n_Wrap(precobs,0)  ;;5-yr mean
   vard2      = var2
   vard2      = var2 - conform(var2,var1_enm,(/1,2/)) 
   var2_spd   = var2_enm
   var2_spd   = (/dim_stddev_n_Wrap(var2,0)/)

   ;;do the Student's t-test;;;;
   ;;The returned probability is two-tailed;;;;
   prob  = var2(0,:,:)
   sigr  = 0.05                         ; critical sig lvl for r
   xtmp  = vard_ref(lat|:,lon|:,time|:) ; reorder but do it only once [temporary]
   ytmp  = vard2(lat|:,lon|:,ncl_join|:)
   xAve  = dim_avg (xtmp)               ; calculate means at each grid point 
   yAve  = dim_avg (ytmp)
   xVar  = dim_variance (xtmp)          ; calculate variances
   yVar  = dim_variance (ytmp)
   xEqv  = equiv_sample_size (xtmp, sigr,0)
   yEqv  = equiv_sample_size (ytmp, sigr,0)
   xN    = wgt_areaave (xEqv, clat, 1., 0)    ; wgty could be gaussian weights 
   yN    = wgt_areaave (yEqv, clat, 1., 0) 
   iflag = True                        ; population variance similar
   prob  = ttest(xAve,xVar,xN,yAve,yVar,yN, iflag, False) 
   prob  = 100.*(1. - prob) ;; conver to significance level 
   delete([/xtmp,ytmp,xAve,yAve,xVar,yVar,xEqv,yEqv,xN,yN/])  

   ;;;calculate the global mean;;;
   rad      = 4.0*atan(1.0)/180.0
   clat     = cos(f[0]->lat*rad)
   ogav     = wgt_areaave(var1_enm, clat, 1.0, 0)
   mgav     = wgt_areaave(var2_enm, clat, 1.0, 0) 
   mspd     = wgt_areaave(var2_spd, clat, 1.0, 0)
   mgbias   = mgav - ogav
   mgrmse   = wgt_arearmse(var2_enm,var1_enm,clat,1.0,0)
   egav     = wgt_areaave(var2, clat, 1.0, 0) 
   egbias   = egav - ogav
   egrmse   = wgt_arearmse(var2,conform(var2,var1_enm,(/1,2/)),clat,1.0,0)
    
   ;;;calculate pattern correlation;;
   vard1_enm = dim_avg_n_Wrap(vard_ref,0)
   vard2_enm = var2_enm - var1_enm
   mn1       = wgt_areaave(vard1_enm, clat, 1.0, 0)
   mn2       = wgt_areaave(vard2_enm, clat, 1.0, 0)
   vard1_enm = vard1_enm - mn1
   vard2_enm = vard2_enm - mn2
   mpcorr    = pattern_cor(vard1_enm, vard2_enm,tofloat(clat), 0)
   vard1     = conform(vard2,vard1_enm,(/1,2/))
   mn3       = wgt_areaave(vard2, clat, 1.0, 0)
   vard2     = vard2 - conform(vard2,mn3,0) 
   epcorr    = pattern_cor(vard1, vard2,tofloat(clat), 0)
   delete([/mn1,mn2,mn3,vard1_enm,vard2_enm,vard1,vard2/])

   ;;write out ensemble mean fields;;;;;
   varx2     = var2_enm 
   varx2     = var2_enm - var1_enm
   varx2!0   = "lat"
   varx2!1   = "lon"

   prob!0    = "lat"
   prob!1    = "lon"

   varx2@stats_name   = (/"min","max","mean","std"/)
   varx2@global_mean  = (/min(egbias),max(egbias),mgbias,stddev(egbias)/)
   varx2@global_rmse  = (/min(egrmse),max(egrmse),mgrmse,stddev(egrmse)/)
   varx2@pattn_corr   = (/min(epcorr),max(epcorr),mpcorr,stddev(epcorr)/)
   varx2@description  = "mean hidcast - TRMM (JAN)"
   var2_spd@description = "ensemble spread" 
   var2_spd@global_mean = mspd
   varout = Groups(igp)+"_BIAS_"+hindstr
   fout->$varout$     = varx2
   varout = Groups(igp)+"_TTEST_"+hindstr
   fout->$varout$     = prob
   varout = Groups(igp)+"_SPREAD_"+hindstr
   fout->$varout$     = var2_spd
   delete([/f,prob,varx2,modfils,epcorr,mpcorr/])
   delete([/egrmse,mgrmse,mgbias,egbias,ogav,egav/])
   delete([/var1_enm,var2_enm,var2,var2_spd/])

 end do
 
 delete([/fout/])

end

