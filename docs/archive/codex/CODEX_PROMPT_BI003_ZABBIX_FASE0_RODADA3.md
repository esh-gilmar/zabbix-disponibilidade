# Prompt para Codex — BI-003 — Fase 0 — Rodada 3

Atue como implementador técnico autônomo e controlado do projeto `sql_extractor`, exclusivamente na **Fase 0 — Rodada 3: Itens, Triggers e Semântica do Monitoramento do Zabbix**.

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
feat/bi-003-zabbix-fase0-round3-semantica
```

A branch já pode existir no remoto. Utilize-a e não crie outra sem necessidade.

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
docs/SPEC-BI-003-Fase-0-Rodada-2-Inventario-Classificacao.md
docs/SPEC-BI-003-Fase-0-Rodada-3-Itens-Triggers-Semantica.md
docs/ZABBIX_BI_Fase0_RELATORIO.md
sql/ZABBIX_BI_Fase0_Descoberta_MySQL.sql
sql/ZABBIX_BI_Fase0_Rodada2_Inventario_MySQL.sql
```

A SPEC operacional desta rodada é:

```text
docs/SPEC-BI-003-Fase-0-Rodada-3-Itens-Triggers-Semantica.md
```

Em divergência de segurança, prevalecem `AGENTS.md` e a SPEC principal.

Não leia ou altere o núcleo Python sem necessidade técnica concreta.

---

## BASELINE COMPROVADO

Considere como baseline documentado:

- MySQL `8.0.46-0ubuntu0.22.04.3`;
- database `zabbix`;
- schema `7020000 / 7020004`;
- 135 hosts regulares;
- 123 habilitados e 12 desabilitados;
- 352 templates;
- 46 outros registros;
- 57 grupos;
- 1.078 tags, nenhuma em host regular;
- 49 templates distintos vinculados;
- 173 vínculos de template;
- 84 hosts regulares com interface de agente;
- 48 com interface SNMP;
- 3 com ambas;
- 6 sem interface;
- nenhum proxy utilizado.

Classificação candidata observada:

```text
19 Access Points
16 switches
45 servidores
6 físicos
38 virtuais
32 Windows
12 Linux
```

Há 55 hosts sem classe principal, nenhum conflito de classe, um servidor sem físico/virtual e um sem Windows/Linux.

As classificações continuam candidatas.

As views customizadas de infraestrutura dependem de histórico e não foram executadas. Suas definições podem ser usadas apenas como pista estrutural/documental.

---

## OBJETIVO

Descobrir, sem consultar histórico ou eventos, como os sinais configurados no Zabbix representam:

- ICMP;
- disponibilidade do agente Zabbix;
- disponibilidade SNMP;
- uptime;
- CPU;
- RAM;
- storage;
- rede;
- serviços Windows;
- sistema operacional/inventário;
- triggers;
- severidades;
- funções das triggers;
- recuperação configurada;
- dependências;
- macros relevantes sem valores;
- tags de trigger;
- diferenças por classe de ativo.

Ao final, produzir uma matriz auditável:

```text
item/trigger → papel candidato no MVP → classe coberta → evidência → limitação
```

Também avaliar estruturalmente, sem aprovar definitivamente, as hipóteses:

```text
Servidores: ICMP + agente
APs/Switches: ICMP + SNMP
```

---

## SEGURANÇA INEGOCIÁVEL

A conta operacional do Zabbix continua temporariamente autorizada para a Fase 0, mas isso NÃO autoriza escrita.

Obrigatório:

- somente `SELECT` ou `WITH`;
- nenhuma DML;
- nenhuma DDL;
- nenhuma procedure;
- nenhuma função com efeito colateral conhecido;
- nenhuma criação de objeto;
- nenhuma alteração de configuração;
- nenhuma escrita no banco;
- somente Generic SQL Extractor;
- transação `READ ONLY`;
- parser/safety ativos;
- timeout por consulta;
- minimização de dados;
- nenhuma credencial em saída;
- nunca exibir ou versionar `.env`;
- nunca versionar CSV, log, ZIP ou output.

Permanece pendente:

```text
criação/substituição por usuário dedicado exclusivamente read-only
```

Não marque isso como concluído sem comprovação externa.

---

## TABELAS PROIBIDAS

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

Não avançar funcionalmente para:

```text
events
problem
event_recovery
acknowledges
alerts
maintenances
maintenances_hosts
maintenances_groups
maintenances_windows
event_suppress
```

