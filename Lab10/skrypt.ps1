#*********************** BAZY DANYCH PRZESTRZENNYCH II - automatyzacja przetwarzania ***********************

#Data utworzenia skryptu: 16.12.2023 21:27:34
#Autor: Aleksandra Pełka - 404407 

#Skrypt automatycznie pobiera, następnie rozpakowuje i sprawdza poprawność pliku. Przefiltrowane dane
#są umieszczane w tabeli w bazie danych oraz wyeksportowane do pliku .csv. 
#W pliku .log umieszczone są informacje dotyczące czasu wykonania i poprawności danego etapu przetwarzania.
#Skrypt wymaga uruchomienia z podaniem 2 parametrów: ścieżki gdzie wypakować pobrany plik i numeru indeksu. 
#Pozostałe parametry są opcjonalne.  

param (
    $sciezkaGdzieWypakowacPlik,
    $nrIndeksu,
    $uzytkownik = "postgres",
    $adresUrl = "http://home.agh.edu.pl/~wsarlej/dyd/bdp2/materialy/cw10/InternetSales_new.zip",
    $WinRAR = "C:\Program Files\WinRAR\WinRAR.exe",
    $lokalizacjaPostgres = 'C:\Program Files\PostgreSQL\13\bin\',
    $separator = '|'
)

$hasloDoArchiwum = Read-Host -Prompt "Podaj hasło do archiwum" -AsSecureString
$hasloDoArchiwum = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($hasloDoArchiwum))
$hasloDoArchiwum = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($hasloDoArchiwum))

$hasloDoBazy = Read-Host -Prompt "Podaj hasło do bazy danych" -AsSecureString
$hasloDoBazy = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($hasloDoBazy)) 
$hasloDoBazy = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($hasloDoBazy))

$aktualnaData = Get-Date 
${TIMESTAMP}  = "{0:MM-dd-yyyy}" -f ($aktualnaData) 

$sciezka = "$sciezkaGdzieWypakowacPlik\Processing"
$podkatalog = "$sciezka\PROCESSED"

$nazwaSkryptu = [System.IO.Path]::GetFileName($MyInvocation.MyCommand.Name)
$nazwaSkryptuBezRozszerzenia = [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Name)
$sciezkaDoSkryptu = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
$sciezkaDoSkryptu = "$sciezkaDoSkryptu\$nazwaSkryptu"
$plikLog = "$podkatalog\$nazwaSkryptuBezRozszerzenia" + "_${TIMESTAMP}.log"


if(Test-Path $sciezka)
{
    Remove-Item -Path $sciezka -Recurse -Force
}
else
{
    New-Item -Path $sciezka -ItemType Directory | Out-Null

}
New-Item -Path $podkatalog -ItemType Directory | Out-Null


$dataUtworzeniaSkryptu = Get-ItemProperty $sciezkaDoSkryptu | Format-Wide -Property CreationTime
"*************** BAZY DANYCH PRZESTRZENNYCH II - automatyzacja przetwarzania ***************`n`nData utworzenia skryptu: " > $plikLog
$dataUtworzeniaSkryptu >> $plikLog


function rozdzielKolumny
{
    param($wiersz)

    $wiersz -split "\$separator"
}

function wyczyscSecretCode
{
    param($wiersz, $indeks)

    if($wiersz.Count-1 -ge $indeks)
    {
        $wiersz[$indeks] = ""
    }
        
    $wiersz -join $separator
}

function zwrocDate
{
    param()

    $data = Get-Date
    $data = "{0:yyyy-MM-dd HH:mm:ss}" -f ($data) 
    $data
}

function zapiszDoPlikuLog
{
    param($komunikat)

    $pobierzDate = zwrocDate
    $pobierzDate + " - $komunikat - SUKCES!" >> $plikLog
}


$postep = 10
$dataRozpoczecia = zwrocdate
Write-Host "*** PRZETWARZANIE ROZPOCZĘTE:`t$dataRozpoczecia ***`n..." -ForegroundColor Green


#A)--------------------------------------------- POBRANIE PLIKU --------------------------------------------------

