pro rad_plot_spw_vel, date, time


rad_fan_ids = [ 208,209,206,207,204,205,33,32,40 ]
rad_codes = [ "adw", "ade", "cvw", "cve", "fhw", "fhe", "bks", "wal", "hok" ]
rad_sct_flg_val=2

velScale = [ -500, 500 ]
widScale = [ 0, 300 ]

ps_open, '/home/bharatr/Docs/plots/vel-swd-' + strtrim( string(date), 2) + strtrim( string(time), 2) + '.ps'


pos_vel_panel=define_panel(2,1,0,0, aspect=aspect,/bar)
pos_swd_panel=define_panel(2,1,1,0, aspect=aspect,/bar)


;rad_all_data_plot, date, time=time, /plot_scan_fov_data, rad_fan_ids = rad_fan_ids, position=pos_vel_panel, /poes_eq_ovalbnd_overlay, /AJ_filter, param_fit_plot = "velocity", scale=velScale, rad_sct_flg_val=rad_sct_flg_val,/vector_scan

for i = 0, n_elements(rad_codes)-1 do begin
	rad_fit_read, date, rad_codes[i], filter = 1
	rad_set_scatterflag,rad_sct_flg_val
	plot_scan, date=date, time=time, param=["width"], coords="mlt", xrange = [-45,45], yrange = [-45,45], scale=[ 0, 200 ],ground=rad_sct_flg_val,/no_fov
	;plot_colorbar, 2.1, 1., 0., 0., /square, scale=velScale, parameter='velocity',/horizontal


	;rad_all_data_plot, date, time=time, /plot_scan_fov_data, rad_fan_ids = rad_fan_ids, position=pos_swd_panel, /poes_eq_ovalbnd_overlay, /AJ_filter, param_fit_plot = "width", scale=widScale, rad_sct_flg_val=rad_sct_flg_val,/vector_scan

	;plot_colorbar, 2.1, 1., 1.0, 0., /square, scale=widScale, parameter='width',/horizontal
endfor 


ps_close,/no_filename

end