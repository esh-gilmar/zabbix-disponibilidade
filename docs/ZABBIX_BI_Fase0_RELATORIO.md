# BI-003 — Relatório de Descoberta Técnica do Zabbix

**Projeto:** MVP de Disponibilidade da Infraestrutura de TI  
**Fase:** 0 — Descoberta Técnica  
**Rodadas concluídas:** 1 — Metadados leves; 2 — Inventário e classificação; 3 — Itens, triggers e semântica; 4 — Eventos, recuperação e intervalos; 5 — Manutenção, supressão e resets candidatos de uptime  
**Data da execução:** 14/08/2026  
**Remessas oficiais analisadas:** `20260814_063942`, `20260814_182252`, `20260814_183050`, `20260814_191925`, `20260814_193044`, `20260814_202056`, `20260814_202937`, `20260814_205026` e `20260814_205609`  
**Ferramenta:** Generic SQL Extractor 2.0.0  
**Banco investigado:** MySQL / database `zabbix`

---

## 1. Objetivo da Rodada 1

Executar uma primeira descoberta técnica exclusivamente por metadados, com baixo custo para o banco, para confirmar versão, contexto, catálogo, índices, constraints, volumetria, particionamento e estruturas candidatas do Zabbix antes de qualquer investigação funcional mais profunda.

A Rodada 1 não consultou histórico detalhado, eventos, problemas, trends ou history.

---

## 2. Resultado da execução

A Rodada 1 foi executada com sucesso utilizando o pacote:

```text
sql/ZABBIX_BI_Fase0_Descoberta_MySQL.sql
```

Resultado observado:

- 12 consultas processadas;
- 10 consultas com status `SUCCESS`;
- 2 consultas com status `EMPTY`;
- 0 consultas com status `ERROR`;
- 0 consultas ignoradas;
- 31 testes locais aprovados antes da extração;
- conexão MySQL validada;
- transação `READ ONLY` aplicada pelo preflight;
- database `zabbix` confirmado;
- schema configurado e visível: `zabbix`;
- snapshot do SQL, manifestos, log, CSVs e ZIP gerados localmente.

As consultas vazias foram:

- `10_tabelas_sem_chave_primaria.csv`;
- `11_particionamento_tabelas.csv`.

A ausência de registros nessas consultas constitui evidência observada desta remessa e não deve ser extrapolada além dos metadados retornados.

---

## 3. Classificação de evidências

Este relatório utiliza as seguintes classificações:

- **Declarada:** informação confirmada por documentação, configuração ou responsável técnico;
- **Observada:** comprovada diretamente pela remessa extraída;
- **Inferida:** conclusão lógica apoiada por evidências observadas;
- **Hipótese:** interpretação ainda pendente de validação.

Relacionamentos funcionais não são considerados confirmados apenas por semelhança de nomes.

---

## 4. Ambiente observado

### 4.1 MySQL

**Evidência observada**

- versão: `8.0.46-0ubuntu0.22.04.3`;
- database selecionado: `zabbix`;
- charset do database: `utf8mb4`;
- collation do database: `utf8mb4_bin`;
- timezone global: `SYSTEM`;
- timezone da sessão: `SYSTEM`;
- timezone do sistema no momento da coleta: `-04`.

O timezone técnico observado foi UTC-4. O timezone funcional/oficial utilizado pelo Zabbix ainda deverá ser reconciliado com a aplicação ou com o responsável técnico.

### 4.2 Versão do schema Zabbix

**Evidência observada**

A tabela `dbversion` retornou:

- `mandatory = 7020000`;
- `optional = 7020004`.

Esses valores comprovam a versão do schema registrada no banco.

A versão exata do produto Zabbix Server não deverá ser declarada exclusivamente a partir desse dado; deverá ser reconciliada posteriormente com a aplicação, API ou informação administrativa.

---

## 5. Catálogo técnico do banco

**Evidência observada**

Foram catalogados:

- 203 tabelas base;
- 28 views;
- 1.777 colunas;
- 607 entradas de índices;
- 602 registros de constraints;
- todas as tabelas base observadas utilizando InnoDB;
- nenhuma tabela base sem chave primária detectada;
- nenhum particionamento de tabelas detectado;
- 272 foreign keys declaradas.

### Consequência técnica

**Inferência**

O banco possui estrutura relacional declarada suficiente para avançar para descoberta funcional sem depender exclusivamente de semelhança de nomes.

Entretanto, uma foreign key comprova relacionamento estrutural, não necessariamente a semântica funcional desejada pelo BI.

---

## 6. Volumetria

**Evidência observada**

O tamanho estimado das tabelas base é de aproximadamente:

```text
17.466,75 MB
```

com aproximadamente:

```text
287.469.431 linhas estimadas
```

As quatro estruturas predominantes foram:

| Tabela | Linhas estimadas | Tamanho estimado |
|---|---:|---:|
| `history_uint` | 149.959.014 | 8.708,38 MB |
| `history` | 95.188.624 | 5.467,25 MB |
| `trends_uint` | 26.683.961 | 1.902,77 MB |
| `trends` | 14.224.070 | 984,81 MB |

Essas quatro tabelas representam aproximadamente:

- 97,7% do tamanho estimado das tabelas;
- 99,5% das linhas estimadas do database.

### 6.1 Risco de consulta histórica

**Inferência suportada por evidências**

As tabelas históricas não deverão ser consultadas globalmente por período nas próximas rodadas.

Se futuramente houver necessidade de consultar `history*` ou `trends*`, a estratégia deverá primeiro identificar os `itemid` de interesse e somente depois utilizar filtros seletivos de item e tempo.

Essa estratégia é coerente com os índices observados, que utilizam `itemid` como componente principal das chaves de acesso dessas estruturas.

---

## 7. Inventário e classificação

**Evidência observada**

Estimativas encontradas em estruturas relevantes:

- `hosts`: 531;
- `hstgrp`: 47;
- `hosts_groups`: 601;
- `host_tag`: 1.070;
- `hosts_templates`: 146;
- `interface`: 156;
- `interface_snmp`: 43;
- `host_inventory`: 2.

O número de registros em `hosts` não deverá ser interpretado automaticamente como quantidade de ativos monitorados, pois a semântica dos registros ainda será analisada na Rodada 2.

### 7.1 Inventário padrão

**Inferência**

A baixa quantidade estimada em `host_inventory` indica que o inventário padrão do Zabbix provavelmente não será suficiente, isoladamente, para fornecer classificação e localização de todos os ativos do MVP.

Essa conclusão deverá ser validada na Rodada 2.

---

## 8. Views customizadas

**Evidência observada**

Foram encontradas views com classificação funcional explícita, incluindo:

- `View_Access_Points`;
- `View_Switches`;
- `View_Servidores`;
- `View_Servidores_Fisicos`;
- `View_Servidores_Virtuais`;
- `View_Servidores_Windows`;
- `View_Servidores_Linux`;
- respectivas views de contagem.

Algumas dessas views expõem atributos relacionados a:

- nome;
- IP;
- marca;
- modelo;
- localização;
- PING;
- latência;
- uptime;
- SNMP;
- Zabbix Agent;
- CPU;
- RAM;
- discos;
- status.

### 8.1 Hipótese para a Rodada 2

Essas views provavelmente contêm ou utilizam regras customizadas já existentes para classificar ativos e apresentar estado de monitoramento.

Essa hipótese deverá ser validada pela definição estrutural das views e pelos relacionamentos utilizados.

Não se deve assumir que:

- as views constituem a fonte oficial do futuro BI;
- o campo `STATUS` equivale à disponibilidade aprovada;
- `PING`, `SNMP` ou `Zabbix` já implementam a regra conceitual definitiva do MVP.

---

## 9. Eventos e recuperação

**Evidência observada**

Foram identificadas foreign keys declaradas relevantes, incluindo relações estruturais como:

```text
event_recovery.eventid   → events.eventid
event_recovery.r_eventid → events.eventid
problem.eventid          → events.eventid
problem.r_eventid        → events.eventid
functions.itemid         → items.itemid
functions.triggerid      → triggers.triggerid
items.hostid             → hosts.hostid
```

### 9.1 Consequência

**Inferência**

Existe um caminho estrutural promissor para investigar futuramente:

```text
problema → recuperação → evento → trigger/item → host
```

Entretanto, a ligação funcional completa ainda não está comprovada.

Campos como `events.objectid` deverão ser reconciliados com `source`, `object` e a semântica do Zabbix antes que o relacionamento seja considerado definitivo.

Nenhuma reconstrução de eventos será feita na Rodada 2.

---

## 10. Manutenção

**Evidência observada**

As estimativas de linhas retornaram zero para estruturas como:

- `maintenances`;
- `maintenances_hosts`;
- `maintenances_groups`;
- `maintenances_windows`;
- `maintenance_tag`;
- `event_suppress`.

Isso não comprova ausência funcional de manutenção programada.

Como `TABLE_ROWS` em InnoDB é estimativo, a existência ou não de manutenções deverá ser validada posteriormente por consultas pequenas, exatas e indexadas.

---

## 11. Segurança da execução

A remessa confirmou operacionalmente:

- SQL validator ativo;
- bloqueio de colunas sensíveis ativo;
- transação MySQL `READ ONLY` aplicada;
- nenhum `ERROR`;
- nenhum warning registrado na remessa oficial;
- nenhuma consulta marcada como pesada;
- nenhuma operação DML ou DDL executada pelo pacote.

