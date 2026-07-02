;----------------------------------------------------------------------
; table_8.ncl
;
; Concepts illustrated:
;   - Drawing a table of filled triangles
;   - Using gsn_csm_blank_plot to get custom tickmark labels
;   - Using "getvalues" to retrieve the min/max of axes
;   - Turning off the top and right tickmarks
;   - Using functions for cleaner code
;   - Attaching multiple custom labelbars to a plot
;   - Attaching filled triangles to a plot
;----------------------------------------------------------------------
;
; These files are loaded by default in NCL V6.2.0 and newer
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "./function.ncl"
;----------------------------------------------------------------------
; Main code
;----------------------------------------------------------------------
begin
  start_time = get_cpu_time()
;
; Generate a 4 x nvars x nmodels dummy array
;     (0,:,:)  - data mins across each nlat x nlon array
;     (1,:,:)  - data maxs     ""
;     (2,:,:)  - data averages ""
;     (3,:,:)  - data stddevs   ""

  var_list             = (/ "U200","U500","U700","U850", \
                            "T200","T500","T700","T850", \
                            "Q500","Q700","Q850", \
                            "AVHRR","HIRS","P-CDR","TRMM"/)

  nvar_list            = ispan(0,dimsizes(var_list)-1,1) ;(/0,1,2,3,4,5,6,7,12,13,15,16/)

  region_list          = (/"hybrid IC (day1)", "hybrid IC (day2)", \
                           "hybrid IC (day3)", "hybrid IC (day4)", \
                           "hybrid IC (day5)", "EAM/DART (day1)", \
                           "EAM/DART (day2)",  "EAM/DART (day3)", \
                           "EAM/DART (day4)",  "EAM/DART (day5)"  \
                           /)

  region_list          = region_list(::-1)
                   
  sname                = (/"(a) Spatial correlation, polar regions", \
                           "(b) Temporal correlation, polar regions", \
                           "(c) Spatial correlation, mid-latitudes", \
                           "(d) Temporal correlation, mid-latitudes", \
                           "(e) Spatial correlation, tropics", \
                           "(f) Temporal correlation, tropics" /)
  type                 = (/"sac","tac"/)
  regions              = (/"Polar","MidLat","Tropics"/)
  dim0                 = dimsizes(type)
  dim1                 = dimsizes(regions)

  plot                 = new(dim1*dim0, graphic)
  fname                = "Fig07"
  wtype                = "pdf"
  wks                  = gsn_open_wks(wtype, fname)

  ;---Set nice levels to use for each of the 4 quantities
   levels              = (/0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9/) ; get_nice_levels(data)
  ;levels              = (/0.3,0.4,0.5,0.6,0.7,0.8,0.85,0.9,0.95/)
  ;---Set colormaps to use for each of the 4 quantities
  ;  min_cmap = subset_cmap("MPL_Blues",18,127)
  ;cmap                = read_colormap_file("amwg_blueyellowred")
  cmap1                = read_colormap_file("radar")
  cmap2                = read_colormap_file("cb_9step")
  cmap3                = read_colormap_file("radar_1")
  cmap4                = read_colormap_file("prcp_2")
  cmap5                = read_colormap_file("StepSeq25")
  cmap6                = read_colormap_file("tbrAvg1")
  cmap                 = (/cmap5(15,:),cmap5(17,:),cmap5(19,:),cmap5(14,:),cmap6(64,:),cmap1(7,:),\
                           cmap1(8,:),cmap1(10,:),cmap1(12,:),cmap1(13,:)/) 

  var_group_num    = (/3,7,10,12/)
  exp_group_num    = (/4/)

  do i = 0, dim0-1
     f                 = addfile("./"+type(i)+"_3regions_data.nc", "r")
     do j = 0, dim1-1

        data          = f->$regions(j)$
        data          = where(ismissing(data), -1, data)

        ;---Create a blank plot that we can add triangles to later.
        row_labels     = region_list
        col_labels     = var_list
        if(type(i).eq."tac")then
          row_labels   = ""
        end if 
        plot(j*dim0+i) = create_plot(wks,row_labels,col_labels,sname(j*dim0+i),var_group_num,exp_group_num)

        ;---Add filled triangles in the given quadrant
        add_filled_blocks(wks,plot(j*dim0+i),data(:,:),levels,cmap,regions(j),var_group_num,exp_group_num)

        ;---Add labelbars for each of the four quantities.
        if  (i .eq. dim0-1) then
         add_labelbar(wks,plot(j*dim0+i),cmap,""+sprintf("%5.2f",levels),"","rgt2")
        ;add_labelbar(wks,plot,std_cmap,""+std_levels,"std","rgt1")
        end if

        delete(data)
     end do
     delete(f)
  end do

  txres               = True
  txres@txFontHeightF = 0.006
  txres@txFont        = "helvetica"
  gsres               = True
  gsres@gsLineColor   = "black"

  do i = 0, 11
     if  (i .eq. 0) then
         ;--Add upper left OLR
         label               = "OLR"
         a                   = 0.428 ;horizonal pos
         b                   = 0.625 ;vertical pos
         c                   = 0.008
         d                   = 0.012
         e                   = 0.008
     else if (i .eq. 1) then
         ;--Add upper right OLR
         a                   = 0.798
     else if (i .eq. 2) then
         ;--Add middle left OLR
         a                   = 0.428 ;
         b                   = 0.385 ; vertical pos
     else if (i .eq. 3) then
         ;--Add middle right OLR
         a                   = 0.798
     else if (i .eq. 4) then
         ;--Add bottom left OLR
         a                   = 0.428
         b                   = 0.145
     else if (i .eq. 5) then
         ;--Add bottom right OLR
         a                   = 0.798
     else if (i .eq. 6) then
         ;--Add upper left PRECT
         label               = "PRECT"
         a                   = 0.476
         b                   = 0.625
         c                   = 0.008
         d                   = 0.016
         e                   = 0.007
     else if (i .eq. 7) then 
         ;--Add upper right PRECT
         a                   = 0.847
     else if (i .eq. 8) then
         ;--Add middle left PRECT
         a                   = 0.476 ; 
         b                   = 0.385 ; vertical pos
     else if (i .eq. 9) then 
         ;--Add middle right PRECT
         a                   = 0.847
     else if (i .eq. 10) then
         ;--Add bottom left PRECT
         a                   = 0.476
         b                   = 0.145
     else
         ;--Add middle right PRECT
         a                   = 0.847
     end if
     end if
     end if
     end if
     end if
     end if
     end if
     end if
     end if
     end if
     end if
     gsn_text_ndc(wks,label, a, b ,txres)
     gsn_polyline_ndc(wks,(/a-d,a-d-e/),  (/b,b/)  ,gsres)
     gsn_polyline_ndc(wks,(/a-d-e,a-d-e/),(/b+c,b/),gsres)
     gsn_polyline_ndc(wks,(/a+d,a+d+e/),  (/b,b/)  ,gsres)
     gsn_polyline_ndc(wks,(/a+d+e,a+d+e/),(/b+c,b/),gsres)
  end do
 
  resP                            = True
  resP@gsnMaximize                = False
  resP@gsnFrame                   = True
  resP@lbLabelAutoStride          = False
  resP@gsnPanelRight              = 0.9
  resP@gsnPanelXWhiteSpacePercent = 2.0
  resP@gsnPanelYWhiteSpacePercent = 6.0
  resP@gsnPanelXF                 = (/0.15,0.52,0.15,0.52,0.15,0.52/)
  gsn_panel(wks,plot(:),(/dim1,dim0/),resP)
 
  if (wtype .eq. "png") then
      tmpa = systemfunc("convert "+fname+".png -trim del.png")
      tmpb = systemfunc("mv del.png "+fname+".png")
  end if

end
