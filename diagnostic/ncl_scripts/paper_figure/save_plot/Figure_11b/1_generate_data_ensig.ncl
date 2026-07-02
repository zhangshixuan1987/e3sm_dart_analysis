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
  VarList      = (/"U","T"/)
  VobList1     = (/"U","T"/)  ;; variable for ERA5
  VobList2     = (/"uwnd","air"/) ;; variable for NCEP reanalysis
  UnitList     = (/"m s~S~-1~N~","K","kg kg~S~-1~N~"/)
  nvars        = dimsizes(VarList)
  year         = 2011
  month        = 1
  nhind        = 5

  P0mb         = 1000.                        ; reference pressure [mb]
  pnew         = (/10,30,50,70,100,150,200,250,300,400,500,600,700,850,925,1000/)
  pnew@units   = "hPa"
  pnew!0       = "lev"
  pnew&lev     = pnew

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
  filobs   = systemfunc("ls "+ LocalObsRoot1+"*_plev.nc")
  f1       = addfiles(filobs,"r")
  print(filobs)
  tmp      = f1[:]->$Varnobs1$
  lev      = f1[0]->lev
  linlog   = -1
  tmp1     = int2p_n_Wrap(lev,tmp,pnew,linlog,1)
  var1     = dim_avg_n_Wrap(tmp1,3)
  delete([/lev,tmp,tmp1/])

  filmod   = systemfunc("ls "+ ModelOutRoot+"/PDCLIM_ENS01/cam_h0/monthly/"+"*.nc")
  f2       = addfiles(filmod,"r")
  tmp      = f2[:]->$Varname$
  tmp1     = vinth2p(tmp,f2[0]->hyam,f2[0]->hybm,pnew,f2[:]->PS,1,P0mb,1,False)
  var2     = dim_avg_n_Wrap(tmp1,3)
  delete([/tmp,tmp1/])

  var2     = var2 - var1
  varx1    = (/dim_avg_n_Wrap(var1,0)/)
  varx2    = (/dim_avg_n_Wrap(var2,0)/)
  varx1!0  = "lev"
  varx1!1  = "lat"
  varx2!0  = "lev"
  varx2!1  = "lat"

  varx1@description  = "5-year mean ERA5 (JAN)"
  varx2@description  = "5-year mean clim - ERA5 (JAN)"

  varx1&lev = pnew
  varx1&lat = var1&lat
  varx2&lev = pnew
  varx2&lat = var1&lat

  varout = "ERA5_5YR_JAN"
  fout->$varout$     = varx1
  varout = "CLIM_5YR_JAN_BIAS"
  fout->$varout$     = varx2

  varo_ref = varx1

  delete([/filobs,filmod,f1,f2,var1,var2,varx1,varx2,varout/])

  ;;;;;process the hindcast simulation for JAN 2011 ;;;;;
  ;;;ERA5 reanalysis;;;;;
  obsfile1  = LocalObsRoot1+year+"_0001_plev.nc"
  File1     = addfile(obsfile1,"r")
  tmp       = File1->$Varnobs1$
  lev       = File1->lev
  linlog    = -1
  pre3d     = int2p_n_Wrap(lev,tmp,pnew,linlog,1)
  precobs   = dim_avg_n_Wrap(dim_avg_n_Wrap(pre3d,3),0)
  delete([/lev,tmp/])
 ;printVarSummary(precobs)

  ;;;NCEP reanalysis
  obsfile2  = LocalObsRoot2+year+".nc"
  File2     = addfile(obsfile2,"r")
  tmp       = File2->$Varnobs2$
  lev       = File2->level
  linlog    = -1
  pre3d2    = int2p_n_Wrap(lev,tmp,pnew,linlog,1)
  precobs2  = dim_avg_n_Wrap(dim_avg_n_Wrap(pre3d2,3),0)
  precobs2  = precobs2 - precobs

  ;;;write out he differences beween two reanalyses
  varout = "ERA5_NCEP_DIFF_JAN"
  fout->$varout$     = precobs2
  delete([/lev,tmp,pre3d2,precobs2/])
 
  ;;;;process day1 - day 5 hindcast simulation;;;
  ;Groups  = (/"PDDART_UVT_HIND_ENS80", "PDDART_UVTQ_HIND_ENS80", \
  ;            "PDNUDG_UV_HIND_ENS20","PDNUDG_ERA5_HIND_ENS01"/)

  Groups  = (/"PDNUDG_ERA5_HIND_ENS01","PDDART_UVTQ_HIND_ENS80"/)
  ngrps   = dimsizes(Groups)

  do igp  = 0,ngrps-1,1

   do ih  = 1,nhind,1
  
   hindstr    = "day"+ih
   topdir     = ModelOutRoot+Groups(igp)+"/"+hindstr+"/cam_h0/monthly"
   modfils    = systemfunc("ls " + topdir+"/2011_00*.nc")
   f          = addfiles(modfils,"r")
   ListSetType (f, "join")  

   var1       = f[:]->$Varname$(:,:,:,:,:)
   ps1        = f[:]->PS(:,:,:,:)
   var2       = vinth2p(var1,f[0]->hyam,f[0]->hybm,pnew,ps1,1,P0mb,1,False)
   var2_enm   = dim_avg_n_Wrap(dim_avg_n_Wrap(dim_avg_n_Wrap(var2,0),0),2)
   var1_enm   = precobs
   printVarSummary(pre3d)
   printVarSummary(var2)
   vspd       = var2 - conform(var2,pre3d,(/1,2,3,4/))
   var2_spd   = precobs
   var2_spd   = (/dim_avg_n_Wrap(dim_avg_n_Wrap(dim_stddev_n_Wrap(vspd,0),0),2)/)

   printVarSummary(var2_enm)
   printVarSummary(var1_enm)
   printVarSummary(var2_spd)
   ;;write out ensemble mean fields;;;;;
   varx2     = varo_ref
   varx2     = var2_enm - var1_enm
   printVarSummary(varx2)
   varx2@description  = "mean hidcast - ERA5 (JAN)"
   varout = Groups(igp)+"_BIAS_"+hindstr
   fout->$varout$     = varx2
   varout = Groups(igp)+"_SPREAD_"+hindstr
   fout->$varout$     = var2_spd
   delete([/f,varx2,var2_spd,vspd,modfils/])
   delete([/var1_enm,var2_enm,var2,var1,ps1/])

  end do 

 end do
 
 end do

 delete([/fout/])

end

