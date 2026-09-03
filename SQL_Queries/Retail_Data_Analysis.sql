use Retail_Analysis

-- DATA PREPRATION AND UNDERSTANDING --

select TOP 1* from Customer
select TOP 1* from prod_cat_info
select TOP 1* from Transactions

-- Q1. What is the total number of rows in each of the 3 tables in the database?
-- =====================================================

select count(*) as cnt from Customer
union
select count(*) as cnt from prod_cat_info
union
select count(*) as cnt from Transactions


-- Q2. What is the total number of transactions that have a return?
-- =====================================================

select count(distinct(transaction_id)) as tran_id from Transactions
where Qty<0


-- Q3. As you would have noticed, the dates provided across the datasets are not in a correct format. 
--As first steps, pls convert the date variables into valid date formats before proceeding ahead.
-- =====================================================

select CONVERT(date,tran_date,105) as tran_date from Transactions


-- Q4. What is the time range of the transaction data available for analysis? Show the output in number of days, 
--months and years simultaneously in different columns.
-- =====================================================

select DATEDIFF(YEAR,MIN(CONVERT(date,tran_date,105)),MAX(CONVERT(date,tran_date,105))) as diff_Year, 
       DATEDIFF(MONTH,MIN(CONVERT(date,tran_date,105)),MAX(CONVERT(date,tran_date,105))) as diff_Month,
       DATEDIFF(DAY,MIN(CONVERT(date,tran_date,105)),MAX(CONVERT(date,tran_date,105))) as diff_Day 
       from transactions


-- Q5. Which product category does the sub-category “DIY” belong to?
-- =====================================================

select prod_cat,prod_subcat from prod_cat_info
where prod_subcat = 'DIY'





--DATA ANALYSIS--
-- Q1. Which channel is most frequently used for transactions?
-- =====================================================

select top 1 store_type as channel, count(store_type) as Nof from Transactions
group by Store_type
order by Store_type asc


-- Q2. What is the count of Male and Female customers in the database?
-- =====================================================

select gender,count(*) as cng from Customer
where gender is not null
group by gender


-- Q3. From which city do we have the maximum number of customers and how many?
-- =====================================================
select top 1 city_code,count(*) as cnc from Customer
group by city_code
order by cnc desc

-- Q4. How many sub-categories are there under the Books category?
-- =====================================================

select prod_cat,prod_subcat from prod_cat_info
where prod_cat = 'Books'

-- Q5. What is the maximum quantity of products ever ordered?
-- =====================================================

select prod_cat_code ,max(qty) as max_qty from Transactions
group by prod_cat_code


-- Q6. What is the net total revenue generated in categories Electronics and Books?
-- =====================================================

select prod_cat,sum(cast(total_amt as float)) as total_revenue from prod_cat_info as t1
join Transactions as t2
on t1.prod_cat_code = t2.prod_cat_code
where prod_cat='Electronics' or prod_cat='Books'
group by prod_cat


-- Q7. How many customers have >10 transactions with us, excluding returns?
-- =====================================================

select count(*) as total_cust from(
select cust_id, count(transaction_id) as total_tran from Transactions
where qty>0
group by cust_id
having count(transaction_id)>10
) as t5


-- Q8. What is the combined revenue earned from 
--the “Electronics” & “Clothing” categories, from “Flagship stores”?
-- =====================================================

select sum(cast(total_amt as float)) as total_revenue from prod_cat_info as t1
join Transactions as t2
on t1.prod_cat_code = t2.prod_cat_code
where prod_cat='Electronics' or prod_cat='Clothing' and store_type= 'flagship store' and qty>0


-- Q9. What is the total revenue generated from “Male” customers in “Electronics” category? 
--Output should display total revenue by prod sub-cat.
-- =====================================================

select prod_subcat, sum(cast(total_amt as float)) as total_revenue 
from Customer as t1
join Transactions as t2
on t1.customer_Id=t2.cust_id
join prod_cat_info as t3
on t2.prod_cat_code=t3.prod_cat_code
where gender='M' and prod_cat='Electronics'
group by prod_subcat


