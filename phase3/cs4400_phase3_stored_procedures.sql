-- CS4400: Introduction to Database Systems Fall 2025 
-- Phase III: ER Management Stored Procedures & Views 
-- Monday, October 13, 2025
-- Caroline Beuscher, Sofia Oliver, Sarah Shivers

--  Establish consistent environment for database behavior:
set global transaction isolation level serializable;
set global SQL_MODE = 'ANSI,TRADITIONAL';
set session SQL_MODE = 'ANSI,TRADITIONAL';
set names utf8mb4;
set SQL_SAFE_UPDATES = 0;

set @thisDatabase = 'er_hospital_management';
use er_hospital_management;

-- -------------------
-- Views
-- -------------------

-- [1] room_wise_view()
-- -----------------------------------------------------------------------------
/* This view provides an overview of patient room assignments, including the patients’ 
first and last names, room numbers, managing department names, assigned doctors' first and 
last names (through appointments), and nurses' first and last names (through room). 
It displays key relationships between patients, their assigned medical staff, and 
the departments overseeing their care. Note that there will be a row for each combination 
of assigned doctor and assigned nurse.*/
-- -----------------------------------------------------------------------------
create or replace view room_wise_view as
select patient_fname, patient_lname, room_num, department_name, doctor_fname, doctor_lname, nurse_fname, nurse_lname from
(select * from 
(select p.firstName as 'patient_fname', p.lastName as 'patient_lname', p.ssn as 'patientId', r.roomNumber, d.longName as 'department_name' from person p 
join patient t on t.ssn = p.ssn
join room r on r.occupiedBy = p.ssn
join department d on d.deptId = r.managingDept) as a
left join 
(select
p.firstName as 'nurse_fname', p.lastName as 'nurse_lname', ra.roomNumber as 'room_num'
from person p
join room_assignment ra on ra.nurseId = p.ssn) as b on a.roomNumber = b.room_num) as m
left join 
(select p.firstName as 'doctor_fname', p.lastName as 'doctor_lname', a.patientId
from person p 
join appt_assignment a on a.doctorId = p.ssn) as n on n.patientId = m.patientId;

-- [2] symptoms_overview_view()
-- -----------------------------------------------------------------------------
/* This view provides a comprehensive overview of patient appointments
along with recorded symptoms. Each row displays the patient’s SSN, their full name 
(HINT: the CONCAT function can be useful here), the appointment time, appointment date, 
and a list of symptoms recorded during the appointment with each symptom separated by a 
comma and a space (HINT: the GROUP_CONCAT function can be useful here). */
-- -----------------------------------------------------------------------------
create or replace view symptoms_overview_view as
select per.ssn, concat(firstName,' ', lastName) as full_name, a.apptDate, a.apptTime, group_concat(symptomType order by symptomType separator ', ') 
as symptoms from person per join patient pat, appointment a, 
symptom s where pat.ssn = per.ssn and per.ssn = a.patientId 
and a.apptDate = s.apptDate and a.apptTime = s.apptTime group by per.ssn, a.apptDate, a.apptTime;


-- [3] medical_staff_view()
-- -----------------------------------------------------------------------------
/* This view displays information about medical staff. For every nurse and doctor, it displays
their ssn, their "staffType" being either "nurse" or "doctor", their "licenseInfo" being either
their licenseNumber or regExpiration, their "jobInfo" being either their shiftType or 
experience, a list of all departments they work in in alphabetical order separated by a
comma and a space (HINT: the GROUP_CONCAT function can be useful here), and their "numAssignments" 
being either the number of rooms they're assigned to or the number of appointments they're assigned to. */
-- -----------------------------------------------------------------------------
create or replace view medical_staff_view as
select n.ssn, 'Nurse' as staffType, n.regExpiration as licenseInfo, n.shiftType as jobInfo, group_concat(distinct d.longName order by longName asc separator ', ' ) as deptNames, count(ra.nurseId) as numAssignments
from nurse n
left join works_in w on w.staffSsn = n.ssn 
left join department d on w.deptId = d.deptId
left join room_assignment ra on ra.nurseId = n.ssn group by n.ssn
union
select dr.ssn, 'Doctor' as staffType, dr.licenseNumber as licenseInfo, dr.experience as jobInfo, group_concat(distinct d.longName order by longName asc separator ', ') as deptNames, count(a.doctorId) as numAssignmnets
from doctor dr
left join works_in w on w.staffSsn = dr.ssn
left join department d on w.deptId = d.deptId
left join appt_assignment a on a.doctorId = dr.ssn group by d.longName, dr.ssn;


