﻿Function New-WinSCPSession {
    [OutputType([WinSCP.Session])]
    
    Param (
        [Parameter(
            ValueFromPipeline = $true
        )]
        [PSCredential]
        $Credential = (Get-Credential),

        [Parameter()]
        [WinSCP.FtpMode]
        $FtpMode = (New-Object -TypeName WinSCP.FtpMode),

        [Parameter()]
        [WinSCP.FtpSecure]
        $FtpSecure = (New-Object -TypeName WinSCP.FtpSecure),
        
        [Parameter()]
        [Switch]
        $GiveUpSecurityAndAcceptAnySshHostKey,

        [Parameter()]
        [Switch]
        $GiveUpSecureityAndAcceptAnyTlsHostCertificate,

        [Parameter(
            Mandatory = $true
        )]
        [String]
        $HostName = $null,

        [Parameter()]
        [Int]
        $PortNumber = 0,

        [Parameter()]
        [WinSCP.Protocol]
        $Protocol = (New-Object -TypeName WinSCP.Protocol),

        [Parameter(
            ValueFromPipelineByPropertyName = $true
        )]
        [String[]]
        $SshHostKeyFingerprint = $null,

        [Parameter()]
        [ValidateScript({ 
            if (Test-Path -Path $_) { 
                return $true 
            } else { 
                throw "$_ not found." 
            } 
        })]
        [String]
        $SshPrivateKeyPath = $null,

        [Parameter()]
        [SecureString]
        $SshPrivateKeySecurePassphrase = $null,

        [Parameter()]
        [String]
        $TlsHostCertificateFingerprint = $null,

        [Parameter()]
        [TimeSpan]
        $Timeout = (New-TimeSpan -Seconds 15),

        [Parameter()]
        [Switch]
        $WebdavSecure,

        [Parameter()]
        [String]
        $WebdavRoot = $null,
        
        [Parameter()]
        [HashTable]
        $RawSetting = $null,

        [Parameter()]
        [ValidateScript({
            if (Test-Path -Path (Split-Path -Path $_)) {
                return $true
            } else {
                throw "Path not found $(Split-Path -Path $_)."
            } 
        })]
        [String]
        $DebugLogPath = $null,

        [Parameter()]
        [ValidateScript({
            if (Test-Path -Path (Split-Path -Path $_)) {
                return $true
            } else {
                throw "Path not found $(Split-Path -Path $_)."
            } 
        })]
        [String]
        $SessionLogPath = $null,

        [Parameter()]
        [TimeSpan]
        $ReconnectTime = (New-TimeSpan -Seconds 120),

        [Parameter()]
        [ScriptBlock]
        $FileTransferProgress = $null
    )

    # Create WinSCP.Session and WinSCP.SessionOptions Objects, parameter values will be assigned to matching object properties.
    $sessionOptions = New-Object -TypeName WinSCP.SessionOptions
    $session = New-Object -TypeName WinSCP.Session

    # Convert PSCredential Object to match names of the WinSCP.SessionOptions Object.
    $PSBoundParameters.Add('UserName', $Credential.UserName)
    $PSBoundParameters.Add('SecurePassword', $Credential.Password)

    # Convert SshPrivateKeySecurePasspahrase to plain text and set it to the corresponding SessionOptions property.
    if ($SshPrivateKeySecurePassphrase -ne $null) {
        $sessionOptions.SshPrivateKeyPassphrase = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SshPrivateKeySecurePassphrase))
    }

    try {
        # Enumerate each parameter.
        foreach ($key in $PSBoundParameters.Keys) {
            # If the property is a member of the WinSCP.SessionOptions object, set the matching value.
            if (($sessionOptions | Get-Member -MemberType Properties).Name -contains $key) {
                $sessionOptions.$key = $PSBoundParameters.$key
            }
            # If the property is a member of the WinSCP.Session object, set the matching value.
            elseif (($session | Get-Member -MemberType Properties).Name -contains $key) {
                $session.$key = $PSBoundParameters.$key
            }
        }

        # Enumerate raw settings and add the options to the WinSCP.SessionOptions object.
        foreach ($key in $RawSetting.Keys) {
            $sessionOptions.AddRawSettings($key, $RawSetting[$key])
        }
    } catch {
        Write-Error -Message $_.ToString()
    }

    try {
        if ($FileTransferProgress -ne $null) {
            $session.Add_FileTransferProgress($FileTransferProgress)
        }

        # Open the WinSCP.Session object using the WinSCP.SessionOptions object.
        $session.Open($sessionOptions)

        # Return the WinSCP.Session object.
        return $session
    } catch {
        Write-Error -Message $_.ToString()
    }
}