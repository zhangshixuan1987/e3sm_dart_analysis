  load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
  load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
  load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

; Purpose: A tempolate to make a 4-panel lat-lon plot
; panel 1: clim vs obs 
; panel 2: CAPT vs obs
; panel 3: DART vs obs
; Author : Shixuan Zhang

begin

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

  dpath                                      = "/pic/projects/E3SM_DA/zhan391/dart_paper_materials/DATA/"
  opath                                      = "./"
  case1name                                  = "GPCP"
  case2name                                  = "PDDART_UVTQ_ENS80"
  tpath                                      = dpath + case1name + "/monthly/"
  cpath                                      = dpath + case2name + "/cam_h0/monthly/" 

  load "./share_info_for_latlon_map.ncl"

  do ll = 0, dimsizes(pout)-1

        file1 			   	     = systemfunc("ls -1 "+tpath+"/*2011*.nc")
        file2                                = systemfunc("ls -1 "+cpath+"/*2011*.nc")
        f1			             = addfiles(file1,"r")
        f                                    = systemfunc("ls -1 "+cpath+"/*2011*.nc")
        f2                                   = addfiles(file2,"r")
        gw1                                  = f1[0]->gw 
        gw2                                  = f2[0]->gw

        ListSetType (f1, "join")
        ListSetType (f2, "join")
        delete([/file1,file2/])

        do jj = 0, dimsizes(modvars)-1

          mvarnam  = modvars(jj)
          print("working on variable "+ mvarnam)

          var1 = f1[:]->$mvarnam$
          if(mvarnam.eq."PRECT")then 
           var2 = f2[:]->PRECC 
           var2 = f2[:]->PRECC + f2[:]->PRECL
          else 
            var2 = f2[:]->$mvarnam$
          end if 

          printVarSummary(var1)
          printVarSummary(var2)

          var1@_FillValue                    = -9999.
          var2@_FillValue                    = -9999.

          var1                               = var1 ;*24.0*3600.0 ;facmod(jj)
          var2                               = var2*facmod(jj)
          var1@units                         = varunt(jj)
          var2@units                         = varunt(jj)

          ;;;;;;select the data for plots;;;;;;;;;;;;;;;;;;;;;;;;;;;
          vp0                                 = dim_avg_n_Wrap(var1(:,{latS:latN},:),0)
          vp2                                 = dim_avg_n_Wrap(var2(:,:,{latS:latN},:),1)
          vp1                                 = conform(vp2,vp0,(/1,2/))
          vp1!0                               = "time"
          vp2!0                               = "time"
          gw                                  = gw1({latS:latN})
          ddd1                                = dimsizes(vp1)
          ddd2                                = dimsizes(vp2)
          delete([/var1,var2,vp0/])

          copy_VarCoords(vp2,vp1)
          printVarSummary(vp1)
          printVarSummary(vp2)
          ;;generate the weighting metrics 
          mcor                          = new((/ddd1(1),ddd1(2)/),float)
          mcor@_FillValue               = vp1@_FillValue
          do i = 0, ddd2(1)-1
             mcor(i,:)                  = tofloat(gw(i))*(2.*pi/ddd1(2))*rearth^2.
          end do

          if(str_lower(statistical_test).eq."true")then 
            l_plot_ttest = True 
            xtmp = vp1(lat|:,lon|:,time|:)       ; reorder but do it only once [temporary]
            ytmp = vp2(lat|:,lon|:,time|:)
           ;printVarSummary(xtmp) 
            xAve = dim_avg (xtmp)              ; calculate means at each grid point
            yAve = dim_avg (ytmp)
            xVar = dim_variance (xtmp)         ; calculate variances
            yVar = dim_variance (ytmp)
            xEqv = equiv_sample_size (xtmp, statistical_siglev,0)
            yEqv = equiv_sample_size (ytmp, statistical_siglev,0)
            xN   = wgt_areaave2 (xEqv, mcor, 0)    ; wgty could be gaussian weights
            yN   = wgt_areaave2 (yEqv, mcor, 0)
           ;print(xN+  " "+yN)          
            iflag = True                       ; population variance similar
            prob  = ttest(xAve,xVar,xN, yAve,yVar,yN, iflag, False)
           ;print(min(prob)+ " " +max(prob))
           ;printVarSummary(prob)
            delete([/xtmp,ytmp,xAve,yAve,xVar,yVar,xEqv,yEqv,xN,yN/])
 	  end if 

	   vp1x				    = dim_avg_n_Wrap(vp1,0)
	   vp2x				    = dim_avg_n_Wrap(vp2,0)
	  ;print(vp1x@_FillValue)

           vp1a				    = vp1x
           vp2a				    = vp2x
           vp11                             = where(ismissing(vp1a(:,:)), vp1x@_FillValue, vp1a(:,:)*mcor)
           vp1m                             = sum(vp11)
           mcor1                            = where(ismissing(vp1a(:,:)), mcor@_FillValue, mcor)
           vp22                             = where(ismissing(vp2a(:,:)), vp2x@_FillValue, vp2a(:,:)*mcor)
           vp2m                             = sum(vp22)
           mcor2                            = where(ismissing(vp2a(:,:)), mcor@_FillValue, mcor)
           vp1m                             = vp1m / sum(mcor1)
           vp2m                             = vp2m / sum(mcor2)
           delete([/vp1,vp2,mcor1,mcor2,vp11,vp22/])

           vp1b                             = where(abs(vp1a) .lt. 1.e-30, vp1x@_FillValue, vp1a)
           vp2b                             = where(abs(vp2a) .lt. 1.e-30, vp2x@_FillValue, vp2a)
           vp1b                             = where(ismissing(vp2b), vp1x@_FillValue, vp1b)
           vp2b                             = where(ismissing(vp1b), vp2x@_FillValue, vp2b)

           adiff                            = vp1a
           adiff                            = vp1a-vp2a

           rdiff                            = vp1a
           rdiff                            = (vp1b-vp2b)*100./abs(vp2b)
              
           mcor3                            = where(ismissing(rdiff(:,:)), mcor@_FillValue, mcor)
           rdifft                           = where(ismissing(rdiff(:,:)), rdiff@_FillValue, rdiff(:,:)*mcor)
           rdiffm                           = sum(rdifft) / sum(mcor3)
           delete([/vp1x,vp2x,rdifft,mcor3,mcor/])

           if(l_plot_ttest)then 
            adiff                           = where(prob.le.statistical_siglev,adiff,adiff@_FillValue)
            rdiff                           = where(prob.le.statistical_siglev,rdiff,rdiff@_FillValue)
           end if 


           ;;;start to process the plot;;;;
           load "../share_color_bar_for_global_map.ncl"
           wtype                        = "eps"
          ;wtype@wkWidth                = 2500
          ;wtype@wkHeight               = 2500
           figdir                       = opath
           fe                           = mvarnam+"_latlon_"+pout(ll) 
           wks                          = gsn_open_wks(wtype,figdir+ fe)

           gsn_merge_colormaps(wks,"amwg","amwg_blueyellowred")  ; merge two color maps

           plot   = new (4,graphic)


