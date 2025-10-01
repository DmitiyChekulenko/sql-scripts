-- =============================================================================
-- НАЗВАНИЕ: Подсчёт историй болезни по диагнозу (I63) и услуге (A25.30.036.002)
-- ОПИСАНИЕ: Считает количество уникальных историй болезни (hh.ID) в разрезе МО,
--           где:
--           - установлен диагноз по МКБ-10 в диапазоне I63–I63.9,
--           - оказана услуга с кодом A25.30.036.002,
--           - дата выписки попадает в заданный интервал.
--
-- ИСПОЛЬЗОВАНИЕ:
--   1. Откройте скрипт в DBeaver.
--   2. При запуске появятся два параметра: date1 и date2.
--   3. Введите даты в формате: 01.09.2025 (БЕЗ кавычек!).
--      Пример: date1 = 01.09.2025, date2 = 30.09.2025
--   4. Скрипт автоматически обернёт их в кавычки и выполнит запрос.
--
-- РЕШЕНИЕ ПРОБЛЕМЫ:
--   Ранее пользователи ошибались, забывая кавычки при вводе дат.
--   Использование синтаксиса '${date1}' в DBeaver позволяет
--   вводить даты как простой текст, а система подставит их как строку.
--
-- ВАЖНО: Формат даты — строго DD.MM.YYYY
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
