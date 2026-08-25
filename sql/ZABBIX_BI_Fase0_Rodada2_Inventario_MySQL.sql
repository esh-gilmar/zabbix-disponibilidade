/*
===============================================================================
BI-003 — Fase 0 — Rodada 2: Inventário e Classificação do Zabbix
Rodada 2A — Estrutura e inventário padrão
SGBD: MySQL
Database esperado: zabbix
Ferramenta: Generic SQL Extractor 2.0
===============================================================================

REGRAS DE SEGURANÇA
- Somente SELECT/CTE em estruturas cadastrais e metadados.
- Nenhuma estrutura histórica é consultada nesta rodada.
- Nenhuma view customizada tem seu conteúdo executado antes da análise de sua
  definição; as Consultas 03 e 04 consultam somente INFORMATION_SCHEMA.
- IP, DNS, credenciais e parâmetros secretos de SNMP não são retornados.
- Os códigos brutos são preservados e não recebem semântica funcional antes da
  análise das evidências da Rodada 2A.
===============================================================================
*/

-- @id: 1
-- @output: 01_estrutura_objetos_inventario.csv
-- @description: Cataloga colunas dos objetos cadastrais necessários à Rodada 2 sem consultar seu conteúdo.
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
      'hosts',
      'hstgrp',
      'hosts_groups',
      'host_tag',
      'hosts_templates',
      'interface',
      'interface_snmp',
      'host_inventory',
      'proxy',
      'proxy_group'
  )
ORDER BY c.TABLE_NAME, c.ORDINAL_POSITION;

-- @id: 2
-- @output: 02_indices_constraints_inventario.csv
-- @description: Cataloga PKs, FKs, uniques e índices dos objetos cadastrais da Rodada 2.
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
      'hosts', 'hstgrp', 'hosts_groups', 'host_tag', 'hosts_templates',
      'interface', 'interface_snmp', 'host_inventory', 'proxy', 'proxy_group'
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
      'hosts', 'hstgrp', 'hosts_groups', 'host_tag', 'hosts_templates',
      'interface', 'interface_snmp', 'host_inventory', 'proxy', 'proxy_group'
  )
ORDER BY table_name, registro_tipo, objeto_nome, ordinal_position;

-- @id: 3
-- @output: 03_estrutura_views_customizadas.csv
-- @description: Cataloga somente metadados de colunas das views customizadas relevantes.
-- @heavy: false
-- @enabled: true
-- @timeout: 120
SELECT
    c.TABLE_SCHEMA AS table_schema,
    c.TABLE_NAME AS view_name,
    c.ORDINAL_POSITION AS ordinal_position,
    c.COLUMN_NAME AS column_name,
    c.DATA_TYPE AS data_type,
    c.COLUMN_TYPE AS column_type,
    c.IS_NULLABLE AS is_nullable
FROM information_schema.COLUMNS c
WHERE c.TABLE_SCHEMA = DATABASE()
  AND c.TABLE_NAME IN (
      'View_Access_Points',
      'View_Switches',
      'View_Servidores',
      'View_Servidores_Fisicos',
      'View_Servidores_Virtuais',
      'View_Servidores_Windows',
      'View_Servidores_Linux'
  )
ORDER BY c.TABLE_NAME, c.ORDINAL_POSITION;

-- @id: 4
-- @output: 04_definicoes_views_customizadas.csv
-- @description: Obtém definições estruturais das views relevantes sem executar o conteúdo das views.
-- @heavy: false
-- @enabled: true
-- @timeout: 120
SELECT
    v.TABLE_SCHEMA AS table_schema,
    v.TABLE_NAME AS view_name,
    v.CHECK_OPTION AS check_option,
    v.IS_UPDATABLE AS is_updatable,
    v.SECURITY_TYPE AS security_type,
    v.VIEW_DEFINITION AS view_definition
