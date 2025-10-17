<#
Powershell

if ( ! ( Test-Path -Path "C:\Temp" ) ) { New-Item -Path "C:\Temp" -ItemType Directory }

# Script URL en lokale pad
$scriptUrl = "https://raw.githubusercontent.com/parlevjo2/parlevjo_tools/refs/heads/main/FindAllServersWithSQL standalone computer.ps1"
$localPath = "c:\temp\FindAllServersWithSQL standalone computer.ps1"

# Download het script
Invoke-WebRequest -Uri $scriptUrl -OutFile $localPath

cd C:\temp
.\FindAllServersWithSQL standalone computer.ps1 $((Get-ADDomain).DNSRoot)
hostname
start .

Remove-Item $localPath

#>

            $InstanceNameskey = "SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names"

            $MSSQLkey = "SOFTWARE\Microsoft\Microsoft SQL Server"

            $type = [Microsoft.Win32.RegistryHive]::LocalMachine

            $regKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($type, $Server)

            $SQLServerkey = $null

            $SQLServerkey = $regKey.OpenSubKey($MSSQLkey)

            # Check to see if MS SQL Server is installed

            IF ($SQLServerkey)             {#Begin IF $SQLSERVERKEY

		"Server, Instance, Version, Edition"

                #DEBUG Write to Host "Sub Keys"

                #Write-Host

                #Write-Host "Sub Keys for $MSSQLkey"

                #Write-Host "---"

                #Foreach($sbky in $SQLServerkey.GetSubKeyNames()){$sbky}

                $Instkey = $null

                $Instkey = $regKey.OpenSubKey($InstanceNameskey)

                # Check to see in chargeable Instances of MS SQL Server are installed

                IF ($Instkey)

                {

                    #DEBUG Write-Host "Values" of SubKeys

                    #Write-Host

                    #Write-Host "Sub Keys for $InstanceNameskey"

                    #Write-Host "--"

                    #Foreach($sub in $Instkey.GetSubKeyNames()){$sub}

                    foreach ($regInstance in $Instkey.GetSubKeyNames())

                    {

                        $RegInstNameKey = $null

                        $SetupKey = $null

                        $SetupKey = "$InstanceNameskey\$regInstance"

                        $RegInstNameKey = $regKey.OpenSubKey($SetupKey)

                        #Open Instance Names Key and get all SQL Instances

                        foreach ($SetupInstance in $RegInstNameKey.GetValueNames())

                        {

                            $version = $null

                            $edition = $null

                            $regInstanceData = $null

                            $SetupVersionKey = $null

                            $VersionInfo = $null

                            $versionKey = $null

                            $regInstanceData = $RegInstNameKey.GetValue($SetupInstance)

                            $SetupVersionKey = "$MSSQLkey\$regInstanceData\Setup"

                            #Open the SQL Instance Setup Key and get the version and edition

                            $versionKey = $regKey.OpenSubKey($SetupVersionKey)

                            $version = $versionKey.GetValue('PatchLevel')

                            $edition = $versionKey.GetValue('Edition')

                            # Write the version and edition info to output file

                            $VersionInfo = $ENV:COMPUTERNAME + ',' + $regInstanceData + ',' + $version + ',' + $edition

                            $versionInfo

                        }#end foreach $SetupInstance

                    }#end foreach $regInstance

                }#end If $instKey

            }#end If $SQLServerKey
