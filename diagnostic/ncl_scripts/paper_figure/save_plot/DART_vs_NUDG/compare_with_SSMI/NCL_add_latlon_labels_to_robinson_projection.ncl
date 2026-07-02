;----------------------------------------------------------------------
; This function attaches lat/lon labels to a Robinson plot.
;
; You will likely need to change lat_values and/or lon_values to
; contain the locations where you want lat/lon labels.
;----------------------------------------------------------------------
function add_robinson_labels(wks,map,latspc,lonspc)
local lat_values, lon_values, lat_labels, lon_labels, \
      nlat, nlon, txres, x_in, y_in, x_out, y_out
begin

 txFontHeightF = 0.016
 lonS  = 0 
 
;-- pick some "nice" values for the latitude labels
  lat_values = (/-45,0,45/)*1. ;ispan(minlat,maxlat,latspc) * 1.
  lon_values = (/-90,90/) *1.  ;ispan(minlon,maxlon,lonspc) * 1.
  nlat       = dimsizes(lat_values)
  nlon       = dimsizes(lon_values)

;-- create the labels; add space before right labels, and after left labels
  lat_labels = where(lat_values.lt.0,abs(lat_values)+"~S~o~N~S",lat_values+"~S~o~N~N")
  lat_labels = where(lat_values.eq.0,"0~S~o~N~",lat_labels)
  lat_labels = where(abs(lat_values).eq.90,"",lat_labels) ;-- no label at lat=abs(90)

;---------------------
;-- latitude labels
;---------------------
  txres                  =  True     ;-- set text resources
  txres@txFontHeightF    =  txFontHeightF
  txres@txFontThicknessF =  2

  y_in  = lat_values                         ;-- plot coordinates
  x_in  = new(dimsizes(y_in),float)          ;-- plot coordinates
  x_out = new(dimsizes(x_in),float)          ;-- for NDC coordinates
  y_out = new(dimsizes(y_in),float)          ;-- for NDC coordinates
  
;-- left latitude labels
  txres@txJust = "CenterRight"
  x_in = lonS*1.0 
  datatondc(map,x_in,y_in,x_out,y_out)
  gsn_text_ndc(wks, lat_labels, x_out-0.012, y_out, txres)

;;-- right latitude labels
;  txres@txJust = "CenterLeft"
;  x_in = 180.0
;  datatondc(map,x_in,y_in,x_out,y_out)
;  gsn_text_ndc(wks, lat_labels, x_out+0.036, y_out, txres)

;---------------------
;-- longitude labels
;---------------------
  lon_labels = where(lon_values.lt.0,abs(lon_values)+"~S~o~N~W",lon_values+"~S~o~N~E")
  lon_labels = where(lon_values.eq.0,"0~S~o~N~",lon_labels)
  lon_labels = where(abs(lon_values).eq.180,"",lon_labels) ;-- no label at lon=abs(180)

;-- longitude labels
  txres@txJust           = "CenterCenter"
  txres@txFontHeightF    = txFontHeightF
  txres@txFontThicknessF =  2
  
  x_in  := lon_values
  y_in  := new(dimsizes(x_in),float)
  x_out := new(dimsizes(x_in),float)
  y_out := new(dimsizes(y_in),float)
  
;-- add top longitude labels
;  y_in = 90.0
;  datatondc(map,x_in,y_in,x_out,y_out)
;  gsn_text_ndc(wks, lon_labels, x_out, y_out+0.012, txres)

;-- add bottom longitude labels
  y_in = -90.0
  datatondc(map,x_in,y_in,x_out,y_out)
  gsn_text_ndc(wks, lon_labels, x_out, y_out-0.012, txres)

;-- that's it
  return(map)
  
end   ;-- end function add_robinson_labels

