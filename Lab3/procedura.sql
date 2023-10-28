-- =====================================================================================
-- Author:		Aleksandra Pe�ka
-- Create date: 	28.10.2023
-- Description:		Procedura zwracaj�ca dane dotycz�ce walut EUR i GBP sprzed x lat
-- =====================================================================================

CREATE PROCEDURE currency 
	-- a) parametr wej�ciowy okre�laj�cy kurs sprzed YearsAgo lat
	@YearsAgo int
AS
BEGIN

	SELECT * FROM dbo.FactCurrencyRate as fc
	INNER JOIN dbo.DimCurrency as dc ON fc.CurrencyKey = dc.CurrencyKey -- b) po��czenie tabel FactCurrencyRate i DimCurrency po odpowiedniej kolumnie,
	WHERE CurrencyAlternateKey IN('GBP', 'EUR') -- d) odfiltrowanie rekord�w dotycz�cych walut: GBP i EUR
	AND Date <= DATEADD(YEAR, -@YearsAgo, GETDATE()) -- c) odfiltrowanie rekord�w zawieraj�cych tylko dane sprzed YearsAgo lat
END

EXEC currency 12


-- 4. b) Co to jest Lookup No Match Output, co i kiedy zostanie tam zapisane?
-- To jedno z wyj�� komponentu Lookup, wykorzystywane do przechwycenia rekord�w, kt�re nie
-- pasuj� do kryteri�w ��czenia. Gdy przy u�yciu Lookup zostanie znaleziony taki rekord
-- automatycznie jest przekierowany do tego wyj�cia, po czym mo�na wykonywa� kolejne operacje
-- na rekordach, dla kt�rych nie znaleziono dopasowa�.

-- 9. e) jaka jest r�nica pomi�dzy kwerend�, a procesem ETL, wska� zalety i wady ETL?

-- Kwerenda to zwykle jedno zapytanie, kt�re pobiera dane z bazy w okre�lonym formacie
-- i przetwarza je na bie��co, co jest przydatne do tworzenia raport�w w czasie rzeczywistym.

-- ETL to proces polegaj�cy na pobieraniu danych z r�nych �r�de�, przekszta�caniu i umieszczaniu
-- ich w bazie docelowej. 
-- Zalety: 
-- zapewnia jednolito�� i wysok� jako�� danych
-- umo�liwia wykonywa� z�o�one operacje na du�ych zbiorach danych
-- mo�liwo�� utworzenia harmonogramu przetwarzania danych
-- Wady:
-- mog� wyst�pi� op�nienia w dostarczaniu danych z uwagi na wykonywanie skomplikowanych operacji
-- wysokie koszty zwi�zane z infrastruktur�
-- skomplikowana identyfikacja i analiza b��d�w

