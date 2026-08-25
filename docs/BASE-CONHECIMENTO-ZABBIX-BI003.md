# Base de Conhecimento — Zabbix / BI-003

**Produto:** MVP de Disponibilidade da Infraestrutura de TI  
**Fonte técnica primária:** Zabbix  
**Arquitetura alvo:** Zabbix API → Python → PostgreSQL → Power BI  
**Período inicial do MVP:** 01/01/2026 em diante, limitado à retenção real disponível  
**Regime inicial:** 24x7  
**Status da descoberta:** Rodadas 1–5 concluídas; Rodada 6 pausada  
**Atualização desta base:** 25/08/2026

---

## 1. Finalidade deste documento

Este arquivo consolida o conhecimento técnico produzido nas Rodadas 1–5 da Fase 0 do BI-003 e deve ser usado como ponto de partida para o ETL, o modelo analítico PostgreSQL e a primeira visualização no Power BI.

Ele não substitui o relatório cumulativo nem as SPECs das rodadas. Para rastreabilidade detalhada, consultar:

- `docs/ZABBIX_BI_Fase0_RELATORIO.md`;
- `docs/SPEC-BI-003-MVP-Disponibilidade-Infraestrutura-TI.md`;
- os pacotes em `sql/`.

A regra de continuidade é: **não refazer descoberta já comprovada sem uma necessidade técnica explícita**.

---

## 2. Vocabulário de evidência

Toda regra ou conclusão deve ser classificada como:

- **OBSERVADA:** comprovada diretamente pelos dados/metadados coletados;
- **DECLARADA:** confirmada por documentação, configuração ou responsável técnico;
- **INFERIDA:** conclusão lógica sustentada por evidências observadas;
- **HIPÓTESE / PENDENTE:** ainda requer validação.

Relacionamento estrutural por FK não equivale automaticamente a semântica funcional de negócio.

---

## 3. Regra semântica vigente para o ETL inicial

A primeira versão do produto trabalhará explicitamente com:

`INDISPONIBILIDADE_OBSERVADA`

O objetivo imediato é responder:

- o ativo apresentou uma janela observada de indisponibilidade?
- quando ela começou?
- quando recuperou?
- quanto tempo durou?
- qual a disponibilidade observada no período?

Nesta etapa, **não** classificar automaticamente uma janela como:

- reboot;
- manutenção;
- falha de rede;
- falha do agente;
- falha SNMP;
- queda elétrica;
- falha de componente;
- causa raiz.

A classificação `RESET_UPTIME_CANDIDATO` permanece diferente de `REBOOT`.

Ausência de dado também não deve ser interpretada automaticamente como indisponibilidade.

> Esta semântica temporária é a regra operacional do ETL inicial e prevalece sobre interpretações conceituais anteriores quando houver conflito.

---

## 4. Limite arquitetural

### 4.1 Produção

Arquitetura aprovada:

```text
Zabbix API — somente leitura
        ↓
Coletor / ETL Python incremental
        ↓
PostgreSQL analítico
        ↓
Power BI
```

O Power BI não deverá consultar diretamente o MySQL produtivo do Zabbix.

### 4.2 Papel do MySQL

O acesso ao MySQL foi utilizado principalmente na Fase 0 para:

- descoberta de metadados;
- compreensão do modelo;
- validação de FKs e índices;
- análise de inventário, itens e triggers;
- reconstrução controlada de eventos/recuperações;
- análise seletiva de uptime.

Os SQLs da Fase 0 são evidência e ferramenta de reconciliação. Eles **não** definem a arquitetura produtiva do ETL.

---

## 5. Ambiente técnico observado

### 5.1 MySQL / schema

**OBSERVADO**

- MySQL: `8.0.46-0ubuntu0.22.04.3`;
- database: `zabbix`;
- charset: `utf8mb4`;
- collation: `utf8mb4_bin`;
- timezone técnico da coleta: UTC-4;
- `dbversion.mandatory = 7020000`;
- `dbversion.optional = 7020004`.

A versão exata do produto Zabbix Server continua pendente de confirmação via aplicação/API/administração.

### 5.2 Catálogo

**OBSERVADO**

- 203 tabelas base;
- 28 views;
- 1.777 colunas;
- 607 entradas de índices;
- 602 registros de constraints;
- 272 FKs declaradas;
- InnoDB nas tabelas base observadas;
- nenhuma tabela base sem PK detectada;
- nenhum particionamento detectado.

