--------------- CREATE WWI_DM USER ----------------
ALTER session set "_ORACLE_SCRIPT" = true;
CREATE USER wwidmuser identified by wwidmuser;
GRANT ALL PRIVILEGES TO wwidmuser;
SELECT * FROM all_users ORDER BY Created DESC;



--------------- REQUIREMENT 1 ----------------
/* CREATE DIMENSIONAL MODEL TABLES */

/*DROP TABLES */
DROP TABLE DimCustomers CASCADE CONSTRAINTS; 
DROP TABLE DimLocation CASCADE CONSTRAINTS; 
DROP TABLE DimProducts CASCADE CONSTRAINTS; 
DROP TABLE DimSalesPeople CASCADE CONSTRAINTS;
DROP TABLE DimSupplier CASCADE CONSTRAINTS; 
DROP TABLE DimDate CASCADE CONSTRAINTS; 
DROP TABLE FactSales;



--Create DimCustomers Table (Type 2 SCD)
CREATE TABLE DimCustomers(  
	CustomerKey                 NUMBER(10),
	CustomerName                NVARCHAR2(100) NULL,
	CustomerCategoryName        NVARCHAR2(50) NULL,
	DeliveryCityName            NVARCHAR2(50) NULL,
	DeliveryStateProvCode       NVARCHAR2(5) NULL,
	DeliveryCountryName         NVARCHAR2(50) NULL,
	PostalCityName              NVARCHAR2(50) NULL,
	PostalStateProvCode         NVARCHAR2(5) NULL,
	PostalCountryName           NVARCHAR2(50) NULL,
	StartDate                   DATE NOT NULL,
	EndDate                     DATE NULL,
    CONSTRAINT PK_DimCustomers PRIMARY KEY ( CustomerKey )
);


--Create DimLocation Table (Type 1 SCD)
CREATE TABLE DimLocation(  
	LocationKey 	    NUMBER(10),
	CityName            NVARCHAR2(50) NULL,
	StateProvCode 	    NVARCHAR2(5) NULL,
	StateProvName 	    NVARCHAR2(50) NULL,
	CountryName 	    NVARCHAR2(60) NULL,
	CountryFormalName   NVARCHAR2(60) NULL,
    CONSTRAINT PK_DimLocation PRIMARY KEY ( LocationKey )
);


--Create DimProducts Table (Type 2 SCD)
CREATE TABLE DimProducts(   
	ProductKey          NUMBER(10),
	ProductName 	    NVARCHAR2(100) NULL,
	ProductColour 	    NVARCHAR2(20) NULL,
	ProductBrand 	    NVARCHAR2(50) NULL,
	ProductSize 	    NVARCHAR2(20) NULL,
	StartDate           DATE NOT NULL,
	EndDate             DATE NULL,
    CONSTRAINT PK_DimProducts PRIMARY KEY ( ProductKey )
);


--Create DimSalesPeople Table (Type 1 SCD)
CREATE TABLE DimSalesPeople(    
	SalespersonKey      NUMBER(10),
	FullName            NVARCHAR2(50) NULL,
	PreferredName       NVARCHAR2(50) NULL,
	LogonName           NVARCHAR2(50) NULL,
	PhoneNumber         NVARCHAR2(20) NULL,
	FaxNumber           NVARCHAR2(20) NULL,
	EmailAddress        NVARCHAR2(256) NULL,
    CONSTRAINT PK_DimSalesPeople PRIMARY KEY (SalespersonKey )
);


--Create DimSuppliers Table (Type 2 SCD)
CREATE TABLE DimSupplier (
    SupplierKey             NUMBER(10) NOT NULL,
    FullName                NVARCHAR2(100) NULL,
    SupplierCategoryName    NVARCHAR2(50) NULL,
    PhoneNumber             NVARCHAR2(20) NULL,
    FaxNumber               NVARCHAR2(20) NULL,
    WebsiteURL              NVARCHAR2(256) NULL,
    StartDate               DATE NOT NULL,
    EndDate                 DATE NULL,
    CONSTRAINT PK_DimSupplier PRIMARY KEY (SupplierKey)
);