-- [4] department_view()
-- -----------------------------------------------------------------------------
/* This view displays information about every department in the hospital. The information
displayed should be the department's long name, number of total staff members, the number of 
doctors in the department, and the number of nurses in the department. If a department does not 
have any doctors/nurses/staff members, ensure the output for those columns is zero, not null */
-- -----------------------------------------------------------------------------
create or replace view department_view as
select d.longName as department, count(w.staffSsn) as totalStaff, count(dr.ssn) as totalDoctors, count(n.ssn) as totalNurses from department d 
join works_in w on d.deptId = w.deptId
left join doctor dr on w.staffSsn = dr.ssn
left join nurse n on w.staffSsn = n.ssn 
group by d.longName;

-- [5] outstanding_charges_view()
-- -----------------------------------------------------------------------------
/* This view displays the outstanding charges for the patients in the hospital. 
“Outstanding charges” is the sum of appointment costs and order costs. It also 
displays a patient’s first name, last name, SSN, funds, number of appointments, 
and number of orders. Ensure there are no null values if there are no charges, 
appointments, orders for a patient (HINT: the IFNULL or COALESCE functions can be 
useful here).  */
-- -----------------------------------------------------------------------------
create or replace view outstanding_charges_view as
select a.firstName as 'fname', a.lastName as 'lname', a.ssn, a.funds, COALESCE(d.Outstanding_Charges,0) as 'outstanding_costs', COALESCE(b.num_appts, 0) as 'appointment_count', COALESCE(c.num_orders, 0) as 'order_count' from
(select firstName, lastName, p.ssn, funds from person p
right join patient t on p.ssn = t.ssn) as a
left join 
(select count(patientId) as 'num_appts', patientId as 'ssn' from appointment
group by ssn) as b on a.ssn = b.ssn
left join 
(select count(patientId) as 'num_orders', patientId as 'ssn' from med_order
group by ssn) as c on c.ssn = a.ssn
left join 
(select sum(cost) as 'Outstanding_Charges', ssn from 
(select sum(cost) as 'cost', patientId as 'ssn' from med_order
group by ssn
union
select sum(cost) as 'cost', patientId as 'ssn' from appointment
group by ssn) as a
group by a.ssn) as d on d.ssn = a.ssn;


-- -------------------
-- Stored Procedures
-- -------------------

-- [6] add_patient()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new patient. If the new patient does 
not exist in the person table, then add them prior to adding the patient. 
Ensure that all input parameters are non-null, and that a patient with the given 
SSN does not already exist. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_patient;
delimiter /​/
create procedure add_patient (
	in ip_ssn varchar(40),
    in ip_first_name varchar(100),
    in ip_last_name varchar(100),
    in ip_birthdate date,
    in ip_address varchar(200), 
    in ip_funds integer,
    in ip_contact char(12)
)
sp_main: begin
	#check no null values
     if ip_ssn IS NULL or
        ip_first_name IS NULL or
        ip_last_name IS NULL or
        ip_birthdate IS NULL or
        ip_address IS NULL or
        ip_funds IS NULL or
        ip_contact IS NULL then 
        leave sp_main; 
        end if;
     
     #check patient exists in person; if not, add to person
     if ip_ssn not in (select ssn from person) then 
 		insert into person (ssn, birthdate, firstName, lastName, address)
         values (ip_ssn, ip_birthdate, ip_first_name, ip_last_name, ip_address);
         end if;
 	
     #check patient does not exist in patient 
     if ip_ssn in (select ssn from patient) then leave sp_main; end if;
     
     #if clear checks, insert patient into patient table
 	insert into patient (ssn, contact, funds) 
     values (ip_ssn, ip_contact, ip_funds);

end /​/
delimiter ;

-- [7] record_symptom()
-- -----------------------------------------------------------------------------
/* This stored procedure records a new symptom for a patient. Ensure that all input 
parameters are non-null, and that the referenced appointment exists for the given 
patient, date, and time. Ensure that the same symptom is not already recorded for 
that exact appointment. */
-- -----------------------------------------------------------------------------
drop procedure if exists record_symptom;
delimiter /​/
create procedure record_symptom (
	in ip_patientId varchar(40),
    in ip_numDays int,
    in ip_apptDate date,
    in ip_apptTime time,
    in ip_symptomType varchar(100)
)
sp_main: begin
	-- check parameters are not null
    if ip_patientId IS NULL or
		ip_numDays IS NULL or
		ip_apptDate IS NULL or
		ip_apptTime IS NULL or
		ip_symptomType is NULL then 
        leave sp_main;
	end if;
        -- check appt exists for patient, date, and time
    if ip_patientId not in (select patientId from appointment) then
		-- select 'patient does not exist' ;
		leave sp_main;
	end if ;
	if ip_apptDate not in (select apptDate from appointment) then
		-- select 'appt day does not exist' ;
		leave sp_main;
    end if; 
	if ip_apptTime not in (select apptTime from appointment) then
		-- select 'appt time does not exist' ;
		leave sp_main;
    end if;

    -- check that symptom is not already recorded in appt
    if ip_symptomType not in (select symptomType from symptom) then
	-- select 'new symptom found';
	insert into symptom values (ip_symptomType, ip_numDays, ip_patientId, ip_apptDate, ip_apptTime);
    end if;
    
