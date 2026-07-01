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
  Groups  = (/"PDCLIM_ENS01","PDDART_UVTQ_HIND_ENS80", "PDNUDG_ERA5_HIND_ENS01"/)
  Expnam  = (/        "CLIM",              "EAM/DART",              "hybrid IC"/)
  ngrps   = dimsizes(Groups)

  ;;;;;;variables to be plotted;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  VarList      = (/"CLDTOT","TGCLDLWP","TGCLDIWP","TMQ", \
                   "PRECL","PRECC","PRECT","AODVIS",\
                   "FNET","FSNT","FLNT","FLNTC",\
                   "NETCF","SWCF","LWCF"/)
  UnitList     = (/"fraction","g m~S~-2~N~","g m~S~-2~N~", "kg m~S~-2~N~",\
                   "mm day~S~-1~N~","mm day~S~-1~N~","mm day~S~-1~N~", "unitless", \
                   "W m~S~-2~N~","W m~S~-2~N~","W m~S~-2~N~","W m~S~-2~N~", \
                   "W m~S~-2~N~","W m~S~-2~N~","W m~S~-2~N~"/)
  nvars        = dimsizes(VarList)
  year         = 2011
  month        = 1
  nhind        = 5

  nmetric      = 3
  gmean        = new ((/ngrps,nhind,nmetric/),string)
  gmean!0      = "groups"
  gmean!1      = "hind"
  gmean!2      = "metric"

  gmean&groups = Expnam
  gmean&hind   = (/"day1","day2","day3","day4","day5"/)
  gmean&metric = (/"Min","Max","Mean"/)

  do iv = 0,nvars-1,1
  
  varnam = VarList(iv)
  varunt = UnitList(iv)
 
  do ih = 0,nhind-1,1

   hday       = ih+1 ; hindcast day

   ;;;;;process the 5-year JAN clim vs OBS obs;;;;;
   filmod   = systemfunc("ls "+ ModelOutRoot+"/"+Groups(0)+"/cam_h0/monthly/"+"*.nc")
   f1       = addfiles(filmod,"r")
   if (varnam.eq."PRECT") then
     var1     = f1[:]->PRECC
     var1     = f1[:]->PRECC +f1[:]->PRECL
   else if (varnam.eq."NETCF") then
     var1     = f1[:]->SWCF
     var1     = f1[:]->SWCF +f1[:]->LWCF
   else if (varnam.eq."FNET") then
     var1     = f1[:]->FSNT
     var1     = f1[:]->FSNT - f1[:]->FLNT 
   else
     var1     = f1[:]->$varnam$
   end if
   end if
   end if 

   if(varnam.eq."TGCLDLWP".or.varnam.eq."TGCLDIWP") then
     var1 = var1*1000.0
   end if 
   if(varnam.eq."PRECC".or.varnam.eq."PRECL".or.varnam.eq."PRECT") then
     var1     = var1 * 24.0 * 3600.0 * 1000.0
   end if 

   ;;;calculate the global mean and error metric;;;
   rad        = 4.0*atan(1.0)/180.0
   clat       = cos(f1[0]->lat*rad)
   dimx       = dimsizes(var1)
   mgmin      = dim_min_n(reshape(var1,(/dimx(0),dimx(1)*dimx(2)/)),1)
   mgmax      = dim_max_n(reshape(var1,(/dimx(0),dimx(1)*dimx(2)/)),1)
   mgave      = wgt_areaave(var1, clat, 1.0, 0)

   gmean(0,ih,0) = sprintf("%8.3f",avg(mgmin))  +" +/- " + sprintf("%12.5f",stddev(mgmin))
   gmean(0,ih,1) = sprintf("%8.3f",avg(mgmax))  +" +/- " + sprintf("%12.5f",stddev(mgmax))
   gmean(0,ih,2) = sprintf("%8.3f",avg(mgave))  +" +/- " + sprintf("%12.5f",stddev(mgave))
   delete([/clat,rad,var1,f1,filmod,dimx,mgmin,mgmax,mgave/])

   do igp  = 1,ngrps-1,1

     hindstr    = "day"+hday
     topdir     = ModelOutRoot+Groups(igp)+"/"+hindstr+"/cam_h0/monthly"
     modfils    = systemfunc("ls " + topdir+"/2011_00*.nc")
     f          = addfiles(modfils,"r")
     ListSetType (f, "join")  

     if (varnam.eq."PRECT") then
       var2     = f[:]->PRECC(:,0,:,:)
       var2     = f[:]->PRECC(:,0,:,:) +f[:]->PRECL(:,0,:,:)
     else if (varnam.eq."NETCF") then
       var2     = f[:]->SWCF(:,0,:,:)
       var2     = f[:]->SWCF(:,0,:,:) +f[:]->LWCF(:,0,:,:)
     else if (varnam.eq."FNET") then
       var2     = f[:]->FSNT(:,0,:,:)
       var2     = f[:]->FSNT(:,0,:,:) - f[:]->FLNT(:,0,:,:)
     else
       var2     = f[:]->$varnam$(:,0,:,:)
     end if
     end if
     end if 

     if(varnam.eq."TGCLDLWP".or.varnam.eq."TGCLDIWP") then
       var2 = var2*1000.0
     end if
     if(varnam.eq."PRECC".or.varnam.eq."PRECL".or.varnam.eq."PRECT") then
       var2 = var2 * 24.0 * 3600.0 * 1000.0
     end if

     ;;;calculate the global mean and error metric;;;
     rad      = 4.0*atan(1.0)/180.0
     clat     = cos(f[0]->lat*rad)
     dimx     = dimsizes(var2)
     mgmin    = dim_min_n(reshape(var2,(/dimx(0),dimx(1)*dimx(2)/)),1) 
     mgmax    = dim_max_n(reshape(var2,(/dimx(0),dimx(1)*dimx(2)/)),1)
     mgave    = wgt_areaave(var2, clat, 1.0, 0)
    
     gmean(igp,ih,0) = sprintf("%8.3f",avg(mgmin))  +" +/- " + sprintf("%12.5f",stddev(mgmin))
     gmean(igp,ih,1) = sprintf("%8.3f",avg(mgmax))  +" +/- " + sprintf("%12.5f",stddev(mgmax))
     gmean(igp,ih,2) = sprintf("%8.3f",avg(mgave))  +" +/- " + sprintf("%12.5f",stddev(mgave))

     delete([/modfils,f,var2,dimx,rad,clat,mgmin,mgmax,mgave/])

  end do 

  end do 

  ;;write out the metrics;;;;
   filout = varnam+"_"+gmean&metric(2)+".txt"
   system("/bin/rm -f "+filout)   ; remove any pre-existing file
   line = new(nhind+1,string)
   line(0) = str_insert("Expnam"," ", 20)
   do igp = 0,ngrps-1,1
      line(0) = line(0)+ str_insert(gmean&groups(igp)," ",20)
   end do
   
   do ih = 0,nhind-1,1
     line(ih+1) = str_insert(gmean&hind(ih)," ",20)
     do igp = 0,ngrps-1,1
      line(ih+1) = line(ih+1) + str_insert(str_squeeze(gmean(igp,ih,2))," ",20)
     end do 
   end do 
   asciiwrite(filout,line)

  end do 
 
end

