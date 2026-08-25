/*
===============================================================================
BI-003 — Fase 0 — Rodada 4: Eventos, Recuperação e Intervalos
Rodadas 4A e 4B — Estrutura, custo e reconstrução controlada
SGBD: MySQL
Database esperado: zabbix
Ferramenta: Generic SQL Extractor 2.0
===============================================================================

REGRAS DE SEGURANÇA
- Somente SELECT/CTE em metadados, configuração e amostras determinísticas.
- Nenhuma consulta ao conteúdo de history* ou trends*.
- Nenhuma varredura global de events ou problem.
- Amostras transacionais ordenadas por eventid e limitadas.
- Nenhum hostname, IP, usuário ou mensagem de reconhecimento é retornado.
- Consultas 11–24 foram habilitadas após a remessa 4A 20260814_202056 com 0 ERROR.
- A 4B usa source=0, object=0, universo de 164 triggers e janela iniciada em 2026-01-01.
- Os códigos brutos não são promovidos a regra funcional nesta rodada.
===============================================================================
*/

-- @id: 1
-- @output: 01_estrutura_objetos_eventos.csv
-- @description: Cataloga colunas das estruturas candidatas de eventos, problemas, recuperação, reconhecimento, supressão e correlação.
-- @heavy: false
-- @enabled: true
-- @timeout: 120
SELECT
    c.TABLE_SCHEMA AS table_schema,
    c.TABLE_NAME AS table_name,
    c.ORDINAL_POSITION AS ordinal_position,
    c.COLUMN_NAME AS column_name,
    c.DATA_TYPE AS data_type,
    c.COLUMN_TYPE AS column_type,
    c.IS_NULLABLE AS is_nullable,
    c.COLUMN_DEFAULT AS column_default,
    c.COLUMN_KEY AS column_key,
    c.EXTRA AS extra
FROM information_schema.COLUMNS c
WHERE c.TABLE_SCHEMA = DATABASE()
  AND c.TABLE_NAME IN (
      'events',
      'problem',
      'event_recovery',
      'acknowledges',
      'event_suppress',
      'event_tag',
      'problem_tag',
      'event_symptom',
      'correlation',
      'corr_condition',
      'corr_operation',
      'triggers',
      'functions',
      'items',
      'hosts',
      'trigger_depends',
      'trigger_tag'
  )
ORDER BY c.TABLE_NAME, c.ORDINAL_POSITION;

-- @id: 2
-- @output: 02_indices_constraints_eventos.csv
-- @description: Cataloga PKs, FKs, constraints e índices das estruturas necessárias à reconstrução controlada.
-- @heavy: false
-- @enabled: true
-- @timeout: 120
SELECT
    'CONSTRAINT' AS registro_tipo,
    tc.TABLE_SCHEMA AS table_schema,
    tc.TABLE_NAME AS table_name,
    tc.CONSTRAINT_NAME AS objeto_nome,
    tc.CONSTRAINT_TYPE AS objeto_tipo,
    kcu.ORDINAL_POSITION AS ordinal_position,
    kcu.COLUMN_NAME AS column_name,
    kcu.REFERENCED_TABLE_NAME AS referenced_table_name,
    kcu.REFERENCED_COLUMN_NAME AS referenced_column_name,
    rc.UPDATE_RULE AS update_rule,
    rc.DELETE_RULE AS delete_rule,
    NULL AS non_unique,
    NULL AS cardinalidade_estimada,
    NULL AS index_type
FROM information_schema.TABLE_CONSTRAINTS tc
LEFT JOIN information_schema.KEY_COLUMN_USAGE kcu
    ON kcu.CONSTRAINT_SCHEMA = tc.CONSTRAINT_SCHEMA
   AND kcu.TABLE_NAME = tc.TABLE_NAME
   AND kcu.CONSTRAINT_NAME = tc.CONSTRAINT_NAME
LEFT JOIN information_schema.REFERENTIAL_CONSTRAINTS rc
    ON rc.CONSTRAINT_SCHEMA = tc.CONSTRAINT_SCHEMA
   AND rc.TABLE_NAME = tc.TABLE_NAME
   AND rc.CONSTRAINT_NAME = tc.CONSTRAINT_NAME
WHERE tc.TABLE_SCHEMA = DATABASE()
  AND tc.TABLE_NAME IN (
      'events', 'problem', 'event_recovery', 'acknowledges', 'event_suppress',
      'event_tag', 'problem_tag', 'event_symptom', 'correlation',
      'corr_condition', 'corr_operation', 'triggers', 'functions', 'items',
      'hosts', 'trigger_depends', 'trigger_tag'
  )
UNION ALL
SELECT
    'INDEX' AS registro_tipo,
    s.TABLE_SCHEMA AS table_schema,
    s.TABLE_NAME AS table_name,
    s.INDEX_NAME AS objeto_nome,
    'INDEX' AS objeto_tipo,
    s.SEQ_IN_INDEX AS ordinal_position,
    s.COLUMN_NAME AS column_name,
    NULL AS referenced_table_name,
    NULL AS referenced_column_name,
    NULL AS update_rule,
    NULL AS delete_rule,
    s.NON_UNIQUE AS non_unique,
    s.CARDINALITY AS cardinalidade_estimada,
    s.INDEX_TYPE AS index_type
FROM information_schema.STATISTICS s
WHERE s.TABLE_SCHEMA = DATABASE()
  AND s.TABLE_NAME IN (
      'events', 'problem', 'event_recovery', 'acknowledges', 'event_suppress',
      'event_tag', 'problem_tag', 'event_symptom', 'correlation',
      'corr_condition', 'corr_operation', 'triggers', 'functions', 'items',
      'hosts', 'trigger_depends', 'trigger_tag'
  )
ORDER BY table_name, registro_tipo, objeto_nome, ordinal_position;

