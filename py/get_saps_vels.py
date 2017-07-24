import saps_lshell_vel_map
import datetime
import pandas
import numpy
import geomag
import get_saps_vels

if __name__ == "__main__":
    inpPOESFile = "../data/processedSaps.txt"
    sapsDataDF = pandas.read_csv(inpPOESFile,\
                 sep=' ', dtype={'dateStr':'str', 'time': 'str'})
    sapsDataDF["date"] = pandas.to_datetime( \
                    sapsDataDF['dateStr'] + "-" +\
                    sapsDataDF['time'], format='%Y%m%d-%H%M')
    sapsObj = get_saps_vels.ProcessVels("../data/new-test-vels-north.txt",\
        sapsDataDF)
    allTimeList = sapsObj.get_all_times()
    print "allTimeList-------->", allTimeList
    timeSel = allTimeList[30]#datetime.datetime( 2011, 4, 9, 8, 40 )
    velsDataDF = sapsObj.get_saps_scatter(timeSel)
    lmObj = saps_lshell_vel_map.LshellMap( velsDataDF )
    # get locations info for getting good fits
    azimCharDF = lmObj.azim_chars()
    # get actual good fits
    goodFitDF = lmObj.get_good_fits(azimCharDF)
    # expand the fitting to cells with no fits
    fitResDF = lmObj.expand_fit_results(goodFitDF)
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
        inpColNames = [ "dateStr", "timeStr", "beam", "range", "geoAzm",\
                 "azimCalcMag", "vLos", "spwdth", "pwr", "MLAT", "MLON",\
                  "MLT",  "GLAT", "GLON", "radId", "radCode"]
        velsDataDF = pandas.read_csv(inpSAPSFile, delim_whitespace=True,\
                                     header=None, names=inpColNames)
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
        using POES boundary information.
        """
        print "getting SAPS scatter...."
        velAnlysDF = self.velsDataDF[ self.velsDataDF["date"] == timeSel\
                     ].reset_index(drop=True)
        sapsSelPrdDF = self.sapsLocDF[  ( self.sapsLocDF["date"] -\
                     timeSel < numpy.timedelta64(self.poesNrstCutoff,'m') )\
                   & ( self.sapsLocDF["date"] - timeSel >\
                    numpy.timedelta64(0,'m') )  ].reset_index(drop=True)
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
        # We only need a few cols
        velAnlysDF["normMLT"] = velAnlysDF["normMLT_x"]
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