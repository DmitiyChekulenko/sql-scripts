 ---аллергоанамнез пациента. вывод в 1 строчку печатки
 SELECT
  ('Аллергия: ' || t.ALLERGEN_DETAILS || '; Реакция на аллергию: ' || alr.RT_NAME) AS "Результат"
 FROM D_V_AGENT_ALLERG_ANAMNESIS t
 JOIN D_AGENT_AA_REACTIONS daar ON daar.PID = t.id
 JOIN D_ALLERG_REACTIONS alr ON alr.id = daar.REACTION
 JOIN D_V_AGENTS a ON a.id = t.PID
 JOIN D_PERSMEDCARD pmc ON pmc.AGENT = a.ID
 JOIN D_DIRECTION_SERVICES ds ON ds.PATIENT = pmc.ID
 WHERE 1=1
AND ds.ID = <DIRECTION_SERVICE>

---(наследственный) анамнез пациента 
SELECT
CASE 
    WHEN COUNT(t1.name) > 0 THEN 
      'Действующие наследсвенные заболевания: ' || 
      LISTAGG(t1.name, '; ') WITHIN GROUP (ORDER BY t1.name)
    ELSE NULL
END AS NASL
FROM D_DETRIMENTAL_EFFECTS t1
JOIN D_AGENT_DETR_EFFECTS f ON f.DETR_EFFECT = t1.ID
JOIN D_AGENTS a ON a.id = f.PID
JOIN D_PERSMEDCARD pmc ON pmc.AGENT = a.ID
JOIN D_DIRECTION_SERVICES ds ON ds.PATIENT = pmc.ID
WHERE 1=1
AND t1.TYPE = '2'
AND ds.ID = <DIRECTION_SERVICE>


---Вредные производственные факторы с СИ паицента
SELECT 
  CASE 
    WHEN COUNT(bf.BF_NAME) > 0 THEN 
      'Действующие вредные производственные факторы: ' || 
      LISTAGG(bf.BF_NAME, '; ') WITHIN GROUP (ORDER BY bf.BF_NAME)
    ELSE NULL
  END AS FACT
FROM D_V_AGENT_BAD_FACTORS dde
JOIN D_V_BADS_FACTORS bf ON bf.ID = dde.BAD_FACTOR_ID
JOIN D_V_AGENTS a ON a.id = dde.PID
JOIN D_V_PERSMEDCARD pmc ON pmc.AGENT = a.ID
JOIN D_V_DIRECTION_SERVICES ds ON ds.PATIENT = pmc.ID
WHERE bf.IS_ACTIVE = '1'
AND ds.ID = <DIRECTION_SERVICE>


---Вредные привычки или зависимости с СИ в поле
SELECT
CASE 
    WHEN COUNT(vp.DETR_EFFECT_NAME) > 0 THEN 
      'Действующие вредные привычки: ' || 
      LISTAGG(vp.DETR_EFFECT_NAME, '; ') WITHIN GROUP (ORDER BY vp.DETR_EFFECT_NAME)
    ELSE NULL
END AS VRED
FROM D_V_AGENT_DETR_EFFECTS vp
JOIN D_V_AGENTS a ON a.id = vp.PID
JOIN D_V_DETRIMENTAL_EFFECTS d ON d.ID = vp.DETR_EFFECT
JOIN D_V_PERSMEDCARD pmc ON pmc.AGENT = a.ID
JOIN D_V_DIRECTION_SERVICES ds ON ds.PATIENT = pmc.ID
WHERE 1=1
AND vp.IS_ACTUAL = '1'
AND ds.ID = <DIRECTION_SERVICE>
