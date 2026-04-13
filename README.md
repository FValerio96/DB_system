# 📽️ Audiovisual Equipment Rental Management - Database Design

[![Status](https://img.shields.io/badge/Status-Completed-success.svg)]()
[![Academic](https://img.shields.io/badge/Type-Academic_Project-blue.svg)]()

## 📖 Project Overview
This repository contains the complete conceptual and logical database design for an international audiovisual equipment rental and installation company. The project translates complex business requirements into a highly optimized Object-Relational database schema.

The case study involves a multinational company with a Central Office and multiple operational Depots globally. The system manages Customers, Event Locations, Setup Teams, and hundreds of daily Bookings for equipment installations.

## 🎯 Objectives & Deliverables

The project is divided into two main engineering phases:

### Phase 1: Conceptual Design (Exercise 1)
- **Requirements Analysis:** Filtering ambiguities and homogenizing business specifications.
- **Glossary & Data Dictionary:** Detailed definition of entities, relationships, and business rules.
- **Conceptual Modeling:** Creation of the Entity-Relationship (ER) diagram (Skeleton and Final Schema).
- **Design Strategy:** Documentation of structural choices (e.g., modeling the Central Office as a system premise rather than a physical entity to avoid singleton tables).

### Phase 2: Logical Design & Performance Analysis (Exercise 2)
- **Volume Table:** Estimation of database size over a projected 10-year horizon (e.g., handling ~1M+ bookings).
- **Access Table (Workload Analysis):** Evaluation of read/write costs for 5 critical daily operations.
- **Redundancy Analysis:** Implementation of derived attributes (e.g., `Booking_Count` on Event Locations) with mathematical justification of I/O performance gains during reporting queries.
- **Logical Schema:** Final Object-Relational database design represented in UML.

## 🛠️ Key Engineering Choices
During the design phase, several strategic decisions were made to optimize performance and data integrity:
1. **Performance Tuning via Redundancy:** An active derivation rule (simulated via DB triggers) was designed to maintain a `Booking_Count` on Event Locations. This choice drops the read operations for the daily ranking report from hundreds of thousands of full table scans down to a simple $O(1)$ read per location.
2. **Table of Accesses Method:** Cost calculations strictly adhere to physical disk I/O principles, factoring in both base accesses (Read=1) and structural updates (Write=2), explicitly handling hidden trigger costs.
