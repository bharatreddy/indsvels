pro plot_scan, date=date, time=time, long=long, $
	param=param, scale=scale, channel=channel, scan_id=scan_id, $
	scan_startjul=scan_startjul, nscans=nscans, $
	coords=coords, xrange=xrange, yrange=yrange, autorange=autorange, $
	charthick=charthick, charsize=charsize, $
	scan_number=scan_number, vector=vector, $
	fixed_length=fixed_length, fixed_color=fixed_color, no_plot_gnd_scatter=no_plot_gnd_scatter, $
	freq_band=freq_band, silent=silent, no_fill=no_fill, no_title=no_title, no_fov=no_fov, $
	rotate=rotate, south=south, ground=ground, sc_values=sc_values, isotropic=isotropic

common rad_data_blk

; get index for current data
data_index = rad_fit_get_data_index()
if data_index eq -1 then begin
	if ~keyword_set(silent) then $
		prinfo, 'No data. '
	return
endif

if (*rad_fit_info[data_index]).nrecs eq 0L then begin
	if ~keyword_set(silent) then begin
		prinfo, 'No data in index '+string(data_index)
		rad_fit_info
	endif
	return
endif

if ~keyword_set(date) then begin
	if ~keyword_set(silent) then $
		prinfo, 'No DATE given, trying for scan date.'
	caldat, (*rad_fit_data[data_index]).juls[0], month, day, year
	date = year*10000L + month*100L + day
endif

if n_elements(time) eq 0 then $
	time = 1200
sfjul, date, time, sjul, fjul, long=long

if n_elements(time) eq 1 then begin
	if ~keyword_set(nscans) then $
		nscans=1
	scans = rad_fit_find_scan(sjul, channel=channel, scan_id=scan_id)
	scans += findgen(nscans)
endif else if n_elements(time) eq 2 then begin
	if keyword_set(nscans) then begin
		prinfo, 'When using TIME as 2-element vector, you must NOT provived NSCANS.'
		return
	endif
	scans = rad_fit_find_scan([sjul, fjul], channel=channel, scan_id=scan_id)
	nscans = n_elements(scans)
endif

if ~keyword_set(param) then $
	param = get_parameter()

if ~keyword_set(coords) then $
	coords = get_coordinates()

if keyword_set(autorange) then $
	rad_calculate_map_coords, ids=(*rad_fit_info[data_index]).id, coords=coords, $
		jul=(sjul+fjul)/2.d, nranges=(*rad_fit_info[data_index]).ngates, $
		xrange=xrange, yrange=yrange, rotate=rotate

if ~keyword_set(yrange) then $
	yrange = [-31,31]

if ~keyword_set(xrange) then $
	xrange = [-31,31]
aspect = float(xrange[1]-xrange[0])/float(yrange[1]-yrange[0])

; if scan_number is set, use that instead of the
; one just found by using date and time
if n_elements(scan_number) gt 0 then begin
	if scan_number ne -1 then begin
		scans = scan_number
		nscans = 1
	endif
endif
npanels = nscans

nparams = n_elements(param)
if nparams gt 1 then begin
	if nscans gt 1 then begin
		prinfo, 'If multiple params are set, nscans must be scalar.'
		return
	endif
	npanels = nparams
endif

; calculate number of panels per page
xmaps = floor(sqrt(npanels)) > 1
ymaps = ceil(npanels/float(xmaps)) > 1

; take into account format of page
; if landscape, make xmaps > ymaps
fmt = get_format(landscape=ls)
if ls then begin
	if ymaps gt xmaps then begin
		tt = xmaps
		xmaps = ymaps
		ymaps = tt
	endif
; if portrait, make ymaps > xmaps
endif else begin
	if xmaps gt ymaps then begin
		tt = ymaps
		ymaps = xmaps
		xmaps = tt
	endif
endelse

; for multiple parameter fan plots
; always stack horizontally them
if nparams gt 1 then begin
	xmaps = npanels
	ymaps = 1
endif



ascale = 0

if nparams eq 1 then $
	plot_colorbar, 1, 1, 0, 0, scale=scale, param=param, $
		panel_position=panel_position, ground=ground, sc_values=sc_values

; loop through panels
for s=0, npanels-1 do begin

	if nparams gt 1 then begin
		aparam = param[s]
		ascan = scans[0]
		if keyword_set(scale) then $
			ascale = scale[s*2:s*2+1] $
		else $
			ascale = get_default_range(aparam)
	endif else begin
		aparam = param[0]
		ascan = scans[s]
		if keyword_set(scale) then $
			ascale = scale
	endelse

	xmap = s mod xmaps
	ymap = s/xmaps

	ytitle = ' '
	if xmap eq 0 then $
		ytitle = ''

	xtitle = ' '
	if ymap eq ymaps-1 then $
		xtitle = ''

	panel_position = 0

	if nparams gt 1 then begin
		; Adjust panel/colorbar position for isotropic case
		if keyword_set(isotropic) then begin
			ppos = define_panel(xmaps, ymaps, xmap, ymap, /bar, aspect=aspect)
			bpos = [ppos[0], ppos[3]*1.03, ppos[2], ppos[3]*1.05]
		endif else bpos = 0
		; Plot colorbar
		plot_colorbar, xmaps, ymaps, xmap, ymap, param=aparam, scale=ascale, $
			panel_position=panel_position, /horizontal, ground=ground, position=bpos
	endif

	if keyword_set(sc_values) then $
		asc_values = sc_values $
	else $
		asc_values = 0
	
	; plot an fan panel for each scan/parameter
	rad_fit_plot_scan_panel, xmaps, ymaps, xmap, ymap, $
		date=date, time=time, long=long, coords=coords, $
		param=aparam, xrange=xrange, yrange=yrange, scale=ascale, $
		scan_number=ascan, channel=channel, scan_id=scan_id, $
		scan_startjul=scan_startjul, /no_fill, $
		freq_band=freq_band, silent=silent, $
		charthick=charthick, charsize=charsize, vector=vector, no_fov=no_fov, $
		fixed_length=fixed_length, fixed_color=fixed_color, $
		rotate=rotate, south=south, ground=ground, no_plot_gnd_scatter=no_plot_gnd_scatter, $
		position=panel_position, sc_values=asc_values, isotropic=isotropic

	if ~keyword_set(no_title) and $
		n_elements(scan_id) gt 0 and n_elements(scan_startjul) gt 0 then $
			rad_fit_plot_scan_title, xmaps, ymaps, xmap, ymap, $
				scan_id=scan_id, scan_startjul=scan_startjul, aspect=aspect, /bar

endfor

; rad_fit_plot_title, ' ', scan_id=scan_id, $
; 	date=date, time=time, param=param

if (*rad_fit_info[data_index]).fitex then $
	fitstr = 'fitEX'

if (*rad_fit_info[data_index]).fitacf then $
	fitstr = 'fitACF'

if (*rad_fit_info[data_index]).fit then $
	fitstr = 'fit'

titlestr = (*rad_fit_info[data_index]).name + $
	' ('+fitstr+')'

rad_fit_plot_title, ' ', titlestr, scan_id=scan_id, date=date, time=time

end