-- @id: 3
-- @output: 03_volumetria_eventos.csv
-- @description: Mede por metadados as linhas e os tamanhos estimados das estruturas da Rodada 4 sem COUNT global.
-- @heavy: false
-- @enabled: true
-- @timeout: 90
SELECT
    t.TABLE_SCHEMA AS table_schema,
    t.TABLE_NAME AS table_name,
    t.ENGINE AS engine,
    t.TABLE_ROWS AS linhas_estimadas,
    ROUND(COALESCE(t.DATA_LENGTH, 0) / 1024 / 1024, 2) AS dados_mb,
    ROUND(COALESCE(t.INDEX_LENGTH, 0) / 1024 / 1024, 2) AS indices_mb,
    ROUND((COALESCE(t.DATA_LENGTH, 0) + COALESCE(t.INDEX_LENGTH, 0)) / 1024 / 1024, 2) AS total_mb
FROM information_schema.TABLES t
WHERE t.TABLE_SCHEMA = DATABASE()
  AND t.TABLE_NAME IN (
      'events', 'problem', 'event_recovery', 'acknowledges', 'event_suppress',
      'event_tag', 'problem_tag', 'event_symptom', 'correlation',
      'corr_condition', 'corr_operation', 'triggers', 'functions', 'items',
      'hosts', 'trigger_depends', 'trigger_tag'
  )
ORDER BY t.TABLE_NAME;

-- @id: 4
-- @output: 04_estruturas_auxiliares_eventos.csv
-- @description: Inventaria por metadados estruturas auxiliares candidatas de eventos, problemas, reconhecimento, correlação, sintomas e supressão.
-- @heavy: false
-- @enabled: true
-- @timeout: 90
SELECT
    t.TABLE_SCHEMA AS table_schema,
    t.TABLE_NAME AS table_name,
    t.TABLE_TYPE AS table_type,
    t.ENGINE AS engine,
    t.TABLE_ROWS AS linhas_estimadas,
    ROUND((COALESCE(t.DATA_LENGTH, 0) + COALESCE(t.INDEX_LENGTH, 0)) / 1024 / 1024, 2) AS total_mb
FROM information_schema.TABLES t
WHERE t.TABLE_SCHEMA = DATABASE()
  AND (
      t.TABLE_NAME IN ('events', 'problem', 'event_recovery', 'acknowledges', 'event_suppress')
      OR t.TABLE_NAME LIKE 'event\_%' ESCAPE '\\'
      OR t.TABLE_NAME LIKE 'problem\_%' ESCAPE '\\'
      OR t.TABLE_NAME LIKE 'corr\_%' ESCAPE '\\'
      OR t.TABLE_NAME LIKE '%correlation%'
      OR t.TABLE_NAME LIKE '%symptom%'
      OR t.TABLE_NAME LIKE '%suppress%'
      OR t.TABLE_NAME LIKE '%acknowledge%'
  )
ORDER BY t.TABLE_NAME
LIMIT 200;

-- @id: 5
-- @output: 05_amostra_eventos_brutos.csv
-- @description: Retorna até 200 eventos recentes por chave primária, preservando somente códigos brutos e chaves técnicas.
-- @heavy: false
-- @enabled: true
-- @timeout: 120
SELECT
    e.eventid,
    e.source AS source_bruto,
    e.object AS object_bruto,
    e.objectid,
    e.clock,
    e.ns,
    e.value AS value_bruto,
    e.severity AS severity_bruto
FROM events e
ORDER BY e.eventid DESC
LIMIT 200;

-- @id: 6
-- @output: 06_distribuicao_recente_source_object_value.csv
-- @description: Agrupa códigos brutos somente nos 10000 eventids mais recentes; aguarda confirmação dos índices da Consulta 02.
-- @heavy: false
-- @enabled: false
-- @timeout: 120
WITH eventos_recentes AS (
    SELECT e.eventid, e.source, e.object, e.value
    FROM events e
    ORDER BY e.eventid DESC
    LIMIT 10000
)
SELECT
    er.source AS source_bruto,
    er.object AS object_bruto,
    er.value AS value_bruto,
    COUNT(*) AS eventos,
    MIN(er.eventid) AS menor_eventid_amostra,
    MAX(er.eventid) AS maior_eventid_amostra
FROM eventos_recentes er
GROUP BY er.source, er.object, er.value
ORDER BY er.source, er.object, er.value;

-- @id: 7
-- @output: 07_amostra_problem_bruto.csv
-- @description: Retorna até 200 problemas recentes por eventid com chaves e códigos brutos, sem textos ou usuários.
-- @heavy: false
-- @enabled: true
-- @timeout: 120
SELECT
    p.eventid,
    p.source AS source_bruto,
    p.object AS object_bruto,
    p.objectid,
    p.clock,
    p.ns,
    p.r_eventid,
    p.r_clock,
    p.r_ns,
    p.correlationid,
    p.acknowledged AS acknowledged_bruto,
    p.severity AS severity_bruto,
    p.cause_eventid
FROM problem p
ORDER BY p.eventid DESC
LIMIT 200;

-- @id: 8
-- @output: 08_amostra_event_recovery.csv
-- @description: Retorna até 200 vínculos recentes entre problema, recuperação e correlação usando apenas chaves técnicas.
-- @heavy: false
-- @enabled: true
-- @timeout: 120
SELECT
    er.eventid,
    er.r_eventid,
    er.c_eventid,
    er.correlationid
FROM event_recovery er
ORDER BY er.eventid DESC
LIMIT 200;

-- @id: 9
-- @output: 09_triggers_candidatas_disponibilidade.csv
-- @description: Reconstrói o universo de triggers candidatas da Rodada 3 a partir da configuração atual e de chaves técnicas observadas.
-- @heavy: false
-- @enabled: true
-- @timeout: 180
WITH candidatas AS (
    SELECT
        t.triggerid,
        t.priority,
        CASE
            WHEN i.key_ = 'icmpping' THEN 'DISPONIBILIDADE_ICMP'
            WHEN i.key_ IN ('agent.ping', 'zabbix[host,agent,available]') THEN 'DISPONIBILIDADE_AGENTE'
            WHEN i.key_ = 'zabbix[host,snmp,available]' THEN 'DISPONIBILIDADE_SNMP'
        END AS sinal_candidato,
        i.hostid
    FROM items i
    JOIN hosts h ON h.hostid = i.hostid
    JOIN functions f ON f.itemid = i.itemid
    JOIN triggers t ON t.triggerid = f.triggerid
    WHERE h.flags = 0
      AND h.status IN (0, 1)
      AND i.key_ IN (
          'icmpping',
          'agent.ping',
          'zabbix[host,agent,available]',
          'zabbix[host,snmp,available]'
      )
)
SELECT
    c.triggerid,
    c.sinal_candidato,
    c.priority AS priority_bruto,
    COUNT(DISTINCT c.hostid) AS hosts_associados
