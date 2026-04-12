# SageFit Database Schema - Sports Equipment Booking System
**AY 2024/2025 - Database Systems Exam Project**

---

## 1. Conceptual Schema (ER Model)

### 1.1 Entities

#### 1. **Customer**
- **ID** (PK) - Alphanumeric identification code
- Name
- Type
- Email
- Phone
- Address
- Bookings (REF Booking) [1..*] - FK reference
- Places (REF Event_Location) [1..*] - FK reference

#### 2. **Event_Location**
- **ID** (PK)
- Address
- House_Number
- Postal_Code
- City
- Province
- Setup_Time_Estimate
- Equipment_Capacity
- Customer_ID (FK → Customer) - REF Customer
- Bookings (REF Booking) [1..*] - FK reference

#### 3. **Booking**
- **ID** (PK)
- Type (recurring/one-time)
- Date
- Duration
- Cost
- Booking_Method (phone/email/website/postal_mail)
- Contract_Type (one-time/seasonal/promotional)
- Team_ID (FK → Team) - REF Team
- Reservation_ID (FK → Customer) - REF Customer
- Location_ID (FK → Event_Location) - REF Event_Location

#### 4. **Team**
- **ID** (PK) - Identification code
- Name
- Max_Members
- Installation_Number (number of installations made)
- Handling_S_Bookings [1..*]
- Belong_To_Depots (REF Depot) - N:M relationship

#### 5. **Member**
- **ID** (PK)
- Name
- Surname
- Phone
- Email
- Team_ID (FK → Team)

#### 6. **Depot**
- **ID** (PK)
- Name
- City
- Province
- Address
- Region
- Number_Of_Employees
- Teams (REF Team) [1..*] - N:M relationship

#### 7. **Municipality**
- **ID** (PK)
- Name
- Depot_ID (FK → Depot) - REF Depot

---

### 1.2 Relationships

1. **PLACE**
   - Customer (1,N) ← PLACE → (1,1) Event_Location
   - *A customer can have multiple event locations, each location belongs to one customer*

2. **BL** (Booking-Location)
   - Event_Location (1,N) ← BL → (1,1) Booking
   - *Each booking is associated with one event location, a location can have multiple bookings*

3. **RESERVATION**
   - Customer (1,N) ← RESERVATION → (1,1) Booking
   - *A customer can make multiple bookings, each booking is made by one customer*

4. **HANDLED**
   - Booking (1,1) ← HANDLED → (1,N) Team
   - *Each booking is handled by exactly one team, a team can handle multiple bookings*

5. **HAS**
   - Team (1,N) ← HAS → (1,1) Member
   - *A team has multiple members, each member belongs to one team*

6. **BELONG**
   - Team (1,N) ← BELONG → (1,N) Depot
   - *Teams can belong to multiple depots, depots can have multiple teams (N:M)*

7. **COVER**
   - Depot (1,N) ← COVER → (1,1) Municipality
   - *Each depot covers multiple municipalities (a region), each municipality belongs to one depot*

---

## 2. Logical Schema (Relational Model)

### 2.1 Relations

```sql
Customer(ID, Name, Type, Email, Phone, Address)
  PK: ID
  
Event_Location(ID, Address, House_Number, Postal_Code, City, Province, Setup_Time_Estimate, Equipment_Capacity, Customer_ID)
  PK: ID
  FK: Customer_ID → Customer(ID)
  
Booking(ID, Type, Date, Duration, Cost, Booking_Method, Contract_Type, Team_ID, Reservation_ID, Location_ID)
  PK: ID
  FK: Team_ID → Team(ID)
  FK: Reservation_ID → Customer(ID)
  FK: Location_ID → Event_Location(ID)
  
Team(ID, Name, Max_Members, Installation_Number)
  PK: ID
  
Member(ID, Name, Surname, Phone, Email, Team_ID)
  PK: ID
  FK: Team_ID → Team(ID)
  
Depot(ID, Name, City, Province, Address, Region, Number_Of_Employees)
  PK: ID
  
Municipality(ID, Name, Depot_ID)
  PK: ID
  FK: Depot_ID → Depot(ID)

-- N:M Relationship between Team and Depot
Team_Depot(Team_ID, Depot_ID)
  PK: (Team_ID, Depot_ID)
  FK: Team_ID → Team(ID)
  FK: Depot_ID → Depot(ID)
```

### 2.2 Translation Rules Applied

1. **Customer → Event_Location (1:N PLACE)**
   - FK Customer_ID added to Event_Location

2. **Event_Location → Booking (1:N BL)**
   - FK Event_Location_ID added to Booking

3. **Customer → Booking (1:N RESERVATION)**
   - FK Customer_ID added to Booking

4. **Team → Booking (1:N HANDLED)**
   - FK Team_ID added to Booking

