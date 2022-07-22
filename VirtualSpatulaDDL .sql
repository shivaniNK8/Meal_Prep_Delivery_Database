/*
 * Database Creation
 * (Creating Tables, Views, Functions, Computed Columns)
 * Project Name: Virtual Spatula
 * 
 * */

USE VirtualSpatula;

--Create all schemas
CREATE SCHEMA Person;
CREATE SCHEMA [Order];
CREATE SCHEMA Recipe;
CREATE SCHEMA Payment;
CREATE SCHEMA Store;

--Create all tables
--Contains column level check constraints, Phone number has to be 10 digit numeric,
--Email should be valid
CREATE TABLE Person.Person
(
	PersonID INT IDENTITY NOT NULL PRIMARY KEY,
	FirstName NVARCHAR(40) NOT NULL,
	MiddleName NVARCHAR(40),
	LastName NVARCHAR(40) NOT NULL,
	PhoneNumber NVARCHAR(10) NOT NULL,
	DateOfBirth DATE NOT NULL,
	Email NVARCHAR(320) NOT NULL,
	Password  VARBINARY(250) NOT NULL,
	CONSTRAINT cc_PH
		CHECK (PhoneNumber NOT LIKE '%[^0-9]%'),
	CONSTRAINT cc_PHLen
		CHECK (LEN(PhoneNumber) = 10),
	CONSTRAINT cc_Email
		CHECK (Email LIKE '%_@__%.__%')
);


--Computed column for age of person
ALTER TABLE Person.Person 
ADD Age  AS (Person.Calculate_Age(DateOfBirth ));

--Column level check constraint for zipcode
CREATE TABLE Person.Address
(
    AddressID INT IDENTITY NOT NULL PRIMARY KEY,
    AddressLine1 NVARCHAR(40) NOT NULL,
    AddressLine2 NVARCHAR(40),
    AddressCity NVARCHAR(40) NOT NULL,
    AddressState NVARCHAR(2) NOT NULL,
    AddressZipCode NVARCHAR(5) NOT NULL,
    CONSTRAINT Check_zip
		CHECK (AddressZipCode NOT LIKE '%[^0-9]%'),
	CONSTRAINT Check_zipLen
		CHECK (LEN(AddressZipCode) = 5)
);

CREATE TABLE Recipe.Ingredient
(
	IngredientID INT IDENTITY NOT NULL PRIMARY KEY,
	Name NVARCHAR(200) NOT NULL,
	Category NVARCHAR(200) NOT NULL
);


CREATE TABLE Recipe.Recipe
(
	RecipeID INT IDENTITY NOT NULL PRIMARY KEY,
	Name NVARCHAR(100) NOT NULL,
	Cuisine NVARCHAR(40) NOT NULL,
	Category NVARCHAR(40) NOT NULL,
	Link NVARCHAR(2000) NOT NULL,
	PrepTime TIME(4) NOT NULL,
	CookTime TIME(4) NOT NULL,
);

CREATE TABLE Person.[User]
(
	UserID INT IDENTITY NOT NULL PRIMARY KEY,
	PersonID INT NOT NULL 
		REFERENCES Person.Person(PersonID),
	DateOfJoining DATE NOT NULL
);

CREATE TABLE Payment.Payment
(
	PaymentID INT IDENTITY NOT NULL PRIMARY KEY,
	PaymentMethod NVARCHAR(20) NOT NULL,
	NameOnCard NVARCHAR(30) NOT NULL,
	CardNumber NVARCHAR(20) NOT NULL,
	ExpireDate DATE NOT NULL,
	PaymentDate DATETIME NOT NULL,
	UserID INT NOT NULL 
		REFERENCES Person.[User] (UserID) , 
	AddressID INT NOT NULL 
		REFERENCES Person.Address (AddressID)
);

CREATE TABLE [Order].[Order]
(
	OrderID INT IDENTITY NOT NULL PRIMARY KEY,
	OrderDate DATETIME NOT NULL,
	Feedback NVARCHAR(100),
	OrderAmount MONEY NOT NULL,
	OrderPickupTime DATETIME,
	OrderDeliveredTime DATETIME,
	UserID INT NOT NULL
		REFERENCES Person.[User](UserID),
	ShippingAddressID INT NOT NULL
		REFERENCES Person.Address(AddressID)
);