FROM candidatas c
GROUP BY c.triggerid, c.sinal_candidato, c.priority
ORDER BY c.triggerid, c.sinal_candidato;

-- @id: 10
-- @output: 10_seletividade_indices_eventos.csv
-- @description: Expõe os índices que podem sustentar filtros por eventid, objectid, source, object, clock e chaves auxiliares da Rodada 4B.
-- @heavy: false
-- @enabled: true
-- @timeout: 90
SELECT
    s.TABLE_NAME AS table_name,
    s.INDEX_NAME AS index_name,
    s.NON_UNIQUE AS non_unique,
    s.SEQ_IN_INDEX AS seq_in_index,
    s.COLUMN_NAME AS column_name,
    s.CARDINALITY AS cardinalidade_estimada,
    s.INDEX_TYPE AS index_type,
    CASE
        WHEN s.COLUMN_NAME IN (
            'eventid', 'r_eventid', 'c_eventid', 'cause_eventid',
            'objectid', 'source', 'object', 'clock', 'triggerid'
        ) THEN 1 ELSE 0
    END AS coluna_relevante_rodada4
FROM information_schema.STATISTICS s
WHERE s.TABLE_SCHEMA = DATABASE()
  AND s.TABLE_NAME IN (
      'events', 'problem', 'event_recovery', 'acknowledges', 'event_suppress',
      'event_tag', 'problem_tag', 'event_symptom', 'triggers', 'functions',
      'items', 'hosts', 'trigger_depends'
  )
ORDER BY s.TABLE_NAME, s.INDEX_NAME, s.SEQ_IN_INDEX;

-- @id: 11
-- @output: 11_eventos_candidatos_amostra.csv
-- @description: Reservada à amostra de até 500 eventos das triggers candidatas após o gate de seletividade da Rodada 4A.
-- @heavy: false
-- @enabled: true
-- @timeout: 180
WITH candidatas AS (
    SELECT
        t.triggerid,
        t.priority AS trigger_priority_bruto,
        MIN(i.hostid) AS hostid,
        COUNT(DISTINCT i.hostid) AS hosts_associados,
        MIN(CASE
            WHEN i.key_ = 'icmpping' THEN 'DISPONIBILIDADE_ICMP'
            WHEN i.key_ IN ('agent.ping', 'zabbix[host,agent,available]') THEN 'DISPONIBILIDADE_AGENTE'
            WHEN i.key_ = 'zabbix[host,snmp,available]' THEN 'DISPONIBILIDADE_SNMP'
        END) AS sinal_candidato
    FROM items i
    JOIN hosts h ON h.hostid = i.hostid
    JOIN functions f ON f.itemid = i.itemid
    JOIN triggers t ON t.triggerid = f.triggerid
    WHERE h.flags = 0
      AND h.status IN (0, 1)
      AND i.key_ IN ('icmpping', 'agent.ping', 'zabbix[host,agent,available]', 'zabbix[host,snmp,available]')
    GROUP BY t.triggerid, t.priority
)
SELECT
    e.eventid,
    e.source AS source_bruto,
    e.object AS object_bruto,
    e.objectid AS triggerid,
    e.clock,
    e.ns,
    e.value AS value_bruto,
    e.severity AS severity_bruto,
    c.sinal_candidato,
    c.hosts_associados
FROM candidatas c
JOIN events e
    ON e.source = 0
   AND e.object = 0
   AND e.objectid = c.triggerid
   AND e.clock >= UNIX_TIMESTAMP('2026-01-01 00:00:00')
ORDER BY e.eventid DESC
LIMIT 500;

-- @id: 12
-- @output: 12_intervalos_problema_recuperacao.csv
-- @description: Reservada à reconstrução problema e recuperação após o gate de seletividade da Rodada 4A.
-- @heavy: false
-- @enabled: true
-- @timeout: 180
WITH
candidatas AS (
    SELECT
        t.triggerid,
        MIN(i.hostid) AS hostid,
        MIN(CASE
            WHEN i.key_ = 'icmpping' THEN 'DISPONIBILIDADE_ICMP'
            WHEN i.key_ IN ('agent.ping', 'zabbix[host,agent,available]') THEN 'DISPONIBILIDADE_AGENTE'
            WHEN i.key_ = 'zabbix[host,snmp,available]' THEN 'DISPONIBILIDADE_SNMP'
        END) AS sinal_candidato
    FROM items i
    JOIN hosts h ON h.hostid = i.hostid
    JOIN functions f ON f.itemid = i.itemid
    JOIN triggers t ON t.triggerid = f.triggerid
    WHERE h.flags = 0
      AND h.status IN (0, 1)
      AND i.key_ IN ('icmpping', 'agent.ping', 'zabbix[host,agent,available]', 'zabbix[host,snmp,available]')
    GROUP BY t.triggerid
),
eventos_amostra AS (
    SELECT e.eventid, e.objectid, e.clock, e.ns, e.value, c.hostid, c.sinal_candidato
    FROM candidatas c
    JOIN events e
        ON e.source = 0
       AND e.object = 0
       AND e.objectid = c.triggerid
       AND e.clock >= UNIX_TIMESTAMP('2026-01-01 00:00:00')
    ORDER BY e.eventid DESC
    LIMIT 500
)
SELECT
    ea.eventid AS problem_eventid,
    er.r_eventid AS recovery_eventid,
    ea.objectid AS triggerid,
    ea.hostid,
    ea.sinal_candidato,
    ea.clock AS inicio_clock,
    ea.ns AS inicio_ns,
    r.clock AS fim_clock,
    r.ns AS fim_ns,
    CASE WHEN r.eventid IS NULL THEN 1 ELSE 0 END AS aberto_tecnico,
    CASE WHEN r.eventid IS NOT NULL THEN r.clock - ea.clock END AS duracao_tecnica_segundos
