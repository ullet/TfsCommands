# TfsCommands - PowerShell wrappers around tf.exe
#               - Pester unit tests - all tests

# Copyright (c) 2014-2016 Trevor Barnett

# Released under terms of the MIT License - see LICENSE for details.

# Apart from parameter construction, almost all work in the module is ultimately
# delegated to tf.exe, which don't want to call in these tests.  Therefore the
# tests make a large use of mocks to verify that the correct command line is
# constructed.  This inevitably creates brittle tests, but best can do without
# actually integrating with a real TFS instance.

# Remove all modules but Pester and 'default' to avoid accidental use of
# commands from external modules, such as community extensions.
Get-Module |
  Where-Object { $_.Name -ne 'Pester' } |
  Where-Object { -not ($_.Name.StartsWith('Microsoft')) } |
  Remove-Module

Import-Module TfsCommands

$here = Split-Path -Parent $MyInvocation.MyCommand.Path

. "$here\TfsCommands.Invoke-TfsCommand.Tests.ps1" -NoModuleImport
. "$here\TfsCommands.Invoke-TfsCommandAtLocation.Tests.ps1" -NoModuleImport
. "$here\TfsCommands.New-TfsCloak.Tests.ps1" -NoModuleImport
. "$here\TfsCommands.New-TfsWorkFolderMapping.Tests.ps1" -NoModuleImport
. "$here\TfsCommands.New-TfsWorkspace.Tests.ps1" -NoModuleImport
. "$here\TfsCommands.Remove-TfsCloak.Tests.ps1" -NoModuleImport
. "$here\TfsCommands.Remove-TfsWorkFolderMapping.Tests.ps1" -NoModuleImport
. "$here\TfsCommands.Remove-TfsWorkspace.Tests.ps1" -NoModuleImport
. "$here\TfsCommands.Show-TfsContent.Tests.ps1" -NoModuleImport
. "$here\TfsCommands.Show-TfsHistory.Tests.ps1" -NoModuleImport
. "$here\TfsCommands.Show-TfsWorkspace.Tests.ps1" -NoModuleImport

# Clean up
Remove-Module TfsCommands
