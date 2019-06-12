::Text left to right
::echo off
::.\ffmpeg.exe -loglevel error -stats -i input.mp4 -i logo32.png -filter_complex "[0:v][1:v]overlay=main_w-overlay_w-10:10" -f avi pipe:1 | ^
::.\ffmpeg.exe -loglevel error -stats -i pipe:0 -vf drawbox="y=(ih-40):width=iw:height=35:color=black@0.4:t=fill,drawtext=text='%~1':fontfile='c\:\/windows\/fonts\/SCRIPTBL.ttf': y=((h)-th-10):x=(mod(5*n\,w+tw)-tw): fontcolor=yellow: fontsize=20: shadowx=-2: shadowy=-5" ^
::-vcodec libx264 -acodec aac -ab 100k -ar 48000 -ac 2 -y %2

::Text Right to Left
echo off
.\ffmpeg.exe -loglevel error -stats -i input.mp4 -i logo32.png -filter_complex "[0:v][1:v]overlay=main_w-overlay_w-10:10" -f avi pipe:1 | ^
.\ffmpeg.exe -loglevel error -stats -i pipe:0 -vf drawbox="y=(ih-40):width=iw:height=35:color=black@0.4:t=fill,drawtext=text='%~1':fontfile='c\:\/windows\/fonts\/SCRIPTBL.ttf': y=((h)-th-10):x=w-mod(max(t-2\,0)*(w+tw)/30\,(w+tw)): fontcolor=yellow: fontsize=20: shadowx=-2: shadowy=-5" ^
-vcodec libx264 -acodec aac -ab 100k -ar 48000 -ac 2 -y %2

echo Opening video file %2
%2