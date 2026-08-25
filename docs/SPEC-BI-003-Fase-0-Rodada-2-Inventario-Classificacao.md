# SPEC BI-003 — Fase 0 — Rodada 2: Inventário e Classificação

**Projeto:** BI-003 — MVP de Disponibilidade da Infraestrutura de TI  
**Fase:** 0 — Descoberta Técnica do Zabbix  
**Rodada:** 2 — Inventário, classificação, localização e views customizadas  
**Ferramenta:** Generic SQL Extractor 2.0  
**SGBD:** MySQL  
**Database:** `zabbix`  
**Branch de trabalho:** `feat/bi-003-zabbix-fase0-round2`  
**Pacote SQL previsto:** `sql/ZABBIX_BI_Fase0_Rodada2_Inventario_MySQL.sql`  
**Status:** APROVADA PARA IMPLEMENTAÇÃO CONTROLADA  
**Versão:** 1.0  
**Data:** 14/08/2026

---

## 1. Autoridade e relação com a SPEC principal

Este documento detalha operacionalmente a Rodada 2 da Fase 0 do BI-003.

A fonte da verdade global da Fase 0 permanece:

```text
docs/SPEC-BI-003-Fase-0-Descoberta-Tecnica-Zabbix.md
```

Este documento complementa a seção de Rodada 2 da SPEC principal. Em caso de divergência:

1. prevalecem as restrições de segurança da SPEC principal;
2. prevalecem as restrições de `AGENTS.md`;
3. esta SPEC define o escopo operacional específico da Rodada 2;
4. dados observados no banco não substituem regra de negócio aprovada sem reconciliação.

---

## 2. Baseline aprovado da Rodada 1

A Rodada 1 foi concluída com sucesso e está documentada em:

```text
docs/ZABBIX_BI_Fase0_RELATORIO.md
```

Evidências já estabelecidas:

- MySQL `8.0.46-0ubuntu0.22.04.3`;
- database `zabbix`;
- schema Zabbix `7020000 / 7020004`;
- 203 tabelas base;
- 28 views;
- 203 tabelas base InnoDB;
- nenhuma tabela base sem PK detectada;
- 272 FKs declaradas;
- nenhum particionamento detectado;
- aproximadamente 17,47 GB em tabelas;
- `history`, `history_uint`, `trends` e `trends_uint` concentram aproximadamente 97,7% do tamanho estimado;
- aproximadamente 531 linhas estimadas em `hosts`;
- 47 grupos;
- 601 vínculos em `hosts_groups`;
- 1.070 tags;
- 146 vínculos host-template;
- 156 interfaces;
- 43 interfaces SNMP;
- apenas 2 linhas estimadas em `host_inventory`.

Views customizadas relevantes observadas:

- `View_Access_Points`;
- `View_Switches`;
- `View_Servidores`;
- `View_Servidores_Fisicos`;
- `View_Servidores_Virtuais`;
- `View_Servidores_Windows`;
- `View_Servidores_Linux`.

Essas views expõem ou aparentam expor atributos relacionados a classificação, localização e monitoramento, incluindo `PING`, `SNMP`, Zabbix Agent, `UPTIME` e `STATUS`.

A semântica funcional dessas views ainda não está comprovada.

---

## 3. Objetivo exclusivo da Rodada 2

Construir evidência reproduzível para descobrir como o ambiente representa o inventário monitorado e sua classificação, sem avançar para eventos ou histórico.

A Rodada 2 deve responder, com evidência:

1. quantos registros de `hosts` representam ativos monitorados;
2. quantos ativos estão habilitados e desabilitados;
3. como diferenciar hosts reais, templates e demais registros existentes em `hosts`;
4. quais grupos existem;
5. como os ativos são distribuídos nos grupos;
6. quais tags são utilizadas e com que frequência;
7. quais templates estão vinculados aos ativos;
8. quais interfaces são utilizadas;
9. quais ativos utilizam agente Zabbix;
10. quais ativos utilizam SNMP;
11. se proxies participam do monitoramento e em que cobertura;
12. como Access Points são classificados;
13. como switches são classificados;
14. como servidores físicos são classificados;
15. como servidores virtuais são classificados;
16. como Windows e Linux são diferenciados;
17. de onde vêm Unidade, Prédio, Sala, Setor e Departamento;
18. quantos ativos possuem classificação incompleta ou conflitante;
19. quantos ativos possuem localização incompleta;
20. quais regras estruturais sustentam as views customizadas;
21. quais divergências existem entre views, grupos, tags, templates e tabelas padrão.

