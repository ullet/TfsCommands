# TfsCommands - PowerShell wrappers around tf.exe
#               - Pester unit tests for Invoke-TfsCommand

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

InModuleScope TfsCommands {
  Describe 'Invoke-TfsCommand' {
    function tf { } # replace real 'tf' with mockable PowerShell command
    Mock tf { } # now can mock it!
    
    It 'calls tf command with correct arguments' {
      Invoke-TfsCommand 'command' 'arg1' 'arg2' 'arg3'
      
      $assertArgs = @{
        CommandName = 'tf'
        ParameterFilter = {
          $args -icontains 'command' -and
          $args -icontains 'arg1' -and
          $args -icontains 'arg2' -and
          $args -icontains 'arg3' -and
          $args.Count -eq 4
        }
      }
      Assert-MockCalled @assertArgs
    }
    
    It 'calls tf command without blank arguments' {
      $cmdArgs = @( 'command', $null, '', '   ', 'arg' )
      Invoke-TfsCommand @cmdArgs
      
      $assertArgs = @{
        CommandName = 'tf'
        ParameterFilter = {
          $args -icontains 'command' -and
          $args -icontains 'arg' -and
          $args.Count -eq 2
        }
      }
      Assert-MockCalled @assertArgs
    }
  }
}
