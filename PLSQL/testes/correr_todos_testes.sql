-- =============================================================================
-- SCRIPT MESTRE DE TESTES
-- Executa toda a suite de testes do projeto
-- =============================================================================
SET SERVEROUTPUT ON SIZE UNLIMITED;
SET FEEDBACK OFF;
SET VERIFY OFF;

PROMPT ========================================================================
PROMPT INICIANDO SUITE DE TESTES DO PROJETO BD2 (V3 - INTEGRIDADE TOTAL)
PROMPT ========================================================================

PROMPT [1/12] Executando Testes Unitários Integrados...
@@executar_testes.sql

PROMPT [2/12] Executando Validação e Formatação de Dados...
@@testes_validacao_dados.sql

PROMPT [3/13] Executando Testes de Integridade da Tabela SALA...
@@testes_tabela_sala.sql

PROMPT [3b/19] Executando Testes de Integridade da Tabela TURMA...
@@testes_tabela_turma.sql

PROMPT [4/14] Executando Testes de Integridade da Tabela AULA...
@@testes_tabela_aula.sql

PROMPT [5/15] Executando Testes de Integridade da Tabela AVALIACAO...
@@testes_tabela_avaliacao.sql

PROMPT [6/16] Executando Testes de Integridade da Tabela CURSO...
@@testes_tabela_curso.sql

PROMPT [7/17] Executando Testes de Integridade da Tabela DOCENTE...
@@testes_tabela_docente.sql

PROMPT [8/18] Executando Testes de Integridade da Tabela ESTUDANTE...
@@testes_tabela_estudante.sql

PROMPT [9/19] Executando Testes de Integridade da Tabela ENTREGA...
@@testes_tabela_entrega.sql

PROMPT [10/19] Executando Testes de Integridade da Tabela ESTUDANTE_ENTREGA...
@@testes_tabela_estudante_entrega.sql

PROMPT [11/19] Executando Testes Funcionais Extra (Multas, Logs)...
@@testes_funcionais_extra.sql

PROMPT [12/19] Executando Lógica de Negócio (Médias e Pagamentos)...
@@testes_logica_negocio.sql

PROMPT [13/19] Executando Testes Avançados (NIF, Conflitos)...
@@testes_avancados.sql

PROMPT [14/19] Executando Testes de Limites de ECTS...
@@testes_limites.sql

PROMPT [15/19] Executando Testes de Regras de Avaliação (Hierarquia e Entregas)...
@@testes_regras_avaliacao.sql

PROMPT [16/19] Executando Regras de Max_Alunos e Grupos...
@@teste_max_alunos.sql

PROMPT [17/19] Executando Teste de Segurança de Logs (Imutabilidade)...
@@teste_seguranca_log.sql

PROMPT [18/19] Validando Vistas e Relatórios...
@@testar_vistas.sql

PROMPT [18b/19] Executando Testes de Integridade da Tabela FICHEIRO_ENTREGA...
@@testes_tabela_ficheiro_entrega.sql

PROMPT [18c/19] Executando Testes de Integridade da Tabela FICHEIRO_RECURSO...
@@testes_tabela_ficheiro_recurso.sql

PROMPT [19/19] Gerando Dados de Demonstração Finais (Cenário Realista)...
@@demo_data.sql

PROMPT ========================================================================
PROMPT TODOS OS TESTES FORAM EXECUTADOS.
PROMPT VERIFIQUE OS LOGS ACIMA PARA CONFIRMAR OS RESULTADOS [OK].
PROMPT ========================================================================
COMMIT;