# SPEC BI-003 — Fase 0 — Rodada 6: Reconciliação com Casos Reais

**Projeto:** BI-003 — MVP de Disponibilidade da Infraestrutura de TI  
**Fase:** 0 — Descoberta Técnica do Zabbix  
**Rodada:** 6 — Reconciliação de manutenção e reinícios com casos reais  
**Branch:** `feat/bi-003-zabbix-fase0-round6-reconciliation`  
**Banco:** MySQL / database `zabbix`  
**Ferramenta de banco:** Generic SQL Extractor 2.0  
**Status:** PREPARADA — AGUARDA IDENTIFICAÇÃO DOS CASOS REAIS  
**Versão:** 1.0  
**Data:** 14/08/2026

---

## 1. Autoridade

Esta SPEC operacionaliza a etapa de reconciliação com casos reais prevista na seção 7.11 da SPEC principal:

```text
docs/SPEC-BI-003-Fase-0-Descoberta-Tecnica-Zabbix.md
```

As evidências técnicas das Rodadas 1 a 5 permanecem consolidadas em:

```text
docs/ZABBIX_BI_Fase0_RELATORIO.md
```

Em qualquer divergência:

1. prevalecem `AGENTS.md` e as regras de segurança da SPEC principal;
2. evidência observada no ambiente prevalece sobre suposição;
3. evidência declarada pelo responsável pelo Zabbix/interface deve ser identificada como Declarada;
4. documentação oficial do Zabbix pode sustentar semântica de API como evidência Declarada;
5. nenhuma proximidade temporal será promovida automaticamente a causalidade;
6. nenhum `RESET_UPTIME_CANDIDATO` será promovido a reboot oficial sem reconciliação do caso;
7. nenhuma ausência de manutenção no estado atual será extrapolada para ausência histórica.

---

## 2. Baseline obrigatório das Rodadas 1–5

### 2.1 Segurança

Está comprovado:

- MySQL `8.0.46-0ubuntu0.22.04.3`;
- database `zabbix`;
- schema registrado `7020000 / 7020004`;
- transação MySQL `READ ONLY` aplicada pelo extrator;
- parser e bloqueio de colunas sensíveis ativos;
- 31 testes locais aprovados nos gates recentes;
- nenhuma DML/DDL executada;
- nenhum `--include-heavy` executado;
- núcleo Python preservado;
- usuário dedicado exclusivamente read-only ainda pendente.

A conta operacional atual permanece autorizada apenas sob as proteções do Generic SQL Extractor durante a Fase 0.

### 2.2 Eventos e recuperação

A Rodada 4 demonstrou, em amostra controlada:

```text
events(value=1)
→ event_recovery
→ events(value=0)
→ trigger
→ function
→ item
→ host
```

Também demonstrou que `problem` não é suficiente isoladamente para histórico: 224 de 249 eventos de problema da amostra já não possuíam linha correspondente em `problem`, embora 241 intervalos tenham sido reconstruídos por `event_recovery`.

A documentação oficial do Zabbix 7.2 declara que `problem.get` é voltado a problemas não resolvidos e, opcionalmente, recentemente resolvidos; para resolvidos mais antigos, deve-se usar `event.get`. Essa declaração é compatível com a limitação observada, mas não comprova por si só a política de housekeeping do ambiente.

### 2.3 Manutenção e supressão

A Rodada 5 comprovou a estrutura de manutenção, mas no estado consultado não observou registros em:

- `maintenances`;
- `maintenances_hosts`;
- `maintenances_groups`;
- `maintenances_windows`;
- `timeperiods`;
- `maintenance_tag`;
- `event_suppress`.

Os 135 hosts regulares estavam fora de manutenção no estado observado.

Isso não comprova ausência histórica de manutenção. Um caso real declarado é obrigatório para avançar a conclusão funcional.

### 2.4 Uptime e resets candidatos

A Rodada 5 identificou:

- 101 itens candidatos de uptime;
- todos com `value_type = 3`;
- tabela histórica comprovada: `history_uint`;
- índice comprovado: `PRIMARY(itemid, clock, ns)`;
- 8 itemids usados na amostra de 14 dias;
- 25 `RESET_UPTIME_CANDIDATO`;
- 13 com evento candidato de ICMP em ±30 minutos;
- 12 sem evento candidato nessa janela.

