# Prompt para Codex — BI-003 — Fase 0 — Rodada 6

Atue como implementador técnico autônomo e controlado do projeto `sql_extractor`, exclusivamente na **Fase 0 — Rodada 6: Reconciliação com Casos Reais**.

Use o Engineering Loop:

```text
inspecionar → planejar → validar entrada → implementar → validar → executar → reconciliar → documentar → verificar conclusão
```

Não avance por suposição. Esta rodada depende de casos reais previamente conhecidos.

---

## REPOSITÓRIO

```text
esh-gilmar/sql_extractor
```

Branch obrigatória:

```text
feat/bi-003-zabbix-fase0-round6-reconciliation
```

Nunca altere diretamente `main`.

Modelo recomendado:

```text
GPT-5.6 Sol
Reasoning: High
```

---

## LEITURA OBRIGATÓRIA

Leia integralmente antes de qualquer execução:

```text
AGENTS.md
README.md
docs/SPEC-BI-003-Fase-0-Descoberta-Tecnica-Zabbix.md
docs/SPEC-BI-003-Fase-0-Rodada-6-Reconciliacao-Casos-Reais.md
docs/ZABBIX_BI_Fase0_RELATORIO.md
sql/ZABBIX_BI_Fase0_Rodada4_Eventos_Recuperacao_MySQL.sql
sql/ZABBIX_BI_Fase0_Rodada5_Manutencao_Reinicios_MySQL.sql
```

A SPEC específica da Rodada 6 define o escopo operacional. `AGENTS.md` e a SPEC principal continuam superiores em segurança.

---

## BASELINE QUE NÃO PODE REGREDIR

Rodadas 1 a 5 estão concluídas.

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

A Rodada 5 comprovou:

- famílias candidatas de uptime;
- `value_type=3` nos 101 candidatos observados;
- `history_uint` como tabela aplicável aos candidatos usados;
- índice `PRIMARY(itemid, clock, ns)`;
- 25 `RESET_UPTIME_CANDIDATO` em janela de 14 dias;
- nenhuma manutenção/supressão observada no estado consultado.

Não transforme essas evidências em regras oficiais sem reconciliação.

---

## GATE 0 — GIT

Antes de alterar qualquer arquivo:

```powershell
git fetch --all --prune
git status --short --branch
git rev-parse HEAD
git rev-parse main
git rev-parse origin/main
git switch feat/bi-003-zabbix-fase0-round6-reconciliation
```

Se a branch existir apenas no remoto, use o equivalente seguro com `--track`.

Pare se houver alterações locais inesperadas.

---

## GATE 1 — CASOS REAIS OBRIGATÓRIOS

Antes de criar SQL, chamar API ou consultar histórico, verifique se existem três casos reais mínimos:

### M1 — manutenção programada

Necessário:

- host/grupo/escopo;
- início e fim aproximados;
- confirmação externa de que foi manutenção programada;
- se possível, nome/ID da manutenção ou screenshot/export da interface.

### R1 — reboot conhecido de servidor

Necessário:

- host ou hostid;
- horário aproximado do reboot;
- fonte externa da confirmação.

### R2 — reboot/reset conhecido de ativo SNMP

Necessário:

- host ou hostid;
- tipo do ativo;
- horário aproximado;
- fonte externa da confirmação;
- se conhecido, informar se foi reboot do equipamento ou somente reset de componente/gerência/SNMP.

### REGRA

Se esses dados não estiverem disponíveis, **PARE** e peça ao responsável pelo projeto somente os dados faltantes.

Não escolha um `RESET_UPTIME_CANDIDATO` da Rodada 5 como “caso conhecido” apenas para completar a rodada.

Produza antes de executar qualquer consulta:

| Caso | Ativo | Janela proposta | Evidência externa | IDs conhecidos | Lacunas |
|---|---|---|---|---|---|

---

## GATE 2 — PLANO DE MINIMIZAÇÃO

Para cada caso, planeje a menor janela necessária.

Padrão inicial:

```text
M1: intervalo declarado + até 2h de margem
R1: horário declarado ±2h
R2: horário declarado ±2h
```

