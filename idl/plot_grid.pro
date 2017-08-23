pro plot_grid

date = 20110409;20130629
time = 0840
sfjul, date, time, jul
;; plot mid lat radars only
rad_fan_ids = [209, 208, 33, 207, 206, 205, 204, 32]


losVelScale = [-200., 200.]
hemisphere = 1.
coords = "mlt"
xrangePlot = [-25, 29]
yrangePlot = [-44,10]
symsize = 0.35
load_usersym, /circle
rad_load_colortable,/website

plotNameDateStr = strtrim( string( date ),2 )
ps_open, '/home/bharatr/Docs/plots/' + 'saps-vels-' + plotNameDateStr+ '-grid.ps'

	map_plot_panel,date=date,time=time,coords=coords,/no_fill,xrange=xrangePlot, $
        yrange=yrangePlot,pos=define_panel(1,1,0,0,/bar),/isotropic,grid_charsize='0.5',/north, $
        title = string(date) + "-" + strtrim( string(time), 2), charsize = 0.5


    rad_map_overlay_scan, rad_fan_ids, jul, scale=losVelScale, coords=coords, $
				param = "velocity", AJ_filter = 1, rad_sct_flg_val=2,/ vector_scan;, set_grnd=50.

	rad_map_overlay_poes_bnd, date, time, coords= coords, fitline_thick=5., fitline_style=2
	;rad_map_overlay_poes, date, time


	gridMlatArr = [ 57., 57.5, 58., 58.5, 59., 59.5, 60., 60.5, 61. ]
	gridMltArr = [ -2., -1., 0., 1., 2., 2.5, 3. ]

	for igMlat = 0, n_elements( gridMlatArr )-1 do begin
		for igMlt = 0, n_elements( gridMltArr )-1 do begin
			currGrdMlat = gridMlatArr[ igMlat ]
			currGrdMlt = gridMltArr[ igMlt ]
			latStart = currGrdMlat - 0.25
			latEnd = currGrdMlat + 0.25
			mltStart = currGrdMlt - 0.5
			mltEnd = currGrdMlt + 0.5
			delMlt = 0.5

			nElMlt = (mltEnd-mltStart)/delMlt + 1
			stereCrdsLow = fltarr( nElMlt, 2 )
			stereCrdsHigh = fltarr( nElMlt, 2 )

			for iMlt = 0, nElMlt-1 do begin
				currMlt = mltStart + iMlt*delMlt
				if currMlt lt 0. then currMlt += 24.
				print, currGrdMlat, currGrdMlt, latStart, latEnd, currMlt
				stcLow = calc_stereo_coords( latStart, currMlt, /mlt )
				stcHigh = calc_stereo_coords( latEnd, currMlt, /mlt )
				stereCrdsLow[iMlt,0] = stcLow[0]
				stereCrdsLow[iMlt,1] = stcLow[1]
				stereCrdsHigh[iMlt,0] = stcHigh[0]
				stereCrdsHigh[iMlt,1] = stcHigh[1]
			endfor

			oplot, [ stereCrdsLow[*,0] ], [ stereCrdsLow[*,1] ], thick=1.;, linestyle=2
			oplot, [ stereCrdsHigh[*,0] ], [ stereCrdsHigh[*,1] ], thick=1.;, linestyle=2

			oplot, [ stereCrdsLow[0,0], stereCrdsHigh[0,0] ], [ stereCrdsLow[0,1], stereCrdsHigh[0,1] ], thick=1.;, linestyle=2
			oplot, [ stereCrdsLow[nElMlt-1,0], stereCrdsHigh[nElMlt-1,0] ], [ stereCrdsLow[nElMlt-1,1], stereCrdsHigh[nElMlt-1,1] ], thick=1.;, linestyle=2

			if currGrdMlt lt 0. then begin
				actMltVal = currGrdMlt + 24.
			endif else begin
				actMltVal = currGrdMlt
			endelse

			stereo1 =  calc_stereo_coords( currGrdMlat, actMltVal, /mlt )
			oplot,[ stereo1[0] ],[ stereo1[1] ], psym=7., symsize=0.5, thick=2.

		endfor
	endfor

	
	plot_colorbar, 1., 1.5, 0.4, 0.5, /square, scale=losVelScale, parameter='velocity';,ground=50.

ps_close,/no_filename
end