-- ZADANIE 2a i 2b
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'stg_dimemp')
BEGIN
	DROP TABLE AdventureWorksDW2022.dbo.stg_dimemp;
END

SELECT EmployeeKey, FirstName, LastName, Title 
INTO AdventureWorksDW2022.dbo.stg_dimemp
FROM dbo.DimEmployee
WHERE EmployeeKey BETWEEN 270 AND 275;

-- ZADANIE 2c
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'scd_dimemp')
BEGIN
	DROP TABLE AdventureWorksDW2022.dbo.scd_dimemp;
END

CREATE TABLE AdventureWorksDW2022.dbo.scd_dimemp (
	EmployeeKey int ,
	FirstName nvarchar(50) not null,
	LastName nvarchar(50) not null,
	Title nvarchar(50),
	StartDate datetime,
	EndDate datetime
);

-- ZADANIE 5b
update STG_DimEmp
set LastName = 'Nowak'
where EmployeeKey = 270;

update STG_DimEmp
set TITLE = 'Senior Design Engineer'
where EmployeeKey = 274;

-- ZADANIE 5c
update STG_DimEmp 
set FIRSTNAME = 'Ryszard' 
where EmployeeKey = 275

select * from stg_dimemp;
select * from scd_dimemp;

-- ZADANIE 6
-- zadanie 5b pierwsza kwerenda (LastName) -> Typ SCD 1 (nadpisanie)
-- zadanie 5b druga kwerenda (Title) -> Typ SCD 2 (dodanie nowego rekordu)
-- zadanie 5c (FirstName) -> Typ SCD 0 (pozostawienie orygina³u)

-- ZADANIE 7
-- Na dzia³anie procesu mia³o wp³yw ustawienie:
-- Fail the transformation if changes are detected in a fixed attribute (pkt. 4d), 
-- z powodu ustawienia Fixed attribute dla atrybutu FirstName 
-- (nastapi³a zmiana FirstName w tabeli stg_dimemp w wyniku kwerendy z 5c, wiêc proces zakoñczy³ siê niepowodzeniem)
