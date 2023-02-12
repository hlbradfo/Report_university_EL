/*==================================================|
|- Project:		Bridge Experience Program			|
|- Created:		20230110							|
|- Revised:		20230212							|
|- Author:		Heather Bradford					|
|- Purpose:		University data report - Internal	|
|- Dependency:										|	
|- Input data:	dataSum library						|
|- Output data:										|
|	- report										|
|		- participation.rtf							|
===================================================*/


/*----------------- Program details -----------------
A. Set up
	Libraries
 		Set up file path and libraries for data 
  		All intermediate files should be stored in Work
	Formats
		Format colors of tables like heat map
		Format colors of maps
	Parameters
		Macro variables to calculate output data
	Macros
		Macro programs to generate output
		Program for each type of output
B. Report
	Create report for university-level outcomes
	Includes breakdown by college and by discipline
	Includes destination outcome, self-reported EL, and EL course enrollment
	Includes overall outcomes and outcomes disagretated by 1 or more subgroups
	Most output is across range of years
	Overall participation included for most recent individual year
----------------------------------------------------*/



/*===============================================
|												|
|					Set up 						|
|												|
===============================================*/

/*---------------- Libraries ------------------*/
%let path=C:\Users\hbradford\Local_data_files;
%let pathOut=C:\Users\hbradford\OneDrive - Virginia Tech\Exp Learning-files\Data\University and college participation;

option validvarname=v7;

/* Data input library */
libname dataIn "&path\dataIn";

/* Cross-reference library */
libname xref xlsx "&path\dataIn\Degree_programs.xlsx";

/* Data output library */
libname dataOut "&path\dataOut";

/* Data summary library */
libname dataSum "&path\dataSum";



/*----------------- Formats -------------------*/
proc format library=dataIn cntlin=xref.formats;
run;

*Format for table as heat map;
proc format;
	value range
		low - -.10 = 'dark red'
		-.10 - -.06 = 'red'
		-.06 - -.03 = 'light red'
		-.03 - .03 = 'white'
		.03 - .06 = 'light blue'
		.06 - .10 = 'blue'
		.10 - high = 'dark blue';
		
	value text
		low - -.03 = 'white'
		-.03 - .03 = 'black'
		.03 - high = 'white';
run;

*Range attribute map for 0 to max range for maps;
data heatMapColor0Max;
	retain id "myid";
	length min max $ 5;
	input min $ max $ colormodel1 $ colormodel2 $;
datalines;
0 100 white cx003C71
;



/*--------------- Parameters ------------------*/

*years;
%let endyearFDS=20;
%let startYearFDS=18;
%let endyearGrad=21;
%let startYearGrad=19;

*variables;
%let destinationText="contEd" "military" "notSeeking" "lookWork" "lookEducation" "looking" "volunteerJob" "work";
%let destinationAll=contEd military notSeeking lookWork lookEducation looking volunteerJob work;
%let destinationShort=contEd looking work;

%let elText="coop" "fieldStudy" "paidIntern" "ptJob" "summerJob" "research" "unpaidIntern" "volunteer" "pdCo" "pdCoUr";
%let elAll=coop fieldStudy paidIntern ptJob summerJob research unpaidIntern volunteer pdCo pdCoUr;
%let elShort=paidIntern research unpaidIntern pdCo pdCoUr;

%let courseText="everin34" "eversa34" "everfs34" "ever4994" "ever4974" "everAny34Course";
%let courseAll=everin34 eversa34 everfs34 ever4994 ever4974 everAny34Course;

*subgorups;
%let subgroupAll=athlet cadet female instate int oneGen rural transf urm urmaus urmous uss vet;
%let subgroupAllNames=athlete cadet female in-state international first-generation rural transfer 
	URM URM-and-USS URM-or-USS USS veteran;

%let raceAll=asian black hispani int island native tworace white;
%let raceShort=asian black hispani int tworace white;
%let subgroupCrossRace=female oneGen uss;

%let govaAll=gova1 gova2 gova3 gova4 gova5 gova6 gova7 gova8 gova9;

%let subgroup1=transf female female female  transf  onegen  rural   rural  rural;
%let subgroup2=onegen transf onegen instate instate instate instate transf oneGen;

/*
*testing;
%let subgroupAll=urm transf onegen female;
%let subgroupAllNames=URM transfer first-generation female;

%let raceAll=asian black hispani;
%let raceShort=asian black hispani tworace white;

%let govaAll=gova1 gova2 gova3;

%let subgroup1=transf female female;
%let subgroup2=onegen transf onegen;

%let subgroupCrossRace=female transf;
*/



/*-------------------- Macros -----------------*/
/* 
Purpose
		Create table with unit x category pooled across years and for the most recent year
Parameters
		unit: level of resolution, often collegeCurrent, collegeActual, or generalDiscipline
		type: 'fds' or 'enroll' based on data source
		categoryText: possible character values for category variable, names encolsed in " "
		categoryName: text name to display in table caption and across header
Inputs
		Summarized overall means with no interactions
		Summarized overall means with 1 interaction
Outputs
		2 report tables: 1 pooled years, 1 for recent year
Use
		%outcomes(unit=collegeCurrent,type='fds',categoryText="paidIntern" "coop",categoryName='Experience')
		Experiences reported from start year to stop year
		Unit	paidIntern	coop
		AAD		75%			2%
		CALS	32%			3%
		
		Experiences reported for stop year
		Unit	paidIntern	coop
		AAD		74%			1%
		CALS	34%			2%
*/

