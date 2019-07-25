#
# Convert .m4a files into mp4 video files with a image slide show and
# running title text.
#
param (
	[Parameter(Mandatory=$False)] 
	[bool] $shouldProcessImages = $False,
	
	[Parameter(Mandatory=$False)] 
	[bool] $shouldComputeAudioDuration = $False,
	
	[Parameter(Mandatory=$False)] 
	[bool] $shouldConvertAudio = $True,

	[Parameter(Mandatory=$False)] 
	[bool] $isDebug = $False
)



$ffmpegRelativePath = ".\ffmpegconverter\bin\";
$ffmpegPath = "";
#$ffProbe = $($ffmpegPath + "ffprobe.exe");
#s$ffmpeg = $($ffmpegPath + "ffprobe.exe");
$audiosSourcePath = "C:\Users\rajanik\OneDrive\Parayanam\Srimad Bhagavatam\Bhagavatam Parayanam\" #"C:\Work\ffmpegconverter\bin\";
$imagesSourcePath = "C:\Users\rajanik\OneDrive\Photos\Krishna\";
$audioDurationPath = $($ffmpegPath + "AudioDuration\");
$imagesDestPath = $($ffmpegPath + "Images\");
$videosDestPath = $($ffmpegPath + "Videos\");
$imageResolutionWidth = "1280";
$imageResolutionHeight = "720";
$videoResolutionWidth = "480";
$videoResolutionHeight = "360";
$imagesPerVideo = 50;
function Convert-SourceImageFiles
{
	Set-Location -Path $ffmpegPath

	$imageFiles = Get-ChildItem -Path $($imagesSourcePath + "*") -Include "*.jpg";
	$fileIndex = 1;
	foreach ($imageFile in $imageFiles) 
	{
		$targetImageFileName = $("Image" + $fileIndex + ".jpg");
		Write-Host $("Processing image file: " + $imageFile.Name + " " + $targetFileName) -ForegroundColor Magenta;

		Convert-SourceImageFile -inImageFile $imageFile -outImageFile $($imagesDestPath + $targetImageFileName)

		$fileIndex++;
	}
}

function Convert-SourceImageFile
{
	param ([System.IO.FileInfo]$inImageFile, [string]$outImageFile)

	C:\Work\ffmpegconverter\bin\ffmpeg.exe -i $('"'+ $inImageFile.FullName + '"') `
	-loglevel error -stats `
	-vf "scale=($imageResolutionWidth):($imageResolutionHeight):force_original_aspect_ratio=decrease,pad=($imageResolutionWidth):($imageResolutionHeight):(ow-iw)/2:(oh-ih)/2,setsar=1" `
	-y $('"' + $outImageFile + '"' );
}

function Convert-SourceAudioFiles
{
	Set-Location -Path $ffmpegPath

	#Get audio duration for all audio files
	$audioFiles = Get-ChildItem -Path $($audiosSourcePath + "*") -Include "*.m4a";
	$fileIndex = 1;
	foreach ($audioFile in $audioFiles) 
	{
		$audioDurationFileName = $($audioDurationPath + $audioFile.BaseName + ".duration.txt");

		if ($shouldComputeAudioDuration)
		{
			Get-AudioDuration -inAudioFile $audioFile -outAudioFile $audioDurationFileName;
		}

		$fileIndex++;
	}

	#Convert audio files to videos
	$fileIndex = 1;
	foreach ($audioFile in $audioFiles) 
	{
		$audioDurationFileName = $($audioDurationPath + $audioFile.BaseName + ".duration.txt");

		#$lines = Get-Content -Path $audioDurationFileName 

		$durationLine = Get-Content -Path $audioDurationFileName -TotalCount 1;
		
		$audioDuration = $durationLine -as [double]

		$outputVideoFile = $($videosDestPath +  $audioFile.BaseName + ".mp4");
		
		Convert-AudioFileToVideo -inAudioFile $audioFile -inAudioDuration $audioDuration -outVideoFile $outputVideoFile;

		if ($isDebug)
		{
			exit;
		}

		$fileIndex++;
	}
}

function Get-AudioDuration
{
	param ([System.IO.FileInfo]$inAudioFile, [string]$outAudioFile)

	Write-Host $outAudioFile -ForegroundColor Magenta

	C:\Work\ffmpegconverter\bin\ffprobe.exe -v error -select_streams a:0 -show_entries stream=duration -of default=noprint_wrappers=1:nokey=1 "$inAudioFile" > "$outAudioFile"
}

function Get-VideoMetaDataFullTitle
{
	param ([string]$outVideoFileName)

	#Video Title
	[string] $videoTitle = ([System.IO.Path]::GetFileNameWithoutExtension($outVideoFile)) -as [string];
	#Volume
	$hyphenPosition = $videoTitle.IndexOf("-");
	$metadataVolume = $videoTitle.Substring(4, $hyphenPosition - 4);
	$videoTitle = $videoTitle.Remove(0, $hyphenPosition + 1);
	#Chapter
	$hyphenPosition = $videoTitle.IndexOf("-");
	$metadataChapter = $videoTitle.Substring(5, $hyphenPosition - 5);
	$videoTitle = $videoTitle.Remove(0, $hyphenPosition + 1);
	#Verse Start
	$hyphenPosition = $videoTitle.IndexOf("-");
	$metadataVerseStart = $videoTitle.Substring(5, $hyphenPosition - 5);
	$videoTitle = $videoTitle.Remove(0, $hyphenPosition + 1);
	#Verse End

	if ($videoTitle.Equals("EOC")){
		$metadataVerseEnd = "End of Chapter";
	}
	else{
		$metadataVerseEnd = $videoTitle -as [string];
	}

	return "Volume {0} Chapter {1} Verse {2} to {3}" -f $metadataVolume, $metadataChapter, $metadataVerseStart, $metadataVerseEnd;
}
function Convert-AudioFileToVideo
{
	param ([System.IO.FileInfo]$inAudioFile, [double]$inAudioDuration, [string]$outVideoFile)

	Write-Host $inAudioFile -ForegroundColor Magenta
	Write-Host $outVideoFile -ForegroundColor Magenta

	$imagesParam = ".\Images\Image%d.jpg";

	$durationTimeSpan = [System.TimeSpan]::FromSeconds($inAudioDuration);
	Write-Host $durationTimeSpan -ForegroundColor Magenta

	#Compute the frame rate based on the $imagesPerVideo and duration of the audio
	$frameRateRaw = $inAudioDuration / $imagesPerVideo;
	$frameRate = 1 / $frameRateRaw;


	#Process the Video Metadata
	$videoAlbum = "Srimad Bhagavatam Parayanam";
	$videoAlbumArtist = "Rajanikanth Thandavan"

	$hyphenPosition = $videoTitle.IndexOf("-");
	$videoTitle = $videoTitle.Remove(0, $hyphenPosition + 1);

	$videoTitleFull = Get-VideoMetaDataFullTitle -outVideoFileName $outVideoFile;

	#run ffmpeg to create slideshow with the audio
	C:\Work\ffmpegconverter\bin\ffmpeg.exe `
	-loglevel error -stats `
	-r $frameRate -start_number 1 `
	-i $imagesParam `
	-i $inAudioFile `
	-metadata title=$videoTitleFull -metadata album=$videoAlbum -metadata album_artist=$videoAlbumArtist `
	-c:v libx264 `
	-pix_fmt yuv420p `
	-s $(($videoResolutionWidth)+"x"+($videoResolutionHeight)) `
	-c:a aac `
	-r $frameRateRaw `
	-strict experimental `
	-shortest `
	-max_muxing_queue_size 8192 `
	-t $inAudioDuration `
	-y .\input.mp4;

	#Add logo and scrolling title to the video created
	C:\Work\ffmpegconverter\bin\AddTitleAndLogo.bat $("""Srimad Bhagavatam " + $videoTitleFull + """") "$outVideoFile"
	
	Remove-Item -Path .\input.mp4
}


$ffmpegPath = Resolve-Path -Path $ffmpegRelativePath
Write-Host "FFMPEG ONVERTER PATH: " + $ffmpegPath -ForegroundColor Green


Write-Host "Ensure destination folders exist" -ForegroundColor Green
New-Item -ItemType Directory -Force -Path $imagesDestPath
New-Item -ItemType Directory -Force -Path $videosDestPath
New-Item -ItemType Directory -Force -Path $audioDurationPath

if ($shouldProcessImages)
{
	#Convert-SourceImageFiles;
}

#Convert-SourceAudioFiles





<#==================================== BACKUP =========================================================#>

<#
	# Working SlideShow
	C:\Work\ffmpegconverter\bin\ffmpeg.exe -loglevel error -stats -r $frameRate -start_number 1 -i $imagesParam -i $inAudioFile -metadata title=$videoTitleFull -metadata album=$videoAlbum -metadata album_artist=$videoAlbumArtist -c:v libx264 -pix_fmt yuv420p -s $(($videoResolutionWidth)+'x'+($videoResolutionHeight)) -c:a aac -r $frameRateRaw -strict experimental -shortest -max_muxing_queue_size 8192 -vf drawbox="y=ih/PHI:color=black@0.4:width=iw:height=48:t=fill,drawtext=fontfile='c\:\/windows\/fonts\/arial.ttf':text=($videoTitleFull):fontcolor=yellow:fontsize=24:x=(w-tw)/2:y=(h/PHI)+th" -t $inAudioDuration -y $outVideoFile;

#>

<##>


<# Backup code for video convertedr
=====================================
	#working DrawText and DrawBox	
	#-vf drawbox="y=ih/PHI:color=black@0.4:width=iw:height=48:t=fill,drawtext=fontfile='c\:\/windows\/fonts\/arial.ttf':text=($videoTitleFull):fontcolor=yellow:fontsize=24:x=(w-tw)/2:y=(h/PHI)+th" `


	# Zoom and Pan
	#C:\Work\ffmpegconverter\bin\ffmpeg.exe -loglevel error -stats -framerate $frameRate -start_number 1 -i $imagesParam -filter_complex "zoompan=z='zoom+0.002':d=25*4:s=480x360" -i "$inAudioFile" -c:v libx264 -r 25 -pix_fmt yuv420p -c:a aac -strict experimental -shortest -max_muxing_queue_size 8192 -y "$outVideoFile"
	
	# Zoom and Pan + Crop
	#C:\Work\ffmpegconverter\bin\ffmpeg.exe -loglevel error -stats -framerate $frameRate -start_number 1 -i $imagesParam -i "$inAudioFile" -c:v libx264 -r 25 -pix_fmt yuv420p -c:a aac -strict experimental -shortest -max_muxing_queue_size 8192 -y "$outVideoFile"

	# No Audio
	#C:\Work\ffmpegconverter\bin\ffmpeg.exe -loglevel error -stats -framerate $frameRate -start_number 1 -i $imagesParam -filter_complex "zoompan=z='zoom+0.002':d=$frameRate*4:s=480x360" -c:v libx264 -r 25 -pix_fmt yuv420p -c:a aac -strict experimental -shortest -max_muxing_queue_size 8192 -y -t $inAudioDuration "$outVideoFile"

	# With audio no effects
	#C:\Work\ffmpegconverter\bin\ffmpeg.exe -loglevel error -stats -framerate $frameRate -start_number 1 -filter_complex "fade=t=in:st=1:d=0.5" -i $imagesParam -i $audioFile -c:v libx264 -r 5 -pix_fmt yuv420p -c:a aac -strict experimental -shortest -max_muxing_queue_size 8192 -y -t $inAudioDuration "$outVideoFile"

	#C:\Work\ffmpegconverter\bin\ffmpeg.exe -loglevel error -stats -start_number 1 -framerate $frameRate -filter_complex "zoompan=z='zoom+0.002':d=100:s=480x360" -i $imagesParam -i $audioFile -c:v libx264 -r 5 -pix_fmt yuv420p -c:a aac -strict experimental -shortest -max_muxing_queue_size 8192 -y -t $inAudioDuration "$outVideoFile"
	#C:\Work\ffmpegconverter\bin\ffmpeg.exe -loglevel error -stats -start_number 1 -framerate $frameRate -i $imagesParam -i $audioFile -c:v libx264 -r 25 -pix_fmt yuv420p -c:a aac -strict experimental -shortest -max_muxing_queue_size 8192 -y -t $inAudioDuration "$outVideoFile"

	#???C:\Work\ffmpegconverter\bin\ffmpeg.exe -i in.jpg -filter_complex "zoompan=z='zoom+0.002':d=25*4:s=1280x800" -pix_fmt yuv420p -c:v libx264 out.mp4

	#No audio / crossfade
	#C:\Work\ffmpegconverter\bin\ffmpeg.exe  -loglevel error -stats -i ".\Images\Image%d.jpg" -filter_complex "zoompan=d=(5+1)/1:fps=1/1,framerate=25:interp_start=0:interp_end=255:scene=100" -y ".\Images\Imagetest.mp4"



#>