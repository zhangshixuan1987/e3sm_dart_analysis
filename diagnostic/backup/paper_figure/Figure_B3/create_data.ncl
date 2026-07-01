load "./area_rectlinear_grid.ncl"

begin

  model                 = (/"PDNUDG_UVTQ_ENS01","PDNUDG_UVT_ENS01","PDNUDG_UV_ENS01", \
                            "PDDART_UVTQ_ENS80","PDDART_UVT_ENS80","PDDART_UV_ENS80"/)

  y_label               = (/"NDG-UVTQ","NDG-UVT","NDG-UV","EDA-UVTQ","EDA-UVT","EDA-UV"/)
  dim0                  = dimsizes(model)

  dim0    		= dimsizes(model)
  
  dimy                  = dimsizes(y_label)

  var                   = (/"US200","US500","US700","US850", \
                            "T200","T500","T700","T850", \
                            "Q500","Q700","Q850", \
                            "OLR","OLR","PRECT","PRECT"/)
  dim1    		= dimsizes(var)

  type    		= (/"tac","sac_3regions"/)
  dim2            	= dimsizes(type)

  region_lobnd 		= (/-90, -60, -20, -90/)
  region_hibnd 		= (/ 90,  60,  20,  90/)
  region_name 		= (/1, 2, 3, 4/)
  region_name@long_name = "1 - Polar region, 90S-60S, 60N-90N; " + \
                          "2 - Mid-latitude, 60S-30S, 30N-60N; " + \
                          "3 - Tropical zone, 20S-20N; " + \
                          "4 - Global"
  regid 		= (/0,1,2,3/)
  regions               = (/"Polar","MidLat","Tropics","Global"/)
  dim3			= dimsizes(regid)

  ;;;;;;;;;;;;;
  ; READ DATA ;
  ;;;;;;;;;;;;;
  modstr = ""
  do i = 0,dimy-1,1
   if(i.eq.dimy-1)then 
     modstr = modstr + i + " - " + y_label(i)+";"
   else
     modstr = modstr + i + " - " + y_label(i)+",  "
   end if 
  end do 
  print(modstr) 

  BASE_Dir              = "/pic/projects/E3SM_DA/zhan391/dart_paper_materials/DATA/POST_DIAG/"
  outtable 		= new((/dimy,dim1/), double)
  outtable              = 0.
  outtable!0 		= "nmodel"
  outtable!1 		= "nvar"
  models 		= ispan(0,dimy-1,1)
  models!0 		= "nmodel"
  models@long_name 	= modstr
  vars 			= ispan(0,dim1-1,1)
  vars!0 		= "nvar"
  vars@long_name 	= "0 - U200,   1 - U500,  2 - U700,  3 - U850, "        + \
		   	  "4 - T200,   5 - T500,  6 - T700,  7 - T850, "        + \
                          "8 - Q500,   9 - Q700,  10 - Q850, 11 - OLR_AVHRR, "  + \
                          "12 - OLR_HIRS, 13 - PRECT_PERSIANN_CDR, 14 - PRECT_TRMM ;"
  outtable&nmodel 	= models
  outtable&nvar   	= vars

  ;;;;;;;;;;;;;;;
  ; NDG_ERA ANC ;
  ;;;;;;;;;;;;;;;
  do k = 0, dim2-1
     if  (type(k) .eq. "tac") then
         fname                                  = "./"+type(k)+"_3regions_data.nc"
     else
         fname                                  = "./"+type(k)+"_data.nc"
     end if
     if  (isfilepresent(fname)) then
         f                                      = addfile(fname, "rw")
     else
         f                                      = addfile(fname, "cw")
     end if
     delete(fname)
     do n = 0, dim3-1

        do i = 0, dim1-1
           if  (i .eq. 11) then
               obs                              = "NOAA_AVHRR"
           else if  (i .eq. 12) then
               obs                              = "NOAA_HIRS"
           else if  (i .eq. 13) then
               obs                              = "PERSIANN_CDR"
           else if  (i .eq. 14) then
               obs                              = "TRMM"
           else
               obs                              = "ERA5"
           end if
           end if
           end if
           end if

           if  (var(i) .eq. "PRECT" .or. var(i) .eq. "OLR") then
               freq  	                        = "daily"
           else
               freq  	                        = "6hr"
           end if

           do j = 0, dim0-1

              ii = j

              year             		        = "2011" 
              if(isStrSubset(model(j),"ENS01")) then 

               fname                             = systemfunc("ls " + BASE_Dir+"CORR/"+model(j)+"-"+obs+"/"+freq+"/"+year+"/"+type(k)+"_"+var(i)+"_0001.nc")
              else
               fname                             = systemfunc("ls " + BASE_Dir+"CORR/"+model(j)+"-"+obs+"/"+freq+"/"+year+"/"+type(k)+"_"+var(i)+"_enmn.nc") 
              end if             
              file1                             = addfiles(fname, "r")
              ListSetType (file1, "join")   
              print(fname)

              corr                            = file1[:]->corr

	      if  (type(k) .eq. "sac_3regions") then
                  outtable(ii,i)                 = (/avg(corr(:,regid(n)))/)
                  delete([/file1,fname,corr/])
              else
                  lat      	                = file1[0]->lat
                  lon      	                = file1[0]->lon
                  gridarea 	                = area_global_rectilinear_grid(lat, lon, False)
                  gridarea@_FillValue           = corr@_FillValue
                  gridarea                      = where(ismissing(corr), gridarea@_FillValue, gridarea)
	          if  (n .eq. 0) then
                      a                         = closest_val(-90.,lat)
                      b                         = closest_val(-60.,lat)
                      c                         = closest_val(60.,lat)
                      d                         = closest_val(90.,lat)
                      if ( all(ismissing(gridarea(a:b,:))) .and. all(ismissing(gridarea(c:d,:))) ) then
                         outtable(ii,i)          = corr@_FillValue
                      else                        
                         avgarea                = (sum(gridarea(a:b,:)) + sum(gridarea(c:d,:))) / \
                                                  ((num(.not. ismissing(gridarea(a:b,:))) + \
                                                  num(.not. ismissing(gridarea(c:d,:)))) * 1.0)
                         outtable(ii,i)          = (/(sum(corr(a:b,:) * gridarea(a:b,:) / avgarea) + \
                                                     sum(corr(c:d,:) * gridarea(c:d,:) / avgarea)) / \
                                                     ((num(.not. ismissing(gridarea(a:b,:))) + \
                                                       num(.not. ismissing(gridarea(c:d,:)))) * 1.0) /)
                      end if 
	              delete([/lat,lon,gridarea/])
                  else if (n .eq. 1) then
                      a                         = closest_val(-60.,lat)
                      b                         = closest_val(-30.,lat)
                      c                         = closest_val(30.,lat)
                      d                         = closest_val(60.,lat)
                      if ( all(ismissing(gridarea(a:b,:))) .and. all(ismissing(gridarea(c:d,:))) ) then
                         outtable(ii,i)          = corr@_FillValue
                      else
                         avgarea                = (sum(gridarea(a:b,:)) + sum(gridarea(c:d,:))) / \
                                                  ((num(.not. ismissing(gridarea(a:b,:))) + \
                                                  num(.not. ismissing(gridarea(c:d,:)))) * 1.0)
                         outtable(ii,i)          = (/(sum(corr(a:b,:) * gridarea(a:b,:) / avgarea) + \
                                                     sum(corr(c:d,:) * gridarea(c:d,:) / avgarea)) / \
                                                     ((num(.not. ismissing(gridarea(a:b,:))) + \
                                                       num(.not. ismissing(gridarea(c:d,:)))) * 1.0) /)
                      end if
	              delete([/lat,lon,gridarea/])
                  else
                      a 	   	        = closest_val(region_lobnd(regid(n)),lat)
                      b 	   	        = closest_val(region_hibnd(regid(n)),lat)
                      if (num(.not. ismissing(gridarea(a:b,:))) .eq. 0) then
                          outtable(ii,i)         = gridarea@_FillValue
                      else
                          avgarea 	        = sum(gridarea(a:b,:)) / (num(.not. ismissing(gridarea(a:b,:))) * 1.0)
                          outtable(ii,i)         = (/avg(corr(a:b,:) * gridarea(a:b,:) / avgarea)/)
                      end if
	              delete([/lat,lon,gridarea/])
                  end if
                  end if
                  delete([/file1,fname,corr/])
              end if
           end do 
	end do
        f->$regions(n)$  = outtable
     end do
     delete(f)
  end do

end
