function Add-GforcesHtmlFiles {
    Write-Debug "   > HTML files" -Verbose
    if ( Test-Path $dir\$tour\index.html ) {
        Remove-Item $dir\$tour\index.html -Force
        #Write-Debug "     Delete file $dir\$tour\index.html"
    }
    if ( Test-Path $dir\$tour\devel.html ) {
        Remove-Item $dir\$tour\devel.html -Force
        #Write-Debug "     Delete file $dir\$tour\devel.html"
    }
    # index.html
    $template_content = Get-Content $dir\.src\html\scene_template.html
    $template_content |
    foreach { ($_).replace('SERVERNAME',$configXML.tour.url) } |
    foreach { ($_).replace('SCENENAME',$tour) } |
    Out-File -Encoding utf8 $dir\$tour\index.html
    # devel.xml
    $template_content |
    foreach { ($_).replace('SERVERNAME','..') } |
    foreach { ($_).replace('SCENENAME',$tour) } |
    foreach { ($_).replace('tour.xml','devel.xml') } |
    Out-File -Encoding utf8 $dir\$tour\devel.html
}

function Add-GforcesContent {
    # index includes: coord.xml and panolist.xml
    Write-Debug "   > content/index.xml file"
    $contentFile = "$dir\$tour\files\content\index.xml"
    New-Item -ItemType File $contentFile -Force | Out-Null
    Set-Content -Force $contentFile '<krpano>'
    Add-Content $contentFile ('    <action name="movecamera_' + $car.id + '">movecamera(' +  $car.h +  ',' + $car.v + ');</action>')
    Add-Content $contentFile ('    <layer name="panolist" keep="true"><pano name="' + $car.id + '" scene="' + $car.name + '" title="' + $car.name + '" /></layer>')
    Add-Content $contentFile '</krpano>'
}

function Add-GforcesDevelXml {
    Write-Debug "   > devel.xml"
    $develFile = "$dir\$tour\files\devel.xml"
    New-Item -ItemType File $develFile -Force | Out-Null
    Add-Content $develFile '<?xml version="1.0" encoding="UTF-8"?>'
    Add-Content $develFile ('<krpano version="' + $krVersion + '">')
    Add-Content $develFile '    <krpano logkey="true" />'
    Add-Content $develFile '    <develmode enabled="true" />'
    Add-Content $develFile '    <!-- Content -->'
    $contentfolder = Get-ChildItem "$dir\$tour\files\content\*.xml"  |
    foreach { Add-Content $develFile ('    <include url="%CURRENTXML%/content/' + $_.BaseName + '.xml" />') }
    Add-Content $develFile '    <!-- Include -->'
    $includefolder = Get-ChildItem "$dir\shared\include\"  |
    foreach { Add-Content $develFile ('    <include url="%SWFPATH%/include/' + $_.BaseName + '/index.xml" />') }
    Add-Content $develFile '    <!-- Scenes -->'
    $scenesfolder = Get-ChildItem "$dir\$tour\files\scenes\*.xml"  |
    foreach { Add-Content $develFile ('    <include url="%CURRENTXML%/scenes/' + $_.BaseName + '.xml" />') }
    Add-Content $develFile '</krpano>'
}