### 11.1 Exceção operacional temporária

**Declarada pelo responsável técnico**

Nesta etapa, a conexão está utilizando temporariamente a própria conta operacional utilizada pelo Zabbix.

A continuidade da Fase 0 com essa credencial foi autorizada pelo responsável pelo projeto até a criação de um usuário exclusivamente de consulta.

Essa autorização não encerra o requisito de segurança.

Permanece pendente:

> criar e substituir a credencial atual por um usuário dedicado exclusivamente a leitura no database `zabbix`.

Enquanto a exceção estiver ativa, permanecem obrigatórias:

- execução exclusivamente pelo Generic SQL Extractor;
- transação `READ ONLY`;
- validação textual de SQL;
- somente instruções `SELECT` ou `WITH`;
- consultas controladas e previamente revisadas;
- nenhuma execução de escrita no banco;
- nenhuma alteração de configuração do Zabbix ou MySQL.

---

## 12. Integridade da remessa

A remessa oficial analisada foi:

```text
20260814_063942
```

Foram validados:

- `manifesto.csv`;
- `manifesto.json`;
- `execucao.json`;
- snapshot do SQL executado;
- CSVs gerados;
- log da execução;
- pacote ZIP local.

Os 10 CSVs gerados possuem hashes compatíveis com os hashes registrados no manifesto.

O ZIP e os arquivos de resultado permanecem locais e não devem ser versionados no GitHub.

---

## 13. Conclusões da Rodada 1

A Rodada 1 cumpriu o objetivo de reduzir as incertezas estruturais iniciais.

Já estão estabelecidos por evidência:

- versão do MySQL;
- versão registrada do schema Zabbix;
- charset e collation;
- timezone técnico observado;
- estrutura geral do database;
- tabelas, views e colunas;
- índices;
- constraints;
- volumetria estimada;
- principais riscos de performance;
- ausência observada de particionamento;
- existência de views customizadas para classificação de infraestrutura;
- caminhos relacionais candidatos para eventos e recuperação.

Ainda permanecem pendentes, entre outros:

- versão exata do Zabbix Server;
- timezone oficial do ambiente;
- substituição da conta operacional por usuário exclusivamente read-only;
- semântica efetiva de hosts, grupos, tags e templates;
- origem da classificação dos ativos;
- origem e completude da localização;
- interpretação das views customizadas;
- identificação dos itens de ICMP, agente, SNMP e uptime;
- semântica das triggers;
- reconstrução de eventos e recuperações;
- manutenção programada;
- detecção de reinícios;
- reconciliação com casos reais;
- mapeamento banco → API.

---

## 14. Próxima rodada

A Rodada 2 deverá ser restrita a:

**Inventário, classificação dos ativos, grupos, tags, templates, interfaces, localização e entendimento estrutural das views customizadas.**

Não há justificativa técnica para consultar `history`, `history_uint`, `trends` ou `trends_uint` na Rodada 2.

Arquivo SQL previsto:

```text
sql/ZABBIX_BI_Fase0_Rodada2_Inventario_MySQL.sql
```

A proposta de consultas da Rodada 2 foi revisada e aprovada em 14/08/2026. A implementação deverá seguir a SPEC operacional específica da rodada, preservando o gate estrutural antes da execução de views customizadas.

---

## 15. Autorização e controle da Rodada 2

**Evidência declarada — 14/08/2026**

O responsável pelo projeto aprovou o levantamento integral das informações propostas para a Rodada 2.

Documentos operacionais versionados para conduzir a implementação:

```text
docs/SPEC-BI-003-Fase-0-Rodada-2-Inventario-Classificacao.md
CODEX_PROMPT_BI003_ZABBIX_FASE0_RODADA2.md
```

A Rodada 2 será executada em dois gates internos:

```text
Rodada 2A — estrutura e inventário padrão
→ análise das evidências
→ Rodada 2B — classificação, qualidade e reconciliação
```

A autorização permite implementar e executar as consultas controladas da SPEC sem nova aprovação para passos rotineiros, desde que todos os gates de segurança sejam atendidos.

Continuam exigindo parada e revisão:

- qualquer `ERROR`;
- necessidade de `--include-heavy`;
- consulta histórica ampla;
- custo incerto;
- necessidade de DML/DDL;
- necessidade de função/procedure;
- necessidade de alterar o núcleo Python;
- retorno inesperadamente volumoso;
- divergência material entre SPEC e dados observados.

Permanece explicitamente proibida nesta rodada a consulta de conteúdo de:

```text
history
history_uint
history_str
history_text
history_log
trends
trends_uint
```

A conta dedicada exclusivamente read-only continua pendente e não deve ser marcada como concluída sem comprovação externa.

---

## 16. Resultado da Rodada 2

### 16.1 Remessas oficiais

As remessas utilizadas como evidência da Rodada 2 são:

| Gate | Remessa | Pasta local | ZIP local | Resultado |
|---|---|---|---|---|
| Rodada 2A | `20260814_182252` | `output/20260814_182252/` | `output/20260814_182252.zip` | 14 `SUCCESS`, 0 `ERROR`, 6 `SKIPPED_DISABLED` |
| Rodada 2B | `20260814_183050` | `output/20260814_183050/` | `output/20260814_183050.zip` | 18 `SUCCESS`, 0 `ERROR`, 2 `SKIPPED_DISABLED` |

A remessa intermediária `20260814_182757` apresentou erro de sintaxe nas Consultas 16 e 18, foi corrigida e **não é evidência oficial**.

Nas duas remessas oficiais foram confirmados:

- conexão com MySQL `8.0.46-0ubuntu0.22.04.3` e database `zabbix`;
- transação `READ ONLY` aplicada;
- parser e bloqueio de colunas sensíveis ativos;
- 31 testes locais aprovados em cada gate;
- nenhuma consulta marcada como pesada;
- nenhuma execução com `--include-heavy`;
- nenhuma DML ou DDL;
- nenhum acesso ao conteúdo de tabelas históricas;
- snapshots SQL idênticos aos pacotes executados;
- hashes dos 14 CSVs da Rodada 2A e dos 18 CSVs da Rodada 2B compatíveis com os manifestos;
- ZIPs locais contendo somente CSVs, manifestos, `execucao.json`, snapshot SQL e log.

### 16.2 Status e linhas por consulta

| ID | Consulta | Rodada 2A | Linhas 2A | Rodada 2B | Linhas 2B |
|---:|---|---|---:|---|---:|
| 01 | Estrutura dos objetos de inventário | `SUCCESS` | 175 | `SUCCESS` | 175 |
| 02 | Índices e constraints | `SUCCESS` | 66 | `SUCCESS` | 66 |
| 03 | Estrutura das views | `SUCCESS` | 99 | `SUCCESS` | 99 |
| 04 | Definições das views | `SUCCESS` | 7 | `SUCCESS` | 7 |
| 05 | Distribuição bruta de `hosts` | `SUCCESS` | 5 | `SUCCESS` | 5 |
| 06 | Hosts habilitados/desabilitados | `SUCCESS` preliminar | 12 | `SUCCESS` final | 2 |
| 07 | Catálogo de grupos | `SUCCESS` | 57 | `SUCCESS` | 57 |
| 08 | Distribuição host-grupo | `SUCCESS` preliminar | 55 | `SUCCESS` final | 44 |
| 09 | Catálogo de tags | `SUCCESS` | 384 | `SUCCESS` | 384 |
| 10 | Templates vinculados | `SUCCESS` | 53 | `SUCCESS` | 53 |
| 11 | Cobertura de interfaces | `SUCCESS` | 10 | `SUCCESS` | 10 |
| 12 | Resumo SNMP | `SUCCESS` | 1 | `SUCCESS` | 1 |
| 13 | Cobertura por proxy | `SUCCESS` | 5 | `SUCCESS` | 5 |
| 14 | Origens candidatas de localização | `SUCCESS` | 539 | `SUCCESS` | 539 |
| 15 | Matriz de classificação | `SKIPPED_DISABLED` | 0 | `SUCCESS` | 135 |
| 16 | Qualidade da classificação | `SKIPPED_DISABLED` | 0 | `SUCCESS` | 1 |
| 17 | Qualidade da localização | `SKIPPED_DISABLED` | 0 | `SUCCESS` | 1 |
| 18 | Amostra de lacunas/conflitos | `SKIPPED_DISABLED` | 0 | `SUCCESS` | 50 |
| 19 | Reconciliação das views | `SKIPPED_DISABLED` | 0 | `SKIPPED_DISABLED` | 0 |
| 20 | Amostra de divergências das views | `SKIPPED_DISABLED` | 0 | `SKIPPED_DISABLED` | 0 |

As Consultas 19 e 20 permaneceram desabilitadas porque a Consulta 04 comprovou dependência histórica em todas as sete views relevantes.

---

## 17. Inventário observado na Rodada 2

### 17.1 Semântica estrutural de `hosts`

**Evidência observada e inferida**

A distribuição atual de 533 registros foi:

- 135 hosts regulares, identificados estruturalmente por `flags = 0` e `status IN (0, 1)`;
- 352 templates, com `status = 3`, `flags = 0` e associação a grupos de template;
- 46 outros registros, com `flags = 2`, sem associação aos grupos de hosts regulares.

Entre os 135 hosts regulares:

- 123 estão habilitados (`status = 0`);
- 12 estão desabilitados (`status = 1`).