FROM eventos_amostra ea
LEFT JOIN event_recovery er ON er.eventid = ea.eventid
LEFT JOIN events r ON r.eventid = er.r_eventid
WHERE ea.value = 1
ORDER BY ea.eventid DESC;

-- @id: 13
-- @output: 13_evento_trigger_host.csv
-- @description: Reservada ao mapeamento evento, trigger e host após o gate de seletividade da Rodada 4A.
-- @heavy: false
-- @enabled: true
-- @timeout: 180
WITH candidatas AS (
    SELECT
        t.triggerid,
        MIN(i.hostid) AS hostid,
        COUNT(DISTINCT i.hostid) AS hosts_associados,
        MIN(CASE
            WHEN i.key_ = 'icmpping' THEN 'DISPONIBILIDADE_ICMP'
            WHEN i.key_ IN ('agent.ping', 'zabbix[host,agent,available]') THEN 'DISPONIBILIDADE_AGENTE'
            WHEN i.key_ = 'zabbix[host,snmp,available]' THEN 'DISPONIBILIDADE_SNMP'
        END) AS sinal_candidato
    FROM items i
    JOIN hosts h ON h.hostid = i.hostid
    JOIN functions f ON f.itemid = i.itemid
    JOIN triggers t ON t.triggerid = f.triggerid
    WHERE h.flags = 0
      AND h.status IN (0, 1)
      AND i.key_ IN ('icmpping', 'agent.ping', 'zabbix[host,agent,available]', 'zabbix[host,snmp,available]')
    GROUP BY t.triggerid
),
classes AS (
    SELECT
        hg.hostid,
        CASE
            WHEN MAX(hg.groupid = 41) = 1 THEN 'ACCESS_POINT'
            WHEN MAX(hg.groupid = 27) = 1 THEN 'SWITCH'
            WHEN MAX(hg.groupid = 22) = 1 THEN 'SERVIDOR'
            ELSE 'OUTRA_CLASSE'
        END AS classe_candidata
    FROM hosts_groups hg
    GROUP BY hg.hostid
)
SELECT
    e.eventid,
    e.objectid AS triggerid,
    c.hostid,
    COALESCE(cl.classe_candidata, 'SEM_CLASSE_CANDIDATA') AS classe_candidata,
    c.sinal_candidato,
    c.hosts_associados,
    e.value AS value_bruto,
    e.clock
FROM candidatas c
JOIN events e
    ON e.source = 0
   AND e.object = 0
   AND e.objectid = c.triggerid
   AND e.clock >= UNIX_TIMESTAMP('2026-01-01 00:00:00')
LEFT JOIN classes cl ON cl.hostid = c.hostid
ORDER BY e.eventid DESC
LIMIT 500;

-- @id: 14
-- @output: 14_problemas_abertos_amostra.csv
-- @description: Reservada à amostra de até 200 problemas abertos após o gate de seletividade da Rodada 4A.
-- @heavy: false
-- @enabled: true
-- @timeout: 180
WITH candidatas AS (
    SELECT
        t.triggerid,
        MIN(i.hostid) AS hostid,
        MIN(CASE
            WHEN i.key_ = 'icmpping' THEN 'DISPONIBILIDADE_ICMP'
            WHEN i.key_ IN ('agent.ping', 'zabbix[host,agent,available]') THEN 'DISPONIBILIDADE_AGENTE'
            WHEN i.key_ = 'zabbix[host,snmp,available]' THEN 'DISPONIBILIDADE_SNMP'
        END) AS sinal_candidato
    FROM items i
    JOIN hosts h ON h.hostid = i.hostid
    JOIN functions f ON f.itemid = i.itemid
    JOIN triggers t ON t.triggerid = f.triggerid
    WHERE h.flags = 0
      AND h.status IN (0, 1)
      AND i.key_ IN ('icmpping', 'agent.ping', 'zabbix[host,agent,available]', 'zabbix[host,snmp,available]')
    GROUP BY t.triggerid
)
SELECT
    p.eventid AS problem_eventid,
    p.objectid AS triggerid,
    c.hostid,
    c.sinal_candidato,
    p.clock AS inicio_clock,
    p.ns AS inicio_ns,
    p.severity AS severity_historica_bruta,
    p.acknowledged AS acknowledged_bruto,
    p.correlationid,
    p.cause_eventid
FROM candidatas c
JOIN problem p
    ON p.source = 0
   AND p.object = 0
   AND p.objectid = c.triggerid
WHERE p.r_eventid IS NULL
  AND p.clock >= UNIX_TIMESTAMP('2026-01-01 00:00:00')
ORDER BY p.eventid DESC
LIMIT 200;

-- @id: 15
-- @output: 15_severidade_evento_trigger.csv
-- @description: Reservada à comparação entre severidade histórica e prioridade atual após o gate de seletividade da Rodada 4A.
-- @heavy: false
-- @enabled: true
-- @timeout: 180
WITH candidatas AS (
    SELECT
        t.triggerid,
        t.priority AS trigger_priority_atual_bruta
    FROM items i
    JOIN hosts h ON h.hostid = i.hostid
    JOIN functions f ON f.itemid = i.itemid
    JOIN triggers t ON t.triggerid = f.triggerid
    WHERE h.flags = 0
      AND h.status IN (0, 1)
      AND i.key_ IN ('icmpping', 'agent.ping', 'zabbix[host,agent,available]', 'zabbix[host,snmp,available]')
    GROUP BY t.triggerid, t.priority
),
eventos_amostra AS (
    SELECT e.eventid, e.objectid, e.clock, e.value, e.severity, c.trigger_priority_atual_bruta
    FROM candidatas c
    JOIN events e
        ON e.source = 0
       AND e.object = 0
       AND e.objectid = c.triggerid
       AND e.clock >= UNIX_TIMESTAMP('2026-01-01 00:00:00')
    ORDER BY e.eventid DESC
    LIMIT 500
)
SELECT
    ea.eventid,
    ea.objectid AS triggerid,
    ea.clock,
    ea.severity AS severity_historica_bruta,
    ea.trigger_priority_atual_bruta,
    CASE WHEN ea.severity = ea.trigger_priority_atual_bruta THEN 1 ELSE 0 END AS severidade_coincide_atual
