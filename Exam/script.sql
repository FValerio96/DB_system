-- ============================================================
-- StageUp -- Audiovisual Equipment Booking System
-- Oracle Object-Relational Implementation
-- ============================================================

CREATE OR REPLACE PROCEDURE DropTypes AUTHID CURRENT_USER IS
BEGIN
    BEGIN EXECUTE IMMEDIATE 'DROP TYPE BookingTY        FORCE'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TYPE Event_LocationTY FORCE'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TYPE MemberTY         FORCE'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TYPE TeamTY           FORCE'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TYPE MunicipalityTY   FORCE'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TYPE Municipality_NT  FORCE'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TYPE CustomerTY       FORCE'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TYPE DepotTY          FORCE'; EXCEPTION WHEN OTHERS THEN NULL; END;
END;
/

CREATE OR REPLACE PROCEDURE DropTables AUTHID CURRENT_USER IS
BEGIN
    BEGIN EXECUTE IMMEDIATE 'DROP TABLE Booking         CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TABLE Event_Location  CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TABLE Member          CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TABLE Team            CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TABLE Depot           CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TABLE Customer        CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
END;
/

CREATE OR REPLACE PROCEDURE CreateTypes AUTHID CURRENT_USER IS
BEGIN
    -- Municipality: element type for nested table (weak entity, no REF needed)
    EXECUTE IMMEDIATE 'CREATE OR REPLACE TYPE MunicipalityTY AS OBJECT (
        ID   VARCHAR2(20),
        Name VARCHAR2(100)
    )';
    -- Unbounded nested table type for municipalities
    EXECUTE IMMEDIATE 'CREATE OR REPLACE TYPE Municipality_NT AS TABLE OF MunicipalityTY';

    -- Depot: embeds municipalities as a nested table
    EXECUTE IMMEDIATE 'CREATE OR REPLACE TYPE DepotTY AS OBJECT (
        ID                  VARCHAR2(20),
        Name                VARCHAR2(100),
        Address             VARCHAR2(200),
        City                VARCHAR2(100),
        Province            VARCHAR2(100),
        Number_Of_Employees INTEGER,
        Region              VARCHAR2(100),
        Municipalities      Municipality_NT
    )';

    EXECUTE IMMEDIATE 'CREATE OR REPLACE TYPE CustomerTY AS OBJECT (
        ID      VARCHAR2(20),
        Name    VARCHAR2(100),
        Type    VARCHAR2(50),
        Email   VARCHAR2(100),
        Phone   VARCHAR2(20),
        Address VARCHAR2(200)
    )';

    EXECUTE IMMEDIATE 'CREATE OR REPLACE TYPE TeamTY AS OBJECT (
        Code                VARCHAR2(20),
        Name                VARCHAR2(100),
        Max_Members         INTEGER,
        Installation_Number INTEGER,
        Depot               REF DepotTY
    )';

    EXECUTE IMMEDIATE 'CREATE OR REPLACE TYPE MemberTY AS OBJECT (
        ID      VARCHAR2(20),
        Name    VARCHAR2(100),
        Surname VARCHAR2(100),
        Phone   VARCHAR2(20),
        Email   VARCHAR2(100),
        Team    REF TeamTY
    )';

    EXECUTE IMMEDIATE 'CREATE OR REPLACE TYPE Event_LocationTY AS OBJECT (
        ID                  VARCHAR2(20),
        Street              VARCHAR2(200),
        House_Number        VARCHAR2(20),
        Postal_Code         VARCHAR2(10),
        City                VARCHAR2(100),
        Province            VARCHAR2(100),
        Setup_Time_Estimate INTEGER,
        Equipment_Capacity  INTEGER,
        Booking_Count       INTEGER,
        Customer            REF CustomerTY
    )';

    EXECUTE IMMEDIATE 'CREATE OR REPLACE TYPE BookingTY AS OBJECT (
        ID             VARCHAR2(20),
        Type           VARCHAR2(50),
        Booking_Date   DATE,
        Duration       INTEGER,
        Cost           NUMBER,
        Booking_Method VARCHAR2(50),
        Contract_Type  VARCHAR2(50),
        Team           REF TeamTY,
        Customer       REF CustomerTY,
        Location       REF Event_LocationTY
    )';
