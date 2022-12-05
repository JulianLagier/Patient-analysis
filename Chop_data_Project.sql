--Check encounters after July 15 1999
select *
from encounters as e
where start > '19990715 00:00:00.000';

--Select patients that are between 19 and 35 at the time of encounter
select e.patient, e.start,p.birthdate,(e.start-p.birthdate)/365 AS Age_at_encounter
from encounters as e
inner join patients as p
	on e.patient = p.id
where (e.start-p.birthdate)/365 BETWEEN 19 and 35;

--Select patients that went in for Drug Overdose
select *
from encounters
where description LIKE '%Drug%';


--Medications
select patient, count(description) as COUNT_CURRENT_MEDS
from medications
group by patient;


--Opiods Medications
select patient, description
from medications
where description LIKE '%Hydromorphone%' OR description LIKE '%Fentanyl 100 MCG%' or description LIKE '%Oxycodone-acetaminophen%';

--MAIN QUERY
select p.first, p.last, e.start,e.description,p.deathdate,(e.start-p.birthdate)/365 as Age_at_encounter, o.Meds_Taken,o.num_of_meds, o.current_opioid_ind,
	start - lag(e.stop) over (partition by e.patient order by e.stop) as days_to_readmission,
	
	CASE WHEN start - lag(e.stop) over (partition by e.patient order by e.stop) <= 30 THEN 1
		 WHEN start - lag(e.stop) over (partition by e.patient order by e.stop) >= 30 THEN 0
		 END AS THIRTY_DAY_READMISSION,
	
	CASE WHEN start - lag(e.stop) over (partition by e.patient order by e.stop) <= 90 THEN 1
		 WHEN start - lag(e.stop) over (partition by e.patient order by e.stop) >= 90 THEN 0
		 END AS NINETY_DAY_READMISSION, 
	
	CASE WHEN e.stop = p.deathdate THEN 1
		 WHEN e.stop != p.deathdate THEN 0
		 END AS DEATH_AT_VISIT_IND

from encounters as e

left join patients as p
	on e.patient = p.id

left join (WITH all_meds as 
					(
					SELECT patient, STRING_AGG(distinct m.description,'/') as Meds_Taken
					FROM medications as m
					WHERE STOP IS NULL
					group by m.patient
				     )
			SELECT distinct medications.patient, Meds_Taken, (LENGTH(Meds_Taken) - LENGTH(REPLACE(Meds_Taken, '/', ''))) +1 as Num_of_meds,
				CASE WHEN all_meds.Meds_Taken LIKE '%Hydromorphone%' THEN 1
					 WHEN all_meds.Meds_Taken LIKE '%Fentanyl 100 MCG%' THEN 1
					 WHEN all_meds.Meds_Taken LIKE '%Oxycodone%' THEN 1
					 WHEN all_meds.Meds_Taken LIKE '%Acetaminophen%' THEN 1
					 ELSE 0
				END AS current_opioid_ind
			from medications
			inner join all_meds
				on medications.patient = all_meds.patient
			where medications.stop IS NULL)as o

	on e.patient = o.patient

where start > '19990715 00:00:00.000' AND description LIKE '%Drug%' AND (e.start-p.birthdate)/365 BETWEEN 19 and 35

order by start;

--Opioids
select patient,
	CASE WHEN description LIKE '%Hydromorphone%' THEN 1
		 WHEN description LIKE '%Fentanyl 100 MCG%' THEN 1
		 WHEN description LIKE '%Oxycodone-acetaminophen%' THEN 1
		 ELSE 0
	END AS current_opioid_ind
from medications;

 --Create test to see how string_Add would do
CREATE TABLE TEST (
	id varchar(60),
	name varchar(60),
	info varchar(60)
	);

INSERT INTO TEST VALUES (1,'joe','big joe'),(2,'Mary','pretty Mary');

SELECT STRING_AGG(name, info)
from test;

--Get all medications taken into one row and make it a CTE to join the other query to get all id's of 
WITH all_meds as (
					SELECT patient, STRING_AGG(m.description,'/') as Meds_Taken
					FROM medications as m
					group by m.patient
				 )
SELECT distinct medications.patient, Meds_Taken, (LENGTH(Meds_Taken) - LENGTH(REPLACE(Meds_Taken, '/', ''))) +1 as Num_of_meds,
	CASE WHEN all_meds.Meds_Taken LIKE '%Hydromorphone%' THEN 1
		 WHEN all_meds.Meds_Taken LIKE '%Fentanyl 100 MCG%' THEN 1
		 WHEN all_meds.Meds_Taken LIKE '%Oxycodone%' THEN 1
		 WHEN all_meds.Meds_Taken LIKE '%Acetaminophen%' THEN 1
		 ELSE 0
	END AS current_opioid_ind
from medications
inner join all_meds
	on medications.patient = all_meds.patient
where medications.stop IS NULL;

--Get a count of All medications by counting the amount of '/' plus +1
WITH all_meds as (
					SELECT patient, STRING_AGG(m.description,'/') as Meds_Taken
					FROM medications as m
					group by m.patient)
SELECT patient, (LENGTH(Meds_Taken) - LENGTH(REPLACE(Meds_Taken, '/', '')))+1 as Num_of_meds
from all_meds;

--90 day readmission
SELECT patient, start, stop,  start - lag(stop) over (partition by patient order by stop) as days_to_readmission
FROM encounters as e
inner join patients as p
	on e.patient = p.id
where start > '19990715 00:00:00.000' AND description LIKE '%Drug%' AND (e.start-p.birthdate)/365 BETWEEN 19 and 35;