;;;;;;;;;;;;;;;;;;;;;;;;;
;
;    Make the Plot
;
;;;;;;;;;;;;;;;;;;;;;;;;;
	      res                  	        = True                  ; plot mods desired
	      res@cnFillOn         	        = True                  ; turn on color fill
	      res@cnLinesOn          	        = False                 ; no contour lines
	      res@cnLineLabelsOn     	        = False
              res@gsnFrame                      = False                 ; Do not draw plot
              res@gsnDraw                       = False                 ; Do not advance frame

              FontHeightF = 0.018
              res@tiMainFontThicknessF          = 3.0
              res@tiMainFontHeightF             = FontHeightF*1.2
              res@tmYLLabelFontHeightF          = FontHeightF
              res@tmXBLabelFontHeightF          = FontHeightF 
              res@tiXAxisFontHeightF            = FontHeightF
              res@tiYAxisFontHeightF            = FontHeightF
              res@gsnStringFontHeightF          = FontHeightF
              res@cnLineLabelFontHeightF        = FontHeightF
              res@lbLabelFontHeightF            = FontHeightF*0.8
              res@lbTitleFontHeightF            = FontHeightF*0.8

              res@tmXTOn                        = False
	     ;res@tmYLLabelFontHeightF	 	= 0.015
              res@tmBorderThicknessF            = 1.0
              res@tmXBMajorThicknessF           = 1.0
              res@tmXBMinorThicknessF           = 1.0
              res@tmYLMajorThicknessF           = 1.0
              res@tmYLMinorThicknessF           = 1.0
              res@tmYRMajorThicknessF           = 1.0
              res@tmYRMinorThicknessF           = 1.0

              res@mpFillOn                      = False        ; turn off map fill
              res@mpGeophysicalLineThicknessF   = 2.0
              res@mpMinLonF                     =   0
              res@mpMaxLonF                     = 360
              res@mpCenterLonF                  = 180     ; This is necessary to get the correct map

    	      res@gsnMajorLatSpacing            = 30
              res@gsnMajorLonSpacing            = 45
              res@gsnMinorLatSpacing            = 15
	      res@gsnMinorLonSpacing            = 15

	      res@lbLabelBarOn      		= True
	      res@lbOrientation     		= "Vertical"
              res@lbPerimOn                     = False             ; default has box
              res@pmLabelBarHeightF             = 0.38
              res@pmLabelBarWidthF              = 0.1
              res@pmLabelBarParallelPosF        = 0.50
              res@pmLabelBarOrthogonalPosF      = 0.05
             ;res@lbTitleString                 = "" 

	      res@cnInfoLabelOn     		= False
	      res@cnLevelSelectionMode      	= "ExplicitLevels"       ; manual levels
	      res@cnMissingValFillColor 	= "White" ;"gray76"               ; black = 1

	     ;res@gsnRightStringFontHeightF	= 0.025
             ;res@gsnRightStringOrthogonalPosF  = 0.06
	     ;res@gsnLeftStringFontHeightF	= 0.025

              res1 = res
              res1@cnLevels                    := sprintf("%7.2f",s1)
              res1@cnFillColors                 = (/3,4,5,6,7,8,9,10,11,12,13,29,30,15,16,17/)
              res1@gsnLeftString                = str_upper(mvarnam)+ " ("+varunt(jj)+")"
              res1@tiMainString                 = panelstr1
              if(max(abs(s1)).ge.100.0)then
                res1@gsnRightString             = "mean: "+sprintf("%5.1f",vp1m)
                res1@lbLabelStrings             = sprintf("%5.0f",s1)
              else
                res1@gsnRightString             = "mean: "+sprintf("%5.2f",vp1m)
                res1@lbLabelStrings             = sprintf("%5.2f",s1)
              end if 
	      plot(0)   			= gsn_csm_contour_map_ce(wks,vp1a(:,:),res1)
             
              res1@gsnLeftString                = str_upper(mvarnam)+ " ("+varunt(jj)+")"
              res1@gsnCenterString              = "" ;seasons(kk)
              res1@tiMainString                 = panelstr2
              if(max(abs(s1)).ge.100.0)then
                res1@gsnRightString             = "mean: "+sprintf("%5.1f",vp2m)
                res1@lbLabelStrings             = sprintf("%5.0f",s1)
              else
                res1@gsnRightString             = "mean: "+sprintf("%5.2f",vp2m)
                res1@lbLabelStrings             = sprintf("%5.2f",s1)
              end if
	      plot(1) 			        = gsn_csm_contour_map_ce(wks,vp2a(:,:),res1)

              res2 = res
	      res2@cnLevels      		= sprintf("%7.2f",s2)
	      res2@cnFillColors  		= (/18,20,22,23,24,25,26,27,28,30,31,33/)
	      res2@gsnLeftString 		= str_upper(mvarnam)+ " ("+varunt(jj)+")"
              res2@tiMainString                 = panelstr1 + " - " + panelstr2 ; "absolute difference"
              res2@gsnCenterString              = "" ;seasons(kk)
              if(max(abs(s2)).ge.100.0)then
                res2@gsnRightString             = "mean: "+sprintf("%5.1f",vp1m - vp2m)
                res2@lbLabelStrings             = sprintf("%5.0f",s2)
              else
                res2@gsnRightString             = "mean: "+sprintf("%5.2f",vp1m - vp2m)
                res2@lbLabelStrings             = sprintf("%5.2f",s2)
              end if
	      plot(2) 			        = gsn_csm_contour_map_ce(wks,adiff(:,:),res2)
	
              res3 = res
              res3@cnLevels      		= sprintf("%7.2f",s3)
              res3@cnFillColors                 = (/18,20,22,23,24,25,26,27,28,30,31,33/)
              res3@gsnLeftString                = str_upper(mvarnam)+ " ("+varunt(jj)+")"
	      res3@tiMainString 		= "Relative difference (%)"
              res3@gsnCenterString              = "";seasons(kk)
              if(max(abs(s3)).ge.10.0)then
                res3@gsnRightString             = "mean: "+sprintf("%5.1f", rdiffm)
                res3@lbLabelStrings             = sprintf("%5.0f",s3)
              else
                res3@gsnRightString             = "mean: "+sprintf("%5.2f", rdiffm)
                res3@lbLabelStrings             = sprintf("%5.2f",s3)
              end if
	      plot(3)	 		        = gsn_csm_contour_map_ce(wks,rdiff(:,:),res3)
	 
              pres                              = True        ; panel plot mods desired
              pres@gsnMaximize                  = False       ; fill the page
              pres@txFontHeightF                = 0.012
              pres@txFontThicknessF             = 2.
              pres@gsnPanelXWhiteSpacePercent   = 3.
              pres@gsnPanelYWhiteSpacePercent   = 5.
              pres@txString                     = "" ;"("+seasons(kk)+")"  
                                                  ;str_upper(mvarnam)+ " ("+seasons(kk)+"; unit: "+unit+")"
              gsn_panel(wks,plot(:),(/2,2/),pres)

              ;convert the figure 
              ;if (wtype .eq. "png") then
              ;  tmpa = systemfunc("convert "+figdir+fe+".png -trim del.png")
              ;  tmpb = systemfunc("mv del.png "+fe+".png")
              ;end if

              delete([/vp1a,vp2a,adiff,rdiff,vp1b,vp2b/])

           delete([/plot,res,pres,wks,ddd1,ddd2,s1,s2,s3/])

        end do       ; end of looping over variables

        delete([/f1,gw1/])
        delete([/f2,gw2/])

  end do
end
