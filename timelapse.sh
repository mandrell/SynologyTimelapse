###############
# This program will be started by cron periodically and check if it should
# compile a timelapse video and upload it to the server.
###############

# Comment the following line to disable logging
# exec >> log.txt  # Does not work when run from Synology task schduler

echo "Starting timelapse script at $(date)"

#####
# Check if the script has already run for the date
# don't run if file is already created

day=$( date +%d )
foldername=/volume1/cam/windsock/$day
#foldername=/volume1/cam/windsock/$( date +%d )

if [[ -f  $foldername/windsockTL.mp4 ]] ; then
  echo "Video exists, script has already run.  Exiting"
  exit
fi


###############
# Determin sunrise/sunset times and evaluate if it's after the 
# timelpase end time sowe can build and send it to the server.
###############


# First obtain a location code from: https://weather.codes/search/
# Insert your location. For example LOXX0001 is a location code for Bratislava, Slovakia
location="USOR0163"
tmpfile=/tmp/$location.out

# Obtain sunrise and sunset raw data from weather.com
wget -q "https://weather.com/weather/today/l/$location" -O "$tmpfile"

# Locate sunrise and sunset times in the data retrived from weather.com
SUNR=$(grep SunriseSunset "$tmpfile" | grep -oE '((1[0-2]|0?[1-9]):([0-5][0-9]) ?([AaPp][Mm]))' | head -1)
SUNS=$(grep SunriseSunset "$tmpfile" | grep -oE '((1[0-2]|0?[1-9]):([0-5][0-9]) ?([AaPp][Mm]))' | tail -1)

sunrise=$(date --date="$SUNR" +%R)
sunset=$(date --date="$SUNS" +%R)

# Use $sunrise and $sunset variables to fit your needs. Example:
echo "The sunrise/sunset for location $location is $sunrise/$sunset"


# Need to caluclate offset times (in minutes, example 90)

# timeStart=$(date -d "$sunrise today - 60mins" +'%H:%M:%S')	# This was from the contractor, is wrong!
# timeStop=$(date -d "$sunset  today + 60mins" +'%H:%M:%S')		# This was from the contractor, is wrong!
timeStart=$(date -d "$sunrise today - 60mins" +'%R')
timeStop=$(date -d "$sunset  today + 60mins" +'%R')

# Append zeros for the seconds
timeStart="${timeStart}:00"
timeStop="${timeStop}:00"

#Strip out the : from the times
timeStart=$(echo $timeStart | tr --delete :)
timeStop=$(echo $timeStop | tr --delete :)




#echo "Timelapse will consist of images between $timeStart and $timeStop"

# Check if $timeStop has passed, if not abort.  If it has, compile timelaspe videos
current_time=$(date +"%T")
current_time=$(echo $current_time | tr --delete :)
echo "Current time : $current_time"
echo "TL stop time : $timeStop"


if [[ $current_time > $timeStop ]];then
  echo "Starting to build timelapse clips..."
else 
  echo "It's not yet $timeStop - Exiting..."
  exit
fi




#echo "Sunrise for location $location: $sunrise"
#echo "Sunset for location $location: $sunset"
echo "Timelapse will consist of images between $timeStart and $timeStop"

###############
# Setup the folder paths.
###############

# Getting current day of month
#day=$( date +%d )
# day=12	#Use this for testing
# echo "Day of month: " $day

# current day folder
folderWindsock=/volume1/cam/windsock/$day
folderRamp=/volume1/cam/ramp/$day
folderOffice=/volume1/cam/office/$day

###############
# This code will process the images for the Windsock camera.
###############

echo "Copying image files for windsock from $folderWindsock"

for filename in $folderWindsock/*.jpg; do
    temp_filename=$(basename "$filename")

    if [ ${temp_filename:8:-4} -gt $timeStart ] && [ ${temp_filename:8:-4} -lt $timeStop ]
    then
        echo "$filename"
        mkdir -p $folderWindsock/temp
        cp $filename $folderWindsock/temp/
    fi
done

echo "Starting ffmpeg for windsock timelapse"

ffmpeg -framerate 24 -r 24 -pattern_type glob -y -i $folderWindsock"/temp/*.jpg" -s:v 640x480 -c:v h264 -pix_fmt yuv420p $folderWindsock/windsockTL.mp4

echo "Removing temp folder"
rm -r $folderWindsock/temp/



###############
# This code will process the images for the Ramp camera.
###############

echo "Copying image files for ramp from $folderRamp"

for filename in $folderRamp/*.jpg; do
    temp_filename=$(basename "$filename")

    if [ ${temp_filename:8:-4} -gt $timeStart ] && [ ${temp_filename:8:-4} -lt $timeStop ]
    then
        echo "$filename"
        mkdir -p $folderRamp/temp
        cp $filename $folderRamp/temp/
    fi
done

echo "Starting ffmpeg for ramp timelapse"

ffmpeg -framerate 24 -r 24 -pattern_type glob -y -i $folderRamp"/temp/*.jpg" -s:v 640x480 -c:v h264 -pix_fmt yuv420p $folderRamp/rampTL.mp4

echo "Removing temp folder"
rm -r $folderRamp/temp/



###############
# This code will process the images for the Office camera.
###############

echo "Copying image files for office from $folderOffice"

for filename in $folderOffice/*.jpg; do
    temp_filename=$(basename "$filename")

    if [ ${temp_filename:8:-4} -gt $timeStart ] && [ ${temp_filename:8:-4} -lt $timeStop ]
    then
        echo "$filename"
        mkdir -p $folderOffice/temp
        cp $filename $folderOffice/temp/
    fi
done

echo "Starting ffmpeg for office timelapse"

ffmpeg -framerate 24 -r 24 -pattern_type glob -y -i $folderOffice"/temp/*.jpg" -s:v 640x480 -c:v h264 -pix_fmt yuv420p $folderOffice/officeTL.mp4

echo "Removing temp folder"
rm -r $folderOffice/temp/



###############
# Copy files to the local history with date stamp.
###############

echo "Copying files to local timelapse folder"
dateStamp=$( date +%Y%m%d)
cp "$folderWindsock"/windsockTL.mp4 /volume1/cam/timelapse/"$dateStamp"_windsockTL.mp4
cp "$folderRamp"/rampTL.mp4 /volume1/cam/timelapse/"$dateStamp"_rampTL.mp4
cp "$folderOffice"/officeTL.mp4 /volume1/cam/timelapse/"$dateStamp"_officeTL.mp4



###############
# Copy files to the web server.
###############

echo "Copying files to webserver"

# host='ftp.host.net'
# user='ftpuser@host.net'
# pass='P@$$word'
# path='timelapse'
# srcfile='file.txt'
# lftp -u $user,$pass $host <<EOF

lftp -u 'ftpuser@host.net','P@$$word' 'ftp.host.net' <<EOF
set ssl:verify-certificate no
#put $srcfile
# mkdir testdir
put $folderWindsock/windsockTL.mp4
put $folderRamp/rampTL.mp4
put $folderOffice/officeTL.mp4
bye
EOF



###############
# Clean up older files
###############

echo "Deleting image files from 27 days ago"

# Remove image data for 27 days ago
old_date=$(date -d "$date -27 days" +"%d")
rm -f -r /volume1/cam/windsock/$old_date
rm -f -r /volume1/cam/ramp/$old_date
rm -f -r /volume1/cam/office/$old_date
