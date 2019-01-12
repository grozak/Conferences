create table Conferences
(
	IDConference int identity
		primary key,
	Name varchar(50) not null,
	StartDate date not null,
	EndDate date not null,
	Canceled bit default 0 not null
)
go

--data rezerwacji musi byc wczesniejsza niz data rozpoczecia konferencji
CREATE TRIGGER check_conference_dates
 on Conferences
 after insert, UPDATE  as
 BEGIN

   DECLARE @startdata as DATE
   set @startdata = (SELECT inserted.StartDate from inserted)

   DECLARE @enddata as DATE
   set @enddata = (SELECT inserted.EndDate from inserted)

   if (
     @startdata > @enddata
   )
 begin
   RAISERROR ('Start date can not be after end date', 16, 1)
   ROLLBACK TRANSACTION
 END
 END
go

create table ConferenceDays
(
	IDConferenceDay int identity
		primary key,
	IDConference int not null
		constraint FK_DniKonferencji_Konferencje
			references Conferences,
	Capacity int not null,
	Price money not null,
	Date date default '1970-01-01',
	Canceled bit default 0 not null
)
go

CREATE TRIGGER can_add_day
ON  ConferenceDays
after INSERT as
BEGIN
  if not exists(SELECT * from inserted
    join Conferences on Conferences.IDConference = inserted.IDConference
    where (inserted.Date>=Conferences.StartDate) and (inserted.Date<=Conferences.EndDate)
  )
BEGIN
RAISERROR ('Can not add day', 16,1)
ROLLBACK TRANSACTION
END
END
go

CREATE TRIGGER can_add_day_same_date
ON  ConferenceDays
after INSERT,UPDATE as
BEGIN

   DECLARE @idConfDay as int
   SET @idConfDay = (SELECT inserted.IDConferenceDay from inserted)

   DECLARE @date as DATE
   SET @date = (SELECT inserted.Date from inserted)

   DECLARE @Conf as int
   SET @Conf = (SELECT Conferences.IDConference from Conferences
                JOIN ConferenceDays on Conferences.IDConference = ConferenceDays.IDConference
                WHERE ConferenceDays.IDConferenceDay = @idConfDay)

 if(
  (SELECT count(ConferenceDays.IDConferenceDay) from ConferenceDays
   join Conferences on ConferenceDays.IDConference = Conferences.IDConference
    where ConferenceDays.Date = @date
     and ConferenceDays.IDConference=@Conf) >1
 )

BEGIN
RAISERROR ('Can not add day-wrong date', 16,1)
ROLLBACK TRANSACTION
END
END
go

CREATE TRIGGER conference_day_canceled
  ON ConferenceDays
  AFTER INSERT, UPDATE
  AS
  BEGIN
    IF EXISTS(
      select *
      from inserted
      join Conferences
      on Conferences.IDConference=inserted.IDConference
      where (COnferences.Canceled=1 and inserted.Canceled=0)
    )
      BEGIN
        RAISERROR ('Can not add Conference Day for canceled Conference',16,1)
        ROLLBACK TRANSACTION
      END
  END
go

CREATE TRIGGER can_decrease_conf_day_capacity
ON  ConferenceDays
after update as
BEGIN
 if exists (select *
           from inserted as dc
           join ConferenceReservation as cr
           on cr.IDConferenceDay=dc.IDConferenceDay
           group by cr.IDConferenceDay, dc.Capacity
           having sum(cr.PeopleCount)>dc.Capacity
 )
BEGIN
RAISERROR ('Can not decrease capacity of conference day. Too many reservations', 16,1)
ROLLBACK TRANSACTION
END
END
go

create table Discounts
(
	IDDiscount int identity
		primary key,
	IDConferenceDay int not null
		constraint FK_Zniżki_DniKonferencji
			references ConferenceDays,
	Discount money not null,
	UntilDate date not null
)
go

CREATE TRIGGER can_add_discount
ON  Discounts
after INSERT,update as
BEGIN
 if exists (select *
           from inserted
          join ConferenceDays on ConferenceDays.IDConferenceDay = inserted.IDConferenceDay
          join Conferences on Conferences.IDConference = ConferenceDays.IDConferenceDay
          where inserted.UntilDate > Conferences.StartDate
 )
BEGIN
RAISERROR ('Can not add discount after the conference begining', 16,1)
ROLLBACK TRANSACTION
END
END
go

