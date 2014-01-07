-- Second variant with SQL Server date/time functions 
SELECT t1.col1 AS startOfGap, min(t2.col1) AS endOfGap  
   FROM  
   (SELECT "in" + '1 day'::interval AS col1 FROM "time_log" tbl1  
      WHERE NOT EXISTS(SELECT * FROM "time_log" tbl2  
                  WHERE date_part('day', tbl1."in" - tbl2."in") = 1)
                    AND "id" = 'jenq'
     AND "in" <> (SELECT max("in") FROM "time_log")) t1 
   INNER JOIN  
   (SELECT "in" - '1 day'::interval AS col1 FROM "time_log" tbl1  
     WHERE NOT EXISTS(SELECT * FROM "time_log" tbl2  
                  WHERE date_part('day', tbl2."in" - tbl1."in") = 1) 
                    AND "id" = 'jenq'
     AND "in" <> (SELECT min("in") FROM "time_log")) t2  
    ON t1.col1 <= t2.col1 
    GROUP BY t1.col1 
    ORDER BY t1.col1; 


SELECT sum(gap) FROM (
  SELECT l1."out", cast(extract('epoch' FROM min(l2."in" - l1."out")) as integer) as gap 
  FROM time_log l1 INNER JOIN time_log l2
    ON l2."in" >= l1."out"
   AND l2."id" = l1."id"
   AND l1."id" = 'jenq'
 GROUP BY l1."out"
) AS gaps
  WHERE gap > 3*3600*24
;

SELECT l1."out", min(l2."in" - l1."out") as "gap"
  FROM time_log l1 INNER JOIN time_log l2
    ON l2."in" >= l1."out"
   AND l2."id" = l1."id"
   AND l1."id" = 'jenq'
 GROUP BY l1."out"
 ORDER BY l1."out"
;
    
