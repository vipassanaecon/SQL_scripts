-- REPLACE <SCHEMA> WITH CLIENTS SCHEMA
---------------------------------------------------------
/* CPT_REV_CODE_PREVALENCE - Checks % of claim lines having
1.IDQ-0253 both revenue code and cpt code
        P - >3%
        D any percent here is bad
        RX - >1%
2.IDQ-0253 revenue code but not cpt code
        P - >3%
        D any percent here is bad
        RX - >1%
3.IDQ-0253 cpt code but not revenue code
        I - >3%
        RX - >1%
4.IDQ-0253 neither cpt nor revenue code
        I- >3%
        P - >3%
        D any percent here is bad
5.IDQ-0225 no CPT code
        P - >3%
        D any percent here is bad
6.IDQ-0225 no revenue code
        I - >3%
7.IDQ-0219 CPT iLike 'j%' where Revenue Code is NULL
        I - >3%
8.IDQ-0219 Revenue Code is NULL when a DRG exists on Claim header
        I,D,P,Rx - >3%
Flag anything where the percentage is higher than given
threshold.
  */ ---------------------------------------------------------
WITH CLMS_W_REV_CODES AS
  (SELECT POPULATION_ID ,
          SOURCE_DESCRIPTION ,
          CLAIM_ID ,
          CLAIM_UID ,
          LINE_NUMBER
   FROM <SCHEMA>.PH_F_CLAIM_DETAIL
   WHERE 1 = 1
     AND COALESCE(ADJUDICATED_REVENUE_CODE, BILLED_REVENUE_CODE) IS NOT NULL
   GROUP BY 1,
            2,
            3,
            4,
            5
   ORDER BY 1,
            2,
            3,
            4,
            5),
     CLMS_W_CPT_CODES AS
  (SELECT POPULATION_ID ,
          SOURCE_DESCRIPTION ,
          CLAIM_ID ,
          CLAIM_UID ,
          LINE_NUMBER
   FROM <SCHEMA>.PH_F_CLAIM_DETAIL
   WHERE 1 = 1
     AND COALESCE(ADJUDICATED_PROCEDURE_CODE, BILLED_PROCEDURE_CODE) IS NOT NULL
   GROUP BY 1,
            2,
            3,
            4,
            5
   ORDER BY 1,
            2,
            3,
            4,
            5)
