﻿Function New-WinSCPItem {
    [OutputType([WinSCP.RemoteFileInfo])]
    
    Param (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [ValidateScript({ 
            if ($_.Opened) { 
                return $true 
            } else { 
                throw 'The WinSCP Session is not in an Open state.'
            }
        })]
        [WinSCP.Session]
        $WinSCPSession,

        [Parameter(
            ValueFromPipelineByPropertyName = $true
        )]
        [String[]]
        $Path = '/',

        [Parameter(
            ValueFromPipelineByPropertyName = $true
        )]
        [String]
        $Name = $null,

        [Parameter()]
        [String]
        $ItemType = 'File',

        [Parameter()]
        [String]
        $Value = $null
    )

    Begin {
        $sessionValueFromPipeLine = $PSBoundParameters.ContainsKey('WinSCPSession')
    }

    Process {
        foreach($p in (Format-WinSCPPathString -Path $($Path))) {
            if (-not ($PSBoundParameters.ContainsKey('Name'))) {
                $Name = Split-Path -Path $p -Leaf
                $p = Format-WinSCPPathString -Path (Split-Path -Path $p -Parent)
            }

            try {
                $newItemParams = @{
                    Path = $env:TEMP
                    Name = $Name
                    ItemType = $ItemType
                    Value = $Value
                    Force = $true
                }

                $resutls = $WinSCPSession.PutFiles((New-Item @newItemParams).FullName, $p, $true)

                if ($resutls.Transfers -ne $null) {
                    Get-WinSCPItem -WinSCPSession $WinSCPSession -Path $resutls.Transfers.Destination
                } else {
                    Get-WinSCPItem -WinSCPSession $WinSCPSession -Path (Format-WinSCPPathString -Path (Join-Path -Path $p -ChildPath $Name))
                }
            } catch {
                Write-Error -Message $_.ToString()
            }
        }
    }

    End {
        if (-not ($sessionValueFromPipeLine)) {
            Remove-WinSCPSession -WinSCPSession $WinSCPSession
        }
    }
}