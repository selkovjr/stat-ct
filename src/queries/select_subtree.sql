-- select a subtree
SELECT t1.*
   FROM activity AS t1, activity AS t2
  WHERE t1.left_id BETWEEN t2.left_id AND t2.right_id
    AND t2.id = 79;

-- select an entire tree as indented text
SELECT repeat('  '::text, count(t2.label)::integer - 1) || t1.label AS node
   FROM activity AS t1, activity AS t2
  WHERE t1.left_id BETWEEN t2.left_id AND t2.right_id
  GROUP BY t1.label, t1.left_id
  ORDER BY t1.left_id;

-- select a subtree as indented text
SELECT repeat('  '::text, count(t2.label)::integer - 1) || t1.label AS node
   FROM activity AS t1, activity AS t2, activity AS t3
  WHERE t1.left_id BETWEEN t2.left_id AND t2.right_id 
    AND t2.left_id BETWEEN t3.left_id AND t3.right_id
    AND t3.id = 79
  GROUP BY t1.label, t1.left_id
  ORDER BY t1.left_id;

-- select a subtree as indented text (version 2)
SELECT count(t2.label), t1.label AS node
   FROM activity AS t1, activity AS t2, activity AS t3 
  WHERE t1.left_id BETWEEN t2.left_id AND t2.right_id 
    AND t2.left_id BETWEEN t3.left_id AND t3.right_id
    AND t3.id = 79
  GROUP BY t1.label, t1.left_id
  ORDER BY t1.left_id;

