BEGIN
    PRINT N'Creating PowerShell_CRUD database...'
    IF (db_id(N'PowerShell_CRUD') IS NULL) 
        BEGIN
            CREATE DATABASE PowerShell_CRUD;
            PRINT N'PowerShell_CRUD database created.'
        END
    ELSE
        PRINT N'PowerShell_CRUD database already exists.'
END


CREATE TABLE [PowerShell_CRUD].[dbo].[Programmers] (
    id BIGINT IDENTITY(1,1) PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    platform VARCHAR(25) NOT NULL,
    favorite_language VARCHAR(25) NOT NULL
)


INSERT INTO [PowerShell_CRUD].[dbo].[Programmers] VALUES ('Barrett', 'Otte', 'Linux', 'Python');
INSERT INTO [PowerShell_CRUD].[dbo].[Programmers] VALUES ('Bill', 'Test', 'Windows', 'C#');
INSERT INTO [PowerShell_CRUD].[dbo].[Programmers] VALUES ('First', 'Last', 'Mac', 'Swift');
INSERT INTO [PowerShell_CRUD].[dbo].[Programmers] VALUES ('Some', 'Body', 'Mac', 'Go');
INSERT INTO [PowerShell_CRUD].[dbo].[Programmers] VALUES ('Terry', 'Davis', 'TempleOS', 'Holy C');
INSERT INTO [PowerShell_CRUD].[dbo].[Programmers] VALUES ('Grey', 'Beard', 'IBMi', 'RPGLE');
INSERT INTO [PowerShell_CRUD].[dbo].[Programmers] VALUES ('Func', 'Tional', 'Windows', 'Haskell');



CREATE TABLE [PowerShell_CRUD].[dbo].[Products] (
    id BIGINT IDENTITY(1,1) PRIMARY KEY,
    p_name VARCHAR(50) NOT NULL,
    p_price INT,
    p_quantity INT
)


INSERT INTO [PowerShell_CRUD].[dbo].[Products] VALUES ('Thing 1', 13, 4);
INSERT INTO [PowerShell_CRUD].[dbo].[Products] VALUES ('Thing 2', 13, 4);
INSERT INTO [PowerShell_CRUD].[dbo].[Products] VALUES ('Something crazy', 133, 10);
INSERT INTO [PowerShell_CRUD].[dbo].[Products] VALUES ('My soul', 1, 1);