create table Client
(
	IDClient int identity
		primary key,
	Login varchar(20) not null,
	Password varchar(50) not null,
	Email varchar(50) not null,
	Phone varchar(15) not null,
	City varchar(50) not null,
	Street varchar(50) not null,
	Country varchar(50) not null,
	PostalCode varchar(6) not null,
	Address varchar(10) not null
)
go

--sprawdza czy mozna dodac kolejnego uczestnika do rezerwacji konferencji (spr limit rezerwacji)
create trigger login_unique
  on Client
  AFTER INSERT, UPDATE AS
  BEGIN

  DECLARE @login AS VARCHAR(20)
  SET @login= (SELECT Login from inserted )

  DECLARE @Counts as int
  set @Counts = (SELECT count(Client.IDClient) from Client
                  WHERE Client.Login = @login
                )

IF ( 1 < @Counts)
BEGIN
RAISERROR('That login already exists',16,1)
ROLLBACK TRANSACTION
END
END
go

create table Individual
(
	IDClient int not null
		primary key
		constraint FK_Indywidualny_Klient
			references Client,
	Name varchar(50) not null,
	Lastname varchar(50) not null
)
go

create table Company
(
	IDClient int not null
		primary key
		constraint FK_Firma_Klient
			references Client,
	Name varchar(50) not null,
	WWW varchar(50) not null
)
go

create table Participants
(
	IDParticipant int identity
		primary key,
	Name varchar(50) not null,
	Lastname varchar(50) not null,
	email varchar(50) not null,
	Phone varchar(15) not null,
	City varchar(50) not null,
	Street varchar(50) not null,
	Address varchar(10) not null,
	Login varchar(20) not null,
	Password varchar(50) not null,
	Country varchar(50) not null,
	PostalCode varchar(6)
)
go

create trigger login_unique_participants
  on Participants
  AFTER INSERT, UPDATE AS
  BEGIN

  DECLARE @login AS VARCHAR(20)
  SET @login= (SELECT Login from inserted )

  DECLARE @Counts as int
  set @Counts = (SELECT count(Participants.IDParticipant) from Participants
                  WHERE Participants.Login = @login
                )

IF ( 1 < @Counts)
BEGIN
RAISERROR('That login already exists',16,1)
ROLLBACK TRANSACTION
END
END
go

create table ConferenceReservation
(
	IDConferenceReservation int identity
		primary key,
	IDConferenceDay int not null
		constraint FK_RezerwacjaKonferencji_DniKonferencji
			references ConferenceDays,
	IDClient int not null
		constraint FK_RezerwacjaKonferencji_Klient
			references Client,
	ReservationDate date not null,
	Canceled bit not null,
	PeopleCount int default 0
)
go

--data rezerwacji musi byc wczesniejsza niz data rozpoczecia konferencji
CREATE TRIGGER check_reservation_date
 on ConferenceReservation
 after insert, UPDATE  as
 BEGIN

   DECLARE @data as DATE
   set @data = (SELECT inserted.ReservationDate from inserted)

   DECLARE @idConferenceDay as INT
   set @idConferenceDay = (SELECT inserted.IDConferenceDay from inserted)

   if (
     (SELECT Conferences.StartDate from Conferences
       join ConferenceDays on Conferences.IDConference = ConferenceDays.IDConference
       where ConferenceDays.IDConferenceDay=@idConferenceDay)
     < @data
   )
 begin
   RAISERROR ('Reservation after conference date', 16, 1)
   ROLLBACK TRANSACTION
 END
 END
go

CREATE TRIGGER conference_reservation_cancel
ON ConferenceReservation
  AFTER INSERT, UPDATE
  AS
  BEGIN
    IF EXISTS(
      select *
      from inserted
      join ConferenceDays
        on ConferenceDays.IDConferenceDay=inserted.IDConferenceDay
      where (ConferenceDays.Canceled=1 and inserted.Canceled=0)
    )
      BEGIN
        RAISERROR ('Can not make reservation for canceled ConferenceDay',16,1)
        ROLLBACK TRANSACTION
      END
  END
go

CREATE TRIGGER limit_participants_per_day
 on ConferenceReservation
 after insert, UPDATE  as
 BEGIN
   if exists( SELECT *
     from inserted
     join ConferenceDays  on inserted.IDConferenceDay= ConferenceDays.IDConferenceDay
     join ConferenceReservation on  ConferenceDays.IDConferenceDay = ConferenceReservation.IDConferenceDay
     where inserted.IDConferenceDay = ConferenceReservation.IDConferenceDay and ConferenceReservation.Canceled=0
     GROUP BY ConferenceReservation.IDConferenceDay, ConferenceDays.Capacity
     having sum(ConferenceReservation.PeopleCount)>ConferenceDays.Capacity
   )
 begin
   RAISERROR ('Can not add more participants to conference day', 16, 1)
   ROLLBACK TRANSACTION
 END
 END
