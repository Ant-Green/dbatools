$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Write-Host -Object "Running $PSCommandpath" -ForegroundColor Cyan
$global:TestConfig = Get-TestConfig

Describe "$CommandName Unit Tests" -Tags "UnitTests" {
    Context "Validate parameters" {
        [object[]]$params = (Get-Command $CommandName).Parameters.Keys | Where-Object {$_ -notin ('whatif', 'confirm')}
        [object[]]$knownParameters = 'SqlInstance', 'SqlCredential', 'Database', 'ExcludeDatabase', 'Simple', 'Primary', 'Secondary', 'EnableException'
        $knownParameters += [System.Management.Automation.PSCmdlet]::CommonParameters
        It "Should only contain our specific parameters" {
            (@(Compare-Object -ReferenceObject ($knownParameters | Where-Object {$_}) -DifferenceObject $params).Count ) | Should Be 0
        }
    }
}

Describe "$CommandName Integration Tests" -Tags "IntegrationTests" {
    BeforeAll {
        $server = Connect-DbaInstance -SqlInstance $TestConfig.instance1
        $skip = $false
        if ($server.Edition -notmatch 'Express') {
            $skip = $true
        }
    }

    It -Skip:$skip "warns if SQL instance edition is not supported" {
        $null = Test-DbaDbLogShipStatus -SqlInstance $TestConfig.instance1 -WarningAction SilentlyContinue -WarningVariable editionwarn
        $editionwarn -match "Express" | Should Be $true
    }

    It "warns if no log shipping found" {
        $null = Test-DbaDbLogShipStatus -SqlInstance $TestConfig.instance2 -Database 'master' -WarningAction SilentlyContinue -WarningVariable doesntexist
        $doesntexist -match "No information available" | Should Be $true
    }
}
