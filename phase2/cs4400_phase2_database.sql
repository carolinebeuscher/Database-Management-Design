-- CS4400: Introduction to Database Systems Fall 2025
-- Phase II: ER Mangement Create Table & Insert Statements
--  Monday, September 15, 2025
-- Caroline Beuscher, Sofia Oliver, Sarah Shivers

--  Establish consistent environment for database behavior:
set global transaction isolation level serializable;
set global SQL_MODE = 'ANSI,TRADITIONAL';
set names utf8mb4;
set SQL_SAFE_UPDATES = 0;

set @thisDatabase = 'er_management';
drop database if exists er_management;
create database if not exists er_management;
use er_management;

-- Define the database structures:

create table er_management.person
( ssn CHAR(11) NOT NULL, 
bdate DATE NOT NULL, 
fname VARCHAR(50) NOT NULL,
lname VARCHAR(50) NOT NULL,
address VARCHAR(50) NOT NULL,
PRIMARY KEY (ssn) );

INSERT INTO er_management.person (ssn, bdate, fname, lname, address)
VALUES
('909-10-1111', '1987-03-22', 'Maria', 'Alvarez', '81 Peachtree Pl NE, Atlanta, GA 30309'),
('323-44-5555', '1979-12-11', 'Marcus', 'Lee', '1420 Oak Terrace, Decatur, GA 30030'),
('123-45-6789', '1965-02-25', 'Christopher', 'Davis', '1234 Peach Street, Atlanta, GA 30305'),
('212-33-4444', '1986-06-06', 'Priya', 'Shah', '1000 Howell Mill Rd, Atlanta, GA 30303'),
('101-22-3030', '1997-05-19', 'Emily', 'Park', '848 Spring St NW, Atlanta, GA 30308'),
('454-66-7777', '1980-05-01', 'Omar', 'Haddad', '108 Main St, Atlanta, GA 30308'),
('888-77-6666', '1975-06-10', 'Sarah', 'Mitchell', '742 Maple Avenue, Decatur, GA 30030'),
('135-79-0000', '1980-08-15', 'David', 'Thompson', '925 Brookside Drive, Marietta, GA 30062'),
('204-60-8010', '1978-04-22', 'Laura', 'Chen', '488 Willow Creek Lane, Johns Creek, GA 30097'),
('987-65-4321', '1970-03-01', 'Matthew', 'Nguyen', '3100 Briarcliff Road, Atlanta, GA 30329'),
('636-77-8888', '1970-01-01', 'Olivia', 'Bennett', '950 W Peachtree, Atlanta, GA 30308'),
('858-99-0000', '1975-06-24', 'Chloe', 'Davis', '500 North Ave, Atlanta, GA 30302'),
('969-00-1112', '1980-12-14', 'Liam', 'Foster', '670 Piedmont Ave, Atlanta, GA 30303'),
('300-40-5000', '1985-01-10', 'David', 'Taylor', '124 Oakwood Circle, Smyrna, GA 30080'),
('800-50-7676', '1987-07-18', 'Ethan', 'Brooks', '275 Pine Hollow Drive, Roswell, GA 30075'),
('103-05-7090', '1990-09-25', 'Hannah', 'Wilson', '889 Laurel Springs Lane, Alpharetta, GA 30022');
						
            
create table er_management.staff
(sssn CHAR(11) NOT NULL,
staffID VARCHAR(6) NOT NULL,
hiredate DATE NOT NULL,
salary INT NOT NULL,
PRIMARY KEY (sssn),
UNIQUE (staffID),
FOREIGN KEY (sssn) REFERENCES person(ssn)
	ON DELETE CASCADE ON UPDATE RESTRICT );

