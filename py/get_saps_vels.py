if __name__ == "__main__":
    import saps_lshell_vel_map
    import datetime
    import pandas
    inpCols = [ "beam", "range", "geoAzm", "azimCalcMag", "magAzm", "vLos"\
               , "MLAT", "MLT", "MLON", "GLAT", "GLON", "radId"\
               , "radCode","normMLT", "normMLTRound", "spwdth", "pwr" ]
    velsDataDF = pandas.read_csv("../data/apr9-840-losVels.txt")
    velsDataDF.columns = inpCols
    lmObj = saps_lshell_vel_map.LshellMap( velsDataDF )
    # get locations info for getting good fits
    azimCharDF = lmObj.azim_chars()
    # get actual good fits
    goodFitDF = lmObj.get_good_fits(azimCharDF)
    # expand the fitting to cells with no fits
    fitResDF = lmObj.expand_fit_results(goodFitDF)
    print fitResDF