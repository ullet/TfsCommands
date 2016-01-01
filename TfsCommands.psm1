# TfsCommands - PowerShell wrappers around tf.exe

# Copyright (c) 2014-2016 Trevor Barnett

# Released under terms of the MIT License - see LICENSE for details.

Import-Module TemporaryDirectory

# public

function New-TfsCloak {
param (
  [Parameter(Mandatory)]
  [String] $ServerPath,
  [String] $WorkspaceName,
  [Uri] $CollectionUrl
)
  $cmdArgs = CommandArguments @(
    'workfold'
    '/cloak'
    $ServerPath
    (WorkspaceParameter $WorkspaceName)
    (CollectionParameter $CollectionUrl))
  Invoke-TfsCommand @cmdArgs
}

function New-TfsWorkFolderMapping {
param (
  [Parameter(Mandatory)]
  [String] $WorkspaceName,
  [Parameter(Mandatory)]
  [String] $ServerPath,
  [String] $LocalPath,
  [Uri] $CollectionUrl
)
  $cmdArgs = CommandArguments @(
    'workfold'
    '/map'
    (CollectionParameter $CollectionUrl)
    (WorkspaceParameter $WorkspaceName)
    $ServerPath
    $LocalPath)
  Invoke-TfsCommand @cmdArgs
}

function New-TfsWorkspace {
param (
  [Parameter(Mandatory)]
  [String] $Name,
  [Uri] $CollectionUrl,
  [String] $Comment,
  [String] $Path,
  [switch] $NoMap
)
  $Path = ($Path | DefaultIfBlank '')
  if ($Path -eq '') { $NoMap = $true }
  $tmpDir = $null
  try {
    $rootMapPath = $Path
    if ($NoMap) {
      # Use a temporary folder for $Path that will be removed immediately
      # afterwards.  Since removing the mapping, the passed in value for $Path,
      # if any, is actually irrelevant.
      $tmpDir = New-TemporaryDirectory
      $rootMapPath = $tmpDir.Path
    }
    $cmdArgs = CommandArguments @(
      $rootMapPath
      'workspace'
      '/new'
      $Name
      (NoPromptParameter)
      (CollectionParameter $CollectionUrl)
      (CommentParameter $Comment)
      (LocationParameter)
      (PermissionParameter)
      (ComputerParameter))
    Invoke-TfsCommandAtLocation @cmdArgs
    if ($NoMap) {
      # Previous command forced setting a mapping to root $/ which is not
      # required, so remove the unwanted mapping.
      Remove-TfsWorkFolderMapping $rootMapPath $Name
    }
  }
  finally {
    if ($tmpDir -ne $null) {
      $tmpDir.Delete()
    }
  }
}

function Remove-TfsCloak {
param (
  [Parameter(Mandatory)]
  [String] $ServerPath,
  [String] $WorkspaceName,
  [Uri] $CollectionUrl
)
  $cmdArgs = CommandArguments @(
    'workfold'
    '/decloak'
    $ServerPath
    (WorkspaceParameter $WorkspaceName)
    (CollectionParameter $CollectionUrl))
  Invoke-TfsCommand @cmdArgs
}

function Remove-TfsWorkFolderMapping {
param (
  [Parameter(Mandatory)]
  [String] $LocalOrServerPath,
  [String] $WorkspaceName,
  [Uri] $CollectionUrl
)
  $cmdArgs = CommandArguments @(
    'workfold'
    '/unmap'
    (CollectionParameter $CollectionUrl)
    (WorkspaceParameter $WorkspaceName)
    $LocalOrServerPath)
  Invoke-TfsCommand @cmdArgs
}

function Remove-TfsWorkspace {
param (
  [Parameter(Mandatory)]
  [String] $Name,
  [Uri] $CollectionUrl
)
  $cmdArgs = CommandArguments @(
    'workspace'
    '/delete'
    (CollectionParameter $CollectionUrl)
    $Name)
  Invoke-TfsCommand @cmdArgs
}