INSERT INTO er_management.staff (sssn, staffID, hiredate, salary)
VALUES
('636-77-8888', '720301', '2023-02-01', 92000),
('858-99-0000', '720303', '2021-11-30', 93500),
('969-00-1112', '720304', '2020-08-20', 90500),
('212-33-4444', '510201', '2016-08-19', 265000),
('323-44-5555', '510202', '2019-09-03', 238000),
('101-22-3030', '510203', '2014-02-27', 312000),
('454-66-7777', '510204', '2012-11-05', 328000),
('888-77-6666', '107435', '2017-03-11', 200000),
('135-79-0000', '237432', '2019-02-05', 250000),
('204-60-8010', '902385', '2012-05-30', 300000),
('987-65-4321', '511283', '2010-01-01', 450000),
('300-40-5000', '936497', '2021-09-15', 79000),
('800-50-7676', '783404', '2017-11-23', 91000),
('103-05-7090', '416799', '2019-08-13', 85000);

    
create table er_management.department
( deptID INT NOT NULL,
dept_name VARCHAR(50) NOT NULL, 
manager CHAR(11) NOT NULL,
PRIMARY KEY (deptID), 
UNIQUE (dept_name, manager),
FOREIGN KEY (manager) REFERENCES staff(sssn) 
	ON DELETE RESTRICT ON UPDATE CASCADE );    

INSERT INTO er_management.department (deptID, dept_name, manager)
VALUES
(4, 'Ophthalmology', '204-60-8010'),
(7, 'Cardiology', '101-22-3030'),
(9, 'Neurology', '454-66-7777'),
(11, 'Primary Care', '987-65-4321');

    
create table er_management.room
( room_num INT NOT NULL,
room_type VARCHAR(50) NOT NULL,
controlling_dept INT NOT NULL,
PRIMARY KEY (room_num), 
FOREIGN KEY (controlling_dept) REFERENCES department(deptID)
	ON DELETE RESTRICT ON UPDATE CASCADE );
    
INSERT INTO er_management.room (room_num, room_type, controlling_dept) 
VALUES
(908, 'Shared', 11),
(1108, 'Private', 4),
(1421, 'Private', 7),
(3102, 'Shared', 9);



create table er_management.patient
( pssn CHAR(11) NOT NULL,
contact VARCHAR(12),
funds INT,
occupy_room INT,
PRIMARY KEY(pssn),
FOREIGN KEY (pssn) REFERENCES person(ssn)
	ON DELETE RESTRICT ON UPDATE RESTRICT,
FOREIGN KEY (occupy_room) REFERENCES room(room_num)
	ON DELETE SET NULL ON UPDATE CASCADE );

INSERT INTO er_management.patient (pssn, contact, funds, occupy_room) VALUES 
('909-10-1111','404-555-1010', 1800, 3102),
('323-44-5555','470-555-2020', 2400, 1421),
('123-45-6789', '470-321-6543', 2000, 1108);



create table er_management.doctor
( dssn CHAR(11) NOT NULL,
licenseNumber VARCHAR(6) NOT NULL,
experience INT NOT NULL, 
PRIMARY KEY (dssn),
UNIQUE (licenseNumber),
FOREIGN KEY (dssn) REFERENCES Staff(sssn)
	ON DELETE RESTRICT ON UPDATE RESTRICT );
    
    
INSERT INTO er_management.doctor (dssn, licenseNumber, experience)
VALUES
('212-33-4444', '77231', 11),
('323-44-5555', '88342', 7),
('101-22-3030', '66125', 15),
('454-66-7777', '99473', 18),
('888-77-6666', '89012', 16),
('135-79-0000', '23456', 8),
('204-60-8010', '34567', 12),
('987-65-4321', '56789', 20);

    
    
    
create table er_management.orders
( orderNumber VARCHAR(50) NOT NULL,
priority INT NOT NULL,
	CHECK (priority >0 and priority <=5),
order_date DATE,
cost DECIMAL(8,2) CHECK (cost>=0),
placedby_doctor CHAR(11) NOT NULL, 
for_patient CHAR(11) NOT NULL,
PRIMARY KEY (orderNumber),
FOREIGN KEY (placedby_doctor) REFERENCES doctor(dssn)
	ON DELETE RESTRICT ON UPDATE RESTRICT,
FOREIGN KEY (for_patient) REFERENCES patient(pssn)
	ON DELETE RESTRICT ON UPDATE RESTRICT );