%macro outcomes(unit=,type=,categoryText=,categoryName=,
		des='Table with unit x category list pooled across years, table of same for most recent year');
	%local categoryName categoryText colName data endYear startYear type unit;
	
	%if %upcase(&type) = 'FDS' %then %do;
		%let colName = category;
		%let data = fdsMeans;
		%let startYear = &startYearFDS;
		%let endYear = &endyearFDS;
	%end;
	%else %if %upcase(&type) = 'ENROLL' %then %do;
		%let colName = course;
		%let data = enrollMeans;
		%let startYear = &startYearGrad;
		%let endYear = &endyearGrad;
	%end;
	%else %put 'Invalid TYPE. Type can be fds or enroll.';
	
	ods text="~S={font_size=12pt}{\pard &categoryName reported by 20&startYear to 20&endYear graduates \par}";
	*table unit x category pooled across years;
	proc report data=dataSum.&data;
		where &unit is not missing and
			&unit ne 'univ' and
			startYear = &startYear and 
			endYear= &endYear and 
			&colName in (&categoryText);
		column &unit avg,&colName;
		define avg / analysis mean '' format=percentn10.1;
		define &unit / group 'Unit';
		define &colName / across &categoryName;
	run;
	
	ods text="~S={font_size=12pt}{\pard &categoryName reported by 20&endYear graduates \par}";
	*table unit x category for most recent year;
	proc report data=dataSum.&data.Int1;
		where &unit is not missing and 
			&unit ne 'univ' and
			gradYear= &endYear and 
			nInteractions = 1 and
			&colName in (&categoryText);
		column &unit avg,&colName;
		define avg / analysis mean '' format=percentn10.1;
		define &unit / group 'Unit';
		define &colName / across &categoryName;
	run;
%mend outcomes;



/* 
Purpose
		Create table of percents for category x (unit x subgroup) and table of gaps for category x unit
Parameters
		unit: level of resolution, often collegeCurrent, collegeActual, or generalDiscipline
		type: 'fds' or 'enroll' based on data source
		categoryText: possible character values for category variable, names encolsed in " "
		categoryName: text name to display in table caption and across header
		subgroup: list of subgroups
		subgroupName: list of more descriptive names for subgroups
Inputs
		Summarized overall means with 1 interaction
Outputs
		2 report tables per subgroup (percents and gaps)
Use
		%outcomesSubgroupWithGaps(unit=collegeCurrent,type='fds',categoryText="paidIntern" "coop",categoryName='Experience',
		subgroup=transf female,subgroupNames=transfer female)
		
					AAD			CALS
					transf		transf
		Experience	0	1		0	1
		paidIntern	80%	70%		30%	25%
		coop		5%	1%		1%	1%
		
		Below is colored based on value
		Experience	AAD		CALS
		paidIntern	-10%	-5%	
		coop		-4%		0%
		
		Repeat for female
*/

%macro outcomesSubgroupWithGaps(unit=,type=,categoryText=,categoryName=,subgroup=,subgroupNames=,
	des='Table of percents for category x (unit x subgroup) and table of gaps for category x unit');
	%local categoryName categoryText colName data endYear i n nextSubgroup nextSubgroupName startYear subgroup subgroupNames type unit;

	%if %upcase(&type) = 'FDS' %then %do;
		%let colName = category;
		%let data = fdsMeans;
		%let startYear = &startYearFDS;
		%let endYear = &endyearFDS;
	%end;
	%else %if %upcase(&type) = 'ENROLL' %then %do;
		%let colName = course;
		%let data = enrollMeans;
		%let startYear = &startYearGrad;
		%let endYear = &endyearGrad;
	%end;
	%else %put 'Invalid TYPE. Type can be fds or enroll.';
	
	%let n = %sysfunc(countw(&subgroup)); *n subgroups;
	%do i = 1 %to &n; *subgroup;
		%let nextSubgroup = %scan(&subgroup,&i); *select subgroup code;
		%let nextSubgroupName = %scan(&subgroupNames,&i,' '); *select subgroup name;
				
		ods text="~S={font_size=12pt}{\pard &categoryName reported by 20&startYear to 20&endYear graduates by &nextSubgroupName \par}";
		
		*table category x (unit x subgroup) with percents;
		proc report data=dataSum.&data.Int1 headline;
			where &unit is not missing and
				&unit ne 'univ' and
				startYear = &startYear and
				endYear = &endYear and 
				nInteractions = 1 and
				&nextSubgroup is not missing and  
				&colName in (&categoryText);
			column &colName avg,&unit,&nextSubgroup;
			define avg / analysis '' format=percentn10.1;
			define &colName / group &categoryName;
			define &unit / across 'Unit';
			define &nextSubgroup / across;
		run;

		ods text="~S={font_size=12pt}{\pard &categoryName gaps reported by 20&startYear to 20&endYear graduates for &nextSubgroupName - alternate subgroup \par}";
		*table category x unit with gaps for given subgroup;
		proc report data=dataSum.&data.Int1 headline style(column)={backgroundcolor=range. foreground=text.};
			where &unit is not missing and
				&unit ne 'univ' and
				startYear = &startYear and
				endYear = &endYear and 
				nInteractions = 1 and
				&nextSubgroup is not missing and  
				&colName in (&categoryText);
			column &colName avg,&unit,(sum range),&nextSubgroup lastvar;
			define avg / analysis '' format=percentn10.1;
			define &colName / group &categoryName;
			define &unit / across 'Unit';
			define &nextSubgroup / across '' noprint;
			define lastvar / computed noprint;
			compute lastvar; *Calculation per college, make gaps negative;
				if _c3_ < _c2_ then _c4_ = _c4_ * -1;
				if _c6_ < _c5_ then _c7_ = _c7_ * -1;
				if _c9_ < _c8_ then _c10_ = _c10_ * -1;
				if _c12_ < _c11_ then _c13_ = _c13_ * -1;
				if _c15_ < _c14_ then _c16_ = _c16_ * -1;
				if _c18_ < _c17_ then _c19_ = _c19_ * -1;
				if _c21_ < _c20_ then _c22_ = _c22_ * -1;
				if _c24_ < _c23_ then _c25_ = _c25_ * -1;
			endcomp;
		run;
	%end; *subgroup;
