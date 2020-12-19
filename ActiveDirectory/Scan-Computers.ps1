<#
.SYNOPSIS
    Get Active Directory Computers

.DESCRIPTION
    Gets Active Directory Computers from the specified OU and returns the
    results in Thycotic Secret Server Extensible Discovery format.

Copyright 2020, The Migus Group, LLC. All rights reserved
#>
($Domain, $Username, $Password, $OU, $Filter, $SearchBase) = $args;

$ErrorActionPreference = 'Stop';

$GetADComputerParameters = @{
    SearchBase  = $SearchBase;
    Filter      = $Filter;
    SearchScope = 'Subtree';
    Credential  = New-Object System.Management.Automation.PSCredential (
        "${Domain}\${Username}", (
            ConvertTo-SecureString "${Password}" -AsPlainText -Force
        )
    );
    Properties  = @(
        'DistinguishedName', 'DNSHostName', 'Name', 'ObjectGuid', 'OperatingSystem'
    );
};

if ($OU -ne $SearchBase) {
    $GetADComputerParameters['SearchBase'] = "{0},{1}" -f $OU, $SearchBase.Trim(',')
}
Get-ADComputer @GetADComputerParameters | Select-Object @{
    Name = 'ComputerName'; Expression = { $_.Name }
}, DNSHostName, @{
    Name = 'ADGuid'; Expression = { $_.ObjectGUID }
}, OperatingSystem, @{
    Name       = 'DistinguishedName';
    Expression = { $_.DistinguishedName -Replace (',DC=.*', '' ) }
}