Nenhum reset foi classificado como reboot oficial.

---

## 3. Objetivo exclusivo da Rodada 6

Reconciliar evidências do banco, da interface do Zabbix e da API para casos reais previamente conhecidos, de forma a validar ou corrigir as interpretações técnicas das Rodadas 4 e 5.

Esta rodada deve priorizar exatamente três casos:

1. **M1 — manutenção programada real**;
2. **R1 — reinício conhecido de servidor**, preferencialmente com `system.uptime`;
3. **R2 — reinício/reset conhecido de ativo SNMP**, distinguindo reboot do equipamento de reset de subsistema/agente SNMP quando possível.

A rodada não deve selecionar casos aleatórios para “encaixar” nas hipóteses existentes.

---

## 4. Gate obrigatório de entrada — CASOS REAIS

Nenhuma consulta de reconciliação deve ser executada sem os três casos mínimos abaixo identificados.

### 4.1 Caso M1 — manutenção programada

Informação mínima necessária:

- host, grupo ou escopo afetado;
- data/hora aproximada de início e fim;
- evidência declarada de que foi manutenção programada;
- quando possível, identificador/nome da manutenção ou screenshot/export da interface.

### 4.2 Caso R1 — reinício de servidor

Informação mínima necessária:

- host/hostid;
- data/hora aproximada conhecida do reboot;
- origem da confirmação: equipe responsável, sistema operacional, interface Zabbix ou outro registro técnico confiável.

### 4.3 Caso R2 — ativo SNMP

Informação mínima necessária:

- host/hostid;
- data/hora aproximada conhecida do reboot/reset;
- tipo do ativo;
- quando conhecido, esclarecer se o fato foi reboot do equipamento inteiro ou apenas reset de componente/gerência/SNMP.

### 4.4 Regra de parada

Se algum dos três casos não puder ser identificado com evidência externa mínima, registrar a lacuna e solicitar ao responsável pelo projeto o dado faltante. Não substituir caso real por um `RESET_UPTIME_CANDIDATO` escolhido apenas por conveniência.

---

## 5. Fontes permitidas

A Rodada 6 pode usar três fontes, sempre distinguindo-as no relatório:

### A. Banco MySQL — Observada

Somente via Generic SQL Extractor, com consultas específicas para os IDs e janelas dos casos aprovados.

### B. Interface Zabbix — Declarada/Observada por reconciliação

A interface deve ser usada apenas para conferir o mesmo caso: manutenção, evento, trigger, host, item e linha temporal visível. Nenhuma configuração deve ser alterada.

Se o Codex não tiver acesso à interface, deve fornecer ao usuário uma lista exata de campos/telas a conferir e trabalhar com screenshot/export fornecido pelo usuário.

### C. API Zabbix — Observada via API

Permitidos somente métodos de leitura necessários à reconciliação, por exemplo:

- `apiinfo.version`;
- `host.get`;
- `item.get`;
- `history.get`;
- `event.get`;
- `problem.get` quando semanticamente aplicável;
- `maintenance.get`;
- outros métodos `*.get` somente se estritamente necessários ao caso e documentados antes do uso.

É proibido usar métodos de escrita, incluindo `*.create`, `*.update`, `*.delete`, ações de acknowledge/suppress ou qualquer chamada que modifique configuração/estado.

Tokens/chaves nunca devem ser impressos, versionados ou gravados em outputs de evidência.

---

## 6. Restrições de escopo

Não executar nesta rodada:

- busca global por eventos para encontrar “bons casos”;
- busca global em `history*`;
- `trends*`;
- consultas sem host/item/eventid e janela temporal explícitos;
- cálculo oficial de disponibilidade;
- MTTR, MTBF, MTTF ou SLA;
- consolidação mensal;
- alteração de templates, triggers, itens, hosts, manutenções ou usuários;
- criação de coletor produtivo;
- PostgreSQL;
- Power BI;
- MCP;
- mudanças no núcleo Python.

---

## 7. Princípio de minimização

Cada caso deve usar a menor janela que preserve a evidência.

