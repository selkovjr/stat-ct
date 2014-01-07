(
  SELECT role, person, min(time), max(time), avg(time)::smallint AS "average time", count(*)
    FROM how_long, survey
   WHERE survey.user = person
   GROUP BY role, person
)
UNION 
SELECT 'BOTH ROLES', 'ALL TOGETHER', min(time), max(time), avg(time)::smallint AS "average time", count(*)
  FROM how_long order by "average time";

(
  SELECT role, min(time), max(time), avg(time)::smallint AS "average time", count(*)
    FROM how_long, survey
   WHERE survey.user = person
   GROUP BY role
)
UNION 
SELECT 'BOTH ROLES', min(time), max(time), avg(time)::smallint AS "average time", count(*)
  FROM how_long order by "average time";

(SELECT role, min(time), max(time), avg(time)::smallint AS "average time", stddev(time)::smallint AS "SD", count(person) FROM how_long, "user" WHERE "user".id = person GROUP BY role) UNION SELECT 'both roles', min(time), max(time), avg(time)::smallint as "average time", stddev(time)::smallint AS "SD", count(*) FROM how_long order by "average time";
