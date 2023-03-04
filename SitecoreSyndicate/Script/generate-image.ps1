<#
    .SYNOPSIS
        Calls Chat GPT and generates images from a prompt
        
    .NOTES
        Sitecore Hackathon 2023
        Team: Sitecore Syndicate
        Scott Stocker
        Sergey Plotnikov
        Topaz Ahmed
#>

function New-MediaItem
{
    [CmdletBinding()]
     param(
             [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)] [ValidateNotNullOrEmpty()] 
             [string]$filePath,
             
             [Parameter(Position=1, Mandatory=$true, ValueFromPipeline=$true)] [ValidateNotNullOrEmpty()] 
             [string]$fileName,
             
             [Parameter(Position=2, Mandatory=$true)] [ValidateNotNullOrEmpty()]
             [string]$mediaPath
         )
     
     
    $mco = New-Object Sitecore.Resources.Media.MediaCreatorOptions
    $mco.Database = [Sitecore.Configuration.Factory]::GetDatabase("master");
    $mco.Language = [Sitecore.Globalization.Language]::Parse("en");
    $mco.Versioned = [Sitecore.Configuration.Settings+Media]::UploadAsVersionableByDefault;
    #$mco.Destination = "$($mediaPath)/$([System.IO.Path]::GetFileNameWithoutExtension($filePath))";
    $mco.Destination = "$($mediaPath)/$fileName"; 
    $mc = New-Object Sitecore.Resources.Media.MediaCreator
    $mc.CreateFromFile($filepath, $mco);
    
    write-host 'New-MediaItem'
    write-host $mco.Destination
    write-host $filepath
}

function Wrapper {
    param(
             [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)] [ValidateNotNullOrEmpty()] 
             [string]$source
         )          
    

$Filename = [guid]::NewGuid() #.ToString() + ".png"  #[System.IO.Path]::GetFileName($source)
 
 Create-Temp-Folder

$dest = $AppPath + "App_Data\temp\$Filename" + '.png' 

write-host 'Wrapper'
write-host 'source ----------- ' $source
write-host 'Filename ----------- ' $Filename
write-host 'dest ----------- ' $dest



Invoke-WebRequest -Uri $source -OutFile $dest
$image = Get-Item $dest

#New-MediaItem $dest "$([Sitecore.Constants]::MediaLibraryPath)/Test"

write-host 'before New-MediaItem ----------- '
write-host $dest
write-host $Filename
write-host "$([Sitecore.Constants]::MediaLibraryPath)/Test"


New-MediaItem $dest $Filename "$([Sitecore.Constants]::MediaLibraryPath)/Test"
Remove-Item $dest

}




<#
    .SYNOPSIS
        Making an API call to chat GPT API to get a generated images by a passing phrase
#> 
function Get-Image-Urls
{
    param(
        [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)] [ValidateNotNullOrEmpty()] 
        [string]$phrase,
        
        [Parameter(Position=1, Mandatory=$true, ValueFromPipeline=$true)] [ValidateNotNullOrEmpty()] 
        [int]$number,
        
        [Parameter(Position=2, Mandatory=$true, ValueFromPipeline=$true)] [ValidateNotNullOrEmpty()] 
        [string]$imageSize
    )
    
    $url = "https://api.openai.com/v1/images/generations"
    $token = "<Your api key>"
    
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type"  = "application/json"
    }
    
    $body = @{
    "prompt" = $phrase
    "n"      =  [int]$number
    "size"   = $imageSize 
    } | ConvertTo-Json
    
    $response = Invoke-RestMethod -Uri $url -Method "POST" -Headers $headers -Body $body
    $response | ConvertTo-Json

    return $response
}

<#
    .SYNOPSIS
        Create a media folder under /sitecore/media library/Images if it doesn't exists 
#>        
function Create-Media-Folder
{
     param(
            [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)] [ValidateNotNullOrEmpty()] 
            [string]$folderName
        )
    
    $root = "$([Sitecore.Constants]::MediaLibraryPath)/Images"
    $imagesFolder = Get-Item -Path $root
    $adjustedFolderName = $folderName.substring(0, [System.Math]::Min(20, $folderName.Length))
    $result = "$($imagesFolder.Paths.FullPath)/$adjustedFolderName"
    Write-Host "Images will be stored in '$result' folder"
    if (Test-Path -Path $result) {
      Write-Host "Destination media folder '$result' already exists"
      return $result
    }
    else {
        # Create the new folder item
        $mediaFolderItem = New-Item -Path $result -ItemType "/sitecore/templates/System/Media/Media folder"
         # Add some metadata to the new folder
        $mediaLibraryPathItem.Editing.BeginEdit()
        $mediaLibraryPathItem.Fields["__Display name"].Value = $folderName
        $mediaLibraryPathItem.Editing.EndEdit()
        return $result
    }
}

function Create-Temp-Folder {
   $tempFolder = "$AppPath\App_Data\temp"
   if (Test-Path -Path $tempFolder) {
      Write-Host "Destination temp folder '$tempFolder' already exists"
      return $result
    }
    else {
        Write-Host "Creating folder '$tempFolder'"
        New-Item -ItemType Directory -Path $tempFolder
    }
    #AppPath\App_Data\temp
}

    write-host '------------------------------'
    #From context menu
    $selectedItem = Get-Item -Path .
    $mediaLibraryPathRoot = $selectedItem.Paths.FullPath
    
    write-host 'mediaLibraryPathRoot' $mediaLibraryPathRoot

    $numbers = [ordered]@{    
      "1"="1"    
      "2"="2"    
      "3"="3"    
      "4"="4"    
      "5"="5"    
      "6"="6"    
      "7"="7"    
      "8"="8"    
      "9"="9"    
      "10"="10"
    }
    
    $options = [ordered]@{    
     "256x256"="256x256"    
     "512x512"="512x512"    
     "1024x1024"="1024x1024"
    }

    $props = @{    
        Parameters = 
        @(        
          @{Name="phrase"; Prompt = "Enter some text for what you want generated:"}        
          @{Name="number"; Title="Choose number of images"; Options=$numbers; Tooltip="Choose number of images to generate."}        
          @{Name="imageSize"; Title="Choose an image size"; Options=$options; Tooltip="Choose image size."}   
        )    
          
        Title = "Generate Images"    
        Description = "Generate images from Chat GPT."    
        Width = 300    
        Height = 300    
        ShowHints = $true
    }
    
    $dialogResult = Read-Variable @props
    
    if($dialogResult -ne "ok"){
       Write-Host "Image generation process canceled."
       Exit
    }
    
    Write-Host $phrase
    Write-Host $number
    Write-Host $imageSize
    

    try 
    {
        write-host "Generating $number images based on term '$phrase' and having size of '$imageSize' "   
        
        #$phrase = "cat"
        #$number = 2
        #$imageSize = "512x512"

        $folder = Create-Media-Folder $phrase

       
        $response = Get-Image-Urls $phrase $number $imageSize
        $imageUrls = $response.data.url

        $i = 1
        foreach ($imageUrl in $imageUrls) {
            $imageName = "$SitecoreDataFolder\" + $phrase
            $imageName = $imageName + "-" + $i
            
            write-host '$imageName ' $mediaImagePath

            Wrapper $imageUrl
            $i = $i + 1
            
         write-host 'Done. Check you media folder for the generated images'
       }

    }

    catch 
    {
        Write-Host "Failed to generate images. Error: $($_.Exception.Message)"
    }
