# Prompt para Codex — BI-003 — Fase 0 — Rodada 5

Atue como implementador técnico autônomo e controlado do projeto `sql_extractor`, exclusivamente na **Fase 0 — Rodada 5: Manutenção, Supressão Programada e Reinícios do Zabbix**.

Use o **Engineering Loop** continuamente:

```text
inspecionar → planejar → implementar → validar → executar → analisar evidências → ajustar → revalidar → documentar → verificar conclusão
```

Não peça confirmação para passos rotineiros já autorizados. Pare somente nas condições explícitas da SPEC.

---

## REPOSITÓRIO E BRANCH

```text
Repositório: esh-gilmar/sql_extractor
Branch: feat/bi-003-zabbix-fase0-round5-maintenance-reboots
Main: main
```

Nunca altere diretamente `main`.

Modelo recomendado:

```text
GPT-5.6 Sol
Reasoning: High
```

---

## LEITURA OBRIGATÓRIA ANTES DE IMPLEMENTAR

Leia integralmente:

```text
AGENTS.md
README.md
docs/SPEC-BI-003-Fase-0-Descoberta-Tecnica-Zabbix.md
docs/SPEC-BI-003-Fase-0-Rodada-5-Manutencao-Supressao-Reinicios.md
docs/ZABBIX_BI_Fase0_RELATORIO.md
sql/ZABBIX_BI_Fase0_Rodada3_Semantica_Monitoramento_MySQL.sql
sql/ZABBIX_BI_Fase0_Rodada4_Eventos_Recuperacao_MySQL.sql
```

A SPEC específica da Rodada 5 define o escopo operacional. As restrições de segurança de `AGENTS.md` e da SPEC principal continuam superiores.

---

## BASELINE QUE NÃO PODE REGREDIR

Rodadas 1–4 concluídas.

A Rodada 4 comprovou em amostra controlada:

```text
events(value=1)
→ event_recovery
→ events(value=0)
→ trigger
→ function
→ item
→ host
```

A remessa oficial 4B usou:

```text
source=0
object=0
164 triggers candidatas
2026
500 eventos mais recentes
```

Foram observados 249 problemas, 241 recuperados, 8 abertos, 2 sobreposições e 1 par simultâneo SNMP + ICMP.

Não transformar essas evidências em regra oficial de disponibilidade.

---

## OBJETIVO DA RODADA 5

Responder somente:

1. como manutenção é representada no schema real;
2. como hosts/grupos/períodos/tags se relacionam à manutenção;
3. como `event_suppress` se relaciona a eventos/manutenções;
4. se existem eventos candidatos suprimidos por manutenção;
5. quais itens de uptime são tecnicamente utilizáveis;
6. qual `value_type` e tabela histórica correspondem a cada uptime candidato;
7. se reduções de uptime podem ser detectadas seletivamente;
8. quais reduções são `RESET_UPTIME_CANDIDATO`;
9. se resets candidatos têm proximidade temporal com eventos de indisponibilidade;
10. quais lacunas impedem classificar manutenção/reboot oficialmente.

Não calcular disponibilidade, MTTR, MTBF, MTTF ou SLA.

---

## SEGURANÇA

Obrigatório:

- somente `SELECT` ou `WITH`;
- transação `READ ONLY`;
- parser/safety ativos;
- sem DML/DDL/procedure/função com efeito colateral;
- sem `FOR UPDATE` ou locks;
- sem valores de macro/segredos;
- sem `.env` exposto;
- sem output bruto versionado;
- sem `--include-heavy`;
- núcleo Python preservado.

### Histórico

Esta é a primeira rodada que pode consultar valores históricos de uptime, mas somente após o gate 5A.

É proibido:

```text
history* sem itemid
trends*
histórico global
janela > 30 dias
qualquer item que não seja uptime candidato comprovado
```

A primeira amostra histórica deve usar no máximo:

```text
8 itemids
14 dias
somente uptime
```

Pode ampliar até 30 dias apenas se a primeira execução demonstrar custo baixo, seletividade, 0 ERROR e nenhum `--include-heavy`.

Se o `value_type` não apontar para `history_uint`, não escolha outra tabela histórica por memória: PARE e solicite revisão.

---

## GATE 0 — GIT

Antes de alteração local:

```powershell
git fetch --all --prune
git status --short --branch
git rev-parse HEAD
git rev-parse main
git rev-parse origin/main
git switch feat/bi-003-zabbix-fase0-round5-maintenance-reboots
```

Se houver mudança local inesperada, PARE.

---

## GATE 5A — ESTRUTURA, MANUTENÇÃO E PREPARO HISTÓRICO

Crie:

```text
sql/ZABBIX_BI_Fase0_Rodada5_Manutencao_Reinicios_MySQL.sql
```

Implemente primeiro somente as Consultas 01–13 da SPEC.

As Consultas 14–24 devem iniciar com:

```text
@enabled: false
```

A 5A deve comprovar por metadados e dados leves:

- tabelas/colunas reais de manutenção;
- índices/FKs;
- volumetria;
- manutenções cadastradas;
- vínculos host/grupo;
- períodos/janelas;
- tags;
- `event_suppress`;
- estado atual de manutenção nos hosts;
- uptime itemids candidatos;
- `value_type`;
- origem/template/família;
- índice histórico `itemid, clock` ou equivalente comprovado;
- conjunto determinístico de até 8 itemids para 5B.