A distinção é uma inferência sustentada pela distribuição bruta, interfaces, grupos, vínculos de template e uso das mesmas estruturas pelas views. Não constitui, isoladamente, aprovação funcional do inventário oficial do futuro BI.

### 17.2 Grupos

**Evidência observada**

- 57 grupos catalogados;
- 45 grupos com `type = 0`;
- 12 grupos com `type = 1`;
- 47 grupos não vazios;
- 624 vínculos host-grupo totais;
- 267 vínculos envolvendo hosts regulares;
- 36 grupos com pelo menos um host regular.

Os grupos usados como sinais candidatos de classificação foram comprovados simultaneamente pelo catálogo e pelos filtros estruturais das views:

| Classificação candidata | Grupo | `groupid` | Hosts regulares |
|---|---|---:|---:|
| Access Point | `Access_Points` | 41 | 19 |
| Switch | `Switches` | 27 | 16 |
| Servidor | `Servidores` | 22 | 45 |
| Físico | `Servidores-Fisicos` | 23 | 6 |
| Virtual | `Servidores-Virtuais` | 24 | 38 |
| Windows | `Servidores-Windows` | 25 | 32 |
| Linux | `Servidores-Linux` | 26 | 12 |

### 17.3 Tags

**Evidência observada**

- 1.078 tags registradas;
- 42 chaves distintas;
- 384 combinações agregadas de chave, valor, status e flags;
- 959 tags pertencem a templates;
- 119 tags pertencem a registros com `flags = 2`;
- nenhum dos 135 hosts regulares possui tag cadastrada.

Consequentemente, tags não sustentam a classificação nem a localização dos hosts regulares nesta remessa. Chaves como `class`, `target`, `location` e `os` observadas nos CSVs pertencem a templates ou a outros registros e não foram promovidas a regra de host.

### 17.4 Templates

**Evidência observada**

- 49 templates distintos vinculados;
- 173 vínculos de template;
- 124 vínculos com hosts regulares habilitados;
- 9 vínculos com hosts regulares desabilitados;
- 40 vínculos com registros de `flags = 2`.

Reconciliação dos templates exatos usados como sinais candidatos:

| Classificação | Grupo e template | Somente grupo | Somente template |
|---|---:|---:|---:|
| Access Point | 18 | 1 | 0 |
| Switch | 1 | 15 | 0 |
| Windows | 29 | 3 | 0 |
| Linux | 12 | 0 | 0 |

Os templates corroboram parcialmente grupos, mas não substituem os grupos como fonte completa de classificação.

### 17.5 Interfaces, agente e SNMP

**Evidência observada e inferida**

- 157 interfaces totais;
- 109 interfaces de tipo bruto `1`;
- 48 interfaces de tipo bruto `2`;
- 84 hosts regulares possuem interface de agente;
- 48 hosts regulares possuem interface SNMP;
- 3 hosts regulares possuem ambas;
- 6 hosts regulares não possuem interface;
- as 48 interfaces SNMP observadas utilizam versão bruta `2`, sem exposição de comunidade, senha ou material de autenticação.

A interpretação tipo `1` = agente e tipo `2` = SNMP é inferida pela estrutura `interface_snmp`, pelos templates vinculados e pelo vocabulário observado.

### 17.6 Proxies

**Evidência observada**

Todos os 533 registros apresentaram:

- `monitored_by = 0`;
- `proxyid` nulo;
- `proxy_groupid` nulo.

Nenhum proxy participa do monitoramento observado nesta remessa.

---

## 18. Qualidade de classificação

**Evidência observada**

Sobre os 135 hosts regulares:

- 19 Access Points;
- 16 switches;
- 45 servidores;
- 6 servidores físicos;
- 38 servidores virtuais;
- 32 servidores Windows;
- 12 servidores Linux;
- 55 sem classificação principal entre AP, switch e servidor;
- 0 classificações principais ambíguas;
- 0 conflitos AP + servidor;
- 0 conflitos switch + servidor;
- 0 conflitos físico + virtual;
- 0 conflitos Windows + Linux;
- 1 servidor sem classificação físico/virtual;
- 1 servidor sem classificação Windows/Linux;
- 0 classificações físico/virtual sem vínculo ao grupo de servidores;
- 0 classificações Windows/Linux sem vínculo ao grupo de servidores.

Essas classificações são candidatas e preservam sua origem em grupos e templates na Consulta 15. Elas não foram convertidas em regra oficial do BI.

---

## 19. Localização e completude

### 19.1 Fontes comprovadas

**Evidência observada e inferida**

- Unidade aparece como vocabulário de grupos, nos grupos 39 e 40;
- Prédio aparece como vocabulário de grupos, nos grupos 42 a 52 utilizados pela consulta final;
- `host_inventory` possui somente um valor não vazio de sistema operacional e nenhuma localização utilizável;
- nenhuma tag de host regular fornece localização;
- as views de APs e switches expõem `LOCAL`, mas derivam o valor de itens e histórico proibido nesta rodada.

Não foi encontrada fonte cadastral comprovada para:

- Sala;
- Setor;
- Departamento.

O grupo `Predio-Departamento_Pessoal` é um valor de grupo de Prédio e não comprova um atributo separado de Departamento.

### 19.2 Medição

**Evidência observada**

- 1 host regular com Unidade;
- 134 sem Unidade;
- 21 com Prédio;
- 114 sem Prédio;
- 0 completos nas cinco dimensões solicitadas;
- 22 parcialmente preenchidos nas fontes comprovadas;
- 113 totalmente ausentes nas fontes comprovadas.

Sala, Setor e Departamento são lacunas comprovadas nesta rodada, não valores presumidos como ausentes em uma fonte desconhecida.

---

## 20. Estrutura e segurança das views customizadas

**Evidência observada**

Todas as sete views relevantes:

- unem `hosts`, `hosts_groups`, `items` e `interface`;
- calculam métricas por `CASE` sobre nomes de itens;
- buscam valores mais recentes por CTEs que varrem tabelas históricas;
- usam grupos como regra estrutural de classificação.

Mapeamento estrutural:

| View | Regra de grupo | Observação |
|---|---:|---|
| `View_Access_Points` | 41 | `STATUS` vem de disponibilidade da interface |
| `View_Switches` | 27 | `STATUS` vem de `hosts.status`; `SNMP` usa disponibilidade da interface |
| `View_Servidores` | 22 | inclui habilitados e desabilitados |
| `View_Servidores_Fisicos` | 23 | inclui habilitados e desabilitados |
| `View_Servidores_Virtuais` | 24 | filtra explicitamente somente `hosts.status = 0` |
| `View_Servidores_Windows` | 25 | inclui habilitados e desabilitados |
| `View_Servidores_Linux` | 26 | inclui habilitados e desabilitados |

Como todas dependem de estruturas históricas proibidas, nenhuma view foi executada. As Consultas 19 e 20 permaneceram desabilitadas. A divergência de conteúdo view × fontes padrão não pôde ser medida com segurança; a divergência estrutural de filtros e significado de `STATUS` ficou comprovada.

Campos `STATUS`, `PING`, `SNMP`, `ZABBIX` e `UPTIME` dessas views não são regras aprovadas de disponibilidade do BI.

---

## 21. Matriz de conclusão da Rodada 2

| Pergunta | Resposta | Evidência | Consulta | Limitação |
|---|---|---|---|---|
| Hosts reais monitorados | 135 hosts regulares | Observada/Inferida | 05, 06, 15 | Regra candidata estrutural |
| Habilitados/desabilitados | 123 / 12 | Observada | 06 | — |
| Hosts/templates/outros | 135 / 352 / 46 | Observada/Inferida | 05 e 2A-06 | Semântica funcional ainda candidata |
| Grupos | 57; 47 não vazios | Observada | 07 | Catálogo atual |
| Distribuição por grupo | 267 vínculos regulares em 36 grupos | Observada | 08 | Sobreposição preservada |
| Tags | 42 chaves; nenhuma em host regular | Observada | 09, 15 | Tags de templates não classificam hosts |
| Templates | 49 distintos; 173 vínculos | Observada | 10 | Cobertura parcial por classe |
| Interfaces | 157 totais | Observada | 11 | Tipos interpretados estruturalmente |
| Agente | 84 hosts regulares | Observada/Inferida | 11, 15 | Tipo bruto `1` |
| SNMP | 48 hosts regulares | Observada/Inferida | 12, 15 | Tipo bruto `2` |
| Proxies | Não utilizados | Observada | 13 | Estado desta remessa |
| Access Points | 19 pelo grupo 41; 18 com template correspondente | Observada/Inferida | 15, 16 | Regra candidata |
| Switches | 16 pelo grupo 27; 1 com template correspondente | Observada/Inferida | 15, 16 | Regra candidata |
| Servidores físicos | 6 pelo grupo 23 | Observada/Inferida | 15, 16 | Regra candidata |
| Servidores virtuais | 38 pelo grupo 24 | Observada/Inferida | 15, 16 | Regra candidata |
| Windows/Linux | 32 / 12 | Observada/Inferida | 15, 16 | Grupos e templates exatos |
| Unidade | Grupos 39/40; cobertura 1 | Observada/Inferida | 14, 17 | Muito incompleta |
| Prédio | Grupos 42–52; cobertura 21 | Observada/Inferida | 14, 17 | Muito incompleta |
| Sala | Lacuna comprovada | Observada | 14, 17 | Sem fonte cadastral segura |
| Setor | Lacuna comprovada | Observada | 14, 17 | Sem fonte cadastral segura |
| Departamento | Lacuna comprovada | Observada | 14, 17 | Sem fonte cadastral segura |
| Qualidade de classificação | 55 sem classe principal; 0 conflitos; 2 lacunas de subtipo | Observada | 16, 18 | Amostra limitada a 50 |
| Qualidade de localização | 0 completos; 22 parciais; 113 ausentes | Observada | 17, 18 | Três campos sem fonte |
| Estrutura das views | Classificação por grupos; métricas por itens/histórico | Observada | 04 | Views não executadas |
| Divergências | Grupo × template medido; views com filtros/status inconsistentes | Observada/Inferida | 04, 15, 16 | Conteúdo das views não reconciliado |