%mend outcomesSubgroupWithGaps;



/* 
Purpose
		Create tables of percents for category x unit for each subgroup
Parameters
		unit: level of resolution, often collegeCurrent, collegeActual, or generalDiscipline
		type: 'fds' or 'enroll' based on data source
		categoryText: possible character values for category variable, names encolsed in " "
		categoryName: text name to display in table caption and across header
		subgroup: list of subgroups
Inputs
		Summarized overall means with 1 interaction
Outputs
		Table per subgroup with percents
Use
		%outcomesSubgroupNoGaps(unit=collegeCurrent,type='fds',categoryText="paidIntern" "coop",categoryName='Experience',subgroup=transf female)
		
		Transf students
		Experience	AAD		CALS
		paidIntern	75%		32%
		coop		2%		1%
		
		female students
		Experience	AAD		CALS
		paidIntern	80%		31%
		coop		2%		2%
*/

%macro outcomesSubgroupNoGaps(unit=,type=,categoryText=,categoryName=,subgroup=,
	des='Tables of percents for category x unit for each subgroup');
	%local categoryName categoryText colName data endYear i n nextSubgroup startYear subgroup type unit;

	%if %upcase(&type) = 'FDS' %then %do;
		%let colName = category;
		%let data = fdsMeans;
		%let startYear = &startYearFDS;
		%let endYear = &endyearFDS;
	%end;
	%else %if %upcase(&type) = 'ENROLL' %then %do;
		%let colName = course;
		%let data = enrollMeans;
		%let startYear = &startYearGrad;
		%let endYear = &endyearGrad;
	%end;
	%else %put 'Invalid TYPE. Type can be fds or enroll.';
	
	%let n = %sysfunc(countw(&subgroup)); *n subgroups;
	%do i = 1 %to &n; *subgroup;
		%let nextSubgroup = %scan(&subgroup,&i); *select subgroup code;
				
		ods text="~S={font_size=12pt}{\pard &categoryName reported by 20&startYear to 20&endYear graduates for &nextSubgroup \par}";
		*table category x unit for given subgroup;
		proc report data=dataSum.&data.Int1 headline;
			where &unit is not missing and
				&unit ne 'univ' and
				startYear = &startYear and
				endYear = &endYear and 
				nInteractions = 1 and
				&nextSubgroup = 1 and  
				&colName in (&categoryText);
			column &colName avg,&unit;
			define avg / analysis '' format=percentn10.1;
			define &colName / group &categoryName;
			define &unit / across 'Unit';
		run;
	%end; *subgroup;
%mend outcomesSubgroupNoGaps;



/* 
Purpose
		Create tables of gaps for unit x subgroup list within each category
Parameters
		unit: level of resolution, often collegeCurrent, collegeActual, or generalDiscipline
		type: 'fds' or 'enroll' based on data source
		category: values for category variable
Inputs
		Summarized overall means with 1 interaction
Outputs
		Table of gaps per category
Use
		%subgroupOutcomes(unit=collegeCurrent,type='fds',category=paidIntern coop)
		
		Gaps are color coded based on value
		PaidIntern
		Unit	Athlet	cadet	female
		AAD		-2.1%	-25.1%	2.3%
		CALS	1.3%	-20.0%	-4.1%
		
		Coop
		Unit	Athlet	cadet	female
		AAD		0.1%	-28.7%	-0.3%
		CALS	1.9%	-21.0%	7.1%
*/

