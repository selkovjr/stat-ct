
 SELECT count(*), c1.activity, c1.date, c1.case_no, c1.trainee, c1.attending INTO tmp FROM "case" c1, "case" c2 WHERE c1.activity = c2.activity AND c1.date = c2.date AND c1.case_no = c2.case_no AND c1.trainee = c2.trainee AND c1.attending = c2.attending GROUP BY c1.activity, c1.date, c1.case_no, c1.trainee, c1.attending ORDER BY date;

SELECT activity, date, case_no, trainee, attending into paired from tmp where count > 1;

 SELECT activity, date, case_no, trainee, attending into unpaired from tmp where count = 1;


 DROP TABLE tmp ;
