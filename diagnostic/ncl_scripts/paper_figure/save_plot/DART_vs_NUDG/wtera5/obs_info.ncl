
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
    dymd             = cd_calendar(time, 4)
    print(min(dymd) + " " +max(dymd))
    ;cd_convert(time,)
    ;print(time@units)

    indob01       = ind(str_squeeze(ObsTypesMetaData).eq."RADIOSONDE_U_WIND_COMPONENT" .or. \
                        str_squeeze(ObsTypesMetaData).eq."AIRCRAFT_U_WIND_COMPONENT" .or. \
                        str_squeeze(ObsTypesMetaData).eq."ACARS_U_WIND_COMPONENT" .or. \
                        str_squeeze(ObsTypesMetaData).eq."SAT_U_WIND_COMPONENT" )
  
    indob02       = ind(str_squeeze(ObsTypesMetaData).eq."RADIOSONDE_V_WIND_COMPONENT" .or. \
                        str_squeeze(ObsTypesMetaData).eq."AIRCRAFT_V_WIND_COMPONENT" .or. \
                        str_squeeze(ObsTypesMetaData).eq."ACARS_V_WIND_COMPONENT" .or. \
                        str_squeeze(ObsTypesMetaData).eq."SAT_V_WIND_COMPONENT")
  
    indob03       = ind(str_squeeze(ObsTypesMetaData).eq."RADIOSONDE_TEMPERATURE" .or. \
                        str_squeeze(ObsTypesMetaData).eq."AIRCRAFT_TEMPERATURE" .or. \
                        str_squeeze(ObsTypesMetaData).eq."AIRS_TEMPERATURE" )

    indob04       = ind(str_squeeze(ObsTypesMetaData).eq."RADIOSONDE_SPECIFIC_HUMIDITY" .or. \
                        str_squeeze(ObsTypesMetaData).eq."AIRS_SPECIFIC_HUMIDITY")

