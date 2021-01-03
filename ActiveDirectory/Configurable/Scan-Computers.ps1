<#
.SYNOPSIS
    Get Active Directory Computers according to parameters in an XML file

.DESCRIPTION
    Get Active Directory Computers from a specified list of OUs. The SearchBase,
    list of OUs, filters and excludes are specified in XML:

    <?xml version="1.0" encoding="utf-8"?>
    <!--
    Thycotic Secret Server Extensible Recovery PowerShell Script Configuration
    -->
    <discover-computers search-base="DC=example,DC=com">
        <!-- scan all OUs -->
        <!--<ous/>-->
        <!-- or scan only these OUs -->
        <ous>
            <ou>OU=Computers</ou>
        </ous>
        <filters>
            <!-- return every object -->
            <!--<filter>*</filter>-->
            <!-- or only return object matches these filters -->
            <filter>OperatingSystem -like 'Windows *'</filter>
        </filters>
        <!-- no exclusions -->
        <!-- <exclude/> -->
        <!-- or exclude computers (by ComputerName) or OUs from the result before returning -->
        <exclude>
            <computer name="Adam-PC" />
            <ou>OU=Baz,OU=Bar,OU=Foo</ou>
        </exclude>
        <!-- they will be ignored if they don't exist -->
    </discover-computers>

Copyright 2020, The Migus Group, LLC. All rights reserved
#>
($Domain, $Username, $Password, $OU, $XmlFilePath) = $args;

$ErrorActionPreference = 'Stop';

[XML]$xml = Get-Content -Path $XmlFilePath;

$SearchBase = $xml.'discover-computers'.'search-base';

ForEach ($filter in $xml.'discover-computers'.filters.filter) {
    $GetADComputerParameters = @{
        SearchBase  = $SearchBase;
        Filter      = $filter.'#text';
        SearchScope = $filter.scope;
        Credential  = [pscredential]::New(
            "${Domain}\${Username}", (ConvertTo-SecureString $Password -AsPlainText -Force)
        );
        Properties  = @('DistinguishedName', 'DNSHostName', 'Name', 'ObjectGuid', 'OperatingSystem');
    };

    if ($OU -ne $SearchBase) {
        $OuDn = '{0},{1}' -f $OU, $SearchBase.Trim(',');
        $OuList = $xml.'discover-computers'.ous.ou;

        if ($OuList -and $OU -notin $OuList) {
            continue
        }
        $GetADComputerParameters['SearchBase'] = $OuDn;
    }

    Get-ADComputer @GetADComputerParameters | Select-Object @{
        Name = 'ComputerName'; Expression = { $_.Name }
    }, DNSHostName, @{
        Name = 'ADGuid'; Expression = { $_.ObjectGUID }
    }, OperatingSystem, @{
        Name = 'DistinguishedName'; Expression = {
            $_.DistinguishedName -Replace (',DC=.*', '' )
        }
    } | Where-Object {
        $_.ComputerName -notin $xml.'discover-computers'.'exclude'.computer.name -and
        $_.DistinguishedName -replace 'CN=[^,]+,', '' -notin $xml.'discover-computers'.'exclude'.ou
    }
}
