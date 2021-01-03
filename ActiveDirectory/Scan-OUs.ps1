<#
.SYNOPSIS
    Get Active Directory Organizational Units (OUs)

.DESCRIPTION
    Gets Active Directory OUs from the specified Domain Suffix and returns the
    results in Thycotic Secret Server Extensible Discovery format.

Copyright 2020, The Migus Group, LLC. All rights reserved
#>
($Domain, $Username, $Password, $SearchBase) = $args;

$ErrorActionPreference = 'Stop';

$ADParameters = @{
    SearchBase  = $SearchBase.Trim(',');
    Filter      = '*';
    SearchScope = 'Subtree';
    Credential  = New-Object System.Management.Automation.PSCredential (
        "${Domain}\${Username}", (ConvertTo-SecureString $Password -AsPlainText -Force)
    );
};

&{
    Get-ADOrganizationalUnit @ADParameters;

    if ($SearchBase.StartsWith('DC=')) {
        Get-ADObject -LDAPFilter '(&(ObjectClass=container)(|(Name=Computers)(Name=Users)))'
    }
} | Select-Object Name, ObjectGUID, @{
    Name       = 'DistinguishedName';
    Expression = {
        $_.DistinguishedName -Replace (',DC=.*', '')
    }
}, ObjectClass