Não amplie automaticamente para 14 dias ou ano inteiro.

Defina previamente:

- hostid;
- itemid de uptime quando aplicável;
- triggerids/eventids relevantes quando conhecidos;
- `time_from` / `time_till`;
- índices que sustentam o acesso.

---

## GATE 3 — SQL ESPECÍFICO DOS CASOS

Somente após Gate 1 e Gate 2, criar:

```text
sql/ZABBIX_BI_Fase0_Rodada6_Reconciliacao_Casos_MySQL.sql
```

O pacote deve conter apenas consultas necessárias aos três casos e usar IDs/janelas explícitas.

Nenhuma consulta global de `events`, `problem`, `history*` ou `trends*`.

Cada consulta deve possuir:

```sql
-- @id:
-- @output:
-- @description:
-- @heavy: false
-- @enabled: true|false
-- @timeout:
```

Se uma consulta parecer pesada ou exigir `@heavy: true`, **PARE** para revisão; `--include-heavy` não está autorizado.

---

## ESCOPO SQL ESPERADO

### M1

- host/grupo e intervalo declarado;
- manutenção/vínculos/timeperiods somente se identificadores existirem ou a estrutura ainda retiver o caso;
- `event_suppress` somente para eventids do caso;
- eventos candidatos do host dentro da janela;
- problema/recuperação somente dentro da janela.

### R1

- item de `system.uptime` do servidor;
- `history_uint` somente do itemid e janela do caso;
- reset por `LAG`;
- eventos candidatos na mesma janela;
- proximidade reset/evento como contexto, sem causalidade automática.

### R2

- item de uptime SNMP do ativo;
- `history_uint` somente do itemid e janela do caso;
- reset por `LAG`;
- eventos ICMP/SNMP na mesma janela;
- distinguir, quando os dados permitirem, uptime do equipamento e uptime de subsistema/gerência.

---

## GATE 4 — TESTES E PREFLIGHT

Antes da execução:

1. executar a suíte completa;
2. exigir 31/31 ou quantidade atual equivalente sem regressão;
3. validar parser;
4. executar `--list` com o novo SQL;
5. revisar consultas e filtros;
6. executar `preflight.ps1`;
7. confirmar MySQL/database `zabbix`;
8. confirmar transação `READ ONLY`;
9. confirmar ausência de segredos/`.env` em output.

Qualquer falha: parar.

---

## GATE 5 — EXECUÇÃO DE BANCO

Executar pelo fluxo oficial do Generic SQL Extractor.

Não usar:

```text
--include-heavy
```

Após a remessa, revisar:

- `manifesto.csv`;
- `manifesto.json`;
- `execucao.json`;
- CSVs;
- snapshot SQL;
- log;
- ZIP.

Se houver qualquer `ERROR`, **PARE**. A remessa com erro não é evidência oficial.

---

## GATE 6 — API ZABBIX

A API é somente leitura nesta rodada.

Primeiro:

```text
apiinfo.version
```

Registre a versão observada.

Métodos de leitura permitidos quando necessários:

```text
host.get
item.get
history.get
event.get
problem.get
maintenance.get
```

Outros `*.get` somente se necessários ao caso e justificados antes do uso.

Nunca usar:

```text
*.create
*.update
*.delete
event.acknowledge
qualquer método que altere estado/configuração
```

### Regras da API

- credencial/token somente em variável de ambiente/local seguro;
- nunca imprimir token;
- nunca salvar token em arquivo versionável;
- outputs brutos permanecem locais;
- filtros devem equivaler ao caso do banco;
- `history.get` para os itens de uptime deve usar `history=3`, itemids explícitos e `time_from/time_till`;
- `problem.get` não deve ser tratado como histórico completo de problemas resolvidos;
- se a API negar acesso, registrar a lacuna e não tentar contornar permissões.

---

## GATE 7 — INTERFACE ZABBIX

Não alterar nenhuma configuração.

Se não houver acesso navegável pelo Codex, peça ao usuário screenshots ou confirmação dos campos exatos.

### M1 — conferir