---

## 4. Escopo permitido

A Rodada 2 pode consultar, de forma controlada, metadados e estruturas cadastrais necessárias para inventário, incluindo quando existentes:

- `information_schema.COLUMNS`;
- `information_schema.STATISTICS`;
- `information_schema.TABLE_CONSTRAINTS`;
- `information_schema.KEY_COLUMN_USAGE`;
- `information_schema.REFERENTIAL_CONSTRAINTS`;
- `information_schema.VIEWS`;
- `hosts`;
- `hstgrp`;
- `hosts_groups`;
- `host_tag`;
- `hosts_templates`;
- `interface`;
- `interface_snmp`;
- `host_inventory`;
- tabelas de proxy identificadas por metadados;
- views customizadas relevantes, somente após análise estrutural demonstrar que sua execução é segura para esta rodada.

Outras tabelas cadastrais pequenas poderão ser adicionadas somente se a definição das views ou as FKs observadas demonstrarem necessidade direta para responder aos objetivos desta SPEC.

---

## 5. Fora de escopo e proibições

Não consultar, nesta rodada, dados históricos das tabelas:

- `history`;
- `history_uint`;
- `history_str`;
- `history_text`;
- `history_log`;
- `trends`;
- `trends_uint`.

Também estão fora de escopo:

- reconstrução de eventos;
- `events` para análise funcional de indisponibilidade;
- `problem` para reconstrução de indisponibilidade;
- `event_recovery` para reconstrução de indisponibilidade;
- MTTR;
- MTBF;
- MTTF;
- cálculo oficial de disponibilidade;
- manutenção programada detalhada;
- reinícios;
- semântica completa de itens e triggers;
- PostgreSQL;
- Power BI;
- coletor produtivo via API;
- MCP;
- mudanças no Zabbix;
- mudanças no MySQL;
- alterações de templates, hosts, tags ou grupos.

A definição textual de uma view pode citar estruturas fora desse escopo. Isso permite apenas registrar a dependência estrutural. Não autoriza consultar o conteúdo dessas estruturas.

---

## 6. Segurança obrigatória

### 6.1 Conta de banco

A conta atualmente utilizada é temporariamente a conta operacional do Zabbix.

O responsável pelo projeto autorizou explicitamente seu uso durante a Fase 0 até a criação de um usuário dedicado exclusivamente a leitura.

Essa autorização é uma exceção operacional temporária e não encerra o requisito:

> criar e substituir a credencial atual por um usuário dedicado exclusivamente read-only no database `zabbix`.

Esse item deve continuar pendente na documentação.

### 6.2 Proteções obrigatórias

Toda execução deverá manter:

- somente `SELECT` ou `WITH`;
- nenhuma DML;
- nenhuma DDL;
- nenhuma procedure;
- nenhuma função com efeito colateral conhecido;
- nenhuma criação de objeto;
- nenhuma alteração de configuração;
- nenhuma tentativa de criar usuário;
- nenhuma escrita no banco;
- nenhuma execução manual fora do Generic SQL Extractor;
- transação `READ ONLY`;
- parser/safety ativos;
- timeout por consulta;
- limites em amostras;
- minimização de identificadores;
- nenhum segredo ou credencial em saída;
- nenhum `.env` exibido, resumido ou versionado.

### 6.3 Núcleo Python

Não alterar o núcleo Python para acomodar regras do Zabbix.

Alteração no núcleo somente será permitida se houver defeito técnico comprovado de:

- parser;
- safety;
- compatibilidade MySQL;
- exportação;
- manifesto;
- log;
- execução read-only.

Se isso ocorrer, aplicar a regra de parada e solicitar revisão antes de modificar o núcleo.

---

## 7. Governança Git obrigatória

Antes de qualquer implementação local:

