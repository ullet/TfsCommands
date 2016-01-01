# TfsCommands

Simple Windows PowerShell wrapper functions to tf.exe   
NB. Just simple functions, no nice PowerShell objects nor pipeline friendly.

_Copyright (c) 2014-2016 Trevor Barnett_

_Released under terms of the MIT License - see LICENSE for details._

## Why?
This module exists because I wanted a slightly more PowerShell-like way of working with the TFS command line.   
Also [Team Foundation Server Power Tools](https://visualstudiogallery.msdn.microsoft.com/f017b10c-02b4-4d6d-9845-58a06545627f)
does not provide Cmdlets for creating or deleting workspaces, workfolder mappings or cloaked folders (and to be honest I didn't know about the Power Tools Cmdlets when I wrote the first version of this module, so it's really just luck that there's very little overlap). 

## How to install
1. Install dependencies:
  1. Install [TemporaryDirectory](//github.com/ullet/TemporaryDirectory) PowerShell module.
2. Download [master.zip](//github.com/ullet/TfsCommands/archive/master.zip) for this repository
3. Extract the contents of the zip file to a new folder named "TfsCommands" inside your
   WindowsPowerShell\Modules folder.

## How to use

```PowerShell
Import-Module TfsCommands

# Create new TFS workspace mapping current directory to root project $/
New-TfsWorkspace workspace1

# Create new TFS workspace mapping specific directory to root project $/
New-TfsWorkspace workspace2 -Path 'C:\workfolder2'

# Create new TFS workspace without mapping to root project $/
New-TfsWorkspace workspace3 -NoMap

# Map current directory to a server path
New-TfsWorkFolderMapping workspace2 $/project

# Map specific directory to a server path
New-TfsWorkFolderMapping workspace3 $/project C:\workfolder3\project

# Cloak server path from workspace mapped to current directory
New-TfsCloak $/project

# Cloak server path from specific workspace
New-TfsCloak $/project workspace1

# Get list of source controlled contents of current directory
Show-TfsContent
Show-TfsContent .

# Get recursive list of source controlled contents of current directory
Show-TfsContent -Recurse

# Get list of source controlled contents of specific local path
Show-TfsContent C:\workspace

# Get list of source controlled contents of specific server path
Show-TfsContent $/project

# Get list of source controlled contents at specific changeset
Show-TfsContent -Version C12345

# Get list of source controlled folders
Show-TfsContent -FoldersOnly

# Get list of source controlled contents including deleted items
Show-TfsContent -IncludeDeleted

# Get source control history of current directory
Show-TfsHistory
Show-TfsHistory .

# Get recursive source control history of current directory
Show-TfsHistory -Recurse

# Get source control history of specific local path
Show-TfsHistory C:\workspace

# Get source control history of specific server path
Show-TfsHistory $/project

# Get source control history sorted in ascending order (oldest first)
Show-TfsHistory -Ascending

# Get history for last 3 changesets
Show-TfsHistory -MaxEntries 3

# Show history in external window
Show-TfsHistory -InExternalWindow

# Show history for last 3 changesets in external window
Show-TfsHistory -MaxEntries 3 -InExternalWindow

# Decloak server path from workspace mapped to current directory
Remove-TfsCloak $/project

# Decloak server path from specific workspace
Remove-TfsCloak $/project workspace1

# Unmap specific server path for workspace mapped to current directory
Remove-TfsWorkFolderMapping $/project

# Unmap specific local path for workspace mapped to current directory
Remove-TfsWorkFolderMapping C:\workfolder3\project

# Unmap specific server path for specific workspace
Remove-TfsWorkFolderMapping $/project workspace2

# Delete specific workspace
Remove-TfsWorkspace workspace1

# Invoke an arbitrary tf.exe command
Invoke-TfsCommand history /v:T .

# Invoke an arbitrary tf.exe command from within a specific directory
# (useful for commands that implicitly use current directory)
Invoke-TfsCommandAtLocation workspace /new workspace1
```
