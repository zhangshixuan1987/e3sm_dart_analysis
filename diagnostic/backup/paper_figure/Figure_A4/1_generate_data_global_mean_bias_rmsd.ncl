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

  ObsRoot = "/pic/projects/uq_climate/zhan391/climate_analysis/obs_data_20140804/"

  if (ldatalocal) then
     ModelOutRoot = "./E3SMV1_SIMULATION/"
  else
     ModelOutRoot = "/pic/projects/E3SM_DA/zhan391/e3sm_dart_FV19/Hindcast_data/5year/climo"
  end if
  
;;;;;;;;;weight files for ESMF regrid function;;;;;
  wgt_dir  = "./"
  wgt_file = wgt_dir+"SE_NE30_to_FV_192x288.bilinear.nc"


;;;;;;;;;;select the regions to calculate the rmse;;;;;;;;;;;;;
  Regions      = (/"Global"/)
  nregs        = dimsizes(Regions)
  season0      = (/"01","ANN"/)
  nseas        = dimsizes(season0)

;;;;;;;;;;select the regions to calculate the rmse;;;;;;;;;;;;;
  Casdir       = (/"PDFREE_F20TRC5-AMIP_f19_d025"/)
  Groups       = (/"PDFREE"/)
  ngrps        = dimsizes(Groups)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  setfileoption("nc", "Format",  "NetCDF4")
  out_file_name = "Bias_and_RMSE_5year_mean_with_respect_to_observations.nc"
  system("rm " + out_file_name)
  fout = addfile(out_file_name,"cw")

;;;;;;;begin to work with the simulations;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  xlabnam = (/"FLDS","FLNS","FLUT","FLUTC","LWCF","FSNS","FSNTOA","FSNTOAC","SWCF","CLDTOT","U (200 hPa) ","Z3 (500 hPa)","PRECT","TMQ","PSL","LHFLX","SHFLX","STRESS MAG","TREFHT","TS (LAND)"/)
  varnam = (/"FLDS","FLNS","FLUT","FLUTC","LWCF","FSNS","FSNTOA","FSNTOAC","SWCF","CLDTOT","U_200","Z3_500","PRECT","PREH2O","PSL","LHFLX","SHFLX","STRESS_MAG","TREFHT","TS_LAND"/)
  obsnam = (/"ISCCP","ISCCP","CERES-EBAF","CERES-EBAF","CERES-EBAF","ISCCP","CERES-EBAF","CERES-EBAF","CERES-EBAF","CLOUDSAT","JRA25","JRA25","GPCP","NVAP","ERAI","JRA25","JRA25","LARYEA","LEGATES","NCEP"/)
  nvars = dimsizes(varnam)
  nmtrx = 2 ; 1 for average, 2 for rmse

;;;processe the zonal mean data;;;;
  plotmean  = new((/nvars/),float)
  plotrmse  = new((/nvars/),float)