%macro subgroupOutcomes(unit=,type=,category=,
	des='Tables of gaps for unit x subgroup list within each category');
	%local category colName data endYear i n nextCategory startYear type unit;
	
	%if %upcase(&type) = 'FDS' %then %do;
		%let colName = category;
		%let data = fdsMeans;
		%let startYear = &startYearFDS;
		%let endYear = &endyearFDS;
	%end;
	%else %if %upcase(&type) = 'ENROLL' %then %do;
		%let colName = course;
		%let data = enrollMeans;
		%let startYear = &startYearGrad;
		%let endYear = &endyearGrad;
	%end;
	%else %put 'Invalid TYPE. Type can be fds or enroll.';
	
	%let n = %sysfunc(countw(&category)); *n subgroups;
	%do i = 1 %to &n; *subgroup;
		%let nextCategory = %scan(&category,&i); *select subgroup code;

		ods text="~S={font_size=12pt}{\pard &nextCategory gaps reported by 20&startYear to 20&endYear graduates \par}";
		*table of unit x subgroups for gaps within each category;
		proc report data=dataSum.&data.Int1 headline style(column)={backgroundcolor=range. foreground=text.};
			where &unit is not missing and
				&unit ne 'univ' and
				startYear = &startYear and
				endYear = &endYear and 
				nInteractions = 1 and
				&colName = %sysfunc(quote(&nextCategory,"'"));
			column &unit avg,
				(athlet cadet female instate int oneGen rural transf urm urmaus urmous uss vet) 
				athlet1 cadet1 female1 instate1 int1 oneGen1 rural1 transf1 urm1 urmaus1 urmous1 uss1 vet1; *ADD NEW HERE;
			define avg / analysis '' sum format=percentn10.1;
			define &unit / group 'Unit';
			
			define athlet / across missing noprint;
			define cadet / across missing noprint;
			define female / across missing noprint;
			define instate / across missing noprint;
			define int / across missing noprint;
			define onegen / across missing noprint;
			define rural / across missing noprint;
			define transf / across missing noprint;
			define urm / across missing noprint;
			define urmaus / across missing noprint;
			define urmous / across missing noprint;
			define uss / across missing noprint;
			define vet / across missing noprint;
			*ADD NEW HERE;
			
			define athlet1 / 'Athlete' computed format=percentn10.1;
			compute athlet1;
				athlet1 = _c4_ - _c3_;
			endcomp;
			define cadet1 / 'Cadet' computed format=percentn10.1;
			compute cadet1;
				cadet1 = _c7_ - _c6_;
			endcomp;
			define female1 / 'Female' computed format=percentn10.1;
			compute female1;
				female1 = _c10_ - _c9_;
			endcomp;
			define instate1 / 'In-state' computed format=percentn10.1;
			compute instate1;
				instate1 = _c13_ - _c12_;
			endcomp;
			define int1 / 'Int' computed format=percentn10.1;
			compute int1;
				int1 = _c16_ - _c15_;
			endcomp;
			define onegen1 / 'First-gen' computed format=percentn10.1;
			compute onegen1;
				onegen1 = _c19_ - _c18_;
			endcomp;
			define rural1 / 'Rural' computed format=percentn10.1;
			compute rural1;
				rural1 = _c22_ - _c21_;
			endcomp;
			define transf1 / 'Transfer' computed format=percentn10.1;
			compute transf1;
				transf1 = _c25_ - _c24_;
			endcomp;
			define urm1 / 'URM' computed format=percentn10.1;
			compute urm1;
				urm1 = _c28_ - _c27_;
			endcomp;
			define urmaus1 / 'URM and USS' computed format=percentn10.1;
			compute urmaus1;
				urmaus1 = _c31_ - _c30_;
			endcomp;
			define urmous1 / 'URM or USS' computed format=percentn10.1;
			compute urmous1;
				urmous1 = _c34_ - _c33_;
			endcomp;
			define uss1 / 'USS' computed format=percentn10.1;
			compute uss1;
				uss1 = _c37_ - _c36_;
			endcomp;
			define vet1 / 'veteran' computed format=percentn10.1;
			compute vet1;
				vet1 = _c40_ - _c39_;
			endcomp;
			*ADD NEW HERE;
		run;	
	%end; *subgroup;
%mend subgroupOutcomes;



/* 
Purpose
		Create tables for unit x (subgroup x subgroup) percents and 3 columns of gaps, 1 table per category
Parameters
		unit: level of resolution, often collegeCurrent, collegeActual, or generalDiscipline
		type: 'fds' or 'enroll' based on data source
		category: values for category variable
		group1: list of subgroup variables
		group2: list of subgroup variables
Inputs
		Summarized overall means with 2 interactions
Outputs
		Table with percents and gaps per category
Use
		%outcomesSubgroup2WithGap(unit=collegeCurrent,type='fds',category=paidIntern coop,group1=transf female,group2=female oneGen)
		
		paidIntern transf x female
					transf
				0		1
				female	female		
		Unit	0	1	0	1		01-00	10-00	11-00
		AAD		80%	75%	68%	65%		-5%		-12%	-15%
		CALS	36%	29%	19%	23%		7%		-17%	-13%
		
		coop transf x female
		...
*/

%macro outcomesSubgroup2WithGaps(unit=,type=,category=,group1=,group2=,
	des='Tables for unit x (subgroup x subgroup) percents and 3 columns of gaps, 1 table per category');
	%local category colName data endYear group1 group2 groupID1 groupID2 i j n nextCategory ngroup startYear type unit;
	
	%if %upcase(&type) = 'FDS' %then %do;
		%let colName = category;
		%let data = fdsMeans;
		%let startYear = &startYearFDS;
		%let endYear = &endyearFDS;
	%end;
	%else %if %upcase(&type) = 'ENROLL' %then %do;
		%let colName = course;
		%let data = enrollMeans;
		%let startYear = &startYearGrad;
		%let endYear = &endyearGrad;
	%end;
	%else %put 'Invalid TYPE. Type can be fds or enroll.';
	
	%let ngroup = %sysfunc(countw(&group1)); *ngroup subgroups;
	%let n = %sysfunc(countw(&category)); *n categories;
	
	%do j = 1 %to &ngroup; *subgroups;
		%let groupID1 = %scan(&group1,&j); *subgroup 1;
		%let groupID2 = %scan(&group2,&j); *subgroup 2;
	
		%do i = 1 %to &n; *category;
			%let nextCategory = %scan(&category,&i); *select destination code;
			
			ods text="~S={font_size=12pt}{\pard &nextCategory reported by 20&startYear to 20&endYear graduates for &groupID1 x &groupID2 \par}";
			*table unit x (subgroup x subgroup) percents and gaps by category;
			proc report data=dataSum.&data.Int2 headline;
			where &unit is not missing and
				&unit ne 'univ' and
				startYear = &startYear and
				endYear = &endYear and 
				nInteractions = 2 and
				&groupID1 is not missing and
				&groupID2 is not missing and 
				&colName = %sysfunc(quote(&nextCategory,"'"));
			column &unit avg,&groupID1,&groupID2 blank gap1 gap2 gap3;
			define avg / analysis '' sum format=percentn10.1;
			define &unit / group 'Unit';
			define &groupID1 / across;
			define &groupID2 / across;
			define blank / '';
			define gap1 / '01-00' computed format=percentn10. style(column)={backgroundcolor=range. foreground=text.};
			compute gap1;
				gap1 = _c3_ - _c2_; *group 1 0, group 2 1 - group 1 0, group 2 0;
			endcomp;
			define gap2 / '10-00' computed format=percentn10. style(column)={backgroundcolor=range. foreground=text.};
			compute gap2;
				gap2 = _c4_ - _c2_; *group 1 1, group 2 0 - group 1 0, group 2 0;
			endcomp;
			define gap3 / '11-00' computed format=percentn10. style(column)={backgroundcolor=range. foreground=text.};
			compute gap3;
				gap3 = _c5_ - _c2_; *group 1 1, group 2 1 - group 1 0, group 2 0;
			endcomp;
		run;
		%end; *category;
	%end; *subgroups;