Padrão inicial recomendado:

- manutenção: intervalo declarado + margem de até 2 horas antes/depois;
- reboot servidor: horário declarado ±2 horas;
- reboot/reset SNMP: horário declarado ±2 horas.

Se a evidência não aparecer, a ampliação deve ser justificada e progressiva. Não ampliar automaticamente para 14 dias ou exercício inteiro.

Preferir IDs técnicos nos outputs. Hostname poderá ser usado na etapa humana de reconciliação, mas não deve ser necessário em CSV versionável — outputs brutos continuam locais e não versionados.

---

## 8. Estratégia em três gates

### Gate 6A — Identificação e plano de reconciliação

Sem execução no banco.

Produzir uma matriz:

| Caso | Ativo técnico | Janela | Evidência externa | IDs conhecidos | Lacunas |
|---|---|---|---|---|---|

Somente avançar se os três casos estiverem adequadamente definidos, ou se o responsável autorizar explicitamente concluir algum caso como lacuna não reconciliável.

### Gate 6B — Banco controlado

Criar, somente após o 6A, um pacote específico:

```text
sql/ZABBIX_BI_Fase0_Rodada6_Reconciliacao_Casos_MySQL.sql
```

O pacote deve usar apenas os hostids/itemids/eventids e janelas aprovados.

### Gate 6C — Interface + API + matriz final

Comparar o mesmo caso nas três fontes:

```text
Banco ↔ Interface Zabbix ↔ API
```

Nenhuma divergência deve ser corrigida por suposição. Registrar exatamente onde as fontes concordam, divergem ou não possuem retenção.

---

## 9. Consultas de banco previstas após Gate 6A

O pacote da Rodada 6 deve conter no máximo as consultas necessárias abaixo, adaptadas aos três casos reais.

### M1 — manutenção

1. host/grupo e estado técnico no intervalo;
2. manutenção e vínculos por ID/escopo, se ainda presentes;
3. janelas/timeperiods, se presentes;
4. `event_suppress` somente para eventids do caso;
5. eventos candidatos do host no intervalo;
6. relação problema/recuperação no intervalo.

### R1 — servidor

7. item de `system.uptime` do host;
8. `history_uint` somente desse item no intervalo;
9. detecção local do reset por `LAG`;
10. eventos candidatos do host na mesma janela;
11. relação reset ↔ eventos, sem causalidade presumida.

### R2 — SNMP

12. item de uptime SNMP do host;
13. `history_uint` somente desse item no intervalo;
14. detecção local do reset por `LAG`;
15. eventos ICMP/SNMP candidatos do host na mesma janela;
16. relação reset ↔ eventos, distinguindo sinal de equipamento e sinal de gerência quando os dados permitirem.

### Qualidade

17. matriz de cobertura dos três casos;
18. divergências banco × evidência declarada.

Nenhuma consulta deve ser marcada `heavy` por padrão. Se o custo parecer incerto, parar antes de executar.

---

## 10. Reconciliação via API

A API deve ser usada com filtros equivalentes aos do banco.

Regras:

- consultar `apiinfo.version` e registrar a versão retornada;
- `maintenance.get` somente pelo maintenanceid/hostid/grupo conhecido, quando aplicável;
- `item.get` somente pelos hosts/itemids dos casos;
- `history.get` com `history=3`, itemids explícitos e `time_from/time_till` dos casos de uptime;
- `event.get` restrito aos hosts/triggers/eventids e janela dos casos;
- `problem.get` não deve ser tratado como fonte histórica completa;
- saída local sanitizada;
- nenhum token em console, arquivo ou commit.

Se a API não estiver disponível ou o perfil não tiver permissão de leitura, registrar como lacuna de reconciliação; não contornar a autorização.

---

## 11. Reconciliação pela interface

Para cada caso, conferir apenas informações necessárias.

### M1

- existência/nome da manutenção;
- host/grupo afetado;
- período;
- tipo da manutenção;
- se problemas aparecem como suprimidos no caso.

### R1/R2

- host correto;
- item de uptime;
- gráfico/últimos dados próximo ao horário declarado;
- evento/trigger no mesmo intervalo, se houver;
- horário apresentado na interface.

