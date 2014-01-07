ALTER TABLE ONLY "activity" DROP CONSTRAINT "$1";

-- shift all ids to make room for "Overall"

-- 1. General was 19; Overall comes in front, so General becomes 20 and 
--    everything above shifts.
UPDATE activity SET id = -(id + 1), parent = CASE WHEN parent >= 19 THEN -(parent + 1) ELSE - parent END, left_id = -(left_id + 2), right_id = -(right_id + 2)
 WHERE id >= (SELECT id FROM activity WHERE label = 'General Capabilities')
   AND left_id >= (SELECT left_id FROM activity WHERE label = 'General Capabilities');

-- 2. Shift positions of all items preceding General, but leave their ids in place
UPDATE activity SET id = -id, parent = -parent, left_id = -(left_id + 2), right_id = -(right_id + 2)
 WHERE id between 2 AND (SELECT -id - 1 FROM activity WHERE label = 'General Capabilities');

-- 3. root and Common must be expanded on the right
UPDATE activity SET right_id = right_id + 2 WHERE id IN (0, 1);

-- 4. Flip sign everywhere
UPDATE activity SET id = -id, parent = -parent, left_id = -left_id, right_id = -right_id WHERE id < 0;

-- 5. Insert the Overall item
INSERT INTO activity VALUES (19, 1, 2, 3, 'f', 'f', 'Overall Assessment');

-- 6. General Capabilities must remain under Common (it was shifted in (1))
UPDATE activity SET parent = (SELECT id FROM activity WHERE label = 'Common') WHERE label = 'General Capabilities';

-- 8. restore self-reference
ALTER TABLE ONLY "activity" ADD CONSTRAINT "$1" FOREIGN KEY ("parent") REFERENCES "activity" ON UPDATE CASCADE;


-- 0...............................................................12029
--  1...Common....66 67................Specific...................12028
--                    68...Abdomen..281   ... ...Uncategorized...12027
--
-- 0..........................................................................12031
--  1...........Common..........68 69...........Specific.....................12030
--   2-Overall-3 4...General...67   70...Abdomen..283 ... ..................12029
