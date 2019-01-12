CREATE PROCEDURE dbo.addConference
  @Name varchar(50),
  @StartDate date,
  @EndDate date
AS
BEGIN

  INSERT INTO Conferences(
    Name,StartDate,EndDate
  )
  VALUES(@Name, @StartDate, @EndDate)
  END
go

CREATE PROCEDURE dbo.addParticipant
    @Name varchar(50),
    @Lastname varchar(50),
    @email varchar(50),
    @Phone varchar(15) ,
    @City varchar(50) ,
    @Street varchar(50),
    @Address varchar(10),
    @Login varchar(20),
    @Password varchar(50),
    @Country varchar(50)
AS
BEGIN

  INSERT INTO Participants(
    Name,Lastname,email,Phone,City,Street,Address,Login,Password,Country
  )
VALUES(@Name, @Lastname, @email,@Phone,@City,@Street,@Address,@Login,@Password,@Country)
  END
go

CREATE PROCEDURE dbo.addPricePoint
  @DayID INT,
  @date DATE,
  @price MONEY
AS
BEGIN
SET NOCOUNT ON
IF @date > GETDATE()
  BEGIN
  INSERT INTO Discounts(
   IDConferenceDay, Discount, UntilDate
  )
  VALUES(@DayID,@price,@date)
  END
  ELSE
PRINT 'Cant change past data'
 end
go

CREATE PROCEDURE dbo.addConferenceReservation
  @dayid INT,
  @Clientid INT,
  @count INT

AS
BEGIN

  INSERT INTO ConferenceReservation(
   IDConferenceDay, IDClient, ReservationDate, Canceled, PeopleCount
  )
  VALUES(@dayid,@Clientid,getdate(),0,@count)
  END
go



CREATE PROCEDURE dbo.cancelWorkshopReservation
  @IDWorkshopReservation int
  AS
 BEGIN
   SET NOCOUNT ON
   UPDATE dbo.WorkshopReservation
   SET dbo.WorkshopReservation.Canceled=1
   where dbo.WorkshopReservation.IDWorkshopReservation=@IDWorkshopReservation
 END
go

CREATE PROCEDURE dbo.cancelWorkshop
  @IDWorkshop int
  AS
  BEGIN

   SET NOCOUNT ON
   UPDATE dbo.WorkshopReservation
    SET dbo.WorkshopReservation.Canceled=1
    where dbo.WorkshopReservation.IDWorkshop=@IdWorkshop

    UPDATE dbo.Workshops
    SET dbo.Workshops.Canceled=1
    where dbo.Workshops.IDWorkshop=@IDWorkshop
  END
go

CREATE PROCEDURE dbo.makeWorkshopReservationActive
  @IDWorkshopReservation int
AS
BEGIN
  SET NOCOUNT ON
  UPDATE dbo.WorkshopReservation
  SET dbo.WorkshopReservation.Canceled=0
  WHERE dbo.WorkshopReservation.IDWorkshopReservation=@IDWorkshopReservation
END
go

CREATE PROCEDURE dbo.makeWorkshopActive
  @IDWorkshop int
  AS
  BEGIN
    SET NOCOUNT ON
    UPDATE dbo.Workshops
    SET dbo.Workshops.Canceled=0
    WHERE dbo.Workshops.IDWorkshop=@IDWorkshop

  END
go

CREATE PROCEDURE dbo.addConferenceDay
  @IdConference int,
  @capacity int,
  @price FLOAT,
  @data DATE
AS
BEGIN
  INSERT INTO ConferenceDays(
    IDConference, Capacity, Price,Date
  )
  VALUES( @IdConference, @capacity, @price,@data)
  END
go

CREATE PROCEDURE dbo.addWorkshop
  @IDConferenceDay     int,
  @Name   VARCHAR(50),
  @StartTime     TIME,
  @EndTime       TIME,
  @Capacity     VARCHAR(50),
  @Price   float,
  @Canceled BIT

