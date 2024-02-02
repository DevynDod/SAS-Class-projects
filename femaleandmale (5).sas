/*Freq table just to helpe give a peak at the data we are looking at */
proc freq data= IPEDGR.GR2021;
 table unitid*grtype;
 where grtype = 16;
run;



/* This is my final table*/

/*All instructional staff total*/


/* This is a table that I just mess around to use*/
proc sql;
create table gr2021 as
    select
    a.unitid,
    sum(case when a.grtype eq 6 then a.GRTOTLT else 0 end) as Grand_Total,
    sum(case when a.grtype eq 6 then a.grtotlm else 0 end) as Total_men_students,
    sum(case when a.grtype eq 6 then a.grtotlw else 0 end) as Total_women_students,
    sum(case when a.grtype eq 9 then a.GRTOTLM else 0 end) as Total_men_graduate,
    sum(case when a.grtype eq 9 then a.GRTOTLW else 0 end) as Total_women_graduate,
    calculated Total_men_graduate + calculated Total_women_graduate as Total_graduate,
    calculated Total_graduate/ calculated Grand_Total as Total_grad_rate format percent8.,
	calculated Total_men_graduate/ calculated Total_men_students as Men_graduation_rate format percent8.,
	calculated Total_women_graduate/ calculated Total_women_students as Women_graduation_rate format percent8.,
	sum(case when a.grtype eq 16 then a.grtotlt else 0 end) as total_transfer_student,
	calculated total_transfer_student/ calculated Grand_Total as Transfer_student_percent format percent8.
	
	from IPEDGR.GR2021 a
	group by 1
;
quit;


proc sql;
create table sfa2021 as
    select
    b.unitid,
    b.SCFA12N as Fallco_stateTuit,
	b.SCFA13P as Fallco_outstateTuit,
	b.UAGRNTN as number_undergradstud_aid,
	b.UAGRNTT as total_undergrad_aid,
	b.UPGRNTN as tot_stud_pellg,
	b.UPGRNTT as tot_pell_aid,
	b.UFLOANN as stud_num_loan,
	b.UFLOANT as total_amt_loans,
	b.ANYAIDN as num_any_aid
	
	from IPEDSFA.SFA2021 b
;
quit;

proc sql;
create table sal2021 as
    select
    c.unitid,
  sum(case when c.arank eq 7 then c.SAINSTT else 0 end) as total_staff,
	sum(case when c.arank eq 7 then c.SAINSTM else 0 end) as staff_men,
	sum(case when c.arank eq 7 then c.SAINSTW else 0 end) as staff_women,
	sum(case when c.arank eq 7 then c.SA12MAT else 0 end) as sal_outlay_12avg,
	sum(case when c.arank eq 7 then c.SA12MAM else 0 end) as sal_out_12menavg,
	sum(case when c.arank eq 7 then c.SA12MAW else 0 end) as sal_out_12womavg
	
	from IPEDSAL.SAL2021_IS c
	group by 1
;
quit;





proc sql;
create table finaldata as 
	select a.*,
		   b.*,
		   c.*
	
	
	from gr2021 a
	Left join sfa2021 b on a.unitid eq b.unitid
	left join sal2021 c on c.unitid eq a.unitid
;
quit;


/* Should we use percentages or numbers? other columns need to add? */


/* start looking at building a model */

PROC DTREE options ;
EVALUATE / options ;
MODIFY specifications ;
MOVE specifications ;
QUIT ;
RECALL ;
RESET options ;
SAVE ;
SUMMARY / options ;
TREEPLOT / options ;
VARIABLES / options ;
VPC specifications ;
VPI specifications ;