FROM information_schema.VIEWS v
WHERE v.TABLE_SCHEMA = DATABASE()
  AND v.TABLE_NAME IN (
      'View_Access_Points',
      'View_Switches',
      'View_Servidores',
      'View_Servidores_Fisicos',
      'View_Servidores_Virtuais',
      'View_Servidores_Windows',
      'View_Servidores_Linux'
  )
ORDER BY v.TABLE_NAME;

-- @id: 5
-- @output: 05_hosts_distribuicao_status.csv
-- @description: Mede a distribuição bruta de hosts por status, flags, modo de monitoramento e vínculos de proxy.
-- @heavy: false
-- @enabled: true
-- @timeout: 90
SELECT
    h.status AS status_bruto,
    h.flags AS flags_bruto,
    h.monitored_by AS monitored_by_bruto,
    CASE WHEN h.proxyid IS NULL THEN 0 ELSE 1 END AS possui_proxyid,
    CASE WHEN h.proxy_groupid IS NULL THEN 0 ELSE 1 END AS possui_proxy_groupid,
    CASE WHEN h.templateid IS NULL THEN 0 ELSE 1 END AS possui_templateid_direto,
    COUNT(*) AS registros_hosts
FROM hosts h
GROUP BY
    h.status,
    h.flags,
    h.monitored_by,
    CASE WHEN h.proxyid IS NULL THEN 0 ELSE 1 END,
    CASE WHEN h.proxy_groupid IS NULL THEN 0 ELSE 1 END,
    CASE WHEN h.templateid IS NULL THEN 0 ELSE 1 END
ORDER BY
    h.status,
    h.flags,
    h.monitored_by,
    possui_proxyid,
    possui_proxy_groupid,
    possui_templateid_direto;

-- @id: 6
-- @output: 06_hosts_monitorados_habilitados_desabilitados.csv
-- @description: Quantifica hosts regulares habilitados e desabilitados após a evidência estrutural da Rodada 2A.
-- @heavy: false
-- @enabled: true
-- @timeout: 90
SELECT
    h.status AS status_bruto,
    h.flags AS flags_bruto,
    CASE
        WHEN h.status = 0 THEN 'HABILITADO'
        WHEN h.status = 1 THEN 'DESABILITADO'
    END AS situacao_monitoramento,
    COUNT(*) AS registros_hosts
FROM hosts h
WHERE h.flags = 0
  AND h.status IN (0, 1)
GROUP BY h.status, h.flags
ORDER BY h.status, h.flags;

-- @id: 7
-- @output: 07_grupos_hosts.csv
-- @description: Cataloga grupos e mede vínculos sem interpretar nomes como regras de negócio.
-- @heavy: false
-- @enabled: true
-- @timeout: 90
SELECT
    g.groupid,
    g.name AS grupo_nome,
    g.flags AS grupo_flags_bruto,
    g.type AS grupo_type_bruto,
    COUNT(hg.hostgroupid) AS vinculos,
    COUNT(DISTINCT hg.hostid) AS registros_hosts_distintos
FROM hstgrp g
LEFT JOIN hosts_groups hg
    ON hg.groupid = g.groupid
GROUP BY g.groupid, g.name, g.flags, g.type
ORDER BY g.name, g.groupid;

-- @id: 8
-- @output: 08_distribuicao_hosts_grupos.csv
-- @description: Distribui hosts regulares por grupo e situação de monitoramento com os códigos brutos preservados.
-- @heavy: false
-- @enabled: true
-- @timeout: 90
SELECT
    g.groupid,
    g.name AS grupo_nome,
    h.status AS host_status_bruto,
    h.flags AS host_flags_bruto,
    COUNT(*) AS vinculos,
    COUNT(DISTINCT h.hostid) AS registros_hosts_distintos
FROM hstgrp g
JOIN hosts_groups hg
    ON hg.groupid = g.groupid
JOIN hosts h
    ON h.hostid = hg.hostid
WHERE h.flags = 0
  AND h.status IN (0, 1)
GROUP BY g.groupid, g.name, h.status, h.flags
ORDER BY g.name, g.groupid, h.status, h.flags;