--Create DimDate Table (Type 0 SCD)
CREATE TABLE DimDate (
    DateKey         NUMBER(10) NOT NULL,
    DateValue       DATE NOT NULL,
    CYear           NUMBER(10) NOT NULL,
    CQtr            NUMBER(1) NOT NULL,
    CMonth          NUMBER(2) NOT NULL,
    DayNo           NUMBER(2) NOT NULL,
    StartOfMonth    DATE NOT NULL,
    EndOfMonth      DATE NOT NULL,
    MonthName       VARCHAR2(9) NOT NULL,
    DayOfWeekName   VARCHAR2(9) NOT NULL,    
    CONSTRAINT PK_DimDate PRIMARY KEY ( DateKey )
);



--Create FactSales Table
CREATE TABLE FactSales (
    CustomerKey      	NUMBER(10) NOT NULL,
    LocationKey      	NUMBER(10) NOT NULL,
    ProductKey       	NUMBER(10) NOT NULL,
    SalespersonKey   	NUMBER(10) NOT NULL,
    SupplierKey         NUMBER(10) NOT NULL, --ADDED SUPPLIER KEY
    DateKey 	      	NUMBER(8) NOT NULL,
    Quantity 	      	NUMBER(4) NOT NULL,
    UnitPrice        	NUMBER(18,2) NOT NULL,
    TaxRate 	      	NUMBER(18,3) NOT NULL,
    TotalBeforeTax   	NUMBER(18,2) NOT NULL,
    TotalAfterTax    	NUMBER(18,2) NOT NULL,
    
    CONSTRAINT FK_FactSales_DimCustomers FOREIGN KEY (CustomerKey) REFERENCES DimCustomers(CustomerKey),
    CONSTRAINT FK_FactSales_DimLocation FOREIGN KEY (LocationKey) REFERENCES DimLocation(LocationKey),
    CONSTRAINT FK_FactSales_DimProducts FOREIGN KEY (ProductKey) REFERENCES DimProducts(ProductKey),
    CONSTRAINT FK_FactSales_DimSalesPeople FOREIGN KEY (SalesPersonKey) REFERENCES DimSalesPeople(SalesPersonKey),
    CONSTRAINT FK_FactSales_DimSupplier FOREIGN KEY (SupplierKey) REFERENCES DimSupplier(SupplierKey),
    CONSTRAINT FK_FactSales_DimDate FOREIGN KEY (DateKey) REFERENCES DimDate(DateKey)
);


--Create indexes on foreign keys
CREATE INDEX IX_FactSales_CustomerKey       ON FactSales(CustomerKey);
CREATE INDEX IX_FactSales_LocationKey       ON FactSales(LocationKey);
CREATE INDEX IX_FactSales_ProductKey        ON FactSales(ProductKey);
CREATE INDEX IX_FactSales_SalesPersonKey    ON FactSales(SalesPersonKey);
CREATE INDEX IX_FactSales_SupplierKey       ON FactSales(SupplierKey);
CREATE INDEX IX_FactSales_DateKey           ON FactSales(DateKey);


--------------- REQUIREMENT 2 ----------------
/* STORED PROCEDURE TO POPULATE DIMDATE TABLE */





--------------- REQUIREMENT 3 ----------------
/* Create Compelling Warehouse Query */



--------------- REQUIREMENT 4 ----------------
/* (1) Create Stage Tables and (2)stored procedure to extract data from source table and load into the stage tables */



-------- CUSTOMERS STAGE TABLE AND EXTRACT ---------
DROP TABLE Customers_Stage;

CREATE TABLE Customers_Stage (
    CustomerName NVARCHAR2(100),
    CustomerCategoryName NVARCHAR2(50),
    DeliveryCityName NVARCHAR2(50),
    DeliveryStateProvinceCode NVARCHAR2(5),
    DeliveryStateProvinceName NVARCHAR2(50),
    DeliveryCountryName NVARCHAR2(50),
    DeliveryFormalName NVARCHAR2(60),
    PostalCityName NVARCHAR2(50),
    PostalStateProvinceCode NVARCHAR2(5),
    PostalStateProvinceName NVARCHAR2(50),
    PostalCountryName NVARCHAR2(50),
    PostalFormalName NVARCHAR2(60)
);


