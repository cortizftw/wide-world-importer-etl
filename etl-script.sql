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
CREATE INDEX IX_FactSales_CustomerKey 	    ON FactSales(CustomerKey);
CREATE INDEX IX_FactSales_LocationKey 	    ON FactSales(LocationKey);
CREATE INDEX IX_FactSales_ProductKey 	    ON FactSales(ProductKey);
CREATE INDEX IX_FactSales_SalesPersonKey 	ON FactSales(SalesPersonKey);
CREATE INDEX IX_FactSales_SupplierKey 	    ON FactSales(SupplierKey);
CREATE INDEX IX_FactSales_DateKey 	        ON FactSales(DateKey);


--Create DimCustomers Table (Type 2 SCD)
CREATE TABLE DimCustomers(  
	CustomerKey 		        NUMBER(10),
	CustomerName 		        NVARCHAR2(100) NULL,
	CustomerCategoryName        NVARCHAR2(50) NULL,
	DeliveryCityName 	        NVARCHAR2(50) NULL,
	DeliveryStateProvCode       NVARCHAR2(5) NULL,
	DeliveryCountryName         NVARCHAR2(50) NULL,
	PostalCityName 		        NVARCHAR2(50) NULL,
	PostalStateProvCode         NVARCHAR2(5) NULL,
	PostalCountryName 	        NVARCHAR2(50) NULL,
	StartDate 			        DATE NOT NULL,
	EndDate 			        DATE NULL,
    CONSTRAINT PK_DimCustomers PRIMARY KEY ( CustomerKey )
);


--Create DimLocation Table (Type 1 SCD)
CREATE TABLE DimLocation(  
	LocationKey 	    NUMBER(10),
	CityName 		    NVARCHAR2(50) NULL,
	StateProvCode 	    NVARCHAR2(5) NULL,
	StateProvName 	    NVARCHAR2(50) NULL,
	CountryName 	    NVARCHAR2(60) NULL,
	CountryFormalName   NVARCHAR2(60) NULL,
    CONSTRAINT PK_DimLocation PRIMARY KEY ( LocationKey )
);


--Create DimProducts Table (Type 2 SCD)
CREATE TABLE DimProducts(   
	ProductKey 		    NUMBER(10),
	ProductName 	    NVARCHAR2(100) NULL,
	ProductColour 	    NVARCHAR2(20) NULL,
	ProductBrand 	    NVARCHAR2(50) NULL,
	ProductSize 	    NVARCHAR2(20) NULL,
	StartDate 		    DATE NOT NULL,
	EndDate 		    DATE NULL,
    CONSTRAINT PK_DimProducts PRIMARY KEY ( ProductKey )
);


--Create DimSalesPerson Table (Type 1 SCD)
CREATE TABLE DimSalesPeople(    
	SalespersonKey 	    NUMBER(10),
	FullName 		    NVARCHAR2(50) NULL,
	PreferredName 	    NVARCHAR2(50) NULL,
	LogonName 		    NVARCHAR2(50) NULL,
	PhoneNumber 	    NVARCHAR2(20) NULL,
	FaxNumber 		    NVARCHAR2(20) NULL,
	EmailAddress 	    NVARCHAR2(256) NULL,
    CONSTRAINT PK_DimSalesPeople PRIMARY KEY (SalespersonKey )
);


--Create DimSuppliers Table (Type 2 SCD)
CREATE TABLE DimSupplier (
    SupplierKey         NUMBER(10) NOT NULL,
    FullName            NVARCHAR2(100) NULL,
    PhoneNumber         NVARCHAR2(20) NULL,
    FaxNumber           NVARCHAR2(20) NULL,
    WebsiteURL          NVARCHAR2(256) NULL,
    StartDate           DATE NOT NULL,
	EndDate             DATE NULL,
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