### 5.3 Volumetria e risco

**OBSERVADO**

Volume aproximado das tabelas base:

- 17.466,75 MB;
- 287.469.431 linhas estimadas.

Maiores estruturas:

| Tabela | Linhas estimadas | Tamanho estimado |
|---|---:|---:|
| `history_uint` | 149.959.014 | 8.708,38 MB |
| `history` | 95.188.624 | 5.467,25 MB |
| `trends_uint` | 26.683.961 | 1.902,77 MB |
| `trends` | 14.224.070 | 984,81 MB |

**REGRA TÉCNICA:** qualquer consulta histórica direta deve filtrar primeiro por `itemid` e por uma janela temporal limitada. Nunca varrer `history*` ou `trends*` globalmente para o BI.

---

## 6. Inventário e classificação de ativos

### 6.1 Hosts regulares

**OBSERVADO / INFERIDO**

A Rodada 2 refinou `hosts` para:

- 135 hosts regulares;
- 123 habilitados;
- 12 desabilitados;
- 352 templates;
- 46 outros registros com `flags = 2`.

Critério estrutural usado na descoberta para hosts regulares:

```text
flags = 0
status IN (0,1)
```

Esse critério é evidência da Fase 0 e deve ser comparado com o comportamento da API antes de virar filtro permanente do coletor.

### 6.2 Classificação candidata por grupos

**OBSERVADO / INFERIDO**

| Classe | Grupo | groupid | Hosts |
|---|---|---:|---:|
| Access Point | `Access_Points` | 41 | 19 |
| Switch | `Switches` | 27 | 16 |
| Servidor | `Servidores` | 22 | 45 |
| Servidor físico | `Servidores-Fisicos` | 23 | 6 |
| Servidor virtual | `Servidores-Virtuais` | 24 | 38 |
| Windows | `Servidores-Windows` | 25 | 32 |
| Linux | `Servidores-Linux` | 26 | 12 |

Qualidade observada:

- 55 hosts regulares sem classificação principal AP/switch/servidor;
- 0 conflitos de classificação principal;
- 1 servidor sem físico/virtual;
- 1 servidor sem Windows/Linux.

### 6.3 Grupos × templates

Templates corroboram a classificação, mas não possuem cobertura suficiente para substituí-la:

| Classe | Grupo + template | Somente grupo | Somente template |
|---|---:|---:|---:|
| AP | 18 | 1 | 0 |
| Switch | 1 | 15 | 0 |
| Windows | 29 | 3 | 0 |
| Linux | 12 | 0 | 0 |

**Conclusão para o MVP:** grupos são a melhor fonte atualmente comprovada para classificação; templates podem atuar como evidência complementar.

### 6.4 Tags de host

**OBSERVADO**

Nenhum dos 135 hosts regulares possuía tag cadastrada na remessa. Portanto, tags de host **não** sustentam hoje a classificação dos ativos regulares, mesmo existindo tags em templates e outros objetos.

---

## 7. Localização

**OBSERVADO / INFERIDO**

Fontes atualmente comprovadas:

- Unidade: grupos 39/40; cobertura de 1 host;
- Prédio: grupos 42–52; cobertura de 21 hosts;
- Sala: sem fonte cadastral comprovada;
- Setor: sem fonte cadastral comprovada;
- Departamento: sem fonte cadastral comprovada.

Qualidade:

- 0 hosts completos nas cinco dimensões desejadas;
- 22 parcialmente preenchidos;
- 113 sem localização nas fontes comprovadas.

A ausência de localização completa não bloqueia o primeiro BI de disponibilidade por ativo/tipo, mas bloqueia uma hierarquia geográfica confiável completa.

---

## 8. Interfaces e formas de monitoramento

**OBSERVADO / INFERIDO**

- 157 interfaces;
- 109 interfaces tipo bruto `1`;
- 48 interfaces tipo bruto `2`;
- 84 hosts regulares com interface de agente;
- 48 com interface SNMP;
- 3 com ambas;
- 6 sem interface.

A interpretação operacional utilizada na Fase 0 foi:

- tipo `1` → agente;
- tipo `2` → SNMP.

Não confundir **presença de interface** com **presença de item/trigger de disponibilidade**.

---

## 9. Itens candidatos de disponibilidade

### 9.1 Famílias observadas

