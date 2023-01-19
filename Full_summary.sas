/*==================================================|
|- Project:		Bridge Experience Program			|
|- Created:		20230110							|
|- Revised:		20230119							|
|- Author:		Heather Bradford					|
|- Purpose:		University data report - Internal	|
|- Dependency:										|	
|- Input data:	dataSum library						|
|- Output data:										|
|	- report										|
|		- participation.rtf							|
===================================================*/


/*----------------- Program details -----------------
A. Libraries
  Set up file path and libraries for data 
  All output data files stored in SOC
  All intermediate files should be stored in Work
  Need to run this script when opening SAS 

----------------------------------------------------*/


/*---------------- Libraries ------------------*/
%let path=C:\Users\hbradford\Local_data_files;
%let pathOut=C:\Users\hbradford\OneDrive - Virginia Tech\Exp Learning-files\Data\University and college participation;

option validvarname=v7;

/* Data input library */
libname dataIn "&path\dataIn";

/* Cross-reference library */
libname xref xlsx "&path\dataIn\Degree_programs.xlsx";


/* Data summary library */
libname dataSum "&path\dataSum";

/* Autocall library for macros */
*options sasautos=("&path\SASCode\SASDataSum\Autocall" sasautos) mautosource;


/*----------------- Formats -------------------*/
proc format library=dataIn cntlin=xref.formats;
run;

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


/*--------------- Parameters ------------------*/

%let currentYearFDS=20;
%let startYearFDS=18;
%let currentYearGrad=21;
%let startYearGrad=19;

%let destination="contEd" "military" "notSeeking" "lookWork" "lookEducation" "looking" "volunteerJob" "work";
%let destinationAll=contEd military notSeeking lookWork lookEducation looking volunteerJob work;
%let destinationShort=contEd looking work;



/*
%let subgroupAll=athlet cadet female instate int oneGen rural transf urm urmaus urmous uss vet;
%let subgroupAllNames=athlete cadet female in-state international first-generation rural transfer 
	URM URM-and-USS URM-or-USS USS veteran;

%let raceAll=asian black hispani island native tworace white;

%let govaAll=gova1 gova2 gova3 gova4 gova5 gova6 gova7 gova8 gova9;

%let subgroup1=transf female female female  transf  onegen  rural   rural  rural;
%let subgroup2=onegen transf onegen instate instate instate instate transf oneGen;
*/


*testing;
%let subgroupAll=urm transf onegen female;
%let subgroupAllNames=URM transfer first-generation female;

%let raceAll=asian black hispani;

%let govaAll=gova1 gova2 gova3;

%let subgroup1=transf female female;
%let subgroup2=onegen transf onegen;

%let subgroupCrossRace=female transf;



/*-------------- Report set-up ----------------*/
options nodate orientation=landscape;
ods rtf file="&pathOut\participation.rtf" keepn startpage=no wordstyle="{\s1 Heading 1 \s2 Heading 2 \s3 Heading 3;}";

ods escapechar='~';



/*--------------- Destination -----------------*/
ods text="~S={font_size=18pt}{\pard\s1\b Destination \par}"; *H1;

	ods text="~S={font_size=16pt}{\pard\s2\b Destination \par}"; *H2;
	
ods text="~S={font_size=12pt}{\pard Destinations reported by 20&startYearFDS. to 20&currentYearFDS. graduates \par}";
%macro outcomes(unit=,categoryText=,categoryName=,
		des='Table with unit x category list pooled across years, table of same for most recent year');
	%local unit categoryText categoryName;
	
	*table unit x category pooled across years;
	proc report data=dataSum.fdsMeans;
		where &unit is not missing and
			&unit ne 'univ' and
			startYear = &startYearFDS and 
			endYear= &currentYearFDS and 
			category in (&categoryText);
		column &unit avg,category;
		define &unit / group 'Unit';
		define category / across &categoryName;
		define avg / analysis mean '' format=percentn10.1;
	run;
	
	ods text="~S={font_size=12pt}{\pard Destinations reported by 20&currentYearFDS. graduates \par}";
	*table unit x category for most recent year;
	proc report data=dataSum.fdsMeansInt1;
		where &unit is not missing and 
			&unit ne 'univ' and
			gradYear= &currentYearFDS and 
			nInteractions = 1 and
			category in (&categoryText);
		column &unit avg,category;
		define &unit / group 'Unit';
		define category / across &categoryName;
		define avg / analysis mean '' format=percentn10.1;
	run;
%mend outcomes;

