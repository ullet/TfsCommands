# TfsCommands - PowerShell wrappers around tf.exe
#               - Pester unit tests for Show-TfsWorkspace

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

Describe 'Show-TfsWorkspace' {

  Mock -ModuleName TfsCommands Invoke-TfsCommand { }
  Mock -ModuleName TfsCommands Invoke-TfsCommandAtLocation { }

  It 'lists workspaces on default server for current user and computer' {
    Show-TfsWorkspace
    
    $assertArgs = @{
      ModuleName = 'TfsCommands'
      CommandName = 'Invoke-TfsCommand'
      ParameterFilter = {
        $Command -ieq 'workspaces' -and
        $Arguments -icontains "/computer:$env:COMPUTERNAME" -and
        $Arguments.Count -eq 1
      }
    }
    Assert-MockCalled @assertArgs
  }
  
  It 'lists workspaces on default server for current user and given computer' {
    $computerName = 'some-computer'

    Show-TfsWorkspace -ComputerName $computerName
    
    $assertArgs = @{
      ModuleName = 'TfsCommands'
      CommandName = 'Invoke-TfsCommand'
      ParameterFilter = {
        $Command -ieq 'workspaces' -and
        $Arguments -icontains "/computer:$computerName" -and
        $Arguments.Count -eq 1
      }
    }
    Assert-MockCalled @assertArgs
  }

  It 'lists workspaces on default server for given owner and current computer' {
    $ownerName = 'some-user'

    Show-TfsWorkspace -OwnerName $ownerName
    
    $assertArgs = @{
      ModuleName = 'TfsCommands'
      CommandName = 'Invoke-TfsCommand'
      ParameterFilter = {
        $Command -ieq 'workspaces' -and
        $Arguments -icontains "/owner:$ownerName" -and
        $Arguments -icontains "/computer:$env:COMPUTERNAME" -and
        $Arguments.Count -eq 2
      }
    }
    Assert-MockCalled @assertArgs
  }

  It 'lists workspaces on default server for given owner and computer' {
    $computerName = 'some-computer'
    $ownerName = 'some-user'

    Show-TfsWorkspace -OwnerName $ownerName -ComputerName $computerName
    
    $assertArgs = @{
      ModuleName = 'TfsCommands'
      CommandName = 'Invoke-TfsCommand'
      ParameterFilter = {
        $Command -ieq 'workspaces' -and
        $Arguments -icontains "/owner:$ownerName" -and
        $Arguments -icontains "/computer:$computerName" -and
        $Arguments.Count -eq 2
      }
    }
    Assert-MockCalled @assertArgs
  }

  It 'lists workspaces for given collection' {
    $collectionUrl = 'http://some/collection'
    $ownerName = 'some-user'

    Show-TfsWorkspace -CollectionUrl $collectionUrl
    
    $assertArgs = @{
      ModuleName = 'TfsCommands'
      CommandName = 'Invoke-TfsCommand'
      ParameterFilter = { $Arguments -icontains "/collection:$collectionUrl" }
    }
    Assert-MockCalled @assertArgs
  }
}