FROM eventos_amostra ea
WHERE ea.value = 1
ORDER BY ea.eventid DESC;

-- @id: 16
-- @output: 16_reconhecimentos_eventos.csv
-- @description: Reservada aos reconhecimentos agregados dos eventids da amostra, sem usuários ou mensagens.
-- @heavy: false
-- @enabled: true
-- @timeout: 180
WITH
candidatas AS (
    SELECT DISTINCT t.triggerid
    FROM items i
    JOIN hosts h ON h.hostid = i.hostid
    JOIN functions f ON f.itemid = i.itemid
    JOIN triggers t ON t.triggerid = f.triggerid
    WHERE h.flags = 0
      AND h.status IN (0, 1)
      AND i.key_ IN ('icmpping', 'agent.ping', 'zabbix[host,agent,available]', 'zabbix[host,snmp,available]')
),
eventos_amostra AS (
    SELECT e.eventid, e.value
    FROM candidatas c
    JOIN events e
        ON e.source = 0
       AND e.object = 0
       AND e.objectid = c.triggerid
       AND e.clock >= UNIX_TIMESTAMP('2026-01-01 00:00:00')
    ORDER BY e.eventid DESC
    LIMIT 500
)
SELECT
    ea.eventid,
    COUNT(a.acknowledgeid) AS reconhecimentos,
    COUNT(DISTINCT a.action) AS codigos_acao_distintos,
    GROUP_CONCAT(DISTINCT a.action ORDER BY a.action SEPARATOR ' | ') AS codigos_acao_brutos,
    MIN(a.clock) AS primeiro_reconhecimento_clock,
    MAX(a.clock) AS ultimo_reconhecimento_clock
FROM eventos_amostra ea
JOIN acknowledges a ON a.eventid = ea.eventid
WHERE ea.value = 1
GROUP BY ea.eventid
ORDER BY ea.eventid DESC;

-- @id: 17
-- @output: 17_correlacao_recuperacao.csv
-- @description: Reservada à correlação e causa pelos campos comprovados na Rodada 4A.
-- @heavy: false
-- @enabled: true
-- @timeout: 180
WITH
candidatas AS (
    SELECT DISTINCT t.triggerid
    FROM items i
    JOIN hosts h ON h.hostid = i.hostid
    JOIN functions f ON f.itemid = i.itemid
    JOIN triggers t ON t.triggerid = f.triggerid
    WHERE h.flags = 0
      AND h.status IN (0, 1)
      AND i.key_ IN ('icmpping', 'agent.ping', 'zabbix[host,agent,available]', 'zabbix[host,snmp,available]')
),
eventos_amostra AS (
    SELECT e.eventid, e.objectid, e.value
    FROM candidatas c
    JOIN events e
        ON e.source = 0
       AND e.object = 0
       AND e.objectid = c.triggerid
       AND e.clock >= UNIX_TIMESTAMP('2026-01-01 00:00:00')
    ORDER BY e.eventid DESC
    LIMIT 500
)
SELECT
    ea.eventid AS problem_eventid,
    ea.objectid AS triggerid,
    p.correlationid AS problem_correlationid,
    p.cause_eventid AS problem_cause_eventid,
    er.c_eventid AS recovery_cause_eventid,
    er.correlationid AS recovery_correlationid,
    er.r_eventid AS recovery_eventid
FROM eventos_amostra ea
LEFT JOIN problem p ON p.eventid = ea.eventid
LEFT JOIN event_recovery er ON er.eventid = ea.eventid
WHERE ea.value = 1
  AND (
      p.correlationid IS NOT NULL
      OR p.cause_eventid IS NOT NULL
      OR er.c_eventid IS NOT NULL
      OR er.correlationid IS NOT NULL
  )
ORDER BY ea.eventid DESC;

-- @id: 18
-- @output: 18_supressao_eventos.csv
-- @description: Reservada à supressão apenas dos eventids da amostra da Rodada 4B.
-- @heavy: false
-- @enabled: true
-- @timeout: 180
WITH
candidatas AS (
    SELECT DISTINCT t.triggerid
    FROM items i
    JOIN hosts h ON h.hostid = i.hostid
    JOIN functions f ON f.itemid = i.itemid
    JOIN triggers t ON t.triggerid = f.triggerid
    WHERE h.flags = 0
      AND h.status IN (0, 1)
      AND i.key_ IN ('icmpping', 'agent.ping', 'zabbix[host,agent,available]', 'zabbix[host,snmp,available]')
),
eventos_amostra AS (
    SELECT e.eventid
    FROM candidatas c
    JOIN events e
        ON e.source = 0
       AND e.object = 0
       AND e.objectid = c.triggerid
       AND e.clock >= UNIX_TIMESTAMP('2026-01-01 00:00:00')
    ORDER BY e.eventid DESC
    LIMIT 500
)
SELECT
    ea.eventid,
    COUNT(es.event_suppressid) AS supressoes,
    COUNT(DISTINCT es.maintenanceid) AS manutencoes_tecnicas_distintas,
    MIN(es.suppress_until) AS menor_suppress_until,
    MAX(es.suppress_until) AS maior_suppress_until
FROM eventos_amostra ea
JOIN event_suppress es ON es.eventid = ea.eventid
GROUP BY ea.eventid
ORDER BY ea.eventid DESC;

-- @id: 19
-- @output: 19_dependencias_triggers_eventos.csv
-- @description: Reservada às dependências das triggers presentes na amostra da Rodada 4B.
-- @heavy: false
-- @enabled: true
-- @timeout: 180
WITH
candidatas AS (
    SELECT DISTINCT t.triggerid
    FROM items i
    JOIN hosts h ON h.hostid = i.hostid
    JOIN functions f ON f.itemid = i.itemid
    JOIN triggers t ON t.triggerid = f.triggerid
    WHERE h.flags = 0
      AND h.status IN (0, 1)
      AND i.key_ IN ('icmpping', 'agent.ping', 'zabbix[host,agent,available]', 'zabbix[host,snmp,available]')
),
eventos_amostra AS (
    SELECT e.eventid, e.objectid AS triggerid, e.value
    FROM candidatas c
    JOIN events e
        ON e.source = 0
       AND e.object = 0
       AND e.objectid = c.triggerid
       AND e.clock >= UNIX_TIMESTAMP('2026-01-01 00:00:00')
    ORDER BY e.eventid DESC
    LIMIT 500
)
SELECT
    ea.eventid,
    ea.triggerid,
    td.triggerid_up AS triggerid_dependencia,
    td.triggerdepid