try
{
    $nazwaPlikuZip = [System.IO.Path]::GetFileName($adresUrl)
    $plik = "$sciezka\$nazwaPlikuZip"

    $webclient = New-Object System.Net.WebClient
    $webclient.DownloadFile($adresUrl, $plik)

    
    Write-Progress -Activity "Postęp przetwarzania" -Status "UKOŃCZONO: Pobranie pliku" -PercentComplete $postep
    zapiszDoPlikuLog("Pobranie pliku")
}
catch
{
    Write-Warning "Pobranie pliku nie powiodło się."
}


#B)--------------------------------------------- ROZPAKOWANIE PLIKU ----------------------------------------------

try
{
    $haslo = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($hasloDoArchiwum))

    Set-Location $sciezka
    Start-Process "$WinRAR" -ArgumentList "x -y `"$plik`" -p$haslo" 

    $postep += 10
    Write-Progress -Activity "Postęp przetwarzania" -Status "UKOŃCZONO: Rozpakowanie pliku" -PercentComplete $postep
    zapiszDoPlikuLog("Rozpakowanie pliku")
}
catch
{
    Write-Warning "Rozpakowanie pliku nie powiodło się."
}


#C)--------------------------------------------- POPRAWNOŚĆ PLIKU ------------------------------------------------

try
{
    sleep 5
    $zawartoscFolderu = Get-ChildItem -Path $sciezka -Filter *.txt
    $nazwaPliku = $zawartoscFolderu.Name
    $zawartoscPliku = Get-Content "$sciezka\$nazwaPliku"

    $naglowek = $zawartoscPliku[0]
    $zawartoscPliku = $zawartoscPliku | Select-Object -Skip 1
    
    #-------------------------------------- pozostawienie unikalnych wierszy --------------------------------------
    $unikalneWiersze = @()
    $zawartoscPlikuBad = @()

    $zawartoscPliku | Group-Object | ForEach-Object {
        if ($_.Count -gt 1) 
        {
            $zawartoscPlikuBad += $_.Name #nieunikalne wiersze
        } 
        else 
        {
            $unikalneWiersze += $_.Name #unikalne wiersze
        }
    }

    $postep += 10
    Write-Progress -Activity "Postęp przetwarzania" -Status "UKOŃCZONO: Sprawdzanie unikalnych wierszy" -PercentComplete $postep

    #------------------------------------------ dalsze filtrowanie pliku ----------------------------------------
    $przefiltrowaneDane = @()
    $podzielonyNaglowek = rozdzielKolumny($naglowek)

    $indeksOrderQuantity = $podzielonyNaglowek.IndexOf("OrderQuantity")
    $indeksSecretCode = $podzielonyNaglowek.IndexOf("SecretCode")
    $indeksCustomerName = $podzielonyNaglowek.IndexOf("Customer_Name")
    $maxLiczbaZnakow = 50

    foreach($linia in $unikalneWiersze)
    {
        $podzielonaLinia = rozdzielKolumny($linia) 

        # puste wiersze
        $liczbaBrakow = $podzielonaLinia | Where-Object { $_ -eq "" } | Measure-Object | Select-Object -ExpandProperty Count
        $wszystkiePusteKolumny = $liczbaBrakow -eq $podzielonaLinia.Count 

        # wiersze z inną liczbą kolumn niż nagłówek
        $wierszeZRoznaLiczbaKolumn = $podzielonaLinia.Count -ne $podzielonyNaglowek.Count
        
        #OrderQuantity > 100 
        $orderQuantityPozaZakresem = $podzielonaLinia[$indeksOrderQuantity] -gt 100
        
        if(($linia -eq "") -or ($wszystkiePusteKolumny) -or ($wierszeZRoznaLiczbaKolumn) -or ($orderQuantityPozaZakresem))
        {
            # wyczyszczenie SecretCode
            $polaczonaLinia = wyczyscSecretCode $podzielonaLinia $indeksSecretCode
            $zawartoscPlikuBad += $polaczonaLinia
        }
        else
        {
            # sprawdzenie formatu CustomerName 
            $customerName = $podzielonaLinia[$indeksCustomerName].Trim('"').Split(",")
            $liczbaPrzecinkow = $customerName.Count 

            if($liczbaPrzecinkow -ne 2)
            {
                # wyczyszczenie SecretCode
                $polaczonaLinia = wyczyscSecretCode $podzielonaLinia $indeksSecretCode
                $zawartoscPlikuBad += $polaczonaLinia
            }
            else
            {
                #sprawdzenie czy w nazwie klienta są znaki specjalne
                $znakiSpecjalne = $false
                $imieNazwisko = $customerName[0] + $customerName[1]

                foreach($znak in $imieNazwisko.ToCharArray())
                {
                    if([char]::IsLetter($znak) -eq $false -and $znak -ne '-')
                    {
                        $znakiSpecjalne = $true
                        break
                    }
                }

                # podział CustomerName na Last Name i First Name
                $podzieloneDane = $podzielonaLinia[0..($indeksCustomerName - 1)] + $customerName + $podzielonaLinia[($indeksCustomerName + 1)..($podzielonaLinia.Count - 1)]
                $prekroczonoMaxLiczbeZnakow = $false

                foreach($dana in $podzieloneDane)
                {
                    if($dana.Length -gt $maxLiczbaZnakow)
                    {
                        $prekroczonoMaxLiczbeZnakow = $true
                        break
                    }
                }

                if($prekroczonoMaxLiczbeZnakow -or $znakiSpecjalne)
                {
                    $polaczonaLinia = wyczyscSecretCode $podzielonaLinia $indeksSecretCode
                    $zawartoscPlikuBad += $polaczonaLinia
                }
                else
                {
                    $polaczoneDane = $podzieloneDane -join $separator
                    $przefiltrowaneDane += $polaczoneDane
                }
                $prekroczonoMaxLiczbeZnakow = $false
                $znakiSpecjalne = $false      
            }
        }
    }
  
    $noweKolumny = @('LAST_NAME', 'FIRST_NAME')
    $nowyNaglowek = $podzielonyNaglowek[0..($indeksCustomerName - 1)] + $noweKolumny + $podzielonyNaglowek[($indeksCustomerName + 1)..($podzielonyNaglowek.Count - 1)] -join '|'
    
    $przefiltrowaneDane = @($nowyNaglowek, $przefiltrowaneDane)
    $przefiltrowaneDane > "$sciezka\$nazwaPliku"

    $zawartoscPlikuBad = @($naglowek, $zawartoscPlikuBad)
    $zawartoscPlikuBad > "$sciezka\InternetSales_new.bad_${TIMESTAMP}"


    $postep += 10
    Write-Progress -Activity "Postęp przetwarzania" -Status "UKOŃCZONO: Sprawdzanie poprawności pliku" -PercentComplete $postep
    zapiszDoPlikuLog("Poprawność pliku")
}
catch
{
    Write-Warning "Sprawdzenie poprawności pliku nie powiodło się."
}


#D)------------------------------------------ TWORZENIE TABELI W POSTGRESQL --------------------------------------------
 
try
{
    #Install-Module PostgreSQLCmdlets
    Set-Location $lokalizacjaPostgres

    $User = $uzytkownik
    $env:PGPASSWORD = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($hasloDoBazy))
    $Database = "postgres"
    $NewDatabase = "lab10_customers"
    $newTable = "CUSTOMERS_$nrIndeksu"
    $Port = "5432"
    $mlz = $maxLiczbaZnakow

    psql -U $User -d $Database -w -c "DROP DATABASE IF EXISTS $NewDatabase" 2>&1 | Out-Null

    psql -U $User -d $Database -w -c "CREATE DATABASE $NewDatabase" | Out-Null
    psql  -U $User -d $NewDatabase -w -c "CREATE TABLE $newTable (ProductKey INT, CurrencyAlternateKey VARCHAR($mlz), LastName VARCHAR($mlz), FirstName VARCHAR($mlz), OrderDateKey VARCHAR($mlz), OrderQuantity INT, UnitPrice VARCHAR($mlz), SecretCode VARCHAR($mlz))" | Out-Null


    $postep += 10
    Write-Progress -Activity "Postęp przetwarzania" -Status "UKOŃCZONO: Tworzenie tabeli w PostgreSQL" -PercentComplete $postep
    zapiszDoPlikuLog("Tworzenie tabeli w PostgreSQL")
}
catch
{
    Write-Warning "Utworzenie tabeli nie powiodło się."
}


#E)-------------------------------------------- WCZYTANIE DANYCH Z PLIKU DO BAZY -----------------------------------------

try
{
    $poprawnyPlik = $przefiltrowaneDane | ConvertFrom-Csv -Delimiter $separator

    for($i=0; $i -lt $poprawnyPlik.Count; $i++)
    {
        $ProductKey = $poprawnyPlik[$i].ProductKey
        $CurrencyAlternateKey = "'" + $poprawnyPlik[$i].CurrencyAlternateKey + "'"
        $LastName = "'" + $poprawnyPlik[$i].LAST_NAME + "'"
        $FirstName = "'" + $poprawnyPlik[$i].FIRST_NAME + "'"
        $OrderDateKey = "'" + $poprawnyPlik[$i].OrderDateKey + "'"
        $OrderQuantity = $poprawnyPlik[$i].OrderQuantity
        $poprawnyPlik[$i].UnitPrice = $poprawnyPlik[$i].UnitPrice -replace ",", "." 
        $UnitPrice = "'" + $poprawnyPlik[$i].UnitPrice + "'"
        $SecretCode = "'" + $poprawnyPlik[$i].SecretCode + "'"

        psql -U $User -d $NewDatabase -w -c "INSERT INTO $newTable (ProductKey, CurrencyAlternateKey, LastName, FirstName, OrderDateKey, OrderQuantity, UnitPrice, SecretCode) VALUES($ProductKey, $CurrencyAlternateKey, $LastName, $FirstName, $OrderDateKey, $OrderQuantity, $UnitPrice, $SecretCode)" | Out-Null
    }


    $postep += 10
    Write-Progress -Activity "Postęp przetwarzania" -Status "UKOŃCZONO: Wczytanie danych z pliku do bazy" -PercentComplete $postep
    zapiszDoPlikuLog("Wczytanie danych z pliku do bazy")
}
catch
{
    Write-Warning "Wczytanie danych z pliku do bazy nie powiodło się."
}


#------------------------------------------------ PRZENIESIENIE PLIKU ---------------------------------------------------

try
{
    Set-Location $sciezka
    $nowaNazwaPliku = ${TIMESTAMP} + "_$nazwaPliku"

    Move-Item -Path "$sciezka\$nazwaPliku" -Destination $podkatalog -PassThru -ErrorAction Stop | Out-Null
    Rename-Item -Path "$podkatalog\$nazwaPliku" "$nowaNazwaPliku"

    $postep += 10
    Write-Progress -Activity "Postęp przetwarzania" -Status "UKOŃCZONO: Przeniesienie pliku" -PercentComplete $postep
    zapiszDoPlikuLog("Przeniesienie pliku")
}
catch
{
    Write-Warning "Przeniesienie pliku nie powiodło się."
}


#------------------------------------------- AKTUALIZACJA KOLUMNY SECRETCODE --------------------------------------------

try
{
    foreach($klient in $poprawnyPlik)
    {
        $firstName = "'" + $klient.FIRST_NAME + "'"
        $lastName = "'" + $klient.LAST_NAME + "'"

        $losowyString = (48..57 + 65..90 + 97..122) | Get-Random -Count 10 | ForEach-Object {[char]$_}
        $losowyString = $losowyString -join ""
        $losowyString =  "'" + $losowyString  + "'"

        psql -U $User -d $NewDatabase -w -c "UPDATE $newTable SET SecretCode=$losowyString WHERE FirstName=$firstName AND LastName=$lastName" | Out-Null
    }

    $postep += 10
    Write-Progress -Activity "Postęp przetwarzania" -Status "UKOŃCZONO: Aktualizacja kolumny SecretCode" -PercentComplete $postep
    zapiszDoPlikuLog("Aktualizacja kolumny SecretCode")
}
catch
{
    Write-Warning "Aktualizacja kolumny SecretCode nie powiodła się."
}


#------------------------------------------------------- EKSPORT ------------------------------------------------------

try
{
    $zaktualizowanaTabela = psql -U $User -d $NewDatabase -w -c "SELECT * FROM $newTable" 
    $plikWyjsciowy = @()

    for ($i=2; $i -lt $zaktualizowanaTabela.Count-2; $i++)
    {
        $dane = New-Object -TypeName PSObject
        $dane | Add-Member -Name 'ProductKey' -MemberType Noteproperty -Value $zaktualizowanaTabela[$i].Split( "|")[0].replace(" ", "")
        $dane | Add-Member -Name 'CurrencyAlternateKey' -MemberType Noteproperty -Value $zaktualizowanaTabela[$i].Split( "|")[1].replace(" ", "")
        $dane | Add-Member -Name 'LastName' -MemberType Noteproperty -Value $zaktualizowanaTabela[$i].Split( "|")[2].replace(" ", "")
        $dane | Add-Member -Name 'FirstName' -MemberType Noteproperty -Value $zaktualizowanaTabela[$i].Split( "|")[3].replace(" ", "")
        $dane | Add-Member -Name 'OrderDateKey' -MemberType Noteproperty -Value $zaktualizowanaTabela[$i].Split( "|")[4].replace(" ", "")
        $dane | Add-Member -Name 'OrderQuantity' -MemberType Noteproperty -Value $zaktualizowanaTabela[$i].Split( "|")[5].replace(" ", "")
        $dane | Add-Member -Name 'UnitPrice' -MemberType Noteproperty -Value $zaktualizowanaTabela[$i].Split( "|")[6].replace(" ", "")
        $dane | Add-Member -Name 'SecretCode' -MemberType Noteproperty -Value $zaktualizowanaTabela[$i].Split( "|")[7].replace(" ", "")
        $plikWyjsciowy += $dane
    }

    $nazwaPlikuBezRozszerzenia = [System.IO.Path]::GetFileNameWithoutExtension($nazwaPliku)
    $plikWyjsciowy | Export-Csv -Path "$sciezka\$nazwaPlikuBezRozszerzenia.csv" -NoTypeInformation

    #$zapiszDoPlikuCsv = $plikWyjsciowy | ConvertTo-Csv -Delimiter ',' -NoTypeInformation | % {$_ -replace '"',''}
    #$zapiszDoPlikuCsv > "$sciezka\$nazwaPlikuBezRozszerzenia-bezExport.csv"


    $postep += 10
    Write-Progress -Activity "Postęp przetwarzania" -Status "UKOŃCZONO: Eksport do pliku .csv" -PercentComplete $postep
    zapiszDoPlikuLog("Eksport do pliku .csv")
}
catch
{
    Write-Warning "Eksport do pliku nie powiódł się."
}


#------------------------------------------------------ KOMPRESJA -----------------------------------------------------

try
{
    $nazwaArchiwum = [System.IO.Path]::GetFileName($adresUrl)
    Remove-Item -Path "$sciezka\$nazwaArchiwum" | Out-Null

    Compress-Archive -Path "$sciezka\$nazwaPlikuBezRozszerzenia.csv" -DestinationPath "$sciezka\$nazwaPlikuBezRozszerzenia.zip" | Out-Null

    $postep += 10
    Write-Progress -Activity "Postęp przetwarzania" -Status "UKOŃCZONO: Kompresja do .zip" -PercentComplete $postep
    zapiszDoPlikuLog("Kompresja do .zip")
}
catch
{
    Write-Warning "Kompresja do .zip nie powiodła się."
}

$dataZakonczenia = zwrocdate
Write-Host "*** PRZETWARZANIE ZAKOŃCZONE:`t$dataZakonczenia ***" -ForegroundColor Green