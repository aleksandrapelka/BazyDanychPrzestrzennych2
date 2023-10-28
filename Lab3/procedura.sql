-- =====================================================================================
-- Author:		Aleksandra Pe³ka
-- Create date: 	28.10.2023
-- Description:		Procedura zwracaj¹ca dane dotycz¹ce walut EUR i GBP sprzed x lat
-- =====================================================================================

CREATE PROCEDURE currency 
	-- a) parametr wejœciowy okreœlaj¹cy kurs sprzed YearsAgo lat
	@YearsAgo int
AS
BEGIN

	SELECT * FROM dbo.FactCurrencyRate as fc
	INNER JOIN dbo.DimCurrency as dc ON fc.CurrencyKey = dc.CurrencyKey -- b) po³¹czenie tabel FactCurrencyRate i DimCurrency po odpowiedniej kolumnie,
	WHERE CurrencyAlternateKey IN('GBP', 'EUR') -- d) odfiltrowanie rekordów dotycz¹cych walut: GBP i EUR
	AND Date <= DATEADD(YEAR, -@YearsAgo, GETDATE()) -- c) odfiltrowanie rekordów zawieraj¹cych tylko dane sprzed YearsAgo lat
END

EXEC currency 12


-- 4. b) Co to jest Lookup No Match Output, co i kiedy zostanie tam zapisane?
-- To jedno z wyjœæ komponentu Lookup, wykorzystywane do przechwycenia rekordów, które nie
-- pasuj¹ do kryteriów ³¹czenia. Gdy przy u¿yciu Lookup zostanie znaleziony taki rekord
-- automatycznie jest przekierowany do tego wyjœcia, po czym mo¿na wykonywaæ kolejne operacje
-- na rekordach, dla których nie znaleziono dopasowañ.

-- 9. e) jaka jest ró¿nica pomiêdzy kwerend¹, a procesem ETL, wska¿ zalety i wady ETL?

-- Kwerenda to zwykle jedno zapytanie, które pobiera dane z bazy w okreœlonym formacie
-- i przetwarza je na bie¿¹co, co jest przydatne do tworzenia raportów w czasie rzeczywistym.

-- ETL to proces polegaj¹cy na pobieraniu danych z ró¿nych Ÿróde³, przekszta³caniu i umieszczaniu
-- ich w bazie docelowej. 
-- Zalety: 
-- zapewnia jednolitoœæ i wysok¹ jakoœæ danych
-- umo¿liwia wykonywaæ z³o¿one operacje na du¿ych zbiorach danych
-- mo¿liwoœæ utworzenia harmonogramu przetwarzania danych
-- Wady:
-- mog¹ wyst¹piæ opóŸnienia w dostarczaniu danych z uwagi na wykonywanie skomplikowanych operacji
-- wysokie koszty zwi¹zane z infrastruktur¹
-- skomplikowana identyfikacja i analiza b³êdów

