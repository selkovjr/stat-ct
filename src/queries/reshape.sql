-- alter all constraints to allow cascading of updates into data tables
ALTER TABLE ONLY "case" DROP CONSTRAINT "$1";
ALTER TABLE ONLY "case" ADD CONSTRAINT "$1" FOREIGN KEY ("activity") REFERENCES "activity"("id") ON UPDATE CASCADE;
ALTER TABLE ONLY "eval" DROP CONSTRAINT "$1";
ALTER TABLE ONLY "eval" ADD CONSTRAINT "$1" FOREIGN KEY ("activity") REFERENCES "activity"("id") ON UPDATE CASCADE;
ALTER TABLE ONLY "note" DROP CONSTRAINT "$1";
ALTER TABLE ONLY "note" ADD CONSTRAINT "$1" FOREIGN KEY ("activity") REFERENCES "activity"("id") ON UPDATE CASCADE;
ALTER TABLE ONLY "feedback" DROP CONSTRAINT "$1";
ALTER TABLE ONLY "feedback" ADD CONSTRAINT "$1" FOREIGN KEY ("activity") REFERENCES "activity"("id") ON UPDATE CASCADE;

ALTER TABLE ONLY "activity" DROP CONSTRAINT "$1";

-- shift all ids to make room for "Specific"

-- 1. Shift only ids in Common, leaving positions as they are
UPDATE activity SET id = -(id + 1), parent = -(parent + 1), left_id = -left_id, right_id = -right_id
 WHERE left_id BETWEEN
 (SELECT left_id + 1 FROM activity WHERE label = 'Common') AND
 (SELECT right_id - 1 FROM activity WHERE label = 'Common');

-- 2. Shift the ids and positions for everything following Common
UPDATE activity
  SET id = -(id + 1), parent = -(parent + 1), left_id = -(left_id + 1), right_id = -(right_id + 1) 
WHERE left_id > (SELECT right_id FROM activity WHERE label = 'Common');

-- 3. Reparent all children of root to the yet non-existent Specific, changing sign of all ids
UPDATE activity SET id = -id, parent = 2, left_id = -left_id, right_id = -right_id WHERE parent = -1;

-- 4. Flip sign everywhere else
UPDATE activity SET id = -id, parent = -parent, left_id = -left_id, right_id = -right_id WHERE id < 0;

-- 5. root must be expanded on the right
UPDATE activity SET right_id = right_id + 2 WHERE id = 0;

-- 6. General Capabilities must remain under Common (it was shifted in (1))
UPDATE activity SET parent = (SELECT id FROM activity WHERE label = 'Common') WHERE label = 'General Capabilities';

-- 7. Finally, insert the new node for Specific (after Common)
INSERT INTO activity VALUES (2, 0, (SELECT right_id + 1 FROM activity WHERE id = 1), (SELECT right_id - 1 FROM activity WHERE id = 0), 'f', 'f', 'Specific');

-- 8. restore self-reference
ALTER TABLE ONLY "activity" ADD CONSTRAINT "$1" FOREIGN KEY ("parent") REFERENCES "activity" ON UPDATE CASCADE;

-- 0.............................................................12027
--  1...Common....66 67...Abdomen..280   ...  ...Uncategorized..12026
--   2..General..65
--
-- 0...............................................................12029
--  1...Common....66 67................Specific...................12028
--                    68...Abdomen..281   ... ...Uncategorized...12027
--