AS
BEGIN
  INSERT INTO Workshops(
    IDConferenceDay, Name, StartTime, EndTime, Capacity, Price, Canceled
  )
  VALUES(@IDConferenceDay,@Name,@StartTime,@EndTime,@Capacity,@Price,@Canceled)
  END
go

--tworzy osobe na warsztat po warunkiem ze jest na rezerwacji konferencji na dana rezerwacje warszttu
--idConferenceparticipant
--idworkshopreservation
CREATE PROCEDURE dbo.sign_to_workshop
  @ConferenceparticiantID int,
  @WorkshopReservation int
AS
BEGIN
SET NOCOUNT ON

  INSERT INTO WorkshopParticipant(IDConferenceParticipants, IDWorkshopReservation)
  VALUES(
  @ConferenceparticiantID,
  @WorkshopReservation
)
END
go

CREATE PROCEDURE editClient(
  @isCompany bit,
  @Login varchar(20),
  @Password varchar(50)=NULL,
  @email varchar(50)=NULL,
  @Phone varchar(15)=NULL,
  @City varchar(50)=NULL,
  @Street varchar(50)=NULL,
  @Country varchar(50)=NULL,
  @PostalCode varchar(6)=NULL,
  @Address varchar(10)=NULL,
  @CompanyName varchar(50)=NULL,
  @WWW varchar(50)=NULL,
  @Name varchar(50)=NULL,
  @LastName varchar(50)=NULL
  )
  AS
  BEGIN
    SET NOCOUNT ON

  DECLARE @ID as int
  SET @ID=(select IDClient
          from dbo.Client
          where dbo.Client.Login=@Login)


    IF @IsCompany=0
      BEGIN
        IF @Name is not NULL
          BEGIN
            UPDATE dbo.Individual
            SET dbo.Individual.Name=@Name
            WHERE dbo.Individual.IDClient=@ID
          END
        IF @Lastname is not NULL
          BEGIN
            UPDATE dbo.Individual
            SET dbo.Individual.LastName=@LastName
            WHERE dbo.Individual.IDClient=@ID
          END
      END
    ELSE
      BEGIN
        IF @CompanyName is not NULL
          BEGIN
            UPDATE dbo.Company
            SET dbo.Company.Name=@CompanyName
            WHERE dbo.Company.IDClient=@ID
          END
        IF @WWW is not NULL
          BEGIN
            UPDATE dbo.Company
            SET dbo.Company.WWW=@WWW
            WHERE dbo.Company.IDClient=@ID
          END
      END

    IF @Password is not NULL
      BEGIN
        UPDATE dbo.Client
        SET dbo.Client.Password=@Password
        where dbo.Client.IDClient=@ID
      END
    IF @email is not NULL
      BEGIN
        UPDATE dbo.Client
        SET dbo.Client.email=@email
        where dbo.Client.IDClient=@ID
      END
    IF @Phone is not NULL
      BEGIN
        UPDATE dbo.Client
        SET dbo.Client.Phone=@Phone
        where dbo.Client.IDClient=@ID
      END
    IF @City is not NULL
      BEGIN
        UPDATE dbo.Client
        SET dbo.Client.City=@City
        where dbo.Client.IDClient=@ID
      END
    IF @Street is not NULL
      BEGIN
        UPDATE dbo.Client
        SET dbo.Client.Street=@Street
        where dbo.Client.IDClient=@ID
      END
    IF @Country is not NULL
      BEGIN
        UPDATE dbo.Client
        SET dbo.Client.Country=@Country
        where dbo.Client.IDClient=@ID
      END
    IF @PostalCode is not NULL
      BEGIN
        UPDATE dbo.Client
        SET dbo.Client.PostalCode=@PostalCode
        where dbo.Client.IDClient=@ID
      END
    IF @Address is not NULL
      BEGIN
        UPDATE dbo.Client
        SET dbo.Client.Address=@Address
        where dbo.Client.IDClient=@ID
      END


  END
