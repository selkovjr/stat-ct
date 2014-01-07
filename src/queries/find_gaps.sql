-- this query lists gaps in the sequence of ids in activity_clone.id 
(SELECT 
  t1.neighbor AS "start", 
  MIN(t2.neighbor) AS "end" FROM (
    SELECT id + 1 AS neighbor
      FROM activity_clone tbl1 
     WHERE NOT EXISTS (
        SELECT * FROM activity_clone tbl2 
         WHERE tbl2.id = tbl1.id + 1
     )
     AND id <> (SELECT MAX(id) FROM activity_clone)
  ) t1
  INNER JOIN (
    SELECT id - 1 AS neighbor
      FROM activity_clone tbl1 
     WHERE NOT EXISTS(
        SELECT * FROM activity_clone tbl2 
         WHERE tbl1.id = tbl2.id + 1
     )
     AND id <> (SELECT MIN(id) FROM activity_clone)
  ) t2 
  ON t1.neighbor <= t2.neighbor
  GROUP BY t1.neighbor
  ORDER BY t1.neighbor
) 
UNION 
  SELECT max(id), NULL FROM activity_clone;

-- this query selects first available id (slow)
SELECT id - 1 AS id
  FROM activity_clone t1 
 WHERE NOT EXISTS(
    SELECT 1 FROM activity_clone t2
     WHERE t1.id = t2.id + 1
   )
   AND id <> 0
UNION
  SELECT max(id) FROM activity_clone
 LIMIT 1;

-- same as above but faster, with the caveat that it returns 
-- nothing when no gaps are found
SELECT id - 1 AS id
  FROM activity_clone t1 
 WHERE NOT EXISTS(
    SELECT 1 FROM activity_clone t2
     WHERE t1.id = t2.id + 1
   )
   AND id <> 0
 LIMIT 1;
 