end /​/
delimiter ;


-- [8] book_appointment()
-- -----------------------------------------------------------------------------
/* This stored procedure books a new appointment for a patient at a specific time and date.
The appointment date/time must be in the future (the CURDATE() and CURTIME() functions will
be helpful). The patient must not have any conflicting appointments and must have the funds
to book it on top of any outstanding costs. Each call to this stored procedure must add the 
relevant data to the appointment table if conditions are met. Ensure that all input parameters 
are non-null and reference an existing patient, and that the cost provided is non‑negative. 
Do not charge the patient, but ensure that they have enough funds to cover their current outstanding 
charges and the cost of this appointment.
HINT: You should complete outstanding_charges_view before this procedure! */
-- -----------------------------------------------------------------------------
drop procedure if exists book_appointment;
delimiter /​/
create procedure book_appointment (
	in ip_patientId char(11),
	in ip_apptDate date,
    in ip_apptTime time,
	in ip_apptCost integer
)
sp_main: begin
	declare appt_datetime DATETIME;
    declare conflict_count INT default 0;
    declare patient_funds INT;
    declare outstanding_charges INT default 0;
    declare required_funds INT default 0;
    
	if ip_patientId is null or
		ip_apptDate is null or
		ip_apptTime is null or
		ip_apptCost is null then
		leave sp_main;
	end if;
    -- check patient exists
	if ip_patientId not in (select ssn from patient) then
    leave sp_main;
    end if;
    -- check that cost is non-neg
    if ip_apptCost < 0 then leave sp_main;
    end if;
	-- combine date and time since they are separate
    set appt_datetime = CONCAT(ip_apptDate, ', ', ip_apptTime);
    -- check if date and time are before current date and time
    if appt_datetime < CURDATE() and appt_datetime < CURTIME()
    then leave sp_main;
    end if;
    -- find count of patients date and time that are the same 
    select count(*) into conflict_count from appointment 
    where patientId = ip_patientId and apptDate = ip_apptDate and apptTime = ip_apptTime;
    -- check if there are conflicts
    if conflict_count > 0 then leave sp_main;
    end if;
    
    -- find funds and outstanding cost from outstanding charges view
    select funds into patient_funds from outstanding_charges_view where ssn = ip_patientId;
    select outstanding_costs into outstanding_charges from outstanding_charges_view where ssn = ip_patientId;
    
    -- set total funds from outstanding cost and appt cost
    set required_funds = outstanding_charges + ip_apptCost;
    
    -- check if patient funds are greater than required funds
    if patient_funds < required_funds then 
    leave sp_main;
    end if;
    -- insert if none of the above are in appt table
     if conflict_count = 0 then
        insert into appointment values (ip_patientId, ip_apptDate, ip_apptTime, ip_apptCost);
	end if;
end /​/
delimiter ;

