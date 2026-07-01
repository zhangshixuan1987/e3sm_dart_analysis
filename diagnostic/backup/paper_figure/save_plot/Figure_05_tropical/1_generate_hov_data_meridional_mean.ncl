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
     ModelOutRoot = "/pic/projects/E3SM_DA/zhan391/dart_paper_materials/DATA/"
  end if

;;;;;;;date for plot;;;;;;
  timeunit     = "days since 2011-01-01 00:00:00"
  year         = 2011
  month        = 1
  nday         = 31
  ymstr1       = sprinti("%04d",year)+sprinti("%02d",month)
  ymstr2       = sprinti("%04d",year)+"-"+sprinti("%02d",month)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  Obname       = "TRMM"
  Groups       = (/"PDNUDG_UV_ENS01",  "PDNUDG_UVT_ENS01",\
                   "PDNUDG_UVTQ_ENS01","PDDART_UV_ENS80",\
                   "PDDART_UVT_ENS80", "PDDART_UVTQ_ENS80"/)
  nens         = (/1, 1, 1, 80, 80, 80/)
  ngrps        = dimsizes(Groups)
  plot         = new(ngrps+1,graphic)

 ;;;;;;variables to be plotted;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  VarList      = (/"PRECT"/)
  UnitList     = (/"mm day~S~-1~N~"/)
  PltNums      = (/"", "", "", "", "", "", "", "", "", "", ""/)
  nvars        = dimsizes(VarList)

 ;;;loop the regions and plot the PDF
 load "./sc_cloud_region.ncl"
 do irg = 0,nsubreg-1,1
  mpMinLatF = minlat(irg)
  mpMaxLatF = maxlat(irg)
  mpMinLonF = minlon(irg)
  mpMaxLonF = maxlon(irg)
  Figstr  = Subreg(irg) ;+ "["+mpMinLatF+"-"+mpMaxLatF;+mpMinLonF+"-"+mpMaxLonF +"]" ;PltNums(iv)

  ;;open netcdf file to save the data for plots;;;;;
  setfileoption("nc", "Format",  "NetCDF4")
  out_file_name = "Hovmoller_201101_daily_mean_vs_TRMM_Meridional_Mean_"+str_sub_str(Subreg(irg)," ","_")+".nc"
  system("rm " + out_file_name)
  fout = addfile(out_file_name,"c")

 do iv = 0,nvars-1, 1

  Varname = VarList(iv)
  Varunt  = UnitList(iv)

 ;;;;read and process observational file 
  obsfile  = ModelOutRoot+ "/"+Obname+"/daily/"+year+".nc"
  File0    = addfile(obsfile,"r")
  obstime  = File0->time
  lat      = File0->lat
  lon      = File0->lon
  obs_tim  = cd_convert( obstime, timeunit)
  precobs  = File0->$Varname$
  precobs  = precobs * 24.0
  printVarSummary(precobs)

  ;;zonal mean;;;;;;;
  rad     = 4.*atan(1.)/180.    ;
  cost    = lat
  cost    = cos(lat*rad)
  pncre   = dim_avg_wgt_n_Wrap(precobs(:,{mpMinLatF:mpMaxLatF},{mpMinLonF:mpMaxLonF}),cost({mpMinLatF:mpMaxLatF}),1,1)
 ;print(min(pncre)  +  " " + max(pncre))
  delete([/lat,lon,obstime,precobs,cost/])

  do igp = 0,ngrps-1,1

   topdir   = ModelOutRoot+ "/"+Groups(igp)+"/"+"/cam_h0/daily/"
   
   if(Varname.eq."PRECT")then 
     modfil1  = systemfunc("ls " + topdir+"/PRECC*.nc")
     modfil2  = systemfunc("ls " + topdir+"/PRECL*.nc")
     fa       = addfiles(modfil1,"r")
     fb       = addfiles(modfil2,"r") 
     ListSetType (fa, "join")  
     ListSetType (fb, "join")  
     modtim1   = fa[0]->time
     lat       = fa[0]->lat
     lon       = fa[0]->lon
     precmd1   = fa[:]->PRECC(:,:,:,:)
     precmd1   = fa[:]->PRECC(:,:,:,:) + fb[:]->PRECL(:,:,:,:)
     delete([/fa,fb,modfil1,modfil2/])
   else
     modfils  = systemfunc("ls -1" + topdir+"/FLUT*.nc")
     fa       = addfiles(modfil1,"r")
     ListSetType (fa, "join")
     modtim1   = fa[0]->time
     lat       = fa[0]->lat
     lon       = fa[0]->lon
     precmd1  = fa[:]->$Varname$
     delete([/fa,modfil/])   
   end if 

   mod_tim   = cd_convert( modtim1, timeunit)
   precmd1   = precmd1 * 1000.0 * 24.0 * 3600.0

   ;printVarSummary(precmd1)
   datestr   = cd_calendar(mod_tim, -2 )      ; yyyymmdd
   ;print(datestr)

   ;;zonal mean;;;;;;;
   rad       = 4.*atan(1.)/180.    ;
   cost      = lat
   cost      = cos(lat*rad)
   wncre1  = dim_avg_wgt_n_Wrap(precmd1(:,:,{mpMinLatF:mpMaxLatF},{mpMinLonF:mpMaxLonF}),cost({mpMinLatF:mpMaxLatF}),1,2)
  ;print(min(wncre1) +  " " + max(wncre1))
   
   ;;;pattern correlation
   pncre0    = conform(wncre1,pncre,(/1,2/))
   encorr    = pattern_cor(wncre1, pncre0, 1.0, 0)
   corr1     =  avg(encorr)
   corr1@min =  min(encorr)
   corr1@max =  max(encorr)
   corr1@std =  stddev(encorr)
   ;;;calculate the RMSE between observations and simulations;;;
   ermse     = wgt_arearmse(wncre1,pncre0, 1.0, 1.0, 0)
   rmse1     =  avg(ermse)
   rmse1@min =  min(ermse)
   rmse1@max =  max(ermse)
   rmse1@std =  stddev(ermse)
   delete(pncre0)

   wncreplt   = dim_avg_n_Wrap(wncre1,0)
   pncreplt   = wncreplt
   pncreplt   = (/pncre/)
 
   pncreplt&time  = mod_tim
   wncreplt&time  = mod_tim
 
 ;;;save the data to netcdf file;;;;
  if(igp.eq.0)then 
   vnmobs = Subrgs(irg)+"_"+Varname+"_"+Obname 
   pncreplt@units = Varunt
   pncreplt@pc   = (/-9999.0,-9999.0,-9999.0,-9999.0/)
   pncreplt@rmse = (/-9999.0,-9999.0,-9999.0,-9999.0/)
   pncreplt@region = Subreg(irg)
   fout->$vnmobs$=pncreplt
  end if 
 
  vnmmod = Subrgs(irg)+"_"+Varname+"_"+Groups(igp)
  wncreplt@units = Varunt
  wncreplt@pc   = (/corr1,corr1@min,corr1@max,corr1@std/)
  wncreplt@rmse = (/rmse1,rmse1@min,rmse1@max,rmse1@std/)
  wncreplt@region = Subreg(irg)
  fout->$vnmmod$=wncreplt
  delete([/encorr,ermse,rmse1,corr1,wncre1/])
  delete([/modtim1,mod_tim,precmd1/])
  delete([/pncreplt,wncreplt/])
 
 end do 
 delete([/pncre,obs_tim/])

 end do ; end of var loop
 
 delete([/fout/])

end do ; end of subreg loop

end

