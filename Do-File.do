
***  Part 1 Data Preparation

** Removing data to match the academic paper

* Install fre
ssc install fre

* Remove individuals that are self employed, retired, in education, maternity leave, in government training
fre jbstat
drop if (jbstat ==1 | jbstat==4 | jbstat==5 | jbstat==7 | jbstat==9 | jbstat==11)

* Only consider individuals that are employed on the interview date
drop if (jbstat ==3 | jbstat ==6 | jbstat ==8 | jbstat ==10 | jbstat ==97)

* Keeping individuals of working age up until the current state pention age
keep if (sex==1 & dvage>=16 & dvage<=66) | (sex==2 & dvage>=16 & dvage<=66)

** Cleaning variables

* Cleaning variables i want to remove < 0 
local vars pidp hidp sex dvage istrtdaty istrtdatm istrtdatd jbstat racel_dv health aidhh aidxhh trainany jbsect jbft_dv jbsat j2has sclfsato jbterm1 jbbgy jbsize gor_dv mastat_dv nchild_dv hiqual_dv jbrgsc_dv scghq1_dv scghq2_dv
foreach v of local vars {
    replace `v' = . if `v' < 0
}

* For the income variables we will remove <= 0 
replace fimngrs_dv=. if fimngrs_dv<=0
replace fimnnet_dv =. if fimnnet_dv<=0
replace fimnlabgrs_dv=. if fimnlabgrs_dv<=0
replace payg_dv=. if payg_dv<=0
replace j2pay_dv=. if j2pay_dv<=0
replace j2pay = . if j2pay<=0

* Changing inapplicable for overtime hours to 0 hours 
replace jbot = 0 if jbot==-8
replace jbotpd = 0 if jbotpd==-8

* Cleanig hours worked variables
replace jbhrs = . if jbhrs<0
replace jbot = . if jbot<0
replace jbotpd = . if jbotpd<0
replace j2hrs = . if j2hrs<0

* check all negative values are removed
sum

* Checking inconsistencies in the data 
fre jbstat
fre jbbgy
misstable sum payg_dv

** Variable creation 

* Gender
gen male = sex==1
gen Female = sex==2
label variable male "1 if male"
label variable Female "1 if female"
 
* IHS transformation of average hourly wage
gen Avg_hourlywage = (payg_dv/(30.4375/7))/(jbhrs + 1.5*jbot)
sum Avg_hourlywage
gen IHS_Avg_hourlywage = asinh(Avg_hourlywage)
sum IHS_Avg_hourlywage
label variable IHS_Avg_hourlywage "IHS transformation of average hourly wage"

* Log mental health
sum scghq2_dv
gen Inverted_caseness = 12 - scghq2_dv
gen log_mental_health = log(Inverted_caseness+((Inverted_caseness^2+1)^0.5))
label variable log_mental_health "Log of the inverted caseness score"

* Age
rename dvage age
* Age polynomials will be created after ensuring age increase by 1 per wave

* Has a degree
gen Has_a_degree = (hiqual_dv ==1 | hiqual_dv == 2)
label variable Has_a_degree "has a first degree or higher degree"

* Children 
rename nchild_dv Children 

* London
gen London = (gor_dv==7)
label variable London "1 if living in London"

* White
gen white = (racel_dv ==1 | racel_dv ==2 | racel_dv ==3 | racel_dv ==4)
label variable white "1 if white"

* Widowed
gen widowed = (mastat_dv ==6 | mastat_dv ==9)
label variable widowed "1 if widowed or surviving civil partner"

* Divorced or seperated
gen divorced_separated = (mastat_dv ==4 | mastat_dv ==5 | mastat_dv ==7 | mastat_dv ==8)
label variable divorced_separated "1 if divorced, separated, or dissolved/separated from civil partner"

* Never Married
gen never_married = (mastat_dv ==1 | mastat_dv ==3 | mastat_dv ==7 | mastat_dv ==8 | mastat_dv ==9 | mastat_dv==10)
label variable never_married "1 if never married"

* Expierence
gen Experience = istrtdaty - jbbgy
label variable Experience "spell in current job in years"

* Expierence square
gen Experience_square = (Experience^2)/100
label variable Experience_square "years in current job squared and divided by 100"

* Experience cube
gen Experience_cube = (Experience^3)/100
label variable Experience_cube "Years in current job cubed and divided by 100"

* Private sector
gen Private_sector = (jbsect ==1)
label variable Private_sector "1 if works for a private business or other limited company"

* Professional
gen Professional = (jbrgsc_dv ==1)
label variable Professional "1 if professional"

* Manager
gen Manager = (jbrgsc_dv==2)
label variable Manager "1 if managerial and technical occupation"

* Skilled non-manual 
gen skilled_non_manual = (jbrgsc_dv ==3)
label variable skilled_non_manual "1 if skilled non-manual"

