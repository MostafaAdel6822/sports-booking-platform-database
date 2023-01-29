CREATE DATABASE Sports_Platform_DB;
DROP DATABASE Sports_Platform_DB;

GO;
CREATE PROCEDURE createAllTables
AS
CREATE TABLE SystemUser 
(
username VARCHAR(20), 
password VARCHAR(20), 
PRIMARY KEY(username)
);

CREATE TABLE SystemAdmin 
(
ID INT IDENTITY, 
name VARCHAR(20), 
username VARCHAR(20), 
PRIMARY KEY(ID), 
FOREIGN KEY(username) REFERENCES SystemUser(username) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE SportsAssociationManager
(
ID INT IDENTITY, 
name VARCHAR(20), 
username VARCHAR(20), 
PRIMARY KEY(ID),
FOREIGN KEY(username) REFERENCES SystemUser(username) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Club(
club_ID INT IDENTITY, 
name VARCHAR(20), 
location VARCHAR(20), 
PRIMARY KEY(club_ID)
);

CREATE TABLE ClubRepresentative 
(
ID INT IDENTITY, 
name VARCHAR(20), 
club_ID INT, 
username VARCHAR(20), 
PRIMARY KEY(ID),
FOREIGN KEY(club_ID) REFERENCES Club(club_ID) ON DELETE CASCADE ON UPDATE CASCADE,
FOREIGN KEY(username) REFERENCES SystemUser(username) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE TABLE Stadium(
ID INT IDENTITY, 
name VARCHAR(20), 
location VARCHAR(20), 
capacity INT, 
status BIT DEFAULT(1), 
PRIMARY KEY(ID)
)

CREATE TABLE StadiumManager(
ID INT IDENTITY, 
name VARCHAR(20), 
stadium_ID INT, 
username VARCHAR(20)
PRIMARY KEY(ID), 
FOREIGN KEY(stadium_ID) REFERENCES Stadium(ID) ON DELETE CASCADE ON UPDATE CASCADE,
FOREIGN KEY(username) REFERENCES SystemUser(username) ON DELETE NO ACTION ON UPDATE NO ACTION
)

CREATE TABLE Match(
match_ID INT IDENTITY, 
start_time DATETIME, 
end_time DATETIME, 
host_club_ID INT, 
guest_club_ID INT, 
stadium_ID INT, 
PRIMARY KEY(match_ID),
FOREIGN KEY(host_club_ID) REFERENCES Club(club_ID) ON DELETE CASCADE ON UPDATE CASCADE, 
FOREIGN KEY(guest_club_ID) REFERENCES Club(club_ID) ON DELETE NO ACTION ON UPDATE NO ACTION, 
FOREIGN KEY(stadium_ID) REFERENCES Stadium(ID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE TABLE HostRequest(
ID INT IDENTITY, 
representative_ID INT, 
manager_ID INT, 
match_ID INT, 
status VARCHAR(20) DEFAULT('unhandled'), 
PRIMARY KEY(ID), 
FOREIGN KEY(representative_ID) REFERENCES ClubRepresentative(ID) ON DELETE CASCADE ON UPDATE CASCADE, 
FOREIGN KEY(manager_ID) REFERENCES StadiumManager(ID) ON DELETE NO ACTION ON UPDATE NO ACTION, 
FOREIGN KEY(match_ID) REFERENCES Match(match_ID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE TABLE Fan(
national_ID VARCHAR(20), 
name VARCHAR(20), 
birth_date DATETIME, 
address VARCHAR(20), 
phone_no INT, 
status BIT DEFAULT(1), 
username VARCHAR(20), 
PRIMARY KEY(national_ID), 
FOREIGN KEY(username) REFERENCES SystemUser(username) ON DELETE CASCADE ON UPDATE CASCADE
)

CREATE TABLE Ticket(
ID INT IDENTITY, 
status BIT DEFAULT(1), 
match_ID INT, 
PRIMARY KEY(ID), 
FOREIGN KEY(match_ID) REFERENCES Match(match_ID) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE TicketBuyingTransactions(
fan_national_ID VARCHAR(20), 
ticket_ID INT, 
FOREIGN KEY(fan_national_ID) REFERENCES Fan(national_ID) ON DELETE CASCADE ON UPDATE CASCADE, 
FOREIGN KEY(ticket_ID) REFERENCES Ticket(ID) ON DELETE NO ACTION ON UPDATE NO ACTION
)

exec createAllTables
GO;
CREATE PROCEDURE dropAllTables
AS
DROP TABLE HostRequest
DROP TABLE TicketBuyingTransactions
DROP TABLE Ticket
DROP TABLE Match
DROP TABLE SystemAdmin
DROP TABLE SportsAssociationManager
DROP TABLE ClubRepresentative
DROP TABLE Club
DROP TABLE StadiumManager
DROP TABLE Stadium
DROP TABLE Fan
DROP TABLE SystemUser

GO;
CREATE PROCEDURE dropAllProceduresFunctionsViews
AS
DROP PROCEDURE createAllTables, dropAllTables, clearAllTables, addAssociationManager,
    addNewMatch, deleteMatch, deleteMatchesOnStadium, addClub, addTicket, deleteClub,
    addStadium, deleteStadium, blockFan, unblockFan, addRepresentative, addHostRequest,
    addStadiumManager, acceptRequest, rejectRequest, addFan, purchaseTicket, updateMatchHost;
DROP VIEW allAssocManagers, allClubRepresentatives, allStadiumManagers, allFans, allMatches,
    allTickets, allClubs, allStadiums, allRequests, clubsWithNoMatches, matchesPerTeam,
    clubsNeverMatched;
DROP FUNCTION viewAvailableStadiumsOn, allUnassignedMatches, allPendingRequests,
    upcomingMatchesOfClub, availableMatchesToAttend, clubsNeverPlayed,
    matchWithHighestAttendance, matchesRankedByAttendance, requestsFromClub;

GO;
CREATE PROCEDURE clearAllTables
AS
DELETE FROM HostRequest
DELETE FROM TicketBuyingTransactions
DELETE FROM Ticket
DELETE FROM Match
DELETE FROM SystemAdmin
DELETE FROM SportsAssociationManager
DELETE FROM ClubRepresentative
DELETE FROM Club
DELETE FROM StadiumManager
DELETE FROM Stadium
DELETE FROM Fan
DELETE FROM SystemUser

-----------------
-----****** 2.2
-----------------

go;
create function viewClubInfo(@rep_username varchar(20))
RETURNS @rTable TABLE(
clubId int, 
clubName VARCHAR(20), 
location varchar(20)
)
as
begin 
insert into @rTable
select  C.club_ID, C.name, C.location
from Club C 
where C.club_ID=(select CR.club_ID from ClubRepresentative CR where CR.username=@rep_username);
return 
end
go;

go;
create function allPending(@username varchar(20))
returns @rTable TABLE(
RepName varchar(20),
HostName varchar(20),
GuestName varchar(20),
StartTime datetime,
EndTime datetime,
RequestStatus varchar(20)
)
as
begin
insert into @rTable 
select CR.name, C1.name, C2.name, M.start_time, M.end_time, HR.status
FROM HostRequest HR 
	INNER JOIN StadiumManager SM ON HR.manager_id = SM.ID
		INNER JOIN ClubRepresentative CR ON HR.representative_ID = CR.ID 
			INNER JOIN Match M ON HR.match_ID = M.match_ID 
			  INNER JOIN Club C1 on M.host_club_ID=C1.club_ID
				INNER JOIN Club C2 ON M.guest_club_ID = C2.club_ID
where SM.username = @username
return
end
go;




GO;
CREATE VIEW allAssocManagers 
AS 
SELECT SAM.username, SU.password, SAM.name
FROM SportsAssociationManager SAM 
	INNER JOIN SystemUser SU ON SAM.username = SU.username;

GO;
CREATE VIEW allClubRepresentatives 
AS 
SELECT CR.username, SU.password, CR.name AS club_representative, C.name AS club_name
FROM ClubRepresentative CR  
	INNER JOIN SystemUser SU ON CR.username = SU.username
		INNER JOIN Club C ON CR.club_ID = C.club_ID;

GO;
CREATE VIEW allStadiumManagers
AS 
SELECT SM.username, SU.password, SM.name AS stadium_manager, S.name AS stadium_name
FROM StadiumManager SM 
	INNER JOIN SystemUser SU ON SM.username = SU.username
		INNER JOIN Stadium S ON SM.stadium_ID = S.ID;

GO;
CREATE VIEW allFans 
AS
SELECT F.username, SU.password, F.name, F.national_ID, 
	F.birth_date, F.status
FROM Fan F 
	INNER JOIN SystemUser SU ON F.username = SU.username;

GO;
CREATE VIEW allMatches
AS
SELECT C1.name AS host_name, C2.name AS guest_name, M.start_time 
FROM Club C1 
	INNER JOIN Match M ON M.host_club_ID = C1.club_ID
		INNER JOIN Club C2 ON M.guest_club_ID = C2.club_ID 


GO;
CREATE VIEW allTickets
AS
SELECT C1.name AS host_name, C2.name AS guest_name, S.name AS stadium_name, M.start_time
FROM Match M 
	INNER JOIN Club C1 ON C1.club_ID = M.host_club_ID 
		INNER JOIN Club C2 ON M.guest_club_ID = C2.club_ID 
			INNER JOIN Stadium S ON M.stadium_ID = S.ID
				INNER JOIN Ticket T ON T.match_ID = M.match_ID

GO;
CREATE VIEW allClubs
AS
SELECT C.name, C.location
FROM Club C;

GO;
CREATE VIEW allStadiums
AS
SELECT S.name, S.location, S.capacity, S.status
FROM Stadium S;

GO;
CREATE VIEW allRequests 
AS
SELECT CR.username AS representative_name, SM.username AS manager_name, HR.status 
FROM HostRequest HR 
	INNER JOIN StadiumManager SM ON SM.ID = HR.manager_ID
		INNER JOIN ClubRepresentative CR ON HR.representative_ID = CR.ID

-----------------
-----****** 2.3
-----------------

-- i
GO;
CREATE PROCEDURE addAssociationManager
@name VARCHAR(20), 
@username VARCHAR(20), 
@password VARCHAR(20)
AS
IF(NOT EXISTS (SELECT * FROM SystemUser WHERE @username = username))
BEGIN
INSERT INTO SystemUser (username, password) VALUES(@username, @password)
INSERT INTO SportsAssociationManager (name, username) VALUES(@name, @username);
END

-- ii
GO;
CREATE PROCEDURE addNewMatch
@host_name VARCHAR(20), 
@guest_name varChar(20), 
@start_time DateTime, 
@end_time DateTime
AS
INSERT INTO Match (host_club_ID, guest_club_ID, start_time, end_time) 
VALUES ((SELECT club_ID FROM Club WHERE name = @host_name), 
		(SELECT club_ID FROM Club WHERE name = @guest_name), 
		@start_time,
		@end_time);

-- iii
GO;
CREATE VIEW clubsWithNoMatches
AS
SELECT C.name 
FROM Club C
WHERE C.club_ID NOT IN (SELECT M.host_club_ID
						FROM Match M)
	AND C.club_ID NOT IN (SELECT M.guest_club_ID
						  FROM Match M)


-- iv
GO;
CREATE PROCEDURE deleteMatch
@host_name VARCHAR(20), 
@guest_name VARCHAR(20)
AS
DELETE 
FROM Match
WHERE Match.host_club_ID = (SELECT club_ID
							FROM Club 
							WHERE name = @host_name)
	AND Match.guest_club_ID = (SELECT club_ID
							   FROM Club 
							   WHERE name = @guest_name);
go;

CREATE PROCEDURE deleteMatch2
@host_name VARCHAR(20), 
@guest_name VARCHAR(20),
@start DateTime,
@end DateTime
AS
DELETE 
FROM Match
WHERE Match.host_club_ID = (SELECT club_ID
							FROM Club 
							WHERE name = @host_name)
	AND Match.guest_club_ID = (SELECT club_ID
							   FROM Club 
							   WHERE name = @guest_name)
    AND Match.start_time=@start AND Match.end_time=@end;
go;


-- v
GO
CREATE PROCEDURE deleteMatchesOnStadium
@stadium_name VARCHAR(20)
AS
DELETE FROM Match
WHERE stadium_ID = (SELECT ID
					FROM Stadium
					WHERE name = @stadium_name)
	AND start_time > CURRENT_TIMESTAMP;

-- vi
GO;
CREATE PROCEDURE addClub
@club_name VARCHAR(20), 
@clubLocation VARCHAR(20)
AS
INSERT INTO Club (name, location)
VALUES(@club_name, @clubLocation)

-- vii
GO;
CREATE PROCEDURE addTicket
@host_name VARCHAR(20), 
@guest_name VARCHAR(20), 
@start_time DATETIME
AS
INSERT INTO Ticket(match_ID) 
VALUES((SELECT match_ID 
		From Match M
		WHERE M.host_club_ID = (SELECT name FROM Club C1 WHERE C1.name =  @host_name) 
		AND M.guest_club_ID  = (SELECT name FROM Club C2 WHERE C2.name = @guest_name)
		AND M.start_time = @start_time))

-- viii
GO;
CREATE PROCEDURE deleteClub
@club_name VARCHAR(20)
AS
DELETE FROM Club
WHERE name = @club_name

-- ix
GO;
CREATE PROCEDURE addStadium
@stadium_name VARCHAR(20), 
@stadium_location VARCHAR(20), 
@stadium_capacity INT
AS
INSERT INTO Stadium (name, location, capacity)
VALUES (@stadium_name, @stadium_location, @stadium_capacity)

-- x
GO;
CREATE PROCEDURE deleteStadium
@stadium_name VARCHAR(20)
AS
DELETE FROM Stadium WHERE name = @stadium_name

-- xi
GO; 
CREATE PROCEDURE blockFan
@fan_national_ID VARCHAR(20)
AS
UPDATE Fan
SET status = 0
WHERE national_ID = @fan_national_ID

-- xii
GO;
CREATE PROCEDURE unblockFan
@fan_national_ID VARCHAR(20)
AS
UPDATE Fan 
SET status = 1	
WHERE national_ID = @fan_national_ID

-- xiii
GO;
CREATE PROCEDURE addRepresentative
@representative_name VARCHAR(20), 
@represented_club_name VARCHAR(20), 
@representative_username VARCHAR(20), 
@representative_password VARCHAR(20)
AS
IF(NOT EXISTS (SELECT * FROM SystemUser WHERE @representative_username = username))
BEGIN
INSERT INTO SystemUser (username, password)
VALUES (@representative_username, @representative_password)
INSERT INTO ClubRepresentative (name, club_ID, username)
VALUES (@representative_name, (SELECT club_ID FROM Club C WHERE C.name = @represented_club_name), @representative_username)
END



-- xiv
GO;
CREATE FUNCTION viewAvailableStadiumsOn(@dateTime DATETIME)
RETURNS @returnedTable TABLE(stadiumName VARCHAR(20),
location VARCHAR(20),
capacity VARCHAR(20))
AS
BEGIN 
INSERT INTO @returnedTable 
SELECT S.name, S.location, S.capacity 
FROM Stadium S
WHERE S.status = 1
	AND S.ID not in (select M.stadium_ID 
					 from Match M inner join Stadium S on M.stadium_ID=S.ID 
					 where M.start_time = @dateTime)
RETURN
END
go;

select * from SportsAssociationManager;
select * from SystemUser
-- xv
GO;
CREATE PROCEDURE addHostRequest
@clubName VARCHAR(20), 
@stadiumName VARCHAR(20), 
@start_time DATETIME
AS
DECLARE @clubID INT
SELECT @clubID = club_ID FROM Club WHERE name = @clubName

INSERT INTO HostRequest(manager_ID, representative_ID, match_ID, status)

VALUES((SELECT ID
		FROM StadiumManager
		WHERE stadium_ID = (SELECT ID
							FROM Stadium 
							WHERE name = @stadiumName)), 
		(SELECT ID FROM ClubRepresentative WHERE club_ID = @clubID), 
		(SELECT match_ID FROM Match
		WHERE host_club_ID = @clubID AND start_time = @start_time),
		'unhandled'
);

-- xvi
GO;
CREATE FUNCTION allUnassignedMatches(@host_name VARCHAR(20))
RETURNS @matches TABLE(guest_club VARCHAR(20),
start_time DATETIME)
AS
BEGIN

DECLARE @host_club_ID INT;
SELECT @host_club_ID = C.club_ID
FROM Club C
WHERE @host_name = C.name

INSERT INTO @matches
SELECT C.name, M.start_time
FROM Match M
	INNER JOIN Club C ON M.guest_club_ID = C.club_ID
WHERE M.host_club_ID = @host_club_ID AND M.stadium_ID IS NULL;

RETURN
END

-- xvii
GO;
CREATE PROCEDURE addStadiumManager
@stadiumManagerName VARCHAR(20), 
@stadiumName  VARCHAR(20), 
@stadiumManagerUserName VARCHAR(20), 
@stadiumManagerPassword VARCHAR(20)
AS
IF(NOT EXISTS (SELECT * FROM SystemUser WHERE @stadiumManagerUserName = username))
BEGIN
INSERT INTO SystemUser (username, password) 
VALUES (@stadiumManagerUserName, @stadiumManagerPassword)
INSERT INTO StadiumManager (name, stadium_ID, username)
VALUES (@stadiumManagerName, (SELECT ID FROM Stadium S WHERE S.name = @stadiumName), @stadiumManagerUserName)
END

-- xviii
GO;
CREATE FUNCTION allPendingRequests(@username VARCHAR(20))
RETURNS @rTable TABLE(
repName VARCHAR(20), 
guest_name VARCHAR(20), 
start_time DATETIME
)
AS
BEGIN
INSERT INTO @rTable 
SELECT CR.name, C.name, M.start_time
FROM HostRequest HR 
	INNER JOIN StadiumManager SM ON HR.manager_id = SM.ID
		INNER JOIN ClubRepresentative CR ON HR.representative_ID = CR.ID 
			INNER JOIN Match M ON HR.match_ID = M.match_ID 
				INNER JOIN Club C ON M.guest_club_ID = C.club_ID
WHERE SM.username = @username AND HR.status='unhandled'; 
RETURN
END
go;



-- xix
GO;
DROP PROC acceptRequest
go;
CREATE PROCEDURE acceptRequest
@username VARCHAR(20), 
@host_name VARCHAR(20), 
@guest_name VARCHAR(20), 
@start_time DATETIME
AS
DECLARE @manager_ID INT;
SELECT @manager_ID = SM.ID
FROM StadiumManager SM
WHERE SM.username = @username

DECLARE @std_ID INT;
SELECT @std_ID = S.ID
FROM Stadium S INNER JOIN StadiumManager SM
	ON S.ID = SM.stadium_ID
WHERE SM.username = @username

DECLARE @host_club_ID INT;
SELECT @host_club_ID = C.club_ID
FROM Club C
WHERE @host_name = C.name

DECLARE @guest_club_ID INT;
SELECT @guest_club_ID = C.club_ID
FROM Club C
WHERE @guest_name = C.name

DECLARE @match_ID INT;
SELECT @match_ID = M.match_ID
FROM Match M
WHERE M.host_club_ID = @host_club_ID
	AND M.guest_club_ID = @guest_club_ID
		AND M.start_time = @start_time;

UPDATE HostRequest
SET status = 'accepted'
WHERE manager_ID = @manager_ID AND match_ID = @match_ID;

UPDATE Match
SET stadium_ID = @std_ID
WHERE match_ID = @match_ID;

DECLARE @cap INT = 0;
SELECT @cap = capacity
FROM Stadium
WHERE id = @std_id
DECLARE @i INT = 0;
WHILE @I < @cap
BEGIN
INSERT INTO Ticket values (1, @match_ID)
SET @i = @i+1
END

-- xx
GO;
CREATE PROCEDURE rejectRequest
@username VARCHAR(20), 
@host_name VARCHAR(20), 
@guest_name VARCHAR(20), 
@start_time DATETIME
AS
DECLARE @manager_ID INT;
SELECT @manager_ID = SM.ID
FROM StadiumManager SM
WHERE SM.username = @username

DECLARE @host_club_ID INT;
SELECT @host_club_ID = C.club_ID
FROM Club C
WHERE @host_name = C.name

DECLARE @guest_club_ID INT;
SELECT @guest_club_ID = C.club_ID
FROM Club C
WHERE @guest_name = C.name

DECLARE @match_ID INT;
SELECT @match_ID = M.match_ID
FROM Match M
WHERE M.host_club_ID = @host_club_ID AND M.guest_club_ID = @guest_club_ID AND M.start_time = @start_time;

UPDATE HostRequest
SET status = 'rejected'
WHERE manager_ID = @manager_ID AND match_ID = @match_ID;

-- xxi
GO;
CREATE PROCEDURE addFan
@name VARCHAR(20), 
@username VARCHAR(20), 
@password VARCHAR(20), 
@national_id VARCHAR(20), 
@birth_date DATETIME, 
@address VARCHAR(20), 
@phone INT
AS
INSERT INTO SystemUser
VALUES(@username, @password);
INSERT INTO Fan(national_id, name, birth_date, address, phone_no, username)
VALUES(@national_id, @name, @birth_date, @address, @phone, @username);
go;
drop proc addFan

-- xxii
GO;
CREATE FUNCTION upcomingMatchesOfClub(@club_name VARCHAR(20))
RETURNS @matches TABLE(
given_club VARCHAR(20),
competing_club VARCHAR(20),
start_time DATETIME,
stadium_name VARCHAR(20))
AS
BEGIN

DECLARE @given_club_ID INT;
SELECT @given_club_ID = C.club_ID
FROM Club C
WHERE @club_name = C.name

INSERT INTO @matches
SELECT C1.name, C2.name, M.start_time, S.name
FROM Club C1 INNER JOIN Match M ON M.host_club_ID = C1.club_ID
    INNER JOIN Club C2 ON M.guest_club_ID = C2.club_ID
            INNER JOIN Stadium S ON M.stadium_ID = S.ID
WHERE (C1.club_ID = @given_club_ID AND M.start_time > CURRENT_TIMESTAMP)
	OR (C2.club_ID = @given_club_ID AND M.start_time > CURRENT_TIMESTAMP);

RETURN
END
go;


-- xxiii
GO;
CREATE FUNCTION availableMatchesToAttend
(@dateTime DATETIME)
RETURNS @returnedTable TABLE(host_name VARCHAR(20),
guest_name VARCHAR(20),
start_time DATETIME,
stadiumName VARCHAR(20))
AS
BEGIN
INSERT INTO @returnedTable
SELECT C1.name, C2.name, M.start_time, S.name
FROM Match M
	INNER JOIN Club C1 ON C1.club_ID = M.host_club_ID
		INNER JOIN Club C2 ON C2.club_ID = M.guest_Club_Id 
			INNER JOIN Stadium S ON S.ID = M.stadium_ID 
				INNER JOIN Ticket T ON T.match_ID = M.match_ID
WHERE M.start_time > @dateTime AND T.status  = 1
RETURN
END

-- xxiv
GO;
CREATE PROCEDURE purchaseTicket
@national_id VARCHAR(20), 
@host_club VARCHAR(20), 
@guest_club VARCHAR(20), 
@start_time DATETIME
AS
DECLARE @ticketID INT
SELECT @ticketID = ID FROM Ticket
WHERE match_ID = (SELECT match_ID
				  FROM Match
				  WHERE host_club_id = (SELECT club_ID
				 					    FROM Club
									    WHERE name = @host_club)
									    AND guest_club_id = 
									  	 	(SELECT club_ID 
										 	 FROM Club
									  	  	 WHERE name = @guest_club) 
				 	AND start_time = @start_time ) and status=1;
INSERT INTO TicketBuyingTransactions
VALUES(@national_id, @ticketID);
UPDATE Ticket 
SET status = 0
WHERE ID = @ticketID;
go;



-- xxv
GO;
CREATE PROCEDURE updateMatchHost
@host_name VARCHAR(20), 
@guest_name VARCHAR(20), 
@start_time DATETIME
AS
DECLARE @host_club_ID INT;
SELECT @host_club_ID = C.club_ID
FROM Club C
WHERE @host_name = C.name

DECLARE @guest_club_ID INT;
SELECT @guest_club_ID = C.club_ID
FROM Club C
WHERE @guest_name = C.name

UPDATE Match
SET host_club_ID = @guest_club_ID, 
	guest_club_ID = @host_club_ID,
	stadium_ID = NULL
WHERE host_club_ID = @host_club_ID
	AND guest_club_ID = @guest_club_ID
		AND start_time = @start_time


-- xxvi
GO;
CREATE VIEW matchesPerTeam
AS
SELECT C.name, count(match_ID) AS num
FROM Club C 
	INNER JOIN Match M ON M.host_club_ID = C.club_ID 
		OR M.guest_club_ID = C.club_ID
WHERE M.end_time < CURRENT_TIMESTAMP
GROUP BY C.name

-- xxvii
GO;
CREATE VIEW clubsNeverMatched 
AS
SELECT C1.name AS first_club, C2.name AS second_club
FROM Club C1, Club C2
WHERE C1.name <> C2.name AND C2.club_ID < C1.club_ID
EXCEPT
(SELECT C1.name AS first_club, C2.name AS second_club
FROM Match M INNER JOIN Club C1 ON M.host_club_ID = C1.club_ID
	INNER JOIN Club C2 ON M.guest_club_ID = C2.club_ID
UNION
SELECT C2.name AS first_club, C1.name AS second_club
FROM Match M INNER JOIN Club C1 ON M.host_club_ID = C1.club_ID
	INNER JOIN Club C2 ON M.guest_club_ID = C2.club_ID)


-- xxviii
GO;
CREATE FUNCTION clubsNeverPlayed(@club_name VARCHAR(20))
RETURNS @clubs TABLE(non_competing_clubs VARCHAR(20))
AS
BEGIN

DECLARE @club_ID INT;
SELECT @club_ID = C.club_ID
FROM Club C
WHERE @club_name = C.name

INSERT INTO @clubs
SELECT C.name
FROM Club C
WHERE C.name <> @club_name 
EXCEPT
(SELECT C2.name
FROM Match M INNER JOIN Club C1 ON M.host_club_ID = @club_ID 
    INNER JOIN Club C2 ON M.guest_club_ID = C2.club_ID
UNION
SELECT C2.name
FROM Match M INNER JOIN Club C1 ON M.guest_club_ID = @club_ID 
    INNER JOIN Club C2 ON M.host_club_ID = C2.club_ID)

RETURN
END

-- xxix
GO;
CREATE FUNCTION matchWithHighestAttendance()
RETURNS @returnedTable TABLE(guest_name VARCHAR(20),
host_name VARCHAR(20),
ticketNum int)
AS
BEGIN
INSERT INTO @returnedTable
SELECT C1.name as Club1, C2.name as Club2, count(*) as TicketsSold 
FROM Match M
	INNER JOIN Club C1 ON M.host_club_ID = C1.club_ID
		INNER JOIN Club C2 ON M.guest_Club_ID = C2.club_ID
			INNER JOIN Ticket T ON M.match_ID = T.match_ID 
WHERE T.status=0
GROUP BY C1.name ,C2.name 
HAVING count(*) = (SELECT max(h) 
				   FROM (SELECT count(*) AS h 
FROM Match M inner join Ticket T on (M.match_ID=T.match_ID) 
WHERE T.status=0 
GROUP BY M.match_ID) as Matches)

RETURN
END


-- xxx
GO
CREATE FUNCTION matchesRankedByAttendance()
RETURNS  @rTable TABLE(
host_name VARCHAR(20), 
guest_name VARCHAR(20),
ticketsSold int
)
AS
BEGIN 
INSERT INTO @rTable
SELECT C1.name as Club1, C2.name as Club2, count(T.ID) as TicketsSold
FROM Match M INNER JOIN Ticket T ON M.match_ID = T.match_ID 
	INNER JOIN Club C1 ON M.host_club_ID = C1.club_ID 
		INNER JOIN CLub C2 ON M.guest_club_ID = C2.club_ID
GROUP BY c1.name,c2.name
ORDER BY count(T.ID) DESC OFFSET 0 Rows;
RETURN 
END

-- xxxi
GO;
CREATE FUNCTION requestsFromClub
(@stadium_name VARCHAR(20), @club_name VARCHAR(20))
RETURNS @clubs TABLE(
host_name VARCHAR(20),
guest_name VARCHAR(20))
AS
BEGIN

DECLARE @stadium_ID INT;
SELECT @stadium_ID = S.ID
FROM Stadium S
WHERE S.name = @stadium_name

DECLARE @manager_ID INT;
SELECT @manager_ID = SM.ID
FROM StadiumManager SM
WHERE SM.ID = @stadium_ID

INSERT INTO @clubs
SELECT C1.name, C2.name
FROM HostRequest HR INNER JOIN Match M ON HR.match_ID = M.match_ID
    INNER JOIN Club C1 ON C1.name = @club_name
        INNER JOIN Club C2 ON M.guest_club_ID = C2.club_ID
WHERE HR.manager_ID = @manager_ID  

RETURN
END

--- for milestone 3
GO;
CREATE VIEW allUpcomingMatches
AS
SELECT C1.name AS host_club_name, C2.name AS guest_club_name, M.start_time, M.end_time
FROM Club C1 INNER JOIN Match M ON M.host_club_ID = C1.club_ID
    INNER JOIN Club C2 ON M.guest_club_ID = C2.club_ID
WHERE M.start_time > CURRENT_TIMESTAMP

GO;
CREATE VIEW alreadyPlayedMatches
AS
SELECT C1.name AS host_club_name, C2.name AS guest_club_name, M.start_time, M.end_time
FROM Club C1 INNER JOIN Match M ON M.host_club_ID = C1.club_ID
    INNER JOIN Club C2 ON M.guest_club_ID = C2.club_ID
WHERE M.end_time < CURRENT_TIMESTAMP


go;
CREATE FUNCTION availableMatchesStartingFrom
(@dateTime DATETIME)
RETURNS @returnedTable TABLE(
host_name VARCHAR(20),
guest_name VARCHAR(20),
stadium_name VARCHAR(20),
stadium_location VARCHAR(20))
AS
BEGIN
INSERT INTO @returnedTable
SELECT C1.name, C2.name, S.name, S.location
FROM Match M
    INNER JOIN Club C1 ON C1.club_ID = M.host_club_ID
        INNER JOIN Club C2 ON C2.club_ID = M.guest_Club_Id 
            INNER JOIN Stadium S ON S.ID = M.stadium_ID 
                INNER JOIN Ticket T ON T.match_ID = M.match_ID
WHERE M.start_time > @dateTime AND T.status  = 1 AND C1.club_ID < C2.club_ID
RETURN
END