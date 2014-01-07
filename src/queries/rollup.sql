CREATE OR REPLACE FUNCTION rollup(int, int) RETURNS record AS
$body$
DECLARE
  category ALIAS FOR $1;
  assessment_id ALIAS FOR $2;
  result record;
BEGIN
  IF category = 0 THEN
    SELECT INTO result (assessment - rating_map.low)::float
      FROM eval, "case", rating_map
     WHERE "case" = assessment_id
       AND "case".id = eval.case
       AND eval.activity = 0
       AND rating_map.role = 
           CASE
             WHEN "case".assessor = "case".trainee THEN 'trainee'
             ELSE 'attending'
           END
       AND rating_map.subtree = 'Overall Case Assessment';
  ELSE
    SELECT INTO result to_char(avg(eval.assessment - rating_map.low), '99D99')::float AS avg, count(*) AS count
     FROM eval, "case", rating_map
    WHERE eval.case = assessment_id
      AND "case".id = eval.case
      AND rating_map.role = 
        CASE
          WHEN "case".assessor = "case".trainee THEN 'trainee'
          ELSE 'attending'
        END
      AND rating_map.subtree = 
        CASE
          WHEN eval.activity IN (
              SELECT t2.id
                FROM activity AS t1, activity AS t2
               WHERE t2.left_id BETWEEN t1.left_id AND t1.right_id
                 AND t1.label = 'General Capabilities'
            ) THEN 'General Capabilities'
          WHEN eval.activity = 0 THEN 'Overall Case Assessment'
          ELSE 'root'
        END
      AND eval.activity IN (
        SELECT t2.id
          FROM activity AS t1, activity AS t2
         WHERE t2.left_id BETWEEN t1.left_id AND t1.right_id
           AND t1.id = category
      )
      AND eval.assessment >= 0;
  END IF;
  RETURN result;
END;
$body$
LANGUAGE 'plpgsql';