-- @id: 9
-- @output: 09_tags_catalogo_uso.csv
-- @description: Cataloga chaves e valores de tags com frequência e códigos brutos dos registros associados.
-- @heavy: false
-- @enabled: true
-- @timeout: 90
SELECT
    ht.tag,
    ht.value,
    ht.automatic AS automatic_bruto,
    h.status AS host_status_bruto,
    h.flags AS host_flags_bruto,
    COUNT(*) AS tags_registradas,
    COUNT(DISTINCT ht.hostid) AS registros_hosts_distintos
FROM host_tag ht
JOIN hosts h
    ON h.hostid = ht.hostid
GROUP BY ht.tag, ht.value, ht.automatic, h.status, h.flags
ORDER BY ht.tag, ht.value, ht.automatic, h.status, h.flags;

-- @id: 10
-- @output: 10_templates_vinculados.csv
-- @description: Cataloga templates vinculados e mede os registros de destino por códigos brutos.
-- @heavy: false
-- @enabled: true
-- @timeout: 90
SELECT
    t.hostid AS template_hostid,
    t.host AS template_nome_tecnico,
    t.name AS template_nome_visivel,
    t.status AS template_status_bruto,
    t.flags AS template_flags_bruto,
    ht.link_type AS link_type_bruto,
    h.status AS destino_status_bruto,
    h.flags AS destino_flags_bruto,
    COUNT(*) AS vinculos,
    COUNT(DISTINCT h.hostid) AS registros_destino_distintos
FROM hosts_templates ht
JOIN hosts t
    ON t.hostid = ht.templateid
JOIN hosts h
    ON h.hostid = ht.hostid
GROUP BY
    t.hostid,
    t.host,
    t.name,
    t.status,
    t.flags,
    ht.link_type,
    h.status,
    h.flags
ORDER BY t.name, t.host, t.hostid, ht.link_type, h.status, h.flags;

-- @id: 11
-- @output: 11_interfaces_cobertura.csv
-- @description: Mede cobertura de interfaces por códigos técnicos sem retornar IP, DNS, porta ou mensagens de erro.
-- @heavy: false
-- @enabled: true
-- @timeout: 90
SELECT
    i.type AS interface_type_bruto,
    i.main AS interface_main_bruto,
    i.useip AS interface_useip_bruto,
    i.available AS interface_available_bruto,
    h.status AS host_status_bruto,
    h.flags AS host_flags_bruto,
    COUNT(*) AS interfaces,
    COUNT(DISTINCT i.hostid) AS registros_hosts_distintos
FROM interface i
JOIN hosts h
    ON h.hostid = i.hostid
GROUP BY i.type, i.main, i.useip, i.available, h.status, h.flags
ORDER BY i.type, i.main, i.useip, i.available, h.status, h.flags;

-- @id: 12
-- @output: 12_interfaces_snmp_resumo.csv
-- @description: Resume cobertura SNMP usando somente campos técnicos não secretos.
-- @heavy: false
-- @enabled: true
-- @timeout: 90
SELECT
    s.version AS snmp_version_bruto,
    s.bulk AS bulk_bruto,
    s.securitylevel AS securitylevel_bruto,
    s.authprotocol AS authprotocol_bruto,
    s.privprotocol AS privprotocol_bruto,
    s.max_repetitions,
    h.status AS host_status_bruto,
    h.flags AS host_flags_bruto,
    COUNT(*) AS interfaces_snmp,
    COUNT(DISTINCT i.hostid) AS registros_hosts_distintos
FROM interface_snmp s
JOIN interface i
    ON i.interfaceid = s.interfaceid
JOIN hosts h
    ON h.hostid = i.hostid
GROUP BY
    s.version,
    s.bulk,
    s.securitylevel,
    s.authprotocol,
    s.privprotocol,
    s.max_repetitions,
    h.status,
    h.flags
ORDER BY
    s.version,
    s.securitylevel,
    s.authprotocol,
    s.privprotocol,
    s.bulk,
    s.max_repetitions,
    h.status,
    h.flags;