FROM eventos_amostra ea
JOIN trigger_depends td ON td.triggerid_down = ea.triggerid
WHERE ea.value = 1
ORDER BY ea.eventid DESC, td.triggerid_up, td.triggerdepid;

-- @id: 20
-- @output: 20_intervalos_sobrepostos_host.csv
-- @description: Reservada a até 100 pares de intervalos sobrepostos no mesmo host dentro da amostra controlada.
-- @heavy: false
-- @enabled: true
-- @timeout: 180
WITH
candidatas AS (
    SELECT
        t.triggerid,
        MIN(i.hostid) AS hostid,
        MIN(CASE
            WHEN i.key_ = 'icmpping' THEN 'DISPONIBILIDADE_ICMP'
            WHEN i.key_ IN ('agent.ping', 'zabbix[host,agent,available]') THEN 'DISPONIBILIDADE_AGENTE'
            WHEN i.key_ = 'zabbix[host,snmp,available]' THEN 'DISPONIBILIDADE_SNMP'
        END) AS sinal_candidato
    FROM items i
    JOIN hosts h ON h.hostid = i.hostid
    JOIN functions f ON f.itemid = i.itemid
    JOIN triggers t ON t.triggerid = f.triggerid
    WHERE h.flags = 0
      AND h.status IN (0, 1)
      AND i.key_ IN ('icmpping', 'agent.ping', 'zabbix[host,agent,available]', 'zabbix[host,snmp,available]')
    GROUP BY t.triggerid
),
eventos_amostra AS (
    SELECT e.eventid, e.objectid, e.clock, e.ns, e.value, c.hostid, c.sinal_candidato
    FROM candidatas c
    JOIN events e
        ON e.source = 0
       AND e.object = 0
       AND e.objectid = c.triggerid
       AND e.clock >= UNIX_TIMESTAMP('2026-01-01 00:00:00')
    ORDER BY e.eventid DESC
    LIMIT 500
),
intervalos AS (
    SELECT
        ea.eventid AS problem_eventid,
        ea.objectid AS triggerid,
        ea.hostid,
        ea.sinal_candidato,
        ea.clock AS inicio_clock,
        r.clock AS fim_clock,
        COALESCE(r.clock, UNIX_TIMESTAMP()) AS fim_comparacao,
        CASE WHEN r.eventid IS NULL THEN 1 ELSE 0 END AS aberto_tecnico
    FROM eventos_amostra ea
    LEFT JOIN event_recovery er ON er.eventid = ea.eventid
    LEFT JOIN events r ON r.eventid = er.r_eventid
    WHERE ea.value = 1
)
SELECT
    a.hostid,
    a.problem_eventid AS problem_eventid_a,
    b.problem_eventid AS problem_eventid_b,
    a.triggerid AS triggerid_a,
    b.triggerid AS triggerid_b,
    a.inicio_clock AS inicio_a,
    a.fim_clock AS fim_a,
    b.inicio_clock AS inicio_b,
    b.fim_clock AS fim_b,
    a.aberto_tecnico AS aberto_a,
    b.aberto_tecnico AS aberto_b
FROM intervalos a
JOIN intervalos b
    ON b.hostid = a.hostid
   AND b.problem_eventid > a.problem_eventid
   AND a.inicio_clock <= b.fim_comparacao
   AND b.inicio_clock <= a.fim_comparacao
ORDER BY a.hostid, a.problem_eventid, b.problem_eventid
LIMIT 100;

-- @id: 21
-- @output: 21_multiplos_sinais_mesmo_intervalo.csv
-- @description: Reservada a múltiplos sinais candidatos simultâneos no mesmo host dentro da amostra controlada.
-- @heavy: false
-- @enabled: true
-- @timeout: 180
WITH
candidatas AS (
    SELECT
        t.triggerid,
        MIN(i.hostid) AS hostid,
        MIN(CASE
            WHEN i.key_ = 'icmpping' THEN 'DISPONIBILIDADE_ICMP'
            WHEN i.key_ IN ('agent.ping', 'zabbix[host,agent,available]') THEN 'DISPONIBILIDADE_AGENTE'
            WHEN i.key_ = 'zabbix[host,snmp,available]' THEN 'DISPONIBILIDADE_SNMP'
        END) AS sinal_candidato
    FROM items i
    JOIN hosts h ON h.hostid = i.hostid
    JOIN functions f ON f.itemid = i.itemid
    JOIN triggers t ON t.triggerid = f.triggerid
    WHERE h.flags = 0
      AND h.status IN (0, 1)
      AND i.key_ IN ('icmpping', 'agent.ping', 'zabbix[host,agent,available]', 'zabbix[host,snmp,available]')
    GROUP BY t.triggerid
),
eventos_amostra AS (
    SELECT e.eventid, e.objectid, e.clock, e.value, c.hostid, c.sinal_candidato
    FROM candidatas c
    JOIN events e
        ON e.source = 0
       AND e.object = 0
       AND e.objectid = c.triggerid
       AND e.clock >= UNIX_TIMESTAMP('2026-01-01 00:00:00')
    ORDER BY e.eventid DESC
    LIMIT 500
),
intervalos AS (
    SELECT
        ea.eventid AS problem_eventid,
        ea.objectid AS triggerid,
        ea.hostid,
        ea.sinal_candidato,
        ea.clock AS inicio_clock,
        r.clock AS fim_clock,
        COALESCE(r.clock, UNIX_TIMESTAMP()) AS fim_comparacao
    FROM eventos_amostra ea
    LEFT JOIN event_recovery er ON er.eventid = ea.eventid
    LEFT JOIN events r ON r.eventid = er.r_eventid
    WHERE ea.value = 1
)
SELECT
    a.hostid,
    a.problem_eventid AS problem_eventid_a,
    b.problem_eventid AS problem_eventid_b,
    a.triggerid AS triggerid_a,
    b.triggerid AS triggerid_b,
    a.sinal_candidato AS sinal_a,
    b.sinal_candidato AS sinal_b,
    a.inicio_clock AS inicio_a,
    a.fim_clock AS fim_a,
    b.inicio_clock AS inicio_b,
    b.fim_clock AS fim_b