%mend outcomesSubgroup2WithGaps;



/* 
Purpose
		Create tables for unit x (subgroup x subgroup) percents, 1 table per category
Parameters
		unit: level of resolution, often collegeCurrent, collegeActual, or generalDiscipline
		type: 'fds' or 'enroll' based on data source
		category: list of category values
		group1: list of subgroup values
		group2: list of subgroup values
Inputs
		Summarized overall means with 2 interactions
Outputs
		Table with percents by subgroup per category
Use
		%outcomesSubgroup2NoGaps(unit=collegeCurrent,type='fds',category=paidIntern coop,group1=asian white,group2=female transf)
		
		paidIntern female x race
								female
				0						1
				asian		white		asian		white
		Unit	.	0	1	.	0	1	.	0	1	.	0	1
		AAD			85%	82%		87%	88%		80%	82%		83%	84%
		CALS		34%	36%		33%	31%		30%	35%		31%	36%
		
		coop female x race
		...
		paidIntern transf x race
		...
		coop transf x race
		...
*/

%macro outcomesSubgroup2NoGaps(unit=,type=,category=,group1=,group2=,
	des='Tables of unit x (subgroup x subgroup) percents by category');
	%local category colName data endYear group1 group2 groupID2 i j n nextCategory ngroup startYear type unit;
	
	%if %upcase(&type) = 'FDS' %then %do;
		%let colName = category;
		%let data = fdsMeans;
		%let startYear = &startYearFDS;
		%let endYear = &endyearFDS;
	%end;
	%else %if %upcase(&type) = 'ENROLL' %then %do;
		%let colName = course;
		%let data = enrollMeans;
		%let startYear = &startYearGrad;
		%let endYear = &endyearGrad;
	%end;
	%else %put 'Invalid TYPE. Type can be fds or enroll.';
	
	%let ngroup = %sysfunc(countw(&group2)); * n subgroups;
	%let n = %sysfunc(countw(&category)); *n categories;
	
	%do j = 1 %to &ngroup; *subgroups;
		%let groupID2 = %scan(&group2,&j); *subgroup 2;
	
		%do i = 1 %to &n; *category;
			%let nextCategory = %scan(&category,&i); *select category;
			
			ods text="~S={font_size=12pt}{\pard &nextCategory reported by 20&startYear to 20&endYear graduates for &groupID2 x race \par}";
			*table unit x (subgroup 2 x subgroup 1) by category;
			proc report data=dataSum.&data.Int2 headline;
			where &unit is not missing and
				&unit ne 'univ' and
				startYear = &startYear and
				endYear = &endYear and 
				nInteractions = 2 and
				&groupID2 is not missing and 
				&colName = %sysfunc(quote(&nextCategory,"'"));
			column &unit avg,&groupID2,(asian black hispani tworace white) lastvar;
			define avg / analysis '' sum format=percentn10.1;
			define &unit / group 'Unit';
			define &groupID2 / across;
			define asian / across missing;
			define black / across missing;
			define hispani / across missing;
			define tworace / across missing;
			define white / across missing;
			define lastvar / computed noprint;
			compute lastvar; *removes text in columns for missing values;
				_c2_ = .;
				_c5_ = .;
				_c8_ = .;
				_c11_ = .; 
				_c14_ = .;
				_c17_ = .;
				_c20_ = .;
				_c23_ = .;
				_c26_ = .;
				_c29_ = .;
			endcomp;
		run;
			
		%end; *category;
	%end; *subgroups;
%mend outcomesSubgroup2NoGaps;



/* 
Purpose
		Create GOVA map for specific category
Parameters
		unit: level of resolution, often collegeCurrent, collegeActual, or generalDiscipline
		type: 'fds' or 'enroll' based on data source
		category: category value
		title: title of map
Inputs
		Summarized overall means by GOVA region
		Map data for graphing
Outputs
		Viginia map colored by GOVA region for each level of &unit
Use
		%mapData(unit=collegeCurrent,type='FDS',category=paidIntern,title=Paid Internship)
*/

