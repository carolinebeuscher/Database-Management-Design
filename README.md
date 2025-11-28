# Emergency Room Management System

A comprehensive database management system for hospital emergency room operations. The system includes a full SQL database schema, views, and stored procedures.

## Project Overview

This system models and manages an emergency room (ER) environment that supports:
- Handling appointments, room occupancy, lab orders, and prescriptions
- Managing nurses, doctors, and staff assignments
- Tracking patients and patient-staff interactions
- Managing departments, insurance funds, and operational workflows


## Project Structure

The project is divided into three phases:

- **Phase 1**: Conceptual Schema Design
  - Entity-Relationship Diagram (ERD) capturing the full structure of the ER system
- **Phase 2**: Database Schema Implementation
  - Creation of relational tables based on the ERD
  - Definition of primary keys, foreign keys, and constraints
  - Setup of initial data and referential integrity rules
- **Phase 3**: Stored Procedures and Views
  - Creation of stored procedures to automate complex ER operations (e.g., placing medical orders, booking appointments, assigning rooms, and adding/removing staff and patients)
  - Creation of views for staff-friendly reporting (e.g., outstanding charges, appointment and symptom summaries, and medical staff information)
 

## Features

### Patient Management
- Add/Manage patients
- View symptoms, insurance funds, medical orders, and appointment history
- Track associated staff members

### Staff Management
- Track all staff, including nurses, doctors, and general employees
- Handle shift, department, appointment, and room assignments
- Manage doctor–patient and nurse–patient relationships

### Medical Orders
- Place lab work or prescription orders
- Track order priority, cost, and prescribing doctor
- Record drug type and dosage for prescriptions
- Record test type for lab work
- Supports insurance fund deduction and cost verification

### Appointments
- Track timeslots, dates, and appointment costs
- Schedule patient appointments with doctors

### Room & Department Management
- Assign patients and nurses to rooms
- Track room type and occupancy
- Link staff and rooms to departments
- Track department costs, managers, and resources

## Setup Instructions

### Prerequisites
- MySQL Server
- Python 3.x
- Virtual Environment (recommended)

### Database Setup
1. Navigate to the `phase2` directory
2. Run the database creation script to build all tables, constraints, and initial inserts:
   ```bash
   mysql -u your_username -p < cs4400_phase2_database.sql
   ```

### Stored Procedures Setup
1. Navigate to the `phase3` directory
2. Run the stored procedures script to load all stored procedures and views:
   ```bash
   mysql -u your_username -p < cs4400_phase3_stored_procedures.sql


## Contributing
This is a course project repository. 