CREATE TABLE Recipe.User_Recipe
(
	User_RecipeID INT IDENTITY NOT NULL PRIMARY KEY,
	RecipeID INT NOT NULL 
		REFERENCES Recipe.Recipe(RecipeID),
	UserID INT NOT NULL
		REFERENCES Person.[User](UserID),
	Feedback NVARCHAR(2000)
);

CREATE TABLE Person.DeliveryPartner
(
	DeliveryPartnerID INT IDENTITY NOT NULL PRIMARY KEY,
	LicenseNumber NVARCHAR(20) NOT NULL,
	DateOfJoining DATE NOT NULL,
	Rating DECIMAL(8,2),
	Salary MONEY NOT NULL,
	VehicleType NVARCHAR(20) NOT NULL,
	VehicleBrand NVARCHAR(60) NOT NULL,
	VehicleModel NVARCHAR(60) NOT NULL,
	VehicleColor NVARCHAR(10) NOT NULL,
	VehicleNumberPlate NVARCHAR(8) NOT NULL,
	PersonID INT NOT NULL
		REFERENCES Person.Person(PersonID)
);

-- Computed column for Bonus of Delivery Partner
ALTER TABLE Person.DeliveryPartner
ADD Bonus AS (Payment.Bonus(DeliveryPartnerID, 1, DATEPART(MONTH, GETDATE())));

-- Computed column for Average Rating of Delivery Partner
ALTER TABLE Person.DeliveryPartner 
ADD Avg_Rating  AS (Payment.Avg_Rating(DeliveryPartnerID ));

CREATE TABLE [Order].DeliveryPartner_Order 
(
	OrderID INT NOT NULL
		REFERENCES [Order].[Order](OrderID),
	DeliveryPartnerID INT NOT NULL
		REFERENCES Person.DeliveryPartner(DeliveryPartnerID),
	Rating INT,
	CONSTRAINT PKDeliveryPartner_Order PRIMARY KEY CLUSTERED
		(OrderID, DeliveryPartnerID)
	
);

CREATE TABLE Payment.[Transaction] 
(
	TransactionID NVARCHAR(50) NOT NULL PRIMARY KEY,
	Status NVARCHAR(10) NOT NULL,
	Date_Time DATETIME NOT NULL,
	PaymentID INT NOT NULL 
		REFERENCES Payment.Payment(PaymentID)
);

CREATE TABLE Store.Store
(
	StoreID INT IDENTITY NOT NULL PRIMARY KEY,
	AddressID INT NOT NULL 
		REFERENCES Person.Address (AddressID),
	Name NVARCHAR(20) NOT NULL
);

CREATE TABLE Store.StoreInventory  
(
	IngredientID INT NOT NULL 
		REFERENCES Recipe.Ingredient(IngredientID) ,
	StoreID INT NOT NULL 
		REFERENCES Store.Store(StoreID), 
	Price MONEY NOT NULL,
	Weight DECIMAL(8,2) NOT NULL,
	MeasurementUnit NVARCHAR(10) NOT NULL,
	CONSTRAINT PKStoreInventory PRIMARY KEY CLUSTERED
		(IngredientID,StoreID),
	CONSTRAINT Check_Price 
		CHECK (Price > 0)
);


CREATE TABLE [Order].Line_Item
(
	OrderID INT NOT NULL REFERENCES [Order].[Order](OrderID),
 	IngredientID INT NOT NULL REFERENCES Recipe.Ingredient(IngredientID),
	IngredientQty INT NOT NULL,
	PerUnitPrice MONEY NOT NULL,
	CONSTRAINT PKLine_Item PRIMARY KEY CLUSTERED
 		(OrderID, IngredientID),
 	CONSTRAINT Check_PUP 
 		CHECK (PerUnitPrice >0 ) ,
 	CONSTRAINT Check_IQ
 		CHECK (IngredientQty >0)
 	
);

CREATE TABLE Recipe.Recipe_Ingredient
(
	RecipeID INT NOT NULL 
		REFERENCES Recipe.Recipe(RecipeID),
	IngredientID INT NOT NULL 
		REFERENCES Recipe.Ingredient(IngredientID),
	RecipeQty NVARCHAR(20) NOT NULL, 
 	CONSTRAINT PKRecipe_Ingredient PRIMARY KEY CLUSTERED
 		(RecipeID, IngredientID),
 	CONSTRAINT Check_RQ
 		CHECK (RecipeQty > 0)
 );