function Show-TfsContent {
param (
  [String] $LocalOrServerPath,
  [String] $Version,
  [switch] $Recurse,
  [switch] $FoldersOnly,
  [switch] $IncludeDeleted
)
  $LocalOrServerPath = ($LocalOrServerPath | Coalesce '')
  $LocalOrServerPath =
    if ($LocalOrServerPath -eq '') { '.' } else { $LocalOrServerPath }
  $cmdArgs = CommandArguments @(
    'dir'
    $LocalOrServerPath
    (VersionParameter $Version)
    (RecursiveParameter $Recurse)
    (FoldersParameter $FoldersOnly)
    (DeletedParameter $IncludeDeleted))
  Invoke-TfsCommand @cmdArgs
}

function Show-TfsHistory {
param (
  [String] $LocalOrServerPath,
  [Nullable[int]] $MaxEntries,
  [switch] $Recurse,
  [switch] $InExternalWindow,
  [switch] $Ascending
)
  $LocalOrServerPath = ($LocalOrServerPath | Coalesce '')
  $LocalOrServerPath =
    if ($LocalOrServerPath -eq '') { '.' } else { $LocalOrServerPath }
  $sortDirection = ''
  if ((-not $InExternalWindow) -and $Ascending) {
    $sortDirection = 'Ascending'
  }
  $cmdArgs = CommandArguments @(
    'history'
    (RecursiveParameter $Recurse)
    (NoPromptParameter (-not $InExternalWindow))
    (StopAfterParameter $MaxEntries)
    $LocalOrServerPath
    (SortParameter $sortDirection))
  Invoke-TfsCommand @cmdArgs
}

function Show-TfsWorkspace {
param (
  [String] $OwnerName,
  [String] $ComputerName,
  [Uri] $CollectionUrl
)
  $cmdArgs = CommandArguments @(
    'workspaces'
    (OwnerParameter $OwnerName)
    (ComputerParameter $ComputerName)
    (CollectionParameter $CollectionUrl))
  Invoke-TfsCommand @cmdArgs
}

function Invoke-TfsCommandAtLocation {
param (
  [Parameter(Mandatory)]
  $Location,
  [Parameter(Mandatory)]
  [String] $Command,
  [Parameter(ValueFromRemainingArguments)]
  [Object[]] $Arguments
)
  Push-Location $Location
  Invoke-TfsCommand $Command ($Arguments | Coalesce @())
  Pop-Location
}

function Invoke-TfsCommand {
param (
  [Parameter(Mandatory)]
  [String] $Command,
  [Parameter(ValueFromRemainingArguments)]
  [Object[]] $Arguments
)
  $cmdArgs = CommandArguments @($Command, $Arguments)
  &tf @cmdArgs
}

# private

function CollectionParameter {
param (
  [String] $CollectionUrl
)
  OptionalNamedParameter 'collection' $CollectionUrl
}

function WorkspaceParameter {
param (
  [String] $WorkspaceName
)
  OptionalNamedParameter 'workspace' $WorkspaceName
}

