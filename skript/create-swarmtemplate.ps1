function New-IsoFile 
{  
  <#  
   .Synopsis  
    Creates a new .iso file  
   .Description  
    The New-IsoFile cmdlet creates a new .iso file containing content from chosen folders  
   .Example  
    New-IsoFile "c:\tools","c:Downloads\utils"  
    This command creates a .iso file in $env:temp folder (default location) that contains c:\tools and c:\downloads\utils folders. The folders themselves are included at the root of the .iso image.  
   .Example 
    New-IsoFile -FromClipboard -Verbose 
    Before running this command, select and copy (Ctrl-C) files/folders in Explorer first.  
   .Example  
    dir c:\WinPE | New-IsoFile -Path c:\temp\WinPE.iso -BootFile "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\efisys.bin" -Media DVDPLUSR -Title "WinPE" 
    This command creates a bootable .iso file containing the content from c:\WinPE folder, but the folder itself isn't included. Boot file etfsboot.com can be found in Windows ADK. Refer to IMAPI_MEDIA_PHYSICAL_TYPE enumeration for possible media types: http://msdn.microsoft.com/en-us/library/windows/desktop/aa366217(v=vs.85).aspx  
   .Notes 
    NAME:  New-IsoFile  
    AUTHOR: Chris Wu 
    LASTEDIT: 03/23/2016 14:46:50  
 #>
 
  [CmdletBinding(DefaultParameterSetName='Source')]Param( 
    [parameter(Position=1,Mandatory=$true,ValueFromPipeline=$true, ParameterSetName='Source')]$Source,  
    [parameter(Position=2)][string]$Path = "$env:temp\$((Get-Date).ToString('yyyyMMdd-HHmmss.ffff')).iso",  
    [ValidateScript({Test-Path -LiteralPath $_ -PathType Leaf})][string]$BootFile = $null, 
    [ValidateSet('CDR','CDRW','DVDRAM','DVDPLUSR','DVDPLUSRW','DVDPLUSR_DUALLAYER','DVDDASHR','DVDDASHRW','DVDDASHR_DUALLAYER','DISK','DVDPLUSRW_DUALLAYER','BDR','BDRE')][string] $Media = 'DVDPLUSRW_DUALLAYER', 
    [string]$Title = "OEMDRV",  
    [switch]$Force, 
    [parameter(ParameterSetName='Clipboard')][switch]$FromClipboard 
  ) 
  
  Begin {  
    ($cp = new-object System.CodeDom.Compiler.CompilerParameters).CompilerOptions = '/unsafe' 
    if (!('ISOFile' -as [type])) {  
      Add-Type -CompilerParameters $cp -TypeDefinition @'
public class ISOFile  
{ 
  public unsafe static void Create(string Path, object Stream, int BlockSize, int TotalBlocks)  
  {  
    int bytes = 0;  
    byte[] buf = new byte[BlockSize];  
    var ptr = (System.IntPtr)(&bytes);  
    var o = System.IO.File.OpenWrite(Path);  
    var i = Stream as System.Runtime.InteropServices.ComTypes.IStream;  
   
    if (o != null) { 
      while (TotalBlocks-- > 0) {  
        i.Read(buf, BlockSize, ptr); o.Write(buf, 0, bytes);  
      }  
      o.Flush(); o.Close();  
    } 
  } 
}  
'@  
    } 
   
    if ($BootFile) { 
      if('BDR','BDRE' -contains $Media) { Write-Warning "Bootable image doesn't seem to work with media type $Media" } 
      ($Stream = New-Object -ComObject ADODB.Stream -Property @{Type=1}).Open()  # adFileTypeBinary 
      $Stream.LoadFromFile((Get-Item -LiteralPath $BootFile).Fullname) 
      ($Boot = New-Object -ComObject IMAPI2FS.BootOptions).AssignBootImage($Stream) 
    } 
  
    $MediaType = @('UNKNOWN','CDROM','CDR','CDRW','DVDROM','DVDRAM','DVDPLUSR','DVDPLUSRW','DVDPLUSR_DUALLAYER','DVDDASHR','DVDDASHRW','DVDDASHR_DUALLAYER','DISK','DVDPLUSRW_DUALLAYER','HDDVDROM','HDDVDR','HDDVDRAM','BDROM','BDR','BDRE') 
  
    Write-Verbose -Message "Selected media type is $Media with value $($MediaType.IndexOf($Media))"
    ($Image = New-Object -com IMAPI2FS.MsftFileSystemImage -Property @{VolumeName=$Title}).ChooseImageDefaultsForMediaType($MediaType.IndexOf($Media)) 
   
    if (!($Target = New-Item -Path $Path -ItemType File -Force:$Force -ErrorAction SilentlyContinue)) { Write-Error -Message "Cannot create file $Path. Use -Force parameter to overwrite if the target file already exists."; break } 
  }  
  
  Process { 
    if($FromClipboard) { 
      if($PSVersionTable.PSVersion.Major -lt 5) { Write-Error -Message 'The -FromClipboard parameter is only supported on PowerShell v5 or higher'; break } 
      $Source = Get-Clipboard -Format FileDropList 
    } 
  
    foreach($item in $Source) { 
      if($item -isnot [System.IO.FileInfo] -and $item -isnot [System.IO.DirectoryInfo]) { 
        $item = Get-Item -LiteralPath $item
      } 
  
      if($item) { 
        Write-Verbose -Message "Adding item to the target image: $($item.FullName)"
        try { $Image.Root.AddTree($item.FullName, $true) } catch { Write-Error -Message ($_.Exception.Message.Trim() + ' Try a different media type.') } 
      } 
    } 
  } 
  
  End {  
    if ($Boot) { $Image.BootImageOptions=$Boot }  
    $Result = $Image.CreateResultImage()  
    [ISOFile]::Create($Target.FullName,$Result.ImageStream,$Result.BlockSize,$Result.TotalBlocks) 
    Write-Verbose -Message "Target image ($($Target.FullName)) has been created"
    $Target
  } 
} 

