SELECT repeat('  '::text, count(t2.label)::integer - 1) AS indent,
       t1.label AS label,
       t1.required AS required,
       t1.opt AS opt
   FROM activity_clone AS t1, activity_clone AS t2, activity_clone AS t3
  WHERE t1.left_id BETWEEN t2.left_id AND t2.right_id
    AND t2.left_id BETWEEN t3.left_id AND t3.right_id
    AND t3.id = 0
  GROUP BY t1.label, t1.left_id, t1.required, t1.opt
  ORDER BY t1.left_id;
);
 
SELECT t1.id, t1.required, t1.opt, t1.label
  FROM activity_clone AS t1, activity_clone AS t2, activity_clone AS t3
  WHERE t1.left_id BETWEEN t2.left_id AND t2.right_id
    AND t2.left_id BETWEEN t3.left_id AND t3.right_id
    AND t3.parent = 14
    AND t3.id != 0
  GROUP BY t1.label, t1.left_id, t1.id, t1.required, t1.opt
  ORDER BY t1.left_id;
