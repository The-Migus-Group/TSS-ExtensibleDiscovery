<#
.SYNOPSIS
Get Active Directory Organizational Units (OUs) according to parameters in an XML file

.DESCRIPTION
Gets Active Directory OUs from the specified Domain Suffix and returns the results in Thycotic Secret Server
Extensible Discovery format. The SearchBase, list of OUs and exclude list are specified in XML.
The list is filtered based on the OU and exclude lists.

Copyright 2021, The Migus Group, LLC. All rights reserved
#>
($Domain, $Username, $Password, $XmlFilePath) = $args;

$ErrorActionPreference = 'Stop';

[XML]$xml = Get-Content -Path $XmlFilePath;

$SearchBase = $xml.'discover-computers'.'search-base'.Trim(',');

$ADParameters = @{
    SearchBase  = $SearchBase;
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
}, ObjectClass | Where-Object {
    $_.DistinguishedName -match ($xml.'discover-computers'.ous.ou -join '|.*,?') -and
    $_.DistinguishedName -notin $xml.'discover-computers'.'exclude'.ou
}
