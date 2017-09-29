pro plot_model_test

common dms_data_blk

coords = "mlt"
potScale = [ -35, -5 ]
cntrMinVal = -35.
n_levels = 6

date = 20150105
timeRange = [0500,0600];[ 1900, 2100 ]

sfjul, date, timeRange, sjul, fjul

satList = [ 16, 17, 18 ];[18];
colList = [ get_gray(), get_blue(), get_black() ]


xticks = 5;get_xticks(sjul, fjul, xminor=_xminor)
xrange = [50,60];[sjul, fjul]
yrange=[0,2000]
xtickformat = 'label_date'
xtickname = replicate(' ', 60)







fNameSapsVels = "/home/bharatr/Docs/data/sample-vel-pred.csv"

; some default settings
velScale = [0., 1200.]
losVelScale = [-800., 800.]
hemisphere = 1.
coords = "mlt"
xrangePlot = [-40, 34]
yrangePlot = [-44,30]
factor = 300.
fixed_length = -1
symsize = 0.35
load_usersym, /circle
rad_load_colortable,/website

currDate = 20150409;20150105;20130317;
currTime = 0700;0500;2000;

nel_arr_all = 10000

dtStr = lonarr(1)
timeStr = intarr(1)


mltArr = fltarr(nel_arr_all)
mlonArr = fltarr(nel_arr_all)
latArr = fltarr(nel_arr_all)
velMagnArr = fltarr(nel_arr_all)
velAzimArr = fltarr(nel_arr_all)
potArr = fltarr(nel_arr_all)
potFakeArr = fltarr(71,25)
dateArr = lonarr(nel_arr_all)
timeArr = intarr(nel_arr_all)
julArr = dblarr(nel_arr_all)

rcnt=0
OPENR, 1, fNameSapsVels
WHILE not eof(1) do begin
	;; read the data line by line

	READF,1, bfld, mlat, mlon, currMLT, efield, normMLT, pot, velMagn

	velAzim = -90.
	

	;; for some reason dates are not working well! 
	;; so doing a manual fix by adding 1. Check every time!!!
	sfjul,date,timeRange[0],currJul

	dateArr[rcnt] = date
	timeArr[rcnt] = timeRange[0]
	velMagnArr[rcnt] = velMagn
	velAzimArr[rcnt] = velAzim
	mltArr[rcnt] = currMLT
	latArr[rcnt] = mlat
	mlonArr[rcnt] = mlon
	julArr[rcnt] = currJul
	potArr[rcnt] = pot
	potFakeArr[mlat, currMLT] = pot

	rcnt += 1

ENDWHILE         
close,1	



dateArr = dateArr[0:rcnt-1]
timeArr = timeArr[0:rcnt-1]
velMagnArr = velMagnArr[0:rcnt-1]
velAzimArr = velAzimArr[0:rcnt-1]
;potArr = potArr[0:rcnt-1]
mltArr = mltArr[0:rcnt-1]
latArr = latArr[0:rcnt-1]
mlonArr = latArr[0:rcnt-1]
julArr = julArr[0:rcnt-1]


;; we'll plot potentials as contours
strLatCntrArr = fltarr(22, 25)
strMltCntrArr = fltarr(22, 25)
mltCntrArr = fltarr(22, 25)
potCntrArr = fltarr(22, 25)
countLat = 0.

for lat = 50., 70. do begin
    countLat += 1.
    countLon = 0.
    for currMlt = 0., 24. do begin
        ;caldat,sjul, evnt_month, evnt_day, evnt_year, strt_hour, strt_min, strt_sec
        ;currMlt = mlt( date, timeymdhmstoyrsec( evnt_year, evnt_month, evnt_day, strt_hour, strt_min, strt_sec ), currMlon )
        ;print, currMlt, countLon
        mltCntrArr[countLat,countLon] = currMlt
        stereoCoords = calc_stereo_coords( lat, currMlt,/ mlt )
        strLatCntrArr[countLat,countLon] = stereoCoords[0]
        strMltCntrArr[countLat,countLon] = stereoCoords[1]
        print, lat, currMlt, potFakeArr[lat, currMlt]
        potCntrArr[countLat,countLon] = potFakeArr[lat, currMlt]
        countLon += 1


    endfor
endfor

;rad_load_colortable, /whitered
loadct,8

ps_open, '/home/bharatr/Docs/plots/model-pots.ps'


map_plot_panel,date=date,time=timeRange[0],coords=coords,/no_fill,xrange=xrangePlot, $
        yrange=yrangePlot,pos=define_panel(1,1,0,0,/bar),/isotropic,grid_charsize='0.5',/north, $
        title = string(date) + "-" + strtrim( string(timeRange[0]), 2), charsize = 0.5


contour, potCntrArr, strLatCntrArr, strMltCntrArr, $
       /overplot, xstyle=4, ystyle=4, noclip=0, thick = 2., $
        levels=cntrMinVal+(potScale[1]-cntrMinVal)*findgen(n_levels+1.)/float(n_levels), /follow;,/fill

contour, potCntrArr, strLatCntrArr, strMltCntrArr, $
/overplot, xstyle=4, ystyle=4, noclip=0, thick = 2., $
levels=cntrMinVal+(potScale[1]-cntrMinVal)*findgen(n_levels+1.)/float(n_levels), /follow



rad_load_colortable, /website
;; overlay dmsp
;dmsp_ssj_fit_eqbnd, date, timeSel[0], coords = coords  

loadct,8
plot_colorbar, 1., 1., 0., 0.,scale=potScale,legend='Potential [kV]', param='power'

ps_close, /no_filename


end