%macro mapData(unit=,type=,title=,category=);
	%local category data i nextUnit title type unit unitLevels;
	
	%if %upcase(&type) = 'FDS' %then %do;
		%let colName = category;
		%let data = fdsMeansInt1;
		%let startYear = &startYearFDS;
		%let endYear = &endyearFDS;
	%end;
	%else %if %upcase(&type) = 'ENROLL' %then %do;
		%let colName = course;
		%let data = enrollMeansInt1;
		%let startYear = &startYearGrad;
		%let endYear = &endyearGrad;
	%end;
	%else %put 'Invalid TYPE. Type can be fds or enroll.';
	
	*identify unique values of unit;
	proc sql noprint;
		select distinct &unit into : unitLevels separated by '|'
		from dataSum.&data
		where &unit is not missing and &unit ne 'univ';
	quit;

	%do i = 1 %to %sysfunc(countc(&unitLevels,'|'))+1; *unit level;
		%let nextUnit = %scan(&unitLevels,&i,'|'); *select level of unit;
	
		data mapData(keep=govaRegion avg);
			set dataSum.&data(where=(&colName = &category and 
			(gova1 = 1 or gova2 = 1 or gova3 = 1 or gova4 = 1 or gova5 = 1 or gova6 = 1 or gova7 = 1 or gova8 = 1 or gova9 = 1)
			and &unit = "&nextUnit" and startYear = &startYear and endYear = &endYear));
			length govaRegion $ 5;
			format avg f8.;
			
			if gova1 = 1 then govaRegion = 'gova1';
			else if gova2 = 1 then govaRegion = 'gova2';
			else if gova3 = 1 then govaRegion = 'gova3';
			else if gova4 = 1 then govaRegion = 'gova4';
			else if gova5 = 1 then govaRegion = 'gova5';
			else if gova6 = 1 then govaRegion = 'gova6';
			else if gova7 = 1 then govaRegion = 'gova7';
			else if gova8 = 1 then govaRegion = 'gova8';
			else if gova9 = 1 then govaRegion = 'gova9';
			
			avg = avg * 100;
		run;
		
		proc sql;
			create table mapDataGOVA as
			select a.avg, b.*
			from mapData as a 
				left join dataOut.govaRegions as b 
				on a.govaregion = b.govaregion
			;
		quit;
		
		*add values for labels per GOVA region;
		proc sql;
			create table govaLabels as
			select a.govaRegion, a.xNew, a.yNew, b.avg as label
			from dataOut.govaMapLabel as a 
				left join mapDataGOVA as b 
				on a.govaRegion = b.govaRegion
			;
		quit;
		
		*create map;
		proc sgmap mapdata=dataOut.vaMapData maprespdata=mapDataGOVA rattrmap=heatMapColor0Max plotdata=govaLabels;
			title "&title &nextUnit";
			choromap avg / mapid=countynm id=county rattrid=myid lineattrs=(color=white);
			gradlegend / title='Percent of graduates';
			text x=xNew y=yNew text=label / group=govaRegion textattrs=(color=black size=14);
		run;
		title;
	%end; *unit level;
%mend mapData;



/*===============================================
|												|
|					Report 						|
|												|
===============================================*/

/*-------------- Report set-up ----------------*/
options nodate orientation=landscape;
ods rtf file="&pathOut\participation.rtf" keepn startpage=no wordstyle="{\s1 Heading 1 \s2 Heading 2 \s3 Heading 3;}";

ods escapechar='~';



/*--------------- Destination -----------------*/
ods text="~S={font_size=18pt}{\pard\s1\b Destination \par}"; *H1;

	ods text="~S={font_size=16pt}{\pard\s2\b Destination \par}"; *H2;

	%outcomes(unit=collegeCurrent,
			  type='fds',
			  categoryText=&destinationText,
			  categoryName='Destination')



/*---------- Destination x subgroup -----------*/
	ods text="~S={font_size=16pt}{\pard\s2\b Demographic \par}"; *H2;

		ods text="~S={font_size=14pt}{\pard\s3 Subgroup heat map \par}"; *H3;
	
		%outcomesSubgroupWithGaps(unit=collegeCurrent,
								  type='fds',
								  categoryText=&destinationText,
								  categoryName='Destination',
								  subgroup=&subgroupAll, 
								  subgroupNames=&subgroupAllNames)
			
		%outcomesSubgroupNoGaps(unit=collegeCurrent,
								type='fds',
								categoryText=&destinationText,
								categoryName='Destination',
				  				subgroup=&raceAll)
				  
		%outcomesSubgroupNoGaps(unit=collegeCurrent,
								type='fds',
								categoryText=&destinationText,
								categoryName='Destination',
								subgroup=&govaAll)



/*---------- Subgroup x destination -----------*/
		ods text="~S={font_size=14pt}{\pard\s3 Destination heat map \par}"; *H3;

		%subgroupOutcomes(unit=collegeCurrent,
					  	  type='fds',
					  	  category=&destinationAll)		



/*----- Destination x subgroup x subgroup -----*/
		ods text="~S={font_size=14pt}{\pard\s3 Subgroup combinations \par}"; *H3;
	
		%outcomesSubgroup2WithGaps(unit=collegeCurrent,
						  		   type='fds',
						  		   category=&destinationShort, 
								   group1=&subgroup1, 
								   group2=&subgroup2)	
			
		%outcomesSubgroup2NoGaps(unit=collegeCurrent,
							     type='fds',
							     category=&destinationShort, 
							     group1=&raceShort, 
							     group2=&subgroupCrossRace)	
		
		
		
/*------------ Destination x GOVA ------------*/	
	
		ods text="~S={font_size=14pt}{\pard\s3 GOVA heat map \par}"; *H3;

			%mapData(unit=collegeCurrent,
					 type='FDS',
			 		 category='work',
			 		 title=Working)
			 		 
			 %mapData(unit=collegeCurrent,
			 		 type='FDS',
			 		 category='looking',
			 		 title=Looking for a placement)
			 		 
			 %mapData(unit=collegeCurrent,
			 		 type='FDS',
			 		 category='contEd',
			 		 title=Contining Education)