$managentvswitch = "vmxnet3 Ethernet Adapter - Virtual Switch"
$internalvswitch = "vmxnet3 Ethernet Adapter - Virtual Switch"

$destpath = "c:\vms"

# Stop script on error
$nameserver="192.168.143.252"
$netmask = "255.255.255.0"
$intnetmask = "255.255.0.0"
$ipgw = "192.168.143.254"
$intgw = "172.30.0.3"
$ErrorActionPreference = "stop"
$scsname = "scs-autoinstall"
$scsextip = "192.168.143.130" 
$scsintip = "172.30.0.3"
$esprefix = "es-autoinstall"
$esnum = "3"
$esextstartip = "192.168.143.131"
$esintstartip = "172.30.0.4"
$gwprefix = "gw-autoinstall"
$gwnum = "2"
$gwextstartip = "192.168.143.135"
$gwintstartip = "172.30.0.10"
$tmname = "tele-autoinstall"
$tmextip = "192.168.143.138"
$tmintip = "172.30.0.15"

#VM Resources
$scscores = 1
$scsmemory = 1 
$scsdisk0capacity = 161061273600
$escores = 1
$esmemory = 1 
$esdisk0capacity = 161061273600
$esdatadiskcapacity = 100000000000
$gwcores = 1
$gwmemory = 1 
$gwdisk0capacity = 161061273600
$tmdisk0capacity = 161061273600

#get CPU Frequency
$cpufrequency = $server.ExtensionData.summary.hardware.CpuMhz







#SCS Install
$createvm = $scsname
((Get-Content -path ..\ks.cfg -Raw) -replace 'centos7template',$scsname) | % {$_ -replace "192.168.143.99",$scsextip } | % {$_ -replace "192.168.143.254",$ipgw } | % {$_ -replace "255.255.255.0",$netmask } | % {$_ -replace "172.29.0.1",$scsintip } | % {$_ -replace "255.255.0.0",$intnetmask } | % {$_ -replace "192.168.143.253",$nameserver } | Set-Content -Path ..\iso\ks.cfg
$iso = New-IsoFile "C:\Users\Administrator\Desktop\deployswarmtemplate\iso\ks.cfg"
write-host "Creating SCS VM with Name: " $scsname " External IP: " $scsextip " and Internal IP: " $scsintip
#rite-host $iso
    $vmexist = hyper-v\get-vm -name $createvm -ErrorAction SilentlyContinue
    If (!$vmexist){
        
        
 #               $HW = $minimal -match "Anvil"
                $cores = $scscores
                $memory = $scsmemory
                $disk0capacity = $scsdisk0capacity
                
                
            [string]$memgb = $memory.ToString() + "GB"
            [uint64]$memorystartupbytes = ($memgb / [uint64]1)
            
            $bootdrivefilename = $destpath + "\" + $createvm + "\" + $createvm + "-0.vhdx"    
            $newvm = new-vm -Name $createvm -Path $destpath -NewVHDPath $bootdrivefilename -NewVHDSizeBytes $disk0capacity  -Generation 2 -MemoryStartupBytes $memorystartupbytes
            Connect-VMNetworkAdapter -vmname $createvm -SwitchName $managentvswitch
            add-VMNetworkAdapter -vmname $createvm -SwitchName $internalvswitch
            Add-VMDvdDrive -vmname $newvm.Name -Path "..\CentOS-7-x86_64-DVD-2009.iso"
            $dvd = get-vmdvddrive -VMName $newvm.Name
            Add-VMDvdDrive -vmname $newvm.Name -Path $iso

            Set-VMFirmware -VMName $newvm.vmname -EnableSecureBoot Off -FirstBootDevice $dvd
            Set-VMProcessor $newvm.name -count $cores -reserve 100
            
           
    
        }


