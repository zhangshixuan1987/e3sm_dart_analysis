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


  AmwgObsRoot  = "/pic/projects/uq_climate/zhan391/climate_analysis/obs_data_20140804/"
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
 
  ;;;;;process the ANN clim vs obs;;;;; 
  filobs  = AmwgObsRoot + "GPCP_ANN_climo.nc" 
  filmod  = ModelOutRoot +"PDCLIM_ENS01/climo/PDFREE_F20TRC5-AMIP_f19_d025_ANN_climo.nc"
  f1 = addfile(filobs,"r")    
  f2 = addfile(filmod,"r")
  var2 = f2->PRECC(0,:,:)
  var2 = f2->PRECC(0,:,:) + f2->PRECL(0,:,:)
  var1 = linint2_Wrap(f1->lon,f1->lat,f1->PRECT(0,:,:),True,var2&lon,var2&lat,0)
  var2 = var2 * 24.0 * 3600.0 * 1000.0 ; convert to mm/day
  var2@units = "mm/day"
  var2 = var2 - var1
  var_ref1 = var2 

  ;;;calculate the global mean;;;
  rad  = 4.0*atan(1.0)/180.0
  clat = cos(f2->lat*rad)
  dgav = wgt_areaave(var2, clat, 1.0, 0)
  ogav = wgt_areaave(var1, clat, 1.0, 0)
  rmse = wgt_arearmse(var1,var2,clat,1.0,0)

  varx1 = var1
  varx2 = var2
  varx1!0 = "lat"
  varx1!1 = "lon"
  varx2!0 = "lat"
  varx2!1 = "lon"
  varx1@stats_name   = (/"min","max","mean","std"/)
  varx1@global_mean  = (/min(ogav),max(ogav),avg(ogav),stddev(ogav)/)
  varx2@stats_name   = (/"min","max","mean","std"/)
  varx2@global_mean  = (/min(dgav),max(dgav),avg(dgav),stddev(dgav)/)
  varx2@global_rmse  = (/min(rmse),max(rmse),avg(rmse),stddev(rmse)/)
  varx2@pattn_corr   = (/0.,0.,0.,0.,0./)
  varx1@description  = "5-year mean GPCP (ANN)"
  varx2@description  = "5-year mean clim - GPCP (ANN)"
  varout = "GPCP_5YR_ANN"
  fout->$varout$    = varx1
  varout = "CLIM_5YR_ANN_BIAS"
  fout->$varout$    = varx2
  delete([/filobs,filmod,f1,f2,var1,var2,varx1,varx2,dgav,ogav,rmse,varout/])

  ;;;;;process the 5-year JAN clim vs obs;;;;;
  filobs  = systemfunc("ls "+ LocalObsRoot+"*.nc")
  filmod  = systemfunc("ls "+ ModelOutRoot+"/PDCLIM_ENS01/cam_h0/monthly/"+"*.nc")  
  f1 = addfiles(filobs,"r")
  f2 = addfiles(filmod,"r")
  var1 = f1[:]->PRECT
  var2 = f2[:]->PRECC
  var2 = f2[:]->PRECC + f2[:]->PRECL
  var2 = var2 * 24.0 * 3600.0 * 1000.0
  var2@units = "mm/day"
  var2 = var2 - var1
  var_ref2 = dim_avg_n_Wrap(var2,0)

  ;;;calculate the global mean;;; 
  rad  = 4.0*atan(1.0)/180.0
  clat = cos(f1[0]->lat*rad)
  dgav = wgt_areaave(var2, clat, 1.0, 0)
  ogav = wgt_areaave(var1, clat, 1.0, 0)
  rmse = wgt_arearmse(var1,var2+var1,clat,1.0,0)
 
  ;;;calculate pattern correlation;;
  varref = conform(var2,var_ref1,(/1,2/))
  corr = pattern_cor(var2, varref,tofloat(clat), 1)
  
  varx1 = (/dim_avg_n_Wrap(var1,0)/)
  varx2 = (/dim_avg_n_Wrap(var2,0)/)
  varx1!0 = "lat"
  varx1!1 = "lon"
  varx2!0 = "lat"
  varx2!1 = "lon"
  varx1@stats_name   = (/"min","max","mean","std"/)
  varx1@global_mean  = (/min(ogav),max(ogav),avg(ogav),stddev(ogav)/)
  varx2@stats_name   = (/"min","max","mean","std"/)
  varx2@global_mean  = (/min(dgav),max(dgav),avg(dgav),stddev(dgav)/)
  varx2@global_rmse  = (/min(rmse),max(rmse),avg(rmse),stddev(rmse)/)
  varx2@pattn_corr   = (/min(corr),max(corr),avg(corr),stddev(corr)/)
  varx1@description  = "5-year mean GPCP (JAN)"
  varx2@description  = "5-year mean clim - GPCP (JAN)"
  varout = "GPCP_5YR_JAN"
  fout->$varout$    = varx1
  varout = "CLIM_5YR_JAN_BIAS"
  fout->$varout$    = varx2
  delete([/filobs,filmod,f1,f2,var1,var2,varx1,varx2,dgav,ogav,rmse,varout,varref,corr/])

  ;;;;;process the hindcast simulation for JAN 2011 ;;;;;
  ;;;;read and process observational file 
  obsfile = LocalObsRoot+year+".nc"
  File0   = addfile(obsfile,"r")
  precobs = File0->$VarList$(0,:,:)

  filmod  = ModelOutRoot+"/PDCLIM_ENS01/cam_h0/monthly/2011_0001.nc"
  File1   = addfile(filmod,"r")
  var2    = File1->PRECC(0,:,:)
  var2    = File1->PRECC(0,:,:) + File1->PRECL(0,:,:)
  var2    = var2 * 24.0 * 3600.0 * 1000.0
  var2@units = "mm/day"
  var2    = var2 - precobs

  ;;;calculate the global mean;;;
  rad  = 4.0*atan(1.0)/180.0
  clat = cos(File1->lat*rad)
  dgav = wgt_areaave(var2, clat, 1.0, 0)
  ogav = wgt_areaave(precobs, clat, 1.0, 0)
  rmse = wgt_arearmse(precobs,var2+precobs,clat,1.0,0)

  ;;;calculate pattern correlation;;
  varref = var_ref2
  corr   = pattern_cor(var2, varref,tofloat(clat), 1)

  varx1 = (/precobs/)
  varx2 = (/var2/)
  varx1!0 = "lat"
  varx1!1 = "lon"
  varx2!0 = "lat"
  varx2!1 = "lon"
  varx1@stats_name   = (/"min","max","mean","std"/)
  varx1@global_mean  = (/min(ogav),max(ogav),avg(ogav),stddev(ogav)/)
  varx2@stats_name   = (/"min","max","mean","std"/)
  varx2@global_mean  = (/min(dgav),max(dgav),avg(dgav),stddev(dgav)/)
  varx2@global_rmse  = (/min(rmse),max(rmse),avg(rmse),stddev(rmse)/)
  varx2@pattn_corr   = (/min(corr),max(corr),avg(corr),stddev(corr)/)
  varx1@description  = "mean GPCP (JAN)"
  varx2@description  = "mean clim - GPCP (JAN)"
  varout = "GPCP_JAN"
  fout->$varout$    = varx1
  varout = "CLIM_JAN_BIAS"
  fout->$varout$    = varx2
  delete([/filmod,File1,var2,varx1,varx2,dgav,ogav,rmse,varout,varref,corr/])

  ;;;;process hindcast simulation;;;
  Groups  = (/"PDDART_UVT_HIND_ENS80", "PDDART_UVTQ_HIND_ENS80", \
              "PDNUDG_UV_HIND_ENS20","PDNUDG_ERA5_HIND_ENS01"/)
  ngrps   = dimsizes(Groups)

  do igp = 0,ngrps-1,1

   do ih = 1,nhind,1
  
   hindstr  = "day"+ih
   topdir   = ModelOutRoot+Groups(igp)+"/"+hindstr+"/cam_h0/monthly"
   modfils  = systemfunc("ls " + topdir+"/2011*.nc")
   f        = addfiles(modfils,"r")
   ListSetType (f, "join")  

   var2       = f[:]->PRECC(:,0,:,:)
   var2       = f[:]->PRECC(:,0,:,:) + f[:]->PRECL(:,0,:,:) 
   var2       = var2 * 1000.0 * 24.0 * 3600.0
   var2@units = "mm/day"

   var1       = conform(var2,precobs,(/1,2/))
   copy_VarCoords(var2,var1)
   vard       = var2
   vard       = var2 - var1

   ;;do the Student's t-test;;;;
   ;;The returned probability is two-tailed;;;;
   sigr = 0.05                        ; critical sig lvl for r
   xtmp = var1(lat|:,lon|:,ncl_join|:)       ; reorder but do it only once [temporary]
   ytmp = var2(lat|:,lon|:,ncl_join|:)
   xAve = dim_avg (xtmp)              ; calculate means at each grid point 
   yAve = dim_avg (ytmp)
   xVar = dim_variance (xtmp)         ; calculate variances
   yVar = dim_variance (ytmp)
   xEqv = equiv_sample_size (xtmp, sigr,0)
   yEqv = equiv_sample_size (ytmp, sigr,0)
   xN   = wgt_areaave (xEqv, clat, 1., 0)    ; wgty could be gaussian weights 
   yN   = wgt_areaave (yEqv, clat, 1., 0) 
   xN = 80
   yN = 80
   iflag= True                        ; population variance similar
   prob = ttest(xAve,xVar,xN, yAve,yVar,yN, iflag, False) 
   prob = 100.*(1. - prob) ;; conver to significance level 
   delete([/xtmp,ytmp,xAve,yAve,xVar,yVar,xEqv,yEqv,xN,yN/])  
  
   ;;;calculate the global mean;;;
   rad  = 4.0*atan(1.0)/180.0
   clat = cos(f[0]->lat*rad)
   dgav = wgt_areaave(vard, clat, 1.0, 0)
   rmse = wgt_arearmse(var1,var2,clat,1.0,0)

   ;;;calculate pattern correlation;;
   varref = conform(vard,var_ref2,(/1,2/))
   corr   = pattern_cor(vard, varref,tofloat(clat), 0)
   encorr = pattern_cor(dim_avg_n_Wrap(vard,0), var_ref2,tofloat(clat), 0)

   ;;write out ensemble mean fields;;;;;
   varx2 = (/dim_avg_n_Wrap(vard,0)/)
   varx2!0 = "lat"
   varx2!1 = "lon"
   prob!0  = "lat"
   prob!1  = "lon"
   varx2@stats_name   = (/"min","max","mean","std"/)
   varx2@global_mean  = (/min(dgav),max(dgav),avg(dgav),stddev(dgav)/)
   varx2@global_rmse  = (/min(rmse),max(rmse),avg(rmse),stddev(rmse)/)
   varx2@pattn_corr   = (/min(corr),max(corr),avg(encorr),stddev(corr)/)
   varx2@description  = "mean hidcast - GPCP (JAN)"
   varout = Groups(igp)+"_BIAS_"+hindstr
   fout->$varout$     = varx2
   varout = Groups(igp)+"_TTEST_"+hindstr
   fout->$varout$     = prob
   delete([/f,var1,var2,vard,prob,varx2,modfils,dgav,rmse,varref,corr/])
 
  end do 

 end do
 
 delete([/fout/])

end