%outcomes(unit=collegeCurrent,
		  categoryText=&destination,
		  categoryName='Destination')



/*---------- Destination x subgroup -----------*/
	ods text="~S={font_size=16pt}{\pard\s2\b Demographic \par}"; *H2;

		ods text="~S={font_size=14pt}{\pard\s3 Subgroup heat map \par}"; *H3;

%macro outcomesSubgroupWithGaps(unit=,categoryText=,categoryName=,subgroup=,subgroupNames=,
	des='Table of percents for category x (unit x subgroup) and table of gaps for category x unit');
	%local n i unit nextSubgroup nextSubgroupName subgroup subgroupNames categoryText categoryName;
	%let n = %sysfunc(countw(&subgroup)); *n subgroups;
	%do i = 1 %to &n; *subgroup;
		%let nextSubgroup = %scan(&subgroup,&i); *select subgroup code;
		%let nextSubgroupName = %scan(&subgroupNames,&i,' '); *select subgroup name;
				
		ods text="~S={font_size=12pt}{\pard Destinations reported by 20&startYearFDS. to 20&currentYearFDS graduates by &nextSubgroupName \par}";
		
		*table category x (unit x subgroup) with percents;
		proc report data=dataSum.fdsMeansInt1 headline;
			where &unit is not missing and
				&unit ne 'univ' and
				startYear = &startYearFDS and
				endYear = &currentYearFDS and 
				nInteractions = 1 and
				&nextSubgroup is not missing and  
				category in (&categoryText);
			column category avg,&unit,&nextSubgroup;
			define &unit / across 'Unit';
			define category / group &categoryName;
			define avg / analysis '' format=percentn10.1;
			define &nextSubgroup / across;
		run;

		ods text="~S={font_size=12pt}{\pard Destination gaps reported by 20&startYearFDS. to 20&currentYearFDS graduates for &nextSubgroupName - alternate subgroup \par}";
		
		*table category x unit with gaps for given subgroup;
		proc report data=dataSum.fdsMeansInt1 headline style(column)={backgroundcolor=range. foreground=text.};
			where &unit is not missing and
				&unit ne 'univ' and
				startYear = &startYearFDS and
				endYear = &currentYearFDS and 
				nInteractions = 1 and
				&nextSubgroup is not missing and  
				category in (&categoryText);
			column category avg,&unit,(sum range),&nextSubgroup lastvar;
			define &unit / across 'Unit';
			define category / group &categoryName;
			define avg / analysis '' format=percentn10.1 ;
			define &nextSubgroup / across '' noprint;
			define lastvar / computed noprint;
			compute lastvar;
				if _c3_ < _c2_ then _c4_ = _c4_ * -1;
				if _c6_ < _c5_ then _c7_ = _c7_ * -1;
				if _c9_ < _c8_ then _c10_ = _c10_ * -1;
				if _c12_ < _c11_ then _c13_ = _c13_ * -1;
				if _c15_ < _c14_ then _c16_ = _c16_ * -1;
				if _c18_ < _c17_ then _c19_ = _c19_ * -1;
				if _c21_ < _c20_ then _c22_ = _c22_ * -1;
			endcomp;
		run;
	%end; *subgroup;
%mend outcomesSubgroupWithGaps;
	
%outcomesSubgroupWithGaps(unit=collegeCurrent,
						  categoryText=&destination,
						  categoryName='Destination',
						  subgroup=&subgroupAll, 
						  subgroupNames=&subgroupAllNames)
			  
			  
%macro outcomesSubgroupNoGaps(unit=,categoryText=,categoryName=,subgroup=,
	des='Tables of percents for category x unit for each subgroup');
	%local n i unit nextSubgroup subgroup categoryText categoryName;
	%let n = %sysfunc(countw(&subgroup)); *n subgroups;
	%do i = 1 %to &n; *subgroup;
		%let nextSubgroup = %scan(&subgroup,&i); *select subgroup code;
				
		ods text="~S={font_size=12pt}{\pard Destinations reported by 20&startYearFDS. to 20&currentYearFDS graduates for &nextSubgroup \par}";
		*table category x unit for given subgroup;
		proc report data=dataSum.fdsMeansInt1 headline;
			where &unit is not missing and
				&unit ne 'univ' and
				startYear = &startYearFDS and
				endYear = &currentYearFDS and 
				nInteractions = 1 and
				&nextSubgroup = 1 and  
				category in (&categoryText);
			column category avg,&unit;
			define &unit / across 'Unit';
			define category / group &categoryName;
			define avg / analysis '' format=percentn10.1;
		run;
	%end; *subgroup;