CREATE TABLE Payment.Invoice
(
	InvoiceID INT IDENTITY NOT NULL PRIMARY KEY,
    PaymentID INT NOT NULL
    	REFERENCES Payment.Payment(PaymentID),
    BillingAddressID INT NOT NULL
    	REFERENCES Person.Address(AddressID),
    OrderID INT NOT NULL
    	REFERENCES [Order].[Order](OrderID)
);

CREATE TABLE Person.UserAddress
(
   	UserID INT NOT NULL
    	REFERENCES Person.[User](UserID),
    AddressID INT NOT NULL
    	REFERENCES Person.Address(AddressID),
  	CONSTRAINT PKUserAddress PRIMARY KEY CLUSTERED
  		(AddressID,UserID)
);


---------------------------------FUNCTIONS---------------------------------
---- Function for Age Calculation 
CREATE FUNCTION Person.Calculate_Age(@DateOfBirth Date)
RETURNS INT 
AS 
BEGIN 
	DECLARE @Age INT; 
SET @Age = DATEDIFF(HOUR,@DateOfBirth,GETDATE())/8766;
RETURN @Age;
END 

DROP FUNCTION Person.DeliveryPartnerAge

---- Function for Delivery PArtner age Calculation 
CREATE FUNCTION Person.DeliveryPartnerAge(@PartnerID INT)
RETURNS INT 
AS 
BEGIN 
	DECLARE @Age INT;
	SELECT @Age = Person.Calculate_Age(p.DateOfBirth)
	FROM Person.DeliveryPartner d
	JOIN Person.Person p 
	ON d.PersonID = p.PersonID 
	WHERE d.DeliveryPartnerID = @PartnerID
RETURN @Age;
END 

---- Function for Bonus calculation 
CREATE FUNCTION Payment.Bonus(@PartnerID INT , @GOAL INT , @Month INT)
RETURNS DECIMAL(20,2)
AS 
BEGIN 
	DECLARE @Avg_Rating DECIMAL(8,2) , @No_of_Orders INT , @Salary INT;
	DECLARE @Bonus Decimal(20,2);
	SELECT @Salary = Salary 
	FROM Person.DeliveryPartner 
	WHERE DeliveryPartnerID = @PartnerID;

	SELECT @Avg_Rating = AVG(CAST(Rating AS DECIMAL(8,2)))
	FROM [Order].DeliveryPartner_Order 
	WHERE DeliveryPartnerID = @PartnerID;

	SELECT  @No_Of_Orders = COUNT(dpo.OrderID)
	FROM [Order].DeliveryPartner_Order dpo
	LEFT JOIN [Order].[Order] ord
		ON dpo.OrderID = ord.OrderID 
	WHERE DATEPART(MONTH,ord.OrderDate) = @Month 
	AND DATEPART(YEAR,GETDATE()) = 2021 
	AND dpo.DeliveryPartnerID = @PartnerID ;

	DECLARE @OrderBonus DECIMAL(20,2);
	SET @OrderBonus = 0;
	IF(@No_Of_Orders > @Goal)
	BEGIN
		SET @OrderBonus = 0.05*@Salary;
	END

	SET @Bonus = @Avg_Rating*0.1*@Salary + @OrderBonus;
	RETURN @Bonus;
END


---- Function for average rating calculation 
CREATE FUNCTION Payment.Avg_Rating(@PartnerID INT )
RETURNS DECIMAL(20,2)
AS 
BEGIN 
	DECLARE @Avg_Rating DECIMAL(8,2)
    SELECT @Avg_Rating = AVG(CAST(Rating AS DECIMAL(8,2)))
	FROM [Order].DeliveryPartner_Order 
	WHERE DeliveryPartnerID = @PartnerID;
	RETURN @Avg_Rating;
END;


---------------------------------COLUMN ENCRYPTION---------------------------------

-- Creating encrypted columns
CREATE MASTER KEY
ENCRYPTION BY PASSWORD = 'Virtualpass';

CREATE CERTIFICATE VirtualCertificate
WITH SUBJECT = 'Virtual Spatula Certificate',
EXPIRY_DATE = '2025-11-30';

CREATE SYMMETRIC KEY PassCardKey
WITH ALGORITHM = AES_128
ENCRYPTION BY CERTIFICATE VirtualCertificate;

OPEN SYMMETRIC KEY PassCardKey
DECRYPTION BY CERTIFICATE VirtualCertificate;

