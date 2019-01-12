--VIEW Function payments_from_client
CREATE PROCEDURE VIEW_payments_from_client (@id INT)
AS
(
    SELECT
    Client.IDClient,
      (
        (SELECT Individual.Name from Individual
        WHERE Individual.IDClient = Client.IDClient)
        +(SELECT Individual.Lastname from Individual
            WHERE Individual.IDClient = Client.IDClient)
      )
        as 'Name',
      ConferenceReservation.IDConferenceReservation,
      ConferenceDays.IDConferenceDay,
      Conferences.Name as 'Conference Name',
      Payments.Amount,
      Payments.PaymentDate as 'Payment date'

    from Client
  left join ConferenceReservation on Client.IDClient = ConferenceReservation.IDClient
  join ConferenceDays on ConferenceReservation.IDConferenceDay = ConferenceDays.IDConferenceDay
  JOIN Conferences on ConferenceDays.IDConference = Conferences.IDConference
  join Payments on ConferenceReservation.IDConferenceReservation = Payments.IDConferenceReservation
    WHERE Client.IDClient = @id
  GROUP BY Client.IDClient,ConferenceReservation.IDConferenceReservation,
    ConferenceDays.IDConferenceDay,Conferences.Name,Payments.Amount,Payments.PaymentDate
)
go

--VIEW_payments_for_conference pokazuje oplaty za dany dzień konferencji
CREATE PROCEDURE VIEW_payments_for_conference (@id INT)
AS
(
    SELECT
      Conferences.IDConference as 'Conference id',
      Conferences.Name as 'Conference Name',
      ConferenceDays.IDConferenceDay as 'Conference day id',
      ConferenceDays.Date 'Conference day date',
      ConferenceReservation.IDConferenceReservation as 'Conference reservation id',
      Client.IDClient as 'Client id',
      Payments.Amount as 'Paid amount',
      Payments.PaymentDate as 'Payment date'

    from Conferences
    join ConferenceDays on Conferences.IDConference = ConferenceDays.IDConference
    left join ConferenceReservation on ConferenceDays.IDConferenceDay = ConferenceReservation.IDConferenceDay
    join Client on ConferenceReservation.IDClient = Client.IDClient
    left join Payments on ConferenceReservation.IDConferenceReservation = Payments.IDConferenceReservation
    where Conferences.IDConference=@id
)
go

--pokazuje ceny konferencji
CREATE PROCEDURE VIEW_prices_for_conference (@id INT)
AS
(
    SELECT
      Conferences.IDConference as 'Conference id',
      Conferences.Name as 'Conference Name',
      Conferences.StartDate as 'Start date',
      Conferences.EndDate as 'End date',
      ConferenceDays.IDConferenceDay as 'Conference day id',
      ConferenceDays.Date as 'Conference day date',
      ConferenceDays.Price as 'Price',
      Discounts.UntilDate as 'Last discount day',
      (1-Discounts.Discount)*100 as 'Discount [%]'

    from Conferences
    join ConferenceDays on Conferences.IDConference = ConferenceDays.IDConference
    left join Discounts on ConferenceDays.IDConferenceDay = Discounts.IDConferenceDay

    where Conferences.IDConference=@id
)
go

CREATE PROCEDURE VIEW_participants_for_conference_day (@id INT)
AS
(
    SELECT
      ConferenceDays.IDConferenceDay,
      ConferenceDays.Date,
      Conferences.Name,
      Participants.Name,
      Participants.Lastname,
      Participants.Phone,
      Participants.email,
      Participants.Address,
      Participants.Street,
      Participants.City,
      Participants.Country
    from ConferenceDays
    join Conferences on ConferenceDays.IDConference = Conferences.IDConference
    join ConferenceReservation on ConferenceDays.IDConferenceDay = ConferenceReservation.IDConferenceDay
    JOIN ConferenceParticipants on ConferenceReservation.IDConferenceReservation = ConferenceParticipants.IDConferenceReservation
    join Participants on ConferenceParticipants.IDParticipant = Participants.IDParticipant
  where ConferenceDays.IDConferenceDay = @id

)
go


