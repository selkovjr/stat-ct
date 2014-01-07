-- swaps two nodes under a single parent

-- This function removes the branch in the second argument
-- and places it in front of the branch in the frist argument.

-- Both branches must belong to the same parent.

CREATE OR REPLACE FUNCTION move_to_the_left_of(int, int) RETURNS INT AS 
$body$
DECLARE
  pop RECORD;
  slide RECORD;
  node_to_pop ALIAS FOR $1;
  node_to_slide ALIAS FOR $2;
  branch_width INTEGER;
BEGIN
  -- 1. Remember the boundaries of the sliding node and the node being displaced
  -- SELECT left_id, right_id INTO slide FROM activity_clone WHERE id = 374;
  -- SELECT left_id, right_id INTO pop FROM activity_clone WHERE id = 373;
  SELECT INTO slide left_id, right_id 
    FROM activity_clone 
   WHERE id = node_to_slide;
  SELECT INTO pop left_id, right_id
    FROM activity_clone 
   WHERE id = node_to_pop;

  -- 2. Hide all left and right values on the branch to move by multiplying them by -1
  -- UPDATE activity_clone SET left_id = -left_id WHERE left_id >= slide.left_id AND right_id <= slide.right_id;
  -- UPDATE activity_clone SET right_id = -right_id WHERE right_id >= slide.left_id AND right_id <= slide.right_id;
  UPDATE activity_clone SET left_id = -left_id WHERE left_id >= slide.left_id AND right_id <= slide.right_id;
  UPDATE activity_clone SET right_id = -right_id WHERE right_id >= slide.left_id AND right_id <= slide.right_id;

  -- 3. Determine branch width: right_id - left_id + 1
  -- SELECT slide.right_id - slide.left_id + 1; -- (10)
  branch_width := slide.right_id - slide.left_id + 1;
    
  -- 4. Make space to insert the sliding branch BEFORE the popping node (and pop that node)
  -- UPDATE activity_clone SET left_id = left_id + 10 WHERE left_id BETWEEN  pop.left_id AND slide.left_id;
  -- UPDATE activity_clone SET right_id = right_id + 10 WHERE right_id BETWEEN pop.left_id AND slide.right_id;
  UPDATE activity_clone
     SET left_id = left_id + branch_width
   WHERE left_id BETWEEN  pop.left_id AND slide.left_id;
                                      -- ids to the right of the items being swapped do not change
  UPDATE activity_clone
     SET right_id = right_id + branch_width
   WHERE right_id BETWEEN pop.left_id AND slide.right_id;

  -- 5. Move the sliding node in place
  UPDATE activity_clone SET left_id = -left_id + pop.left_id - slide.left_id WHERE left_id < 0;
  UPDATE activity_clone SET right_id = -right_id + pop.left_id - slide.left_id WHERE right_id < 0;

  RETURN (1);
END;
$body$
LANGUAGE 'plpgsql';

stat=# SELECT * from activity_clone WHERE parent=81 or id=81;
 id  | parent | left_id | right_id | required | opt |         label         
-----+--------+---------+----------+----------+-----+-----------------------
 378 |     81 |      50 |       51 | f        | f   | Judgement, Insight
  81 |     14 |      49 |       64 | f        | f   | Maturity
 379 |     81 |      60 |       61 | f        | f   | Perseverance
 380 |     81 |      62 |       63 | f        | f   | Poise
  82 |     81 |      52 |       59 | f        | f   | Leadership & Teamwork
(5 rows)

