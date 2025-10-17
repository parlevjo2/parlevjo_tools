<#
Start-BitsTransfer -Source "http://go.microsoft.com/fwlink/?linkid=74689" -Destination "$env:ProgramData\WSUS Offline Catalog\wsusscn2.cab"
(Get-FileHash "$env:ProgramData\WSUS Offline Catalog\wsusscn2.cab").Hash

$VerbosePreference="Continue"
cd "$env:ProgramData\WSUS Offline Catalog"
$wsus_offline_catalog_filehash=(Get-FileHash "wsusscn2.cab").Hash
.\Get-MissingUpdates.ps1 -Wsusscn2Url "http://go.microsoft.com/fwlink/?linkid=74689" -FileHash $wsus_offline_catalog_filehash
#>

Param(
    [parameter(mandatory)]
    [string]$FileHash,

    [parameter(mandatory)]
    [string]$Wsusscn2Url
)


Function Get-Hash($Path){

    $Stream = New-Object System.IO.FileStream($Path,[System.IO.FileMode]::Open)

    $StringBuilder = New-Object System.Text.StringBuilder
    $HashCreate = [System.Security.Cryptography.HashAlgorithm]::Create("SHA256").ComputeHash($Stream)
    $HashCreate | Foreach {
        $StringBuilder.Append($_.ToString("x2")) | Out-Null
    }
    $Stream.Close()
    $StringBuilder.ToString()
}

$DataFolder = "$env:ProgramData\WSUS Offline Catalog"
$CabPath = "$DataFolder\wsusscn2.cab"

# Create download dir
mkdir $DataFolder -Force | Out-Null

# Check if cab exists
$CabExists = Test-Path $CabPath

$HashMatch=$false

# Compare hashes if download is needed
if($CabExists){
    Write-Verbose "Comparing hashes of wsusscn2.cab"

    $HashMatch = $FileHash -eq (Get-Hash -Path $CabPath)

    if(!$HashMatch){
        Write-Warning "Filehash of $CabPath did not match $($FileHash) - downloading"
        Remove-Item $CabPath -Force
    }
    Else{
        Write-Verbose "Hashes matched $HashMatch"
    }
}

Write-Verbose "Hashes matched $HashMatch"
$CabExists = Test-Path $CabPath

# Download wsus2scn.cab if it doesn't exist or hashes mismatch
if(!$CabExists -or $HashMatch -eq $false){
    Write-Verbose "Downloading wsusscn2.cab"
    # Works on Windows Server 2008 as well
    (New-Object System.Net.WebClient).DownloadFile($Wsusscn2Url, $CabPath)

    if($FileHash -ne (Get-Hash -Path $CabPath)){
        Throw "$CabPath did not match $($FileHash)"
    }

}

# Date of wsusscn2.cab should be not older than 31 days
If (((Get-Item $CabPath).LastWriteTime) -le (Get-Date).AddDays(-31)) {
        Throw "$CabPath is older than 31 days: $((Get-Item $CabPath).LastWriteTime))"
}

Write-Verbose "Checking digital signature of wsusscn2.cab"

$CertificateIssuer = "CN=Microsoft Code Signing PCA 2011, O=Microsoft Corporation, L=Redmond, S=Washington, C=US"
$Signature = Get-AuthenticodeSignature -FilePath $CabPath
$SignatureOk = $Signature.SignerCertificate.Issuer -eq $CertificateIssuer -and $Signature.Status -eq "Valid"


If(!$SignatureOk){
    Throw "Signature of wsusscn2.cab is invalid!"
}


Write-Verbose "Creating Windows Update session"
$UpdateSession = New-Object -ComObject Microsoft.Update.Session
$UpdateServiceManager  = New-Object -ComObject Microsoft.Update.ServiceManager

$UpdateService = $UpdateServiceManager.AddScanPackageService("Offline Sync Service", $CabPath, 1)

Write-Verbose "Creating Windows Update Searcher"
$UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
$UpdateSearcher.ServerSelection = 3
$UpdateSearcher.ServiceID = $UpdateService.ServiceID.ToString()

Write-Verbose "Searching for missing updates"
$SearchResult = $UpdateSearcher.Search("IsInstalled=0")

$Updates = $SearchResult.Updates

$UpdateSummary = [PSCustomObject]@{

    ComputerName = $env:COMPUTERNAME
    MissingUpdatesCount = $Updates.Count
    Vulnerabilities = $Updates | Foreach {
        $_.CveIDs
    }
    MissingUpdates = $Updates | Select Title, MsrcSeverity, @{Name="KBArticleIDs";Expression={$_.KBArticleIDs}}
}

Return $UpdateSummary
