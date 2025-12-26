-- =============================================================================
-- 7. VISTAS E FUNÇÕES AUXILIARES (REFORMATADO)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Função para verificar se um aluno tem dívidas
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION FUN_IS_DEVEDOR(p_estudante_id IN NUMBER) 
    RETURN CHAR 
IS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count 
    FROM parcela_propina p 
    JOIN matricula m ON p.matricula_id = m.id
    WHERE m.estudante_id = p_estudante_id 
      AND p.estado != 'P' 
      AND p.data_vencimento < SYSDATE 
      AND m.status = '1' 
      AND p.status = '1';

    IF v_count > 0 THEN 
        RETURN 'S'; 
    ELSE 
        RETURN 'N'; 
    END IF;
EXCEPTION 
    WHEN OTHERS THEN 
        RETURN 'N'; 
END FUN_IS_DEVEDOR;
/

-- -----------------------------------------------------------------------------
-- Vista: Pauta de Notas
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW VW_PAUTA_TURMA AS
    SELECT 
        t.nome AS turma,
        uc.nome AS unidade_curricular,
        e.nome AS estudante,
        e.codigo AS numero_estudante,
        av.titulo AS avaliacao,
        n.nota
    FROM nota n
    JOIN inscricao i ON n.inscricao_id = i.id
    JOIN matricula m ON i.matricula_id = m.id
    JOIN estudante e ON m.estudante_id = e.id
    JOIN avaliacao av ON n.avaliacao_id = av.id
    JOIN turma t ON i.turma_id = t.id
    JOIN unidade_curricular uc ON t.unidade_curricular_id = uc.id
    WHERE n.status = '1'
    ORDER BY t.nome, e.nome;
/

-- -----------------------------------------------------------------------------
-- Vista: Alerta de Assiduidade
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW VW_ALERTA_ASSIDUIDADE AS
    WITH assiduidade_calc AS (
        SELECT 
            i.id AS inscricao_id,
            i.matricula_id,
            t.unidade_curricular_id,
            COUNT(p.aula_id) AS total_aulas,
            SUM(CASE WHEN p.presente = '1' THEN 1 ELSE 0 END) AS presencas
        FROM inscricao i
        JOIN turma t ON i.turma_id = t.id
        LEFT JOIN presenca p ON i.id = p.inscricao_id
        WHERE i.status = '1'
        GROUP BY i.id, i.matricula_id, t.unidade_curricular_id
    )
    SELECT 
        e.nome AS estudante,
        uc.nome AS disciplina,
        ucc.percentagem_presenca AS limite,
        ROUND((ac.presencas / NULLIF(ac.total_aulas, 0)) * 100, 2) AS atual
    FROM assiduidade_calc ac
    JOIN matricula m ON ac.matricula_id = m.id
    JOIN estudante e ON m.estudante_id = e.id
    JOIN unidade_curricular uc ON ac.unidade_curricular_id = uc.id
    JOIN uc_curso ucc ON (uc.id = ucc.unidade_curricular_id AND m.curso_id = ucc.curso_id)
    WHERE ucc.presenca_obrigatoria = '1'
      AND (ac.presencas / NULLIF(ac.total_aulas, 0)) * 100 < ucc.percentagem_presenca;
/