import pandas
import datetime
import numpy
import scipy.optimize
import scipy.stats

class LshellMap(object):
    """
    A class with methods to estimate
    SAPS velocities at a given time.
    Given a map of L-o-S SuperDARN
    velocities (in a DF) we
    estimate SAPS velocities.
    """
    def __init__(self, sapsVelsDF):
        """
        Set up some constants.
        Used for fitting.
        """
        self.mincutOffLosVel = 50.
        self.maxcutOffLosVel = 2000.
        self.mincutOffspWdth = 100.
        self.maxcutOffspWdth = 500.
        self.cellAzmRngCutoff = 40.
        self.cellCntUniqAzimsCutoff = 5.
        self.minCutOffPwr = 3.
        self.cellSizenormMLT = 1.
        self.cellSizeMLAT = 0.5
        self.cutoffAzimStdErr = 100.
        self.cutoffVelStdErr = 25.
        self.cutoffKSPval = 0.1
        self.cutoffKSPAzimStd = 0.9
        self.cutoffKSDstatDMLT = 0.7
        self.cutOffPredWestDelTheta = 25.
        self.cutoffAzmStdLowVal = 5.
        self.minNumPntsCutoffCell = 5 # Somewhat arbitrary determination!!
        self.fitAzmType = "azimCalcMag"
        self.mltFitRange = 1.5
        self.initGuess = ( 1000., 10. )
        # Filter out some unwanted scatter from vel data
        self.sapsVelsDF = sapsVelsDF[ \
                        (abs(sapsVelsDF["vLos"]) >= self.mincutOffLosVel) &\
                       (sapsVelsDF["spwdth"] >= self.mincutOffspWdth)&\
                       (sapsVelsDF["pwr"] >= self.minCutOffPwr)&\
                       (abs(sapsVelsDF["vLos"]) <= self.maxcutOffLosVel)&\
                       (sapsVelsDF["spwdth"] <= self.maxcutOffspWdth)\
                       ].reset_index(drop=True)
        # SAPS(westward) vLos are positive for positive azimuths and vice versa.
        # filter the others out
        self.sapsVelsDF = self.sapsVelsDF[ \
            self.sapsVelsDF[self.fitAzmType]/self.sapsVelsDF["vLos"] > 0.\
            ].reset_index(drop=True)

    def azim_chars(self):
        """
        Get Azimuth characteristics of SAPS
        velocities. Basically find out which 
        cells are suitable for L-shell fitting.
        """
        minLat = round( self.sapsVelsDF["MLAT"].min() )
        maxLat = round( self.sapsVelsDF["MLAT"].max() )
        minnormMLT = round( self.sapsVelsDF["normMLT"].min() )
        maxnormMLT = round( self.sapsVelsDF["normMLT"].max() )
        # Keep lists for storing details later
        uniqAzimListMlat = []
        uniqAzimListMlt = []
        uniqAzimListdelMLT = []
        uniqAzimListAzimsUniq = []
        uniqAzimListAzimRange = []
        # loop through each cell and get an l-shell fit
        for la in numpy.arange( minLat, maxLat+1, self.cellSizeMLAT ):
            for ml in numpy.arange( minnormMLT, maxnormMLT+1, self.cellSizenormMLT ):
                dfSel = self.sapsVelsDF[ \
                    (self.sapsVelsDF["MLAT"] >= la - self.cellSizeMLAT/2.) &\
                     (self.sapsVelsDF["MLAT"] < la + self.cellSizeMLAT/2.) ]
                # Since we are working with large MLT ranges (for fitting)
                # It is appropriate to check if there actually are good enough
                # number of data points in the cell ( +/- 0.5 MLT range ). If yes
                # we proceed if not we skip the cell !!
                chkCntDF = dfSel[ abs( dfSel["normMLT"] -ml ) <= 0.5 ]
                if chkCntDF.shape[0] < self.minNumPntsCutoffCell:
                    continue
                # round off azimuths for ease of calc
                dfSel["rndAzim"] = dfSel[self.fitAzmType].round()
                # get MLTs to nearest half
                dfSel["normMLTRound"] = [ \
                        round(x * 2) / 2 for\
                        x in dfSel["normMLT"] ]
                mltAzmDF = dfSel.groupby(["normMLTRound"])\
                    ["rndAzim"].aggregate(\
                        lambda x: tuple(x)).reset_index()
                # get MLTs closest to the current one
                # we'll check the closest MLTs which are
                # 0, 0.5 and 1 MLT. We'll not go beyond 
                # +/- 1. hour in MLT (2 MLT hour range)
                # keep a list of unq azim values at diff
                # del MLT ranges
                fullUniqAzimList = []
                for delMLT in numpy.arange( 0., self.mltFitRange+0.5, 0.5 ): 
                    currAzimValsDF = mltAzmDF[ \
                        abs(mltAzmDF["normMLTRound"] - ml) <= delMLT ]
                    # Check if there are any values
                    if currAzimValsDF.shape[0] == 0:
                        continue
                    currUniqazimList = list( set( [ j for i in\
                                currAzimValsDF["rndAzim"].tolist()\
                                for j in i ] ) )
                    fullUniqAzimList = list( set( fullUniqAzimList +\
                     currUniqazimList ) )
                    uniqAzimListMlat.append( la )
                    uniqAzimListMlt.append( ml )
                    uniqAzimListdelMLT.append( delMLT )
                    uniqAzimListAzimsUniq.append( fullUniqAzimList )
                    uniqAzimListAzimRange.append( \
                            max(fullUniqAzimList) - min(fullUniqAzimList) )
                        
        # convert to a dataframe
        azimCharDF = pandas.DataFrame(
            {'MLAT': uniqAzimListMlat,
             'MLT': uniqAzimListMlt,
             'delMLT': uniqAzimListdelMLT,
             'uniqAzmiList': uniqAzimListAzimsUniq,
             'azimRng': uniqAzimListAzimRange
            })
        # In each row get a count of uniqAzims
        azimCharDF["countUniqAzims"] = [ len(x) for x\
         in azimCharDF["uniqAzmiList"] ]
        # Filter out certain unwanted values
        azimCharDF = azimCharDF[ (azimCharDF["azimRng"] >= self.cellAzmRngCutoff)\
                 & (azimCharDF["countUniqAzims"] >= self.cellCntUniqAzimsCutoff)\
                 ].reset_index(drop=True)
        # Return the DF
        return azimCharDF

    def vel_sine_func(self, theta, Vmax, delTheta):
        """
        sinusoid fitting function
        """
        # we are working in degrees but numpy deals with radians
        # convert to radians
        return Vmax * numpy.sin( numpy.deg2rad(theta) +\
                                numpy.deg2rad(delTheta) )

    def model_func(self, theta, Vmax, delTheta):
        """
        Get estaimted velocity from the fit
        """
        vLos = Vmax * numpy.sin( numpy.deg2rad(theta) +\
                                numpy.deg2rad(delTheta) )
        return vLos

    def get_good_fits(self, azimCharDF):
        """
        Find cells where we get good fitting results
        """
        # Arrays to store results
        cellMlatArr = []
        cellMLTArr = []
        cellVelFitArr = []
        cellAzimFitArr = []
        cellVelFitStdArr = []
        cellAzimFitStdArr = []
        cellFitMLTRangeArr = []
        cellGoodFitFndArr = []
        # get a list of the uniq MLATs and MLTs
        # start fitting values to them
        for cl, cm in azimCharDF.groupby( [ "MLAT", "MLT" ] ).groups.keys():
            subDF = azimCharDF[ (azimCharDF["MLAT"] == cl) &\
                              (azimCharDF["MLT"] == cm)]
            # Now for each mlat, mlt and delMLT combination
            # fit sine curves and test their goodness of fit
            goodVelStd = None
            goodAzmStd = None
            goodKSDstat = None
            goodKSPval = None
            goodVelFit = None
            goodAzimFit = None
            goodDMLT = None
            for indValDmlt, dMlt in enumerate(subDF["delMLT"].values):
                dfSel = self.sapsVelsDF[ \
                        (self.sapsVelsDF["MLAT"] >= cl - self.cellSizeMLAT/2.) &\
                         (self.sapsVelsDF["MLAT"] < cl + self.cellSizeMLAT/2.) &\
                                (self.sapsVelsDF["normMLT"] >= cm - dMlt) &\
                                 (self.sapsVelsDF["normMLT"] < cm + dMlt)\
                                 ].reset_index(drop=True)
                if dfSel.shape[0] < self.minNumPntsCutoffCell:
                    continue
                # Need both positive and negative azims for fitting
                # fits without those aren't very good!
                if ( ( dfSel[ dfSel[self.fitAzmType] > 0. ].shape[0] == 0) or\
                    ( dfSel[ dfSel[self.fitAzmType] < 0. ].shape[0] == 0) ):
                    continue
                popt, pcov = scipy.optimize.curve_fit(self.vel_sine_func, \
                            dfSel[self.fitAzmType].T,\
                            dfSel['vLos'].T,
                           p0=self.initGuess)
                # Kolmogorov-Smirnov Test for goodness of fit
                ksTestvLosFitArr = [ round( self.model_func(t, popt[0],popt[1]) )\
                                        for t in dfSel[self.fitAzmType].tolist() ]
                ksDStat, ksPVal = scipy.stats.ks_2samp( dfSel["vLos"].tolist(),\
                             ksTestvLosFitArr )
                
                # Now to store the best fit and discard others
                # To determine it we'll keep only those values
                # with less variance good KS TEST stats.
                percVelStd = abs( (pcov[0,0]**0.5)*100./popt[0] )
                percAzimStd = abs( (pcov[1,1]**0.5)*100./popt[1] )
                # sometimes there are bad fits, we need fits which are
                # predominantly westwards. Discard the rest
                if abs(popt[1]) > self.cutOffPredWestDelTheta:
                    continue
                if percVelStd > self.cutoffVelStdErr:
                    continue
                if percAzimStd > self.cutoffAzimStdErr:
                    # Sometimes there may be decent fits
                    # especially if delTheta is low (< 3-4)
                    # In that case we can check ksPVal, if it 
                    # is greater than say 0.9 we'll keep the fit
                    if ksPVal < self.cutoffKSPAzimStd:
                        continue
                    else:
                        if abs(pcov[1,1]**0.5) >= self.cutoffAzmStdLowVal:
                            continue
                if ksPVal < self.cutoffKSPval :
                    continue
                if goodVelStd is None:
                    # This is the first good fit
                    # lets use it for now
                    goodVelStd = pcov[0,0]**0.5
                    goodAzmStd = pcov[1,1]**0.5
                    goodKSDstat = ksDStat
                    goodKSPval = ksPVal
                    goodVelFit =  popt[0]
                    goodAzimFit =  popt[1]
                    goodDMLT = dMlt
                else:
                    # Now we need to choose one good fit
                    # from multiple values.
                    # Also we can't choose values with large
                    # dMlt span. We'll use ks test D statistic
                    # to determine this. If current ks Dstat is 
                    # better 30% less than prev best (self.cutoffKSDstatDMLT=0.7)
                    # use the new one.
                    if abs(ksDStat)/abs(goodKSDstat) < self.cutoffKSDstatDMLT:
                        goodVelStd = pcov[0,0]**0.5
                        goodAzmStd = pcov[1,1]**0.5
                        goodKSDstat = ksDStat
                        goodKSPval = ksPVal
                        goodVelFit =  popt[0]
                        goodAzimFit =  popt[1]
                        goodDMLT = dMlt
            # store results in arr
            if goodVelStd is not None:
                cellMlatArr.append( cl )           
                cellMLTArr.append( cm )
                cellVelFitArr.append( goodVelFit )
                cellAzimFitArr.append( goodAzimFit )
                cellVelFitStdArr.append( goodVelStd )
                cellAzimFitStdArr.append( goodAzmStd )
                cellFitMLTRangeArr.append( goodDMLT )
                cellGoodFitFndArr.append( True )
                        
        # convert to a dataframe
        fitResultsDF = pandas.DataFrame(
            {'mlat': cellMlatArr,
             'normMlt': cellMLTArr,
             'velSAPS': cellVelFitArr,
             'azimSAPS': cellAzimFitArr,
             'velSTD': cellVelFitStdArr,
             'azimSTD': cellAzimFitStdArr,
             'delMLT': cellFitMLTRangeArr,
             'goodFit': cellGoodFitFndArr
            })

        return fitResultsDF


    def expand_fit_results(self, fitResultsDF):
        """
        expand fit results from the good cells
        to cells with not so good fitting results.
        """
        # Now we have the good fits!
        # We'll have to find fits for cells
        # where we didn't find good fits.
        expFitDataTupleArr = []
        minLat = round( self.sapsVelsDF["MLAT"].min() )
        maxLat = round( self.sapsVelsDF["MLAT"].max() )
        minnormMLT = round( self.sapsVelsDF["normMLT"].min() )
        maxnormMLT = round( self.sapsVelsDF["normMLT"].max() )
        for la in numpy.arange( minLat, maxLat+1, self.cellSizeMLAT ):
            for ml in numpy.arange( minnormMLT, maxnormMLT+1, self.cellSizenormMLT ):
                dfSel = self.sapsVelsDF[\
                         (self.sapsVelsDF["MLAT"] >= la - self.cellSizeMLAT/2.) &\
                          (self.sapsVelsDF["MLAT"] < la + self.cellSizeMLAT/2.) &\
                           (self.sapsVelsDF["normMLT"] >= ml - self.cellSizenormMLT/2.) &\
                            (self.sapsVelsDF["normMLT"] < ml + self.cellSizenormMLT/2.)]
                if dfSel.shape[0] >= self.minNumPntsCutoffCell:
                    # get cells with no good fits
                    if fitResultsDF[ (fitResultsDF["normMlt"] == ml) &\
                                   (fitResultsDF["mlat"] == la)].shape[0] == 0.:
                        # Get the closest good fit
                        # We need closest good fit in MLT and then in MLAT.
                        delMLTsFits = sorted( [ abs(ml-x) for x in fitResultsDF["normMlt"] ] )
                        subMltFitDF = fitResultsDF[ \
                                abs(fitResultsDF["normMlt"]-ml) ==\
                                 min(delMLTsFits) ]
                        # Get the closest MLAT from the closest MLT
                        delMLATsFits = sorted( [ abs(la-x) \
                            for x in subMltFitDF["mlat"] ] )
                        subMlatFitDF = subMltFitDF[\
                         abs(subMltFitDF["mlat"]-la) == min(delMLATsFits) ]
                        # It is good if we have just one value
                        # But if we have more than 1 value we
                        # need to be cautious. We can either choose
                        # one of them or take a mean!                
                        sapsAzimGuess = subMlatFitDF["azimSAPS"].mean()
                        # WE'll choose max vLos
                        if ( numpy.abs( numpy.min(dfSel['vLos']) ) >=\
                             numpy.max( dfSel['vLos'] ) ):
                            currVlosMax = numpy.min(dfSel['vLos'])
                        else:
                            currVlosMax = numpy.max(dfSel['vLos'])
                        currVlosMaxAzim = dfSel[ dfSel['vLos'] == \
                            currVlosMax ][self.fitAzmType].tolist()[0]
                        currCellVLosAzimMaxVal = ( currVlosMax, currVlosMaxAzim )
                        estSapsVel = currCellVLosAzimMaxVal[0]/( numpy.cos(\
                                 numpy.deg2rad( 90.-sapsAzimGuess-\
                                    currCellVLosAzimMaxVal[1] ) ) )
                        expFitDataTupleArr.append( (sapsAzimGuess, None, None,\
                                     False, la, ml, estSapsVel, None) )

        # Store the results in a DF                
        expColList = ['azimSAPS', 'azimSTD', 'delMLT', 'goodFit',\
                      'mlat', 'normMlt', 'velSAPS', 'velSTD']                
        expFitResDF = pandas.DataFrame( expFitDataTupleArr, columns=expColList )
        # Add the endpoints too
        expFitResDF["endPtMLAT"] = numpy.round( (\
                    expFitResDF["velSAPS"]/1000.) * numpy.cos( \
                    numpy.deg2rad(-90-1*expFitResDF["azimSAPS"]) ) +\
                     expFitResDF["mlat"], 2)
        expFitResDF["endPtNormMLT"] = numpy.round( (\
                    expFitResDF["velSAPS"]/1000.) *\
                     numpy.sin( numpy.deg2rad(-90-1*expFitResDF["azimSAPS"]) )\
                      + expFitResDF["normMlt"], 2)
        # Merge the results from both DFs
        fitResultsDF = pandas.concat( [fitResultsDF, expFitResDF] )
        return fitResultsDF.reset_index(drop=True)