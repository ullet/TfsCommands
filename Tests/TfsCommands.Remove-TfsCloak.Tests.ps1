# TfsCommands - PowerShell wrappers around tf.exe
#               - Pester unit tests for Remove-TfsCloak

# Copyright (c) 2014-2016 Trevor Barnett

# Released under terms of the MIT License - see LICENSE for details.

# Apart from parameter construction, almost all work in the module is ultimately
# delegated to tf.exe, which don't want to call in these tests.  Therefore the
# tests make a large use of mocks to verify that the correct command line is
# constructed.  This inevitably creates brittle tests, but best can do without
# actually integrating with a real TFS instance.

Param (
  [switch] $NoModuleImport
)

if (-not $NoModuleImport) {
  Import-Module TfsCommands -Force
}

Describe 'Remove-TfsCloak' {

  Mock -ModuleName TfsCommands Invoke-TfsCommand { }
  Mock -ModuleName TfsCommands Invoke-TfsCommandAtLocation { }

  It 'removes cloak from the specified path' {
    $serverPath = '$/project/directory'
    $workspaceName = 'some-workspace'
    $collectionUrl = 'http://some/tfs/collection'

    Remove-TfsCloak $serverPath $workspaceName $collectionUrl

    $assertArgs = @{
      ModuleName = 'TfsCommands'
      CommandName = 'Invoke-TfsCommand'
      ParameterFilter = {
        $Command -ieq 'workfold' -and
        $Arguments -icontains '/decloak' -and
        $Arguments -icontains $serverPath -and
        $Arguments -icontains "/workspace:$workspaceName" -and
        $Arguments -icontains "/collection:$collectionUrl" -and
        $Arguments.Count -eq 4
      }
    }
    Assert-MockCalled @assertArgs
  }

  It 'does not require collection URL parameter' {
    $serverPath = '$/project/directory'
    $workspaceName = 'some-workspace'

    Remove-TfsCloak $serverPath $workspaceName

    $assertArgs = @{
      ModuleName = 'TfsCommands'
      CommandName = 'Invoke-TfsCommand'
      ParameterFilter = {
        $Command -ieq 'workfold' -and
        $Arguments -icontains '/decloak' -and
        $Arguments -icontains $serverPath -and
        $Arguments -icontains "/workspace:$workspaceName" -and
        $Arguments.Count -eq 3
      }
    }
    Assert-MockCalled @assertArgs
  }

  It 'does not require workspace name parameter' {
    $serverPath = '$/project/directory'

    Remove-TfsCloak $serverPath

    $assertArgs = @{
      ModuleName = 'TfsCommands'
      CommandName = 'Invoke-TfsCommand'
      ParameterFilter = {
        $Command -ieq 'workfold' -and
        $Arguments -icontains '/decloak' -and
        $Arguments -icontains $serverPath -and
        $Arguments.Count -eq 2
      }
    }
    Assert-MockCalled @assertArgs
  }
}
