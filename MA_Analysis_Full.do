*====== 数据清洗 ======
Checking variable types and missing values
describe
misstable summarize

Generate core variable (goodwill_ratio) 
gen goodwill_ratio = goodwill / total_assets

Shrinkage treatment (1% level
winsor2 tobin_qA goodwill_ratio size leverage cash_flow equity listing_age, replace cuts(0.5 99.5)

Save data
save final_data.dta, replace

*====== 主回归分析 ======
Logarithmic
gen log_cash_flow = log(abs(cash_flow) + 1) * sign(cash_flow)
gen log_equity = log(equity)

Descriptive statistics (including control variables)
summarize tobin_qA goodwill_ratio size leverage log_cash_flow log_equity listing_age

Export results
logout, save(Descriptive statistics) word replace: tabstat tobin_qA goodwill_ratio size leverage log_cash_flow log_equity listing_age, statistics(mean median sd min max N) columns(statistics)

Correlation coefficient matrix
correlate tobin_qA goodwill_ratio  size leverage cash_flow equity listing_age

Direct coding
encode industry_code, gen(industry_num)

Benchmark regression (controlling for industry and year fixed effects)
reghdfe tobin_qA goodwill_ratio  size leverage cash_flow equity listing_age industry_num year
collin tobin_qA goodwill_ratio size leverage cash_flow equity listing_age industry_num year

Results
outreg2 using Regression outcome.xlsx, replace dec(3) excel drop(i.industry_num i.year)

*====== 稳健性检验 ======
Robustness test
Substitution of explained variables（tobin_qB）
regress tobin_qB goodwill_ratio size leverage cash_flow equity listing_age i.industry_num i.year, robust

Results
outreg2 using Substitution of tobin_qA.xlsx, replace ctitle(替换Y=tobin_qB) dec(3) excel

Generate lagged variables (assuming year variable is year)
sort stkcd year
by stkcd: gen lag_goodwill_ratio = goodwill_ratio[_n-1]
by stkcd: gen lag_tobin_qA = tobin_qA[_n]

lagrangian regression (math.)
reghdfe lag_tobin_qA lag_goodwill_ratio size leverage cash_flow equity listing_age industry_num year

Results
outreg2 using Robustness test.xlsx, replace ctitle(滞后效应) dec(3) excel

*====== 调节效应 ======
Moderating effect
Method 1, use original value if data is available, set to 0 if no data is available
Generate analyst attention variable (original value + missing value to compensation)
gen analyst_num = analyst_coverage 
replace analyst_num = 0 if missing(analyst_num)

Generate interaction
gen interaction_num = goodwill_ratio * analyst_num

Moderated effects regression (controlling for individual, industry, and year fixed effects)
Model 1: reghdfe (individual + industry + year)
reghdfe tobin_q goodwill_ratio analyst_num interaction size leverage log_cash_flow log_equity listing_age, absorb(id_num industry_num year) vce(robust)
outreg2 using "Comparison of results 1.xlsx", replace excel ctitle("模型1: reghdfe") keep(goodwill_ratio analyst_num interaction)

Model 2：xtreg
xtreg tobin_q goodwill_ratio analyst_num interaction size leverage cash_flow_100 equity_100 listing_age i.year, fe robust
outreg2 using "Comparison of results 2.xlsx", append excel ctitle("模型2: xtreg") keep(goodwill_ratio analyst_num interaction)

Model 3：areg
areg tobin_q goodwill_ratio analyst_num interaction size leverage log_cash_flow log_equity listing_age i.year, absorb(id_num) robust

Method 2, dummy variables (yes=1, no=0)
Step 1: Generate analyst-focused dummy variables
gen analyst_dummy = !missing(analyst_coverage)

Generate interaction
gen interaction_dummy = goodwill_ratio * analyst_dummy

Model 1：OLS
reg tobin_q c.goodwill_ratio##i.analyst_dummy size leverage log_cash_flow log_equity listing_age i.industry_num i.year, robust

outreg2 using "Dummy variable outcome 1.xlsx", replace excel

Model 2：panel fixed effect
xtreg tobin_q c.goodwill_ratio##i.analyst_dummy size leverage log_cash_flow log_equity listing_age i.year, fe robust

outreg2 using "Dummy variable outcome 2.xlsx", append excel

Model 3：Reghdfe
reghdfe tobin_q c.goodwill_ratio##i.analyst_dummy size leverage cash_flow_100 equity_100 listing_age, absorb(id_num industry_num year) vce(robust)

outreg2 using "Dummy variable outcome 3.xlsx", append excel

Model 4：areg
areg tobin_q c.goodwill_ratio##i.analyst_dummy size leverage cash_flow_100 equity_100 listing_age i.year, absorb(id_num) robust

outreg2 using "Dummy variable outcome 4.xlsx", append excel

outreg2 using "outcome .xlsx", append excel ctitle("Model 3: areg") keep(goodwill_ratio analyst_num interaction)


