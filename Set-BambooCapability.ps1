function Set-BambooCapability {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidatePattern('^[^=]+$')]
        [string]$Key,

        [Parameter(Mandatory)]
        [string]$Value,

        [Parameter(Mandatory)]
        [string]$Path
    )

    process {
        if (-Not (Test-Path $Path)) {
            # Create file with the new capability if it doesn't exist
            "$Key=$Value" | Set-Content -Path $Path
            return
        }

        $newLine = [Environment]::NewLine

        $lines = Get-Content -Path $Path
        if ( $lines.Count -eq 1) { 
            $lines += $newLine
        }
        $found = $false

        $updatedLines = $lines | ForEach-Object {
            if ("$_".StartsWith("$Key=")) {
                $found = $true
                Write-Verbose "Found key '$Key', updating value."
                "$Key=$Value"
            } else {
                Write-Debug "Key '$Key' not found, keeping line."
                $_
            }
        }

        if (-not $found) {
            Write-Verbose "Key '$Key' not found, adding new capability."
            $updatedLines += "$Key=$Value" 
        }

        $updatedLines | Set-Content -Path $Path 
    }
}