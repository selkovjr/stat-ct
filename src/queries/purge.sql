DELETE from remark;
DELETE from review;
DELETE from activity_change_log WHERE version > 0;
UPDATE activity_change_log SET "when" = 'now';
SELECT setval('activity_log_seq', 1);
SELECT setval('case_id_seq', 1);
DELETE FROM case_to_ignore;
DELETE FROM copy_buffer;
DELETE from "case";
DROP SEQUENCE surgeon_seq;
DELETE FROM feedback;
DELETE FROM note;
DELETE FROM survey;
DELETE FROM activity;