--IDENTYFIKATORY, widok generuje uczestnikom dane do identyfikatorow na konferencje (bierze @id=id konferencji)
CREATE PROCEDURE VIEW_GENERATE_ID (@id INT)
AS
 return SELECT
      ROW_NUMBER() OVER(ORDER BY Participants.IDParticipant ASC) AS ID,
       Participants.Name,
       Participants.Lastname,
       Participants.email,
       Conferences.Name as 'Conference name'
        from Participants
         join ConferenceParticipants on Participants.IDParticipant = ConferenceParticipants.IDParticipant
         join ConferenceReservation on ConferenceParticipants.IDConferenceReservation = ConferenceReservation.IDConferenceReservation
         join ConferenceDays on ConferenceReservation.IDConferenceDay = ConferenceDays.IDConferenceDay
         JOIN Conferences on ConferenceDays.IDConference = Conferences.IDConference
        where @id = ConferenceDays.IDConference
go

CREATE PROCEDURE VIEW_participants_for_Workhop (@IDWorkshop int)
AS
  BEGIN
      select Participants.Name, Participants.Lastname, Participants.email, Participants.Phone, Participants.City,
        Participants.street, Participants.Address,Participants.PostalCode, Participants.Country
      from WorkshopParticipant
      join ConferenceParticipants
        on ConferenceParticipants.IDConferenceParticipants=WorkshopParticipant.IDConferenceParticipants
      join Participants
        on Participants.IDParticipant=ConferenceParticipants.IDParticipant
      join WorkshopReservation
        on WorkshopParticipant.IDWorkshopReservation=WorkshopReservation.IDWorkshopReservation
      join Workshops
        on Workshops.IDWorkshop=WorkshopReservation.IDWorkshop
      where Workshops.IDWorkshop=@IDWorkshop
  END
go




CREATE PROCEDURE VIEW_most_attended_workshops (@IDCOnference int=null)
AS
  BEGIN
    if @IDConference is not null
      BEGIN
        select Conferences.Name as 'ConferenceName', Workshops.Name as 'WorkshopName', count(*) as 'attendees'
        from  ConferenceDays
        join Workshops
          on Workshops.IDConferenceDay=ConferenceDays.IDConferenceDay
        join Conferences
          on Conferences.IDConference=ConferenceDays.IDConference
        join workshopreservation
          on WorkshopReservation.IDWorkshop=Workshops.IDWorkshop
        join WorkshopParticipant
          on WorkshopParticipant.IDWorkshopReservation=WorkshopReservation.IDWorkshopReservation
        where Conferences.IDConference=@IDCOnference and Workshops.Canceled=0
        group by Conferences.Name, Workshops.Name
        order by count(*) desc
      END
    ELSE
    BEGIN
      select Conferences.Name as 'ConferenceName', Workshops.Name as 'WorkshopName', count(*) as 'attendees'
      from Workshops
        join ConferenceDays
          on Workshops.IDConferenceDay=ConferenceDays.IDConferenceDay
        join Conferences
          on Conferences.IDConference=ConferenceDays.IDConference
        join workshopreservation
          on WorkshopReservation.IDWorkshop=Workshops.IDWorkshop
        join WorkshopParticipant
          on WorkshopParticipant.IDWorkshopReservation=WorkshopReservation.IDWorkshopReservation
        where Workshops.Canceled=0
        group by Conferences.Name, Workshops.Name
        order by count(*) desc
    END
  END
go

CREATE PROCEDURE VIEW_workshop_reservations_for_ConferenceReservation (@IDConferenceReservation int)
AS
  BEGIN
    select Workshops.Name, WorkshopReservation.Canceled, WorkshopReservation.PeopleCount
    from WorkshopReservation
    join Workshops
      on Workshops.IDWorkshop=WorkshopReservation.IDWorkshop
    where WorkshopReservation.IDConferenceReservation=1
    order by WorkshopReservation.canceled, WorkshopReservation.IDWorkshop
  END
go