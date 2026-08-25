# Prompt para Codex — BI-003 — Fase 0 — Rodada 4

Atue como implementador técnico autônomo e controlado do projeto `sql_extractor`, exclusivamente na **Fase 0 — Rodada 4: Eventos, Problemas, Recuperação e Intervalos de Indisponibilidade do Zabbix**.

Use o **Engineering Loop** continuamente até concluir a rodada dentro dos critérios de aceite da SPEC específica.

Fluxo esperado:

```text
inspecionar → planejar → implementar → validar → executar → analisar evidências → ajustar → revalidar → documentar → verificar conclusão
```

Não peça confirmação para passos rotineiros já autorizados por este prompt. Pare somente nas condições explícitas de parada.

---

## REPOSITÓRIO

```text
esh-gilmar/sql_extractor
```

Branch principal:

```text
main
```

Branch obrigatória desta rodada:

```text
feat/bi-003-zabbix-fase0-round4-events-recovery
```

A branch pode já existir no remoto. Utilize-a e não crie outra sem necessidade.

Nunca altere diretamente `main`.

---

## MODELO RECOMENDADO

```text
Modelo: GPT-5.6 Sol
Reasoning effort: High
```

Use `High` durante toda a rodada. Não aumente para `max` por padrão.

---

## FONTE DA VERDADE

Leia integralmente antes de agir:

```text
AGENTS.md
README.md
docs/SPEC-BI-003-Fase-0-Descoberta-Tecnica-Zabbix.md
docs/SPEC-BI-003-Fase-0-Rodada-4-Eventos-Recuperacao-Intervalos.md
docs/ZABBIX_BI_Fase0_RELATORIO.md
sql/ZABBIX_BI_Fase0_Rodada3_Semantica_Monitoramento_MySQL.sql
```

A SPEC específica desta rodada é:

```text
docs/SPEC-BI-003-Fase-0-Rodada-4-Eventos-Recuperacao-Intervalos.md
```

Em qualquer divergência de segurança, prevalecem `AGENTS.md` e a SPEC principal da Fase 0.

Não implemente a partir de memória do schema do Zabbix. Descubra primeiro por metadados.

---

## BASELINE COMPROVADO

Considere como baseline documentado:

- Rodadas 1, 2 e 3 concluídas;
- 135 hosts regulares;
- 123 habilitados e 12 desabilitados;
- classificação candidata por grupos/templates;
- caminho estrutural `host → item → function → trigger` comprovado;
- triggers candidatas de disponibilidade identificadas;
- dependências de trigger observadas;
- tags de trigger observadas;
- hipótese `servidor = ICMP + agente` não suportada pela configuração atual;
- hipótese `AP/switch = ICMP + SNMP` parcialmente suportada;
- nenhuma consulta histórica, DML/DDL ou `--include-heavy` executada nas rodadas anteriores;
- conta dedicada exclusivamente read-only ainda pendente.

Não reabra escopos já encerrados sem evidência de erro material.

---

## OBJETIVO

Concluir a Rodada 4 demonstrando, com amostra controlada e reproduzível, como o Zabbix registra:

1. eventos de problema;
2. eventos de recuperação;
3. problemas ainda abertos;
4. vínculo problema → recuperação;
5. vínculo evento → trigger;
6. vínculo trigger → host;
7. início/fim de intervalos;
8. duração técnica da amostra;
9. severidade histórica;
10. reconhecimentos;
11. correlação/causa quando existente;
12. supressão;
13. dependências de trigger;
14. sobreposições de intervalos;
15. múltiplos sinais simultâneos no mesmo host;
16. lacunas que impedem converter isso em disponibilidade oficial.

A Rodada 4 deve demonstrar um **modelo candidato de reconstrução**, não calcular disponibilidade oficial.

---

## PRINCÍPIO DE SEGURANÇA MAIS IMPORTANTE

Esta rodada toca tabelas potencialmente volumosas de eventos.

Portanto:

```text
NÃO CONSULTAR EVENTOS GLOBALMENTE.
NÃO CONSULTAR PROBLEM GLOBALMENTE.
NÃO CONSULTAR HISTORY/TRENDS.
```

Qualquer consulta temporal precisa ter seletividade demonstrada por índice, universo de triggers candidatas, janela temporal e/ou `LIMIT` determinístico.