#}
    else
    {
    write-host "VM "  $createvm  " existiert bereits. Nichts zu tun!"
    }

start-vm $createvm


#ES install
for ($i=0; $i -lt $esnum; $i++){
$createvm = $esprefix + ($i + 1)
$essplitip = @()
$essplitip = $esextstartip.split(".")
$esaktip = $essplitip[0] + "." + $essplitip[1] + "." + $essplitip[2] + "." + ([int]$essplitip[3] + [int]$i +1)
$esintsplitip = $esintstartip.split(".")
$esintaktip = $esintsplitip[0] + "." + $esintsplitip[1] + "." + $esintsplitip[2] + "." + ([int]$esintsplitip[3] + [int]$i +1)

#Write-Host $esintaktip
((Get-Content -path ..\ks.cfg -Raw) -replace 'centos7template',$createvm) | % {$_ -replace "192.168.143.99",$esaktip } | % {$_ -replace "192.168.143.254",$ipgw } | % {$_ -replace "255.255.255.0",$netmask } | % {$_ -replace "172.29.0.1",$esintaktip } | % {$_ -replace "255.255.0.0",$intnetmask }  | % {$_ -replace "192.168.143.253",$nameserver } | Set-Content -Path ..\iso\ks.cfg
$iso = New-IsoFile "C:\Users\Administrator\Desktop\deployswarmtemplate\iso\ks.cfg"
write-host "Creating ES VM with Name: " $createvm " External IP: " $esaktip " and Internal IP: " $esintaktip

    $vmexist = hyper-v\get-vm -name $createvm -ErrorAction SilentlyContinue
    If (!$vmexist){
        
        

                $cores = $escores
                $memory = $esmemory
                $disk0capacity = $esdisk0capacity
                
                
            [string]$memgb = $memory.ToString() + "GB"
            [uint64]$memorystartupbytes = ($memgb / [uint64]1)
            
            $bootdrivefilename = $destpath + "\" + $createvm + "\" + $createvm + "-0.vhdx"    
            $datadrivefilename = $destpath + "\" + $createvm + "\" + $createvm + "-1.vhdx"    
            $newvm = new-vm -Name $createvm -Path $destpath -NewVHDPath $bootdrivefilename -NewVHDSizeBytes $disk0capacity  -Generation 2 -MemoryStartupBytes $memorystartupbytes
            New-VHD -SizeBytes $esdatadiskcapacity -Path $datadrivefilename
            Add-VMHardDiskDrive -vmname $createvm -Path $datadrivefilename  
            Connect-VMNetworkAdapter -vmname $createvm -SwitchName $managentvswitch
            add-VMNetworkAdapter -vmname $createvm -SwitchName $internalvswitch
            Add-VMDvdDrive -vmname $newvm.Name -Path "..\CentOS-7-x86_64-DVD-2009.iso"
            $dvd = get-vmdvddrive -VMName $newvm.Name
            Add-VMDvdDrive -vmname $newvm.Name -Path $iso

            Set-VMFirmware -VMName $newvm.vmname -EnableSecureBoot Off -FirstBootDevice $dvd
            Set-VMProcessor $newvm.name -count $cores -reserve 100
            
           
    
        }


#}
    else
    {
    write-host "VM "  $createvm  " existiert bereits. Nichts zu tun!"
    }
}

