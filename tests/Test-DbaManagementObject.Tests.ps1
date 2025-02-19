<#
    The below statement stays in for every test you build.
#>
$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Write-Host -Object "Running $PSCommandPath" -ForegroundColor Cyan
$global:TestConfig = Get-TestConfig

<#
    Unit test is required for any command added
#>
Describe "$CommandName Unit Tests" -Tag 'UnitTests' {
    Context "Validate parameters" {
        [object[]]$params = (Get-Command $CommandName).Parameters.Keys | Where-Object {$_ -notin ('whatif', 'confirm')}
        [object[]]$knownParameters = 'ComputerName', 'Credential', 'VersionNumber', 'EnableException'
        $knownParameters += [System.Management.Automation.PSCmdlet]::CommonParameters
        It "Should only contain our specific parameters" {
            (@(Compare-Object -ReferenceObject ($knownParameters | Where-Object {$_}) -DifferenceObject $params).Count ) | Should Be 0
        }
    }
}
Describe "$CommandName Integration Tests" -Tags "IntegrationTests" {
    BeforeAll {
        $versionMajor = (Connect-DbaInstance -SqlInstance $TestConfig.instance2).VersionMajor
    }
    Context "Command actually works" {
        $trueResults = Test-DbaManagementObject -ComputerName $TestConfig.instance2 -VersionNumber $versionMajor
        It "Should have correct properties" {
            $ExpectedProps = 'ComputerName,Version,Exists'.Split(',')
            ($trueResults[0].PsObject.Properties.Name | Sort-Object) | Should Be ($ExpectedProps | Sort-Object)
        }

        It "Should return true for VersionNumber $versionMajor" {
            $trueResults.Exists | Should Be $true
        }

        $falseResults = Test-DbaManagementObject -ComputerName $TestConfig.instance2 -VersionNumber -1
        It "Should return false for VersionNumber -1" {
            $falseResults.Exists | Should Be $false
        }
    }
}
