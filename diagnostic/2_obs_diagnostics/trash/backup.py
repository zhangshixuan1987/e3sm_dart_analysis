def extract_obs_group():
    obs_group = {'Conventional' : 
                     ['TEMPERATURE','SPECIFIC_HUMIDITY','PRESSURE', 
                      'RADIOSONDE_U_WIND_COMPONENT','RADIOSONDE_V_WIND_COMPONENT',
                      'RADIOSONDE_GEOPOTENTIAL_HGT','RADIOSONDE_SURFACE_PRESSURE','RADIOSONDE_TEMPERATURE',
                      'RADIOSONDE_SPECIFIC_HUMIDITY', 'DROPSONDE_U_WIND_COMPONENT','DROPSONDE_V_WIND_COMPONENT',
                      'DROPSONDE_SURFACE_PRESSURE', 'DROPSONDE_TEMPERATURE', 'DROPSONDE_SPECIFIC_HUMIDITY',
                      'AIRCRAFT_U_WIND_COMPONENT', 'AIRCRAFT_V_WIND_COMPONENT','AIRCRAFT_TEMPERATURE',
                      'AIRCRAFT_SPECIFIC_HUMIDITY','ACARS_U_WIND_COMPONENT','ACARS_V_WIND_COMPONENT',
                      'ACARS_TEMPERATURE','ACARS_SPECIFIC_HUMIDITY','RADIOSONDE_SURFACE_ALTIMETER',
                      'DROPSONDE_SURFACE_ALTIMETER','METAR_ALTIMETER','MESONET_SURFACE_ALTIMETER',
                      'MARINE_SFC_U_WIND_COMPONENT','MARINE_SFC_V_WIND_COMPONENT','MARINE_SFC_TEMPERATURE',
                      'MARINE_SFC_SPECIFIC_HUMIDITY','MARINE_SFC_PRESSURE','LAND_SFC_U_WIND_COMPONENT',
                      'LAND_SFC_V_WIND_COMPONENT','LAND_SFC_TEMPERATURE','LAND_SFC_SPECIFIC_HUMIDITY',
                      'LAND_SFC_PRESSURE','MARINE_SFC_ALTIMETER','LAND_SFC_ALTIMETER' ],
                 'Satellite' :
                     ['GPSRO_REFRACTIVITY','SAT_TEMPERATURE','SAT_TEMPERATURE_ELECTRON','SAT_TEMPERATURE_ION',
                      'SAT_DENSITY_NEUTRAL_O3P', 'SAT_DENSITY_NEUTRAL_O2', 'SAT_DENSITY_NEUTRAL_N2',
                      'SAT_DENSITY_NEUTRAL_N4S', 'SAT_DENSITY_NEUTRAL_NO', 'SAT_DENSITY_NEUTRAL_N2D',
                      'SAT_DENSITY_NEUTRAL_N2P', 'SAT_DENSITY_NEUTRAL_H',  'SAT_DENSITY_NEUTRAL_HE',
                      'SAT_DENSITY_NEUTRAL_CO2', 'SAT_DENSITY_NEUTRAL_O1D', 'SAT_DENSITY_ION_O4SP', 
                      'SAT_DENSITY_ION_O2P', 'SAT_DENSITY_ION_N2P', 'SAT_DENSITY_ION_NP', 
                      'SAT_DENSITY_ION_O2DP', 'SAT_DENSITY_ION_O2PP', 'SAT_DENSITY_ION_HP',
                      'SAT_DENSITY_ION_HEP', 'SAT_DENSITY_ION_E', 'SAT_VELOCITY_U',
                      'SAT_DENSITY_ION_NOP','SAT_VELOCITY_V', 'SAT_VELOCITY_W',
                      'SAT_VELOCITY_U_ION','SAT_VELOCITY_V_ION', 'SAT_VELOCITY_W_ION',
                      'SAT_VELOCITY_VERTICAL_O3P','SAT_VELOCITY_VERTICAL_O2', 'SAT_VELOCITY_VERTICAL_N2',
                      'SAT_VELOCITY_VERTICAL_N4S', 'SAT_VELOCITY_VERTICAL_NO', 'SAT_F107','SAT_RHO', 'GPS_PROFILE', 
                      'COSMIC_ELECTRON_DENSITY', 'GND_GPS_VTEC','CHAMP_DENSITY','MIDAS_TEC','SSUSI_O_N2_RATIO',
                      'GPS_VTEC_EXTRAP', 'SABER_TEMPERATURE', 'AURAMLS_TEMPERATURE', 
                      'SAT_U_WIND_COMPONENT', 'SAT_V_WIND_COMPONENT', 'ATOV_TEMPERATURE','AIRS_TEMPERATURE',
                      'AIRS_SPECIFIC_HUMIDITY','GPS_PRECIPITABLE_WATER', 'VADWND_U_WIND_COMPONENT',
                      'VADWND_V_WIND_COMPONENT','CIMMS_AMV_U_WIND_COMPONENT','CIMMS_AMV_V_WIND_COMPONENT'],
                }
    
    return obs_group 

