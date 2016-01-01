# TfsCommands - PowerShell wrappers around tf.exe
#               - Pester unit tests for New-TfsWorkspace

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

Describe 'New-TfsWorkspace' {

  Mock -ModuleName TfsCommands Invoke-TfsCommand { }
  Mock -ModuleName TfsCommands Invoke-TfsCommandAtLocation { }
  Mock -ModuleName TfsCommands New-TemporaryDirectory {
    New-Module -AsCustomObject -ScriptBlock {
      $Path = 'TestDrive:\tempdir'
      function Delete { }
      Export-ModuleMember -Variable Path
      Export-ModuleMember Delete
    }
  }
  Mock -ModuleName TfsCommands Remove-TfsWorkFolderMapping { }

  It 'creates new workspace with the given name' {
    $workspaceName = 'some-workspace'
    $collectionUrl = 'http://some/tfs/collection'
    $comment = "some comment"

    New-TfsWorkspace $workspaceName $collectionUrl $comment

    $assertArgs = @{
      ModuleName = 'TfsCommands'
      CommandName = 'Invoke-TfsCommandAtLocation'
      ParameterFilter = {
        $Command -ieq 'workspace' -and
        $Arguments -icontains '/new' -and
        $Arguments -icontains $workspaceName -and
        $Arguments -icontains "/collection:$collectionUrl" -and
        $Arguments -icontains "/comment:'$comment'" -and
        $Arguments -icontains "/noprompt" -and
        $Arguments -icontains "/permission:private" -and
        $Arguments -icontains "/location:server" -and
        $Arguments -icontains "/computer:$env:COMPUTERNAME" -and
        $Arguments.Count -eq 8
      }
    }
    Assert-MockCalled @assertArgs
  }

  It 'creates new workspace with root work folder mapping to specified path' {
    $workspaceName = 'some-workspace'
    $collectionUrl = 'http://some/tfs/collection'
    $comment = "some comment"
    $pathToMap = "/local/path/to/be/mapped/to/server/root"

    New-TfsWorkspace $workspaceName $collectionUrl $comment $pathToMap

    $assertArgs = @{
      ModuleName = 'TfsCommands'
      CommandName = 'Invoke-TfsCommandAtLocation'
      ParameterFilter = { $Location -eq $pathToMap }
    }
    Assert-MockCalled @assertArgs
  }

  It 'does not require comment parameter' {
    $workspaceName = 'some-workspace'
    $collectionUrl = 'http://some/tfs/collection'

    New-TfsWorkspace $workspaceName $collectionUrl

    $assertArgs = @{
      ModuleName = 'TfsCommands'
      CommandName = 'Invoke-TfsCommandAtLocation'
      ParameterFilter = {
        $Command -ieq 'workspace' -and
        $Arguments -icontains '/new' -and
        $Arguments -icontains $workspaceName -and
        $Arguments -icontains "/collection:$collectionUrl" -and
        $Arguments -icontains "/noprompt" -and
        $Arguments -icontains "/permission:private" -and
        $Arguments -icontains "/location:server" -and
        $Arguments -icontains "/computer:$env:COMPUTERNAME" -and
        $Arguments.Count -eq 7
      }
    }
    Assert-MockCalled @assertArgs
  }

  It 'does not require collection URL parameter' {
    $workspaceName = 'some-workspace'

    New-TfsWorkspace $workspaceName

    $assertArgs = @{
      ModuleName = 'TfsCommands'
      CommandName = 'Invoke-TfsCommandAtLocation'
      ParameterFilter = {
        $Command -ieq 'workspace' -and
        $Arguments -icontains '/new' -and
        $Arguments -icontains $workspaceName -and
        $Arguments -icontains "/noprompt" -and
        $Arguments -icontains "/permission:private" -and
        $Arguments -icontains "/location:server" -and
        $Arguments -icontains "/computer:$env:COMPUTERNAME" -and
        $Arguments.Count -eq 6
      }
    }
    Assert-MockCalled @assertArgs
  }

  It 'uses temporary location if option set to not keep root mapping' {
    New-TfsWorkspace 'some-workspace' -NoMap

    $assertArgs = @{
      ModuleName = 'TfsCommands'
      CommandName = 'Invoke-TfsCommandAtLocation'
      ParameterFilter = { $Location -eq 'TestDrive:\tempdir' }
    }
    Assert-MockCalled @assertArgs
  }
  
  It 'uses temporary location if local path for root mapping not given' {
    New-TfsWorkspace 'some-workspace'

    $assertArgs = @{
      ModuleName = 'TfsCommands'
      CommandName = 'Invoke-TfsCommandAtLocation'
      ParameterFilter = { $Location -eq 'TestDrive:\tempdir' }
    }
    Assert-MockCalled @assertArgs
  }

  It 'removes temporary root work folder mapping' {
    $newWorkspaceName = 'some-workspace'

    New-TfsWorkspace $newWorkspaceName -NoMap

    $assertArgs = @{
      ModuleName = 'TfsCommands'
      CommandName = 'Remove-TfsWorkFolderMapping'
      ParameterFilter = {
        $WorkspaceName -eq $newWorkspaceName -and
        $LocalOrServerPath -eq 'TestDrive:\tempdir'
      }
    }
    Assert-MockCalled @assertArgs
  }
}