-- @id: 13
-- @output: 13_proxy_cobertura.csv
-- @description: Mede cobertura por proxy ou grupo de proxies sem expor endereços, TLS, timeouts ou outros parâmetros sensíveis.
-- @heavy: false
-- @enabled: true
-- @timeout: 90
SELECT
    h.monitored_by AS monitored_by_bruto,
    h.proxyid,
    p.name AS proxy_nome,
    p.operating_mode AS proxy_operating_mode_bruto,
    h.proxy_groupid,
    pg.name AS proxy_group_nome,
    h.status AS host_status_bruto,
    h.flags AS host_flags_bruto,
    COUNT(*) AS registros_hosts
FROM hosts h
LEFT JOIN proxy p
    ON p.proxyid = h.proxyid
LEFT JOIN proxy_group pg
    ON pg.proxy_groupid = h.proxy_groupid
GROUP BY
    h.monitored_by,
    h.proxyid,
    p.name,
    p.operating_mode,
    h.proxy_groupid,
    pg.name,
    h.status,
    h.flags
ORDER BY
    h.monitored_by,
    h.proxyid,
    h.proxy_groupid,
    h.status,
    h.flags;

-- @id: 14
-- @output: 14_origens_candidatas_localizacao.csv
-- @description: Consolida valores cadastrais candidatos de inventário, tags, grupos e nomes de colunas das views sem aprovar mapeamentos por semelhança.
-- @heavy: false
-- @enabled: true
-- @timeout: 120
SELECT
    'HOST_INVENTORY' AS origem_tipo,
    'host_inventory' AS origem_objeto,
    x.campo AS origem_campo,
    x.valor AS valor_observado,
    COUNT(DISTINCT x.hostid) AS registros_hosts_distintos
FROM (
    SELECT hostid, 'type' AS campo, NULLIF(TRIM(type), '') AS valor FROM host_inventory
    UNION ALL
    SELECT hostid, 'os', NULLIF(TRIM(os), '') FROM host_inventory
    UNION ALL
    SELECT hostid, 'os_full', NULLIF(TRIM(os_full), '') FROM host_inventory
    UNION ALL
    SELECT hostid, 'os_short', NULLIF(TRIM(os_short), '') FROM host_inventory
    UNION ALL
    SELECT hostid, 'location', NULLIF(TRIM(location), '') FROM host_inventory
    UNION ALL
    SELECT hostid, 'site_address_a', NULLIF(TRIM(site_address_a), '') FROM host_inventory
    UNION ALL
    SELECT hostid, 'site_address_b', NULLIF(TRIM(site_address_b), '') FROM host_inventory
    UNION ALL
    SELECT hostid, 'site_address_c', NULLIF(TRIM(site_address_c), '') FROM host_inventory
    UNION ALL
    SELECT hostid, 'site_city', NULLIF(TRIM(site_city), '') FROM host_inventory
    UNION ALL
    SELECT hostid, 'site_state', NULLIF(TRIM(site_state), '') FROM host_inventory
    UNION ALL
    SELECT hostid, 'site_country', NULLIF(TRIM(site_country), '') FROM host_inventory
    UNION ALL
    SELECT hostid, 'site_rack', NULLIF(TRIM(site_rack), '') FROM host_inventory
    UNION ALL
    SELECT hostid, 'deployment_status', NULLIF(TRIM(deployment_status), '') FROM host_inventory
) x
WHERE x.valor IS NOT NULL
GROUP BY x.campo, x.valor
UNION ALL
SELECT
    'HOST_TAG' AS origem_tipo,
    'host_tag' AS origem_objeto,
    ht.tag AS origem_campo,
    ht.value AS valor_observado,
    COUNT(DISTINCT ht.hostid) AS registros_hosts_distintos
FROM host_tag ht
GROUP BY ht.tag, ht.value
UNION ALL
SELECT
    'HOST_GROUP' AS origem_tipo,
    'hstgrp' AS origem_objeto,
    'name' AS origem_campo,
    g.name AS valor_observado,
    COUNT(DISTINCT hg.hostid) AS registros_hosts_distintos