INSERT INTO er_management.orders (orderNumber, priority, order_date, cost, placedby_doctor, for_patient) 
VALUES 
('3100451', 2, '2025-09-15', 25, '323-44-5555', '909-10-1111'),
('3750129', 1, '2025-09-15', 95, '101-22-3030', '323-44-5555'),
('1560238', 2, '2025-04-27', 15, '888-77-6666', '123-45-6789'),
('1561902', 1, '2025-05-01', 50, '135-79-0000', '123-45-6789');


create table er_management.appointment
( apptssn CHAR(11) NOT NULL,
booking_date DATE NOT NULL,
booking_time TIME NOT NULL,
cost DECIMAL(8,2) NOT NULL CHECK (cost >= 0),
PRIMARY KEY (apptssn, booking_date, booking_time),
FOREIGN KEY (apptssn) REFERENCES patient(pssn)
	ON DELETE RESTRICT ON UPDATE RESTRICT);
    
INSERT INTO er_management.appointment (apptssn, booking_date, booking_time, cost)
VALUES
('909-10-1111', '2025-09-15', '09:20:00', 520),
('323-44-5555', '2025-09-15', '14:05:00', 460),
('123-45-6789', '2025-03-15', '15:00:00', 300),
('123-45-6789', '2025-04-27', '11:30:00', 750);

    
create table er_management.nurse
( nssn CHAR(11) NOT NULL,
shiftType VARCHAR(10) NOT NULL,
regExpiration DATE NOT NULL,
PRIMARY KEY (nssn),
FOREIGN KEY (nssn) REFERENCES Staff(sssn)
	ON DELETE CASCADE ON UPDATE RESTRICT );

INSERT INTO er_management.nurse (nssn, shiftType, regExpiration)
VALUES
('636-77-8888', 'Morning', '2027-01-31'),
('858-99-0000', 'Night', '2026-05-31'),
('969-00-1112', 'Afternoon', '2026-12-31'),
('300-40-5000', 'Morning', '2026-06-01'),
('800-50-7676', 'Afternoon', '2026-07-15'),
('103-05-7090', 'Night', '2026-05-31');



create table er_management.prescription
( orderNumber VARCHAR(50) NOT NULL,
drugType VARCHAR(50) NOT NULL,
dosage INT NOT NULL CHECK (dosage > 0),
PRIMARY KEY(orderNumber),
FOREIGN KEY (orderNumber) REFERENCES orders(orderNumber)
	ON DELETE CASCADE ON UPDATE RESTRICT );
    

INSERT INTO er_management.prescription (orderNumber, drugType, dosage) VALUES 
('3100451', 'Sumatriptan', 50),
('1560238', 'pain relievers', 800);


 create table er_management.labwork
 ( lab_order_num VARCHAR(50) NOT NULL,
 lab_type VARCHAR(100) NOT NULL,
 PRIMARY KEY(lab_order_num),
 FOREIGN KEY (lab_order_num) REFERENCES orders(orderNumber)
	ON DELETE CASCADE ON UPDATE RESTRICT );

INSERT INTO er_management.labwork (lab_order_num, lab_type) VALUES
('3750129', 'Cardiac enzyme panel'),
('1561902', 'Blood test');



create table er_management.symptoms
 ( syssn CHAR(11) NOT NULL,
 booking_date DATE NOT NULL,
 booking_time TIME NOT NULL,
 sym_type VARCHAR(100) NOT NULL,
 num_days INT NOT NULL CHECK (num_days > 0),
 PRIMARY KEY(syssn, booking_date, booking_time, sym_type, num_days),
 FOREIGN KEY (syssn) REFERENCES patient(pssn)
	ON DELETE RESTRICT ON UPDATE RESTRICT,
 FOREIGN KEY (syssn,booking_date, booking_time) REFERENCES appointment(apptssn, booking_date, booking_time)
	ON DELETE RESTRICT ON UPDATE RESTRICT );


