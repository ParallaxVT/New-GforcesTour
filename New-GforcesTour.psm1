if (Get-Module New-GforcesTour) { return }

#Push-Location $psScriptRoot
#. .\New-GforcesTour-Functions.ps1
. C:\Users\Rafael\Documents\WindowsPowerShell\Modules\New-GforcesTour\New-GforcesTour-Functions.ps1
#Pop-Location

function New-GforcesTour {
    <#
    .SYNOPSIS

    .DESCRIPTION

    .PARAMETER TourName
        The Name of the Tour to build.
    .EXAMPLE
        C:\PS>New-GforcesTour scene1
    #>
    [CmdletBinding()]
    Param (
    [Parameter(
        Mandatory=$True,
        ValueFromPipeline=$True,
        ValueFromPipelineByPropertyName=$true)]
        $TourName
        #[string]$TourName
        )
    Begin {
        #$DebugPreference = "Continue"
        # Stop if there is any error
        $ErrorActionPreference = "Stop"
        $krVersion = "1.18"
        # All the files are relative to this script path
        $dir = "E:\virtual_tours\gforces\cars"
        #$dir = "C:\Users\Rafael\Downloads\gforces-tour"
        $config = "$dir\.src\config.xml"
        #Clear-Host
        if (!(Test-Path $config)) { Throw "Where is config.xml?" }
        # Source config.xml
        [xml]$configXml = Get-Content $config
        Write-Verbose "-------------------- Checking --------------------"
        foreach ( $country in $configXml.tour.country ) {
            foreach ( $brand in $country.brand) {
                foreach ($model in $brand.model) {
                    foreach ($car in $model.car) {
                        Write-Verbose ">> $($car.id)"
                        # Check that there is a panorama for each car in config.xml
                        if(!(Test-Path .\.src\panos\$($car.id).jpg )) { Throw "Pano .src\panos\$($car.id).jpg NOT FOUND." }
                        #Write-Verbose "   > .src\panos\$($car.id).jpg"
                        # Check that every car has tites and scene.xml
                        if(!(Test-Path .\$($car.id)\files )) { Throw "Folder .\$($car.id)\files NOT FOUND. Did you create the tiles correctly?" }
                        if(!(Test-Path .\$($car.id)\files\scenes )) { Throw "Folder .\$($car.id)\files\scenes NOT FOUND. Did you create the tiles correctly?" }
                        if(!(Test-Path .\$($car.id)\files\scenes\tiles )) { Throw "Folder .\$($car.id)\files\scenes\tiles NOT FOUND. Did you create the tiles correctly?" }
                        if(!(Test-Path .\$($car.id)\files\scenes\scene.xml )) { Throw "File .\$($car.id)\files\scenes\scene.xml NOT FOUND. Did you create the tiles correctly?" }
                        #Write-Verbose "    > $($car.id)"
                        # Check that the panorama names has 3 underscores
                        $underscores = ((($car.id).ToString()).split("_")).count
                        if($underscores -ne "4") { Throw "The file $($car.id) doesn't have 4 underscores, it has $underscores. Plaese raname it. "}
                    }
                }
            }
        }
        # Check there are no folders which don't belong to an existing panorama
        Get-ChildItem . -Exclude .src, .no_scenes, brands, shared -Directory |
        foreach {
            $carFolder = ".src/panos/$($_.BaseName).jpg"
            if(!(Test-Path $($carFolder))) {
                throw "The following folder is obsolete: $($_.FullName)"
            }
        }
        Write-Verbose "-------------------- Cars --------------------"
    }
    Process {
        # Check that the objects taken from the pipeline exist in config.xml
        foreach ( $country in $configXml.tour.country ) {
            foreach ( $brand in $country.brand) {
                foreach ($model in $brand.model) {
                    foreach ($car in $model.car) {
                        $tour = $($car.id) | where { $_ -match $TourName.BaseName }
                        if ($tour -notlike "" ){
                            Write-Verbose ">> $tour"
                            # Add index.html and devel.html
                            Add-GforcesHtmlFiles
                            # Add 'car/files/content/coord.xml' and 'car/files/content/panolist.xml'
                            Add-GforcesContent
                            # Add 'car/files/devel.xml'
                            Add-GforcesDevelXml
                            # Add 'car/file/tour.xml'
                            Add-GforcesTourXml
                        }
                    }
                }
            }
        }
    }
    End {
    # Check that all the car folders contain any HTML file.
    # If there isn't one, that would mean that I generated the tiles for a car, but I didn't add the details to config.xml
    # and run the script to generate the tour files
    Get-ChildItem . -Exclude .src, .no_scenes, brands, shared -Directory |
        foreach {
            if(!(Test-Path "$($_.FullName)/*.html")){Throw "The follwing folder doesn't contain any HTLM files: $($_.FullName)`
            This is probably because I generated the tiles but I didn't add the details to the config.xml file"}
        }
    # Add 'brands/index.html'
    Add-GfocesBrandsIndex
    # Add 'brands/country/index.html'
    Add-GforcesCountryIndex
    # Add 'brands/country/brand/index.html'
    Add-GforcesBrandIndex
    # Add 'brands/country/brand/model/index.html'
    Add-GforcesModelIndex
    # Add 'brands/country/grid_brands.html' and 'grid_more'
    Add-GforcesGridBrands
    # Add 'brands/country/brand/brand.html'
    Add-GforcesBrandHtml
    # Add 'brands/country/brand/content/items.xml'
    Add-GforcesBrandItemsXml
    # Add 'brands/country/brand/devel_brand.xml'
    Add-GforcesBrandDevelXml
    # Add 'brands/country/brand/brand.xml'
    Add-GforcesBrandXml
    }
}