FROM hstgrp g
LEFT JOIN hosts_groups hg
    ON hg.groupid = g.groupid
GROUP BY g.groupid, g.name
UNION ALL
SELECT
    'VIEW_COLUMN' AS origem_tipo,
    c.TABLE_NAME AS origem_objeto,
    c.COLUMN_NAME AS origem_campo,
    NULL AS valor_observado,
    0 AS registros_hosts_distintos
FROM information_schema.COLUMNS c
WHERE c.TABLE_SCHEMA = DATABASE()
  AND c.TABLE_NAME IN (
      'View_Access_Points',
      'View_Switches',
      'View_Servidores',
      'View_Servidores_Fisicos',
      'View_Servidores_Virtuais',
      'View_Servidores_Windows',
      'View_Servidores_Linux'
  )
ORDER BY origem_tipo, origem_objeto, origem_campo, valor_observado;

-- @id: 15
-- @output: 15_matriz_classificacao_host.csv
-- @description: Matriz candidata por host regular com sinais de grupo, template, tag, inventário e interface comprovados na Rodada 2A.
-- @heavy: false
-- @enabled: true
-- @timeout: 120
WITH
hosts_regulares AS (
    SELECT h.hostid, h.status, h.flags
    FROM hosts h
    WHERE h.flags = 0
      AND h.status IN (0, 1)
),
sinais_grupo AS (
    SELECT
        hg.hostid,
        MAX(g.groupid = 41) AS grupo_access_point,
        MAX(g.groupid = 27) AS grupo_switch,
        MAX(g.groupid = 22) AS grupo_servidor,
        MAX(g.groupid = 23) AS grupo_fisico,
        MAX(g.groupid = 24) AS grupo_virtual,
        MAX(g.groupid = 25) AS grupo_windows,
        MAX(g.groupid = 26) AS grupo_linux,
        GROUP_CONCAT(
            DISTINCT CASE
                WHEN g.groupid IN (22, 23, 24, 25, 26, 27, 41) THEN g.name
            END
            ORDER BY g.name SEPARATOR ' | '
        ) AS grupos_classificacao_observados
    FROM hosts_groups hg
    JOIN hstgrp g
        ON g.groupid = hg.groupid
    GROUP BY hg.hostid
),
sinais_template AS (
    SELECT
        ht.hostid,
        MAX(ht.templateid = 10774) AS template_access_point,
        MAX(ht.templateid = 10777) AS template_switch,
        MAX(ht.templateid = 10081) AS template_windows,
        MAX(ht.templateid = 10001) AS template_linux,
        GROUP_CONCAT(
            DISTINCT CASE
                WHEN ht.templateid IN (10774, 10777, 10081, 10001) THEN t.name
            END
            ORDER BY t.name SEPARATOR ' | '
        ) AS templates_classificacao_observados
    FROM hosts_templates ht
    JOIN hosts t
        ON t.hostid = ht.templateid
    GROUP BY ht.hostid
),
sinais_tag AS (
    SELECT
        ht.hostid,
        COUNT(*) AS quantidade_tags,
        GROUP_CONCAT(
            DISTINCT CONCAT(ht.tag, '=', ht.value)
            ORDER BY ht.tag, ht.value SEPARATOR ' | '
        ) AS tags_observadas
    FROM host_tag ht
    GROUP BY ht.hostid
),
sinais_interface AS (
    SELECT
        i.hostid,
        MAX(i.type = 1) AS usa_agente,
        MAX(i.type = 2) AS usa_snmp,
        COUNT(*) AS quantidade_interfaces
    FROM interface i
    GROUP BY i.hostid
)
SELECT
    hr.hostid,
    hr.status AS status_bruto,
    hr.flags AS flags_bruto,
    CASE WHEN hr.status = 0 THEN 'HABILITADO' ELSE 'DESABILITADO' END AS situacao_monitoramento,
    COALESCE(sg.grupo_access_point, 0) AS sinal_grupo_access_point,
    COALESCE(st.template_access_point, 0) AS sinal_template_access_point,
    COALESCE(sg.grupo_switch, 0) AS sinal_grupo_switch,
    COALESCE(st.template_switch, 0) AS sinal_template_switch,
    COALESCE(sg.grupo_servidor, 0) AS sinal_grupo_servidor,
    COALESCE(sg.grupo_fisico, 0) AS sinal_grupo_fisico,
    COALESCE(sg.grupo_virtual, 0) AS sinal_grupo_virtual,
    COALESCE(sg.grupo_windows, 0) AS sinal_grupo_windows,
    COALESCE(st.template_windows, 0) AS sinal_template_windows,
    COALESCE(sg.grupo_linux, 0) AS sinal_grupo_linux,
    COALESCE(st.template_linux, 0) AS sinal_template_linux,
    COALESCE(si.usa_agente, 0) AS usa_interface_agente,
    COALESCE(si.usa_snmp, 0) AS usa_interface_snmp,
    COALESCE(si.quantidade_interfaces, 0) AS quantidade_interfaces,
    COALESCE(stg.quantidade_tags, 0) AS quantidade_tags,
    stg.tags_observadas,
    hi.os AS inventario_os_observado,
    sg.grupos_classificacao_observados,
    st.templates_classificacao_observados
