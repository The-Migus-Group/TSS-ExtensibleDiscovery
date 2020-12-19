<#
.SYNOPSIS
    Get Windows Accounts

.DESCRIPTION
    Gets local acccounts on a Windows Computer and returns the results
    in Thycotic Secret Server Extensible Discovery format.

Copyright 2020, The Migus Group, LLC. All rights reserved
#>
($Domain, $Username, $Password, $ComputerName) = $args;

(New-Object System.DirectoryServices.DirectoryEntry(
        "WinNT://${ComputerName}", "${Domain}\${Username}" , $Password
    )
).Children | Where-Object SchemaClassName -EQ 'User' |
Select-Object @{
    Name = "Username"; Expression = { $_.Name }
}, @{
    Name = "Resource"; Expression = { $ComputerName }
}, @{
    Name = "Disabled"; Expression = { $_.AccountDisabled }
}