# This function is used by Add-GforcesTourXml and Add-GforcesBrandXml
function Add-ToTourXml ($selectedFolder) {
    foreach ($xmlFile in $selectedFolder) {
        Get-Content $xmlFile |
        # Skip the lines containing krpano tags
        where { $_ -notmatch "<krpano" -and $_ -notmatch "</krpano" -and $_.trim() -ne "" } |
        # Remove any whitespace before ="
        foreach { $_ -replace '\s+="','="' } |
        # Add custom images to cars from 'nl'
        foreach {
            if ($countrycode -eq "nl") {
                $_ -replace 'tions/inst', 'tions/nl_inst' `
                   -replace 'fs.png', 'nl_fs.png' `
                   -replace 'message.png', 'nl_message.png' `
            } else { $_ }
        } |
        # Remove any whitespace at the start of each line. Do this always the last thing in this function
        foreach { $_.ToString().TrimStart() |
        Add-Content $tourFile
        }
    }
}

function Add-GforcesTourXml {
    Write-Debug "   > tour.xml"
    $tourFile = "$dir\$tour\files\tour.xml"
    New-Item -ItemType File $tourFile -Force | Out-Null
    Add-Content $tourFile '<?xml version="1.0" encoding="UTF-8"?>'
    Add-Content $tourFile ('<krpano version="' + $krVersion + '">')
    Add-Content $tourFile '<krpano logkey="true" />'
    # Add XML files inside 'content' folder
    $contentFolder = Get-ChildItem "$dir\$tour\files\content\*.xml"
    Add-ToTourXml $contentFolder
    # Add XML files inside 'include' folder
    $includeFolder = Get-ChildItem "$dir\shared\include\*\*.xml" -Exclude coordfinder, editor_and_options
    Add-ToTourXml $includeFolder
    # Add XML files inside 'scenes' folder
    $scenesFolder = Get-ChildItem "$dir\$tour\files\scenes\*.xml"
    Add-ToTourXml $scenesFolder
    Add-Content $tourFile '</krpano>'
}

function Add-GfocesBrandsIndex {
    Write-Verbose "-------------------- Webpages --------------------"
    Write-Verbose ">> index.html"
    $tour = $configXml.tour.country
    Get-Content "$dir\.src\html\index_template.html" |
    foreach {
        if ($_ -match 'ADDCONTENT' ) {
            '            <h4>Choose a country</h4>'
            '            <ul>'
            foreach ($country in $tour) {
                '                <li><a href="./' + $country.id + '/index.html" title="' + $country.name + '">'+ $country.name + '</a></li>'
            }
            '            </ul>'
        }
        else
        {
            $_
        }
    } |
    foreach {($_).replace('NEWPATH','..')} |
    foreach {($_).replace('HOMEPATH','.')} |
    foreach {($_).replace('./brands/index.html','./index.html')} |
    foreach {($_).replace('.brands {','.brands {display:none;')} |
    Set-Content "$dir\brands\index.html"
}

function Add-GforcesCountryIndex {
    Write-Verbose ">> Countries:"
    $tour = $configXml.tour.country
    foreach ($item in $tourArray) {
        $countryId = ($item -split "_")[0]
        $brandId = ($item -split "_")[1]
        [Array]$countryArray += $countryId
        $countrArray = $countrArray | sort -Unique
        foreach ($country in $tour | where { $_.id -like $countryArray } ) {
            $countryFolder = "$dir\brands\$($country.id)"
            if (!(Test-Path "$countryFolder")) {
                New-Item "$countryFolder" -Type Directory | Out-Null
                Write-Debug "     Add folder $countryFolder"
            }
            Get-Content "$dir\.src\html\index_template.html" |
            foreach {
                if ($_ -match 'ADDCONTENT' ) {
                    '            <h5><a href="../index.html">(Up One Level)</a></h5>'
                    foreach ($brand in $country.brand) {
                        '            <h4><a href="./' + $($brand.id) + '/index.html">' + $brand.name + '</a></h4>'
                        '            <ul>'
                        foreach ($model in $brand.model) {
                            foreach ($car in $model.car) {
                            '                <li><a href="../../' + $car.id + '/index.html" title="' + $car.name + '">'+ $car.id + '</a></li>'
                            }
                        }
                        '            </ul>'
                    }
                }
                else
                {
                    $_
                }
            } |
            foreach {($_).replace('NEWPATH','../..')} |
            foreach {($_).replace('HOMEPATH','..')} |
            foreach {($_).replace('All Brands','Grid View')} |
            foreach {($_).replace('./brands/index.html','./grid_brands.html')} |
            Set-Content "$countryFolder\index.html"
            # devel.html
            Get-Content "$dir\.src\html\index_template.html" |
            foreach {
                if ($_ -match 'ADDCONTENT' ) {
                    '            <h5><a href="../index.html">(Up One Level)</a></h5>'
                    foreach ($brand in $country.brand ) {
                        '            <h4>' + $brand.name + '</h4>'
                        '            <ul>'
                        foreach ($model in $brand.model) {
                            foreach ($car in $model.car) {
                            '                <li><a href="../../' + $car.id + '/devel.html" title="' + $car.name + '">'+ $car.id + '</a></li>'
                            }
                        }
                        '            </ul>'
                    }
                }
                else
                {
                    $_
                }
            } |
            foreach {($_).replace('NEWPATH','../..')} |
            foreach {($_).replace('HOMEPATH','..')} |
            foreach {($_).replace('All Brands','Grid View')} |
            foreach {($_).replace('./brands/index.html','./grid_brands.html')} |
            foreach {($_).replace('</style>','.home-content{background:palegoldenrod;}</style>')} |
            Set-Content "$countryFolder\devel.html"
            Write-Verbose "   > $($country.id)/devel.html file"
        }
    }
}

function Add-GforcesRecent {
    Get-Content "$dir\.src\html\index_template.html" |
    foreach {
        if ($_ -match 'ADDCONTENT' ) {
            '            <h4>Recent Cars - DEVEL</h4>'
            '            <ul>'
            foreach ($car in $tourIDArray) {
                    '                <li><a href="../' + $car + '/devel.html" title="' + $car + '">'+ $car + '</a></li>'
            }
            '            </ul>'
            '            <h4>Recent Cars - WEB</h4>'
            '            <ul>'
            foreach ($car in $tourIDArray) {
                    '                <li><a href="SERVERNAME/' + $car + '/index.html" title="' + $car + '">'+ $car + '</a></li>'
            }
            '            </ul>'
        }
        else
        {
            $_
        }
    } |
    foreach {($_).replace('NEWPATH','..')} |
    foreach {($_).replace('HOMEPATH','.')} |
    foreach {($_).replace('./brands/index.html','./index.html')} |
    foreach {($_).replace('.brands {','.brands {display:none;')} |
    foreach {($_).replace('SERVERNAME',$configXML.tour.url) } |
    Set-Content "$dir\brands\recent.html"
    Write-Verbose ">> recent.html"
}

function Add-GforcesBrandIndex {
    Write-Verbose ">> Brands:"
    $tour = $configXml.tour.country
    foreach ($item in $tourArray) {
        $countryId = ($item -split "_")[0]
        $brandId = ($item -split "_")[1]
        foreach ($country in $tour | where { $_.id -like $countryId } ) {
            foreach ($brand in $country.brand | where { $_.id -like $brandId } ) {
                $brandFolder = "$dir\brands\$($country.id)\$($brand.id)"
                if (!(Test-Path "$brandFolder")) {
                    New-Item "$brandFolder" -Type Directory | Out-Null
                    Write-Debug "     Add folder $brandFolder"
                }
                Get-Content "$dir\.src\html\index_template.html" |
                foreach {
                    if ($_ -match 'ADDCONTENT' ) {
                        '            <h5><a href="../index.html">(Up One Level)</a></h5>'
                        '            <h4>' + $brand.name + '</h4>'
                        '            <ul>'
                        if ( !(Test-Path "$brandFolder") ) {
                            New-Item "$brandFolder" -Type Directory | Out-Null
                            Write-Debug "     Add folder $brandFolder"
                        }
                        foreach ($model in $brand.model) {
                        '                <li><a href="../../' + $country.id + '/' + $brand.id + '/' + $model.id + '/index.html" title="' + $model.name + '">'+ $model.name + '</a></li>'
                        }
                        '            </ul>'
                    }
                    else
                    {
                        $_
                    }
                } |
                foreach {($_).replace('NEWPATH','../../..')} |
                foreach {($_).replace('HOMEPATH','../..')} |
                foreach {($_).replace('All Brands','Dark Interface')} |
                foreach {($_).replace('./brands/index.html','./brand.html')} |
                Set-Content "$brandFolder\index.html"
                Write-Verbose "   > $($country.id)/$($brand.id)/index.html file"
                #Write-Debug "     Add file $dir\brands\$($country.id)\$($brand.id)\index.html"
            }
        }
    }
}

function Add-GforcesModelIndex {
    Write-Verbose ">> Models:"
    $tour = $configXml.tour.country
    foreach ($item in $tourArray) {
        $countryId = ($item -split "_")[0]
        $brandId = ($item -split "_")[1]
        foreach ($country in $tour | where { $_.id -like $countryId } ) {
            foreach ($brand in $country.brand | where { $_.id -like $brandId } ) {
                foreach ($model in $brand.model) {
                    $modelFolder = "$dir\brands\$($country.id)\$($brand.id)\$($model.id)"
                    if (!(Test-Path "$modelFolder")) {
                        New-Item "$modelFolder" -Type Directory | Out-Null
                        Write-Debug "     Add folder $modelFolder"
                    }
                    Get-Content "$dir\.src\html\index_template.html" |
                    foreach {
                        if ($_ -match 'ADDCONTENT' ) {
                            '            <h5><a href="../index.html">(Up One Level)</a></h5>'
                            '            <h4>' + $model.name + '</h4>'
                            '            <ul>'
                            if ( !(Test-Path $modelFolder) ) {
                                New-Item $modelFolder -Type Directory | Out-Null
                                Write-Debug "     Add folder $modelFolder"
                            }
                            foreach ($car in $model.car) {
                                '                <li><a href="../../../../' + $car.id + '/index.html" title="' + $car.name + '">'+ $car.id + '</a></li>'
                            }
                            '            </ul>'
                        }
                        else
                        {
                            $_
                        }
                    } |
                    foreach {($_).replace('NEWPATH','../../../..')} |
                    foreach {($_).replace('HOMEPATH','../../..')} |
                    foreach {($_).replace('./brands/index.html','../brand.html')} |
                    foreach {($_).replace('.brands {','.brands {display:none;')} |
                    Set-Content "$modelFolder\index.html"
                    Write-Verbose "   > $($country.id)\$($brand.id)\$($model.id)\index.html"
                    #Write-Debug "     Add file $modelFolder\index.html"
                }
            }
        }
    }
}

function Add-GforcesGridBrands {
    Write-Verbose "-------------------- Grid View -------------------- "
    # Generate the HTML files with the logos in a grid
    $tour = $configXml.tour.country
    $param1 = 0
    $param2 = 0
    $tempfile = "$dir\.src\html\index.temp"
        foreach ($item in $tourArray) {
        $countryId = ($item -split "_")[0]
        $brandId = ($item -split "_")[1]
        foreach ($country in $tour | where { $_.id -like $countryId } ) {
            $brandsfile = "$dir\brands\$($country.id)\grid_brands.html"
            $morebrandsfile = "$dir\brands\$($country.id)\grid_more.html"
            New-Item -ItemType File $tempfile -Force | Out-Null
            foreach ($brand in $country.brand) {
                $brand_name = $brand.id
                Add-Content $tempfile ('                <article class="one-fifth" style="transform:translate(' + $param1 + 'px,' + $param2 + 'px); -webkit-transform: translate3d(' + $param1 + 'px,' + $param2 + 'px,0px);"><a href="./' + $($brand.id) + '/brand.html" class="project-meta" title="Click me"><img src="../../shared/html_brands/img/logos/' + $($brand.id) + '.jpg" alt="' + $($brand.name) + '"/></a><a href="./' + $($brand.id) + '/brand.html" class="project-meta"><h5 class="title">' + $($brand.name) + '</h5></a></article>')
                $param1 = $param1 + 192
                if ($param1 -eq 960) {
                    $param1 = 0
                    $param2 = $param2 + 220
                }
            }
            $template_content = Get-Content $dir\.src\html\brands_index_template.html
            $brands_content = Get-Content $tempfile
            $template_content | foreach {
                if ($_ -match 'ADDCONTENT' ) {
                    $brands_content
                } elseif ($_ -match 'PARAM3') {
                    ($_).replace('PARAM3',$param2)
                } else {
                    $_
                }
            } | Set-Content $brandsfile
            Write-Verbose "   > $($country.id)\grid_brands.html"
            #Write-Debug "     Add file $brandsfile"
            Remove-Item $tempfile -Force
            # Now we need to create grid_more.html, which is the same as grid_brands.html but changing the the links to more_brands.html
            Get-Content $brandsfile |
            foreach { ($_).replace('brand.html','grid_more.html') } |
            Out-File -Encoding utf8 $morebrandsfile
            Write-Verbose "   > $($country.id)\grid_more.html"
            #Write-Debug "     Add file $morebrandsfile"
        }
    }
}

function Add-GforcesBrandHtml {
    Write-Verbose "-------------------- Dark Interface -------------------- "
    Write-Verbose ">> HTML:"
    $tour = $configXml.tour.country
    foreach ($item in $tourArray) {
        $countryId = ($item -split "_")[0]
        $brandId = ($item -split "_")[1]
        foreach ($country in $tour | where { $_.id -like $countryId } ) {
            foreach ($brand in $country.brand | where { $_.id -like $brandId } ) {
                $first_car = $brand.model.car[0].id
                $brand_name = $brand.id
                $brandname = "$($country.id)/$($brand.id)"
                # Create brand.html for each brand
                $template_content = Get-Content $dir\.src\html\brand_template.html
                $template_content |
                foreach { ($_).replace('SERVERNAME',$configXML.tour.url) } |
                foreach { ($_).replace('BRANDNAME',$brandname) } |
                foreach { ($_).replace('SCENENAME',$first_car) } |
                Out-File -Encoding utf8 $dir\brands\$($country.id)\$brand_name\brand.html
                Write-Verbose "   > $($country.id)\$brand_name\brand.html"
                # Create more_brands.html for each brand
                $template_content |
                foreach { ($_).replace('SERVERNAME',$configXML.tour.url) } |
                foreach { ($_).replace('BRANDNAME',$brandname) } |
                foreach { ($_).replace('SCENENAME',($first_car + ',null,more')) } |
                Out-File -Encoding utf8 $dir\brands\$($country.id)\$brand_name\more_brands.html
                Write-Debug "   > $($country.id)\$brand_name\more_brand.html"
                # Create devel\brand.html
                $template_content |
                foreach { ($_).replace('SERVERNAME','../../..') } |
                foreach { ($_).replace('SCENENAME',$first_car) } |
                foreach { ($_).replace('BRANDNAME',$brandname) } |
                foreach { ($_).replace('brand.xml','devel_brand.xml') } |
                Out-File -Encoding utf8 $dir\brands\$($country.id)\$brand_name\devel_brand.html
                Write-Debug "   > $($country.id)\$brand_name\devel_brand.html"
                # Create devel\more_brands.html
                $template_content |
                foreach { ($_).replace('SERVERNAME','../..') } |
                foreach { ($_).replace('BRANDNAME',$brand_name) } |
                foreach { ($_).replace('SCENENAME',($first_car + ',null,more')) } |
                foreach { ($_).replace('brand.xml','devel_brand.xml') } |
                Out-File -Encoding utf8 $dir\brands\$($country.id)\$brand_name\devel_more_brands.html
                Write-Debug "   > $($country.id)\$brand_name\devel_more_brand.html"
            }
        }
    }
}

function Add-GforcesBrandItemsXml {
    Write-Verbose ">> XML:"
    $tour = $configXml.tour.country
    foreach ($item in $tourArray) {
        $countryId = ($item -split "_")[0]
        $brandId = ($item -split "_")[1]
        foreach ($country in $tour | where { $_.id -like $countryId } ) {
            foreach ($brand in $country.brand | where { $_.id -like $brandId } ) {
                $itemsFile = "$dir\brands\$($country.id)\$($brand.id)\content\items.xml"
                New-Item -ItemType File $itemsFile -Force | Out-Null
                Add-Content $itemsFile ('<krpano>')
                $order = 0
                foreach ($model in $brand.model) {
                    foreach ($car in $model.car | where {
                    $_.id -notlike 'hyundai_i1' -and
                    $_.id -notlike 'land_rover_range_rover_sport' -and
                    $_.id -notlike 'nissan_370z_roadster_open' -and
                    $_.id -notlike 'nissan_leaf' -and
                    $_.id -notlike 'nissan_note' -and
                    $_.id -notlike 'nissan_qashqai' -and
                    $_.id -notlike 'volvo_v70'
                    }){
                        $y_value = 2 + ($order * 50)
                        Add-Content $itemsFile ('<layer name    ="container_1_item_' + $car.id + '"')
                        Add-Content $itemsFile ('       html    ="[h1]' + $car.name + '[/h1]"')
                        Add-Content $itemsFile ('       onclick ="activatepano(' + ($car.id) + ',scenevariation);"')
                        Add-Content $itemsFile ('       style   ="container_1_item_style"')
                        Add-Content $itemsFile ('       y       ="' + $y_value + '"')
                        Add-Content $itemsFile '       />'
                        $order = $order + 1
                    }
                }
                Add-Content $itemsFile ('</krpano>')
                $scroll_height = $order * 50
                # Update scroll height after removing some scenes
                $startup_content = Get-Content "$dir\shared\include_brand\startup\index.xml"
                $startup_content |
                foreach { ($_).replace('SCROLLHEIGHT',$scroll_height) } |
                Out-File -Encoding utf8 "$dir\shared\include_brand\startup\index.xml"
                Write-Verbose "   > $($country.id)\$($brand.id)\content\items.xml"
                # Copy the corresponding logo
                Copy-Item "$dir\shared\html_brands\img\logos\$($brand.id).jpg" "$dir\brands\$($country.id)\$($brand.id)\content\thumb.jpg"
            }
        }
    }
}

function Add-GforcesBrandDevelXml {
    $tour = $configXml.tour.country
    foreach ($item in $tourArray) {
        $countryId = ($item -split "_")[0]
        $brandId = ($item -split "_")[1]
        foreach ($country in $tour | where { $_.id -like $countryId } ) {
            foreach ($brand in $country.brand | where { $_.id -like $brandId } ) {
                $develFile = "$dir\brands\$($country.id)\$($brand.id)\devel_brand.xml"
                New-Item -ItemType File $develFile -Force | Out-Null
                Add-Content $develFile '<?xml version="1.0" encoding="UTF-8"?>'
                Add-Content $develFile ('<krpano version="' + $krVersion + '">')
                Add-Content $develFile '<krpano logkey="true" />'
                Add-Content $develFile '    <develmode enabled="true" />'
                Add-Content $develFile '    <!-- Content -->'
                Add-Content $develFile ('    <include url="%CURRENTXML%/content/' + $(Get-Item $dir\brands\$($country.id)\$($brand.id)\content\items.xml).BaseName + '.xml" />')
                foreach ($model in $brand.model) {
                    foreach ($car in $model.car) {
                        Add-Content $develFile ('    <include url="%SWFPATH%/../' + $(Get-Item $dir\$($car.id)).BaseName + '/files/content/index.xml" />')
                    }
                }
                Add-Content $develFile '    <!-- Include -->'
                $includefolder = dir "$dir\shared\include_brand\"  |
                foreach { Add-Content $develFile ('    <include url="%SWFPATH%/include_brand/' + $_.BaseName + '/index.xml" />') }
                Add-Content $develFile '    <!-- Scenes -->'
                foreach ($model in $brand.model) {
                    foreach ($car in $model.car) {
                        Add-Content $develFile ('    <include url="%SWFPATH%/../' + $(Get-Item $dir\$($car.id)).BaseName + '/files/scenes/scene.xml" />')
                    }
                }
                Add-Content $develFile '</krpano>'
                Write-Verbose "   > $($country.id)\$($brand.id)\devel_brand.xml"
            }
        }
    }
}

function Add-GforcesBrandXml {
    $tour = $configXml.tour.country
    foreach ($item in $tourArray) {
        $countryId = ($item -split "_")[0]
        $brandId = ($item -split "_")[1]
        foreach ($country in $tour | where { $_.id -like $countryId } ) {
            foreach ($brand in $country.brand | where { $_.id -like $brandId } ) {
                $tourFile = "$dir\brands\$($country.id)\$($brand.id)\brand.xml"
                New-Item -ItemType File $tourFile -Force | Out-Null
                Add-Content $tourFile '<?xml version="1.0" encoding="UTF-8"?>'
                Add-Content $tourFile ('<krpano version="' + $krver + '">')
                Add-Content $tourFile '<krpano logkey="true" />'
                # Add 'items.xml' file inside 'brands' directory
                $contentFolder = Get-Item "$dir\brands\$($country.id)\$($brand.id)\content\items.xml"
                Add-ToTourXml $contentFolder
                # Add 'content/index.xml' file inside each car belonging to the same brand
                foreach ($model in $brand.model) {
                    foreach ($car in $model.car) {
                        #Add-Content $develFile ('    <include url="%SWFPATH%/../' + $(Get-Item $dir\$($car.id)).BaseName + '/files/content/index.xml" />')
                        $contentFolder = Get-Item "$dir\$($car.id)\files\content\index.xml"
                        Add-ToTourXml $contentFolder
                    }
                }
                # Add XML files inside 'include' folder
                $includeFolder = Get-ChildItem "$dir\shared\include_brand\*\*.xml" -Exclude coordfinder, editor_and_options
                Add-ToTourXml $includeFolder
                # Add 'scene.xml' file inside each car belonging to the same brand
                foreach ($model in $brand.model) {
                    foreach ($car in $model.car) {
                        $scenesFolder = Get-Item "$dir\$($car.id)\files\scenes\scene.xml"
                        Add-ToTourXml $scenesFolder
                    }
                }
                Add-Content $tourFile '</krpano>'
                Write-Verbose "   > $($country.id)\$($brand.id)\brand.html"
            }
        }
    }
}

function Rename-CarsWithWrongName {
    # Array containing all the cars to be ranamed
    $renameTour = $configXml.tour.rename.car
    foreach ($renameCar in $renameTour) {
        [Array]$renameArray += $renameCar
    }
    # Check if any of the cars to be renamed are in the cars passed in the pipeline (Intersect arrays)
    $renameThisCars = $tourIDArray + $renameArray.id | select -Unique
    $renameThisCars = $tourIDArray | Where-Object { $renameArray.id -contains $_ }
    if ($renameThisCars -notlike "") {
        Write-Verbose "-------------------- Rename Cars --------------------"
    }
    #write-host $renameThisCars
    # Run 2 foreach loops to get the 'renameTo' attribute
    foreach ($item in $renameThisCars) {
        foreach ($renameCar in $renameArray | where {$_.id -like $item})  {
            $carID = $($renameCar.id)
            $carRenameTo = $($renameCar.renameTo)
            #Write-Host $carID
            #Write-Host $carRenameTo
            # Delete folder with the wrong name     
            if ( Test-Path $dir\$carRenameTo ) {
                Remove-Item $dir\$carRenameTo -Recurse -Force
            }
            # Create a new folder with the wrong name with a folder named 'files' inside it
            New-Item -Path $dir\$carRenameTo -ItemType Directory | Out-Null
            New-Item -Path $dir\$carRenameTo\files -ItemType Directory | Out-Null
            # Copy original 'index.html' file replacing wrong name for the right one
            $index_content = Get-Content $dir\$carID\index.html
            $index_content |
            foreach { ($_).replace($CarID,$carRenameTo ) } |
            Out-File -Encoding utf8 $dir\$carRenameTo\index.html
            # Copy original 'tour.xml' file replacing wrong name for the right one
            $index_content = Get-Content $dir\$carID\files\tour.xml
            $index_content |
            foreach { ($_).replace($CarID + '"',$carRenameTo + '"' ) } |
            Out-File -Encoding utf8 $dir\$carRenameTo\files\tour.xml
            Write-Verbose ">> $carID > $carRenameTo"
        }
    }
    # Check if the following things exist:
    #  Folder with the wrong car name 
    #  index.html
    #  'files' folder
    #  tour.xml
    # If any of this is missing print a warning to run the script for an specific car
}