go

CREATE PROCEDURE dbo.addtoPayment
  @ConferenceID int,
  @Amount MONEY,
  @Date   DATE
  as
  BEGIN
    INSERT INTO Payments(
     IDConferenceReservation, Amount, PaymentDate
    )
    VALUES (@ConferenceID,@Amount,@Date)
  END
go


CREATE PROCEDURE editParticipant(
  @Name varchar(50)=NULL,
  @Lastname varchar(50)=NULL,
  @email varchar(50)=NULL,
  @Phone varchar(15)=NULL,
  @City varchar(50)=NULL,
  @Street varchar(50)=NULL,
  @Address varchar(10)=NULL,
  @Login varchar(50),
  @Password varchar(50)=NULL,
  @Country varchar(50)=NULL,
  @PostalCode varchar(6)=NULL
)
AS
BEGIN
  SET NOCOUNT ON

  IF @Name is not NULL
    BEGIN
      UPDATE dbo.Participants
      SET dbo.Participants.Name=@Name
      where dbo.Participants.Login=@Login
    END

  IF @Lastname is not NULL
    BEGIN
      UPDATE dbo.Participants
      SET dbo.Participants.Lastname=@Lastname
      where dbo.Participants.Login=@Login
    END

  IF @email is not NULL
    BEGIN
      UPDATE dbo.Participants
      SET dbo.Participants.email=@email
      where dbo.Participants.Login=@Login
    END

  IF @Phone is not NULL
    BEGIN
      UPDATE dbo.Participants
      SET dbo.Participants.Phone=@Phone
      where dbo.Participants.Login=@Login
    END

  IF @City is not NULL
    BEGIN
      UPDATE dbo.Participants
      SET dbo.Participants.City=@City
      where dbo.Participants.Login=@Login
    END

  IF @Street is not NULL
    BEGIN
      UPDATE dbo.Participants
      SET dbo.Participants.Street=@Street
      where dbo.Participants.Login=@Login
    END

  IF @Address is not NULL
    BEGIN
      UPDATE dbo.Participants
      SET dbo.Participants.Address=@Address
      where dbo.Participants.Login=@Login
    END

  IF @Password is not NULL
    BEGIN
      UPDATE dbo.Participants
      SET dbo.Participants.Password=@Password
      where dbo.Participants.Login=@Login
    END

  IF @Country is not NULL
    BEGIN
      UPDATE dbo.Participants
      SET dbo.Participants.Country=@Country
      where dbo.Participants.Login=@Login
    END

  IF @PostalCode is not NULL
    BEGIN
      UPDATE dbo.Participants
      SET dbo.Participants.PostalCode=@PostalCode
      where dbo.Participants.Login=@Login
    END
END
go

CREATE PROCEDURE editWorkshopCapacity(
  @IDWorkshop int,
  @NewCapacity int
)
  AS
  BEGIN
    SET NOCOUNT ON
    if not exists(
      select *
      from dbo.Workshops
      where dbo.Workshops.IDWorkshop=@IDWorkshop
    )
      BEGIN
        RAISERROR ('The is no workshop with given ID', 16,1)
        ROLLBACK TRANSACTION
      END
    ELSE
      BEGIN
        UPDATE dbo.Workshops
        SET dbo.Workshops.Capacity=@NewCapacity
        WHERE dbo.Workshops.IDWorkshop=@IDWorkshop
      END
  END
go

CREATE PROCEDURE editConferenceDayCapacity(
  @IDConferenceDay int,
  @NewCapacity int
)
  AS
BEGIN
  SET NOCOUNT ON
  IF not exists(
      select *
      from dbo.ConferenceDays
      where dbo.ConferenceDays.IDConferenceDay=@IDConferenceDay
    )
      BEGIN
        RAISERROR ('The is no Conference Day with given ID', 16,1)
        ROLLBACK TRANSACTION
      END
  ELSE
    BEGIN
      UPDATE dbo.ConferenceDays
      SET dbo.ConferenceDays.Capacity=@NewCapacity
      WHERE dbo.ConferenceDays.IDConferenceDay=@IDConferenceDay
    END
