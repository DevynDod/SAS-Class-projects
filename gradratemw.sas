%let path=/Data1/IPEDSData/DataFiles/GraduationRates-GR;
%let libraryName=IPEDGR;
libname &libraryName "&path/SASData";

options fmtsearch=(&libraryName);

options validvarname=v7;

/*Dr. Blums Code*/
proc transpose data=ipedgr.gr2021 out=grdrtmw(rename=(col1=count));
  by unitid grtype;
  var grtotl:;
  where grtype in (8,9);
run;

proc sort data=grdrtmw out=grdrtmws;
  by unitid _label_ count;
run;

data grdrtmw1;
  set grdrtmws;
  by unitID _label_;
  _numerator=lag1(count);
  if last._label_ then do;
    Category = propcase(scan(_label_,2));
    if count ne 0 then rate = _numerator/count;
      else rate = .;
    output;
  end;
  drop _: count grtype;
run;

data sal2021_is;
 set ipedsal.sal2021_is;
 where arank = 7;
 keep unitid saoutlt satotlt;
run;

data grdrtsm;
merge grdrtmw1(in=a) ipedicm.ic2021_ay(in=b) sal2021_is(in=c) ipedsfa.sfa2021(in=d) ipedicm.hd2021(in=e) ipedicm.ic2021(in=f);
by unitid;
if a and b and c and d and e and f;
drop x:;
run;

proc format;
value obereg  
0='U.S. Service schools' 
1,2='New England and Mid East' 
3,4='Great Lakes and Plains' 
5='Southeast (AL, AR, FL, GA, KY, LA, MS, NC, SC, TN, VA, WV)' 
6='Southwest (AZ, NM, OK, TX)' 
7='Rocky Mountains (CO, ID, MT, UT, WY)' 
8='Far West (AK, CA, HI, NV, OR, WA)' 
9='Other U.S. jurisdictions (AS, FM, GU, MH, MP, PR, PW, VI)'
;

value pubpriv
 1 = 'Public'
 2,3,4 = 'Private'
 ;
run;


data grdrtsm1;
 set grdrtsm;
 where not missing(tuition2) and uagrnta ne . and upgrnta ne . and ufloana ne .;
 
 instate = tuition2 + fee2;
 outstate = tuition3 + fee3;
 
 AvgSalOut = saoutlt/satotlt;
 AvgGrant = uagrnta;
 AvgPell = upgrnta;
 AvgFed = ufloana;
 
 obereg2 = put(obereg,obereg.);
 cntlaffi2 = put(cntlaffi,pubpriv.);
  
 keep unitid rate category instate outstate AvgSalOut AvgGrant AvgPell AvgFed obereg obereg2 cntlaffi cntlaffi2;
run;

proc standard data=grdrtsm1 mean=0 std=1 out=grdrtstd;
var instate outstate avgsalout avggrant avgpell avgfed;
run;

proc means data=grdrtstd;
run;

proc glm data=grdrtstd;
  where category in ('Men','Women') and obereg not in (0 9);
  class category obereg2 cntlaffi2;
  model rate = category|instate|outstate|avgsalout|avggrant|avgpell|avgfed|obereg2|cntlaffi2 @2;
    lsmeans obereg2 category cntlaffi2 / adjust=tukey diff lines;
run;

/*-----------Models------------*/

/*Proc glm with rate as the response and category(M/W) In-state tuition and fees, Out of State tuition and fees
Avg Salary Outlay for Number of full-time, non-medical, instructional staff - total as of November 1, on 9, 10, 11 or 12 month contract.
Avg Grant, Pell Grant and Fed monies awarded in financial aid...no cross products 
- standardized the quant variables around the means.*/
proc glm data=grdrtstd;
 where category in ('Men', 'Women') and obereg not in (0 9);
 class category;
 model rate = category instate outstate avgsalout avggrant avgpell avgfed;
 lsmeans category / diff cl;
run;

/*Remove instate and avggrant*/
proc glm data=grdrtstd;
 where category in ('Men', 'Women') and obereg not in (0 9);
 class category;
 model rate = category outstate avgsalout avgpell avgfed / solution;
 lsmeans category / diff cl;
run;

/*Proc glmselect using only standardized quant variables with cross products and stepwise selection.*/
proc glmselect data=grdrtstd;
 where category in ('Men','Women') and obereg not in (0 9);
 class category;
 model rate = category|instate|outstate|avgsalout|avggrant|avgpell|avgfed @2/
 selection=stepwise(select=sl slentry=0.1 slstay=0.1);
run;

/*Proc glm using standardized quant variables with cross products and slices on the categorical variables of 
M/W and geographic regions (obereg) not including service schools or outlying areas*/
proc glm data=grdrtstd;
  where category in ('Men','Women') and obereg not in (0 9);
  class category obereg2;
  model rate = category|instate|outstate|avgsalout|avggrant|avgpell|avgfed|obereg2 @2 / solution;
    lsmeans category*obereg2 / slice=category slice=obereg2 ;
run;

proc glmselect data=grdrtstd;
 where category in ('Men','Women') and obereg not in (0 9);
 class category obereg2;
 model rate = category|instate|outstate|avgsalout|avggrant|avgpell|avgfed|obereg2 @2/
 selection=stepwise(select=sl slentry=0.1 slstay=0.1);
run;

/**Remove avggrant**/
proc glmselect data=grdrtstd;
 where category in ('Men','Women') and obereg not in (0 9);
 class category obereg2;
 model rate = category|instate|outstate|avgsalout|avgpell|avgfed|obereg2 @2/
 selection=stepwise(select=sl slentry=0.1 slstay=0.1);
run;

ods graphics off;
proc glm data=grdrtstd;
  where category in ('Men','Women') and obereg not in (0 9);
  class category obereg2 cntlaffi2;
  model rate = category|instate|outstate|avgsalout|avgpell|avgfed|obereg2|cntlaffi2 @2;
    lsmeans category*obereg2 / slice=category slice=obereg2;
    lsmeans category*cntlaffi2 / slice=category slice=cntlaffi2;
    lsmeans obereg2*cntlaffi2 / slice = obereg2 slice=cntlaffi2;
    lsmeans obereg2 category cntlaffi2 / adjust=tukey diff lines;
    lsmeans category*obereg2 / adjust=tukey diff lines;
run;

ods graphics off;
proc glm data=grdrtstd;
 where category in ('Men','Women') and obereg not in (0 9);
 class category obereg2 cntlaffi2;
 model rate=category category*instate category*outstate category*avgpell category*avgfed category*obereg2
            category*cntlaffi2 instate outstate avgpell avgfed obereg2 cntlaffi2 category*cntlaffi2*obereg2
            / solution;
 lsmeans category*obereg2 / adjust=tukey;
 lsmeans category*cntlaffi2 / adjust=tukey;
 lsmeans category*cntlaffi2*obereg2 / adjust=tukey;
run;