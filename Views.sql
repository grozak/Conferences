
CREATE VIEW CompanyOverview AS
SELECT Client.IDClient,Client.Login,Client.Password,Client.Email,Company.WWW, Client.Country,Client.City,
  Client.Street,Client.Adderss,'Company' as "Type"
FROM dbo.Client
  join Company on Client.IDClient = Company.IDClient
go

CREATE VIEW IndividualOverview AS
SELECT Individual.Name, Individual.Lastname, Client.IDClient,Client.Login,Client.Password,Client.Email, Client.Country,Client.City,
  Client.Street,Client.Adderss,'Individual' as "Type"
FROM dbo.Client
  join Individual on Client.IDClient = Individual.IDClient
go

CREATE VIEW ConferenceParticipantsOverview AS
SELECT
  Participants.Name,
  Participants.Street,
  Participants.City,
  Participants.email,
  Participants.Login,
  Participants.Password,
  Conferences.Name as 'Conference Name',
  ConferenceDays.IDConferenceDay
FROM dbo.Participants
  join ConferenceParticipants on ConferenceParticipants.IDParticipant = Participants.IDParticipant
  join ConferenceReservation on ConferenceReservation.IDConferenceReservation = ConferenceParticipants.IDConferenceReservation
  left OUTER join ConferenceDays on ConferenceDays.IDConferenceDay = ConferenceReservation.IDConferenceDay
  left OUTER join Conferences on ConferenceDays.IDConference = Conferences.IDConference
  WHERE Conferences.EndDate>=(GETDATE())
go

CREATE VIEW CanceledWorkshopsReservation AS
SELECT *
FROM dbo.WorkshopReservation
WHERE (WorkshopReservation.Canceled)=1
go

CREATE VIEW ChargeForClientPerDay AS
SELECT
  C.IDClient as 'Client ID',
  CON.Name as  'Conference',
  CD.IDConferenceDay as 'Days',
  CR.PeopleCount as 'People Registered',
  CR.PeopleCount*CD.Price   as 'Charge for entrance',
  sum(WR.PeopleCount*WOR.Price) as 'Charge for Workshop'
FROM dbo.ConferenceReservation as CR
  full join ConferenceDays as CD on CR.IDConferenceDay = CD.IDConferenceDay
  join Conferences as CON on CON.IDConference = CR.IDConferenceDay
  join Client as C on CR.IDClient = C.IDClient
  left join WorkshopReservation as WR on CR.IDConferenceReservation = WR.IDConferenceReservation
  left  join Workshops as WOR on WR.IDWorkshop = WOR.IDWorkshop

where (ABS(DATEDIFF(DAY,CR.ReservationDate,CON.StartDate))<14)
GROUP BY
 C.IDClient,
  CON.Name,
  CD.IDConferenceDay,
  CR.PeopleCount,
  CR.PeopleCount,
  CD.Price
go

CREATE VIEW WorkshopOverview AS

  (SELECT
     W.IDWorkshop                                               AS "Workshop ID",
     W.Name                                                     AS "Workshop name",
     W.IDConferenceDay                                          AS "Conference Day ID",
     (SELECT Conferences.Name
      FROM Conferences
        JOIN ConferenceDays ON Conferences.IDConference = ConferenceDays.IDConference
      WHERE ConferenceDays.IDConferenceDay = W.IDConferenceDay) AS "Conference",
     W.StartTime                                                AS "Start time",
     W.EndTime                                                  AS "End time",
      (SELECT ConferenceDays.Date from ConferenceDays
          where W.IDConferenceDay = ConferenceDays.IDConferenceDay )AS "Date",
     W.Price                                                    AS "Entry price",
     'Active'                                                   AS "Availability"

   FROM dbo.Workshops AS W
   WHERE (W.Canceled) = 0
   GROUP BY W.IDConferenceDay, W.StartTime, W.Price, W.EndTime, W.IDWorkshop, W.Name
  )
  UNION
  (
      SELECT
     W.IDWorkshop                                               AS "Workshop ID",
     W.Name                                                     AS "Workshop name",
     W.IDConferenceDay                                          AS "Conference Day ID",
     (SELECT Conferences.Name
      FROM Conferences
        JOIN ConferenceDays ON Conferences.IDConference = ConferenceDays.IDConference
      WHERE ConferenceDays.IDConferenceDay = W.IDConferenceDay) AS "Conference",
     W.StartTime                                                AS "Start time",
     W.EndTime                                                  AS "End time",
        (SELECT ConferenceDays.Date from ConferenceDays
          where W.IDConferenceDay = ConferenceDays.IDConferenceDay )AS "Date",
     W.Price                                                    AS "Entry price",
     'Canceled'                                                   AS "Availability"

   FROM dbo.Workshops AS W
   WHERE (W.Canceled) = 1
   GROUP BY W.IDConferenceDay, W.StartTime, W.Price, W.EndTime, W.IDWorkshop, W.Name
  )
go

CREATE VIEW UpcomingConferences AS
SELECT c.Name, c.StartDate, c.EndDate,
  days.IDConferenceDay,isnull((
  SELECT SUM(ConferenceParticipants.IDParticipant) FROM ConferenceParticipants
  join ConferenceReservation ON ConferenceParticipants.IDConferenceReservation = ConferenceReservation.IDConferenceReservation
  where days.IDConferenceDay = ConferenceReservation.IDConferenceDay
),0) as 'Participants'

FROM Conferences as c
  FULL JOIN ConferenceDays as days ON c.IDConference = days.IDConference
WHERE (c.EndDate >= GETDATE())
GROUP BY c.IDConference, c.Name, c.StartDate, c.EndDate,days.IDConferenceDay
go