CREATE OR REPLACE PROCEDURE Customers_Extract 
IS
    RowCt NUMBER(10):=0;
    v_sql VARCHAR(255) := 'TRUNCATE TABLE wwidmuser.Customers_Stage DROP STORAGE';
BEGIN
    EXECUTE IMMEDIATE v_sql;

    INSERT INTO wwidmuser.Customers_Stage
    WITH CityDetails AS (
        SELECT ci.CityID,
               ci.CityName,
               sp.StateProvinceCode,
               sp.StateProvinceName,
               co.CountryName,
               co.FormalName
        FROM wwidbuser.Cities ci
        LEFT JOIN wwidbuser.StateProvinces sp
            ON ci.StateProvinceID = sp.StateProvinceID
        LEFT JOIN wwidbuser.Countries co
            ON sp.CountryID = co.CountryID 
    )
    
    SELECT cust.CustomerName,
           cat.CustomerCategoryName,
           dc.CityName,
           dc.StateProvinceCode,
           dc.StateProvinceName,
           dc.CountryName,
           dc.FormalName,
           pc.CityName,
           pc.StateProvinceCode,
           pc.StateProvinceName,
           pc.CountryName,
           pc.FormalName
    FROM wwidbuser.Customers cust
    LEFT JOIN wwidbuser.CustomerCategories cat
        ON cust.CustomerCategoryID = cat.CustomerCategoryID
    LEFT JOIN CityDetails dc
        ON cust.DeliveryCityID = dc.CityID
    LEFT JOIN CityDetails pc
        ON cust.PostalCityID = pc.CityID;

    RowCt := SQL%ROWCOUNT;
    DBMS_OUTPUT.PUT_LINE('Number of customers added: ' || TO_CHAR(SQL%ROWCOUNT));
END;


EXECUTE Customers_Extract;
SELECT COUNT(*) FROM Customers_Stage;
SELECT * FROM Customers_Stage;


-------- PRODUCTS STAGE TABLE AND EXTRACT ---------
DROP TABLE Products_Stage;

CREATE TABLE Products_Stage (
    StockItemName   NVARCHAR2(100),
    Brand           NVARCHAR2(50),
    ItemSize        NVARCHAR2(20),
    ColorName       NVARCHAR2(20)
);


CREATE OR REPLACE PROCEDURE Products_Extract 
IS
    RowCt    NUMBER(10):=  0;
    v_sql   VARCHAR(255) := 'TRUNCATE TABLE wwidmuser.Products_Stage DROP STORAGE';
BEGIN
    EXECUTE IMMEDIATE v_sql;
    
    INSERT INTO wwidmuser.Products_Stage
    
    SELECT  s.StockItemName,
            s.Brand,
            s.ItemSize,
            c.ColorName
    FROM wwidbuser.StockItems s
    LEFT JOIN wwidbuser.Colors c
        ON s.ColorID = c.ColorID;
    
    RowCt := SQL%ROWCOUNT;
    DBMS_OUTPUT.PUT_LINE('Number of products added: '|| TO_CHAR(RowCt));
END;


EXECUTE Products_Extract;
SELECT COUNT(*) FROM Products_Stage;
SELECT * FROM Products_Stage;


--------- SALESPEOPLE STAGE TABLE AND EXTRACT ---------
DROP TABLE SalesPeople_Stage;

CREATE TABLE SalesPeople_Stage (
    FullName            NVARCHAR2(50) NULL,
	PreferredName       NVARCHAR2(50) NULL,
	LogonName           NVARCHAR2(50) NULL,
	PhoneNumber         NVARCHAR2(20) NULL,
	FaxNumber           NVARCHAR2(20) NULL,
	EmailAddress        NVARCHAR2(256) NULL
);


CREATE OR REPLACE PROCEDURE SalesPeople_Extract 
IS 
    RowCT NUMBER(10):=0;
    v_sql VARCHAR2(255) := 'TRUNCATE TABLE wwidmuser.SalesPeople_Stage DROP STORAGE';