- manutenção;
- escopo host/grupo;
- período;
- tipo;
- indicação de supressão quando visível.

### R1/R2 — conferir

- host;
- item de uptime;
- gráfico/últimos valores na janela;
- evento/trigger associado quando houver;
- horário exibido pela interface.

Não peça screenshots com dados desnecessariamente sensíveis.

---

## GATE 8 — RECONCILIAÇÃO

Para cada caso, gerar:

| Caso | Fato declarado | Banco | Interface | API | Conclusão | Limitação |
|---|---|---|---|---|---|---|

Classificação permitida:

```text
RECONCILIADO
PARCIALMENTE_RECONCILIADO
DIVERGENTE
NÃO_RECONCILIÁVEL
```

### M1

Somente declarar manutenção programada tecnicamente reconhecível se houver associação comprovada com manutenção/supressão ou mecanismo oficial identificado.

### R1/R2

Somente promover `RESET_UPTIME_CANDIDATO` a reboot validado quando existir confirmação externa do reboot do ativo.

Evento ICMP/SNMP próximo não é prova causal isolada.

---

## DOCUMENTAÇÃO OFICIAL ZABBIX — USO CORRETO

Use a documentação oficial da versão 7.2 como evidência Declarada para semântica da API.

Pontos relevantes já conhecidos e que devem ser verificados na fonte oficial se forem usados na conclusão:

- `maintenance.get` recupera manutenções e pode filtrar por maintenanceid, hostid e groupid;
- `history.get` permite filtrar por `itemids`, `time_from`, `time_till` e tipo de histórico;
- `event.get` recupera eventos por filtros controlados;
- `problem.get` é voltado a problemas não resolvidos e, opcionalmente, recentemente resolvidos; eventos resolvidos mais antigos devem ser obtidos por `event.get`.

Não use documentação como substituto da evidência real do caso.

---

## DOCUMENTAÇÃO FINAL

Somente após concluir os três casos:

- atualizar `docs/ZABBIX_BI_Fase0_RELATORIO.md`;
- atualizar `docs/SPEC-BI-003-Fase-0-Descoberta-Tecnica-Zabbix.md`;
- marcar checklist da reconciliação apenas conforme evidência;
- registrar versão da API observada;
- documentar objetos/campos de API necessários à arquitetura produtiva;
- manter usuário dedicado read-only como pendente se ainda não houver comprovação.

Não versionar:

- CSVs;
- ZIPs;
- logs;
- respostas brutas da API;
- screenshots sensíveis;
- `.env`;
- tokens.

---

## REGRA DE PARADA

Pare imediatamente em qualquer um destes casos:

- caso real não identificado adequadamente;
- qualquer `ERROR` do extrator;
- consulta sem filtro específico de caso;
- custo ou volume inesperado;
- necessidade de `--include-heavy`;
- necessidade de ampliar muito a janela;
- DML/DDL;
- método de API de escrita;
- token/segredo exposto;
- alteração necessária no núcleo Python;
- divergência material que altere interpretação das Rodadas 4 ou 5.

Não corrija silenciosamente uma divergência funcional.

---

## GIT FINAL

Se e somente se a rodada estiver concluída:

1. rodar testes finais;
2. revisar `git diff`;
3. confirmar que nenhum output bruto/segredo foi incluído;
4. commit apenas SQL e documentação necessários;
5. push para a mesma branch;
6. não fazer merge;
7. não usar force push.

---

## SAÍDA FINAL DO CODEX

Ao encerrar, informe:

- branch e commits;
- três casos reconciliados;
- janelas usadas;
- remessa oficial de banco;
- status das consultas;
- versão da API observada;
- métodos API usados;
- resultado banco × interface × API de cada caso;
- quais `RESET_UPTIME_CANDIDATO` foram ou não promovidos a reboot validado;
- tratamento da manutenção programada;
- divergências/lacunas;
- confirmação de ausência de consultas amplas, DML/DDL, `--include-heavy` e segredos;
- estado do usuário dedicado read-only;
- se a Fase 0 está pronta ou não para fechamento e `writing-plans`.
