function Set-BambooCapability {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
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

        $lines = Get-Content -Path $Path
        $found = $false

        $updatedLines = $lines | ForEach-Object {
            Write-Debug ("Processing line: $_")
            if ("$_".StartsWith("$Key=")) {
                $found = $true
                Write-Debug ' - Found existing key, updating value.'
                "$Key=$Value"
            } else {
                Write-Debug " - Key '$Key' not found, keeping line."
                $_
            }
        }

        if (-not $found) {
            Write-Debug " - Key '$Key' not found, adding new capability."
            $updatedLines += "$Key=$Value"
        }

        $updatedLines | Set-Content -Path $Path
    }
}