END;
/

CREATE OR REPLACE PROCEDURE CreateTables AUTHID CURRENT_USER IS
BEGIN
    -- Depot: municipalities embedded as nested table (weak entity)
    EXECUTE IMMEDIATE 'CREATE TABLE Depot OF DepotTY (
        ID   PRIMARY KEY,
        Name NOT NULL,
        City NOT NULL,
        Address NOT NULL,
        Number_Of_Employees NOT NULL,
        CONSTRAINT chk_depot_employees CHECK (Number_Of_Employees >= 0)
    ) NESTED TABLE Municipalities STORE AS Municipality_Store';

    -- Team: each team belongs to exactly one Depot (1:N BELONGS_TO)
    EXECUTE IMMEDIATE 'CREATE TABLE Team OF TeamTY (
        Code PRIMARY KEY,
        Name NOT NULL,
        Max_Members NOT NULL,
        CONSTRAINT chk_max_members CHECK (Max_Members > 0),
        Installation_Number NOT NULL,
        CONSTRAINT chk_installation_number CHECK (Installation_Number >= 0),
        Depot NOT NULL REFERENCES Depot
    )';

    EXECUTE IMMEDIATE 'CREATE TABLE Member OF MemberTY (
        ID      PRIMARY KEY,
        Name    NOT NULL,
        Surname NOT NULL,
        Team    REFERENCES Team ON DELETE SET NULL
    )';

    EXECUTE IMMEDIATE 'CREATE TABLE Customer OF CustomerTY (
        ID   PRIMARY KEY,
        Name NOT NULL,
        CONSTRAINT chk_customer_type CHECK (Type IN (''Individual'', ''Company'')),
        Type  NOT NULL,
        Email NOT NULL
    )';

    EXECUTE IMMEDIATE 'CREATE TABLE Event_Location OF Event_LocationTY (
        ID     PRIMARY KEY,
        Street NOT NULL,
        City   NOT NULL,
        Setup_Time_Estimate NOT NULL,
        CONSTRAINT chk_setup_time CHECK (Setup_Time_Estimate > 0),
        Equipment_Capacity NOT NULL,
        CONSTRAINT chk_equip_capacity CHECK (Equipment_Capacity >= 0),
        Booking_Count NOT NULL,
        CONSTRAINT chk_booking_count CHECK (Booking_Count >= 0),
        Customer REFERENCES Customer ON DELETE SET NULL
    )';

    EXECUTE IMMEDIATE 'CREATE TABLE Booking OF BookingTY (
        ID PRIMARY KEY,
        CONSTRAINT chk_booking_type   CHECK (Type IN (''recurring'', ''one-time'')),
        CONSTRAINT chk_booking_method CHECK (Booking_Method IN
            (''phone'', ''email'', ''website'', ''postal_mail'')),
        CONSTRAINT chk_contract_type  CHECK (Contract_Type IN
            (''one-time'', ''seasonal'', ''promotional'')),
        CONSTRAINT chk_duration CHECK (Duration > 0),
        CONSTRAINT chk_cost     CHECK (Cost >= 0),
        Type           NOT NULL,
        Booking_Date   NOT NULL,
        Duration       NOT NULL,
        Cost           NOT NULL,
        Booking_Method NOT NULL,
        Contract_Type  NOT NULL,
        Team     NOT NULL REFERENCES Team,
        Customer NOT NULL REFERENCES Customer,
        Location NOT NULL REFERENCES Event_Location
    )';
END;
/

CREATE OR REPLACE PROCEDURE SchemaCreation AUTHID CURRENT_USER IS
BEGIN
    DropTables;
    DropTypes;
    CreateTypes;
    CreateTables;
