# ======================================================= 
# NAME: PrinterMap-prod.ps1 
# AUTHOR: Gildas MBAKI 
# DATE: 23/09/2021
# VERSION 1.0
#
#
# COMMENTS: Mapper les imprimantes utilisateurs depuis SRV-XXXX
#
# 
# Requires -Version 5.0 
# ======================================================= 



Clear-Host

# Variables
$printServer = "SRV-XXXX" # Serveur de fichier
$InstalledPrinters  # Imprimantes locales
$AvailablePrinters  # Imprimantes disponibles sur le serveur d'impression (Droits NTFS)
$ScopePrinter       # Filtre les imprimantes a installer
$InstallPrinters    # Imprimantes a installer


# Fonction qui v�rifie les imprimantes locales

function CheckLocalPrinters {
    param (
        
    )
    
    $LocalPrinters = Get-Printer | where {$_.Name -like "*\\*"} | select Name,ShareName #,PortName,Computername,DriverName

    if ( $null -eq $LocalPrinters) {

        $LocalPrinters = ""
    }

    Return $LocalPrinters

}



# Fonction qui v�rifie les imprimantes disponibles sur le serveur

function CheckServerPrinters {
    param (
        [String]$Server
    )

    $SharedPrinters = Get-Printer -ComputerName $Server | select Name,ShareName #,PortName,Computername,DriverName

    Return $SharedPrinters
    
}




# Fonction qui installe les imprimantes 
#   Paremetre : $Printerlist = liste des imprimantes a installer
#               $Server = Nom du serveur d'impression
#

function InstallPrinters {
    param (
        $PrinterList,$Server)
    
    "
    ====== Chargement des imprimantes ==============
    "

        foreach ($printer in $PrinterList) {

            $PrinterName = $printer.Name
            $PrinterShareName = $printer.ShareName
            
            "Installation de l'imprimante $PrinterName, $PrinterShareName " 
        
            
                try {
                    Add-Printer -ConnectionName \\$Server\$PrinterShareName -Verbose
                }
                catch {

                    #Write-Warning $Error[0]
                    Write-Warning "Erreur de l'installation"
        
                }

                Start-Sleep 1

        }

            "Chargememet des imprimantes termin�"

 }

    
# Main


    # R�cup�ration des imprimantes locales
    $InstalledPrinters = CheckLocalPrinters #| select -ExpandProperty ShareName 

    # R�cup�ration des imprimantes sur le serveur
    $AvailablePrinters =  CheckServerPrinters -Server $printServer

    # Compare la liste des imprimantes install�e avec le serveur
    $ScopePrinter = Compare-Object $InstalledPrinters $AvailablePrinters  -Property ShareName | where { $_.SideIndicator -eq "=>"} | select -ExpandProperty ShareName

    # R�cup�re la liste des imprimantes a installer en fonction du filtre
    $InstallPrinters = $AvailablePrinters | Where-Object {$ScopePrinter -contains $_.ShareName }

    "Imprimantes sur le poste
    "
    $InstalledPrinters

    "
    Imprimantes disponibles
    "
    $AvailablePrinters
    "
    Imprimantes manquantes
    "
    $InstallPrinters


    # si des imprimantes sont a d�ployer, on les installe. Sinon on ne fait rien
    if ($null -ne $InstallPrinters) {
        
        InstallPrinters -Server $printServer -PrinterList $InstallPrinters
    }

    else {
        "
        Toutes les imprimantes sont sur le poste
        "
    }