* Skilled manual
gen skilled_manual = (jbrgsc_dv ==4)
label variable skilled_manual "1 if skilled manual"

* Part time job 
gen part_time_job = (jbft_dv ==2)
label variable part_time_job "1 if part time"

* Number of employees
replace jbsize = . if jbsize>=10
gen Number_of_employees = .
replace Number_of_employees = 1.5 if jbsize == 1
replace Number_of_employees = 6.0 if jbsize == 2
replace Number_of_employees = 17.0 if jbsize == 3
replace Number_of_employees = 37.0 if jbsize == 4
replace Number_of_employees = 75.0 if jbsize == 5
replace Number_of_employees = 149.5 if jbsize == 6
replace Number_of_employees = 349.5 if jbsize == 7
replace Number_of_employees = 749.5 if jbsize == 8
replace Number_of_employees = 1000 if jbsize == 9
label variable Number_of_employees "Number of employees at workplace (max 1,000), categories recoded as midpoint"

* Job training (lag)
gen job_training_lag = (trainany==1)
label variable job_training_lag "1 if received education or training in the last year"

* Removing observations that have missing values for desired variables
drop if IHS_Avg_hourlywage ==.
drop if log_mental_health ==.
drop if age ==.
drop if Has_a_degree ==.
drop if Children ==.
drop if London ==.
drop if white ==.
drop if widowed ==.
drop if divorced_separated ==.
drop if never_married ==.
drop if Private_sector ==.
drop if Professional ==.
drop if Manager ==.
drop if skilled_non_manual ==.
drop if skilled_manual ==.
drop if part_time_job ==.
drop if Number_of_employees ==.
drop if job_training_lag ==.

** Creating balenced panel data
xtset pidp wave
sort pidp
by pidp: gen Wave_appearances=_N
tab Wave_appearances
drop if Wave_appearances <8
xtset pidp wave 
label variable Wave_appearances "How many waves appeared in"
order wave, after(pidp)
order age, after(wave)

** Data checking

* Checking age increases by one for each respondent in each consecutive wave 
by pidp (wave): gen age_difference = age - l.age
tab age_difference
label variable age_diff "Original difference in age between consecutive waves for each respondent"

* Ensuring age increases by one for each respondent in each consecutive wave
gen age1 = .

levelsof wave, local(waves)  
foreach w of local waves {
replace age1 = age if wave==`w' & missing(age1)
replace age1 = l.age1 + 1 if wave>`w' & missing(age1)
}
label variable age1 "age at each wave ensuring age increases by 1 each year from wave 1 to 8"

by pidp (wave): gen age_difference1 = age1 - l.age1
tab age_difference1
label variable age_difference1 "the difference between age and its lag"

* Creating age, age square, Age cube 
drop age 
drop age_difference
rename age1 age
rename age_difference1 age_difference
gen age_squared = (age^2)/100
gen age_cubed = (age^3)/100
label variable age "age from date of birth"
label variable age_squared "age squared divided by 100"
label variable age_cubed "age cubed divided by 100"

* Ensuring gender remains consistant throughout waves
by pidp (wave): replace sex = sex[1]
by pidp (wave): gen sex_difference = sex - l.sex
tab sex_difference
 label variable sex_difference "the difference in gender between consecutive waves"
 
*** Part 2 estimation

* Generate the individual means for all time-varying variables
foreach v of varlist log_mental_health age age_squared age_cubed Has_a_degree Children London white widowed divorced_separated never_married Private_sector Professional Manager skilled_non_manual skilled_manual part_time_job Number_of_employees job_training {
    bysort pidp: egen m`v' = mean(`v')
}

* Check data is balenced panel before estimations 
xtset pidp wave

** Male Estimates 

* Male POLS cluster
reg IHS_Avg_hourlywage log_mental_health age age_squared age_cubed Has_a_degree Children London white widowed divorced_separated never_married Private_sector Professional Manager skilled_non_manual skilled_manual part_time_job Number_of_employees job_training_lag wave if male ==1, vce(cluster pidp)
estimates store Male_POLScluster

* Random effects male cluster
xtreg IHS_Avg_hourlywage log_mental_health age age_squared age_cubed Has_a_degree Children London white widowed divorced_separated never_married Private_sector Professional Manager skilled_non_manual skilled_manual part_time_job Number_of_employees job_training_lag wave if male ==1, vce(cluster pidp)
estimates store Male_REcluster

* Test for panel data (POLS vs RE) male and cluster
xttest0 

* Fixed effects male cluster
xtreg IHS_Avg_hourlywage log_mental_health age age_squared age_cubed Has_a_degree Children London white widowed divorced_separated never_married Private_sector Professional Manager skilled_non_manual skilled_manual part_time_job Number_of_employees job_training_lag wave if male ==1, vce(cluster pidp) fe
estimates store Male_FEcluster

