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
    Add-Content $contentFile ('    <action name="movecamera_' + $car.id + '">movecamera(' +  $car.h +  ',' + $car.v + ');')
    if ($car.seat1) { Add-Content $contentFile ("        add_seat_btn(1,$($car.seat1));") }
    if ($car.seat2) { Add-Content $contentFile ("        add_seat_btn(2,$($car.seat2));") }
    if ($car.bg1) { Add-Content $contentFile ("        add_bg_btn(1,$($car.bg1));") }
    if ($car.bg2) { Add-Content $contentFile ("        add_bg_btn(2,$($car.bg2));") }
    if ($car.bg3) { Add-Content $contentFile ("        add_bg_btn(3,$($car.bg3));") }
    if (!($car.bg1)) { Add-Content $contentFile ("        removelayer(bg_btn);") }
    Add-Content $contentFile ('    </action>')
    Add-Content $contentFile ('    <layer name="panolist" keep="true"><pano name="' + $car.id + '" scene="' + $car.name + '" title="' + $car.name + '" /></layer>')
    Add-Content $contentFile '</krpano>'
}

function Add-GforcesDevelXml {
    Write-Debug "   > devel.xml"
    $develFile = "$dir\$tour\files\devel.xml"
    New-Item -ItemType File $develFile -Force | Out-Null
    Add-Content $develFile '<?xml version="1.0" encoding="UTF-8"?>'
    Add-Content $develFile ('<krpano version="' + $krVersion + '" logkey="true">')
    Add-Content $develFile '    <develmode enabled="true" />'
    Add-Content $develFile '    <!-- Plugins -->'
    Add-Content $develFile ('    <include url="%SWFPATH%/plugins/showtext.xml" />')
    Add-Content $develFile '    <!-- Content -->'
    $contentfolder = Get-ChildItem "$dir\$tour\files\content\*.xml"  |
    foreach { Add-Content $develFile ('    <include url="%CURRENTXML%/content/' + $_.BaseName + '.xml" />') }
    Add-Content $develFile '    <!-- Include -->'
    $includefolder = Get-ChildItem "$dir\shared\includev2\"  |
    foreach { Add-Content $develFile ('    <include url="%SWFPATH%/includev2/' + $_.BaseName + '/index.xml" />') }
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
    $enFile = "$dir\$tour\files\en.xml"
    New-Item -ItemType File $tourFile -Force | Out-Null
    Add-Content $tourFile '<?xml version="1.0" encoding="UTF-8"?>'
    Add-Content $tourFile ('<krpano version="' + $krVersion + '">')
    Add-Content $tourFile '<krpano logkey="true" />'
    Add-Content $tourFile '<include url="%SWFPATH%/plugins/showtext.xml" />'
    # Add XML files inside 'content' folder
    $contentFolder = Get-ChildItem "$dir\$tour\files\content\*.xml"
    Add-ToTourXml $contentFolder
    # Add XML files inside 'include' folder
    if (Test-Path "$dir\$tour\files\scenes\scene.xml") {
        # For normal interiors
        $includeFolder = Get-ChildItem "$dir\shared\includev2\*\*.xml" -Exclude coordfinder, editor_and_options, visualiser
        # For the visualiser
    }
    else
    {
        $includeFolder = Get-ChildItem "$dir\shared\includev2\*\*.xml" -Exclude coordfinder, editor_and_options
    }
    Add-ToTourXml $includeFolder
    # Add XML files inside 'scenes' folder
    # If it's a Visualiser interior fix scene name in the firs scene
    if (Test-Path "$dir\$tour\files\scenes\scene_1_a.xml") {
        $newScenename = '<scene name="' + $car.id + '">'
        $sceneContent = Get-Content "$dir\$tour\files\scenes\scene_1_a.xml"
        $sceneContent |
        foreach { ($_).replace('<scene name="scene_1_a">',$newScenename) } |
        Out-File -Encoding utf8 "$dir\$tour\files\scenes\scene_1_a.xml"
    }
    # Now add the XML files
    $scenesFolder = Get-ChildItem "$dir\$tour\files\scenes\*.xml"
    Add-ToTourXml $scenesFolder
    Add-Content $tourFile '</krpano>'
    # Duplicate tour.xml as en.xml
    Copy-Item -Path $tourFile -Destination $enFile -Force
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
            '                <li><a href="./ie/index.html" title="Ireland">Ireland</a></li>' # Add Ireland manually
            # Add countries inside <morecountries>
            $morecountries = $configXml.tour.morecountries
            foreach ($newcountry in $morecountries.country) {
                '                <li><a href="./' + $newcountry.dest + '/index.html" title="' + $newcountry.name + '">' + $newcountry.name + '</a></li>' # Add South Africa manually
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

function Add-GforcesCountryIndex ($customtour) {
    Write-Verbose ">> Countries:"
    if (!($customtour)) {
        $tour = $configXml.tour.country
    } else {
        $tour = $customtour
    }
    foreach ($item in $tourArray) {
        $countryId = ($item -split "_")[0]
        $brandId = ($item -split "_")[1]
        foreach ($country in $tour | Where-Object { $_.id -like $countryId } ) {
            if (!($customtour)) {
                $countryFolder = "$dir\brands\$($country.id)"
            } else {
                # Define destcountry variable to use later
                $destcountry = $($country.dest)
                $countryFolder = "$dir\brands\$destcountry"
            }
            if (!(Test-Path "$countryFolder")) {
                New-Item "$countryFolder" -Type Directory | Out-Null
                Write-Debug "     Add folder $countryFolder"
            }

            if (!($customtour)) {
                Get-Content "$dir\.src\html\index_template.html" |
                foreach {
                    if ($_ -match 'ADDCONTENT' ) {
                        '            <h5><a href="../index.html">(Up One Level)</a></h5>'
                        foreach ($brand in $country.brand) {
                            '            <h4><a name="' + $brand.id + '" href="./' + $($brand.id) + '/index.html">' + $brand.name + '</a></h4>'
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
                foreach {($_).replace('./brands/index.html','./grid_more.html')} |
                Set-Content "$countryFolder\index.html"
                Write-Verbose "   > $($country.id)\index.html file"
                # devel.html
                (Get-Content "$countryFolder\index.html") |
                foreach { ($_).replace('</style>','.home-content{background:palegoldenrod;}</style>') } |
                foreach { ($_).replace('index.html','devel.html') } |
                Set-Content "$countryFolder\devel.html"
                Write-Verbose "   > $($country.id)\devel.html file"
            }
            if ($country.id -like 'gb' ) {
                Get-Content "$dir\brands\gb\index.html" |
                foreach {($_).replace('gb_','ie_')} |
                Set-Content "$dir\brands\ie\index.html"
                Write-Verbose "   > ie\index.html file"
            }
            # Do the following block only when the function is callod for more countries
            if ($customtour) {
                # country code origing and country code dest
                $ccorig = $country.id + '_'
                $ccdest = $destcountry + '_'
                Get-Content "$dir\.src\html\index_template.html" |
                foreach {
                    if ($_ -match 'ADDCONTENT' ) {
                        '            <h5><a href="../index.html">(Up One Level)</a></h5>'
                        foreach ($brand in $country.brand) {
                            '            <h4><a name="' + $brand.id + '" href="./' + $($brand.id) + '/index.html">' + $brand.name + '</a></h4>'
                            '            <ul>'
                            foreach ($model in $brand.model) {
                                foreach ($car in $model.car) {
                                    'INSERT' + $brand.id
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
                foreach {($_).replace('./brands/index.html','./grid_more.html')} |
                Set-Content "$countryFolder\index.html"
                Write-Verbose "   > $($destcountry)\index.html file"
                foreach ($brand in $country.brand ) {
                    $ctext = "INSERT" + $brand.id
                    (Get-Content "$countryFolder\index.html") |
                    foreach {
                        if ($_ -match $ctext ) {
                            foreach ($country in $configXml.tour.country | Where-Object { $_.id -like $countryId } ) {
                                foreach ($brand in $country.brand | Where-Object { $_.id -like $brand.id } ) {
                                    foreach ($model in $brand.model) {
                                        foreach ($car in $model.car) {
                                        '                <li><a href="../../' + $car.id + '/index.html" title="' + $car.name + '">'+ $car.id + '</a></li>'
                                        }
                                    }
                                }
                            }
                        } else {
                            $_
                        }
                    } |
                    foreach { ($_).replace("$ccorig","$ccdest") } |
                    Set-Content "$countryFolder\index.html"
                    Write-Verbose "   > $($destcountry)\index.html > $($brand.id)"
                }
            }
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

function Add-GforcesBrandIndex ($customtour) {
    Write-Verbose ">> Brands:"
    if (!($customtour)) {
        $tour = $configXml.tour.country
    } else {
        $tour = $customtour
    }
    foreach ($item in $tourArray) {
        $countryId = ($item -split "_")[0]
        $brandId = ($item -split "_")[1]
        foreach ($country in $tour | where { $_.id -like $countryId } ) {
            foreach ($brand in $country.brand | where { $_.id -like $brandId } ) {
                if (!($customtour)) {
                    $brandFolder = "$dir\brands\$($country.id)\$($brand.id)"
                } else {
                    # Define destcountry variable to use later
                    $destcountry = $($country.dest)
                    $brandFolder = "$dir\brands\$destcountry\$($brand.id)"
                }
                if (!(Test-Path "$brandFolder")) {
                    New-Item "$brandFolder" -Type Directory | Out-Null
                    Write-Debug "     Add folder $brandFolder"
                }
                if ($country.id -like 'gb' ) {
                    if (!(Test-Path "$dir\brands\ie\$($brand.id)")) {
                        New-Item "$dir\brands\ie\$($brand.id)" -Type Directory | Out-Null
                        Write-Debug "     Add folder $dir\brands\ie\$($brand.id)"
                    }
                }
                if (!($customtour)) {
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
                    Write-Verbose "   > $($country.id)\$($brand.id)\index.html file"

                    if ($country.id -like 'gb' ) {
                        Get-Content "$dir\brands\gb\$($brand.id)\index.html" |
                        foreach {($_).replace('gb_','ie_')} |
                        Set-Content "$dir\brands\ie\$($brand.id)\index.html"
                        Write-Verbose "   > ie\$($brand.id)\index.html file"
                    }
                } else {
                # Do the following block only when the function is called for more countries
                    if ($customtour) {
                        Copy-Item -Recurse -Force -Path "$dir\brands\$($country.id)\$($brand.id)" -Destination "$dir\brands\$($country.dest)\"
                        $allModels = Get-ChildItem $brandFolder -Filter "*.html"
                        ForEach ($item in $allModels) {
                            Get-Content $item.FullName |
                            ForEach { ($_).replace("$($country.id)","$($country.dest)") } |
                            Set-Content $item.FullName
                            Write-Verbose "   > $($country.dest)\$($brand.id)\$($item.Name)"
                        }
                        $allCars = Get-ChildItem "$brandFolder" -Directory -Exclude 'content'
                        ForEach ($item2 in $allCars) {
                            $itemPath = Join-Path "$item2" -ChildPath "index.html"
                            Get-Content $itemPath |
                            ForEach { ($_).replace("$($country.id)","$($country.dest)") } |
                            Set-Content $itemPath
                            Write-Verbose "   > $($country.dest)\$($brand.id)\$($item2.BaseName)\index.html"
                        }
                    }
                }
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
                            if ($country.id -like 'gb' ) {
                                if ( !(Test-Path $dir\brands\ie\$($brand.id)\$($model.id)) ) {
                                    New-Item $dir\brands\ie\$($brand.id)\$($model.id) -Type Directory | Out-Null
                                    Write-Debug "     Add folder $dir\brands\ie\$($brand.id)\$($model.id)"
                                }

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
                    if ($country.id -like 'gb' ) {
                        Get-Content "$dir\brands\gb\$($brand.id)\$($model.id)\index.html" |
                        foreach {($_).replace('gb_','ie_')} |
                        Set-Content "$dir\brands\ie\$($brand.id)\$($model.id)\index.html"
                        Write-Verbose "   > ie\$($brand.id)\$($model.id)\index.html"
                    }
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
                    $param2 = $param2 + 170
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
            } |
            foreach { ($_).replace('<div id="logo">','<div id="logo" style="width:375px;margin:0 auto;padding:27px 0 0;float:none;">') } |
            foreach { ($_).replace('logo.gif','logo-net-director.jpg') } |
            Set-Content $brandsfile
            Write-Verbose "   > $($country.id)\grid_brands.html"
            #Write-Debug "     Add file $brandsfile"
            Remove-Item $tempfile -Force
            # Now we need to create grid_more.html, which is the same as grid_brands.html but changing the the links to more_brands.html
            Get-Content $brandsfile |
            foreach { ($_).replace('brand.html','more_brands.html') } |
            foreach { ($_).replace('<div id="logo">','<div id="logo" style="width:375px;margin:0 auto;padding:27px 0 0;float:none;">') } |
            foreach { ($_).replace('logo.gif','logo-net-director.jpg') } |
            Out-File -Encoding utf8 $morebrandsfile
            Write-Verbose "   > $($country.id)\grid_more.html"
            #Write-Debug "     Add file $morebrandsfile"
            if ($country.id -like 'gb' ) {
                Get-Content "$dir\brands\gb\grid_brands.html" |
                foreach {($_).replace('gb_','ie_')} |
                Set-Content "$dir\brands\ie\grid_brands.html"
                Write-Verbose "   > ie\grid_brands.html file"
                Get-Content "$dir\brands\gb\grid_more.html" |
                foreach {($_).replace('gb_','ie_')} |
                Set-Content "$dir\brands\ie\grid_more.html"
                Write-Verbose "   > ie\grid_more.html file"
            }
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
        foreach ($country in $tour | Where-Object { $_.id -like $countryId } ) {
            foreach ($brand in $country.brand | Where-Object { $_.id -like $brandId } ) {
                $firstModel = $brand.model[0].id
                foreach ($model in $brand.model | Where-Object { $_.id -like $firstModel }) {
                    foreach ($car in $model.car | Where-Object { $_.hide -notlike 'y'}) {
                        $first_car = $car.id
                    }
                }
                # Fix when there is only one car and $first_car = null
                if (!$first_car) {
                    $first_car = $brand.model.car.id
                }
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
                Write-Debug "   > $($country.id)\$brand_name\more_brands.html"
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
                foreach { ($_).replace('SERVERNAME','../../..') } |
                foreach { ($_).replace('BRANDNAME',$brand_name) } |
                foreach { ($_).replace('SCENENAME',($first_car + ',null,more')) } |
                foreach { ($_).replace('../../../brands',"../../../brands/$($country.id)") } |
                foreach { ($_).replace('brand.xml','devel_brand.xml') } |
                Out-File -Encoding utf8 $dir\brands\$($country.id)\$brand_name\devel_more_brands.html
                Write-Debug "   > $($country.id)\$brand_name\devel_more_brands.html"
                if ($country.id -like 'gb' ) {
                    Copy-Item "$dir\brands\gb\$brand_name\brand.html" "$dir\brands\ie\$brand_name\brand.html"
                    Write-Verbose "   > ie\$brand_name\brand.html"

                    Copy-Item "$dir\brands\gb\$brand_name\more_brands.html" "$dir\brands\ie\$brand_name\more_brands.html"
                    Write-Debug "   > ie\$brand_name\more_brands.html"

                    Get-Content "$dir\brands\gb\$brand_name\devel_brand.html" |
                    foreach {($_).replace('/gb/','/ie/')} |
                    Set-Content "$dir\brands\ie\$brand_name\devel_brand.html"
                    Write-Debug "   > ie\$brand_name\devel_brand.html"

                    Get-Content "$dir\brands\gb\$brand_name\devel_more_brands.html" |
                    foreach {($_).replace('/gb/','/ie/')} |
                    Set-Content "$dir\brands\ie\$brand_name\devel_more_brands.html"
                    Write-Debug "   > ie\$brand_name\devel_more_brands.html"
                }
            }
        }
    }
}

function Add-GforcesMoreCountriesIndex {
    Write-Verbose "-------------------- More Countries -------------------- "
    $moreconuntries = $configXml.tour.morecountries.country
    Add-GforcesCountryIndex $moreconuntries
    Add-GforcesBrandIndex $moreconuntries
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
                    foreach ($car in $model.car | where { $_.hide -notlike 'y' }) {
                        $y_value = 2 + ($order * 50)
                        $newCarName= $car.name -replace ' - 20.*',''
                        Add-Content $itemsFile ('<layer name    ="container_1_item_' + $car.id + '"')
                        Add-Content $itemsFile ('       html    ="[h1]' + $newCarName + '[/h1]"')
                        Add-Content $itemsFile ('       onclick ="activatepano(' + ($car.id) + ',scenevariation);"')
                        Add-Content $itemsFile ('       style   ="container_1_item_style"')
                        Add-Content $itemsFile ('       y       ="' + $y_value + '"')
                        Add-Content $itemsFile ('       />')
                        $order = $order + 1
                    }
                }
                # Update scroll height after removing some scenes
                Add-Content $itemsFile ('<data name="number_of_scenes">' + $order + '</data>')
                Add-Content $itemsFile ('</krpano>')
                Write-Verbose "   > $($country.id)\$($brand.id)\content\items.xml"
                # Copy the corresponding logo
                Copy-Item "$dir\shared\html_brands\img\logos\$($brand.id).jpg" "$dir\brands\$($country.id)\$($brand.id)\content\thumb.jpg"
            }
            if($country.id = 'gb') {
                if (!(Test-Path "$dir\brands\gb\$($brand.id)\content")) {
                    New-Item -Type directory "$dir\brands\gb\$($brand.id)\content" -Force | Out-Null
                }
                Get-Content "$dir\brands\gb\$($brand.id)\content\items.xml" |
                foreach {($_).replace('gb_','ie_')} |
                Set-Content "$dir\brands\ie\$($brand.id)\items.xml"
                Write-Verbose "   > ie\$($brand.id)\content\items.xml"
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
                        if ($ignoreArray -notcontains $car.id) {
                            Add-Content $develFile ('    <include url="%SWFPATH%/../' + $(Get-Item $dir\$($car.id)).BaseName + '/files/content/index.xml" />')
                        }
                    }
                }
                Add-Content $develFile '    <!-- Include -->'
                $includefolder = dir "$dir\shared\include_brand\"  |
                foreach { Add-Content $develFile ('    <include url="%SWFPATH%/include_brand/' + $_.BaseName + '/index.xml" />') }
                Add-Content $develFile '    <!-- Scenes -->'
                foreach ($model in $brand.model) {
                    foreach ($car in $model.car) {
                        if ($ignoreArray -notcontains $car.id) {
                            Add-Content $develFile ('    <include url="%SWFPATH%/../' + $(Get-Item $dir\$($car.id)).BaseName + '/files/scenes/scene.xml" />')
                        }
                    }
                }
                Add-Content $develFile '</krpano>'
                Write-Verbose "   > $($country.id)\$($brand.id)\devel_brand.xml"
                if ($country.id = 'gb') {
                    Get-Content "$dir\brands\gb\$($brand.id)\devel_brand.xml" |
                    foreach {($_).replace('gb_','ie_')} |
                    Set-Content "$dir\brands\ie\$($brand.id)\devel_brand.xml"
                    Write-Verbose "   > ie\$($brand.id)\devel_brand.xml"
                }
            }
        }
    }
}

function Add-GforcesBrandXml {
    $tour = $configXml.tour.country
    if ($ignoreArray -notcontains $tourArray) {
        foreach ($item in $tourArray) {
            $countryId = ($item -split "_")[0]
            $brandId = ($item -split "_")[1]
            foreach ($country in $tour | where { $_.id -like $countryId } ) {
                foreach ($brand in $country.brand | where { $_.id -like $brandId } ) {
                    $tourFile = "$dir\brands\$($country.id)\$($brand.id)\brand.xml"
                    # Variable country code is used by the function Add-ToTourXml
                    $countrycode = $countryId
                    New-Item -ItemType File $tourFile -Force | Out-Null
                    Add-Content $tourFile '<?xml version="1.0" encoding="UTF-8"?>'
                    Add-Content $tourFile ('<krpano version="' + $krver + '">')
                    Add-Content $tourFile '<krpano logkey="true" />'
                    # Add 'items.xml' file inside 'brands' directory
                    $contentFolder = Get-Item "$dir\brands\$($country.id)\$($brand.id)\content\items.xml"
                    Add-ToTourXml $contentFolder
                    # Add 'content/index.xml' file inside each car belonging to the same brand
                    if ($countryId -like "ae") {
                    $exclude = $ignoredCarsArray
                    } else {
                    $exclude = $ignoreArray
                    }
                    foreach ($model in $brand.model) {
                        foreach ($car in $model.car) {
                            if ($exclude -notcontains $car.id) {
                                #Add-Content $develFile ('    <include url="%SWFPATH%/../' + $(Get-Item $dir\$($car.id)).BaseName + '/files/content/index.xml" />')
                                $contentFolder = Get-Item "$dir\$($car.id)\files\content\index.xml"
                                Add-ToTourXml $contentFolder
                            }
                        }
                    }
                    # Add XML files inside 'include' folder
                    $includeFolder = Get-ChildItem "$dir\shared\include_brand\*\*.xml" -Exclude coordfinder, editor_and_options
                    Add-ToTourXml $includeFolder
                    # Add 'scene.xml' file inside each car belonging to the same brand
                    foreach ($model in $brand.model) {
                        foreach ($car in $model.car) {
                            if ($exclude -notcontains $car.id) {
                                if(Test-Path $dir\$($car.id)\files\scenes\scene.xml) {
                                    $scenesFolder = Get-Item "$dir\$($car.id)\files\scenes\scene.xml"
                                }
                                else
                                {
                                    $scenesFolder = Get-Item "$dir\$($car.id)\files\scenes\scene_*.xml"
                                }
                                Add-ToTourXml $scenesFolder
                            }
                        }
                    }
                    Add-Content $tourFile '</krpano>'
                    Write-Verbose "   > $($country.id)\$($brand.id)\brand.xml"
                }
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
            # Copy btn_#.jpg images if there is any
            if ( Get-ChildItem $dir\$carID\files\btn*.jpg ) {
                Copy-Item $dir\$carID\files\btn_*.jpg $dir\$carRenameTo\files\
            }
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

function Duplicate-GforcesCars {
    $duplicateItems = $configXml.tour.duplicate.country
    $tour = $configXml.tour.country
    if ($ignoreArray -notcontains $tourArray) {
        [Array]$duplicateArray = $null
        foreach ($item in $tourIDArray) {
            $countryId = ($item -split "_")[0]
            $brandId = ($item -split "_")[1]
            foreach ($country_duplicate in $duplicateItems | where { $_.id -like $countryId } ) {
                foreach ($brand_duplicate in $country_duplicate.brand | where { $_.id -like $brandId -or $_.id -like 'all' } ) {
                    $dest = $brand_duplicate.dest
                    $countrycode = ($item -split "_")[0]
                    $brand = ($item -split "_")[1]
                    $model = ($item -split "_")[2]
                    $deriv = ($item -split "_")[3]
                    $car_origin = $countrycode + '_' + $brand + '_' + $model + '_' + $deriv
                    $car_duplicate = $dest + '_' + $brand + '_' + $model + '_' + $deriv
                    if (!(Test-Path "$dir\$car_duplicate")) {
                        New-Item "$dir\$car_duplicate" -Type Directory | Out-Null
                    }
                    # index.html for OEM cars are done manually to point all URLs to the manufacturers folder
                    # Hence, don't override that file
                    if ($ignoreArray -notcontains $car_origin) {
                        if ( Test-Path $dir\$car_duplicate\index.html ) {
                            Remove-Item $dir\$car_duplicate\index.html -Force
                        }
                        $template_content = Get-Content $dir\.src\html\scene_template.html
                        $template_content |
                        foreach { ($_).replace('SERVERNAME',$configXML.tour.url) } |
                        foreach { ($_).replace('SCENENAME',$item) } |
                        Out-File -Encoding utf8 $dir\$car_duplicate\index.html
                    }
                    # Add content\index.xml
                    if (!(Test-Path "$dir\$car_duplicate\files")) {
                        New-Item "$dir\$car_duplicate\files" -Type Director | Out-Null
                    }
                    if (!(Test-Path "$dir\$car_duplicate\files\content")) {
                        New-Item "$dir\$car_duplicate\files\content" -Type Directory | Out-Null
                    }
                    $origin_content = Get-Content $dir\$car_origin\files\content\index.xml
                    $origin_content |
                    Out-File -Encoding utf8  $dir\$car_duplicate\files\content\index.xml -Force
                    # Add scenes\scene.xml
                    if (!(Test-Path "$dir\$car_duplicate\files\scenes")) {
                        New-Item "$dir\$car_duplicate\files\scenes" -Type Directory | Out-Null
                    }
                    if(Test-Path $dir\$car_origin\files\scenes\scene.xml) {
                        $origin_scene = Get-Content $dir\$car_origin\files\scenes\scene.xml
                        $origin_scene |
                        foreach { ($_).replace('name="' + $countrycode + '_', 'name="' + $dest + '_') } |
                        Out-File -Encoding utf8  $dir\$car_duplicate\files\scenes\scene.xml -Force
                    }
                    else
                    {
                        $origin_scene = Get-Content $dir\$car_origin\files\scenes\scene*.xml
                        $out_file = "$dir\$car_duplicate\files\scenes\scene.xml"
                        New-Item -ItemType File $out_file -Force | Out-Null
                        Add-Content $out_file ('<krpano>')
                        $origin_scene |
                        add-content $out_file
                        Add-Content $out_file ('</krpano>')
                    }
                    # Add files/en.xml
                    if(Test-Path $dir\$car_origin\files\tour.xml) {
                        Copy-Item -Path $dir\$car_origin\files\tour.xml -Destination $dir\$car_duplicate\files\en.xml -Force
                    }
                    # Duplicate seat variation buttons
                    if ( Get-ChildItem $dir\$car_origin\files\btn*.jpg ) {
                        Copy-Item $dir\$car_origin\files\btn_*.jpg $dir\$car_duplicate\files\
                    }
                    # Create an Array to print the items afterwards
                    $duplicateInfo = ">> $car_origin > $car_duplicate"
                    [Array]$duplicateArray += $duplicateInfo
                }
            }
        }
        Write-Verbose "--------------------Cars For Other Countries --------------------"
        foreach ($duplicatedCar in $duplicateArray) {
            Write-Warning $duplicatedCar
        }
    }
}
