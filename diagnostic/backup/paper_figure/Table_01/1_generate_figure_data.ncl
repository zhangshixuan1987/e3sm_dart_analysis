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

  ;;;;process hindcast simulation;;;
  Groups  = (/"PDDART_UVTQ_HIND_ENS80", "PDNUDG_ERA5_HIND_ENS01"/)
  Expnam  = (/"EAM/DART","hybrid IC"/)
  ngrps   = dimsizes(Groups)

  ;;;;;;variables to be plotted;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  VarList      = (/"CLDTOT","PRECT","TMQ","FLUT", "SWCF","LWCF","NETCF"/)
  UnitList     = (/"fraction","mm day~S~-1~N~","kg m~S~-2~N~","W m~S~-2~N~","W m~S~-2~N~","W m~S~-2~N~","W m~S~-2~N~"/)
  nvars        = dimsizes(VarList)
  year         = 2011
  month        = 1
  hday         = 1 ; hindcast day

  nmetric      = 6
  gmean        = new ((/ngrps+1,nmetric/),string)
  gmean!0      = "groups"
  gmean!1      = "metric"
  gmean&groups = (/"OBS", Expnam(0), Expnam(1)/)
  gmean&metric = (/"Min","Max","Mean","BIAS","RMSE","CORR"/)

  do iv = 0,nvars-1,1
  
   varnam = VarList(iv)
   varunt = UnitList(iv)
   
   if (varnam.eq."PRECT") then 
     ObsSrc = "GPCP"
   else if (varnam.eq."TMQ") then 
     ObsSrc = "RSS"
   else if (varnam.eq."FLUT") then 
     ObsSrc = "NOAA_AVHRR"
   else 
     ObsSrc = "CERES_EBAF"
   end if 
   end if 
   end if 

   LocalObsRoot  = ModelOutRoot+"/"+ObsSrc+"/monthly/"

   ;;;read and process the observations;;; 
   obsfile = LocalObsRoot+year+".nc"
   File0   = addfile(obsfile,"r")
   if(varnam.eq."FLUT") then
     precobs = File0->OLR(0,:,:)
   else
     precobs = File0->$varnam$(0,:,:)
   end if 

   if (varnam.eq."CLDTOT") then
     precobs = precobs/100.0 ; convert to fraction
   end if 
 
   do igp  = 0,ngrps-1,1

     hindstr    = "day"+hday
     topdir     = ModelOutRoot+Groups(igp)+"/"+hindstr+"/cam_h0/monthly"
     modfils    = systemfunc("ls " + topdir+"/2011_00*.nc")
     f          = addfiles(modfils,"r")
     ListSetType (f, "join")  

     if (varnam.eq."PRECT") then
       var2     = f[:]->PRECC(:,0,:,:)
       var2     = f[:]->PRECC(:,0,:,:) +f[:]->PRECL(:,0,:,:)
       var2     = var2 * 24.0 * 3600.0 * 1000.0
       var2@units = "mm/day"
     else if (varnam.eq."NETCF") then
       var2     = f[:]->SWCF(:,0,:,:)
       var2     = f[:]->SWCF(:,0,:,:) +f[:]->LWCF(:,0,:,:)
     else
       var2     = f[:]->$varnam$(:,0,:,:)
     end if
     end if

     var1       = conform(var2,precobs,(/1,2/)) 
     dimx       = dimsizes(var2)
     ;;;calculate the global mean and error metric;;;
     rad      = 4.0*atan(1.0)/180.0
     clat     = cos(f[0]->lat*rad)
      
     ogav     = wgt_areaave(var1, clat, 1.0, 0)
     mgmin    = dim_min_n(reshape(var2,(/dimx(0),dimx(1)*dimx(2)/)),1) 
     mgmax    = dim_max_n(reshape(var2,(/dimx(0),dimx(1)*dimx(2)/)),1)
     mgave    = wgt_areaave(var2, clat, 1.0, 0)
     mgbias   = mgave - ogav
     mgrmse   = wgt_arearmse(var1,var2,clat,1.0,0)
     mpcorr   = pattern_cor(var1, var2,tofloat(clat), 1)
    
     if(igp.eq.0) then 
       gmean(0,0) = sprintf("%6.2f",min(precobs)) 
       gmean(0,1) = sprintf("%6.2f",max(precobs))
       gmean(0,2) = sprintf("%6.2f",wgt_areaave(precobs, clat, 1.0, 0)) 
       gmean(0,3) = sprintf("%6.2f",-9999)
       gmean(0,4) = sprintf("%6.2f",-9999) 
       gmean(0,5) = sprintf("%6.2f",-9999) 
     end if 

     gmean(igp+1,0) = sprintf("%6.2f",avg(mgmin))  +" +/- " + sprintf("%12.5f",stddev(mgmin))
     gmean(igp+1,1) = sprintf("%6.2f",avg(mgmax))  +" +/- " + sprintf("%12.5f",stddev(mgmax))
     gmean(igp+1,2) = sprintf("%6.2f",avg(mgave))  +" +/- " + sprintf("%12.5f",stddev(mgave))
     gmean(igp+1,3) = sprintf("%6.2f",avg(mgbias)) +" +/- " + sprintf("%12.5f",stddev(mgbias))
     gmean(igp+1,4) = sprintf("%6.2f",avg(mgrmse)) +" +/- " + sprintf("%12.5f",stddev(mgrmse))
     gmean(igp+1,5) = sprintf("%6.2f",avg(mpcorr)) +" +/- " + sprintf("%12.5f",stddev(mpcorr))

     delete([/modfils,f,var1,var2,dimx,rad,clat,ogav,mgmin,mgmax,mgave,mgbias,mgrmse,mpcorr/])

  end do 

  ;;write out the metrics;;;;
   filout = varnam+"_"+"hindcast_day"+hday+".txt"
   system("/bin/rm -f "+filout)   ; remove any pre-existing file
   line = new(ngrps+2,string)
   line(0) = str_insert("Expnam"," ", 20)
   do ix = 2,nmetric-1,1
      line(0) = line(0)+ str_insert(gmean&metric(ix)," ",20)
   end do

   do igp = 0,ngrps,1
     line(igp+1) = str_insert(gmean&groups(igp)," ",20)
     do ix = 2,nmetric-1,1
      line(igp+1) = line(igp+1) + str_insert(str_squeeze(gmean(igp,ix))," ",20)
     end do 
   end do 
   asciiwrite(filout,line)
   delete([/precobs,obsfile,File0/])

  end do 
 
end

