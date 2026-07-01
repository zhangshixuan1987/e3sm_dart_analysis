;*************************************************
; histo_4.ncl
;
; Concepts illustrated:
;   - Drawing a histogram using exact min/max of data
;   - Generating dummy data using "rand"
;   - Drawing X axis labels at a 45 degree angle
;
;************************************************
;
; This file is loaded by default in NCL V6.2.0 and newer
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
;************************************************
begin

  outdir      = "/pic/projects/E3SM_DA/zhan391/dart_paper_materials/DATA/model_vs_obs/"

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  Groups      = (/"ERA5_ANL_ENS01",\
                  "PDDART_UV_ENS80","PDDART_UVT_ENS80","PDDART_UVTQ_ENS80", \
                  "PDNUDG_UV_ENS01","PDNUDG_UVT_ENS01","PDNUDG_UVTQ_ENS01"/)
  ngrps       = dimsizes(Groups)

  Regions     = (/"Global","North America"/)
  nregs       = dimsizes(Regions) 

  VarNameList = (/"U", "T", "Q" /)
  UnitList    = (/"m s~S~-1~N~", "K", "g kg~S~-1~N~"/)
  nvars       = dimsizes(VarNameList)

  plot_lev    = (/1000,850,700,500,400,300,200,100/)
  
  do igp = 0,ngrps-1,1

    setfileoption("nc", "Format",  "NetCDF4")
    out_file_name = "RMSE_"+Groups(igp)+"_vs_obs_UTQ.nc"
    system("rm " + out_file_name)
    fout = addfile(out_file_name,"c")

    do iv  = 0,nvars-1,1

     filnms  = systemfunc("ls " + outdir+Groups(igp)+"/"+Groups(igp)+"*.nc")
     fln     = addfiles(filnms,"r")
     ListSetType (fln, "join")

     print(dimsizes(filnms))

    if(igp.eq.0)then 
     staname = fln[0]->sta_names 
     regions = fln[0]->reg_names    
     lonlim1 = fln[0]->lonlim1
     lonlim2 = fln[0]->lonlim2
     latlim1 = fln[0]->latlim1
     latlim2 = fln[0]->latlim2 
     plev    = fln[0]->plev
     irmse   = ind(staname.eq."rmse")
     inobs   = ind(staname.eq."nobs")
     indreg  = get1Dindex(str_squeeze(regions),Regions)
     indlev  = get1Dindex(plev,plot_lev) 

    end if 
 
    varin = VarNameList(iv)+"_en01"
    tmp1  = fln[:]->$varin$(:,indreg,indlev,irmse)
    tmp2  = fln[:]->$varin$(:,indreg,indlev,inobs)

    rmse  = dim_avg_n(tmp1,0)
    rstd  = dim_stddev_n(tmp1,0)
    nobs  = dim_sum_n(tmp2,0)

    if(VarNameList(iv).eq."Q")then
      rmse = rmse * 1000.0
      rstd = rstd * 1000.0
    end if 

    print("")
    print("output: "+ out_file_name)
    print("")

    region = str_squeeze(regions(indreg))

    if(iv.eq.0)then 
     plev!0   = "lev"
     region!0 = "nreg"
     fout->plev = plev(indlev)
     fout->region = region  
    end if 

    vnmobs = VarNameList(iv)+"_rmse"
    rmse!0 = "nreg"
    rmse!1 = "lev"
    rmse@units = UnitList(iv)
    rmse@description = "Root-mean-squre error" 
    rmse@regions     = str_squeeze(regions(indreg))
    fout->$vnmobs$ = rmse 

    vnmobs = VarNameList(iv)+"_std"
    rstd!0 = "nreg"
    rstd!1 = "lev"
    rstd@units = UnitList(iv)
    rstd@description = "Root-mean-squre error"  
    rstd@regions     = str_squeeze(regions(indreg))
    fout->$vnmobs$ = rstd

    vnmobs = VarNameList(iv)+"_nobs"
    nobs!0 = "nreg"
    nobs!1 = "lev"
    nobs@units = UnitList(iv)
    nobs@description = "Root-mean-squre error"
    nobs@regions     = str_squeeze(regions(indreg))
    fout->$vnmobs$ = nobs
 
    delete([/rmse,vnmobs,rstd,nobs,filnms,fln/])   
   end do 

 end do 
end