Capturas devem omitir ou mascarar dados sensíveis que não sejam necessários.

---

## 12. Critérios de conclusão por caso

Cada caso deverá terminar com uma das classificações:

- **RECONCILIADO:** banco, interface e API sustentam o fato declarado dentro da precisão esperada;
- **PARCIALMENTE_RECONCILIADO:** duas fontes sustentam o caso e a terceira possui lacuna explicada;
- **DIVERGENTE:** fontes retornam informações incompatíveis que exigem investigação;
- **NÃO_RECONCILIÁVEL:** retenção, ausência de registro ou falta de acesso impede conclusão.

### M1

Somente considerar “manutenção programada reconhecível” se o caso declarado puder ser associado a manutenção/supressão ou outra representação oficial comprovada no Zabbix.

### R1/R2

Somente considerar “reboot validado” se o reset de uptime coincidir com uma confirmação externa do reboot do ativo. Proximidade com evento ICMP/SNMP é contexto, não prova causal isolada.

---

## 13. Evidências e terminologia

Manter as classes:

- **Declarada**;
- **Observada**;
- **Inferida**;
- **Hipótese**.

A matriz final deve possuir:

| Caso | Fato declarado | Banco | Interface | API | Conclusão | Evidência | Limitação |
|---|---|---|---|---|---|---|---|

---

## 14. Segurança e regra de parada

Parar imediatamente se ocorrer:

- qualquer `ERROR` no extrator;
- qualquer consulta sem filtro específico de caso;
- necessidade de `--include-heavy`;
- necessidade de ampliar significativamente a janela;
- necessidade de DML/DDL;
- necessidade de método de API de escrita;
- exposição de token/senha/`.env`;
- necessidade de alterar o núcleo Python;
- retorno inesperadamente volumoso;
- divergência material que exija reinterpretar as Rodadas 4 ou 5;
- ausência dos identificadores mínimos dos casos reais.

---

## 15. Documentação final

Após a reconciliação, e somente após evidência suficiente:

1. atualizar `docs/ZABBIX_BI_Fase0_RELATORIO.md`;
2. atualizar a SPEC principal e o checklist da seção 7.11;
3. registrar versão da API observada;
4. registrar quais objetos/campos da API são necessários para a arquitetura produtiva;
5. preservar a pendência do usuário dedicado read-only até comprovação externa;
6. não versionar screenshots sensíveis, respostas brutas da API, CSVs, logs, ZIPs ou tokens.

---

## 16. Definition of Done

A Rodada 6 só pode ser concluída quando:

- [ ] M1 foi identificado por evidência externa mínima;
- [ ] R1 foi identificado por evidência externa mínima;
- [ ] R2 foi identificado por evidência externa mínima;
- [ ] consultas de banco foram específicas aos três casos;
- [ ] nenhum acesso histórico amplo ocorreu;
- [ ] interface foi conferida ou a lacuna foi formalmente registrada;
- [ ] API foi conferida ou a lacuna de acesso foi formalmente registrada;
- [ ] manutenção/supressão foi reconciliada ou classificada como não reconciliável;
- [ ] reboot de servidor foi reconciliado ou classificado;
- [ ] reboot/reset SNMP foi reconciliado ou classificado;
- [ ] nenhuma proximidade temporal foi tratada como causalidade automática;
- [ ] regras candidatas das Rodadas 4/5 foram confirmadas, corrigidas ou mantidas como hipóteses;
- [ ] relatório e checklist foram atualizados;
- [ ] 0 `ERROR` nas remessas oficiais;
- [ ] núcleo Python permaneceu intacto;
- [ ] nenhum segredo/output bruto foi versionado;
- [ ] usuário dedicado read-only permaneceu como pendência se ainda não criado.

---

## 17. Saída esperada

Ao final, a Fase 0 deverá possuir evidência humana e técnica suficiente para decidir se:

- manutenção programada pode ser excluída de indisponibilidade futura e por qual mecanismo;
- resets de uptime são sinal confiável de reboot para servidores e ativos SNMP;
- quais objetos da API reproduzem com segurança as evidências encontradas no banco;
- quais lacunas ainda impedem fechar a Fase 0 e entrar em `writing-plans`.