-- [9] place_order()
-- -----------------------------------------------------------------------------
/* This stored procedures places a new order for a patient as ordered by their
doctor. The patient must also have enough funds to cover the cost of the order on 
top of any outstanding costs. Each call to this stored procedure will represent 
either a prescription or a lab report, and the relevant data should be added to the 
corresponding table. Ensure that the order-specific, patient-specific, and doctor-specific 
input parameters are non-null, and that either all the labwork specific input parameters are 
non-null OR all the prescription-specific input parameters are non-null (i.e. if ip_labType 
is non-null, ip_drug and ip_dosage should both be null).
Ensure the inputs reference an existing patient and doctor. 
Ensure that the order number is unique for all orders and positive. Ensure that a cost 
is provided and non‑negative. Do not charge the patient, but ensure that they have 
enough funds to cover their current outstanding charges and the cost of this appointment. 
Ensure that the priority is within the valid range. If the order is a prescription, ensure 
the dosage is positive. Ensure that the order is never recorded as both a lab work and a prescription.
The order date inserted should be the current date, and the previous procedure lists a function that
will be required to use in this procedure as well.
HINT: You should complete outstanding_charges_view before this procedure! */
-- -----------------------------------------------------------------------------
drop procedure if exists place_order;
delimiter /​/
create procedure place_order (
	in ip_orderNumber int, 
	in ip_priority int,
    in ip_patientId char(11), 
	in ip_doctorId char(11),
    in ip_cost integer,
    in ip_labType varchar(100),
    in ip_drug varchar(100),
    in ip_dosage int
)
sp_main: begin
	declare patient_funds INT;
    declare outstanding_charges INT;
    declare required_funds INT;
    declare prescription_specific BOOL;
    declare labwork_specific BOOL;
	
    #check order values are non-null 
	If ip_orderNumber IS NULL or
    ip_priority IS NULL or
    ip_patientId IS NULL or 
    ip_doctorId IS NULL or 
    ip_cost IS NULL
    then leave sp_main; end if;
    
    #check either prescription-specific or labwork-specific is not null 
    If (ip_labType IS NULL and
    ip_drug IS NOT NULL and 
    ip_dosage IS NOT NULL) 
    then set prescription_specific = True; end if;
    
    if (ip_labType IS NOT NULL and
    ip_drug IS NULL and 
    ip_dosage IS NULL) 
    then set labwork_specific = True; end if;
    
    #if both prescription-specific and labwork-specific are null then leave
    #if both prescription-specific and labwork-specific are not null them leave
    if not prescription_specific and not labwork_specific then leave sp_main; end if;
    if prescription_specific and labwork_specific then leave sp_main; end if;
    
	#check patient and doctor exist
	if ip_patientId not in (select ssn from patient) then leave sp_main; end if; 
	if ip_doctorId not in (select ssn from doctor) then leave sp_main; end if; 
        
	#check order number is positive and unique 
	if ip_orderNumber <0 then leave sp_main; end if; 
	if ip_orderNumber in (select orderNumber from med_order) then leave sp_main; end if; 
        
	#check cost is positive
	if ip_cost <0 then leave sp_main; end if; 

	#check priority is in valid range
	if ip_priority not between 1 and 5 then leave sp_main; end if; 
        
	#check patient has enough funds to cover order cost and outstanding charges
	select funds into patient_funds from outstanding_charges_view where ssn = ip_patientId;
	select outstanding_costs into outstanding_charges from outstanding_charges_view where ssn = ip_patientId;
	set required_funds = outstanding_charges + ip_cost;
	if patient_funds < required_funds then leave sp_main; end if;

    #ensure dosage is positive if order is prescription-specific
	if prescription_specific = True then 
        if ip_dosage <0 then leave sp_main; end if; 
	end if;
	
	#if passes checks, insert into med_order
    insert into med_order (orderNumber, orderDate, priority, patientId, doctorId, cost) 
    values (ip_orderNumber, curdate(), ip_priority, ip_patientId, ip_doctorId, ip_cost);
    
    #if prescription_specific, insert into perscription 
    if prescription_specific = True then 
    insert into prescription (orderNumber, drug, dosage)
    values (ip_orderNumber, ip_drug, ip_dosage); end if;
    
    #if labwork-specific, insert into labwork 
    if labwork_specific = True then 
    insert into lab_work (orderNumber, labType)
    values (ip_orderNumber, ip_labType); end if;
end /​/
delimiter ;

