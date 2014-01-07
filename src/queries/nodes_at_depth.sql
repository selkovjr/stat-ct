SELECT node.label, (count(parent.label) - 1) AS depth
  FROM activity AS node, activity AS parent
 WHERE node.left_id BETWEEN parent.left_id AND parent.right_id
 GROUP BY node.label, node.left_id
 ORDER BY depth, node.left_id;
