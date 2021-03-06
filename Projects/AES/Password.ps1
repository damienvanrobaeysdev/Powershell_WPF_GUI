##Initialize######
[System.Reflection.Assembly]::LoadWithPartialName('presentationframework') | out-null
[System.Reflection.Assembly]::LoadFrom('assembly\MahApps.Metro.dll')       | out-null 
[System.Reflection.Assembly]::LoadFrom('assembly\MahApps.Metro.IconPacks.dll') | out-null
[System.Reflection.Assembly]::LoadFrom('assembly\System.Windows.Interactivity.dll') | out-null
Add-Type -AssemblyName "System.Windows.Forms"
Add-Type -AssemblyName "System.Drawing"
[System.Windows.Forms.Application]::EnableVisualStyles()
[String]$ScriptDirectory = split-path $myinvocation.mycommand.path
#$ScriptDirectory =(get-location).path
function LoadXml ($global:filename)
{
    $XamlLoader=(New-Object System.Xml.XmlDocument)
    $XamlLoader.Load($filename)
    return $XamlLoader
}

# Load MainWindow
$XamlMainWindow=LoadXml("$ScriptDirectory\SecurePass.xaml")
$Reader=(New-Object System.Xml.XmlNodeReader $XamlMainWindow)
$Form=[Windows.Markup.XamlReader]::Load($Reader)

$Check = $Form.findname("Check")
$MakeSecure = $Form.findname("Save")
$passwordBox = $Form.findname("passwordBox")
$Utilisateur = $Form.findname("Utilisateur")
$Host_Connection = $Form.findname("Host_IP")
$Product = $form.findname("Product")
$Status_Connection_Info = $Form.findname("Status_C_NC")
#########################################################################
#                       Functions       								#
#########################################################################
function Test-RegKey {
	[cmdletbinding()]
	Param(
		[Parameter(Position=0)]
		[System.String]$Path,
		
		[Parameter(Position=1)]
		[System.String]$Key
	)

    if ($Key.IsPresent)
    {

    (Test-Path $Path) -and  (Get-ItemProperty $Path).$Key
    }
    else
        {
        (Test-Path $Path)
        }
    }
function New-RegKeyProduct
 {
     [CmdletBinding()]
     Param
     (
                 
         [Parameter(Mandatory = $true)]
         [ValidateSet("JM2K69")]   
         [String]$Author,
         [ValidateSet("StormShield","PhotonOS","Docker")]
         [String]$Product,
         [ValidateSet("AES_Key_Hash")]
         [Parameter(Mandatory = $true)]
         [String]$Key,
         $Value

     )
 
     $test = Test-RegKey -Path HKCU:\Software\$Author\$Product -Key $key
     $testA = Test-RegKey -Path HKCU:\Software\$Author
    if ($test -eq $true)
    { }
    else
    {
       if ($testA -eq $true)
       {
            New-Item -Path HKCU:\Software\$Author -Name $Product |Out-Null
            New-ItemProperty -path HKCU:\Software\$Author\$Product -Name $key -Value $Value |Out-Null

       }
       else
       {    
            New-Item -Path HKCU:\Software -Name $Author |Out-Null
            New-Item -Path HKCU:\Software\$Author -Name $Product |Out-Null
            New-ItemProperty -path HKCU:\Software\$Author\$Product -Name $key -Value $Value |Out-Null
        }

    }
    
        
    
 }
 function Read-RegKeyProduct
 {
     [CmdletBinding()]
     Param
     (
         [Parameter(Mandatory = $true)]
         [ValidateSet("JM2K69")]   
         [String]$Author,
         [String]$Product,
         [ValidateSet("AES_Key_Hash")]
         [Parameter(Mandatory = $true)]
         [String]$Key
         

     )
 
     $test = Test-RegKey -Path HKCU:\Software\$Author\$Product -Key $key
     
    if ($test -eq $true)
        { 
            $AESKey = (Get-ItemProperty -Path HKCU:\Software\$Author\$Product\ -Name $Key).AES_Key_Hash
            return  $AESKey
        }
    else
        {
            write-warning "Key not found" 
        }
    
 }
