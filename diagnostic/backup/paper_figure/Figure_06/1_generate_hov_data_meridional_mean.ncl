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
  Groups       = (/"PDNUDG_UVTQ_ENS01",  "PDDART_UVTQ_ENS80"/)
  nens         = (/1,  80/)
  ngrps        = dimsizes(Groups)
  plot         = new(ngrps+1,graphic)

 ;;;;;;variables to be plotted;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  VarList      = (/"PRECC","PRECL"/)
  UnitList     = (/"mm day~S~-1~N~","mm day~S~-1~N~"/)
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
  out_file_name = "Hovmoller_201101_daily_mean_Meridional_Mean_"+str_sub_str(Subreg(irg)," ","_")+".nc"
  system("rm " + out_file_name)
  fout = addfile(out_file_name,"c")

 do iv = 0,nvars-1, 1

  Varname = VarList(iv)
  Varunt  = UnitList(iv)

  do igp = 0,ngrps-1,1

   topdir   = ModelOutRoot+ "/"+Groups(igp)+"/"+"/cam_h0/daily/"
   modfils  = systemfunc("ls -1 " + topdir+"/"+Varname+"*.nc")
   fa       = addfiles(modfils,"r")
   ListSetType (fa, "join")
   modtim1   = fa[0]->time
   lat       = fa[0]->lat
   lon       = fa[0]->lon
   precmd1  = fa[:]->$Varname$(:,:,:,:)
   delete([/fa,modfils/])   

   mod_tim   = cd_convert( modtim1, timeunit)
   precmd1   = precmd1 * 1000.0 * 24.0 * 3600.0

  ;printVarSummary(precmd1)
   datestr   = cd_calendar(mod_tim, -2 )      ; yyyymmdd
  ;print(datestr)

   ;;zonal mean;;;;;;;
   rad       = 4.*atan(1.)/180.    ;
   cost      = lat
   cost      = cos(lat*rad)
   printVarSummary(precmd1)

   wncre1    = dim_avg_wgt_n_Wrap(precmd1(:,:,{mpMinLatF:mpMaxLatF},{mpMinLonF:mpMaxLonF}),cost({mpMinLatF:mpMaxLatF}),1,2)
  ;print(min(wncre1) +  " " + max(wncre1))
   
   wncreplt       = dim_avg_n_Wrap(wncre1,0)
   wncreplt&time  = mod_tim
 
 ;;;save the data to netcdf file;;;;
  vnmmod = Subrgs(irg)+"_"+Varname+"_"+Groups(igp)
  wncreplt@units = Varunt
  wncreplt@region = Subreg(irg)
  fout->$vnmmod$=wncreplt
  delete([/modtim1,mod_tim,precmd1,wncre1/])
  delete([/wncreplt/])
 
 end do 

 end do ; end of var loop
 
 delete([/fout/])

end do ; end of subreg loop

end

