;;;;;;declare the variables for lat-lon map;;;;;;;;;;;;

  modvars    = (/"PRECT"/)
  facmod     = (/1000*24*3600/)
  varunt     = (/"mm day~S~-1~N~"/)
  panelstr1  = case1name
  panelstr2  = case2name

  statistical_test                           = False ;True
  statistical_siglev                         = 0.1
  l_plot_ttest                               = False

;define regions for plot
  latS                                       = -90.  ;negative for southern hemisphere
  latN                                       =  90.  ;negative for southern hemisphere
  pout                                       = "Global"
  pi                                         = 3.14159265
  rearth                                     = 6.37122e6
  grav                                       = 9.806
  sigma                                      = 5.67e-8 ; Stefan-Boltzmann constant

