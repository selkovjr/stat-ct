-- this funciton simply deletes the nodes
CREATE OR REPLACE FUNCTION deleteSubtree(BIGINT) RETURNS INTEGER AS '
DECLARE r RECORD ;
BEGIN
  SELECT INTO r * FROM activity_clone WHERE id = $1;
  DELETE FROM NestedSet
  WHERE left_id BETWEEN r.left_id AND r.right_id;
  RETURN 1;
END;
' LANGUAGE 'plpgsql';

-- this function closes gaps in left and right ids
CREATE OR REPLACE FUNCTION closeGap(BIGINT) RETURNS INTEGER AS '
DECLARE r RECORD;
BEGIN
  SELECT INTO r * FROM activity_clone WHERE id = $1;
  UPDATE activity_clone
  SET
  left_id = CASE
    WHEN left_id > r.left_id
    THEN left_id - (r.right_id - r.left_id 1 )
  ELSE left_id END,
  right_id = CASE
    WHEN right_id > r.left_id
    THEN right_id - (r.right_id - r.left_id 1 )
  ELSE right_id END;
RETURN 1;
END;
' LANGUAGE 'plpgsql';

-- this one does both things at once
CREATE OR REPLACE FUNCTION delete_subtree(int) RETURNS INT AS '
DECLARE
  node_to_delete ALIAS FOR $1;
  victim         RECORD;
  branch_width   INTEGER;
BEGIN
  SELECT INTO victim id, left_id, right_id 
    FROM activity_clone 
   WHERE id = node_to_delete;

  DELETE FROM activity_clone 
   WHERE left_id >= victim.left_id
     AND right_id <= victim.right_id;

  branch_width := victim.right_id - victim.left_id + 1;

  UPDATE activity_clone SET left_id = left_id - branch_width
   WHERE left_id > victim.left_id;

  UPDATE activity_clone SET right_id = right_id - branch_width
   WHERE right_id > victim.right_id;

  RETURN(0);
END;
' LANGUAGE 'plpgsql';

-- this function deletes the parent and re-parents its children
CREATE OR REPLACE FUNCTION reparent(int) RETURNS int AS
$body$
DECLARE
  parent_id ALIAS FOR $1;
  victim RECORD;
BEGIN
  SELECT INTO victim parent, left_id, right_id 
    FROM activity_clone 
   WHERE id = parent_id;

  DELETE FROM activity_clone 
   WHERE id = parent_id;
 
  -- The following 2 queries update the children
  UPDATE activity_clone SET left_id = left_id - 1, parent = victim.parent
   WHERE left_id >= victim.left_id
     AND right_id < victim.right_id;
  UPDATE activity_clone SET right_id = right_id - 1, parent = victim.parent
   WHERE left_id >= victim.left_id
     AND right_id < victim.right_id;

  -- The following 2 queries update the rest of the tree
  UPDATE activity_clone SET left_id = left_id - 2
   WHERE left_id > victim.right_id;
  UPDATE activity_clone SET right_id = right_id - 2
   WHERE right_id > victim.right_id;

  RETURN(0);
END;
$body$
LANGUAGE 'plpgsql';
