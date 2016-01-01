# TfsCommands - PowerShell wrappers around tf.exe
#               - Pester unit tests for Show-TfsHistory

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

Describe 'Show-TfsHistory' {

  Mock -ModuleName TfsCommands Invoke-TfsCommand { }
  Mock -ModuleName TfsCommands Invoke-TfsCommandAtLocation { }

  It 'shows source control history of specified server or local directory' {
    $localOrServerPath = '$/project/directory'

    Show-TfsHistory $localOrServerPath

    $assertArgs = @{
      ModuleName = 'TfsCommands'
      CommandName = 'Invoke-TfsCommand'
      ParameterFilter = {
        $Command -ieq 'history' -and
        $Arguments -icontains $localOrServerPath -and
        $Arguments -icontains '/noprompt' -and
        $Arguments.Count -eq 2
      }
    }
    Assert-MockCalled @assertArgs
  }
  
  It 'defaults to current directory if path not specified' {
    Show-TfsHistory

    $assertArgs = @{
      ModuleName = 'TfsCommands'
      CommandName = 'Invoke-TfsCommand'
      ParameterFilter = {
        $Command -ieq 'history' -and
        $Arguments -icontains '.' -and
        $Arguments -icontains '/noprompt' -and
        $Arguments.Count -eq 2
      }
    }
    Assert-MockCalled @assertArgs
  }
  
  It 'optionally recurses sub-directories' {
    # PowerShell convention calls parameter "Recurse" not "Recursive"
    Show-TfsHistory -Recurse
    
    $assertArgs = @{
      ModuleName = 'TfsCommands'
      CommandName = 'Invoke-TfsCommand'
      ParameterFilter = { $Arguments -icontains "/recursive" }
    }
    Assert-MockCalled @assertArgs
  }
  
  It 'optionally shows in external window' {
    Show-TfsHistory -InExternalWindow
    
    $assertArgs = @{
      ModuleName = 'TfsCommands'
      CommandName = 'Invoke-TfsCommand'
      ParameterFilter = { $Arguments -inotcontains "/noprompt" }
    }
    Assert-MockCalled @assertArgs
  }
  
  It 'optionally sorted in ascending order' {
    Show-TfsHistory -Ascending
    
    $assertArgs = @{
      ModuleName = 'TfsCommands'
      CommandName = 'Invoke-TfsCommand'
      ParameterFilter = { $Arguments -icontains "/sort:ascending" }
    }
    Assert-MockCalled @assertArgs
  }
  
  It 'ignores ascending switch if shown in external window' {
    Show-TfsHistory -InExternalWindow -Ascending
    
    $assertArgs = @{
      ModuleName = 'TfsCommands'
      CommandName = 'Invoke-TfsCommand'
      ParameterFilter = { $Arguments -inotcontains "/sort:ascending" }
    }
    Assert-MockCalled @assertArgs
  }
  
  It 'optionally limits to a maximum number of entries' {
    $max = Random -Min 1 -Max 100

    Show-TfsHistory -MaxEntries $max
    
    $assertArgs = @{
      ModuleName = 'TfsCommands'
      CommandName = 'Invoke-TfsCommand'
      ParameterFilter = { $Arguments -icontains "/stopafter:$max" }
    }
    Assert-MockCalled @assertArgs
  }
  
  # Pester does not scope Assert-MockCalled "ParameterFilter" to 'It' - mocks
  # are scoped to either 'Describe' or 'Context', which includes assertions.
  # This means tests can have unexpected side-effects for other tests.
  # The specific example here is where an earlier test assertion was that:
  #   '($Arguments | % { $_ }) -icontains "/stopafter:$max"'
  # which is inverse of what want to insert here:
  #   '($Arguments | % { $_ }) -inotcontains "/stopafter:$max"'
  # But because of the earlier test the assertion passes when expected to fail
  # (because at time or writing feature was not yet implemented).
  Context 'Negative max entries' {
    It 'ignores MaxEntries parameter' {
      $max = Random -Min -100 -Max -1

      Show-TfsHistory -MaxEntries $max
      
      $assertArgs = @{
        ModuleName = 'TfsCommands'
        CommandName = 'Invoke-TfsCommand'
        ParameterFilter = { $Arguments -inotcontains "/stopafter:$max" }
      }
      Assert-MockCalled @assertArgs
    }
  }
  
  # Same problem occurs for hard-coded value in the 'zero' test, so presumably
  # not due to sharing same '$max' variable.
  Context 'Zero max entries' {  
    It 'ignores MaxEntries parameter' {
      Show-TfsHistory -MaxEntries 0
      
      $assertArgs = @{
        ModuleName = 'TfsCommands'
        CommandName = 'Invoke-TfsCommand'
        ParameterFilter = { $Arguments -inotcontains "/stopafter:0" }
      }
      Assert-MockCalled @assertArgs
    }
  }

  It 'List-TfsHistory is an alias' {
    $localOrServerPath = '$/project/directory'

    List-TfsHistory $localOrServerPath

    $assertArgs = @{
      ModuleName = 'TfsCommands'
      CommandName = 'Invoke-TfsCommand'
      ParameterFilter = {
        $Command -ieq 'history' -and
        $Arguments -icontains $localOrServerPath -and
        $Arguments -icontains '/noprompt' -and
        $Arguments.Count -eq 2
      }
    }
    Assert-MockCalled @assertArgs
  }
}