1. executar `git fetch --all --prune`;
2. confirmar working tree limpo;
3. confirmar que `HEAD`, `main` e `origin/main` representam o baseline esperado;
4. não alterar diretamente `main`;
5. utilizar a branch:

```text
feat/bi-003-zabbix-fase0-round2
```

A branch já pode existir no remoto. Nesse caso, deve ser buscada e utilizada sem recriá-la.

Não fazer merge na `main` automaticamente.

Ao finalizar, a branch deve permanecer:

- com working tree limpo;
- commits coerentes;
- documentação atualizada;
- pronta para revisão humana.

---

## 8. Estratégia da Rodada 2

A Rodada 2 será executada em dois gates internos.

### 8.1 Rodada 2A — Estrutura e inventário padrão

Objetivo:

- descobrir campos e relacionamentos reais;
- obter definições das views sem executá-las;
- medir hosts, grupos, tags, templates, interfaces e proxies;
- descobrir o vocabulário efetivamente utilizado para classificação e localização.

A Rodada 2A não deve assumir previamente nomes de tags, grupos ou campos de localização.

### 8.2 Rodada 2B — Classificação, qualidade e reconciliação

Somente após analisar os resultados da Rodada 2A:

- construir lógica candidata de classificação com base em valores realmente observados;
- medir classificação incompleta e conflitante;
- medir localização incompleta;
- comparar views customizadas com estruturas padrão;
- registrar divergências.

A Rodada 2B continua fazendo parte da mesma Rodada 2 e não autoriza avançar para itens, triggers, eventos ou histórico.

---

## 9. Diretriz especial para views customizadas

As views customizadas são evidência observada de uma solução existente. Não são regra de negócio aprovada.

Antes de qualquer `SELECT` contra o conteúdo de uma view relevante, deve-se consultar sua estrutura e `VIEW_DEFINITION`.

Não assumir que:

- `View_Access_Points` contém todos os APs corretos;
- `View_Switches` contém todos os switches corretos;
- `View_Servidores_*` representa o inventário oficial;
- `STATUS` equivale à disponibilidade do futuro BI;
- `PING`, `SNMP` ou `ZABBIX` implementam a regra conceitual aprovada;
- o nome da view comprova a origem da classificação.

### 9.1 Gate de execução das views

Uma view só poderá ser consultada na Rodada 2B quando sua definição demonstrar que:

- não acessa diretamente `history*` ou `trends*` proibidas nesta rodada;
- não executa função/procedure com efeito colateral conhecido;
- não possui construção de custo incerto incompatível com o ambiente;
- não exige consulta ampla a estruturas de alto volume;
- sua execução pode ser limitada e justificada.

Se alguma view utilizar estrutura proibida, não executar a view. Registrar apenas a dependência estrutural como evidência observada.

---

## 10. Minimização de dados

A descoberta deve evitar exposição desnecessária de nomes, IPs, DNS ou outros identificadores.

Preferências de saída:

- usar contagens agregadas sempre que possível;
- usar `hostid` como chave técnica nas matrizes de qualidade;
- não retornar IP/DNS quando a pergunta puder ser respondida por contagem;
- limitar amostras de divergência a no máximo 50 registros;
- não retornar credenciais ou parâmetros SNMP sensíveis;
- não retornar valores de comunidade, autenticação, senha ou segredo;
- não copiar resultados CSV para GitHub.

Nomes de grupos, tags, valores de tags e templates podem ser retornados quando necessários para provar a classificação ou localização, pois são parte da semântica investigada. Ainda assim, devem ser limitados ao necessário.

---

## 11. Pacote SQL

Criar sem substituir o pacote da Rodada 1:

```text
sql/ZABBIX_BI_Fase0_Rodada2_Inventario_MySQL.sql
```

Cada consulta deve possuir:

```sql
-- @id: <inteiro único>
-- @output: <arquivo.csv>
-- @description: <objetivo claro>
-- @heavy: false|true
-- @enabled: true|false
-- @timeout: <segundos>
```

Requisitos:

- uma única instrução por bloco;
- início por `SELECT` ou `WITH`;
- ordenação determinística;
- `LIMIT` em amostras;
- sem `SELECT *` transacional irrestrito;
- sem consultas históricas;
- sem funções de efeito colateral;
- sem dependência de valor não observado para classificar ativos.

