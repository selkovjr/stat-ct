
--
-- Name: assessment_rollup(integer, integer); Type: FUNCTION; Schema: public; Owner: stat
--

CREATE FUNCTION specific_assessment_rollup_by_label(text, integer) RETURNS record
    AS $_$
DECLARE
  category ALIAS FOR $1;
  assessment_id ALIAS FOR $2;
  result record;
BEGIN

  SELECT INTO result to_char(avg(eval.assessment - rating_map.low), '99D99')::float AS avg, count(*) AS count
   FROM eval, "case", rating_map
  WHERE eval.case = assessment_id
    AND "case".id = eval.case
    AND rating_map.role = 
      CASE
        WHEN "case".assessor = "case".trainee THEN 'trainee'
        ELSE 'attending'
      END
    AND rating_map.subtree = 'Specific'
    AND eval.activity IN (
      SELECT t4.id
        FROM activity AS t1, activity AS t2, activity AS t3, activity AS t4
       WHERE t4.left_id BETWEEN t3.left_id AND t3.right_id
         AND t3.label = category
         AND t3.parent = t2.id
	 AND t2.parent = t1.id
	 AND t1.parent = 2 -- Specific
    )
    AND eval.assessment >= 0;

  RETURN result;
END;
$_$
    LANGUAGE plpgsql;
