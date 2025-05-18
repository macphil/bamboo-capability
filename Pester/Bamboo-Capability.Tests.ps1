# bamboo-capability.tests.ps1
Describe 'Test creating a file with random key-value lines' {
    BeforeAll {
        # Load the function to be tested
        . (Join-Path $PSScriptRoot '..' 'Get-BambooCapabilities.ps1')
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
        $content | Write-Host -ForegroundColor Green
        
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
}