function CommentParameter {
param (
  [String] $Comment
)
  $Comment = ($Comment | Coalesce '')
  $Comment = EscapeDoubleQuotes $Comment
  $parameter = OptionalNamedParameter 'comment' $Comment
  # wrap whole parameter in quotes to prevent later being split on whitespace
  if ($parameter) { "`"$parameter`"" } else { $null }
}

function VersionParameter {
param (
  [String] $Version
)
  OptionalNamedParameter 'version' $Version
}

function NoPromptParameter {
param (
  [bool] $Enabled = $true
)
  SwitchParameter 'noprompt' $Enabled
}

function LocationParameter {
param (
  [String] $Location
)
  $Location = ($Location | DefaultIfBlank 'server')
  OptionalNamedParameter 'location' $Location
}

function PermissionParameter {
param (
  [String] $Permission
)
  $Permission = ($Permission | DefaultIfBlank 'private')
  OptionalNamedParameter 'permission' $Permission
}

function ComputerParameter {
param (
  [String] $ComputerName
)
  $ComputerName = ($ComputerName | DefaultIfBlank $env:COMPUTERNAME)
  OptionalNamedParameter 'computer' $ComputerName
}

function OwnerParameter {
param (
  [String] $OwnerName
)
  OptionalNamedParameter 'owner' $OwnerName
}

function SortParameter {
param (
  [String] $SortDirection
)
  OptionalNamedParameter 'sort' $SortDirection
}

function StopAfterParameter {
param (
  [Nullable[int]] $MaxEntries
)
  $MaxEntries = ($MaxEntries | Coalesce 0)
  $cmdArgs = @(
    'stopafter'
    if ($MaxEntries -lt 1) { $null } else { $MaxEntries }
  )
  OptionalNamedParameter @cmdArgs
}

function RecursiveParameter {
param (
  [bool] $Recurse
)
  SwitchParameter 'recursive' $Recurse
}

function FoldersParameter {
param (
  [bool] $FoldersOnly
)
  SwitchParameter 'folders' $FoldersOnly
}

function DeletedParameter {
param (
  [bool] $IncludeDeleted
)
  SwitchParameter 'deleted' $IncludeDeleted
}

function OptionalNamedParameter {
param (
  [Parameter(Mandatory)]
  [String] $Name,
  [String] $Value
)
  $Value = ($Value | DefaultIfBlank '')
  if ($Value -ne '') { Parameter $Name $Value } else { $null }
}

function SwitchParameter {
param (
  [Parameter(Mandatory)]
  [String] $Name,
  [bool] $Enabled = $true
)
  if ($Enabled) { Parameter $Name } else { $null }
}

function Parameter {
param (
  [Parameter(Mandatory)]
  [String] $Name,
  [String] $Value
)
  $Name = ($Name | Coalesce '')
  $Value = ($Value | Coalesce '')
  $parameter = $null
  if ($Name -ne '') {
    $parameter = '/' + $Name
    if ($Value -ne '')
    {
      $parameter += ':' + $Value
    }
  }
  else {
    $parameter = $Value
  }
  $parameter
}

function EscapeDoubleQuotes {
param (
  [String] $value
)
  # Simply replace with 'dos' two quotes escape sequence
  $value -replace '"', '""'
}

function CommandArguments {
  param (
    [Object[]] $cmdArgs
  )
  # flatten (1 level) and remove any nulls or blanks
  $outCmdArgs = $cmdArgs | 
    % { $_ } | 
    ? { (([String]$_) | DefaultIfBlank '') -ne '' }
  $outCmdArgs
}

function Coalesce {
param (
  [Object] $Default,
  [Parameter(ValueFromPipeline)]
  [Object[]] $Source
)
  Process {
    if ($_ -eq $null) { $Default } else { $_ }
  }
}

function DefaultIfBlank {
param (
  [String] $Default,
  [Parameter(ValueFromPipeline)]
  [String[]] $Source
)
  Process {
    $trimmedValue = ($_ | Coalesce '').Trim()
    if ($trimmedValue -eq '') { $Default } else { $_ }
  }
}

function ExportFunction {
  param (
    [Parameter(Mandatory)]
    [String] $Function,
    [String] $Alias
  )
  $Alias = ($Alias | Coalesce '')
  if ($Alias -ne '') {
    Set-Alias $Alias $Function -Scope:script
  }
  Export-ModuleMember @PSBoundParameters
}

ExportFunction New-TfsCloak Add-TfsCloak
ExportFunction New-TfsWorkFolderMapping Add-TfsWorkFolderMapping
ExportFunction New-TfsWorkspace Add-TfsWorkspace
ExportFunction Remove-TfsCloak Delete-TfsCloak
ExportFunction Remove-TfsWorkFolderMapping Delete-TfsWorkFolderMapping
ExportFunction Remove-TfsWorkspace Delete-TfsWorkspace
ExportFunction Show-TfsContent List-TfsContent
ExportFunction Show-TfsHistory List-TfsHistory
ExportFunction Show-TfsWorkspace List-TfsWorkspace
ExportFunction Invoke-TfsCommand
ExportFunction Invoke-TfsCommandAtLocation