| Papel candidato | Chave | Hosts |
|---|---|---:|
| ICMP | `icmpping` | 84 |
| Agente/check | `agent.ping` | 41 |
| Agente/disponibilidade interna | `zabbix[host,agent,available]` | 41 |
| SNMP/disponibilidade interna | `zabbix[host,snmp,available]` | 37 |
| Uptime SO | `system.uptime` | 41 |
| Uptime SNMP hardware | `system.hw.uptime[hrSystemUptime.0]` | 30 |
| Uptime SNMP rede | `system.net.uptime[sysUpTime.0]` | 30 |

`icmppingloss` e `icmppingsec` foram classificados como sinais de saúde/qualidade de ICMP, não como disponibilidade binária principal.

### 9.2 Cobertura por classe

| Classe | Hosts | ICMP | Agente | SNMP | Uptime |
|---|---:|---:|---:|---:|---:|
| Access Points | 19 | 19 | — | 18 | 18 |
| Switches | 16 | 14 | — | 1 | 1 |
| Servidores | 45 | 2 | 41 | — | 41 |
| Windows | 32 | 1 | 29 | — | 29 |
| Linux | 12 | 1 | 12 | — | 12 |

### 9.3 Consequência semântica importante

O desenho conceitual original propunha:

```text
Servidor indisponível = ICMP indisponível E agente indisponível
Ativo de rede indisponível = ICMP indisponível E SNMP indisponível
```

A configuração observada **não suporta essa conjunção para toda a frota**:

- servidor: apenas 2/45 possuem ICMP candidato;
- switch: apenas 1/16 possui SNMP candidato;
- AP: 18/19 possuem ICMP + SNMP e sustentam bem a hipótese estruturalmente.

Portanto, a primeira visão deve expor a **fonte do sinal** e não fingir que existe uma regra uniforme já validada para todas as classes.

---

## 10. Triggers candidatas

**OBSERVADO / INFERIDO**

Foram identificadas 164 triggers candidatas associadas aos sinais de disponibilidade:

- 86 ICMP;
- 41 agente;
- 37 SNMP.

Prioridades observadas:

- 37 com prioridade 2;
- 53 com prioridade 3;
- 73 com prioridade 4;
- 1 com prioridade 5.

Características:

- todas habilitadas;
- 162 utilizam `max`;
- 1 utiliza `avg`;
- 1 utiliza `last`;
- todas com `recovery_mode = 0`;
- todas com `correlation_mode = 0`;
- 41 permitem fechamento manual;
- 116 possuem dependência estrutural;
- 162 têm tag `scope=availability`;
- 2 não tinham tag associada na consulta controlada.

### 10.1 Caminho estrutural comprovado

```text
hosts.hostid
← items.hostid
← functions.itemid
→ functions.triggerid
→ triggers.triggerid
```

FKs relevantes:

```text
items.hostid                   → hosts.hostid
items.templateid               → items.itemid
functions.itemid               → items.itemid
functions.triggerid            → triggers.triggerid
trigger_depends.triggerid_down → triggers.triggerid
trigger_depends.triggerid_up   → triggers.triggerid
trigger_tag.triggerid          → triggers.triggerid
```

---

## 11. Eventos e recuperação

### 11.1 Estruturas relevantes

- `events`;
- `problem`;
- `event_recovery`;
- `acknowledges`;
- `event_suppress`;
- `trigger_depends`.

### 11.2 Caminho observado

Para o recorte estudado com `source=0`, `object=0`:

```text
events(value=1, objectid=triggerid)
→ event_recovery.eventid
→ event_recovery.r_eventid
→ events(value=0)
→ trigger
→ function
→ item
→ host
```

Esse caminho é tecnicamente suficiente para reconstruir uma **janela observada de problema/recuperação**, sem atribuir ainda uma causa.

### 11.3 Evidência da amostra da Rodada 4

Amostra comum de 500 eventos candidatos:

- 249 eventos de problema;
- 241 recuperados;
- 8 abertos dentro da amostra;
- 12 problemas abertos no universo candidato anual da Consulta 14;
- 0 problemas sem trigger mapeada;
- 0 sem host mapeado;
- 0 durações negativas.

Nos 241 intervalos encerrados:

- duração mínima: 60 s;
- máxima: 922.560 s;
- média descritiva: 5.875,27 s.

Essas durações são **intervalos técnicos**, não MTTR, SLA ou indisponibilidade oficial.