BEGIN
    EXECUTE IMMEDIATE v_sql;
    
    INSERT INTO SalesPeople_Stage
    
    SELECT  FullName,
            PreferredName,
            LogonName,
            PhoneNumber,
            FaxNumber,
            EmailAddress
    FROM wwidbuser.People
    WHERE isSalesPerson = 1;
    
    RowCt := SQL%ROWCOUNT;
    DBMS_OUTPUT.PUT_LINE('Number of sales people added: '|| TO_CHAR(RowCt));
END;

EXECUTE SalesPeople_Extract;
SELECT COUNT(*) FROM SalesPeople_Stage;
SELECT * FROM SalesPeople_Stage;


--- ORDERS -----








--- SUPPLIERS -----








--------------- REQUIREMENT 5 ----------------
/* (1) Create Preload Staging Tables and (2)stored procedure to perform transformations of the source to destination data */


-------- CUSTOMERS PRELOAD TABLE AND TRANSFORMATION ---------
DROP TABLE Customers_Preload;

CREATE TABLE Customers_Preload (
   CustomerKey              NUMBER(10) NOT NULL,
   CustomerName             NVARCHAR2(100) NULL,
   CustomerCategoryName     NVARCHAR2(50) NULL,
   DeliveryCityName         NVARCHAR2(50) NULL,
   DeliveryStateProvCode    NVARCHAR2(5) NULL,
   DeliveryCountryName      NVARCHAR2(50) NULL,
   PostalCityName           NVARCHAR2(50) NULL,
   PostalStateProvCode      NVARCHAR2(5) NULL,
   PostalCountryName        NVARCHAR2(50) NULL,
   StartDate                DATE NOT NULL,
   EndDate                  DATE NULL,
   CONSTRAINT PK_Customers_Preload PRIMARY KEY ( CustomerKey )
);

CREATE SEQUENCE CustomerKey START WITH 1;


CREATE OR REPLACE PROCEDURE Customers_Transform
AS
  RowCt NUMBER(10);
  v_sql VARCHAR(255) := 'TRUNCATE TABLE Customers_Preload DROP STORAGE';
  StartDate DATE := SYSDATE; 
  EndDate DATE := SYSDATE - 1;
BEGIN
    EXECUTE IMMEDIATE v_sql;
 --BEGIN TRANSACTION;
 -- Add updated records
    INSERT INTO Customers_Preload /* Column list excluded for brevity */
    SELECT CustomerKey.NEXTVAL AS CustomerKey,
           stg.CustomerName,
           stg.CustomerCategoryName,
           stg.DeliveryCityName,
           stg.DeliveryStateProvinceCode,
           stg.DeliveryCountryName,
           stg.PostalCityName,
           stg.PostalStateProvinceCode,
           stg.PostalCountryName,
           StartDate,
           NULL
    FROM Customers_Stage stg
    JOIN DimCustomers cu
        ON stg.CustomerName = cu.CustomerName AND cu.EndDate IS NULL
    WHERE stg.CustomerCategoryName <> cu.CustomerCategoryName
          OR stg.DeliveryCityName <> cu.DeliveryCityName
          OR stg.DeliveryStateProvinceCode <> cu.DeliveryStateProvCode
          OR stg.DeliveryCountryName <> cu.DeliveryCountryName
          OR stg.PostalCityName <> cu.PostalCityName
          OR stg.PostalStateProvinceCode <> cu.PostalStateProvCode
          OR stg.PostalCountryName <> cu.PostalCountryName;

    -- Add existing records, and expire as necessary
    INSERT INTO Customers_Preload /* Column list excluded for brevity */
    SELECT cu.CustomerKey,
           cu.CustomerName,
           cu.CustomerCategoryName,
           cu.DeliveryCityName,
           cu.DeliveryStateProvCode,
           cu.DeliveryCountryName,
           cu.PostalCityName,
           cu.PostalStateProvCode,
           cu.PostalCountryName,
           cu.StartDate,
           CASE 
               WHEN pl.CustomerName IS NULL THEN NULL
               ELSE cu.EndDate
           END AS EndDate
    FROM DimCustomers cu
    LEFT JOIN Customers_Preload pl    
        ON pl.CustomerName = cu.CustomerName
        AND cu.EndDate IS NULL;
 -- Create new records
    INSERT INTO Customers_Preload /* Column list excluded for brevity */
    SELECT CustomerKey.NEXTVAL AS CustomerKey,
           stg.CustomerName,
           stg.CustomerCategoryName,
           stg.DeliveryCityName,
           stg.DeliveryStateProvinceCode,
           stg.DeliveryCountryName,
           stg.PostalCityName,
           stg.PostalStateProvinceCode,
           stg.PostalCountryName,
           StartDate,
           NULL
    FROM Customers_Stage stg
    WHERE NOT EXISTS ( SELECT 1 FROM DimCustomers cu WHERE stg.CustomerName = cu.CustomerName );
    -- Expire missing records
    INSERT INTO Customers_Preload /* Column list excluded for brevity */
    SELECT cu.CustomerKey,
           cu.CustomerName,
           cu.CustomerCategoryName,
           cu.DeliveryCityName,
           cu.DeliveryStateProvCode,
           cu.DeliveryCountryName,
           cu.PostalCityName,
           cu.PostalStateProvCode,
           cu.PostalCountryName,
           cu.StartDate,
           EndDate
    FROM DimCustomers cu
    WHERE NOT EXISTS ( SELECT 1 FROM Customers_Stage stg WHERE stg.CustomerName = cu.CustomerName )
          AND cu.EndDate IS NULL;

    RowCt := SQL%ROWCOUNT;
    dbms_output.put_line(TO_CHAR(RowCt) ||' Rows have been inserted!');