Não leia valores de `history_uint` no 5A.

---

## VALIDAÇÃO 5A

Execute a suíte completa de testes.

Valide parser e `--list` usando o mecanismo suportado pelo README.

Execute:

```powershell
.\preflight.ps1
```

Somente com preflight verde:

```powershell
.\run_extractor.ps1
```

Não use `--include-heavy`.

Analise obrigatoriamente:

- `manifesto.csv`;
- `manifesto.json`;
- `execucao.json`;
- snapshot SQL;
- CSVs;
- log;
- ZIP.

Se houver qualquer `ERROR`, PARE. A remessa não é evidência oficial.

---

## ANÁLISE DO GATE 5A

Classifique evidências como:

```text
Declarada
Observada
Inferida
Hipótese
```

Antes de habilitar 5B, confirme explicitamente:

1. uptime itemids comprovados;
2. `value_type` comprovado;
3. tabela histórica comprovada;
4. índice seletivo comprovado;
5. máximo 8 itemids;
6. janela inicial máxima de 14 dias;
7. consultas históricas sem `heavy`;
8. custo aceitável.

Se qualquer item falhar, mantenha 5B histórica desabilitada e PARE para revisão.

---

## GATE 5B — SUPRESSÃO E RESET DE UPTIME

Se 5A estiver integralmente verde, adapte/habilite as Consultas 14–24 usando somente os fatos observados.

Regras obrigatórias:

- não hard-code coluna inexistente;
- não inventar semântica de maintenance/event_suppress;
- não expandir calendário complexo sem schema comprovado;
- não chamar queda de uptime de reboot;
- usar o termo `RESET_UPTIME_CANDIDATO`;
- `system.uptime` pode ser tratado como candidato forte de reinício do SO, mas continua pendente de reconciliação;
- uptime SNMP pode refletir reboot do equipamento ou reinicialização do subsistema/agente de gerenciamento;
- medir proximidade reset × evento em até ±30 minutos sem inferir causalidade;
- nenhum limiar arbitrário de queda sem evidência.

Detecção mínima:

```text
mesmo itemid
clock_atual > clock_anterior
valor_atual < valor_anterior
```

Use `LAG` somente sobre o subconjunto previamente filtrado por `itemid` e tempo.

---

## VALIDAÇÃO 5B

Após habilitar 5B:

1. revise SQL completo;
2. execute 31 testes ou a suíte completa vigente;
3. parser/`--list`;
4. preflight;
5. execute nova remessa;
6. exija 0 `ERROR`;
7. valide hashes, snapshot, manifestos, logs e ZIP;
8. confirme ausência de outputs brutos no Git.

Se a amostra de 14 dias não contiver reset e o custo for comprovadamente baixo, é permitido ampliar para no máximo 30 dias. Acima de 30 dias, PARE.

---

## DOCUMENTAÇÃO FINAL

Somente após evidência final válida, atualize:

```text
docs/ZABBIX_BI_Fase0_RELATORIO.md
docs/SPEC-BI-003-Fase-0-Descoberta-Tecnica-Zabbix.md
```

Documente:

- remessas oficiais;
- status/linhas por consulta;
- estruturas reais de manutenção;
- existência ou ausência de manutenção;
- event_suppress;
- itemids/famílias/value_type de uptime;
- janela histórica usada;
- quantidade de resets candidatos;
- distribuição por classe/família;
- proximidade com eventos;
- coincidência com manutenção/supressão;
- qualidade/lacunas;
- limitações;
- pendência do usuário dedicado read-only.

Não documente como fato o que não foi observado.

---

## REGRA DE PARADA

PARE imediatamente em qualquer destes casos:

- `ERROR`;
- `--include-heavy` necessário;
- histórico sem `itemid`;
- janela > 30 dias;
- índice insuficiente;
- volume inesperado;
- timeout;
- necessidade de tabela histórica diferente da previamente comprovada/aprovada;
- necessidade de DML/DDL/procedure;
- alteração de núcleo Python;
- coluna/tabela divergente da SPEC;
- custo incerto;
- tentativa de promover reset a reboot oficial sem reconciliação.

Não faça retry cego. Primeiro classifique a falha como código, schema, dados, segurança ou performance.

---

## GIT FINAL

Quando a rodada estiver concluída:

```powershell
git status
git diff --check
```

Confirme:

- working tree coerente;
- nenhum `.env`;
- nenhum output/CSV/log/ZIP;
- somente SQL e documentação da rodada;
- nenhum core Python sem autorização.

Faça commits objetivos e push na mesma branch.

Não faça merge em `main`.

---

## SAÍDA FINAL ESPERADA

Ao concluir, informe:

- branch;
- commits;
- arquivos alterados;
- testes;
- parser/`--list`;
- preflights;
- remessas oficiais;
- status de cada consulta;
- manutenção observada;
- supressão observada;
- uptime/value_type/tabela histórica;
- janela e itemids usados;
- resets candidatos;
- correlações temporais;
- limitações;
- confirmação de que não houve DML/DDL, histórico amplo, `--include-heavy`, segredo ou alteração do núcleo Python;
- confirmação de que o usuário dedicado read-only continua pendente;
- indicação de que o próximo passo, se aprovado, é a reconciliação com casos reais prevista na SPEC principal.