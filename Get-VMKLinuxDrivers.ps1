Function Get-VMKLinuxDrivers {
    param (
        [Parameter(Mandatory=$true)][string]$Cluster
    )
 
    $vmhosts = Get-Cluster $Cluster | Get-VMHost | where {$_.ConnectionState -eq "Connected"}
 
    $results = @()
    foreach ($vmhost in $vmhosts) {
        Write-Host "Checking $($vmhost.name) ..."
        $esxcli = Get-EsxCli -VMHost $vmhost -V2
        $modules = $esxcli.system.module.list.Invoke() | where {$_.IsLoaded -eq $true}
        $vmklinuxDrivers = @()
        foreach ($module in $modules) {
            $moduleName = $esxcli.system.module.get.CreateArgs()
            $moduleName.module = $module.name
            $vmkernelModule = $esxcli.system.module.get.Invoke($moduleName)
 
            if($vmkernelModule.RequiredNamespaces -match "com.vmware.driverAPI") {
                $vmklinuxDrivers += $module.name
            }
        }
 
        if($vmklinuxDrivers -ne $null) {
            $tmp = [pscustomobject] @{
                VMHost = $vmhost.name;
                VMKLinuxDriver = ($vmklinuxDrivers -join ",")
            }
            $results += $tmp
        }
    }
    $results | Sort-Object -Property VMHost | FT
}
 