-- [10] add_staff_to_dept()
-- -----------------------------------------------------------------------------
/* This stored procedure adds a staff member to a department. If they are already
a staff member and not a manager for a different department, they can be assigned
to this new department. If they are not yet a staff member or person, they can be 
assigned to this new department and all other necessary information should be 
added to the database. Ensure that all input parameters are non-null and that the 
Department ID references an existing department. Ensure that the staff member is 
not already assigned to the department. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_staff_to_dept;
delimiter /​/
create procedure add_staff_to_dept (
	in ip_deptId integer,
    in ip_ssn char(11),
    in ip_firstName varchar(100),
	in ip_lastName varchar(100),
    in ip_birthdate date,
    in ip_startdate date,
    in ip_address varchar(200),
    in ip_staffId integer,
    in ip_salary integer
)
sp_main: begin
	if ip_deptId is null or
ip_ssn is null or
	ip_firstName is null or
        ip_lastName is null or
        ip_birthdate is null or
        ip_startdate is null or
        ip_address is null or
        ip_staffId is null or
        ip_salary is null then
	leave sp_main;
    end if;
	
    if ip_deptId not in (select deptId from department) then leave sp_main; end if;
    
    if (ip_ssn,ip_deptId) in (select * from works_in) then leave sp_main; end if;
    
    if ip_ssn in (select manager from department) then leave sp_main; end if;

    if ip_ssn not in (select ssn from person) then 
    insert into person(ssn, firstName, lastName, birthdate, address) values (ip_ssn, ip_firstName, ip_lastName, ip_birthdate, ip_address); end if;
    
	insert into staff(ssn, staffId, hireDate, salary) values (ip_ssn, ip_staffId, ip_startdate, ip_salary);
	insert into works_in(staffSsn, deptId) values (ip_ssn, ip_deptId);

end /​/
delimiter ;

-- [11] add_funds()
-- -----------------------------------------------------------------------------
/* This stored procedure adds funds to an existing patient. The amount of funds
added must be positive. Ensure that all input parameters are non-null and reference 
an existing patient. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_funds;
delimiter /​/
create procedure add_funds (
	in ip_ssn char(11),
    in ip_funds integer
)
sp_main: begin
	-- check inputs are not null
    if ip_ssn IS NULL or
		ip_funds is NULL then 
        leave sp_main;
	end if;
    -- check existing patient
	if ip_ssn not in (select ssn from patient) then
		leave sp_main;
	end if;
    -- check adding positive number
    if ip_funds > 0 then
		update patient set funds = (funds + ip_funds) where ssn = ip_ssn;
	end if;
end /​/
delimiter ;

-- [12] assign_nurse_to_room()
-- -----------------------------------------------------------------------------
/* This stored procedure assigns a nurse to a room. In order to ensure they
are not over-booked, a nurse cannot be assigned to more than 4 rooms. Ensure that 
all input parameters are non-null and reference an existing nurse and room. */
-- -----------------------------------------------------------------------------
drop procedure if exists assign_nurse_to_room;
delimiter /​/
create procedure assign_nurse_to_room (
	in ip_nurseId char(11),
    in ip_roomNumber integer
)
sp_main: begin
	-- inputs not null
    if ip_nurseId is NULL or
		ip_roomNumber is NULL then
        leave sp_main;
	end if;
    -- references existing nurse and room
    if ip_nurseId not in (select ssn from nurse) then 
		leave sp_main;
	end if;
    if ip_roomNumber not in (select roomNumber from room) then 
		leave sp_main;
	end if;
    
    -- address if nurse is already assigned that room 
    if (ip_roomNumber, ip_nurseId) in (select roomNumber, nurseId from room_assignment)
    then leave sp_main; 
	end if;
    
    -- nurse is not assigned to > 4 rooms
    if ip_nurseId in 
		(select nurseId from room_assignment
		group by nurseId
		having count(nurseId) < 4)
        then 
        insert into room_assignment values (ip_roomNumber, ip_nurseId);
	end if;
end /​/
delimiter ;

-- [13] assign_room_to_patient()
-- -----------------------------------------------------------------------------
/* This stored procedure assigns a room to a patient. The room must currently be
unoccupied. If the patient is currently assigned to a different room, they should 
be removed from that room. To ensure that the patient is placed in the correct type 
of room, we must also confirm that the provided room type matches that of the 
provided room number. Ensure that all input parameters are non-null and reference 
an existing patient and room. */
-- -----------------------------------------------------------------------------
drop procedure if exists assign_room_to_patient;
delimiter /​/
create procedure assign_room_to_patient (
    in ip_ssn char(11),
    in ip_roomNumber int,
    in ip_roomType varchar(100)
)
sp_main: begin
    declare occupied char(11);
    
    -- input not null
    if ip_ssn is null or
		ip_roomNumber is null or
        ip_roomType is null then
        leave sp_main;
	end if;
    -- room exists
    if ip_roomNumber not in (select roomNumber from room) then
		leave sp_main;
	end if;
    -- patient exists
    if ip_ssn not in (select ssn from patient) then
		leave sp_main;
	end if;
    -- room unoccupied
    if ip_roomNumber in (select roomNumber from room where occupiedBy is not null) then
		leave sp_main;
	end if;
    -- if patient assigned to different room, need to remove
    if ip_ssn in (select occupiedBy from room) then
		update room set occupiedBy = NULL where ip_ssn = occupiedBy;
	end if;
    -- provided room type matches provided room number
	if ip_roomType not like (select roomType from room where ip_roomNumber = roomNumber) then 
    leave sp_main;
    end if;
    
    update room set occupiedBy = ip_ssn where ip_roomNumber = roomNumber and ip_roomType = roomType;


    