-- 10. What is percentage of sales and returns by product sub category; 
--display only top 5 sub categories in terms of sales?
-- =====================================================

--percentage of sales--
select t5.prod_subcat,percentage_sales,percentage_returns from(
select top 5 prod_subcat,(sum(cast(total_amt as float))/(select sum(cast(total_amt as float))as total_sales from Transactions where qty>0)) as percentage_sales
from prod_cat_info as t1
join Transactions as t2
on t1.prod_cat_code=t2.prod_cat_code
where qty>0
group by prod_subcat
order by percentage_sales desc
) as t5
join
--percentage of returns--
(select prod_subcat,(sum(cast(total_amt as float))/(select sum(cast(total_amt as float))as total_sales from Transactions where qty<0)) as percentage_returns
from prod_cat_info as t1
join Transactions as t2
on t1.prod_cat_code=t2.prod_cat_code
where qty<0
group by prod_subcat
) as t6
on t5.prod_subcat=t6.prod_subcat

-- 11. For all customers aged between 25 to 35 years find what is the net total revenue generated by 
--these consumers in last 30 days of transactions 
--from max transaction date available in the data?
-- =====================================================

--Age of Customer--
select C.cust_id,age,revenue,tran_date from(
select * from(
select cust_id,DATEDIFF(year,dob,max_date) as age,revenue from(
select cust_id,dob,max(CONVERT(date,tran_date,105)) as max_date ,sum(cast(total_amt as float)) as revenue
from Customer as t1
join Transactions as t2
on t1.customer_Id=t2.cust_id
where qty>0
group by cust_id,dob) as A
) as B
where age between 25 and 35
) as C
join (
-- 30 days of transactions--
select cust_id,CONVERT(date,tran_date,105) as tran_date
from Transactions
group by cust_id,CONVERT(date,tran_date,105)
having CONVERT(date,tran_date,105) >= (select DATEADD(day,-30,max(CONVERT(date,tran_date,105))) as cuttoff_date from Transactions)
) as D
on c.cust_id=d.cust_id


-- Q12. Which product category has seen the max value of returns in the last 3 months of transactions?
-- =====================================================

select top 1 prod_cat,sum(Returns) as qty_retuns from(
select prod_cat,CONVERT(date,tran_date,105) as tran_date,sum(qty) as Returns
from prod_cat_info as t1
join Transactions as t2
on t1.prod_cat_code=t2.prod_cat_code
where qty<0
group by prod_cat,CONVERT(date,tran_date,105)
having CONVERT(date,tran_date,105) >= (select DATEADD(MONTH,-3,max(CONVERT(date,tran_date,105))) as cuttoff_date from Transactions)
) as A
group by prod_cat
order by qty_retuns asc


-- Q13. Which store-type sells the maximum products; by value of sales amount and by quantity sold?
-- =====================================================

select top 1 store_type,sum(cast(total_amt as float)) as sales_amt,sum(qty) as return_qty from Transactions
where qty>0
group by store_type
order by return_qty desc,sales_amt desc

-- Q14. What are the categories for which average revenue is above the overall average.
-- =====================================================
select prod_cat_code,AVG(cast(total_amt as float))as avg_sales from Transactions
group by prod_cat_code
having AVG(cast(total_amt as float)) >= (select AVG(cast(total_amt as float)) as sum_sales from Transactions where qty>0)


-- Q15. Find the average and total revenue by each subcategory for 
--the categories which are among top 5 categories in terms of quantity sold.
-- =====================================================

select prod_subcat_code,AVG(cast(total_amt as float)) as avg_revenue,sum(cast(total_amt as float)) as sum_revenue from Transactions
where qty>0 and prod_cat_code in(select top 5 prod_cat_code from Transactions
                                 where qty>0
                                 group by prod_cat_code 
                                 order by sum(qty) desc
                                 )
group by prod_subcat_code

