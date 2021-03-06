pro saps_apr9_vel_data


common radarinfo
common rad_data_blk


;; create dates, times and necessary parameters
;; from input radIds
inpradIds = [33, 207, 206, 205, 204, 32]


nel_arr_all = 100
dateArr = lonarr(nel_arr_all)
radIdArr = fltarr(nel_arr_all)
minTimeArr = intarr(nel_arr_all)
maxTimeArr = intarr(nel_arr_all)


rcnt=0
for rc=0,n_elements(inpradIds)-1 do begin
	

	dateArr[rcnt] = 20110409
	radIdArr[rcnt] = inpradIds[rc]
	minTimeArr[rcnt] = 0600
	maxTimeArr[rcnt] = 1100

	rcnt += 1
endfor


dateArr = dateArr[0:rcnt-1]
radIdArr = radIdArr[0:rcnt-1]
minTimeArr = minTimeArr[0:rcnt-1]
maxTimeArr = maxTimeArr[0:rcnt-1]

coords = "magn"


fname_saps_vel = '/home/bharatr/Docs/data/new-test-vels-north.txt' 
openw,1,fname_saps_vel

for dtRdCnt=0.d,double(rcnt-1) do begin

	print, "working with---->", dateArr[dtRdCnt], radIdArr[dtRdCnt], minTimeArr[dtRdCnt], maxTimeArr[dtRdCnt]
	date = dateArr[dtRdCnt]
	timeRange = [ minTimeArr[dtRdCnt], maxTimeArr[dtRdCnt] ]
	radId = radIdArr[dtRdCnt]




	;; get the radar name from id
	radInd = where(network[*].id[0] eq radId, cc)
	if cc lt 1 then begin
		print, ' Radar not in SuperDARN list: '+radar
		rad_fit_set_data_index, data_index-1
		return
	endif
	radCode = network[radInd].code[0]

	print, "radId, radCode--> ", radId, " ", radCode


	rad_fit_read, date, radCode, time=timeRange, /filter


	sfjul,date,timeRange,sjul_search,fjul_search

	dt_skip_time=2.d ;;; we search data the grd file every 2 min
	del_jul=dt_skip_time/1440.d ;;; This is the time step used to read the data --> Selected to be 60 min

	nele_search=((fjul_search-sjul_search)/del_jul)+1 ;; Num of 2-min times to be searched..


	for srch=0.d,double(nele_search-1) do begin

	        ;;;Calculate the current jul
	        juls_curr=sjul_search+srch*del_jul
	    	sfjul,datesel,timesel,juls_curr,/jul_to_date
	    	print, "currently working with-->", datesel,timesel, radCode

	    	;; get index for current data
			data_index = rad_fit_get_data_index()
			if data_index eq -1 then begin
				print, "data index is -1!!!"
				return
			endif

			;; get year and yearsec from juls_curr
			caldat, juls_curr, mm, dd, year
			yrsec = (juls_curr-julday(1,1,year,0,0,0))*86400.d

			;; get scan info
			scan_number = rad_fit_find_scan(juls_curr)
			varr = rad_fit_get_scan(scan_number, scan_startjul=juls_curr)
			specWidArr = rad_fit_get_scan(scan_number, scan_startjul=juls_curr, param='width')
			pwrArr = rad_fit_get_scan(scan_number, scan_startjul=juls_curr, param='power')


			;; get mlat, mlon info from fovs
			scan_beams = WHERE((*rad_fit_data[data_index]).beam_scan EQ scan_number and $
						(*rad_fit_data[data_index]).channel eq (*rad_fit_info[data_index]).channels[0], $
						no_scan_beams)

			rad_define_beams, (*rad_fit_info[data_index]).id, (*rad_fit_info[data_index]).nbeams, $
					(*rad_fit_info[data_index]).ngates, year, yrsec, coords=coords, $
					lagfr0=(*rad_fit_data[data_index]).lagfr[scan_beams[0]], $
					smsep0=(*rad_fit_data[data_index]).smsep[scan_beams[0]], $
					fov_loc_full=fov_loc_full, fov_loc_center=fov_loc_center


			rad_define_beams, (*rad_fit_info[data_index]).id, (*rad_fit_info[data_index]).nbeams, $
					(*rad_fit_info[data_index]).ngates, year, yrsec, coords="geog", $
					lagfr0=(*rad_fit_data[data_index]).lagfr[scan_beams[0]], $
					smsep0=(*rad_fit_data[data_index]).smsep[scan_beams[0]], $
					fov_loc_full=geo_fov_loc_full, fov_loc_center=geo_fov_loc_center


			; we need to calculate azimuth in a different way
			;; taken from bearing calculation in http://www.movable-type.co.uk/scripts/latlong.html
			;; Formula:	θ = atan2( sin Δλ ⋅ cos φ2 , cos φ1 ⋅ sin φ2 − sin φ1 ⋅ cos φ2 ⋅ cos Δλ )
			;; where	φ1,λ1 is the start point, φ2,λ2 the end point (Δλ is the difference in longitude)

			radMLAT = (*rad_fit_info[data_index]).mlat*!dtor
			radMLON = (*rad_fit_info[data_index]).mlon*!dtor




			


			;; get the data
			sz = size(varr, /dim)
			radar_beams = sz[0]
			radar_gates = sz[1]


			; loop through and extract
			for b=0, radar_beams-1 do begin
				for r=0, radar_gates-1 do begin
					if varr[b,r] NE 10000 then begin
						currMLat = fov_loc_center[0,b,r]
						currMlon = fov_loc_center[1,b,r]
						currMLT = mlt(year, yrsec, fov_loc_center[1,b,r])
						currGLat = geo_fov_loc_center[0,b,r]
						currGlon = geo_fov_loc_center[1,b,r]

						;; azimuth calc
						slat = currMLat*!dtor
						slon = currMlon*!dtor
						dlon = radMLON - slon
						newAzimMagn = atan( sin(dlon)*cos(radMLAT), cos(slat)*sin(radMLAT) - sin(slat)*cos(radMLAT)*cos(dlon) )*!radeg
						newAzimMagn = ( ( newAzimMagn + 360. ) mod 360. ) - 180.

						;; we'll also need the beam azimuth
						currbeamAzim = rt_get_azim(radCode, b, datesel)
						printf,1, datesel,timesel, b, r, currbeamAzim, newAzimMagn, varr[b,r], specWidArr[b,r], pwrArr[b,r], currMLat, currMlon, currMLT, currGLat, currGlon, radId, radCode, $
	                                                                format = '(I8, I5, 2I4, 5f11.4, 5f11.4, I5, A5)'

					endif
				endfor
			endfor

	endfor	

endfor

close,1

end