### 11.4 `problem` não é fonte histórica suficiente isoladamente

Dos 249 problemas da amostra, 224 já não possuíam linha correspondente em `problem`, enquanto 241 intervalos foram reconstruídos por `event_recovery`.

**Consequência:** o ETL histórico não deve depender apenas da tabela/endpoint equivalente a problemas atualmente abertos/persistidos. O histórico de eventos + recuperação precisa ser preservado na camada analítica própria.

### 11.5 Severidade histórica

Dos 249 problemas:

- 243 tinham severidade histórica igual à prioridade atual da trigger;
- 6 divergiam.

O modelo deve preservar a severidade do evento histórico e não derivá-la exclusivamente da prioridade atual da trigger.

---

## 12. Sobreposição e dupla contagem

**OBSERVADO**

A Rodada 4 encontrou dois pares de intervalos sobrepostos no mesmo host; um deles combinava:

```text
DISPONIBILIDADE_SNMP + DISPONIBILIDADE_ICMP
```

**REGRA TÉCNICA OBRIGATÓRIA:** o cálculo agregado por ativo deve realizar união temporal de janelas aplicáveis antes de somar segundos indisponíveis.

Não somar diretamente durações de triggers independentes.

---

## 13. Manutenção e supressão

### 13.1 Estrutura existe

FKs relevantes:

```text
maintenances_hosts.maintenanceid   → maintenances.maintenanceid
maintenances_hosts.hostid          → hosts.hostid
maintenances_groups.maintenanceid  → maintenances.maintenanceid
maintenances_groups.groupid        → hstgrp.groupid
maintenances_windows.maintenanceid → maintenances.maintenanceid
maintenances_windows.timeperiodid  → timeperiods.timeperiodid
maintenance_tag.maintenanceid      → maintenances.maintenanceid
event_suppress.eventid             → events.eventid
event_suppress.maintenanceid       → maintenances.maintenanceid
```

### 13.2 Estado observado na Rodada 5

- nenhuma manutenção retornada nas consultas pequenas;
- `event_suppress` sem registros;
- 135 hosts regulares com `maintenance_status=0`, `maintenance_type=0` e `maintenanceid` nulo;
- 134 eventos candidatos recentes classificados tecnicamente como não suprimidos.

**IMPORTANTE:** isso é fotografia do estado observado e **não prova ausência histórica de manutenção**.

Na primeira visão de `INDISPONIBILIDADE_OBSERVADA`, não excluir silenciosamente uma janela por hipótese de manutenção.

---

## 14. Uptime e resets candidatos

### 14.1 Estrutura

Foram identificados 101 itens candidatos de uptime com `value_type=3`, portanto mapeados para `history_uint` no gate analisado.

PK de `history_uint`:

```text
PRIMARY(itemid, clock, ns)
```

### 14.2 Amostra seletiva

Rodada 5B:

- 8 itemids;
- janela de 14 dias;
- 320.833 amostras no recorte filtrado;
- 25 `RESET_UPTIME_CANDIDATO`;
- 7 dos 8 itemids apresentaram queda.

Distribuição:

- AP / uptime SNMP hardware: 12;
- Windows / `system.uptime`: 2;
- Linux / `system.uptime`: 5;
- outra classe / uptime SNMP hardware: 6;
- switch selecionado: 0.

Dos 25 resets:

- 13 tinham evento candidato no mesmo host em ±30 minutos;
- 12 não tinham;
- os 13 eventos próximos eram ICMP;
- distância absoluta: 4 a 715 s;
- média descritiva: 207,46 s.

**REGRA:** proximidade temporal não comprova causalidade. Manter `RESET_UPTIME_CANDIDATO` até validação semântica posterior.

---

## 15. Views customizadas encontradas

Views observadas:

- `View_Access_Points`;
- `View_Switches`;
- `View_Servidores`;
- `View_Servidores_Fisicos`;
- `View_Servidores_Virtuais`;
- `View_Servidores_Windows`;
- `View_Servidores_Linux`.

Elas:

- usam grupos para classificação;
- combinam `hosts`, `hosts_groups`, `items`, `interface`;
- consultam histórico para obter valores recentes;
- apresentam semânticas diferentes para `STATUS` entre si.

**Conclusão:** são referência de implementação existente, não fonte oficial do novo BI. Não reutilizar `STATUS`, `PING`, `SNMP`, `ZABBIX` ou `UPTIME` dessas views como regra definitiva sem reconciliação.

