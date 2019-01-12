--ile studentow
--parametr=idrezerwacjikonferencji
CREATE FUNCTION students_count
(
@param int
)
RETURNS int
AS
BEGIN
DECLARE @suma int
SET @suma = ISNULL((
SELECT count(*) from ConferenceParticipants
  join ConferenceReservation on ConferenceParticipants.IDConferenceReservation = ConferenceReservation.IDConferenceReservation
  WHERE ConferenceReservation.IDConferenceReservation=@param
  AND ConferenceParticipants.StudentID is NOT NULL
                   ),0)
RETURN @suma
END
go

--Parametr: idrezerwacji konferencji
--jezeli nie znajdzie znizki, zwraca cenę dnia * 1
CREATE FUNCTION find_price_per_day
(
@param int
)
RETURNS money
AS
BEGIN
DECLARE @suma MONEY
DECLARE @price MONEY

SET @suma = isnull((SELECT top 1 Discounts.Discount FROM ConferenceReservation
JOIN ConferenceDays ON ConferenceReservation.IDConferenceDay = ConferenceDays.IDConferenceDay
JOIN Discounts ON ConferenceDays.IDConferenceDay = Discounts.IDConferenceDay
WHERE ConferenceReservation.IDConferenceReservation=@param
AND ConferenceReservation.ReservationDate< Discounts.UntilDate
ORDER BY Discounts.UntilDate ASC ),1)


SET @price = (SELECT ConferenceDays.Price from ConferenceDays
  JOIN ConferenceReservation on ConferenceDays.IDConferenceDay = ConferenceReservation.IDConferenceDay
where ConferenceReservation.IDConferenceReservation=@param)

RETURN (@suma*@price)
END
go


--Policz_cene ­ funkcja podaję cenę warsztatu dla rezerwacji warsztatu o podanym
--rezerwacja warsztatu id
CREATE FUNCTION price_workshop
(
@param int
)
RETURNS MONEY
AS
BEGIN
DECLARE @suma MONEY
SET @suma=ISNULL((SELECT WorkshopReservation.PeopleCount*Workshops.Price
FROM WorkshopReservation JOIN Workshops ON WorkshopReservation.IDWorkshop=Workshops.IDWorkshop
WHERE IDWorkshopReservation=@param),0)
RETURN @suma
END
go

CREATE FUNCTION isClientACompany(
  @ID int
)
  RETURNS bit
  AS
  BEGIN
    IF exists(
      select *
      from Individual
      where Individual.IDClient=@ID
    )
      RETURN 0;
    RETURN 1;
  END
go


--zwraca cene warsztatow danej rezerwacji konferencji
CREATE FUNCTION count_payment_for_workshops
(
@param int
)
RETURNS MONEY
AS
BEGIN
DECLARE @suma MONEY

SET @suma =isnull((Select SUM(dbo.price_workshop(WorkshopReservation.IDWorkshopReservation)) FROM WorkshopReservation
  join ConferenceReservation on WorkshopReservation.IDConferenceReservation = ConferenceReservation.IDConferenceReservation
  join Workshops on WorkshopReservation.IDWorkshop = Workshops.IDWorkshop
  WHERE ConferenceReservation.IDConferenceReservation=@param AND Workshops.Canceled=0),0)

  RETURN @suma
end
go

--Oblicza caly koszt dla danej
--idRezerwacjikonferencji
CREATE FUNCTION count_payment
(
@param int
)
RETURNS MONEY
AS
BEGIN
DECLARE @suma MONEY

SET @suma = ISNULL((SELECT ( ConferenceReservation.PeopleCount*dbo.find_price_per_day(ConferenceReservation.IDConferenceReservation)
- dbo.students_count(ConferenceReservation.IDConferenceReservation)*dbo.find_price_per_day(ConferenceReservation.IDConferenceReservation)/2 )
FROM ConferenceReservation WHERE IDConferenceReservation=@param),0)

declare @suma2 MONEY
exec @suma2 =count_payment_for_workshops @param
SET @suma2 = @suma2 +@suma

RETURN @suma2
END
go


CREATE FUNCTION freePlacesForConferenceDay(
  @IDConferenceDay int
)
  RETURNS INT
  AS
  BEGIN
    RETURN(
      select ConferenceDays.Capacity-ISNULL((select sum(PeopleCount)
                                      from ConferenceReservation
                                      where ConferenceReservation.IDConferenceDay=@IDConferenceDay and
                                            ConferenceReservation.Canceled=0
                                      group by ConferenceReservation.IDConferenceDay
                                      ), 0)
      from ConferenceDays
      where ConferenceDays.IDConferenceDay=@IDConferenceDay

    )
  END
go

CREATE FUNCTION freePlacesForWorkshop(
  @IDWorkshop int
)
  RETURNS INT
  AS
  BEGIN
    IF exists(select *
              from Workshops
              where Workshops.IDWorkshop=@IDWorkshop and Workshops.Canceled=1)
      BEGIN
        RETURN NULL
      END

    RETURN(
      select Workshops.Capacity-ISNULL((select sum(PeopleCount)
                                      from WorkshopReservation
                                      where WorkshopReservation.IDWorkshop=@IDWorkshop and
                                            WorkshopReservation.Canceled=0
                                      group by WorkshopReservation.IDWorkshop
                                      ), 0)
      from Workshops
      where Workshops.IDWorkshop=@IDWorkshop
    )
  END
go

--Oblicza ile zapłacano za rezerwacje
CREATE FUNCTION count_paid
(
@param int
)
RETURNS MONEY
AS
BEGIN
DECLARE @suma MONEY

SET @suma = ISNULL((
    SELECT sum(Payments.Amount)from Payments
    where IDConferenceReservation=@param
                   ),0)

RETURN @suma
END
go


