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

  ModelOutRoot  = "/pic/projects/E3SM_DA/zhan391/dart_paper_materials/DATA/"
  LocalObsRoot1 = ModelOutRoot+"/ERA5_ANL_ENS01/monthly/"
  LocalObsRoot2 = ModelOutRoot+"/NCEP_Reanalysis/monthly/"
  OutRoot      = "./"

  ;;;;;;variables to be plotted;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  VarList      = (/"U"/)
  VobList1     = (/"U"/)  ;; variable for ERA5
  VobList2     = (/"uwnd"/) ;; variable for NCEP reanalysis
  UnitList     = (/"m s~S~-1~N~","K","kg kg~S~-1~N~"/)
  nvars        = dimsizes(VarList)
  year         = 2011
  month        = 1
  nhind        = 5

  ;;;read the pressure levels in ERA5 data;;;;
  obsfile1     = LocalObsRoot1+year+"_0001_plev.nc"
  File1        = addfile(obsfile1,"r")
  pnew         = File1->lev
  pnew!0       = "lev"
  pnew&lev     = pnew
  P0mb         = 1000.                        ; reference pressure [mb]
  delete([/File1,obsfile1/])

 do iv = 0,nvars-1,1

  Varname  = VarList(iv)
  Varnobs1 = VobList1(iv)
  Varnobs2 = VobList2(iv)

  ;;open netcdf file to save the data for plots;;;;;
  setfileoption("nc", "Format",  "NetCDF4")
  out_file_name = "Global_map_e3sm_vs_ERA5_"+Varname+".nc"
  system("rm " + out_file_name)
  fout = addfile(out_file_name,"cw")

  ;;;;;process the 5-year JAN clim vs obs;;;;;
  ;;ERA5 reanalysis 
  filobs1   = systemfunc("ls "+ LocalObsRoot1+"*_plev.nc")
  f1        = addfiles(filobs1,"r")
  varo1     = f1[:]->$Varnobs1$
  ;;NCEP reanalysis;; 
  filobs2   = systemfunc("ls "+ LocalObsRoot2+"*.nc")
  f2        = addfiles(filobs2,"r")
  tmp       = f2[:]->$Varnobs2$
  lev       = f2[0]->level
  ;;;interpolate to the ERA5 vertical levels 
  linlog    = -1
  varo2     = int2p_n_Wrap(lev,tmp,pnew,linlog,1)
  delete([/lev,tmp/])

  ;;;;compare with CLIM 
  filmod   = systemfunc("ls "+ ModelOutRoot+"/PDCLIM_ENS01/cam_h0/monthly/"+"*.nc")
  f3       = addfiles(filmod,"r")
  tmp      = f3[:]->$Varname$
  var2     = vinth2p(tmp,f3[0]->hyam,f3[0]->hybm,pnew,f3[:]->PS,1,P0mb,1,False)
  
  ;;;mask the missing values and do comparison;;;;
  var2     = where (ismissing(varo1),var2@_FillValue, var2)
  var2     = where (ismissing(varo2),var2@_FillValue, var2)
  varo1    = where (ismissing(var2),varo1@_FillValue, varo1)
  varo2    = where (ismissing(var2),varo2@_FillValue, varo2)
  vzmn1    = dim_avg_n_Wrap(dim_avg_n_Wrap(varo1,3),0)
  vzmn2    = dim_avg_n_Wrap(dim_avg_n_Wrap(varo2,3),0)
  vzmn3    = dim_avg_n_Wrap(dim_avg_n_Wrap(var2,3),0)
  
  ;printVarSummary(vzmn1)
  ;printVarSummary(vzmn2)
  ;printVarSummary(vzmn3)

  vzdifo    = vzmn1
  vzdifo    = vzmn2 - vzmn1
  vzdifm    = vzmn1
  vzdifm    = vzmn3 - vzmn1

  ;;;write out he differences beween two reanalyses
  vzmn1@description   = "5-year mean ERA5 (JAN)"
  vzdifo@description  = "5-year mean NCEP - ERA5 (JAN)"
  vzdifm@description  = "5-year mean clim - ERA5 (JAN)"
  varout              = "ERA5_5YR_JAN"
  fout->$varout$      = vzmn1
  varout = "ERA5_NCEP_DIFF_JAN"
  fout->$varout$     = vzdifo
  varout = "CLIM_5YR_JAN_BIAS"
  fout->$varout$     = vzdifm
  delete([/filobs1,filobs2,filmod,f1,f2,f3,var2,varo1,varo2,vzmn1,vzdifo,vzdifm,tmp/])

  ;;;;;process the hindcast simulation for JAN 2011 ;;;;;
  obsfile1  = LocalObsRoot1+year+"_0001_plev.nc"
  File1     = addfile(obsfile1,"r")
  precobs   = File1->$Varnobs1$
 ;printVarSummary(precobs)

  Groups  = (/"PDNUDG_ERA5_HIND_ENS01","PDDART_UVTQ_HIND_ENS80"/)
  ngrps   = dimsizes(Groups)

  do igp  = 0,ngrps-1,1

   do ih  = 1,nhind,1
  
   hindstr    = "day"+ih
   topdir     = ModelOutRoot+Groups(igp)+"/"+hindstr+"/cam_h0/monthly"
   modfils    = systemfunc("ls " + topdir+"/2011_00*.nc")
   f          = addfiles(modfils,"r")
   ListSetType (f, "join")  

   tmp        = f[:]->$Varname$(:,:,:,:,:)
   ps1        = f[:]->PS(:,:,:,:)
   var2       = vinth2p(tmp,f[0]->hyam,f[0]->hybm,pnew,ps1,1,P0mb,1,False)
   var1       = conform(var2,precobs,(/1,2,3,4/))
   ;;;mask out the missing values;;;;
   var2       = where(ismissing(var1),var2@_FillValue,var2)
   var1       = where(ismissing(var2),var1@_FillValue,var1)
  
   ;;;calculate the metrics for the comparison;;;;
   var1_enm   = fout->ERA5_5YR_JAN
   var1_enm   = (/dim_avg_n_Wrap(dim_avg_n_Wrap(dim_avg_n_Wrap(var1,0),0),2)/)
   var2_enm   = fout->ERA5_5YR_JAN
   var2_enm   = (/dim_avg_n_Wrap(dim_avg_n_Wrap(dim_avg_n_Wrap(var2,0),0),2)/)
   
   ;;ensemble mean difference   
   vdifm      = var1_enm
   vdifm      = var2_enm - var1_enm
   ;;ensemble spread 
   vspdm      = var1_enm
   vspdm      = (/dim_avg_n_Wrap(dim_avg_n_Wrap(dim_stddev_n_Wrap(var2,0),0),2)/)

   ;;write out ensemble mean difference;;;;;
   vdifm@description  = "mean hidcast - ERA5 (JAN)"
   varout = Groups(igp)+"_BIAS_"+hindstr
   fout->$varout$     = vdifm
   vspdm@description  = "ensemble spread of 80 monthly means" 
   varout = Groups(igp)+"_SPREAD_"+hindstr
   fout->$varout$     = vspdm
   delete([/f,modfils,tmp,ps1,var1,var2,var1_enm,var2_enm,vdifm,vspdm/])

  end do 

 end do
 
 end do

 delete([/fout/])

end