/*--------- Discipline x destination ----------*/
	ods text="~S={font_size=16pt}{\pard\s2\b Discipline \par}"; *H2;
	
		ods text="~S={font_size=14pt}{\pard\s3 Destination \par}"; *H3;
		%outcomes(unit=generalDiscipline,
				  type='fds',
				  categoryText=&destinationText,
				  categoryName='Destination')
		
		
		
/*--- Discipline x destination x subgroup -----*/
		ods text="~S={font_size=14pt}{\pard\s3 Subgroup heat map \par}"; *H3;
		
		%outcomesSubgroupWithGaps(unit=generalDiscipline,
								  type='fds',
								  categoryText=&destinationText,
								  categoryName='Destination',
								  subgroup=&subgroupAll, 
					  			  subgroupNames=&subgroupAllNames)
		
		%outcomesSubgroupNoGaps(unit=generalDiscipline,
								type='fds',
								categoryText=&destinationText,
								categoryName='Destination',
								subgroup=&raceAll)
				  
		%outcomesSubgroupNoGaps(unit=generalDiscipline,
								type='fds',
								categoryText=&destinationText,
								categoryName='Destination',
								subgroup=&govaAll)
			  
		
		
/*--- Discipline x destination x subgroup -----*/
		ods text="~S={font_size=14pt}{\pard\s3 Destination heat map \par}"; *H3;
		
		%subgroupOutcomes(unit=generalDiscipline,
						  type='fds',
						  category=&destinationAll)	
					  
			  
		
/*------ Discipline x destination x GOVA ------*/
		ods text="~S={font_size=14pt}{\pard\s3 GOVA heat map \par}"; *H3;

		%mapData(unit=generalDiscipline,
			 	 type='FDS',
			 	 category='looking',
			 	 title=Looking for a Placement)
			 		 
		%mapData(unit=generalDiscipline,
			 	 type='FDS',
			 	 category='work',
			 	 title=Working)



/*------------- EL - self-report --------------*/
ods text="~S={font_size=18pt}{\pard\s1\b Experiential Learning - Self-report \par}"; *H1;

	ods text="~S={font_size=16pt}{\pard\s2\b Experiential Learning \par}"; *H2;

	%outcomes(unit=collegeCurrent,
			  type='fds',
			  categoryText=&elText,
			  categoryName='Experiential Learning')
			 
			 
			 
/*-------- EL self-report x subgroup ----------*/
	ods text="~S={font_size=16pt}{\pard\s2\b Demographic \par}"; *H2;

		ods text="~S={font_size=14pt}{\pard\s3 Subgroup heat map \par}"; *H3;

		%outcomesSubgroupWithGaps(unit=collegeCurrent,
								  type='fds',
								  categoryText=&elText,
								  categoryName='Experience',
								  subgroup=&subgroupAll,
								  subgroupNames=&subgroupAllNames)

		%outcomesSubgroupNoGaps(unit=collegeCurrent,
								type='fds',
								categoryText=&elText,
								categoryName='Experience',
								subgroup=&raceAll)
		
		%outcomesSubgroupNoGaps(unit=collegeCurrent,
								type='fds',
								categoryText=&elText,
								categoryName='Experience',
								subgroup=&govaAll)
		
		
		
/*-------- Subgroup x EL self-report ----------*/
		ods text="~S={font_size=14pt}{\pard\s3 EL heat map \par}"; *H3;

		%subgroupOutcomes(unit=collegeCurrent,
						  type='fds',
						  category=&elAll)



/*---- EL self-report x subgroup x subgroup ---*/
		ods text="~S={font_size=14pt}{\pard\s3 Subgroup combinations \par}"; *H3;
		
		%outcomesSubgroup2WithGaps(unit=collegeCurrent,
								   type='fds',
								   category=&elShort,
								   group1=&subgroup1,
								   group2=&subgroup2)
		
		%outcomesSubgroup2NoGaps(unit=collegeCurrent,
								 type='fds',
								 category=&elShort,
								 group1=&raceShort,
								 group2=&subgroupCrossRace)
								   
		
		
/*----------- EL self-report x GOVA -----------*/
		ods text="~S={font_size=14pt}{\pard\s3 GOVA heat map \par}"; *H3;
		
		%mapData(unit=collegeCurrent,
				 type='FDS',
			 	 category='paidIntern',
			 	 title=Paid Internship)
			 		 
		%mapData(unit=collegeCurrent,
				 type='FDS',
			 	 category='unpaidIntern',
			 	 title=Unpaid Internship)
			 		 
		%mapData(unit=collegeCurrent,
				 type='FDS',
			 	 category='research',
			 	 title=Undergraduate Research)



/*------- Discipline x EL self-report ---------*/
	ods text="~S={font_size=16pt}{\pard\s2\b Discipline \par}"; *H2;

		ods text="~S={font_size=14pt}{\pard\s3 EL - self-report \par}"; *H3;
		
		%outcomes(unit=generalDiscipline,
				  type='fds',
				  categoryText=&elText,
				  categoryName='Experience')
			 
			 
			 
