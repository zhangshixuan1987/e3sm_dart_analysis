
;  obs_types =(/ "RADIOSONDE_U_WIND_COMPONENT",\
;                "RADIOSONDE_V_WIND_COMPONENT",\
;                "RADIOSONDE_TEMPERATURE",\
;                "RADIOSONDE_SPECIFIC_HUMIDITY",\
;                "AIRCRAFT_U_WIND_COMPONENT",\
;                "AIRCRAFT_V_WIND_COMPONENT",\
;                "AIRCRAFT_TEMPERATURE",\
;                "ACARS_U_WIND_COMPONENT",\
;                "ACARS_V_WIND_COMPONENT",\
;                "ACARS_TEMPERATURE",\
;                "AIRS_TEMPERATURE",\
;                "AIRS_SPECIFIC_HUMIDITY",\
;                "SAT_U_WIND_COMPONENT",\
;                "SAT_V_WIND_COMPONENT",\
;                "GPSRO_REFRACTIVITY" /)

  CopyMetaData     = chartostring(fxx->CopyMetaData)
  ObsTypesMetaData = chartostring(fxx->ObsTypesMetaData) ; ( ObsTypes, stringlength )
  ObsTypes         = fxx->ObsTypes ; ( ObsTypes )
  ObsIndex         = fxx->ObsIndex ; ( ObsIndex ) ; dim+1
  obs_type         = fxx->obs_type ; ( ObsIndex )
  location         = fxx->location ; ( ObsIndex, locdim )
  time             = fxx->time
  observations     = fxx->observations(:,0) ;;
  vertype          = fxx->which_vert ;( ObsIndex )

  if(Varname.eq."U".or.Varname.eq."US")then

      indob01       = ind(str_squeeze(ObsTypesMetaData).eq."RADIOSONDE_U_WIND_COMPONENT")
      indtp1        = ind(obs_type.eq.ObsTypes(indob01))

  end if

  if(Varname.eq."V".or.Varname.eq."VS")then

      indob01       = ind(str_squeeze(ObsTypesMetaData).eq."RADIOSONDE_V_WIND_COMPONENT")
      indtp1        = ind(obs_type.eq.ObsTypes(indob01))

  end if

  if(Varname.eq."T")then

      indob01       = ind(str_squeeze(ObsTypesMetaData).eq."RADIOSONDE_TEMPERATURE")
      indtp1        = ind(obs_type.eq.ObsTypes(indob01))

  end if

  if(Varname.eq."Q")then

      indob01       = ind(str_squeeze(ObsTypesMetaData).eq."RADIOSONDE_SPECIFIC_HUMIDITY")
      indtp1        = ind(obs_type.eq.ObsTypes(indob01))

  end if