Se houver dúvida de custo, PARE.

---

## TABELAS HISTÓRICAS PROIBIDAS

Não consultar conteúdo de:

```text
history
history_uint
history_str
history_text
history_log
trends
trends_uint
```

Nem direta nem indiretamente.

---

## FORA DE ESCOPO

Não avançar para:

- disponibilidade oficial;
- MTTR;
- MTBF;
- MTTF;
- SLA;
- agregações mensais oficiais;
- manutenção programada como regra funcional;
- detecção definitiva de reinício;
- análise de uptime histórico;
- PostgreSQL;
- API produtiva;
- Power BI;
- MCP;
- refatoração geral do extrator.

Manutenção e reinícios pertencem à Rodada 5.

---

# ENGINEERING LOOP OBRIGATÓRIO

## ETAPA 0 — Gate Git

Execute:

```powershell
git fetch --all --prune
git status --short --branch
git rev-parse HEAD
git rev-parse main
git rev-parse origin/main
```

Confirme:

- working tree limpa;
- branch correta;
- baseline da Rodada 3 presente;
- nenhum trabalho em `main`.

Faça checkout de:

```powershell
git switch feat/bi-003-zabbix-fase0-round4-events-recovery
```

Se necessário, rastreie a branch remota de forma segura.

Se houver alterações locais inesperadas, PARE.

---

## ETAPA 1 — Leitura e plano

Leia integralmente todos os documentos obrigatórios.

Monte para si um checklist das Consultas 01–24 da SPEC.

Separe mentalmente a rodada em:

```text
Rodada 4A — estrutura, índices, volume e códigos brutos
→ análise de seletividade
→ Rodada 4B — reconstrução controlada
```

Não implemente lógica funcional da 4B antes de saber o schema real e os índices.

---

## ETAPA 2 — Criar pacote SQL da Rodada 4A

Crie:

```text
sql/ZABBIX_BI_Fase0_Rodada4_Eventos_Recuperacao_MySQL.sql
```

Implemente inicialmente as Consultas 01–10 da SPEC.

Cada consulta deve conter:

```sql
-- @id:
-- @output:
-- @description:
-- @heavy:
-- @enabled:
-- @timeout:
```

Requisitos:

- uma instrução por bloco;
- somente `SELECT` ou `WITH`;
- nenhum `SELECT *` irrestrito;
- nenhum scan global de eventos;
- amostras pequenas;
- ordenação por chave/indexação comprovada;
- sem conteúdo sensível;
- sem nomes de usuários;
- sem mensagens de reconhecimento;
- sem histórico/trends.

Consultas 11–24 devem permanecer `@enabled: false` até a análise da 4A, se isso for compatível com o parser.

---

## ETAPA 3 — Revisão estática

Antes de banco, releia o SQL inteiro e confirme:

- não há `history*`/`trends*`;
- não há DML/DDL;
- não há procedures;
- não há funções suspeitas;
- nenhum agrupamento global de `events` ou `problem`;
- amostras possuem `LIMIT`;
- IDs e outputs são únicos;
- 4B está desabilitada.

Se houver consulta cujo custo você não consiga justificar, não a execute.

---

## ETAPA 4 — Testes, parser e `--list`

Execute a suíte local completa exigida pelo repositório.

Valide o parser e liste o novo pacote.

Exemplo, adaptando à CLI real do projeto:

```powershell
$env:PYTHONPATH = "$PWD\src"
.\.venv\Scripts\python.exe -m generic_sql_extractor.cli --list --sql-file sql\ZABBIX_BI_Fase0_Rodada4_Eventos_Recuperacao_MySQL.sql
```

Se a sintaxe da CLI for diferente, use a forma documentada no README sem alterar o núcleo.

---

## ETAPA 5 — Preflight

Garanta localmente que o `.env` aponta para o novo pacote sem mostrar seu conteúdo.

Execute:

```powershell
.\preflight.ps1
```

Só continue se:

- testes aprovados;
- conexão aprovada;
- database esperado confirmado;
- transação `READ ONLY` aplicada;
- nenhum erro crítico.

---

## ETAPA 6 — Executar Rodada 4A

Execute:

```powershell
.\run_extractor.ps1
```

Não use `--include-heavy`.

Depois analise integralmente:

```text
manifesto.csv
manifesto.json
execucao.json
csv/
sql/
log
ZIP local
```

Exija:

- 0 `ERROR`;
- outputs plausíveis;
- snapshot SQL correto;
- nenhuma credencial;
- nenhum histórico acessado.

Se houver `ERROR`, PARE.

---

## ETAPA 7 — Gate obrigatório de seletividade

Antes de habilitar qualquer consulta 4B, analise e documente para si:

### Estrutura

- colunas reais de `events`;
- colunas reais de `problem`;
- colunas reais de `event_recovery`;
- estruturas reais de reconhecimentos/supressão/correlação.

### Índices

Confirme quais índices sustentam acesso por:

- `eventid`;
- `objectid`;
- `source`;
- `object`;
- `clock`;
- eventids auxiliares.

### Volumetria

Confirme tamanho e linhas estimadas.

### Semântica bruta

Descubra, sem presumir:

- códigos de `source`;
- códigos de `object`;
- códigos de `value`;
- como `objectid` se comporta nos eventos candidatos.

### Caminhos

Confirme se os dados suportam:

```text
event → trigger
problem event → event_recovery → recovery event
trigger → host
```

### Recorte temporal

Defina uma janela segura:

- no máximo exercício vigente;
- preferencialmente menor se suficiente;
- limitada ao universo de triggers candidatas;
- com índices adequados.

Se qualquer parte crítica não for comprovada, PARE.

---

## ETAPA 8 — Implementar Rodada 4B

Somente depois do gate de seletividade, implemente/ajuste as Consultas 11–24.

### Universo

Comece pelas triggers candidatas da Rodada 3, reconstruídas a partir da configuração atual.

Não comece por todos os eventos.

### Consulta 11

Amostra máxima de 500 eventos candidatos.

### Consulta 12

Reconstrução problema → recuperação, com início/fim e duração técnica apenas quando houver recuperação.

### Consulta 13

Mapeamento evento → trigger → host, preferindo IDs técnicos.

### Consulta 14

Problemas abertos, máximo 200.

### Consulta 15

Comparar severidade histórica com prioridade atual da trigger.

### Consulta 16

Reconhecimentos agregados. Não retornar nome de usuário nem comentário.

### Consulta 17

Correlação/causa apenas pelos campos realmente observados.

### Consulta 18

Supressão somente para eventids da amostra.

### Consulta 19

Dependências da trigger; não excluir evento automaticamente.

### Consulta 20

Sobreposição de intervalos no mesmo host, máximo 100 pares.

### Consulta 21

Múltiplos sinais simultâneos no mesmo host.

### Consulta 22

Qualidade da reconstrução.

### Consulta 23

Amostra máxima de 50 anomalias técnicas.

### Consulta 24

Matriz compacta do modelo reconstruído.

---

## ETAPA 9 — Revalidar Rodada 4B

Depois das alterações:

1. rode testes novamente;
2. valide parser;
3. execute `--list`;
4. releia o SQL completo;
5. confira limites e índices;
6. execute `preflight.ps1` novamente.

Só então execute 4B.

---

## ETAPA 10 — Executar Rodada 4B

Execute:

```powershell
.\run_extractor.ps1
```

Sem `--include-heavy`.

Exija 0 `ERROR`.

Se houver timeout, volume inesperado ou plano de custo duvidoso, PARE.

---

## ETAPA 11 — Analisar evidências

Classifique cada conclusão como:

```text
Declarada
Observada
Inferida
Hipótese
```

Determine, no mínimo:

- como o problema começa;
- como a recuperação é ligada;
- como aberto/fechado é identificado;
- como evento liga a trigger;
- como trigger liga ao host;
- onde fica severidade histórica;
- como acknowledgements aparecem;
- como supressão aparece;
- como dependências aparecem;
- se há sobreposição;
- se há múltiplos sinais simultâneos;
- quais anomalias existem.

Não chame duração da amostra de MTTR.

Não chame intervalo reconstruído de indisponibilidade oficial.

---

## ETAPA 12 — Documentar

Atualize somente depois das evidências finais:

```text
docs/ZABBIX_BI_Fase0_RELATORIO.md
docs/SPEC-BI-003-Fase-0-Descoberta-Tecnica-Zabbix.md
```

Registre:

