# TfsCommands - PowerShell wrappers around tf.exe
#               - Pester unit tests for Remove-TfsWorkFolderMapping

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

Describe 'Remove-TfsWorkFolderMapping' {

  Mock -ModuleName TfsCommands Invoke-TfsCommand { }
  Mock -ModuleName TfsCommands Invoke-TfsCommandAtLocation { }

  It 'removes work folder mapping to server or local path' {
    $localOrServerPath = '$/project/directory'
    $workspaceName = 'some-workspace'
    $collectionUrl = 'http://some/tfs/collection'

    $cmdArgs = @($localOrServerPath, $workspaceName, $collectionUrl)
    Remove-TfsWorkFolderMapping @cmdArgs

    $assertArgs = @{
      ModuleName = 'TfsCommands'
      CommandName = 'Invoke-TfsCommand'
      ParameterFilter = {
        $Command -ieq 'workfold' -and
        $Arguments -icontains '/unmap' -and
        $Arguments -icontains "/collection:$collectionUrl" -and
        $Arguments -icontains "/workspace:$workspaceName" -and
        $Arguments -icontains $localOrServerPath
        $Arguments.Count -eq 4
      }
    }
    Assert-MockCalled @assertArgs
  }

  It 'does not require collection URL parameter' {
    $localOrServerPath = '$/project/directory'
    $workspaceName = 'some-workspace'

    Remove-TfsWorkFolderMapping $localOrServerPath $workspaceName

    $assertArgs = @{
      ModuleName = 'TfsCommands'
      CommandName = 'Invoke-TfsCommand'
      ParameterFilter = {
        $Command -ieq 'workfold' -and
        $Arguments -icontains '/unmap' -and
        $Arguments -icontains "/workspace:$workspaceName" -and
        $Arguments -icontains $localOrServerPath -and
        $Arguments.Count -eq 3
      }
    }
    Assert-MockCalled @assertArgs
  }

  It 'does not require workspace name parameter' {
    $localOrServerPath = '$/project/directory'

    Remove-TfsWorkFolderMapping $localOrServerPath

    $assertArgs = @{
      ModuleName = 'TfsCommands'
      CommandName = 'Invoke-TfsCommand'
      ParameterFilter = {
        $Command -ieq 'workfold' -and
        $Arguments -icontains '/unmap' -and
        $Arguments -icontains $localOrServerPath -and
        $Arguments.Count -eq 2
      }
    }
    Assert-MockCalled @assertArgs
  }
}