SELECT PersonID ,CONVERT(varchar, DecryptByKey(Password))
FROM Person.Person p 

SELECT PaymentID,CONVERT(varchar, DecryptByKey(CardNumber))
FROM Payment.Payment p

-- Insert encrypted data
INSERT INTO Person.Person 
	VALUES('John', 'Smith', 'Doe', 
		   '5362179108','1990-11-11',
		   'john@gmail.com', 
		   EncryptByKey(Key_GUID(N'PassCardKey'), 'Password'));
		  
INSERT INTO Person.Person 
	VALUES('Shivani', 'S', 'Naik', 
		   '5362279108','1994-1-11',
		   'shivani@gmail.com', 
		   EncryptByKey(Key_GUID(N'PassCardKey'), 'Password1'));
		  
		  
INSERT INTO Person.Person 
	VALUES('Sanchana','A', 'Mohankumar', 
		   '5362286908','1997-9-20',
		   'sanchana@gmail.com', 
		   EncryptByKey(Key_GUID(N'PassCardKey'), 'Password3'));
		  
INSERT INTO Person.Person 
	VALUES('Dongliang', 'A', 'Guo', 
		   '6366779109','1994-1-11',
		   'dongliang@gmail.com', 
		   EncryptByKey(Key_GUID(N'PassCardKey'), 'Password4'));
INSERT INTO Person.Person 
	VALUES('Pulkit', 'A', 'Saharan', 
		   '7966749119','1999-5-12',
		   'pulkit@gmail.com', 
		   EncryptByKey(Key_GUID(N'PassCardKey'), 'Password5'));
		  
INSERT INTO Person.Person 
	VALUES('Yuqi', 'A', 'Shen', 
		   '6369877989','1994-7-12',
		   'yuqi@gmail.com', 
		   EncryptByKey(Key_GUID(N'PassCardKey'), 'Password6'));

INSERT INTO Person.Person 
	VALUES('Chris', 'S', 'Evans', 
		   '5362179108','1989-12-11',
		   'ChrisE@gmail.com', 
		   EncryptByKey(Key_GUID(N'PassCardKey'), 'Password'));
		   
		   
INSERT INTO Person.Person 
	VALUES('Bennett', 'T', 'Claude', 
		   '5362179108','1988-01-14',
		   'BennettC@gmail.com', 
		   EncryptByKey(Key_GUID(N'PassCardKey'), 'Password'));

INSERT INTO Person.Person 
	VALUES('Harding', 'T', 'Josephen', 
		   '4157897354','1994-03-10',
		   'HardingJ@gmail.com', 
		   EncryptByKey(Key_GUID(N'PassCardKey'), 'Password'));

INSERT INTO Person.Person 
	VALUES('Peter', 'C', 'Christopher', 
		   '2139875643','1993-05-10',
		   'PeterC@gmail.com', 
		   EncryptByKey(Key_GUID(N'PassCardKey'), 'Password'));


INSERT INTO VirtualSpatula.Payment.Payment (PaymentMethod,NameOnCard,CardNumber,ExpireDate,PaymentDate,UserID,AddressID) VALUES
	 (N'VISA',N'Wayra Ashkii',EncryptByKey(Key_GUID(N'PassCardKey'), '4539755523668190'),N'2022-05-31',{ts '2021-01-29 12:43:15.000'},1,1),
	 (N'VISA',N'Campbell Tate',EncryptByKey(Key_GUID(N'PassCardKey'), '4710287175005670'),N'2022-08-31',{ts '2022-03-25 19:13:20.000'},2,2),
	 (N'American Express',N'Dongliang Guo',EncryptByKey(Key_GUID(N'PassCardKey'), '375788603886356'),N'2022-10-31',{ts '2020-11-12 09:02:40.000'},3,3),
	 (N'Discover',N'Pulkit Saharan',EncryptByKey(Key_GUID(N'PassCardKey'), '6011636429199140'),N'2024-05-31',{ts '2023-12-29 14:13:14.000'},4,4),
	 (N'VISA',N'Yuqi Shen',EncryptByKey(Key_GUID(N'PassCardKey'), '4916090522269060'),N'2023-07-31',{ts '2021-03-03 22:49:17.000'},5,5),
	 (N'Discover',N'Logan Dayton',EncryptByKey(Key_GUID(N'PassCardKey'), '6011636429199140'),N'2024-05-31',{ts '2023-12-29 14:13:14.000'},6,6),
	 (N'VISA',N'Arron Flint',EncryptByKey(Key_GUID(N'PassCardKey'), '4916090522269060'),N'2023-07-31',{ts '2021-03-03 22:49:17.000'},7,7),
	 (N'VISA',N'Jackie Chen',EncryptByKey(Key_GUID(N'PassCardKey'), '5221688349054460'),N'2023-10-31',{ts '2021-11-29 08:20:45.000'},8,8),
	 (N'VISA',N'Peter Kristopher',EncryptByKey(Key_GUID(N'PassCardKey'), '375788603886356'),N'2022-10-31',{ts '2020-11-12 09:02:40.000'},9,9),
	 (N'American Express',N'Harding Joseph',EncryptByKey(Key_GUID(N'PassCardKey'), '5202807583381440'),N'2022-12-31',{ts '2019-10-27 04:43:21.000'},10,10);