def read_metrics_data(var,var_dict,exp_dict,path_template,file_template):
    
    data_dict = dict() 
    for exp in exp_dict.keys():
        date = exp_dict[exp]['period']
        time_unit = 'days since {}-{}-{} '.format(
            date.split("-")[0][0:4],
            date.split("-")[0][4:6],
            date.split("-")[0][6:8]
        )
        run = exp_dict[exp]['run']
        key = exp_dict[exp]['key']
        diag = exp_dict[exp]['diag2']
        path = path_template.replace('%(RUNNAME)',run).replace('%(CASENAME)',key).replace('%(DIAG)',diag)
        file = file_template.replace('%(RUNNAME)',exp).replace('%(RES)',resolution).replace('%(MACH)',machine).replace('%(KEY)',diag_key).replace('%(TIME)',date)
        
        time,plev,plevp1,mlev,mlevp1,hlev,hlevp1,tsprd,trmse,tnpos,tnuse,hrank = read_dart_obs_diag(regnam,var,dtype,var_dict[var],date,path,file)
        
        if exp not in data_dict.keys():
            data_dict[exp] = dict() 
        
        data_dict[exp]['time'] = time - time[0]
        data_dict[exp]['time_unit'] = time_unit
        data_dict[exp]['rmse'] = trmse
        data_dict[exp]['spread'] = tsprd
        data_dict[exp]['rejection'] = np.where(tnpos > 0, 100.0 - (tnuse * 100.0/tnpos), np.nan)
        data_dict[exp]['histrank'] = hrank
        data_dict[exp]['rmse_str'] = 'RMSE'
        data_dict[exp]['spread_str'] = 'Total Spread'
        data_dict[exp]['rejection_str'] = 'Data Rejection(%)'
        data_dict[exp]['period'] = date

        if var_dict[var]['lev_type'] == 'pressure':
            data_dict[exp]['lev'] = plev
            data_dict[exp]['levp'] = plevp1
            levstr = []
            for i,lev in enumerate(plev):
                pstr = '{}-{} hPa'.format(int(plevp1[i+1]),int(plevp1[i]))
                levstr.append(pstr)
            data_dict[exp]['levstr'] = levstr 
        elif var_dict[var]['lev_type'] == 'height':
            data_dict[exp]['lev'] = hlev
            data_dict[exp]['levp'] = hlevp1
            levstr = []
            for i,lev in enumerate(hlev):
                pstr = '{}-{} m'.format(hlevp1[i],hlevp1[i+1])
                levstr.append(pstr)
            data_dict[exp]['levstr'] = levstr 
        elif var_dict[var]['lev_type'] == 'model':
            data_dict[exp]['lev'] = mlev
            data_dict[exp]['levp'] = mlevp1
            levstr = []
            for i,lev in enumerate(mlev):
                pstr = '{}-{} layer'.format(mlevp1[i],mlevp1[i+1])
                levstr.append(pstr)
            data_dict[exp]['levstr'] = levstr 
            
    return data_dict,levstr 

