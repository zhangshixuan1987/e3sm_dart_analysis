;=======================================================
; arm_2.ncl
;=======================================================
;
; These files are loaded by default in NCL V6.2.0 and newer
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
; load "./contributed.ncl"
  load "./exp_info.ncl"

begin

  data_dir  = "/pic/projects/E3SM_DA/zhan391/dart_paper_materials/DATA/ARM_OBS/"
  arm_site  = "TWP"
  arm_diri  = data_dir+"ORG_DAT/"+arm_site+"/"
  arm_fils  = systemfunc ("ls "+arm_diri+"*C1*.cdf") ; file paths
  ntimes    = dimsizes(arm_fils)

  varnam    = (/"u_wind","v_wind","tdry","rh"/)
  varstr    = (/"U","V","T","RH"/)
  vardes    = (/"Zonal wind", "Meridional wind", "Temperature", "Relative humidity"/)
  varunt    = (/"m s~S~-1~N~", "m s~S~-1~N~", "~S~o~N~C","%"/)
  nvars     = dimsizes(varnam)
 
  fixpres   = (/950, 850, 700, 600, 500, 400, 300, 200, 100/) 
  nplev     = dimsizes(fixpres)
  dat4d     = new ((/nvars,ncases+1,ntimes,nplev/),double,-9999.0)
  time      = new(ntimes,double,-9999.0)
  obsnum    = new ((/nvars,ntimes,nplev+1/),double,-9999.0)

;;open netcdf file to save the data for plots;;;;;
  setfileoption("nc", "Format",  "NetCDF4")
  out_file_name = "Profile_6h_Plev_EAM_vs_ARM_"+arm_site+"_DAT.nc"
  system("rm " + out_file_name)
  fout = addfile(out_file_name,"cw")

  do itime  = 1,ntimes -1,1
  
   fili     = systemfunc ( "basename "+arm_fils(itime))
   cfil     = stringtochar(fili)
   yyo      = chartostring(cfil(18:21))
   mmo      = chartostring(cfil(22:23))
   ddo      = chartostring(cfil(24:25))
   hho      = chartostring(cfil(27:28))
   mno      = chartostring(cfil(29:30))
   sdo      = chartostring(cfil(31:32))
   hmso     = hho+mno+sdo

   fobs     = addfile(arm_diri+fili,"r")

   if(itime .eq. 1)then 
     time_unt  = "hours since "+yyo+"-"+mmo+"-"+ddo+ " 00:00:00 0:00"
   end if

   time(itime) = cd_inv_calendar(toint(yyo),toint(mmo),toint(ddo),toint(hho),toint(mno),toint(sdo),time_unt, 0)

   do iv     = 0,nvars-1,1

    fobs     = addfile(arm_diri+fili,"r")
    pres     = fobs->pres
    varnm    = varnam(iv)
    vqcnm    = "qc_"+varnam(iv)
    varo     =  fobs->$varnm$
    qc       =  fobs->$vqcnm$
    indqc    = ind(qc.eq.0)
 
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    linlog = 2   ; ln(p) interpolation
    if(num(.not.ismissing(indqc)).gt.3)then 
      dat4d(iv,0,itime,:) = int2p_n(pres(indqc),varo(indqc),fixpres,linlog,0)
    end if 

    do ip = 0,nplev,1
      if(ip.eq.0)then
        indxx = ind(qc.eq.0.and.pres.ge.fixpres(ip))
        obsnum(iv,itime,ip) = num(.not.ismissing(indxx))
        delete(indxx)
      else if (ip.eq.nplev) then
        indxx = ind(qc.eq.0.and.pres.le.fixpres(ip-1))
        obsnum(iv,itime,ip) = num(.not.ismissing(indxx))
        delete(indxx)
      else 
        indxx = ind(qc.eq.0.and.pres.lt.fixpres(ip-1).and.pres.ge.fixpres(ip))
        obsnum(iv,itime,ip) = num(.not.ismissing(indxx))
        delete(indxx)
      end if
      end if 
    end do

    do icas = 0,ncases-1

     if(icas.eq.0)then 
       mod_diri  = data_dir+"/MOD_DAT/model_to_obs/"+case(icas)
     else if (isStrSubset(case(icas),"ENS01")) then 
       mod_diri  = data_dir+"/MOD_DAT/model_to_obs/"+case(icas)+"/"+hind(icas)+"/0001"
     else
       mod_diri  = data_dir+"/MOD_DAT/model_to_obs/"+case(icas)+"/"+hind(icas)+"/enmn"
     end if 
     end if
     fmdi   = mod_diri+"/"+case(icas)+"_"+str_lower(arm_site)+"C1."+ yyo + mmo+ddo+"."+hmso+".nc"
     print(fmdi)
     fmod   = addfile(fmdi,"r")
     var1   =  fmod->$varnm$ 

     if(num(.not.ismissing(indqc)).gt.3)then
      dat4d(iv,icas+1,itime,:) = int2p_n(pres(indqc),var1(indqc),fixpres,linlog,0)
     end if

     delete([/fmdi,fmod,var1/])
    end do 
     delete([/fobs,pres,varnm,vqcnm,varo,qc,indqc/])
    end do 

   end do 

   printVarSummary(dat4d)
   do iv = 0,nvars-1

    dat3d = dat4d(iv,:,:,:)
    
    if(iv.eq.0)then
     Groups!0  = "case"
     Groups&case = ispan(0,ncases,1)
     time!0       = "time"
     time&time    = time
     fixpres!0    = "lev"
     fixpres&lev  = fixpres
     fout->group  = Groups
     fout->time   = time
     fout->lev    = fixpres
    end if 

    obsnum1        = obsnum(iv,:,:)
    obsnum1!0      = "time"
    obsnum1!1      = "ilev"
    tmvar          = varstr(iv)+"_obsnum"
    fout->$tmvar$  = obsnum1
    delete([/obsnum1,tmvar/])

    vnmobs = varstr(iv)+"_"+arm_site
    dat3d!0 = "case"
    dat3d!1 = "time"
    dat3d!2 = "lev"
    fout->$vnmobs$ = dat3d
    delete([/dat3d/])

   end do

end