--COMMIT TRANSACTION;
  EXCEPTION
    WHEN OTHERS THEN
       dbms_output.put_line(SQLERRM);
       dbms_output.put_line(v_sql);
END;


EXECUTE Customers_Transform;
SELECT COUNT(*) FROM Customers_Preload;
SELECT * FROM Customers_Preload;



-------- LOCATION PRELOAD TABLE AND TRANSFORMATION ---------
DROP TABLE Locations_Preload;

CREATE TABLE Locations_Preload (
    LocationKey         NUMBER(10) NOT NULL,	
    CityName            NVARCHAR2(50) NULL,
    StateProvCode       NVARCHAR2(5) NULL,
    StateProvName       NVARCHAR2(50) NULL,
    CountryName         NVARCHAR2(60) NULL,
    CountryFormalName   NVARCHAR2(60) NULL,
    CONSTRAINT PK_Location_Preload PRIMARY KEY (LocationKey)
);


CREATE SEQUENCE LocationKey START WITH 1;


CREATE OR REPLACE PROCEDURE Locations_Transform
AS
  RowCt NUMBER(10);
  v_sql VARCHAR(255) := 'TRUNCATE TABLE Locations_Preload DROP STORAGE';
BEGIN
    EXECUTE IMMEDIATE v_sql;
    INSERT INTO Locations_Preload /* Column list excluded for brevity */
    SELECT LocationKey.NEXTVAL AS LocationKey,
           cu.DeliveryCityName,
           cu.DeliveryStateProvinceCode,
           cu.DeliveryStateProvinceName,
           cu.DeliveryCountryName,
           cu.DeliveryFormalName
    FROM Customers_Stage cu
    WHERE NOT EXISTS 
	( SELECT 1 
              FROM DimLocation ci
              WHERE cu.DeliveryCityName = ci.CityName
                AND cu.DeliveryStateProvinceName = ci.StateProvName
                AND cu.DeliveryCountryName = ci.CountryName 
        );
        
    INSERT INTO Locations_Preload /* Column list excluded for brevity */
    SELECT ci.LocationKey,
           cu.DeliveryCityName,
           cu.DeliveryStateProvinceCode,
           cu.DeliveryStateProvinceName,
           cu.DeliveryCountryName,
           cu.DeliveryFormalName
    FROM Customers_Stage cu
    JOIN DimLocation ci
        ON cu.DeliveryCityName = ci.CityName
        AND cu.DeliveryStateProvinceName = ci.StateProvName
        AND cu.DeliveryCountryName = ci.CountryName;
    
    RowCt := SQL%ROWCOUNT;
    IF sql%notfound THEN
       dbms_output.put_line('No records found. Check with source system.');
    ELSIF sql%found THEN
       dbms_output.put_line(TO_CHAR(RowCt) ||' Rows have been inserted!');
    END IF;
    
  EXCEPTION
    WHEN OTHERS THEN
       dbms_output.put_line(SQLERRM);
       dbms_output.put_line(v_sql);
