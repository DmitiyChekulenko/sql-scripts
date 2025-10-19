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
--   Ранее пользователи ошибались, забывая кавычки при вводе дат + пользователь часто полагает что date2 означает включение случаев входящих в date2
--   Использование синтаксиса '${date1}' в DBeaver позволяет
--   вводить даты как простой текст, а система подставит их как строку.
--   Использование конструкции  + INTERVAL '1' DAY - INTERVAL '1' SECOND означает что все случае включенные в date2 попадут в выборку
-- ВАЖНО: Формат даты — строго DD.MM.YYYY


-- =============================================================================

SELECT
    l.CODE_LPU,
    COUNT(DISTINCT hh.ID) AS hh_count
FROM D_LPU l
LEFT JOIN D_HOSP_HISTORIES hh ON hh.LPU = l.ID
LEFT JOIN D_MKB10 mkb ON mkb.id = hh.MKB_CLINIC
LEFT JOIN D_DISEASECASES dc ON dc.id = hh.DISEASECASE
LEFT JOIN D_DIRECTION_SERVICES ds ON ds.DISEASECASE = dc.ID
LEFT JOIN D_V_SERVICES serv ON serv.ID = ds.SERVICE
WHERE 1=1
  AND mkb.MKB_CODE BETWEEN 'I63' AND 'I63.9'
  AND serv.SE_CODE = 'A25.30.036.002'
  AND hh.DATE_OUT BETWEEN TO_DATE('${date1}', 'dd.mm.yyyy') AND TO_DATE('${date2}', 'dd.mm.yyyy') + INTERVAL '1' DAY - INTERVAL '1' SECOND
GROUP BY l.CODE_LPU
ORDER BY l.CODE_LPU;
