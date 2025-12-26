-- =============================================================================
-- 8. OTIMIZAÇÃO E PERFORMANCE (ÍNDICES SINCRONIZADOS COM DDLV3)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 8.1. ÍNDICES DE CHAVES ESTRANGEIRAS (FK)
-- -----------------------------------------------------------------------------

-- Tabela: INSCRICAO
CREATE INDEX idx_inscricao_turma ON inscricao(turma_id);
CREATE INDEX idx_inscricao_matricula ON inscricao(matricula_id);

-- Tabela: MATRICULA
CREATE INDEX idx_matricula_estudante ON matricula(estudante_id);
CREATE INDEX idx_matricula_curso ON matricula(curso_id);
CREATE INDEX idx_matricula_estado ON matricula(estado_matricula_id);

-- Tabela: TURMA
CREATE INDEX idx_turma_uc ON turma(unidade_curricular_id);
CREATE INDEX idx_turma_docente ON turma(docente_id);

-- Tabela: AULA
CREATE INDEX idx_aula_turma ON aula(turma_id);
CREATE INDEX idx_aula_sala ON aula(sala_id);
CREATE INDEX idx_aula_tipo ON aula(tipo_aula_id);

-- Tabela: NOTA
-- Nota: PK é (avaliacao_id, inscricao_id), por isso criamos índice apenas na 2ª coluna
CREATE INDEX idx_nota_inscricao ON nota(inscricao_id);

-- Tabela: PRESENCA
-- Nota: PK é (aula_id, inscricao_id), por isso criamos índice apenas na 2ª coluna
CREATE INDEX idx_presenca_inscricao ON presenca(inscricao_id);

-- Tabela: PARCELA_PROPINA
CREATE INDEX idx_parcela_matricula ON parcela_propina(matricula_id);

-- Tabela: ENTREGA
CREATE INDEX idx_entrega_avaliacao ON entrega(avaliacao_id);

-- Tabela: ESTUDANTE_ENTREGA
-- Nota: PK é (entrega_id, inscricao_id), criamos índice na 2ª coluna
CREATE INDEX idx_est_entrega_insc ON estudante_entrega(inscricao_id);

-- Tabela: AVALIACAO
CREATE INDEX idx_avaliacao_turma ON avaliacao(turma_id);
CREATE INDEX idx_avaliacao_tipo ON avaliacao(tipo_avaliacao_id);
CREATE INDEX idx_avaliacao_pai ON avaliacao(avaliacao_pai_id);

-- -----------------------------------------------------------------------------
-- 8.2. ÍNDICES ESTRATÉGICOS (COLUNAS DE PESQUISA FREQUENTE)
-- -----------------------------------------------------------------------------

-- ESTUDANTE: Identidade e Contacto
CREATE UNIQUE INDEX idx_estudante_codigo ON estudante(codigo);
CREATE INDEX idx_estudante_nif ON estudante(nif);
CREATE INDEX idx_estudante_cc ON estudante(cc);
CREATE INDEX idx_estudante_nome ON estudante(nome);
CREATE INDEX idx_estudante_email ON estudante(email);

-- DOCENTE: Identidade e Contacto
CREATE INDEX idx_docente_nif ON docente(nif);
CREATE INDEX idx_docente_nome ON docente(nome);
CREATE INDEX idx_docente_email ON docente(email);

-- CURSO e UNIDADE CURRICULAR
CREATE INDEX idx_curso_codigo ON curso(codigo);
CREATE INDEX idx_uc_codigo ON unidade_curricular(codigo);

-- LOG
CREATE INDEX idx_log_created_at ON log(created_at);
