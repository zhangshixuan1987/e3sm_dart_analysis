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
  OutRoot      = "./"

  ;;;;;;variables to be plotted;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  Varname     = (/"PRECT","FLUT","CLDTOT"/)
  Varunit     = (/"mm day~S~-1~N~","W m~S~-2~N~","fraction"/)
  nvars        = dimsizes(Varname)

  year         = 2011
  month        = 1
  nhind        = 5

  ;;open netcdf file to save the data for plots;;;;;
  setfileoption("nc", "Format",  "NetCDF4")
  out_file_name = "Time_series_dart_vs_hybridIC.nc"
  system("rm " + out_file_name)
  fout = addfile(out_file_name,"c")
 
  ;;;;;process the 5-year JAN clim vs obs;;;;;
  filmod   = systemfunc("ls "+ ModelOutRoot+"/PDCLIM_ENS01/cam_h0/monthly/"+"*.nc")
  f1       = addfiles(filmod,"r")
  do iv    = 0,nvars-1,1
   if(Varname(iv).eq."PRECT") then
     var1  = f1[:]->PRECC(:,:,:)
     var1  = f1[:]->PRECC(:,:,:)+f1[:]->PRECL(:,:,:)
     var1  = var1 * 24.0 * 3600.0 * 1000.0
     var1@units = Varunit(iv)
   else
     var1       = f1[:]->$Varname(iv)$(:,:,:)
     var1@units = Varunit(iv)
   end if
   ;;;calculate the global mean;;;
   rad      = 4.0*atan(1.0)/180.0
   clat     = cos(f1[0]->lat*rad)
   gmean    = wgt_areaave(var1, clat, 1.0, 0)
   grmsd    = (/dim_stddev_n_Wrap(gmean,0)/)
   genmn    = (/dim_avg_n_Wrap(gmean,0)/)
   grmsd!0  = "time0"
   genmn!0  = "time0"
   varout = "CLIM_"+Varname(iv) + "_MEAN"
   fout->$varout$ = genmn
   varout = "CLIM_"+Varname(iv) + "_RMSD"
   fout->$varout$ = grmsd
   delete([/var1,gmean,grmsd,genmn/])
  end do 

  ;;;;process hindcast simulaiton;;;
  Groups  = (/"PDDART_UVT_HIND_ENS80", "PDDART_UVTQ_HIND_ENS80", "PDNUDG_ERA5_HIND_ENS01"/)
  ngrps   = dimsizes(Groups)

  do igp  = 0,ngrps-1,1

   if(isStrSubset(Groups(igp),"ENS01"))then 
     hindstr    = "hind_ensemble/enmn"
   else
    hindstr    = "hind_ensemble/0001"
   end if 
   topdir     = ModelOutRoot+Groups(igp)+"/"+hindstr+"/"
   modfils    = systemfunc("ls " + topdir+"/2011*.nc")
   f          = addfiles(modfils,"r")
   ListSetType (f, "join")  
   print(modfils)
   
   do iv = 0,nvars-1,1

    time       = (/f[0]->time/)
    time       = (time -time(0))* 24.0 ; convert to hours
    time!0     = "time"
    time&time  = time
    time@units = "Forecast lead time"

    if(Varname(iv).eq."PRECT") then 

     var2       = f[:]->PRECC(:,:,:,:)
     var2       = f[:]->PRECC(:,:,:,:)+f[:]->PRECL(:,:,:,:)
     var2       = var2 * 24.0 * 3600.0 * 1000.0
     var2@units = Varunit(iv)

    else if (Varname(iv).eq."CLDTOT") then
     var2       = f[:]->clt(:,:,:,:)
     var2@units = Varunit(iv)

    else
     var2       = f[:]->$Varname(iv)$(:,:,:,:)
     var2@units = Varunit(iv)
  
    end if 
    end if 

    ;;;calculate the global mean;;;
    rad      = 4.0*atan(1.0)/180.0
    clat     = cos(f[0]->lat*rad)
    gmean    = wgt_areaave(var2, clat, 1.0, 0)
    grmsd    = (/dim_stddev_n_Wrap(gmean,0)/) 
    genmn    = (/dim_avg_n_Wrap(gmean,0)/)

    genmn!0  = "time"
    grmsd!0  = "time"
    genmn&time = time
    grmsd&time = time 
    if(igp.eq.0)then 
      fout->time     = time 
    end if 
    varout = Groups(igp)+"_"+Varname(iv) + "_MEAN"
    fout->$varout$ = genmn
    varout = Groups(igp)+"_"+Varname(iv) + "_RMSD"
    fout->$varout$ = grmsd
    delete([/var2,time,gmean,grmsd,genmn/])

   end do 

 end do
 
 delete([/fout/])

end