go

CREATE TRIGGER change_people_count
 on ConferenceReservation
 after UPDATE as
 BEGIN

   DECLARE @conferenceID AS int
   set @conferenceID = (
     SELECT inserted.IDConferenceReservation from inserted
   )

   if ((SELECT count(ConferenceParticipants.IDParticipant) from ConferenceParticipants
        where  ConferenceParticipants.IDConferenceReservation = @conferenceID)
      > (SELECT PeopleCount from ConferenceReservation
          where ConferenceReservation.IDConferenceReservation=@conferenceID))
 begin
   RAISERROR ('Can not decrease people count, too much participants', 16, 1)
   ROLLBACK TRANSACTION
 END
 END
go

create table Payments
(
	IDPayment int identity
		primary key,
	IDConferenceReservation int not null
		constraint FK_Wpłaty_RezerwacjaKonferencji
			references ConferenceReservation,
	Amount money not null,
	PaymentDate date not null
)
go

--sprawdza czy zapalata nie dotyczy anulowanej konferencji
CREATE TRIGGER check_ConferenceReservation_if_canceled
ON Payments
AFTER INSERT,UPDATE AS
BEGIN

   DECLARE @idConf as int
   SET @idConf = (SELECT inserted.IDConferenceReservation from inserted)

   if exists(SELECT * from ConferenceReservation
     where (ConferenceReservation.IDConferenceReservation =@idConf)
     and (ConferenceReservation.Canceled=1)
   )
 BEGIN
RAISERROR ('Reservation has been canseled', 16, 1)
ROLLBACK TRANSACTION
END
END
go

--sprawdza czy zapalata nie jest po poczatku konferencji
CREATE TRIGGER check_payment_date
ON Payments
AFTER INSERT,UPDATE AS
BEGIN

   DECLARE @idConf as int
   SET @idConf = (SELECT inserted.IDConferenceReservation from inserted)

   DECLARE @date as DATE
   SET @date = (SELECT inserted.PaymentDate from inserted)

   if(
     (SELECT ConferenceReservation.ReservationDate from ConferenceReservation
       WHERE ConferenceReservation.IDConferenceReservation=@idConf) < @date
   )

 BEGIN
RAISERROR ('Payment is too late', 16, 1)
ROLLBACK TRANSACTION
END
END
go

--kontrola wpłaty
CREATE TRIGGER conference_payment
ON Payments
AFTER INSERT,UPDATE AS
BEGIN

  DECLARE @ConferenceReservation as INT
  SET @ConferenceReservation = (SELECT IDConferenceReservation from inserted)

  DECLARE @PaidAmount AS float
  SET @PaidAmount = (SELECT sum(Payments.Amount) FROM Payments
  where Payments.IDConferenceReservation = @ConferenceReservation
  )


  if(@PaidAmount > dbo.count_payment(@ConferenceReservation))
BEGIN
RAISERROR ('Too big amount.', 16, 1)
ROLLBACK TRANSACTION
END
END
go

create table ConferenceParticipants
(
	IDConferenceParticipants int identity
		primary key,
	IDParticipant int not null
		constraint FK_UczestnicyKonferencja_Uczestnicy
			references Participants,
	IDConferenceReservation int not null
		constraint FK_UczestnicyKonferencja_RezerwacjaKonferencji
			references ConferenceReservation,
	StudentID int
)
go

create trigger add_to_conference_reservation
  on ConferenceParticipants
  AFTER INSERT AS
  BEGIN

  DECLARE @ConfDayBookingID AS int
  SET @ConfDayBookingID = (SELECT IDConferenceReservation FROM inserted)

  DECLARE @ParticipantsCount AS int
  SET @ParticipantsCount = (SELECT COUNT(*) FROM ConferenceParticipants
  WHERE ConferenceParticipants.IDConferenceReservation = @ConfDayBookingID)
    PRINT @ParticipantsCount

  DECLARE @ParticipantsNo AS int
  SET @ParticipantsNo = (SELECT ConferenceReservation.PeopleCount FROM ConferenceReservation
  WHERE ConferenceReservation.IDConferenceReservation =@ConfDayBookingID)
    PRINT @ParticipantsNo