---

## 22. Divergências, limitações e riscos

### 22.1 Divergências observadas

- 1 AP está somente no grupo, sem o template candidato;
- 15 switches estão somente no grupo, sem o template candidato;
- 3 hosts Windows estão somente no grupo, sem o template candidato;
- Linux apresentou cobertura coincidente entre grupo e template;
- a view de servidores virtuais exclui desabilitados, enquanto as demais views de classificação não aplicam o mesmo filtro;
- o significado de `STATUS` varia entre as views;
- os totais exatos atuais diferem das estimativas InnoDB da Rodada 1: 533 registros em `hosts`, 57 grupos, 624 vínculos host-grupo, 1.078 tags, 173 vínculos de template, 157 interfaces e 48 interfaces SNMP.

As diferenças frente à Rodada 1 são tratadas como refinamento por contagem exata e possível evolução do cadastro, não como regra funcional.

### 22.2 Limitações abertas

- classificação por grupo/template ainda requer aprovação funcional;
- 55 hosts regulares não pertencem às três classes principais investigadas;
- Unidade e Prédio possuem baixa cobertura;
- Sala, Setor e Departamento não possuem fonte cadastral comprovada;
- o conteúdo das views não pôde ser reconciliado sem violar a proibição de histórico;
- versão exata do produto Zabbix e timezone funcional permanecem pendentes;
- a conta operacional temporária continua em uso.

Permanece pendente, sem alteração:

> criar e substituir a credencial atual por um usuário dedicado exclusivamente read-only no database `zabbix`.

---

## 23. Conclusão da Rodada 2 e transição executada

A Rodada 2 foi concluída com evidências reproduzíveis para inventário, classificação, interfaces, proxy, localização e estrutura das views, incluindo lacunas formalmente comprovadas.

Nenhum conteúdo histórico foi consultado. A única interação com referências históricas ocorreu ao ler texto de `VIEW_DEFINITION` no `information_schema`, sem executar as views.

Essa conclusão estabeleceu a entrada da Rodada 3, executada e documentada nas seções seguintes com filtros seletivos e o mesmo gate de segurança.

---

## 24. Resultado da Rodada 3

### 24.1 Escopo e pacote oficial

A Rodada 3 investigou exclusivamente configuração e semântica de itens e triggers por meio do pacote:

```text
sql/ZABBIX_BI_Fase0_Rodada3_Semantica_Monitoramento_MySQL.sql
```

Não foram consultados valores de item, histórico, trends, eventos, problemas, recuperação de eventos ou manutenção. O núcleo Python do Generic SQL Extractor foi preservado.

### 24.2 Remessas oficiais

| Gate | Remessa | Pasta local | ZIP local | Resultado |
|---|---|---|---|---|
| Rodada 3A | `20260814_191925` | `output/20260814_191925/` | `output/20260814_191925.zip` | 11 `SUCCESS`, 0 `ERROR`, 11 `SKIPPED_DISABLED` |
| Rodada 3B | `20260814_193044` | `output/20260814_193044/` | `output/20260814_193044.zip` | 22 `SUCCESS`, 0 `ERROR`, 0 ignoradas |

Nas duas remessas foram confirmados:

- 31 testes locais aprovados;
- conexão ao database `zabbix`;
- transação `READ ONLY` aplicada;
- parser e bloqueio de colunas sensíveis ativos;
- nenhuma consulta marcada como pesada;
- nenhuma execução com `--include-heavy`;
- nenhuma DML ou DDL;
- nenhum acesso a conteúdo histórico ou funcional de eventos;
- nenhum valor de macro selecionado;
- snapshots SQL idênticos aos pacotes executados;
- hashes dos CSVs compatíveis com os manifestos;
- 0 warnings de banco na remessa final.

### 24.3 Status e linhas por consulta

| ID | Consulta | Rodada 3A | Linhas 3A | Rodada 3B | Linhas 3B |
|---:|---|---|---:|---|---:|
| 01 | Estrutura dos objetos de monitoramento | `SUCCESS` | 145 | `SUCCESS` | 145 |
| 02 | Índices e constraints | `SUCCESS` | 96 | `SUCCESS` | 96 |
| 03 | Volumetria de configuração | `SUCCESS` | 7 | `SUCCESS` | 7 |
| 04 | Distribuição bruta de itens | `SUCCESS` | 60 | `SUCCESS` | 60 |
| 05 | Catálogo de chaves e nomes | `SUCCESS` | 5.000 | `SUCCESS` | 5.000 |
| 06 | Origem dos itens por template | `SUCCESS` | 635 | `SUCCESS` | 635 |
| 07 | Distribuição bruta de triggers | `SUCCESS` | 39 | `SUCCESS` | 39 |
| 08 | Catálogo de descrições de trigger | `SUCCESS` | 1.561 | `SUCCESS` | 1.561 |
| 09 | Relação função, item e trigger | `SUCCESS` | 5.200 | `SUCCESS` | 5.200 |
| 10 | Dependências de trigger | `SUCCESS` | 1.715 | `SUCCESS` | 1.715 |
| 11 | Nomes e cobertura de macros | `SUCCESS` | 124 | `SUCCESS` | 124 |
| 12 | Tags de trigger | `SKIPPED_DISABLED` | 0 | `SUCCESS` | 23 |
| 13 | Matriz de itens candidatos | `SKIPPED_DISABLED` | 0 | `SUCCESS` | 304 |
| 14 | Matriz trigger → item candidato | `SKIPPED_DISABLED` | 0 | `SUCCESS` | 164 |
| 15 | Cobertura ICMP por classe | `SKIPPED_DISABLED` | 0 | `SUCCESS` | 7 |
| 16 | Cobertura de agente em servidores | `SKIPPED_DISABLED` | 0 | `SUCCESS` | 3 |
| 17 | Cobertura SNMP em rede | `SKIPPED_DISABLED` | 0 | `SUCCESS` | 2 |
| 18 | Cobertura de uptime | `SKIPPED_DISABLED` | 0 | `SUCCESS` | 11 |
| 19 | Saúde e inventário | `SKIPPED_DISABLED` | 0 | `SUCCESS` | 66 |
| 20 | Semântica das triggers candidatas | `SKIPPED_DISABLED` | 0 | `SUCCESS` | 164 |
| 21 | Qualidade semântica | `SKIPPED_DISABLED` | 0 | `SUCCESS` | 6 |
| 22 | Amostra de lacunas | `SKIPPED_DISABLED` | 0 | `SUCCESS` | 50 |

A Consulta 05 atingiu o limite determinístico de 5.000 linhas. As chaves recorrentes necessárias à Rodada 3B estavam presentes; itens menos frequentes podem permanecer fora desse catálogo textual e constituem limitação documentada.

---

## 25. Estrutura e vocabulário observados

### 25.1 Estrutura relacional

**Evidência observada**

Foram confirmadas as FKs:

```text
items.hostid                    → hosts.hostid
items.templateid                → items.itemid
functions.itemid                → items.itemid
functions.triggerid             → triggers.triggerid
trigger_depends.triggerid_down  → triggers.triggerid
trigger_depends.triggerid_up    → triggers.triggerid
trigger_tag.triggerid           → triggers.triggerid
hostmacro.hostid                → hosts.hostid
triggers.templateid             → triggers.triggerid
```

O caminho estrutural `host → item → função → trigger` está comprovado por constraints e por 5.200 triggers relacionadas aos itens dos hosts regulares.

### 25.2 Volumetria estimada de configuração

**Evidência observada**

| Objeto | Linhas estimadas | Tamanho estimado |
|---|---:|---:|
| `items` | 30.585 | 35,41 MB |
| `functions` | 15.425 | 3,55 MB |
| `triggers` | 11.383 | 9,02 MB |
| `trigger_depends` | 3.051 | 0,41 MB |
| `trigger_tag` | 12.571 | 1,91 MB |
| `hostmacro` | 6.424 | 2,03 MB |
| `globalmacro` | 0 estimada | 0,02 MB |

Os volumes e tempos observados permaneceram compatíveis com consultas de configuração seletivas.

---

## 26. Matriz de candidatos de disponibilidade

### 26.1 Itens candidatos observados