END;
/


--------------------------------------------------------------------
-- Population Procedure
--------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE PopulateDatabase(
    p_num_customers IN NUMBER,
    p_num_bookings  IN NUMBER
) IS
BEGIN
    -- Insert 10 Depots with empty nested table (municipalities added below)
    FOR i IN 1..10 LOOP
        INSERT INTO Depot VALUES (
            DepotTY(
                'Depot' || TO_CHAR(i),
                'DepotName' || TO_CHAR(i),
                'Via Deposito ' || TO_CHAR(i),
                'City' || TO_CHAR(i),
                'Province' || TO_CHAR(i),
                ROUND(DBMS_RANDOM.VALUE(10, 80)),
                'Region' || TO_CHAR(CEIL(i / 2)),
                Municipality_NT()   -- initialised empty
            )
        );
    END LOOP;

    -- Insert 10 Municipalities per Depot into the nested table (100 total)
    FOR depot_id IN 1..10 LOOP
        FOR i IN 1..10 LOOP
            INSERT INTO TABLE(
                SELECT d.Municipalities FROM Depot d
                 WHERE d.ID = 'Depot' || TO_CHAR(depot_id)
            ) VALUES (MunicipalityTY(
                'Mun' || TO_CHAR((depot_id - 1) * 10 + i),
                'Municipality' || TO_CHAR((depot_id - 1) * 10 + i)
            ));
        END LOOP;
    END LOOP;

    -- Insert 100 Teams (10 per Depot, 1:N BELONGS_TO)
    FOR i IN 1..100 LOOP
        INSERT INTO Team VALUES (TeamTY(
            'Team'     || TO_CHAR(i),
            'TeamName' || TO_CHAR(i),
            10,
            0,
            (SELECT REF(d) FROM Depot d WHERE d.ID = 'Depot' || TO_CHAR(CEIL(i / 10)))
        ));
    END LOOP;

    -- Insert 7 Members per Team (700 total)
    FOR team_num IN 1..100 LOOP
        FOR i IN 1..7 LOOP
            DECLARE v_mid VARCHAR2(20) := 'MB' || TO_CHAR((team_num - 1) * 7 + i); BEGIN
                INSERT INTO Member VALUES (
                    MemberTY(
                        v_mid,
                        'Name' || v_mid,
                        'Surname' || v_mid,
                        '33' || TO_CHAR(ROUND(DBMS_RANDOM.VALUE(1000000, 9999999))),
                        'member' || v_mid || '@stageup.com',
                        (SELECT REF(t) FROM Team t
                          WHERE t.Code = 'Team' || TO_CHAR(team_num))
                    )
                );
            END;
        END LOOP;
    END LOOP;

    -- Insert Customers
    FOR i IN 1..p_num_customers LOOP
        INSERT INTO Customer VALUES (
            CustomerTY(
                'Cust' || TO_CHAR(i),
                'CustomerName' || TO_CHAR(i),
                CASE WHEN MOD(i, 2) = 0 THEN 'Individual' ELSE 'Company' END,
                'cust' || TO_CHAR(i) || '@example.com',
                '33' || TO_CHAR(ROUND(DBMS_RANDOM.VALUE(1000000, 9999999))),
                'Via Roma ' || TO_CHAR(i)
            )
        );
    END LOOP;

    -- Insert Event Locations (10 per customer = 1000 total for 100 customers)
    FOR i IN 1..p_num_customers LOOP
        FOR j IN 1..10 LOOP
            INSERT INTO Event_Location VALUES (
                Event_LocationTY(
                    'Loc' || TO_CHAR((i - 1) * 10 + j),
                    'Via Evento ' || TO_CHAR((i - 1) * 10 + j),
                    TO_CHAR(j),
                    TO_CHAR(70000 + MOD((i - 1) * 10 + j, 100)),
                    'City' || TO_CHAR(MOD(i, 10) + 1),
                    'Province' || TO_CHAR(MOD(i, 5) + 1),
                    ROUND(DBMS_RANDOM.VALUE(30, 180)),
                    ROUND(DBMS_RANDOM.VALUE(50, 500)),
                    0,   -- Booking_Count starts at 0
                    (SELECT REF(c) FROM Customer c WHERE c.ID = 'Cust' || TO_CHAR(i))
                )
            );
        END LOOP;
    END LOOP;

    -- Insert Bookings
    FOR i IN 1..p_num_bookings LOOP
        DECLARE
            v_max_loc    NUMBER := p_num_customers * 10;
            v_loc_id     VARCHAR2(20) := 'Loc'  || TO_CHAR(ROUND(DBMS_RANDOM.VALUE(1, v_max_loc)));
            v_cust_id    VARCHAR2(20) := 'Cust' || TO_CHAR(ROUND(DBMS_RANDOM.VALUE(1, p_num_customers)));
            v_team_code  VARCHAR2(20) := 'Team' || TO_CHAR(ROUND(DBMS_RANDOM.VALUE(1, 100)));
        BEGIN
            INSERT INTO Booking VALUES (
                BookingTY(
                    'Book' || TO_CHAR(i),
                    CASE WHEN MOD(i, 2) = 0 THEN 'recurring' ELSE 'one-time' END,
                    SYSDATE + ROUND(DBMS_RANDOM.VALUE(-90, 90)),
                    ROUND(DBMS_RANDOM.VALUE(1, 8)),
                    ROUND(DBMS_RANDOM.VALUE(200, 5000)),
                    CASE MOD(i, 4)
                        WHEN 0 THEN 'phone'
                        WHEN 1 THEN 'email'
                        WHEN 2 THEN 'website'
                        WHEN 3 THEN 'postal_mail'
                    END,
                    CASE MOD(i, 3)
                        WHEN 0 THEN 'one-time'
                        WHEN 1 THEN 'seasonal'
                        WHEN 2 THEN 'promotional'
                    END,
                    (SELECT REF(t) FROM Team           t WHERE t.Code = v_team_code),
                    (SELECT REF(c) FROM Customer       c WHERE c.ID   = v_cust_id),
                    (SELECT REF(l) FROM Event_Location l WHERE l.ID   = v_loc_id)
                )
            );
        END;
    END LOOP;
