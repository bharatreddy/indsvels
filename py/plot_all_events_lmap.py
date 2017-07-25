import saps_lshell_vel_map
import pandas
import get_saps_vels
import os

if __name__ == "__main__":
     # Base directory where all the files are stored
    baseDir = "/home/bharat/Documents/code/new-vel-data/veldata/"
    # POES Boundary data
    inpPOESFile = "../data/processedSaps.txt"
    # create a DF with the data
    sapsDataDF = pandas.read_csv(inpPOESFile,\
                 sep=' ', dtype={'dateStr':'str', 'time': 'str'})
    sapsDataDF["date"] = pandas.to_datetime( \
                    sapsDataDF['dateStr'] + "-" +\
                    sapsDataDF['time'], format='%Y%m%d-%H%M')
    failedDTObjs = []
    # read data from a file
    for root, dirs, files in os.walk(baseDir):
        for fNum, fName in enumerate(files):
            currInpLosFile = root + fName    
            print "working with--->", currInpLosFile, fNum,"/",len(files)
            # READ data
            sapsObj = get_saps_vels.ProcessVels(currInpLosFile, sapsDataDF)
            allTimeList = sapsObj.get_all_times()
            for timeSel in allTimeList:
                print "current time--->", timeSel, fNum,"/",len(files)
                velsDataDF = sapsObj.get_saps_scatter(timeSel)
                lmObj = saps_lshell_vel_map.LshellMap( velsDataDF, timeSel )
                # get locations info for getting good fits
                azimCharDF = lmObj.azim_chars()
                # If no good fit is found discard and store the 
                # datetimes in a list for reference!
                if azimCharDF.shape[0] == 0:
                    failedDTObjs.append(timeSel)
                    print "no good azims found--->", timeSel
                    continue
                # get actual good fits
                goodFitDF = lmObj.get_good_fits(azimCharDF)
                # If no good fits are found! exit
                if goodFitDF.shape[0] == 0:
                    print "no good fits found--->", timeSel
                    continue
                # expand the fitting to cells with no fits
                fitResDF = lmObj.expand_fit_results(goodFitDF)
                # Set up a few conditions to filter out some data
                # 1) If the number of fits is less than 5 skip
                if fitResDF.shape[0] < 5:
                    continue
                # 2) number of good fits should be greater than bad one's
                if (fitResDF[ fitResDF["goodFit"] \
                        ].shape[0]*1./fitResDF.shape[0]) <= 0.5:
                    continue
                # 3) Number of unique MLTs in the fits should be greater
                # than or equal to 3 (for example, 0, 1, 2)
                if len( fitResDF["normMlt"].unique().tolist() ) < 3.:
                    continue
                # plot the results
                print "Plot the data!"
                lmObj.plot_lshell_map(fitResDF)
    # NOTE DATES which failed
    print "Failed dates---->"
    print failedDTObjs
    print "total--->", len(failedDTObjs)