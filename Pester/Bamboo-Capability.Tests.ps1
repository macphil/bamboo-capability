# bamboo-capability.tests.ps1
Describe 'Test creating a file with random key-value lines' {
    BeforeAll {
        # Load the function to be tested
        . (Join-Path $PSScriptRoot '..' 'Get-BambooCapabilities.ps1')
        . (Join-Path $PSScriptRoot '..' 'Set-BambooCapability.ps1')
        function New-RandomKeyFile {
            param($path, $numLines = 5)
            $lines = for ($i = 1; $i -le $numLines; $i++) {
                $key = "key$([System.Guid]::NewGuid().ToString('N').Substring(0,8))"
                $value = "value$([System.Guid]::NewGuid().ToString('N').Substring(0,8))"
                "$key=$value"
            }
            Set-Content -Path $path -Value $lines
            # Write-Host "File created at $path with $numLines lines."
        }

        $tempPath = [System.IO.Path]::GetTempPath()
        $multipleTestFile = Join-Path $tempPath 'bamboo-capabilities.example_multiple.properties'
        Set-Content -Path $multipleTestFile -Value '# test file'         

    }

    AfterAll {
        # Cleanup
        Get-Content $multipleTestFile | Write-Host -ForegroundColor Green        
        Remove-Item $multipleTestFile -Force
    }

    It 'Creates a test file with random key-value pairs in the temp folder' {
        # Arrange
        $tempPath = [System.IO.Path]::GetTempPath()
        $testFile = Join-Path $tempPath ('bamboo-capabilities.testfile_{0}.properties' -f ([guid]::NewGuid()))

        New-RandomKeyFile -Path $testFile

        # Assert file exists
        Test-Path $testFile | Should -BeTrue

        # Assert file has correct number of lines and format
        $content = Get-Content $testFile
        $content.Count | Should -Be 5
        foreach ($line in $content) {
            $line | Should -Match '^[^=]+=[^=]+$'
        }

        # Cleanup
        Remove-Item $testFile -Force
    }

    It 'Handles empty lines and comments correctly' {
        # Arrange
        $tempPath = [System.IO.Path]::GetTempPath()
        $testFile = Join-Path $tempPath ('bamboo-capabilities.testfile_{0}.properties' -f ([guid]::NewGuid()))

        # Create a test file with empty lines and comments
        $lines = @(
            'key1=value1'
            ''
            '# This is a comment'
            'key2=value2'
            '  '
            'key3=value3'
        )
        Set-Content -Path $testFile -Value $lines

        # Act
        $content = Get-BambooCapabilities -Path $testFile

        # Assert file has correct number of lines and format
        $content.Count | Should -Be 3
        $content[0].Key | Should -Be 'key1'
        $content[0].Value | Should -Be 'value1'
        $content[1].Key | Should -Be 'key2'
        $content[1].Value | Should -Be 'value2'
        $content[2].Key | Should -Be 'key3'
        $content[2].Value | Should -Be 'value3'
        # Assert that comments and empty lines are ignored
        $content | Where-Object { $_.Key -eq '' } | Should -BeNull
        $content | Where-Object { $_.Key -eq '# This is a comment' } | Should -BeNull
        $content | Where-Object { $_.Key -eq '  ' } | Should -BeNull
        # Cleanup
        Remove-Item $testFile -Force
    }
    It 'Handles file correctly' {

        # Arrange
        $tempPath = [System.IO.Path]::GetTempPath()
        $testFile = Join-Path $tempPath ('bamboo-capabilities.example_{0}.properties' -f ([guid]::NewGuid()))

        # Example properties based on Atlassian documentation
        $lines = @(
            'system.jdk.JDK_1_8=/Library/Java/JavaVirtualMachines/jdk1.8.0_202.jdk/Contents/Home'
            'system.jdk.JDK\ 17=/opt/java/openjdk17/bin/java'
            'system.jdk.JDK\ 1.6=C:\\Program Files\\Java\\jdk6.0.17'
            'system.git.executable=/usr/bin/git'
            'system.docker.executable=/usr/local/bin/docker'
            'system.maven.Maven_3_6=/usr/local/apache-maven-3.6.3'
            'custom.capability.example=exampleValue'
            'foo=bar'
        )
        Set-Content -Path $testFile -Value $lines

        # Act
        $content = Get-BambooCapabilities -Path $testFile

        # Assert
        $content.Count | Should -Be 8
        $content | Where-Object { $_.Key -eq 'system.jdk.JDK_1_8' } | Should -Not -BeNullOrEmpty
        $content | Where-Object { $_.Key -eq 'system.git.executable' } | Should -Not -BeNullOrEmpty
        $content | Where-Object { $_.Key -eq 'system.docker.executable' } | Should -Not -BeNullOrEmpty
        $content | Where-Object { $_.Key -eq 'system.maven.Maven_3_6' } | Should -Not -BeNullOrEmpty
        $content | Where-Object { $_.Key -eq 'custom.capability.example' } | Should -Not -BeNullOrEmpty

        # Cleanup
        Remove-Item $testFile -Force
    }

    It 'Handles WhereKeyStartsWith correctly' {

        # Arrange
        $tempPath = [System.IO.Path]::GetTempPath()
        $testFile = Join-Path $tempPath ('bamboo-capabilities.example_{0}.properties' -f ([guid]::NewGuid()))

        # Example properties based on Atlassian documentation
        $lines = @(
            'system.jdk.JDK_1_8=/Library/Java/JavaVirtualMachines/jdk1.8.0_202.jdk/Contents/Home'
            'system.jdk.JDK\ 17=/opt/java/openjdk17/bin/java'
            'system.jdk.JDK\ 1.6=C:\\Program Files\\Java\\jdk6.0.17'
            'system.git.executable=/usr/bin/git'
            'system.docker.executable=/usr/local/bin/docker'
            'system.maven.Maven_3_6=/usr/local/apache-maven-3.6.3'
            'custom.capability.example=exampleValue'
            'foo=bar'
        )
        Set-Content -Path $testFile -Value $lines

        # Act
        $content = Get-BambooCapabilities -Path $testFile -WhereKeyStartsWith 'system.jdk.JDK\ 1.6'

        # Assert
        $content.Count | Should -Be 1
        $content.Key | Should -Be 'system.jdk.JDK\ 1.6'
        $content.Value | Should -Be 'C:\\Program Files\\Java\\jdk6.0.17'

        # Cleanup
        Remove-Item $testFile -Force
    }

    It 'Handles Update correctly' {

        # Arrange
        $tempPath = [System.IO.Path]::GetTempPath()
        $testFile = Join-Path $tempPath ('bamboo-capabilities.example_{0}.properties' -f ([guid]::NewGuid()))

        $keyToUpdate = 'system.jdk.JDK\ 1.6'
        $newValue = 'C:\\Program Files\\Java\\jdk6.0.25'
        $keyToAdd = 'system.jdk.JDK\ 25'
        $newValueToAdd = 'C:\\Program Files\\Java\\jdk25'

        # Example properties based on Atlassian documentation
        $lines = @(
            '# comment'
            'system.jdk.JDK\ 17=/opt/java/openjdk17/bin/java'
            "$keyToUpdate=C:\\Program Files\\Java\\jdk6.0.17"
            'system.git.executable=/usr/bin/git'
            'system.docker.executable=/usr/local/bin/docker'
            'system.maven.Maven_3_6=/usr/local/apache-maven-3.6.3'
            'custom.capability.example=exampleValue'
        )
        Set-Content -Path $testFile -Value $lines

        # Act
        $setBambooParams = @{
            Path    = $testFile
            Debug   = $false
            Verbose = $true
        }

        Set-BambooCapability @setBambooParams -Key $keyToUpdate -Value $newValue
        Set-BambooCapability @setBambooParams -Key $keyToAdd -Value $newValueToAdd

        $content = Get-BambooCapabilities -Path $testFile
        # Assert
        $content | Where-Object { $_.Key -eq $keyToUpdate } | Select-Object -ExpandProperty Value | Should -Be $newValue
        $content | Where-Object { $_.Key -eq $keyToAdd } | Select-Object -ExpandProperty Value | Should -Be $newValueToAdd
        $content.Count | Should -Be 7

        # Cleanup
        Remove-Item $testFile -Force
    }
    
    It "Handles '<ArrangedKey>' correctly" -ForEach @(
        @(
            @{ ArrangedKey = 'key.with.dot' ; InitialValue = 'init-dot-{0}' -f [guid]::NewGuid() ; UpdatedValue = 'upd-dot-{0}' -f [guid]::NewGuid() }
            @{ ArrangedKey = 'key-with-dash'; InitialValue = 'init-dash-{0}' -f [guid]::NewGuid(); UpdatedValue = 'upd-dash-{0}' -f [guid]::NewGuid() }
            @{ ArrangedKey = 'key_with_underscore'; InitialValue = 'init_underscore_{0}' -f [guid]::NewGuid(); UpdatedValue = 'upd_underscore_{0}' -f [guid]::NewGuid() }
            @{ ArrangedKey = 'key with space'; InitialValue = 'init space {0}' -f [guid]::NewGuid(); UpdatedValue = 'upd space {0}' -f [guid]::NewGuid() }
            @{ ArrangedKey = 'key/with/slash'; InitialValue = 'init/slash/{0}' -f [guid]::NewGuid(); UpdatedValue = 'upd/slash/{0}' -f [guid]::NewGuid() }
            @{ ArrangedKey = 'key\with\backslash'; InitialValue = 'init\backslash\{0}' -f [guid]::NewGuid(); UpdatedValue = 'upd\backslash\{0}' -f [guid]::NewGuid() }
            @{ ArrangedKey = 'key:with:colon'; InitialValue = 'init:colon:{0}' -f [guid]::NewGuid(); UpdatedValue = 'upd:colon:{0}' -f [guid]::NewGuid() }
            @{ ArrangedKey = 'key,with,comma'; InitialValue = 'init,comma,{0}' -f [guid]::NewGuid(); UpdatedValue = 'upd,comma,{0}' -f [guid]::NewGuid() }
            # @{ ArrangedKey = 'key=with=equals'; InitialValue = 'init=equals={0}' -f [guid]::NewGuid(); UpdatedValue = 'upd=equals={0}' -f [guid]::NewGuid() } # This is malformed and should throw an error
            @{ ArrangedKey = 'key#with#hash'; InitialValue = 'init#hash#{0}' -f [guid]::NewGuid(); UpdatedValue = 'upd#hash#{0}' -f [guid]::NewGuid() }
            @{ ArrangedKey = 'key$with$dollar'; InitialValue = 'init$dollar${0}' -f [guid]::NewGuid(); UpdatedValue = 'upd$dollar${0}' -f [guid]::NewGuid() }
            @{ ArrangedKey = 'key%with%percent'; InitialValue = 'init%percent%{0}' -f [guid]::NewGuid(); UpdatedValue = 'upd%percent%{0}' -f [guid]::NewGuid() }
            @{ ArrangedKey = 'key@with@at'; InitialValue = 'init@at@{0}' -f [guid]::NewGuid(); UpdatedValue = 'upd@at@{0}' -f [guid]::NewGuid() }
            @{ ArrangedKey = 'key!with!exclamation'; InitialValue = 'init!exclamation!{0}' -f [guid]::NewGuid(); UpdatedValue = 'upd!exclamation!{0}' -f [guid]::NewGuid() }
            @{ ArrangedKey = 'key(with(paren)'; InitialValue = 'init(paren){0}' -f [guid]::NewGuid(); UpdatedValue = 'upd(paren){0}' -f [guid]::NewGuid() }
            @{ ArrangedKey = 'key)with)paren)'; InitialValue = 'init)paren){0}' -f [guid]::NewGuid(); UpdatedValue = 'upd)paren){0}' -f [guid]::NewGuid() }
        )
    ) {
        # Act
        $setBambooParams = @{
            Path    = $multipleTestFile
            Debug   = $false
            Verbose = $true
            Key     = $ArrangedKey
            Value   = $InitialValue
        }

        Set-BambooCapability @setBambooParams

        $initialActial = Get-BambooCapabilities -Path $multipleTestFile -WhereKeyStartsWith $ArrangedKey
        $initialActial.Count | Should -Be 1
        $initialActial | Select-Object -ExpandProperty Value | Should -Be $InitialValue

        # Update the capability
        $setBambooParams.Value = $UpdatedValue
        Set-BambooCapability @setBambooParams
        $updatedActual = Get-BambooCapabilities -Path $multipleTestFile -WhereKeyStartsWith $ArrangedKey
        $updatedActual.Count | Should -Be 1
        $updatedActual | Select-Object -ExpandProperty Value | Should -Be $UpdatedValue
    }

    It "Handles mailformed key '<ArrangedKey>' correctly" -ForEach @(
        @{ArrangedKey = 'key=with=equals' }
        @{ArrangedKey = '' }
        @{ArrangedKey = $null }
    ) {
        # Act
        $setBambooParams = @{
            Path    = $multipleTestFile
            Debug   = $false
            Verbose = $true
            Key     = $ArrangedKey
            Value   = 'newValue'
        }

        { Set-BambooCapability @setBambooParams } | Should -Throw -ErrorId 'ParameterArgumentValidationError,Set-BambooCapability'
    }
}