| Papel candidato | Chave observada | Itens/hosts | Estado bruto | Origem/template relevante | Classificação |
|---|---|---:|---:|---|---|
| ICMP | `icmpping` | 84 / 84 | 0 | `ICMP Ping`, templates de AP/switch e outros SNMP | Observada/Inferida |
| Agente — check | `agent.ping` | 41 / 41 | 0 | `Windows by Zabbix agent`; `Linux by Zabbix agent` | Observada/Inferida |
| Agente — disponibilidade interna | `zabbix[host,agent,available]` | 41 / 41 | 0 | templates Windows/Linux | Observada/Inferida |
| SNMP — disponibilidade interna | `zabbix[host,snmp,available]` | 37 / 37 | 0 | templates de AP, switch e outros dispositivos SNMP | Observada/Inferida |
| Uptime de agente | `system.uptime` | 41 / 41 | 0 | templates Windows/Linux | Observada/Inferida |
| Uptime de hardware | `system.hw.uptime[hrSystemUptime.0]` | 30 / 30 | 0 | templates SNMP | Observada/Inferida |
| Uptime de rede | `system.net.uptime[sysUpTime.0]` | 30 / 30 | 0 | templates SNMP | Observada/Inferida |

`icmppingloss` e `icmppingsec` também foram observados em 84 e 83 hosts, respectivamente, mas foram mantidos como sinais de qualidade/saúde do ICMP, não como sinal binário principal de disponibilidade.

### 26.2 Cobertura por classe

| Classe | Hosts | ICMP candidato | Agente candidato | SNMP candidato | Uptime candidato |
|---|---:|---:|---:|---:|---:|
| Access Points | 19 | 19 | não aplicável | 18 | 18 |
| Switches | 16 | 14 | não aplicável | 1 | 1 |
| Servidores | 45 | 2 | 41 | não aplicável | 41 |
| Windows | 32 | 1 | 29 | não aplicável | 29 |
| Linux | 12 | 1 | 12 | não aplicável | 12 |

Comparações estruturais relevantes:

- servidores: 42 possuem interface de agente, mas somente 41 possuem itens/triggers candidatos do agente;
- APs: 18 possuem interface SNMP e os mesmos 18 possuem item/trigger candidato SNMP;
- switches: 9 possuem interface SNMP, mas somente 1 possui item/trigger candidato SNMP;
- em todos os 135 hosts, 84 possuem ICMP candidato e 71 possuem pelo menos um uptime candidato.

A presença de interface não foi tratada como equivalente à presença de item ou trigger de disponibilidade.

---

## 27. Triggers candidatas, severidades e funções

### 27.1 Matriz resumida

| Papel candidato | Triggers | Hosts relacionados | Descrições recorrentes |
|---|---:|---:|---|
| ICMP | 86 | 84 | indisponibilidade por ICMP, perda de pacotes e caso customizado de host inacessível/down |
| Agente | 41 | 41 | agente Zabbix indisponível em Windows/Linux |
| SNMP | 37 | 37 | ausência de coleta SNMP |

### 27.2 Severidades declaradas e observadas

O mapeamento dos códigos é **Declarado** pela documentação oficial do Zabbix 7.0: `1=Information`, `2=Warning`, `3=Average`, `4=High`, `5=Disaster`. A distribuição abaixo é **Observada** na remessa 3B:

| Prioridade bruta | Severidade declarada | Triggers candidatas |
|---:|---|---:|
| 2 | Warning | 37 |
| 3 | Average | 53 |
| 4 | High | 73 |
| 5 | Disaster | 1 |