def draw_obs_diag_prof(var,var_dict,data_dict,fig_path,fgw=20,fgh=12,hs=0.2,ws=0.2):
    
    ncols = len(data_dict.keys())
    nrows = 1
    
    #create figure  
    frac = 12.0/35.0
    frac = fgh/fgw
    fontz = 20 * fgw*1.0/fgh * frac
    fig, axes = plt.subplots(nrows=nrows,
                             ncols=ncols, 
                             figsize=(fgw,fgh))
    
    cmap = {
        'blue':    '#377eb8', 
        'orange':  '#ff7f00',
        'green':   '#4daf4a',
        'pink':    '#f781bf',
        'brown':   '#a65628',
        'purple':  '#984ea3',
        'gray':    '#999999',
        'red':     '#e41a1c',
        'yellow':  '#dede00'
    } 
 
    lnthks = np.linspace(1,8,len(data_dict.keys()))  
    colors = list(cmap.keys())[0:len(data_dict.keys())]
    sizes = np.linspace(15, 25, len(data_dict.keys())) / 3.5
    mksize = np.linspace(10,20,len(data_dict.keys()))
    
    x1min = var_dict['y1aix'][0]
    x1max = var_dict['y1aix'][1]
    x2min = var_dict['y2aix'][0]
    x2max = var_dict['y2aix'][1]
    
    if var_dict['lev_type']  == 'pressure':
        levstr = 'Pressure (hPa)'
    elif var_dict['lev_type']  == 'height':
        levstr = 'Height (m)'
    elif var_dict['lev_type']  == 'model':
        levstr = 'Model Level'
        
        
    for j,exp in enumerate(data_dict.keys()):

        lev = data_dict[exp]['lev'][:]
        levp = data_dict[exp]['levp'][:]
        rmse = data_dict[exp]['rmse'][:]
        spread = data_dict[exp]['spread'][:]
        rate = data_dict[exp]['rejection'][:]
        rmse_str = data_dict[exp]['rmse_str']
        spread_str = data_dict[exp]['spread_str']
        rejection_str = data_dict[exp]['rejection_str']
        
        ymin = min(levp)-1.0
        ymax = max(levp)
        #print(ymin,ymax)
        #print(xxx)
        
        k = j 
            
        line1 = axes.flat[k].plot(
            rmse, lev, 
            color = cmap['red'],
            marker = "o",
            markersize = mksize[1],
            linestyle = "-",
            linewidth = lnthks[1],
            label = "RMSE"
        )
        
        line2 = axes.flat[k].plot(
            spread, lev,
            color = cmap['blue'],
            marker = "v",
            markersize = mksize[1],
            linestyle = "-",
            linewidth = lnthks[1],
            label = "Total Spread"
        )

        
        # Usa geocat.viz.util convenience function to add minor and major tick lines
        gv.add_major_minor_ticks(axes.flat[k], x_minor_per_major=1, y_minor_per_major=1, labelsize=fontz)

        # Usa geocat.viz.util convenience function to set axes parameters without calling several matplotlib functions
        # Set axes limits, and tick values
        gv.set_axes_limits_and_ticks(
            axes.flat[k],                         
            xlim=(x1min,x1max),
            #ylim=(ymin,ymax)
            #yticks=np.arange(0, 17, 3)
            )
        
        # Customize ticks and labels
        axes.flat[k].tick_params(labelsize=fontz*1.1, length=8)
        axes.flat[k].set_xlabel("{} & {}".format(rmse_str,spread_str),fontsize=fontz*1.1)        
        axes.flat[k].set_ylabel("{}".format(levstr), fontsize=fontz*1.1)    
        # Set second y-axis label
        #ax2.set_xlabel("{}".format(rejection_str), fontsize=fontz*1.1)        
        #ax2.set_ylabel("{}".format(level_str), fontsize=fontz*1.1)   
        
        axes.flat[k].tick_params(top=False, right=False)
        #axes.flat[k].set_title('{}'.format(var),loc='left',fontsize=fontz*1.2,pad=20)
        #axes.flat[k].set_title('{}'.format(metrics_str),loc='right',fontsize=fontz*1.2,pad=20)
        axes.flat[k].set_title('{}'.format(var),loc='center',fontsize=fontz*1.2,pad=10)
        #axes.flat[k].text(1,1,metrics_str,fontsize=fontz*1.2, color='red', fontweight='bold', ha='center', va='center') #transform=plt.gcf().transFigure)
        #axes.flat[k].text(xpos_str,ypos_str,metrics_str,color='red',fontsize=fontz,fontweight='bold',ha='center',va='center',transform=axes.flat[k].transAxes)
        
        # Create a single legend for the figure
        axes.flat[k].legend(fontsize = fontz, loc='upper right') #fig.legend([line1, line2, line3], ['RMSE', 'Total Spread', 'Data Rejection'], loc='upper right')

        print(var_dict['lev_type'] )
        if var_dict['lev_type']  == 'pressure':
            axes.flat[k].invert_yaxis()
        
        ################################
        ax2 = axes.flat[k].twiny()             
        line3 = ax2.plot(rate, lev,
                         color = cmap['gray'],
                         marker="*",
                         markersize=mksize[1]*1.5,
                         linestyle = "-",
                         linewidth = lnthks[1],
                         label = "Data Rejection"
                        )
        
        # Usa geocat.viz.util convenience function to add minor and major tick lines
        gv.add_major_minor_ticks(ax2, x_minor_per_major=1, y_minor_per_major=1, labelsize=fontz)
        # Set axes limits, and tick values
        gv.set_axes_limits_and_ticks(ax2,
                                     xlim=(x2min,x2max),
                                     #ylim=(ymin,ymax),
                                     #yticks=np.arange(0, 101, 20)
                                    )
            
        # Set second y-axis label
        #ax2.set_xlabel("{}".format(rejection_str), fontsize=fontz*1.1)        
        #ax2.set_ylabel("{}".format(level_str), fontsize=fontz*1.1)        
        
        # Customize ticks and labels
        ax2.tick_params(labelsize=fontz*1.1, length=8)
        ax2.set_xlabel("{}".format(rejection_str),fontsize=fontz*1.1)        
        #ax2.set_ylabel("")      
        ax2.tick_params(bottom=False,left=False,right=False)
        
        # Create a single legend for the figure
        ax2.legend(fontsize = fontz, loc='lower right')

    #plt.tight_layout()
    plt.subplots_adjust(hspace=hs)
    plt.subplots_adjust(wspace=ws)
    plt.show()
    
    if not os.path.exists(fig_path):
        os.makedirs(fig_path)
    fname = os.path.join(fig_path,'fig_profil_obs_diag_{}.png'.format(var))
    fig.savefig(fname)
    
    return 

