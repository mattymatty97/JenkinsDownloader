# JenkinsDownloader
a bash script for easly download/update Jenkis Artifacts

To use:
  - Download the file on your Linux machine
  - Install jq needed to parse jsons files
  - open the script and modify the starting lines with the correct parameters ( jenkins link, artifact ordinal position, channel )
  - set the correct SavePath
  - run it

To update:
  - just re-run the script without any modification
  
To reset the script:
  - modify the "actual" variable to be '0'