function Remove-RegKeyProduct{
     [CmdletBinding()]
     Param
     (
         [Parameter(Mandatory = $true)]
         [ValidateSet("JM2K69")]   
         [String]$Author,
         [String]$Product,
         [ValidateSet("AES_Key_Hash")]
         [Parameter(Mandatory = $true)]
         [String]$Key
         

     )
 
     $test = Test-RegKey -Path HKCU:\Software\$Author\$Product -Key $key 

    if ($test -eq $true)
        { 
            Remove-ItemProperty -Path HKCU:\Software\$Author\$Product\ -Name $Key -Confirm:$false
            Remove-Item -Path HKCU:\Software\$Author\$Product -Recurse -Confirm:$false
        }
    
 }

 function Test-AutoLogin  {
	
	$test = 0
	$KeyFile = $ScriptDirectory+"\"+"AES.key"
	$MgrCreds = $ScriptDirectory+"\"+"account_Creds.xml"
	
		If (Test-Path $KeyFile) {
		$test += 1
		}
		If (Test-Path $MgrCreds) {
			$test += 1
		}
				
        if ($test -eq 2) 
        {
        	[MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($Form,"Verification","Les fichiers necessaires sont presents." )

        }
        else 
        {
            [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($Form,"Verification","Les fichiers necessaires ne sont pas tous presents." )
        }


}

#########################################################################
#                            End Functions       					   #
#########################################################################


$MakeSecure.add_Click({
    $Product.SelectedIndex = 0
    $Product = $Product.SelectionBoxItem
    $ScriptDirectory = $ScriptDirectory+"\"+$Product
    if (!(test-path $ScriptDirectory )) {
        New-Item $ScriptDirectory -ItemType Directory | Out-Null
    }
    $KeyFile = $ScriptDirectory+"\"+"AES.key"
If (Test-Path $KeyFile){
My-logger "AES File Exists"
$Key = Get-Content $KeyFile
My-logger "Continuing..."
}
Else {
$Key = New-Object Byte[] 16   # You can use 16, 24, or 32 for AES
[Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($Key)
$Key | out-file $KeyFile
$hash=Get-FileHash $KeyFile
New-RegKeyProduct -Author JM2K69 -Product $Product -Key AES_Key_Hash -Value $hash.hash

}

	

	$MgrCreds = $ScriptDirectory+"\"+"account_Creds.xml"
	If (Test-Path $MgrCreds){
	$ImportObject = Import-Clixml $MgrCreds
	$SecureString = ConvertTo-SecureString -String $ImportObject.Password -Key $Key
	$UserName = $ImportObject.UserName.Split("#")[0]
	$Global:vcenter = $ImportObject.UserName.Split("#")[1]
	$MyCredential = New-Object System.Management.Automation.PSCredential($UserName, $SecureString)
	}
	Else {
	
	$Global:vcenter = $Host_Connection.text.tostring()
	$Global:User= $Utilisateur.text.tostring()
	$Global:pass_value = $PasswordBox.password.tostring()
	$Password = $Global:pass_value | ConvertTo-SecureString -AsPlainText -Force
	
	
	$exportObject = New-Object psobject -Property @{
		UserName = $Global:User+"#"+$Global:vcenter
		Password = ConvertFrom-SecureString -SecureString $password -Key $Key
	}

	$exportObject | Export-Clixml $MgrCreds
	$MyCredential = $newPScreds
	}
	
	[MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($Form,"Sauvegarde","Les donnees de connections ont bien ete sauvegardees." )



    })

$Check.add_Click({
    $Product.SelectedIndex = 0
    $Product = $Product.SelectionBoxItem
    $ScriptDirectory = $ScriptDirectory+"\"+$Product

    Test-AutoLogin
    $MgrCreds = $ScriptDirectory+"\"+"account_Creds.xml"
    $AES =  "$ScriptDirectory\AES.key"
    
    $testF1 = Test-Path $MgrCreds
    $testF2 = Test-Path $AES

    if ($testF1 -eq $true -and $testF2 -eq $true)
    {
   
            $FindKey = Test-RegKey -Path HKCU:\Software\JM2K69\$Product -Key AES_Key_Hash
            
            if ($FindKey -eq $false)
            {
               
                Remove-Item "$ScriptDirectory\AES.key" -Force | Out-Null
                Remove-Item $MgrCreds -Force | Out-Null
                
                [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($Form,"Securite","Des donnees sont manquantes par mesure de securite tous est supprimer." )


            }
            $readOriginalAES = Read-RegKeyProduct -Author JM2K69 -Product $Product -Key AES_Key_Hash 
            $HashRead = Get-FileHash "$ScriptDirectory\AES.key"
            $HashFinalRead = $HashRead.hash
            if ($FindKey -eq $true)
            {
                if($readOriginalAES -eq $HashFinalRead) 
                {
                    $Key = Get-Content  "$ScriptDirectory\AES.key"
                    $Status_Connection_Info.Content = "Integrite Ok de la cle AES."
                    $Status_Connection_Info.Foreground ="Green"
                }
                else
                {
                    $Status_Connection_Info.Content = "La cle AES a ete modifiee."
                    $Status_Connection_Info.Foreground ="Red"
                                
                    Remove-Item "$ScriptDirectory\AES.key" -Force | Out-Null
                    Remove-RegKeyProduct -Author JM2K69 -Product $Product -Key AES_Key_Hash
                    Remove-Item $MgrCreds -Force | Out-Null
                    
                    [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($Form,"Securite","Des donnees sont manquantes par mesure de securite tous est supprimer." )

                }
        }   

    }

})
	
$Product.SelectedIndex = 0
$Form.ShowDialog() | Out-Null

