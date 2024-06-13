-- multi-step query

-- step 1: on group level, identify the top 100 commercial customer groups (commerical_ind = 1) based on the group's total deposit balance.
-- step 2: on customer level, (commerical_ind = 1), calculate their total deposit balance, count of deposit accounts, and minimum/earliest account open date.
-- step 3: on customer level, rank customers by deposit balance, then count of accts, then dep acct open date.
-- step 4: select the top customer for each group
-- step 5: assign row number, using window function Row_Number and Partition by Customer_Group, filter the query to generate only rownum=1.

with top_groups as (
  select
  	dim_customer_group.group_id,
  	dim_customer_group.group_system,
  	dim_customer_group.group_name,
  	sum(dep_bal.balance) as Group_Total_Commercial_Deposit_Balance
  from dim_customer_group
  	join dim_customer
  		on dim_customer_group.group_id = dim_customer.group_id
  		and dim_customer_group.group_system = dim_customer.group_system
  	join daily_deposit_balance as dep_bal
  		on dim_customer.customer_id = daily_deposit_balance.customer_id
  		and dim_customer.customer_system = daily_deposit_balance.customer_system
  		and dep_bal.commercial_ind = 1
  		and end_date = '2023-12-31'
  group by Group_Total_Commercial_Deposit_Balance DESC 
  limit 100 OFFSET 0
  ),
  
  comm_cust_dep_accts as (
    select 
    	customer_id,
    	customer_system,
    	SUM(dep_bal.balance) as comm_cust_dep,
    	count(distinct dep_bal.deposit_acct_nbr) as count_dep_accts,
    	MIN(dep_bal.acct_open_date) as oldest_dep_acct
    from daily_deposit_balance
    where 
    	end_date = '2023-12-31'
    	and commercial_ind = 1
    group by 
    	customer_id,
    	customer_system
  ),
  
  ranked_customer_deposits_by_group as (
    SELECT
    	dim_customer_group.group_id,
    	dim_customer_group.group_system,
    	comm_cust_dep_accts.customer_id,
    	comm_cust_dep_accts.customer_system,
    	comm_cust_dep_accts.comm_cust_dep,
    	comm_cust_dep_accts.count_dep_accts,
    	comm_cust_dep_accts.oldest_dep_acct
    	ROW_NUMBER() OVER (PARTITION BY 
                           dim_customer_group.group_id, 
                           dim_customer_group.group_system 
                           order by 
                           comm_cust_dep_accts.comm_cust_dep DESC, 
                           comm_cust_dep_accts.count_dep_accts DESC,
                           comm_cust_dep_accts.oldest_dep_acct ASC
                          ) as cust_rank_in_group
    from comm_cust_dep_accts
 	join dim_customer
         on comm_cust_dep_accts.customer_id = dim_customer.customer_id
    join dim_customer_group
         on dim_customer.group_id = dim_customer_group.group_id
   ),
   
   top_customer_for_group as (
     SELECT
     	group_id,
    	group_system,
    	customer_id,
    	customer_system,
    	comm_cust_dep,
    	count_dep_accts,
    	oldest_dep_acct
     from ranked_customer_deposits_by_group
     where cust_rank_in_group = 1
     )
     
SELECT
  top_groups.group_id,
  top_groups.group_system,
  top_groups.group_name,
  top_groups.Group_Total_Commercial_Deposit_Balance,
  top_customer_for_group.Customer_id,
  top_customer_for_group.Customer_system,
  dim_customer.Customer_name
from top_groups
	left join top_customer_for_group
		on top_groups.customer_id = top_customer_for_group.customer_id
		on top_groups.customer_system = top_customer_for_group.customer_system
	left join dim_customer
		on top_customer_for_group.group_id = dim_customer.group_id
		on top_customer_for_group.group_system = dim_customer.group_system;
 order by 
 	 top_groups.Group_Total_Commercial_Deposit_Balance DESC;