#!/bin/sh

#****************************************************************************** 
#****************************************************************************** 
#
#            Plex DVR Post Processing w/Handbrake (H.264) Script
#
#****************************************************************************** 
#****************************************************************************** 
#  
#  Version: 1.0
#
#  Pre-requisites: 
#     HandBrakeCLI
#
#
#  Usage: 
#     'PlexPostProc.sh %1'
#
#  Description:
#      My script is currently pretty simple.  Here's the general flow:
#
#      1. Creates a temporary directory in the home directory for 
#      the show it is about to transcode.
#
#      2. Uses Handbrake (could be modified to use ffmpeg or other transcoder, 
#      but I chose this out of simplicity) to transcode the original, very 
#      large MPEG2 format file to a smaller, more manageable H.264 mp4 file 
#      (which can be streamed to my Roku boxes).
#
#	   3. Copies the file back to the original filename for final processing
#
#****************************************************************************** 

#****************************************************************************** 
#  Do not edit below this line
#****************************************************************************** 

fatal() {
   echo "[FATAL] $1.";
   echo "[FATAL] Program is now exiting.";
   exit 1;
}
# The above is a simple function for handling fatal erros. (It outputs an error, and exits the program.)

if [ ! -z "$1" ]; then 
# The if selection statement proceeds to the script if $1 is not empty.
   if [ ! -f "$1" ]; then 
      fatal "$1 does not exist"
   fi
   # The above if selection statement checks if the file exists before proceeding. 
   
   FILENAME=$1 	# %FILE% - Filename of original file
   TEMPFILENAME="$(mktemp)"  # Temporary File for transcoding
   NEWFILENAME="${FILENAME%.ts}.mkv"   
   LOCKFILENAME="/tmp/PlexPostProcLock"
   HANDBRAKECLI="/usr/bin/HandBrakeCLI"

   # Uncomment if you want to adjust the bandwidth for this thread
   #MYPID=$$	# Process ID for current script
   # Adjust niceness of CPU priority for the current process
   #renice 19 $MYPID
   
   # Ensures no more than 1 convert process running at a time.
   # Keeps CPU happy.
   while [ -f "$LOCKFILENAME" ]; do sleep 10; done;
   touch "$LOCKFILENAME"

   echo "********************************************************"
   echo "Transcoding, Converting to H.264 w/Handbrake"
   echo "********************************************************"
   #"$HANDBRAKECLI" -i "$FILENAME" -f mkv --aencoder copy -e qsv_h264 --x264-preset veryfast --x264-profile auto -q 16 --maxHeight 720 --decomb bob -o "$TEMPFILENAME" || fatal "Handbreak has failed (Is it installed?)"
   "$HANDBRAKECLI" -i "$FILENAME" -o "$TEMPFILENAME" --format mkv --encoder x264 --quality 20 --loose-anamorphic --decomb veryfast --x264-preset fast --h264-profile high --h264-level 4.1  || fatal "Handbrake has failed (Is it installed?)"
   
   echo "********************************************************"
   echo "Cleanup / Copy $TEMPFILENAME to $NEWFILENAME"
   echo "********************************************************"

   rm -f "$FILENAME"
   mv -f "$TEMPFILENAME" "$NEWFILENAME"
   chmod 664 "$NEWFILENAME"
   
   # Let next conversion run.
   rm -f "$LOCKFILENAME"

   echo "Done.  Congrats!"
else
   echo "PlexPostProc by nebhead"
   echo "Usage: $0 FileName"
fi