#GW install
for ($i=0; $i -lt $gwnum; $i++){
$createvm = $gwprefix + ($i +1)
$gwsplitip = @()

$gwsplitip = $gwextstartip.split(".")

$gwaktip = $gwsplitip[0] + "." + $gwsplitip[1] + "." + $gwsplitip[2] + "." + ([int]$gwsplitip[3] + [int]$i +1)
$gwintsplitip = $gwintstartip.split(".")
$gwintaktip = $gwintsplitip[0] + "." + $gwintsplitip[1] + "." + $gwintsplitip[2] + "." + ([int]$gwintsplitip[3] + [int]$i +1)

((Get-Content -path ..\ks.cfg -Raw) -replace 'centos7template',$createvm) | % {$_ -replace "192.168.143.99",$gwaktip } | % {$_ -replace "192.168.143.254",$ipgw } | % {$_ -replace "255.255.255.0",$netmask } | % {$_ -replace "172.29.0.1",$gwintaktip } | % {$_ -replace "255.255.0.0",$intnetmask } | % {$_ -replace "192.168.143.253",$nameserver } | Set-Content -Path ..\iso\ks.cfg
$iso = New-IsoFile "C:\Users\Administrator\Desktop\deployswarmtemplate\iso\ks.cfg"
write-host "Creating GW VM with Name: " $createvm " External IP: " $gwaktip " and Internal IP: " $gwintaktip
#write-host $iso

    $vmexist = hyper-v\get-vm -name $createvm -ErrorAction SilentlyContinue
    If (!$vmexist){
        
                $cores = $gwcores
                $memory = $gwmemory
                $disk0capacity = $gwdisk0capacity

                
                
            [string]$memgb = $memory.ToString() + "GB"
            [uint64]$memorystartupbytes = ($memgb / [uint64]1)
            
            $bootdrivefilename = $destpath + "\" + $createvm + "\" + $createvm + "-0.vhdx"    
            $newvm = new-vm -Name $createvm -Path $destpath -NewVHDPath $bootdrivefilename -NewVHDSizeBytes $disk0capacity  -Generation 2 -MemoryStartupBytes $memorystartupbytes
            Connect-VMNetworkAdapter -vmname $createvm -SwitchName $managentvswitch
            add-VMNetworkAdapter -vmname $createvm -SwitchName $internalvswitch
            Add-VMDvdDrive -vmname $newvm.Name -Path "..\CentOS-7-x86_64-DVD-2009.iso"
            $dvd = get-vmdvddrive -VMName $newvm.Name
            Add-VMDvdDrive -vmname $newvm.Name -Path $iso

            Set-VMFirmware -VMName $newvm.vmname -EnableSecureBoot Off -FirstBootDevice $dvd
            Set-VMProcessor $newvm.name -count $cores -reserve 100
            
           
    
        }


#}
    else
    {
    write-host "VM "  $createvm  " existiert bereits. Nichts zu tun!"
    }
}

#Telemetry Install
$createvm = $tmname

((Get-Content -path ..\ks.cfg -Raw) -replace 'centos7template',$tmname) | % {$_ -replace "192.168.143.99",$tmextip } | % {$_ -replace "192.168.143.254",$ipgw } | % {$_ -replace "255.255.255.0",$netmask } | % {$_ -replace "172.29.0.1",$tmintip } | % {$_ -replace "255.255.0.0",$intnetmask }  | % {$_ -replace "192.168.143.253",$nameserver } | Set-Content -Path ..\iso\ks.cfg
$iso = New-IsoFile "C:\Users\Administrator\Desktop\deployswarmtemplate\iso\ks.cfg"
write-host "Creating Telemetry VM with Name: " $createvm " External IP: " $tmextip " and Internal IP: " $tmintip
#write-host $iso
    $vmexist = hyper-v\get-vm -name $createvm -ErrorAction SilentlyContinue
    If (!$vmexist){
        
        
 
                $cores = $scscores
                $memory = $scsmemory
                $disk0capacity = $tmdisk0capacity
                
                
            [string]$memgb = $memory.ToString() + "GB"
            [uint64]$memorystartupbytes = ($memgb / [uint64]1)
            
            $bootdrivefilename = $destpath + "\" + $createvm + "\" + $createvm + "-0.vhdx"    
            $newvm = new-vm -Name $createvm -Path $destpath -NewVHDPath $bootdrivefilename -NewVHDSizeBytes $disk0capacity  -Generation 2 -MemoryStartupBytes $memorystartupbytes
            Connect-VMNetworkAdapter -vmname $createvm -SwitchName $managentvswitch
            add-VMNetworkAdapter -vmname $createvm -SwitchName $internalvswitch
            Add-VMDvdDrive -vmname $newvm.Name -Path "..\CentOS-7-x86_64-DVD-2009.iso"
            $dvd = get-vmdvddrive -VMName $newvm.Name
            Add-VMDvdDrive -vmname $newvm.Name -Path $iso

            Set-VMFirmware -VMName $newvm.vmname -EnableSecureBoot Off -FirstBootDevice $dvd
            Set-VMProcessor $newvm.name -count $cores -reserve 100
            
           
    
        }


#}
    else
    {
    write-host "VM "  $createvm  " existiert bereits. Nichts zu tun!"
    }