A Rodada 3 é de configuração e semântica, não de histórico, eventos ou manutenção.

---

## MACROS E SEGREDOS

Você pode consultar:

- nome da macro;
- host/template ao qual está associada;
- cobertura;
- presença/ausência.

Você NÃO pode selecionar:

- valor da macro;
- community SNMP;
- senha;
- token;
- secret;
- PSK;
- chave privada;
- qualquer material de autenticação.

Se uma consulta precisar de valor de macro para continuar, PARE e peça revisão.

---

# ENGINEERING LOOP

## ETAPA 0 — Gate Git

Execute:

```powershell
git fetch --all --prune
git status --short --branch
git rev-parse HEAD
git rev-parse main
git rev-parse origin/main
git rev-parse origin/feat/bi-003-zabbix-fase0-round3-semantica
```

Confirme:

- working tree limpo;
- branch remota presente;
- baseline da Rodada 2 presente;
- nenhum trabalho em `main`.

Faça checkout:

```powershell
git switch feat/bi-003-zabbix-fase0-round3-semantica
```

Se ainda não houver branch local, rastreie a remota com a forma segura equivalente.

Se houver alteração local inesperada, PARE.

---

## ETAPA 1 — Leitura e plano

Leia todos os arquivos obrigatórios.

Depois faça um checklist interno das Consultas 01–22 descritas na SPEC.

A execução é adaptativa:

```text
Rodada 3A → analisar vocabulário real → Rodada 3B
```

Não implemente a 3B com chaves inventadas antes de observar a 3A.

---

## ETAPA 2 — Implementar Rodada 3A

Crie:

```text
sql/ZABBIX_BI_Fase0_Rodada3_Semantica_Monitoramento_MySQL.sql
```

Implemente inicialmente as Consultas 01–12.

Cada consulta deve possuir:

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
- somente `SELECT`/`WITH`;
- ordenação determinística;
- filtro por hosts regulares/templates relevantes quando aplicável;
- sem histórico;
- sem eventos;
- sem valores de macro;
- sem IP/DNS/hostname quando não necessários;
- sem `SELECT *` irrestrito;
- limites em catálogos/amostras quando necessário.

Consultas 13–22 devem permanecer `@enabled: false` ou não materializadas até haver evidência suficiente da 3A.

---

## ETAPA 3 — Revisão estática da 3A

Antes de acessar o banco:

1. leia o SQL inteiro;
2. procure qualquer referência a `history`, `trends`, `events`, `problem` ou `event_recovery` em consulta de conteúdo;
3. confirme ausência de DML/DDL;
4. confirme ausência de valores de macro;
5. confirme que consultas de `items`/`triggers` estão restritas ao escopo;
6. confirme outputs e IDs únicos;
7. confirme timeouts e limites.

Uma simples referência em comentário explicativo não autoriza consulta ao objeto proibido.

Se houver dúvida de custo, PARE.

---

## ETAPA 4 — Testes, parser e `--list`

Execute a suíte local exigida pelo repositório.

Valide o novo pacote no parser.

Depois liste as consultas com a CLI, usando `--sql-file` ou a forma suportada pela versão atual.

Exemplo:

```powershell
$env:PYTHONPATH = "$PWD\src"
.\.venv\Scripts\python.exe -m generic_sql_extractor.cli --list --sql-file sql\ZABBIX_BI_Fase0_Rodada3_Semantica_Monitoramento_MySQL.sql
```

Se essa combinação não for suportada, use a forma documentada no README. Não altere o núcleo apenas para adequar o comando.

Confirme:

- 01–12 habilitadas de acordo com a SPEC;
- 13–22 desabilitadas inicialmente;
- nenhuma heavy habilitada;
- metadados corretos.

---

## ETAPA 5 — Preflight 3A

Sem mostrar `.env`, garanta que o pacote configurado é o da Rodada 3.

Execute:

```powershell
.\preflight.ps1
```

Continue somente se:

- testes passarem;
- conexão for aprovada;
- database `zabbix` for confirmado;
- transação `READ ONLY` for aplicada;
- não houver erro crítico.

---

## ETAPA 6 — Executar 3A

Execute:

```powershell
.\run_extractor.ps1
```

Não use:

```text
--include-heavy
```

Analise integralmente a remessa mais recente:

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
- outputs esperados;
- volumes plausíveis;
- nenhuma credencial/segredo;
- snapshot SQL correto.

Se houver `ERROR`, PARE.

---

## ETAPA 7 — Analisar Rodada 3A