end /​/
delimiter ;

-- [14] assign_doctor_to_appointment()
-- -----------------------------------------------------------------------------
/* This stored procedure assigns a doctor to an existing appointment. Ensure that no
more than 3 doctors are assigned to an appointment, and that the doctor does not
have commitments to other patients at the exact appointment time. Ensure that all input 
parameters are non-null and reference an existing doctor and appointment. */
-- -----------------------------------------------------------------------------
drop procedure if exists assign_doctor_to_appointment;
delimiter /​/
create procedure assign_doctor_to_appointment (
	in ip_patientId char(11),
    in ip_apptDate date,
    in ip_apptTime time,
    in ip_doctorId char(11)
)
sp_main: begin
	
	#check no null inputs
	if ip_patientId IS NULL or
    ip_apptDate is NULL or 
    ip_apptTime IS NULL or
    ip_doctorId IS NULL
    then leave sp_main; end if;
    
    #check doctor exists
    if ip_doctorId not in (select ssn from doctor)
    then leave sp_main; end if;

    
    #check appointment date and time slot exists to be able to assign a doctor
	if CONCAT(ip_apptDate, ', ', ip_apptTime) not in 
    (select CONCAT(apptDate, ', ',apptTime) from appointment)
    then leave sp_main; end if;
    
	#check max 2 doctors are already assigned to appt
	if CONCAT(ip_apptDate, ', ', ip_apptTime) in (
   	select concat(apptDate, ', ', apptTime) from(
	select count(doctorId), apptDate, apptTime from appt_assignment
	group by apptDate, apptTime
	having count(doctorId) >2) a)
	then leave sp_main; end if;
    
    
	#check doc is free
    if concat(ip_apptTime, ', ', ip_doctorId) in (
    select concat(apptTime, ', ',doctorId) from appt_assignment)
    then leave sp_main; end if;
    
    #if clears checks, assign doc to appt
    insert into appt_assignment (patientId, apptDate, apptTime, doctorId)
    values (ip_patientId, ip_apptDate, ip_apptTime, ip_doctorId);

end /​/
delimiter ;

-- [15] manage_department()
-- -----------------------------------------------------------------------------
/* This stored procedure assigns a staff member as the manager of a department.
The staff member cannot currently be the manager for any departments. They
should be removed from working in any departments except the given
department (make sure the staff member is not the sole employee for any of these 
other departments, as they cannot leave and be a manager for another department otherwise),
for which they should be set as its manager. Ensure that all input parameters are non-null 
and reference an existing staff member and department.
*/
-- -----------------------------------------------------------------------------
drop procedure if exists manage_department;
delimiter /​/
create procedure manage_department (
	in ip_ssn char(11),
    in ip_deptId int
)
sp_main: begin
	declare dept_count int;

 	if ip_ssn is null or
 		ip_deptId is null then
 	leave sp_main;
		end if;
     
     -- check if they are an employee
		if ip_ssn not in (select staffSsn from works_in) then leave sp_main; end if;
     
	-- check if they are a manager
		if ip_ssn in (select manager from department) then leave sp_main; end if;
     
	-- check if they are sole employee
		select count(*) into dept_count from works_in where deptId = 1;
		if dept_count = 1 then leave sp_main; end if;
     
     -- remove from department they work in 
		if ip_ssn in (select staffSsn from works_in) then
 		delete from works_in where ip_ssn = staffSsn; end if;
	
     -- inserts
		insert into works_in(staffSsn, deptId) values (ip_ssn, ip_deptId);
		update department set deptId = ip_deptId, manager = ip_ssn where deptId = ip_deptId;
end /​/
delimiter ;

-- [16] release_room()
-- -----------------------------------------------------------------------------
/* This stored procedure removes a patient from a given room. Ensure that 
the input room number is non-null and references an existing room.  */
-- -----------------------------------------------------------------------------
drop procedure if exists release_room;
delimiter /​/
create procedure release_room (
    in ip_roomNumber int
)
sp_main: begin
	-- input not null
    if ip_roomNumber is null then
		leave sp_main;
	end if;
    
    -- references exisitng room
    if ip_roomNumber in (select roomNumber from room) then
		update room set occupiedBy = NULL where ip_roomNumber = roomNumber;
	end if;
end /​/
delimiter ;