---

## 16. O que já é suficiente para iniciar o ETL

É possível iniciar um ETL mínimo de **indisponibilidade observada** com:

1. cadastro de hosts/ativos e status de monitoramento;
2. grupos para classificação inicial;
3. itens e triggers de disponibilidade candidatos;
4. eventos de problema das triggers selecionadas;
5. vínculo de recuperação (`event_recovery` / equivalente da API);
6. relacionamento trigger → item → host;
7. severidade histórica do evento;
8. indicação da fonte do sinal (`ICMP`, `AGENTE`, `SNMP`);
9. intervalo aberto/encerrado;
10. consolidação temporal por ativo.

Não precisamos conhecer a causa da indisponibilidade para construir essa primeira camada.

---

## 17. Lacuna que realmente afeta o indicador

A principal lacuna técnica não é a causa; é a **regra de seleção/composição do sinal que representa disponibilidade observada por classe/ativo**, pois a cobertura é heterogênea.

Até a validação semântica final, a abordagem recomendada é:

- preservar o sinal técnico original;
- não afirmar uma conjunção que o ativo não possui;
- carregar janelas candidatas com rastreabilidade;
- expor `fonte_sinal` e `regra_mvp`;
- calcular uma visão de disponibilidade observada somente sobre sinais explicitamente aceitos para o MVP;
- manter indicador de cobertura/qualidade.

Essa decisão deve ser parametrizável, não hardcoded em dezenas de consultas.

---

## 18. Modelo mínimo recomendado para PostgreSQL

### 18.1 `dim_ativo`

Grão: um ativo Zabbix.

Campos mínimos:

- `ativo_sk`;
- `hostid_zabbix`;
- `host`;
- `nome_visivel`;
- `tipo_ativo`;
- `fisico_virtual`;
- `sistema_operacional`;
- `status_monitoramento`;
- `grupos_origem`;
- `unidade`;
- `predio`;
- `sala`;
- `setor`;
- `departamento`;
- `classificacao_evidencia`;
- `ativo_desde` / `ativo_ate`, se necessário.

### 18.2 `fato_indisponibilidade`

Grão recomendado para a camada técnica:

**uma janela contínua observada por ativo e sinal de disponibilidade.**

Campos mínimos:

- `indisponibilidade_id`;
- `ativo_sk`;
- `problem_eventid`;
- `recovery_eventid`;
- `triggerid_zabbix`;
- `fonte_sinal`;
- `inicio_ts`;
- `fim_ts`;
- `duracao_segundos`;
- `aberta`;
- `severidade_historica`;
- `classificacao_semantica = 'INDISPONIBILIDADE_OBSERVADA'`;
- `regra_mvp`;
- `confianca` / `status_validacao`, se adotado;
- `extraido_em`;
- `atualizado_em`.

### 18.3 Camada consolidada

Criar view ou materialização diária somente depois da união temporal das janelas aplicáveis:

`vw_disponibilidade_diaria`

Campos:

- ativo;
- data;
- segundos_observados;
- segundos_indisponiveis;
- segundos_disponiveis;
- disponibilidade_percentual;
- ocorrencias_iniciadas_no_dia;
- indicador_cobertura_dado.

### 18.4 Controle de carga

`controle_execucao_carga`

- execução;
- início/fim;
- status;
- etapa/endpoint;
- watermark inicial/final;
- lidos/inseridos/atualizados/rejeitados;
- mensagem de erro sanitizada;
- versão do coletor.

---

## 19. Regra de disponibilidade inicial

Fórmula matemática:

```text
Disponibilidade % =
(Tempo observado - Tempo indisponível consolidado)
/ Tempo observado
* 100
```

Para a implementação:

- recortar intervalos na janela de análise;
- para evento aberto, usar o fim da janela de análise/última atualização válida;
- dividir eventos que atravessam meia-noite para agregação diária;
- consolidar sobreposição antes da soma;
- nunca contar ausência de coleta como indisponibilidade automaticamente;
- considerar ativação/desativação do ativo quando a informação estiver disponível;
- usar timezone oficial assim que validado; até lá, registrar explicitamente o timezone técnico de origem e normalizar internamente.

---

## 20. Estratégia incremental recomendada

### 20.1 Fonte produtiva

Preferir API do Zabbix.

### 20.2 Watermark