Classifique cada conclusão como:

```text
Declarada
Observada
Inferida
Hipótese
```

Determine o vocabulário real do ambiente.

### Itens

Identifique:

- status/tipos brutos;
- value_type/flags relevantes;
- chaves recorrentes;
- nomes recorrentes;
- herança/origem por template;
- diferenças por classe.

### Disponibilidade

Procure evidência real para:

- ICMP;
- agente;
- SNMP;
- uptime.

Não assuma que uma chave padrão existe. Use somente valores observados.

### Saúde

Identifique sinais candidatos de:

- CPU;
- RAM;
- storage;
- rede;
- serviços Windows.

### Inventário/contexto

Identifique itens de:

- sistema operacional;
- outros atributos de inventário.

### Triggers

Determine:

- descrições recorrentes;
- prioridades;
- status;
- funções;
- recuperação;
- correlação;
- fechamento manual;
- dependências.

### Macros

Catalogar somente nomes e cobertura. Nunca valores.

---

## ETAPA 8 — Documentação oficial quando necessária

Se códigos numéricos ou semântica técnica não puderem ser interpretados com segurança somente pelos dados, você pode consultar documentação ou código-fonte oficial do Zabbix.

Use exclusivamente fonte oficial e compatível com o schema observado.

Registre como **Declarada** e mantenha separado do que foi **Observado** no banco.

Não use documentação para inventar itens ausentes do ambiente.

---

## ETAPA 9 — Implementar Rodada 3B

Com base apenas no vocabulário observado, implemente/ajuste Consultas 13–22.

### 13 — Matriz de itens de disponibilidade

Selecionar candidatos reais de ICMP, agente, SNMP e uptime.

### 14 — Matriz de trigger → item

Relacionar somente triggers candidatas aos itens candidatos. Expressões completas podem ser retornadas apenas para esse subconjunto controlado.

### 15 — Cobertura ICMP

Medir cobertura por classe.

### 16 — Cobertura agente

Medir cobertura em servidores. Não confundir interface agente com item/trigger de disponibilidade do agente.

### 17 — Cobertura SNMP

Medir cobertura em APs e switches sem expor parâmetros sensíveis.

### 18 — Uptime

Medir existência/configuração. Não consultar valor de uptime nem detectar reboot.

### 19 — Saúde e inventário

Classificar itens observados em CPU, RAM, storage, rede, serviços, SO e outros.

### 20 — Semântica das triggers candidatas

Consolidar severidade, funções, dependências, recovery_mode, manual_close e nomes de macros.

### 21 — Qualidade semântica

Medir ausências, concorrência, itens/triggers desabilitados e lacunas por classe.

### 22 — Amostra de lacunas

Máximo 50 registros, usando chaves técnicas mínimas.

---

## ETAPA 10 — Avaliar hipóteses conceituais

Avalie estruturalmente:

```text
Servidores: ICMP + agente
APs/Switches: ICMP + SNMP
```

Classificação permitida:

```text
suportada estruturalmente
parcialmente suportada
não suportada pelos dados atuais
ambígua
```

Não declare regra oficial de disponibilidade nesta rodada.

Não calcule indisponibilidade.

---

## ETAPA 11 — Revalidar 3B

Após implementar a 3B:

1. rode testes;
2. valide parser;
3. execute `--list`;
4. releia SQL completo;
5. verifique referências proibidas;
6. execute `preflight.ps1` novamente.

Só execute se tudo estiver aprovado.

---

## ETAPA 12 — Executar 3B

Execute:

```powershell
.\run_extractor.ps1
```

Sem `--include-heavy`.

Analise a nova remessa integralmente.

Exija 0 `ERROR`.

Se houver volume inesperado, PARE.

---

## ETAPA 13 — Consolidar evidências

Monte uma matriz final para cada objetivo da SPEC:

```text
Pergunta
Resposta
Classificação da evidência
Consulta/arquivo
Limitação
```

Produza também a matriz:

```text
item/trigger → papel candidato → classe → cobertura → origem/template → evidência → limitação
```

Separe explicitamente:

```text
Disponibilidade
Saúde operacional
Inventário/contexto
```

---

## ETAPA 14 — Atualizar documentação

Somente após a remessa final limpa, atualize:

```text
docs/ZABBIX_BI_Fase0_RELATORIO.md
docs/SPEC-BI-003-Fase-0-Descoberta-Tecnica-Zabbix.md
```

Documente:

- remessas oficiais;
- status/linhas por consulta;
- itens candidatos;
- triggers candidatas;
- funções;
- severidades;
- recuperação configurada;
- dependências;
- macros somente por nome;
- tags de trigger;
- diferenças por classe;
- cobertura ICMP/agente/SNMP/uptime;
- saúde e inventário;
- lacunas/ambiguidades;
- avaliação das duas hipóteses conceituais;
- ausência de histórico/eventos consultados;
- usuário read-only dedicado ainda pendente.

Não versionar resultados brutos.

---

## ETAPA 15 — Verificação final

Antes de declarar a Rodada 3 concluída, confirme todos os critérios de aceite da SPEC.

Obrigatório:

- 0 `ERROR` nas remessas oficiais;
- nenhuma DML/DDL;
- nenhuma consulta a histórico;
- nenhuma consulta funcional a eventos;
- nenhum `--include-heavy`;
- nenhum valor de macro/segredo;
- núcleo Python preservado;
- documentação atualizada;
- testes finais aprovados;
- nenhum output versionado.

Se algum critério não estiver atendido, continue o Engineering Loop somente se a correção estiver dentro do escopo e for segura.

---

## ETAPA 16 — Git final

Revise:

```powershell
git status
git diff --check
git diff
```

Crie commits coerentes na branch da Rodada 3.

Faça push se a autenticação local já estiver disponível.

Não faça merge na `main`.

Não force push.

---

# REGRA DE PARADA OBRIGATÓRIA

Pare imediatamente e solicite revisão se ocorrer:

- qualquer `ERROR`;
- falha crítica no preflight;
- necessidade de `--include-heavy`;
- necessidade de consultar `history*`/`trends*`;
- necessidade de consultar eventos para concluir a semântica;
- necessidade de DML/DDL;
- necessidade de procedure/função com efeito colateral;
- necessidade de valor de macro ou segredo;
- necessidade de alterar núcleo Python;
- custo de consulta incerto;
- volume inesperado;
- divergência material entre SPEC e dados;
- impossibilidade de distinguir disponibilidade de saúde sem ampliar escopo;
- necessidade de avançar para eventos, recuperação, manutenção ou reinício.

Não contorne a regra de parada para finalizar.

---

# DEFINIÇÃO DE PRONTO

A Rodada 3 está pronta quando:

1. o pacote SQL da Rodada 3 existe;
2. 3A foi executada com 0 ERROR;
3. vocabulário real foi analisado;
4. 3B foi implementada somente com base em evidências;
5. 3B foi executada com 0 ERROR ou lacunas condicionais foram formalmente documentadas;
6. ICMP foi identificado ou lacuna comprovada;
7. agente foi identificado ou lacuna comprovada;
8. SNMP foi identificado ou lacuna comprovada;
9. uptime foi identificado ou lacuna comprovada;
10. CPU/RAM/storage/rede/serviços/SO foram catalogados quando presentes;
11. triggers candidatas foram mapeadas;
12. funções/severidades/recuperação/dependências foram analisadas;
13. macros foram tratadas somente por nome;
14. cobertura por classe foi medida;
15. disponibilidade foi separada de saúde e inventário;
16. hipóteses `ICMP + agente` e `ICMP + SNMP` foram avaliadas estruturalmente;
17. nenhuma tabela histórica foi consultada;
18. nenhum evento foi analisado funcionalmente;
19. documentação foi atualizada;
20. conta dedicada read-only continua corretamente pendente;
21. testes finais passaram;
22. branch ficou pronta para revisão sem merge na `main`.

---

# SAÍDA FINAL DO CODEX

Ao concluir, apresente objetivamente:

1. branch e commits;
2. arquivos criados/alterados;
3. comandos de validação;
4. testes;
5. preflight;
6. remessas 3A e 3B;
7. status e linhas por consulta;
8. itens candidatos de ICMP/agente/SNMP/uptime;
9. triggers candidatas e severidades;
10. funções/recuperação/dependências relevantes;
11. diferenças por classe;
12. matriz disponibilidade × saúde × inventário;
13. lacunas e ambiguidades;
14. avaliação estrutural de `ICMP + agente` e `ICMP + SNMP`;
15. confirmação de nenhuma consulta histórica/evento funcional;
16. confirmação de nenhuma DML/DDL/`--include-heavy`;
17. confirmação de nenhum valor de macro/segredo;
18. pendência do usuário dedicado read-only;
19. próximo passo recomendado, limitado à preparação da Rodada 4.