END;
/


--------------------------------------------------------------------
-- Procedure 1: Register a new customer (Operation 1)
--------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE proc_register_customer (
    p_id      IN VARCHAR2,
    p_name    IN VARCHAR2,
    p_type    IN VARCHAR2,   -- 'Individual' or 'Company'
    p_email   IN VARCHAR2,
    p_phone   IN VARCHAR2,
    p_address IN VARCHAR2
) AS
BEGIN
    INSERT INTO Customer
    VALUES (CustomerTY(p_id, p_name, p_type, p_email, p_phone, p_address));
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20001, 'Error in proc_register_customer: ' || SQLERRM);
END;
/


--------------------------------------------------------------------
-- Procedure 2: Record a new booking (Operation 2)
--------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE proc_add_booking (
    p_id            IN VARCHAR2,
    p_type          IN VARCHAR2,   -- 'recurring' or 'one-time'
    p_date          IN DATE,
    p_duration      IN INTEGER,
    p_cost          IN NUMBER,
    p_method        IN VARCHAR2,   -- 'phone','email','website','postal_mail'
    p_contract_type IN VARCHAR2,   -- 'one-time','seasonal','promotional'
    p_team_code     IN VARCHAR2,
    p_customer_id   IN VARCHAR2,
    p_location_id   IN VARCHAR2
) AS
    v_ct NUMBER; v_cc NUMBER; v_cl NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_ct FROM Team          WHERE Code = p_team_code;
    SELECT COUNT(*) INTO v_cc FROM Customer       WHERE ID   = p_customer_id;
    SELECT COUNT(*) INTO v_cl FROM Event_Location WHERE ID   = p_location_id;

    IF v_ct = 0 THEN RAISE_APPLICATION_ERROR(-20010, 'Error: Team not found!');       END IF;
    IF v_cc = 0 THEN RAISE_APPLICATION_ERROR(-20011, 'Error: Customer not found!');   END IF;
    IF v_cl = 0 THEN RAISE_APPLICATION_ERROR(-20012, 'Error: Location not found!');   END IF;

    INSERT INTO Booking VALUES (BookingTY(
        p_id, p_type, p_date, p_duration, p_cost, p_method, p_contract_type,
        (SELECT REF(t) FROM Team           t WHERE t.Code = p_team_code),
        (SELECT REF(c) FROM Customer       c WHERE c.ID   = p_customer_id),
        (SELECT REF(l) FROM Event_Location l WHERE l.ID   = p_location_id)
    ));
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20013, 'Error in proc_add_booking: ' || SQLERRM);
END;
/


