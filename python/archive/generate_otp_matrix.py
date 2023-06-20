#!/usr/bin/jython
# inspired from https://github.com/rafapereirabr/otp-travel-time-matrix/blob/master/python_script.py
# and https://github.com/opentripplanner/OpenTripPlanner/blob/master/src/test/resources/scripts/test.py

# *note:* graph object file is quite large and only sits in local laptop, not online

from org.opentripplanner.scripting.api import OtpsEntryPoint

# Instantiate an OtpsEntryPoint
otp = OtpsEntryPoint.fromArgs(['--graphs', '.',
                               '--router', 'tynewear'])

# Start timing the code
import time
start_time = time.time()

# Get the default router
router = otp.getRouter()


# Create a default request for a given departure time
req = otp.createRequest()
req.setDateTime(2023, 1, 19, 8, 00, 00)  # set departure time https://github.com/opentripplanner/OpenTripPlanner/blob/63d4aa9f128bb7cbd987211e2f41b7c1f560ce21/src/main/java/org/opentripplanner/scripting/api/OtpsRoutingRequest.java#L37
req.setMaxTimeSec(7200)                   # set a limit to maximum travel time (seconds) 7200 sec = 2 hours
req.setModes('WALK,TRANSIT')             # define transport mode
req.setClampInitialWait(0)                # clamp the initial wait time to zero
# req.maxWalkDistance = 3000                 # set the maximum distance (in meters) the user is willing to walk
# req.walkSpeed = walkSpeed                 # set average walking speed ( meters ?)
# req.bikeSpeed = bikeSpeed                 # set average cycling speed (miles per hour ?)
# ?ERROR req.setSearchRadiusM(500)                 # set max snapping distance to connect trip origin to street network

# for more routing options, check: http://dev.opentripplanner.org/javadoc/0.19.0/org/opentripplanner/scripting/api/OtpsRoutingRequest.html


# Read Points of Destination - The file points.csv contains the columns GEOID, X and Y.
origs = otp.loadCSVPopulation('./graphs/tynewear/tynewear_lsoas_centroids.csv', 'Y', 'X')
dests = otp.loadCSVPopulation('./graphs/tynewear/tynewear_lsoas_centroids.csv', 'Y', 'X')


# Create a CSV output
matrixCsv = otp.createCSVOutput()
matrixCsv.setHeader([ 'origin', 'destination', 'walk_distance', 'travel_time', 'boardings' ])

# Start Loop
for origin in origs:
  print("Processing origin: ", origin)
  req.setOrigin(origin)
  spt = router.plan(req)
  if spt is None: continue

  # Evaluate the SPT for all points
  result = spt.eval(dests)
  
  # Add a new row of result in the CSV output
  for r in result:
    matrixCsv.addRow([ origin.getStringData('GEOID'), r.getIndividual().getStringData('GEOID'), r.getWalkDistance() , r.getTime(),  r.getBoardings() ])

# Save the result
matrixCsv.save('traveltime_matrix.csv')

# Stop timing the code
print("Elapsed time was %g seconds" % (time.time() - start_time))