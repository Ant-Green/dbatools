$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Write-Host -Object "Running $PSCommandPath" -ForegroundColor Cyan
$global:TestConfig = Get-TestConfig

Describe "$CommandName Unit Tests" -Tag 'UnitTests' {
    Context "Validate parameters" {
        [object[]]$params = (Get-Command $CommandName).Parameters.Keys | Where-Object { $_ -notin ('whatif', 'confirm') }
        [object[]]$knownParameters = 'SqlInstance', 'SqlCredential', 'Alert', 'Category', 'Database', 'Operator', 'DelayBetweenResponses', 'Disabled', 'EventDescriptionKeyword', 'EventSource', 'JobId', 'Severity', 'MessageId', 'NotificationMessage', 'PerformanceCondition', 'WmiEventNamespace', 'WmiEventQuery', 'NotifyMethod', 'EnableException'
        $knownParameters += [System.Management.Automation.PSCmdlet]::CommonParameters
        It "Should only contain our specific parameters" {
            (@(Compare-Object -ReferenceObject ($knownParameters | Where-Object { $_ }) -DifferenceObject $params).Count ) | Should Be 0
        }
    }
}

Describe "$CommandName Integration Tests" -Tags "IntegrationTests" {
    BeforeEach {
        Get-DbaAgentAlert -SqlInstance $TestConfig.instance2, $TestConfig.instance3 -Alert "Test Alert", "Another Alert" | Remove-DbaAgentAlert -Confirm:$false
    }
    AfterAll {
        Get-DbaAgentAlert -SqlInstance $TestConfig.instance2, $TestConfig.instance3 -Alert "Test Alert", "Another Alert" | Remove-DbaAgentAlert -Confirm:$false
    }
    Context 'Creating a new SQL Server Agent alert' {
        $parms = @{
            SqlInstance           = $TestConfig.instance2
            Alert                 = "Test Alert"
            DelayBetweenResponses = 60
            Disabled              = $false
            NotifyMethod          = "NotifyEmail"
            NotificationMessage   = "Test Notification"
            Severity              = 17
            EnableException       = $true
        }

        It 'Should create a new alert' {
            $alert = New-DbaAgentAlert @parms

            # Assert
            $alert.Name | Should -Be 'Test Alert'
            $alert.DelayBetweenResponses | Should -Be 60
            $alert.IsEnabled | Should -Be $true
            $alert.Severity | Should -Be 17

            Get-DbaAgentAlert -SqlInstance $TestConfig.instance2 -Alert $parms.Alert | Should -Not -BeNullOrEmpty
        }

        It 'Should create a new alert' {
            $parms = @{
                SqlInstance           = $TestConfig.instance3
                Alert                 = "Another Alert"
                DelayBetweenResponses = 60
                NotifyMethod          = "NotifyEmail"
                NotificationMessage   = "Test Notification"
                MessageId             = 826
                EnableException       = $true
            }

            $alert = New-DbaAgentAlert @parms

            # Assert
            $alert.Name | Should -Be "Another Alert"
            $alert.DelayBetweenResponses | Should -Be 60
            $alert.IsEnabled | Should -Be $true
            $alert.MessageId | Should -Be 826
            $alert.Severity | Should -Be 0

            Get-DbaAgentAlert -SqlInstance $TestConfig.instance3 -Alert $parms.Alert | Should -Not -BeNullOrEmpty
        }
    }
}
