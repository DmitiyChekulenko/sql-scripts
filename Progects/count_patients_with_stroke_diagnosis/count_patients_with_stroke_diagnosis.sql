-- =============================================================================
-- НАЗВАНИЕ: Подсчёт уникальных пациентов с диагнозом инсульта (I60–I69.8)
-- ОПИСАНИЕ: Считает количество пациентов, у которых в заданный период
--           был установлен диагноз из группы "Инсульты" (МКБ-10: I60–I69.8),
--           независимо от того, был ли диагноз выставлен:
--           • на амбулаторном приёме (через D_VIS_DIAGNOSISES), ИЛИ
--           • в стационаре (в истории болезни, D_HOSP_HISTORIES).
--
-- ОСОБЕННОСТИ:
--   • Используется UNION для объединения двух источников диагнозов.
--   • Гарантировано отсутствие дублирования пациентов (каждый — 1 раз).
--   • Поддержка параметров date1 и date2 через синтаксис DBeaver '${param}'.
--
-- ИСПОЛЬЗОВАНИЕ:
--   1. Запустите скрипт в DBeaver.
--   2. В появившемся окне введите:
--        date1 = 01.01.2025   (начало периода)
--        date2 = 31.12.2025   (конец периода)
--   3. Вводите даты БЕЗ кавычек и в формате DD.MM.YYYY.
--
-- ВОЗВРАЩАЕТ: 
--   patient_count — число уникальных пациентов за период.
--
-- АВТОР: [Дмитрий Чекуленко / DmitiyChekulenko]
-- ДАТА: 2025-10-01
-- =============================================================================

SELECT COUNT(DISTINCT t.patient_id) AS patient_count
FROM (
   -- 1. Диагнозы, выставленные на приёмах (визитах)
   SELECT a.id AS patient_id
   FROM D_VIS_DIAGNOSISES dd
   JOIN D_MKB10 mkb ON mkb.id = dd.MKB
   JOIN D_VISITS v ON v.ID = dd.PID
   JOIN D_DIRECTION_SERVICES ds ON ds.id = v.PID
   JOIN D_PERSMEDCARD pmc ON pmc.ID = ds.PATIENT
   JOIN D_AGENTS a ON a.id = pmc.AGENT
   WHERE v.VISIT_DATE BETWEEN TO_DATE('${date1}', 'dd.mm.yyyy') AND TO_DATE('${date2}', 'dd.mm.yyyy')
     AND mkb.MKB_CODE BETWEEN 'I60' AND 'I69.8'
------
   UNION
------
   -- 2. Клинические диагнозы из историй болезни
   SELECT a.id AS patient_id
   FROM D_HOSP_HISTORIES hh
   JOIN D_MKB10 mkb ON mkb.id = hh.MKB_CLINIC
   JOIN D_PERSMEDCARD pmc ON pmc.ID = hh.PATIENT
   JOIN D_AGENTS a ON a.id = pmc.AGENT
   WHERE hh.MKB_CLINIC_DATE BETWEEN TO_DATE('${date1}', 'dd.mm.yyyy') AND TO_DATE('${date2}', 'dd.mm.yyyy')
     AND mkb.MKB_CODE BETWEEN 'I60' AND 'I69.8'
) t;
