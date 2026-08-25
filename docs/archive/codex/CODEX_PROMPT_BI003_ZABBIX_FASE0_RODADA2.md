# Prompt para Codex — BI-003 — Fase 0 — Rodada 2

Atue como implementador técnico autônomo e controlado do projeto `sql_extractor`, exclusivamente na **Fase 0 — Rodada 2: Inventário e Classificação do Zabbix**.

Use o **Engineering Loop** de forma contínua até concluir a rodada dentro dos critérios de aceite desta SPEC.

O loop esperado é:

```text
inspecionar → planejar → implementar → validar → executar → analisar evidências → corrigir/ajustar → revalidar → documentar → verificar conclusão
```

Não interrompa o trabalho para pedir confirmação sobre passos rotineiros já autorizados por este prompt. Pare somente nas condições explícitas de parada abaixo.

---

## REPOSITÓRIO

GitHub:

```text
esh-gilmar/sql_extractor
```

Branch principal:

```text
main
```

Branch obrigatória desta rodada:

```text
feat/bi-003-zabbix-fase0-round2
```

A branch pode já existir no remoto. Utilize-a; não recrie outra branch sem necessidade.

Nunca altere diretamente a `main`.

---

## MODELO OPERACIONAL

Esta tarefa exige raciocínio de engenharia, leitura de evidências, SQL seguro, decisões adaptativas entre Rodada 2A e 2B e verificação de múltiplos gates.

Configuração recomendada no Codex:

```text
Modelo: GPT-5.6 Sol
Reasoning effort: High
```

Não aumente para `max` por padrão. O escopo é bem especificado e o objetivo é manter precisão sem ampliar desnecessariamente a investigação.

---

## FONTE DA VERDADE

Leia integralmente antes de agir:

```text
AGENTS.md
README.md
docs/SPEC-BI-003-Fase-0-Descoberta-Tecnica-Zabbix.md
docs/SPEC-BI-003-Fase-0-Rodada-2-Inventario-Classificacao.md
docs/ZABBIX_BI_Fase0_RELATORIO.md
sql/ZABBIX_BI_Fase0_Descoberta_MySQL.sql
```

A SPEC específica da Rodada 2 é:

```text
docs/SPEC-BI-003-Fase-0-Rodada-2-Inventario-Classificacao.md
```

A SPEC principal continua sendo a fonte global da Fase 0.

Em qualquer divergência de segurança, prevalecem `AGENTS.md` e a SPEC principal.

Leia código de parser, safety ou núcleo Python somente se houver necessidade técnica concreta.

---

## BASELINE JÁ COMPROVADO

A Rodada 1 foi concluída com sucesso.

Considere como baseline documentado:

- MySQL `8.0.46-0ubuntu0.22.04.3`;
- database `zabbix`;
- schema Zabbix `7020000 / 7020004`;
- 203 tabelas base;
- 28 views;
- 272 FKs declaradas;
- nenhuma tabela base sem PK detectada;
- nenhum particionamento detectado;
- aproximadamente 17,47 GB em tabelas;
- `history`, `history_uint`, `trends` e `trends_uint` concentram aproximadamente 97,7% do tamanho;
- aproximadamente 531 registros estimados em `hosts`;
- 47 grupos;
- 601 vínculos em `hosts_groups`;
- 1.070 tags;
- 146 vínculos host-template;
- 156 interfaces;
- 43 interfaces SNMP;
- apenas 2 linhas estimadas em `host_inventory`.

Views customizadas já observadas:

```text
View_Access_Points
View_Switches
View_Servidores
View_Servidores_Fisicos
View_Servidores_Virtuais
View_Servidores_Windows
View_Servidores_Linux
```

A semântica dessas views NÃO está comprovada.

---

## OBJETIVO

Concluir integralmente a Rodada 2, produzindo evidência para responder:

1. quantos hosts são ativos monitorados reais;
2. quantos estão habilitados/desabilitados;
3. como hosts reais se diferenciam de templates e demais registros;
4. quais grupos existem;
5. como os ativos se distribuem nos grupos;
6. quais tags são utilizadas;
7. quais templates estão vinculados;
8. quais interfaces são utilizadas;
9. quais ativos usam agente;
10. quais usam SNMP;
11. se proxies são utilizados;
12. como APs são classificados;
13. como switches são classificados;
14. como servidores físicos são classificados;
15. como servidores virtuais são classificados;
16. como Windows e Linux são diferenciados;
17. de onde vêm Unidade, Prédio, Sala, Setor e Departamento;
18. quantos ativos têm classificação incompleta ou conflitante;
19. quantos têm localização incompleta;
20. quais regras estruturais sustentam as views customizadas;
21. quais divergências existem entre views, grupos, tags, templates e tabelas padrão.