* Correlated random effects male cluster
xtreg IHS_Avg_hourlywage log_mental_health age age_squared age_cubed Has_a_degree Children London white widowed divorced_separated never_married Private_sector Professional Manager skilled_non_manual skilled_manual part_time_job Number_of_employees job_training_lag mlog_mental_health mage mage_squared mage_cubed mHas_a_degree mChildren mLondon mwhite mwidowed mdivorced_separated mnever_married mPrivate_sector mProfessional mManager mskilled_non_manual mskilled_manual mpart_time_job mNumber_of_employees mjob_training_lag if male ==1, re vce(cluster pidp) 
estimates store Male_CREcluster

** Regression based hausman test male

* with heteroskedasticity and serial correlation robust SEs
xtreg IHS_Avg_hourlywage log_mental_health age age_squared age_cubed Has_a_degree Children London white widowed divorced_separated never_married Private_sector Professional Manager skilled_non_manual skilled_manual part_time_job Number_of_employees job_training_lag mlog_mental_health mage mage_squared mage_cubed mHas_a_degree mChildren mLondon mwhite mwidowed mdivorced_separated mnever_married mPrivate_sector mProfessional mManager mskilled_non_manual mskilled_manual mpart_time_job mNumber_of_employees mjob_training_lag if male ==1, re vce(cluster pidp)
test mlog_mental_health mage mage_squared mage_cubed mHas_a_degree mChildren mLondon mwhite mwidowed mdivorced_separated mnever_married mPrivate_sector mProfessional mManager mskilled_non_manual mskilled_manual mpart_time_job mNumber_of_employees mjob_training_lag

* Install esttab 
search esttab

** Male estimates table with clustered standard errors
esttab Male_POLScluster Male_REcluster Male_FEcluster Male_CREcluster using workshop5.rtf, replace star(* 0.1 ** 0.05 *** 0.01) se mtitles r2 obslast compress 

** Female estimates

* Female POlS cluster
reg IHS_Avg_hourlywage log_mental_health age age_squared age_cubed Has_a_degree Children London white widowed divorced_separated never_married Private_sector Professional Manager skilled_non_manual skilled_manual part_time_job Number_of_employees job_training_lag wave if Female ==1, vce(cluster pidp)
estimates store Female_POLScluster

* Random effects female cluster
xtreg IHS_Avg_hourlywage log_mental_health age age_squared age_cubed Has_a_degree Children London white widowed divorced_separated never_married Private_sector Professional Manager skilled_non_manual skilled_manual part_time_job Number_of_employees job_training_lag wave if Female ==1, vce(cluster pidp)
estimates store Female_REcluster

* Test for panel data (POLS vs RE) Female and cluster
xttest0 

* Fixed effects female cluster
xtreg IHS_Avg_hourlywage log_mental_health age age_squared age_cubed Has_a_degree Children London white widowed divorced_separated never_married Private_sector Professional Manager skilled_non_manual skilled_manual part_time_job Number_of_employees job_training_lag wave if Female ==1, vce(cluster pidp) fe
estimates store Female_FEcluster

* Correlated random effects female cluster
xtreg IHS_Avg_hourlywage log_mental_health age age_squared age_cubed Has_a_degree Children London white widowed divorced_separated never_married Private_sector Professional Manager skilled_non_manual skilled_manual part_time_job Number_of_employees job_training_lag mlog_mental_health mage mage_squared mage_cubed mHas_a_degree mChildren mLondon mwhite mwidowed mdivorced_separated mnever_married mPrivate_sector mProfessional mManager mskilled_non_manual mskilled_manual mpart_time_job mNumber_of_employees mjob_training_lag if Female ==1, re vce(cluster pidp) 
estimates store Female_CREcluster

** Regression based hausman test female

* with heteroskedasticity and serial correlation robust SEs
xtreg IHS_Avg_hourlywage log_mental_health age age_squared age_cubed Has_a_degree Children London white widowed divorced_separated never_married Private_sector Professional Manager skilled_non_manual skilled_manual part_time_job Number_of_employees job_training_lag mlog_mental_health mage mage_squared mage_cubed mHas_a_degree mChildren mLondon mwhite mwidowed mdivorced_separated mnever_married mPrivate_sector mProfessional mManager mskilled_non_manual mskilled_manual mpart_time_job mNumber_of_employees mjob_training_lag if Female ==1, re vce(cluster pidp)
test mlog_mental_health mage mage_squared mage_cubed mHas_a_degree mChildren mLondon mwhite mwidowed mdivorced_separated mnever_married mPrivate_sector mProfessional mManager mskilled_non_manual mskilled_manual mpart_time_job mNumber_of_employees mjob_training_lag

** Female estimates table with clustered standard errors
esttab Female_POLScluster Female_REcluster Female_FEcluster Female_CREcluster using workshop5.rtf, replace star(* 0.1 ** 0.05 *** 0.01) se mtitles r2 obslast compress 

** Checking why white and wave are dropped in FE
xtsum white age wave