-- [17] remove_patient()
-- -----------------------------------------------------------------------------
/* This stored procedure removes a given patient. If the patient has any pending
orders or remaining appointments (regardless of time), they cannot be removed.
If the patient is not a staff member, they then must be completely removed from 
the database. Ensure all data relevant to this patient is removed. Ensure that the 
input SSN is non-null and references an existing patient. */
-- -----------------------------------------------------------------------------
drop procedure if exists remove_patient;
delimiter /​/
create procedure remove_patient (
	in ip_ssn char(11)
)
sp_main: begin
		-- not null
		if ip_ssn is null then
        leave sp_main;
        end if;
    -- existing patient
		if ip_ssn not in (select ssn from patient) then
        leave sp_main;
        end if;
    -- no pending orders or remaining appts (regardless of time)
		if ip_ssn in (select patientId from med_order) then 
        leave sp_main;
        end if;
        if ip_ssn in (select patientId from appointment) then 
        leave sp_main;
        end if;
    -- ensure all relevant data is removed from patient
		delete from patient where ip_ssn = ssn;
	-- delete patient from person only if they are not staff
		if ip_ssn in (select ssn from staff) then
			leave sp_main;
		end if;
        
        delete from person where ip_ssn = ssn;
end /​/
delimiter ;

-- remove_staff()
-- -----------------------------------------------------------------------------
/* This stored procedure removes a given staff member. If the staff member is a 
manager, they are not removed. If the staff member is a nurse, all rooms
they are assigned to have a remaining nurse if they are to be removed. 
If the staff member is a doctor, all appointments they are assigned to have
a remaining doctor and they have no pending orders if they are to be removed.
If the staff member is not a patient, then they are completely removed from 
the database. All data relevant to this staff member is removed. */
-- -----------------------------------------------------------------------------
drop procedure if exists remove_staff;
delimiter /​/
create procedure remove_staff (
	in ip_ssn char(11)
)
sp_main: begin
	-- ensure parameters are not null
    if ip_ssn is null then
		leave sp_main;
	end if;
    
	-- ensure staff member exists
	if not exists (select ssn from staff where ssn = ip_ssn) then
		leave sp_main;
	end if;
	
    -- if staff member is a nurse
    if exists (select ssn from nurse where ssn = ip_ssn) then
	if exists (
		select 1
		from (
			 -- Get all rooms assigned to the nurse
			 select roomNumber
			 from room_assignment
			 where nurseId = ip_ssn
		) as my_rooms
		where not exists (
			 -- Check if there is any other nurse assigned to that room
			 select 1
			 from room_assignment 
			 where roomNumber = my_rooms.roomNumber
			   and nurseId <> ip_ssn
		)
	)
	then
		leave sp_main;
	end if;
		
        -- remove this nurse from room_assignment and nurse tables
		delete from room_assignment where nurseId = ip_ssn;
		delete from nurse where ssn = ip_ssn;
	end if;
	
    -- if staff member is a doctor
	if exists (select ssn from doctor where ssn = ip_ssn) then
		-- ensure the doctor does not have any pending orders
		if exists (select * from med_order where doctorId = ip_ssn) then 
			leave sp_main;
		end if;
		
		-- ensure all appointments assigned to this doctor have remaining doctors assigned
		if exists (
		select 1
		from (
			 -- Get all appointments assigned to ip_ssn
			 select patientId, apptDate, apptTime
			 from appt_assignment
			 where doctorId = ip_ssn
		) as ip_appointments
		where not exists (
			 -- For the same appointment, check if there is any other doctor assigned
			 select 1
			 from appt_assignment 
			 where patientId = ip_appointments.patientId
			   and apptDate = ip_appointments.apptDate
			   and apptTime = ip_appointments.apptTime
			   and doctorId <> ip_ssn
		)
	)
	then
		leave sp_main;
	end if;
        
		-- remove this doctor from appt_assignment and doctor tables
		delete from appt_assignment where doctorId = ip_ssn;
		delete from doctor where ssn = ip_ssn;
	end if;
    
    -- remove staff member from works_in and staff tables
    delete from works_in where staffSsn = ip_ssn;
    delete from staff where ssn = ip_ssn;

	-- ensure staff member is not a patient
	if exists (select * from patient where ssn = ip_ssn) then 
		leave sp_main;
	end if;
    
    -- remove staff member from person table
	delete from person where ssn = ip_ssn;
end /​/
delimiter ;