FROM hosts_regulares hr
LEFT JOIN sinais_grupo sg
    ON sg.hostid = hr.hostid
LEFT JOIN sinais_template st
    ON st.hostid = hr.hostid
LEFT JOIN sinais_tag stg
    ON stg.hostid = hr.hostid
LEFT JOIN sinais_interface si
    ON si.hostid = hr.hostid
LEFT JOIN host_inventory hi
    ON hi.hostid = hr.hostid
ORDER BY hr.hostid;

-- @id: 16
-- @output: 16_qualidade_classificacao.csv
-- @description: Mede cobertura, incompletude e conflitos das classificações candidatas comprovadas na Rodada 2A.
-- @heavy: false
-- @enabled: true
-- @timeout: 120
WITH
hosts_regulares AS (
    SELECT h.hostid
    FROM hosts h
    WHERE h.flags = 0
      AND h.status IN (0, 1)
),
sinais_grupo AS (
    SELECT
        hg.hostid,
        MAX(hg.groupid = 41) AS access_point,
        MAX(hg.groupid = 27) AS switch,
        MAX(hg.groupid = 22) AS servidor,
        MAX(hg.groupid = 23) AS fisico,
        MAX(hg.groupid = 24) AS virtual_flag,
        MAX(hg.groupid = 25) AS windows,
        MAX(hg.groupid = 26) AS linux
    FROM hosts_groups hg
    GROUP BY hg.hostid
),
sinais_template AS (
    SELECT
        ht.hostid,
        MAX(ht.templateid = 10774) AS access_point,
        MAX(ht.templateid = 10777) AS switch,
        MAX(ht.templateid = 10081) AS windows,
        MAX(ht.templateid = 10001) AS linux
    FROM hosts_templates ht
    GROUP BY ht.hostid
),
matriz AS (
    SELECT
        hr.hostid,
        GREATEST(COALESCE(sg.access_point, 0), COALESCE(st.access_point, 0)) AS access_point,
        GREATEST(COALESCE(sg.switch, 0), COALESCE(st.switch, 0)) AS switch,
        COALESCE(sg.servidor, 0) AS servidor,
        COALESCE(sg.fisico, 0) AS fisico,
        COALESCE(sg.virtual_flag, 0) AS virtual_flag,
        GREATEST(COALESCE(sg.windows, 0), COALESCE(st.windows, 0)) AS windows,
        GREATEST(COALESCE(sg.linux, 0), COALESCE(st.linux, 0)) AS linux
    FROM hosts_regulares hr
    LEFT JOIN sinais_grupo sg
        ON sg.hostid = hr.hostid
    LEFT JOIN sinais_template st
        ON st.hostid = hr.hostid
)
SELECT
    COUNT(*) AS total_hosts_regulares,
    SUM(access_point = 1) AS access_points_classificados,
    SUM(switch = 1) AS switches_classificados,
    SUM(servidor = 1) AS servidores_classificados,
    SUM(fisico = 1) AS fisicos_classificados,
    SUM(virtual_flag = 1) AS virtuais_classificados,
    SUM(windows = 1) AS windows_classificados,
    SUM(linux = 1) AS linux_classificados,
    SUM((access_point + switch + servidor) = 0) AS sem_classificacao_principal,
    SUM((access_point + switch + servidor) > 1) AS classificacao_principal_ambigua,
    SUM(access_point = 1 AND servidor = 1) AS conflito_access_point_servidor,
    SUM(switch = 1 AND servidor = 1) AS conflito_switch_servidor,
    SUM(fisico = 1 AND virtual_flag = 1) AS conflito_fisico_virtual,
    SUM(windows = 1 AND linux = 1) AS conflito_windows_linux,
    SUM(servidor = 1 AND fisico = 0 AND virtual_flag = 0) AS servidor_sem_fisico_virtual,
    SUM(servidor = 1 AND windows = 0 AND linux = 0) AS servidor_sem_windows_linux,
    SUM((fisico = 1 OR virtual_flag = 1) AND servidor = 0) AS fisico_virtual_sem_servidor,
    SUM((windows = 1 OR linux = 1) AND servidor = 0) AS sistema_operacional_sem_servidor