IF (@ParticipantsNo < @ParticipantsCount)
BEGIN
RAISERROR('Too much participants',16,1)
ROLLBACK TRANSACTION
END
END
go

create trigger is_participant_signed_conference_day
  on ConferenceParticipants
  AFTER INSERT, UPDATE AS
  BEGIN
  IF (select count(*)
    from inserted ins
    join ConferenceReservation cr
    on cr.IDConferenceReservation=ins.IDConferenceReservation
    join ConferenceReservation cr2
    on cr.IDConferenceDay=cr2.IDConferenceDay
    join ConferenceParticipants cp
    on cp.IDConferenceReservation=cr2.IDConferenceReservation
    where ins.IDParticipant=cp.IDParticipant
  )>1
BEGIN
RAISERROR('Participant is already signed',16,1)
ROLLBACK TRANSACTION
END
END
go

--sprawdza czy uzytkownik nie dodaje sie do anuowanej rezerwacji
create trigger is_reservtion_cancelled
  on ConferenceParticipants
  AFTER INSERT,UPDATE AS
  BEGIN

    DECLARE @id as int =( SELECT IDConferenceReservation FROM inserted)

IF exists(
    SELECT ConferenceReservation.IDConferenceReservation
    FROM ConferenceReservation
    WHERE ConferenceReservation.Canceled=1
    and ConferenceReservation.IDConferenceReservation=@id
)
BEGIN
RAISERROR('This reservation has been canceled',16,1)
ROLLBACK TRANSACTION
END
END
go

create table Workshops
(
	IDWorkshop int identity
		primary key,
	IDConferenceDay int not null
		constraint FK_Warsztaty_DniKonferencji
			references ConferenceDays,
	Name varchar(50) not null,
	StartTime time not null,
	EndTime time not null,
	Capacity int not null,
	Price money not null,
	Canceled bit not null
)
go

--poczatek warsztatu < koniec warsztatu
CREATE TRIGGER check_workshop_hours
 on Workshops
 after insert, UPDATE  as
 BEGIN

   DECLARE @starttime as TIME
   set @starttime = (SELECT inserted.StartTime from inserted)

   DECLARE @endtime as time
   set @endtime = (SELECT inserted.EndTime from inserted)

   if (
     @starttime > @endtime
   )
 begin
   RAISERROR ('Start time can not be later than end time', 16, 1)
   ROLLBACK TRANSACTION
 END
 END
go

CREATE TRIGGER can_decrease_workshop_capacity
ON Workshops
AFTER UPDATE AS
BEGIN
IF EXISTS (Select 'Yes'
From inserted INNER JOIN
WorkshopReservation on inserted.IDWorkshop=WorkshopReservation.IDWorkshop
Group BY WorkshopReservation.IDWorkshop,inserted.Capacity
Having Sum(WorkshopReservation.PeopleCount)>inserted.Capacity
)
BEGIN
RAISERROR ('Cannot decrease workshop capacity, too many reservations.', 16,
1)
ROLLBACK TRANSACTION
END
END
go

create table WorkshopReservation
(
	IDWorkshopReservation int identity
		primary key,
	IDWorkshop int not null
		constraint FK_RezerwacjaWarsztatu_Warsztaty
			references Workshops,
	Canceled bit not null,
	IDConferenceReservation int
		constraint FK_RezerwacjaWarsztatu_RezerwacjaKonferencji
			references ConferenceReservation,
	PeopleCount int
)
go

create TRIGGER workshop_limit
 ON WorkshopReservation
AFTER INSERT,UPDATE AS
BEGIN
 if exists (
   select *
   from inserted
     join Workshops on inserted.IDWorkshop=Workshops.IDWorkshop
     join WorkshopReservation on Workshops.IDWorkshop = WorkshopReservation.IDWorkshop
     where inserted.IDWorkshop=WorkshopReservation.IDWorkshop and WorkshopReservation.Canceled=0
     GROUP BY WorkshopReservation.IDWorkshop, Workshops.IDWorkshop,Workshops.Capacity
     HAVING sum(WorkshopReservation.PeopleCount)>Workshops.Capacity
 )
   begin
     RAISERROR ('Can not add more participants to the workshop', 16, 1)
     ROLLBACK TRANSACTION
   END
END
go

CREATE TRIGGER workshop_reservation_cancel
  ON WorkshopReservation
 AFTER INSERT,UPDATE
 AS
