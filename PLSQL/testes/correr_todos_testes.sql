-- =============================================================================
-- SCRIPT PRINCIPAL DE TESTES
-- Executa todos os testes do sistema em ordem.
-- =============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED;
SET FEEDBACK OFF;
SET TERMOUT ON;

PROMPT ========================================================================
PROMPT INICIANDO SUITE DE TESTES DO PROJETO BD2
PROMPT ========================================================================

PROMPT [1/7] Executando Testes Unitários (executar_testes.sql)...
@@executar_testes.sql

PROMPT
PROMPT -----------------------------------------------------------------------
PROMPT [2/7] Executando Lógica de Negócio (testes_logica_negocio.sql)...
@@testes_logica_negocio.sql

PROMPT
PROMPT -----------------------------------------------------------------------
PROMPT [3/7] Executando Testes Avançados (testes_avancados.sql)...
@@testes_avancados.sql

PROMPT
PROMPT -----------------------------------------------------------------------
PROMPT [4/7] Executando Testes de Limites (testes_limites.sql)...
@@testes_limites.sql

PROMPT
PROMPT -----------------------------------------------------------------------
PROMPT [5/7] Executando Regras de Avaliação (testes_regras_avaliacao.sql)...
@@testes_regras_avaliacao.sql

PROMPT
PROMPT -----------------------------------------------------------------------
PROMPT [6/7] Validando Vistas e Relatórios (testar_vistas.sql)...
@@testar_vistas.sql

PROMPT
PROMPT -----------------------------------------------------------------------
PROMPT [7/7] Gerando Dados de Demonstração Finais (demo_data.sql)...
@@demo_data.sql

PROMPT
PROMPT -----------------------------------------------------------------------

PROMPT ========================================================================
PROMPT TODOS OS TESTES FORAM EXECUTADOS.
PROMPT OS DADOS FORAM PERSISTIDOS (COMMIT).
PROMPT ========================================================================
