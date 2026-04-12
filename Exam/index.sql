-- ============================================================
-- StageUp -- Index & Performance Analysis
-- ============================================================

SET AUTOTRACE ON

-- Operation 1: Register a new customer (10 x day)
INSERT INTO Customer
VALUES (CustomerTY(
    'CustTrace','Trace Customer','Company',
    'trace@stageup.com','3339876543','Via Trace 1'
));

-- Operation 2: Record a new booking (300 x day)
INSERT INTO Booking
VALUES (BookingTY(
    'BookTrace','one-time',SYSDATE,3,800,'email','seasonal',
    (SELECT REF(t) FROM Team           t WHERE t.Code = 'Team1'),
    (SELECT REF(c) FROM Customer       c WHERE c.ID   = 'Cust1'),
    (SELECT REF(l) FROM Event_Location l WHERE l.ID   = 'Loc1')
));

-- Operation 3: Register a new event location (50 x day)
INSERT INTO Event_Location
VALUES (Event_LocationTY(
    'LocTrace','Via Trace 1','1','70000','TraceCity','TC',
    60,100,0,
    (SELECT REF(c) FROM Customer c WHERE c.ID = 'Cust1')
));

-- Operation 4: View teams at a specific event location (20 x day)
SELECT DISTINCT DEREF(b.Team).Code AS team_code,
                DEREF(b.Team).Name AS team_name
  FROM Booking b
 WHERE b.Location = (SELECT REF(l) FROM Event_Location l WHERE l.ID = 'Loc1');

-- Operation 5: Event locations ranked by booking count desc (5 x day)
SELECT l.ID, l.City, l.Street, l.Booking_Count
  FROM Event_Location l
 ORDER BY l.Booking_Count DESC;


-- ============================================================
-- EXPLAIN PLAN Section
-- ============================================================

-- Operation 1
EXPLAIN PLAN FOR
INSERT INTO Customer
VALUES (CustomerTY(
    'CustTrace2','Trace2','Individual',
    'trace2@stageup.com','3339876544','Via Trace 2'
));
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Operation 2
EXPLAIN PLAN FOR
INSERT INTO Booking
VALUES (BookingTY(
    'BookTrace2','recurring',SYSDATE,5,1200,'phone','promotional',
    (SELECT REF(t) FROM Team           t WHERE t.Code = 'Team2'),
    (SELECT REF(c) FROM Customer       c WHERE c.ID   = 'Cust2'),
    (SELECT REF(l) FROM Event_Location l WHERE l.ID   = 'Loc2')
));
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Operation 3
EXPLAIN PLAN FOR
INSERT INTO Event_Location
VALUES (Event_LocationTY(
    'LocTrace2','Via Trace 2','2','70001','TraceCity','TC',
    45,80,0,
    (SELECT REF(c) FROM Customer c WHERE c.ID = 'Cust1')
));
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Operation 4 -- WITHOUT index (drop to compare)
DROP INDEX idx_booking_location;

EXPLAIN PLAN FOR
SELECT DISTINCT DEREF(b.Team).Code AS team_code,
                DEREF(b.Team).Name AS team_name
  FROM Booking b
 WHERE b.Location = (SELECT REF(l) FROM Event_Location l WHERE l.ID = 'Loc1');
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Recreate index and rerun
CREATE INDEX idx_booking_location ON Booking(Location);

-- Operation 4 -- WITH index
EXPLAIN PLAN FOR
SELECT DISTINCT DEREF(b.Team).Code AS team_code,
                DEREF(b.Team).Name AS team_name
  FROM Booking b
 WHERE b.Location = (SELECT REF(l) FROM Event_Location l WHERE l.ID = 'Loc1');
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Operation 5 -- Booking_Count already stored (redundancy): single scan
EXPLAIN PLAN FOR
SELECT l.ID, l.City, l.Street, l.Booking_Count
  FROM Event_Location l
 ORDER BY l.Booking_Count DESC;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