def draw_obs_diag_ts(var,var_dict,plevstr,data_dict,fig_path,fgw=20,fgh=12,hs=0.2,ws=0.2):
    
    ncols = len(data_dict.keys())
    nrows = len(plevstr)
    
    #create figure  
    frac = 12.0/35.0
    frac = fgh/fgw
    fontz = 12 * fgw*1.0/fgh * frac
    fig, axes = plt.subplots(nrows=nrows,
                             ncols=ncols, 
                             figsize=(fgw,fgh))
    
    cmap = {
        'blue':    '#377eb8', 
        'orange':  '#ff7f00',
        'green':   '#4daf4a',
        'pink':    '#f781bf',
        'brown':   '#a65628',
        'purple':  '#984ea3',
        'gray':    '#999999',
        'red':     '#e41a1c',
        'yellow':  '#dede00'
    } 
 
    lnthks = np.linspace(1, 10, len(plevstr))  
    colors = list(cmap.keys())[0:len(plevstr)]
    sizes = np.linspace(15, 25, len(plevstr)) / 3.5
    mksize = np.linspace(5,10,len(plevstr))
    
    y1min = var_dict['y1aix'][0]
    y1max = var_dict['y1aix'][1]
    y2min = var_dict['y2aix'][0]
    y2max = var_dict['y2aix'][1]
    
    tmp = []
    for exp in data_dict.keys():
        time = data_dict[exp]['time'][:]
        tmp.append(min(time)) 
        tmp.append(max(time)) 
    xmin = min(tmp)
    xmax = max(tmp)+1
    
    for i,lev in enumerate(plevstr):
        
        for j,exp in enumerate(data_dict.keys()):

            time = data_dict[exp]['time'][:]
            rmse = data_dict[exp]['rmse'][:,i]
            spread = data_dict[exp]['spread'][:,i]
            rate = data_dict[exp]['rejection'][:,i]
            rmse_str = data_dict[exp]['rmse_str']
            spread_str = data_dict[exp]['spread_str']
            rejection_str = data_dict[exp]['rejection_str']
            
            k = i*len(data_dict.keys()) + j 
            
            axes.flat[k].plot(time, rmse, 
                              color = cmap['red'],
                              marker="o",
                              markersize=mksize[1],
                              linestyle = "-",
                              label = "RMSE",
                              linewidth = lnthks[1])
        
            axes.flat[k].plot(time, spread, 
                              color = cmap['blue'],
                              marker="v",
                              markersize=mksize[1],
                              linestyle = "-",
                              label = "Total Spread",
                              linewidth = lnthks[1])

            # Set first y-axis label
            axes.flat[k].set_ylabel("{} & {}".format(rmse_str,spread_str),fontsize=fontz*1.1)        
        
            # Usa geocat.viz.util convenience function to add minor and major tick lines
            gv.add_major_minor_ticks(axes.flat[k], x_minor_per_major=1, y_minor_per_major=1, labelsize=fontz)

            # Usa geocat.viz.util convenience function to set axes parameters without calling several matplotlib functions
            # Set axes limits, and tick values
            gv.set_axes_limits_and_ticks(
                axes.flat[k],                         
                xlim=(xmin,xmax),
                ylim=(y1min,y1max)
                #yticks=np.arange(0, 17, 3)
                )

            # Customize ticks and labels
            axes.flat[k].tick_params(labelsize=fontz*1.1, length=8)
            #axes.flat[k].set_xlabel("{}".format(data_dict['time_unit']))     
            #axes.flat[k].set_ylabel("")      
            axes.flat[k].tick_params(top=False, right=False)

            #axes.flat[k].set_title('{}'.format(var),loc='left',fontsize=fontz*1.2,pad=20)
            #axes.flat[k].set_title('{}'.format(metrics_str),loc='right',fontsize=fontz*1.2,pad=20)
            axes.flat[k].set_title('{} ({})'.format(var,plevstr[i]),loc='center',fontsize=fontz*1.2,pad=10)
            #axes.flat[k].text(1,1,metrics_str,fontsize=fontz*1.2, color='red', fontweight='bold', ha='center', va='center') #transform=plt.gcf().transFigure)
            #axes.flat[k].text(xpos_str,ypos_str,metrics_str,color='red',fontsize=fontz,fontweight='bold',ha='center',va='center',transform=axes.flat[k].transAxes)
        
            # Create a single legend for the figure
            axes.flat[k].legend(fontsize = fontz, loc='upper left') #fig.legend([line1, line2, line3], ['RMSE', 'Total Spread', 'Data Rejection'], loc='upper right')

            ################################
            ax2 = axes.flat[k].twinx() 
            ax2.plot(time, rate,
                     color = cmap['gray'],
                     marker="*",
                     markersize=mksize[1],
                     linestyle = "-",
                     label = "Data Rejection",
                     linewidth = lnthks[1]
                    )
        
            # Usa geocat.viz.util convenience function to add minor and major tick lines
            gv.add_major_minor_ticks(ax2, x_minor_per_major=1, y_minor_per_major=1, labelsize=fontz)
            # Set axes limits, and tick values
            gv.set_axes_limits_and_ticks(ax2,
                                 ylim=(y2min,y2max),
                                 yticks=np.arange(0, 101, 20))
            
            # Set second y-axis label
            ax2.set_ylabel("{}".format(rejection_str), fontsize=fontz*1.1)        
        
            # Customize ticks and labels
            ax2.tick_params(labelsize=fontz*1.1, length=8)
            #ax2.set_xlabel("{}".format(data_dict['time_unit']))     
            #ax2.set_ylabel("")      
            ax2.tick_params(top=False, left=False)
            
            # Create a single legend for the figure
            ax2.legend(fontsize = fontz, loc='lower left')
        
    #plt.tight_layout()
    plt.subplots_adjust(hspace=hs)
    plt.subplots_adjust(wspace=ws)
    plt.show()
    
    if not os.path.exists(fig_path):
        os.makedirs(fig_path)
    fname = os.path.join(fig_path,'fig_2d_obs_diag_{}.png'.format(var))
    fig.savefig(fname)
    
    return 