-- [18] remove_staff_from_dept()
-- -----------------------------------------------------------------------------
/* This stored procedure removes a staff member from a department. If the staff
member is the manager of that department, they cannot be removed. If the staff
member, after removal, is no longer working for any departments, they should then 
also be removed as a staff member, following all logic in the remove_staff procedure. 
Ensure that all input parameters are non-null and that the given person works for
the given department. Ensure that the department will have at least one staff member 
remaining after this staff member is removed. */
-- -----------------------------------------------------------------------------
drop procedure if exists remove_staff_from_dept;
delimiter /​/
create procedure remove_staff_from_dept (
	in ip_ssn char(11),
    in ip_deptId integer
)
sp_main: begin
	declare ssn_count INT;
    declare dept_count INT;
    declare dept_manager CHAR(11);

	#check input is not null
    if ip_ssn IS NULL or
    ip_deptId IS NULL 
    then leave sp_main; end if;
    
    #check staff is not a manager of the input department 
    select manager into dept_manager from department where ip_deptId = deptID;
    if ip_ssn = dept_manager then leave sp_main; end if;
    
    #check staff works in the given dept 
    if CONCAT(ip_ssn, ', ', ip_deptId) not in (select CONCAT(staffSsn, ', ', deptId) from works_in)
    then leave sp_main; end if;
    
    #check how many depts the staff member works in 
    select count(staffSsn) into ssn_count from works_in where staffSsn = ip_ssn;
    
    #check how many people work in the given dept and leave if dept has less than 2 employees
    select count(staffSsn) into dept_count from works_in where deptId = ip_deptId;
    if dept_count <2 then leave sp_main; end if;
    
    #if staff only works in this one department then delete them from everywhere 
    if ssn_count = 1 then 
    call remove_staff(ip_ssn); end if;
    
    #if staff member works for more than 1 dept just delete them from the given dept 
	delete from works_in where staffSsn = ip_ssn and deptId = ip_deptId;
    
end /​/
delimiter ;

-- [19] complete_appointment()
-- -----------------------------------------------------------------------------
/* This stored procedure completes an appointment given its date, time, and patient SSN.
The completed appointment and any related information should be removed 
from the system, and the patient should be charged accordingly. Ensure that all 
input parameters are non-null and that they reference an existing appointment. */
-- -----------------------------------------------------------------------------
drop procedure if exists complete_appointment;
delimiter /​/
create procedure complete_appointment (
	in ip_patientId char(11),
    in ip_apptDate DATE, 
    in ip_apptTime TIME
)
sp_main: begin
	declare appt_cost INT;
    
    #check no null parameters 
    if ip_patientId IS NULL or
	ip_apptDate IS NULL or
    ip_apptTime IS NULL then 
    leave sp_main; end if;
    
    #Check the appointment is an existing appointment 
	if CONCAT(ip_patientId, ', ', ip_apptDate, ', ', ip_apptTime) not in 
    (select CONCAT(patientId, ', ', apptDate, ', ',apptTime) from appointment)
    then leave sp_main; end if;
    
    
    #take appt cost and subtract from patient's funds 
    select cost into appt_cost from appointment where patientId = ip_patientId;
	#update outstanding_charges_view set outstanding_costs = outstanding_costs + appt_cost where ssn = ip_patientId;
    update patient set funds = funds - appt_cost where ssn = ip_patientId;
    
    
    #delete appointment 
    delete from appointment where patientId = ip_patientId and apptDate = ip_apptDate and apptTime = ip_apptTime;

    
end /​/
delimiter ;

-- [20] complete_orders()
-- -----------------------------------------------------------------------------
/* This stored procedure attempts to complete a certain number of orders based on the 
passed in value. Orders should be completed in order of their priority, from highest to
lowest. If multiple orders have the same priority, the older dated one should be 
completed first. Any completed orders should be removed from the system, and patients 
should be charged accordingly. Ensure that there is a non-null number of orders
passed in, and complete as many as possible up to that limit. */
-- -----------------------------------------------------------------------------
drop procedure if exists complete_orders;
delimiter /​/
create procedure complete_orders (
	in ip_num_orders integer
)
sp_main: begin
	declare completed_orders int default 0;
    declare top_order int;
    declare order_cost int;
    declare patient_funds int;
    declare ip_ssn char(11); 
    
	-- not null
		if ip_num_orders is null then
        leave sp_main;
        end if;
	
    -- while loop
		while completed_orders < ip_num_orders do
			select orderNumber into top_order from med_order order by priority desc, orderDate asc limit 1;
            select cost into order_cost from med_order where orderNumber = top_order;
            select patientId into ip_ssn from med_order where orderNumber = top_order;
            update patient set funds = funds - order_cost where ssn = ip_ssn; 
            delete from med_order where orderNumber = top_order;
			set completed_orders = completed_orders + 1;
		end while;
        
    
end /​/
delimiter ;
