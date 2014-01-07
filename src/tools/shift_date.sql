BEGIN TRANSACTION;
UPDATE feedback SET "when" = "when" + (SELECT 'now' - max("timestamp") FROM "case")::interval;
UPDATE note SET "when" = "when" + (SELECT 'now' - max("timestamp") FROM "case")::interval;
UPDATE review SET "when" = "when" + (SELECT 'now' - max("timestamp") FROM "case")::interval;
UPDATE time_log SET "in" = "in" + (SELECT 'now' - max("out") FROM "time_log")::interval - '1 day'::interval, "out" = "out" + (SELECT 'now' - max("out") FROM "time_log")::interval - '1 day'::interval;
UPDATE "case" SET "date" = "date" + (SELECT 'now' - max("date")::timestamp FROM "case")::interval,  "timestamp" = "timestamp" + (SELECT 'now' - max("timestamp") FROM "case")::interval;
END TRANSACTION;
