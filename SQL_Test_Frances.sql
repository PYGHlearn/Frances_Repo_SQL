--EW SQL Test.

--Calculate total loan balance per customer.

WITH CustTotalLoan AS (
    SELECT
        dlb.customer_id, 
        dlb.customer_system, 
        SUM(dlb.balance) as CustLoanBalTotal
    FROM
        daily_loan_balance as dlb
    WHERE
        dlb.end_date = '2023-12-31'
    GROUP BY
        dlb.customer_id, dlb.customer_system
),
    
--Rank loan accounts by balance, account open date, then acct nbr.

LoanAcctsRanked AS (
    SELECT
        dlb.customer_id, 
        dlb.customer_system, 
        dlb.balance, 
        dlb.acct_open_date, 
        dlb.loan_acct_nbr, 
        ROW_NUMBER() OVER(
            PARTITION BY 
                dlb.customer_id, dlb.customer_system
            ORDER BY 
                dlb.balance DESC, dlb.acct_open_date ASC, dlb.loan_acct_nbr ASC) 
        AS RowNum
    FROM
        daily_loan_balance AS dlb
    WHERE
        dlb.end_date = '2023-12-31'
),

--Select only the top loan account per customer.

CustTopLoan AS (
    SELECT 
        LnRank.customer_id, 
        LnRank.customer_system, 
        LnRank.balance, 
        LnRank.acct_open_date, 
        LnRank.loan_acct_nbr
    FROM 
        LoanAcctsRanked as LnRank
    WHERE 
        LnRank.RowNum = 1
), 
    
--Exclude the loan customers who have deposits. 

LoanOnlyCust AS (
    SELECT
        TopLn.customer_id,
        TopLn.customer_system, 
        TotalLn.CustLoanBalTotal, 
        TopLn.loan_acct_nbr
    FROM 
        CustTopLoan as TopLn
    JOIN
        CustTotalLoan AS TotalLn
        ON TopLn.customer_id = TotalLn.customer_id
        AND TopLn.customer_system = TotalLn.customer_system
    LEFT JOIN
        daily_deposit_balance AS DepBal
        ON TopLn.customer_id = DepBal.customer_id
        AND TopLn.customer_system = DepBal.customer_system
        AND DepBal.end_date = '2023-12-31'
    WHERE
        DepBal.customer_id IS NULL
), 

--Merge all 5 required data columns into 1 single table.

CustomerLoanSummary AS (
    SELECT
        LOC.customer_id, 
        LOC.customer_system, 
        LOC.CustLoanBalTotal, 
        LOC.loan_acct_nbr, 
        custDB.customer_name
    FROM 
        LoanOnlyCust AS LOC 
    JOIN 
        dim_customer AS custDB
        ON LOC.customer_id = custDB.customer_id
        AND LOC.customer_system = custDB.customer_system
)

--Select only the top 100 loan-only customers sorted by total loan balance.

SELECT TOP 100
    CustSum.customer_id, 
    CustSum.customer_system,
    CustSum.customer_name, 
    CustSum.CustLoanBalTotal, 
    CustSum.loan_acct_nbr AS Primary_Loan_Acct_Nbr
FROM 
    CustomerLoanSummary AS CustSum
ORDER BY 
    CustSum.CustLoanBalTotal;
