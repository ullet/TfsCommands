# TfsCommands - PowerShell wrappers around tf.exe
#               - Pester unit tests for New-TfsWorkFolderMapping

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

Describe 'New-TfsWorkFolderMapping' {

  Mock -ModuleName TfsCommands Invoke-TfsCommand { }
  Mock -ModuleName TfsCommands Invoke-TfsCommandAtLocation { }

  It 'creates work folder mapping between server and local paths' {
    $workspaceName = 'some-workspace'
    $serverPath = '$/project/directory'
    $localPath = '/local/file/system/path'
    $collectionUrl = 'http://some/tfs/collection'

    $cmdArgs = @(
      $workspaceName, $serverPath, $localPath, $collectionUrl)
    New-TfsWorkFolderMapping @cmdArgs

    $assertArgs = @{
      ModuleName = 'TfsCommands'
      CommandName = 'Invoke-TfsCommand'
      ParameterFilter = {
        $Command -ieq 'workfold' -and
        $Arguments -icontains '/map' -and
        $Arguments -icontains "/collection:$collectionUrl" -and
        $Arguments -icontains "/workspace:$workspaceName" -and
        $Arguments -icontains $serverPath -and
        $Arguments -icontains $localPath -and
        $Arguments.Count -eq 5
      }
    }
    Assert-MockCalled @assertArgs
  }

  It 'does not require collection URL parameter' {
    $workspaceName = 'some-workspace'
    $serverPath = '$/project/directory'
    $localPath = '/local/file/system/path'

    New-TfsWorkFolderMapping $workspaceName $serverPath $localPath

    $assertArgs = @{
      ModuleName = 'TfsCommands'
      CommandName = 'Invoke-TfsCommand'
      ParameterFilter = {
        $Command -ieq 'workfold' -and
        $Arguments -icontains '/map' -and
        $Arguments -icontains "/workspace:$workspaceName" -and
        $Arguments -icontains $serverPath -and
        $Arguments -icontains $localPath -and
        $Arguments.Count -eq 4
      }
    }
    Assert-MockCalled @assertArgs
  }

  It 'does not require local path parameter' {
    $workspaceName = 'some-workspace'
    $serverPath = '$/project/directory'

    New-TfsWorkFolderMapping $workspaceName $serverPath

    $assertArgs = @{
      ModuleName = 'TfsCommands'
      CommandName = 'Invoke-TfsCommand'
      ParameterFilter = {
        $Command -ieq 'workfold' -and
        $Arguments -icontains '/map' -and
        $Arguments -icontains "/workspace:$workspaceName" -and
        $Arguments -icontains $serverPath -and
        $Arguments.Count -eq 3
      }
    }
    Assert-MockCalled @assertArgs
  }
}
