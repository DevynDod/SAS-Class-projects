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
    sum(case when a.grtype eq 9 then a.GRTOTLT else 0 end) as Total_graduates,
    calculated Total_graduates/ calculated Grand_Total as Total_grad_rate format percent8.,
	calculated Total_men_graduate/ calculated Total_men_students as Men_graduation_rate format percent8.,
	calculated Total_women_graduate/ calculated Total_women_students as Women_graduation_rate format percent8.,
	sum(case when a.grtype eq 16 then a.grtotlt else 0 end) as total_transfer_student,
	calculated total_transfer_student/ calculated Grand_Total as Transfer_student_percent format percent8.
	
	from IPEDGR.GR2021 a
	where a.grtype in (6,9,16)
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
create table HD2021 as 
	select
	d.unitid,
	d.obereg,
	d.hloffer
	
from IPEDICM.HD2021 d
where d.obereg in (1,2,3,4,5,6,7,8)
;
quit;



proc sql;
create table finaldata as 
	select a.*,
		   b.*,
		   c.*,
		   d.*
	
	
	from gr2021 a
	Left join sfa2021 b on a.unitid eq b.unitid
	left join sal2021 c on a.unitid eq c.unitid
	left join HD2021 d on  a.unitid eq d.unitid
;
quit;

/* Create a dataset like Blums */
proc format;
	value grad
	0-.4 = "Low Graduation Rate"
	.4-.69 = "Medium Graduation Rate"
	.69- High = "High Graduation Rate"
	;
run;

proc means data = finaldata q1 mean q3;
var total_grad_rate;
run;

data final_nograd;
	set finaldata;
	format Total_grad_rate grad.;
	grad_rate_cat = put(total_grad_rate, grad.);
	drop Women_graduation_rate Men_graduation_rate Total_men_graduate 
	Total_women_graduate Total_graduates;
	
run;


/* Should we use percentages or numbers? other columns need to add? */


/* start looking at building a model */

 

 
ODS GRAPHICS ON;
 
PROC HPSPLIT DATA= final_nograd(drop = total_grad_rate);
	class grad_rate_cat;
    MODEL grad_rate_cat = _numeric_  ;
    PRUNE costcomplexity;
    PARTITION FRACTION(VALIDATE=0.3 SEED=42);
    OUTPUT OUT = SCORED;
 
run;



/* Model number 2 */
proc transpose data=ipedgr.gr2021 out=gr2021B(rename=(col1=count));
  by unitid grtype;
  var grtotl:;
  where grtype in (6,9)/* and Unitid eq 206154*/;

run;

 
proc sort data=gr2021B;
  by unitid _label_ descending grtype /*count*/;
run;

data gr2021B;
  set gr2021B;
  by unitID _label_;
  _numerator=lag1(count);
  _gr_ = lag1(grtype);
  if last._label_ then do;
    Category = propcase(scan(_label_,2));
    Total_students = count;
    if count ne 0  and grtype eq 6 and _gr_ = 9 then rate = _numerator/count;
      else 
      	if grtype = _gr_  then rate = -1;
      	else
      		if count eq 0 or _numerator eq 0 then rate = -2;
      		else
      		  rate = .;
    output;
  end;
  drop _: count grtype;
  /*format rate grad.;*/
run;
/*Make a column that has the grad rate numbers*/

/*proc freq data = gr2021B;
table grtype;
run;*/



proc sql;
create table finalb as
select
	a.*,
	b.total_transfer_student,
	b.Transfer_student_percent,
	c.*,
	d.*,
	e.*
	
	
	
	
	from GR2021B a
	left join GR2021 b on a.unitid eq b.unitid
	left join SFA2021 c on a.unitid eq c.unitid
	left join SAL2021 d on a.unitid eq d.unitid
	left join HD2021 e on a.unitid eq e.unitid
	where rate gt 0 and total_staff ne . and staff_women ne . and staff_men ne .
;
quit;



ods graphics off;

 /*Category Fallco_outstateTuit Fallco_stateTuit hloffer num_any_aid 
 number_undergradstud_aid obereg sal_out_12menavg rate sal_out_12womavg 
 sal_outlay_12avg staff_men staff_women status stud_num_loan tot_pell_aid 
 tot_stud_pellg total_amt_loans total_staff Total_Students Total_transfer_student 
 total_undergrad_aid Transfer_student_percent unitid*/


data finaldata;
  set finalb;
  where category in ('Men', 'Women');
  if category = 'Men' then category_numeric = 1;
  else if category = 'Women' then category_numeric = 2;
  drop unitid;
  
run;

proc means data = finaldata missing;
var  _numeric_;
run;

proc freq data = finaldata;
table total_staff;
run;

proc corr data = finalb;
var total_staff staff_men staff_women;
run;

proc glmselect data=finaldata;
  class category_numeric;
  model rate = Fallco_outstateTuit Fallco_stateTuit hloffer num_any_aid number_undergradstud_aid
   obereg sal_out_12menavg sal_out_12womavg sal_outlay_12avg staff_men staff_women 
   stud_num_loan tot_pell_aid tot_stud_pellg total_amt_loans total_staff Total_students
   Total_transfer_student total_undergrad_aid Transfer_student_percent
   / selection = stepwise(select=sl slstay=0.05 slentry=0.05 choose=sbc);
   
run;


proc logistic data=finalb;
  where category in ('Men', 'Women');
  class category;
  format rate grad.;
  model rate = _numeric_ / link=glogit;
run;


/*Work on our logistic model gotta change the rate to be ordinal(1,2,3) and look at
adjacent values.

Get rid of rate as a predictor and UnitID maybe take out how we are splitting rate.

Maybe possible feature engineering*/