---

## 12. Consultas mínimas obrigatórias

### Consulta 01 — Estrutura dos objetos de inventário

**Output:** `01_estrutura_objetos_inventario.csv`  
**Fase:** 2A  
**Risco:** Baixo

Levantar via `information_schema.COLUMNS` as colunas dos objetos cadastrais relevantes.

Objetivo:

- confirmar nomes e tipos reais antes de escrever joins;
- descobrir campos de status, flags, proxy, interface e inventário;
- eliminar suposições de schema.

### Consulta 02 — Índices e relacionamentos do inventário

**Output:** `02_indices_constraints_inventario.csv`  
**Fase:** 2A  
**Risco:** Baixo

Levantar PKs, FKs, uniques e índices apenas dos objetos necessários à Rodada 2.

Objetivo:

- comprovar caminhos estruturais;
- verificar índices que sustentam joins;
- não afirmar relacionamento apenas por semelhança de nomes.

### Consulta 03 — Estrutura das views customizadas

**Output:** `03_estrutura_views_customizadas.csv`  
**Fase:** 2A  
**Risco:** Baixo

Catalogar colunas das views relevantes sem executar seu conteúdo.

Objetivo:

- identificar atributos realmente expostos;
- comparar nomes e tipos;
- localizar indícios de classificação, localização e monitoramento.

### Consulta 04 — Definições das views customizadas

**Output:** `04_definicoes_views_customizadas.csv`  
**Fase:** 2A  
**Risco:** Médio

Consultar `information_schema.VIEWS.VIEW_DEFINITION` para as views relevantes.

Objetivo:

- identificar tabelas de origem;
- identificar joins;
- identificar filtros;
- identificar `CASE` ou regras de classificação;
- identificar dependências proibidas antes de executar as views.

Não consultar o conteúdo das views nesta etapa.

### Consulta 05 — Distribuição bruta de registros em hosts

**Output:** `05_hosts_distribuicao_status.csv`  
**Fase:** 2A  
**Risco:** Baixo

Agrupar `hosts` por campos brutos relevantes descobertos na Consulta 01.

Objetivo:

- medir categorias existentes;
- descobrir valores usados para status/flags;
- evitar interpretar 531 registros como 531 ativos.

### Consulta 06 — Hosts reais habilitados e desabilitados

**Output:** `06_hosts_monitorados_habilitados_desabilitados.csv`  
**Fase:** 2A  
**Risco:** Baixo

Após interpretar estruturalmente os valores observados na Consulta 05, calcular os totais de hosts reais monitorados, habilitados e desabilitados.

A consulta deve manter o valor bruto relevante no agrupamento para auditabilidade.

### Consulta 07 — Catálogo de grupos

**Output:** `07_grupos_hosts.csv`  
**Fase:** 2A  
**Risco:** Baixo-Médio

Listar grupos necessários à classificação.

Objetivo:

- descobrir vocabulário real;
- verificar se classificação/localização está codificada em grupos.

### Consulta 08 — Distribuição de hosts por grupo

**Output:** `08_distribuicao_hosts_grupos.csv`  
**Fase:** 2A  
**Risco:** Baixo

Produzir contagem de hosts reais por grupo e, quando seguro, por situação do host.

Objetivo:

- medir cobertura;
- identificar hosts sem grupo;
- identificar múltiplos vínculos.

### Consulta 09 — Catálogo e uso de tags

**Output:** `09_tags_catalogo_uso.csv`  
**Fase:** 2A  
**Risco:** Baixo-Médio

Agrupar por tag e valor, com quantidade de hosts distintos.

Objetivo:

- descobrir chaves/valores realmente utilizados;
- procurar evidência para tipo, sistema operacional e localização;
- não assumir previamente nomes como `unidade`, `predio` ou equivalentes.

### Consulta 10 — Templates vinculados

**Output:** `10_templates_vinculados.csv`  
**Fase:** 2A  
**Risco:** Baixo-Médio

Listar templates vinculados e quantidade de hosts distintos.

Objetivo:

- verificar se AP, switch, servidor, Windows/Linux ou físico/virtual são diferenciados por template.

