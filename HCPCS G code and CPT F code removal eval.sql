WITH ONTOLOGY AS 
(SELECT 
       OA.ALIAS AS ALIAS,
         O.POPULATION_ID,
         O.CODE_SYSTEM_ID AS CODE_SYSTEM_ID,
         O.CODE_OID AS CODE_OID
FROM <SCHEMA>.PH_D_ONTOLOGY O
JOIN <SCHEMA>.PH_D_ONTOLOGY_CONCEPT_ALIAS OA ON (O.CONCEPT_ID = OA.CONCEPT_ID
                                              AND O.CONTEXT_ID = OA.CONTEXT_ID
                                              AND O.POPULATION_ID = OA.POPULATION_ID)
WHERE O.CONTEXT_ID = 'D580A162A16F45E6ACC90B8EC500EC0C' -- HEDISMY2020 CONTEXT ID
)

SELECT 
    '<SCHEMA>' AS CLIENT_SCHEMA,
     STANDARD_CODE,
     DATA_MODEL,
     COUNT(CASE 
          WHEN M_DATE >= CURRENT_DATE - 3650 
          AND STANDARD_CODE IS NOT NULL
          THEN 1 
        END) AS TEN_YEAR_COUNT,
     COUNT(CASE 
          WHEN M_DATE >= CURRENT_DATE - 365
          AND STANDARD_CODE IS NOT NULL 
          THEN 1
        END) AS ONE_YEAR_COUNT
FROM 
(
SELECT DISTINCT   
          '<SCHEMA>' AS CLIENT_SCHEMA,
          'CONDITION' AS DATA_MODEL,  
           C.POPULATION_ID,
           O.CODE_SYSTEM_ID,
           O.CODE_OID,
           O.ALIAS,
           C.CONDITION_CODING_SYSTEM_ID,
           C.CONDITION_CODE AS STANDARD_CODE,
           C.EFFECTIVE_DT_TM AS M_DATE
FROM <SCHEMA>.PH_F_CONDITION C -- provides list of empis with these conditions and their dates of these conditions 
JOIN ONTOLOGY O ON (C.CONDITION_CODE = O.CODE_OID 
          AND C.POPULATION_ID = O.POPULATION_ID
          AND C.CONDITION_CODING_SYSTEM_ID = O.CODE_SYSTEM_ID)
WHERE C.EFFECTIVE_DT_TM >= CURRENT_DATE - 3650
AND C.CONDITION_CODE IN 
                       ('3044F',
                        '3051F', 
                        '3052F',
                        '3046F',
                        '3072F',
                        '2022F',
                        '2025F',
                        '2023F',
                        '3048F',
                        '3049F',
                        '3050F')
UNION ALL
SELECT DISTINCT   
          '<SCHEMA>' AS CLIENT_SCHEMA,
          'PROCEDURE' AS DATA_MODEL,
           P.POPULATION_ID,
           O.CODE_SYSTEM_ID,
           O.CODE_OID,
           O.ALIAS,
           P.PROCEDURE_CODING_SYSTEM_ID,
               P.PROCEDURE_CODE AS STANDARD_CODE,
           P.SERVICE_START_DT_TM AS M_DATE
FROM <SCHEMA>.PH_F_PROCEDURE P -- provides list of empis with these procedures and their dates of these conditions 
JOIN ONTOLOGY O ON (P.PROCEDURE_CODE = O.CODE_OID)
        AND (P.POPULATION_ID = O.POPULATION_ID)
        AND (P.PROCEDURE_CODING_SYSTEM_ID = O.CODE_SYSTEM_ID)
WHERE P.SERVICE_START_DT_TM >= CURRENT_DATE - 3650
AND P.PROCEDURE_CODE IN 
                       ('3014F',
                        'G9899',
                        '3015F',
                        '3017F',
                        '3514F',
                        '2026F',
                        '2024F',
                        '2023F',
                        '3023F',
                        '3025F',
                        '3044F',
                        '3051F', 
                        '3052F',
                        '3046F',
                        '3072F',
                        '2022F',
                        '2025F',
                        '3048F',
                        '3049F',
                        '3050F')
UNION ALL
SELECT DISTINCT   
          '<SCHEMA>' AS CLIENT_SCHEMA,
          'RESULT' AS DATA_MODEL,
           R.POPULATION_ID,
           O.CODE_SYSTEM_ID,
           O.CODE_OID,
           O.ALIAS,
           R.RESULT_CODING_SYSTEM_ID,
           R.RESULT_CODE AS STANDARD_CODE,
           R.SERVICE_DATE AS M_DATE
FROM <SCHEMA>.PH_F_RESULT R -- provides list of empis with these results and their dates of these conditions 
JOIN ONTOLOGY O ON (R.RESULT_CODE  = O.CODE_OID) 
        AND (R.POPULATION_ID = O.POPULATION_ID)
        AND (R.RESULT_CODING_SYSTEM_ID = O.CODE_SYSTEM_ID)
WHERE R.SERVICE_DATE >= CURRENT_DATE - 3650
AND R.RESULT_CODE IN 
                         ('3044F',
                          '3051F', 
                          '3052F',
                          '3046F',
                          '3072F',
                          '2022F',
                          '2025F',
                          '2023F',
                          '3048F',
                          '3049F',
                          '3050F')                                                                                            
              ) AS SUB1
GROUP BY 1,
         2,
         3
ORDER BY 1,
         2,
         3
             
