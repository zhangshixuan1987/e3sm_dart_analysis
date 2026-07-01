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
  LocalObsRoot1 = ModelOutRoot+"/GPCP/monthly/"
  LocalObsRoot2 = ModelOutRoot+"/CERES_EBAF/monthly/"
  OutRoot       = "./"

  ;;;subregions used by the analyses;;;;;;;;;;;;;;;;
  Subreg        = (/ "Global",  "MidLat",  "Tropics"/)
  minlat        = (/ -90.0,        25.0,     -20.0/)
  maxlat        = (/  90.0,        55.0,      20.0/)
  minlon        = (/   0.0,         0.0,       0.0/)
  maxlon        = (/ 360.0,       360.0,     360.0/)
  nsubreg       = dimsizes(Subreg)

  ;;;;;;variables to be plotted;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  VarList       = (/"PRECT","FLUT"/)
  UnitList      = (/"mm day~S~-1~N~","W m~S~-2~N~"/)
  nvars         = dimsizes(VarList)

  year          = 2011
  month         = 1
  nhind         = 5

 do irg = 0, nsubreg -1,1
 
  lat1 = minlat(irg)
  lat2 = maxlat(irg)
  lon1 = minlon(irg)
  lon2 = maxlon(irg)

  ;;open netcdf file to save the data for plots;;;;;
  setfileoption("nc", "Format",  "NetCDF4")
  out_file_name = "Time_series_dart_vs_hybridIC_mean_"+Subreg(irg)+".nc"
  system("rm " + out_file_name)
  fout = addfile(out_file_name,"c")
 
  do iv = 0,nvars-1,1
  
   Varname = VarList(iv)
   Varunit = UnitList(iv)
  
   if(Varname.eq."PRECT") then
    LocalObsRoot = LocalObsRoot1
   else
    LocalObsRoot = LocalObsRoot2 
   end if 

   ;;;;;process the 5-year JAN clim vs obs;;;;;
   filobs     = systemfunc("ls "+ LocalObsRoot+"*.nc")
   filmod     = systemfunc("ls "+ ModelOutRoot+"/PDCLIM_ENS01/cam_h0/monthly/"+"*.nc")  
   f1         = addfiles(filobs,"r")
   f2         = addfiles(filmod,"r")

   if(Varname.eq."PRECT") then 
    var2       = f2[:]->PRECC
    var2       = f2[:]->PRECC +f2[:]->PRECL
    var2       = var2 * 24.0 * 3600.0 * 1000.0
    var2@units = Varunit
    var1       = var2
    var1       = (/f1[:]->PRECT/)
   else
    var2       = f2[:]->$Varname$
    var2@units = Varunit
    var1       = var2
    var1       = (/f1[:]->$Varname$/)
   end if 

   ;;;calculate the global mean;;; 
   rad      = 4.0*atan(1.0)/180.0
   clat     = f1[0]->lat
   clat     = cos(f1[0]->lat*rad)
   ;;;calculate the mean values;;;
   gmean1   = wgt_areaave(var1(:,{lat1:lat2},{lon1:lon2}), clat({lat1:lat2}), 1.0, 0)
   grmsd1   = (/dim_stddev_n_Wrap(gmean1,0)/)
   genmn1   = (/dim_avg_n_Wrap(gmean1,0)/)
   gmean2   = wgt_areaave(var2(:,{lat1:lat2},{lon1:lon2}), clat({lat1:lat2}), 1.0, 0)
   grmsd2   = (/dim_stddev_n_Wrap(gmean2,0)/)
   genmn2   = (/dim_avg_n_Wrap(gmean2,0)/)
 
   grmsd1!0  = "time"
   genmn1!0  = "time"
   varout = "OBS_"+Varname + "_5yr_MEAN"
   fout->$varout$ = genmn1
   varout = "OBS_"+Varname + "_5yr_RMSD"
   fout->$varout$ = grmsd1

   grmsd2!0  = "time"
   genmn2!0  = "time"
   varout = "CLIM_"+Varname + "_5yr_MEAN"
   fout->$varout$ = genmn2
   varout = "CLIM_"+Varname + "_5yr_RMSD"
   fout->$varout$ = grmsd2
   delete([/filobs,filmod,f1,f2,var1,var2,gmean1,gmean2,grmsd1,grmsd2,genmn1,genmn2/])

  ;;;;;process the hindcast simulation for JAN 2011 ;;;;;
   Groups  = (/"PDDART_UVTQ_HIND_ENS80", "PDNUDG_ERA5_HIND_ENS01"/)
   ngrps   = dimsizes(Groups)

  do igp  = 0,ngrps-1,1

   genmn  = new((/1,nhind/),double)
   grmsd  = new((/1,nhind/),double)

   do ih  = 1,nhind,1
  
    hindstr    = "day"+ih
    topdir     = ModelOutRoot+Groups(igp)+"/"+hindstr+"/cam_h0/monthly"
    modfils    = systemfunc("ls " + topdir+"/2011_00*.nc")
    f           = addfiles(modfils,"r")
    ListSetType (f, "join")  

    if(Varname.eq."PRECT") then
     var2       = f[:]->PRECC(:,:,:,:)
     var2       = f[:]->PRECC(:,:,:,:) +f[:]->PRECL(:,:,:,:)
     var2       = var2 * 24.0 * 3600.0 * 1000.0
     var2@units = Varunit
    else
     var2       = f[:]->$Varname$(:,:,:,:)
     var2@units = Varunit
    end if

    ;;;calculate the global mean;;;
    rad      = 4.0*atan(1.0)/180.0
    clat     = f[0]->lat
    clat     = cos(f[0]->lat*rad)
    ;;;calculate the mean values;;;
    gmean           = wgt_areaave(var2(:,0,{lat1:lat2},{lon1:lon2}), clat({lat1:lat2}), 1.0, 0)
    grmsd(0,ih-1)   = (/dim_stddev_n_Wrap(gmean,0)/)
    genmn(0,ih-1)   = (/dim_avg_n_Wrap(gmean,0)/)
    delete([/var2,clat,modfils,f,gmean/])
   end do 

   grmsd!0 = "time"
   grmsd!1 = "nhind"
   genmn!0 = "time"
   genmn!1 = "nhind"
   varout = Groups(igp)+"_"+Varname +"_JAN_MEAN"
   fout->$varout$     = genmn
   varout = Groups(igp)+"_"+Varname +"_JAN_RMSD"
   fout->$varout$     = grmsd
  
   delete([/grmsd,genmn/])
  end do 

 end do
 
 delete([/fout/])
 end do 

end

