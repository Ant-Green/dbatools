$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Write-Host -Object "Running $PSCommandPath" -ForegroundColor Cyan
$global:TestConfig = Get-TestConfig

Describe "$CommandName Unit Tests" -Tag 'UnitTests' {
    Context "Validate parameters" {
        [object[]]$params = (Get-Command $CommandName).Parameters.Keys | Where-Object {$_ -notin ('whatif', 'confirm')}
        [object[]]$knownParameters = 'SqlInstance', 'SqlCredential', 'Name', 'Path', 'Template', 'TargetFilePath', 'TargetFileMetadataPath', 'EnableException', 'StartUpState'
        $knownParameters += [System.Management.Automation.PSCmdlet]::CommonParameters
        It "Should only contain our specific parameters" {
            (@(Compare-Object -ReferenceObject ($knownParameters | Where-Object {$_}) -DifferenceObject $params).Count ) | Should Be 0
        }
    }
}

Describe "$CommandName Integration Tests" -Tags "IntegrationTests" {
    AfterAll {
        $null = Get-DbaXESession -SqlInstance $TestConfig.instance2 -Session 'Overly Complex Queries' | Remove-DbaXESession
    }
    Context "Test Importing Session Template" {
        It -Skip "session imports with proper name and non-default target file location" {
            $result = Import-DbaXESessionTemplate -SqlInstance $TestConfig.instance2 -Template 'Overly Complex Queries' -TargetFilePath C:\temp
            $result.Name | Should Be "Overly Complex Queries"
            $result.TargetFile -match 'C\:\\temp' | Should Be $true
        }
    }
}