### Consulta 11 — Cobertura de interfaces

**Output:** `11_interfaces_cobertura.csv`  
**Fase:** 2A  
**Risco:** Baixo

Agrupar interfaces por tipo e medir hosts distintos.

Objetivo:

- identificar uso de agente, SNMP e demais tipos;
- não retornar IP ou DNS quando desnecessário.

### Consulta 12 — Resumo SNMP

**Output:** `12_interfaces_snmp_resumo.csv`  
**Fase:** 2A  
**Risco:** Baixo

Medir cobertura das interfaces SNMP utilizando apenas campos técnicos não secretos.

É proibido retornar:

- comunidades;
- senhas;
- secrets;
- credenciais;
- material de autenticação.

### Consulta 13 — Cobertura por proxy

**Output:** `13_proxy_cobertura.csv`  
**Fase:** 2A  
**Risco:** Baixo

Somente após descobrir o modelo real de proxy pela Consulta 01/02, medir quantidade de hosts por proxy ou modo equivalente.

Não listar configuração sensível.

### Consulta 14 — Origens candidatas de localização

**Output:** `14_origens_candidatas_localizacao.csv`  
**Fase:** 2A  
**Risco:** Baixo-Médio

Consolidar evidências observáveis de localização vindas de:

- `host_inventory`;
- tags;
- grupos;
- colunas das views customizadas;
- outras estruturas cadastrais pequenas demonstradas pelas definições das views.

Objetivo:

- determinar onde Unidade, Prédio, Sala, Setor e Departamento realmente estão representados;
- não inventar mapeamento.

### Consulta 15 — Matriz candidata de classificação por host

**Output:** `15_matriz_classificacao_host.csv`  
**Fase:** 2B  
**Risco:** Médio  
**Estado inicial recomendado:** `@enabled: false`

Somente depois da análise da Rodada 2A, criar uma matriz por `hostid` contendo sinais candidatos derivados de grupos, tags e templates.

Classificações a investigar:

- Access Point;
- switch;
- servidor;
- físico;
- virtual;
- Windows;
- Linux.

A matriz deve registrar a origem de cada sinal. Ela não deve transformar hipótese em regra oficial.

### Consulta 16 — Qualidade da classificação

**Output:** `16_qualidade_classificacao.csv`  
**Fase:** 2B  
**Risco:** Médio  
**Estado inicial recomendado:** `@enabled: false`

Medir:

- classificados;
- sem classificação;
- classificação ambígua;
- AP + servidor;
- switch + servidor;
- físico + virtual;
- Windows + Linux;
- outros conflitos demonstrados pelos dados.

Não codificar conflitos sem evidência da Rodada 2A.

### Consulta 17 — Qualidade da localização

**Output:** `17_qualidade_localizacao.csv`  
**Fase:** 2B  
**Risco:** Médio  
**Estado inicial recomendado:** `@enabled: false`

Após comprovar as fontes reais, medir completude de:

- Unidade;
- Prédio;
- Sala;
- Setor;
- Departamento.

Deve distinguir:

- completo;
- parcialmente preenchido;
- totalmente ausente.

### Consulta 18 — Amostra controlada de incompletos e conflitos

**Output:** `18_amostra_incompletos_conflitos.csv`  
**Fase:** 2B  
**Risco:** Médio  
**Estado inicial recomendado:** `@enabled: false`

Retornar no máximo 50 registros, preferencialmente usando `hostid` e indicadores de lacuna/conflito.

Evitar hostname/IP salvo se absolutamente necessário para reconciliação e justificado no relatório.

### Consulta 19 — Reconciliação entre views e fontes padrão

**Output:** `19_reconciliacao_views_fontes_padrao.csv`  
**Fase:** 2B  
**Risco:** Médio-Condicional  
**Estado inicial obrigatório:** `@enabled: false`

Só habilitar depois que a Consulta 04 demonstrar que a execução das views é segura para esta rodada.

Produzir comparação agregada entre:

- presença na view;
- classificação por grupos;
- classificação por tags;
- classificação por templates;
- classificação física/virtual;
- classificação Windows/Linux.

### Consulta 20 — Amostra de divergências das views

