# Documentação de Implementação PL/SQL - Projeto BD2

Este documento resume todos os componentes de lógica de servidor (Server-Side Logic) implementados no projeto, organizados por área funcional.

## 1. Infraestrutura e Automação de Dados
**Ficheiros:** `1_auto_increment.sql`, `9_data_formatting.sql`, `sequences.sql`

*   **Identificadores Automáticos:** Todas as tabelas principais utilizam sequências (`SEQ_*`) para gerar IDs automaticamente (`BEFORE INSERT`).
*   **Formatação Automática:**
    *   **Emails:** Convertidos automaticamente para minúsculas.
    *   **Nomes:** Convertidos para *Title Case* (Iniciais maiúsculas).
    *   **Códigos (Cursos/UCs):** Convertidos para maiúsculas e sem espaços extra.
*   **Número de Aluno:** Geração automática sequencial (ex: `2025000001`) separada do ID interno.

## 2. Integridade e Regras de Negócio (Triggers Complexos)
**Ficheiros:** `5_integrity_triggers.sql`, `10_pkg_constantes.sql`, `12_pkg_validacao.sql`

*   **Validação de Notas:** Impede inserção de notas fora do intervalo 0-20.
*   **Gestão de Horários:** Deteta e alerta sobre **sobreposição de aulas** (mesma sala ou mesmo docente no mesmo horário).
*   **Capacidade de Turmas:** Monitoriza o limite de alunos (`max_alunos`) e emite alertas se excedido.
*   **Regras Financeiras:**
    *   A função `FUN_IS_DEVEDOR` verifica pagamentos em atraso.
    *   Alerta se um aluno devedor tentar realizar inscrições.
*   **Regras Académicas:**
    *   **Limite de ECTS:** Valida se o aluno excede 72 ECTS num ano letivo.
    *   **Plano de Estudos:** Verifica se a UC pertence efetivamente ao curso do aluno.
    *   **Avaliações:** Garante que a soma dos pesos das avaliações não excede 100%.
*   **Validação de Documentos:** Validação algorítmica rigorosa de **NIF** e **Cartão de Cidadão** (configurável em `PKG_CONSTANTES`).

## 3. Motor de Cálculo de Notas (Agregação)
**Ficheiros:** `11_pkg_buffer_nota.sql`, `5_integrity_triggers.sql`

*   **Cálculo Automático:** Ao lançar/alterar uma nota parcial, o sistema recalcula automaticamente:
    1.  A nota da avaliação "Pai" (se existir).
    2.  A nota final da Inscrição (baseada nos pesos).
*   **Prevenção de Erros:** Utilização de um pacote de *Buffer* e flags de controlo (`g_a_calcular`) para evitar o erro de "Mutating Table" e recursividade infinita.

## 4. Módulos Funcionais (Packages)
**Ficheiro:** `6_functional_packages.sql`

### Tesouraria (`PKG_TESOURARIA`)
*   **Gerar Plano:** Cria automaticamente as parcelas de propinas baseadas no valor do curso e número de prestações.
*   **Processar Pagamento:** Liquida prestações e aplica automaticamente uma **multa de 10%** se o pagamento for feito após o vencimento.

### Gestão de Dados (`PKG_GESTAO_DADOS`)
*   **Soft Delete:** Permite que registos sejam marcados como inativos (`status=0`) em vez de serem apagados fisicamente, preservando o histórico.
*   **Logging Centralizado:** Procedimentos padronizados para registar erros e alertas.

## 5. Auditoria e Rastreabilidade
**Ficheiros:** `0_pkg_config_audit.sql`, `2_audit_and_maintenance.sql`

*   **Timestamp Automático:** Coluna `updated_at` atualizada automaticamente em qualquer alteração.
*   **Auditoria Forense (Notas):** Registo detalhado na tabela `LOG` de quem alterou uma nota, o valor antigo e o novo valor.
*   **Configuração Dinâmica:** O pacote `PKG_CONFIG_LOG` permite ativar/desativar logs por tabela sem alterar o código dos triggers.

## 6. Reporting e Vistas
**Ficheiro:** `7_views_functions.sql`

*   **`VW_PAUTA_TURMA`:** Vista consolidada para consulta rápida de notas finais e aprovações por turma.
*   **`VW_ALERTA_ASSIDUIDADE`:** Identifica automaticamente alunos com percentagem de faltas superior a 25%.

## 7. Estratégia de Testes (Persistente)
**Pasta:** `PLSQL/testes/`

*   **Testes Unitários:** Validação básica de inserções.
*   **Testes de Lógica:** Verificação matemática de médias e pagamentos.
*   **Testes de Limites:** Tentativa de quebra de regras (ECTS excessivos, Turmas cheias).
*   **Testes Avançados:** Verificação de *Soft-Delete* e conflitos de horário.
*   **Demo Data:** Geração de dados fictícios para demonstração visual das vistas.