--------------------------------------------------------------------
-- Procedure 3: Register a new event location (Operation 3)
--------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE proc_register_location (
    p_id          IN VARCHAR2,
    p_street      IN VARCHAR2,
    p_house_num   IN VARCHAR2,
    p_postal_code IN VARCHAR2,
    p_city        IN VARCHAR2,
    p_province    IN VARCHAR2,
    p_setup_time  IN INTEGER,
    p_equip_cap   IN INTEGER,
    p_customer_id IN VARCHAR2
) AS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM Customer WHERE ID = p_customer_id;
    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20020, 'Error: Customer not found!');
    END IF;

    INSERT INTO Event_Location VALUES (Event_LocationTY(
        p_id, p_street, p_house_num, p_postal_code, p_city, p_province,
        p_setup_time, p_equip_cap,
        0,   -- Booking_Count initialised to 0
        (SELECT REF(c) FROM Customer c WHERE c.ID = p_customer_id)
    ));
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20021, 'Error in proc_register_location: ' || SQLERRM);
END;
/


--------------------------------------------------------------------
-- Procedure 4: View teams that handled a specific event location (Op 4)
--------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE proc_get_teams_at_location (
    p_location_id IN  VARCHAR2,
    p_cursor      OUT SYS_REFCURSOR
) AS
BEGIN
    OPEN p_cursor FOR
        SELECT DISTINCT
               DEREF(b.Team).Code AS team_code,
               DEREF(b.Team).Name AS team_name
          FROM Booking b
         WHERE b.Location = (SELECT REF(l) FROM Event_Location l
                               WHERE l.ID = p_location_id);
END;
/


--------------------------------------------------------------------
-- Procedure 5: Event locations ranked by booking count desc (Op 5)
--------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE proc_get_locations_ranked (
    p_cursor OUT SYS_REFCURSOR
) AS
BEGIN
    OPEN p_cursor FOR
        SELECT l.ID, l.City, l.Street, l.Booking_Count
          FROM Event_Location l
         ORDER BY l.Booking_Count DESC;
END;
/


--------------------------------------------------------------------
-- Trigger 1: Enforce team member capacity (BR: members <= Max_Members)
--------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_member_capacity
BEFORE INSERT ON Member
FOR EACH ROW
DECLARE
    v_current_count NUMBER;
    v_max_members   NUMBER;
    v_team_code     VARCHAR2(20);
BEGIN
    SELECT t.Code, t.Max_Members INTO v_team_code, v_max_members
      FROM Team t WHERE REF(t) = :NEW.Team;

    SELECT COUNT(*) INTO v_current_count
      FROM Member m WHERE m.Team = :NEW.Team;

    IF v_current_count >= v_max_members THEN
        RAISE_APPLICATION_ERROR(-20040,
            'Error: Team ' || v_team_code ||
            ' has reached its maximum capacity of ' || v_max_members || ' members.');
    END IF;
END;
/


