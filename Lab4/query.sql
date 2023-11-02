-- wyświetlenie definicji tabeli w bazie Oracle

DESCRIBE TABLE dbo.FactInternetSales;

-- wyświetlenie informacji o kluczu obcym

SELECT
    CONSTRAINT_NAME,
    TABLE_NAME,
    COLUMN_NAME,
    R_CONSTRAINT_NAME,
    R_TABLE_NAME,
    R_COLUMN_NAME
FROM
    USER_CONS_COLUMNS
WHERE
    TABLE_NAME = 'dbo.FactInternetSales' AND CONSTRAINT_NAME LIKE 'FK%';


-- wyświetlenie definicji tabeli w bazie PostgreSQL

SELECT * FROM information_schema.columns
WHERE table_name = 'dbo.FactInternetSales';

-- wyświetlenie informacji o kluczu obcym

SELECT
    tc.constraint_name AS constraint_name,
    tc.table_name AS table_name,
    kcu.column_name AS column_name,
	tc.constraint_type AS key_type
FROM
    information_schema.table_constraints AS tc
    JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
WHERE
	tc.table_name = 'dbo.FactInternetSales';


-- wyświetlenie definicji tabeli w bazie MySQL

DESC dbo.FactInternetSales;

SHOW COLUMNS FROM dbo.FactInternetSales;

-- wyświetlenie informacji o kluczu obcym

SELECT
  CONSTRAINT_NAME,
  TABLE_NAME,
  COLUMN_NAME,
  REFERENCED_TABLE_NAME,
  REFERENCED_COLUMN_NAME
FROM
  INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE
  REFERENCED_TABLE_NAME IS NOT NULL
  AND TABLE_NAME = 'dbo.FactInternetSales';

