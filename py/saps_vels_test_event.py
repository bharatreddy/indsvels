import saps_lshell_vel_map
import datetime
import pandas
import numpy
import geomag
import saps_vels_test_event
import feather

if __name__ == "__main__":
    inpPOESFile = "../data/processedSaps.txt"
    sapsDataDF = pandas.read_csv(inpPOESFile,\
                 sep=' ', dtype={'dateStr':'str', 'time': 'str'})
    sapsDataDF["date"] = pandas.to_datetime( \
                    sapsDataDF['dateStr'] + "-" +\
                    sapsDataDF['time'], format='%Y%m%d-%H%M')
    sapsObj = saps_vels_test_event.ProcessVels("../data/saps-vels-20150105.txt",\
        sapsDataDF)
    allTimeList = sapsObj.get_all_times()
    timeSel = allTimeList[47]#datetime.datetime( 2011, 4, 9, 8, 40 )
    # for iii, aaa in enumerate(allTimeList):
    #     print "timeSel-------->", iii, aaa
    velsDataDF = sapsObj.get_saps_scatter(timeSel)
    print velsDataDF["radCode"].unique()
    lmObj = saps_lshell_vel_map.LshellMap( velsDataDF, timeSel )
    # get locations info for getting good fits
    azimCharDF = lmObj.azim_chars()
    # get actual good fits
    goodFitDF = lmObj.get_good_fits(azimCharDF)
    # print goodFitDF
    # expand the fitting to cells with no fits
    fitResDF = lmObj.expand_fit_results(goodFitDF)
    fitResDF = fitResDF.round(2)
    feather.write_dataframe(fitResDF, '../data/vels-20150105.feather')
    # mlat, normMLT, velAzim, velMagn, gFit
    fitResDF.to_csv("../data/fit-res-20150105-420UT.txt", header=False,\
                                      index=False, sep=' ',\
                 columns = [ "mlat", "normMlt", "azimSAPS", "velSAPS" ] )
    print fitResDF


