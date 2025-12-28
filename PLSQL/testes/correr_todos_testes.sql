
SET SERVEROUTPUT ON;
SET VERIFY OFF;

PROMPT ========================================================================
PROMPT INICIANDO SUITE DE TESTES DO PROJETO BD2 (V2 - LIMITES DE GRUPOS)
PROMPT ========================================================================

-- 1. Testes Unitários Básicos
PROMPT [1/12] Executando Testes Unitários...
@@executar_testes.sql

-- 1.1. Testes de Validação de Dados
PROMPT
PROMPT ----------------------------------------------------------------------
PROMPT [2/12] Executando Validação e Formatação de Dados...
@@testes_validacao_dados.sql

-- 1.2. NOVO: Testes de Integridade Específicos (SALA, AULA)
PROMPT
PROMPT ----------------------------------------------------------------------
PROMPT [3/13] Executando Testes de Integridade da Tabela SALA...
@@testes_tabela_sala.sql

PROMPT
PROMPT ----------------------------------------------------------------------
PROMPT [3b/19] Executando Testes de Integridade da Tabela TURMA...
@@testes_tabela_turma.sql

PROMPT
PROMPT ----------------------------------------------------------------------
PROMPT [4/14] Executando Testes de Integridade da Tabela AULA...
@@testes_tabela_aula.sql

PROMPT
PROMPT ----------------------------------------------------------------------
PROMPT [5/15] Executando Testes de Integridade da Tabela AVALIACAO...
@@testes_tabela_avaliacao.sql

PROMPT
PROMPT ----------------------------------------------------------------------
PROMPT [6/16] Executando Testes de Integridade da Tabela CURSO...
@@testes_tabela_curso.sql

PROMPT
PROMPT ----------------------------------------------------------------------
PROMPT [7/17] Executando Testes de Integridade da Tabela DOCENTE...
@@testes_tabela_docente.sql

PROMPT
PROMPT ----------------------------------------------------------------------
PROMPT [8/18] Executando Testes de Integridade da Tabela ESTUDANTE...
@@testes_tabela_estudante.sql

PROMPT
PROMPT ----------------------------------------------------------------------
PROMPT [9/19] Executando Testes de Integridade da Tabela ENTREGA...
@@testes_tabela_entrega.sql

PROMPT
PROMPT ----------------------------------------------------------------------
PROMPT [10/19] Executando Testes de Integridade da Tabela ESTUDANTE_ENTREGA...
@@testes_tabela_estudante_entrega.sql

-- 1.3. Testes Funcionais Extra
PROMPT
PROMPT ----------------------------------------------------------------------
PROMPT [11/19] Executando Testes Funcionais Extra (Multas, Logs)...
@@testes_funcionais_extra.sql

-- 2. Testes de Lógica de Negócio
PROMPT
PROMPT ----------------------------------------------------------------------
PROMPT [12/19] Executando Lógica de Negócio (Médias e Pagamentos)...
@@testes_logica_negocio.sql

-- 3. Testes Avançados
PROMPT
PROMPT ----------------------------------------------------------------------
PROMPT [13/19] Executando Testes Avançados (NIF, Conflitos)...
@@testes_avancados.sql

-- 4. Testes de Limites de ECTS
PROMPT
PROMPT ----------------------------------------------------------------------
PROMPT [14/19] Executando Testes de Limites de ECTS...
@@testes_limites.sql

-- 5. Testes de Regras de Avaliação (Gerais)
PROMPT
PROMPT ----------------------------------------------------------------------
PROMPT [15/19] Executando Testes de Regras de Avaliação (Hierarquia e Entregas)...
@@testes_regras_avaliacao.sql

-- 6. Teste de Limites de Alunos e Grupos (NOVO)
PROMPT
PROMPT ----------------------------------------------------------------------
PROMPT [16/19] Executando Regras de Max_Alunos e Grupos...
@@teste_max_alunos.sql

-- 7. Teste de Segurança de Logs
PROMPT
PROMPT ----------------------------------------------------------------------
PROMPT [17/19] Executando Teste de Segurança de Logs (Imutabilidade)...
@@teste_seguranca_log.sql

-- 8. Teste de Vistas
PROMPT
PROMPT ----------------------------------------------------------------------
PROMPT [18/19] Validando Vistas e Relatórios...
@@testar_vistas.sql

-- 9. Gerar Dados de Demonstração
PROMPT
PROMPT ----------------------------------------------------------------------
PROMPT [19/19] Gerando Dados de Demonstração Finais (Cenário Realista)...
@@demo_data.sql


PROMPT
PROMPT ----------------------------------------------------------------------
PROMPT ========================================================================
PROMPT TODOS OS TESTES FORAM EXECUTADOS COM SUCESSO.
PROMPT OS DADOS FORAM PERSISTIDOS (COMMIT).
PROMPT ========================================================================

COMMIT;
-- EXIT; -- Descomenta se quiseres que o SQLPlus feche sozinho no fim