;;read and calculate the mean and rmsd;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;read observations;;;;;;;;;;;;;;;;;;;;;;
   obsvars    = varnam+ "_"+obsnam
   era40_vars  = (/"LHFLX_ERA40","PREH2O_ERA40"/)
   erai_vars  = (/"PREH2O_ERAI", "PSL_ERAI"/)
   jra25_vars  = (/"TREFHT_JRA25","PSL_JRA25","SHFLX_JRA25","LHFLX_JRA25", \
                   "PRH2O_JRA25","U_200_JRA25","Z3_500_JRA25","STRESS_MAG_JRA25"/)
   ceres_vars  = (/"SOLIN_CERES","FSNTOA_CERES","FSNTOAC_CERES","FLUT_CERES","FLUTC_CERES", \
                  "LWCF_CERES","SWCF_CERES","RESTOA_CERES"/)
   ceres2_vars = (/"SOLIN_CERES-EBAF","FSNTOA_CERES-EBAF","FSNTOAC_CERES-EBAF","FLUT_CERES-EBAF","FLUTC_CERES-EBAF", \
                  "LWCF_CERES-EBAF","SWCF_CERES-EBAF","RESTOA_CERES-EBAF"/)
   erbe_vars   = (/"FSNTOA_ERBE","FSNTOAC_ERBE","FLUT_ERBE","FLUTC_ERBE", \
                  "RESTOA_ERBE","LWCF_ERBE","SWCF_ERBE"/)
   ers_vars   = (/"STRESS_MAG_ERS"/)
   gpcp_vars  = (/"PRECT_GPCP"/)
   isccp_vars = (/"CLDTOT_ISCCP"/)
   cloudsat_vars = (/"CLDTOT_CLOUDSAT"/)
   hadisst_vars = (/"SST_HADISST"/)
   hadisst_pi_vars = (/"SST_HADISST_PI"/)
   hadisst_pd_vars = (/"SST_HADISST_PD"/)
   isccpFD_vars = (/"FLDS_ISCCP","FLNS_ISCCP","FSDS_ISCCP","FSNS_ISCCP"/)
   leg_vars   = (/"TREFHT_LEGATES"/)
   ncep_vars  = (/"TS_NCEP","TS_LAND_NCEP"/)
   merra_vars  = (/"PSL_MERRA","TS_MERRA", "U_200_MERRA","Z3_500_MERRA","STRESS_MAG_MERRA" /)
   nvap_vars  = (/"PREH2O_NVAP"/)
   airs_vars  = (/"PREH2O_AIRS"/)
   whoi_vars  = (/"LHFLX_WHOI"/)
   laryea_vars = (/"FSNS_LARYEA","SHFLX_LARYEA","STRESS_MAG_LARYEA"/)
   nobs_vars  =  (/"FLNT_CAM","FSNT_CAM","AODVIS","AODDUST"/)

   do isea = 0,nseas-1,1
   
   season   = season0(isea)

   ptr_jra25    = addfile(ObsRoot+"/JRA25_"+season+"_climo.nc","r")
   ptr_era40    = addfile(ObsRoot+"/ERA40_"+season+"_climo.nc","r")
   ptr_erai     = addfile(ObsRoot+"/ERAI_"+season+"_climo.nc","r")
   ptr_ceres    = addfile(ObsRoot+"/CERES_"+season+"_climo.nc","r")
   ptr_ceres2   = addfile(ObsRoot+"/CERES-EBAF_"+season+"_climo.nc","r")
   ptr_erbe     = addfile(ObsRoot+"/ERBE_"+season+"_climo.nc","r")
   ptr_ers      = addfile(ObsRoot+"/ERS_"+season+"_climo.nc","r")
   ptr_gpcp     = addfile(ObsRoot+"/GPCP_"+season+"_climo.nc","r")
   ptr_hadisst  = addfile(ObsRoot+"/HadISST_CL_"+season+"_climo.nc","r")
   ptr_hadisst_pi = addfile(ObsRoot+"/HadISST_PI_"+season+"_climo.nc","r")
   ptr_hadisst_pd = addfile(ObsRoot+"/HadISST_PD_"+season+"_climo.nc","r")
   ptr_isccp    = addfile(ObsRoot+"/ISCCP_"+season+"_climo.nc","r")
   ptr_isccpFD  = addfile(ObsRoot+"/ISCCPFD_"+season+"_climo.nc","r")
   ptr_leg      = addfile(ObsRoot+"/LEGATES_"+season+"_climo.nc","r")
   ptr_ncep     = addfile(ObsRoot+"/NCEP_"+season+"_climo.nc","r")
   ptr_merra    = addfile(ObsRoot+"/MERRA_"+season+"_climo.nc","r")
   ptr_nvap     = addfile(ObsRoot+"/NVAP_"+season+"_climo.nc","r")
   ptr_airs     = addfile(ObsRoot+"/AIRS_"+season+"_climo.nc","r")
   ptr_whoi     = addfile(ObsRoot+"/WHOI_"+season+"_climo.nc","r")
   ptr_laryea   = addfile(ObsRoot+"/LARYEA_"+season+"_climo.nc","r")
   ptr_cloudsat = addfile(ObsRoot+"/CLOUDSAT_"+season+"_climo.nc","r")
   if(season.eq."01")then 
     ptr_t42      = addfile(ObsRoot+"/T42_ORO_DJF_climo.nc","r")
   else
     ptr_t42      = addfile(ObsRoot+"/T42_ORO_"+season+"_climo.nc","r")
   end if 
   oro          = ptr_t42->ORO

  do igp    = 0,ngrps-1
   
   ;read model file 
   ptr_dt1800  = addfile(ModelOutRoot+"/"+Casdir(igp)+"/"+Casdir(igp)+"_"+season+"_climo.nc","r")
   
   re = 6.3712e6         ; radius of earth
   pi = 3.14159265

   do i = 0, nvars-1
      if (any(obsvars(i) .eq. erai_vars)) then
        inptr2 = ptr_erai
      end if
      if (any(obsvars(i) .eq. era40_vars)) then
        inptr2 = ptr_era40
      end if
      if (any(obsvars(i) .eq. jra25_vars)) then
        inptr2 = ptr_jra25
      end if
      if (any(obsvars(i) .eq. ceres_vars)) then
        inptr2 = ptr_ceres
      end if
      if (any(obsvars(i) .eq. ceres2_vars)) then
        inptr2 = ptr_ceres2
      end if
      if (any(obsvars(i) .eq. erbe_vars)) then
        inptr2 = ptr_erbe
      end if
      if (any(obsvars(i) .eq. ers_vars)) then
        inptr2 = ptr_ers
      end if
      if (any(obsvars(i) .eq. gpcp_vars)) then
        inptr2 = ptr_gpcp
      end if
      if (any(obsvars(i) .eq. hadisst_vars)) then
        inptr2 = ptr_hadisst
      end if
      if (any(obsvars(i) .eq. hadisst_pi_vars)) then
        inptr2 = ptr_hadisst_pi
      end if
      if (any(obsvars(i) .eq. hadisst_pd_vars)) then
        inptr2 = ptr_hadisst_pd
      end if
      if (any(obsvars(i) .eq. isccp_vars)) then
        inptr2 = ptr_isccp
      end if
      if (any(obsvars(i) .eq. isccpFD_vars)) then
        inptr2 = ptr_isccpFD
      end if
      if (any(obsvars(i) .eq. leg_vars)) then
        inptr2 = ptr_leg
      end if
      if (any(obsvars(i) .eq. ncep_vars)) then
        inptr2 = ptr_ncep
      end if
      if (any(obsvars(i) .eq. merra_vars)) then
        inptr2 = ptr_merra
      end if
      if (any(obsvars(i) .eq. nvap_vars)) then
        inptr2 = ptr_nvap
      end if
      if (any(obsvars(i) .eq. airs_vars)) then
        inptr2 = ptr_airs
      end if
      if (any(obsvars(i) .eq. whoi_vars)) then
        inptr2 = ptr_whoi
      end if
      if (any(obsvars(i) .eq. laryea_vars)) then
        inptr2 = ptr_laryea
      end if
      if (any(obsvars(i) .eq. cloudsat_vars)) then
        inptr2 = ptr_cloudsat
      end if

      if (varnam(i).eq."T_850" .or. varnam(i).eq."U_200" .or. \
          varnam(i).eq."Z3_300" .or. varnam(i).eq."Z3_500" .or. \
          varnam(i).eq."TS_LAND") then
        extrap = False
        interp = 2 
        if (varnam(i).eq."T_850") then
          B = inptr2->T(0,{850},:,:)
          B@long_name = "850mb temperature"
          B@units = "K"
          pnew = 850.0 
          P0mb = 1000.0
          tmp1 = vinth2p(ptr_dt1800->T(0,:,:,:),ptr_dt1800->hyam,ptr_dt1800->hybm,pnew,ptr_dt1800->PS(0,:,:),interp,P0mb,1,extrap)
          A1   = tmp1(0,:,:)
          delete([/pnew,P0mb,tmp1/])
        end if
        if (varnam(i).eq."TS_LAND") then
          ts = inptr2->TS(0,:,:)
          B = ts
          B = mask(ts,oro,1)
          B@long_name = "Surface temp (land)"
          B@units = "K"
          ts1 = ptr_dt1800->TS(0,:,:)
          A1  = ts1
          A1  = mask(ts1,ptr_dt1800->LANDFRAC(0,:,:),1)
          delete([/ts1/])
        end if
        if (varnam(i).eq."U_200") then
          B = inptr2->U(0,{200},:,:)
          B@long_name = "200mb zonal wind"
          B@units = "m/s"
          pnew = 200.0
          P0mb = 1000.0
          tmp1 = vinth2p(ptr_dt1800->U(0,:,:,:),ptr_dt1800->hyam,ptr_dt1800->hybm,pnew,ptr_dt1800->PS(0,:,:),interp,P0mb,1,extrap)
          A1   = tmp1(0,:,:)
          A1@long_name = ptr_dt1800->Z3@long_name
          A1@units = ptr_dt1800->Z3@units
          delete([/pnew,P0mb,tmp1/])
        end if
        if (varnam(i).eq."Z3_300") then
          B = inptr2->Z3(0,{300},:,:)
          B = (/B/100./)
          B@long_name = "300mb geop height"
          B@units = "hectometers"
          pnew = 300.0
          P0mb = 1000.0
          tmp1 = vinth2p(ptr_dt1800->Z3(0,:,:,:),ptr_dt1800->hyam,ptr_dt1800->hybm,pnew,ptr_dt1800->PS(0,:,:),interp,P0mb,1,extrap)
          A1   = tmp1(0,:,:)
          A1@long_name = ptr_dt1800->Z3@long_name
          A1@units = ptr_dt1800->Z3@units
          delete([/pnew,P0mb,tmp1/])
        end if
        if (varnam(i).eq."Z3_500") then
          B = inptr2->Z3(0,{500},:,:)
          B = (/B/100./)
          B@long_name = "500mb geop height"
          B@units = "hectometers"
          pnew = 500.0
          P0mb = 1000.0
          tmp1 = vinth2p(ptr_dt1800->Z3(0,:,:,:),ptr_dt1800->hyam,ptr_dt1800->hybm,pnew,ptr_dt1800->PS(0,:,:),interp,P0mb,1,extrap)
          A1   = tmp1(0,:,:)
          A1   = (/A1/100./)
          A1@long_name = ptr_dt1800->Z3@long_name
          A1@units = "hectometers"
          delete([/pnew,P0mb,tmp1/])
        end if
      else
          if (obsvars(i).eq."CLDTOT_CLOUDSAT"  .or. obsvars(i).eq."SST_HADISST" \
            .or. obsvars(i).eq."SST_HADISST_PI" .or. obsvars(i).eq."SST_HADISST_PD") then
            B  = inptr2->$varnam(i)$
            A1 = ptr_dt1800->$varnam(i)$(0,:,:)
            if(obsvars(i).eq."CLDTOT_CLOUDSAT") then
             A1 = A1*100.0
            end if 
          else
            B = inptr2->$varnam(i)$(0,:,:)        ; all other obsvars
            if (varnam(i).eq."PRECT")then
             A1 = ptr_dt1800->PRECC(0,:,:)
             A1 = ptr_dt1800->PRECC(0,:,:) + ptr_dt1800->PRECL(0,:,:)
             A1 = A1*24.0*3600.0*1000.0
            else if (varnam(i).eq."PREH2O")then
             A1 = ptr_dt1800->TMQ(0,:,:)
            else if (varnam(i).eq."STRESS_MAG") then
             ocnf1   = ptr_dt1800->OCNFRAC(0,:,:)
             tmpu1   = ptr_dt1800->TAUX(0,:,:)
             tmpv1   = ptr_dt1800->TAUY(0,:,:)
             taux1 = tmpu1
             tauy1 = tmpv1
             taux1 = (/-1.0*mask(tmpu1,ocnf1.ge.0.5,True)/)
             tauy1 = (/-1.0*mask(tmpv1,ocnf1.ge.0.5,True)/)
             A1 = taux1 
             A1 = (/sqrt(taux1^2 + tauy1^2)/)
             delete([/tmpu1,tmpv1,taux1,tauy1/])
            else if (varnam(i).eq."PSL") then
             A1 = ptr_dt1800->$varnam(i)$(0,:,:)
             A1 = (/A1/100./) 
             A1@units = "mbar"
            else
             A1 = ptr_dt1800->$varnam(i)$(0,:,:)
            end if 
            end if
            end if
            end if    
          end if
      end if 

      lat2 = inptr2->lat
      nlat2 = dimsizes(lat2)
      lon2 = inptr2->lon
      nlon2 = dimsizes(lon2)
      if (isfilevar(inptr2,"gw")) then
        gw2 = inptr2->gw
      else
        if (isfilevar(inptr2,"wgt")) then
          gw2 = inptr2->wgt
        else
          ;print("===== gw2 =====")
          gw2temp = latRegWgt(lat2,"double",0)  ; no gw in file
          gw2 = gw2temp
          gw2!0 = "lat"
          gw2&lat = lat2
          delete(gw2temp)
        end if
      end if     

      lat1  = ptr_dt1800->lat
      nlat1 = dimsizes(lat1)
      lon1  = ptr_dt1800->lon
      nlon1 = dimsizes(lon1)
      if (isfilevar(ptr_dt1800,"gw")) then
        gw1 = ptr_dt1800->gw
      else
        if (isfilevar(ptr_dt1800,"wgt")) then
          gw1 = ptr_dt1800->wgt
        else
          ;print("===== gw1 =====")
          gw1temp = latRegWgt(lat1,"double",0)  ; no gw in file
          gw1 = gw1temp
          delete(gw1temp)
          gw1!0 = "lat"
          gw1&lat = lat1
        end if
      end if
      meanmd1 = wgt_areaave(A1,gw1,1.0,0)
      meanob  = wgt_areaave(B ,gw2,1.0,0)
      plotmean(i)  = (meanmd1-meanob)/(meanob)
       
      if (nlat1 .ge. nlat2) then           ; interp A to nlat2
        tmp1  = B
        tmp2  = B
        tmp1  = linint2(lon1,lat1,A1,False,lon2,lat2,0)
        tmp1  = tmp1 - wgt_areaave(tmp1,gw2,1.0,0)
        B     = B    - wgt_areaave(B, gw2,1.0,0)     
        rmsd1 = wgt_arearmse(tmp1,B,gw2,1.0,0)
        tmp1d = ndtooned(B)
        rmsob = dim_stddev(tmp1d)
        plotrmse(i)  = rmsd1/rmsob
        delete([/tmp1,tmp2,rmsd1,rmsob,tmp1d/])
      else
        tmp  = A1
        tmp  = linint2(lon2,lat2,B,False,lon1,lat1,0)
        A1   = A1  -  wgt_areaave(A1,gw1,1.0,0)
        tmp  = tmp -  wgt_areaave(tmp,gw1,1.0,0)
        rmsd1 = wgt_arearmse(A1,tmp,gw1,1.0,0)
        tmp1d = ndtooned(tmp)
        rmsob = dim_stddev(tmp1d)
        plotrmse(i)  = rmsd1/rmsob
        delete([/tmp,rmsd1,rmsob,tmp1d/])
      end if 
   printVarSummary(B)
   printVarSummary(A1)
   delete([/A1,B,lat2,lon2,gw2,lat1,lon1,gw1/])
 end do ;end var loop

 ;;;;open a netcdf file and save the data for plot;;;;;
 rmseo = plotrmse
 biaso = plotmean
 rmseo!0     = "nvars"
 rmseo&nvars = ispan(1,nvars,1)
 rmseo&nvars@long_name = "number of variables"
 biaso!0     = "nvars"
 biaso&nvars = ispan(1,nvars,1)
 biaso&nvars@long_name = "number of variables"

 outname0 = Groups(igp)+"_BIAS_"+season
 outname1 = Groups(igp)+"_RMSE_"+season
 fout->$outname0$=biaso
 fout->$outname1$=rmseo
 delete([/rmseo,biaso,outname0,outname1/])

 if(igp.eq.0)then
  ovarnam                 = (/xlabnam/)
  ovarnam!0               = "nvars"
  ovarnam&nvars           = ispan(1,nvars,1)
  ovarnam&nvars@long_name = "number of variables"
  obsnam!0                = "nvars"
  obsnam&nvars            = ispan(1,nvars,1)
  obsnam&nvars@long_name  = "number of variables"
  fout->Evaluated_variables=ovarnam
  fout->Observation_data_source=obsnam
 ;delete([/ovarnam,obsnam/])
 end if 
  
end do ; end igp loop

end do ;

end