**Output:** `20_amostra_divergencias_views.csv`  
**Fase:** 2B  
**Risco:** Médio-Condicional  
**Estado inicial obrigatório:** `@enabled: false`

Somente se a Consulta 19 for autorizada e segura.

Retornar no máximo 50 divergências usando chave técnica mínima.

Objetivo:

- provar casos concretos em que a solução existente diverge das fontes padrão;
- preparar reconciliação humana posterior.

---

## 13. Política de heavy queries

Nenhuma consulta da Rodada 2 deve ser marcada como pesada por conveniência.

Se, durante a implementação, alguma consulta exigir custo incerto ou leitura ampla:

1. não executá-la;
2. marcar `@heavy: true` ou `@enabled: false`, conforme o caso;
3. documentar o motivo;
4. parar e solicitar autorização antes de usar `--include-heavy`.

`--include-heavy` não está autorizado por esta SPEC.

---

## 14. Processo obrigatório de implementação e execução

### Gate 0 — Git

- `git fetch --all --prune`;
- working tree limpo;
- confirmar refs;
- usar `feat/bi-003-zabbix-fase0-round2`;
- não trabalhar na `main`.

### Gate 1 — Leitura

Ler integralmente:

- `AGENTS.md`;
- `README.md`;
- `docs/SPEC-BI-003-Fase-0-Descoberta-Tecnica-Zabbix.md`;
- esta SPEC;
- `docs/ZABBIX_BI_Fase0_RELATORIO.md`;
- `sql/ZABBIX_BI_Fase0_Descoberta_MySQL.sql`.

Ler parser/safety somente se necessário.

### Gate 2 — Implementação da Rodada 2A

- criar o novo pacote SQL;
- implementar Consultas 01–14;
- deixar Consultas 15–20 desabilitadas ou ainda não materializadas até haver evidência suficiente;
- não alterar o núcleo Python.

### Gate 3 — Validação local

- executar todos os testes locais exigidos pelo repositório;
- validar o parser;
- executar `--list`;
- revisar todas as consultas uma a uma;
- garantir ausência de DML/DDL e estruturas proibidas.

### Gate 4 — Preflight

Executar:

```powershell
.\preflight.ps1
```

Somente continuar se:

- testes aprovados;
- conexão aprovada;
- transação read-only aprovada;
- nenhum erro crítico.

### Gate 5 — Execução da Rodada 2A

Executar:

```powershell
.\run_extractor.ps1
```

Sem `--include-heavy`.

Analisar:

- `manifesto.csv`;
- `manifesto.json`;
- `execucao.json`;
- CSVs;
- log;
- snapshot SQL;
- ZIP local.

Se houver qualquer `ERROR`, aplicar regra de parada.

### Gate 6 — Análise intermediária

Classificar cada conclusão como:

- Declarada;
- Observada;
- Inferida;
- Hipótese.

A partir dos CSVs 01–14:

- determinar semântica de `hosts`;
- determinar vocabulário de grupos;
- determinar vocabulário de tags;
- determinar templates relevantes;
- determinar tipos de interface;
- determinar modelo de proxy;
- determinar fontes candidatas de localização;
- revisar definições das views;
- decidir quais views podem ser executadas com segurança.

### Gate 7 — Implementação da Rodada 2B

Somente com evidência suficiente:

- implementar/ajustar Consultas 15–20;
- manter desabilitada qualquer consulta cuja semântica não esteja comprovada;
- não inventar padrões de texto;
- não avançar para histórico/eventos.

### Gate 8 — Nova validação

Repetir:

- testes;
- parser;
- `--list`;
- revisão de SQL;
- `preflight.ps1`.

### Gate 9 — Execução da Rodada 2B

Executar novamente:

```powershell
.\run_extractor.ps1
```

Sem `--include-heavy`.

Analisar integralmente a remessa.

### Gate 10 — Documentação

Somente depois das evidências:

- atualizar `docs/ZABBIX_BI_Fase0_RELATORIO.md`;
- atualizar a SPEC principal apenas nos itens comprovados;
- registrar a conta read-only como pendente enquanto não criada;
- documentar limitações e divergências;
- registrar caminhos das remessas locais sem versionar CSV/ZIP/log;
- preparar a próxima rodada sem implementá-la.

