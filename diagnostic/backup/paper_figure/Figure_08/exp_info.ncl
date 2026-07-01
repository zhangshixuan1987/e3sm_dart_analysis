
  case      = (/"ERA5_ANL_ENS01", \
                "PDNUDG_ERA5_HIND_ENS01", \
                "PDNUDG_ERA5_HIND_ENS01", \
                "PDNUDG_ERA5_HIND_ENS01", \
                "PDNUDG_ERA5_HIND_ENS01", \
                "PDNUDG_ERA5_HIND_ENS01", \
                "PDDART_UVTQ_HIND_ENS80", \
                "PDDART_UVTQ_HIND_ENS80", \
                "PDDART_UVTQ_HIND_ENS80", \
                "PDDART_UVTQ_HIND_ENS80", \
                "PDDART_UVTQ_HIND_ENS80"/)

  hind      = (/"", \
                "day1",\
                "day2",\
                "day3",\
                "day4",\
                "day5",\
                "day1",\
                "day2",\
                "day3",\
                "day4",\
                "day5"/)


  Groups    = (/"ARM-SGP",   \
                "ER5_ANL",   \
                "hybrid_d1", \
                "hybrid_d2", \
                "hybrid_d3", \
                "hybrid_d4", \
                "hybrid_d5", \
                "dart_d1", \
                "dart_d2", \
                "dart_d3", \
                "dart_d4", \
                "dart_d5"/)

  ncases     = dimsizes(case)
  ngrps     = dimsizes(Groups)