---------------------------------VIEWS---------------------------------

-- UserProfile view, displays the most preferred cuisine and total number of recipes per user.
-- Can be used to provide promotions and recommend new recipes.		  
CREATE VIEW UserProfile AS 
WITH temp AS
(SELECT p.UserID AS UserID1, rs.Cuisine AS CuisineName, COUNT(rs.Cuisine) AS Cuisine,
DENSE_RANK() OVER (PARTITION BY p.UserID ORDER BY COUNT(rs.Cuisine) DESC) AS [Rank of Cuisine]
FROM Person.[User] p
JOIN Recipe.User_Recipe r
ON p.UserID = r.UserID
JOIN Recipe.Recipe rs
ON r.RecipeID = rs.RecipeID
GROUP BY p.UserID,rs.Cuisine),
t2 AS(
SELECT UserID1, SUM(Cuisine) RecipeCount
FROM temp
GROUP BY UserID1
)
SELECT temp.UserID1, 
		STRING_AGG(temp.CuisineName,', ') MostPreferredCuisine,
		MAX(t2.RecipeCount) TotalRecipes
FROM temp
JOIN t2
ON temp.UserID1 = t2.UserID1
WHERE [Rank of Cuisine]=1
GROUP BY temp.UserID1

-- Creating view for card promotion, displays the number of times a type of payment method is used, 
-- can be used to provide promotions, like if a payment method is used less than 20%
-- of times, an offer can be introduced to encourage its use

CREATE VIEW CardPromtion AS
SELECT PaymentMethod,Times ,
CASE WHEN CAST(Times AS decimal(5,2))/(SELECT count(PaymentID) FROM Payment.Payment) <=0.2 THEN '10% Cashback' ELSE 'No Offer' END AS 'Offer'
FROM (
SELECT p.PaymentMethod ,count( p.PaymentID)  AS Times
FROM Payment.Payment p
GROUP by p.PaymentMethod) AS a;

-- Store inventory view, displays the availability of ingredients in stores

CREATE VIEW StoreView AS 
WITH temp AS 
(
SELECT DISTINCT t.IngredientID , t.StoreID,
CASE WHEN CONCAT(t.StoreID ,' ',t.IngredientID)  IN (SELECT concat(ssi.StoreID ,' ' ,ssi.IngredientID) FROM Store.StoreInventory ssi)
THEN 'Yes' ELSE 'No' END AS 'Availability'
FROM (SELECT ri.IngredientID ,ss.StoreID
FROM Recipe.Ingredient ri
CROSS JOIN Store.Store ss)  t 
CROSS JOIN Store.Store ss
LEFT JOIN Store.StoreInventory ssi
ON ss.StoreID = ssi.IngredientID )
SELECT t.IngredientID,ri.Name,t.Store1, t.Store2, t.Store3
FROM (
SELECT IngredientID, [1] 'Store1', [2] 'Store2', [3]  'Store3'
FROM 
(SELECT IngredientID , StoreID, [Availability]
FROM temp) vertical
pivot
(max([Availability]) 
for StoreID IN ([1],[2],[3])) horizontal)  AS t
LEFT JOIN Recipe.Ingredient ri
ON t.IngredientID = ri.IngredientID;

-- Table level check constraint

ALTER TABLE Person.DeliveryPartner 
	ADD CONSTRAINT AgeLimit CHECK 
		(Person.DeliveryPartnerAge(DeliveryPartnerID) >= 18);