class ProcessVels(object):
    """
    A class to read in velocities from
    the csv files, process them and finally
    estimate the L-shell velocities.
    """
    def __init__(self, inpSAPSFile, sapsLocDF, cutOffLosVel=50., calcMagAzm=False):
        """
        read data from the input file to a DF
        format it for further use
        """
        self.poesNrstCutoff = 40
        # inpColNames = [ "dateStr", "timeStr", "beam", "range", "geoAzm",\
        #          "azimCalcMag", "vLos", "spwdth", "pwr", "MLAT", "MLON",\
        #           "MLT",  "GLAT", "GLON", "radId", "radCode"]

        inpColNames = [ "dateStr", "timeStr", "beam", "range",\
                 "azimCalcMag", "vLos", "MLAT", "MLON"\
           , "MLT", "GLAT", "GLON", "radId", "radCode" ]
        velsDataDF = pandas.read_csv(inpSAPSFile, delim_whitespace=True,\
                                     header=None, names=inpColNames)
        if "spwdth" not in velsDataDF.columns:
            # setup some dummy values
            velsDataDF["spwdth"] = 100.
        if "pwr" not in velsDataDF.columns:
            # setup some dummy values
            velsDataDF["pwr"] = 10.
        if "geoAzm" not in velsDataDF.columns:
            # setup some dummy values
            velsDataDF["geoAzm"] = 60.
        # add a datetime col
        velsDataDF["date"] = velsDataDF.apply( self.str_to_datetime, axis=1 )
                                # pandas.to_datetime( \
                                # velsDataDF['dateStr'].astype(str) + "-" +\
                                # velsDataDF['timeStr'].astype(str),\
                                #  format='%Y%m%d-%H%M')
        # for some reason MLAT is a str type, convert it to float
        velsDataDF["MLAT"] = velsDataDF["MLAT"].astype(float)
        # Also get a normMLT for plotting
        velsDataDF['normMLT'] = [x-24 if x >= 12 else x\
                         for x in velsDataDF['MLT']]
        # get magn azimuth from geo
        if calcMagAzm:
            print "calculating mag azims from geo...."
            velsDataDF["magAzm"] = velsDataDF.apply( \
                        self.convert_to_mag_azm, axis=1 )
        else:
            # Else store dummy value
            velsDataDF["magAzm"] = -999.
        # remove velocies whose magnitude is less than 200 m/s
        velsDataDF = velsDataDF[ abs(velsDataDF["vLos"]) >= cutOffLosVel ]
        self.velsDataDF = velsDataDF
        self.sapsLocDF = sapsLocDF

    def str_to_datetime(self, row):
        # Given a datestr and a time string convert to a python datetime obj.
        import datetime
        datecolName="dateStr"
        timeColName="timeStr"
        currDateStr = str( int( row[datecolName] ) )
    #     return currDateStr
        if row[timeColName] < 10:
            currTimeStr = "000" + str( int( row[timeColName] ) )
        elif row[timeColName] < 100:
            currTimeStr = "00" + str( int( row[timeColName] ) )
        elif row[timeColName] < 1000:
            currTimeStr = "0" + str( int( row[timeColName] ) )
        else:
            currTimeStr = str( int( row[timeColName] ) )
        return datetime.datetime.strptime( currDateStr\
                        + ":" + currTimeStr, "%Y%m%d:%H%M" )

    def get_saps_scatter(self, timeSel):
        """
        Given a time filter out saps scatter
        using POES boundary information. If no data
        is found during the given data, take in 
        all scatter during the day!
        """
        print "getting SAPS scatter...."
        velAnlysDF = self.velsDataDF[ self.velsDataDF["date"] == timeSel\
                     ].reset_index(drop=True)
        sapsSelPrdDF = self.sapsLocDF[  ( self.sapsLocDF["date"] -\
                     timeSel < numpy.timedelta64(self.poesNrstCutoff,'m') )\
                   & ( self.sapsLocDF["date"] - timeSel >\
                    numpy.timedelta64(0,'m') )  ].reset_index(drop=True)
        if sapsSelPrdDF.shape[0] > 0:
            poesBndDF = sapsSelPrdDF[ ["poesMLT", "poesLat"] \
                        ].drop_duplicates().reset_index(drop=True)
            poesBndDF['normMLT'] = [x-24 if x >= 12 \
                        else x for x in poesBndDF['poesMLT']]
            # Merge POES boundary DF with the vels DF
            velAnlysDF["normMLTRound"] = velAnlysDF["normMLT"].astype(int)
            velAnlysDF = pandas.merge( velAnlysDF, poesBndDF,\
                         left_on="normMLTRound", right_on="normMLT", how="inner" )
            # Filter out velocties above the POES boundary
            velAnlysDF = velAnlysDF[ velAnlysDF["MLAT"] < velAnlysDF["poesLat"]\
                                   ].reset_index(drop=True).drop_duplicates()
        else:
            # Merge POES boundary DF with the vels DF
            velAnlysDF["normMLTRound"] = velAnlysDF["normMLT"].astype(int)
        outSelCols = [ "beam", "range", "geoAzm", "azimCalcMag", "magAzm",\
                 "vLos" , "MLAT", "MLT", "MLON", "GLAT", "GLON", "radId" ,\
                  "radCode","normMLT", "normMLTRound", "spwdth", "pwr" ]
        velAnlysDF = velAnlysDF[outSelCols]
        return velAnlysDF

    def convert_to_mag_azm(self,row):
        """
        Given geo azim, GLAT and GLON
        get magnetic azimuth!
        """
        gm = geomag.geomag.GeoMag()
        mg = gm.GeoMag(row['GLAT'], \
                       row['GLON'], h=300., time=row['date'].date())
        azm_mag = (round(row['geoAzm'] - mg.dec,2))
        return azm_mag

    def get_all_times(self):
        """
        From the vels DF get a list of all unique times.
        """
        return self.velsDataDF["date"].unique()