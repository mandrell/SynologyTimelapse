# SynologyTimelapse
This project aims to take images that are saved from several webcams throughout the day and automatically build a timelapse at the end of the day.  This project does not cover collecting the images from the cameras, simply building the timelapse based on image files that have been saved to the NAS (in our case, we use FTP).

**Features**
- Set location for automatic determination of sunrise/sunset time
- Set start/stop offsets from sunrise and sunset
- Detect when the timelapse period has completed and build timelapse from saved images
- Upload completed timelapse to web server via SFTP
- Rotate saved images to free up space
- Locally save copies of timelapse for each day

## See it in action
You can see the system at Lenhardt Airpark (7S9) in action on this page: <br>
[Lenhardt Webcams](https://airhaven.net/webcams/) <br>

[Click here for the latest video](https://airhaven.net/webcamsupload/rampTL.mp4)

## System Details

This is running on a used Synology DS220j.

The cameras each FTP a JPEG image every 15 seconds to a folder: CameraName/DateNum/image.jpg

A schdeuled task starts just before the earliest sunset of the year, and then runs every 15 minutes until midnight.  When the script runs, it first checks to see if it's already completed the timelapses for the day, and if so just aborts.

It will then check weather.com for the sunrise and sunset times and the current time to see if it's past the timelapse end time.  If it's not yet past the end time, it will abort.

If the current time is past the end of the timelapse, it will then start processing each of the cameras.  For each camera it will copy the images with timestamps (in the filename) that are within the timelapse timeframe to a temp folder.  It will then use ffmepg to build the timelapse video.  The temp folder is then deleted.

Once each timelapse video is created, the script will copy the videos to the timelapse directory for retention (it does not delete these).  It will then copy the video files to a web server.

Upon completion the script will delete the camera folders for 27 days ago.

### File Structure
- cam
  - CameraName1
    - 01
    - 02
    - 03
    - ..
  - CameraName2
    - 01
    - 02
    - 03
    - ..

## Synology NAS Setup

### 1. Setup the NAS filesystem
Create Storage Pool 'Pool1'
Create Volume 'Volume1'
Create Share 'cam'

Inside 'cam' there will be a file for each camera.  In our case that is:
- office
- ramp
- windsock

We then need to add two folders, 'script' and 'timelapse' for the shell script to go and timelapse videos to be saved.
- script
- timelapse

![Screenshot of Filestation](https://user-images.githubusercontent.com/10911727/171042623-c91fc814-54fb-4cfc-b87e-94bdd0790e3c.png)

### 2. Setp the FTP user for the cameras
Add a user for the camera that is only allowed to access FTP.  This is the user account that is used by the cameras to transfer image files to the NAS.

### 3. Setup the task scheduler 
Setup the task using Control Panel -> Task Scheduler

![image](https://user-images.githubusercontent.com/10911727/171043731-33c285b2-48cd-4046-8261-350973d838b9.png)

![image](https://user-images.githubusercontent.com/10911727/171043694-bc289ba3-62f6-42cc-ad17-c4d60a52b936.png)

![image](https://user-images.githubusercontent.com/10911727/171043706-676037e3-d5d0-460d-ba93-33d6e5698ae2.png)