END;

EXECUTE Locations_Transform;
SELECT count(*) FROM Locations_Preload;
SELECT * FROM Locations_Preload;


-------- PRODUCTS PRELOAD TABLE AND TRANSFORMATION ---------
DROP TABLE Products_Preload;


CREATE TABLE Products_Preload (
    ProductKey          NUMBER(10),
	ProductName 	    NVARCHAR2(100) NULL,
	ProductColour 	    NVARCHAR2(20) NULL,
	ProductBrand 	    NVARCHAR2(50) NULL,
	ProductSize 	    NVARCHAR2(20) NULL,
	StartDate           DATE NOT NULL,
	EndDate             DATE NULL,
    CONSTRAINT PK_Products_Preload PRIMARY KEY ( ProductKey )
);

CREATE SEQUENCE ProductKey START WITH 1;

CREATE OR REPLACE PROCEDURE Products_Transform
AS
  RowCt NUMBER(10);
  v_sql VARCHAR(255) := 'TRUNCATE TABLE Products_Preload DROP STORAGE';
  StartDate DATE := SYSDATE; 
  EndDate DATE := SYSDATE - 1;
BEGIN
    EXECUTE IMMEDIATE v_sql;

 -- Add updated records
    INSERT INTO Products_Preload 
    SELECT ProductKey.NEXTVAL AS ProductKey,
           stg.StockItemName,
           stg.ColorName,
           stg.Brand,
           stg.ItemSize,
           StartDate,
           NULL
    FROM Products_Stage stg
    JOIN DimProducts cu
        ON stg.StockItemName = cu.ProductName AND cu.EndDate IS NULL
    WHERE stg.Brand <> cu.ProductBrand
          OR stg.ItemSize <> cu.ProductSize
          OR stg.ColorName <> cu.ProductColour;

    -- Add existing records, and expire as necessary
    INSERT INTO Products_Preload 
    SELECT cu.ProductKey,
           cu.ProductName,
           cu.ProductColour,
           cu.ProductBrand,
           cu.ProductSize,
           cu.StartDate,
           CASE 
               WHEN pl.ProductName IS NULL THEN NULL
               ELSE cu.EndDate
           END AS EndDate
    FROM DimProducts cu
    LEFT JOIN Products_Preload pl    
        ON pl.ProductName = cu.ProductName
        AND cu.EndDate IS NULL;
        
 -- Create new records
    INSERT INTO Products_Preload 
    SELECT ProductKey.NEXTVAL AS ProductKey,
           stg.StockItemName,
           stg.ColorName,
           stg.Brand,
           stg.ItemSize,
           StartDate,
           NULL
    FROM Products_Stage stg
    WHERE NOT EXISTS ( SELECT 1 FROM DimProducts cu WHERE stg.StockItemName = cu.ProductName );
    -- Expire missing records
    INSERT INTO Products_Preload /* Column list excluded for brevity */
    SELECT cu.ProductKey,
           cu.ProductName,
           cu.ProductColour,
           cu.ProductBrand,
           cu.ProductSize,
           cu.StartDate,
           EndDate
    FROM DimProducts cu
    WHERE NOT EXISTS ( SELECT 1 FROM Products_Stage stg WHERE stg.StockItemName = cu.ProductName )
          AND cu.EndDate IS NULL;

    RowCt := SQL%ROWCOUNT;
    dbms_output.put_line(TO_CHAR(RowCt) ||' Rows have been inserted!');
--COMMIT TRANSACTION;
  EXCEPTION
    WHEN OTHERS THEN
       dbms_output.put_line(SQLERRM);
       dbms_output.put_line(v_sql);         
END;


EXECUTE Products_Transform;
SELECT count(*) FROM Products_Preload;
SELECT * FROM Products_Preload;


-------- SALESPEOPLE PRELOAD TABLE AND TRANSFORMATION ---------




-------- SUPPLIERS PRELOAD TABLE AND TRANSFORMATION ---------




-------- ORDER PRELOAD TABLE AND TRANSFORMATION ---------