END
go


CREATE PROCEDURE addWorkshopReservation
  @IDWorkshop INT,
  @IDConferenceReservation INT,
  @PeopleCount INT

AS
BEGIN

  INSERT INTO WorkshopReservation(
   IDWorkshop, Canceled, IDConferenceReservation, PeopleCount
  )
  VALUES(@IDWorkshop,0, @IDConferenceReservation,@PeopleCount)
  END
go


--tworzy osobe na warsztat ze znajdzie workshopreservation dla danego workshop
--idWorkshop
--idworkshopreservation
CREATE PROCEDURE user_sign_to_workshop
 @ConferenceparticiantID int,
 @WorkshopID int
AS
BEGIN
SET NOCOUNT ON
 DECLARE @WorkshopReservationID int
 set @WorkshopReservationID = (
   SELECT TOP 1 WorkshopReservation.IDWorkshopReservation
   FROM WorkshopReservation
     JOIN Workshops ON Workshops.IDWorkshop = WorkshopReservation.IDWorkshop
     JOIN ConferenceReservation
       ON WorkshopReservation.IDConferenceReservation = ConferenceReservation.IDConferenceReservation
     JOIN ConferenceParticipants
       ON ConferenceReservation.IDConferenceReservation = ConferenceParticipants.IDConferenceReservation
   WHERE Workshops.IDWorkshop=@WorkshopID
         and ConferenceParticipants.IDConferenceParticipants = @ConferenceparticiantID
 )
 if(@WorkshopReservationID IS NOT NULL )
   BEGIN
   exec sign_to_workshop @ConferenceparticiantID,@WorkshopReservationID
    end
  ELSE
    RAISERROR('Can not add to workshop', 16, 1)
END
go

CREATE PROCEDURE dbo.addConferenceParticipant
  @IDParticipant      int,
  @IDConferenceReservation   int,
  @StudentsID int =null
AS
BEGIN

  INSERT INTO ConferenceParticipants(
    IDParticipant, IDConferenceReservation, StudentID
  )
  VALUES(@IDParticipant,@IDConferenceReservation,@StudentsID)

  END
go

CREATE PROCEDURE editPeopleCountInWorkshopReservation(
  @IDWorkshopReservation int,
  @NewPeopleCount int
)
AS
  BEGIN
    SET NOCOUNT ON

    IF EXISTS(select *
              from WorkshopReservation
              where WorkshopReservation.IDWorkshopReservation=@IDWorkshopReservation)
    BEGIN
      UPDATE WorkshopReservation
      SET WorkshopReservation.PeopleCount=@NewPeopleCount
      WHERE WorkshopReservation.IDWorkshopReservation=@IDWorkshopReservation
    END
    ELSE
    RAISERROR('There is no reservation with given ID',16,1)
  END
go

CREATE PROCEDURE makeConferenceReservationActive
  @IDConferenceReservation int
  AS
  BEGIN
    SET NOCOUNT ON
    UPDATE dbo.ConferenceReservation
    SET dbo.ConferenceReservation.Canceled=0
    where dbo.ConferenceReservation.IDConferenceReservation=@IDConferenceReservation


    UPDATE dbo.WorkshopReservation
    SET dbo.WorkshopReservation.Canceled=0
    WHERE WorkshopReservation.IDWorkshopReservation IN  (select WorkshopReservation.IDWorkshopReservation
                 from WorkshopReservation
                 join Workshops
                 on Workshops.IDWorkshop=WorkshopReservation.IDWorkshop
                 where WorkshopReservation.IDConferenceReservation=@IDConferenceReservation and Workshops.Canceled=0)
  END
go