5. **Team → Member (1:N HAS)**
   - FK Team_ID added to Member

6. **Team ↔ Depot (N:M BELONG)**
   - New table Team_Depot created with both FKs

7. **Depot → Municipality (1:N COVER)**
   - FK Depot_ID added to Municipality

---

## 3. Constraints

### 3.1 Domain Constraints
- Customer.Type ∈ {'Individual', 'Company'}
- Booking.Type ∈ {'recurring', 'one-time'}
- Booking.Booking_Method ∈ {'phone', 'email', 'website', 'postal_mail'}
- Booking.Contract_Type ∈ {'one-time', 'seasonal', 'promotional'}
- Booking.Duration > 0
- Booking.Cost >= 0
- Team.Max_Members > 0
- Team.Installation_Number >= 0
- Depot.Number_Of_Employees >= 0
- Event_Location.Setup_Time_Estimate > 0
- Event_Location.Equipment_Capacity > 0

### 3.2 Key Constraints
- All PKs are NOT NULL and UNIQUE
- All FKs reference existing PKs

### 3.3 Referential Integrity
- ON DELETE CASCADE for:
  - Customer → Event_Location
  - Team → Member
  - Depot → Municipality (if depot is deleted, municipalities should be reassigned)
  
- ON DELETE RESTRICT for:
  - Customer → Booking (cannot delete customer with active bookings)
  - Team → Booking (cannot delete team with assigned bookings)
  - Municipality → Depot (cannot delete depot if municipalities are assigned)

### 3.4 Business Rules
1. Each booking must be handled by exactly one team
2. Each team can handle multiple bookings simultaneously
3. A team can belong to multiple depots (operational flexibility)
4. Each member belongs to exactly one team
5. Number of members in a team should not exceed Max_Members (application-level check)
6. Central office coordinates bookings but does not handle physical setups (business logic, not modeled)
7. Event locations can have multiple bookings over time
8. Each event location has setup time estimate and equipment capacity constraints
9. Each Depot covers a geographic region (stored as Region attribute), and each depot covers multiple municipalities (1:N relationship)

---

## 4. Workload Analysis

### 4.1 Access Patterns (from requirements)

| ID | Type | Frequency | Description |
|----|------|-----------|-------------|
| 1 | I | 10 x Day | Insert new bookings |
| 2 | I | 30 x Day | Insert new customers |
| 3 | I | 5 x Day | Insert new teams |
| 4 | I | 2 x Day | Insert new members |
| 5 | Q | **5 x Day** | **Query to keep track of members of ID in team lambda** ⭐ |

### 4.2 Critical Queries

#### Query 5 (Most Frequent - 5x/day)
**Requirement**: Keep track of members of a specific team

```sql
-- Given team_id = lambda
SELECT m.ID, m.Name, m.Surname
FROM Member m
WHERE m.Team_ID = :team_id;
```

**Access Volume**: 
- Volume: 100 (assuming ~20 members per team × 5 teams accessed)
- Type: Read-only
- Priority: HIGH (most frequent query)

### 4.3 Optimization Recommendations

Based on workload:

1. **Index on Member.Team_ID** (for Query 5)
   ```sql
   CREATE INDEX idx_member_team ON Member(Team_ID);
   ```

2. **Index on Booking foreign keys** (for frequent inserts and joins)
   ```sql
   CREATE INDEX idx_booking_reservation ON Booking(Reservation_ID);
   CREATE INDEX idx_booking_team ON Booking(Team_ID);
   CREATE INDEX idx_booking_location ON Booking(Location_ID);
   ```

3. **Composite index for booking searches**
   ```sql
   CREATE INDEX idx_booking_date_team ON Booking(Date, Team_ID);
   ```

---

## 5. Implementation Notes

### 5.1 Suggested Data Types (PostgreSQL)

