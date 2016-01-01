# TfsCommands - PowerShell wrappers around tf.exe
#               - Pester unit tests for Invoke-TfsCommandAtLocation

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

New-Variable -Scope Script -option Constant LOCATION 'TestDrive:/some-directory'

Describe 'Invoke-TfsCommandAtLocation' {
  Mock -Module TfsCommands Invoke-TfsCommand { }
  Mock -Module TfsCommands Push-Location { }
  Mock -Module TfsCommands Pop-Location { }

  BeforeAll {
    New-Item -ItemType Container $LOCATION | Out-Null
  }
  
  AfterAll {
    Remove-Item $LOCATION -Recurse -Force
  }
  
  It 'calls Invoke-TfsCommand with correct arguments' {
    Invoke-TfsCommandAtLocation $LOCATION 'command' 'arg1' 'arg2' 'arg3'
    
    $assertArgs = @{
      ModuleName = 'TfsCommands'
      CommandName = 'Invoke-TfsCommand'
      ParameterFilter = {
        $Command -eq 'command'
        $Arguments -icontains 'arg1' -and
        $Arguments -icontains 'arg2' -and
        $Arguments -icontains 'arg3' -and
        $Arguments.Count -eq 3
      }
    }
    Assert-MockCalled @assertArgs
  }
  
  It 'changes directory before calling Invoke-TfsCommand' {
    # actually testing changes directory at some point - assuming before

    Invoke-TfsCommandAtLocation $LOCATION 'command'
    
    $assertArgs = @{
      ModuleName = 'TfsCommands'
      CommandName = 'Push-Location'
      ParameterFilter = { $Path -eq $LOCATION }
    }
    Assert-MockCalled @assertArgs
  }
  
  It 'changes directory back after calling Invoke-TfsCommand' {
    # actually testing changes directory back at some point - assuming after

    Invoke-TfsCommandAtLocation $LOCATION 'command'
    
    $assertArgs = @{
      ModuleName = 'TfsCommands'
      CommandName = 'Pop-Location'
    }
    Assert-MockCalled @assertArgs
  }
}