/*--  Discipline x EL self-report x subgroup --*/
		ods text="~S={font_size=14pt}{\pard\s3 Subgroup heat map \par}"; *H3;

		%outcomesSubgroupWithGaps(unit=generalDiscipline,
								  type='fds',
								  categoryText=&elText,
								  categoryName='Experience',
								  subgroup=&subgroupAll,
								  subgroupNames=&subgroupAllNames)

		%outcomesSubgroupNoGaps(unit=generalDiscipline,
								type='fds',
								categoryText=&elText,
								categoryName='Experience',
								subgroup=&raceAll)
		
		%outcomesSubgroupNoGaps(unit=generalDiscipline,
								type='fds',
								categoryText=&elText,
								categoryName='Experience',
								subgroup=&govaAll)



/*-- Discipline x subgroup x EL self-report ---*/
		ods text="~S={font_size=14pt}{\pard\s3 EL heat map \par}"; *H3;

		%subgroupOutcomes(unit=generalDiscipline,
						  type='fds',
						  category=&elAll)
		
		
		
/*----- Discipline x EL self-report x GOVA ----*/
		ods text="~S={font_size=14pt}{\pard\s3 GOVA heat map \par}"; *H3;
		
		%mapData(unit=generalDiscipline,
				 type='FDS',
			 	 category='paidIntern',
			 	 title=Paid Internship)
			 		 
		%mapData(unit=generalDiscipline,
				 type='FDS',
			 	 category='unpaidIntern',
			 	 title=Unpaid Internship)
			 		 
		%mapData(unit=generalDiscipline,
				 type='FDS',
			 	 category='research',
			 	 title=Undergraduate Research)
		
		

/*---------------- EL - course ----------------*/
ods text="~S={font_size=18pt}{\pard\s1\b Experiential Learning - Courses \par}"; *H1;

	ods text="~S={font_size=16pt}{\pard\s2\b EL - courses \par}"; *H2;
			 
	%outcomes(unit=collegeCurrent,
			  type='enroll',
			  categoryText=&courseText,
			  categoryName='Course')


	
/*---------- EL course x subgroup -------------*/
	ods text="~S={font_size=16pt}{\pard\s2\b Demographic \par}"; *H2;

		ods text="~S={font_size=14pt}{\pard\s3 Subgroup heat map \par}"; *H3;
		
		%outcomesSubgroupWithGaps(unit=collegeCurrent,
								  type='enroll',
								  categoryText=&courseText,
								  categoryName='Course',
								  subgroup=&subgroupAll, 
								  subgroupNames=&subgroupAllNames)
	
		%outcomesSubgroupNoGaps(unit=collegeCurrent,
								type='enroll',
								categoryText=&courseText,
								categoryName='Course',
				  				subgroup=&raceAll)
				  
		%outcomesSubgroupNoGaps(unit=collegeCurrent,
								type='enroll',
								categoryText=&courseText,
								categoryName='Course',
								subgroup=&govaAll)



/*---------- Subgroup x EL course -------------*/
		ods text="~S={font_size=14pt}{\pard\s3 Course heat map \par}"; *H3;

		%subgroupOutcomes(unit=collegeCurrent,
			  			  type='enroll',
			 		 	  category=&courseAll)	



/*----- EL course x subgroup x subgroup -------*/
		ods text="~S={font_size=14pt}{\pard\s3 Subgroup combinations \par}"; *H3;
		
		%outcomesSubgroup2WithGaps(unit=collegeCurrent,
								   type='enroll',
								   category=&courseAll,
								   group1=&subgroup1,
								   group2=&subgroup2)
									
		%outcomesSubgroup2NoGaps(unit=collegeCurrent,
								 type='enroll',
								 category=&courseAll,
								 group1=&raceShort,
								 group2=&subgroupCrossRace)
		
		
		
/*------------- EL course x GOVA --------------*/		
		ods text="~S={font_size=14pt}{\pard\s3 GOVA heat map \par}"; *H3;
		
		%mapData(unit=collegeCurrent,
				 type='enroll',
			 	 category='everAny34Course',
			 	 title=Any upper-level EL course)
			 		 
		

/*---------- Discipine x EL course ------------*/
	ods text="~S={font_size=16pt}{\pard\s2\b Discipline \par}"; *H2;
			 
	%outcomes(unit=generalDiscipline,
			  type='enroll',
			  categoryText=&courseText,
			  categoryName='Course')
			 
			 
			 
/*---- Discipline x EL course x subgroup ------*/
	ods text="~S={font_size=16pt}{\pard\s2\b Demographic \par}"; *H2;

		ods text="~S={font_size=14pt}{\pard\s3 Subgroup heat map \par}"; *H3;

		%outcomesSubgroupWithGaps(unit=generalDiscipline,
								  type='enroll',
								  categoryText=&courseText,
								  categoryName='Course',
								  subgroup=&subgroupAll, 
								  subgroupNames=&subgroupAllNames)
	
		%outcomesSubgroupNoGaps(unit=generalDiscipline,
								type='enroll',
								categoryText=&courseText,
								categoryName='Course',
				  				subgroup=&raceAll)
				  
		%outcomesSubgroupNoGaps(unit=generalDiscipline,
								type='enroll',
								categoryText=&courseText,
								categoryName='Course',
								subgroup=&govaAll)



/*----- Discipline x Subgroup x EL course -----*/
		ods text="~S={font_size=14pt}{\pard\s3 Course heat map \par}"; *H3;

		%subgroupOutcomes(unit=generalDiscipline,
			  			  type='enroll',
			 		 	  category=&courseAll)	



/*------ Discipline x EL course x GOVA --------*/		
		ods text="~S={font_size=14pt}{\pard\s3 GOVA heat map \par}"; *H3;

		%mapData(unit=generalDiscipline,
				 type='enroll',
			 	 category='everAny34Course',
			 	 title=Any upper-level EL course)



ods rtf close;