def read_dart_obs_diag(regnam,var,dtype,var_dict,date,path,file):
    rpath = os.path.join(path,file)
    print('read file',rpath)
    #print(xxx)
    #dr = xc.open_dataset(rpath)
    dr = xc.open_mfdataset(rpath,decode_times=False)
    #print(dr)
    #print(xxx)
    #DART namelist for observation process
    #namelist         = np.array([char.decode('utf-8').strip() for char in dr['namelist'].values])

    # quantities to identify time and location     
    time = dr['time'].values
    time_bounds = dr['time_bounds'].values
    
    mlevel = dr['mlevel'].values 
    mlevel_edges = dr['mlevel_edges'].values
    
    plevel = dr['plevel'].values 
    plevel_edges = dr['plevel_edges'].values 
    
    hlevel = dr['hlevel'].values 
    hlevel_edges = dr['hlevel_edges'].values 
    
    rank_bins = dr['rank_bins'].values
    
    region = dr['region'].values 
    region_names = np.array([char.decode('utf-8').strip() for char in dr['region_names'].values]) #string 
    ind_reg = np.where(region_names == regnam)
    
    CopyMetaData     = np.array([char.decode('utf-8').strip() for char in dr['CopyMetaData'].values]) #string 
    copy             = dr['copy'].values #integer
    ind_vars         = np.where(CopyMetaData == var_dict['CopySpread'])
    ind_rmse         = np.where(CopyMetaData == var_dict['CopyRMSE'])
    ind_npos         = np.where(CopyMetaData == var_dict['CopyNposs'])
    ind_nuse         = np.where(CopyMetaData == var_dict['CopyNused'])

    #quantities to identify observation type 
    ObservationTypes = np.array([char.decode('utf-8').strip() for char in dr['ObservationTypes'].values])
    obstypes = dr['obstypes'].values
    
    print("info of variables: ") 
    print("ObservationTypes.shape= ",ObservationTypes.shape) 
    print("obstypes.shape= ",obstypes.shape) 
    print("CopyMetaData.shape= ",CopyMetaData.shape) 
    print("rank_bins.shape= ",rank_bins.shape) 
    print("time.shape= ",time.shape) 
    print("plevel.shape= ",plevel.shape) 
    print("mlevel.shape= ",mlevel.shape) 
    print("hlevel.shape= ",hlevel.shape) 
    print("region.shape= ",region.shape) 
    
    hrank = [] 
    if dtype == 'guess':
        varname = '{}_{}'.format(var_dict['name'],dtype)
        tsprd = dr[varname].values[:,ind_vars,:,ind_reg]
        trmse = dr[varname].values[:,ind_rmse,:,ind_reg]
        tnpos = dr[varname].values[:,ind_npos,:,ind_reg]
        tnuse = dr[varname].values[:,ind_nuse,:,ind_reg]
        sprd  = tsprd[0,0,:,:]
        rmse  = trmse[0,0,:,:]
        npos  = tnpos[0,0,:,:]
        nuse  = tnuse[0,0,:,:]  
    elif dtype == 'VPguess':
        varname = '{}_{}'.format(var_dict['name'],var_dict['type2'])
        vsprd = dr[varname].values[ind_vars,:,ind_reg]
        vrmse = dr[varname].values[ind_rmse,:,ind_reg]
        vnpos = dr[varname].values[ind_npos,:,ind_reg]
        vnuse = dr[varname].values[ind_nuse,:,ind_reg]
        sprd  = vsprd[0,0,:]
        rmse  = vrmse[0,0,:]
        npos  = vnpos[0,0,:]
        nuse  = vnuse[0,0,:]
    elif dtype == 'guess_RankHist':
        varname = '{}_{}'.format(var_dict['name'],var_dict['type3'])
        hrank = dr[varname].values[:,:,:,ind_reg]
        hrank = hrank[0,:,:,:]
    
    return time,plevel,plevel_edges,mlevel,mlevel_edges,hlevel,hlevel_edges,sprd,rmse,npos,nuse,hrank

