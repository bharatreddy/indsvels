pro saps_mean_pots

common rad_data_blk

rad_load_colortable,/leicester

;; events selected
dateSel = [ 20120618 ];
timeSel = [ 0400 ];
;; set plot/map parameters
xrangePlot = [-44, 44]
yrangePlot = [-44,30]
velScale = [0,800]
potScale = [-50.,0.]
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

    print, asy, currNrmMLT, currLat, currPot


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




ps_open,'/home/bharatr/Docs/plots/saps-probs.ps'

map_plot_panel,date=date,time=time,coords=coords,/no_fill,xrange=xrangePlot,yrange=yrangePlot,/no_coast,pos=define_panel(2,2,0,0,/bar),/isotropic,grid_charsize='0.5',/north, $
    title = '0 < Asy-H <= 30', charsize = 0.5

currLatSel = latArr[jindsAsy30]
currMLTSel = nrmMltArr[jindsAsy30]
currPotSel = potsArr[jindsAsy30]

strLatArr = fltarr( n_elements(currLatSel), n_elements(currMLTSel) )
strMltArr = fltarr( n_elements(currLatSel), n_elements(currMLTSel) )
potsArr = fltarr( n_elements(currLatSel), n_elements(currMLTSel) )

for la = 0,n_elements(currLatSel) -1 do begin
    for ml = 0,n_elements(cntrMLTArr) -1 do begin
        lat = currLatSel[la]
        currNM = cntrMLTArr[ml]
        if ( currNM lt 0. ) then begin
            currMlt = currNM + 24.
        endif else begin
            currMlt = currNM
        endelse
        stereoCoords = calc_stereo_coords( lat, currMlt,/ mlt )

        strLatArr[la,ml] = stereoCoords[0]
        strMltArr[la,ml] = stereoCoords[1]
        currPotMltInds = where( (currMLTSel eq currNM) )

        if ( currPotMltInds[0] eq -1 ) then begin
            potsArr[ la, ml ] = 0.
        endif else begin

            currMLTSelMLT = currMLTSel[currPotMltInds]
            currLatSelMLT = currLatSel[currPotMltInds]
            currPotSelMLT = currPotSel[currPotMltInds]
            currPotMlatInds = where( ( currLatSelMLT eq lat ) )

            if ( currPotMlatInds[0] eq -1 ) then begin
                potsArr[ la, ml ] = 0.
            endif else begin

                currPotSelMLAT = currPotSelMLT[currPotMlatInds]
                potsArr[ la, ml ] = currPotSelMLAT
            endelse

    endfor
    
endfor


contour, potsArr, strLatArr, strMltArr, $
        /overplot, xstyle=4, ystyle=4, noclip=0, thick = 2., $
        levels=cntrMinVal+(potScale[1]-cntrMinVal)*findgen(n_levels+1.)/float(n_levels), /follow

ps_close


end