--anuluje rezerwacje z selecta :
create PROCEDURE dbo.cancel_unpaid_reservation
AS
BEGIN
--select zwaraca rezerwacje starsze niz 7 dni, ktore jeszcze sa aktywne i nieoplacone
declare @id int
declare cur CURSOR LOCAL for
  (
    SELECT CR.IDConferenceReservation
    FROM ConferenceReservation AS CR
      INNER JOIN
      Payments AS P ON P.IDConferenceReservation = CR.IDConferenceReservation
    WHERE CR.ReservationDate < DATEADD(DAY, -7, GETDATE()) AND CR.Canceled = 0
    GROUP BY CR.IDConferenceReservation
    HAVING Sum(P.Amount) < dbo.count_payment(CR.IDConferenceReservation)
    UNION
    (
      SELECT CR.IDConferenceReservation
      FROM ConferenceReservation AS CR
      WHERE NOT exists(
          SELECT Payments.IDConferenceReservation
          FROM Payments
          WHERE Payments.IDConferenceReservation = CR.IDConferenceReservation
      ) AND CR.ReservationDate < DATEADD(DAY, -7, GETDATE()) AND CR.Canceled = 0
    )
  )
open cur
fetch next from cur into @id
WHILE @@FETCH_STATUS = 0
BEGIN

      EXEC cancelConferenceReservation @id
      fetch next from cur into @id

END
CLOSE cur
DEALLOCATE cur

end
go

create PROCEDURE dbo.cancelConferenceReservation
  @IDConferenceReservation int
  AS
  BEGIN
    SET NOCOUNT ON
    UPDATE dbo.ConferenceReservation
    SET dbo.ConferenceReservation.Canceled=1
    where dbo.ConferenceReservation.IDConferenceReservation=@IDConferenceReservation

    UPDATE dbo.WorkshopReservation
    SET dbo.WorkshopReservation.Canceled=1
    WHERE dbo.WorkshopReservation.IDConferenceReservation=@IDConferenceReservation
  END
go


CREATE PROCEDURE cancelConferenceDay (
  @IDConferenceDay int
)
  AS
