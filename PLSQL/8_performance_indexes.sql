-- =============================================================================
-- 8. OTIMIZAÇÃO E PERFORMANCE (ÍNDICES DE CHAVES ESTRANGEIRAS)
-- Evita "Table Lock" em operações de delete/update no pai e acelera joins.
-- =============================================================================

-- Tabela: INSCRICAO
CREATE INDEX idx_inscricao_turma ON inscricao(turma_id);
CREATE INDEX idx_inscricao_matricula ON inscricao(matricula_id);

-- Tabela: MATRICULA
CREATE INDEX idx_matricula_estudante ON matricula(estudante_id);
CREATE INDEX idx_matricula_curso ON matricula(curso_id);

-- Tabela: TURMA
CREATE INDEX idx_turma_uc ON turma(unidade_curricular_id);
CREATE INDEX idx_turma_docente ON turma(docente_id);

-- Tabela: AULA
CREATE INDEX idx_aula_turma ON aula(turma_id);
CREATE INDEX idx_aula_sala ON aula(sala_id);
CREATE INDEX idx_aula_tipo ON aula(tipo_aula_id);

-- Tabela: NOTA (Crítico para pautas)
CREATE INDEX idx_nota_inscricao ON nota(inscricao_id);
CREATE INDEX idx_nota_avaliacao ON nota(avaliacao_id);

-- Tabela: PRESENCA (Crítico para relatórios de assiduidade)
CREATE INDEX idx_presenca_inscricao ON presenca(inscricao_id);
CREATE INDEX idx_presenca_aula ON presenca(aula_id);

-- Tabela: PARCELA_PROPINA (Financeiro)
CREATE INDEX idx_propina_matricula ON parcela_propina(matricula_id);

-- Tabela: ENTREGA
CREATE INDEX idx_entrega_avaliacao ON entrega(avaliacao_id);

-- Tabela: ESTUDANTE_ENTREGA
CREATE INDEX idx_est_entrega_entrega ON estudante_entrega(entrega_id);
CREATE INDEX idx_est_entrega_inscricao ON estudante_entrega(inscricao_id);

-- Tabela: AVALIACAO
CREATE INDEX idx_avaliacao_turma ON avaliacao(turma_id);