---

## SEGURANÇA INEGOCIÁVEL

A conta atualmente utilizada é temporariamente a própria conta operacional do Zabbix. Seu uso foi autorizado para a Fase 0.

Isso NÃO autoriza escrita.

Obrigatório:

- somente `SELECT` ou `WITH`;
- nenhuma DML;
- nenhuma DDL;
- nenhuma procedure;
- nenhuma função com efeito colateral conhecido;
- nenhuma criação de objeto;
- nenhuma alteração de configuração;
- nenhuma criação de usuário;
- nenhuma escrita no banco;
- nenhuma execução SQL manual fora do Generic SQL Extractor;
- transação `READ ONLY`;
- parser e safety ativos;
- timeout por consulta;
- limites em amostras;
- minimização de IPs, DNS, hostnames e identificadores;
- nunca mostrar ou versionar `.env`;
- nunca enviar CSVs, logs, ZIPs ou outputs ao GitHub.

O requisito de criar um usuário dedicado read-only permanece pendente e deve continuar marcado como pendente na documentação.

---

## TABELAS HISTÓRICAS PROIBIDAS NESTA RODADA

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

Nem direta nem indiretamente por meio de uma view cuja definição revele dependência dessas estruturas.

Se uma view relevante acessar qualquer uma dessas tabelas, não execute a view. Registre apenas a dependência estrutural.

---

## FORA DE ESCOPO

Não avance para:

- reconstrução de eventos;
- `problem`;
- `event_recovery`;
- MTTR;
- MTBF;
- MTTF;
- disponibilidade oficial;
- manutenção detalhada;
- reinícios;
- análise funcional de itens/triggers;
- PostgreSQL;
- Power BI;
- API produtiva;
- MCP;
- refatoração geral do extrator.

Não faça trabalho preparatório da Rodada 3 além de registrar o próximo passo.

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

- working tree limpo;
- `main` local alinhada ao baseline esperado ou atualizada de forma segura;
- branch remota da rodada disponível;
- nenhum trabalho direto em `main`.

Faça checkout da branch:

```powershell
git switch feat/bi-003-zabbix-fase0-round2
```

Se necessário, use a forma segura equivalente para rastrear `origin/feat/bi-003-zabbix-fase0-round2`.

Se houver alteração local inesperada, PARE.

---

## ETAPA 1 — Leitura e plano

Leia todos os arquivos obrigatórios.

Depois produza para si um checklist curto das Consultas 01–20 previstas na SPEC.

Não implemente lógica de classificação baseada em suposição.

A Rodada 2 é adaptativa:

```text
Rodada 2A → analisar evidências → Rodada 2B
```

---

## ETAPA 2 — Criar o pacote SQL da Rodada 2A

Crie:

```text
sql/ZABBIX_BI_Fase0_Rodada2_Inventario_MySQL.sql
```

Implemente inicialmente as Consultas 01–14 descritas na SPEC.

Cada bloco deve conter:

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
- determinismo;
- limites em amostras;
- sem `SELECT *` irrestrito;
- sem campos secretos;
- sem IP/DNS quando não necessário;
- usar metadados antes de conteúdo.

Para Consultas 15–20:

- não invente SQL ainda se depender de valores não observados;
- pode deixar blocos documentados com `@enabled: false` somente se isso for válido para o parser;
- preferencialmente implemente-os apenas após a análise da Rodada 2A.

---

## ETAPA 3 — Revisão estática do SQL

Antes de acessar o banco:

1. leia o arquivo SQL completo;
2. confirme que não contém as tabelas históricas proibidas em consultas de conteúdo;
3. confirme ausência de DML/DDL;
4. confirme ausência de funções suspeitas;
5. confirme que nenhuma consulta de view executa conteúdo antes da definição ser analisada;
6. confirme que outputs e IDs são únicos.

Se perceber custo incerto, não execute a consulta.

---

## ETAPA 4 — Testes, parser e listagem

Execute a suíte local exigida pelo repositório.

Depois liste o pacote com a CLI, usando `--sql-file` se necessário para garantir que o novo arquivo é o pacote validado.

Exemplo:

```powershell
$env:PYTHONPATH = "$PWD\src"
.\.venv\Scripts\python.exe -m generic_sql_extractor.cli --list --sql-file sql\ZABBIX_BI_Fase0_Rodada2_Inventario_MySQL.sql
```

Se a CLI não aceitar essa combinação na versão atual, use a forma documentada no README sem alterar o núcleo.

Confirme:

- todas as consultas esperadas aparecem;
- metadados corretos;
- nenhuma consulta pesada habilitada indevidamente;
- nenhuma consulta proibida.