FROM intervalos a
JOIN intervalos b
    ON b.hostid = a.hostid
   AND b.problem_eventid > a.problem_eventid
   AND b.sinal_candidato <> a.sinal_candidato
   AND a.inicio_clock <= b.fim_comparacao
   AND b.inicio_clock <= a.fim_comparacao
ORDER BY a.hostid, a.problem_eventid, b.problem_eventid
LIMIT 100;

-- @id: 22
-- @output: 22_qualidade_reconstrucao.csv
-- @description: Reservada à matriz agregada de qualidade da reconstrução controlada.
-- @heavy: false
-- @enabled: true
-- @timeout: 180
WITH
candidatas AS (
    SELECT t.triggerid, MIN(i.hostid) AS hostid
    FROM items i
    JOIN hosts h ON h.hostid = i.hostid
    JOIN functions f ON f.itemid = i.itemid
    JOIN triggers t ON t.triggerid = f.triggerid
    WHERE h.flags = 0
      AND h.status IN (0, 1)
      AND i.key_ IN ('icmpping', 'agent.ping', 'zabbix[host,agent,available]', 'zabbix[host,snmp,available]')
    GROUP BY t.triggerid
),
eventos_amostra AS (
    SELECT e.eventid, e.objectid, e.clock, e.value, c.hostid
    FROM candidatas c
    JOIN events e
        ON e.source = 0
       AND e.object = 0
       AND e.objectid = c.triggerid
       AND e.clock >= UNIX_TIMESTAMP('2026-01-01 00:00:00')
    ORDER BY e.eventid DESC
    LIMIT 500
),
intervalos AS (
    SELECT
        ea.eventid AS problem_eventid,
        ea.objectid AS triggerid,
        ea.hostid,
        ea.clock AS inicio_clock,
        p.eventid AS problem_registrado,
        p.r_eventid AS problem_recovery_eventid,
        er.r_eventid AS recovery_eventid,
        r.eventid AS recovery_registrada,
        r.clock AS fim_clock,
        COALESCE(r.clock, UNIX_TIMESTAMP()) AS fim_comparacao
    FROM eventos_amostra ea
    LEFT JOIN problem p ON p.eventid = ea.eventid
    LEFT JOIN event_recovery er ON er.eventid = ea.eventid
    LEFT JOIN events r ON r.eventid = er.r_eventid
    WHERE ea.value = 1
),
sobreposicoes AS (
    SELECT a.problem_eventid AS eventid_a, b.problem_eventid AS eventid_b
    FROM intervalos a
    JOIN intervalos b
        ON b.hostid = a.hostid
       AND b.problem_eventid > a.problem_eventid
       AND a.inicio_clock <= b.fim_comparacao
       AND b.inicio_clock <= a.fim_comparacao
)
SELECT
    COUNT(*) AS problemas_selecionados,
    SUM(i.recovery_registrada IS NOT NULL) AS recuperados,
    SUM(i.recovery_eventid IS NULL) AS abertos,
    SUM(NOT EXISTS (SELECT 1 FROM triggers t WHERE t.triggerid = i.triggerid)) AS sem_trigger_mapeada,
    SUM(i.hostid IS NULL) AS sem_host_mapeado,
    SUM(i.problem_registrado IS NULL) AS sem_registro_problem,
    SUM(i.problem_recovery_eventid IS NOT NULL AND i.recovery_registrada IS NULL) AS recuperacao_ausente_quando_esperada,
    SUM(i.fim_clock IS NOT NULL AND i.fim_clock < i.inicio_clock) AS duracao_negativa,
    SUM(EXISTS (SELECT 1 FROM trigger_depends td WHERE td.triggerid_down = i.triggerid)) AS eventos_com_trigger_dependente,
    SUM(EXISTS (SELECT 1 FROM acknowledges a WHERE a.eventid = i.problem_eventid)) AS eventos_reconhecidos,
    SUM(EXISTS (SELECT 1 FROM event_suppress es WHERE es.eventid = i.problem_eventid)) AS eventos_suprimidos,
    (SELECT COUNT(*) FROM sobreposicoes) AS pares_intervalos_sobrepostos
FROM intervalos i;

-- @id: 23
-- @output: 23_amostra_anomalias_reconstrucao.csv
-- @description: Reservada a até 50 anomalias técnicas da reconstrução, somente com chaves e flags.
-- @heavy: false
-- @enabled: true
-- @timeout: 180
WITH
candidatas AS (
    SELECT t.triggerid, MIN(i.hostid) AS hostid
    FROM items i
    JOIN hosts h ON h.hostid = i.hostid
    JOIN functions f ON f.itemid = i.itemid
    JOIN triggers t ON t.triggerid = f.triggerid
    WHERE h.flags = 0
      AND h.status IN (0, 1)
      AND i.key_ IN ('icmpping', 'agent.ping', 'zabbix[host,agent,available]', 'zabbix[host,snmp,available]')
    GROUP BY t.triggerid
),
eventos_amostra AS (
    SELECT e.eventid, e.objectid, e.clock, e.value, c.hostid
    FROM candidatas c
    JOIN events e
        ON e.source = 0
       AND e.object = 0
       AND e.objectid = c.triggerid
       AND e.clock >= UNIX_TIMESTAMP('2026-01-01 00:00:00')
    ORDER BY e.eventid DESC
    LIMIT 500
)
SELECT
    ea.eventid AS problem_eventid,
    ea.objectid AS triggerid,
    er.r_eventid AS recovery_eventid,
    (p.eventid IS NULL) AS sem_registro_problem,
    (p.r_eventid IS NOT NULL AND er.eventid IS NULL) AS sem_event_recovery_esperado,
    (p.r_eventid IS NOT NULL AND er.r_eventid IS NOT NULL AND p.r_eventid <> er.r_eventid) AS recovery_divergente,
    (COALESCE(er.r_eventid, p.r_eventid) IS NOT NULL AND r.eventid IS NULL) AS recovery_evento_ausente,
    (r.clock IS NOT NULL AND r.clock < ea.clock) AS duracao_negativa,
    (ea.hostid IS NULL) AS sem_host_mapeado