INSERT INTO er_management.symptoms (syssn, booking_date, booking_time, sym_type, num_days) VALUES
('909-10-1111', '2025-09-15', '09:20:00', 'Migraine', 5), 
('909-10-1111', '2025-09-15', '09:20:00', 'Numbness in fingers', 2),
('323-44-5555', '2025-09-15', '14:05:00', 'Chest tightness', 1),
('123-45-6789', '2025-03-15', '15:00:00', 'blurry vision', 7),
('123-45-6789', '2025-04-27', '11:30:00', 'blurry vision', 40),
('123-45-6789', '2025-04-27', '11:30:00', 'sensitivity to bright light', 10),
('123-45-6789', '2025-04-27', '11:30:00', 'seeing halos', 2);




create table er_management.works_in
( staff_ssn CHAR(11) NOT NULL,
department INT NOT NULL,
PRIMARY KEY(staff_ssn, department),
FOREIGN KEY (staff_ssn) REFERENCES staff(sssn)
	ON DELETE RESTRICT ON UPDATE RESTRICT,
FOREIGN KEY (department) REFERENCES department(deptID)
	ON DELETE RESTRICT ON UPDATE CASCADE );
    

INSERT INTO er_management.works_in (staff_ssn, department) VALUES
('636-77-8888', 9), 
('636-77-8888', 7), 
('858-99-0000', 7),
('858-99-0000', 4),
('969-00-1112', 7), 
('212-33-4444', 7), 
('323-44-5555', 9), 
('101-22-3030', 7), 
('454-66-7777', 9), 
('888-77-6666', 11), 
('135-79-0000', 4), 
('204-60-8010', 4), 
('987-65-4321', 11), 
('300-40-5000', 4), 
('800-50-7676', 4), 
('103-05-7090', 11);




create table er_management.assigned
( nurse_ssn CHAR(11) NOT NULL,
room_num INT NOT NULL,
PRIMARY KEY (nurse_ssn, room_num),
FOREIGN KEY (nurse_ssn) REFERENCES nurse(nssn)
	ON DELETE RESTRICT ON UPDATE RESTRICT,
FOREIGN KEY (room_num) REFERENCES room(room_num)
	ON DELETE CASCADE ON UPDATE CASCADE);
    
INSERT INTO er_management.assigned (nurse_ssn, room_num) VALUES
('636-77-8888',3102), 
('636-77-8888', 908), 
('858-99-0000', 1421), 
('969-00-1112', 1421), 
('969-00-1112', 1108), 
('300-40-5000', 1108), 
('800-50-7676', 1108), 
('103-05-7090', 1108); 




create table er_management.scheduled_for
( doc_ssn CHAR(11) NOT NULL,
assn CHAR(11) NOT NULL,
appt_booking_date DATE NOT NULL,
appt_booking_time TIME NOT NULL,
PRIMARY KEY (doc_ssn, appt_booking_time, appt_booking_date, assn),
FOREIGN KEY (doc_ssn) REFERENCES doctor(dssn)
	ON DELETE RESTRICT ON UPDATE RESTRICT,
FOREIGN KEY (assn, appt_booking_date, appt_booking_time) REFERENCES appointment(apptssn,booking_date,booking_time)
	ON DELETE CASCADE ON UPDATE CASCADE );

INSERT INTO er_management.scheduled_for (doc_ssn, assn, appt_booking_date, appt_booking_time) VALUES
('323-44-5555', '909-10-1111', '2025-09-15', '09:20:00'), 
('212-33-4444', '909-10-1111', '2025-09-15', '09:20:00'), 
('101-22-3030', '323-44-5555', '2025-09-15', '14:05:00'), 
('888-77-6666', '123-45-6789', '2025-03-15', '15:00:00'), 
('135-79-0000', '123-45-6789', '2025-04-27', '11:30:00'), 
('204-60-8010', '123-45-6789', '2025-04-27', '11:30:00');