---

## ETAPA 5 — Preflight

Garanta que o `.env` aponta localmente para o pacote da Rodada 2, sem exibir seu conteúdo.

Execute:

```powershell
.\preflight.ps1
```

Só continue se:

- testes passarem;
- conexão passar;
- MySQL/database esperado forem confirmados;
- transação `READ ONLY` for aplicada;
- não houver `ERROR`.

Se o preflight falhar, aplique diagnóstico conservador.

Não altere o núcleo Python sem defeito comprovado e sem aplicar a regra de parada.

---

## ETAPA 6 — Executar Rodada 2A

Execute exclusivamente:

```powershell
.\run_extractor.ps1
```

Não use:

```text
--include-heavy
```

Depois localize a remessa mais recente e analise integralmente:

```text
manifesto.csv
manifesto.json
execucao.json
csv/
sql/
log correspondente
ZIP local
```

Confirme:

- 0 `ERROR`;
- outputs esperados;
- quantidade de linhas plausível;
- nenhum arquivo sensível;
- snapshot do SQL correto.

Se houver `ERROR`, PARE.

---

## ETAPA 7 — Análise das evidências 2A

Analise os CSVs sem extrapolar a evidência.

Classifique descobertas como:

```text
Declarada
Observada
Inferida
Hipótese
```

Determine especificamente:

### Hosts

- quais valores brutos de `hosts` existem;
- quais representam hosts reais;
- quais representam templates;
- quais representam outros registros;
- como habilitado/desabilitado é representado.

### Grupos

- catálogo real;
- padrões que sugerem tipo ou localização;
- cobertura;
- sobreposição.

### Tags

- chaves reais;
- valores reais;
- frequência;
- sinais de tipo, SO ou localização.

### Templates

- quais são utilizados;
- se há evidência de classificação por template.

### Interfaces

- tipos reais;
- agente;
- SNMP;
- outros;
- cobertura por host.

### Proxy

- modelo real no schema;
- cobertura;
- sem configuração sensível.

### Localização

Descubra, sem adivinhar, onde aparecem:

```text
Unidade
Prédio
Sala
Setor
Departamento
```

### Views customizadas

Para cada view relevante, registre:

- tabelas de origem;
- joins;
- filtros;
- CASEs;
- dependências;
- se acessa estrutura proibida;
- se pode ou não ser executada na Rodada 2B.

Não trate `STATUS`, `PING`, `SNMP`, `ZABBIX` ou `UPTIME` como regra aprovada do BI.

---

## ETAPA 8 — Implementar Rodada 2B

Somente após a evidência da 2A, implemente ou ajuste as Consultas 15–20 da SPEC.

### Consulta 15

Criar matriz de classificação por `hostid`, com colunas que preservem a origem do sinal:

- grupo;
- tag;
- template;
- outras fontes cadastrais comprovadas.

Classificações:

- Access Point;
- switch;
- servidor;
- físico;
- virtual;
- Windows;
- Linux.

Não usar padrões inventados.

### Consulta 16

Medir qualidade e conflitos de classificação.

### Consulta 17

Medir completude de Unidade, Prédio, Sala, Setor e Departamento somente usando fontes comprovadas.

### Consulta 18

Amostra máxima de 50 lacunas/conflitos.

### Consulta 19

Somente habilitar se as definições das views demonstrarem execução segura.

Comparar de forma agregada views × grupos × tags × templates.

### Consulta 20

Somente se Consulta 19 for segura.

Amostra máxima de 50 divergências.

Se uma view depender de `history*`/`trends*`, deixe Consultas 19/20 desabilitadas para essa view e documente a limitação.

---

## ETAPA 9 — Revalidar tudo

Depois das mudanças da 2B:

1. rode testes novamente;
2. valide parser;
3. execute `--list`;
4. releia o SQL inteiro;
5. execute `preflight.ps1` novamente.

Só então execute a Rodada 2B.

---

## ETAPA 10 — Executar Rodada 2B

Execute:

```powershell
.\run_extractor.ps1
```

Sem `--include-heavy`.

Analise integralmente a nova remessa.

Se houver qualquer `ERROR`, PARE.

Se os resultados forem volumosos de forma inesperada, PARE.

---

## ETAPA 11 — Consolidar conclusões

Monte uma matriz de conclusão para cada objetivo da Rodada 2 com:

```text
Pergunta
Resposta
Classificação da evidência
Arquivo/consulta que comprova
Limitação, se houver
```

Não é obrigatório que todas as respostas sejam positivas.

É aceitável concluir `lacuna comprovada` quando a origem não puder ser demonstrada sem sair do escopo.

---

## ETAPA 12 — Atualizar documentação

Somente após as evidências finais:

Atualize:

```text
docs/ZABBIX_BI_Fase0_RELATORIO.md
docs/SPEC-BI-003-Fase-0-Descoberta-Tecnica-Zabbix.md
```

Preserve esta SPEC específica como registro da rodada.

Documente:

- remessas utilizadas;
- status de cada consulta;
- quantidades;
- classificação de evidência;
- semântica de hosts;
- grupos;
- tags;
- templates;
- interfaces;
- SNMP/agente;
- proxies;
- classificação;
- localização;
- qualidade;
- lógica estrutural das views;
- divergências;
- limitações;
- riscos;
- ausência de histórico consultado.

Mantenha explicitamente pendente:

```text
criação/substituição por usuário de banco exclusivamente read-only
```

Não versionar:

- `.env`;
- CSVs;
- logs;
- ZIPs;
- diretórios de output.

---

## ETAPA 13 — Verificação antes de concluir

Antes de declarar conclusão, verifique todos os critérios da SPEC específica.

Confirme no mínimo:

- 0 `ERROR` nas remessas usadas como evidência;
- nenhuma DML/DDL;
- nenhuma consulta histórica ampla;
- nenhuma view insegura executada;
- nenhum `--include-heavy`;
- núcleo Python preservado;
- documentação atualizada;
- arquivos sensíveis fora do Git;
- testes finais aprovados;
- working tree final consistente.

Se algum critério não estiver atendido, continue o Engineering Loop enquanto a correção estiver dentro do escopo e for segura.

---

## ETAPA 14 — Git final

Revise:

```powershell
git status
git diff --check
git diff
```

Crie commits coerentes na branch da rodada.

Faça push da branch se o ambiente já possuir autenticação válida.

Não faça merge na `main`.

Não force push.

---

# REGRA DE PARADA OBRIGATÓRIA

Pare imediatamente e solicite revisão se ocorrer qualquer um dos casos:

- `ERROR` em consulta;
- falha crítica no preflight;
- necessidade de `--include-heavy`;
- necessidade de consultar histórico amplo;
- necessidade de DML/DDL;
- necessidade de executar função/procedure;
- necessidade de alterar o núcleo Python;
- dúvida relevante sobre custo;
- retorno inesperadamente volumoso;
- segredo ou credencial aparecendo em saída;
- view que dependa de tabela histórica proibida e cuja execução seja necessária para continuar;
- divergência entre SPEC e dados observados;
- necessidade de ampliar a rodada para itens, triggers, eventos ou manutenção.

Não contorne essas condições em nome de "finalizar".

---

# DEFINIÇÃO DE PRONTO

A Rodada 2 está pronta quando:

1. o pacote SQL da Rodada 2 existe e está validado;
2. Rodada 2A foi executada sem erro;
3. evidências 2A foram analisadas;
4. Rodada 2B foi implementada apenas com base em evidências;
5. Rodada 2B foi executada sem erro ou consultas inviáveis foram formalmente classificadas como lacuna/condicionais;
6. hosts/templates foram diferenciados;
7. habilitados/desabilitados foram quantificados;
8. grupos foram catalogados e distribuídos;
9. tags foram catalogadas;
10. templates foram analisados;
11. interfaces/agente/SNMP foram quantificados;
12. proxies foram avaliados;
13. AP/switch/servidor/físico/virtual/Windows/Linux foram classificados ou a lacuna foi comprovada;
14. Unidade/Prédio/Sala/Setor/Departamento tiveram origem comprovada ou lacuna comprovada;
15. qualidade de classificação e localização foi medida quando tecnicamente possível;
16. views customizadas tiveram estrutura documentada;
17. divergências foram medidas quando seguro;
18. nenhuma tabela histórica proibida foi consultada;
19. documentação foi atualizada;
20. usuário dedicado read-only continua corretamente marcado como pendente;
21. testes finais passaram;
22. branch ficou pronta para revisão e sem merge na `main`.

---

# SAÍDA FINAL DO CODEX

Ao concluir, apresente de forma objetiva:

1. branch e commits criados;
2. arquivos criados/alterados;
3. comandos de validação executados;
4. resultado dos testes;
5. resultado do preflight;
6. remessas locais da Rodada 2A e 2B;
7. status e linhas por consulta;
8. resumo das conclusões Declaradas/Observadas/Inferidas/Hipóteses;
9. classificações e localizações comprovadas;
10. divergências encontradas;
11. limitações ainda abertas;
12. confirmação de que nenhuma consulta histórica ampla foi executada;
13. confirmação de que não houve DML/DDL;
14. confirmação de que a conta read-only dedicada permanece pendente;
15. próximo passo recomendado, limitado à preparação da Rodada 3.
