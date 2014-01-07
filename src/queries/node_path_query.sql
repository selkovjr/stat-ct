SELECT parent.label
FROM activity AS node, activity AS parent
WHERE node.left_id BETWEEN parent.left_id AND parent.right_id
AND node.label = 'Test for Air Leak'
ORDER BY node.left_id;

SELECT parent.label
FROM activity AS node, activity AS parent
WHERE node.left_id BETWEEN parent.left_id AND parent.right_id
AND node.id = 372
ORDER BY node.left_id;

-- this query determines whether the node is in the General category
SELECT label from (SELECT parent.label
FROM activity AS node, activity AS parent
WHERE node.left_id BETWEEN parent.left_id AND parent.right_id
AND node.id = 83
) AS parent WHERE label ~* 'general capabilities';
