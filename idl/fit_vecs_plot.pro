pro fit_vecs_plot


common radarinfo
common rad_data_blk

fNameSapsVels = "/home/bharatr/Docs/data/fit-res-20150409-7UT.txt"

date = 20150409
time = 0700

; some default settings
velScale = [0., 1200.]
losVelScale = [-1200., 1200.]
hemisphere = 1.
coords = "mlt"
xrangePlot = [-25, 29]
yrangePlot = [-44,10]
factor = 300.
fixed_length = -1
symsize = 0.5
load_usersym, /circle
rad_load_colortable,/leicester

nel_arr_all = 10000

dtStr = lonarr(1)
timeStr = intarr(1)

mltArr = fltarr(nel_arr_all)
latArr = fltarr(nel_arr_all)
velMagnArr = fltarr(nel_arr_all)
velAzimArr = fltarr(nel_arr_all)
gFitArr = fltarr(nel_arr_all)

rcnt=0
OPENR, 1, fNameSapsVels
WHILE not eof(1) do begin
	;; read the data line by line

	READF,1, mlat, normMLT, velAzim, velMagn
	
	gFit = 0

	if normMLT lt 0. then begin
		currMLT = normMLT + 24.
	endif else begin
		currMLT = normMLT
	endelse

	
	velMagnArr[rcnt] = velMagn
	velAzimArr[rcnt] = velAzim
	mltArr[rcnt] = currMLT
	latArr[rcnt] = mlat
	gFitArr[rcnt] = gFit
	rcnt += 1

ENDWHILE         
close,1	



velMagnArr = velMagnArr[0:rcnt-1]
velAzimArr = velAzimArr[0:rcnt-1]
mltArr = mltArr[0:rcnt-1]
latArr = latArr[0:rcnt-1]
gFitArr = gFitArr[0:rcnt-1]



if coords eq "mlt" then in_mlt=1

plotNameDateStr = strtrim( string( date ),2 )









;; plot mid lat radars only
rad_fan_ids = [209, 208, 33, 207, 206, 205, 204, 32]












ps_open, '/home/bharatr/Docs/plots/' + 'saps-vels-fit-' + plotNameDateStr+ '.ps'


sfjul, date, time, currSapsJul

currSapsVelMagns = velMagnArr
currSapsVelAzims = velAzimArr
currSapsMlats = latArr
currSapsMlts = mltArr

	map_plot_panel,date=date,time=time,coords=coords,/no_fill,xrange=xrangePlot, $
        yrange=yrangePlot,pos=define_panel(1,1,0,0,/bar),/isotropic,grid_charsize='0.5',/north, $
        title = string(date) + "-" + strtrim( string(time), 2), charsize = 0.5


;rad_map_overlay_scan, rad_fan_ids, currSapsJul, scale=losVelScale, coords=coords, $
;			param = "velocity", AJ_filter = 1, rad_sct_flg_val=2

for vcnt=0,n_elements(currSapsVelMagns)-1 do begin

	lat = currSapsMlats[vcnt]
	plon = currSapsMlts[vcnt]
	vel = currSapsVelMagns[vcnt]
	azim = -90.-1*currSapsVelAzims[vcnt]
	currGfit = gFitArr[vcnt]

	print, lat, plon, vel, azim
	
	lon = ( plon + 360. ) mod 360.

	tmp = calc_stereo_coords(lat, plon, hemisphere=1, mlt=(coords eq 'mlt') )
	x_pos_vec = tmp[0]
	y_pos_vec = tmp[1]

	vec_azm = azim*!dtor + ( hemisphere lt 0. ? !pi : 0. )
	vec_len = factor*vel/!re/1e3


	; Find latitude of end of vector
	coLat = (90. - abs(lat))*!dtor
	cos_coLat = (COS(vec_len)*COS(coLat) + $
		SIN(vec_len)*SIN(coLat)*COS(vec_azm) < 1.) > (-1.)
	vec_coLat = ACOS(cos_coLat)
	vec_lat = 90.-vec_coLat*!radeg 

	cos_dLon = ((COS(vec_len) - $
				COS(vec_coLat)*COS(coLat))/(SIN(vec_coLat)*SIN(coLat)) < 1.) > (-1.)
	delta_lon = ACOS(cos_dLon)
	IF vec_azm LT 0 THEN $
		delta_lon = -delta_lon
	vec_lon = (lon*( in_mlt ? 15. : 1. )*!dtor + delta_lon	)*!radeg

	tmp = calc_stereo_coords(vec_lat, vec_lon)
	new_x = tmp[0]
	new_y = tmp[1]


	vec_col = get_color_index(vel,scale=velScale,colorsteps=get_colorsteps(),ncolors=get_ncolors(), param='power')

	

	if currGfit gt 0. then begin
		oplot, [x_pos_vec,new_x], [y_pos_vec,new_y],$
				thick=2, COLOR=vec_col, noclip=0
		oplot, [x_pos_vec], [y_pos_vec], psym=8, $
			symsize=symsize, color=vec_col, noclip=0
	endif else begin
		oplot, [x_pos_vec,new_x], [y_pos_vec,new_y],$
				thick=2, COLOR=vec_col, noclip=0
		oplot, [x_pos_vec], [y_pos_vec], psym=2, $
			symsize=symsize, color=vec_col, noclip=0
	endelse

endfor

plot_colorbar, 1., 1.45, 0.65, 0.5, /square, scale=velScale, parameter='power', legend="Velocity [m/s]"


ps_close,/no_filename













end