--------------------------------------------------------------------
-- Trigger 2: Increment Installation_Number in Team after booking insert
--------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_update_installation_count
AFTER INSERT ON Booking
FOR EACH ROW
BEGIN
    UPDATE Team t
       SET t.Installation_Number = t.Installation_Number + 1
     WHERE REF(t) = :NEW.Team;
END;
/


--------------------------------------------------------------------
-- Trigger 3: Increment Booking_Count on Event_Location after booking insert
--            (maintains Op5 redundancy)
--------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_update_booking_count
AFTER INSERT ON Booking
FOR EACH ROW
BEGIN
    UPDATE Event_Location l
       SET l.Booking_Count = l.Booking_Count + 1
     WHERE REF(l) = :NEW.Location;
END;
/


SET SERVEROUTPUT OFF
/
BEGIN
    SchemaCreation;
END;
/

-- Index on Booking.Location REF -- speeds up Op4 (teams at a given location)
CREATE INDEX idx_booking_location ON Booking(Location);

BEGIN
    PopulateDatabase(
        p_num_customers => 100,
        p_num_bookings  => 1000
    );
END;
/

SET SERVEROUTPUT ON
/

-- Web application seed data
INSERT INTO Depot VALUES (
    DepotTY('DepotWeb', 'StageUp Web Depot', 'Via Web 1', 'Bari', 'BA', 20, 'Puglia', Municipality_NT())
);

INSERT INTO Team VALUES (TeamTY('TeamWeb', 'Web Setup Crew', 10, 0,
    (SELECT REF(d) FROM Depot d WHERE d.ID = 'DepotWeb')));

INSERT INTO Customer VALUES (
    CustomerTY('CustWeb', 'Web Customer', 'Company', 'web@stageup.com', '3331234567', 'Via Web 1, Bari')
);

INSERT INTO Event_Location VALUES (
    Event_LocationTY(
        'LocWeb', 'Via Palcoscenico 1', '10', '70121', 'Bari', 'BA',
        90, 200, 0,
        (SELECT REF(c) FROM Customer c WHERE c.ID = 'CustWeb')
    )
);


-- ============================================================
-- TEST SUITE
-- ============================================================

-- Test Trigger 1: Exceed team member capacity (TeamSmall max=2)
INSERT INTO Team VALUES (TeamTY('TeamSmall', 'Small Team', 2, 0,
    (SELECT REF(d) FROM Depot d WHERE d.ID = 'Depot1')));

INSERT INTO Member VALUES (MemberTY('MB_S1','Alice','Rossi','3331111111','alice@test.com',
    (SELECT REF(t) FROM Team t WHERE t.Code = 'TeamSmall')));
INSERT INTO Member VALUES (MemberTY('MB_S2','Bob','Bianchi','3332222222','bob@test.com',
    (SELECT REF(t) FROM Team t WHERE t.Code = 'TeamSmall')));
-- Should FAIL (capacity = 2, already 2 members):
INSERT INTO Member VALUES (MemberTY('MB_S3','Charlie','Verdi','3333333333','charlie@test.com',
    (SELECT REF(t) FROM Team t WHERE t.Code = 'TeamSmall')));

-- Test Trigger 2 & 3: Verify counters after booking insert
SELECT Code, Installation_Number FROM Team          WHERE Code = 'TeamWeb';
SELECT ID,   Booking_Count        FROM Event_Location WHERE ID   = 'LocWeb';

INSERT INTO Booking VALUES (BookingTY(
    'BookTest1', 'one-time', SYSDATE, 4, 1500, 'email', 'one-time',
    (SELECT REF(t) FROM Team           t WHERE t.Code = 'TeamWeb'),
    (SELECT REF(c) FROM Customer       c WHERE c.ID   = 'CustWeb'),
    (SELECT REF(l) FROM Event_Location l WHERE l.ID   = 'LocWeb')
));

-- Both should now show 1:
SELECT Code, Installation_Number FROM Team          WHERE Code = 'TeamWeb';
SELECT ID,   Booking_Count        FROM Event_Location WHERE ID   = 'LocWeb';