BEGIN
 IF EXISTS(select *
           from inserted
           join Workshops
           on Workshops.IDWorkshop=inserted.IDWorkshop
           where Workshops.Canceled=1 and inserted.Canceled=0)
  BEGIN
   RAISERROR ('Can not make reservation for canceled workshop',16,1)
   ROLLBACK TRANSACTION
  END
END
go

create table WorkshopParticipant
(
	IDConferenceParticipants int not null
		constraint FK_UczestnicyWarsztat_UczestnicyKonferencja
			references ConferenceParticipants,
	IDWorkshopReservation int not null
		constraint FK_UczestnicyWarsztat_RezerwacjaWarsztatu
			references WorkshopReservation
)
go

CREATE TRIGGER is_participant_signed_workshop
  ON WorkshopParticipant
  AFTER INSERT, UPDATE
  AS
  BEGIN
    if (select count(*)
        from inserted ins
        join WorkshopReservation wr
        on wr.IDWorkshopReservation=ins.IDWorkshopReservation
        join WorkshopParticipant wp
        on wp.IDWorkshopReservation=wr.IDWorkshopReservation
        where wp.IDConferenceParticipants=ins.IDConferenceParticipants
    )>1
  BEGIN
    RAISERROR ('Participant is already signed to workshop`', 16,1)
    ROLLBACK TRANSACTION
  END
  END
go

CREATE TRIGGER is_time_colision
 ON WorkshopParticipant
 AFTER INSERT, UPDATE
 AS
 BEGIN

   DECLARE @insertedIDConferenceParticipants as int
   set @insertedIDConferenceParticipants = (SELECT inserted.IDConferenceParticipants from inserted )

   DECLARE @insertedIDIDWorkshopReservation as int
   set @insertedIDIDWorkshopReservation = (SELECT inserted.IDWorkshopReservation from inserted )



    DECLARE @User as int
    set @User = (SELECT ConferenceParticipants.IDConferenceParticipants from ConferenceParticipants
      where ConferenceParticipants.IDConferenceParticipants = @insertedIDConferenceParticipants
    )

   DECLARE @Workshop as int
    set @Workshop = (SELECT Workshops.IDWorkshop from Workshops
      join WorkshopReservation on Workshops.IDWorkshop = WorkshopReservation.IDWorkshop
      where @insertedIDIDWorkshopReservation = WorkshopReservation.IDWorkshopReservation
    )

   DECLARE @start as TIME
   set @start = (select Workshops.StartTime from Workshops
     where Workshops.IDWorkshop  = @Workshop
   )

   DECLARE @end as TIME
   set @end = (select Workshops.EndTime from Workshops
     where Workshops.IDWorkshop  = @Workshop
   )

   if (
     SELECT count(Workshops.IDWorkshop) from Workshops
     join WorkshopReservation on Workshops.IDWorkshop = WorkshopReservation.IDWorkshop
     join WorkshopParticipant on WorkshopReservation.IDWorkshopReservation = WorkshopParticipant.IDWorkshopReservation
     join ConferenceParticipants on WorkshopParticipant.IDConferenceParticipants = ConferenceParticipants.IDConferenceParticipants
     where @User = ConferenceParticipants.IDConferenceParticipants
           AND (
                 (@start <= Workshops.EndTime and @start >= Workshops.StartTime)
                  or
                 (@end <= Workshops.EndTime and @start >= Workshops.StartTime)
           )
      )>1
 BEGIN
   RAISERROR ('Participant is already on a different workshop at that time`', 16,1)
   ROLLBACK TRANSACTION
 END
 END
go

create TRIGGER participant_on_conference_day
on WorkshopParticipant
AFTER INSERT, UPDATE AS
BEGIN
if  NOT EXISTS(SELECT *
from inserted
  join WorkshopReservation
    on WorkshopReservation.IDWorkshopReservation = inserted.IDWorkshopReservation
  join Workshops
    on Workshops.IDWorkshop=WorkshopReservation.IDWorkshop
  join ConferenceParticipants
    on ConferenceParticipants.IDConferenceParticipants=inserted.IDConferenceParticipants
  join ConferenceReservation
    on ConferenceParticipants.IDConferenceReservation = ConferenceReservation.IDConferenceReservation
  where Workshops.IDConferenceDay=ConferenceReservation.IDConferenceDay
)
BEGIN
RAISERROR ('Person is not participant of Conference Day', 16,1);
ROLLBACK TRANSACTION
END
END
go