FROM eventos_amostra ea
LEFT JOIN problem p ON p.eventid = ea.eventid
LEFT JOIN event_recovery er ON er.eventid = ea.eventid
LEFT JOIN events r ON r.eventid = COALESCE(er.r_eventid, p.r_eventid)
WHERE ea.value = 1
  AND (
      p.eventid IS NULL
      OR (p.r_eventid IS NOT NULL AND er.eventid IS NULL)
      OR (p.r_eventid IS NOT NULL AND er.r_eventid IS NOT NULL AND p.r_eventid <> er.r_eventid)
      OR (COALESCE(er.r_eventid, p.r_eventid) IS NOT NULL AND r.eventid IS NULL)
      OR (r.clock IS NOT NULL AND r.clock < ea.clock)
      OR ea.hostid IS NULL
  )
ORDER BY ea.eventid DESC
LIMIT 50;

-- @id: 24
-- @output: 24_matriz_modelo_eventos.csv
-- @description: Reservada à matriz compacta do modelo candidato de eventos após a Rodada 4B.
-- @heavy: false
-- @enabled: true
-- @timeout: 180
WITH
candidatas AS (
    SELECT t.triggerid, MIN(i.hostid) AS hostid
    FROM items i
    JOIN hosts h ON h.hostid = i.hostid
    JOIN functions f ON f.itemid = i.itemid
    JOIN triggers t ON t.triggerid = f.triggerid
    WHERE h.flags = 0
      AND h.status IN (0, 1)
      AND i.key_ IN ('icmpping', 'agent.ping', 'zabbix[host,agent,available]', 'zabbix[host,snmp,available]')
    GROUP BY t.triggerid
),
eventos_amostra AS (
    SELECT e.eventid, e.objectid, e.clock, e.value, e.severity, c.hostid
    FROM candidatas c
    JOIN events e
        ON e.source = 0
       AND e.object = 0
       AND e.objectid = c.triggerid
       AND e.clock >= UNIX_TIMESTAMP('2026-01-01 00:00:00')
    ORDER BY e.eventid DESC
    LIMIT 500
),
problemas AS (
    SELECT
        ea.eventid,
        ea.objectid,
        ea.hostid,
        ea.clock,
        ea.severity,
        p.correlationid,
        p.cause_eventid,
        er.r_eventid,
        er.c_eventid,
        er.correlationid AS recovery_correlationid,
        r.clock AS recovery_clock
    FROM eventos_amostra ea
    LEFT JOIN problem p ON p.eventid = ea.eventid
    LEFT JOIN event_recovery er ON er.eventid = ea.eventid
    LEFT JOIN events r ON r.eventid = er.r_eventid
    WHERE ea.value = 1
)
SELECT 'EVENTO_PROBLEMA' AS componente, 'events(source=0,object=0,value=1)' AS caminho_tecnico,
       COUNT(*) AS registros_observados_amostra, 'OBSERVADA' AS classificacao,
       'MODELO_CANDIDATO_NAO_OFICIAL' AS limitacao
FROM problemas
UNION ALL
SELECT 'PROBLEMA_RECUPERACAO', 'event_recovery.eventid -> r_eventid -> events.eventid',
       SUM(r_eventid IS NOT NULL), 'OBSERVADA', 'DURACAO_TECNICA_NAO_E_MTTR'
FROM problemas
UNION ALL
SELECT 'PROBLEMA_ABERTO', 'event_recovery.r_eventid ausente na amostra',
       SUM(r_eventid IS NULL), 'OBSERVADA', 'INTERVALO_SEM_FIM'
FROM problemas
UNION ALL
SELECT 'EVENTO_TRIGGER', 'events.objectid -> triggers.triggerid para source=0/object=0',
       SUM(objectid IS NOT NULL), 'OBSERVADA', 'CODIGOS_RESTRITOS_A_AMOSTRA'
FROM problemas
UNION ALL
SELECT 'TRIGGER_HOST', 'trigger -> function -> item -> host',
       SUM(hostid IS NOT NULL), 'OBSERVADA', 'CLASSIFICACAO_CANDIDATA'
FROM problemas
UNION ALL
SELECT 'SEVERIDADE_HISTORICA', 'events.severity',
       SUM(severity IS NOT NULL), 'OBSERVADA', 'COMPARAR_COM_PRIORIDADE_ATUAL'
FROM problemas
UNION ALL
SELECT 'RECONHECIMENTO', 'acknowledges.eventid',
       SUM(EXISTS (SELECT 1 FROM acknowledges a WHERE a.eventid = problemas.eventid)),
       'OBSERVADA', 'SEM_USUARIO_OU_MENSAGEM'
FROM problemas
UNION ALL
SELECT 'SUPRESSAO', 'event_suppress.eventid',
       SUM(EXISTS (SELECT 1 FROM event_suppress es WHERE es.eventid = problemas.eventid)),
       'OBSERVADA', 'MANUTENCAO_FORA_DO_ESCOPO'
FROM problemas
UNION ALL
SELECT 'DEPENDENCIA', 'trigger_depends.triggerid_down',
       SUM(EXISTS (SELECT 1 FROM trigger_depends td WHERE td.triggerid_down = problemas.objectid)),
       'OBSERVADA', 'NAO_EXCLUI_EVENTO_AUTOMATICAMENTE'
FROM problemas
UNION ALL
SELECT 'CORRELACAO_CAUSA', 'problem/event_recovery correlationid e cause_eventid',
       SUM(correlationid IS NOT NULL OR cause_eventid IS NOT NULL OR c_eventid IS NOT NULL OR recovery_correlationid IS NOT NULL),
       'OBSERVADA', 'SEM_INFERIR_SEMANTICA_ALEM_DOS_CAMPOS'
FROM problemas
ORDER BY componente;
