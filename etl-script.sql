--------------- CREATE WWI_DM USER ----------------
ALTER session set "_ORACLE_SCRIPT" = true;
CREATE USER wwidmuser identified by wwidmuser;
GRANT ALL PRIVILEGES TO wwidmuser;
SELECT * FROM all_users ORDER BY Created DESC;



--------------- REQUIREMENT 1 ----------------
/* CREATE DIMENSIONAL MODEL TABLES */

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
    CONSTRAINT FK_FactSales_DimSalesPerson FOREIGN KEY (SalesPersonKey) REFERENCES DimSalesPerson(SalesPersonKey),
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


--Create DimSalesPerson Table (Type 1 SCD)
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

SET SERVEROUT ON;
EXECUTE Customers_Extract;
SELECT * FROM customers_stage;


--- PRODUCTS -----
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

SET SERVEROUT ON;
EXECUTE Products_Extract;
SELECT * FROM Products_Stage;


--- SALESPEOPLE -----



--- ORDERS -----



--- SUPPLIERS -----

