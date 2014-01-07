-- appends a single (empty) node to another node in argument
CREATE OR REPLACE FUNCTION append_node_to(int) RETURNS INT AS
$body$
DECLARE
    targetparent RECORD;
    parent_node ALIAS FOR $1;
    new_id INTEGER;
    new_left_id INTEGER;
    new_right_id INTEGER;
BEGIN
    -- remember the original range of the target node
    SELECT INTO targetparent id, left_id, right_id 
           FROM activity_clone 
           WHERE id = parent_node;

    -- move the right_id of all elements FOLLOWING and
    -- INCLUDING the target node off by branch width (which is 1 + 1)
    UPDATE activity_clone SET right_id = right_id + 2
           WHERE right_id >= targetparent.right_id;

    -- move the left_id of all elements FOLLOWING the
    -- target node by branch width
    UPDATE activity_clone SET left_id = left_id + 2
           WHERE left_id > targetparent.right_id;

    -- assign the new range for the item being inserted
    new_left_id := targetparent.right_id;  -- replaces parent in post-order
    new_right_id := targetparent.right_id + 1; -- sets the range (1 new element)

    -- assign new id
    SELECT INTO new_id (SELECT max(id)+1 FROM activity_clone);

    -- insert and link to parent
    INSERT INTO activity_clone
           (id, parent, left_id, right_id) VALUES
           (new_id, targetparent.id, new_left_id, new_right_id);

    RETURN (new_id);
END;
$body$
LANGUAGE 'plpgsql';

-- appends a subtree in copy_buffer to a node in argument
CREATE OR REPLACE FUNCTION append_buffer_to(int) RETURNS INT AS 
$body$
DECLARE
    parent_node ALIAS FOR $1;
    parent_right_id INTEGER;
    old_left_id INTEGER;
    offset INTEGER;
    branch_width INTEGER;
BEGIN
    -- remember the original range of the target node
    SELECT INTO parent_right_id right_id FROM activity_clone WHERE id = parent_node;

    -- determine branch width: right_id - left_id + 1
    SELECT INTO branch_width (SELECT max(right_id) - min(left_id) + 1 FROM copy_buffer);
    
    -- remember the old left_id of the branch
    SELECT INTO old_left_id (SELECT min(left_id) FROM copy_buffer);

    -- reparent the branch
    UPDATE copy_buffer SET parent = parent_node WHERE left_id = old_left_id;

    -- calculate the amount by which the entire branch in buffer must be shifted
    offset := old_left_id - parent_right_id;

    -- shift the branch
    UPDATE copy_buffer SET left_id = left_id - offset;
    UPDATE copy_buffer SET right_id = right_id - offset;

    -- shift nodes following the target node and expand the target node
    UPDATE activity_clone SET right_id = right_id + branch_width 
           WHERE right_id >= parent_right_id;
    UPDATE activity_clone SET left_id = left_id + branch_width
           WHERE left_id > parent_right_id;

    -- insert the buffer
    INSERT INTO activity_clone SELECT * FROM copy_buffer;

    -- clean up the mess left by a kludge in Util::next_available_id()
    DELETE FROM activity_clone WHERE parent = -1;

    -- make sure data in copy_buffer will not be used again
    DROP TABLE copy_buffer;

    RETURN (1);
END;
$body$
LANGUAGE 'plpgsql';
