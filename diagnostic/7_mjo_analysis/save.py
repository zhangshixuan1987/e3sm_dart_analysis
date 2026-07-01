    def generate_hovmoller(self, exp_key, title=None, savepath=None,
                           filter_by_amplitude=False, amp_thresh=1.0,
                           overlay_phase=False,
                           shade_amplitude=False,
                           vmin=-5, vmax=5, nlevs=21,
                           xlabel='Longitude',
                           precip_ticks=None):

        segs = self.data_dict[exp_key]
        nens = max(segs[s].get('nens', 1) for s in segs)

        print(f"\n[INFO] Processing {exp_key} with {nens} ensemble member(s)...")

        if nens == 1:
            da = self._load_and_concatenate_segments(segs)
        else:
            ens_list = []
            for m in range(1, nens + 1):
                member_id = f'EN{m:02d}'
                da_ens = self._load_and_concatenate_segments(segs, ensemble=member_id)
                ens_list.append(da_ens.expand_dims(ensemble=[member_id]))
            da = xr.concat(ens_list, dim='ensemble').mean(dim='ensemble', skipna=True)

        if self.remove_clim:
            if len(da.time) > 270:
                # Remove daily climatology if long enough
                da_clim = self._remove_daily_climatology(da)
                da_filt = self._bandpass_filter(da_clim)
            else:
                # Remove mean over time (suitable for 90-day dataset)
                da_anom = da - da.mean(dim='time')
                da_filt = self._bandpass_filter(da_anom)
        else:
            da_filt = self._bandpass_filter(da)

        hov = self._compute_equatorial_mean(da_filt)
        hov['time'] = pd.to_datetime(hov.time.values).normalize()
        hov = hov.assign_coords(lon=((hov.lon + 360) % 360))
        hov = hov.sortby('lon')
        hov_plot = hov.transpose("time", "lon")

        rmm_aligned = None
        if filter_by_amplitude or overlay_phase or shade_amplitude:
            rmm_ds = self._load_rmm_index()
            rmm_df = rmm_ds.to_dataframe().dropna()
            rmm_df.index = rmm_df.index.normalize()
            rmm_df = rmm_df.loc[rmm_df.index.isin(hov.time.values)]
            rmm_df = rmm_df[rmm_df['amplitude'] > 1.0]
            rmm_df = rmm_df[~rmm_df.index.duplicated(keep='first')] 
            dups = rmm_df.index[rmm_df.index.duplicated()]
            print("Duplicate times in RMM index:", du)

        plt.figure(figsize=(9, 6))
        print(f"total time in hovmoller {len(hov['time'])}")
        cf = plt.contourf(
            hov_plot.lon.values,
            hov_plot.time.values,
            hov_plot.values,
            levels=np.linspace(vmin, vmax, nlevs),
            cmap='RdBu_r',
            vmin=vmin,
            vmax=vmax,
            extend='both'
        )

        if shade_amplitude and rmm_aligned is not None and 'amplitude' in rmm_aligned:
            amp = rmm_aligned['amplitude']
            amp_norm = amp / amp.max()
            plt.scatter(
                hov_plot.lon.values[-1] + 5,
                hov_plot.time.values,
                c=amp_norm,
                cmap='Greys',
                marker='s',
                s=20,
                label='RMM Amplitude'
            )

        for line_lon in [120, 150, 180]:
            plt.axvline(line_lon, color='gray', linestyle='--', linewidth=1.5)

        plt.title(title or f'MJO Precip Hovmöller: {exp_key}', fontsize=self.fontz)
        plt.xlabel(xlabel, fontsize=self.fontz)
        plt.ylabel('Time', fontsize=self.fontz)

        cbar = plt.colorbar(cf, orientation='vertical', pad=0.015, shrink=0.6)
        cbar.set_label("Filtered Precip (mm/day)", fontsize=self.fontz)
        cbar.set_ticks(np.linspace(vmin, vmax, 9))
        cbar.ax.tick_params(labelsize=self.fontz)

        plt.gca().yaxis.set_major_formatter(mdates.DateFormatter('%b-%d'))

        xticks = [0, 30, 60, 90, 120, 150, 180, 210, 240, 270, 300, 330, 360]
        xticklabels = ['0', '30E', '60E', '90E', '120E', '150E', '180',
                       '150W', '120W', '90W', '60W', '30W', '0']
        ax = plt.gca()
        ax.set_xticks(xticks)
        ax.set_xticklabels(xticklabels, fontsize=self.fontz)
        ax.tick_params(labelsize=self.fontz)
        ax.invert_yaxis()

        if overlay_phase and 'phase' in hov.coords:
            for phase in range(1, 9):
                mask = hov.phase.values == phase
                if np.any(mask):
                    y_vals = hov.time.values[mask]
                    x_vals = np.full_like(y_vals, hov.lon.values[0] - 10)
                    plt.scatter(x_vals, y_vals, label=f'Phase {phase}', s=10)
            plt.legend(title='RMM Phase', loc='upper left',
                       fontsize=self.fontz - 2, title_fontsize=self.fontz)

        plt.tight_layout()
        plt.show()

        if savepath:
            plt.savefig(savepath, dpi=600)
            print(f"[INFO] Saved to {savepath}")
            plt.close()

