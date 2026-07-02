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

  ModelOutRoot = "/pic/projects/E3SM_DA/zhan391/dart_paper_materials/DATA/"
  LocalObsRoot = ModelOutRoot+"/GPCP/monthly/"
  OutRoot      = "./"

  ;;;;;;variables to be plotted;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  VarList      = (/"PRECT"/)
  UnitList     = (/"mm day~S~-1~N~"/)
  nvars        = dimsizes(VarList)
  year         = 2011
  month        = 1
  nhind        = 5

  ;;open netcdf file to save the data for plots;;;;;
  setfileoption("nc", "Format",  "NetCDF4")
  out_file_name = "Global_map_e3sm_vs_GPCP_"+VarList+".nc"
  system("rm " + out_file_name)
  fout = addfile(out_file_name,"c")
 
  ;;;;;process the 5-year JAN clim vs obs;;;;;
  filobs   = systemfunc("ls "+ LocalObsRoot+"*.nc")
  filmod   = systemfunc("ls "+ ModelOutRoot+"/PDCLIM_ENS01/cam_h0/monthly/"+"*.nc")  
  f1       = addfiles(filobs,"r")
  f2       = addfiles(filmod,"r")
  var2     = f2[:]->PRECC
  var2     = f2[:]->PRECC +f2[:]->PRECL
  var2     = var2 * 24.0 * 3600.0 * 1000.0
  var2@units = "mm/day"
  var1     = var2
  var1     = (/f1[:]->PRECT/)

  ;;do the Student's t-test;;;;
  ;;The returned probability is two-tailed;;;;
  prob  = var1(0,:,:)
  rad   = 4.0*atan(1.0)/180.0
  clat  = cos(f1[0]->lat*rad)
  sigr  = 0.05                         ; critical sig lvl for r
  xtmp  = var1(lat|:,lon|:,time|:) ; reorder but do it only once [temporary]
  ytmp  = var2(lat|:,lon|:,time|:)
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
  prob!0  = "lat"
  prob!1  = "lon"
  delete([/xtmp,ytmp,xAve,yAve,xVar,yVar,xEqv,yEqv,xN,yN/])

  ;;;calculate the global mean;;; 
  rad      = 4.0*atan(1.0)/180.0
  clat     = cos(f1[0]->lat*rad)
  ogav     = wgt_areaave(var1, clat, 1.0, 0)
  dgav     = wgt_areaave(var2, clat, 1.0, 0)
  rmse     = wgt_arearmse(var1,var2,clat,1.0,0)
  dgav     = dgav - ogav

  ;;;calculate pattern correlation;;
  var1_tmp = var1 - conform(var1,ogav,0) 
  var2_tmp = var2 - conform(var2,dgav,0)
  corr     = pattern_cor(var1_tmp, var2_tmp,tofloat(clat), 0)
  delete([/var1_tmp,var2_tmp/])

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
  varx1@description  = "5-year mean GPCP (JAN)"
  varx2@description  = "5-year mean clim - GPCP (JAN)"
  varout = "GPCP_5YR_JAN"
  fout->$varout$     = varx1
  varout = "CLIM_5YR_JAN_BIAS"
  fout->$varout$     = varx2
  varout = "CLIM_5YR_JAN_TTEST"
  fout->$varout$     = prob

  varo_ref = var1
  vard_ref = var2

  delete([/filobs,filmod,f1,f2,var1,var2,varx1,varx2,dgav,ogav,rmse,varout,corr,prob/])

  ;;;;;process the hindcast simulation for JAN 2011 ;;;;;
  ;;;;read and process observational file 
  obsfile = LocalObsRoot+year+".nc"
  File0   = addfile(obsfile,"r")
  precobs = File0->$VarList$(0,:,:)

  ;;;;process hindcast simulation;;;
  Groups  = (/"PDDART_UVT_HIND_ENS80", "PDDART_UVTQ_HIND_ENS80", \
              "PDNUDG_UV_HIND_ENS20","PDNUDG_ERA5_HIND_ENS01"/)
  ngrps   = dimsizes(Groups)

  do igp  = 0,ngrps-1,1

   do ih  = 1,nhind,1
  
   hindstr    = "day"+ih
   topdir     = ModelOutRoot+Groups(igp)+"/"+hindstr+"/cam_h0/monthly"
   modfils    = systemfunc("ls " + topdir+"/2011*.nc")
   f          = addfiles(modfils,"r")
   ListSetType (f, "join")  

   var2       = f[:]->PRECC(:,0,:,:)
   var2       = f[:]->PRECC(:,0,:,:)+f[:]->PRECL(:,0,:,:)
   var2       = var2 * 24.0 * 3600.0 * 1000.0
   var2@units = "mm/day"
   var2_enm   = dim_avg_n_Wrap(var2,0)      ;;ensemble mean
   var1_enm   = precobs ;dim_avg_n_Wrap(varo_ref,0)  ;;5-yr mean

   vard2      = var2
   vard2      = var2 - conform(var2,var1_enm,(/1,2/)) 
  
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
   varx2@description  = "mean hidcast - GPCP (JAN)"
   varout = Groups(igp)+"_BIAS_"+hindstr
   fout->$varout$     = varx2
   varout = Groups(igp)+"_TTEST_"+hindstr
   fout->$varout$     = prob
   delete([/f,prob,varx2,modfils,epcorr,mpcorr/])
   delete([/egrmse,mgrmse,mgbias,egbias,ogav,egav/])
   delete([/var1_enm,var2_enm,var2/])

  end do 

 end do
 
 delete([/fout/])

end