SELECT C.POPULATION_ID AS POPULATION_ID,
       C.SOURCE_DESCRIPTION AS SOURCE_DESCRIPTION,
       C.FORM_TYPE AS FORM_TYPE,
    -- 1.IDQ-0253 both revenue code and cpt code
       ROUND((COUNT(DISTINCT CASE
                                 WHEN RC_CHECK.CLAIM_UID IS NOT NULL
                                      AND CPT_CHECK.CLAIM_UID IS NOT NULL THEN CD.CLAIM_UID || '-' || CD.LINE_NUMBER
                             END) / COUNT(DISTINCT (CD.CLAIM_UID || '-' || CD.LINE_NUMBER))) * 100, 2) AS YES_RC_YES_CPT -->>count of service lines with rev code and cpt
 ,
       CASE 
          WHEN
        (ROUND((COUNT(DISTINCT CASE
                                 WHEN RC_CHECK.CLAIM_UID IS NOT NULL
                                      AND CPT_CHECK.CLAIM_UID IS NOT NULL THEN CD.CLAIM_UID || '-' || CD.LINE_NUMBER
                             END) / COUNT(DISTINCT (CD.CLAIM_UID || '-' || CD.LINE_NUMBER))) * 100, 2)) >= 3.0 AND C.FORM_TYPE = 'P' THEN 'FAIL' 
          WHEN 
        (ROUND((COUNT(DISTINCT CASE
                                 WHEN RC_CHECK.CLAIM_UID IS NOT NULL
                                      AND CPT_CHECK.CLAIM_UID IS NOT NULL THEN CD.CLAIM_UID || '-' || CD.LINE_NUMBER
                             END) / COUNT(DISTINCT (CD.CLAIM_UID || '-' || CD.LINE_NUMBER))) * 100, 2)) >= 1.0 AND C.FORM_TYPE = 'Rx' THEN 'FAIL' 
          WHEN 
        (ROUND((COUNT(DISTINCT CASE
                                 WHEN RC_CHECK.CLAIM_UID IS NOT NULL
                                      AND CPT_CHECK.CLAIM_UID IS NOT NULL THEN CD.CLAIM_UID || '-' || CD.LINE_NUMBER
                             END) / COUNT(DISTINCT (CD.CLAIM_UID || '-' || CD.LINE_NUMBER))) * 100, 2)) > 0 AND C.FORM_TYPE = 'D' THEN 'FAIL' 
          ELSE 'PASS'                                                                                  
          END AS YES_RC_YES_CPT_PASS_OR_FAIL -->>count of service lines with rev code and cpt 
 ,  
    -- 2.IDQ-0253 revenue code but not cpt code
       ROUND((COUNT(DISTINCT CASE
                                 WHEN RC_CHECK.CLAIM_UID IS NOT NULL
                                      AND CPT_CHECK.CLAIM_UID IS NULL THEN CD.CLAIM_UID || '-' || CD.LINE_NUMBER
                             END) / COUNT(DISTINCT (CD.CLAIM_UID || '-' || CD.LINE_NUMBER))) * 100, 2) AS YES_RC_NO_CPT -->>count of service lines with rev code and no cpt
 ,
       CASE 
          WHEN
       (ROUND((COUNT(DISTINCT CASE
                                 WHEN RC_CHECK.CLAIM_UID IS NOT NULL
                                      AND CPT_CHECK.CLAIM_UID IS NULL THEN CD.CLAIM_UID || '-' || CD.LINE_NUMBER
                             END) / COUNT(DISTINCT (CD.CLAIM_UID || '-' || CD.LINE_NUMBER))) * 100, 2)) >= 3.0 AND C.FORM_TYPE = 'P' THEN 'FAIL' 
          WHEN
       (ROUND((COUNT(DISTINCT CASE
                                 WHEN RC_CHECK.CLAIM_UID IS NOT NULL
                                      AND CPT_CHECK.CLAIM_UID IS NULL THEN CD.CLAIM_UID || '-' || CD.LINE_NUMBER
                             END) / COUNT(DISTINCT (CD.CLAIM_UID || '-' || CD.LINE_NUMBER))) * 100, 2)) >= 1.0 AND C.FORM_TYPE = 'Rx' THEN 'FAIL'
          WHEN
       (ROUND((COUNT(DISTINCT CASE
                                 WHEN RC_CHECK.CLAIM_UID IS NOT NULL
                                      AND CPT_CHECK.CLAIM_UID IS NULL THEN CD.CLAIM_UID || '-' || CD.LINE_NUMBER
                             END) / COUNT(DISTINCT (CD.CLAIM_UID || '-' || CD.LINE_NUMBER))) * 100, 2)) > 0 AND C.FORM_TYPE = 'D' THEN 'FAIL' 
          ELSE 'PASS'
          END AS YES_RC_NO_CPT_PASS_OR_FAIL -->>count of service lines with rev code and no cpt
 ,
    -- 3.IDQ-0253 cpt code but not revenue code
       ROUND((COUNT(DISTINCT CASE
                                 WHEN RC_CHECK.CLAIM_UID IS NULL
                                      AND CPT_CHECK.CLAIM_UID IS NOT NULL THEN CD.CLAIM_UID || '-' || CD.LINE_NUMBER
                             END) / COUNT(DISTINCT (CD.CLAIM_UID || '-' || CD.LINE_NUMBER))) * 100, 2) AS NO_RC_YES_CPT -->>count of service lines with cpt and no rev code
 ,
       CASE 
          WHEN
       (ROUND((COUNT(DISTINCT CASE
                                 WHEN RC_CHECK.CLAIM_UID IS NULL
                                      AND CPT_CHECK.CLAIM_UID IS NOT NULL THEN CD.CLAIM_UID || '-' || CD.LINE_NUMBER
                             END) / COUNT(DISTINCT (CD.CLAIM_UID || '-' || CD.LINE_NUMBER))) * 100, 2)) >= 3.0 AND C.FORM_TYPE = 'I' THEN 'FAIL' 
          WHEN
       (ROUND((COUNT(DISTINCT CASE
                                 WHEN RC_CHECK.CLAIM_UID IS NULL
                                      AND CPT_CHECK.CLAIM_UID IS NOT NULL THEN CD.CLAIM_UID || '-' || CD.LINE_NUMBER
                             END) / COUNT(DISTINCT (CD.CLAIM_UID || '-' || CD.LINE_NUMBER))) * 100, 2)) >= 1.0 AND C.FORM_TYPE = 'Rx' THEN 'FAIL'
          ELSE 'PASS'
          END AS NO_RC_YES_CPT_PASS_OR_FAIL -->>count of service lines with cpt and no rev code
 ,
    -- 4.IDQ-0253 neither cpt nor revenue code
       ROUND((COUNT(DISTINCT CASE
                                 WHEN RC_CHECK.CLAIM_UID IS NULL
                                      AND CPT_CHECK.CLAIM_UID IS NULL THEN CD.CLAIM_UID || '-' || CD.LINE_NUMBER
                             END) / COUNT(DISTINCT (CD.CLAIM_UID || '-' || CD.LINE_NUMBER))) * 100, 2) AS NO_RC_NO_CPT -->>count of service lines with no rev code or cpt
 ,      
       CASE 
          WHEN
          (ROUND((COUNT(DISTINCT CASE
                                 WHEN RC_CHECK.CLAIM_UID IS NULL
                                      AND CPT_CHECK.CLAIM_UID IS NULL THEN CD.CLAIM_UID || '-' || CD.LINE_NUMBER
                             END) / COUNT(DISTINCT (CD.CLAIM_UID || '-' || CD.LINE_NUMBER))) * 100, 2)) >= 3.0 AND C.FORM_TYPE = 'I' THEN 'FAIL' 
          WHEN
         (ROUND((COUNT(DISTINCT CASE
                                 WHEN RC_CHECK.CLAIM_UID IS NULL
                                      AND CPT_CHECK.CLAIM_UID IS NULL THEN CD.CLAIM_UID || '-' || CD.LINE_NUMBER
                             END) / COUNT(DISTINCT (CD.CLAIM_UID || '-' || CD.LINE_NUMBER))) * 100, 2)) >= 3.0 AND C.FORM_TYPE = 'P' THEN 'FAIL' 
          WHEN
         (ROUND((COUNT(DISTINCT CASE
                                 WHEN RC_CHECK.CLAIM_UID IS NULL
                                      AND CPT_CHECK.CLAIM_UID IS NULL THEN CD.CLAIM_UID || '-' || CD.LINE_NUMBER
                             END) / COUNT(DISTINCT (CD.CLAIM_UID || '-' || CD.LINE_NUMBER))) * 100, 2)) > 0 AND C.FORM_TYPE = 'D' THEN 'FAIL' 
          ELSE 'PASS' 
          END AS NO_RC_NO_CPT_PASS_OR_FAIL
 ,
    -- 5.IDQ-0225 no CPT code
       ROUND((COUNT(DISTINCT CASE
                                 WHEN CPT_CHECK.CLAIM_UID IS NULL THEN CD.CLAIM_UID || '-' || CD.LINE_NUMBER
                             END) / COUNT(DISTINCT (CD.CLAIM_UID || '-' || CD.LINE_NUMBER))) * 100, 2) AS NO_CPT -->>count of service lines with no cpt
 ,
      CASE 
          WHEN
       (ROUND((COUNT(DISTINCT CASE
                                 WHEN CPT_CHECK.CLAIM_UID IS NULL THEN CD.CLAIM_UID || '-' || CD.LINE_NUMBER
                             END) / COUNT(DISTINCT (CD.CLAIM_UID || '-' || CD.LINE_NUMBER))) * 100, 2)) >= 3.0 AND C.FORM_TYPE = 'P' THEN 'FAIL' 
          WHEN
       (ROUND((COUNT(DISTINCT CASE
                                 WHEN CPT_CHECK.CLAIM_UID IS NULL THEN CD.CLAIM_UID || '-' || CD.LINE_NUMBER
                             END) / COUNT(DISTINCT (CD.CLAIM_UID || '-' || CD.LINE_NUMBER))) * 100, 2)) > 0 AND C.FORM_TYPE = 'D' THEN 'FAIL' 
          ELSE 'PASS'  
          END AS NO_CPT_PASS_OR_FAIL -->>count of service lines with no cpt
 ,
    -- 6.IDQ-0225 no revenue code
       ROUND((COUNT(DISTINCT CASE
                                 WHEN RC_CHECK.CLAIM_UID IS NULL THEN CD.CLAIM_UID || '-' || CD.LINE_NUMBER
                             END) / COUNT(DISTINCT (CD.CLAIM_UID || '-' || CD.LINE_NUMBER))) * 100, 2) AS NO_RC -->>count of service lines with no rev code
 ,
       CASE 
          WHEN   
       (ROUND((COUNT(DISTINCT CASE
                                 WHEN RC_CHECK.CLAIM_UID IS NULL THEN CD.CLAIM_UID || '-' || CD.LINE_NUMBER
                             END) / COUNT(DISTINCT (CD.CLAIM_UID || '-' || CD.LINE_NUMBER))) * 100, 2)) >= 3.0 AND C.FORM_TYPE = 'I' THEN 'FAIL' 
          ELSE 'PASS'  
          END AS NO_RC_PASS_OR_FAIL -->>count of service lines with no rev code
 , 
    -- 7.IDQ-0219 CPT iLike 'j%' where Revenue Code is NULL
       ROUND((COUNT(DISTINCT CASE
                                 WHEN RC_CHECK.CLAIM_UID IS NULL
                                      AND COALESCE(CD.ADJUDICATED_PROCEDURE_CODE, CD.BILLED_PROCEDURE_CODE) iLike 'j%' THEN CD.CLAIM_UID || '-' || CD.LINE_NUMBER
                             END) / COUNT(DISTINCT (CD.CLAIM_UID || '-' || CD.LINE_NUMBER))) * 100, 2) AS NO_RC_YES_J_CPT -->>count of service lines with cpt like 'j%' and no rev code
 ,
       CASE 
          WHEN 
       (ROUND((COUNT(DISTINCT CASE
                                 WHEN RC_CHECK.CLAIM_UID IS NULL
                                      AND COALESCE(CD.ADJUDICATED_PROCEDURE_CODE, CD.BILLED_PROCEDURE_CODE) iLike 'j%' THEN CD.CLAIM_UID || '-' || CD.LINE_NUMBER
                             END) / COUNT(DISTINCT (CD.CLAIM_UID || '-' || CD.LINE_NUMBER))) * 100, 2)) >= 3.0 THEN 'FAIL' 
          ELSE 'PASS' 
          END AS NO_RC_YES_J_CPT_PASS_OR_FAIL -->>count of service lines with cpt like 'j%' and no rev code
 ,
    -- 8.IDQ-0219 Revenue Code is NULL when a DRG exists on Claim header
       ROUND((COUNT(DISTINCT CASE
                                 WHEN RC_CHECK.CLAIM_UID IS NULL
                                      AND C.DIAGNOSIS_RELATED_GROUP_CODE IS NOT NULL THEN CD.CLAIM_UID || '-' || CD.LINE_NUMBER
                             END) / COUNT(DISTINCT (CD.CLAIM_UID || '-' || CD.LINE_NUMBER))) * 100, 2) AS NO_RC_YES_DRG -->>count of service lines with no rev code when DRG exists on claim
 ,
       CASE 
          WHEN  
       (ROUND((COUNT(DISTINCT CASE
                                 WHEN RC_CHECK.CLAIM_UID IS NULL
                                      AND C.DIAGNOSIS_RELATED_GROUP_CODE IS NOT NULL THEN CD.CLAIM_UID || '-' || CD.LINE_NUMBER
                             END) / COUNT(DISTINCT (CD.CLAIM_UID || '-' || CD.LINE_NUMBER))) * 100, 2)) >= 3.0 THEN 'FAIL' 
          ELSE 'PASS' 
          END AS NO_RC_YES_DRG_PASS_OR_FAIL -->>count of service lines with no rev code when DRG exists on claim
 ,
       COUNT(DISTINCT CD.CLAIM_ID) AS TOTAL_CLAIM_COUNT
 ,
       COUNT(DISTINCT (CD.CLAIM_UID || '-' || CD.LINE_NUMBER)) AS TOTAL_SERVICE_LINE_COUNT
