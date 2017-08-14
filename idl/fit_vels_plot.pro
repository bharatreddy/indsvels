pro fit_vels_plot

date = 20110409
time = 0840
sfjul, date, time, jul
;; plot mid lat radars only
rad_fan_ids = [209, 208, 33, 207, 206, 205, 204, 32]


losVelScale = [-800., 800.]
hemisphere = 1.
coords = "mlt"
xrangePlot = [-24, 30]
yrangePlot = [-44,10]
symsize = 0.35
load_usersym, /circle
rad_load_colortable,/website

plotNameDateStr = strtrim( string( date ),2 )
ps_open, '/home/bharatr/Docs/plots/' + 'saps-vels-' + plotNameDateStr+ '.ps'

	map_plot_panel,date=date,time=time,coords=coords,/no_fill,xrange=xrangePlot, $
        yrange=yrangePlot,pos=define_panel(1,1,0,0,/bar),/isotropic,grid_charsize='0.5',/north, $
        title = string(date) + "-" + strtrim( string(time), 2), charsize = 0.5


    rad_map_overlay_scan, rad_fan_ids, jul, scale=losVelScale, coords=coords, $
				param = "velocity", AJ_filter = 1, rad_sct_flg_val=2,/ vector_scan, set_grnd=50.

	rad_map_overlay_poes_bnd, date, time, coords= coords, fitline_thick=5., fitline_style=2

	latStart = 58.75
	latEnd = 59.25
	mltStart = -0.5
	mltEnd = 0.5
	delMlt = 0.5

	nElMlt = (mltEnd-mltStart)/delMlt + 1

	stereCrdsLow = fltarr( nElMlt, 2 )
	stereCrdsHigh = fltarr( nElMlt, 2 )

	for iMlt = 0, nElMlt-1 do begin
		currMlt = mltStart + iMlt*delMlt
		if currMlt lt 0. then currMlt += 24.
		stcLow = calc_stereo_coords( latStart, currMlt, /mlt )
		stcHigh = calc_stereo_coords( latEnd, currMlt, /mlt )
		stereCrdsLow[iMlt,0] = stcLow[0]
		stereCrdsLow[iMlt,1] = stcLow[1]
		stereCrdsHigh[iMlt,0] = stcHigh[0]
		stereCrdsHigh[iMlt,1] = stcHigh[1]

		

	endfor

	oplot, [ stereCrdsLow[*,0] ], [ stereCrdsLow[*,1] ], thick=5.
	oplot, [ stereCrdsHigh[*,0] ], [ stereCrdsHigh[*,1] ], thick=5.

	oplot, [ stereCrdsLow[0,0], stereCrdsHigh[0,0] ], [ stereCrdsLow[0,1], stereCrdsHigh[0,1] ], thick=5.
	oplot, [ stereCrdsLow[nElMlt-1,0], stereCrdsHigh[nElMlt-1,0] ], [ stereCrdsLow[nElMlt-1,1], stereCrdsHigh[nElMlt-1,1] ], thick=5.

	latStart = 59.25
	latEnd = 59.75
	mltStart = -0.5
	mltEnd = 2.5
	delMlt = 0.5

	nElMlt = (mltEnd-mltStart)/delMlt + 1

	stereCrdsLow = fltarr( nElMlt, 2 )
	stereCrdsHigh = fltarr( nElMlt, 2 )

	for iMlt = 0, nElMlt-1 do begin
		currMlt = mltStart + iMlt*delMlt
		if currMlt lt 0. then currMlt += 24.
		stcLow = calc_stereo_coords( latStart, currMlt, /mlt )
		stcHigh = calc_stereo_coords( latEnd, currMlt, /mlt )
		stereCrdsLow[iMlt,0] = stcLow[0]
		stereCrdsLow[iMlt,1] = stcLow[1]
		stereCrdsHigh[iMlt,0] = stcHigh[0]
		stereCrdsHigh[iMlt,1] = stcHigh[1]

		

	endfor

	oplot, [ stereCrdsLow[*,0] ], [ stereCrdsLow[*,1] ], thick=5.
	oplot, [ stereCrdsHigh[*,0] ], [ stereCrdsHigh[*,1] ], thick=5.

	oplot, [ stereCrdsLow[0,0], stereCrdsHigh[0,0] ], [ stereCrdsLow[0,1], stereCrdsHigh[0,1] ], thick=5.
	oplot, [ stereCrdsLow[nElMlt-1,0], stereCrdsHigh[nElMlt-1,0] ], [ stereCrdsLow[nElMlt-1,1], stereCrdsHigh[nElMlt-1,1] ], thick=5.



	stereo2 = calc_stereo_coords( 59.5, 1., /mlt )
	stereo1 =  calc_stereo_coords( 59., 0., /mlt )
	oplot,[ stereo1[0] ],[ stereo1[1] ], psym=7., symsize=0.5, thick=2.
	oplot,[ stereo2[0] ],[ stereo2[1] ], psym=7., symsize=0.5, thick=2.



	plot_colorbar, 1., 1.5, 0.4, 0.5, /square, scale=losVelScale, parameter='velocity',ground=50.

ps_close,/no_filename
end