- remessas 4A/4B;
- status e linhas por consulta;
- índices utilizados como justificativa de seletividade;
- limites temporais e de amostra;
- códigos brutos observados;
- relação problema/recuperação;
- problemas abertos;
- duração técnica;
- severidade histórica;
- reconhecimento;
- correlação;
- supressão;
- dependências;
- sobreposição;
- múltiplos sinais;
- qualidade;
- limitações.

Mantenha pendente:

```text
criação/substituição por usuário de banco exclusivamente read-only
```

Não versionar outputs brutos.

---

## ETAPA 13 — Verificação de conclusão

Antes de declarar Rodada 4 concluída, confira todos os critérios da SPEC.

Confirme:

- 0 `ERROR` nas remessas oficiais;
- nenhuma consulta global de eventos/problemas;
- nenhuma history/trends;
- nenhuma DML/DDL;
- nenhum `--include-heavy`;
- nenhuma exposição sensível;
- núcleo Python preservado;
- documentação atualizada;
- testes finais aprovados.

Se algo seguro e dentro do escopo ainda estiver incompleto, continue o Engineering Loop.

Se a única forma de concluir for ampliar risco/escopo, registre lacuna e aplique regra de parada.

---

## ETAPA 14 — Git final

Execute:

```powershell
git status
git diff --check
git diff
```

Crie commits coerentes.

Faça push da branch se a autenticação já estiver disponível.

Não faça merge em `main`.

Não force push.

---

# REGRA OBRIGATÓRIA DE PARADA

Pare e peça revisão se ocorrer qualquer um destes casos:

- `ERROR` em remessa candidata a oficial;
- preflight crítico falhar;
- necessidade de `--include-heavy`;
- índice inadequado para consulta temporal;
- dúvida material de custo;
- necessidade de scan global de `events` ou `problem`;
- necessidade de history/trends;
- necessidade de DML/DDL;
- necessidade de procedure/função com efeito colateral;
- necessidade de alterar núcleo Python;
- timeout;
- volume inesperado;
- segredo/conteúdo sensível inesperado;
- `source/object` não sustentar vínculo com trigger;
- `problem/event_recovery` não sustentar o modelo esperado;
- necessidade de incluir manutenção ou reinício;
- divergência material entre SPEC e dados.

Não contorne essas condições para "terminar" a rodada.

---

# DEFINIÇÃO DE PRONTO

A Rodada 4 está pronta quando:

1. o pacote SQL existe e está validado;
2. 4A foi executada sem erro;
3. estrutura, índices, volumetria e códigos brutos foram analisados;
4. seletividade da 4B foi demonstrada;
5. 4B foi executada sem erro ou lacunas foram formalizadas;
6. problema → recuperação foi demonstrado ou classificado como lacuna;
7. evento → trigger → host foi demonstrado;
8. aberto/fechado foi demonstrado;
9. início/fim/duração técnica foram demonstrados em amostra;
10. severidade histórica foi avaliada;
11. reconhecimentos foram avaliados;
12. correlação foi avaliada quando existente;
13. supressão foi avaliada;
14. dependências foram avaliadas;
15. sobreposições foram avaliadas;
16. múltiplos sinais simultâneos foram avaliados;
17. qualidade/anomalias foram documentadas;
18. nenhuma consulta global/histórica proibida foi executada;
19. documentação foi atualizada;
20. conta dedicada read-only continua corretamente pendente;
21. testes passaram;
22. branch está limpa e pronta para revisão.

---

# SAÍDA FINAL DO CODEX

Ao concluir, apresente objetivamente:

1. branch e commits;
2. arquivos criados/alterados;
3. testes/parser/`--list`;
4. preflight;
5. remessas 4A/4B;
6. status/linhas por consulta;
7. evidência de seletividade e índices;
8. modelo problema → recuperação;
9. modelo evento → trigger → host;
10. quantidade de problemas recuperados/abertos na amostra;
11. duração técnica e suas limitações;
12. severidade histórica;
13. reconhecimentos;
14. correlação;
15. supressão;
16. dependências;
17. sobreposições/múltiplos sinais;
18. lacunas/anomalias;
19. confirmação de ausência de history/trends, DML/DDL e `--include-heavy`;
20. confirmação de que usuário dedicado read-only continua pendente;
21. próximo passo limitado à preparação da Rodada 5.
