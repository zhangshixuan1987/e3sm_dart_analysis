;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;this script is used to difine the absolute difference levels (diffgrp1),;;; 
;;;;;;;;the relative difference levels (diffgrp2), then choose color bar for plot;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

 ;;;subregions used by the analyses;;;;;;;;;;;;;;;;
 ;Low stratocumulus clouds
 ;Northeast Pacific (NEP) 15–35N, 120–140W
 ;Southeast Pacific (SEP) 10–30S, 75–95W
 ;Southeast Atlantic (SEA) 10–30S, 10W–10E
 ;Southeast Indian Ocean (SEI) 20–40S, 90–110E
 ;Stormtrack
 ;North Pacific (NP) 40–60N, 165–185E
 ;Northeast Atlantic (NEA) 10–30N, 25–45W
 ;North Atlantic (NA) 45–65N, 30–50W
 ;High Clouds
 ;Southern Ocean (SO) 45–65S, 130-170E; 180W–180E
 ; Subreg       = (/ "NEP",  "SEP",  "SEA",  "SEI",  "NP", "NEA",  "NA",    "SO"/)
 ; minlat       = (/  15.0,  -10.0,  -10.0,  -20.0,  40.0,  10.0,  45.0,   -45.0/)
 ; maxlat       = (/  35.0,  -30.0,  -30.0,  -40.0,  60.0,  30.0,  65.0,   -65.0/)
 ; minlon       = (/-140.0,  -95.0,  -10.0,   90.0, 165.0, -45.0, -50.0,   130.0/)
 ; maxlon       = (/-120.0,  -75.0,   10.0,  110.0, 185.0, -25.0, -30.0,   170.0/)
 ; nsubreg      = dimsizes(Subreg)

  Subreg       = (/ "North Pacific",  "CONUS",  "Tropics"/)
  Subrgs       = (/ "NP",  "CONUS",  "Trop"/)
  minlat       = (/  10.0,   20.0,  -25.0/)
  maxlat       = (/  65.0,   60.0,   25.0/)
  minlon       = (/ 110.0,  150.0,   60.0/)
  maxlon       = (/ 260.0,  300.0,  260.0/)
  nsubreg      = dimsizes(Subreg)

  olrminy      = (/228., 219., 244/)
  olrmaxy      = (/240., 234., 264/)
  pcpminy      = (/1.5,  2.2,  3.2/)
  pcpmaxy      = (/3.3,  3.2,  5.2/)

