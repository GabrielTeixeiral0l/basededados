--- START OF FILE correr_todos_testes.sql ---

SET SERVEROUTPUT ON;
SET VERIFY OFF;

PROMPT ========================================================================
PROMPT INICIANDO SUITE DE TESTES DO PROJETO BD2 (V2 - LIMITES DE GRUPOS)
PROMPT ========================================================================

-- 1. Testes Unitários Básicos
PROMPT [1/9] Executando Testes Unitários...
@@executar_testes.sql

-- 2. Testes de Lógica de Negócio
PROMPT
PROMPT ----------------------------------------------------------------------
PROMPT [2/9] Executando Lógica de Negócio (Médias e Pagamentos)...
@@testes_logica_negocio.sql

-- 3. Testes Avançados
PROMPT
PROMPT ----------------------------------------------------------------------
PROMPT [3/9] Executando Testes Avançados (NIF, Conflitos)...
@@testes_avancados.sql

-- 4. Testes de Limites de ECTS
PROMPT
PROMPT ----------------------------------------------------------------------
PROMPT [4/9] Executando Testes de Limites de ECTS...
@@testes_limites.sql

-- 5. Testes de Regras de Avaliação (Gerais)
PROMPT
PROMPT ----------------------------------------------------------------------
PROMPT [5/9] Executando Regras de Avaliação (Hierarquia e Entregas)...
@@testes_regras_avaliacao.sql

-- 6. Teste de Limites de Alunos e Grupos (NOVO)
PROMPT
PROMPT ----------------------------------------------------------------------
PROMPT [6/9] Executando Regras de Max_Alunos e Grupos...
@@teste_max_alunos.sql

-- 7. Teste de Segurança de Logs
PROMPT
PROMPT ----------------------------------------------------------------------
PROMPT [7/9] Executando Teste de Segurança de Logs (Imutabilidade)...
@@teste_seguranca_log.sql

-- 8. Teste de Vistas
PROMPT
PROMPT ----------------------------------------------------------------------
PROMPT [8/9] Validando Vistas e Relatórios...
@@testar_vistas.sql

-- 9. Gerar Dados de Demonstração
PROMPT
PROMPT ----------------------------------------------------------------------
PROMPT [9/9] Gerando Dados de Demonstração Finais (Cenário Realista)...
@@demo_data.sql


PROMPT
PROMPT ----------------------------------------------------------------------
PROMPT ========================================================================
PROMPT TODOS OS TESTES FORAM EXECUTADOS COM SUCESSO.
PROMPT OS DADOS FORAM PERSISTIDOS (COMMIT).
PROMPT ========================================================================

COMMIT;
-- EXIT; -- Descomenta se quiseres que o SQLPlus feche sozinho no fim