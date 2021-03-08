-- https://jira2.cerner.com/browse/HIDATAINT-26295 -- 
SELECT PROGRAM_ID,
       CASE
           WHEN EXISTS
                  (SELECT 1
                   FROM <SCHEMA>.PH_F_IDENT_OUTCOME_COMPONENT DIAB
                   WHERE POPULATION_ID = '<POPULATION_ID>' -- Registries Population
                     AND PROGRAM_ID = '<PROGRAM_ID>'  -- replace with program_id, (e.g. <schema>.diabetesmellitus.clinical.diabetes-mellitus)
                     AND STATUS = 'SATISFIED' -- list patients with diabetes documentation based on satisfying these components
                     AND NAME IN ('cernerstandard.diabetesmellitus.org2014.clinical/diabetes-mellitus-type-2',
                                  'cernerstandard.diabetesmellitus.org2014.clinical/diabetes-problem',
                                  'cernerstandard.diabetesmellitus.org2014.clinical/diabetes-type-1-and-other-dx',
                                  'cernerstandard.diabetesmellitus.org2014.clinical/diabetes-type-1-type-2-and-other',
                                  'cernerstandard.diabetesmellitus.org2014.clinical/diabetes-type-1-type-2-and-other-prob-cl')
                     AND DIAB.EMPI_ID = PD.EMPI_ID
                     AND DIAB.POPULATION_iD = PD.POPULATION_ID) THEN TRUE
           ELSE FALSE
       END AS HAS_DIABETES_DOCUMENTATION,
       COUNT (DISTINCT PD.EMPI_ID)
FROM <SCHEMA>.PH_D_PERSON_DEMOGRAPHICS AS PD
JOIN
  (SELECT POPULATION_ID,
          PROGRAM_ID,
          STATUS,
          NAME AS COMPONENT,
          EMPI_ID
   FROM <SCHEMA>.PH_F_IDENT_OUTCOME_COMPONENT COM
   WHERE POPULATION_ID = '<POPULATION_ID>'
     AND PROGRAM_ID LIKE '%diabetesmellitus.clinical.diabetes-mellitus'
     AND STATUS = 'SATISFIED' -- patients satisfying these components
     AND NAME IN ('cernerstandard.diabetesmellitus.org2014.clinical/hba1c-gte-6-dot-5',
                  'cernerstandard.diabetesmellitus.org2014.clinical/eagl-gte-140',
                  'cernerstandard.diabetesmellitus.org2014.clinical/eagl-gte-7-point-8',
                  'cernerstandard.diabetesmellitus.org2014.clinical/hba1c-gte-9',
                  'cernerstandard.diabetesmellitus.org2014.clinical/eagl-gte-212',
                  'cernerstandard.diabetesmellitus.org2014.clinical/eagl-gte-11-point-8')
    UNION
    SELECT POPULATION_ID,
           PROGRAM_ID,
           STATUS,
           NAME AS COMPONENT,
           EMPI_ID
   FROM <SCHEMA>.PH_F_IDENT_OUTCOME_COMPONENT COM
   WHERE POPULATION_ID = '<POPULATION_ID>'
     AND PROGRAM_ID LIKE '%diabetesmellitus.clinical.diabetes-mellitus'
     AND STATUS = 'SATISFIED' -- patients satisfying this component with no gestational diabetes.
     AND NAME = 'cernerstandard.diabetesmellitus.org2014.clinical/diabetic-med'
     AND EXISTS (SELECT 1
     			 FROM <SCHEMA>.PH_F_IDENT_OUTCOME_COMPONENT GEST
     			 WHERE POPULATION_ID = '<POPULATION_ID>'
			     AND PROGRAM_ID LIKE '%diabetesmellitus.clinical.diabetes-mellitus'
			     AND STATUS = 'SATISFIED'
			     AND NAME = 'cernerstandard.diabetesmellitus.org2014.clinical/no-gestational-diabetes'
			     AND GEST.EMPI_ID = COM.EMPI_ID
			     AND GEST.POPULATION_ID = COM.POPULATION_ID)
   ) COM ON COM.EMPI_ID = PD.EMPI_ID
		 AND COM.POPULATION_ID = PD.POPULATION_ID
WHERE AGE_IN_YEARS(BIRTH_DATE) >= 18
  AND AGE_IN_YEARS(BIRTH_DATE) <= 120
GROUP BY 1,
         2