```sql
-- Customer
ID: SERIAL PRIMARY KEY -- Alphanumeric identification code
Name: VARCHAR(100) NOT NULL
Type: VARCHAR(50) NOT NULL -- 'Individual' or 'Company'
Email: VARCHAR(100)
Phone: VARCHAR(20)
Address: VARCHAR(200)

-- Event_Location
ID: SERIAL PRIMARY KEY
Address: VARCHAR(200) NOT NULL -- Street name
House_Number: VARCHAR(20) -- House/building number
Postal_Code: VARCHAR(10)
City: VARCHAR(100) NOT NULL
Province: VARCHAR(100)
Setup_Time_Estimate: INTEGER -- in minutes or hours
Equipment_Capacity: INTEGER -- max equipment units
Customer_ID: INTEGER NOT NULL

-- Booking
ID: SERIAL PRIMARY KEY
Type: VARCHAR(50) NOT NULL -- 'recurring' or 'one-time'
Date: DATE NOT NULL
Duration: INTEGER NOT NULL -- in hours or minutes
Cost: DECIMAL(10,2) NOT NULL
Booking_Method: VARCHAR(50) -- 'phone', 'email', 'website', 'postal_mail'
Contract_Type: VARCHAR(50) -- 'one-time', 'seasonal', 'promotional'
Team_ID: INTEGER NOT NULL
Reservation_ID: INTEGER NOT NULL -- FK to Customer
Location_ID: INTEGER NOT NULL -- FK to Event_Location

-- Team
ID: SERIAL PRIMARY KEY -- Also serves as identification code
Name: VARCHAR(100) NOT NULL UNIQUE
Max_Members: INTEGER NOT NULL CHECK (Max_Members > 0)
Installation_Number: INTEGER DEFAULT 0 -- Number of installations made

-- Member
ID: SERIAL PRIMARY KEY
Name: VARCHAR(100) NOT NULL
Surname: VARCHAR(100) NOT NULL
Phone: VARCHAR(20)
Email: VARCHAR(100)
Team_ID: INTEGER NOT NULL

-- Depot
ID: SERIAL PRIMARY KEY
Name: VARCHAR(100) NOT NULL
City: VARCHAR(100) NOT NULL
Province: VARCHAR(100)
Address: VARCHAR(200) NOT NULL
Region: VARCHAR(100) -- Geographic region covered by this depot
Number_Of_Employees: INTEGER NOT NULL CHECK (Number_Of_Employees >= 0)

-- Municipality
ID: SERIAL PRIMARY KEY
Name: VARCHAR(100) NOT NULL UNIQUE
Depot_ID: INTEGER NOT NULL -- FK to Depot (each municipality belongs to one depot)

-- Team_Depot (N:M relationship)
Team_ID: INTEGER NOT NULL
Depot_ID: INTEGER NOT NULL
PRIMARY KEY (Team_ID, Depot_ID)
```

### 5.2 Sample Data Considerations
- Start with ~50 customers
- ~20 teams
- ~100 members (avg 5 per team)
- ~10 depots
- ~30 municipalities
- ~200 bookings

---

## 6. ER Diagram Summary

```
Customer (1,N)──PLACE──(1,1) Event_Location
    |                           |
    | (1,N)                     | (1,N)
    |                           |
    └──RESERVATION──(1,1)       └──BL──(1,1)
                    ↓                    ↓
                  Booking ──HANDLED──(1,N) Team
                                           ↓
                                    (1,N)  │  (1,N)
                                           │
                                      HAS  │  BELONG
                                           │
                                    (1,1)  │  (1,N)
                                           ↓      ↓
                                      Member   Depot
                                                  │
                                                  │ (1,N)
                                                  │
                                          (1,N) COVER
                                                  │
                                                  ↓
                                            (1,1) Municipality
```

---

## 7. Next Steps for Implementation

1. ✅ **Phase 1**: Create DDL (Data Definition Language)
   - CREATE TABLE statements
   - PRIMARY KEY constraints
   - FOREIGN KEY constraints
   - CHECK constraints
   - Indexes

2. ✅ **Phase 2**: Populate with sample data
   - INSERT statements for all tables
   - Ensure referential integrity

3. ✅ **Phase 3**: Implement critical queries
   - Query 5 (member tracking)
   - Additional reporting queries

4. ✅ **Phase 4**: Performance optimization
   - Analyze query plans
   - Add/adjust indexes as needed
   - Monitor access patterns

---

## 8. Ambiguity Resolutions

Based on the requirements, the following ambiguities were resolved:

1. **Customer Type**: Can be Individual or Company (alphanumeric identification code)
2. **Customer Personal Details**: Include Email, Phone, and Address for contact information
3. **Booking-Team relationship**: Each booking is handled by ONE team (not multiple)
4. **Team-Depot relationship**: N:M (teams can operate from multiple depots)
5. **Event Location ownership**: Belongs to customer (customer's event venues/locations)
6. **Event Location Address**: Split into Address (street name) and House_Number (building number) as per requirements
7. **Member uniqueness**: Each member belongs to exactly one team at a time
8. **Member Personal Data**: Include Phone and Email for team member contact information
9. **Central Office**: Not modeled as separate entity - it coordinates bookings but doesn't perform physical setups (business logic only)
10. **Booking Types**: Can be recurring or one-time
11. **Booking Methods**: Phone, email, website, or postal mail
12. **Contract Types**: One-time, seasonal, or promotional rentals
13. **Setup constraints**: Each event location has setup time estimate and equipment capacity
14. **Region vs Entity**: Region is an attribute of Depot (geographic area covered), NOT a separate entity. Each depot covers a region that consists of one or more municipalities (Municipality → Depot is 1:N)

---

**Document Version**: 1.0  
**Last Updated**: April 9, 2026  
**Author**: Based on ER diagram and requirements analysis
