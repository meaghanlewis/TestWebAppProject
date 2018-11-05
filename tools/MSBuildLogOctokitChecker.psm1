
function  Send-MsbuildLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Path,
        [ValidateNotNullOrEmpty()]
        [string] $Token,
        [ValidateNotNullOrEmpty()]
        [string] $CloneRoot,
        [ValidateNotNullOrEmpty()]
        [Alias('Sha', 'CommitHash')]
        [string] $HeadCommit
    )

    If(-not [System.IO.Path]::IsPathRooted($Path)) {
        $Path = [System.IO.Path]::Combine($PWD, $Path);
    }

    #TODO: Stream this
    $FileBytes = [System.IO.File]::ReadAllBytes($Path);
    $FileEnc = [System.Text.Encoding]::GetEncoding("ISO-8859-1").GetString($FileBytes);
    $FileInfo = New-Object System.IO.FileInfo @($Path)
    $Boundary = [System.Guid]::NewGuid().ToString();
    $LF = "`r`n";
    $Body = @(
        "--$Boundary",
        "Content-Disposition: form-data; name=`"CommitSha`"$LF",
        $HeadCommit,
        "--$Boundary",
        "Content-Disposition: form-data; name=`"CloneRoot`"$LF",
        $CloneRoot
        "--$Boundary",
        "Content-Disposition: form-data; name=`"BinaryLogFile`"; filename=`"$($FileInfo.Name)`"",
        "Content-Type: application/octet-stream$LF",
        $FileEnc,
        "--$Boundary--$LF"
    ) -join $LF

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization", "Bearer $Token")
    $headers.Add("Accept", "application/json")

    $Uri = GetUploadUrl

    $ProxyUri = [Uri]$null
    $Proxy = [System.Net.WebRequest]::GetSystemWebProxy()
    if ($Proxy) {
        $Proxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials
        $ProxyUri = $Proxy.GetProxy("$Uri")
    }

    if ($ProxyUri -ne $Uri){
        Invoke-RestMethod `
            -Method POST `
            -Uri $Uri `
            -ContentType "multipart/form-data; boundary=$Boundary" `
            -Body $Body `
            -Headers $Headers `
            -Proxy $ProxyUri `
            -ProxyUseDefaultCredentials
    }
    else {
        Invoke-RestMethod `
            -Method POST `
            -Uri $Uri `
            -ContentType "multipart/form-data; boundary=$Boundary" `
            -Body $Body `
            -Headers $Headers
    }
}

function  Send-MsbuildLogAppveyor {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Path,
        [ValidateNotNullOrEmpty()]
        [string] $Token
    )

    $CloneRoot = $env:APPVEYOR_BUILD_FOLDER
    $HeadCommit = $env:APPVEYOR_REPO_COMMIT

    Send-MsbuildLog $Path $Token $CloneRoot $HeadCommit
}

# Export only the functions using PowerShell standard verb-noun naming.
# Be sure to list each exported functions in the FunctionsToExport field of the module manifest file.
# This improves performance of command discovery in PowerShell.
Export-ModuleMember -Function '*-*'

# "Private" methods
function GetUploadUrl() {
    [CmdletBinding()]
    [OutputType([String])]
    param (
    )
    $BaseUrl = If($env:MSBLOC_POSH_URL) {$env:MSBLOC_POSH_URL} else {'https://msblocweb.azurewebsites.net'}
    $FullUrl = '{0}/api/log/upload' -f $BaseUrl
    Write-Verbose "Upload Url: $FullUrl"
    return $FullUrl
}
