-- ************** O V E R A L L ***************
SELECT id AS "Overall Assessment" from "case" WHERE false;

(
  SELECT CASE WHEN assessor = trainee THEN 'trainee' ELSE 'attending' END as role,
         min(assessment - 30),
         max(assessment - 30),
         to_char(avg(assessment - 30), '99D9') AS average,
         to_char(stddev(assessment - 30), '99D9') AS "SD",
         count(*)
    FROM eval, "case"
   WHERE eval."case" = "case".id
     AND eval.activity = 0
   GROUP BY role
)
UNION
SELECT 'both roles' as role,
       min(assessment - 30),
       max(assessment - 30),
       to_char(avg(assessment - 30), '99D9') AS average,
       to_char(stddev(assessment - 30), '99D9') AS "SD",
       count(*)
  FROM eval, "case"
 WHERE eval."case" = "case".id
   AND eval.activity = 0
 GROUP BY role;

-- --------------- S K I L L ------------------------
SELECT id as "Skill" FROM "case" WHERE false;

(
  SELECT CASE WHEN assessor = trainee THEN 'trainee' ELSE 'attending' END as role,
         min(assessment - 20),
         max(assessment - 20),
         to_char(avg(assessment - 20), '99D9') AS average,
         to_char(stddev(assessment - 20), '99D9') AS "SD",
         count(*)
    FROM eval, "case"
   WHERE eval."case" = "case".id
     AND eval.activity IN (
       SELECT t1.id
         FROM activity AS t1, activity AS t2
        WHERE t1.left_id BETWEEN t2.left_id AND t2.right_id
          AND t2.label ~* '^skill$'
     )
   GROUP BY role
)
UNION
SELECT 'both roles' as role,
       min(assessment - 20),
       max(assessment - 20),
       to_char(avg(assessment - 20), '99D9') AS average,
       to_char(stddev(assessment - 20), '99D9') AS "SD",
       count(*)
  FROM eval, "case"
 WHERE eval."case" = "case".id
   AND eval.activity IN (
     SELECT t1.id
       FROM activity AS t1, activity AS t2
      WHERE t1.left_id BETWEEN t2.left_id AND t2.right_id
        AND t2.label ~* '^skill$'
   )
 GROUP BY role;

-- --------------- K N O W L E D G E  ------------------------
SELECT id as "Knowledge" FROM "case" WHERE false;

(
  SELECT CASE WHEN assessor = trainee THEN 'trainee' ELSE 'attending' END as role,
         min(assessment - 20),
         max(assessment - 20),
         to_char(avg(assessment - 20), '99D9') AS average,
         to_char(stddev(assessment - 20), '99D9') AS "SD",
         count(*)
    FROM eval, "case"
   WHERE eval."case" = "case".id
     AND eval.activity IN (
       SELECT t1.id
         FROM activity AS t1, activity AS t2
        WHERE t1.left_id BETWEEN t2.left_id AND t2.right_id
          AND t2.label ~* '^knowledge.*understanding$'
     )
   GROUP BY role
)
UNION
SELECT 'both roles' as role,
       min(assessment - 20),
       max(assessment - 20),
       to_char(avg(assessment - 20), '99D9') AS average,
       to_char(stddev(assessment - 20), '99D9') AS "SD",
       count(*)
  FROM eval, "case"
 WHERE eval."case" = "case".id
   AND eval.activity IN (
     SELECT t1.id
       FROM activity AS t1, activity AS t2
      WHERE t1.left_id BETWEEN t2.left_id AND t2.right_id
        AND t2.label ~* '^knowledge.*understanding$'
   )
 GROUP BY role;

-- --------------- I N D E P E N D E N C E ------------------------
SELECT id as "Independence" FROM "case" WHERE false;

(
  SELECT CASE WHEN assessor = trainee THEN 'trainee' ELSE 'attending' END as role,
         min(assessment - 20),
         max(assessment - 20),
         to_char(avg(assessment - 20), '99D9') AS average,
         to_char(stddev(assessment - 20), '99D9') AS "SD",
         count(*)
    FROM eval, "case"
   WHERE eval."case" = "case".id
     AND eval.activity IN (
       SELECT t1.id
         FROM activity AS t1, activity AS t2
        WHERE t1.left_id BETWEEN t2.left_id AND t2.right_id
          AND t2.label ~* '^independence$'
     )
   GROUP BY role
)
UNION
SELECT 'both roles' as role,
       min(assessment - 20),
       max(assessment - 20),
       to_char(avg(assessment - 20), '99D9') AS average,
       to_char(stddev(assessment - 20), '99D9') AS "SD",
       count(*)
  FROM eval, "case"
 WHERE eval."case" = "case".id
   AND eval.activity IN (
     SELECT t1.id
       FROM activity AS t1, activity AS t2
      WHERE t1.left_id BETWEEN t2.left_id AND t2.right_id
        AND t2.label ~* '^independence$'
   )
 GROUP BY role;


-- --------------- S P E C I F I C ------------------------
SELECT id as "Specific" FROM "case" WHERE false;


  SELECT 'trainee' AS role,
         min(assessment - 10),
         max(assessment - 10),
         to_char(avg(assessment - 10), '99D9') AS average,
         to_char(stddev(assessment - 10), '99D9') AS "SD",
         count(*)
    FROM eval, "case"
   WHERE eval."case" = "case".id
     AND eval.assessment >= 10 AND eval.assessment <= 13
     AND assessor = trainee
     AND eval.activity IN (
       SELECT t1.id
         FROM activity AS t1, activity AS t2
        WHERE t1.left_id BETWEEN t2.left_id AND t2.right_id
          AND t2.id = "case".activity
     )
   GROUP BY role;

  SELECT 'attending' AS role,
         min(assessment),
         max(assessment),
         to_char(avg(assessment), '99D9') AS average,
         to_char(stddev(assessment), '99D9') AS "SD",
         count(*)
    FROM eval, "case"
   WHERE eval."case" = "case".id
     AND eval.assessment != -1
     AND assessor = attending
     AND eval.activity IN (
       SELECT t1.id
         FROM activity AS t1, activity AS t2
        WHERE t1.left_id BETWEEN t2.left_id AND t2.right_id
          AND t2.id = "case".activity
     )
   GROUP BY role;