CREATE VIEW MissingParticipantData AS
SELECT
  ConferenceReservation.IDClient,
  (
    SELECT Client.Phone
    FROM Client
    WHERE Client.IDClient = ConferenceReservation.IDClient
  ) as 'Phone',
  isnull(
      (SELECT Individual.Name+' '+Individual.Lastname from Individual
          join Client on Individual.IDClient = Client.IDClient
          WHERE Client.IDClient=ConferenceReservation.IDClient
      ),
      (
        SELECT Company.Name from Company
          join Client on Company.IDClient = Client.IDClient
          WHERE Client.IDClient=ConferenceReservation.IDClient
      )
  ) as 'Name',

  ConferenceReservation.IDConferenceReservation,
 ABS(DATEDIFF(DAY,ConferenceReservation.ReservationDate,Conferences.StartDate)) as 'Days To Conference',
  ConferenceReservation.IDConferenceDay,ConferenceReservation.PeopleCount AS 'People requested',
   (count(ConferenceParticipants.IDParticipant)) as 'People registered'

FROM dbo.ConferenceReservation
join ConferenceDays ON ConferenceReservation.IDConferenceDay = ConferenceDays.IDConferenceDay
join Conferences on ConferenceDays.IDConference = Conferences.IDConference
full join ConferenceParticipants on ConferenceReservation.IDConferenceReservation = ConferenceParticipants.IDConferenceReservation

where (ABS(DATEDIFF(DAY,ConferenceReservation.ReservationDate,Conferences.StartDate))<14)
GROUP BY
   ConferenceReservation.IDClient,
  ConferenceReservation.IDConferenceReservation,
  ConferenceReservation.IDConferenceDay,
  ConferenceReservation.ReservationDate,Conferences.StartDate,
  ConferenceReservation.PeopleCount
  having (count(ConferenceParticipants.IDParticipant) < ConferenceReservation.PeopleCount)
go

CREATE VIEW ParticipantsForWorkshops AS
SELECT
     Participants.Name,
     Participants.Lastname,
     Participants.email,
      Workshops.Name as 'Workshop',
      Workshops.Price,
      Workshops.StartTime,
      Workshops.EndTime,
     Conferences.Name as 'Conference name',
    ConferenceDays.IDConferenceDay
   FROM Participants
     JOIN ConferenceParticipants ON Participants.IDParticipant = ConferenceParticipants.IDParticipant
     JOIN ConferenceReservation
       ON ConferenceParticipants.IDConferenceReservation = ConferenceReservation.IDConferenceReservation
     JOIN ConferenceDays ON ConferenceReservation.IDConferenceDay = ConferenceDays.IDConferenceDay
     join Conferences on ConferenceDays.IDConference = Conferences.IDConference
      JOIN Workshops on ConferenceDays.IDConferenceDay = Workshops.IDConferenceDay
    GROUP BY
      Conferences.Name,
      ConferenceDays.IDConferenceDay,
      Workshops.Name,
      Workshops.Price,
      Workshops.StartTime,
      Workshops.EndTime,
      Participants.Name,
     Participants.Lastname,
     Participants.email
go

CREATE VIEW conferenceReservationPaymentOverview AS
SELECT
  Conferences.Name,
  Conferences.IDConference,
  ConferenceDays.IDConferenceDay,
  ConferenceDays.Price,
  ConferenceDays.Capacity,
  (dbo.freePlacesForConferenceDay(ConferenceDays.IDConferenceDay)) as 'Available places',
  ConferenceReservation.IDConferenceReservation,
  (dbo.count_paid(ConferenceReservation.IDConferenceReservation)) as 'Paid amount',
  (dbo.count_payment(ConferenceReservation.IDConferenceReservation)) as 'Due amount'
  FROM Conferences
  join ConferenceDays on Conferences.IDConference = ConferenceDays.IDConference
  join ConferenceReservation on ConferenceDays.IDConferenceDay = ConferenceReservation.IDConferenceDay
  where Conferences.Canceled=0 and ConferenceDays.Canceled=0 and ConferenceReservation.Canceled=0
go

CREATE VIEW ConferenceDayParticipantsList as
select
  ConferenceDays.IDConferenceDay,
  ConferenceReservation.IDConferenceReservation,
  Participants.Name,
  Participants.Lastname,
  Participants.email
FROM ConferenceDays
  join ConferenceReservation on ConferenceDays.IDConferenceDay = ConferenceReservation.IDConferenceDay
  join ConferenceParticipants on ConferenceReservation.IDConferenceReservation = ConferenceParticipants.IDConferenceReservation
  join Participants on ConferenceParticipants.IDParticipant = Participants.IDParticipant
GROUP BY ConferenceDays.IDConferenceDay,
  ConferenceReservation.IDConferenceReservation,
  Participants.Name,
  Participants.Lastname,
  Participants.email
go

create view popularClients as
  SELECT top 100
    c.IDClient,
    c.Login,
    (
      isnull(
          (SELECT name from Individual where Individual.IDClient = c.IDClient),
            (SELECT name from Company where Company.IDClient = c.IDClient)
      )
    ) as 'Customer Name',
    (
      SELECT count(ConferenceReservation.IDConferenceReservation) from ConferenceReservation
      where ConferenceReservation.IDClient = c.IDClient
    ) as 'No. of reservation'

  FROM Client as c
  ORDER BY
(
      SELECT count(ConferenceReservation.IDConferenceReservation) from ConferenceReservation
      where ConferenceReservation.IDClient = c.IDClient
    ) desc
go