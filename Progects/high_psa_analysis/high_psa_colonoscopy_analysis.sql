-- Анализ пациентов с ПСА >= 100, прошедших колоноскопию и получивших релевантный диагноз
-- Цель: оценка связи между высоким ПСА и патологиями ЖКТ по данным медицинских учреждений

-- Шаг 0: Определение целевых медицинских организаций (МО) по коду
WITH target_lpu AS (
   SELECT COLUMN_VALUE AS CODE_LPU
   FROM TABLE(SYS.ODCIVARCHAR2LIST(
       '250100', '250133', '250142', '250191', '250210', '250236',
       '250240', '250244', '250250', '250296', '250322', '250337',
       '250343', '250360', '250366', '250376', '250384', '250391',
       '250396', '250410', '250443', '250452', '250458', '250473',
       '250477', '250495', '250500', '250515', '250525', '250540',
       '250556', '250558', '250560', '250617', '250629', '250632',
       '250634', '250686', '250700', '250701', '250702', '250747'
   ))
),
---
-- Шаг 1: Выбор пациентов с ПСА >= 100, возрастом 40–74 лет, в заданном периоде
psa_high AS (
   SELECT /*+ MATERIALIZE */
       l.CODE_LPU,
       pmc.id AS pmc_id,
       jj.CONFIRM_DATE AS psa_date
   FROM D_LPU l
   JOIN D_LPU_SERVICES s ON s.LPU = l.ID
   JOIN D_SERVICES ss ON ss.ID = s.SERVICE AND ss.SE_CODE = 'A09.19.001'  -- Код услуги: ПСА
   JOIN D_LABMED_RESEARCH r ON r.LPU_SERVICE = s.ID
   JOIN D_LABMED_RESEARCH_METHODS rm ON rm.PID = r.ID
   JOIN D_LABMED_REF_VAL rv ON rv.METHOD = rm.ID
   JOIN D_LABMED_RSRCH_JOURSP jj ON jj.RSRCH_RESREF_VAL = rv.ID
   JOIN D_LABMED_RSRCH_JOUR j ON j.ID = jj.PID
   JOIN D_LABMED_PATJOUR dpj ON dpj.id = j.PATJOUR
   JOIN D_PERSMEDCARD pmc ON pmc.ID = dpj.PATIENT
   JOIN D_AGENTS a ON a.id = pmc.AGENT
   WHERE
       l.CODE_LPU IN (SELECT COLUMN_VALUE FROM target_lpu)  -- Оптимизация: используем CTE вместо повторного списка
       AND jj.CONFIRM_DATE BETWEEN TO_DATE('${date1}', 'dd.mm.yyyy')
                               AND TO_DATE('${date2}', 'dd.mm.yyyy') + INTERVAL '1' DAY - INTERVAL '1' SECOND
       AND jj.NUM_VALUE >= 100
       AND (EXTRACT(YEAR FROM jj.CONFIRM_DATE) - EXTRACT(YEAR FROM a.BIRTHDATE)) BETWEEN 40 AND 74
),
---
-- Шаг 2: Колоноскопии, проведённые ПОСЛЕ даты анализа ПСА
colono_after_psa AS (
   SELECT /*+ MATERIALIZE */
       p.CODE_LPU,
       p.pmc_id,
       v_colono.VISIT_DATE AS colono_date
   FROM psa_high p
   JOIN D_VISITS v_colono ON v_colono.PATIENT = p.pmc_id
   JOIN D_DIRECTION_SERVICES ds ON ds.ID = v_colono.PID
   JOIN D_SERVICES ss2 ON ss2.ID = ds.SERVICE AND ss2.SE_CODE = 'A03.18.001'  -- Код услуги: колоноскопия
   WHERE v_colono.VISIT_DATE >= p.psa_date
),
---
-- Шаг 3: Диагнозы, установленные ПОСЛЕ колоноскопии и соответствующие заданным МКБ-10
diag_after_colono AS (
   SELECT /*+ MATERIALIZE */
       c.CODE_LPU,
       c.pmc_id
   FROM colono_after_psa c
   JOIN D_VISITS v_diag ON v_diag.PATIENT = c.pmc_id
   JOIN D_VIS_DIAGNOSISES d ON d.PID = v_diag.ID
   JOIN D_MKB10 mkb ON mkb.id = d.MKB
   WHERE v_diag.VISIT_DATE >= c.colono_date
     AND (
          mkb.MKB_CODE BETWEEN 'C18' AND 'C21.8'    -- Злокачественные новообразования ободочной/прямой кишки
       OR mkb.MKB_CODE BETWEEN 'D12' AND 'D12.9'    -- Доброкачественные новообразования
       OR mkb.MKB_CODE BETWEEN 'K50' AND 'K52.9'    -- Неспецифический язвенный колит, болезнь Крона и др.
       OR mkb.MKB_CODE IN ('K62.0', 'K62.1', 'K63.5')  -- Полипы, язвы, перфорация кишечника
     )
)
---
-- Финальный результат: количество случаев по каждому МО (включая нули)
SELECT
   l.CODE_LPU,
   COUNT(DISTINCT d.pmc_id) AS "Количество_случаев"
FROM target_lpu l
LEFT JOIN diag_after_colono d ON d.CODE_LPU = l.CODE_LPU
GROUP BY l.CODE_LPU
ORDER BY l.CODE_LPU;