FROM matriz;

-- @id: 17
-- @output: 17_qualidade_localizacao.csv
-- @description: Mede completude de Unidade e Prédio por grupos e formaliza a ausência de fonte para Sala, Setor e Departamento.
-- @heavy: false
-- @enabled: true
-- @timeout: 120
WITH
hosts_regulares AS (
    SELECT h.hostid
    FROM hosts h
    WHERE h.flags = 0
      AND h.status IN (0, 1)
),
localizacao AS (
    SELECT
        hr.hostid,
        COALESCE(MAX(hg.groupid IN (39, 40)), 0) AS possui_unidade,
        COALESCE(MAX(hg.groupid IN (42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52)), 0) AS possui_predio
    FROM hosts_regulares hr
    LEFT JOIN hosts_groups hg
        ON hg.hostid = hr.hostid
    GROUP BY hr.hostid
)
SELECT
    COUNT(*) AS total_hosts_regulares,
    SUM(possui_unidade = 1) AS com_unidade,
    SUM(possui_unidade = 0) AS sem_unidade,
    SUM(possui_predio = 1) AS com_predio,
    SUM(possui_predio = 0) AS sem_predio,
    0 AS fonte_sala_comprovada,
    0 AS fonte_setor_comprovada,
    0 AS fonte_departamento_comprovada,
    0 AS completos_cinco_campos,
    SUM(possui_unidade = 1 OR possui_predio = 1) AS parcialmente_preenchidos,
    SUM(possui_unidade = 0 AND possui_predio = 0) AS totalmente_ausentes_nas_fontes_comprovadas,
    'Sala|Setor|Departamento' AS campos_sem_fonte_comprovada
FROM localizacao;

