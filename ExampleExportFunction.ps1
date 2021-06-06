function Example_Export
{
    param($Name,$EXOLocation,$SPOLocation,$Destination)
    "Creating new compliance search"
    $ComplianceSearch=New-ComplianceSearch -Name $Name -ExchangeLocation $EXOLocation -SharePointLocation $SPOLocation
    Start-ComplianceSearch -Identity $ComplianceSearch.Name
    "Awaiting for compliance search to execute"
    while ((Get-ComplianceSearch -Identity $ComplianceSearch.Name).Status -ne "Completed")
    {
        Write-Host -NoNewline "."
        Start-Sleep -Seconds 5
    }
    "`nCreating new search action for export"
    if ((Get-ComplianceSearch -Identity $ComplianceSearch.Name).Status -eq "Completed")
    {
	$ComplianceSearchAction=New-ComplianceSearchAction -SearchName $ComplianceSearch.Name -IncludeCredential -Export
    }
    "Awaiting for search action to complete"
    while ((Get-ComplianceSearchAction -Identity $ComplianceSearchAction.Name).Status -ne "Completed")
    {
        Write-Host -NoNewline "."
        Start-Sleep -Seconds 5
    }
    "`nAwaiting data to be prepared"
    $PercentComplete=0
    while ($PercentComplete -ne "100")
    {
        $Results=(Get-ComplianceSearchAction -Identity $ComplianceSearchAction.Name -Details).Results
        if ($Results -like "*Progress*")
        {
            $PercentComplete = $Results.Split(";")[22].Trim().Split(" ")[1].Split(".")[0]
        }
        Write-Host -NoNewline "."
        Start-Sleep -Seconds 5
    }

    "`nSearch Export Completed"
    # Split container URL and SAS token
    $Container=$ComplianceSearchAction.Results.Split(";")[0].Trim().Split(" ")[2]
    $SAStoken=$ComplianceSearchAction.Results.Split(";")[1].Trim().Split(" ")[2]

    if ($Container -and $SAStoken)
    {
        "Using AzCopy to download data - edit this to match your location"
	.\azcopy copy "$($Container)$($SAStoken)" $Destination --recursive
    }
   
}

#Connect-IPPSSession
#Example_Export -Name "ExampleSearch1" -EXOLocation "stevetest@stevieg.org" -SPOLocation "https://stevegoodman-my.sharepoint.com/personal/stevetest_stevieg_org/" -Destination ".\" 