FROM <SCHEMA>.PH_F_CLAIM C
JOIN <SCHEMA>.PH_F_CLAIM_DETAIL CD ON CD.CLAIM_ID = C.CLAIM_ID
AND CD.CLAIM_UID = C.CLAIM_UID
AND CD.POPULATION_ID = C.POPULATION_ID
AND CD.SOURCE_DESCRIPTION = C.SOURCE_DESCRIPTION
LEFT JOIN CLMS_W_REV_CODES RC_CHECK ON RC_CHECK.POPULATION_ID = CD.POPULATION_ID
AND RC_CHECK.CLAIM_ID = CD.CLAIM_ID
AND RC_CHECK.CLAIM_UID = CD.CLAIM_UID
AND RC_CHECK.LINE_NUMBER = CD.LINE_NUMBER
AND RC_CHECK.SOURCE_DESCRIPTION = CD.SOURCE_DESCRIPTION
LEFT JOIN CLMS_W_CPT_CODES CPT_CHECK ON CPT_CHECK.POPULATION_ID = CD.POPULATION_ID
AND CPT_CHECK.CLAIM_ID = CD.CLAIM_ID
AND CPT_CHECK.CLAIM_UID = CD.CLAIM_UID
AND CPT_CHECK.LINE_NUMBER = CD.LINE_NUMBER
AND CPT_CHECK.SOURCE_DESCRIPTION = CD.SOURCE_DESCRIPTION
WHERE 1 = 1
GROUP BY 1,
         2,
         3
ORDER BY 1,
         2,
         3