Manter marcador incremental por entidade/endpoint. Para eventos, combinar:

- `eventid` como chave idempotente;
- `clock` como fronteira temporal;
- pequena janela de sobreposição/releitura para absorver recuperação tardia e atualizações.

### 20.3 Idempotência

- `upsert` pelo identificador técnico estável;
- evento de problema pode entrar aberto e ser atualizado quando a recuperação aparecer;
- reprocessar uma janela recente sem duplicar fatos;
- permitir reprocessamento explícito por período.

### 20.4 Reconciliação recorrente

Mesmo com watermark crescente, reconsultar uma janela recente para:

- fechar intervalos anteriormente abertos;
- absorver alterações tardias;
- detectar falhas transitórias de coleta.

A retenção final da camada analítica deve ser independente da retenção operacional do Zabbix.

---

## 21. Primeira página Power BI viável

### KPIs

- Disponibilidade Observada Geral %;
- Ativos Monitorados no escopo;
- Ativos com indisponibilidade no período;
- Tempo Total Indisponível;
- Ocorrências de Indisponibilidade.

### Visuais

- disponibilidade observada por dia;
- ranking dos ativos com pior disponibilidade;
- disponibilidade por tipo de ativo;
- quantidade e duração de janelas ao longo do tempo;
- tabela de detalhe com ativo, início, recuperação, duração, sinal e classificação.

### Regra de comunicação

Enquanto a semântica não estiver reconciliada, o título/subtítulo da página deve deixar claro que o indicador representa **disponibilidade observada pelos sinais selecionados do Zabbix**, e não causa raiz validada.

---

## 22. Débitos semânticos explicitamente adiados

A Rodada 6 está pausada. Permanecem para validação posterior:

- manutenção programada;
- confirmação de reboot de servidor;
- reboot/reset de ativo SNMP;
- interpretação definitiva de reset de uptime;
- diferenciação entre indisponibilidade real do ativo e falha específica de agente/protocolo;
- causa de indisponibilidade;
- efeito funcional de dependências de trigger;
- códigos de reconhecimento;
- timezone oficial;
- política de retenção de `problem`;
- regra oficial de composição dos sinais por classe;
- janela mínima de confirmação definitiva.

Esses débitos não bloqueiam a ingestão e a visualização da `INDISPONIBILIDADE_OBSERVADA`, desde que a incerteza seja preservada no modelo.

---

## 23. Pontos de segurança

- Zabbix produtivo: somente leitura;
- nenhuma credencial hardcoded;
- nenhum token/segredo versionado;
- logs sem segredos;
- consultas históricas diretas apenas seletivas;
- não versionar `output/`, CSVs brutos, ZIPs de remessa ou `.env`;
- a conta dedicada exclusivamente read-only do banco permanecia pendente ao fim da Fase 0;
- para o produto, preferir API com credencial dedicada de leitura.

---

## 24. Mapa dos SQLs migrados

| Rodada | Arquivo | Finalidade |
|---|---|---|
| 1 | `sql/ZABBIX_BI_Fase0_Descoberta_MySQL.sql` | metadados, catálogo, índices, constraints e volumetria |
| 2 | `sql/ZABBIX_BI_Fase0_Rodada2_Inventario_MySQL.sql` | hosts, grupos, classificação, interfaces, localização e views |
| 3 | `sql/ZABBIX_BI_Fase0_Rodada3_Semantica_Monitoramento_MySQL.sql` | itens, triggers, sinais de disponibilidade e cobertura |
| 4 | `sql/ZABBIX_BI_Fase0_Rodada4_Eventos_Recuperacao_MySQL.sql` | eventos, recuperação e reconstrução de intervalos |
| 5 | `sql/ZABBIX_BI_Fase0_Rodada5_Manutencao_Reinicios_MySQL.sql` | manutenção/supressão e uptime seletivo |

---

## 25. Decisão de continuidade

A Fase 0 cumpriu sua função: já existe evidência suficiente para começar a transformar o Zabbix em informação analítica.

A próxima frente deve ser:

```text
1. contrato de extração via API
2. modelo PostgreSQL mínimo
3. coletor Python incremental
4. reconstrução das janelas observadas
5. união temporal / disponibilidade diária
6. validação de amostra
7. primeira página Power BI
```

A investigação de causa e reboot deve continuar desacoplada do primeiro pipeline de disponibilidade observada.
