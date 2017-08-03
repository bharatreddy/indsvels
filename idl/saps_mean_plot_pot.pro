pro saps_mean_plot_pot

common rad_data_blk

rad_load_colortable,/website


load_usersym, /circle

;; events selected
date = [ 20120618 ];
time = [ 0400 ];
;; set plot/map parameters
xrangePlot = [-44, 44]
yrangePlot = [-44,30]
velScale = [0,800]
potScale = [-40.,0.]
cntrMinVal = 5.
n_levels = 5
coords = "mlt"



fNameSP = "/home/bharatr/Docs/data/sapsPotentials.txt"

nel_arr_all = 10000
asyValArr = fltarr(nel_arr_all)
asyBinArr = strarr(nel_arr_all)
nrmMltArr = fltarr(nel_arr_all)
mlatArr = fltarr(nel_arr_all)
potsArr = fltarr(nel_arr_all)

nv=0
OPENR, 1, fNameSP
WHILE not eof(1) do begin
    READF,1, asy, currNrmMLT, currLat, currPot

    ;print, asy, currNrmMLT, currLat, currPot


    asyValArr[nv] = asy
    mlatArr[nv] = currLat
    potsArr[nv] = currPot
    nrmMltArr[nv] = currNrmMLT

    if ( asy eq 30) then $
        asyBinArr[nv] = '0 < Asy-H <= 30'
    if ( asy eq 60) then $
        asyBinArr[nv] = '30 < Asy-H <= 60'
    if ( asy eq 90) then $
        asyBinArr[nv] = '60 < Asy-H <= 90'
    if ( asy eq 180) then $
        asyBinArr[nv] = '90 < Asy-H <= 180'
    

    nv=nv+1   
ENDWHILE         
close,1



asyValArr = asyValArr[0:nv-1] 
mlatArr = mlatArr[0:nv-1] 
potsArr = potsArr[0:nv-1]
nrmMltArr = nrmMltArr[0:nv-1] 
asyBinArr = asyBinArr[0:nv-1] 


;; get the indices of data in different groups
jindsAsy30 = where( ( ( asyValArr eq 30. ) )  )
jindsAsy60 = where( ( ( asyValArr eq 60. ) )  )
jindsAsy90 = where( ( ( asyValArr eq 90. ) )  )
jindsAsy180 = where( ( ( asyValArr eq 180. ) )  )




ps_open,'/home/bharatr/Docs/plots/saps-pots.ps'

map_plot_panel,date=date,time=time,coords=coords,/no_fill,xrange=xrangePlot,yrange=yrangePlot,/no_coast,pos=define_panel(2,2,0,0,/bar),/isotropic,grid_charsize='0.5',/north, $
    title = '90 < Asy-H <= 180', charsize = 0.5

currLatSel = mlatArr[jindsAsy180]
currMLTSel = nrmMltArr[jindsAsy180]
currPotSel = potsArr[jindsAsy180]


for k = 0,n_elements(currLatSel) -1 do begin
    
    ;if ( currPotSel[k] lt .1 ) then continue

    currNM = currMLTSel[k]

    if ( currNM lt 0. ) then begin
            currMlt = currNM + 24.
    endif else begin
        currMlt = currNM
    endelse

    stereCr_low = calc_stereo_coords( currLatSel[k], currMlt, /mlt )

    colValCurr = get_color_index(currPotSel[k],scale=potScale,colorsteps=get_colorsteps(),ncolors=get_ncolors(), param='power')
    print, currLatSel[k], currNM, currPotSel[k]    
    oplot, [stereCr_low[0]], [stereCr_low[1]], color = colValCurr,thick = selSymThick, psym=8, SYMSIZE=selSymSize
    
endfor


map_plot_panel,date=date,time=time,coords=coords,/no_fill,xrange=xrangePlot,yrange=yrangePlot,/no_coast,pos=define_panel(2,2,1,0,/bar),/isotropic,grid_charsize='0.5',/north, $
    title = '60 < Asy-H <= 90', charsize = 0.5

currLatSel = mlatArr[jindsAsy90]
currMLTSel = nrmMltArr[jindsAsy90]
currPotSel = potsArr[jindsAsy90]


for k = 0,n_elements(currLatSel) -1 do begin
    
    ;if ( currPotSel[k] lt .1 ) then continue

    currNM = currMLTSel[k]

    if ( currNM lt 0. ) then begin
            currMlt = currNM + 24.
    endif else begin
        currMlt = currNM
    endelse

    stereCr_low = calc_stereo_coords( currLatSel[k], currMlt, /mlt )

    colValCurr = get_color_index(currPotSel[k],scale=potScale,colorsteps=get_colorsteps(),ncolors=get_ncolors(), param='power')
    print, currLatSel[k], currNM, currPotSel[k]    
    oplot, [stereCr_low[0]], [stereCr_low[1]], color = colValCurr,thick = selSymThick, psym=8, SYMSIZE=selSymSize
    
endfor


map_plot_panel,date=date,time=time,coords=coords,/no_fill,xrange=xrangePlot,yrange=yrangePlot,/no_coast,pos=define_panel(2,2,1,1,/bar),/isotropic,grid_charsize='0.5',/north, $
    title = '30 < Asy-H <= 60', charsize = 0.5

currLatSel = mlatArr[jindsAsy60]
currMLTSel = nrmMltArr[jindsAsy60]
currPotSel = potsArr[jindsAsy60]


for k = 0,n_elements(currLatSel) -1 do begin
    
    ;if ( currPotSel[k] lt .1 ) then continue

    currNM = currMLTSel[k]

    if ( currNM lt 0. ) then begin
            currMlt = currNM + 24.
    endif else begin
        currMlt = currNM
    endelse

    stereCr_low = calc_stereo_coords( currLatSel[k], currMlt, /mlt )

    colValCurr = get_color_index(currPotSel[k],scale=potScale,colorsteps=get_colorsteps(),ncolors=get_ncolors(), param='power')
    print, currLatSel[k], currNM, currPotSel[k]    
    oplot, [stereCr_low[0]], [stereCr_low[1]], color = colValCurr,thick = selSymThick, psym=8, SYMSIZE=selSymSize
    
endfor

map_plot_panel,date=date,time=time,coords=coords,/no_fill,xrange=xrangePlot,yrange=yrangePlot,/no_coast,pos=define_panel(2,2,0,1,/bar),/isotropic,grid_charsize='0.5',/north, $
    title = '0 < Asy-H <= 30', charsize = 0.5

currLatSel = mlatArr[jindsAsy30]
currMLTSel = nrmMltArr[jindsAsy30]
currPotSel = potsArr[jindsAsy30]


for k = 0,n_elements(currLatSel) -1 do begin
    
    ;if ( currPotSel[k] lt .1 ) then continue

    currNM = currMLTSel[k]

    if ( currNM lt 0. ) then begin
            currMlt = currNM + 24.
    endif else begin
        currMlt = currNM
    endelse

    stereCr_low = calc_stereo_coords( currLatSel[k], currMlt, /mlt )

    colValCurr = get_color_index(currPotSel[k],scale=potScale,colorsteps=get_colorsteps(),ncolors=get_ncolors(), param='power')
    print, currLatSel[k], currNM, currPotSel[k]    
    oplot, [stereCr_low[0]], [stereCr_low[1]], color = colValCurr,thick = selSymThick, psym=8, SYMSIZE=selSymSize
    
endfor

plot_colorbar, 1., 1., 0., 0.,scale=potScale,legend='SAPS Potentials', level_format='(f6.2)',param='power'

ps_close,/no_filename


end