%mend outcomesSubgroupNoGaps;
	
	
%outcomesSubgroupNoGaps(unit=collegeCurrent,
						categoryText=&destination,
						categoryName='Destination',
		  				subgroup=&raceAll)
		  
%outcomesSubgroupNoGaps(unit=collegeCurrent,
						categoryText=&destination,
						categoryName='Destination',
						subgroup=&govaAll)



/*---------- Subgroup x destination -----------*/
		ods text="~S={font_size=14pt}{\pard\s3 Destination heat map \par}"; *H3;

%macro subgroupOutcomes(unit=,category=,
	des='Tables of gaps for unit x subgroup list within each category');
	%local n i unit category nextCategory;
	%let n = %sysfunc(countw(&category)); *n subgroups;
	%do i = 1 %to &n; *subgroup;
		%let nextCategory = %scan(&category,&i); *select subgroup code;

		ods text="~S={font_size=12pt}{\pard &nextCategory gaps reported by 20&startYearFDS. to 20&currentYearFDS graduates \par}";
		*table of unit x subgroups for gaps within each category;
		proc report data=dataSum.fdsMeansInt1 headline style(column)={backgroundcolor=range. foreground=text.};
			where &unit is not missing and
				&unit ne 'univ' and
				startYear = &startYearFDS and
				endYear = &currentYearFDS and 
				nInteractions = 1 and
				category = %sysfunc(quote(&nextCategory,"'"));
			column &unit avg,
				(athlet cadet female instate int oneGen rural transf urm urmaus urmous uss vet) 
				athlet1 cadet1 female1 instate1 int1 oneGen1 rural1 transf1 urm1 urmaus1 urmous1 uss1 vet1;
			define &unit / group 'Unit';
			define avg / analysis '' sum format=percentn10.1 ;
			
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
		run;	
	%end; *subgroup;
%mend subgroupOutcomes;
	
%subgroupOutcomes(unit=collegeCurrent,
			  	  category=&destinationAll)		



/*----- Destination x subgroup x subgroup -----*/
		ods text="~S={font_size=14pt}{\pard\s3 Subgroup combinations \par}"; *H3;
		
%macro outcomesSubgroup2WithGaps(unit=,destination=,group1=,group2=,
	des='Tables for unit x (subgroup x subgroup) percents and 3 columns of gaps, 1 table per category');
	%local n i j groupID1 groupID2 unit destination nextDest ngroup group1 group2;
	%let ngroup = %sysfunc(countw(&group1)); *ngroup subgroups;
	%let n = %sysfunc(countw(&destination)); *n destinations;
	
	%do j = 1 %to &ngroup; *subgroups;
		%let groupID1 = %scan(&group1,&j); *subgroup 1;
		%let groupID2 = %scan(&group2,&j); *subgroup 2;
	
		%do i = 1 %to &n; *destination;
			%let nextDest = %scan(&destination,&i); *select destination code;
			
			ods text="~S={font_size=12pt}{\pard &nextDest reported by 20&startYearFDS. to 20&currentYearFDS graduates for &groupID1 x &groupID2 \par}";
			*table unit x (subgroup x subgroup) percents and gaps by category;
			proc report data=dataSum.fdsMeansInt2 headline;
			where &unit is not missing and
				&unit ne 'univ' and
				startYear = &startYearFDS and
				endYear = &currentYearFDS and 
				nInteractions = 2 and
				&groupID1 is not missing and
				&groupID2 is not missing and 
				category = %sysfunc(quote(&nextDest,"'"));
			column &unit avg,&groupID1,&groupID2 blank gap1 gap2 gap3;
			define &unit / group 'Unit';
			define avg / analysis '' sum format=percentn10.1 ;
			define blank / '';
			define &groupID1 / across;
			define &groupID2 / across;
			define gap1 / '01-00' computed format=percentn10. style(column)={backgroundcolor=range. foreground=text.};
			compute gap1;
				gap1 = _c3_ - _c2_;
			endcomp;
			define gap2 / '10-00' computed format=percentn10. style(column)={backgroundcolor=range. foreground=text.};
			compute gap2;
				gap2 = _c4_ - _c2_;
			endcomp;
			define gap3 / '11-00' computed format=percentn10. style(column)={backgroundcolor=range. foreground=text.};
			compute gap3;
				gap3 = _c5_ - _c2_;
			endcomp;
		run;
		%end; *destinations;
	%end; *subgroups;
%mend outcomesSubgroup2WithGaps;
	