if __name__ == "__main__":
    top_path = "/compyfs/zhan391/v3_dart_cda_scratch"
    out_path = os.path.join(top_path,"diagnostic","obs_diagnostics")
    fig_path = os.path.join(top_path,"diagnostic","obs_diagnostics","figures")

    #QCString = ['Data QC','DART quality control']
    #CopyString = ['observation' 'prior ensemble mean' 'prior ensemble spread','observation error variance']
    var_dict = {'RADIOSONDE_U': 
                     {'name'       : 'RADIOSONDE_U_WIND_COMPONENT',
                      'lev_type'   : 'pressure',
                      'CopySpread' : 'totalspread',
                      'CopyRMSE'   : 'rmse',
                      'CopyNposs'  : 'Nposs',
                      'CopyNused'  : 'Nused',
                      'type1'      : 'guess',
                      'type2'      : 'VPguess',  
                      'type3'      : 'guess_RankHist',
                      'y1aix'      : [0,10],
                      'y2aix'      : [0,100],
                     },
                'RADIOSONDE_V': 
                     {'name'       : 'RADIOSONDE_V_WIND_COMPONENT',
                      'lev_type'   : 'pressure',
                      'CopySpread' : 'totalspread',
                      'CopyRMSE'   : 'rmse',
                      'CopyNposs'  : 'Nposs',
                      'CopyNused'  : 'Nused',
                      'type1'      : 'guess',
                      'type2'      : 'VPguess',  
                      'type3'      : 'guess_RankHist',
                      'y1aix'      : [0,10],
                      'y2aix'      : [0,100],
                     },
                'RADIOSONDE_T': 
                     {'name'       : 'RADIOSONDE_TEMPERATURE',                      
                      'lev_type'   : 'pressure',
                      'CopySpread' : 'totalspread',
                      'CopyRMSE'   : 'rmse',
                      'CopyNposs'  : 'Nposs',
                      'CopyNused'  : 'Nused',
                      'type1'      : 'guess',
                      'type2'      : 'VPguess',  
                      'type3'      : 'guess_RankHist',
                      'y1aix'      : [0,5],
                      'y2aix'      : [0,100],
                     },
                'RADIOSONDE_Q': 
                     {'name'       : 'RADIOSONDE_SPECIFIC_HUMIDITY',
                      'lev_type'   : 'pressure',
                      'CopySpread' : 'totalspread',
                      'CopyRMSE'   : 'rmse',
                      'CopyNposs'  : 'Nposs',
                      'CopyNused'  : 'Nused',
                      'type1'      : 'guess',
                      'type2'      : 'VPguess',  
                      'type3'      : 'guess_RankHist',
                      'y1aix'      : [0,5],
                      'y2aix'      : [0,100],
                     },
                'SAT_U': 
                     {'name'       : 'SAT_U_WIND_COMPONENT',
                      'lev_type'   : 'pressure',
                      'CopySpread' : 'totalspread',
                      'CopyRMSE'   : 'rmse',
                      'CopyNposs'  : 'Nposs',
                      'CopyNused'  : 'Nused',
                      'type1'      : 'guess',
                      'type2'      : 'VPguess',  
                      'type3'      : 'guess_RankHist',
                      'y1aix'      : [0,10],
                      'y2aix'      : [0,100],
                     },
                'SAT_V': 
                     {'name'       : 'SAT_V_WIND_COMPONENT',
                      'lev_type'   : 'pressure',
                      'CopySpread' : 'totalspread',
                      'CopyRMSE'   : 'rmse',
                      'CopyNposs'  : 'Nposs',
                      'CopyNused'  : 'Nused',
                      'type1'      : 'guess',
                      'type2'      : 'VPguess',  
                      'type3'      : 'guess_RankHist',
                      'y1aix'      : [0,10],
                      'y2aix'      : [0,100],
                     },
    }
    
    obs_group = extract_obs_group() 
    exp_dict = extract_exp_info()

    case_name = 'PNWSNOW'
    resolution = "F20TR_ne30pg2_r05_IcoswISC30E3r5"
    machine = "compy"
    diag_key = "obs_diag_output"
    frequency = "6hourly"
    regnam = 'Northern Hemisphere' #'global'
    path_template  = "/compyfs/zhan391/v3_dart_cda_scratch/%(RUNNAME)/archive/%(CASENAME)/dart_diagnostics/%(DIAG)"
    file_template  = "%(RUNNAME)_%(RES)_%(MACH).dart.e.eam_%(KEY).%(TIME).nc"

    var = 'RADIOSONDE_T' #'RADIOSONDE_U','RADIOSONDE_V'
    dtype = "VPguess" #, 'guess_RankHist'    
    data_dict,levstr = read_metrics_data(var,var_dict,exp_dict,path_template,file_template)
    draw_obs_diag_prof(var,var_dict[var],data_dict,fig_path,fgw=24,fgh=10,hs=0.5,ws=0.5)

