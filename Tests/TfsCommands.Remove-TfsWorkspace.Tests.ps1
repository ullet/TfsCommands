# TfsCommands - PowerShell wrappers around tf.exe
#               - Pester unit tests for Remove-TfsWorkspace

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

Describe 'Remove-TfsWorkspace' {

  Mock -ModuleName TfsCommands Invoke-TfsCommand { }
  Mock -ModuleName TfsCommands Invoke-TfsCommandAtLocation { }

  It 'removes workspace with given name' {
    $workspaceName = 'some-workspace'
    $collectionUrl = 'http://some/tfs/collection'

    Remove-TfsWorkspace $workspaceName $collectionUrl

    $assertArgs = @{
      ModuleName = 'TfsCommands'
      CommandName = 'Invoke-TfsCommand'
      ParameterFilter = {
        $Command -ieq 'workspace' -and
        $Arguments -icontains '/delete' -and
        $Arguments -icontains $workspaceName -and
        $Arguments -icontains "/collection:$collectionUrl" -and
        $Arguments.Count -eq 3
      }
    }
    Assert-MockCalled @assertArgs
  }
  
  Context 'Collection URL parameter not given' {
    It 'does not require collection URL parameter' {
      $workspaceName = 'some-workspace'

      Remove-TfsWorkspace $workspaceName

      $assertArgs = @{
        ModuleName = 'TfsCommands'
        CommandName = 'Invoke-TfsCommand'
        ParameterFilter = {
          $Command -ieq 'workspace' -and
          $Arguments -icontains '/delete' -and
          $Arguments -icontains $workspaceName -and
          $Arguments.Count -eq 2
        }
      }
      Assert-MockCalled @assertArgs
    }
  }
}
