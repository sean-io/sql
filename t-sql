########################################################################
/* Sample t-sql excercises creating procedures, functions, and triggers */

/* Function to check for duplicate student IDs */

CREATE FUNCTION [dbo].[countIDs] (@ID AS INT)
	RETURNS INT
	AS
	BEGIN
		DECLARE @myCount AS INT

		SELECT @myCount = COUNT(ID)
		FROM STUDENTS
		WHERE ID = @ID

		RETURN @myCount
	END

########################################################################

/* Insert Procedure */

CREATE PROCEDURE [dbo].[Students_Insert]
(	@ID int,
    	@LASTNAME varchar(50),
    	@FIRSTNAME varchar(50),
    	@STATE varchar(50),
    	@PHONE varchar(50),
    	@EMAIL varchar(50),
    	@GRADYEAR int,
    	@GPA decimal(20,10),
	@PROGRAM varchar(50),
	@NEWSLETTER bit
)
AS
BEGIN

	--Run CountIDs function to check to make sure the ID does exist
	IF [dbo].[countIDs] (@ID) > 0
	BEGIN
		RAISERROR ('ID already exists', 1, 1)
		RETURN 0
	END


	--Format GPA as 2 decimal places
	DECLARE @TwoDecimalGPA AS DECIMAL(3,2)
	SELECT @TwoDecimalGPA = CAST(@GPA as numeric(3,2))

	--Make sure GPA is within range
	IF ((@TwoDecimalGPA > 4) OR (@TwoDecimalGPA < 0))
	BEGIN
		RAISERROR ('GPA value is invalid', 1, 1)
		RETURN 0
	END	 


--Attempt insert
INSERT INTO [dbo].[Students]
           ([ID]
           ,[LASTNAME]
           ,[FIRSTNAME]
           ,[STATE]
           ,[PHONE]
           ,[EMAIL]
           ,[GRADYEAR]
           ,[GPA]
           ,[PROGRAM]
           ,[NEWSLETTER])
     VALUES
           (@ID
           ,@LASTNAME
           ,@FIRSTNAME
           ,@STATE
           ,@PHONE
           ,@EMAIL
           ,@GRADYEAR
           ,@TwoDecimalGPA
           ,@PROGRAM
           ,@NEWSLETTER)

		   --check to see if insert occured 
		   --and return status
		   
		   IF @@ROWCOUNT = 1
				RETURN 1
		   ELSE 
				RETURN 0
END

GO
;

########################################################################

/* Update Procedure */

CREATE PROCEDURE [dbo].[Students_Update]
(	@ID int,
    	@LASTNAME varchar(50),
    	@FIRSTNAME varchar(50),
    	@STATE varchar(50),
    	@PHONE varchar(50),
    	@EMAIL varchar(50),
	@GRADYEAR int,
   	@GPA decimal(20,10),
	@PROGRAM varchar(50),
	@NEWSLETTER bit
)
AS
BEGIN

--Run CountIDs function to check to make sure the ID does exist
	IF [dbo].[countIDs] (@ID) <> 1
	BEGIN
		RAISERROR ('ID does not exist', 1, 1)
		RETURN 0
	END

	--Can not subscribe to newsletter if email is null
	IF (@email IS NULL)
		SET @NEWSLETTER = 0
 
	--Attempt Update
UPDATE [dbo].[Students]
   SET [LASTNAME] = @LASTNAME 
      ,[FIRSTNAME] = @FIRSTNAME 
      ,[STATE] = @STATE 
      ,[PHONE] = @PHONE 
      ,[EMAIL] = @EMAIL 
      ,[GRADYEAR] = @GRADYEAR 
      ,[GPA] = @GPA 
      ,[PROGRAM] = @PROGRAM 
      ,[NEWSLETTER] = @NEWSLETTER 
 WHERE ID = @ID
     
		   --check to see if update occured 
		   --and return status
		   IF @@ROWCOUNT = 1
				RETURN 1
		   ELSE 
				RETURN 0
END

GO
:

########################################################################

/* Delete Procedure */

CREATE PROCEDURE [dbo].[Students_Delete](@ID int)
WITH EXECUTE AS CALLER
AS
BEGIN

	--Run CountIDs function to check to make sure the ID does exist
	IF [dbo].[countIDs] (@ID <> 1
	BEGIN
		RAISERROR ('ID does not exist', 1, 1)
		RETURN 0
	END


		--Attempt Delete
		DELETE FROM [dbo].[Students]
		WHERE ID = @ID
     
		--check to see if update occured 
		--and return status
		IF @@ROWCOUNT = 1
			BEGIN
				INSERT INTO StudentDeleteLog 
				VALUES (suser_sname(), @ID, getdate())

				RETURN 1
			END
			
		ELSE 
			RETURN 0
END

GO
;

########################################################################

/* Utilizing input and output paramerters in a procedure */

ALTER PROCEDURE [dbo].[myTest] (@param1 as int OUTPUT, @param2 as varchar(10))
AS
BEGIN
SELECT 'This the myTest procedure'

SELECT @param1
SET @param1 = 27

SELECT @param2

RETURN 1
END

GO
DECLARE @X as int = 13
EXEC myTest @X OUTPUT, 'Param2 Text'
SELECT @X 
;

########################################################################

/* Using a cursor in a procedure to return data */

CREATE PROC procedureCursor(@authors CURSOR VARYING OUTPUT)
AS 
BEGIN
	SET @authors = CURSOR FOR
	
	SELECT firstname
	FROM authors
	ORDER BY firstname

	OPEN @authors
END

GO

DECLARE @myCursor CURSOR
DECLARE @firstName varchar(50)

EXEC dbo.procedureCursor @authors = @myCursor OUTPUT

FETCH NEXT FROM @myCursor INTO @firstName
SELECT @firstName

CLOSE @myCursor
DEALLOCATE @myCursor
;

########################################################################

/* After Trigger */

CREATE TRIGGER [dbo].[CategoryDeactivation]
ON [dbo].[Categories]
AFTER UPDATE
AS
BEGIN 
	DECLARE @isActive AS bit

	SELECT @isActive = Active
	FROM Inserted

	IF (@isActive = 0)
		UPDATE Products
		SET Active = 0
		WHERE CategoryID IN (SELECT CategoryID FROM Inserted)

END
;

UPDATE Categories SET Active = 0
WHERE CategoryID = 1
;

select top 10 * from products 
; 

########################################################################

/* "Instead of" trigger to enforce data integrity */

CREATE TRIGGER [dbo].[CategoryDelete]
ON [dbo].[Categories]
INSTEAD OF DELETE
AS
BEGIN 
		UPDATE Categories
		SET Active = 0
		WHERE CategoryID IN (SELECT CategoryID FROM Deleted)
END

########################################################################

/* DB level trigger */

CREATE TRIGGER safety 
ON DATABASE 
FOR DROP_TABLE, ALTER_TABLE 
AS 
   PRINT 'You do not have permission to drop or alter tables!' 
   ROLLBACK
   ;
   
########################################################################

/* Exercises modified from: https://www.linkedin.com/learning/sql-server-triggers-stored-procedures-and-functions */