%outcomesSubgroup2WithGaps(unit=collegeCurrent,
				  		   destination=&destinationShort, 
						   group1=&subgroup1, 
						   group2=&subgroup2)	
		
		
%macro outcomesSubgroup2NoGaps(unit=,destination=,group1=,group2=,
	des='Tables of unit x (subgroup x subgroup) percents by category');
	%local n i j unit destination nextDest group1 group2 groupID2 ngroup;
	%let ngroup = %sysfunc(countw(&group2));
	%let n = %sysfunc(countw(&destination)); *n destinations;
	
	%do j = 1 %to &ngroup; *subgroups;
		%let groupID2 = %scan(&group2,&j); *subgroup 2;
	
		%do i = 1 %to &n; *destination;
			%let nextDest = %scan(&destination,&i); *select destination code;
			
			ods text="~S={font_size=12pt}{\pard &nextDest reported by 20&startYearFDS. to 20&currentYearFDS graduates for &groupID2 x race \par}";
			*table unit x (subgroup 2 x subgroup 1) by category;
			proc report data=dataSum.fdsMeansInt2 headline;
			where &unit is not missing and
				&unit ne 'univ' and
				startYear = &startYearFDS and
				endYear = &currentYearFDS and 
				nInteractions = 2 and
				&groupID2 is not missing and 
				category = %sysfunc(quote(&nextDest,"'"));
			column &unit avg,&groupID2,(asian black hispani island native tworace white) lastvar;
			define &unit / group 'Unit';
			define avg / analysis '' sum format=percentn10.1 ;
			define &groupID2 / across;
			define asian / across missing;
			define black / across missing;
			define hispani / across missing;
			define island / across missing;
			define native / across missing;
			define tworace / across missing;
			define white / across missing;
			define lastvar / computed noprint;
			compute lastvar;
				_c2_ = .;
				_c5_ = .;
				_c8_ = .;
				_c11_ = .; 
				** continue when have issues fixed;
			endcomp;
		run;
			
		%end; *destinations;
	%end; *subgroups;
%mend outcomesSubgroup2NoGaps;
	
%outcomesSubgroup2NoGaps(unit=collegeCurrent,
					     destination=&destinationShort, 
					     race=&raceAll, 
					     group2=&subgroupCrossRace)	
		
		
		
/*------------ Destination x GOVA ------------*/	
	
		ods text="~S={font_size=14pt}{\pard\s3 GOVA heat map \par}"; *H3;



/*--------- Destination x discipline ----------*/
	ods text="~S={font_size=16pt}{\pard\s2\b Discipline \par}"; *H2;
	
		ods text="~S={font_size=14pt}{\pard\s3 Destination \par}"; *H3;
%outcomes(unit=generalDiscipline,
		  categoryText=&destination,
		  categoryName='Destination')
		
		
		
/*--- Destination x discipline x subgroup -----*/
		ods text="~S={font_size=14pt}{\pard\s3 Subgroup heat map \par}"; *H3;
		
%outcomesSubgroupWithGaps(unit=generalDiscipline,
						  categoryText=&destination,
						  categoryName='Destination',
						  subgroup=&subgroupAll, 
			  			  subgroupNames=&subgroupAllNames)

%outcomesSubgroupNoGaps(unit=generalDiscipline,
						categoryText=&destination,
						categoryName='Destination',
						subgroup=&raceAll)
		  
%outcomesSubgroupNoGaps(unit=generalDiscipline,
						categoryText=&destination,
						categoryName='Destination',
						subgroup=&govaAll)
			  
		
		
/*--- Destination x subgroup x discipline -----*/
		ods text="~S={font_size=14pt}{\pard\s3 Destination heat map \par}"; *H3;
		
%subgroupOutcomes(unit=generalDiscipline,
				  category=&destinationAll)	
			  
			  
		
/*------ Destination x discipline x GOVA ------*/
		ods text="~S={font_size=14pt}{\pard\s3 GOVA heat map \par}"; *H3;



/*------------- EL - self-report --------------*/
ods text="~S={font_size=18pt}{\pard\s1\b Experiential Learning - Self-report \par}"; *H1;



/*---------------- EL - course ----------------*/
ods text="~S={font_size=18pt}{\pard\s1\b Experiential Learning - Courses \par}"; *H1;



ods rtf close;

/*
proc sql;
	select collegeCurrent, avg, category, instate
	from dataSum.fdsMeansInt1
	where category = 'contEd' and startYear=18 and endyear=20 and collegeCurrent is not missing and
	instate is not missing;
quit;
*/