BEGIN
  SET NOCOUNT ON
  UPDATE ConferenceDays
  SET ConferenceDays.Canceled=1
  WHERE ConferenceDays.IDConferenceDay=@IDConferenceDay

  CREATE TABLE #IDs (ID int)
  INSERT INTO #IDs(ID) (
      select IDConferenceReservation
      from ConferenceReservation
      where ConferenceReservation.IDConferenceDay=@IDConferenceDay
  )

  Declare @ID int

  While exists(select * from #IDs)
  BEGIN
    set @ID=(Select top 1 ID from #IDs)

    exec cancelConferenceReservation @ID

    Delete from #IDs where ID=@ID
  END
  DROP TABLE #IDs
END
go



CREATE PROCEDURE cancelConference(
  @IDConference int
)
  AS
  BEGIN
    SET NOCOUNT ON

    UPDATE Conferences
    SET Conferences.Canceled=1
    WHERE Conferences.IDConference=@IDConference

    CREATE TABLE #IDC (ID int)
    INSERT INTO #IDC(ID) (
      select IDConferenceDay
      from ConferenceDays
      where ConferenceDays.IDConference=@IDConference
    )
    Declare @IDC int

    while exists(select * from #IDC)
    BEGIN
      set @IDC=(select top 1 ID from #IDC)
      exec cancelConferenceDay @IDC
      delete from #IDC where ID=@IDC
    END
    DROP TABLE #IDC
  END
go



--Sprawdza, czy rezerwacja istnieje i czy nie jest za pozno na wprowadzenie zmian
CREATE PROCEDURE editPeopleCountInConferenceReservation (
  @IDConferenceReservation int,
  @NewPeopleCount int
)
AS
  BEGIN
    SET NOCOUNT ON

    IF (EXISTS(select *
              from ConferenceReservation
              where ConferenceReservation.IDConferenceReservation=@IDConferenceReservation)
         and (
            (SELECT datediff(day,ConferenceReservation.ReservationDate,Conferences.StartDate) from ConferenceReservation
              join ConferenceDays on ConferenceReservation.IDConferenceDay = ConferenceDays.IDConferenceDay
              JOIN Conferences on ConferenceDays.IDConference = Conferences.IDConference
              WHERE IDConferenceReservation=@IDConferenceReservation
            )<14
          )
    )
      BEGIN
        UPDATE ConferenceReservation
        SET ConferenceReservation.PeopleCount=@NewPeopleCount
        WHERE ConferenceReservation.IDConferenceReservation=@IDConferenceReservation
      END
    ELSE
    RAISERROR ('There is no reservation with given ID or it is too late for changes',16,1)
  END
go


CREATE PROCEDURE editPeopleCountInReservationUSERLEVEL(
  @IDClient int,
  @IDConferenceReservation int,
  @NewPeopleCount int

)
  AS
BEGIN
  SET NOCOUNT ON

  if(@IDClient != null)
  BEGIN
    if (SELECT datediff(DAY,ConferenceReservation.ReservationDate,Conferences.StartDate) FROM ConferenceReservation
        join ConferenceDays on ConferenceReservation.IDConferenceDay = ConferenceDays.IDConferenceDay
        join Conferences on ConferenceDays.IDConference = Conferences.IDConference
        where ConferenceReservation.IDConferenceReservation=@IDConferenceReservation) > 14
       or (
         (SELECT IDClient from ConferenceReservation
            where IDConferenceReservation=@IDConferenceReservation) != @IDClient
       )
      BEGIN
        RAISERROR ('Too late to make reservation changes, or mismatched ID', 16,1)
        ROLLBACK TRANSACTION
      END
  END

  UPDATE dbo.ConferenceReservation
    set dbo.ConferenceReservation.PeopleCount = @NewPeopleCount

END
go

CREATE PROCEDURE deleteConferenceParticipant(
  @IDClient                INT = NULL,
  @IDConferenceParticipant INT
)
AS
  BEGIN
    SET NOCOUNT ON

    IF @IDClient IS NOT NULL
      BEGIN
        IF DATEDIFF(DAY, GETDATE(), (
          SELECT date
          FROM ConferenceDays
            JOIN ConferenceReservation
              ON ConferenceReservation.IDConferenceDay = ConferenceDays.IDConferenceDay
            JOIN ConferenceParticipants
              ON ConferenceParticipants.IDConferenceReservation = ConferenceReservation.IDConferenceReservation
          WHERE ConferenceParticipants.IDConferenceParticipants = @IDConferenceParticipant
        )) > 14
        BEGIN
          DELETE
          FROM WorkshopParticipant
          WHERE IDConferenceParticipants IN
                (SELECT ConferenceParticipants.IDConferenceParticipants
                 FROM ConferenceParticipants
                   JOIN ConferenceReservation
                     ON ConferenceParticipants.IDConferenceReservation = ConferenceReservation.IDConferenceReservation
                 WHERE ConferenceReservation.IDClient = @IDClient AND
                       ConferenceParticipants.IDConferenceParticipants = @IDConferenceParticipant)

          DELETE
          FROM ConferenceParticipants
          WHERE IDConferenceParticipants IN
                (SELECT ConferenceParticipants.IDConferenceParticipants
                 FROM ConferenceParticipants
                   JOIN ConferenceReservation
                     ON ConferenceParticipants.IDConferenceReservation = ConferenceReservation.IDConferenceReservation
                 WHERE ConferenceReservation.IDClient = @IDClient AND
                       ConferenceParticipants.IDConferenceParticipants = @IDConferenceParticipant)
        END
        ELSE
          BEGIN
            RAISERROR ('It is too late to edit participant list',16,1)
          END
      END
    ELSE
      BEGIN
        DELETE
        FROM WorkshopParticipant
        WHERE IDConferenceParticipants IN
              (SELECT ConferenceParticipants.IDConferenceParticipants
               FROM ConferenceParticipants
                 JOIN ConferenceReservation
                   ON ConferenceParticipants.IDConferenceReservation = ConferenceReservation.IDConferenceReservation
               WHERE ConferenceParticipants.IDConferenceParticipants = @IDConferenceParticipant)

        DELETE
        FROM ConferenceParticipants
        WHERE IDConferenceParticipants IN
              (SELECT ConferenceParticipants.IDConferenceParticipants
               FROM ConferenceParticipants
                 JOIN ConferenceReservation
                   ON ConferenceParticipants.IDConferenceReservation = ConferenceReservation.IDConferenceReservation
               WHERE ConferenceParticipants.IDConferenceParticipants = @IDConferenceParticipant)
      END
  END
go

CREATE PROCEDURE deleteWorkshopParticipant(
  @IDClient                INT = NULL,
  @IDConferenceParticipant INT
)
AS
  BEGIN
    SET NOCOUNT ON

    IF @IDClient IS NOT NULL
      BEGIN
        DELETE
        FROM WorkshopParticipant
        WHERE IDConferenceParticipants IN
              (SELECT ConferenceParticipants.IDConferenceParticipants
               FROM ConferenceParticipants
                 JOIN ConferenceReservation
                   ON ConferenceParticipants.IDConferenceReservation = ConferenceReservation.IDConferenceReservation
               WHERE ConferenceReservation.IDClient = @IDClient AND
                     ConferenceParticipants.IDConferenceParticipants = @IDConferenceParticipant)
      END
    ELSE
      BEGIN
        DELETE
        FROM WorkshopParticipant
        WHERE IDConferenceParticipants IN
              (SELECT ConferenceParticipants.IDConferenceParticipants
               FROM ConferenceParticipants
                 JOIN ConferenceReservation
                   ON ConferenceParticipants.IDConferenceReservation = ConferenceReservation.IDConferenceReservation
               WHERE ConferenceParticipants.IDConferenceParticipants = @IDConferenceParticipant)
      END

  END
go

CREATE PROCEDURE dbo.addClient
  @isCompany bit,
  @Login      VARCHAR(20),
  @Password   VARCHAR(50),
    @Email      VARCHAR(50),
    @Phone      VARCHAR(15),
    @City       VARCHAR(50),
    @Street     VARCHAR(50),
    @Country    VARCHAR(50),
    @PostalCode VARCHAR(6),
    @Address    VARCHAR(10),
  @CompanyName varchar(50)=NULL,
  @WWW         varchar(50)=NULL,
  @Name        varchar(50)=NULL,
  @LastName    varchar(50)=NULL
AS
BEGIN
  DECLARE @fail BIT
  SET @fail=0
  IF @isCompany=1
    BEGIN
      IF @CompanyName is NULL
        BEGIN
          SET @fail=1
          RAISERROR ('CompanyName missing',16,1)
          ROLLBACK TRANSACTION
        END
    END
  IF @isCompany=0
    BEGIN
      IF @Name is null or @LastName is NULL
        BEGIN
          SET @fail=1
          RAISERROR ('Name or LastName missing',16,1)
          ROLLBACK TRANSACTION
        END
    END

if @fail=0
  BEGIN
    INSERT INTO Client(
      Login, Password, email, City, Street, Country, PostalCode, Address, Phone
    )
    VALUES(@Login, @Password, @Email,@City,@Street,@Country,@PostalCode,@Address,@Phone)
    DECLARE @ID int
    SET @ID =(select IDClient
              from dbo.Client
              where dbo.Client.Login=@Login)

    IF @isCompany=1
      BEGIN
          INSERT INTO Company(IDClient,Name,WWW) VALUES(@ID,@CompanyName,@WWW)
      END
    ELSE
      BEGIN
          INSERT INTO Individual(IDClient,Name,LastName) VALUES(@ID,@Name,@LastName)
      END
    END
  END
go