### Gate 11 — Finalização Git

- conferir diff;
- garantir que nenhum `.env`, CSV, log, ZIP ou output foi versionado;
- executar testes finais;
- criar commits coerentes;
- deixar working tree limpo;
- push da branch quando permitido pelo ambiente;
- não fazer merge na `main`.

---

## 15. Regra de parada

Parar imediatamente e pedir revisão se ocorrer:

- qualquer `ERROR` na extração;
- falha no preflight;
- necessidade de `--include-heavy`;
- necessidade de consulta histórica ampla;
- necessidade de DML/DDL;
- necessidade de executar função ou procedure;
- necessidade de alterar núcleo Python;
- custo de consulta incerto;
- retorno inesperadamente volumoso;
- view que acesse `history*` ou `trends*` e cuja execução seria necessária para continuar;
- presença inesperada de segredos;
- divergência entre SPEC e dados observados;
- impossibilidade de provar a origem de classificação/localização sem ampliar o escopo.

Não contornar a regra de parada para concluir o loop.

---

## 16. Classificação de evidências

Toda conclusão final da Rodada 2 deve usar uma destas classificações:

### Declarada

Confirmada por configuração, documentação oficial do projeto ou responsável técnico.

### Observada

Comprovada diretamente pelos CSVs/remessa extraída.

### Inferida

Conclusão lógica sustentada por uma ou mais evidências observadas.

### Hipótese

Possibilidade ainda não validada.

Nunca converter automaticamente uma hipótese de classificação em regra aprovada do BI.

---

## 17. Critérios de aceite da Rodada 2

A Rodada 2 só estará concluída quando houver evidência suficiente para responder ou declarar explicitamente a lacuna de todos os itens abaixo:

- [ ] quantidade de hosts reais monitorados;
- [ ] quantidade habilitada/desabilitada;
- [ ] distinção host/template/outros registros;
- [ ] catálogo de grupos;
- [ ] distribuição host-grupo;
- [ ] catálogo de tags;
- [ ] templates vinculados;
- [ ] interfaces por tipo;
- [ ] cobertura de agente;
- [ ] cobertura SNMP;
- [ ] proxies avaliados;
- [ ] classificação de AP;
- [ ] classificação de switch;
- [ ] classificação de servidor físico;
- [ ] classificação de servidor virtual;
- [ ] diferenciação Windows/Linux;
- [ ] origem de Unidade;
- [ ] origem de Prédio;
- [ ] origem de Sala;
- [ ] origem de Setor;
- [ ] origem de Departamento;
- [ ] completude da classificação;
- [ ] conflitos de classificação;
- [ ] completude da localização;
- [ ] estrutura das views customizadas;
- [ ] divergências views × fontes padrão;
- [ ] nenhuma consulta histórica ampla executada;
- [ ] nenhuma DML/DDL executada;
- [ ] nenhum `ERROR` nas remessas oficiais utilizadas como evidência;
- [ ] documentação atualizada;
- [ ] conta dedicada read-only continua marcada como pendente, salvo se criada externamente e comprovada;
- [ ] branch limpa e pronta para revisão.

Um item pode ser aceito como lacuna somente se a impossibilidade for documentada com evidência e sem extrapolar o escopo.

---

## 18. Resultado final esperado

Ao concluir, a Rodada 2 deverá entregar:

```text
sql/ZABBIX_BI_Fase0_Rodada2_Inventario_MySQL.sql
```

além de:

- remessa(s) local(is) auditável(is);
- manifesto CSV/JSON;
- `execucao.json`;
- snapshot do SQL;
- CSVs da Rodada 2;
- log local;
- ZIP local;
- relatório da Fase 0 atualizado;
- SPEC principal atualizada nos pontos comprovados;
- matriz documentada de classificação e localização;
- lista de divergências/lacunas;
- próximo passo recomendado para a Rodada 3.

Resultados de execução não devem ser enviados ao GitHub.

---

## 19. Próxima fase permitida após conclusão

Somente depois de a Rodada 2 ser aprovada será permitido preparar a Rodada 3:

> itens, triggers e semântica do monitoramento.

A Rodada 2 não deve implementar a Rodada 3 antecipadamente.