Fonte declarada: [Zabbix 7.0 — Trigger object](https://www.zabbix.com/documentation/7.0/en/manual/api/reference/trigger/object).

### 27.3 Funções, recuperação e dependências

**Evidência observada**

- funções candidatas: `max` em 162 triggers, `avg` em 1 e `last` em 1;
- todas as 164 triggers candidatas estavam habilitadas (`status = 0`);
- todas utilizavam `recovery_mode = 0`;
- todas utilizavam `correlation_mode = 0`;
- 41 permitiam fechamento manual (`manual_close = 1`);
- 116 possuíam pelo menos uma dependência estrutural;
- 162 tinham a tag `scope=availability`; 2 não possuíam tag na consulta candidata;
- nenhuma das 164 expressões candidatas continha macro de usuário.

Pela documentação oficial, `recovery_mode = 0` significa recuperação pela própria expressão, `correlation_mode = 0` fecha todos os problemas associados e `manual_close = 1` permite fechamento manual. Essas interpretações são declaradas; os códigos e quantidades são observados.

---

## 28. Macros e tags

### 28.1 Macros

**Evidência observada**

Foram catalogados 124 registros agregados de nomes de macro nos escopos global, host regular e template vinculado. Entre os nomes relevantes observados estão:

```text
{$ICMP_LOSS_WARN}
{$ICMP_RESPONSE_TIME_WARN}
{$AGENT.TIMEOUT}
{$SNMP.TIMEOUT}
{$SNMP_COMMUNITY}
```

Somente os nomes e a cobertura foram consultados. Nenhum valor de macro, community SNMP, senha, token ou segredo foi selecionado ou documentado.

### 28.2 Tags de trigger

**Evidência observada**

A tag `scope` utiliza os valores técnicos:

```text
availability
capacity
notice
performance
security
```

Para as 164 triggers candidatas de disponibilidade, 162 possuíam `scope=availability` e 2 não possuíam tag associada na consulta controlada.

---

## 29. Disponibilidade × saúde × inventário

| Camada | Evidência observada | Papel candidato | Limitação |
|---|---|---|---|
| Disponibilidade | `icmpping`, `agent.ping`, disponibilidade interna de agente/SNMP e triggers relacionadas | sinais candidatos para regras futuras | não há eventos, duração nem reconciliação funcional nesta rodada |
| Uptime/contexto operacional | três famílias de uptime em 71 hosts | comprovar configuração e futura investigação de reinícios | nenhum valor de uptime foi consultado; reinício não foi detectado |
| Saúde — CPU | 877 itens candidatos em 444 chaves agregadas | utilização, filas e estados de CPU | classificação por vocabulário observado; não define indisponibilidade |
| Saúde — RAM | 883 itens candidatos em 426 chaves agregadas | memória, swap e contadores relacionados | não define indisponibilidade |
| Saúde — storage | 2.333 itens candidatos em 677 chaves agregadas | filesystem, discos e storage | não define indisponibilidade |
| Saúde — rede | 1.521 itens candidatos em 860 chaves agregadas | interfaces, tráfego, erros e estado de link | não equivale ao ICMP/SNMP do ativo |
| Saúde — serviços Windows | 1.807 itens candidatos em 251 chaves agregadas | descoberta e estado de serviços | serviço parado não equivale automaticamente a host indisponível |
| Inventário/contexto | 164 itens nas chaves `system.sw.os`, `system.uname`, `agent.hostname` e `system.hostname` | sistema operacional e identificação técnica | cobertura máxima observada por família: 41 hosts |

As quantidades de saúde podem conter múltiplos itens por host e chaves descobertas específicas. Elas representam configuração observada, não ativos únicos nem ocorrências operacionais.

---

## 30. Qualidade semântica e lacunas

**Evidência observada**

- 51 dos 135 hosts regulares não possuem `icmpping` candidato;
- 64 não possuem item de uptime candidato;
- 43 dos 45 servidores não possuem ICMP candidato;
- 4 dos 45 servidores não possuem os itens candidatos do agente;
- 4 dos 45 servidores não possuem uptime candidato;
- 1 dos 19 APs não possui candidato SNMP nem uptime candidato;
- 2 dos 16 switches não possuem candidato ICMP;
- 15 dos 16 switches não possuem candidato SNMP nem uptime candidato;
- nenhum item candidato estava desabilitado;
- nenhuma trigger candidata estava desabilitada;
- não foram detectados múltiplos itens concorrentes acima dos padrões observados;
- 41 hosts possuem ao menos um candidato sem trigger relacionada; o caso é explicado principalmente pelos itens de uptime, que não foram promovidos a triggers de disponibilidade;
- a amostra de lacunas foi limitada a 50 `hostid`, sem hostname, IP ou DNS.

Essas lacunas são técnicas e candidatas. Não constituem falhas oficialmente aprovadas de monitoramento.

---

## 31. Avaliação estrutural das hipóteses

### 31.1 Servidores: ICMP + agente

**Classificação:** não suportada pelos dados atuais.

Dos 45 servidores, 41 possuem sinais candidatos do agente, mas somente 2 possuem ICMP candidato. Portanto, a cobertura conjunta não pode superar 2 de 45 com a configuração observada.

Essa conclusão avalia apenas suporte estrutural. Não aprova regra de indisponibilidade.

### 31.2 Access Points e switches: ICMP + SNMP

**Classificação:** parcialmente suportada.

- Access Points: 19 de 19 possuem ICMP e 18 de 19 possuem SNMP, sustentando estruturalmente a combinação para 18 ativos;
- switches: 14 de 16 possuem ICMP, mas apenas 1 de 16 possui SNMP candidato, apesar de 9 possuírem interface SNMP.

A hipótese é bem sustentada para a maior parte dos APs e não é sustentada para o conjunto de switches. A aprovação definitiva depende de eventos, recuperação e reconciliação com casos reais.

---

## 32. Matriz de conclusão da Rodada 3

| Pergunta | Resposta | Classificação | Consulta/arquivo | Limitação |
|---|---|---|---|---|
| Estrutura de itens/funções/triggers | FKs e colunas comprovadas | Observada | 01, 02 | Semântica funcional depende dos dados |
| Relação item → função → trigger | 5.200 triggers no escopo | Observada | 09 | Inclui saúde e descoberta |
| Distribuição de itens | 60 combinações brutas | Observada | 04 | Códigos não promovidos a regra |
| Chaves de item | catálogo determinístico de 5.000 linhas | Observada | 05 | catálogo atingiu o limite |
| Origem por template | 635 combinações | Observada | 06 | nomes são configuração atual |
| ICMP | `icmpping` em 84 hosts | Observada/Inferida | 13, 15 | regra candidata |
| Agente | dois sinais em 41 hosts | Observada/Inferida | 13, 16 | interface não equivale a item |
| SNMP | sinal interno em 37 hosts | Observada/Inferida | 13, 17 | baixa cobertura em switches |
| Uptime | três famílias em 71 hosts | Observada/Inferida | 13, 18, 21 | valores não consultados |
| CPU/RAM/storage/rede/serviços/SO | seis famílias catalogadas | Observada/Inferida | 19 | classificação candidata |
| Triggers candidatas | 164 | Observada/Inferida | 14, 20 | não são regra oficial |
| Severidades | prioridades 2–5 | Observada/Declarada | 20 + documentação oficial | sem eventos nesta rodada |
| Funções | `max`, `avg`, `last` | Observada | 20 | somente candidatos |
| Recuperação | modo 0 em todas as candidatas | Observada/Declarada | 20 | sem testar eventos de recuperação |
| Dependências | 116 candidatas com dependência | Observada | 20 | efeito funcional não reconciliado |
| Macros | 124 nomes/coberturas agregados | Observada | 11 | nenhum valor consultado |
| Tags | 23 combinações; `scope=availability` predominante nos candidatos | Observada | 12, 20 | 2 candidatos sem tag |
| Lacunas | medidas por classe e amostra técnica | Observada | 21, 22 | amostra limitada a 50 |
| Hipótese servidor | não suportada atualmente | Inferida | 15, 16, 21 | falta ICMP na maioria |
| Hipótese AP/switch | parcialmente suportada | Inferida | 15, 17, 21 | baixa cobertura SNMP em switches |

---

## 33. Segurança, limitações e próximo passo

A Rodada 3 foi concluída com:

- 0 `ERROR` nas duas remessas oficiais;
- nenhuma DML ou DDL;
- nenhuma consulta a conteúdo histórico;
- nenhuma consulta funcional a eventos;
- nenhum `--include-heavy`;
- nenhum valor de macro ou segredo selecionado;
- nenhuma execução de view customizada;
- nenhuma alteração do núcleo Python;
- nenhuma saída bruta versionada.

Permanece pendente, sem alteração:

> criar e substituir a credencial atual por um usuário dedicado exclusivamente read-only no database `zabbix`.

O próximo passo permitido é preparar a Rodada 4 para eventos, problemas, recuperação e reconstrução controlada de intervalos de indisponibilidade. Essa preparação deverá começar por metadados, seletividade e regras de custo próprias, sem assumir que as hipóteses candidatas da Rodada 3 já são regras oficiais.

---

## 34. Resultado da Rodada 4

### 34.1 Escopo, pacote e remessas oficiais

A Rodada 4 demonstrou um modelo candidato de reconstrução de eventos, problemas e recuperações por meio do pacote:

```text
sql/ZABBIX_BI_Fase0_Rodada4_Eventos_Recuperacao_MySQL.sql
```

As remessas oficiais são:

| Gate | Remessa | Pasta local | ZIP local | Resultado |
|---|---|---|---|---|
| Rodada 4A | `20260814_202056` | `output/20260814_202056/` | `output/20260814_202056.zip` | 9 `SUCCESS`, 0 `ERROR`, 15 `SKIPPED_DISABLED` |
| Rodada 4B | `20260814_202937` | `output/20260814_202937/` | `output/20260814_202937.zip` | 21 `SUCCESS`, 2 `EMPTY`, 0 `ERROR`, 1 `SKIPPED_DISABLED` |

A remessa `20260814_200320` apresentou erro por referência à coluna inexistente `problem.suppressed`, foi rejeitada e não constitui evidência oficial. A remessa `20260814_202805`, embora sem `ERROR`, foi intermediária: detectou-se que as Consultas 15–17 e 19 não preservavam exatamente a amostra comum de 500 eventos. O filtro foi alinhado antes da remessa oficial 4B.

Nas remessas oficiais foram confirmados:

- 31 testes locais aprovados em cada execução;
- conexão ao database `zabbix`;
- transação `READ ONLY` aplicada;
- parser, validador SQL e bloqueio de colunas sensíveis ativos;
- nenhuma DML ou DDL;
- nenhuma consulta ao conteúdo de `history*` ou `trends*`;
- nenhuma execução com `--include-heavy`;
- nenhum hostname, IP, nome de usuário ou mensagem de reconhecimento retornado;
- snapshot SQL idêntico ao pacote executado;
- hashes dos CSVs compatíveis com os manifestos;
- ZIPs locais sem `.env` ou resultados externos ao escopo;
- núcleo Python preservado.

### 34.2 Status e linhas por consulta

| ID | Consulta | Rodada 4A | Linhas 4A | Rodada 4B | Linhas 4B |
|---:|---|---|---:|---|---:|
| 01 | Estrutura dos objetos de eventos | `SUCCESS` | 188 | `SUCCESS` | 188 |
| 02 | Índices e constraints | `SUCCESS` | 134 | `SUCCESS` | 134 |
| 03 | Volumetria estimada | `SUCCESS` | 17 | `SUCCESS` | 17 |
| 04 | Estruturas auxiliares | `SUCCESS` | 16 | `SUCCESS` | 16 |
| 05 | Amostra bruta de eventos | `SUCCESS` | 200 | `SUCCESS` | 200 |
| 06 | Distribuição recente de códigos | `SKIPPED_DISABLED` | 0 | `SKIPPED_DISABLED` | 0 |
| 07 | Amostra bruta de `problem` | `SUCCESS` | 200 | `SUCCESS` | 200 |
| 08 | Amostra de `event_recovery` | `SUCCESS` | 200 | `SUCCESS` | 200 |
| 09 | Triggers candidatas | `SUCCESS` | 164 | `SUCCESS` | 164 |
| 10 | Seletividade e índices | `SUCCESS` | 71 | `SUCCESS` | 71 |
| 11 | Eventos candidatos | `SKIPPED_DISABLED` | 0 | `SUCCESS` | 500 |
| 12 | Intervalos problema → recuperação | `SKIPPED_DISABLED` | 0 | `SUCCESS` | 249 |
| 13 | Evento → trigger → host | `SKIPPED_DISABLED` | 0 | `SUCCESS` | 500 |
| 14 | Problemas abertos | `SKIPPED_DISABLED` | 0 | `SUCCESS` | 12 |
| 15 | Severidade histórica × atual | `SKIPPED_DISABLED` | 0 | `SUCCESS` | 249 |
| 16 | Reconhecimentos agregados | `SKIPPED_DISABLED` | 0 | `SUCCESS` | 6 |
| 17 | Correlação e causa | `SKIPPED_DISABLED` | 0 | `EMPTY` | 0 |
| 18 | Supressão | `SKIPPED_DISABLED` | 0 | `EMPTY` | 0 |
| 19 | Dependências | `SKIPPED_DISABLED` | 0 | `SUCCESS` | 6 |
| 20 | Sobreposições por host | `SKIPPED_DISABLED` | 0 | `SUCCESS` | 2 |
| 21 | Múltiplos sinais simultâneos | `SKIPPED_DISABLED` | 0 | `SUCCESS` | 1 |
| 22 | Qualidade da reconstrução | `SKIPPED_DISABLED` | 0 | `SUCCESS` | 1 |
| 23 | Amostra de anomalias | `SKIPPED_DISABLED` | 0 | `SUCCESS` | 50 |
| 24 | Matriz do modelo | `SKIPPED_DISABLED` | 0 | `SUCCESS` | 10 |

A Consulta 06 permaneceu desabilitada porque a amostra menor da Consulta 05 foi suficiente para comprovar os códigos necessários; não houve justificativa para agregar 10.000 eventos.

### 34.3 Estrutura, volumetria e seletividade

**Evidência observada**

Estruturas e linhas estimadas relevantes:

| Tabela | Linhas estimadas | Tamanho estimado |
|---|---:|---:|
| `events` | 91.607 | 21,17 MB |
| `problem` | 217 | 0,11 MB |
| `event_recovery` | 50.440 | 7,41 MB |
| `acknowledges` | 51 | 0,06 MB |
| `event_suppress` | 0 | 0,08 MB |
| `event_tag` | 486.496 | 41,11 MB |
| `problem_tag` | 1.290 | 2,06 MB |

Os índices que sustentaram a Rodada 4B foram:

- `events_1(source, object, objectid, clock)` para universo de triggers e janela temporal;
- `events.PRIMARY(eventid)` para amostras recentes e recuperação;
- `problem_1(source, object, objectid)`, `problem.PRIMARY(eventid)`, `problem_3(r_eventid)` e `problem_4(cause_eventid)`;
- `event_recovery.PRIMARY(eventid)`, `event_recovery_1(r_eventid)` e `event_recovery_2(c_eventid)`;
- `acknowledges_2(eventid)`;
- `event_suppress_1(eventid, maintenanceid)`;
- `trigger_depends_1(triggerid_down, triggerid_up)`;
- PKs e FKs do caminho `function → item → host`.

A 4B foi limitada a:

```text
source = 0
object = 0
164 triggers candidatas
clock >= 2026-01-01 00:00:00 no timezone técnico da sessão
500 eventos mais recentes por eventid
```

A amostra final de 500 eventos cobriu `2026-07-23 14:32:18 -04:00` a `2026-08-14 16:46:44 -04:00`. Todos os tempos por consulta ficaram abaixo de um segundo na remessa final.

### 34.4 Códigos brutos e caminhos estruturais

**Evidência observada**

Na amostra bruta recente, os 200 eventos possuíam `source=0`, `object=0` e `value` igual a `0` ou `1`. Dos 102 registros simultaneamente presentes nas amostras de `events` e `problem`, todos apresentaram:

- `source=0`;
- `object=0`;
- `value=1`;
- o mesmo `objectid` em ambas as estruturas.

Nos 98 pares completos simultaneamente presentes em `events` e `event_recovery`:

- o evento de problema tinha `value=1`;
- o evento de recuperação tinha `value=0`;
- problema e recuperação possuíam o mesmo `objectid`;
- `problem.r_eventid` e `event_recovery.r_eventid` coincidiam.

**Inferência sustentada pela amostra**

Para `source=0` e `object=0`, o caminho candidato observado é:

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

Esse caminho é um modelo candidato de reconstrução e não uma regra oficial de disponibilidade.

### 34.5 Intervalos, abertos e duração técnica

**Evidência observada**

Na amostra comum de 500 eventos candidatos:

- 249 eram eventos de problema;
- 241 possuíam evento de recuperação;
- 8 permaneciam tecnicamente abertos;
- 251 eram eventos de recuperação;
- 0 problemas ficaram sem trigger mapeada;
- 0 problemas ficaram sem host mapeado;
- 0 recuperações esperadas ficaram sem evento de recuperação;
- 0 durações negativas foram observadas.

A Consulta 14 encontrou 12 problemas abertos no universo candidato do exercício vigente. O total é maior que os 8 da Consulta 12 porque a Consulta 14 cobre o recorte anual candidato, enquanto a Consulta 12 preserva apenas os 500 eventos da amostra comum.

Para os 241 intervalos encerrados da amostra:

- duração técnica mínima: 60 segundos;
- duração técnica máxima: 922.560 segundos;
- duração técnica média descritiva: 5.875,27 segundos.

Essas durações são diferenças técnicas entre clocks de problema e recuperação. Não constituem MTTR, SLA ou indisponibilidade oficial.

### 34.6 Severidade histórica e reconhecimentos

**Evidência observada**

Dos 249 eventos de problema:

- 243 possuíam severidade histórica igual à prioridade atual da trigger;
- 6 divergiam;
- nas divergências, a severidade histórica bruta era `1`, enquanto a prioridade atual era `3` em 2 eventos e `4` em 4 eventos.

**Inferência**

O modelo futuro deve preservar a severidade histórica do evento e não depender exclusivamente da prioridade atual da trigger.

Foram observados:

- 6 eventos reconhecidos;
- 6 registros de reconhecimento;
- somente o código bruto de ação `14` nesses registros.

Nenhum nome de usuário ou mensagem foi consultado. A semântica funcional do código `14` permanece pendente de fonte declarada ou reconciliação.

### 34.7 Correlação, supressão e dependências

**Evidência observada**

- nenhuma correlação ou causa foi observada nos campos comprovados de `problem` e `event_recovery` para a amostra;
- nenhuma supressão foi observada nos eventids da amostra;
- 6 eventos de problema, relacionados a 5 triggers, possuíam dependência como `triggerid_down`;
- dependência foi registrada como contexto e não causou exclusão automática de eventos.

As ausências de correlação e supressão são limitadas à amostra e ao estado observado. Não comprovam impossibilidade funcional dessas estruturas.

### 34.8 Sobreposições e múltiplos sinais

**Evidência observada**

Foram encontrados 2 pares de intervalos sobrepostos no mesmo host:

- um par com um intervalo aberto e outro encerrado;
- um par com ambos os intervalos encerrados e os mesmos limites técnicos.

Um dos pares combinava sinais candidatos diferentes:

```text
DISPONIBILIDADE_SNMP + DISPONIBILIDADE_ICMP
```

**Inferência**

Somar durações de problemas por host sem união temporal pode produzir dupla contagem. A existência de múltiplos sinais simultâneos também impede tratar cada trigger como uma indisponibilidade independente sem regra funcional reconciliada.

### 34.9 Qualidade, anomalias e lacunas

**Evidência observada**

Dos 249 eventos de problema da amostra, 224 já não possuíam linha correspondente na estrutura `problem`, embora 241 intervalos tenham sido reconstruídos por `event_recovery`. A Consulta 23 atingiu o limite de 50 anomalias; todas as 50 eram exclusivamente ausência de linha em `problem`, sem:

- recuperação divergente;
- evento de recuperação ausente quando esperado;
- duração negativa;
- trigger ou host não mapeado.

**Inferência**

`problem` não é suficiente isoladamente para reconstruir todo o recorte histórico observado. A causa da ausência dessas linhas — retenção, housekeeping ou outra regra interna — permanece hipótese e não foi presumida.

Permanecem lacunas para disponibilidade oficial:

- aprovação funcional dos sinais candidatos por classe de ativo;
- união temporal e regra para múltiplas triggers no mesmo host;
- efeito funcional das dependências;
- interpretação declarada dos códigos de reconhecimento;
- timezone oficial;
- manutenção programada e significado da supressão, reservados à Rodada 5;
- reconciliação com casos reais e interface/API do Zabbix;
- política de retenção de `problem`;
- conta dedicada exclusivamente read-only.

### 34.10 Conclusão e próximo passo

A Rodada 4 foi concluída como demonstração controlada do modelo candidato `problema → recuperação → trigger → host`, com intervalos abertos/encerrados, duração técnica, severidade histórica, reconhecimento, dependências e sobreposições avaliados.

Não foi calculada disponibilidade oficial, MTTR, MTBF, MTTF ou SLA. Nenhuma manutenção ou reinício foi classificado.

Permanece pendente, sem alteração:

> criar e substituir a credencial atual por um usuário dedicado exclusivamente read-only no database `zabbix`.

O próximo passo permitido é preparar a Rodada 5, restrita a manutenção, supressão programada e reinícios.

---

## 35. Resultado da Rodada 5

### 35.1 Escopo, pacote e remessas oficiais

A Rodada 5 investigou estruturas de manutenção e supressão e, após um gate estrutural limpo, leu seletivamente uptime para detectar somente `RESET_UPTIME_CANDIDATO`.

O pacote oficial é:

```text
sql/ZABBIX_BI_Fase0_Rodada5_Manutencao_Reinicios_MySQL.sql
```

As remessas oficiais são:

| Gate | Remessa | Pasta local | ZIP local | Resultado |
|---|---|---|---|---|
| Rodada 5A | `20260814_205026` | `output/20260814_205026/` | `output/20260814_205026.zip` | 7 `SUCCESS`, 6 `EMPTY`, 0 `ERROR`, 11 `SKIPPED_DISABLED` |
| Rodada 5B | `20260814_205609` | `output/20260814_205609/` | `output/20260814_205609.zip` | 16 `SUCCESS`, 8 `EMPTY`, 0 `ERROR`, 0 ignoradas |

Nas duas remessas foram confirmados:

- 31 testes locais aprovados;
- conexão ao database `zabbix`;
- transação `READ ONLY` aplicada;
- parser, validador SQL e bloqueio de colunas sensíveis ativos;
- nenhuma DML ou DDL;
- nenhum `--include-heavy`;
- nenhuma consulta a `trends*`;
- nenhum acesso a `history_uint` na Rodada 5A;
- acesso a `history_uint` na 5B somente com oito `itemid` explícitos e janela de 14 dias;
- snapshots SQL idênticos aos pacotes executados;
- hashes dos CSVs compatíveis com os manifestos;
- ZIPs locais sem `.env`;
- núcleo Python preservado.

### 35.2 Status e linhas por consulta

| ID | Consulta | Rodada 5A | Linhas 5A | Rodada 5B | Linhas 5B |
|---:|---|---|---:|---|---:|
| 01 | Estrutura de manutenção e uptime | `SUCCESS` | 147 | `SUCCESS` | 147 |
| 02 | Índices e constraints | `SUCCESS` | 120 | `SUCCESS` | 120 |
| 03 | Volumetria estimada | `SUCCESS` | 14 | `SUCCESS` | 14 |
| 04 | Catálogo de manutenções | `EMPTY` | 0 | `EMPTY` | 0 |
| 05 | Manutenção → host | `EMPTY` | 0 | `EMPTY` | 0 |
| 06 | Manutenção → grupo | `EMPTY` | 0 | `EMPTY` | 0 |
| 07 | Períodos e janelas | `EMPTY` | 0 | `EMPTY` | 0 |
| 08 | Tags de manutenção | `EMPTY` | 0 | `EMPTY` | 0 |
| 09 | Amostra de `event_suppress` | `EMPTY` | 0 | `EMPTY` | 0 |
| 10 | Cobertura atual nos hosts regulares | `SUCCESS` | 1 | `SUCCESS` | 1 |
| 11 | Itens de uptime e `value_type` | `SUCCESS` | 101 | `SUCCESS` | 101 |
| 12 | Seleção de itemids | `SUCCESS` | 8 | `SUCCESS` | 8 |
| 13 | Índice histórico | `SUCCESS` | 3 | `SUCCESS` | 3 |
| 14 | Supressões e manutenção no recorte | `SKIPPED_DISABLED` | 0 | `EMPTY` | 0 |
| 15 | Eventos suprimidos × não suprimidos | `SKIPPED_DISABLED` | 0 | `SUCCESS` | 1 |
| 16 | Amostra seletiva de uptime | `SKIPPED_DISABLED` | 0 | `SUCCESS` | 1.600 |
| 17 | Quedas de uptime por item | `SKIPPED_DISABLED` | 0 | `SUCCESS` | 7 |
| 18 | Resets candidatos | `SKIPPED_DISABLED` | 0 | `SUCCESS` | 25 |
| 19 | Resets por classe/família | `SKIPPED_DISABLED` | 0 | `SUCCESS` | 4 |
| 20 | Qualidade das séries | `SKIPPED_DISABLED` | 0 | `SUCCESS` | 8 |
| 21 | Proximidade reset × evento | `SKIPPED_DISABLED` | 0 | `SUCCESS` | 25 |
| 22 | Reset × manutenção/supressão | `SKIPPED_DISABLED` | 0 | `EMPTY` | 0 |
| 23 | Divergências e lacunas | `SKIPPED_DISABLED` | 0 | `SUCCESS` | 12 |
| 24 | Matriz de conclusão | `SKIPPED_DISABLED` | 0 | `SUCCESS` | 10 |

O maior tempo por consulta na 5B foi 3,55 segundos. Não houve justificativa para ampliar a janela além de 14 dias.

### 35.3 Manutenção e supressão observadas

**Evidência observada**

O schema contém os caminhos estruturais esperados:

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

No estado exato observado pelas consultas pequenas:

- `maintenances`, `maintenances_hosts`, `maintenances_groups`, `maintenances_windows`, `timeperiods` e `maintenance_tag` não retornaram registros;
- `event_suppress` não retornou registros;
- os 135 hosts regulares apresentaram `maintenance_status=0`, `maintenance_type=0` e `maintenanceid` nulo;
- 134 eventos de problema candidatos dos últimos 14 dias estavam na categoria técnica não suprimida;
- não foi observada coincidência reset × evento suprimido × manutenção.

**Limitação**

Essa ausência descreve o estado e o recorte observados. Não comprova ausência histórica de manutenção e não permite validar funcionalmente a distinção entre manutenção programada e falha. Um caso real de manutenção permanece obrigatório na reconciliação.

### 35.4 Gate histórico e seleção de uptime

**Evidência observada**

Os 101 itens candidatos de uptime apresentaram `value_type=3` e tabela histórica candidata `history_uint`:

| Chave | Classe observada | Itens |
|---|---|---:|
| `system.uptime` | Windows | 29 |
| `system.uptime` | Linux | 12 |
| `system.hw.uptime[hrSystemUptime.0]` | Access Point / switch / outras classes | 18 / 1 / 11 |
| `system.net.uptime[sysUpTime.0]` | Access Point / switch / outras classes | 18 / 1 / 11 |

A PK observada de `history_uint` é:

```text
PRIMARY(itemid, clock, ns)
```

A seleção determinística da 5A produziu os seguintes oito itemids:

| Classe candidata | Itemids | Família selecionada |
|---|---|---|
| Access Point | `56135`, `56207` | uptime SNMP de hardware |
| Switch | `57286` | uptime SNMP de hardware |
| Windows | `50648`, `50934` | `system.uptime` |
| Linux | `42240`, `54314` | `system.uptime` |
| Outra classe | `58869` | uptime SNMP de hardware |

O Gate 5B foi aprovado porque os oito itens tinham o mesmo `value_type`, a tabela era `history_uint`, o índice começava por `itemid, clock`, a janela permaneceu em 14 dias, nenhuma consulta era pesada e os custos da 5A ficaram abaixo de um segundo.

### 35.5 Série histórica e resets candidatos

**Evidência observada**

O recorte filtrado continha 320.833 amostras nos oito itemids. A Consulta 16 exportou somente as 200 amostras mais recentes por item, totalizando 1.600 linhas.

A regra técnica aplicada foi exclusivamente:

```text
mesmo itemid
clock atual > clock anterior
valor atual < valor anterior
```

Foram observados 25 `RESET_UPTIME_CANDIDATO` em 7 dos 8 itemids:

| Classe/família | Resets candidatos | Itemids | Hosts |
|---|---:|---:|---:|
| Access Point / uptime SNMP de hardware | 12 | 2 | 2 |
| Windows / `system.uptime` | 2 | 2 | 2 |
| Linux / `system.uptime` | 5 | 2 | 2 |
| Outra classe / uptime SNMP de hardware | 6 | 1 | 1 |

O item do switch selecionado não apresentou queda no recorte. Não foram excluídas quedas por limiar arbitrário.

**Interpretação controlada**

- `system.uptime` é um candidato forte, por evidência declarada, a reinício do sistema operacional, mas os 7 resets observados nessa família continuam pendentes de reconciliação;
- os 18 resets da família SNMP podem representar reinício do equipamento ou apenas do subsistema/agente de gerenciamento;
- nenhum dos 25 registros constitui reboot oficial do ativo.

### 35.6 Qualidade das séries

**Evidência observada**

- os oito itemids possuíam amostras na janela;
- não foram observados valores nulos;
- não foram observados clocks com múltiplos registros;
- a densidade ficou entre 118,74 e 119,58 amostras por hora;
- o maior gap foi 4.621 segundos;
- dois itemids apresentaram um gap superior a uma hora;
- os demais seis não apresentaram gap superior a uma hora.

Os gaps são informação de qualidade da série e não foram usados para eliminar resets candidatos.

### 35.7 Proximidade com eventos candidatos

**Evidência observada**

Dos 25 resets candidatos:

- 13 possuíam um evento de problema candidato no mesmo host em até ±30 minutos;
- 12 não possuíam evento candidato nessa janela;
- os 13 eventos próximos pertenciam ao sinal candidato de ICMP;
- a distância absoluta variou de 4 a 715 segundos;
- a distância absoluta média descritiva foi 207,46 segundos.

**Limitação**

Proximidade temporal não comprova causalidade. Os 13 pares não aprovam reboot, indisponibilidade oficial nem relação causal entre o reset e o evento de ICMP.

### 35.8 Matriz de evidência e lacunas

| Pergunta | Resposta | Classificação | Limitação |
|---|---|---|---|
| Schema de manutenção existe? | Sim, com FKs e índices declarados | Observada | Estrutura não comprova uso funcional |
| Há manutenção configurada no estado observado? | Não foram retornados registros | Observada | Não prova ausência histórica |
| Há hosts atualmente em manutenção? | 0 de 135 hosts regulares | Observada | Fotografia do momento da coleta |
| Há supressão observada? | `event_suppress` vazio; 134 eventos candidatos não suprimidos | Observada | Limitado ao estado e recorte |
| Uptime usa qual tabela? | 101 itens com `value_type=3`; `history_uint` no gate aprovado | Observada/Declarada | Mapeamento restrito aos candidatos comprovados |
| Índice é seletivo? | PK `itemid, clock, ns` | Observada | Obrigatório manter itemid e tempo |
| Resets podem ser detectados? | 25 candidatos em 14 dias | Observada | Não equivalem a reboot |
| Resets se aproximam de eventos? | 13 em ±30 minutos | Observada | Sem causalidade |
| Manutenção pode ser separada de falha? | Estruturalmente há caminhos, mas falta caso observado | Inferida/Lacuna | Requer reconciliação real |
| Reinício oficial pode ser classificado? | Não nesta rodada | Hipótese pendente | Requer interface/API e caso conhecido |

A Consulta 23 registrou 12 lacunas, todas `RESET_SEM_EVENTO_CANDIDATO_30_MIN`. Não houve item selecionado com `value_type` divergente nem item sem série na janela.

### 35.9 Segurança e integridade

A Rodada 5 foi concluída com:

- 0 `ERROR` nas remessas oficiais;
- nenhuma DML, DDL, procedure, lock ou `FOR UPDATE`;
- nenhuma consulta global a `history*` ou `trends*`;
- nenhum período acima de 14 dias;
- no máximo oito itemids;
- `LAG` aplicado somente após os filtros de item e tempo;
- nenhuma execução com `--include-heavy`;
- nenhum segredo, hostname, IP, DNS, usuário ou mensagem livre selecionado;
- nenhuma alteração no núcleo Python;
- nenhuma saída bruta versionada.

Permanece pendente, sem alteração:

> criar e substituir a credencial atual por um usuário dedicado exclusivamente read-only no database `zabbix`.

### 35.10 Conclusão e próximo passo

A Rodada 5 foi concluída como descoberta técnica de manutenção, supressão e resets candidatos de uptime. O schema e os caminhos estruturais foram comprovados; o estado observado não continha configuração de manutenção, supressão nem host atualmente em manutenção.

Os 25 resets detectados permanecem exclusivamente `RESET_UPTIME_CANDIDATO`. Não foram calculados disponibilidade, MTTR, MTBF, MTTF ou SLA, e nenhuma manutenção foi excluída de indicador.

O próximo passo permitido é a reconciliação com casos reais: uma manutenção programada, um reinício conhecido de servidor e, quando disponível, um reset conhecido de ativo SNMP, comparando banco, interface Zabbix e API.
