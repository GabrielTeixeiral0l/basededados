-- =============================================================================
-- SUITE DE TESTES COMPLETA
-- Objetivo: Executar todos os cenários de teste de forma sequencial e persistente.
-- =============================================================================
SET SERVEROUTPUT ON;
SET FEEDBACK OFF;
SET VERIFY OFF;

PROMPT 
PROMPT ========================================================================
PROMPT  INICIANDO SUITE DE TESTES DO PROJETO BD2
PROMPT ========================================================================
PROMPT

-- 1. Testes Unitários Básicos (Fluxo Feliz)
PROMPT [1/6] Executando Testes Unitários (executar_testes.sql)...
@@executar_testes.sql
PROMPT ------------------------------------------------------------------------

-- 2. Lógica de Negócio (Notas, Médias e Pagamentos)
PROMPT [2/6] Executando Lógica de Negócio (testes_logica_negocio.sql)...
@@testes_logica_negocio.sql
PROMPT ------------------------------------------------------------------------

-- 3. Regras Avançadas (Conflitos, Soft-Delete, Validações)
PROMPT [3/6] Executando Testes Avançados (testes_avancados.sql)...
@@testes_avancados.sql
PROMPT ------------------------------------------------------------------------

-- 4. Limites e Restrições (ECTS, Capacidade)
PROMPT [4/6] Executando Testes de Limites (testes_limites.sql)...
@@testes_limites.sql
PROMPT ------------------------------------------------------------------------

-- 5. Vistas e Relatórios
PROMPT [5/6] Validando Vistas e Relatórios (testar_vistas.sql)...
@@testar_vistas.sql
PROMPT ------------------------------------------------------------------------

-- 6. Dados de Demonstração (Massa de dados para inspeção manual)
PROMPT [6/6] Gerando Dados de Demonstração Finais (demo_data.sql)...
@@demo_data.sql
PROMPT ------------------------------------------------------------------------

PROMPT
PROMPT ========================================================================
PROMPT  TODOS OS TESTES FORAM EXECUTADOS.
PROMPT  OS DADOS FORAM PERSISTIDOS (COMMIT).
PROMPT ========================================================================
PROMPT