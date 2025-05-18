function Get-BambooCapabilities {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$Path,
        [string]$WhereKeyStartsWith = ''
    )

    process {
        if (-not (Test-Path $Path)) {
            Write-Error "File not found: $Path"
            return
        }

        $capabilities = @()

        $lines = Get-Content -Path $Path | Where-Object { $_ -and ($_ -notmatch '^\s*#') }
        foreach ($line in $lines) {
            if ($line -match '^\s*([^=]+?)\s*=\s*(.*)$') {
                $capabilities += [PSCustomObject]@{
                    Key   = $matches[1].Trim()
                    Value = $matches[2].Trim()
                }
            }
        }
        
        if ($WhereKeyStartsWith) {
            $capabilities = $capabilities | Where-Object { $_.Key -like "$WhereKeyStartsWith*" }
        }
    }
    end {
        return $capabilities    
    }
}