-- @id: 18
-- @output: 18_amostra_incompletos_conflitos.csv
-- @description: Amostra por hostid de lacunas e conflitos de classificação/localização, limitada a 50 registros.
-- @heavy: false
-- @enabled: true
-- @timeout: 120
WITH
hosts_regulares AS (
    SELECT h.hostid, h.status
    FROM hosts h
    WHERE h.flags = 0
      AND h.status IN (0, 1)
),
sinais_grupo AS (
    SELECT
        hg.hostid,
        MAX(hg.groupid = 41) AS access_point,
        MAX(hg.groupid = 27) AS switch,
        MAX(hg.groupid = 22) AS servidor,
        MAX(hg.groupid = 23) AS fisico,
        MAX(hg.groupid = 24) AS virtual_flag,
        MAX(hg.groupid = 25) AS windows,
        MAX(hg.groupid = 26) AS linux,
        MAX(hg.groupid IN (39, 40)) AS unidade,
        MAX(hg.groupid IN (42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52)) AS predio
    FROM hosts_groups hg
    GROUP BY hg.hostid
),
sinais_template AS (
    SELECT
        ht.hostid,
        MAX(ht.templateid = 10774) AS access_point,
        MAX(ht.templateid = 10777) AS switch,
        MAX(ht.templateid = 10081) AS windows,
        MAX(ht.templateid = 10001) AS linux
    FROM hosts_templates ht
    GROUP BY ht.hostid
),
matriz AS (
    SELECT
        hr.hostid,
        hr.status,
        GREATEST(COALESCE(sg.access_point, 0), COALESCE(st.access_point, 0)) AS access_point,
        GREATEST(COALESCE(sg.switch, 0), COALESCE(st.switch, 0)) AS switch,
        COALESCE(sg.servidor, 0) AS servidor,
        COALESCE(sg.fisico, 0) AS fisico,
        COALESCE(sg.virtual_flag, 0) AS virtual_flag,
        GREATEST(COALESCE(sg.windows, 0), COALESCE(st.windows, 0)) AS windows,
        GREATEST(COALESCE(sg.linux, 0), COALESCE(st.linux, 0)) AS linux,
        COALESCE(sg.unidade, 0) AS unidade,
        COALESCE(sg.predio, 0) AS predio
    FROM hosts_regulares hr
    LEFT JOIN sinais_grupo sg
        ON sg.hostid = hr.hostid
    LEFT JOIN sinais_template st
        ON st.hostid = hr.hostid
)
SELECT
    hostid,
    status AS status_bruto,
    (access_point + switch + servidor = 0) AS sem_classificacao_principal,
    (access_point + switch + servidor > 1) AS classificacao_principal_ambigua,
    (access_point = 1 AND servidor = 1) AS conflito_access_point_servidor,
    (switch = 1 AND servidor = 1) AS conflito_switch_servidor,
    (fisico = 1 AND virtual_flag = 1) AS conflito_fisico_virtual,
    (windows = 1 AND linux = 1) AS conflito_windows_linux,
    (servidor = 1 AND fisico = 0 AND virtual_flag = 0) AS servidor_sem_fisico_virtual,
    (servidor = 1 AND windows = 0 AND linux = 0) AS servidor_sem_windows_linux,
    (unidade = 0) AS sem_unidade,
    (predio = 0) AS sem_predio,
    1 AS lacuna_fonte_sala_setor_departamento
FROM matriz
WHERE (access_point + switch + servidor = 0)
   OR (access_point + switch + servidor > 1)
   OR (fisico = 1 AND virtual_flag = 1)
   OR (windows = 1 AND linux = 1)
   OR (servidor = 1 AND fisico = 0 AND virtual_flag = 0)
   OR (servidor = 1 AND windows = 0 AND linux = 0)
   OR unidade = 0
   OR predio = 0
ORDER BY
    classificacao_principal_ambigua DESC,
    conflito_fisico_virtual DESC,
    conflito_windows_linux DESC,
    hostid
LIMIT 50;

-- @id: 19
-- @output: 19_reconciliacao_views_fontes_padrao.csv
-- @description: Desabilitada: todas as sete views relevantes dependem de estruturas históricas proibidas nesta rodada.
-- @heavy: false
-- @enabled: false
-- @timeout: 120
SELECT 'INVIAVEL_NESTA_RODADA_POR_DEPENDENCIA_HISTORICA' AS estado;

-- @id: 20
-- @output: 20_amostra_divergencias_views.csv
-- @description: Desabilitada porque a Consulta 19 é inviável com segurança nesta rodada.
-- @heavy: false
-- @enabled: false
-- @timeout: 120
SELECT 'INVIAVEL_NESTA_RODADA_POR_DEPENDENCIA_HISTORICA' AS estado
LIMIT 50;