if __name__ == "__main__":
    top_path = "/compyfs/zhan391/v3_dart_cda_scratch"
    out_path = os.path.join(top_path,"diagnostic","obs_diagnostics")
    fig_path = os.path.join(top_path,"diagnostic","obs_diagnostics","figures")

    #QCString = ['Data QC','DART quality control']
    #CopyString = ['observation' 'prior ensemble mean' 'prior ensemble spread','observation error variance']
    var_dict = {'RADIOSONDE_U': 
                     {'name'       : 'RADIOSONDE_U_WIND_COMPONENT',
                      'lev_type'   : 'pressure',
                      'CopySpread' : 'totalspread',
                      'CopyRMSE'   : 'rmse',
                      'CopyNposs'  : 'Nposs',
                      'CopyNused'  : 'Nused',
                      'type1'      : 'guess',
                      'type2'      : 'VPguess',  
                      'type3'      : 'guess_RankHist',
                      'y1aix'      : [0,10],
                      'y2aix'      : [0,100],
                     },
                'RADIOSONDE_V': 
                     {'name'       : 'RADIOSONDE_V_WIND_COMPONENT',
                      'lev_type'   : 'pressure',
                      'CopySpread' : 'totalspread',
                      'CopyRMSE'   : 'rmse',
                      'CopyNposs'  : 'Nposs',
                      'CopyNused'  : 'Nused',
                      'type1'      : 'guess',
                      'type2'      : 'VPguess',  
                      'type3'      : 'guess_RankHist',
                      'y1aix'      : [0,10],
                      'y2aix'      : [0,100],
                     },
                'RADIOSONDE_T': 
                     {'name'       : 'RADIOSONDE_TEMPERATURE',                      
                      'lev_type'   : 'pressure',
                      'CopySpread' : 'totalspread',
                      'CopyRMSE'   : 'rmse',
                      'CopyNposs'  : 'Nposs',
                      'CopyNused'  : 'Nused',
                      'type1'      : 'guess',
                      'type2'      : 'VPguess',  
                      'type3'      : 'guess_RankHist',
                      'y1aix'      : [0,10],
                      'y2aix'      : [0,100],
                     },
                'RADIOSONDE_Q': 
                     {'name'       : 'RADIOSONDE_SPECIFIC_HUMIDITY',
                      'lev_type'   : 'pressure',
                      'CopySpread' : 'totalspread',
                      'CopyRMSE'   : 'rmse',
                      'CopyNposs'  : 'Nposs',
                      'CopyNused'  : 'Nused',
                      'type1'      : 'guess',
                      'type2'      : 'VPguess',  
                      'type3'      : 'guess_RankHist',
                      'y1aix'      : [0,10],
                      'y2aix'      : [0,100],
                     },
                'SAT_U': 
                     {'name'       : 'SAT_U_WIND_COMPONENT',
                      'lev_type'   : 'pressure',
                      'CopySpread' : 'totalspread',
                      'CopyRMSE'   : 'rmse',
                      'CopyNposs'  : 'Nposs',
                      'CopyNused'  : 'Nused',
                      'type1'      : 'guess',
                      'type2'      : 'VPguess',  
                      'type3'      : 'guess_RankHist',
                      'y1aix'      : [0,10],
                      'y2aix'      : [0,100],
                     },
                'SAT_V': 
                     {'name'       : 'SAT_V_WIND_COMPONENT',
                      'lev_type'   : 'pressure',
                      'CopySpread' : 'totalspread',
                      'CopyRMSE'   : 'rmse',
                      'CopyNposs'  : 'Nposs',
                      'CopyNused'  : 'Nused',
                      'type1'      : 'guess',
                      'type2'      : 'VPguess',  
                      'type3'      : 'guess_RankHist',
                      'y1aix'      : [0,10],
                      'y2aix'      : [0,100],
                     },
    }
    
    obs_group = extract_obs_group() 
    exp_dict = extract_exp_info()

    case_name = 'PNWSNOW'
    resolution = "F20TR_ne30pg2_r05_IcoswISC30E3r5"
    machine = "compy"
    diag_key = "obs_diag_output"
    frequency = "6hourly"
    regnam = 'Northern Hemisphere' #'global'
    path_template  = "/compyfs/zhan391/v3_dart_cda_scratch/%(RUNNAME)/archive/%(CASENAME)/dart_diagnostics/%(DIAG)"
    file_template  = "%(RUNNAME)_%(RES)_%(MACH).dart.e.eam_%(KEY).%(TIME).nc"

    var = 'RADIOSONDE_T' #'SAT_U' #'RADIOSONDE_U' #'RADIOSONDE_U','RADIOSONDE_V'
    dtype = "guess" # "VPguess", 'guess_RankHist'    
    data_dict,levstr = read_metrics_data(var,var_dict,exp_dict,path_template,file_template)
    print(data_dict.keys())
    draw_obs_diag_ts(var,var_dict[var],levstr,data_dict,fig_path,fgw=25,fgh=60,hs=0.5,ws=0.5)
        

